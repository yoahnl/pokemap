import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;

img.PngDecoder validatedStaticPngDecoder(Uint8List bytes,
    {required int maxDimension, required int maxPixels}) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 8) {
    throw const FormatException('Invalid PNG signature.');
  }
  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature[index]) {
      throw const FormatException('Invalid PNG signature.');
    }
  }
  final data = ByteData.sublistView(bytes);
  img.PngInfo? header;
  final idat = <Uint8List>[];
  var idatEnded = false;
  var ended = false;
  var offset = 8;
  while (offset < bytes.length) {
    if (bytes.length - offset < 12) {
      throw const FormatException('Truncated PNG chunk.');
    }
    final length = data.getUint32(offset);
    final end = offset + 12 + length;
    if (end > bytes.length) {
      throw const FormatException('PNG chunk exceeds its payload bounds.');
    }
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    if (!RegExp(r'^[A-Za-z]{4}$').hasMatch(type) ||
        getCrc32(Uint8List.sublistView(bytes, offset + 4, end - 4)) !=
            data.getUint32(end - 4)) {
      throw const FormatException('Invalid PNG chunk type or checksum.');
    }
    if (header == null && type != 'IHDR') {
      throw const FormatException('PNG must begin with IHDR.');
    }
    if (type == 'IHDR') {
      if (header != null || length != 13) {
        throw const FormatException('PNG requires exactly one IHDR.');
      }
      header = img.PngInfo()
        ..width = data.getUint32(offset + 8)
        ..height = data.getUint32(offset + 12)
        ..bits = bytes[offset + 16]
        ..colorType = bytes[offset + 17]
        ..compressionMethod = bytes[offset + 18]
        ..filterMethod = bytes[offset + 19]
        ..interlaceMethod = bytes[offset + 20];
      _validateHeader(header, maxDimension, maxPixels);
    } else if (type == 'IDAT') {
      if (idatEnded) {
        throw const FormatException('PNG IDAT chunks must remain consecutive.');
      }
      idat.add(Uint8List.sublistView(bytes, offset + 8, end - 4));
    } else {
      if (idat.isNotEmpty) idatEnded = true;
      if (type == 'acTL' || type == 'fcTL' || type == 'fdAT') {
        throw const FormatException('PNG textures must be static.');
      }
      if (type == 'IEND') {
        if (length != 0 || end != bytes.length) {
          throw const FormatException('Invalid PNG end chunk.');
        }
        ended = true;
      } else if (type != 'PLTE' && type.codeUnitAt(0) & 32 == 0) {
        throw const FormatException('Unsupported critical PNG chunk.');
      }
    }
    offset = end;
  }
  if (header == null || idat.isEmpty || !ended) {
    throw const FormatException('PNG requires IHDR, IDAT and IEND.');
  }
  final builder = BytesBuilder(copy: false);
  if (idat.length > 1) {
    for (final chunk in idat) {
      builder.add(chunk);
    }
  }
  final compressed = idat.length == 1 ? idat.single : builder.takeBytes();
  _validateInflation(compressed, staticPngScanlineBytes(header));
  final decoder = img.PngDecoder();
  final decoded = decoder.startDecode(bytes);
  final info = decoder.info;
  if (decoded == null ||
      decoded.numFrames != 1 ||
      info.isAnimated ||
      info.width != header.width ||
      info.height != header.height ||
      info.bits != header.bits ||
      info.colorType != header.colorType ||
      info.interlaceMethod != header.interlaceMethod) {
    throw const FormatException(
        'PNG decoding disagrees with its static header.');
  }
  return decoder;
}

void _validateHeader(img.PngInfo info, int maxDimension, int maxPixels) {
  final bits = switch (info.colorType) {
    0 => const [1, 2, 4, 8, 16],
    2 || 4 || 6 => const [8, 16],
    3 => const [1, 2, 4, 8],
    _ => const <int>[],
  };
  if (info.width < 1 ||
      info.height < 1 ||
      info.width > maxDimension ||
      info.height > maxDimension ||
      info.width * info.height > maxPixels ||
      !bits.contains(info.bits) ||
      info.compressionMethod != 0 ||
      info.filterMethod != 0 ||
      info.interlaceMethod > 1) {
    throw const FormatException(
        'PNG header exceeds the supported native bounds.');
  }
}

int staticPngScanlineBytes(img.PngInfo info) {
  final channels = switch (info.colorType) {
    0 || 3 => 1,
    2 => 3,
    4 => 2,
    6 => 4,
    _ => throw const FormatException('Unsupported PNG color type.'),
  };
  int pass(int x, int y, int dx, int dy) {
    final width = math.max(0, (info.width - x + dx - 1) ~/ dx);
    final height = math.max(0, (info.height - y + dy - 1) ~/ dy);
    if (width == 0 || height == 0) return 0;
    return height * (1 + (width * channels * info.bits + 7) ~/ 8);
  }

  if (info.interlaceMethod == 0) return pass(0, 0, 1, 1);
  if (info.interlaceMethod != 1) {
    throw const FormatException('Unsupported PNG interlace method.');
  }
  return pass(0, 0, 8, 8) +
      pass(4, 0, 8, 8) +
      pass(0, 4, 4, 8) +
      pass(2, 0, 4, 4) +
      pass(0, 2, 2, 4) +
      pass(1, 0, 2, 2) +
      pass(0, 1, 1, 2);
}

void _validateInflation(Uint8List compressed, int expected) {
  if (compressed.length < 6 ||
      compressed[0] & 15 != 8 ||
      compressed[0] >> 4 > 7 ||
      (compressed[0] * 256 + compressed[1]) % 31 != 0 ||
      compressed[1] & 32 != 0) {
    throw const FormatException('Invalid PNG zlib header.');
  }
  final input =
      InputMemoryStream(compressed, offset: 2, length: compressed.length - 6);
  final output = _BoundedPngOutput(expected);
  Inflate.stream(input, output: output);
  final adler =
      ByteData.sublistView(compressed).getUint32(compressed.length - 4);
  if (!input.isEOS || output.length != expected || output.adler32 != adler) {
    throw const FormatException(
        'PNG scanline stream is incomplete or corrupt.');
  }
}

final class _BoundedPngOutput extends OutputStream {
  _BoundedPngOutput(this.expected) : super(byteOrder: ByteOrder.littleEndian);
  final int expected;
  final Uint8List _window = Uint8List(32768);
  final Uint8List _checksumBuffer = Uint8List(3800);
  int _checksumLength = 0;
  int _adler = 1;
  int _length = 0;
  @override
  int get length => _length;
  int get adler32 => getAdler32(
      Uint8List.sublistView(_checksumBuffer, 0, _checksumLength), _adler);

  void _reserve(int count) {
    if (count < 0 || count > expected - _length) {
      throw const FormatException(
          'PNG scanline data exceeds its declared dimensions.');
    }
  }

  @override
  void writeByte(int value) {
    _reserve(1);
    _window[_length++ % _window.length] = value;
    _checksumBuffer[_checksumLength++] = value;
    if (_checksumLength == _checksumBuffer.length) {
      _adler = getAdler32(_checksumBuffer, _adler);
      _checksumLength = 0;
    }
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    final count = length ?? bytes.length;
    _reserve(count);
    if (count > bytes.length) {
      throw const FormatException('Invalid inflate write.');
    }
    for (var index = 0; index < count; index++) {
      writeByte(bytes[index]);
    }
  }

  @override
  void writeStream(InputStream stream) {
    _reserve(stream.length);
    while (!stream.isEOS) {
      writeByte(stream.readByte());
    }
  }

  @override
  Uint8List subset(int start, [int? end]) {
    final from = start < 0 ? _length + start : start;
    final until = end == null ? _length : (end < 0 ? _length + end : end);
    if (from < math.max(0, _length - _window.length) ||
        until < from ||
        until > _length ||
        until - from > _window.length) {
      throw const FormatException('Invalid PNG deflate back-reference.');
    }
    final bytes = Uint8List(until - from);
    for (var index = from; index < until; index++) {
      bytes[index - from] = _window[index % _window.length];
    }
    return bytes;
  }

  @override
  void clear() => throw StateError('The bounded PNG output cannot be reset.');
  @override
  void flush() {}
}
