import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:avelune_converter_adapters/src/source_event_study_composer.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';

final class _RubyObject {
  _RubyObject(this.className, this.fields);
  final String className;
  final Map<String, Object?> fields;
}

final class _RubyBytes {
  const _RubyBytes(this.bytes);
  final List<int> bytes;
}

final class _RubyIvars {
  const _RubyIvars(this.value, this.fields);
  final Object? value;
  final Map<String, Object?> fields;
}

final class _RubyExtended {
  const _RubyExtended(this.value);
  final Object? value;
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
    if (value is _RubyIvars) {
      return [
        0x49,
        ..._value(value.value),
        ..._packed(value.fields.length),
        for (final pair in value.fields.entries) ...[
          ..._symbol(pair.key),
          ..._value(pair.value)
        ]
      ];
    }
    if (value is _RubyExtended) {
      return [
        0x65,
        ..._symbol('UnknownContactExtension'),
        ..._value(value.value)
      ];
    }
    if (value == null) return [0x30];
    if (value is bool) return [value ? 0x54 : 0x46];
    if (value is int) return [0x69, ..._packed(value)];
    final prior = _objects[value];
    if (prior != null) return [0x40, ..._packed(prior)];
    _objects[value] = _objects.length;
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
          ..._symbol(entry.key),
          ..._value(entry.value)
        ],
      ];
    }
    if (value is _RubyUserDefined) {
      return [0x75, ..._symbol(value.className),
        ..._packed(value.bytes.length), ...value.bytes];
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

_RubyObject _tileset(
        {String image = 'Terrain',
        List<String>? autotiles,
        int? counterTile,
        int? blockedTile}) =>
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
      '@passages': _RubyTable(
          512,
          1,
          1,
          List.generate(
              512,
              (i) =>
                  (i == blockedTile ? 15 : i % 16) |
                  (i == counterTile ? 0x80 : 0)),
          dimensions: 1),
      '@priorities': _RubyTable(512, 1, 1, List.generate(512, (i) => i % 6),
          dimensions: 1),
      '@terrain_tags': _RubyTable(512, 1, 1, List.generate(512, (i) => i % 8),
          dimensions: 1),
    });

_RubyObject _command(int code, List<Object?> parameters, {int indent = 0}) =>
    _RubyObject('RPG::EventCommand',
        {'@code': code, '@indent': indent, '@parameters': parameters});

_RubyObject _page(List<_RubyObject> commands,
        {int trigger = 0, String character = 'QualifiedNpc'}) =>
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

_RubyObject _event(int id, List<_RubyObject> pages,
        {int x = 1, int y = 1, String? name}) =>
    _RubyObject('RPG::Event', {
      '@id': id,
      '@name': name ?? 'Event $id',
      '@x': x,
      '@y': y,
      '@pages': pages
    });

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
    String? eventName,
    _RubyObject? tileset,
    Map<int, _RubyObject>? extraEvents,
    bool attestedScripts = false}) async {
  final data = _project(maps: {
    1: _map(events: {1: _event(1, pages, name: eventName), ...?extraEvents}),
    8: _map(),
  }, tileset: tileset);
  data['Graphics/Characters/QualifiedNpc.png'] = _png();
  if (attestedScripts) {
    data['Data/Scripts.rxdata'] =
        await File(Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS']!)
            .readAsBytes();
  }
  if (system) {
    data['Data/System.rxdata'] = _MarshalFixture()
        .dump(_RubyObject('RPG::System', {'@switches': switches}));
  }
  return _normalize(_source(data), includeEventSystem: includeSystem);
}

SourceEventAnalyzer _analyzer(NormalizedSourceProject project,
        {String? scriptsHash}) =>
    SourceEventAnalyzer.forProject(project,
        profile: SourceEventProfile.kantoForProject(project,
            scriptsArchiveHash: Sha256Hash(
                scriptsHash ?? SourceEventProfile.kantoScriptsArchiveSha256)));

_RubyObject _withCondition(_RubyObject page, Map<String, Object?> values) {
  (page.fields['@condition'] as _RubyObject).fields.addAll(values);
  return page;
}

Map<int, MapData> _nativeMaps(NormalizedSourceProject source) => {
      for (final map in source.maps.map((ir) => ir.map))
        map.sourceMapId: MapData(
            id: 'native_map_${map.sourceMapId}',
            name: map.name,
            size: GridSize(width: map.width, height: map.height)),
    };

SourceEventProjection _projectEvents(NormalizedSourceProject source,
        {Map<int, MapData>? maps}) =>
    const SourceEventProjector().project(
        source: source,
        analysis: _analyzer(source).analyze(),
        nativeMaps: maps ?? _nativeMaps(source),
        characterBindings: {
          for (final file in source.snapshot.entries.where((entry) =>
              entry.relativePath == 'Graphics/Characters/QualifiedNpc.png'))
            sourceEventCharacterBindingKey(
                    characterName: 'QualifiedNpc', pattern: 0, direction: 2):
                SourceEventCharacterBinding(
                    characterId: 'native_qualified_npc',
                    sourceSnapshotHash: source.snapshot.canonicalHash,
                    sourceFileId: file.fileId,
                    sourceFileHash: file.sha256!,
                    sourcePattern: 0,
                    sourceDirection: 2),
        });

Future<SourceEventProjection> _projectSign(_RubyObject page,
    {String eventName = 'Route sign',
    bool blockedSource = true,
    bool blockedNative = true}) async {
  final source = await _events([page],
      eventName: eventName,
      tileset: _tileset(blockedTile: blockedSource ? 400 : null),
      attestedScripts: true);
  final maps = _nativeMaps(source);
  maps[1] = maps[1]!.copyWith(layers: [
    MapLayer.collision(
        id: 'sign_collision',
        name: 'Collision',
        collisions: List.generate(6, (index) => index == 4 && blockedNative)),
  ]);
  return _projectEvents(source, maps: maps);
}

_RubyObject _facingSignPage({
  List<Object?> condition = const [6, -1, 8],
  String text = r'\w[signskin]“Heal your Pokémon!”\nPokémon ',
  List<_RubyObject> suffix = const [],
}) => _page([
  _command(111, condition),
  _command(101, [text], indent: 1),
  _command(401, ['Center'], indent: 1),
  _command(0, [], indent: 1),
  _command(412, []),
  ...suffix,
  _command(0, []),
], trigger: 1, character: '');

Future<NormalizedSourceProject> _bookshelfSource({
  Set<int> blockedCells = const {5, 6},
  String eventName = 'Bookshelf size(2,1)',
  _RubyObject? page,
  Map<int, _RubyObject>? extraEvents,
}) async {
  final data = _project(maps: {
    1: _map(
        width: 4,
        height: 3,
        data: _RubyTable(4, 3, 3, [
          ...List.filled(12, 384),
          ...List.filled(12, 0),
          ...List.generate(12, (index) => blockedCells.contains(index) ? 400 : 0),
        ]),
        events: {
          1: _event(1, [
            page ?? _page([
              _command(101, [r"It's crammed full of Pokémon\nbooks."]),
              _command(0, []),
            ], character: ''),
          ], name: eventName),
          ...?extraEvents,
        }),
  }, tileset: _tileset(blockedTile: 400));
  data['Data/Scripts.rxdata'] =
      await File(Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS']!).readAsBytes();
  return _normalize(_source(data), includeEventSystem: true);
}

Map<int, MapData> _bookshelfMaps(NormalizedSourceProject source,
    {Set<int> blockedCells = const {5, 6}}) {
  final maps = _nativeMaps(source);
  maps[1] = maps[1]!.copyWith(layers: [
    MapLayer.collision(
        id: 'bookshelf_collision',
        name: 'Collision',
        collisions: List.generate(12, blockedCells.contains)),
  ]);
  return maps;
}

bool _guard(
    NarrativeEventConditionExpression expression, Map<String, bool> facts) {
  return switch (expression) {
    NarrativeEventConditionLeaf(:final condition) => condition.when(
        fact: (id, value) => (facts[id] ?? false) == value,
        narrativeEventConsumed: (_, __) =>
            throw StateError('Source pages use Facts')),
    NarrativeEventConditionAll(:final children) =>
      children.every((c) => _guard(c, facts)),
    NarrativeEventConditionAny(:final children) =>
      children.any((c) => _guard(c, facts)),
    NarrativeEventConditionNot(:final child) => !_guard(child, facts),
  };
}

List<_RubyObject> _interactionFacingCommands() {
  final face = _RubyObject(
      'RPG::MoveCommand', {'@code': 25, '@parameters': <Object?>[]});
  return [
    _command(209, [
      0,
      _RubyObject('RPG::MoveRoute', {
        '@repeat': false,
        '@skippable': false,
        '@list': [
          face,
          _RubyObject(
              'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]}),
        ],
      }),
    ]),
    _command(509, [face]),
  ];
}

void main() {
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  for (final value in [null, false, true, 'invalid']) {
    test('retention decodes strict selected SnapEdges $value', () async {
      final bytes = _project(maps: {1: _map(), 8: _map()});
      bytes['Data/Scripts.rxdata'] = await File(scriptsPath!).readAsBytes();
      bytes['Data/map_metadata.dat'] = _MarshalFixture().dump({
        1: _RubyObject('GameData::MapMetadata', {'@id': 1, '@snap_edges': value}),
        8: _RubyObject('GameData::MapMetadata', {'@id': 8}),
      });
      final files = _source(bytes);
      final source = await _normalize(files);
      final operation = sourceEventMapRetentionPolicy(source: source, files: files,
        nativeMapIds: {1: 'first', 8: 'second'});
      if (value is String) {
        await expectLater(operation, throwsA(isA<NativeWriteException>()));
      } else {
        final policy = await operation;
        expect(policy.clampViewportToMapIds, value == true ? {'first'} : isEmpty);
        expect(policy.viewportWidthTiles, 16);
        expect(policy.viewportHeightTiles, 12);
        expect(policy.marginTiles, 6);
      }
    }, skip: scriptsPath == null);
  }
  final doorStep =
      _RubyObject('RPG::MoveCommand', {'@code': 4, '@parameters': <Object?>[]});
  final doorRoute = [
    _command(209, [
      -1,
      _RubyObject('RPG::MoveRoute', {
        '@repeat': false,
        '@skippable': true,
        '@list': [
          doorStep,
          _RubyObject(
              'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})
        ],
      })
    ]),
    _command(509, [doorStep]),
  ];
  final doorPrograms = <String, List<_RubyObject>>{
    'forcedRoute': doorRoute,
    'routeBarrier': [_command(210, [])],
    'playerVisibility': [
      _command(208, [0])
    ],
    'playerOnEvent': [
      _command(111, [12, 'get_self.onEvent?']),
      _command(412, [])
    ],
    'tempSwitchSetter': [
      _command(355, ['setTempSwitchOn("A")'])
    ],
  };
  for (final entry in doorPrograms.entries) {
    test(
        'door IR ${entry.key} keeps dependent rewards and every page quarantined',
        () async {
      final source = await _events([
        _page([
          _command(101, ['Lower page stays inactive'])
        ]),
        _page([
          _command(123, ['A', 0]),
          ...entry.value,
          _command(123, ['B', 0]),
          _command(0, [])
        ]),
      ]);
      final result = _projectEvents(source);
      final evidence = jsonEncode(result.semanticEvidence);
      expect(
          evidence,
          contains(entry.key == 'tempSwitchSetter'
              ? 'sourceTempSwitchUnsupported'
              : 'sourceDoorProgramUnsupported'));
      expect(result.registry.records.single.definitionOrNull, isNull);
      expect(
          result.registry.records
              .where((record) => record.enabledOrNull == true),
          isEmpty);
      expect(result.facts, isEmpty);
      expect(result.scenes, isEmpty);
      expect(result.dialogues, isEmpty);
      expect(result.nativeMaps.values.expand((map) => map.entities), isEmpty);
      expect(result.nativeMaps.values.expand((map) => map.warps), isEmpty);
      expect(result.staticSemanticsQualified, isFalse);
    });
  }

  final presentationCommands = [
    _command(223, [_tone([-255, -255, -255, 0]), 6]),
    _command(106, [8]),
    _command(250, [_RubyObject('RPG::AudioFile', {
      '@name': 'Exit Door', '@volume': 80, '@pitch': 100,
    })]),
  ];
  test(
      'door IR TempSwitch page cannot become a persistent fact or fallback page',
      () async {
    final source = await _events([
      _page([
        _command(101, ['Do not admit the lower page'])
      ]),
      _withCondition(
          _page([
            _command(123, ['A', 0]),
            _command(0, [])
          ], trigger: 3),
          {'@switch1_valid': true, '@switch1_id': 22}),
    ],
        switches: List.generate(
            23, (id) => id == 22 ? 's:tsOff?("A")' : 'Switch $id'));
    final result = _projectEvents(source);
    expect(jsonEncode(result.semanticEvidence),
        contains('sourceTempSwitchUnsupported'));
    expect(result.registry.records.single.definitionOrNull, isNull);
    expect(result.facts, isEmpty);
    expect(result.scenes, isEmpty);
    expect(result.dialogues, isEmpty);
    expect(result.nativeMaps.values.expand((map) => map.entities), isEmpty);
    expect(result.staticSemanticsQualified, isFalse);
  });
  for (final command in presentationCommands) {
    test('recognized presentation ${command.fields['@code']} keeps every page quarantined', () async {
      final source = await _events([
        _page([
          _command(101, ['A lower page must remain inactive'])
        ]),
        _page([
          _command(123, ['A', 0]),
          command,
          _command(123, ['B', 0]),
          _command(0, []),
        ]),
      ]);
      final before = source.canonicalHash;
      final result = _projectEvents(source);
      expect(jsonEncode(result.semanticEvidence), contains('sourcePresentationUnsupported'));
      expect(result.registry.records.single.definitionOrNull, isNull);
      expect(result.registry.records.where((record) => record.enabledOrNull == true), isEmpty);
      expect(result.nativeMaps[1]!.entities, isEmpty);
      expect(result.facts, isEmpty);
      expect(result.scenes, isEmpty);
      expect(result.dialogues, isEmpty);
      expect(result.staticSemanticsQualified, isFalse);
      expect(source.canonicalHash, before);
      final profile = result.semanticEvidence['sourceProfile'] as Map;
      expect(profile['profile'], 'kanto-events-static-v5');
      expect(result.semanticEvidence['sourceProfileHash'],
          canonicalHashOf(profile).value);
      final historical =
          jsonDecode(jsonEncode(profile)) as Map<String, dynamic>;
      historical['profile'] = 'kanto-events-static-v2';
      (historical['oracleSections'] as Map).remove('039');
      expect(canonicalHashOf(historical).value,
          isNot(result.semanticEvidence['sourceProfileHash']));
      expect(result.artifacts.single.rawSha256,
          _hash(utf8.encode(canonicalJsonOf(result.semanticEvidence))));
      final historicalEvidence = jsonDecode(jsonEncode(result.semanticEvidence)) as Map<String, dynamic>;
      historicalEvidence['sourceProfile'] = historical;
      historicalEvidence['sourceProfileHash'] = canonicalHashOf(historical).value;
      expect(_hash(utf8.encode(canonicalJsonOf(historicalEvidence))),
          isNot(result.artifacts.single.rawSha256));
    });
  }

  test('presentation exit program cannot publish its warp or pending facts', () async {
    final source = await _events([_page([
      presentationCommands[2], presentationCommands[0], presentationCommands[1],
      _command(201, [0, 8, 2, 1, 0, 1]),
      _command(223, [_tone([0, 0, 0, 0]), 6]),
      _command(123, ['A', 0]), _command(0, []),
    ], trigger: 1)]);
    final result = _projectEvents(source);
    expect(jsonEncode(result.semanticEvidence), contains('sourcePresentationUnsupported'));
    expect(result.registry.records.single.definitionOrNull, isNull);
    expect(result.scenes, isEmpty);
    expect(result.facts, isEmpty);
    expect(result.nativeMaps.values.expand((map) => map.warps), isEmpty);
    expect(result.nativeMaps.values.expand((map) => map.entities), isEmpty);
    expect(result.staticSemanticsQualified, isFalse);
  });

  test('unported source formatting quarantines the whole colored event',
      () async {
    for (final text in [
      r'\bHello<b>bold</b>',
      r'\bHello<C3 = E00808,D0D0C8>red</C3>',
      r'\rHello<icon=itemPotion>',
      r'\bHello<br>next',
      r'\bA&amp;B',
      r'\bA&lt;B',
      r'\bA&gt;B',
      r'\bA&quot;B',
      r'\bA&apos;B',
      r'\bNidoran&m;',
      r'\bNidoran&f;',
    ]) {
      final result = _projectEvents(await _events([
        _page([
          _command(101, [text]),
          _command(123, ['A', 0]),
        ])
      ]));
      expect(result.registry.records.single.definitionOrNull, isNull,
          reason: text);
      expect(result.facts, isEmpty, reason: text);
      expect(result.scenes, isEmpty, reason: text);
      expect(result.dialogues, isEmpty, reason: text);
    }
  });

  test('stationary NPC source dialogue adapts its final face-player route',
      () async {
    final source = await _events([
      _page([
        _command(101, [r'\bI heard that ghosts haunt\nLavender Town.']),
        ..._interactionFacingCommands(),
        _command(0, []),
      ])
    ]);
    final result = _projectEvents(source);
    expect(result.registry.records.single.definitionOrNull, isNotNull);
    final payload = result.scenes.single.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneYarnDialoguePayload>()
        .single;
    expect(payload.linePolicies.single.feedback.plainText,
        'I heard that ghosts haunt\nLavender Town.');
    final event = (result.semanticEvidence['events'] as List).single as Map;
    final page = (event['pages'] as List).single as Map;
    final adaptation = (page['adaptedCommands'] as List).single as Map;
    expect(adaptation['nativeContract'], 'npcFacingAtEntityInteract');
    expect(adaptation['sourceOpcodes'], [209, 509]);
    expect(adaptation['persistentFacingCertified'], isFalse);
    expect((adaptation['span'] as Map)['firstCommandIndex'], 1);
    expect((adaptation['span'] as Map)['lastCommandIndex'], 2);
    expect(adaptation['rawDataRefs'], hasLength(2));
    expect(result.facts, isEmpty);
    expect(
        result.nativeMaps[1]!.entities.single.npc!.facing, EntityFacing.south);
  });

  test(
      'face-player routes stay inactive outside the stable interaction context',
      () async {
    for (final variant in [
      'touch',
      'through',
      'directionFix',
      'moving',
      'branch',
      'effect',
      'routeFirst',
      'multiPage',
    ]) {
      final page = _page([
        if (variant == 'routeFirst') ..._interactionFacingCommands(),
        if (variant == 'branch') _command(111, [0, 1, 0]),
        _command(101, ['Hello'], indent: variant == 'branch' ? 1 : 0),
        if (variant == 'branch') _command(412, []),
        if (variant == 'effect') _command(123, ['A', 0]),
        if (variant != 'routeFirst') ..._interactionFacingCommands(),
      ], trigger: variant == 'touch' ? 1 : 0);
      if (variant == 'through') page.fields['@through'] = true;
      if (variant == 'directionFix') page.fields['@direction_fix'] = true;
      if (variant == 'moving') page.fields['@move_type'] = 1;
      final result = _projectEvents(await _events([
        page,
        if (variant == 'multiPage')
          _page([
            _command(101, ['Other page'])
          ]),
      ]));
      expect(result.registry.records.single.definitionOrNull, isNull,
          reason: variant);
      expect(result.facts, isEmpty, reason: variant);
      expect(result.scenes, isEmpty, reason: variant);
      expect(jsonEncode(result.semanticEvidence),
          contains('interactionFacingUnsupported'),
          reason: variant);
    }
  });

  test('static source dialogue preserves explicit colors and newlines',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(101, [r'\bI heard that ghosts haunt\nLavender Town.']),
      ])
    ]));
    expect(result.registry.records.single.definitionOrNull, isNotNull);
    final payload = result.scenes.single.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneYarnDialoguePayload>()
        .single;
    final document = const YarnDialogueCompiler()
        .compile(result.dialogueSources.values.single);
    final text =
        (document.nodes.single.steps.single as RuntimeDialogueLine).text;
    expect(text, 'I heard that ghosts haunt\nLavender Town.');
    final feedback = payload.linePolicies.single.feedback;
    expect(feedback.plainText, text);
    expect(
        feedback.segments.single,
        DialogueTextSegment(text,
            style: DialogueSegmentStyle(
                colorArgb: 0xff3050c8, shadowColorArgb: 0xffd0d0c8)));
  });

  test('unknown tags and uppercase entities stay literal source text',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(101, [r'\bA<thing>&AMP;B']),
      ])
    ]));
    expect(result.registry.records.single.definitionOrNull, isNotNull);
    final payload = result.scenes.single.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneYarnDialoguePayload>()
        .single;
    expect(payload.linePolicies.single.feedback.plainText, 'A<thing>&AMP;B');
  });

  test('static source dialogue keeps color changes within the same line',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(101, [r'Hello \bblue\rred\nnext']),
      ])
    ]));
    expect(result.registry.records.single.definitionOrNull, isNotNull);
    final payload = result.scenes.single.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneYarnDialoguePayload>()
        .single;
    final feedback = payload.linePolicies.single.feedback;
    expect(feedback.plainText, 'Hello bluered\nnext');
    expect(feedback.segments, [
      DialogueTextSegment('Hello '),
      DialogueTextSegment('blue',
          style: DialogueSegmentStyle(
              colorArgb: 0xff3050c8, shadowColorArgb: 0xffd0d0c8)),
      DialogueTextSegment('red\nnext',
          style: DialogueSegmentStyle(
              colorArgb: 0xffe00808, shadowColorArgb: 0xffd0d0c8)),
    ]);
  });

  test('unqualified source text controls quarantine all dependent effects',
      () async {
    for (final text in [
      r'\bHello\v[1]',
      r'\PN',
      r'\c[0]Hello',
      r'Hello\wt[20]',
      r'\bHello\n[1]',
      r'\\bHello',
      'Hello\\',
    ]) {
      final result = _projectEvents(await _events([
        _page([
          _command(101, [text]),
          _command(123, ['A', 0]),
        ])
      ]));
      expect(result.registry.records.single.definitionOrNull, isNull,
          reason: text);
      expect(result.scenes, isEmpty, reason: text);
      expect(result.dialogues, isEmpty, reason: text);
      expect(result.facts, isEmpty, reason: text);
      expect(jsonEncode(result.semanticEvidence),
          contains('sourceTextControlUnsupported'),
          reason: text);
    }
  });

  test('static source text controls use the oracle case-insensitive spelling',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(101, [r'\BBlue\RRed\NNext']),
      ])
    ]));
    expect(result.registry.records.single.definitionOrNull, isNotNull);
    final payload = result.scenes.single.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneYarnDialoguePayload>()
        .single;
    expect(payload.linePolicies.single.feedback.plainText, 'BlueRed\nNext');
    expect(
        payload.linePolicies.single.feedback.segments
            .whereType<DialogueTextSegment>()
            .map((segment) => segment.style!.colorArgb),
        [0xff3050c8, 0xffe00808]);
  });

  for (final variant in [
    'throughIvar',
    'throughExtension',
    'tileIvar',
    'nameIvar',
    'conditionIvar',
    'conditionExtension',
    'pageUnknownIvar',
    'graphicUnknownIvar'
  ]) {
    test('source touch rejects raw contact decoration $variant', () async {
      final page = _page([
        _command(101, ['Touch'])
      ], trigger: 1, character: '')
        ..fields['@through'] = true;
      final graphic = page.fields['@graphic'] as _RubyObject;
      final condition = page.fields['@condition'] as _RubyObject;
      switch (variant) {
        case 'throughIvar':
          page.fields['@through'] = const _RubyIvars(true, {'@unknown': false});
        case 'throughExtension':
          page.fields['@through'] = const _RubyExtended(true);
        case 'tileIvar':
          graphic.fields['@tile_id'] = const _RubyIvars(0, {'@unknown': false});
        case 'nameIvar':
          graphic.fields['@character_name'] =
              const _RubyIvars('', {'@unknown': false});
        case 'conditionIvar':
          condition.fields['@switch1_valid'] =
              const _RubyIvars(false, {'@unknown': false});
        case 'conditionExtension':
          page.fields['@condition'] = _RubyExtended(condition);
        case 'pageUnknownIvar':
          page.fields['@unknown'] = false;
        case 'graphicUnknownIvar':
          graphic.fields['@unknown'] = false;
      }
      final result =
          _projectEvents(await _events([page], attestedScripts: true));
      expect(result.scenes, isEmpty);
      expect(
          result.registry.records
              .every((record) => record.definitionOrNull == null),
          isTrue);
    }, skip: Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'] == null);
  }

  test('source touch accepts a plain attested passable page', () async {
    final page = _page([
      _command(101, ['Touch'])
    ], trigger: 1, character: '')
      ..fields['@through'] = true;
    final result = _projectEvents(await _events([page], attestedScripts: true));
    expect(result.scenes, hasLength(1));
    expect(result.registry.records.single.definitionOrNull!.source.kind,
        NarrativeEventSourceKind.triggerEnter);
  }, skip: Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'] == null);

  test('original Center sign retains its complete two-cell bump footprint', () async {
    final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT']!;
    final data = {
      'README.md': utf8.encode('Pokemon Essentials v21.1\n'),
      for (final path in ['Data/MapInfos.rxdata', 'Data/Map100.rxdata',
        'Data/Tilesets.rxdata', 'Data/System.rxdata', 'Data/Scripts.rxdata'])
        path: await File('$root/$path').readAsBytes(),
    };
    expect(_hash(data['Data/Map100.rxdata']!).value,
        '3a101f07319e797c0021212ce5e6adc5344128eaff4b1ea2c4712219289c47a0');
    final source = await _normalize(_source(data), selectedMapIds: {100}, includeEventSystem: true);
    final maps = _nativeMaps(source);
    final map = maps[100]!;
    maps[100] = map.copyWith(layers: [MapLayer.collision(id: 'sign-collision', name: 'Collision',
      collisions: List.generate(map.size.width * map.size.height,
        (index) => index ~/ map.size.width == 25 && [11, 12].contains(index % map.size.width)))]);
    final result = _projectEvents(source, maps: maps);
    final definition = result.registry.records.map((record) => record.definitionOrNull)
        .whereType<NarrativeEventDefinition>().singleWhere((definition) =>
          definition.source.kind == NarrativeEventSourceKind.triggerBump);
    final trigger = result.nativeMaps[100]!.triggers.singleWhere((trigger) => trigger.id == definition.source.toJson()['triggerId']);
    expect(trigger.area.pos, const GridPos(x: 11, y: 25));
    expect(trigger.area.size, const GridSize(width: 2, height: 1));
    final scene = result.scenes.singleWhere((scene) => scene.id == definition.sceneId);
    final condition = scene.graph.nodes.map((node) => node.payload).whereType<SceneConditionPayload>().single.conditionSource;
    expect(condition, SceneConditionSource.playerFacing(direction: EntityFacing.north, expected: true));
    final text = scene.graph.nodes.map((node) => node.payload).whereType<SceneYarnDialoguePayload>().single;
    expect(text.linePolicies.single.feedback.plainText, '“Heal your Pokémon!”\nPokémon Center');
    final event = (result.semanticEvidence['events'] as List).cast<Map>().singleWhere((event) =>
      (event['locator'] as Map)['mapId'] == 100 && (event['locator'] as Map)['eventId'] == 10);
    expect(event['status'], 'adaptedStaticSemantics');
    expect(event['gaps'], isEmpty);
    expect(((event['pages'] as List).single as Map)['sourceContact'], containsPair('reason', 'stationaryFootprintTilesBlocked'));
    expect(result.nativeMaps[100]!.entities.singleWhere((entity) => entity.pos == trigger.area.pos).size,
      const GridSize(width: 2, height: 1));
  }, skip: scriptsPath == null || Platform.environment['AVELUNE_AC13_SOURCE_ROOT'] == null);

  test('two-cell sign cannot be an import candidate outside native bounds', () async {
    final source = await _bookshelfSource(page: _facingSignPage(), eventName: 'Center sign size(2,1)');
    final maps = _bookshelfMaps(source);
    maps[1] = maps[1]!.copyWith(size: const GridSize(width: 2, height: 3), layers: [
      MapLayer.collision(id: 'narrow', name: 'Collision', collisions: [false, false, false, true, true, false]),
    ]);
    final candidates = const SourceEventProjector().characterImportCandidates(
      source: source, analysis: _analyzer(source).analyze(), nativeMaps: maps);
    expect(candidates, isEmpty);
  }, skip: scriptsPath == null);

  test('two-cell sign refuses an overlapping source event on its second cell', () async {
    final source = await _bookshelfSource(page: _facingSignPage(), eventName: 'Center sign size(2,1)',
      extraEvents: {2: _event(2, [_page([_command(0, [])], character: '')], x: 2, y: 1)});
    final result = _projectEvents(source, maps: _bookshelfMaps(source));
    expect(result.registry.records.first.definitionOrNull, isNull);
    expect(result.nativeMaps[1]!.triggers, isEmpty);
  }, skip: scriptsPath == null);

  for (final blocked in [<int>{5, 6}, <int>{5}, <int>{6}, <int>{}]) {
    test('two-cell directional sign requires both native blocked cells $blocked', () async {
      final source = await _bookshelfSource(page: _facingSignPage(), eventName: 'Center sign size(2,1)');
      final result = _projectEvents(source, maps: _bookshelfMaps(source, blockedCells: blocked));
      if (blocked.length == 2) {
        expect(result.registry.records.single.definitionOrNull, isNotNull);
        expect(result.nativeMaps[1]!.triggers.single.area.size, const GridSize(width: 2, height: 1));
      } else {
        expect(result.registry.records.single.definitionOrNull, isNull);
        expect(result.nativeMaps[1]!.triggers, isEmpty);
      }
    }, skip: scriptsPath == null);
  }

  for (final entry in {
    'Route 9 sign': r'Route 9\nCerulean City - Rock Tunnel',
    'Rock tunnel sign': r'Rock Tunnel\nDetour to Lavender Town',
    'Power plant sign': 'Power Plant',
  }.entries) {
    test('unit sign ${entry.key} adapts presentation with the proved front bump',
        () async {
      final result = await _projectSign(
          _page([
            _command(101, [r'\w[signskin]' + entry.value]),
            _command(0, []),
          ], trigger: 1, character: ''),
          eventName: entry.key);
      final record = result.registry.records.single;
      expect(record.definitionOrNull, isNotNull,
          reason: 'A qualified unit sign must publish its front bump event.');
      final definition = record.definitionOrNull!;
      expect(record.enabledOrNull, isTrue);
      expect(definition.source.kind, NarrativeEventSourceKind.triggerBump);
      final map = result.nativeMaps[1]!;
      expect(map.triggers.single.area.pos, const GridPos(x: 1, y: 1));
      expect(map.triggers.single.area.size,
          const GridSize(width: 1, height: 1));
      expect(map.entities.single.blocksMovement, isFalse);
      final payload = result.scenes.single.graph.nodes
          .map((node) => node.payload)
          .whereType<SceneYarnDialoguePayload>()
          .single;
      expect(payload.linePolicies.single.feedback.plainText,
          entry.value.replaceAll(r'\n', '\n'));
      final event = (result.semanticEvidence['events'] as List).single as Map;
      final page = (event['pages'] as List).single as Map;
      expect(page['sourceContact'], containsPair('kind', 'front'));
      expect(page['sourceContact'],
          containsPair('reason', 'stationaryTilesBlocked'));
      final adaptation = (page['adaptedCommands'] as List).single as Map;
      expect(adaptation['sourceOpcodes'], [101]);
      expect(adaptation['sourceControl'], r'\w[signskin]');
      expect(adaptation['targetStyle'], 'aveluneNativeDialogue');
      expect(adaptation['equivalenceScope'], ['plainText', 'frontTerrainBump']);
      expect(adaptation['windowSkinParityQualified'], isFalse);
      expect(adaptation['rawDataRefs'], hasLength(1));
      expect((adaptation['span'] as Map)['firstCommandIndex'], 0);
      expect((adaptation['span'] as Map)['lastCommandIndex'], 0);
      expect(result.facts, isEmpty);
      expect(result.worldRules, isEmpty);
      expect(result.nativeMaps.values.expand((map) => map.warps), isEmpty);
      expect(result.semanticEvidence['sourceAdmission'], isFalse);
      expect(result.semanticEvidence['globalPlayabilityCertified'], isFalse);
    }, skip: scriptsPath == null);
  }

  for (final entry in {
    2: EntityFacing.south, 4: EntityFacing.west,
    6: EntityFacing.east, 8: EntityFacing.north,
  }.entries) {
    test('directional sign maps source facing ${entry.key} to native ${entry.value.name}',
        () async {
      final result = await _projectSign(_facingSignPage(condition: [6, -1, entry.key]));
      final record = result.registry.records.single;
      expect(record.definitionOrNull, isNotNull);
      expect(record.definitionOrNull!.source.kind, NarrativeEventSourceKind.triggerBump);
      final scene = result.scenes.single;
      final condition = scene.graph.nodes.map((node) => node.payload)
          .whereType<SceneConditionPayload>().single.conditionSource;
      expect(condition, SceneConditionSource.playerFacing(direction: entry.value, expected: true));
      for (final facing in Direction.values) {
        final world = GameplayWorldState.initial(map: result.nativeMaps[1]!,
            playerPos: const GridPos(x: 0, y: 0), playerFacing: facing);
        final shown = <String>[];
        final execution = await SceneRuntimeExecutor(callbacks:
            SceneRuntimeExecutionCallbacks(
              evaluateCondition: (intent) => evaluateScenePlayerFacing(
                  source: intent.conditionSource!, world: world) ? 'true' : 'false',
              showDialogue: (intent) {
                shown.add(intent.linePolicies.single.feedback.plainText);
                return 'completed';
              },
              startBattle: (_) => throw StateError('Sign has no battle'),
              playCinematic: (_) => throw StateError('Sign has no cinematic'),
              applyConsequence: (_) => throw StateError('Sign has no consequence'),
              executeInteractiveCommand: (_) => throw StateError('Sign has no service'),
            )).execute(buildSceneRuntimePlan(scene).plan!);
        expect(execution.status, SceneRuntimeExecutionStatus.completed);
        expect(shown, facing == entry.value.asDirection
            ? ['“Heal your Pokémon!”\nPokémon Center'] : isEmpty);
      }
      final evidence = (result.semanticEvidence['events'] as List).single as Map;
      final page = (evidence['pages'] as List).single as Map;
      final adaptation = (page['adaptedCommands'] as List).single as Map;
      expect(adaptation['sourceOpcodes'], [111, 101, 401, 412]);
      expect(adaptation['sourceControl'], r'\w[signskin]');
      expect(adaptation['sourceFacingDirection'], entry.key);
      expect(adaptation['nativeFacingDirection'], entry.value.name);
      expect(adaptation['windowSkinParityQualified'], isFalse);
      expect(result.facts, isEmpty);
      expect(result.worldRules, isEmpty);
    }, skip: scriptsPath == null);
  }

  for (final variant in ['actor', 'direction', 'arity', 'skin', 'control', 'suffix']) {
    test('directional sign retains whole-event quarantine for $variant', () async {
      final page = _facingSignPage(
          condition: switch (variant) {
            'actor' => [6, 0, 8], 'direction' => [6, -1, 5],
            'arity' => [6, -1, 8, true], _ => [6, -1, 8],
          },
          text: variant == 'skin' ? r'\w[unknown]Heal'
              : variant == 'control' ? r'\w[signskin]Heal\unknown'
              : r'\w[signskin]“Heal your Pokémon!”\nPokémon ',
          suffix: variant == 'suffix' ? [_command(355, ['unknown()'])] : const []);
      final result = await _projectSign(page);
      expect(result.registry.records.single.definitionOrNull, isNull);
      expect(result.nativeMaps[1]!.entities, isEmpty);
      expect(result.nativeMaps[1]!.triggers, isEmpty);
      expect(result.scenes, isEmpty);
      expect(result.dialogues, isEmpty);
      expect(result.facts, isEmpty);
    }, skip: scriptsPath == null);
  }

  for (final entry in [(false, true), (true, false), (false, false)]) {
    test('directional sign refuses source/native collision ${entry.$1}/${entry.$2}', () async {
      final result = await _projectSign(_facingSignPage(),
          blockedSource: entry.$1, blockedNative: entry.$2);
      expect(result.registry.records.single.definitionOrNull, isNull);
      expect(result.nativeMaps[1]!.entities, isEmpty);
      expect(result.nativeMaps[1]!.triggers, isEmpty);
      expect(result.scenes, isEmpty);
    }, skip: scriptsPath == null);
  }

  for (final entry in [(false, true), (true, false), (false, false)]) {
    test('unit sign refuses source/native collision ${entry.$1}/${entry.$2}',
        () async {
      final result = await _projectSign(
          _page([
            _command(101, [r'\w[signskin]Route 9']),
            _command(0, []),
          ], trigger: 1, character: ''),
          blockedSource: entry.$1,
          blockedNative: entry.$2);
      expect(result.registry.records.single.definitionOrNull, isNull);
      expect(result.scenes, isEmpty);
      expect(result.dialogues, isEmpty);
      expect(result.facts, isEmpty);
      expect(result.nativeMaps[1]!.triggers, isEmpty);
      expect(result.nativeMaps[1]!.entities, isEmpty);
    }, skip: scriptsPath == null);
  }

  test('unit sign refuses a missing raw page attestation without crashing',
      () async {
    final source = await _events([
      _page([
        _command(101, [r'\w[signskin]Route 9']),
        _command(0, []),
      ], trigger: 1, character: ''),
    ], tileset: _tileset(blockedTile: 400), attestedScripts: true);
    final original = _analyzer(source).analyze();
    final event = original.events.single;
    final page = event.pages.single;
    final analysis = SourceEventAnalysis(
        profile: original.profile,
        diagnostics: original.diagnostics,
        events: [
          SourceEventDefinition(
              sourceMapId: event.sourceMapId,
              sourceEventId: event.sourceEventId,
              sourceFileId: event.sourceFileId,
              identity: event.identity,
              name: event.name,
              x: event.x,
              y: event.y,
              locator: event.locator,
              pages: [
                SourceEventPageAnalysis(
                    sourcePage: page.sourcePage,
                    locator: page.locator,
                    condition: page.condition,
                    graphic: page.graphic,
                    body: page.body,
                    rawDataRef: null,
                    diagnostics: page.diagnostics),
              ]),
        ]);
    final maps = _nativeMaps(source);
    maps[1] = maps[1]!.copyWith(layers: [
      MapLayer.collision(
          id: 'sign_collision',
          name: 'Collision',
          collisions: List.generate(6, (index) => index == 4)),
    ]);
    final result = const SourceEventProjector().project(
        source: source, analysis: analysis, nativeMaps: maps);
    expect(result.registry.records.single.definitionOrNull, isNull);
    expect(result.scenes, isEmpty);
    expect(result.dialogues, isEmpty);
    expect(result.facts, isEmpty);
    expect(result.nativeMaps[1]!.triggers, isEmpty);
    expect(result.nativeMaps[1]!.entities, isEmpty);
  }, skip: scriptsPath == null);

  for (final text in [
    r'\w[other]Route 9',
    r'\w[signskinRoute 9',
    r'\w[signskin]Route 9\PN',
    r'\w[signskin]Route 9\w[signskin]',
    r'\W[signskin]Route 9',
    r'Route 9\w[signskin]',
    r'\w[signskin]',
  ]) {
    test('unit sign rejects unknown or malformed presentation $text', () async {
      final result = await _projectSign(_page([
        _command(101, [text]),
        _command(0, []),
      ], trigger: 1, character: ''));
      expect(result.registry.records.single.definitionOrNull, isNull);
      expect(result.scenes, isEmpty);
      expect(result.dialogues, isEmpty);
      expect(result.facts, isEmpty);
      expect(result.nativeMaps[1]!.triggers, isEmpty);
      expect(result.nativeMaps[1]!.entities, isEmpty);
    }, skip: scriptsPath == null);
  }

  for (final variant in ['unknown', 'reward', 'moving', 'wide', 'touchThrough']) {
    test('unit sign keeps every dependent effect quarantined for $variant',
        () async {
      final page = _page([
        _command(101, [r'\w[signskin]Route 9']),
        if (variant == 'unknown') _command(355, ['unqualified_call()']),
        if (variant == 'reward') _command(123, ['A', 0]),
        _command(0, []),
      ], trigger: 1, character: '');
      if (variant == 'moving') page.fields['@move_type'] = 1;
      if (variant == 'touchThrough') page.fields['@through'] = true;
      final result = await _projectSign(page,
          eventName: variant == 'wide' ? 'Sign size(2,1)' : 'Route sign');
      expect(result.registry.records.single.definitionOrNull, isNull);
      expect(result.scenes, isEmpty);
      expect(result.dialogues, isEmpty);
      expect(result.facts, isEmpty);
      expect(result.nativeMaps[1]!.triggers, isEmpty);
      expect(result.nativeMaps[1]!.entities, isEmpty);
    }, skip: scriptsPath == null);
  }

  test('hidden item player touch requires source bump semantics', () async {
    final page = _page([
      _command(101, ['Hidden touch'])
    ], trigger: 1, character: '')
      ..fields['@through'] = true;
    final result = _projectEvents(
        await _events([page], eventName: 'HiddenItem', attestedScripts: true));
    expect(result.registry.records.single.definitionOrNull, isNull);
    expect(result.scenes, isEmpty);
    expect(jsonEncode(result.semanticEvidence),
        contains('sourceTerrainBumpUnqualified'));
  }, skip: scriptsPath == null);
  test(
      'player touch on an impassable source cell is not changed into an enter trigger',
      () async {
    final page = _page([
      _command(101, ['Blocked touch'])
    ], trigger: 1, character: '')
      ..fields['@through'] = true;
    final result = _projectEvents(await _events([page],
        tileset: _tileset(blockedTile: 400), attestedScripts: true));
    expect(result.registry.records.single.definitionOrNull, isNull);
    expect(result.scenes, isEmpty);
    expect(jsonEncode(result.semanticEvidence),
        contains('sourceTerrainBumpUnqualified'));
  }, skip: scriptsPath == null);
  test(
      'source event size directives do not qualify with a smaller native footprint',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(101, ['Large actor'])
      ])
    ], eventName: 'Npc size(2,1)'));
    expect(result.registry.records.single.definitionOrNull, isNull);
    expect(result.nativeMaps[1]!.entities, isEmpty);
    expect(jsonEncode(result.semanticEvidence),
        contains('eventFootprintUnsupported'));
  });
  test(
      'empty source event graphics do not block the player under the attested oracle',
      () async {
    final source = await _events([
      _page([
        _command(101, ['Hidden item'])
      ], character: '')
    ], eventName: 'HiddenItem original');
    final result = _projectEvents(source);
    final map = result.nativeMaps[1]!;
    final project = ProjectManifest(
        name: 'Invisible obstacle',
        tilesets: const [],
        maps: [
          ProjectMapEntry(
              id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
        ]);
    final world = GameplayWorldState.initial(
        map: map,
        project: project,
        playerPos: const GridPos(x: 1, y: 1),
        tileWidth: 32,
        tileHeight: 32);
    expect(map.entities.single.blocksMovement, isFalse);
    expect(world.worldStaticObstaclesCollidePlayerCollisionRect(), isFalse);
  });
  test('current cell source interactions quarantine the entire invisible event',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(101, ['Current cell']),
        _command(123, ['A', 0])
      ], character: '')
    ]));
    expect(result.registry.records.single.definitionOrNull, isNull);
    expect(result.nativeMaps[1]!.entities, isEmpty);
    expect(result.scenes, isEmpty);
    expect(result.facts, isEmpty);
    expect(jsonEncode(result.semanticEvidence),
        contains('interactionFootprintUnsupported'));
  });

  test('bookshelf projects one native two-cell action footprint', () async {
    final source = await _bookshelfSource();
    final result = _projectEvents(source, maps: _bookshelfMaps(source));
    final record = result.registry.records.single;
    expect(record.definitionOrNull, isNotNull,
        reason: 'Both proved blocked cells must share one action event.');
    expect(record.definitionOrNull!.source.kind,
        NarrativeEventSourceKind.entityInteract);
    final map = result.nativeMaps[1]!;
    final entity = map.entities.single;
    expect(entity.size, const GridSize(width: 2, height: 1));
    expect(entity.pos, const GridPos(x: 1, y: 1));
    expect(entity.blocksMovement, isFalse);
    expect(map.triggers, isEmpty);
    expect(result.facts, isEmpty);
    final payload = result.scenes.single.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneYarnDialoguePayload>()
        .single;
    expect(payload.linePolicies.single.feedback.plainText,
        "It's crammed full of Pokémon\nbooks.");
    for (final approach in [
      (const GridPos(x: 1, y: 2), Direction.north),
      (const GridPos(x: 2, y: 2), Direction.north),
      (const GridPos(x: 0, y: 1), Direction.east),
      (const GridPos(x: 3, y: 1), Direction.west),
    ]) {
      final world = GameplayWorldState.initial(
          map: map, playerPos: approach.$1, playerFacing: approach.$2,
          tileWidth: 32, tileHeight: 32);
      final interaction = stepGameplayWorld(world, const InteractIntent());
      expect(interaction, isA<EntityInteracted>(), reason: '$approach');
      expect((interaction as EntityInteracted).entity.id, entity.id);
    }
    final event = (result.semanticEvidence['events'] as List).single as Map;
    final page = (event['pages'] as List).single as Map;
    final adaptation = (page['adaptedCommands'] as List).single as Map;
    expect(adaptation['nativeContract'], 'staticActionAcrossFootprint');
    expect(adaptation['sourceFootprint'], {'width': 2, 'height': 1});
    expect(adaptation['sourceCellPassages'], hasLength(2));
  }, skip: scriptsPath == null);

  test('bookshelf rejects native dimensions before footprint qualification', () async {
    final source = await _bookshelfSource();
    final maps = _bookshelfMaps(source, blockedCells: const {3, 4});
    maps[1] = maps[1]!.copyWith(size: const GridSize(width: 2, height: 6));
    expect(() => _projectEvents(source, maps: maps),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'events.target.binding')));
  }, skip: scriptsPath == null);

  for (final blocked in [<int>{5}, <int>{6}, <int>{}]) {
    for (final mismatch in ['source', 'native']) {
      test('bookshelf refuses $mismatch collision cells $blocked', () async {
        final source = await _bookshelfSource(
            blockedCells: mismatch == 'source' ? blocked : const {5, 6});
        final result = _projectEvents(source,
            maps: _bookshelfMaps(source,
                blockedCells: mismatch == 'native' ? blocked : const {5, 6}));
        expect(result.registry.records.single.definitionOrNull, isNull);
        expect(result.nativeMaps[1]!.entities, isEmpty);
        expect(result.nativeMaps[1]!.triggers, isEmpty);
        expect(result.scenes, isEmpty);
        expect(result.dialogues, isEmpty);
        expect(result.facts, isEmpty);
      }, skip: scriptsPath == null);
    }
  }

  for (final variant in ['unknown', 'through', 'moving', 'large', 'raw']) {
    test('bookshelf retains whole-event quarantine for $variant', () async {
      final page = _page([
        _command(101, [r"It's crammed full of Pokémon\nbooks."]),
        if (variant == 'unknown') _command(355, ['pbShowMap']),
        _command(0, []),
      ], character: '');
      if (variant == 'through') page.fields['@through'] = true;
      if (variant == 'moving') page.fields['@move_type'] = 1;
      if (variant == 'raw') page.fields['@unknown'] = false;
      final source = await _bookshelfSource(page: page,
          eventName: variant == 'large' ? 'Bookshelf size(3,1)' : 'Bookshelf size(2,1)');
      final result = _projectEvents(source, maps: _bookshelfMaps(source));
      expect(result.registry.records.single.definitionOrNull, isNull);
      expect(result.nativeMaps[1]!.entities, isEmpty);
      expect(result.nativeMaps[1]!.triggers, isEmpty);
      expect(result.scenes, isEmpty);
      expect(result.dialogues, isEmpty);
      expect(result.facts, isEmpty);
    }, skip: scriptsPath == null);
  }

  test(
      'through source interaction is not silently changed to front cell interaction',
      () async {
    final page = _page([
      _command(101, ['Current cell'])
    ])
      ..fields['@through'] = true;
    final result = _projectEvents(await _events([page]));
    expect(result.registry.records.single.definitionOrNull, isNull);
    expect(result.scenes, isEmpty);
    expect(jsonEncode(result.semanticEvidence),
        contains('interactionFootprintUnsupported'));
  });
  test(
      'source counter reach is preserved inactive until native interaction supports it',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(101, ['Across a counter'])
      ])
    ], tileset: _tileset(counterTile: 385)));
    expect(result.registry.records.single.definitionOrNull, isNull);
    expect(result.scenes, isEmpty);
    expect(jsonEncode(result.semanticEvidence),
        contains('counterInteractionReachUnsupported'));
  });
  test(
      'projection map mutations build canonical action drafts with their map context',
      () async {
    final touch = _page([
      _command(101, ['Touch'])
    ], trigger: 1, character: '')
      ..fields['@through'] = true;
    final source = await _events(
        [
          _page([
            _command(201, [0, 8, 2, 1, 0, 0])
          ], character: '')
        ],
        eventName: 'HiddenItem warp',
        attestedScripts: true,
        extraEvents: {
          2: _event(2, [touch], x: 2)
        });
    final maps = _nativeMaps(source);
    final result = _projectEvents(source);
    expect(result.mutations.map((mutation) => mutation.actionId),
        containsAll(['entity.upsert', 'trigger.create', 'warp.create']));
    final project =
        ProjectManifest(name: 'Projection', tilesets: const [], maps: [
      for (final map in maps.values)
        ProjectMapEntry(
            id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
    ]);
    for (final mutation in result.mutations.where((m) => [
          'entity.upsert',
          'trigger.create',
          'warp.create'
        ].contains(m.actionId))) {
      final bytes = {
        for (final map in maps.values)
          'map:${map.id}': utf8.encode(jsonEncode(map.toJson()))
      };
      final revision = 'sha256:${_hash([1]).value}';
      final context = AuthoringPlanningContext(
          snapshot: ProjectSnapshot(
              projectHandle: const ProjectHandle('prj_projection'),
              revision: revision,
              manifest: project,
              maps: maps.values,
              resourceFingerprints: {
                for (final entry in bytes.entries)
                  entry.key: computeAuthoringBytesFingerprint(entry.value,
                      logicalName: 'maps/${entry.key.substring(4)}.json')
              },
              resourceBytes: bytes),
          request: AuthoringRequest(
              requestId: mutation.operationId.value,
              actionId: mutation.actionId,
              actionVersion: 1,
              workspaceHandle: 'workspace_projection',
              expectedRevision: revision,
              parameters: mutation.parameters),
          planId: 'plan_projection',
          seed: 1);
      final draft = switch (mutation.actionId) {
        'entity.upsert' => const EntityActions().build(context),
        'trigger.create' => const TriggerZoneActions().build(context),
        'warp.create' => const WarpConnectionActions().build(context),
        _ => throw StateError('Unexpected map mutation'),
      };
      expect(draft.changeSet.changes, hasLength(1));
      final after = MapData.fromJson(
          jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
              as Map<String, dynamic>);
      maps[maps.entries.singleWhere((e) => e.value.id == after.id).key] = after;
    }
    expect(
        canonicalJsonOf(jsonDecode(jsonEncode(maps[1]!.toJson()))),
        canonicalJsonOf(
            jsonDecode(jsonEncode(result.nativeMaps[1]!.toJson()))));
    expect(
        canonicalJsonOf(jsonDecode(jsonEncode(maps[8]!.toJson()))),
        canonicalJsonOf(
            jsonDecode(jsonEncode(result.nativeMaps[8]!.toJson()))));
  }, skip: scriptsPath == null);

  test(
      'projection Facts and World Rules pass their canonical authoring handlers',
      () async {
    final result = _projectEvents(await _events([
      _withCondition(
          _page([
            _command(101, ['Visible'])
          ]),
          {'@self_switch_valid': true})
    ]));
    var project =
        ProjectManifest(name: 'Projection', tilesets: const [], maps: [
      for (final map in result.nativeMaps.values)
        ProjectMapEntry(
            id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
    ]);
    for (final fact in result.facts) {
      project = const FactRuleActions().createFact(project, fact: fact);
    }
    for (final rule in result.worldRules) {
      project = const FactRuleActions().createWorldRule(project,
          maps: result.nativeMaps.values.toList(), rule: rule);
    }
    for (final dialogue in result.dialogues) {
      project = const DialogueActions().create(project,
          entry: dialogue, source: result.dialogueSources[dialogue.id]!);
    }
    for (final scene in result.scenes) {
      project = const SceneActions().upsert(project,
          maps: result.nativeMaps.values.toList(), scene: scene);
    }
    project = const EventV2Actions().setRegistryMode(project,
        maps: result.nativeMaps.values.toList(), mode: EventSystemMode.v2Only);
    for (final record in result.registry.records) {
      try {
        project = const EventV2Actions().upsertRecord(project,
            maps: result.nativeMaps.values.toList(), record: record);
      } on NarrativeAuthoringException catch (error) {
        fail('${error.code}: ${error.details}');
      }
    }
    expect(project.eventRegistry!.records, hasLength(1));
    expect(project.facts, result.facts);
  });

  test(
      'source character binding resolves exact pattern and direction without borrowing defaults',
      () async {
    final page = _page([
      _command(101, ['Salut'])
    ], character: 'SourceNpc');
    (page.fields['@graphic'] as _RubyObject)
        .fields
        .addAll({'@pattern': 3, '@direction': 8});
    final bytes = _project(maps: {
      1: _map(events: {
        1: _event(1, [page])
      })
    });
    bytes['Graphics/Characters/SourceNpc.png'] = _png();
    final files = _source(bytes);
    final source = await _normalize(files, includeEventSystem: true);
    final file = files.snapshot.entries.singleWhere(
        (f) => f.relativePath == 'Graphics/Characters/SourceNpc.png');
    final key = sourceEventCharacterBindingKey(
        characterName: 'SourceNpc', pattern: 3, direction: 8);
    final result = const SourceEventProjector().project(
        source: source,
        analysis: _analyzer(source).analyze(),
        nativeMaps: _nativeMaps(source),
        characterBindings: {
          key: SourceEventCharacterBinding(
              characterId: 'native_char_exact',
              sourceSnapshotHash: source.snapshot.canonicalHash,
              sourceFileId: file.fileId,
              sourceFileHash: file.sha256!,
              sourcePattern: 3,
              sourceDirection: 8)
        });
    expect(result.registry.records.single.definitionOrNull, isNotNull);
    expect(result.nativeMaps[1]!.entities.single.npc!.characterId,
        'native_char_exact');
    expect(
        result.nativeMaps[1]!.entities.single.npc!.facing, EntityFacing.north);
    expect(result.nativeMaps[1]!.entities.single.blocksMovement, isTrue);
    expect(
        result.nativeMaps[1]!.entities.single
            .properties[mapEntityCollisionWidthProperty],
        '1');
    expect(
        result.nativeMaps[1]!.entities.single
            .properties[mapEntityCollisionHeightProperty],
        '1');
    expect(
        key,
        isNot(sourceEventCharacterBindingKey(
            characterName: 'SourceNpc', pattern: 0, direction: 8)));
    expect(
        key,
        isNot(sourceEventCharacterBindingKey(
            characterName: 'SourceNpc', pattern: 3, direction: 2)));
  });

  test(
      'single fact page controls native entity presence without inventing a source base page',
      () async {
    final result = _projectEvents(await _events([
      _withCondition(
          _page([
            _command(101, ['Visible seulement après A'])
          ]),
          {'@self_switch_valid': true})
    ]));
    expect(result.registry.records.single.definitionOrNull, isNotNull);
    expect(result.worldRules, hasLength(2));
    final map = result.nativeMaps[1]!;
    final project = ProjectManifest(
        name: 'Presence',
        tilesets: const [],
        maps: [
          ProjectMapEntry(
              id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
        ],
        facts: result.facts,
        worldRules: result.worldRules);
    expect(
        diagnoseWorldRules(project, maps: result.nativeMaps.values.toList())
            .hasErrors,
        isFalse);
    expect(result.worldRules.map((r) => r.effect.kind).toSet(),
        {WorldRuleEffectKind.entityHidden, WorldRuleEffectKind.entityVisible});
    expect(
        result.worldRules
            .map((r) => r.source.resolvedExpectedFactValue.boolValue)
            .toSet(),
        {false, true});
  });

  test(
      'EV-A projects original self switch pages with exclusive guards and scoped Facts',
      () async {
    final pages = [
      _page([
        _command(101, ['Bienvenue']),
        _command(123, ['A', 0])
      ]),
      _withCondition(
          _page([
            _command(101, ['Tu es de retour'])
          ]),
          {'@self_switch_valid': true})
    ];
    final source =
        await _events(pages, extraEvents: {2: _event(2, pages, x: 2)});
    final result = _projectEvents(source);
    final self =
        sourceEventFactBindingId(_analyzer(source).selfFactId(1, 1, 'A'));
    final other =
        sourceEventFactBindingId(_analyzer(source).selfFactId(1, 2, 'A'));
    expect(result.registry.mode, EventSystemMode.v2Only);
    expect(result.registry.records, hasLength(4));
    expect(result.facts.map((f) => f.id).toSet(), {self, other});
    expect(self, isNot(other));
    final records = result.registry.records
        .where((r) =>
            r.definitionOrNull!.source.toJson()['entityId'] ==
            result.nativeMaps[1]!.entities.first.id)
        .toList();
    for (final enabled in [false, true]) {
      final active = records
          .where((r) =>
              r.enabledOrNull == true &&
              _guard(r.definitionOrNull!.conditionExpression, {self: enabled}))
          .toList();
      expect(active, hasLength(1));
      expect(active.single.definitionOrNull!.priority, enabled ? 1 : 0);
    }
    final action = result.scenes
        .expand((s) => s.graph.nodes)
        .map((n) => n.payload)
        .whereType<SceneActionPayload>()
        .map((p) => p.consequence)
        .whereType<SceneSetFactConsequence>();
    expect(action.map((a) => a.factId).toSet(), {self, other});
    expect(result.staticSemanticsQualified, isTrue);
    expect(result.playableCertified, isFalse);
  });

  test('EVT01 retains a last true empty page including unconditional shadowing',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(101, ['Ancienne page'])
      ]),
      _page([_command(0, [])])
    ]));
    final records = result.registry.records;
    expect(records, hasLength(2));
    expect(records.where((r) => r.enabledOrNull == true), hasLength(1));
    expect(records.last.definitionOrNull!.priority, 1);
    final scene = result.scenes
        .singleWhere((s) => s.id == records.last.definitionOrNull!.sceneId);
    expect(scene.graph.nodes.map((n) => n.kind).toList(),
        [SceneNodeKind.start, SceneNodeKind.end]);
    expect(scene.graph.edges.single.fromPortId, 'completed');
  });

  test(
      'unknown upper page quarantines the whole event with no executable lower page',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(101, ['Ne pas jouer'])
      ]),
      _page([
        _command(355, ['unknown_reward()']),
        _command(123, ['A', 0])
      ]),
    ]));
    expect(result.registry.records, hasLength(1));
    expect(result.registry.records.single.definitionOrNull, isNull);
    expect(result.nativeMaps[1]!.entities, isEmpty);
    expect(result.scenes, isEmpty);
    expect(result.facts, isEmpty);
    expect(result.staticSemanticsQualified, isFalse);
    expect(jsonEncode(result.semanticEvidence), contains('sourceQuarantined'));
  });

  test('EVT04 choice alternatives retain their ordered branches then rejoin',
      () async {
    final source = await _events([
      _page([
        _command(101, ['Choisis']),
        _command(102, [
          ['Oui', 'Non'],
          0
        ]),
        _command(402, [0, 'Oui']),
        _command(123, ['A', 0], indent: 1),
        _command(402, [1, 'Non']),
        _command(123, ['B', 0], indent: 1),
        _command(404, []),
        _command(121, [1, 1, 0]),
      ])
    ]);
    final result = _projectEvents(source);
    final compiled = const YarnDialogueCompiler()
        .compile(result.dialogueSources.values.single);
    final choices = compiled.nodes.single.steps
        .whereType<RuntimeDialogueChoiceBlock>()
        .single;
    expect(choices.choices.map((c) => c.text).toList(), ['Oui', 'Non']);
    final scene = result.scenes.single;
    final yarn = scene.graph.nodes
        .singleWhere((n) => n.kind == SceneNodeKind.yarnDialogue);
    final ports = scene.graph.edges
        .where((e) => e.fromNodeId == yarn.id)
        .map((e) => e.fromPortId)
        .toList();
    expect(ports, containsAll(['choice_0', 'choice_1', 'completed']));
    final switchId =
        sourceEventFactBindingId(_analyzer(source).globalFactId(1));
    expect(
        scene.graph.nodes
            .map((n) => n.payload)
            .whereType<SceneActionPayload>()
            .map((a) => a.consequence)
            .whereType<SceneSetFactConsequence>()
            .any((a) => a.factId == switchId),
        isTrue);
  });

  test(
      'EVT04 true cancellation routes its own branch without adding a visible option',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(102, [
          ['Continuer'],
          5
        ]),
        _command(402, [0, 'Continuer']),
        _command(123, ['A', 0], indent: 1),
        _command(403, []),
        _command(123, ['B', 0], indent: 1),
        _command(404, []),
      ])
    ]));
    expect(result.registry.records.single.definitionOrNull, isNotNull);
    final payload = result.scenes.single.graph.nodes
        .map((n) => n.payload)
        .whereType<SceneYarnDialoguePayload>()
        .single;
    final policy = payload.choicePolicies.single;
    expect(policy.nodeName, 'Start');
    expect(policy.choiceIndex, 0);
    expect(
        policy.cancellation.kind, SceneDialogueChoiceCancellationKind.branch);
    expect(policy.cancellation.outcomeId, 'cancel');
    expect(payload.expectedOutcomes, ['choice_0', 'cancel']);
    expect(result.dialogues.single.declaredOutcomes.map((o) => o.id).toList(),
        ['choice_0']);
    final compiled = const YarnDialogueCompiler()
        .compile(result.dialogueSources.values.single);
    expect(
        compiled.nodes.single.steps
            .whereType<RuntimeDialogueChoiceBlock>()
            .single
            .choices,
        hasLength(1));
    expect(payload.toJson()['choicePolicies'], isNotNull);
  });

  test('cancel to choice executes the existing option through a typed policy',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(102, [
          ['Oui', 'Non'],
          2
        ]),
        _command(402, [0, 'Oui']),
        _command(123, ['A', 0], indent: 1),
        _command(402, [1, 'Non']),
        _command(123, ['B', 0], indent: 1),
        _command(404, []),
      ])
    ]));
    expect(result.registry.records.single.definitionOrNull, isNotNull);
    final payload = result.scenes.single.graph.nodes
        .map((n) => n.payload)
        .whereType<SceneYarnDialoguePayload>()
        .single;
    expect(payload.choicePolicies.single.cancellation.kind,
        SceneDialogueChoiceCancellationKind.choice);
    expect(payload.choicePolicies.single.cancellation.outcomeId, 'choice_1');
    expect(payload.choicePolicies.single.defaultOutcomeId, 'choice_0');
    expect(payload.expectedOutcomes, ['choice_0', 'choice_1']);
  });

  test(
      'EV-B recognized pickup stays quarantined until bag messages and audio parity exist',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(111, [12, 'pbItemBall(:POTION)']),
        _command(123, ['A', 0], indent: 1),
        _command(412, []),
      ]),
      _withCondition(_page([_command(0, [])]), {'@self_switch_valid': true})
    ]));
    expect(result.registry.records.single.definitionOrNull, isNull);
    expect(result.facts, isEmpty);
    expect(result.scenes, isEmpty);
    expect(jsonEncode(result.semanticEvidence),
        contains('pickupBagCapacityMessagesAudio'));
    expect(result.nativeMaps[1]!.entities, isEmpty);
  });

  test(
      'EV-B quantity greater than one reports possible source partial addition',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(111, [12, 'pbItemBall(:POTION, 2)']),
        _command(412, []),
      ])
    ]));
    expect(jsonEncode(result.semanticEvidence),
        contains('pickupFailureMayPartiallyAdd'));
    expect(result.registry.records.single.definitionOrNull, isNull);
  });

  test(
      'EV-C literal destination is included and the arrival cannot trigger on enter',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(201, [0, 8, 2, 1, 0, 0])
      ])
    ]));
    final warp = result.nativeMaps[8]!.warps.single;
    expect(warp.pos, const GridPos(x: 2, y: 1));
    expect(warp.triggerMode, MapWarpTriggerMode.sceneOnly);
    final action = result.scenes.single.graph.nodes
        .map((n) => n.payload)
        .whereType<SceneActionPayload>()
        .single
        .interactiveCommand as SceneWarpInteractiveCommand;
    expect(action.destinationMapId, result.nativeMaps[8]!.id);
    expect(action.warpId, warp.id);
    expect(result.mutations.any((m) => m.actionId == 'warp.create'), isTrue);
    expect(
        result.mutations.indexWhere((m) => m.actionId == 'warp.create'),
        lessThan(
            result.mutations.indexWhere((m) => m.actionId == 'scene.upsert')));
  });

  test('EV-C excluded target or forced direction prevents any active transfer',
      () async {
    final source = await _events([
      _page([
        _command(201, [0, 8, 2, 1, 0, 0])
      ])
    ]);
    final missing = _projectEvents(source, maps: {1: _nativeMaps(source)[1]!});
    expect(missing.registry.records.single.definitionOrNull, isNull);
    final directed = _projectEvents(await _events([
      _page([
        _command(201, [0, 8, 2, 1, 2, 0])
      ])
    ]));
    expect(directed.registry.records.single.definitionOrNull, isNull);
  });

  test(
      'unbound graphics quarantine the event without borrowing a native default NPC',
      () async {
    final result = _projectEvents(await _events([
      _page([
        _command(101, ['Salut'])
      ], character: 'SourceNpc')
    ]));
    expect(result.registry.records.single.definitionOrNull, isNull);
    expect(result.nativeMaps[1]!.entities, isEmpty);
    expect(jsonEncode(result.semanticEvidence),
        contains('characterBindingMissing'));
  });

  test(
      'replay is deterministic bound to the source and uses canonical semantic actions',
      () async {
    final source = await _events([
      _page([
        _command(101, ['  title: danger <<jump evil>>  '])
      ])
    ]);
    final first = _projectEvents(source), second = _projectEvents(source);
    expect(canonicalJsonOf(first.semanticEvidence),
        canonicalJsonOf(second.semanticEvidence));
    expect(first.operationIds.map((o) => o.value).toSet(),
        hasLength(first.operationIds.length));
    expect(first.mutations.first.actionId, 'event_v2.registry_mode.set');
    expect(first.mutations.map((m) => m.actionId), isNot(contains('map.save')));
    expect(first.artifacts, hasLength(1));
    expect(first.artifacts.single.reference.mediaType, 'application/json');
    final doc = const YarnDialogueCompiler()
        .compile(first.dialogueSources.values.single);
    expect((doc.nodes.single.steps.single as RuntimeDialogueLine).text,
        '  title: danger <<jump evil>>  ');
    expect(() => first.nativeMaps.clear(), throwsUnsupportedError);
    expect(() => first.semanticEvidence.clear(), throwsUnsupportedError);
  });
}
