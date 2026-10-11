part of '../avelune_converter_core.dart';

final class ZlibDecodeLimits {
  const ZlibDecodeLimits({
    this.maxInputBytes = 8388608,
    this.maxOutputBytes = 33554432,
    this.maxBlocks = 100000,
  });

  final int maxInputBytes;
  final int maxOutputBytes;
  final int maxBlocks;

  void _validate(BinaryDecodeLocation location) {
    if (maxInputBytes <= 0 ||
        maxInputBytes > 268435456 ||
        maxOutputBytes <= 0 ||
        maxOutputBytes > 268435456 ||
        maxBlocks <= 0 ||
        maxBlocks > 1000000) {
      throw BinaryDecodeError('zlib.invalid_limits',
          'Zlib limits must be positive and bounded.', location);
    }
  }
}

final class BoundedZlibDecoder {
  const BoundedZlibDecoder();

  Uint8List decode(
    List<int> bytes, {
    ZlibDecodeLimits limits = const ZlibDecodeLimits(),
    String sourcePath = '<memory>',
    int baseOffset = 0,
  }) {
    final location =
        BinaryDecodeLocation(sourcePath: sourcePath, byteOffset: baseOffset);
    limits._validate(location);
    if (baseOffset < 0 || baseOffset > 9007199254740991 - bytes.length) {
      throw BinaryDecodeError(
          'zlib.invalid_limits',
          'The compressed source offset must be nonnegative and bounded.',
          location);
    }
    if (bytes.length > limits.maxInputBytes) {
      throw BinaryDecodeError('zlib.quota.input',
          'Compressed input exceeds its byte quota.', location);
    }
    final input = Uint8List(bytes.length);
    for (var index = 0; index < input.length; index++) {
      final value = bytes[index];
      if (value < 0 || value > 255) {
        throw BinaryDecodeError(
            'zlib.invalid_header',
            'Compressed input must contain bytes.',
            BinaryDecodeLocation(
                sourcePath: sourcePath, byteOffset: baseOffset + index));
      }
      input[index] = value;
    }
    return _ZlibReader(input, limits, sourcePath, baseOffset).decode();
  }
}

final class _ZlibReader {
  _ZlibReader(this.bytes, this.limits, this.sourcePath, this.baseOffset)
      : bodyEnd = bytes.length - 4;

  final Uint8List bytes;
  final ZlibDecodeLimits limits;
  final String sourcePath;
  final int baseOffset;
  final int bodyEnd;
  int position = 0;
  int bitOffset = 0;
  _ZlibHuffman? _fixedLiteral;
  _ZlibHuffman? _fixedDistance;

  Never fail(String code, String message,
          [int? offset]) =>
      throw BinaryDecodeError(
          code,
          message,
          BinaryDecodeLocation(
              sourcePath: sourcePath,
              byteOffset: baseOffset + (offset ?? position)));

  Uint8List decode() {
    if (bytes.length < 2) fail('zlib.truncated', 'Truncated zlib header.');
    final cmf = bytes[0];
    final flag = bytes[1];
    if ((cmf & 15) != 8 || (cmf >> 4) > 7 || (cmf * 256 + flag) % 31 != 0) {
      fail('zlib.invalid_header',
          'Invalid compression method, window or header check.');
    }
    if ((flag & 32) != 0) {
      fail('zlib.dictionary_unsupported',
          'Preset dictionaries are not supported.');
    }
    if (bytes.length < 6) {
      fail('zlib.truncated', 'Missing zlib body or checksum.');
    }
    position = 2;
    final output =
        _ZlibOutput(this, limits.maxOutputBytes, 1 << (8 + (cmf >> 4)));
    var blocks = 0;
    var finalBlock = false;
    while (!finalBlock) {
      if (blocks >= limits.maxBlocks) {
        fail('zlib.quota.blocks', 'Deflate block quota exceeded.');
      }
      blocks++;
      final blockStart = position;
      finalBlock = bits(1) == 1;
      final kind = bits(2);
      switch (kind) {
        case 0:
          _stored(output);
        case 1:
          _fixedLiteral ??= _ZlibHuffman.build(
              List.generate(
                  288,
                  (symbol) => symbol < 144
                      ? 8
                      : symbol < 256
                          ? 9
                          : symbol < 280
                              ? 7
                              : 8),
              this);
          _fixedDistance ??= _ZlibHuffman.build(List.filled(32, 5), this);
          _compressed(output, _fixedLiteral!, _fixedDistance!);
        case 2:
          final trees = _dynamic();
          _compressed(output, trees.$1, trees.$2);
        default:
          fail(
              'zlib.invalid_block', 'Reserved deflate block type.', blockStart);
      }
    }
    align();
    if (position != bodyEnd) {
      fail('zlib.trailing_bytes',
          'Bytes follow the final deflate block and checksum.');
    }
    var expected = 0;
    for (var index = 0; index < 4; index++) {
      expected = expected * 256 + bytes[position + index];
    }
    if (expected != output.adler) {
      fail('zlib.checksum',
          'The decompressed Adler-32 checksum does not match.');
    }
    return output.finish();
  }

  int bits(int count) {
    var value = 0;
    for (var index = 0; index < count; index++) {
      if (position >= bodyEnd) {
        fail(
            'zlib.truncated', 'Compressed data ends before the current value.');
      }
      value |= ((bytes[position] >> bitOffset) & 1) << index;
      bitOffset++;
      if (bitOffset == 8) {
        position++;
        bitOffset = 0;
      }
    }
    return value;
  }

  void align() {
    if (bitOffset != 0) position++;
    bitOffset = 0;
  }

  void _stored(_ZlibOutput output) {
    align();
    final length = bits(16);
    final complement = bits(16);
    if ((length ^ complement) != 65535) {
      fail('zlib.invalid_block', 'Stored LEN and NLEN are not complements.');
    }
    if (length > bodyEnd - position) {
      fail('zlib.truncated', 'Stored block extends beyond compressed data.');
    }
    output.reserve(length);
    for (var index = 0; index < length; index++) {
      output.append(bytes[position++]);
    }
  }

  (_ZlibHuffman, _ZlibHuffman) _dynamic() {
    final literalCount = bits(5) + 257;
    if (literalCount > 286) {
      fail('zlib.invalid_tree', 'Reserved dynamic literal tree length.');
    }
    final distanceCount = bits(5) + 1;
    final codeCount = bits(4) + 4;
    final codeLengths = List<int>.filled(19, 0);
    for (var index = 0; index < codeCount; index++) {
      codeLengths[_zlibCodeOrder[index]] = bits(3);
    }
    final codeTree = _ZlibHuffman.build(codeLengths, this);
    final lengths = List<int>.filled(literalCount + distanceCount, 0);
    var used = 0;
    while (used < lengths.length) {
      final symbol = codeTree.read(this);
      if (symbol <= 15) {
        lengths[used++] = symbol;
        continue;
      }
      final int value;
      final int repeat;
      switch (symbol) {
        case 16:
          if (used == 0) {
            fail('zlib.invalid_tree', 'A repeat has no preceding code length.');
          }
          value = lengths[used - 1];
          repeat = bits(2) + 3;
        case 17:
          value = 0;
          repeat = bits(3) + 3;
        case 18:
          value = 0;
          repeat = bits(7) + 11;
        default:
          fail('zlib.invalid_tree', 'Invalid code-length symbol.');
      }
      if (repeat > lengths.length - used) {
        fail('zlib.invalid_tree', 'Code-length repeat exceeds its tree.');
      }
      lengths.fillRange(used, used + repeat, value);
      used += repeat;
    }
    if (lengths[256] == 0) {
      fail('zlib.invalid_tree', 'Literal tree has no end-of-block code.');
    }
    final literals = _ZlibHuffman.build(lengths.sublist(0, literalCount), this,
        allowSingleton: true);
    final distances = _ZlibHuffman.build(lengths.sublist(literalCount), this,
        allowSingleton: true, allowEmpty: true);
    return (literals, distances);
  }

  void _compressed(
      _ZlibOutput output, _ZlibHuffman literals, _ZlibHuffman distances) {
    while (true) {
      final symbol = literals.read(this);
      if (symbol < 256) {
        output.reserve(1);
        output.append(symbol);
      } else if (symbol == 256) {
        return;
      } else {
        if (symbol > 285) {
          fail('zlib.invalid_block', 'Reserved literal or length symbol.');
        }
        final slot = symbol - 257;
        final count = _zlibLengthBases[slot] + bits(_zlibLengthExtras[slot]);
        if (distances.empty) {
          fail(
              'zlib.invalid_distance', 'A backreference has no distance tree.');
        }
        final distanceCode = distances.read(this);
        if (distanceCode > 29) {
          fail('zlib.invalid_distance', 'Reserved distance symbol.');
        }
        final distance = _zlibDistanceBases[distanceCode] +
            bits(_zlibDistanceExtras[distanceCode]);
        output.copy(distance, count);
      }
    }
  }
}

final class _ZlibHuffman {
  _ZlibHuffman(this._zero, this._one, this._symbols, this.empty);

  final Int32List _zero;
  final Int32List _one;
  final Int32List _symbols;
  final bool empty;

  static _ZlibHuffman build(List<int> lengths, _ZlibReader reader,
      {bool allowSingleton = false, bool allowEmpty = false}) {
    final counts = List<int>.filled(16, 0);
    var used = 0;
    var maximum = 0;
    for (final length in lengths) {
      if (length < 0 || length > 15) {
        reader.fail(
            'zlib.invalid_tree', 'Huffman length is outside its bound.');
      }
      if (length > 0) {
        counts[length]++;
        used++;
        if (length > maximum) maximum = length;
      }
    }
    if (used == 0 && !allowEmpty) {
      reader.fail('zlib.invalid_tree', 'Huffman tree has no symbols.');
    }
    var remaining = 1;
    for (var length = 1; length <= maximum; length++) {
      remaining = remaining * 2 - counts[length];
      if (remaining < 0) {
        reader.fail('zlib.invalid_tree', 'Huffman tree is oversubscribed.');
      }
    }
    if (used > 0 &&
        remaining > 0 &&
        !(allowSingleton && used == 1 && maximum == 1)) {
      reader.fail('zlib.invalid_tree', 'Huffman tree is incomplete.');
    }
    final capacity = lengths.length * 2 + 1;
    final zero = Int32List(capacity)..fillRange(0, capacity, -1);
    final one = Int32List(capacity)..fillRange(0, capacity, -1);
    final symbols = Int32List(capacity)..fillRange(0, capacity, -1);
    final next = List<int>.filled(16, 0);
    var code = 0;
    for (var length = 1; length <= 15; length++) {
      code = (code + counts[length - 1]) * 2;
      next[length] = code;
    }
    var nodes = 1;
    for (var symbol = 0; symbol < lengths.length; symbol++) {
      final length = lengths[symbol];
      if (length == 0) continue;
      final value = next[length]++;
      var node = 0;
      for (var shift = length - 1; shift >= 0; shift--) {
        final edges = ((value >> shift) & 1) == 0 ? zero : one;
        if (edges[node] == -1) {
          if (nodes >= capacity) {
            reader.fail('zlib.invalid_tree', 'Huffman node bound exceeded.');
          }
          edges[node] = nodes++;
        }
        node = edges[node];
      }
      symbols[node] = symbol;
    }
    return _ZlibHuffman(zero, one, symbols, used == 0);
  }

  int read(_ZlibReader reader) {
    var node = 0;
    for (var depth = 0; depth < 15; depth++) {
      node = reader.bits(1) == 0 ? _zero[node] : _one[node];
      if (node < 0) {
        reader.fail(
            'zlib.invalid_tree', 'Compressed Huffman code is unassigned.');
      }
      if (_symbols[node] >= 0) return _symbols[node];
    }
    reader.fail('zlib.invalid_tree', 'Compressed Huffman code is too long.');
  }
}

final class _ZlibOutput {
  _ZlibOutput(this.reader, this.limit, this.window);

  final _ZlibReader reader;
  final int limit;
  final int window;
  final Uint8List _history = Uint8List(32768);
  final List<Uint8List> _segments = [];
  Uint8List? _current;
  int _segmentUsed = 0;
  int length = 0;
  int _a = 1;
  int _b = 0;

  int get adler => _b * 65536 + _a;

  void reserve(int count) {
    if (count > limit - length) {
      reader.fail(
          'zlib.quota.output', 'Decompressed output exceeds its byte quota.');
    }
  }

  void append(int byte) {
    if (_current == null || _segmentUsed == _current!.length) {
      final available = limit - length;
      final size = available < 32768 ? available : 32768;
      _current = Uint8List(size);
      _segments.add(_current!);
      _segmentUsed = 0;
    }
    _current![_segmentUsed++] = byte;
    _history[length & 32767] = byte;
    length++;
    _a = (_a + byte) % 65521;
    _b = (_b + _a) % 65521;
  }

  void copy(int distance, int count) {
    if (distance < 1 || distance > window || distance > length) {
      reader.fail('zlib.invalid_distance',
          'Backreference exceeds available history or the declared window.');
    }
    reserve(count);
    for (var index = 0; index < count; index++) {
      append(_history[(length - distance) & 32767]);
    }
  }

  Uint8List finish() {
    final result = Uint8List(length);
    var offset = 0;
    for (final segment in _segments) {
      final remaining = length - offset;
      final count = remaining < segment.length ? remaining : segment.length;
      result.setRange(offset, offset + count, segment);
      offset += count;
    }
    return result;
  }
}

const _zlibCodeOrder = [
  16,
  17,
  18,
  0,
  8,
  7,
  9,
  6,
  10,
  5,
  11,
  4,
  12,
  3,
  13,
  2,
  14,
  1,
  15
];
const _zlibLengthBases = [
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  13,
  15,
  17,
  19,
  23,
  27,
  31,
  35,
  43,
  51,
  59,
  67,
  83,
  99,
  115,
  131,
  163,
  195,
  227,
  258
];
const _zlibLengthExtras = [
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  1,
  1,
  1,
  2,
  2,
  2,
  2,
  3,
  3,
  3,
  3,
  4,
  4,
  4,
  4,
  5,
  5,
  5,
  5,
  0
];
const _zlibDistanceBases = [
  1,
  2,
  3,
  4,
  5,
  7,
  9,
  13,
  17,
  25,
  33,
  49,
  65,
  97,
  129,
  193,
  257,
  385,
  513,
  769,
  1025,
  1537,
  2049,
  3073,
  4097,
  6145,
  8193,
  12289,
  16385,
  24577
];
const _zlibDistanceExtras = [
  0,
  0,
  0,
  0,
  1,
  1,
  2,
  2,
  3,
  3,
  4,
  4,
  5,
  5,
  6,
  6,
  7,
  7,
  8,
  8,
  9,
  9,
  10,
  10,
  11,
  11,
  12,
  12,
  13,
  13
];
