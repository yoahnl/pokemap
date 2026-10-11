import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

final class _GuardedBytes extends ListBase<int> {
  _GuardedBytes(this._bytes, {required this.forbiddenFrom});

  final List<int> _bytes;
  final int forbiddenFrom;
  final List<int> reads = [];

  @override
  int get length => _bytes.length;

  @override
  set length(int value) => throw UnsupportedError('Read-only test input');

  @override
  int operator [](int index) {
    reads.add(index);
    if (index >= forbiddenFrom) {
      throw StateError('Decoder read a payload after its quota was exhausted');
    }
    return _bytes[index];
  }

  @override
  void operator []=(int index, int value) =>
      throw UnsupportedError('Read-only test input');
}

List<int> _fromHex(String hex) => [
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ];

String _doubleBits(double value) {
  final data = ByteData(8)..setFloat64(0, value, Endian.little);
  return data.buffer
      .asUint8List()
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

List<int> _packed(int value) {
  if (value == 0) return [0];
  if (value > 0 && value < 123) return [value + 5];
  if (value < 0 && value > -124) return [(value - 5) & 255];
  var width = 1;
  if (value > 0) {
    while (value >= (1 << (8 * width))) {
      width++;
    }
    return [width, for (var i = 0; i < width; i++) (value >> (8 * i)) & 255];
  }
  while (value < -(1 << (8 * width))) {
    width++;
  }
  return [
    (-width) & 255,
    for (var i = 0; i < width; i++) (value >> (8 * i)) & 255
  ];
}

List<int> _marshal(List<int> body) => [4, 8, ...body];
List<int> _integer(int value) => [0x69, ..._packed(value)];
List<int> _symbol(String name) => _rawSymbol(utf8.encode(name));
List<int> _rawSymbol(List<int> bytes) =>
    [0x3a, ..._packed(bytes.length), ...bytes];
List<int> _string(List<int> bytes) =>
    [0x22, ..._packed(bytes.length), ...bytes];
List<int> _text(String text) => _string(utf8.encode(text));
List<int> _array(List<List<int>> elements) => [
      0x5b,
      ..._packed(elements.length),
      for (final element in elements) ...element,
    ];
List<int> _link(int id) => [0x40, ..._packed(id)];
List<int> _symbolLink(int id) => [0x3b, ..._packed(id)];
List<int> _userDefined(String name, List<int> payload) => [
      0x75,
      ..._symbol(name),
      ..._packed(payload.length),
      ...payload,
    ];
List<int> _object(String name, List<(String, List<int>)> variables) => [
      0x6f,
      ..._symbol(name),
      ..._packed(variables.length),
      for (final variable in variables) ...[
        ..._symbol(variable.$1),
        ...variable.$2,
      ],
    ];
List<int> _ivar(List<int> value, List<(String, List<int>)> variables) => [
      0x49,
      ...value,
      ..._packed(variables.length),
      for (final variable in variables) ...[
        ..._symbol(variable.$1),
        ...variable.$2,
      ],
    ];
List<int> _hash(List<(List<int>, List<int>)> pairs,
        {List<int>? defaultValue}) =>
    [
      defaultValue == null ? 0x7b : 0x7d,
      ..._packed(pairs.length),
      for (final pair in pairs) ...[...pair.$1, ...pair.$2],
      if (defaultValue != null) ...defaultValue,
    ];
List<int> _floating(String value) =>
    [0x66, ..._packed(value.length), ...ascii.encode(value)];

MarshalDocument _decode(List<int> body,
        {MarshalDecodeLimits limits = const MarshalDecodeLimits()}) =>
    const MarshalDecoder().decode(_marshal(body),
        limits: limits, sourcePath: 'Data/Fixture.rxdata');
MarshalNode _root(List<int> body) {
  final document = _decode(body);
  return document.node(document.rootId);
}

Matcher _binaryError(String code, {int? offset}) => isA<BinaryDecodeError>()
    .having((error) => error.code, 'code', code)
    .having((error) => error.location.sourcePath, 'sourcePath',
        'Data/Fixture.rxdata')
    .having((error) => error.location.byteOffset, 'byteOffset',
        offset ?? greaterThanOrEqualTo(0))
    .having((error) => error.location.graphPath, 'graphPath', isNotEmpty);

List<int> _tablePayload(int dimensions, int x, int y, int z, List<int> cells,
    {int? count}) {
  final data = ByteData(20 + cells.length * 2);
  final fields = [dimensions, x, y, z, count ?? cells.length];
  for (var i = 0; i < fields.length; i++) {
    data.setUint32(i * 4, fields[i], Endian.little);
  }
  for (var i = 0; i < cells.length; i++) {
    data.setInt16(20 + i * 2, cells[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

SourceTable _table(List<int> payload,
        {MarshalDecodeLimits limits = const MarshalDecodeLimits()}) =>
    const TableDecoder()
        .decode(_root(_userDefined('Table', payload)), limits: limits);

List<int> _fourDoubles(List<double> values) {
  final data = ByteData(32);
  for (var i = 0; i < 4; i++) {
    data.setFloat64(i * 8, values[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  group('DEC-02 inert Marshal graph', () {
    test('decodes nil and booleans without object references', () {
      final document = _decode(_array([
        [0x30],
        [0x54],
        [0x46]
      ]));
      final elements = document.node(document.rootId).elements;
      expect(document.node(elements[0]).kind, MarshalKind.nil);
      expect(document.node(elements[1]).booleanValue, isTrue);
      expect(document.node(elements[2]).booleanValue, isFalse);
      expect(document.objectCount, 1);
      expect(document.symbolCount, 0);
      expect(document.bytesRead, 7);
    });

    for (final value in [
      -2147483648,
      -65537,
      -65536,
      -257,
      -256,
      -150,
      -124,
      -123,
      -1,
      0,
      1,
      122,
      123,
      255,
      256,
      65535,
      65536,
      2147483647
    ]) {
      test('decodes packed fixnum $value without payload sign-bit inference',
          () {
        final node = _root(_integer(value));
        expect(node.kind, MarshalKind.integer);
        expect(node.integerValue, BigInt.from(value));
      });
    }

    test('preserves positive bignum words beyond JavaScript precision', () {
      final node =
          _root([0x6c, 0x2b, ..._packed(4), 1, 0, 0, 0, 0, 0, 0, 0x80]);
      expect(node.kind, MarshalKind.bigInteger);
      expect(node.integerValue, (BigInt.one << 63) + BigInt.one);
    });

    test('preserves negative bignum words', () {
      final node = _root(
          [0x6c, 0x2d, ..._packed(3), 0x34, 0x12, 0x78, 0x56, 0xbc, 0x9a]);
      expect(node.integerValue, -BigInt.parse('9abc56781234', radix: 16));
    });

    test('keeps finite floats and negative zero exact', () {
      expect(_root(_floating('1.25e2')).floatValue, 125.0);
      final negativeZero = _root(_floating('-0')).floatValue!;
      expect(negativeZero, 0.0);
      expect(negativeZero.isNegative, isTrue);
    });

    test('keeps non-finite floats inert instead of passing through JSON', () {
      expect(_root(_floating('nan')).floatValue!.isNaN, isTrue);
      expect(_root(_floating('inf')).floatValue, double.infinity);
      expect(_root(_floating('-inf')).floatValue, double.negativeInfinity);
    });

    test('restores the exact Ruby 1.8 Marshal 4.8 binary mantissa suffix', () {
      final document = const MarshalDecoder().decode(
          _fromHex('0408661b302e313030303030303030303030303030303100999a'));
      final value = document.node(document.rootId).floatValue!;
      expect(value, 0.1);
      expect(_doubleBits(value), '9a9999999999b93f');
    });

    test('restores a negative Ruby 1.8 binary mantissa suffix exactly', () {
      final document = const MarshalDecoder().decode(
          _fromHex('0408661c2d302e313030303030303030303030303030303100999a'));
      final value = document.node(document.rootId).floatValue!;
      expect(value, -0.1);
      expect(_doubleBits(value), '9a9999999999b9bf');
    });

    for (final (name, hex, bits) in [
      (
        'minimum normal plus one ULP',
        '0408661f322e32323530373338353835303732303139652d333038000001',
        '0100000000001000'
      ),
      (
        'maximum subnormal',
        '0408661f322e32323530373338353835303732303039652d33303800fffe',
        'ffffffffffff0f00'
      ),
      (
        'one-byte subnormal suffix',
        '0408661e342e30373432333139343136373637383139652d3331320080',
        '34120000c0000000'
      ),
      (
        'maximum finite',
        '0408661f312e37393736393331333438363233313537652b33303800ffff',
        'ffffffffffffef7f'
      ),
    ]) {
      test('restores exact Ruby 1.8 bits for $name', () {
        final document = const MarshalDecoder().decode(_fromHex(hex));
        expect(_doubleBits(document.node(document.rootId).floatValue!), bits);
      });
    }

    test('uses independent zero-based symbol references', () {
      final document = _decode(_array(
          [_symbol('alpha'), _symbolLink(0), _symbol('beta'), _symbolLink(1)]));
      final elements = document.node(document.rootId).elements;
      expect(elements[1], elements[0]);
      expect(elements[3], elements[2]);
      expect(document.node(elements[0]).name, 'alpha');
      expect(document.symbolCount, 2);
      expect(document.objectCount, 1);
    });

    test('preserves shared string identity and a cycle to the root', () {
      final document = _decode(_array([_text('shared'), _link(1), _link(0)]));
      final elements = document.node(document.rootId).elements;
      expect(elements[1], elements[0]);
      expect(elements[2], document.rootId);
      expect(document.objectCount, 2);
      expect(document.nodes.length, 2);
    });

    test('does not merge equal strings with distinct Marshal identities', () {
      final document = _decode(_array([_text('same'), _text('same')]));
      final elements = document.node(document.rootId).elements;
      expect(elements[0], isNot(elements[1]));
      expect(document.objectCount, 3);
    });

    test('registers an object before reading its self-referencing attributes',
        () {
      final document = _decode(
          _object('RPG::Map', [('@self', _link(0)), ('@width', _integer(3))]));
      final node = document.node(document.rootId);
      expect(node.kind, MarshalKind.object);
      expect(node.className, 'RPG::Map');
      expect(document.node(node.instanceVariables[0].key).name, '@self');
      expect(node.instanceVariables[0].value, document.rootId);
      expect(document.node(node.instanceVariables[1].value).integerValue,
          BigInt.from(3));
    });

    test('keeps ordered arbitrary hash keys and its default value', () {
      final document = _decode(_hash(
          [(_integer(7), _text('seven')), (_symbol('key'), _integer(8))],
          defaultValue: _integer(-1)));
      final node = document.node(document.rootId);
      expect(node.kind, MarshalKind.hash);
      expect(document.node(node.pairs[0].key).integerValue, BigInt.from(7));
      expect(document.node(node.pairs[1].key).name, 'key');
      expect(document.node(node.defaultValue!).integerValue, BigInt.from(-1));
    });

    test('allows a hash value to reference its own hash', () {
      final document = _decode(_hash([(_integer(1), _link(0))]));
      expect(
          document.node(document.rootId).pairs.single.value, document.rootId);
    });

    test('registers user-marshal state before a reference to itself', () {
      final document =
          _decode([0x55, ..._symbol('HostileMarshalLoad'), ..._link(0)]);
      final node = document.node(document.rootId);
      expect(node.kind, MarshalKind.userMarshal);
      expect(node.className, 'HostileMarshalLoad');
      expect(node.elements.single, document.rootId);
    });

    test('preserves unknown user-defined payload without a class resolver', () {
      final node = _root(_userDefined('Kernel::UntrustedLoad', [0, 255, 127]));
      expect(node.kind, MarshalKind.userDefined);
      expect(node.className, 'Kernel::UntrustedLoad');
      expect(node.bytes, [0, 255, 127]);
    });

    test('preserves the Ruby Iu registration order around encoding objects',
        () {
      final document = const MarshalDecoder().decode(
          _fromHex(
              '04085b0849753a064c06e9063a0d656e636f64696e67220f49534f2d383835392d3140074922097461696c063a064554'),
          sourcePath: 'controlled-ruby-iu-fixture');
      final elements = document.node(document.rootId).elements;
      expect(elements[0], elements[1]);
      final payload = document.node(elements[0]);
      expect(payload.kind, MarshalKind.userDefined);
      expect(payload.className, 'L');
      expect(payload.bytes, [0xe9]);
      expect(payload.text().text, 'é');
      expect(payload.text().encoding, 'ISO-8859-1');
      expect(document.node(elements[2]).text().text, 'tail');
      expect(document.objectCount, 4);
    });

    test('keeps regexp bytes and option flags without compiling a regexp', () {
      final source = ascii.encode(r'(a+)+$');
      final node = _root([0x2f, ..._packed(source.length), ...source, 5]);
      expect(node.kind, MarshalKind.regexp);
      expect(node.bytes, source);
      expect(node.regexpFlags, 5);
    });

    for (final tag in [0x63, 0x6d, 0x4d]) {
      test('keeps class or module tag $tag as an inert name', () {
        final name = ascii.encode('Hostile::Constant');
        final node = _root([tag, ..._packed(name.length), ...name]);
        expect(
            node.kind,
            tag == 0x63
                ? MarshalKind.classReference
                : MarshalKind.moduleReference);
        expect(node.name, 'Hostile::Constant');
      });
    }

    test('reads extended module symbol before its wrapped object', () {
      final node = _root([0x65, ..._symbol('HostileExtension'), ..._array([])]);
      expect(node.kind, MarshalKind.array);
      expect(node.extensions, ['HostileExtension']);
    });

    test('preserves user-class decoration without instantiating a class', () {
      final node =
          _root([0x43, ..._symbol('HostileString'), ..._text('inert')]);
      expect(node.kind, MarshalKind.string);
      expect(node.userClass, 'HostileString');
      expect(node.text().text, 'inert');
    });

    test('preserves struct members as symbol-to-value pairs', () {
      final document = _decode([
        0x53,
        ..._symbol('Point'),
        ..._packed(2),
        ..._symbol('x'),
        ..._integer(3),
        ..._symbol('y'),
        ..._integer(2)
      ]);
      final node = document.node(document.rootId);
      expect(node.kind, MarshalKind.struct);
      expect(node.className, 'Point');
      expect(document.node(node.pairs[0].key).name, 'x');
      expect(document.node(node.pairs[1].value).integerValue, BigInt.from(2));
    });

    test('registers inert data object before reading its state', () {
      final document = _decode([0x64, ..._symbol('HostileData'), ..._link(0)]);
      final node = document.node(document.rootId);
      expect(node.kind, MarshalKind.data);
      expect(node.className, 'HostileData');
      expect(node.elements.single, document.rootId);
    });

    test('defensively copies input and exposes immutable graph collections',
        () {
      final bytes = _marshal(_array([
        _ivar(_text('safe'), [('@extra', _integer(1))])
      ]));
      final document = const MarshalDecoder().decode(bytes);
      final node =
          document.node(document.node(document.rootId).elements.single);
      bytes.fillRange(0, bytes.length, 0);
      expect(node.text().text, 'safe');
      expect(() => document.nodes.clear(), throwsUnsupportedError);
      expect(() => document.node(document.rootId).elements.clear(),
          throwsUnsupportedError);
      expect(() => node.bytes![0] = 0, throwsUnsupportedError);
      expect(() => node.instanceVariables.clear(), throwsUnsupportedError);
      expect(() => node.text().bytes.clear(), throwsUnsupportedError);
      expect(() => node.extensions.clear(), throwsUnsupportedError);
    });
  });

  group('DEC-03 callback canary', () {
    test('decodes a controlled Ruby dump without calling _load or marshal_load',
        () {
      final temporary =
          Directory.systemTemp.createTempSync('avelune-ac03-canary-');
      try {
        final canary = File('${temporary.path}/callback-called');
        final generated = Process.runSync(
            'ruby',
            [
              '-e',
              r'''
class ConverterHostileLoad
  def _dump(depth)
    "payload"
  end
  def self._load(payload)
    File.write(ENV.fetch("AVELUNE_TEST_CANARY"), "_load")
    new
  end
end
class ConverterHostileMarshal
  def marshal_dump
    [self]
  end
  def marshal_load(state)
    File.write(ENV.fetch("AVELUNE_TEST_CANARY"), "marshal_load")
  end
end
STDOUT.binmode
STDOUT.write(Marshal.dump([ConverterHostileLoad.new, ConverterHostileMarshal.new]))
'''
            ],
            environment: {'AVELUNE_TEST_CANARY': canary.path},
            stdoutEncoding: null);
        expect(generated.exitCode, 0, reason: generated.stderr.toString());
        expect(canary.existsSync(), isFalse);
        final document = const MarshalDecoder().decode(
            generated.stdout as List<int>,
            sourcePath: 'controlled-ruby-fixture');
        final root = document.node(document.rootId);
        final userDefined = document.node(root.elements[0]);
        final userMarshal = document.node(root.elements[1]);
        expect(userDefined.className, 'ConverterHostileLoad');
        expect(userDefined.kind, MarshalKind.userDefined);
        expect(userMarshal.className, 'ConverterHostileMarshal');
        expect(userMarshal.kind, MarshalKind.userMarshal);
        expect(document.node(userMarshal.elements.single).elements.single,
            root.elements[1]);
        expect(canary.existsSync(), isFalse);
      } finally {
        temporary.deleteSync(recursive: true);
      }
    });
  });

  group('DEC-04 malformed binary and quotas', () {
    for (final bytes in <List<int>>[
      [],
      [4],
      [4, 8]
    ]) {
      test('localizes truncated input ${bytes.length}', () {
        expect(
            () => const MarshalDecoder()
                .decode(bytes, sourcePath: 'Data/Fixture.rxdata'),
            throwsA(_binaryError('marshal.truncated', offset: bytes.length)));
      });
    }

    for (final version in <List<int>>[
      [3, 8],
      [4, 7],
      [4, 9]
    ]) {
      test('refuses unsupported version $version', () {
        expect(
            () => const MarshalDecoder()
                .decode([...version, 0x30], sourcePath: 'Data/Fixture.rxdata'),
            throwsA(_binaryError('marshal.invalid_version')));
      });
    }

    test('refuses trailing bytes after one root object', () {
      expect(() => _decode([0x30, 0x30]),
          throwsA(_binaryError('marshal.trailing_bytes', offset: 3)));
    });

    test('reports the source path and byte of an unknown tag', () {
      expect(
          () => _decode(_array([
                [0x30],
                [0x7f]
              ])),
          throwsA(_binaryError('marshal.unsupported_tag', offset: 5)));
    });

    for (final id in [-1, 0, 1]) {
      test('refuses object reference $id before registration', () {
        expect(() => _decode(_link(id)),
            throwsA(_binaryError('marshal.invalid_reference')));
      });
      test('refuses symbol reference $id before registration', () {
        expect(() => _decode(_symbolLink(id)),
            throwsA(_binaryError('marshal.invalid_symbol')));
      });
    }

    test('does not confuse an object reference with a symbol reference', () {
      expect(() => _decode(_array([_symbol('onlySymbol'), _link(1)])),
          throwsA(_binaryError('marshal.invalid_reference')));
      expect(() => _decode(_array([_text('onlyString'), _symbolLink(0)])),
          throwsA(_binaryError('marshal.invalid_symbol')));
    });

    test('refuses negative byte-sequence lengths before allocation', () {
      expect(() => _decode([0x22, ..._packed(-1)]),
          throwsA(_binaryError('marshal.invalid_length')));
    });

    test('refuses a claimed string length beyond remaining bytes', () {
      expect(() => _decode([0x22, ..._packed(8), 0x61]),
          throwsA(_binaryError('marshal.truncated')));
    });

    test('refuses incomplete packed integer payload', () {
      expect(() => _decode([0x69, 4, 1, 2, 3]),
          throwsA(_binaryError('marshal.truncated')));
    });

    test('refuses an invalid floating-point token', () {
      expect(() => _decode(_floating('12garbage')),
          throwsA(_binaryError('marshal.invalid_float')));
    });

    test('refuses a binary mantissa suffix on a non-finite float', () {
      final payload = [...ascii.encode('nan'), 0, 0x99, 0x9a];
      expect(() => _decode([0x66, ..._packed(payload.length), ...payload]),
          throwsA(_binaryError('marshal.invalid_float')));
    });

    test('localizes a truncated legacy binary mantissa payload', () {
      final bytes =
          _fromHex('0408661b302e31303030303030303030303030303030310099');
      expect(
          () => const MarshalDecoder()
              .decode(bytes, sourcePath: 'Data/Fixture.rxdata'),
          throwsA(_binaryError('marshal.truncated')));
    });

    test('refuses unknown bignum sign', () {
      expect(() => _decode([0x6c, 0x3f, ..._packed(1), 1, 0]),
          throwsA(isA<BinaryDecodeError>()));
    });

    final quotaCases = <(String, List<int>, MarshalDecodeLimits)>[
      ('input', _array([]), const MarshalDecodeLimits(maxInputBytes: 3)),
      (
        'nodes',
        _array([
          [0x30],
          [0x30]
        ]),
        const MarshalDecodeLimits(maxNodes: 2)
      ),
      (
        'objects',
        _array([_text('x')]),
        const MarshalDecodeLimits(maxObjects: 1)
      ),
      (
        'symbols',
        _array([_symbol('a'), _symbol('b')]),
        const MarshalDecodeLimits(maxSymbols: 1)
      ),
      (
        'depth',
        _array([
          _array([
            _array([
              [0x30]
            ])
          ])
        ]),
        const MarshalDecodeLimits(maxDepth: 1)
      ),
      ('string', _text('abc'), const MarshalDecodeLimits(maxStringBytes: 2)),
      (
        'total_string',
        _array([_text('ab'), _text('cd')]),
        const MarshalDecodeLimits(maxTotalStringBytes: 3)
      ),
      (
        'container',
        _array([
          [0x30],
          [0x30]
        ]),
        const MarshalDecodeLimits(maxContainerEntries: 1)
      ),
      (
        'total_entries',
        _array([
          _array([
            [0x30]
          ]),
          _array([
            [0x30]
          ])
        ]),
        const MarshalDecodeLimits(maxTotalEntries: 2)
      ),
      (
        'big_integer',
        [0x6c, 0x2b, ..._packed(2), 1, 0, 0, 0],
        const MarshalDecodeLimits(maxBigIntegerWords: 1)
      ),
    ];
    for (final quotaCase in quotaCases) {
      test('refuses ${quotaCase.$1} quota before oversized allocation', () {
        expect(() => _decode(quotaCase.$2, limits: quotaCase.$3),
            throwsA(_binaryError('marshal.quota.${quotaCase.$1}')));
      });
    }

    test('bounds repeated references without duplicating the target graph', () {
      final document = _decode(
          _array([_array([]), for (var i = 0; i < 20; i++) _link(1)]),
          limits: const MarshalDecodeLimits(maxNodes: 2));
      final elements = document.node(document.rootId).elements;
      expect(elements, everyElement(elements.first));
      expect(document.nodes.length, 2);
      expect(document.objectCount, 2);
    });

    test('bounds the cumulative location text across short graph paths', () {
      expect(
          () => _decode(
              _array([
                _array([
                  _array([
                    [0x30]
                  ])
                ])
              ]),
              limits: const MarshalDecodeLimits(maxTotalLocationCodeUnits: 20)),
          throwsA(_binaryError('marshal.quota.locations')));
    });

    test('refuses an exhausted object quota before reading string payload', () {
      final bytes = _GuardedBytes(_marshal(_array([_text('large-payload')])),
          forbiddenFrom: 6);
      expect(
          () => const MarshalDecoder().decode(bytes,
              limits: const MarshalDecodeLimits(maxObjects: 1),
              sourcePath: 'Data/Fixture.rxdata'),
          throwsA(_binaryError('marshal.quota.objects')));
      expect(bytes.reads, everyElement(lessThan(6)));
    });

    test('refuses an exhausted symbol quota before reading symbol payload', () {
      final bytes = _GuardedBytes(
          _marshal(_array([_symbol('x'), _symbol('large-symbol-payload')])),
          forbiddenFrom: 9);
      expect(
          () => const MarshalDecoder().decode(bytes,
              limits: const MarshalDecodeLimits(maxSymbols: 1),
              sourcePath: 'Data/Fixture.rxdata'),
          throwsA(_binaryError('marshal.quota.symbols')));
      expect(bytes.reads, everyElement(lessThan(9)));
    });

    test('rejects invalid zero budgets with a localized error', () {
      expect(
          () => _decode([0x30], limits: const MarshalDecodeLimits(maxNodes: 0)),
          throwsA(_binaryError('marshal.invalid_limits')));
    });
  });

  group('DEC-06 exact strings and encoding preservation', () {
    test('keeps a binary symbol name as bytes without replacement text', () {
      final node = _root(_rawSymbol([0xff, 0xfe]));
      expect(node.kind, MarshalKind.symbol);
      expect(node.name, isNull);
      expect(node.bytes, [0xff, 0xfe]);
      expect(node.text().text, isNull);
      expect(node.text().diagnosticCode, isNotNull);
    });

    test('decodes E=true UTF-8 exactly', () {
      final node = _root(_ivar(_string(utf8.encode('Pokémon 日本')), [
        ('E', [0x54])
      ]));
      final text = node.text();
      expect(text.text, 'Pokémon 日本');
      expect(text.encoding, 'UTF-8');
      expect(text.diagnosticCode, isNull);
      expect(text.bytes, utf8.encode('Pokémon 日本'));
    });

    test('preserves invalid UTF-8 bytes with no replacement text', () {
      final text = _root(_ivar(_string([0xc3, 0x28]), [
        ('E', [0x54])
      ])).text();
      expect(text.text, isNull);
      expect(text.diagnosticCode, isNotNull);
      expect(text.bytes, [0xc3, 0x28]);
    });

    test('decodes E=false US-ASCII strictly', () {
      final text = _root(_ivar(_text('ascii'), [
        ('E', [0x46])
      ])).text();
      expect(text.text, 'ascii');
      expect(text.encoding, 'US-ASCII');
      expect(text.diagnosticCode, isNull);
    });

    test('keeps non-ASCII E=false bytes with a diagnostic', () {
      final text = _root(_ivar(_string([0xe9]), [
        ('E', [0x46])
      ])).text();
      expect(text.text, isNull);
      expect(text.bytes, [0xe9]);
      expect(text.diagnosticCode, isNotNull);
    });

    test('decodes a named ISO-8859-1 string without UTF-8 substitution', () {
      final text =
          _root(_ivar(_string([0xe9]), [('encoding', _text('ISO-8859-1'))]))
              .text();
      expect(text.text, 'é');
      expect(text.encoding, 'ISO-8859-1');
      expect(text.diagnosticCode, isNull);
    });

    test('preserves unknown named encoding and bytes', () {
      final text = _root(_ivar(
          _string([0x82, 0xa0]), [('encoding', _text('Windows-31J'))])).text();
      expect(text.text, isNull);
      expect(text.encoding, 'Windows-31J');
      expect(text.bytes, [0x82, 0xa0]);
      expect(text.diagnosticCode, 'marshal.unsupported_encoding');
    });

    test('does not pretend binary non-ASCII data is decoded text', () {
      final text = _root(
              _ivar(_string([0xff, 0x00]), [('encoding', _text('ASCII-8BIT'))]))
          .text();
      expect(text.text, isNull);
      expect(text.bytes, [0xff, 0x00]);
      expect(text.encoding, 'ASCII-8BIT');
      expect(text.diagnosticCode, isNotNull);
    });

    test('encoding metadata does not create a new object identity', () {
      final document = _decode(_array([
        _ivar(_text('utf8'), [
          ('E', [0x54])
        ]),
        _link(1)
      ]));
      final elements = document.node(document.rootId).elements;
      expect(elements[0], elements[1]);
      expect(document.objectCount, 2);
      expect(document.node(elements[1]).text().encoding, 'UTF-8');
    });

    test('rejects encoding metadata with an invalid E value', () {
      expect(() => _decode(_ivar(_text('x'), [('E', _integer(1))])),
          throwsA(_binaryError('marshal.invalid_encoding')));
    });
  });

  group('DEC-01 Table axes and signed cells', () {
    test('decodes independent 3x2x3 values with X as fastest axis', () {
      final cells = [
        1,
        2,
        3,
        11,
        12,
        13,
        101,
        102,
        103,
        111,
        112,
        113,
        201,
        202,
        203,
        211,
        212,
        213
      ];
      final table = _table(_tablePayload(3, 3, 2, 3, cells));
      expect(table.dimensions, 3);
      expect(table.xSize, 3);
      expect(table.ySize, 2);
      expect(table.zSize, 3);
      expect(table.cellCount, 18);
      for (var z = 0; z < 3; z++) {
        for (var y = 0; y < 2; y++) {
          for (var x = 0; x < 3; x++) {
            expect(table.valueAt(x, y, z), 1 + x + 10 * y + 100 * z);
          }
        }
      }
    });

    test('decodes signed int16 endpoints and negative animation sentinels', () {
      final table = _table(_tablePayload(1, 4, 1, 1, [-32768, -1, 0, 32767]));
      expect([for (var x = 0; x < 4; x++) table.valueAt(x, 0, 0)],
          [-32768, -1, 0, 32767]);
    });

    test('preserves declared three dimensions with unit axis sizes', () {
      final table = _table(_tablePayload(3, 1, 1, 1, [7]));
      expect(table.dimensions, 3);
      expect(table.valueAt(0, 0, 0), 7);
    });

    test('supports a zero-sized active axis without allocating cells', () {
      final table = _table(_tablePayload(1, 0, 1, 1, []));
      expect(table.cellCount, 0);
      expect(() => table.valueAt(0, 0, 0), throwsRangeError);
    });

    test('rejects coordinates beyond each axis and negative coordinates', () {
      final table = _table(_tablePayload(3, 1, 1, 1, [7]));
      for (final point in [
        (1, 0, 0),
        (0, 1, 0),
        (0, 0, 1),
        (-1, 0, 0),
        (0, -1, 0),
        (0, 0, -1)
      ]) {
        expect(() => table.valueAt(point.$1, point.$2, point.$3),
            throwsRangeError);
      }
    });

    test('rejects a non-Table payload', () {
      expect(
          () => const TableDecoder()
              .decode(_root(_userDefined('Unknown', List.filled(20, 0)))),
          throwsA(_binaryError('table.invalid_type')));
    });

    test('rejects a Table name serialized as an ordinary object', () {
      expect(() => const TableDecoder().decode(_root(_object('Table', []))),
          throwsA(_binaryError('table.invalid_type')));
    });

    test('rejects a header shorter than five uint32 fields', () {
      expect(() => _table(List.filled(19, 0)),
          throwsA(_binaryError('table.header')));
    });

    for (final dimensions in [0, 4]) {
      test('rejects unsupported dimension count $dimensions', () {
        expect(() => _table(_tablePayload(dimensions, 1, 1, 1, [1])),
            throwsA(_binaryError('table.dimensions')));
      });
    }

    test('rejects inconsistent inactive axes', () {
      expect(() => _table(_tablePayload(1, 1, 2, 1, [1, 2])),
          throwsA(_binaryError('table.dimensions')));
      expect(() => _table(_tablePayload(2, 1, 1, 2, [1, 2])),
          throwsA(_binaryError('table.dimensions')));
    });

    test('rejects a cell count that contradicts the dimensions', () {
      expect(() => _table(_tablePayload(3, 3, 2, 3, [1], count: 1)),
          throwsA(_binaryError('table.length')));
    });

    test('rejects missing and trailing cell bytes', () {
      final payload = _tablePayload(1, 1, 1, 1, [7]);
      expect(() => _table(payload.sublist(0, payload.length - 1)),
          throwsA(_binaryError('table.length')));
      expect(
          () => _table([...payload, 0]), throwsA(_binaryError('table.length')));
    });

    test('rejects huge dimensions before an overflowing allocation', () {
      expect(
          () => _table(_tablePayload(3, 0xffffffff, 0xffffffff, 0xffffffff, [],
              count: 0)),
          throwsA(isA<BinaryDecodeError>()));
    });

    test('checks the Table cell quota before allocation', () {
      expect(
          () => _table(_tablePayload(1, 3, 1, 1, [1, 2, 3]),
              limits: const MarshalDecodeLimits(maxTableCells: 2)),
          throwsA(_binaryError('table.quota')));
    });

    test('checks the product quota even when each positive axis fits', () {
      expect(
          () => _table(_tablePayload(3, 100, 100, 100, [], count: 1000000),
              limits: const MarshalDecodeLimits(maxTableCells: 1000)),
          throwsA(_binaryError('table.quota')));
    });
  });

  group('DEC-04 known Color and Tone payloads', () {
    test('decodes Color four float64 little-endian channels', () {
      final color = const RgssColorDecoder().decode(
          _root(_userDefined('Color', _fourDoubles([1.25, 2.5, 3.75, 255]))));
      expect([color.red, color.green, color.blue, color.alpha],
          [1.25, 2.5, 3.75, 255]);
    });

    test('decodes Tone signed RGB and gray channels', () {
      final tone = const RgssToneDecoder().decode(
          _root(_userDefined('Tone', _fourDoubles([-255, 12.5, -1, 64]))));
      expect(
          [tone.red, tone.green, tone.blue, tone.gray], [-255, 12.5, -1, 64]);
    });

    test('rejects Color and Tone payloads with a wrong size', () {
      expect(
          () => const RgssColorDecoder()
              .decode(_root(_userDefined('Color', List.filled(31, 0)))),
          throwsA(isA<BinaryDecodeError>()));
      expect(
          () => const RgssToneDecoder()
              .decode(_root(_userDefined('Tone', List.filled(33, 0)))),
          throwsA(isA<BinaryDecodeError>()));
    });

    test('rejects non-finite Color and Tone channels', () {
      expect(
          () => const RgssColorDecoder().decode(_root(
              _userDefined('Color', _fourDoubles([double.nan, 0, 0, 0])))),
          throwsA(isA<BinaryDecodeError>()));
      expect(
          () => const RgssToneDecoder().decode(_root(
              _userDefined('Tone', _fourDoubles([0, double.infinity, 0, 0])))),
          throwsA(isA<BinaryDecodeError>()));
    });
  });
}
