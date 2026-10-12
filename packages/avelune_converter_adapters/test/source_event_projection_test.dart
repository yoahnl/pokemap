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

final class _RubyObject {
  _RubyObject(this.className, this.fields);
  final String className;
  final Map<String, Object?> fields;
}

final class _RubyBytes {
  const _RubyBytes(this.bytes);
  final List<int> bytes;
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
    Map<int, _RubyObject>? extraEvents}) async {
  final data = _project(maps: {
    1: _map(events: {1: _event(1, pages, name: eventName), ...?extraEvents}),
    8: _map(),
  }, tileset: tileset);
  data['Graphics/Characters/QualifiedNpc.png'] = _png();
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

void main() {
  test('hidden item player touch requires source bump semantics', () async {
    final page = _page([
      _command(101, ['Hidden touch'])
    ], trigger: 1, character: '')
      ..fields['@through'] = true;
    final result =
        _projectEvents(await _events([page], eventName: 'HiddenItem'));
    expect(result.registry.records.single.definitionOrNull, isNull);
    expect(result.scenes, isEmpty);
    expect(jsonEncode(result.semanticEvidence),
        contains('touchInteractionFootprintUnsupported'));
  });
  test(
      'player touch on an impassable source cell is not changed into an enter trigger',
      () async {
    final page = _page([
      _command(101, ['Blocked touch'])
    ], trigger: 1, character: '')
      ..fields['@through'] = true;
    final result = _projectEvents(
        await _events([page], tileset: _tileset(blockedTile: 400)));
    expect(result.registry.records.single.definitionOrNull, isNull);
    expect(result.scenes, isEmpty);
    expect(jsonEncode(result.semanticEvidence),
        contains('touchInteractionFootprintUnsupported'));
  });
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
        extraEvents: {
          2: _event(2, [touch], x: 2)
        });
    final maps = _nativeMaps(source);
    final result = _projectEvents(source);
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
  });

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
    expect(warp.triggerMode, MapWarpTriggerMode.onBump);
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
