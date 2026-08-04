import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';

/// Dependency-free PNG adapter used only by the native JSONL composition root.
///
/// The canonical packer remains codec-agnostic. The editor injects its richer
/// image-package adapter while CLI/MCP accept the portable non-interlaced PNG
/// subset normally used by Tiled pixel-art collections.
final class CliPngTiledImageCollectionRasterCodec
    implements TiledImageCollectionRasterCodec {
  const CliPngTiledImageCollectionRasterCodec();

  @override
  TiledImageCollectionRasterMetadata inspect(List<int> encodedBytes) {
    final png = _PngDocument.parse(encodedBytes, decodePixels: false);
    return TiledImageCollectionRasterMetadata(
      pixelWidth: png.width,
      pixelHeight: png.height,
    );
  }

  @override
  TiledImageCollectionRgbaImage decode(List<int> encodedBytes) {
    final png = _PngDocument.parse(encodedBytes, decodePixels: true);
    return TiledImageCollectionRgbaImage(
      pixelWidth: png.width,
      pixelHeight: png.height,
      rgbaBytes: png.rgbaBytes!,
    );
  }

  @override
  List<int> encodePng(TiledImageCollectionRgbaImage image) {
    final filtered = BytesBuilder(copy: false);
    final rowLength = image.pixelWidth * 4;
    for (var y = 0; y < image.pixelHeight; y += 1) {
      filtered.addByte(0);
      final start = y * rowLength;
      filtered.add(image.rgbaBytes.sublist(start, start + rowLength));
    }
    final output = BytesBuilder(copy: false)..add(_pngSignature);
    output
      ..add(_chunk(
        'IHDR',
        <int>[
          ..._uint32(image.pixelWidth),
          ..._uint32(image.pixelHeight),
          8,
          6,
          0,
          0,
          0,
        ],
      ))
      ..add(_chunk('IDAT', ZLibCodec().encode(filtered.takeBytes())))
      ..add(_chunk('IEND', const <int>[]));
    return List<int>.unmodifiable(output.takeBytes());
  }
}

final class _PngDocument {
  const _PngDocument({
    required this.width,
    required this.height,
    required this.rgbaBytes,
  });

  static _PngDocument parse(
    List<int> bytes, {
    required bool decodePixels,
  }) {
    if (bytes.length < 33 || !_same(bytes, 0, _pngSignature)) {
      throw const FormatException('Invalid PNG signature.');
    }
    var offset = _pngSignature.length;
    int? width;
    int? height;
    int? bitDepth;
    int? colorType;
    List<int>? palette;
    List<int>? transparency;
    final compressed = BytesBuilder(copy: false);
    var sawEnd = false;
    while (offset < bytes.length) {
      if (offset + 12 > bytes.length) {
        throw const FormatException('Truncated PNG chunk.');
      }
      final length = _readUint32(bytes, offset);
      final typeOffset = offset + 4;
      final dataOffset = offset + 8;
      final end = dataOffset + length;
      if (length < 0 || end + 4 > bytes.length) {
        throw const FormatException('Invalid PNG chunk length.');
      }
      final type = ascii.decode(bytes.sublist(typeOffset, typeOffset + 4));
      final data = bytes.sublist(dataOffset, end);
      final expectedCrc = _readUint32(bytes, end);
      final actualCrc = _crc32(<int>[
        ...bytes.sublist(typeOffset, typeOffset + 4),
        ...data,
      ]);
      if (actualCrc != expectedCrc) {
        throw const FormatException('PNG chunk checksum is invalid.');
      }
      switch (type) {
        case 'IHDR':
          if (width != null || data.length != 13) {
            throw const FormatException('Invalid PNG header.');
          }
          width = _readUint32(data, 0);
          height = _readUint32(data, 4);
          bitDepth = data[8];
          colorType = data[9];
          if (width <= 0 ||
              height <= 0 ||
              data[10] != 0 ||
              data[11] != 0 ||
              data[12] != 0 ||
              !_supportedDepth(colorType, bitDepth)) {
            throw const FormatException('Unsupported PNG header.');
          }
        case 'PLTE':
          palette = data;
        case 'tRNS':
          transparency = data;
        case 'IDAT':
          if (decodePixels) compressed.add(data);
        case 'IEND':
          sawEnd = true;
          offset = end + 4;
          break;
      }
      offset = end + 4;
      if (sawEnd) break;
    }
    if (!sawEnd ||
        width == null ||
        height == null ||
        bitDepth == null ||
        colorType == null) {
      throw const FormatException('Incomplete PNG document.');
    }
    if (!decodePixels) {
      return _PngDocument(width: width, height: height, rgbaBytes: null);
    }
    if (colorType == 3 &&
        (palette == null || palette.isEmpty || palette.length % 3 != 0)) {
      throw const FormatException('Indexed PNG requires a valid palette.');
    }
    final channels = _channels(colorType);
    final rowLength = (width * channels * bitDepth + 7) ~/ 8;
    final expectedLength = height * (rowLength + 1);
    final inflated = _inflateBounded(
      compressed.takeBytes(),
      maximumBytes: expectedLength,
    );
    if (inflated.length != expectedLength) {
      throw const FormatException('PNG pixel stream has an invalid length.');
    }
    final bytesPerPixel = ((channels * bitDepth + 7) ~/ 8).clamp(1, 8);
    final rows = List<Uint8List>.generate(
      height,
      (_) => Uint8List(rowLength),
      growable: false,
    );
    var sourceOffset = 0;
    for (var y = 0; y < height; y += 1) {
      final filter = inflated[sourceOffset++];
      final raw = inflated.sublist(sourceOffset, sourceOffset + rowLength);
      sourceOffset += rowLength;
      _unfilter(
        rows[y],
        raw,
        filter: filter,
        previous: y == 0 ? null : rows[y - 1],
        bytesPerPixel: bytesPerPixel,
      );
    }
    final rgba = Uint8List(width * height * 4);
    var target = 0;
    for (final row in rows) {
      for (var x = 0; x < width; x += 1) {
        final samples = <int>[
          for (var channel = 0; channel < channels; channel += 1)
            _sample(row, x * channels + channel, bitDepth),
        ];
        final pixel = _rgba(
          samples,
          bitDepth: bitDepth,
          colorType: colorType,
          palette: palette,
          transparency: transparency,
        );
        rgba.setRange(target, target + 4, pixel);
        target += 4;
      }
    }
    return _PngDocument(width: width, height: height, rgbaBytes: rgba);
  }

  final int width;
  final int height;
  final List<int>? rgbaBytes;
}

const List<int> _pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];

bool _supportedDepth(int colorType, int bitDepth) => switch (colorType) {
      0 || 3 => const <int>{1, 2, 4, 8}.contains(bitDepth),
      2 || 4 || 6 => bitDepth == 8,
      _ => false,
    };

int _channels(int colorType) => switch (colorType) {
      0 || 3 => 1,
      2 => 3,
      4 => 2,
      6 => 4,
      _ => throw const FormatException('Unsupported PNG color type.'),
    };

List<int> _rgba(
  List<int> samples, {
  required int bitDepth,
  required int colorType,
  required List<int>? palette,
  required List<int>? transparency,
}) {
  final maximum = (1 << bitDepth) - 1;
  int scale(int value) => (value * 255 + maximum ~/ 2) ~/ maximum;
  return switch (colorType) {
    0 => <int>[
        scale(samples[0]),
        scale(samples[0]),
        scale(samples[0]),
        _transparentGray(samples[0], transparency) ? 0 : 255,
      ],
    2 => <int>[
        samples[0],
        samples[1],
        samples[2],
        _transparentRgb(samples, transparency) ? 0 : 255,
      ],
    3 => _paletteRgba(samples[0], palette!, transparency),
    4 => <int>[
        samples[0],
        samples[0],
        samples[0],
        samples[1],
      ],
    6 => <int>[samples[0], samples[1], samples[2], samples[3]],
    _ => throw const FormatException('Unsupported PNG color type.'),
  };
}

List<int> _paletteRgba(
  int index,
  List<int> palette,
  List<int>? transparency,
) {
  final offset = index * 3;
  if (offset + 2 >= palette.length) {
    throw const FormatException('PNG palette index is out of bounds.');
  }
  return <int>[
    palette[offset],
    palette[offset + 1],
    palette[offset + 2],
    transparency != null && index < transparency.length
        ? transparency[index]
        : 255,
  ];
}

bool _transparentGray(int gray, List<int>? transparency) =>
    transparency != null &&
    transparency.length >= 2 &&
    gray == ((transparency[0] << 8) | transparency[1]);

bool _transparentRgb(List<int> rgb, List<int>? transparency) =>
    transparency != null &&
    transparency.length >= 6 &&
    rgb[0] == ((transparency[0] << 8) | transparency[1]) &&
    rgb[1] == ((transparency[2] << 8) | transparency[3]) &&
    rgb[2] == ((transparency[4] << 8) | transparency[5]);

int _sample(List<int> row, int sampleIndex, int bitDepth) {
  if (bitDepth == 8) return row[sampleIndex];
  final bitOffset = sampleIndex * bitDepth;
  final byte = row[bitOffset ~/ 8];
  final shift = 8 - bitDepth - bitOffset % 8;
  return (byte >> shift) & ((1 << bitDepth) - 1);
}

void _unfilter(
  Uint8List output,
  List<int> raw, {
  required int filter,
  required Uint8List? previous,
  required int bytesPerPixel,
}) {
  if (filter < 0 || filter > 4) {
    throw const FormatException('Unsupported PNG row filter.');
  }
  for (var index = 0; index < raw.length; index += 1) {
    final left = index >= bytesPerPixel ? output[index - bytesPerPixel] : 0;
    final above = previous?[index] ?? 0;
    final upperLeft =
        index >= bytesPerPixel ? (previous?[index - bytesPerPixel] ?? 0) : 0;
    final predictor = switch (filter) {
      0 => 0,
      1 => left,
      2 => above,
      3 => (left + above) ~/ 2,
      4 => _paeth(left, above, upperLeft),
      _ => 0,
    };
    output[index] = (raw[index] + predictor) & 0xff;
  }
}

int _paeth(int left, int above, int upperLeft) {
  final prediction = left + above - upperLeft;
  final leftDistance = (prediction - left).abs();
  final aboveDistance = (prediction - above).abs();
  final upperLeftDistance = (prediction - upperLeft).abs();
  if (leftDistance <= aboveDistance && leftDistance <= upperLeftDistance) {
    return left;
  }
  return aboveDistance <= upperLeftDistance ? above : upperLeft;
}

List<int> _inflateBounded(List<int> input, {required int maximumBytes}) {
  final sink = _BoundedByteSink(maximumBytes);
  final conversion = ZLibCodec().decoder.startChunkedConversion(sink);
  conversion
    ..add(input)
    ..close();
  return sink.bytes;
}

final class _BoundedByteSink extends ByteConversionSinkBase {
  _BoundedByteSink(this.maximumBytes);

  final int maximumBytes;
  final BytesBuilder _builder = BytesBuilder(copy: false);
  var _length = 0;
  var _closed = false;

  List<int> get bytes {
    if (!_closed) throw StateError('The PNG stream is not closed.');
    return _builder.toBytes();
  }

  @override
  void add(List<int> chunk) {
    if (_closed || chunk.length > maximumBytes - _length) {
      throw const FormatException('PNG pixel stream exceeds its declaration.');
    }
    _length += chunk.length;
    _builder.add(chunk);
  }

  @override
  void close() => _closed = true;
}

List<int> _chunk(String type, List<int> data) {
  final typeBytes = ascii.encode(type);
  return <int>[
    ..._uint32(data.length),
    ...typeBytes,
    ...data,
    ..._uint32(_crc32(<int>[...typeBytes, ...data])),
  ];
}

List<int> _uint32(int value) => <int>[
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];

int _readUint32(List<int> bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

bool _same(List<int> bytes, int offset, List<int> expected) {
  if (offset < 0 || offset + expected.length > bytes.length) return false;
  for (var index = 0; index < expected.length; index += 1) {
    if (bytes[offset + index] != expected[index]) return false;
  }
  return true;
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit += 1) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}
