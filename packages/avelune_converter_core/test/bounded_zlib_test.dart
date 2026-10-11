import 'dart:collection';
import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

final _fixtures = <String, List<int>>{
  'stored': base64Decode('eAEBDQDy/3N0b3JlZABieXRlc/8kxwW4'),
  'fixed': base64Decode(
      'eAFzdHIchaNwFI7CUTgKR+EoHIWjcBSOwlE4CkfhKByFo3AUjsJROApH4SgchaNwFI7CUTgKR+EoHIWjcBSOwlE4CkfhKByFo3AUjsJROApH4SgchaNwFI7CUTgKR+EoHIWjcBSOwlE4CkfhKByFo3AUjsJROApH4SgchaNwFI7CUTgKR+EoHIWjcBSOwlE4CkfhKByFo3AUjsJROApH4SgchaNwFI7CUTgKR+EoHIWjcBSOwlE4CkfhKByFo3AUjsJROApH4SgchaNwFI7CUTgKR+EoHIWjcBSOwlE4CkfhKByFo3AUjsJROApH4SgchaNwFI7CUTgKR+EoHIWjcBSOwlE4CkfhKByFo3AUjsJROApH4SgchaNwFI7CUTgKR+EoHIWjcBSOwlE4CkfhKByFo3AUjsJROApH4SgchaNwFI7CUTgKR+EoHIWjcBSOwlE4CkfhKByFo3AUjsJROApH4SgchaNwFI7CUTgKR+EoHIWjcBSOwlE4CkfhKByFo3AUjsJROApH4SgchaNwFI7CUTgKR+EoHIWjcBSOwlE4CkfhKByFo3AUjsJROApH4SgchaNwFI7CUTgKRyGVIQCLpvo0'),
  'dynamic': base64Decode(
      'eJzty8VxAgAAADCgSHF3p8XdHfbfij245J9AMPQTjkRjv/FEMpXOZHP5QrFUrlRr9Uaz1e50e/3B3/9wNJ5MZ/PFcrXebHf7w/F0vlxv98fz9Q74vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vu/7vv/1/wN+iYmU'),
  'bomb': base64Decode(
      'eNrtwTEBAAAAwqBs61/KEL5AAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB8BrGMPPE='),
  'mixed': base64Decode('eJwqKEpNy6wAAAAA//8rLk0DkgAhWQUk'),
};

void main() {
  const decoder = BoundedZlibDecoder();

  Matcher code(String value) =>
      isA<BinaryDecodeError>().having((error) => error.code, 'code', value);

  test('stored Python zlib oracle preserves every binary byte', () {
    expect(decoder.decode(_fixtures['stored']!),
        [...'stored'.codeUnits, 0, ...'bytes'.codeUnits, 255]);
  });

  test('fixed Python zlib oracle crosses chunks and wraps the history window',
      () {
    expect(decoder.decode(_fixtures['fixed']!),
        List.generate(70000, (index) => index.isEven ? 65 : 66));
  });

  test('dynamic Python zlib oracle decodes canonical trees and backreferences',
      () {
    expect(decoder.decode(_fixtures['dynamic']!),
        List.generate(128000, (index) => index % 64));
  });

  test('mixed Python zlib oracle preserves history across block boundaries',
      () {
    expect(decoder.decode(_fixtures['mixed']!), 'prefixsuffix'.codeUnits);
  });

  test('empty final stored block is valid', () {
    expect(decoder.decode(_frame([1, 0, 0, 255, 255], [])), isEmpty);
  });

  test('input quota is checked before reading or copying any source byte', () {
    final unreadable = _UnreadableBytes(200);
    expect(
        () => decoder.decode(unreadable,
            limits: const ZlibDecodeLimits(maxInputBytes: 100)),
        throwsA(code('zlib.quota.input')));
    expect(unreadable.reads, 0);
  });

  test('bomb output quota aborts before consuming the compressed stream', () {
    final input = _fixtures['bomb']!;
    expect(
        () => decoder.decode(input,
            limits: const ZlibDecodeLimits(maxOutputBytes: 16),
            sourcePath: 'Data/Scripts.rxdata',
            baseOffset: 100),
        throwsA(isA<BinaryDecodeError>()
            .having((error) => error.code, 'code', 'zlib.quota.output')
            .having((error) => error.location.sourcePath, 'source path',
                'Data/Scripts.rxdata')
            .having(
                (error) => error.location.byteOffset,
                'offset',
                allOf(greaterThanOrEqualTo(100),
                    lessThan(100 + input.length - 4)))));
  });

  test('stored block output quota is enforced before its data copy', () {
    expect(
        () => decoder.decode(_fixtures['stored']!,
            limits: const ZlibDecodeLimits(maxOutputBytes: 12)),
        throwsA(code('zlib.quota.output')));
  });

  test('output at the exact configured quota is accepted', () {
    expect(
        decoder.decode(_fixtures['stored']!,
            limits: const ZlibDecodeLimits(maxOutputBytes: 13)),
        hasLength(13));
  });

  test('block quota includes empty blocks', () {
    final bits = _Bits();
    for (var i = 0; i < 2; i++) {
      bits.bits(i == 1 ? 1 : 0, 3);
      bits.align();
      bits.bits(0, 16);
      bits.bits(65535, 16);
    }
    expect(
        () => decoder.decode(_frame(bits.bytes, []),
            limits: const ZlibDecodeLimits(maxBlocks: 1)),
        throwsA(code('zlib.quota.blocks')));
  });

  test('invalid configured limits and base offset are rejected', () {
    for (final limits in [
      const ZlibDecodeLimits(maxInputBytes: 0),
      const ZlibDecodeLimits(maxOutputBytes: -1),
      const ZlibDecodeLimits(maxBlocks: 0),
      const ZlibDecodeLimits(maxOutputBytes: 1 << 40),
    ]) {
      expect(() => decoder.decode(_fixtures['stored']!, limits: limits),
          throwsA(code('zlib.invalid_limits')));
    }
    expect(() => decoder.decode(_fixtures['stored']!, baseOffset: -1),
        throwsA(code('zlib.invalid_limits')));
  });

  test('truncated headers and missing final block are rejected', () {
    for (final input in [
      <int>[],
      [0x78],
      _frame([], [])
    ]) {
      expect(() => decoder.decode(input), throwsA(code('zlib.truncated')));
    }
    expect(() => decoder.decode(_frame([0, 0, 0, 255, 255], [])),
        throwsA(code('zlib.truncated')));
  });

  test('every truncated prefix of a valid stored frame is rejected', () {
    final bytes = _fixtures['stored']!;
    for (var length = 0; length < bytes.length; length++) {
      expect(() => decoder.decode(bytes.sublist(0, length)),
          throwsA(isA<BinaryDecodeError>()));
    }
  });

  test('incorrect header check, method and window are rejected', () {
    final badCheck = [..._fixtures['stored']!]..[1] ^= 1;
    expect(
        () => decoder.decode(badCheck), throwsA(code('zlib.invalid_header')));
    expect(() => decoder.decode(_frame([1, 0, 0, 255, 255], [], cmf: 0x79)),
        throwsA(code('zlib.invalid_header')));
    expect(() => decoder.decode(_frame([1, 0, 0, 255, 255], [], cmf: 0x88)),
        throwsA(code('zlib.invalid_header')));
    expect(
        () => decoder.decode([256, 0]), throwsA(code('zlib.invalid_header')));
  });

  test('preset dictionaries are explicitly unsupported', () {
    final cmf = 0x78;
    final flag = 0x20 + ((31 - ((cmf * 256 + 0x20) % 31)) % 31);
    expect(() => decoder.decode([cmf, flag, 0, 0, 0, 0]),
        throwsA(code('zlib.dictionary_unsupported')));
  });

  test('reserved block type is rejected at its compressed locator', () {
    expect(
        () => decoder.decode(_frame([7], []),
            sourcePath: 'payload', baseOffset: 50),
        throwsA(isA<BinaryDecodeError>()
            .having((error) => error.code, 'code', 'zlib.invalid_block')
            .having((error) => error.location.byteOffset, 'offset', 52)));
  });

  test('LEN and NLEN must be complements even when LEN is zero', () {
    expect(() => decoder.decode(_frame([1, 0, 0, 0, 0], [])),
        throwsA(code('zlib.invalid_block')));
    final mismatch = [..._fixtures['stored']!]..[5] ^= 1;
    expect(() => decoder.decode(mismatch), throwsA(code('zlib.invalid_block')));
  });

  test('stored block cannot consume bytes from the Adler trailer', () {
    expect(() => decoder.decode(_frame([1, 1, 0, 254, 255], [])),
        throwsA(code('zlib.truncated')));
  });

  test('Adler mismatch and trailing bytes are rejected', () {
    final checksum = [..._fixtures['stored']!]..[23] ^= 1;
    expect(() => decoder.decode(checksum), throwsA(code('zlib.checksum')));
    expect(() => decoder.decode([..._fixtures['stored']!, 0]),
        throwsA(code('zlib.trailing_bytes')));
    expect(
        () =>
            decoder.decode([..._fixtures['stored']!, ..._fixtures['stored']!]),
        throwsA(code('zlib.trailing_bytes')));
  });

  test('fixed distance cannot reference before the first output byte', () {
    final bits = _Bits()
      ..bits(3, 3)
      ..fixed(257)
      ..code(0, 5)
      ..fixed(256);
    expect(() => decoder.decode(_frame(bits.bytes, [])),
        throwsA(code('zlib.invalid_distance')));
  });

  test('reserved fixed literal and distance symbols are rejected', () {
    final literal = _Bits()
      ..bits(3, 3)
      ..fixed(286);
    expect(() => decoder.decode(_frame(literal.bytes, [])),
        throwsA(code('zlib.invalid_block')));
    final distance = _Bits()
      ..bits(3, 3)
      ..fixed(65)
      ..fixed(257)
      ..code(30, 5);
    expect(() => decoder.decode(_frame(distance.bytes, [65])),
        throwsA(code('zlib.invalid_distance')));
  });

  test('backreferences respect the declared CINFO window', () {
    final initial = List.generate(300, (index) => index % 251);
    final bits = _Bits()..bits(0, 3);
    bits.align();
    bits.bits(300, 16);
    bits.bits(300 ^ 65535, 16);
    for (final byte in initial) {
      bits.bits(byte, 8);
    }
    bits.bits(3, 3);
    bits.fixed(257);
    bits.code(16, 5);
    bits.bits(43, 7);
    bits.fixed(256);
    final expected = [...initial, ...initial.take(3)];
    expect(decoder.decode(_frame(bits.bytes, expected)), expected);
    expect(() => decoder.decode(_frame(bits.bytes, expected, cmf: 0x08)),
        throwsA(code('zlib.invalid_distance')));
  });

  test('fixed tree requires a complete end-of-block code', () {
    final bits = _Bits()
      ..bits(3, 3)
      ..fixed(65);
    expect(() => decoder.decode(_frame(bits.bytes, [65])),
        throwsA(code('zlib.truncated')));
  });

  test('dynamic HLIT reserved values are rejected before tree allocation', () {
    final raw = _hex('f5c0810800000000207feb5100');
    expect(() => decoder.decode(_frame(raw, [])),
        throwsA(code('zlib.invalid_tree')));
  });

  test('oversubscribed and incomplete code-length trees are rejected', () {
    for (final lengths in [
      [1, 1, 1, 1],
      [0, 0, 0, 1]
    ]) {
      final bits = _dynamicHeader(lengths);
      expect(() => decoder.decode(_frame(bits.bytes, [])),
          throwsA(code('zlib.invalid_tree')));
    }
  });

  test('code-length repeat 16 requires a preceding value', () {
    final bits = _dynamicHeader([1, 0, 0, 1])
      ..code(1, 1)
      ..bits(0, 2);
    expect(() => decoder.decode(_frame(bits.bytes, [])),
        throwsA(code('zlib.invalid_tree')));
  });

  test('code-length repeats cannot overflow declared tree lengths', () {
    final bits = _dynamicHeader([0, 0, 1, 1])
      ..code(1, 1)
      ..bits(127, 7)
      ..code(1, 1)
      ..bits(127, 7);
    expect(() => decoder.decode(_frame(bits.bytes, [])),
        throwsA(code('zlib.invalid_tree')));
  });

  test('literal tree must provide an end-of-block symbol', () {
    final bits = _dynamicHeader([0, 0, 1, 1])
      ..code(1, 1)
      ..bits(127, 7)
      ..code(1, 1)
      ..bits(109, 7);
    expect(() => decoder.decode(_frame(bits.bytes, [])),
        throwsA(code('zlib.invalid_tree')));
  });

  test('dynamic singleton end-of-block and absent distance tree are valid', () {
    final literals = List<int>.filled(257, 0)..[256] = 1;
    final bits = _dynamicLengths(literals, [0])..code(0, 1);
    expect(decoder.decode(_frame(bits.bytes, [])), isEmpty);
  });

  test('dynamic literal-only blocks can omit all distance codes', () {
    final literals = List<int>.filled(257, 0)
      ..[65] = 1
      ..[256] = 1;
    final bits = _dynamicLengths(literals, [0]);
    for (var index = 0; index < 4; index++) {
      bits.code(0, 1);
    }
    bits.code(1, 1);
    expect(
        decoder.decode(_frame(bits.bytes, [65, 65, 65, 65])), [65, 65, 65, 65]);
  });

  test('Python zlib oracle accepts multiple unused zero-length distance codes',
      () {
    final input = _hex(
        '780105c10104000000001000000000000000000100000000000000000000000000000000000000000000800800420042');
    expect(decoder.decode(input), [65]);
  });

  test('dynamic singleton distance permits overlapping backreferences', () {
    final literals = List<int>.filled(258, 0)
      ..[65] = 1
      ..[256] = 2
      ..[257] = 2;
    final bits = _dynamicLengths(literals, [1])
      ..code(0, 1)
      ..code(3, 2)
      ..code(0, 1)
      ..code(2, 2);
    expect(
        decoder.decode(_frame(bits.bytes, [65, 65, 65, 65])), [65, 65, 65, 65]);
  });

  test('a length code cannot use an absent dynamic distance tree', () {
    final literals = List<int>.filled(258, 0)
      ..[65] = 1
      ..[256] = 2
      ..[257] = 2;
    for (final distances in [
      [0],
      [0, 0]
    ]) {
      final bits = _dynamicLengths(literals, distances)
        ..code(0, 1)
        ..code(3, 2);
      expect(() => decoder.decode(_frame(bits.bytes, [65])),
          throwsA(code('zlib.invalid_distance')));
    }
  });

  test('unused singleton Huffman branches are rejected', () {
    final literals = List<int>.filled(257, 0)..[256] = 1;
    final bits = _dynamicLengths(literals, [0])..code(1, 1);
    expect(() => decoder.decode(_frame(bits.bytes, [])),
        throwsA(code('zlib.invalid_tree')));
  });

  test('literal and distance trees reject oversubscription and incompleteness',
      () {
    final completeLiterals = List<int>.filled(257, 0)
      ..[65] = 1
      ..[256] = 1;
    final incompleteLiterals = List<int>.filled(257, 0)
      ..[65] = 2
      ..[256] = 2;
    final oversubscribedLiterals = List<int>.filled(257, 0)
      ..[65] = 1
      ..[66] = 1
      ..[256] = 1;
    for (final trees in [
      (incompleteLiterals, [1]),
      (oversubscribedLiterals, [1]),
      (completeLiterals, [2]),
      (completeLiterals, [2, 2]),
      (completeLiterals, [1, 1, 1]),
    ]) {
      final bits = _dynamicLengths(trees.$1, trees.$2);
      expect(() => decoder.decode(_frame(bits.bytes, [])),
          throwsA(code('zlib.invalid_tree')));
    }
  });

  test('reserved dynamic distance symbols are rejected when consumed', () {
    final literals = List<int>.filled(258, 0)
      ..[65] = 1
      ..[256] = 2
      ..[257] = 2;
    final distances = List<int>.filled(31, 0)..[30] = 1;
    final bits = _dynamicLengths(literals, distances)
      ..code(0, 1)
      ..code(3, 2)
      ..code(0, 1);
    expect(() => decoder.decode(_frame(bits.bytes, [65])),
        throwsA(code('zlib.invalid_distance')));
  });

  test('maximum distance reads the correct bytes after a complete ring wrap',
      () {
    final initial =
        List.generate(32768, (index) => ((index * 73) ^ (index >> 8)) & 255);
    final bits = _Bits()..bits(0, 3);
    bits.align();
    bits.bits(initial.length, 16);
    bits.bits(initial.length ^ 65535, 16);
    for (final byte in initial) {
      bits.bits(byte, 8);
    }
    bits.bits(3, 3);
    bits.fixed(285);
    bits.code(29, 5);
    bits.bits(8191, 13);
    bits.fixed(256);
    final expected = [...initial, ...initial.take(258)];
    expect(decoder.decode(_frame(bits.bytes, expected)), expected);
  });

  test('the smallest declared window accepts overlapping length 258 copies',
      () {
    final bits = _Bits()
      ..bits(3, 3)
      ..fixed(65)
      ..fixed(285)
      ..code(0, 5)
      ..fixed(256);
    final expected = List<int>.filled(259, 65);
    expect(decoder.decode(_frame(bits.bytes, expected, cmf: 0x08)), expected);
  });
}

_Bits _dynamicLengths(List<int> literals, List<int> distances) {
  final bits = _Bits()
    ..bits(5, 3)
    ..bits(literals.length - 257, 5)
    ..bits(distances.length - 1, 5)
    ..bits(14, 4);
  for (final symbol in [
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
    1
  ]) {
    bits.bits(symbol <= 3 ? 2 : 0, 3);
  }
  for (final length in [...literals, ...distances]) {
    bits.code(length, 2);
  }
  return bits;
}

_Bits _dynamicHeader(List<int> lengths) {
  final bits = _Bits()
    ..bits(5, 3)
    ..bits(0, 5)
    ..bits(0, 5)
    ..bits(0, 4);
  for (final length in lengths) {
    bits.bits(length, 3);
  }
  return bits;
}

List<int> _frame(List<int> raw, List<int> output, {int cmf = 0x78}) {
  final flag = (31 - ((cmf * 256) % 31)) % 31;
  var a = 1;
  var b = 0;
  for (final byte in output) {
    a = (a + byte) % 65521;
    b = (b + a) % 65521;
  }
  final adler = b * 65536 + a;
  return [
    cmf,
    flag,
    ...raw,
    (adler >> 24) & 255,
    (adler >> 16) & 255,
    (adler >> 8) & 255,
    adler & 255
  ];
}

List<int> _hex(String value) => [
      for (var offset = 0; offset < value.length; offset += 2)
        int.parse(value.substring(offset, offset + 2), radix: 16)
    ];

final class _Bits {
  final _bytes = <int>[];
  int _count = 0;

  void bits(int value, int count) {
    for (var index = 0; index < count; index++) {
      _bit((value >> index) & 1);
    }
  }

  void code(int value, int count) {
    for (var index = count - 1; index >= 0; index--) {
      _bit((value >> index) & 1);
    }
  }

  void fixed(int symbol) {
    if (symbol <= 143) {
      code(0x30 + symbol, 8);
    } else if (symbol <= 255) {
      code(0x190 + symbol - 144, 9);
    } else if (symbol <= 279) {
      code(symbol - 256, 7);
    } else {
      code(0xc0 + symbol - 280, 8);
    }
  }

  void _bit(int bit) {
    if (_count % 8 == 0) _bytes.add(0);
    _bytes[_count ~/ 8] |= bit << (_count % 8);
    _count++;
  }

  void align() {
    while (_count % 8 != 0) {
      _bit(0);
    }
  }

  List<int> get bytes {
    align();
    return List.unmodifiable(_bytes);
  }
}

final class _UnreadableBytes extends ListBase<int> {
  _UnreadableBytes(this._length);
  final int _length;
  int reads = 0;
  @override
  int get length => _length;
  @override
  set length(int value) => throw UnsupportedError('length');
  @override
  int operator [](int index) {
    reads++;
    throw StateError('Input quota must run before any byte read.');
  }

  @override
  void operator []=(int index, int value) => throw UnsupportedError('write');
}
