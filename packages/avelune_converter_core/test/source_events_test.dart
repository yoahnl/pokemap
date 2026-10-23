import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

final class _RubyObject {
  _RubyObject(this.className, this.fields, {this.fieldExtensions = const {}});
  final String className;
  final Map<String, Object?> fields;
  final Map<String, String> fieldExtensions;
}

final class _RubyBytes {
  const _RubyBytes(this.bytes);
  final List<int> bytes;
}

final class _RubyUserDefined {
  const _RubyUserDefined(this.className, this.bytes);
  final String className;
  final List<int> bytes;
}

_RubyUserDefined _tone(List<double> channels) {
  final bytes = ByteData(channels.length * 8);
  for (var i = 0; i < channels.length; i++) {
    bytes.setFloat64(i * 8, channels[i], Endian.little);
  }
  return _RubyUserDefined('Tone', bytes.buffer.asUint8List());
}

_RubyObject _se({Object? name = 'Exit Door', Object? volume = 80,
        Object? pitch = 100}) =>
    _RubyObject('RPG::AudioFile',
        {'@name': name, '@volume': volume, '@pitch': pitch});

final class _RubyAnnotation {
  const _RubyAnnotation(this.value,
      {this.extension, this.userClass, this.fields = const {},
      this.fieldExtensions = const {}});
  final Object? value;
  final String? extension, userClass;
  final Map<String, Object?> fields;
  final Map<String, String> fieldExtensions;
}

final class _RubyTable {
  _RubyTable(this.x, this.y, this.z, this.cells, {this.dimensions = 3});
  final int dimensions;
  final int x;
  final int y;
  final int z;
  final List<int> cells;
}

final class _MarshalFixture {
  final _objects = HashMap<Object, int>.identity();

  List<int> dump(Object? value) => [4, 8, ..._value(value)];

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
      for (var i = 0; i < width; i++) (value >> (i * 8)) & 255,
    ];
  }

  List<int> _symbol(String value) {
    final bytes = utf8.encode(value);
    return [0x3a, ..._packed(bytes.length), ...bytes];
  }

  List<int> _value(Object? value) {
    if (value is _RubyAnnotation) {
      if (value.extension != null) {
        return [0x65, ..._symbol(value.extension!), ..._value(value.value)];
      }
      if (value.userClass != null) {
        return [0x43, ..._symbol(value.userClass!), ..._value(value.value)];
      }
      return [
        0x49,
        ..._value(value.value),
        ..._packed(value.fields.length),
        for (final entry in value.fields.entries) ...[
          if (value.fieldExtensions[entry.key] case final extension?) ...[
            0x65, ..._symbol(extension),
          ],
          ..._symbol(entry.key),
          ..._value(entry.value)
        ],
      ];
    }
    if (value == null) return [0x30];
    if (value is bool) return [value ? 0x54 : 0x46];
    if (value is int) return [0x69, ..._packed(value)];
    final prior = _objects[value];
    if (prior != null) return [0x40, ..._packed(prior)];
    _objects[value] = _objects.length;
    if (value is double) {
      final bytes = ascii.encode(value.toString());
      return [0x66, ..._packed(bytes.length), ...bytes];
    }
    if (value is String || value is _RubyBytes) {
      final bytes =
          value is String ? utf8.encode(value) : (value as _RubyBytes).bytes;
      return [0x22, ..._packed(bytes.length), ...bytes];
    }
    if (value is List) {
      return [
        0x5b,
        ..._packed(value.length),
        for (final item in value) ..._value(item)
      ];
    }
    if (value is Map) {
      return [
        0x7b,
        ..._packed(value.length),
        for (final entry in value.entries) ...[
          ..._value(entry.key),
          ..._value(entry.value)
        ],
      ];
    }
    if (value is _RubyObject) {
      return [
        0x6f,
        ..._symbol(value.className),
        ..._packed(value.fields.length),
        for (final entry in value.fields.entries) ...[
          if (value.fieldExtensions[entry.key] case final extension?) ...[
            0x65,
            ..._symbol(extension),
          ],
          ..._symbol(entry.key),
          ..._value(entry.value)
        ],
      ];
    }
    if (value is _RubyUserDefined) {
      return [
        0x75,
        ..._symbol(value.className),
        ..._packed(value.bytes.length),
        ...value.bytes
      ];
    }
    if (value is _RubyTable) {
      final data = ByteData(20 + value.cells.length * 2)
        ..setUint32(0, value.dimensions, Endian.little)
        ..setUint32(4, value.x, Endian.little)
        ..setUint32(8, value.y, Endian.little)
        ..setUint32(12, value.z, Endian.little)
        ..setUint32(16, value.cells.length, Endian.little);
      for (var i = 0; i < value.cells.length; i++) {
        data.setInt16(20 + 2 * i, value.cells[i], Endian.little);
      }
      final bytes = data.buffer.asUint8List();
      return [0x75, ..._symbol('Table'), ..._packed(bytes.length), ...bytes];
    }
    throw ArgumentError('Unsupported synthetic fixture value');
  }
}

_RubyObject _mapInfo(String name, {int parent = 0, int order = 0}) =>
    _RubyObject('RPG::MapInfo', {
      '@name': name,
      '@parent_id': parent,
      '@order': order,
      '@expanded': true,
      '@scroll_x': 4,
      '@scroll_y': 7,
    });

_RubyObject _map({
  int width = 3,
  int height = 2,
  int tileset = 1,
  _RubyTable? data,
  Map<int, Object?>? events,
}) =>
    _RubyObject('RPG::Map', {
      '@tileset_id': tileset,
      '@width': width,
      '@height': height,
      '@data': data ??
          _RubyTable(width, height, 3,
              List.generate(width * height * 3, (i) => 384 + i)),
      '@events': events ?? <int, Object?>{},
      '@autoplay_bgm': false,
      '@bgm': _RubyObject(
          'RPG::AudioFile', {'@name': '', '@volume': 80, '@pitch': 100}),
      '@autoplay_bgs': false,
      '@bgs': _RubyObject(
          'RPG::AudioFile', {'@name': '', '@volume': 80, '@pitch': 100}),
      '@encounter_list': <Object?>[],
      '@encounter_step': 30,
    });

_RubyObject _tileset({String image = 'Terrain', List<String>? autotiles}) =>
    _RubyObject('RPG::Tileset', {
      '@id': 1,
      '@name': 'Source terrain',
      '@tileset_name': image,
      '@autotile_names': autotiles ?? List.filled(7, ''),
      '@panorama_name': '',
      '@panorama_hue': 0,
      '@fog_name': '',
      '@fog_hue': 0,
      '@fog_opacity': 64,
      '@fog_blend_type': 0,
      '@fog_zoom': 200,
      '@fog_sx': 0,
      '@fog_sy': 0,
      '@battleback_name': '',
      '@passages': _RubyTable(512, 1, 1, List.generate(512, (i) => i % 16),
          dimensions: 1),
      '@priorities': _RubyTable(512, 1, 1, List.generate(512, (i) => i % 6),
          dimensions: 1),
      '@terrain_tags': _RubyTable(512, 1, 1, List.generate(512, (i) => i % 8),
          dimensions: 1),
    });

_RubyObject _command(int code, List<Object?> parameters, {int indent = 0}) =>
    _RubyObject('RPG::EventCommand',
        {'@code': code, '@indent': indent, '@parameters': parameters});

_RubyObject _moveCommand(int code, {List<Object?> parameters = const []}) =>
    _RubyObject('RPG::MoveCommand', {'@code': code, '@parameters': parameters});

_RubyObject _facingRoute() => _RubyObject('RPG::MoveRoute', {
      '@repeat': false,
      '@skippable': false,
      '@list': [_moveCommand(25), _moveCommand(0)],
    });

List<_RubyObject> _facingCommands({Object? target = 0, Object? route}) => [
      _command(209, [target, route ?? _facingRoute()]),
      _command(509, [_moveCommand(25)]),
      _command(0, []),
    ];

List<_RubyObject> _forcedRoute(List<_RubyObject> steps,
        {Object? target = 0,
        int indent = 0,
        bool repeat = false,
        bool skippable = true}) =>
    [
      _command(
          209,
          [
            target,
            _RubyObject('RPG::MoveRoute', {
              '@repeat': repeat,
              '@skippable': skippable,
              '@list': [...steps, _moveCommand(0)],
            })
          ],
          indent: indent),
      for (final step in steps) _command(509, [step], indent: indent),
    ];

List<_RubyObject> _doorTurns({bool opening = true}) => [
      _moveCommand(15, parameters: [2]),
      _moveCommand(opening ? 17 : 18),
      _moveCommand(15, parameters: [2]),
      _moveCommand(opening ? 18 : 17),
      _moveCommand(15, parameters: [2]),
      _moveCommand(opening ? 19 : 16),
      _moveCommand(15, parameters: [2]),
    ];

List<String> _doorSwitches({String literal = 's:tsOff?("A")'}) =>
    List.generate(23, (id) => id == 22 ? literal : 'Switch $id');

List<_RubyObject> _doorPages() {
  final enter = _page([
    ..._forcedRoute([
      _moveCommand(44, parameters: [_se(name: 'frlg_pcdoor', volume: 100)]),
      ..._doorTurns()
    ]),
    _command(210, []),
    ..._forcedRoute([_moveCommand(37), _moveCommand(4), _moveCommand(38)],
        target: -1),
    _command(210, []),
    _command(208, [0]),
    ..._forcedRoute(_doorTurns(opening: false)),
    _command(210, []),
    _command(223, [
      _tone([-255, -255, -255, 0]),
      6
    ]),
    _command(106, [8]),
    _command(208, [1]),
    _command(201, [0, 102, 9, 10, 8, 1]),
    _command(223, [
      _tone([0, 0, 0, 0]),
      6
    ]),
    _command(0, []),
  ], trigger: 1, character: 'OBJ_FRLG_Doors3');
  final arrive = _withCondition(
      _page([
        _command(111, [12, 'get_self.onEvent?']),
        _command(208, [0], indent: 1),
        ..._forcedRoute([
          _moveCommand(44, parameters: [_se(name: 'frlg_pcdoor', volume: 100)]),
          ..._doorTurns()
        ], indent: 1),
        _command(210, [], indent: 1),
        _command(208, [1], indent: 1),
        ..._forcedRoute([_moveCommand(1)], target: -1, indent: 1),
        _command(210, [], indent: 1),
        ..._forcedRoute(_doorTurns(opening: false).sublist(1), indent: 1),
        _command(210, [], indent: 1),
        _command(0, [], indent: 1),
        _command(412, []),
        _command(355, ['setTempSwitchOn("A")']),
        _command(0, []),
      ], trigger: 3, character: 'OBJ_FRLG_Doors3'),
      {'@switch1_valid': true, '@switch1_id': 22});
  for (final page in [enter, arrive]) {
    (page.fields['@graphic'] as _RubyObject).fields['@pattern'] = 3;
  }
  return [enter, arrive];
}

_RubyObject _changedFacingRoute(Map<String, Object?> fields) =>
    _facingRoute()..fields.addAll(fields);

_RubyObject _page(List<_RubyObject> commands,
        {int trigger = 0, String character = ''}) =>
    _RubyObject('RPG::Event::Page', {
      '@condition': _RubyObject('RPG::Event::Page::Condition', {
        '@switch1_valid': false,
        '@switch2_valid': false,
        '@variable_valid': false,
        '@self_switch_valid': false,
        '@switch1_id': 1,
        '@switch2_id': 1,
        '@variable_id': 1,
        '@variable_value': 0,
        '@self_switch_ch': 'A',
      }),
      '@graphic': _RubyObject('RPG::Event::Page::Graphic', {
        '@tile_id': 0,
        '@character_name': character,
        '@character_hue': 0,
        '@direction': 2,
        '@pattern': 0,
        '@opacity': 255,
        '@blend_type': 0,
      }),
      '@move_type': 0,
      '@move_speed': 3,
      '@move_frequency': 3,
      '@move_route': _RubyObject('RPG::MoveRoute', {
        '@repeat': true,
        '@skippable': false,
        '@list': [
          _RubyObject(
              'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})
        ],
      }),
      '@walk_anime': true,
      '@step_anime': false,
      '@direction_fix': false,
      '@through': false,
      '@always_on_top': false,
      '@trigger': trigger,
      '@list': commands,
    });

_RubyObject _event(int id, List<_RubyObject> pages, {int x = 1, int y = 1}) =>
    _RubyObject('RPG::Event',
        {'@id': id, '@name': 'Event $id', '@x': x, '@y': y, '@pages': pages});

List<int> _png() {
  final header = ByteData(13)
    ..setUint32(0, 256, Endian.big)
    ..setUint32(4, 96, Endian.big)
    ..setUint8(8, 8)
    ..setUint8(9, 6);
  return [
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    ..._pngChunk('IHDR', header.buffer.asUint8List()),
    ..._pngChunk(
        'IDAT', ZLibEncoder().convert(List.filled(96 * (1 + 256 * 4), 0))),
    ..._pngChunk('IEND', []),
  ];
}

List<int> _pngChunk(String type, List<int> payload) {
  final body = [...ascii.encode(type), ...payload];
  var crc = 0xffffffff;
  for (final byte in body) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      crc = crc & 1 == 0 ? crc >> 1 : (crc >> 1) ^ 0xedb88320;
    }
  }
  final length = ByteData(4)..setUint32(0, payload.length, Endian.big);
  final checksum = ByteData(4)..setUint32(0, crc ^ 0xffffffff, Endian.big);
  return [
    ...length.buffer.asUint8List(),
    ...body,
    ...checksum.buffer.asUint8List()
  ];
}

Map<String, List<int>> _project({
  Map<int, _RubyObject>? maps,
  Map<int, _RubyObject>? infos,
  _RubyObject? tileset,
  bool image = true,
}) {
  final sourceMaps = maps ?? {1: _map()};
  final sourceInfos =
      infos ?? {for (final id in sourceMaps.keys) id: _mapInfo('Map $id')};
  return {
    'README.md': utf8.encode('Pokemon Essentials v21.1\n'),
    'Data/MapInfos.rxdata': _MarshalFixture().dump(sourceInfos),
    'Data/Tilesets.rxdata':
        _MarshalFixture().dump([null, tileset ?? _tileset()]),
    for (final entry in sourceMaps.entries)
      'Data/Map${entry.key.toString().padLeft(3, '0')}.rxdata':
          _MarshalFixture().dump(entry.value),
    if (image) 'Graphics/Tilesets/Terrain.png': _png(),
  };
}

Sha256Hash _hash(List<int> bytes) =>
    Sha256Hash(crypto.sha256.convert(bytes).toString());

final class _Files implements SourceFilePort {
  _Files(this.bytes, this.snapshot) {
    for (final entry in snapshot.entries) {
      byId[entry.fileId] = entry.relativePath;
    }
  }
  final Map<String, List<int>> bytes;
  final SourceSnapshot snapshot;
  final byId = <ConverterId, String>{};
  final reads = <String>[];
  final replacements = <String, List<int>>{};
  void Function(String)? onRead;

  @override
  Future<List<int>> read(ConverterId fileId) async {
    final path = byId[fileId]!;
    reads.add(path);
    onRead?.call(path);
    return List<int>.from(replacements[path] ?? bytes[path]!);
  }
}

_Files _source(Map<String, List<int>> bytes,
    {bool reverse = false,
    SourceScanState state = SourceScanState.complete,
    String namespace = 'synthetic-project'}) {
  final entries = [
    for (final entry in bytes.entries)
      SourceFileEntry(
        fileId: ConverterId(
            'fixture:${base64Url.encode(utf8.encode(entry.key)).replaceAll('=', '')}'),
        relativePath: entry.key,
        kind: SourceNodeKind.file,
        byteLength: entry.value.length,
        sha256: _hash(entry.value),
        format: entry.key.endsWith('.rxdata')
            ? 'ruby-marshal'
            : entry.key.endsWith('.png')
                ? 'png'
                : 'text',
        family: entry.key.endsWith('.rxdata')
            ? 'rmxp'
            : entry.key.endsWith('.png')
                ? 'raster'
                : 'documentation',
      ),
  ];
  final snapshot = SourceSnapshot(
    logicalProjectNamespace: ConverterId(namespace),
    policyHash: _hash([1, 2, 3]),
    entries: reverse ? entries.reversed.toList() : entries,
    diagnostics: [],
    excludedPaths: [],
    profileEvidence: [
      if (bytes.containsKey('README.md'))
        SourceProfileEvidence(
            relativePath: 'README.md',
            fileHash: _hash(bytes['README.md']!),
            version: '21.1',
            line: 1,
            excerpt: 'Pokemon Essentials v21.1'),
    ],
    state: state,
  );
  return _Files(bytes, snapshot);
}

Future<NormalizedSourceProject> _normalize(_Files files,
        {SourceNormalizationLimits limits = const SourceNormalizationLimits(),
        Set<int>? selectedMapIds,
        bool includeEventSystem = false,
        ScanCancellation? cancellation}) =>
    const RmxpSourceNormalizer().normalize(
        snapshot: files.snapshot,
        files: files,
        limits: limits,
        selectedMapIds: selectedMapIds,
        includeEventSystem: includeEventSystem,
        cancellation: cancellation);

Future<NormalizedSourceProject> _events(List<_RubyObject> pages,
    {bool system = true,
    bool includeSystem = true,
    List<Object?> switches = const ['', 'Ready', 's:dangerous()'],
    List<Object?>? variables,
    List<Object?>? commonEvents,
    Map<int, _RubyObject>? extraEvents}) async {
  final data = _project(maps: {
    1: _map(events: {1: _event(1, pages), ...?extraEvents}),
    8: _map(),
  });
  if (system) {
    data['Data/System.rxdata'] = _MarshalFixture()
        .dump(_RubyObject('RPG::System', {'@switches': switches,
          '@variables': variables ?? List.filled(128, '')}));
  }
  if (commonEvents != null) {
    data['Data/CommonEvents.rxdata'] = _MarshalFixture().dump(commonEvents);
  }
  return _normalize(_source(data), includeEventSystem: includeSystem);
}

SourceEventAnalyzer _analyzer(NormalizedSourceProject project,
        {String? scriptsHash}) =>
    SourceEventAnalyzer.forProject(project,
        profile: SourceEventProfile.forProject(project,
            scriptsArchiveHash: Sha256Hash(
                scriptsHash ?? fixtureSourceInterpretationProfile.scriptsArchiveHash.value),
interpretationProfile: fixtureSourceInterpretationProfile,
));

_RubyObject _withCondition(_RubyObject page, Map<String, Object?> values) {
  (page.fields['@condition'] as _RubyObject).fields.addAll(values);
  return page;
}

_RubyObject _cutPage() => _page([
      ..._forcedRoute([_moveCommand(16)], skippable: false),
      _command(111, [12, 'pbCut']),
      _command(355, ['pbSmashThisEvent'], indent: 1),
      _command(0, [], indent: 1),
      _command(412, []),
      _command(0, []),
    ], character: 'OBJ_FRLG_Cut Tree');

Future<NormalizedSourceProject> _cutSource({
  int mapId = 37,
  int eventId = 12,
  int x = 2,
  int y = 3,
  String name = 'Garden obstacle',
  String namespace = 'synthetic-cut-garden',
  List<_RubyObject>? pages,
}) {
  final event = _event(eventId, pages ?? [_cutPage()], x: x, y: y);
  event.fields['@name'] = name;
  final data = _project(maps: {
    mapId: _map(width: 8, height: 8, events: {eventId: event}),
  });
  return _normalize(_source(data, namespace: namespace),
      includeEventSystem: true);
}

SourceEvent _cutSourceEvent(NormalizedSourceProject source) =>
    source.maps.single.map.events.single;

void _expectNoCut(SourceEventDefinition event) {
  expect(event.isQuarantined, isTrue);
  expect(
      event.pages
          .expand((page) => page.body.nodes)
          .whereType<SourceFieldObstacleProgramNode>(),
      isEmpty);
}

extension on SourceEventAnalysis {
  SourceEventDefinition requireEvent(int mapId, int eventId) {
    final event = eventAt(mapId, eventId);
    expect(event, isNotNull,
        reason: 'The preserved source event must be analyzed');
    return event!;
  }
}


_RubyObject _rockSmashPage() => _page([
      ..._forcedRoute([_moveCommand(16)], skippable: false),
      _command(111, [12, 'pbRockSmash']),
      _command(355, ['pbSmashThisEvent'], indent: 1),
      _command(355, ['pbRockSmashRandomEncounter'], indent: 1),
      _command(0, [], indent: 1),
      _command(412, []),
      _command(0, []),
    ], character: 'OBJ_FRLG_RockSmash Rock');

_RubyObject _strengthPage() => _page([
      _command(355, ['pbPushThisBoulder']),
      _command(0, []),
    ], trigger: 1, character: 'OBJ_FRLG_Strength Boulder');

void main() {
  group('authoritative single event analysis', () {
    Map<String, Object?> shape(SourceEventDefinition event) => {
      'identity': event.identity.value, 'map': event.sourceMapId,
      'event': event.sourceEventId, 'file': event.sourceFileId.value,
      'name': event.name, 'x': event.x, 'y': event.y,
      'locator': event.locator.toJson(), 'quarantined': event.isQuarantined,
      'pages': [for (final page in event.pages) {
        'source': page.sourcePage.toJson(),
        'condition': page.condition.toJson(),
        'raw': page.rawDataRef?.toJson(),
        'graphic': page.graphic == null ? null : [
          page.graphic!.characterName, page.graphic!.direction,
          page.graphic!.tileId, page.graphic!.through,
        ],
        'diagnostics': page.diagnostics.map((d) => d.toJson()).toList(),
        'nodes': [for (final node in page.body.nodes) {
          'kind': node.runtimeType.toString(), 'span': node.span.toJson(),
          if (node is SourceTextNode) 'text': node.text,
          if (node is SourceSelfSwitchNode) ...{
            'fact': node.factId, 'letter': node.letter, 'value': node.value,
          },
          if (node is SourceCommonEventCallNode) 'call': {
            'id': node.commonEventId, 'map': node.sourceMapId,
            'event': node.sourceEventId, 'span': node.body.span.toJson(),
            'text': node.body.nodes.whereType<SourceTextNode>().map((n) => n.text).toList(),
          },
          if (node is SourceUnknownNode) ...{
            'command': node.command.toJson(), 'reason': node.reason,
          },
        }],
      }],
    };
    test('matches the full pass while preserving cross-map and common-event context', () async {
      final data = _project(maps: {
        1: _map(events: {1: _event(1, [_page([
          _command(101, ['Original text']),
          _command(355, ['pbSetSelfSwitch(2, "A", true, 8)']),
          _command(117, [1]), _command(0, []),
        ]), _withCondition(_page([_command(0, [])]), {
          '@switch1_valid': true, '@switch1_id': 1,
        })])}),
        8: _map(events: {2: _event(2, [_page([_command(0, [])])])}),
      });
      data['Data/System.rxdata'] = _MarshalFixture().dump(_RubyObject('RPG::System', {
        '@switches': ['', 'Ready'], '@variables': ['', 'Counter'],
      }));
      data['Data/CommonEvents.rxdata'] = _MarshalFixture().dump([null,
        _RubyObject('RPG::CommonEvent', {'@id': 1, '@name': 'Original common',
          '@trigger': 0, '@switch_id': 1, '@list': [
            _command(101, ['Common text']), _command(0, []),
          ]})]);
      final source = await _normalize(_source(data), includeEventSystem: true);
      final analyzer = _analyzer(source), full = _analyzer(source).analyze();
      for (final event in full.events) {
        expect(shape(analyzer.analyzeEventAt(event.sourceMapId, event.sourceEventId)!), shape(event));
      }
      final selected = analyzer.analyzeEventAt(1, 1)!;
      expect(selected.isQuarantined, isFalse);
      expect(selected.pages.first.body.nodes.whereType<SourceSelfSwitchNode>().single.factId,
          analyzer.selfFactId(8, 2, 'A'));
      expect(selected.pages.first.body.nodes.whereType<SourceCommonEventCallNode>(), hasLength(1));
      expect(analyzer.analyzeEventAt(99, 1), isNull);
      expect(analyzer.analyzeEventAt(1, 99), isNull);
    });
    test('retains profile and invalid-graphic refusals from the same parser', () async {
      final page = _page([_command(355, ['unsupported()']), _command(0, [])]);
      (page.fields['@graphic'] as _RubyObject).fields['@direction'] = 9;
      final source = await _events([page]);
      for (final analyzer in [_analyzer(source), _analyzer(source, scriptsHash: '0' * 64)]) {
        final target = analyzer.analyzeEventAt(1, 1)!;
        expect(target.isQuarantined, isTrue);
        expect(shape(target), shape(analyzer.analyze().requireEvent(1, 1)));
      }
    });
    test('standard pages reuse sealed source evidence within an analysis', () async {
      final source = await _events(
        [_page([_command(101, ['Event 1']), _command(0, [])])],
        switches: ['', for (var index = 1; index <= 5000; index++) 'Switch $index'],
        extraEvents: {
          for (var id = 2; id <= 1024; id++)
            id: _event(id, [_page([
              _command(101, ['Event $id']), _command(0, []),
            ])]),
        },
      );
      final watch = Stopwatch()..start();
      final analyzer = _analyzer(source);
      final result = analyzer.analyze();
      final repeated = analyzer.analyze();
      watch.stop();
      expect(result.events, hasLength(1024));
      expect(repeated.events.map(shape).toList(), result.events.map(shape).toList());
      for (final event in result.events) {
        expect(event.pages.single.body.nodes.whereType<SourceTextNode>().single.text,
            'Event ${event.sourceEventId}');
        expect(event.isQuarantined, isFalse);
      }
      if (Platform.environment['AVELUNE_CONVERTER_EVENT_BENCHMARK'] == '1') {
        stdout.writeln('sealed_event_analysis_ms=${watch.elapsedMilliseconds}');
        expect(watch.elapsed, lessThan(const Duration(seconds: 3)),
            reason: 'Sealed names and evidence must not be decoded for every page.');
      }
    });
    test('fresh source bytes cannot reuse an earlier event result', () async {
      final original = await _events([_page([_command(101, ['Before']), _command(0, [])])]);
      final changed = await _events([_page([_command(101, ['After']), _command(0, [])])]);
      final before = _analyzer(original).analyzeEventAt(1, 1)!;
      final after = _analyzer(changed).analyzeEventAt(1, 1)!;
      expect((before.pages.single.body.nodes.single as SourceTextNode).text, 'Before');
      expect((after.pages.single.body.nodes.single as SourceTextNode).text, 'After');
      expect(after.pages.single.rawDataRef!.contentHash,
          isNot(before.pages.single.rawDataRef!.contentHash));
    });
    test('duplicate source event identities are refused before authoritative analysis', () async {
      final data = _project(maps: {1: _map(events: {
        1: _event(1, [_page([])]), 2: _event(2, [_page([])]),
      })});
      const path = 'Data/Map001.rxdata';
      final bytes = data[path]!.toList();
      final document = const MarshalDecoder().decode(bytes, sourcePath: path);
      final eventField = document.node(document.rootId).instanceVariables.singleWhere(
          (field) => document.node(field.key).text().text == '@events');
      final duplicateKey = document.node(document.node(eventField.value).pairs.last.key);
      bytes[duplicateKey.location.byteOffset + 1] = 6;
      data[path] = bytes;
      final source = await _normalize(_source(data));
      expect(source.diagnostics.map((diagnostic) => diagnostic.code),
          contains('normalization.duplicate_event_id'));
      expect(source.maps, isEmpty);
      expect(_analyzer(source).analyzeEventAt(1, 1), isNull);
    });
  });
  group('literal foreign self-switch conditions', () {
    for (final letter in ['A', 'B', 'C', 'D']) {
      test('reads the declared current-map target $letter without Ruby', () async {
        final source = await _events([_page([
          _command(111, [12, "\$game_self_switches[[@map_id, 2, '$letter']] "]),
          _command(101, ['Present'], indent: 1),
          _command(0, [], indent: 1),
          _command(412, []),
          _command(0, []),
        ])], extraEvents: {2: _event(2, [_page([])])});
        final analyzer = _analyzer(source);
        final event = analyzer.analyze().requireEvent(1, 1);
        expect(event.isQuarantined, isFalse);
        final branch = event.pages.single.body.nodes.single as SourceConditionalNode;
        expect(branch.condition.kind, SourceEventConditionKind.selfSwitch);
        expect(branch.condition.factId, analyzer.selfFactId(1, 2, letter));
        expect(branch.condition.expectedValue, isTrue);
        expect(branch.whenTrue.nodes.single, isA<SourceTextNode>());
      });
    }
    for (final script in [
      r"$game_self_switches[[8, 2, 'A']]",
      r"$game_self_switches[[@map_id, 9, 'A']]",
      r"$game_self_switches[[@map_id, 0, 'A']]",
      r"$game_self_switches[[@map_id, -2, 'A']]",
      r"$game_self_switches[[@map_id, 02, 'A']]",
      r"$game_self_switches[[@map_id, event_id, 'A']]",
      r"$game_self_switches[[@map_id, 2, 'E']]",
      r"$game_self_switches[[@map_id, 2, 'A']]; unsafe()",
      r"$game_self_switches[[@map_id, 2, 'A']].to_s",
      r"$game_self_switches[[@map_id, 2, 'A']] == true",
    ]) {
      test('refuses opaque foreign read $script', () async {
        final source = await _events([_page([
          _command(111, [12, script]), _command(0, [], indent: 1),
          _command(412, []), _command(0, []),
        ])], extraEvents: {2: _event(2, [_page([])])});
        expect(_analyzer(source).analyze().requireEvent(1, 1).isQuarantined, isTrue);
      });
    }
  });

  group('literal foreign self-switch statements', () {
    for (final (script, target, value) in [
      ('pbSetSelfSwitch(1, "A", true)', (1, 1), true),
      ('pbSetSelfSwitch(2, "A", true)', (1, 2), true),
      ("pbSetSelfSwitch(2, 'B', false, -9)", (1, 2), false),
      ('pbSetSelfSwitch(2, "C", true, 1)', (1, 2), true),
      ('pbSetSelfSwitch(1, "D", false, 8)', (8, 1), false),
      (r'$game_self_switches[[1,2,"A"]]=true', (1, 2), true),
      (r"$game_self_switches[[8, 1, 'D']] = false", (8, 1), false),
      (r'$game_self_switches[[@map_id,2,"B"]]=true', (1, 2), true),
    ]) {
      test('resolves $script to the exact target fact', () async {
        final data = _project(maps: {
          1: _map(events: {
            1: _event(1, [_page([_command(355, [script]), _command(0, [])])]),
            2: _event(2, [_page([])]),
          }),
          8: _map(events: {1: _event(1, [_page([])])}),
        });
        final source = await _normalize(_source(data));
        final analyzer = _analyzer(source);
        final event = analyzer.analyze().requireEvent(1, 1);
        expect(event.isQuarantined, isFalse);
        final node = event.pages.single.body.nodes.single as SourceSelfSwitchNode;
        expect(node.factId, analyzer.selfFactId(target.$1, target.$2, node.letter));
        expect(node.value, value);
      });
    }
    test('retains complete ordered statements and ordinary command suffix', () async {
      final source = await _events([_page([
        _command(355, ['pbSetSelfSwitch(2, "A", true); pbSetSelfSwitch(2, "B", false)']),
        _command(655, ['pbSetSelfSwitch(2, "C", true, -1)']),
        _command(101, ['After']),
        _command(0, []),
      ])], extraEvents: {2: _event(2, [_page([])])});
      final event = _analyzer(source).analyze().requireEvent(1, 1);
      expect(event.isQuarantined, isFalse);
      expect(event.pages.single.body.nodes.map((node) => node.runtimeType),
          [SourceSelfSwitchNode, SourceSelfSwitchNode, SourceSelfSwitchNode, SourceTextNode]);
      expect(event.pages.single.body.nodes.whereType<SourceSelfSwitchNode>().map((node) => node.letter), ['A', 'B', 'C']);
    });
    for (final script in [
      'pbSetSelfSwitch(2, "A")', 'pbSetSelfSwitch(2, "A", true, 0)',
      'pbSetSelfSwitch(2, "A", true, 99)', 'pbSetSelfSwitch(9, "A", true)',
      'pbSetSelfSwitch(0, "A", true)', 'pbSetSelfSwitch(-2, "A", true)',
      'pbSetSelfSwitch(2, "E", true)', 'pbSetSelfSwitch(2, "A", 1)',
      'pbSetSelfSwitch(2, "A", flag)', 'pbSetSelfSwitch(id, "A", true)',
      'pbSetSelfSwitch(2, "A", true, map)', 'pbSetSelfSwitch(2, "#{value}", true)',
      'x = pbSetSelfSwitch(2, "A", true)', 'puts(pbSetSelfSwitch(2, "A", true))',
      'pbSetSelfSwitch(2, "A", true) if ready', 'pbSetSelfSwitch(2, "A", true); unsafe()',
      'if true\npbSetSelfSwitch(2, "A", true)\nend',
      'pbSetSelfSwitch(2, "A", true, 1, 7)', 'pbSetSelfSwitch(02, "A", true)',
      r'$game_self_switches[[99,2,"A"]]=true',
      r'$game_self_switches[[1,9,"A"]]=true',
      r'$game_self_switches[[map,2,"A"]]=true',
      r'$game_self_switches[[1,id,"A"]]=true',
      r'$game_self_switches[[1,2,"E"]]=true',
      r'$game_self_switches[[1,2,"A"]]=flag',
      r'$game_self_switches[[1,2,"A"]]=true; unsafe()',
      r'$game_self_switches[[1,2,"A"]]=true if ready',
      r'$game_self_switches[[01,2,"A"]]=true',
      r'$game_self_switches[[1,02,"A"]]=true',
    ]) {
      test('quarantines the whole script $script', () async {
        final source = await _events([_page([_command(355, [script]), _command(0, [])])],
            extraEvents: {2: _event(2, [_page([])])});
        final event = _analyzer(source).analyze().requireEvent(1, 1);
        expect(event.isQuarantined, isTrue);
        expect(event.pages.single.body.nodes.whereType<SourceSelfSwitchNode>(), isEmpty);
      });
    }
    test('dormancy audit records the foreign destination rather than the writer owner', () async {
      final source = await _normalize(_source(_project(maps: {
        1: _map(events: {1: _event(1, [_page([
          _command(355, ['pbSetSelfSwitch(14, "A", true, 205)']), _command(0, []),
        ])])}),
        205: _map(events: {14: _event(14, [_page([])])}),
      })));
      final analyzer = _analyzer(source);
      final proof = auditSourceParallelDormancy(source: source, profile: analyzer.profile).toJson();
      final writes = (proof['nativeWriteSet'] as List).cast<Map>();
      expect(writes, hasLength(1));
      expect(writes.single['factId'], analyzer.selfFactId(205, 14, 'A'));
      expect(writes.single['factId'], isNot(analyzer.selfFactId(1, 1, 'A')));
      expect(proof['refusals'], isNot(contains('sourceDormancyControllerWriterExecutable')));
    });
    test('requires the exact qualified source profile', () async {
      final source = await _events([_page([_command(355, ['pbSetSelfSwitch(2, "A", true)'])])],
          extraEvents: {2: _event(2, [_page([])])});
      expect(_analyzer(source, scriptsHash: '0' * 64).analyze().requireEvent(1, 1).isQuarantined, isTrue);
    });
  });

  group('common event inert census', () {
    _RubyObject common(List<_RubyObject> commands, {int id = 1, int trigger = 0}) =>
        _RubyObject('RPG::CommonEvent', {'@id': id, '@name': 'Inert',
          '@trigger': trigger, '@switch_id': 1, '@list': commands});
    for (final trigger in [0, 1, 2]) {
      test('sparse lists include every trigger $trigger and retain scripts without execution', () async {
        final source = await _events([], commonEvents: [null, null, common([
          _command(108, [r'$game_variables[7] = []']),
          _command(408, [r'pbSet(7, [])']),
          _command(355, ['pbSet(']), _command(655, ['1, "ON")']),
          _command(111, [12, 'predicate()']), _command(117, [2]),
          _command(122, [3, 4, 0, 0, 7]),
          _command(103, [5, 2]), _command(105, [6]), _command(0, []),
        ], id: 2, trigger: trigger)]);
        final observed = _analyzer(source).observeOpaqueCommonEventRuby();
        expect(observed.complete, isTrue);
        expect(observed.present, isTrue);
        expect(observed.dynamicVariableWrite, isFalse);
        expect(observed.variableWrites, {3, 4, 5, 6});
        expect(observed.texts.join('\n'), 'pbSet(\n1, "ON")\npredicate()');
        expect(() => observed.texts.clear(), throwsUnsupportedError);
        expect(() => observed.variableWrites.clear(), throwsUnsupportedError);
      });
    }
    test('routes use the same inert script collector as pages', () async {
      final source = await _events([], commonEvents: [null, common([
        ..._forcedRoute([_moveCommand(45, parameters: ['route_script()'])]), _command(0, []),
      ])]);
      final observed = _analyzer(source).observeOpaqueCommonEventRuby();
      expect(observed.complete, isTrue);
      expect(observed.texts, everyElement('route_script()'));
      expect(observed.texts, isNotEmpty);
    });
    test('inventoried source excluded from archive remains incomplete', () async {
      final source = await _events([], includeSystem: false,
          commonEvents: [null, common([_command(0, [])])]);
      final observed = _analyzer(source).observeOpaqueCommonEventRuby();
      expect(observed.present, isTrue);
      expect(observed.complete, isFalse);
    });
    test('dynamic writer ranges do not invent static identities', () async {
      final source = await _events([], commonEvents: [null, common([
        _command(122, ['target', 7, 0, 0, 3]), _command(0, []),
      ])]);
      final observed = _analyzer(source).observeOpaqueCommonEventRuby();
      expect(observed.complete, isTrue);
      expect(observed.dynamicVariableWrite, isTrue);
      expect(observed.variableWrites, isEmpty);
    });
    for (final record in [
      common([_command(355, [3])]),
      common([_command(117, [])]),
      common([_command(0, [])], id: 2),
      common([_command(0, [])], trigger: 3),
    ]) {
      test('malformed common envelope ${record.fields} remains incomplete', () async {
        final source = await _events([], commonEvents: [null, record]);
        expect(source.canPlan, isFalse);
        expect(_analyzer(source).observeOpaqueCommonEventRuby().complete, isFalse);
        expect(source.diagnostics.map((d) => d.code), contains('normalization.invalid_common_events'));
      });
    }
  });
  group('generic source numeric control', () {
    test('annotations between text continuations and choices do not split dialogue', () async {
      final source = await _events([_page([
        _command(101, ['first']), _command(108, ['between lines']),
        _command(401, ['second']), _command(108, ['before choice']),
        _command(408, ['continued annotation']),
        _command(102, [['yes'], 0]), _command(402, [0, 'yes']),
        _command(115, [], indent: 1), _command(404, []), _command(0, []),
      ])]);
      final event = _analyzer(source).analyze().requireEvent(1, 1);
      expect(event.isQuarantined, isFalse);
      final node = event.pages.single.body.nodes.single as SourceTextNode;
      expect(node.text, 'first second');
      expect(node.followingChoice, isNotNull);
      expect(node.annotations, hasLength(2));
    });
    test('annotations retain their exact lines and span without quarantine', () async {
      final source = await _events([_page([
        _command(108, ['annotation']), _command(408, ['continuation']),
        _command(115, []), _command(0, []),
      ])]);
      final event = _analyzer(source).analyze().requireEvent(1, 1);
      expect(event.isQuarantined, isFalse);
      expect(event.pages.single.body.nodes.map((node) => node.runtimeType.toString()),
          ['SourceAnnotationNode', 'SourceExitEventNode']);
      expect(event.pages.single.body.nodes.first.span.firstCommandIndex, 0);
      expect(event.pages.single.body.nodes.first.span.lastCommandIndex, 1);
      expect(event.pages.single.sourcePage.commands.first.parameters, ['annotation']);
    });
    for (final commands in [
      [_command(408, ['orphan'])],
      [_command(108, [4])],
      [_command(108, ['ok']), _command(408, [])],
      [_command(115, [0])],
    ]) {
      test('malformed annotations and exit stay quarantined $commands', () async {
        final source = await _events([_page([...commands, _command(0, [])])]);
        expect(_analyzer(source).analyze().requireEvent(1, 1).isQuarantined, isTrue);
      });
    }
    test('literal integer range writes preserve source value and clamp', () async {
      final source = await _events([_page([
        _command(122, [3, 5, 0, 0, -2147483648]), _command(0, []),
      ])]);
      final event = _analyzer(source).analyze().requireEvent(1, 1);
      expect(event.isQuarantined, isFalse);
      final node = event.pages.single.body.nodes.single as SourceVariableSetNode;
      expect(node.firstId, 3);
      expect(node.lastId, 5);
      expect(node.sourceValue, -2147483648);
      expect(node.value, -99999999);
      expect(node.factIds, [for (var id = 3; id <= 5; id++)
        'source:${source.snapshot.logicalProjectNamespace.value}:variable:$id']);
    });
    test('all literal assignment clamp boundaries match the source interpreter', () async {
      for (final value in [-2147483648, -100000000, -99999999, -1, 0, 99999999, 100000000, 2147483647]) {
        final source = await _events([_page([_command(122, [1, 1, 0, 0, value]), _command(0, [])])]);
        final event = _analyzer(source).analyze().requireEvent(1, 1);
        final node = event.pages.single.body.nodes.single as SourceVariableSetNode;
        expect(node.sourceValue, value);
        expect(node.value, value.clamp(-99999999, 99999999));
      }
    });
    for (final operation in [1, 2]) {
      test('literal arithmetic preserves operation, operand and every target $operation', () async {
        final source = await _events([_page([
          _command(122, [3, 5, operation, 0, -2147483648]), _command(0, []),
        ])]);
        final event = _analyzer(source).analyze().requireEvent(1, 1);
        expect(event.isQuarantined, isFalse);
        final node = event.pages.single.body.nodes.single as SourceVariableAdjustNode;
        expect(node.firstId, 3);
        expect(node.lastId, 5);
        expect(node.operand, -2147483648);
        expect(node.subtract, operation == 2);
        expect(node.factIds, [for (var id = 3; id <= 5; id++)
          'source:${source.snapshot.logicalProjectNamespace.value}:variable:$id']);
        expect(node.toJson()['operator'], operation == 2 ? 'subtract' : 'add');
      });
    }
    test('variable ID 5000 requires a plain metadata name and 5001 stays rejected', () async {
      for (final id in [5000, 5001]) {
        final source = await _events([_page([_command(122, [id, id, 0, 0, 0]), _command(0, [])])],
          variables: List.filled(5002, ''));
        expect(_analyzer(source).analyze().requireEvent(1, 1).isQuarantined, id == 5001);
      }
      for (final name in [null, 0, <Object?>[], _RubyAnnotation('', extension: 'Unknown')]) {
        final source = await _events([_page([_command(122, [1, 1, 0, 0, 0]), _command(0, [])])],
          variables: ['', name]);
        expect(_analyzer(source).analyze().requireEvent(1, 1).isQuarantined, isTrue);
      }
    });
    test('decorated raw integer operands cannot borrow normalized literal values', () async {
      for (final value in [_RubyAnnotation(7, extension: 'Unknown'),
        _RubyAnnotation(7, fields: {'@value': 7})]) {
        final source = await _events([_page([_command(122, [1, 1, 0, 0, value]), _command(0, [])])]);
        final event = _analyzer(source).analyze().eventAt(1, 1);
        if (event == null) {
          expect(source.canPlan, isFalse);
          expect(source.diagnostics.any((diagnostic) => diagnostic.blocksPlanning), isTrue);
        } else {
          expect(event.isQuarantined, isTrue);
        }
      }
    });
    for (final parameters in [
      [1, 7, 1, 1, 0], [1, 7, 0, 1, 6], [1, 7, 0, 'name', 0],
      [1, 0, 0, 1, 0], [1, 128, 0, 1, 0],
    ]) {
      test('dynamic or invalid integer comparison stays unqualified $parameters', () async {
        final source = await _events([_page([
          _command(111, parameters), _command(115, [], indent: 1), _command(412, []), _command(0, []),
        ])]);
        expect(_analyzer(source).analyze().requireEvent(1, 1).isQuarantined, isTrue);
      });
    }
    for (final parameters in [
      [0, 1, 0, 0, 1], [2, 1, 0, 0, 1], [1, 128, 0, 0, 1],
      [5001, 5001, 0, 0, 1], [1, 1, 3, 0, 1], [1, 1, 0, 1, 2],
      [1, 1, 1, 1, 2], [1, 1, 2, 1, 2], [1, 1, 6, 0, 1],
      [1, 1, 0, 0, 'name'], [1, 1, 0, 0, [1, 2]],
    ]) {
      test('invalid or dynamic numeric write is quarantined $parameters', () async {
        final source = await _events([_page([_command(122, parameters), _command(0, [])])]);
        expect(_analyzer(source).analyze().requireEvent(1, 1).isQuarantined, isTrue);
      });
    }
    for (var operation = 0; operation < 6; operation++) {
      test('integer branch operator $operation follows source semantics', () async {
        final source = await _events([_page([
          _command(111, [1, 7, 0, -1, operation]),
          _command(101, ['yes'], indent: 1), _command(412, []), _command(0, []),
        ])]);
        final event = _analyzer(source).analyze().requireEvent(1, 1);
        expect(event.isQuarantined, isFalse);
        final condition = (event.pages.single.body.nodes.single as SourceConditionalNode).condition;
        for (final value in [-2, -1, 0]) {
          final expected = [value == -1, value >= -1, value <= -1,
            value > -1, value < -1, value != -1][operation];
          expect(condition.evaluate(variables: {7: value}), expected);
        }
        expect(condition.evaluate(), [false, true, false, true, false, true][operation]);
      });
    }
  });

  group('structural field obstacle programmes CV-02A', () {
    test('attestation is produced only by the raw source analyzer', () async {
      final source = await _cutSource();
      final analysis = _analyzer(source).analyze();
      final event = analysis.events.single;
      expect(analysis.attestsFieldObstacleEvent(source: source, event: event), isTrue);
      final forged = SourceEventAnalysis(profile: analysis.profile,
          events: analysis.events, diagnostics: analysis.diagnostics);
      expect(forged.attestsFieldObstacleEvent(source: source, event: event), isFalse);
      final changed = SourceEventDefinition(sourceMapId: event.sourceMapId,
          sourceEventId: event.sourceEventId, sourceFileId: event.sourceFileId,
          identity: event.identity, name: event.name, x: event.x + 1,
          y: event.y, locator: event.locator, pages: event.pages);
      expect(analysis.attestsFieldObstacleEvent(source: source, event: changed), isFalse);
      final other = await _cutSource(name: 'Another raw event');
      expect(analysis.attestsFieldObstacleEvent(source: other, event: event), isFalse);
      final fresh = _analyzer(source).analyze();
      expect(fresh.attestsFieldObstacleEvent(source: source, event: event), isTrue);
    });

    test('recognizes exact Rock Smash without erasing the encounter call',
        () async {
      final source = await _cutSource(pages: [_rockSmashPage()]);
      final event = _analyzer(source).analyze().events.single;
      expect(event.isQuarantined, isFalse);
      final node = event.pages.single.body.nodes.single;
      final payload = (node as dynamic).toJson() as Map;
      expect(payload['kind'], 'fieldObstacleProgram');
      expect(payload['sourceMove'], 'ROCKSMASH');
      expect(payload['sourceCalls'], [
        'pbRockSmash',
        'pbSmashThisEvent',
        'pbRockSmashRandomEncounter'
      ]);
      expect(payload.containsKey('sourceRegion'), isFalse);
      expect(payload.containsKey('sourceBadgeIndex'), isFalse);
      expect(node.span.firstCommandIndex, 0);
      expect(node.span.lastCommandIndex, 7);
    });

    test('recognizes the exact Strength touch programme', () async {
      final source = await _cutSource(pages: [_strengthPage()]);
      final event = _analyzer(source).analyze().events.single;
      expect(event.isQuarantined, isFalse);
      final node = event.pages.single.body.nodes.single;
      final payload = (node as dynamic).toJson() as Map;
      expect(payload['kind'], 'fieldObstacleProgram');
      expect(payload['sourceMove'], 'STRENGTH');
      expect(payload['sourceCalls'], ['pbPushThisBoulder']);
      expect(payload.containsKey('sourceRegion'), isFalse);
      expect(payload.containsKey('sourceBadgeIndex'), isFalse);
      expect(event.pages.single.triggerCode, 1);
      expect(node.span.firstCommandIndex, 0);
      expect(node.span.lastCommandIndex, 1);
    });

    test('Cut programme delegates badge and region policy to its source binding',
        () async {
      final source = await _cutSource();
      final event = _analyzer(source).analyze().events.single;
      expect(event.isQuarantined, isFalse);
      final payload =
          (event.pages.single.body.nodes.single as dynamic).toJson() as Map;
      expect(payload['kind'], 'fieldObstacleProgram');
      expect(payload['sourceMove'], 'CUT');
      expect(payload.containsKey('sourceRegion'), isFalse);
      expect(payload.containsKey('sourceBadgeIndex'), isFalse);
    });

    for (final mutation in <String, void Function(_RubyObject)>{
      'missing encounter': (page) =>
          (page.fields['@list'] as List).removeAt(4),
      'changed encounter': (page) =>
          ((page.fields['@list'] as List)[4] as _RubyObject)
              .fields['@parameters'] = ['pbRockSmashRandomEncounter; extra'],
      'wrong encounter indent': (page) =>
          ((page.fields['@list'] as List)[4] as _RubyObject)
              .fields['@indent'] = 0,
      'touch trigger': (page) => page.fields['@trigger'] = 1,
    }.entries) {
      test('Rock Smash refuses ${mutation.key}', () async {
        final page = _rockSmashPage();
        mutation.value(page);
        final source = await _cutSource(pages: [page]);
        expect(_analyzer(source).analyze().events.single.isQuarantined, isTrue);
      });
    }

    for (final mutation in <String, void Function(_RubyObject)>{
      'action trigger': (page) => page.fields['@trigger'] = 0,
      'appended Ruby': (page) =>
          ((page.fields['@list'] as List)[0] as _RubyObject)
              .fields['@parameters'] = ['pbPushThisBoulder; extra'],
      'extra command': (page) =>
          (page.fields['@list'] as List).add(_command(0, [])),
      'passable obstacle': (page) => page.fields['@through'] = true,
    }.entries) {
      test('Strength refuses ${mutation.key}', () async {
        final page = _strengthPage();
        mutation.value(page);
        final source = await _cutSource(pages: [page]);
        expect(_analyzer(source).analyze().events.single.isQuarantined, isTrue);
      });
    }
  });


  group('structural Cut obstacle programmes', () {
    test('equivalent pages qualify independently of project and event identity',
        () async {
      final first = await _cutSource();
      final second = await _cutSource(
          mapId: 211,
          eventId: 29,
          x: 6,
          y: 4,
          name: 'A different tree',
          namespace: 'synthetic-cut-orchard');
      final nodes = <SourceFieldObstacleProgramNode>[];
      for (final source in [first, second]) {
        final analysis = _analyzer(source).analyze();
        final event = analysis.events.single;
        expect(event.isQuarantined, isFalse);
        expect(
            event.pages.single.condition.kind, SourceEventConditionKind.always);
        final node = event.pages.single.body.nodes.single;
        expect(node, isA<SourceFieldObstacleProgramNode>());
        final cut = node as SourceFieldObstacleProgramNode;
        nodes.add(cut);
        expect(cut.sourceMove, 'CUT');
        expect(cut.span.firstCommandIndex, 0);
        expect(cut.span.lastCommandIndex, 6);
        expect(cut.toJson()['sourceScriptsExecuted'], 0);
        expect(cut.toJson()['nativeExecutionQualified'], isFalse);
        expect(cut.toJson()['fullSourceFieldObstacleParityQualified'], isFalse);
        expect(cut.rawDataRef.locator!.mapId, event.sourceMapId);
        expect(cut.rawDataRef.locator!.eventId, event.sourceEventId);
        expect(
            cut.isBoundToSourceEvent(
                source: source,
                profile: analysis.profile,
                sourceMapId: event.sourceMapId,
                event: _cutSourceEvent(source)),
            isTrue);
      }
      expect(nodes[0].templateHash, nodes[1].templateHash);
      expect(nodes[0].sourceSnapshotHash, isNot(nodes[1].sourceSnapshotHash));
      expect(nodes[0].profileHash, isNot(nodes[1].profileHash));
      expect(nodes[0].rawDataRef.id, isNot(nodes[1].rawDataRef.id));
    });

    final mutations = <String, void Function(_RubyObject)>{
      'conditional switch page': (page) =>
          _withCondition(page, {'@switch1_valid': true}),
      'conditional variable page': (page) =>
          _withCondition(page, {'@variable_valid': true}),
      'conditional self switch page': (page) =>
          _withCondition(page, {'@self_switch_valid': true}),
      'touch trigger': (page) => page.fields['@trigger'] = 1,
      'another character graphic': (page) =>
          (page.fields['@graphic'] as _RubyObject).fields['@character_name'] =
              'Unqualified tree',
      'different graphic frame': (page) =>
          (page.fields['@graphic'] as _RubyObject).fields['@pattern'] = 1,
      'different graphic direction': (page) =>
          (page.fields['@graphic'] as _RubyObject).fields['@direction'] = 4,
      'transparent graphic': (page) =>
          (page.fields['@graphic'] as _RubyObject).fields['@opacity'] = 0,
      'passable obstacle': (page) => page.fields['@through'] = true,
      'moving obstacle': (page) => page.fields['@move_type'] = 1,
      'extra page field': (page) => page.fields['@unknown'] = true,
      'repeating forced route': (page) =>
          (((page.fields['@list'] as List)[0] as _RubyObject)
                  .fields['@parameters'] as List)[1]
              .fields['@repeat'] = true,
      'skippable forced route': (page) =>
          (((page.fields['@list'] as List)[0] as _RubyObject)
                  .fields['@parameters'] as List)[1]
              .fields['@skippable'] = true,
      'foreign route target': (page) =>
          (((page.fields['@list'] as List)[0] as _RubyObject)
              .fields['@parameters'] as List)[0] = -1,
      'wrong facing route': (page) =>
          (((((page.fields['@list'] as List)[0] as _RubyObject)
                  .fields['@parameters'] as List)[1] as _RubyObject)
              .fields['@list'] as List)[0] = _moveCommand(17),
      'wrong route terminator': (page) =>
          (((((page.fields['@list'] as List)[0] as _RubyObject)
                  .fields['@parameters'] as List)[1] as _RubyObject)
              .fields['@list'] as List)[1] = _moveCommand(1),
      'wrong route copy': (page) =>
          ((page.fields['@list'] as List)[1] as _RubyObject)
              .fields['@parameters'] = [_moveCommand(17)],
      'extra route parameter': (page) =>
          ((page.fields['@list'] as List)[1] as _RubyObject)
              .fields['@parameters'] = [
            _moveCommand(16, parameters: [1])
          ],
      'wrong condition code': (page) =>
          ((page.fields['@list'] as List)[2] as _RubyObject)
              .fields['@parameters'] = [0, 'pbCut'],
      'unknown condition Ruby': (page) =>
          ((page.fields['@list'] as List)[2] as _RubyObject)
              .fields['@parameters'] = [12, 'pbCut; unknown_call'],
      'unknown effect Ruby': (page) =>
          ((page.fields['@list'] as List)[3] as _RubyObject)
              .fields['@parameters'] = ['pbSmashThisEvent; unknown_call'],
      'wrong effect indent': (page) =>
          ((page.fields['@list'] as List)[3] as _RubyObject).fields['@indent'] =
              0,
      'wrong end opcode': (page) =>
          ((page.fields['@list'] as List)[5] as _RubyObject).fields['@code'] =
              411,
      'extra command': (page) =>
          (page.fields['@list'] as List).add(_command(0, [])),
      'missing command': (page) => (page.fields['@list'] as List).removeLast(),
    };
    for (final mutation in mutations.entries) {
      test('refuses ${mutation.key}', () async {
        final page = _cutPage();
        mutation.value(page);
        final source = await _cutSource(pages: [page]);
        _expectNoCut(_analyzer(source).analyze().events.single);
      });
    }

    test('refuses multiple pages and an unqualified source profile', () async {
      final multiPage = await _cutSource(pages: [_cutPage(), _cutPage()]);
      _expectNoCut(_analyzer(multiPage).analyze().events.single);
      final source = await _cutSource();
      _expectNoCut(
          _analyzer(source, scriptsHash: '0' * 64).analyze().events.single);
    });

    for (final mode in [
      'code',
      'indent',
      'index',
      'parameter',
      'parameterRef',
      'locator',
      'pageRef',
      'conditionRef',
      'trigger',
      'position',
      'name'
    ]) {
      test('binding refuses normalized $mode mismatch with raw source',
          () async {
        final source = await _cutSource();
        final analysis = _analyzer(source).analyze();
        final node = analysis.events.single.pages.single.body.nodes.single
            as SourceFieldObstacleProgramNode;
        final json = jsonDecode(jsonEncode(source.maps.single.toJson())) as Map;
        final event = (json['map']['events'] as List).single as Map;
        final page = (event['pages'] as List).single as Map;
        final commands = page['commands'] as List;
        switch (mode) {
          case 'code':
            (commands[3] as Map)['code'] = 101;
          case 'indent':
            (commands[3] as Map)['indent'] = 0;
          case 'index':
              (commands[3] as Map)['originalIndex'] = 9;
              ((commands[3] as Map)['sourceLocator'] as Map)['commandIndex'] = 9;
          case 'parameter':
            (commands[3] as Map)['parameters'] = ['unknown_call'];
          case 'parameterRef':
            ((commands[0] as Map)['parameters'] as List)[1] =
                ((commands[1] as Map)['parameters'] as List)[0];
          case 'locator':
            ((commands[3] as Map)['sourceLocator'] as Map)['eventId'] = 13;
          case 'pageRef':
            page['rawDataRef'] = page['conditionsDataRef'];
          case 'conditionRef':
            page['conditionsDataRef'] = page['rawDataRef'];
          case 'trigger':
            page['triggerCode'] = 1;
          case 'position':
            event['x'] = 4;
          case 'name':
            event['name'] = 'Unbound name';
        }
          if (mode == 'locator') {
            expect(() => SourceMapIr.fromJson(json), throwsA(isA<ContractError>()));
            return;
          }
          final changed = SourceMapIr.fromJson(json).map.events.single;
        expect(
            node.isBoundToSourceEvent(
                source: source,
                profile: analysis.profile,
                sourceMapId: 37,
                event: changed),
            isFalse);
      });
    }

    test('binding refuses stale snapshot and stale profile qualification',
        () async {
      final first = await _cutSource();
      final next = await _cutSource(name: 'Renamed tree');
      final analysis = _analyzer(first).analyze();
      final node = analysis.events.single.pages.single.body.nodes.single
          as SourceFieldObstacleProgramNode;
      expect(
          node.isBoundToSourceEvent(
              source: next,
              profile: _analyzer(next).profile,
              sourceMapId: 37,
              event: _cutSourceEvent(next)),
          isFalse);
      expect(
          node.isBoundToSourceEvent(
              source: first,
              profile: _analyzer(next).profile,
              sourceMapId: 37,
              event: _cutSourceEvent(first)),
          isFalse);
      _expectNoCut(
          SourceEventAnalyzer.forProject(next, profile: analysis.profile)
              .analyze()
              .events
              .single);
    });
  });

  for (final direction in [2, 4, 6, 8]) {
    test('player facing condition recognizes only literal player $direction',
        () async {
      final project = await _events([
        _page([
          _command(111, [6, -1, direction]),
          _command(101, ['Facing'], indent: 1),
          _command(0, [], indent: 1),
          _command(412, []),
          _command(0, []),
        ])
      ]);
      final page = _analyzer(project).analyze().requireEvent(1, 1).pages.single;
      expect(page.isQuarantined, isFalse);
      final node = page.body.nodes.single as SourceConditionalNode;
      expect(node.condition.kind.name, 'playerFacing');
      expect(node.condition.toJson()['sourceDirection'], direction);
    });
  }
  for (final parameters in <List<Object?>>[
    [6, 0, 8], [6, 1, 8], [6, -2, 8], [6, -1, 0], [6, -1, 3],
    [6, -1, 10], [6, -1, 8, 'suffix'], [6, -1], [6, -1, '8;bad()'],
  ]) {
    test('player facing condition rejects malformed or other actors $parameters', () async {
      final project = await _events([_page([
        _command(111, parameters),
        _command(101, ['Facing'], indent: 1),
        _command(0, [], indent: 1),
        _command(412, []), _command(0, []),
      ])]);
      expect(_analyzer(project).analyze().requireEvent(1, 1).isQuarantined, isTrue);
    });
  }
  test('player facing condition requires the qualified profile', () async {
    final project = await _events([_page([
      _command(111, [6, -1, 8]),
      _command(101, ['Facing'], indent: 1),
      _command(0, [], indent: 1),
      _command(412, []), _command(0, []),
    ])]);
    expect(_analyzer(project, scriptsHash: '0' * 64).analyze()
        .requireEvent(1, 1).isQuarantined, isTrue);
  });
  test('player facing condition validates kind and evaluates unknown explicitly', () {
    final facing = SourceEventCondition(kind: SourceEventConditionKind.playerFacing,
        sourceDirection: 8);
    expect(facing.isQualified, isTrue);
    expect(facing.evaluate(), isNull);
    expect(facing.evaluate(playerFacing: 8), isTrue);
    expect(facing.evaluate(playerFacing: 2), isFalse);
    expect(SourceEventCondition(kind: SourceEventConditionKind.playerFacing,
        sourceDirection: 3).isQualified, isFalse);
    expect(SourceEventCondition(kind: SourceEventConditionKind.always,
        sourceDirection: 8).isQualified, isFalse);
  });
  test('original door profile declares a map scoped route barrier and fresh followers', () {
    final profile = SourceEventProfile(
      scriptsArchiveHash: Sha256Hash(fixtureSourceInterpretationProfile.scriptsArchiveHash.value),
      sourceSnapshotHash: Sha256Hash('a' * 64), normalizationHash: Sha256Hash('b' * 64),
interpretationProfile: fixtureSourceInterpretationProfile,
);
    final timing = profile.toJson()['doorTiming'] as Map;
    expect(timing['globalRouteBarrierScope'], 'allRepresentedForcedRoutesOnTheActiveNativeMap');
    expect(timing['sourceExecutionContext'], 'freshNativeProjectWithoutImportedSourceFollowers');
  });
  test('door IR recognizes the original Center entry without flattening routes',
      () async {
    final bytes = _project(maps: {
      100: _map(
          width: 20,
          height: 30,
          events: {8: _event(8, _doorPages(), x: 13, y: 25)}),
      102: _map(width: 20, height: 14),
    });
    bytes['Data/System.rxdata'] = _MarshalFixture()
        .dump(_RubyObject('RPG::System', {'@switches': _doorSwitches()}));
    final project = await _normalize(_source(bytes), includeEventSystem: true);
    final before = project.canonicalHash;
    final archive = project.archive.canonicalHash;
    final result = _analyzer(project).analyze();
    final event = result.requireEvent(100, 8);
    final entry = event.pages.first;
    expect(entry.body.nodes.map((node) => node.runtimeType.toString()), [
      'SourceForcedMoveRouteNode',
      'SourceMoveRouteBarrierNode',
      'SourceForcedMoveRouteNode',
      'SourceMoveRouteBarrierNode',
      'SourcePlayerVisibilityNode',
      'SourceForcedMoveRouteNode',
      'SourceMoveRouteBarrierNode',
      'SourceToneNode',
      'SourceWaitNode',
      'SourcePlayerVisibilityNode',
      'SourceWarpNode',
      'SourceToneNode',
    ]);
    expect(entry.isQuarantined, isFalse);
    expect(
        [entry.triggerCode, entry.graphic!.direction, entry.graphic!.pattern],
        [1, 2, 3]);
    expect(entry.graphic!.characterName, 'OBJ_FRLG_Doors3');
    final route = entry.body.nodes.first as SourceForcedMoveRouteNode;
    final routeJson = route.toJson() as Map;
    expect(routeJson['targetSourceCharacterId'], 0);
    expect(routeJson['repeat'], isFalse);
    expect(routeJson['skippable'], isTrue);
    expect((routeJson['steps'] as List).map((dynamic step) => step['kind']), [
      'soundEffect',
      'wait',
      'turnLeft',
      'wait',
      'turnRight',
      'wait',
      'turnUp',
      'wait'
    ]);
    expect((routeJson['steps'] as List).first['sound'],
        {'name': 'frlg_pcdoor', 'volume': 100, 'pitch': 100});
    expect(route.rawDataRefs, hasLength(9));
    expect([route.span.firstCommandIndex, route.span.lastCommandIndex], [0, 8]);
    final playerRoute = entry.body.nodes[2] as SourceForcedMoveRouteNode;
    expect(playerRoute.toJson()['targetSourceCharacterId'], -1);
    expect(
        (playerRoute.toJson()['steps'] as List)
            .map((dynamic step) => step['kind']),
        ['throughOn', 'moveUp', 'throughOff']);
    expect(
        (entry.body.nodes[4] as SourcePlayerVisibilityNode).visible, isFalse);
    expect((entry.body.nodes[9] as SourcePlayerVisibilityNode).visible, isTrue);
    expect(
        (entry.body.nodes[1] as SourceMoveRouteBarrierNode).toJson()['scope'],
        'allForcedRoutes');
    final warp = entry.body.nodes[10] as SourceWarpNode;
    expect([warp.targetSourceMapId, warp.x, warp.y, warp.direction, warp.fade],
        [102, 9, 10, 8, false]);
    final returnPage = event.pages[1];
    expect(returnPage.triggerCode, 3);
    expect(returnPage.condition.children.single.kind.name, 'tempSwitch');
    expect(
        returnPage.condition.children.single.toJson()['tempSwitchLetter'], 'A');
    expect(returnPage.condition.children.single.toJson()['lifetime'],
        'mapEventInstance');
    expect(returnPage.condition.children.single.factId, isNull);
    expect(returnPage.condition.evaluate(), isNull);
    expect(event.selectPage(facts: {_analyzer(project).globalFactId(22): true}),
        isNull);
    expect(returnPage.body.nodes.map((node) => node.runtimeType.toString()),
        ['SourceConditionalNode', 'SourceTempSwitchNode']);
    final branch = returnPage.body.nodes.first as SourceConditionalNode;
    expect(branch.condition.kind.name, 'playerOnEvent');
    expect(branch.condition.evaluate(), isNull);
    expect(
        branch.whenTrue.nodes.where((node) =>
            node.runtimeType.toString() == 'SourceForcedMoveRouteNode'),
        hasLength(3));
    expect(branch.whenFalse.nodes, isEmpty);
    final setter = returnPage.body.nodes.last as SourceTempSwitchNode;
    expect(setter.toJson()['letter'], 'A');
    expect(setter.toJson()['value'], isTrue);
    expect(setter.toJson()['lifetime'], 'mapEventInstance');
    expect(setter.span.firstCommandIndex,
        greaterThan(branch.span.lastCommandIndex));
    expect([branch.span.lastCommandIndex, setter.span.firstCommandIndex],
        [25, 26]);
    expect(result.profile.toJson()['profile'], 'rmxp-static-events-v1');
    expect(project.canonicalHash, before);
    expect(project.archive.canonicalHash, archive);
  });

  test('door IR typed route collections preserve distinct copy locators',
      () async {
    final project = await _events([
      _page([
        ..._forcedRoute([
          _moveCommand(15, parameters: [2]),
          _moveCommand(17)
        ]),
        _command(0, []),
      ])
    ]);
    final analyzer = _analyzer(project);
    final route = analyzer
        .analyze()
        .requireEvent(1, 1)
        .pages
        .single
        .body
        .nodes
        .single as SourceForcedMoveRouteNode;
    expect(
        route.rawDataRefs.map((ref) => ref.locator!.commandIndex), [0, 1, 2]);
    expect(route.rawDataRefs.map((ref) => ref.id).toSet(), hasLength(3));
    expect(
        route.steps.map((step) => step.rawDataRef), route.rawDataRefs.skip(1));
    expect(route.profileHash, analyzer.profile.canonicalHash);
    expect(route.steps.first.durationTicks, 2);
    expect(route.steps.first.toJson()['durationMs'], 100);
    expect(() => route.steps.clear(), throwsUnsupportedError);
    expect(() => route.rawDataRefs.clear(), throwsUnsupportedError);
    expect(() => (route.toJson()['steps'] as List).clear(),
        throwsUnsupportedError);
    final settingGlobal22 = await _events([
      _page([
        _command(121, [22, 22, 0]),
        _command(0, [])
      ])
    ], switches: _doorSwitches());
    expect(
        _analyzer(settingGlobal22).analyze().requireEvent(1, 1).isQuarantined,
        isTrue);
    for (final scriptsHash in ['a' * 64]) {
      final page = _analyzer(project, scriptsHash: scriptsHash)
          .analyze()
          .requireEvent(1, 1)
          .pages
          .single;
      expect(page.isQuarantined, isTrue);
      expect(page.body.nodes.whereType<SourceForcedMoveRouteNode>(), isEmpty);
    }
  });

  test('stair IR preserves lateral diagonal and priority route primitives', () async {
    final commands = <_RubyObject>[
      _command(111, [6, -1, 6]),
      ..._forcedRoute([
        for (final code in [37, 39, 18, 3, 8]) _moveCommand(code),
      ], target: -1, indent: 1, skippable: false),
      _command(210, [], indent: 1),
      _command(201, [0, 1, 1, 1, 0, 1], indent: 1),
      ..._forcedRoute([
        for (final code in [38, 40]) _moveCommand(code),
      ], target: -1, indent: 1, skippable: false),
      _command(0, [], indent: 1),
      _command(412, []),
      _command(0, []),
    ];
    final source = await _events([_page(commands, trigger: 1)]);
    final event = _analyzer(source).analyze().requireEvent(1, 1);
    expect(event.isQuarantined, isFalse);
    final branch = event.pages.single.body.nodes.single as SourceConditionalNode;
    expect(branch.condition.kind, SourceEventConditionKind.playerFacing);
    expect(branch.condition.sourceDirection, 6);
    final routes = branch.whenTrue.nodes.whereType<SourceForcedMoveRouteNode>().toList();
    expect(routes, hasLength(2));
    expect(routes.first.steps.map((step) => step.kind.name),
        ['throughOn', 'alwaysOnTopOn', 'turnRight', 'moveRight', 'moveUpperRight']);
    expect(routes.last.steps.map((step) => step.kind.name),
        ['throughOff', 'alwaysOnTopOff']);
    expect(routes.first.skippable, isFalse);
    expect(routes.last.span.firstCommandIndex,
        greaterThan(branch.whenTrue.nodes.whereType<SourceWarpNode>().single.span.lastCommandIndex));
    expect(routes.first.rawDataRefs, hasLength(6));
    expect(routes.last.rawDataRefs, hasLength(3));
    for (final code in [2, 7]) {
      final other = await _events([_page([
        ..._forcedRoute([_moveCommand(code)], target: -1),
        _command(0, []),
      ])]);
      final event = _analyzer(other).analyze().requireEvent(1, 1);
      expect(event.isQuarantined, isFalse, reason: '$code');
      final route = event.pages.single.body.nodes.single as SourceForcedMoveRouteNode;
      expect(route.steps.single.kind.name, code == 2 ? 'moveLeft' : 'moveUpperLeft');
    }
  });

  test('stair IR rejects malformed primitive parameters and forged copies', () async {
    for (final code in [2, 3, 7, 8, 39, 40]) {
      for (final corruptCopy in [false, true]) {
        final route = _forcedRoute([_moveCommand(code)], target: -1);
        if (corruptCopy) {
          route.last = _command(509, [_moveCommand(code == 39 ? 40 : 39)]);
        } else {
          final value = (route.first.fields['@parameters'] as List)[1] as _RubyObject;
          (value.fields['@list'] as List).first.fields['@parameters'] = [1];
        }
        final source = await _events([_page([...route, _command(0, [])])]);
        expect(_analyzer(source).analyze().requireEvent(1, 1).isQuarantined,
            isTrue, reason: '$code corruptCopy=$corruptCopy');
      }
    }
  });

  test('door IR validates every route copy including the last step', () async {
    for (final variant in [
      'missingCopy',
      'extraCopy',
      'wrongCopy',
      'wrongIndent',
      'badTerminator',
      'extraTerminator',
      'unknownStep',
      'waitNegative',
      'waitFractional',
      'badSound',
      'targetFractional'
    ]) {
      final steps = [
        _moveCommand(15, parameters: [2]),
        _moveCommand(17)
      ];
      final commands = _forcedRoute(steps);
      final route =
          (commands.first.fields['@parameters'] as List)[1] as _RubyObject;
      final list = route.fields['@list'] as List;
      switch (variant) {
        case 'missingCopy':
          commands.removeLast();
        case 'extraCopy':
          commands.add(_command(509, [_moveCommand(17)]));
        case 'wrongCopy':
          commands.last = _command(509, [_moveCommand(18)]);
        case 'wrongIndent':
          commands.last.fields['@indent'] = 1;
        case 'badTerminator':
          list.last = _moveCommand(0, parameters: [1]);
        case 'extraTerminator':
          list.insert(1, _moveCommand(0));
        case 'unknownStep':
          (steps.last.fields)['@code'] = 45;
        case 'waitNegative':
          steps.first.fields['@parameters'] = [-1];
        case 'waitFractional':
          steps.first.fields['@parameters'] = [2.5];
        case 'badSound':
          steps.last.fields.addAll({
            '@code': 44,
            '@parameters': [_se(pitch: 151)]
          });
        case 'targetFractional':
          (commands.first.fields['@parameters'] as List)[0] = -.5;
      }
      commands.add(_command(0, []));
      final project = await _events([_page(commands)]);
      expect(
          _analyzer(project).analyze().requireEvent(1, 1).isQuarantined, isTrue,
          reason: variant);
    }
  });

  test(
      'door IR recognizes barriers and visibility with strict literal parameters',
      () async {
    final project = await _events([
      _page([
        _command(210, []),
        _command(208, [0]),
        _command(208, [1]),
        _command(0, [])
      ])
    ]);
    final page = _analyzer(project).analyze().requireEvent(1, 1).pages.single;
    expect(page.body.nodes.map((node) => node.runtimeType.toString()), [
      'SourceMoveRouteBarrierNode',
      'SourcePlayerVisibilityNode',
      'SourcePlayerVisibilityNode'
    ]);
    for (final command in [
      _command(210, [0]),
      _command(208, []),
      _command(208, [2]),
      _command(208, [false]),
      _command(208, [0.0])
    ]) {
      final invalid = await _events([
        _page([command, _command(0, [])])
      ]);
      expect(_analyzer(invalid).analyze().requireEvent(1, 1).isQuarantined,
          isTrue);
    }
  });

  test(
      'door IR rejects annotated branch discriminators and temporary switch ids',
      () async {
    final branch = await _events([
      _page([
        _command(111, [
          const _RubyAnnotation(12, extension: 'UnknownExtension'),
          'get_self.onEvent?'
        ]),
        _command(412, []),
        _command(0, []),
      ])
    ]);
    expect(
        _analyzer(branch).analyze().requireEvent(1, 1).isQuarantined, isTrue);
    final temporary = await _events([
      _withCondition(_page([_command(0, [])]), {
        '@switch1_valid': true,
        '@switch1_id': const _RubyAnnotation(22, extension: 'UnknownExtension'),
      }),
    ], switches: _doorSwitches());
    expect(_analyzer(temporary).analyze().requireEvent(1, 1).isQuarantined,
        isTrue);
  });

  test('temporary switch letters follow exact calls and metadata at arbitrary switch identities', () async {
    for(final letter in const ['A','B','C','D']) {
      final page = _withCondition(_page([_command(355,['setTempSwitchOn("$letter")']),_command(0,[])]),
        {'@switch1_valid':true,'@switch1_id':1});
      final project = await _events([page],switches:[null,'s:tsOff?("$letter")']);
      final event = _analyzer(project).analyze().requireEvent(1,1);
      expect(event.isQuarantined,isFalse);
      expect(event.pages.single.condition.children.single.tempSwitchLetter,letter);
      expect((event.pages.single.body.nodes.single as SourceTempSwitchNode).letter,letter);
    }
  });

  test('door IR only recognizes exact TempSwitch and onEvent literals',
      () async {
    for (final literal in [
      's:tsOff?("A") ',
      's:tsOff?(\'A\')',
      's:tsOff?("A"); dangerous()'
    ]) {
      final page = _withCondition(_page([_command(0, [])]),
          {'@switch1_valid': true, '@switch1_id': 22});
      final project =
          await _events([page], switches: _doorSwitches(literal: literal));
      expect(_analyzer(project).analyze().requireEvent(1, 1).isQuarantined,
          isTrue);
    }
    for (final script in [
      'get_self.onEvent? ',
      'get_self.onEvent?; dangerous()',
      'onEvent?'
    ]) {
      final project = await _events([
        _page([
          _command(111, [12, script]),
          _command(412, []),
          _command(0, [])
        ])
      ]);
      expect(_analyzer(project).analyze().requireEvent(1, 1).isQuarantined,
          isTrue);
    }
    for (final script in [
      'setTempSwitchOn("A") ',
      'setTempSwitchOn("E")',
      'setTempSwitchOn("A"); dangerous()'
    ]) {
      final project = await _events([
        _page([
          _command(355, [script]),
          _command(0, [])
        ])
      ]);
      expect(_analyzer(project).analyze().requireEvent(1, 1).isQuarantined,
          isTrue);
    }
    final continued = await _events([
      _page([
        _command(355, ['setTempSwitchOn("A")']),
        _command(655, ['dangerous()']),
        _command(0, [])
      ])
    ]);
    expect(_analyzer(continued).analyze().requireEvent(1, 1).isQuarantined,
        isTrue);
    final exact = await _events([
      _page([
        _command(355, ['setTempSwitchOn("A")']),
        _command(0, [])
      ])
    ]);
    expect(
        _analyzer(exact)
            .analyze()
            .requireEvent(1, 1)
            .pages
            .single
            .body
            .nodes
            .single
            .runtimeType
            .toString(),
        'SourceTempSwitchNode');
  });

  test('door IR rejects annotated dynamic switch names', () async {
    for (final name in [
      const _RubyAnnotation('s:tsOff?("A")', extension: 'UnknownExtension'),
      const _RubyAnnotation('s:tsOff?("A")', userClass: 'UnknownString'),
      const _RubyAnnotation('s:tsOff?("A")', fields: {'@unknown': true}),
    ]) {
      final switches = <Object?>[..._doorSwitches()]..[22] = name;
      final project = await _events([
        _withCondition(_page([_command(0, [])]),
            {'@switch1_valid': true, '@switch1_id': 22}),
      ], switches: switches);
      final page = _analyzer(project).analyze().requireEvent(1, 1).pages.single;
      expect(page.isQuarantined, isTrue);
      expect(page.condition.isQualified, isFalse);
    }
  });

  test('door IR rejects annotated TempSwitch branch parameters', () async {
    for (var slot = 0; slot < 3; slot++) {
      final parameters = <Object?>[0, 22, 0];
      parameters[slot] = _RubyAnnotation(parameters[slot], extension: 'UnknownExtension');
      final project = await _events([_page([
        _command(111, parameters), _command(412, []), _command(0, []),
      ])], switches: _doorSwitches());
      expect(_analyzer(project).analyze().requireEvent(1, 1).isQuarantined, isTrue);
    }
  });

  test('Center 102 exit recognizes presentation IR without source mutation',
      () async {
    final commands = [
      _command(250, [_se()]),
      _command(223, [_tone([-255, -255, -255, 0]), 6]),
      _command(106, [8]),
      _command(201, [0, 100, 13, 25, 0, 1]),
      _command(223, [_tone([0, 0, 0, 0]), 6]),
      _command(0, []),
    ];
    final project = await _normalize(_source(_project(maps: {
      102: _map(width: 20, height: 14,
          events: {1: _event(1, [_page(commands, trigger: 1)], x: 9, y: 11)}),
      100: _map(width: 20, height: 30),
    })));
    final before = project.canonicalHash;
    final archiveBefore = project.archive.canonicalHash;
    final sourceBefore = canonicalJsonOf(project.maps.map((map) => map.toJson()).toList());
    final analysis = _analyzer(project).analyze();
    final page = analysis.requireEvent(102, 1).pages.single;
    expect(page.body.nodes, hasLength(1));
    final warp = page.body.nodes.single as SourceWarpNode;
    final program = warp.originalProgram!;
    expect((warp.targetSourceMapId, warp.x, warp.y, warp.direction, warp.fade),
        (100, 13, 25, 0, false));
    expect(program.matches(warp), isTrue);
    expect(program.presentation, SourceExternalWarpPresentation.fade);
    expect(program.illustrationName, isNull);
    expect(program.declaredProgram.toJson()['mode'], 'automaticSourceStructure');
    expect(program.sourceSnapshotHash, project.snapshot.canonicalHash);
    expect(program.profileHash, analysis.profile.canonicalHash);
    expect(program.rawDataRef, page.rawDataRef);
    expect((warp.span.firstCommandIndex, warp.span.lastCommandIndex), (0, 5));
    expect(warp.span.locator.toJson(), page.locator.toJson());
    expect(program.isBoundToSourceEvent(source: project, profile: analysis.profile,
        event: project.maps.singleWhere((map) => map.map.sourceMapId == 102).map.events.single),
        isTrue);
    expect(page.isQuarantined, isFalse);
    expect(page.sourcePage.commands.map((command) => command.code),
        [250, 223, 106, 201, 223, 0]);
    final sound = program.sound;
    expect([sound.name, sound.volume, sound.pitch], ['Exit Door', 80, 100]);
    expect((sound.span.firstCommandIndex, sound.span.lastCommandIndex), (0, 0));
    expect(sound.rawDataRef.fileId, page.rawDataRef!.fileId);
    expect(sound.rawDataRef.id.value,
        (page.sourcePage.commands.first.parameters.first as Map)['preservedDataRef']);
    expect([program.fadeOutMs, program.transferDelayMs, program.revealMs],
        [300, 400, 300]);
    final rawPage = program.declaredProgram.pageValues[0]!;
    final rawCommands = rawPage['list'] as List;
    for (final (index, channels) in [(1, [-255.0, -255.0, -255.0, 0.0]), (4, [0.0, 0.0, 0.0, 0.0])]) {
      final parameters = (rawCommands[index] as Map)['parameters'] as List;
      final tone = parameters.first as Map;
      expect(tone['__class__'], 'Tone');
      final payload = ByteData.sublistView(base64Decode(tone['marshalPayload'] as String));
      expect([for (var channel = 0; channel < 4; channel++) payload.getFloat64(channel * 8, Endian.little)], channels);
      expect(parameters.last, 6);
    }
    expect((rawCommands[2] as Map)['parameters'], [8]);
    expect((rawCommands[3] as Map)['parameters'], [0, 100, 13, 25, 0, 1]);
    expect((rawCommands.last as Map)['parameters'], isEmpty);
    expect(() => rawCommands.clear(), throwsUnsupportedError);
    final json = program.toJson();
    expect(jsonDecode(jsonEncode(json)), json);
    expect(json['sourceScriptsExecuted'], 0);
    json['fadeOutMs'] = 99;
    expect(program.toJson()['fadeOutMs'], 300);
    expect(project.canonicalHash, before);
    expect(project.archive.canonicalHash, archiveBefore);
    expect(canonicalJsonOf(project.maps.map((map) => map.toJson()).toList()), sourceBefore);
    expect(() => page.body.nodes.clear(), throwsUnsupportedError);
  });

  for (final channels in <List<double>>[
    [1.5, -2.25, 3.125, 128.75],
    [-255, 255, 0, 255],
  ]) {
    test('Tone preserves finite RGSS channels $channels and zero duration', () async {
      final page = _analyzer(await _events([_page([
        _command(223, [_tone(channels), 0]), _command(0, []),
      ])])).analyze().requireEvent(1, 1).pages.single;
      expect(page.body.nodes.single.runtimeType.toString(), 'SourceToneNode');
      final dynamic node = page.body.nodes.single;
      expect([node.red, node.green, node.blue, node.gray], channels);
      expect([node.durationTicks, node.durationMs], [0, 0]);
    });
  }

  for (final ticks in [0, 1, 8, 2147483647]) {
    test('Wait recognizes integer $ticks at the attested 20 Hz', () async {
      final page = _analyzer(await _events([_page([
        _command(106, [ticks]), _command(0, []),
      ])])).analyze().requireEvent(1, 1).pages.single;
      expect(page.body.nodes.single.runtimeType.toString(), 'SourceWaitNode');
      final dynamic node = page.body.nodes.single;
      expect([node.durationTicks, node.durationMs], [ticks, ticks * 50]);
      expect(node.toJson()['ticksPerSecond'], 20);
    });
  }

  for (final values in [(0, 50), (100, 150)]) {
    test('SE retains literal RGSS volume and pitch $values', () async {
      final page = _analyzer(await _events([_page([
        _command(250, [_se(volume: values.$1, pitch: values.$2)]),
        _command(0, []),
      ])])).analyze().requireEvent(1, 1).pages.single;
      expect(page.body.nodes.single.runtimeType.toString(), 'SourceSoundEffectNode');
      final dynamic node = page.body.nodes.single;
      expect([node.name, node.volume, node.pitch], ['Exit Door', values.$1, values.$2]);
      expect(node.toJson()['waitForCompletion'], isFalse);
    });
  }

  test('SE preserves standard Marshal string encoding metadata', () async {
    final page = _analyzer(await _events([_page([
      _command(250, [_se(name: const _RubyAnnotation('Exit Door', fields: {'E': true}))]),
      _command(0, []),
    ])])).analyze().requireEvent(1, 1).pages.single;
    expect(page.body.nodes.single.runtimeType.toString(), 'SourceSoundEffectNode');
    final dynamic node = page.body.nodes.single;
    expect(node.name, 'Exit Door');
  });

  final rejectedPresentation = <String, _RubyObject>{
    'short Tone': _command(223, [const _RubyUserDefined('Tone', [0]), 6]),
    'long Tone': _command(223, [_RubyUserDefined('Tone', List.filled(33, 0)), 6]),
    'wrong Tone class': _command(223, [const _RubyUserDefined('Color', []), 6]),
    'Tone object instead of bytes': _command(223, [_RubyObject('Tone', {}), 6]),
    'nonfinite Tone': _command(223, [_tone([double.nan, 0, 0, 0]), 6]),
    'infinite Tone': _command(223, [_tone([0, double.infinity, 0, 0]), 6]),
    'RGB below bound': _command(223, [_tone([-255.001, 0, 0, 0]), 6]),
    'RGB above bound': _command(223, [_tone([0, 0, 255.001, 0]), 6]),
    'gray below bound': _command(223, [_tone([0, 0, 0, -0.001]), 6]),
    'gray above bound': _command(223, [_tone([0, 0, 0, 255.001]), 6]),
    'extended Tone': _command(223, [_RubyAnnotation(_tone([0, 0, 0, 0]), extension: 'Extra'), 6]),
    'annotated Tone': _command(223, [_RubyAnnotation(_tone([0, 0, 0, 0]), fields: {'@extra': 1}), 6]),
    'extra Tone parameter': _command(223, [_tone([0, 0, 0, 0]), 6, false]),
    'negative Tone duration': _command(223, [_tone([0, 0, 0, 0]), -1]),
    'string Tone duration': _command(223, [_tone([0, 0, 0, 0]), '6']),
    'missing Wait': _command(106, []),
    'extra Wait': _command(106, [8, false]),
    'negative Wait': _command(106, [-1]),
    'string Wait': _command(106, ['8']),
    'boolean Wait': _command(106, [true]),
    'oversized Wait': _command(106, [2147483648]),
    'dynamic SE': _command(250, ['Exit Door']),
    'wrong SE class': _command(250, [_RubyObject('AudioFile', _se().fields)]),
    'extra SE field': _command(250, [_se()..fields['@extra'] = false]),
    'missing SE pitch': _command(250, [_se()..fields.remove('@pitch')]),
    'extended SE': _command(250, [_RubyAnnotation(_se(), extension: 'Extra')]),
    'annotated SE name': _command(250, [_se(name: const _RubyAnnotation('Exit Door', fields: {'@extra': 1}))]),
    'extended SE encoding key': _command(250, [_se(name: const _RubyAnnotation('Exit Door',
        fields: {'E': true}, fieldExtensions: {'E': 'Extra'}))]),
    'extended SE encoding value': _command(250, [_se(name: const _RubyAnnotation('Exit Door',
        fields: {'encoding': _RubyAnnotation('UTF-8', extension: 'Extra')}))]),
    'nonliteral SE name': _command(250, [_se(name: _RubyObject('Unknown', {}))]),
    'SE volume below bound': _command(250, [_se(volume: -1)]),
    'SE volume above bound': _command(250, [_se(volume: 101)]),
    'SE pitch below bound': _command(250, [_se(pitch: 49)]),
    'SE pitch above bound': _command(250, [_se(pitch: 151)]),
    'extra SE parameter': _command(250, [_se(), false]),
  };
  for (final entry in rejectedPresentation.entries) {
    test('${entry.key} closes the complete presentation unit', () async {
      final project = await _events([_page([
        entry.value, _command(123, ['A', 0]), _command(0, []),
      ])]);
      final before = project.archive.canonicalHash;
      final page = _analyzer(project).analyze().requireEvent(1, 1).pages.single;
      expect(page.isQuarantined, isTrue);
      expect(page.body.isQuarantined, isTrue);
      expect(page.body.nodes.first, isA<SourceUnknownNode>());
      expect(page.sourcePage.commands.map((command) => command.code),
          [entry.value.fields['@code'], 123, 0]);
      expect(project.archive.canonicalHash, before);
    });
  }

  test('invalid Marshal annotation on Wait cannot admit a source event', () async {
    final project = await _events([_page([
      _command(106, [const _RubyAnnotation(8, fields: {'@extra': 1})]),
      _command(123, ['A', 0]), _command(0, []),
    ])]);
    expect(project.canPlan, isFalse);
    expect(project.diagnostics.any((diagnostic) => diagnostic.blocksPlanning), isTrue);
    expect(_analyzer(project).analyze().events, isEmpty);
  });

  test('presentation recognition does not admit an unknown suffix', () async {
    final page = _analyzer(await _events([_page([
      _command(106, [8]), _command(999, []),
      _command(123, ['A', 0]), _command(0, []),
    ])])).analyze().requireEvent(1, 1).pages.single;
    expect(page.body.nodes.first.runtimeType.toString(), 'SourceWaitNode');
    expect(page.isQuarantined, isTrue);
    expect(page.body.nodes[1], isA<SourceUnknownNode>());
  });

  test('presentation requires matching attested profile and source bindings', () async {
    final project = await _events([_page([
      _command(250, [_se()]),
      _command(223, [_tone([0, 0, 0, 0]), 6]),
      _command(106, [8]), _command(0, []),
    ])]);
    for (final profile in [
      SourceEventProfile.forProject(project, scriptsArchiveHash: _hash([9]),
interpretationProfile: fixtureSourceInterpretationProfile,
),
      SourceEventProfile(scriptsArchiveHash: Sha256Hash(fixtureSourceInterpretationProfile.scriptsArchiveHash.value),
          sourceSnapshotHash: _hash([9]), normalizationHash: project.canonicalHash,
interpretationProfile: fixtureSourceInterpretationProfile,
),
      SourceEventProfile(scriptsArchiveHash: Sha256Hash(fixtureSourceInterpretationProfile.scriptsArchiveHash.value),
          sourceSnapshotHash: project.snapshot.canonicalHash, normalizationHash: _hash([9]),
interpretationProfile: fixtureSourceInterpretationProfile,
),
    ]) {
      final page = SourceEventAnalyzer.forProject(project, profile: profile)
          .analyze().requireEvent(1, 1).pages.single;
      expect(page.isQuarantined, isTrue);
      expect(page.body.isQuarantined, isTrue);
      expect(page.body.nodes, everyElement(isA<SourceUnknownNode>()));
    }
  });

  test('exact current-event facing route preserves its two-command source span',
      () async {
    final commands = [
      _command(101, ['Hello']),
      ..._facingCommands(),
    ];
    final project = await _events([_page(commands)]);
    final before = project.archive.canonicalHash;
    final analysis = _analyzer(project).analyze();
    final page = analysis.requireEvent(1, 1).pages.single;
    expect(page.isQuarantined, isFalse);
    expect(analysis.diagnostics, isEmpty);
    expect(page.body.nodes, hasLength(2));
    final node = page.body.nodes.last as SourceInteractionFacingNode;
    expect([node.span.firstCommandIndex, node.span.lastCommandIndex], [1, 2]);
    expect(node.span.locator.commandIndex, 1);
    expect(page.sourcePage.commands.map((command) => command.code),
        [101, 209, 509, 0]);
    expect(page.rawDataRef, isNotNull);
    expect(node.rawDataRefs, hasLength(2));
    for (var i = 0; i < node.rawDataRefs.length; i++) {
      final reference = node.rawDataRefs[i];
      final command = page.sourcePage.commands[1 + i];
      final parameter = command.parameters[i == 0 ? 1 : 0] as Map;
      expect(reference.id.value, parameter['preservedDataRef']);
      expect(reference.locator!.toJson(), command.sourceLocator.toJson());
      expect(reference.fileId, page.rawDataRef!.fileId);
      expect(reference.contentHash,
          project.archive.files[reference.fileId]!.contentHash);
      expect(reference.status, 'preservedOnly');
    }
    expect(() => node.rawDataRefs.clear(), throwsUnsupportedError);
    expect(project.archive.canonicalHash, before);
  });

  test('static event profile retains explicitly selected inert witnesses', () async {
    final profile = SourceEventProfile.forProject(await _events([_page([])]),
        interpretationProfile: fixtureSourceInterpretationProfile);
    final json = profile.toJson();
    expect(json['profile'], 'rmxp-static-events-v1');
    expect(json['oracleSections'], {
      'Interpreter': crypto.sha256.convert(syntheticInterpretationSection).toString()
    });
  });

  final rejectedRoutes = <String, Object?>{
    'repeated route': _changedFacingRoute({'@repeat': true}),
    'skippable route': _changedFacingRoute({'@skippable': true}),
    'nonboolean repeat': _changedFacingRoute({'@repeat': 0}),
    'nonboolean skippable': _changedFacingRoute({'@skippable': 0}),
    'extra route field': _changedFacingRoute({'@wait': false}),
    'missing repeat': _facingRoute()..fields.remove('@repeat'),
    'missing skippable': _facingRoute()..fields.remove('@skippable'),
    'missing route list': _facingRoute()..fields.remove('@list'),
    'wrong route class': _RubyObject('CustomMoveRoute', _facingRoute().fields),
    'untyped route map': _facingRoute().fields,
    'empty route': _changedFacingRoute({'@list': <Object?>[]}),
    'missing terminator': _changedFacingRoute({
      '@list': [_moveCommand(25)]
    }),
    'extra movement': _changedFacingRoute({
      '@list': [_moveCommand(25), _moveCommand(1), _moveCommand(0)]
    }),
    'unknown movement': _changedFacingRoute({
      '@list': [_moveCommand(999), _moveCommand(0)]
    }),
    'fixed orientation': _changedFacingRoute({
      '@list': [_moveCommand(24), _moveCommand(0)]
    }),
    'wrong terminator': _changedFacingRoute({
      '@list': [_moveCommand(25), _moveCommand(999)]
    }),
    'facing parameter': _changedFacingRoute({
      '@list': [
        _moveCommand(25, parameters: [0]),
        _moveCommand(0)
      ]
    }),
    'terminator parameter': _changedFacingRoute({
      '@list': [
        _moveCommand(25),
        _moveCommand(0, parameters: [0])
      ]
    }),
    'extra movement field': _changedFacingRoute({
      '@list': [_moveCommand(25)..fields['@extra'] = false, _moveCommand(0)]
    }),
    'missing movement parameters': _changedFacingRoute({
      '@list': [_moveCommand(25)..fields.remove('@parameters'), _moveCommand(0)]
    }),
    'wrong movement class': _changedFacingRoute({
      '@list': [
        _RubyObject('UnknownCommand', _moveCommand(25).fields),
        _moveCommand(0)
      ]
    }),
    'extended route':
        _RubyAnnotation(_facingRoute(), extension: 'UnknownExtension'),
    'extended field symbol': _RubyObject(
        'RPG::MoveRoute', _facingRoute().fields,
        fieldExtensions: {'@repeat': 'UnknownExtension'}),
    'forged reference marker': {'preservedDataRef': 'missing-reference'},
    'invalid reference marker': {'preservedDataRef': 'invalid reference'},
    'extended movement': _changedFacingRoute({
      '@list': [
        _RubyAnnotation(_moveCommand(25), extension: 'UnknownExtension'),
        _moveCommand(0)
      ]
    }),
    'extended route list': _changedFacingRoute({
      '@list': _RubyAnnotation([_moveCommand(25), _moveCommand(0)],
          extension: 'UnknownExtension')
    }),
    'custom route list': _changedFacingRoute({
      '@list': _RubyAnnotation([_moveCommand(25), _moveCommand(0)],
          userClass: 'UnknownArray')
    }),
    'annotated route list': _changedFacingRoute({
      '@list': _RubyAnnotation([_moveCommand(25), _moveCommand(0)],
          fields: {'@extra': true})
    }),
    'extended flag': _changedFacingRoute({
      '@repeat': const _RubyAnnotation(false, extension: 'UnknownExtension')
    }),
    'annotated movement parameters': _changedFacingRoute({
      '@list': [
        _moveCommand(25)
          ..fields['@parameters'] =
              const _RubyAnnotation(<Object?>[], fields: {'@extra': true}),
        _moveCommand(0)
      ]
    }),
  };
  for (final entry in rejectedRoutes.entries) {
    test('${entry.key} quarantines the entire facing page', () async {
      final commands = _facingCommands(route: entry.value);
      commands.insert(2, _command(123, ['A', 0]));
      final project = await _events([_page(commands)]);
      final before = project.archive.canonicalHash;
      final page = _analyzer(project).analyze().requireEvent(1, 1).pages.single;
      expect(page.isQuarantined, isTrue);
      expect(page.body.isQuarantined, isTrue);
      expect(page.body.nodes.map((node) => node.runtimeType.toString()),
          isNot(contains('SourceInteractionFacingNode')));
      expect(page.sourcePage.commands.map((command) => command.code),
          [209, 509, 123, 0]);
      expect(project.archive.canonicalHash, before);
    });
  }

  final rejectedCommands = <String, List<_RubyObject>>{
    'player target': _facingCommands(target: -1),
    'named event target': _facingCommands(target: 1),
    'string target': _facingCommands(target: '0'),
    'boolean target': _facingCommands(target: false),
    'missing route parameter': [
      _command(209, [0]),
      _command(509, [_moveCommand(25)]),
      _command(0, [])
    ],
    'extra route parameter': [
      _command(209, [0, _facingRoute(), false]),
      _command(509, [_moveCommand(25)]),
      _command(0, [])
    ],
    'missing copy': [
      _command(209, [0, _facingRoute()]),
      _command(0, [])
    ],
    'standalone copy': [
      _command(509, [_moveCommand(25)]),
      _command(0, [])
    ],
    'wrong copy opcode': [
      _command(209, [0, _facingRoute()]),
      _command(509, [_moveCommand(24)]),
      _command(0, [])
    ],
    'copy parameter': [
      _command(209, [0, _facingRoute()]),
      _command(509, [
        _moveCommand(25, parameters: [0])
      ]),
      _command(0, [])
    ],
    'extra copy field': [
      _command(209, [0, _facingRoute()]),
      _command(509, [_moveCommand(25)..fields['@extra'] = false]),
      _command(0, [])
    ],
    'wrong copy indent': [
      _command(209, [0, _facingRoute()]),
      _command(509, [_moveCommand(25)], indent: 1),
      _command(0, [])
    ],
    'missing copy payload': [
      _command(209, [0, _facingRoute()]),
      _command(509, []),
      _command(0, [])
    ],
    'extra copy payload': [
      _command(209, [0, _facingRoute()]),
      _command(509, [_moveCommand(25), _moveCommand(25)]),
      _command(0, [])
    ],
    'separated copy': [
      _command(209, [0, _facingRoute()]),
      _command(101, ['Interruption']),
      _command(509, [_moveCommand(25)]),
      _command(0, [])
    ],
    'extra event command field': _facingCommands()
      ..first.fields['@extra'] = false,
  };
  for (final entry in rejectedCommands.entries) {
    test('${entry.key} cannot qualify current-event facing', () async {
      final commands = [...entry.value];
      commands.insert(commands.length - 1, _command(123, ['A', 0]));
      final page = _analyzer(await _events([_page(commands)]))
          .analyze()
          .requireEvent(1, 1)
          .pages
          .single;
      expect(page.isQuarantined, isTrue);
      expect(page.body.isQuarantined, isTrue);
      expect(page.body.nodes.map((node) => node.runtimeType.toString()),
          isNot(contains('SourceInteractionFacingNode')));
    });
  }

  test('facing cannot be enabled by another script hash or source binding',
      () async {
    final project = await _events([_page(_facingCommands())]);
    for (final profile in [
      SourceEventProfile.forProject(project,
          scriptsArchiveHash: Sha256Hash('a' * 64),
interpretationProfile: fixtureSourceInterpretationProfile,
),
      SourceEventProfile(
          scriptsArchiveHash:
              Sha256Hash(fixtureSourceInterpretationProfile.scriptsArchiveHash.value),
          sourceSnapshotHash: _hash([9]),
          normalizationHash: project.canonicalHash,
interpretationProfile: fixtureSourceInterpretationProfile,
),
      SourceEventProfile(
          scriptsArchiveHash:
              Sha256Hash(fixtureSourceInterpretationProfile.scriptsArchiveHash.value),
          sourceSnapshotHash: project.snapshot.canonicalHash,
          normalizationHash: _hash([9]),
interpretationProfile: fixtureSourceInterpretationProfile,
),
    ]) {
      final page = SourceEventAnalyzer.forProject(project, profile: profile)
          .analyze()
          .requireEvent(1, 1)
          .pages
          .single;
      expect(page.isQuarantined, isTrue);
      expect(page.body.isQuarantined, isTrue);
      expect(page.body.nodes.map((node) => node.runtimeType.toString()),
          isNot(contains('SourceInteractionFacingNode')));
    }
  });

  test('linked movement copies retain distinct exact command locators',
      () async {
    final move = _moveCommand(25);
    final route = _changedFacingRoute({
      '@list': [move, _moveCommand(0)]
    });
    final project = await _events([
      _page([
        _command(209, [0, route]),
        _command(509, [move]),
        _command(0, [])
      ])
    ]);
    final page = _analyzer(project).analyze().requireEvent(1, 1).pages.single;
    expect(page.isQuarantined, isFalse);
    final node = page.body.nodes.single as SourceInteractionFacingNode;
    expect(node.rawDataRefs.map((ref) => ref.locator!.commandIndex), [0, 1]);
    expect(node.rawDataRefs.map((ref) => ref.id).toSet(), hasLength(2));
  });

  test(
      'annotated raw event commands and parameter arrays cannot qualify facing',
      () async {
    final extended = _page(_facingCommands());
    final commands = extended.fields['@list'] as List<_RubyObject>;
    extended.fields['@list'] = [
      _RubyAnnotation(commands.first, extension: 'UnknownExtension'),
      ...commands.skip(1)
    ];
    final annotated = _page(_facingCommands());
    final raw = (annotated.fields['@list'] as List<_RubyObject>).first;
    raw.fields['@parameters'] =
        _RubyAnnotation(raw.fields['@parameters'], fields: {'@extra': true});
    for (final sourcePage in [extended, annotated]) {
      final page = _analyzer(await _events([sourcePage]))
          .analyze()
          .requireEvent(1, 1)
          .pages
          .single;
      expect(page.isQuarantined, isTrue);
      expect(page.body.isQuarantined, isTrue);
      expect(page.body.nodes.whereType<SourceInteractionFacingNode>(), isEmpty);
    }
  });

  test('qualified facing cannot make an unknown suffix executable', () async {
    final commands = _facingCommands();
    commands.insert(2, _command(999, []));
    commands.insert(3, _command(123, ['A', 0]));
    final page = _analyzer(await _events([_page(commands)]))
        .analyze()
        .requireEvent(1, 1)
        .pages
        .single;
    expect(page.isQuarantined, isTrue);
    expect(page.body.isQuarantined, isTrue);
    expect(page.body.nodes.first, isA<SourceInteractionFacingNode>());
    expect(page.body.nodes[1], isA<SourceUnknownNode>());
  });

  test(
      'RMXP internal zero preserves the original pickup branch and raw commands',
      () async {
    final analysis = _analyzer(await _events([
      _page([
        _command(111, [12, 'pbItemBall(:ETHER)']),
        _command(123, ['A', 0], indent: 1),
        _command(0, [], indent: 1),
        _command(412, []),
        _command(0, []),
      ])
    ]))
        .analyze();
    final event = analysis.requireEvent(1, 1);
    final page = event.pages.single;
    expect(event.isQuarantined, isFalse);
    expect(analysis.diagnostics, isEmpty);
    final conditional = page.body.nodes.single as SourceConditionalNode;
    expect(conditional.condition.pickup!.sourceSymbol, 'ETHER');
    expect(conditional.condition.pickup!.quantity, 1);
    final effect = conditional.whenTrue.nodes.single as SourceSelfSwitchNode;
    expect(effect.letter, 'A');
    expect(effect.value, isTrue);
    expect(conditional.whenTrue.span.lastCommandIndex, 2);
    expect(conditional.span.lastCommandIndex, 3);
    expect(page.body.span.lastCommandIndex, 4);
    expect(page.sourcePage.commands.map((command) => command.code),
        [111, 123, 0, 412, 0]);
    expect(page.sourcePage.commands.map((command) => command.indent),
        [0, 1, 1, 0, 0]);
    expect(page.rawDataRef, isNotNull);
  });

  test('RMXP internal zero does not hide the last true empty pickup page',
      () async {
    final analyzer = _analyzer(await _events([
      _page([
        _command(111, [12, 'pbItemBall(:ETHER)']),
        _command(123, ['A', 0], indent: 1),
        _command(0, [], indent: 1),
        _command(412, []),
        _command(0, []),
      ]),
      _withCondition(_page([_command(0, [])]),
          {'@self_switch_valid': true, '@self_switch_ch': 'A'}),
    ]));
    final event = analyzer.analyze().requireEvent(1, 1);
    expect(event.isQuarantined, isFalse);
    expect(event.selectPage()!.originalPageIndex, 0);
    final consumed =
        event.selectPage(facts: {analyzer.selfFactId(1, 1, 'A'): true});
    expect(consumed!.originalPageIndex, 1);
    expect(consumed.isEmpty, isTrue);
    expect(consumed.body.nodes, isEmpty);
  });

  test('RMXP internal zeros preserve nested true and false branch scopes',
      () async {
    final event = _analyzer(await _events([
      _page([
        _command(111, [2, 'A', 0]),
        _command(111, [2, 'B', 0], indent: 1),
        _command(123, ['C', 0], indent: 2),
        _command(0, [], indent: 2),
        _command(411, [], indent: 1),
        _command(0, [], indent: 2),
        _command(412, [], indent: 1),
        _command(0, [], indent: 1),
        _command(411, []),
        _command(0, [], indent: 1),
        _command(123, ['D', 0], indent: 1),
        _command(0, [], indent: 1),
        _command(412, []),
        _command(0, []),
      ])
    ]))
        .analyze()
        .requireEvent(1, 1);
    expect(event.isQuarantined, isFalse);
    final outer = event.pages.single.body.nodes.single as SourceConditionalNode;
    final inner = outer.whenTrue.nodes.single as SourceConditionalNode;
    expect((inner.whenTrue.nodes.single as SourceSelfSwitchNode).letter, 'C');
    expect(inner.whenFalse.nodes, isEmpty);
    expect((outer.whenFalse.nodes.single as SourceSelfSwitchNode).letter, 'D');
    expect(inner.whenTrue.span.lastCommandIndex, 3);
    expect(inner.whenFalse.span.firstCommandIndex, 5);
    expect(inner.span.lastCommandIndex, 6);
    expect(outer.whenTrue.span.lastCommandIndex, 7);
    expect(outer.whenFalse.span.lastCommandIndex, 11);
    expect(outer.span.lastCommandIndex, 12);
  });

  test(
      'RMXP internal zeros preserve choice options and the cancellation branch',
      () async {
    final event = _analyzer(await _events([
      _page([
        _command(102, [
          ['Take', 'Leave'],
          5
        ]),
        _command(402, [0, 'Take']),
        _command(0, [], indent: 1),
        _command(123, ['A', 0], indent: 1),
        _command(0, [], indent: 1),
        _command(402, [1, 'Leave']),
        _command(0, [], indent: 1),
        _command(403, []),
        _command(0, [], indent: 1),
        _command(404, []),
        _command(0, []),
      ])
    ]))
        .analyze()
        .requireEvent(1, 1);
    expect(event.isQuarantined, isFalse);
    final choice = event.pages.single.body.nodes.single as SourceChoiceNode;
    expect(choice.branches.map((branch) => branch.label), ['Take', 'Leave']);
    expect(
        choice.branches.first.body.nodes.single, isA<SourceSelfSwitchNode>());
    expect(choice.branches.last.body.nodes, isEmpty);
    expect(choice.cancelBranch!.nodes, isEmpty);
    expect(choice.cancelType, 5);
    expect(choice.span.lastCommandIndex, 9);
  });

  test('RMXP internal root zeros cannot truncate later effects or raw spans',
      () async {
    final event = _analyzer(await _events([
      _page([
        _command(0, []),
        _command(101, ['Still here']),
        _command(0, []),
        _command(123, ['A', 0]),
        _command(0, []),
      ])
    ]))
        .analyze()
        .requireEvent(1, 1);
    expect(event.isQuarantined, isFalse);
    final body = event.pages.single.body;
    expect(body.nodes, hasLength(2));
    expect((body.nodes.first as SourceTextNode).text, 'Still here');
    expect(body.nodes.last, isA<SourceSelfSwitchNode>());
    expect(body.span.firstCommandIndex, 0);
    expect(body.span.lastCommandIndex, 4);
  });

  test(
      'RMXP internal zeros still reject malformed scopes and terminal commands',
      () async {
    for (final commands in [
      [
        _command(0, []),
        _command(123, ['A', 0])
      ],
      [
        _command(0, ['unexpected']),
        _command(0, [])
      ],
      [
        _command(0, []),
        _command(0, ['unexpected'])
      ],
      [_command(0, []), _command(0, [], indent: 1)],
      [
        _command(111, [2, 'A', 0]),
        _command(0, [], indent: 2),
        _command(412, []),
        _command(0, []),
      ],
      [
        _command(111, [2, 'A', 0]),
        _command(0, [], indent: 1),
        _command(0, []),
      ],
      [
        _command(111, [2, 'A', 0]),
        _command(0, [], indent: 1),
        _command(412, [], indent: 1),
        _command(0, []),
      ],
    ]) {
      final analysis = _analyzer(await _events([_page(commands)])).analyze();
      expect(analysis.requireEvent(1, 1).isQuarantined, isTrue);
      expect(analysis.diagnostics, isNotEmpty);
    }
  });

  test('RMXP internal zero cannot qualify an unknown nested command', () async {
    final analysis = _analyzer(await _events([
      _page([
        _command(111, [2, 'A', 0]),
        _command(0, [], indent: 1),
        _command(999, [], indent: 1),
        _command(0, [], indent: 1),
        _command(412, []),
        _command(0, []),
      ])
    ]))
        .analyze();
    final event = analysis.requireEvent(1, 1);
    expect(event.isQuarantined, isTrue);
    expect(analysis.diagnostics.map((diagnostic) => diagnostic.code),
        contains('events.unknown_command'));
    final conditional =
        event.pages.single.body.nodes.single as SourceConditionalNode;
    expect(conditional.whenTrue.nodes, hasLength(1));
    expect(conditional.whenTrue.nodes.single, isA<SourceUnknownNode>());
    expect(conditional.whenTrue.nodes.single.span.firstCommandIndex, 2);
  });

  test(
      'closed literal pickup condition preserves the source symbol and both return branches',
      () async {
    for (final expression in [
      'pbItemBall(:POTION)',
      ' pbItemBall( :POTION, 2 ) '
    ]) {
      final result = _analyzer(await _events([
        _page([
          _command(111, [12, expression]),
          _command(123, ['A', 0], indent: 1),
          _command(411, []),
          _command(101, ['Bag full'], indent: 1),
          _command(412, []),
          _command(0, []),
        ])
      ]))
          .analyze();
      final event = result.requireEvent(1, 1);
      final condition =
          event.pages.single.body.nodes.single as SourceConditionalNode;
      expect(condition.condition.kind, SourceEventConditionKind.pickup);
      expect(condition.condition.pickup!.sourceSymbol, 'POTION');
      expect(condition.condition.pickup!.quantity,
          expression.contains(',') ? 2 : 1);
      expect(condition.condition.pickup!.failureMayPartiallyAdd,
          expression.contains(','));
      expect(condition.condition.toJson()['pickup'],
          containsPair('targetQualification', 'required'));
      expect(condition.condition.evaluate(), isNull);
      expect(condition.whenTrue.nodes.single, isA<SourceSelfSwitchNode>());
      expect(condition.whenFalse.nodes.single, isA<SourceTextNode>());
      expect(event.isQuarantined, isFalse);
    }
  });

  test('closed bag item predicates preserve positive and negative presence', () async {
    for (final expression in [
      r'$bag.quantity(:OLDROD) == 0',
      r'$bag.quantity(:GOODROD)>0',
      r'$bag.has?(:SUPERROD)',
      r'!$bag.has?(:SUPERROD)',
    ]) {
      final event = _analyzer(await _events([
        _page([
          _command(111, [12, expression]),
          _command(101, ['matched'], indent: 1),
          _command(411, []),
          _command(101, ['unmatched'], indent: 1),
          _command(412, []),
          _command(0, []),
        ])
      ])).analyze().requireEvent(1, 1);
      expect(event.isQuarantined, isFalse, reason: expression);
      final node = event.pages.single.body.nodes.single as SourceConditionalNode;
      expect(node.condition.kind.name, 'itemPresence');
      expect(node.condition.toJson()['sourceItemSymbol'],
          expression.contains('OLDROD') ? 'OLDROD' : expression.contains('GOODROD') ? 'GOODROD' : 'SUPERROD');
      expect(node.condition.expectedValue,
          !expression.contains('== 0') && !expression.startsWith('!'));
      expect(node.whenTrue.nodes.single, isA<SourceTextNode>());
      expect(node.whenFalse.nodes.single, isA<SourceTextNode>());
    }
  });

  test('standalone receive item has a typed helper and ignored source return', () async {
    final event = _analyzer(await _events([
      _page([
        _command(355, ['pbReceiveItem(:OLDROD)']),
        _command(101, ['Continue even if grant fails']),
        _command(123, ['A', 0]),
        _command(0, []),
      ])
    ])).analyze().requireEvent(1, 1);
    expect(event.isQuarantined, isFalse);
    final grant = event.pages.single.body.nodes.first;
    expect(grant, isA<SourcePickupNode>());
    expect((grant as SourcePickupNode).sourceSymbol, 'OLDROD');
    expect(grant.toJson()['helper'], 'receiveItem');
    expect(grant.toJson()['sourceReturnValueUsed'], isFalse);
    expect(event.pages.single.body.nodes[1], isA<SourceTextNode>());
    expect(event.pages.single.body.nodes[2], isA<SourceSelfSwitchNode>());
  });

  test('item giver literals reject dynamic Ruby and changed source profiles', () async {
    for (final expression in [
      r'$bag.quantity(item)>0',
      r'$bag.quantity(:OLDROD) >= 1',
      r'$bag.quantity(:OLDROD) == 1',
      r'$bag.has?(:OLDROD) || reward()',
      r'!$bag.has?(:OLDROD); reward()',
      r'$bag.has?(:OLDROD, extra)',
      r'$bag.quantity(:OLDROD)>0' '\n',
    ]) {
      final event = _analyzer(await _events([
        _page([_command(111, [12, expression]), _command(412, [])])
      ])).analyze().requireEvent(1, 1);
      expect(event.isQuarantined, isTrue, reason: expression);
    }
    for (final expression in [
      'pbReceiveItem(item)',
      'pbReceiveItem(:OLDROD); reward()',
      'pbReceiveItem(:OLDROD) || reward()',
      'pbReceiveItem(:OLDROD, quantity)',
      'pbReceiveItem(:OLDROD, 0)',
    ]) {
      final event = _analyzer(await _events([
        _page([_command(355, [expression]), _command(0, [])])
      ])).analyze().requireEvent(1, 1);
      expect(event.isQuarantined, isTrue, reason: expression);
    }
    final project = await _events([
      _page([_command(355, ['pbReceiveItem(:OLDROD)']), _command(0, [])])
    ]);
    expect(_analyzer(project, scriptsHash: '0' * 64).analyze()
        .requireEvent(1, 1).isQuarantined, isTrue);
  });

  test(
      'pickup-looking dynamic Ruby and statement suffixes are entirely quarantined',
      () async {
    for (final expression in [
      'pbItemBall(item)',
      'pbItemBall(:POTION, amount)',
      'pbItemBall(:POTION, 0)',
      'pbItemBall(:POTION, -1)',
      'pbItemBall(:POTION, 01)',
      'pbItemBall(:POTION, 2147483648)',
      'pbItemBall(:POTION, *items)',
      'obj.pbItemBall(:POTION)',
      'pbItemBall(:POTION); reward()',
      'pbItemBall(:POTION) || reward()',
      'pbItemBall(:"#{dynamic}")',
      'pbItemBall(:POTION, 1, extra)',
      'pbItemBall(: POTION)',
      'pbItemBall\n(:POTION)',
    ]) {
      final event = _analyzer(await _events([
        _page([
          _command(111, [12, expression]),
          _command(123, ['A', 0], indent: 1),
          _command(412, []),
        ])
      ]))
          .analyze()
          .requireEvent(1, 1);
      expect(event.isQuarantined, isTrue, reason: expression);
    }
  });

  test(
      'Essentials dummy126 and pickup scripts are never promoted to native grants',
      () async {
    for (final command in [
      _command(126, [1, 0, 0, 1]),
      _command(355, ['pbItemBall(:POTION)'])
    ]) {
      final event = _analyzer(await _events([
        _page([command])
      ]))
          .analyze()
          .requireEvent(1, 1);
      expect(event.isQuarantined, isTrue);
      expect(
          event.pages.single.body.nodes.single, isNot(isA<SourcePickupNode>()));
    }
  });

  test('exact oracle and source bindings qualify a profile', () async {
    final project = await _events([_page([])]);
    final profile = _analyzer(project).profile;
    expect(profile.isQualified, isTrue);
    expect(profile.sourceSnapshotHash, project.snapshot.canonicalHash);
    expect(profile.normalizationHash, project.canonicalHash);
    expect(
        _analyzer(project, scriptsHash: 'a' * 64).profile.isQualified, isFalse);
    expect(SourceEventProfile.forProject(project,
interpretationProfile: fixtureSourceInterpretationProfile,
).isQualified, isFalse);
  });

  test('System is optional and retained only for requested event studies',
      () async {
    final omitted = await _events([_page([])], includeSystem: false);
    final included = await _events([_page([])]);
    expect(omitted.archive.files.values.map((file) => file.entry.relativePath),
        isNot(contains('Data/System.rxdata')));
    expect(included.archive.files.values.map((file) => file.entry.relativePath),
        contains('Data/System.rxdata'));
    expect(omitted.canPlan, isTrue);
    expect(included.canPlan, isTrue);
  });

  test(
      'last true empty page masks earlier commands and remains in source order',
      () async {
    final project = await _events([
      _page([
        _command(101, ['Earlier']),
        _command(0, [])
      ]),
      _page([_command(0, [])]),
    ]);
    final event = _analyzer(project).analyze().requireEvent(1, 1);
    expect(event.pages.map((page) => page.originalPageIndex), [0, 1]);
    expect(event.selectPage()!.originalPageIndex, 1);
    expect(event.pages.last.isEmpty, isTrue);
    expect(event.isQuarantined, isFalse);
    expect(event.name, 'Event 1');
    expect([event.x, event.y], [1, 1]);
  });

  test(
      'self-switch identities are map and event scoped and snapshot independent',
      () async {
    final condition = {'@self_switch_valid': true, '@self_switch_ch': 'A'};
    final project = await _events([
      _page([
        _command(123, ['A', 0]),
        _command(0, [])
      ]),
      _withCondition(_page([]), condition),
    ], extraEvents: {
      2: _event(2, [_withCondition(_page([]), condition)])
    });
    final analyzer = _analyzer(project);
    final analysis = analyzer.analyze();
    final first = analysis.requireEvent(1, 1);
    final second = analysis.requireEvent(1, 2);
    final fact = analyzer.selfFactId(1, 1, 'A');
    expect(first.selectPage()!.originalPageIndex, 0);
    expect(first.selectPage(facts: {fact: true})!.originalPageIndex, 1);
    expect(second.selectPage(facts: {fact: true}), isNull);
    expect(fact, isNot(analyzer.selfFactId(8, 1, 'A')));
    expect(fact, isNot(analyzer.selfFactId(1, 2, 'A')));
    final changed = _analyzer(await _events([
      _page([
        _command(101, ['changed'])
      ])
    ]));
    expect(fact, changed.selfFactId(1, 1, 'A'));
    expect((first.pages.first.body.nodes.first as SourceSelfSwitchNode).factId,
        fact);
  });

  test('script-named and absent switches never become boolean conditions',
      () async {
    for (final switchId in [1, 2, 3]) {
      final project = await _events([
        _withCondition(_page([]), {
          '@switch1_valid': true,
          '@switch1_id': switchId,
        })
      ]);
      final page = _analyzer(project).analyze().requireEvent(1, 1).pages.single;
      expect(page.condition.isQualified, switchId == 1);
      if (switchId != 1) {
        expect(page.condition.evaluate(), isNull);
        expect(page.isQuarantined, isTrue);
      }
    }
    final absent = await _events([
      _withCondition(_page([]), {
        '@switch1_valid': true,
        '@switch1_id': 1,
      })
    ], system: false);
    expect(
        _analyzer(absent).analyze().requireEvent(1, 1).isQuarantined, isTrue);
  });

  test('unknown higher condition prevents selecting a lower page', () async {
    final project = await _events([
      _page([
        _command(101, ['Unsafe fallback'])
      ]),
      _withCondition(_page([]), {'@switch1_valid': true, '@switch1_id': 2}),
    ]);
    expect(
        _analyzer(project).analyze().requireEvent(1, 1).selectPage(), isNull);
  });

  test('page variables use the source greater-than-or-equal threshold',
      () async {
    final project = await _events([
      _withCondition(_page([]), {
        '@variable_valid': true,
        '@variable_id': 7,
        '@variable_value': 3,
      })
    ]);
    final condition =
        _analyzer(project).analyze().requireEvent(1, 1).pages.single.condition;
    expect(condition.evaluate(variables: {7: 2}), isFalse);
    expect(condition.evaluate(variables: {7: 3}), isTrue);
    expect(condition.evaluate(variables: {7: 4}), isTrue);
  });

  test('page graphics and movement are read without mutating sealed references',
      () async {
    final page = _page([])..fields['@through'] = true;
    final graphic = page.fields['@graphic'] as _RubyObject;
    graphic.fields['@direction'] = 8;
    graphic.fields['@pattern'] = 2;
    final project = await _events([page]);
    final before = project.archive.canonicalHash;
    final result = _analyzer(project).analyze().requireEvent(1, 1).pages.single;
    expect(result.graphic!.through, isTrue);
    expect(result.graphic!.direction, 8);
    expect(result.graphic!.pattern, 2);
    expect(result.graphic!.moveSpeed, 3);
    expect(result.rawDataRef!.contentHash,
        project.archive.files[result.rawDataRef!.fileId]!.contentHash);
    expect(project.archive.canonicalHash, before);
  });

  test('text continuation preserves oracle spaces and source span', () async {
    final project = await _events([
      _page([
        _command(101, ['Hello']),
        _command(401, ['world']),
        _command(401, ['']),
        _command(401, [' again']),
        _command(0, []),
      ])
    ]);
    final node = _analyzer(project)
        .analyze()
        .requireEvent(1, 1)
        .pages
        .single
        .body
        .nodes
        .single as SourceTextNode;
    expect(node.text, 'Hello world  again');
    expect([node.span.firstCommandIndex, node.span.lastCommandIndex], [0, 3]);
    expect(node.span.locator.pageIndex, 0);
  });

  test('conditional AST keeps both dependent branches and switch range',
      () async {
    final project = await _events([
      _page([
        _command(111, [0, 1, 0]),
        _command(121, [1, 1, 1], indent: 1),
        _command(411, []),
        _command(123, ['B', 0], indent: 1),
        _command(412, []),
        _command(0, []),
      ])
    ]);
    final analyzer = _analyzer(project);
    final page = analyzer.analyze().requireEvent(1, 1).pages.single;
    final node = page.body.nodes.single as SourceConditionalNode;
    expect(page.isQuarantined, isFalse);
    expect(node.condition.evaluate(facts: {analyzer.globalFactId(1): true}),
        isTrue);
    expect((node.whenTrue.nodes.single as SourceSwitchNode).value, isFalse);
    expect((node.whenFalse.nodes.single as SourceSelfSwitchNode).letter, 'B');
    expect(node.span.lastCommandIndex, 4);
  });

  test(
      'all alternatives and cancellation are structured under a preceding text',
      () async {
    final project = await _events([
      _page([
        _command(101, ['Choose']),
        _command(102, [
          ['Yes', 'No'],
          5
        ]),
        _command(402, [0, 'Yes']),
        _command(123, ['A', 0], indent: 1),
        _command(402, [1, 'No']),
        _command(101, ['No'], indent: 1),
        _command(403, []),
        _command(101, ['Cancel'], indent: 1),
        _command(404, []),
        _command(0, []),
      ])
    ]);
    final page = _analyzer(project).analyze().requireEvent(1, 1).pages.single;
    final text = page.body.nodes.single as SourceTextNode;
    final choice = text.followingChoice!;
    expect(page.isQuarantined, isFalse);
    expect(choice.branches.map((branch) => branch.label), ['Yes', 'No']);
    expect(choice.cancelType, 5);
    expect(
        (choice.cancelBranch!.nodes.single as SourceTextNode).text, 'Cancel');
    expect(text.span.lastCommandIndex, 8);
  });

  test('literal warp resolves selected map coordinates direction and fade',
      () async {
    final project = await _events([
      _page([
        _command(201, [0, 8, 2, 1, 6, 0])
      ])
    ]);
    final page = _analyzer(project).analyze().requireEvent(1, 1).pages.single;
    final warp = page.body.nodes.single as SourceWarpNode;
    expect(
        [warp.targetSourceMapId, warp.x, warp.y, warp.direction], [8, 2, 1, 6]);
    expect(warp.fade, isTrue);
    expect(page.isQuarantined, isFalse);
  });

  test('dynamic invalid and excluded warps quarantine the entire page',
      () async {
    for (final params in [
      [1, 8, 1, 1, 2, 0],
      [0, 8, 3, 1, 2, 0],
      [0, 9, 1, 1, 2, 0],
      [0, 8, 1, 1, 3, 0]
    ]) {
      final project = await _events([
        _page([
          _command(201, params),
          _command(123, ['A', 0])
        ])
      ]);
      expect(_analyzer(project).analyze().requireEvent(1, 1).isQuarantined,
          isTrue);
    }
  });

  test(
      'script groups remain inert and dependent effects are quarantined together',
      () async {
    final project = await _events([
      _page([
        _command(355, ['remove_money()']),
        _command(655, ['dynamic()']),
        _command(355, ['reward()']),
        _command(123, ['A', 0]),
        _command(0, []),
      ])
    ]);
    final event = _analyzer(project).analyze().requireEvent(1, 1);
    final block = event.pages.single.body;
    expect(event.isQuarantined, isTrue);
    expect(block.isQuarantined, isTrue);
    expect(block.nodes, hasLength(2));
    final script = block.nodes.first as SourceScriptNode;
    expect(script.script, 'remove_money()\ndynamic()\nreward()\n');
    expect(script.span.lastCommandIndex, 2);
    expect(block.span.lastCommandIndex, 4);
  });

  test('unknown nested branch quarantines its page without flattening siblings',
      () async {
    final project = await _events([
      _page([
        _command(111, [0, 1, 0]),
        _command(999, [], indent: 1),
        _command(411, []),
        _command(123, ['A', 0], indent: 1),
        _command(412, []),
      ])
    ]);
    final event = _analyzer(project).analyze().requireEvent(1, 1);
    final conditional =
        event.pages.single.body.nodes.single as SourceConditionalNode;
    expect(event.isQuarantined, isTrue);
    expect(conditional.whenTrue.nodes.single, isA<SourceUnknownNode>());
    expect(conditional.whenFalse.nodes.single, isA<SourceSelfSwitchNode>());
  });

  test(
      'malformed block structure and terminal command cannot expose suffix effects',
      () async {
    for (final commands in [
      [
        _command(111, [0, 1, 0]),
        _command(123, ['A', 0])
      ],
      [
        _command(401, ['orphan']),
        _command(123, ['A', 0])
      ],
      [
        _command(0, []),
        _command(123, ['A', 0])
      ],
      [
        _command(111, [0, 1, 0]),
        _command(999, [], indent: 1)
      ],
    ]) {
      final project = await _events([_page(commands)]);
      expect(_analyzer(project).analyze().requireEvent(1, 1).isQuarantined,
          isTrue);
    }
  });

  test(
      'unqualified oracle and mismatched project bindings cannot enable events',
      () async {
    final project = await _events([_page([])]);
    expect(
        _analyzer(project, scriptsHash: 'a' * 64)
            .analyze()
            .requireEvent(1, 1)
            .isQuarantined,
        isTrue);
    final wrong = SourceEventProfile(
        scriptsArchiveHash:
            Sha256Hash(fixtureSourceInterpretationProfile.scriptsArchiveHash.value),
        sourceSnapshotHash: _hash([9]),
        normalizationHash: project.canonicalHash,
interpretationProfile: fixtureSourceInterpretationProfile,
);
    expect(
        SourceEventAnalyzer.forProject(project, profile: wrong)
            .analyze()
            .requireEvent(1, 1)
            .isQuarantined,
        isTrue);
  });

  test('fresh analyzers preserve snapshot ownership and profile qualification',
      () async {
    final first = await _events([_page([_command(101, ['First'])])]);
    final second = await _events([_page([_command(101, ['Second'])])]);
    expect(first.snapshot.entries.map((entry) => entry.fileId),
        second.snapshot.entries.map((entry) => entry.fileId));
    expect(first.snapshot.canonicalHash, isNot(second.snapshot.canonicalHash));
    final firstProfile = _analyzer(first).profile;
    List<String> texts(NormalizedSourceProject source) => _analyzer(source)
        .analyze().requireEvent(1, 1).pages.single.body.nodes
        .whereType<SourceTextNode>().map((node) => node.text).toList();
    expect(texts(first), ['First']);
    expect(texts(second), ['Second']);
    for (var repeat = 0; repeat < 2; repeat++) {
      expect(texts(second), ['Second']);
      for (final rejected in [
        _analyzer(first, scriptsHash: 'a' * 64).profile,
        _analyzer(second).profile,
        SourceEventProfile(
            scriptsArchiveHash: firstProfile.scriptsArchiveHash,
            sourceSnapshotHash: firstProfile.sourceSnapshotHash,
            normalizationHash: _hash([9]),
            interpretationProfile: firstProfile.interpretationProfile),
      ]) {
        expect(SourceEventAnalyzer.forProject(first, profile: rejected)
            .analyze().requireEvent(1, 1).isQuarantined, isTrue);
      }
      expect(texts(first), ['First']);
    }
  });

  test('full analyses share owned immutable nodes and preserve current profiles',
      () async {
    final source = await _events([_page([_command(101, ['First'])])],
        extraEvents: {2: _event(2, [_page([_command(101, ['Second'])])])});
    final sourceJson = canonicalHashOf(source.toJson());
    final profile = _analyzer(source).profile;
    final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
    final targeted = analyzer.analyzeEventAt(1, 2)!;
    expect(targeted.sourceEventId, 2);
    final full = analyzer.analyze();
    expect(full.events, hasLength(2));
    expect(analyzer.analyze(), same(full));
    final repeated = SourceEventAnalyzer.forProject(source, profile: profile).analyze();
    expect(repeated, same(full));
    final clone = SourceEventProfile(
        scriptsArchiveHash: profile.scriptsArchiveHash,
        sourceSnapshotHash: profile.sourceSnapshotHash,
        normalizationHash: profile.normalizationHash,
        interpretationProfile: profile.interpretationProfile);
    expect(clone, isNot(same(profile)));
    expect(clone.canonicalHash, profile.canonicalHash);
    final wrapped = SourceEventAnalyzer.forProject(source, profile: clone).analyze();
    expect(wrapped.profile, same(clone));
    expect(wrapped.events.first, same(full.events.first));
    expect(wrapped.events.first.pages.single.body.nodes.single,
        same(full.events.first.pages.single.body.nodes.single));
    Sha256Hash shape(SourceEventAnalysis value) => canonicalHashOf([
      value.profile.toJson(),
      for (final event in value.events) [event.identity.value,
        for (final page in event.pages) [page.sourcePage.toJson(),
          page.condition.toJson(), page.body.span.toJson(),
          for (final node in page.body.nodes.whereType<SourceTextNode>()) node.text]],
      value.diagnostics.map((diagnostic) => diagnostic.toJson()).toList(),
    ]);
    expect(shape(wrapped), shape(full));
    expect(() => wrapped.events.clear(), throwsUnsupportedError);
    expect(() => wrapped.events.first.pages.single.body.nodes.clear(),
        throwsUnsupportedError);
    final after = analyzer.analyzeEventAt(1, 2)!;
    expect(after.sourceEventId, 2);
    expect((after.pages.single.body.nodes.single as SourceTextNode).text, 'Second');
    expect(analyzer.analyze(), same(full));
    final foreign = await _events([_page([_command(101, ['First'])])],
        extraEvents: {2: _event(2, [_page([_command(101, ['Second'])])])});
    expect(foreign.snapshot.canonicalHash, source.snapshot.canonicalHash);
    expect(foreign.canonicalHash, source.canonicalHash);
    final separatelyOwned = SourceEventAnalyzer.forProject(foreign,
        profile: clone).analyze();
    expect(shape(separatelyOwned), shape(full));
    expect(separatelyOwned.events.first, isNot(same(full.events.first)));
    final alternate = SourceEventProfile.forProject(source,
        scriptsArchiveHash: profile.scriptsArchiveHash,
        interpretationProfile: SourceInterpretationProfile.fromJson({
          ...profile.interpretationProfile!.toJson(),
          'profileId': 'alternate-full-analysis-profile',
        }));
    expect(alternate.isQualified, isTrue);
    expect(alternate.canonicalHash, isNot(profile.canonicalHash));
    final alternateResult = SourceEventAnalyzer.forProject(source,
        profile: alternate).analyze();
    expect(alternateResult.profile, same(alternate));
    expect(alternateResult.events.first, isNot(same(full.events.first)));
    expect(alternateResult.events.first.isQuarantined, isFalse);
    final invalid = _analyzer(source, scriptsHash: 'a' * 64).analyze();
    expect(invalid.events.first.isQuarantined, isTrue);
    expect(SourceEventAnalyzer.forProject(source, profile: alternate).analyze(),
        same(alternateResult));
    expect(shape(analyzer.analyze()), shape(full));
    expect(canonicalHashOf(source.toJson()), sourceJson);
  });

  test('published analysis nodes branches and conditions are immutable',
      () async {
    final analysis = _analyzer(await _events([
      _page([
        _command(101, ['Hi'])
      ])
    ]))
        .analyze();
    final event = analysis.requireEvent(1, 1);
    final page = event.pages.single;
    expect(() => analysis.events.clear(), throwsUnsupportedError);
    expect(() => event.pages.clear(), throwsUnsupportedError);
    expect(() => page.body.nodes.clear(), throwsUnsupportedError);
    expect(() => page.condition.children.clear(), throwsUnsupportedError);
  });

  test('deep command nesting is rejected before recursive AST allocation',
      () async {
    final commands = [
      for (var depth = 0; depth < 130; depth++)
        _command(111, [0, 1, 0], indent: depth),
      _command(123, ['A', 0], indent: 130),
      for (var depth = 129; depth >= 0; depth--)
        _command(412, [], indent: depth),
      _command(0, []),
    ];
    final result = _analyzer(await _events([_page(commands)])).analyze();
    expect(result.requireEvent(1, 1).isQuarantined, isTrue);
    expect(result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('events.command_depth_exceeded'));
  });

  test('adjacent Essentials choices merge with stable branch indices', () async {
    final choice = [
      _command(102, [
        ['One'],
        0
      ]),
      _command(402, [0, 'One']),
      _command(123, ['A', 0], indent: 1),
      _command(404, []),
    ];
    final result = _analyzer(await _events([
      _page([...choice, ...choice])
    ]))
        .analyze();
    expect(result.requireEvent(1, 1).isQuarantined, isFalse);
    final merged = result.requireEvent(1, 1).pages.single.body.nodes.single as SourceChoiceNode;
    expect(merged.branches.map((branch) => branch.index), [0, 1]);
    expect(merged.cancellation.kind, SourceChoiceCancellationKind.disabled);
  });

  test(
      'preservation markers and malformed graphics cannot masquerade as typed values',
      () async {
    final page = _page([
      _command(121, [1, _RubyObject('Unknown', {}), 0])
    ]);
    (page.fields['@graphic'] as _RubyObject).fields['@direction'] = 7;
    final result = _analyzer(await _events([page])).analyze();
    expect(result.requireEvent(1, 1).isQuarantined, isTrue);
    expect(result.requireEvent(1, 1).pages.single.graphic, isNull);
    expect(result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('events.invalid_command_parameters'));
  });

  group('literal Pokemon gifts', () {
    for (final pair in [('LAPRAS', 25), ('BULBASAUR', 1), ('CLOCKBIRD', 100)]) {
      test('preserves typed literal ${pair.$1} without executing source', () async {
        final source = await _events([
          _page([
            _command(101, ['Before']),
            _command(355, ['pbAddPokemon(:${pair.$1},${pair.$2})']),
            _command(123, ['A', 0]),
            _command(0, []),
          ]),
          _withCondition(_page([_command(101, ['After']), _command(0, [])]),
              {'@self_switch_valid': true, '@self_switch_ch': 'A'}),
        ]);
        final before = source.archive.canonicalHash;
        final event = _analyzer(source).analyze().requireEvent(1, 1);
        final node = event.pages.first.body.nodes.whereType<SourcePokemonGiftNode>().single;
        expect(node.sourceSpeciesSymbol, pair.$1);
        expect(node.level, pair.$2);
        expect(node.span.firstCommandIndex, 1);
        expect(node.span.lastCommandIndex, 1);
        expect(node.rawDataRef.contentHash, source.archive.files[node.rawDataRef.fileId]!.entry.sha256);
        expect(node.sourceSnapshotHash, source.snapshot.canonicalHash);
        expect(node.normalizationHash, source.canonicalHash);
        expect(event.isQuarantined, false);
        expect(event.pages.last.condition.kind, SourceEventConditionKind.all);
        expect(source.archive.canonicalHash, before);
      });
    }
    for (final script in [
      'pbAddPokemon(pbGet(1),25)',
      'pbAddPokemon(:LAPRAS,pbGet(3))',
      'pbAddPokemon(:LAPRAS,0)',
      'pbAddPokemon(:LAPRAS,101)',
      'pbAddPokemon(:LAPRAS,025)',
      'pbAddPokemon(:LAPRAS,25); danger()',
      'pbAddPokemon(:LAPRAS,25)\ndanger()',
      'pbAddPokemon\n(:LAPRAS,25)',
      'pbAddPokemon\r(:LAPRAS,25)',
      'pbAddPokemon(:LAPRAS,25,false)',
      'pbAddToParty(:LAPRAS,25)',
      'pbAddPokemon(:lapras,25)',
      'pbAddPokemon(:LAPRAS,25) # partial',
    ]) {
      test('keeps unsupported complete program quarantined: $script', () async {
        final source = await _events([_page([_command(355, [script]), _command(0, [])])]);
        final page = _analyzer(source).analyze().requireEvent(1, 1).pages.single;
        expect(page.isQuarantined, true);
        expect(page.body.nodes.whereType<SourcePokemonGiftNode>(), isEmpty);
      });
    }
    test('never recognizes a prefix of a grouped script', () async {
      final source = await _events([_page([
        _command(355, ['pbAddPokemon(:LAPRAS,25)']),
        _command(655, ['danger()']),
        _command(0, []),
      ])]);
      final page = _analyzer(source).analyze().requireEvent(1, 1).pages.single;
      expect(page.isQuarantined, true);
      expect(page.body.nodes.whereType<SourcePokemonGiftNode>(), isEmpty);
    });
    test('requires qualified profile and literal raw parameters', () async {
      final source = await _events([_page([
        _command(355, ['pbAddPokemon(:LAPRAS,25)']), _command(0, []),
      ])]);
      final page = _analyzer(source, scriptsHash: 'a' * 64).analyze().requireEvent(1, 1).pages.single;
      expect(page.isQuarantined, true);
      expect(page.body.nodes.whereType<SourcePokemonGiftNode>(), isEmpty);
      final annotated = await _events([_page([
        _command(355, [const _RubyAnnotation('pbAddPokemon(:LAPRAS,25)', extension: 'Evil')]),
        _command(0, []),
      ])]);
      expect(_analyzer(annotated).analyze().requireEvent(1, 1).isQuarantined, true);
    });
  });
}
