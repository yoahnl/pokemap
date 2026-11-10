import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image;

import 'native_bindings.dart';

enum Gen5SpriteSide { front, back }

final class Gen5NativeSprite {
  static const canvasWidth = 256;
  static const canvasHeight = 256;

  Gen5NativeSprite._(
    this._allocations,
    this._request,
    this._info,
    this._infoSize,
    this._output,
    this._details,
    this._palette,
  );

  factory Gen5NativeSprite({
    required Map<String, Uint8List> assets,
    required Gen5SpriteSide side,
    bool shiny = false,
    bool normalizeFiveBitPalette = false,
  }) {
    final prefix = side.name;
    Uint8List asset(String name) =>
        assets[name] ??
        (throw FormatException('Missing Gen 5 sprite asset: $name'));
    final atlasBytes = asset('$prefix.png');
    _validateIndexedAtlas(atlasBytes);
    final png = image.decodePng(atlasBytes, frame: 0);
    if (png == null ||
        !png.hasPalette ||
        png.width != 256 ||
        png.height != 128) {
      throw const FormatException('Invalid indexed Gen 5 sprite atlas');
    }
    final tiles = Uint8List(16384);
    for (var tileY = 0; tileY < 16; tileY++) {
      for (var tileX = 0; tileX < 32; tileX++) {
        for (var y = 0; y < 8; y++) {
          for (var x = 0; x < 8; x += 2) {
            final left = png.getPixelIndex(tileX * 8 + x, tileY * 8 + y);
            final right = png.getPixelIndex(tileX * 8 + x + 1, tileY * 8 + y);
            if (left < 0 || left > 15 || right < 0 || right > 15) {
              throw const FormatException('Invalid Gen 5 sprite palette index');
            }
            tiles[(tileY * 32 + tileX) * 32 + y * 4 + x ~/ 2] =
                left | (right << 4);
          }
        }
      }
    }
    final palette = _parsePalette(
      asset(shiny ? 'shiny.pal' : 'normal.pal'),
      normalizeFiveBitPalette,
    );
    final allocations = <Pointer<Void>>[];
    Pointer<T> allocate<T extends NativeType>(int size) {
      final value = probeAlloc(size);
      if (value == nullptr) throw StateError('Gen 5 native allocation failed');
      allocations.add(value);
      return value.cast<T>();
    }

    Pointer<Uint8> copy(Uint8List data) {
      final value = allocate<Uint8>(data.length);
      value.asTypedList(data.length).setAll(0, data);
      return value;
    }

    try {
      final compressedBytes = asset('${prefix}_animations.nanr.lz11');
      final compressed = copy(compressedBytes);
      final animation = allocate<Uint8>(1048576);
      final written = allocate<IntPtr>(sizeOf<IntPtr>());
      if (apiDecompress(
            compressed,
            compressedBytes.length,
            animation,
            1048576,
            written,
          ) !=
          0) {
        throw const FormatException(
          'Invalid compressed Gen 5 sprite animation',
        );
      }
      final request = allocate<ProbeRequest>(sizeOf<ProbeRequest>());
      final fields = request.ref;
      fields.tiles = copy(tiles);
      fields.tileSize = tiles.length;
      final cells = asset('${prefix}_cells.ncer');
      fields.ncer = copy(cells);
      fields.ncerSize = cells.length;
      fields.nanr = animation;
      fields.nanrSize = written.value;
      final maps = asset('${prefix}_multi_cells.nmcr');
      fields.nmcr = copy(maps);
      fields.nmcrSize = maps.length;
      final timeline = asset('${prefix}_multi_animations.nmar');
      fields.nmar = copy(timeline);
      fields.nmarSize = timeline.length;
      fields.timeline = 0;
      fields.minX = -(canvasWidth ~/ 2);
      fields.minY = -(canvasHeight ~/ 2);
      fields.width = canvasWidth;
      fields.height = canvasHeight;
      fields.childMode = 0;
      fields.parentCompleted = 0;
      final info = asset('${prefix}_info.bin');
      final rectangles = copy(info);
      final output = allocate<Uint8>(canvasWidth * canvasHeight);
      final details = allocate<Int32>(264 * sizeOf<Int32>());
      final sprite = Gen5NativeSprite._(
        allocations,
        request,
        rectangles,
        info.length,
        output,
        details,
        palette,
      );
      sprite.renderIndexed(0);
      return sprite;
    } on Object {
      for (final pointer in allocations.reversed) {
        probeFree(pointer);
      }
      rethrow;
    }
  }

  final List<Pointer<Void>> _allocations;
  final Pointer<ProbeRequest> _request;
  final Pointer<Uint8> _info;
  final int _infoSize;
  final Pointer<Uint8> _output;
  final Pointer<Int32> _details;
  final Uint8List _palette;
  bool _disposed = false;

  Uint8List renderIndexed(int tick) {
    if (_disposed) throw StateError('Gen 5 sprite has been disposed');
    if (tick < 0 || tick > 0x7fffffff) {
      throw RangeError.range(tick, 0, 0x7fffffff, 'tick');
    }
    _request.ref.tick = tick;
    final result = probeRenderRectangles(
      _request,
      _output,
      canvasWidth * canvasHeight,
      _details,
      264,
      _info,
      _infoSize,
    );
    if (result != 0)
      throw FormatException('Gen 5 native sprite render failed: $result');
    return Uint8List.fromList(_output.asTypedList(canvasWidth * canvasHeight));
  }

  Uint8List renderRgba(int tick) {
    final indices = renderIndexed(tick);
    final rgba = Uint8List(indices.length * 4);
    for (var i = 0; i < indices.length; i++) {
      final color = indices[i];
      if (color > 15)
        throw const FormatException('Invalid rendered palette index');
      rgba.setRange(i * 4, i * 4 + 4, _palette, color * 4);
    }
    return rgba;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final pointer in _allocations.reversed) {
      probeFree(pointer);
    }
    _allocations.clear();
  }
}

void _validateIndexedAtlas(Uint8List bytes) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 33 || bytes.length > 1048576 ||
      !List.generate(signature.length, (i) => bytes[i] == signature[i])
          .every((equal) => equal)) {
    throw const FormatException('Invalid Gen 5 sprite atlas header');
  }
  final data = ByteData.sublistView(bytes);
  if (data.getUint32(8, Endian.big) != 13 ||
      ascii.decode(bytes.sublist(12, 16), allowInvalid: true) != 'IHDR' ||
      data.getUint32(16, Endian.big) != 256 ||
      data.getUint32(20, Endian.big) != 128 ||
      !const [1, 2, 4, 8].contains(bytes[24]) ||
      bytes[25] != 3 ||
      bytes[26] != 0 ||
      bytes[27] != 0 ||
      bytes[28] != 0) {
    throw const FormatException('Invalid indexed Gen 5 sprite atlas');
  }
  final compressed = BytesBuilder(copy: false);
  var hasEnd = false;
  for (var offset = 8; offset < bytes.length;) {
    if (bytes.length - offset < 12) {
      throw const FormatException('Invalid Gen 5 sprite atlas chunk');
    }
    final length = data.getUint32(offset, Endian.big);
    if (length > bytes.length - offset - 12) {
      throw const FormatException('Invalid Gen 5 sprite atlas chunk');
    }
    final type = ascii.decode(bytes.sublist(offset + 4, offset + 8), allowInvalid: true);
    if ((type == 'IHDR' && offset != 8) ||
        type == 'acTL' || type == 'fcTL' || type == 'fdAT') {
      throw const FormatException('Unsupported Gen 5 sprite atlas');
    }
    if (type == 'IDAT') compressed.add(bytes.sublist(offset + 8, offset + 8 + length));
    offset += length + 12;
    if (type == 'IEND') {
      hasEnd = true;
      break;
    }
  }
  if (!hasEnd || compressed.isEmpty) {
    throw const FormatException('Invalid Gen 5 sprite atlas data');
  }
  final expected = ((256 * bytes[24] + 7) ~/ 8 + 1) * 128;
  final sink = _InflatedAtlasLimit(expected);
  try {
    final decoder = ZLibDecoder().startChunkedConversion(sink);
    decoder.add(compressed.takeBytes());
    decoder.close();
  } on FormatException {
    rethrow;
  } on Object {
    throw const FormatException('Invalid Gen 5 sprite atlas compression');
  }
  if (sink.length != expected) {
    throw const FormatException('Invalid Gen 5 sprite atlas data length');
  }
}

final class _InflatedAtlasLimit implements Sink<List<int>> {
  _InflatedAtlasLimit(this.maximum);

  final int maximum;
  var length = 0;

  @override
  void add(List<int> bytes) {
    if (bytes.length > maximum - length) {
      throw const FormatException('Gen 5 sprite atlas decompression limit');
    }
    length += bytes.length;
  }

  @override
  void close() {}
}

Uint8List _parsePalette(Uint8List bytes, bool normalizeFiveBit) {
  final lines = ascii.decode(bytes).trim().split(RegExp(r'\r?\n'));
  if (lines.length != 19 ||
      lines[0] != 'JASC-PAL' ||
      lines[1] != '0100' ||
      lines[2] != '16') {
    throw const FormatException('Invalid Gen 5 sprite palette');
  }
  final palette = Uint8List(64);
  for (var index = 0; index < 16; index++) {
    final values = lines[index + 3].trim().split(RegExp(r'\s+'));
    if (values.length != 3)
      throw const FormatException('Invalid Gen 5 palette color');
    for (var channel = 0; channel < 3; channel++) {
      final value = int.tryParse(values[channel]);
      if (value == null || value < 0 || value > 255) {
        throw const FormatException('Invalid Gen 5 palette channel');
      }
      final value5 = value >> 3;
      if (normalizeFiveBit && value != value5 * 255 ~/ 31) {
        throw const FormatException(
          'Palette is not representable in five bits',
        );
      }
      palette[index * 4 + channel] = index == 0
          ? 0
          : (normalizeFiveBit ? (value5 << 3) | (value5 >> 2) : value);
    }
    palette[index * 4 + 3] = index == 0 ? 0 : 255;
  }
  return palette;
}
