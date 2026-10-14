import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

List<int> _packed(int value) {
  if (value == 0) return [0];
  if (value > 0 && value < 123) return [value + 5];
  if (value < 0 && value > -124) return [(value - 5) & 255];
  var width = 1;
  while (value >= (1 << (width * 8)) || value < -(1 << (width * 8))) {
    width++;
  }
  return [
    value >= 0 ? width : (-width) & 255,
    for (var i = 0; i < width; i++) (value >> (i * 8)) & 255
  ];
}

List<int> _integer(int value) => [0x69, ..._packed(value)];
List<int> _symbol(String value) =>
    [0x3a, ..._packed(utf8.encode(value).length), ...utf8.encode(value)];
List<int> _string(String value) =>
    [0x22, ..._packed(utf8.encode(value).length), ...utf8.encode(value)];
List<int> _hash(List<(List<int>, List<int>)> pairs,
        {List<int>? defaultValue}) =>
    [
      defaultValue == null ? 0x7b : 0x7d,
      ..._packed(pairs.length),
      for (final pair in pairs) ...[...pair.$1, ...pair.$2],
      if (defaultValue != null) ...defaultValue,
    ];
List<int> _object(List<(List<int>, List<int>)> fields,
        {String className = 'GameData::MapMetadata'}) =>
    [
      0x6f,
      ..._symbol(className),
      ..._packed(fields.length),
      for (final field in fields) ...[...field.$1, ...field.$2],
    ];
List<int> _record(
        {List<int>? id,
        List<int>? snap = const [0x54],
        List<(List<int>, List<int>)> extra = const []}) =>
    _object([
      (_symbol('@id'), id ?? _integer(1)),
      if (snap != null) (_symbol('@snap_edges'), snap),
      ...extra,
    ]);
List<int> _extended(List<int> value) =>
    [0x65, ..._symbol('UnknownSemantics'), ...value];
List<int> _subclass(List<int> value) =>
    [0x43, ..._symbol('UnknownHash'), ...value];
List<int> _ivars(List<int> value) =>
    [0x49, ...value, ..._packed(1), ..._symbol('@unknown'), 0x54];
List<int> _table(List<int> record) => _hash([(_integer(1), record)]);

void main() {
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  final sourceRoot = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  late List<int> scripts;
  setUpAll(() async {
    if (scriptsPath != null) scripts = await File(scriptsPath).readAsBytes();
  });

  Future<LiteralTileFixture> fixture(List<int> root) =>
      LiteralTileFixture.create(scriptsBytes: scripts, extraFiles: {
        'Data/map_metadata.dat': [4, 8, ...root]
      });

  final bad = <String, List<int>>{
    'root array': [0x5b, 0],
    'non nil root default':
        _hash([(_integer(1), _record())], defaultValue: [0x54]),
    'decorated nil root default':
        _hash([(_integer(1), _record())], defaultValue: _extended([0x30])),
    'root extension': _extended(_table(_record())),
    'root user class': _subclass(_table(_record())),
    'root instance variables': _ivars(_table(_record())),
    'string map key': _hash([(_string('1'), _record())]),
    'decorated map key': _hash([(_extended(_integer(1)), _record())]),
    'zero map key': _hash([(_integer(0), _record(id: _integer(0)))]),
    'negative map key': _hash([(_integer(-1), _record(id: _integer(-1)))]),
    'oversized map key':
        _hash([(_integer(2147483648), _record(id: _integer(2147483648)))]),
    'duplicate map key':
        _hash([(_integer(1), _record()), (_integer(1), _record())]),
    'wrong record kind': _table(_hash([])),
    'class symbol extension': _table([
      0x6f,
      ..._extended(_symbol('GameData::MapMetadata')),
      ..._packed(2),
      ..._symbol('@id'),
      ..._integer(1),
      ..._symbol('@snap_edges'),
      0x54
    ]),
    'class symbol ivars': _table([
      0x6f,
      ..._ivars(_symbol('GameData::MapMetadata')),
      ..._packed(2),
      ..._symbol('@id'),
      ..._integer(1),
      ..._symbol('@snap_edges'),
      0x54
    ]),
    'wrong record class': _table(
        _object([(_symbol('@id'), _integer(1))], className: 'UnknownMetadata')),
    'record extension': _table(_extended(_record())),
    'unknown record variable': _table(_record(extra: [
      (_symbol('@unknown'), [0x54])
    ])),
    'duplicate record variable': _table(_record(extra: [
      (_symbol('@snap_edges'), [0x46])
    ])),
    'decorated variable name': _table(_object([
      (_symbol('@id'), _integer(1)),
      (_extended(_symbol('@snap_edges')), [0x54])
    ])),
    'missing identity': _table(_object([
      (_symbol('@snap_edges'), [0x54])
    ])),
    'wrong identity kind': _table(_record(id: _string('1'))),
    'different identity': _table(_record(id: _integer(2))),
    'decorated identity': _table(_record(id: _extended(_integer(1)))),
    'integer SnapEdges': _table(_record(snap: _integer(1))),
    'decorated boolean SnapEdges': _table(_record(snap: _extended([0x54]))),
    'decorated nil SnapEdges': _table(_record(snap: _extended([0x30]))),
    'decorated known text': _table(
        _record(extra: [(_symbol('@real_name'), _extended(_string('Name')))])),
    'unknown ivar on known text': _table(
        _record(extra: [(_symbol('@real_name'), _ivars(_string('Name')))])),
    'decorated nested known value': _table(_record(extra: [
      (_symbol('@flags'), [0x5b, ..._packed(1), ..._extended(_string('flag'))])
    ])),
    'decorated text encoding key': _table(_record(extra: [
      (
        _symbol('@real_name'),
        [
          0x49,
          ..._string('Name'),
          ..._packed(1),
          ..._extended(_symbol('E')),
          0x54
        ]
      )
    ])),
    'decorated text encoding value': _table(_record(extra: [
      (
        _symbol('@real_name'),
        [
          0x49,
          ..._string('Name'),
          ..._packed(1),
          ..._symbol('E'),
          ..._extended([0x54])
        ]
      )
    ])),
    'invalid unselected record': _hash([
      (_integer(1), _record()),
      (_integer(2), _extended(_record(id: _integer(2))))
    ]),
  };
  for (final entry in bad.entries) {
    test('retention rejects ${entry.key}', () async {
      final input = await fixture(entry.value);
      await expectLater(
          sourceEventMapRetentionPolicy(
              source: input.source,
              files: input.files,
              nativeMapIds: {1: 'native-one'}),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'events.retention.metadata')));
    }, skip: scriptsPath == null);
  }

  test('plain metadata accepts absent nil false true and a nil hash default',
      () async {
    for (final snap in [
      null,
      <int>[0x30],
      <int>[0x46],
      <int>[0x54]
    ]) {
      final input = await fixture(
          _hash([(_integer(1), _record(snap: snap))], defaultValue: [0x30]));
      final policy = await sourceEventMapRetentionPolicy(
          source: input.source,
          files: input.files,
          nativeMapIds: {1: 'native-one', 2: 'native-two'});
      expect(policy.clampViewportToMapIds,
          snap != null && snap.single == 0x54 ? {'native-one'} : isEmpty);
      expect(policy.viewportWidthTiles, 16);
      expect(policy.viewportHeightTiles, 12);
      expect(policy.marginTiles, 6);
    }
  }, skip: scriptsPath == null);

  test('known text accepts only its canonical Ruby UTF8 encoding attribute',
      () async {
    final text = [
      0x49,
      ..._string('Name'),
      ..._packed(1),
      ..._symbol('E'),
      0x54
    ];
    final input =
        await fixture(_table(_record(extra: [(_symbol('@real_name'), text)])));
    final policy = await sourceEventMapRetentionPolicy(
        source: input.source,
        files: input.files,
        nativeMapIds: {1: 'native-one'});
    expect(policy.clampViewportToMapIds, {'native-one'});
  }, skip: scriptsPath == null);

  test('sealed original map metadata remains valid', () async {
    final bytes = await File('$sourceRoot/Data/map_metadata.dat').readAsBytes();
    final input = await LiteralTileFixture.create(
        scriptsBytes: scripts, extraFiles: {'Data/map_metadata.dat': bytes});
    final policy = await sourceEventMapRetentionPolicy(
        source: input.source,
        files: input.files,
        nativeMapIds: {98: 'native-98', 100: 'native-100', 102: 'native-102'});
    expect(policy.clampViewportToMapIds, isEmpty);
  }, skip: scriptsPath == null || sourceRoot == null);
}
