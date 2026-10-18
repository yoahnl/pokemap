import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:avelune_converter_adapters/src/source_event_study_composer.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_static_door_program.dart';

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
    List<Object?>? variables,
    String? eventName,
    _RubyObject? tileset,
    Map<int, _RubyObject>? extraEvents,
    Map<int, _RubyObject>? extraMaps,
    List<Object?>? commonEvents,
    List<int>? commonEventBytes,
    bool attestedScripts = false}) async {
  final data = _project(maps: {
    1: _map(events: {1: _event(1, pages, name: eventName), ...?extraEvents}),
    8: _map(),
    ...?extraMaps,
  }, tileset: tileset);
  data['Graphics/Characters/QualifiedNpc.png'] = _png();
  if (commonEvents != null) {
    data['Data/CommonEvents.rxdata'] = _MarshalFixture().dump(commonEvents);
  }
  if (commonEventBytes != null) data['Data/CommonEvents.rxdata'] = commonEventBytes;
  if (attestedScripts) {
    data['Data/Scripts.rxdata'] =
        await File(Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS']!)
            .readAsBytes();
  }
  if (system) {
    data['Data/System.rxdata'] = _MarshalFixture()
        .dump(_RubyObject('RPG::System', {'@switches': switches,
          '@variables': variables ?? List.filled(128, '')}));
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

Map<int, MapData> _nativeMaps(NormalizedSourceProject source) => {
      for (final map in source.maps.map((ir) => ir.map))
        map.sourceMapId: MapData(
            id: 'native_map_${map.sourceMapId}',
            name: map.name,
            size: GridSize(width: map.width, height: map.height)),
    };

SourceEventProjection _projectEvents(NormalizedSourceProject source,
        {Map<int, MapData>? maps, SourceEventAnalysis? analysis}) =>
    const SourceEventProjector().project(
        source: source,
        analysis: analysis ?? _analyzer(source).analyze(),
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

SourceFileEntry _graphicEntry(String name,
        {Sha256Hash? hash, int length = 4, SourceNodeKind kind = SourceNodeKind.file}) =>
    SourceFileEntry(
        fileId: ConverterId('graphic:${base64Url.encode(utf8.encode(name)).replaceAll('=', '')}'),
        relativePath: 'Graphics/Characters/$name.png',
        kind: kind,
        byteLength: kind == SourceNodeKind.file ? length : 0,
        sha256: kind == SourceNodeKind.file ? hash : null,
        format: 'png',
        family: 'raster');

Future<NormalizedSourceProject> _graphicSource(List<SourceFileEntry> graphics,
    {List<String> names = const ['A', 'B']}) async {
  final data = _project(maps: {
    1: _map(events: {
      1: _event(1, [
        for (final name in names)
          _page([_command(101, ['Hello']), _command(0, [])], character: name),
      ]),
    }),
  });
  final original = _source(data).snapshot;
  final entries = [...original.entries, ...graphics];
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: original.logicalProjectNamespace,
      policyHash: original.policyHash,
      entries: entries,
      diagnostics: [],
      excludedPaths: [],
      profileEvidence: original.profileEvidence,
      state: SourceScanState.complete);
  entries.clear();
  return _normalize(_Files(data, snapshot));
}

SourceEventProjection _projectGiverGraphics(NormalizedSourceProject source) {
  final original = _analyzer(source).analyze();
  final event = original.events.single;
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
              for (final page in event.pages)
                SourceEventPageAnalysis(
                    sourcePage: page.sourcePage,
                    locator: page.locator,
                    condition: page.condition,
                    graphic: page.graphic,
                    body: SourceEventBlock(span: page.body.span, nodes: [
                      ...page.body.nodes,
                      SourcePickupNode(page.body.span,
                          sourceSymbol: 'POTION',
                          quantity: 1,
                          helper: SourceItemGrantHelper.receiveItem),
                    ]),
                    rawDataRef: page.rawDataRef,
                    diagnostics: page.diagnostics),
            ]),
      ]);
  return const SourceEventProjector().project(
      source: source, analysis: analysis, nativeMaps: _nativeMaps(source));
}

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

Future<({GameState state, List<String> shown})> _runNumericScene(
    SourceEventProjection result, SceneAsset scene, {GameState? initial,
    String choice = 'choice_0'}) async {
  var state = initial ?? const GameState(saveId: 'numeric-source');
  final resolver = NarrativeFactRuntimeResolver.fromFacts(result.facts);
  final writer = NarrativeFactRuntimeWriter(resolver);
  final shown = <String>[];
  final plan = buildSceneRuntimePlan(SceneAsset.fromJson(
      jsonDecode(jsonEncode(scene.toJson())) as Map<String, dynamic>));
  expect(plan.plan, isNotNull);
  final execution = await SceneRuntimeExecutor(callbacks:
      SceneRuntimeExecutionCallbacks(
        evaluateCondition: (intent) {
          final source = intent.conditionSource!;
          final value = resolver.resolve(factId: source.sourceId,
              runtimeState: state.narrativeFactRuntimeState,
              storyFlags: state.storyFlags) as NarrativeFactRuntimeResolved;
          return value.narrativeValue.matches(source.resolvedFactOperator,
              source.resolvedExpectedFactValue) ? 'true' : 'false';
        },
        showDialogue: (intent) {
          final document = const YarnDialogueCompiler().compile(result.dialogueSources[intent.dialogueId]!);
          shown.addAll(document.nodes.single.steps.whereType<RuntimeDialogueLine>().map((line) => line.text));
          return intent.declaredOutputPortIds.contains(choice) ? choice : 'completed';
        },
        applyConsequence: (consequence) {
          final set = consequence as SceneSetFactConsequence;
          final write = writer.setFactValue(gameState: state, factId: set.factId,
              value: set.narrativeValue);
          expect(write.success, isTrue);
          state = write.gameState;
          return 'completed';
        },
        startBattle: (_) => throw StateError('No battle'),
        playCinematic: (_) => throw StateError('No cinematic'),
        executeInteractiveCommand: (_) => throw StateError('No interactive command'),
      )).execute(plan.plan!);
  expect(execution.status, SceneRuntimeExecutionStatus.completed);
  return (state: GameState.fromJson(jsonDecode(jsonEncode(state.toJson()))
      as Map<String, dynamic>), shown: shown);
}

void main() {
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];

  group('foreign self-switch native projection', () {
    test('dense seven-event closure has a deterministic bound and replay', () async {
      const count = 7;
      final events = {for (var owner = 1; owner <= count; owner++)
        owner: _event(owner, [_page([
          for (var target = 1; target <= count; target++)
            if (target != owner) _command(355, ['pbSetSelfSwitch($target, "A", true)']),
          _command(0, []),
        ])], x: owner - 1, y: 0)};
      final source = await _events([_page([])], attestedScripts: true,
          extraMaps: {1: _map(width: count, height: 2, events: events)});
      final result = _projectEvents(source);
      expect(result.registry.records.every((record) => record.definitionOrNull != null), isTrue);
      expect(result.facts, hasLength(count));
      final proof = result.semanticEvidence['foreignSelfSwitchQualification'];
      expect(proof, isA<Map>());
      final closures = ((proof as Map)['ownerClosures'] as List).cast<Map>();
      expect(closures, hasLength(count));
      expect(closures.map((closure) => closure['evaluatedStateCount']), everyElement(count));
      expect(closures.map((closure) => closure['distinctStateCount']), everyElement(count));
      expect(closures.map((closure) => closure['arrivalContextCount']), everyElement(1));
      expect(closures.map((closure) => closure['refused']), everyElement(false));
      expect(closures.fold<int>(0, (sum, closure) => sum + (closure['evaluatedStateCount'] as int)), count * count);
      final replay = _projectEvents(source);
      expect(canonicalJsonOf(replay.semanticEvidence), canonicalJsonOf(result.semanticEvidence));
      expect(canonicalJsonOf(replay.mutations.indexed.map((entry) => entry.$2.toJson(entry.$1)).toList()),
          canonicalJsonOf(result.mutations.indexed.map((entry) => entry.$2.toJson(entry.$1)).toList()));
    });
    test('arrival guards distinguish repeated self-switch target contexts', () async {
      final source = await _events([_page([
        _command(355, ['pbSetSelfSwitch(2, "A", true)']),
        _command(201, [0, 8, 2, 1, 0, 0]), _command(0, []),
      ])], attestedScripts: true, extraEvents: {
        2: _event(2, [_page([
          _command(355, ['pbSetSelfSwitch(1, "B", true)']), _command(0, []),
        ])], x: 2, y: 0),
      }, extraMaps: {8: _map(events: {1: _event(1, [_page([
        _command(355, ['setTempSwitchOn("A")']), _command(106, [1]),
        _command(355, ['pbSetSelfSwitch(2, "C", true, 1)']), _command(0, []),
      ], trigger: 3)], x: 2, y: 1)})});
      final result = _projectEvents(source);
      expect(result.registry.records.every((record) => record.definitionOrNull == null), isTrue);
      expect(result.facts, isEmpty);
      final proof = result.semanticEvidence['foreignSelfSwitchQualification'] as Map;
      final closures = (proof['ownerClosures'] as List).cast<Map>();
      final first = closures.singleWhere((closure) => closure['ownerSourceIdentity'] ==
          _analyzer(source).analyze().eventAt(1, 1)!.identity.value);
      expect(first['arrivalContextCount'], 2);
      expect(first['evaluatedStateCount'], first['distinctStateCount']);
      expect(first['refused'], isTrue);
    });
    for (final invalid in ['setter', 'source', 'trigger', 'graphic', 'missingTarget', 'numericWriter']) {
      test('a cycle propagates the later transitive refusal $invalid', () async {
        final source = await _events([_page([
          _command(355, ['pbSetSelfSwitch(2, "A", true)']), _command(0, []),
        ])], attestedScripts: true, extraEvents: {
          2: _event(2, [_page([
            _command(355, ['pbSetSelfSwitch(1, "B", true)']),
            _command(355, ['pbSetSelfSwitch(3, "A", true)']), _command(0, []),
          ])], x: 2, y: 0),
          3: _event(3, [_page([
            if (invalid == 'setter') _command(355, ['pbSetSelfSwitch(1, "A", flag)'])
            else if (invalid == 'missingTarget') _command(355, ['pbSetSelfSwitch(99, "A", true)'])
            else if (invalid == 'numericWriter') _command(122, [7, 7, 0, 0, 1])
            else _command(123, ['C', 0]),
            _command(0, []),
          ], trigger: invalid == 'trigger' ? 4 : 0,
             character: invalid == 'graphic' ? 'MissingActor' : 'QualifiedNpc')], x: 2, y: 1),
          if (invalid == 'numericWriter') 4: _event(4, [_page([
            _command(355, [r'$game_variables[7] = []']), _command(0, []),
          ])], x: 0, y: 0),
        });
        final analysis = _analyzer(source).analyze();
        final target = analysis.eventAt(1, 3)!;
        final page = target.pages.single;
        final setter = page.body.nodes.first;
        final supplied = invalid != 'source' ? analysis : SourceEventAnalysis(
          profile: analysis.profile, diagnostics: [], events: [for (final event in analysis.events)
            if (event.identity != target.identity) event else SourceEventDefinition(
              sourceMapId: target.sourceMapId, sourceEventId: target.sourceEventId,
              sourceFileId: target.sourceFileId, identity: target.identity, name: target.name,
              x: target.x, y: target.y, locator: target.locator, pages: [SourceEventPageAnalysis(
                sourcePage: page.sourcePage, locator: page.locator, condition: page.condition,
                graphic: page.graphic, rawDataRef: page.rawDataRef, diagnostics: [],
                body: SourceEventBlock(span: page.body.span, nodes: [SourceSelfSwitchNode(setter.span,
                  factId: _analyzer(source).selfFactId(1, 1, 'C'), letter: 'C', value: true)]))])]);
        if (invalid == 'graphic') {
          final candidates = const SourceEventProjector().characterImportCandidates(
            source: source, analysis: supplied, nativeMaps: _nativeMaps(source));
          expect(candidates.map((event) => event.identity), contains(analysis.eventAt(1, 1)!.identity));
        }
        final result = _projectEvents(source, analysis: supplied);
        expect(result.registry.records.every((record) => record.definitionOrNull == null), isTrue);
        expect(result.facts, isEmpty);
        expect(result.scenes, isEmpty);
        expect(jsonEncode(result.semanticEvidence), contains('sourceSelfSwitchTargetUnavailable'));
      });
    }

    for (final attested in [false, true]) {
      test('rejects a fabricated setter in dialogue-only source attested=$attested', () async {
        final source = await _events([_page([
          _command(101, ['Only dialogue']), _command(0, []),
        ])], attestedScripts: attested, extraEvents: {2: _event(2, [_page([])])});
        final analysis = _analyzer(source).analyze();
        final original = analysis.eventAt(1, 1)!;
        final page = original.pages.single;
        final forged = SourceEventDefinition(sourceMapId: original.sourceMapId,
          sourceEventId: original.sourceEventId, sourceFileId: original.sourceFileId,
          identity: original.identity, name: original.name, x: original.x, y: original.y,
          locator: original.locator, pages: [SourceEventPageAnalysis(
            sourcePage: page.sourcePage, locator: page.locator, condition: page.condition,
            graphic: page.graphic, rawDataRef: page.rawDataRef, diagnostics: [],
            body: SourceEventBlock(span: page.body.span, nodes: [
              SourceSelfSwitchNode(page.body.nodes.first.span,
                factId: _analyzer(source).selfFactId(1, 2, 'A'), letter: 'A', value: true),
              ...page.body.nodes,
            ]))]);
        final result = _projectEvents(source,
          analysis: SourceEventAnalysis(profile: analysis.profile,
            events: [for (final event in analysis.events) event.identity == original.identity ? forged : event], diagnostics: []));
        expect(result.facts, isEmpty);
        expect(result.registry.records.first.definitionOrNull, isNull);
        expect(result.scenes.expand((scene) => scene.graph.nodes)
            .map((node) => node.payload).whereType<SceneActionPayload>(), isEmpty);
      });
      test('preserves legitimate RM123 local setters attested=$attested', () async {
        final source = await _events([_page([
          _command(123, ['C', 0]), _command(0, []),
        ])], attestedScripts: attested, extraEvents: {2: _event(2, [_page([])])});
        final result = _projectEvents(source);
        final expected = sourceEventFactBindingId(_analyzer(source).selfFactId(1, 1, 'C'));
        expect(result.facts.map((fact) => fact.id), [expected]);
        expect(result.registry.records.every((record) => record.definitionOrNull != null), isTrue);
        final scene = result.scenes.singleWhere((scene) => scene.graph.nodes
            .map((node) => node.payload).whereType<SceneActionPayload>().isNotEmpty);
        final run = await _runNumericScene(result, scene);
        expect(run.state.narrativeFactRuntimeState.valuesByFactId[expected]!.boolValue, isTrue);
      });
    }

    test('rejects a forged self-switch destination page condition', () async {
      final source = await _events([_page([
        _command(355, ['pbSetSelfSwitch(2, "A", true)']), _command(0, []),
      ])], attestedScripts: true, extraEvents: {2: _event(2, [
        _withCondition(_page([_command(101, ['Target'])]), {'@self_switch_valid': true}),
      ], x: 2, y: 0)});
      final analysis = _analyzer(source).analyze();
      final original = analysis.eventAt(1, 2)!;
      final page = original.pages.single;
      final forged = SourceEventDefinition(sourceMapId: original.sourceMapId,
        sourceEventId: original.sourceEventId, sourceFileId: original.sourceFileId,
        identity: original.identity, name: original.name, x: original.x, y: original.y,
        locator: original.locator, pages: [SourceEventPageAnalysis(
          sourcePage: page.sourcePage, locator: page.locator,
          condition: SourceEventCondition(kind: SourceEventConditionKind.selfSwitch,
            factId: _analyzer(source).selfFactId(1, 1, 'A')),
          graphic: page.graphic, rawDataRef: page.rawDataRef, diagnostics: [], body: page.body)]);
      final result = _projectEvents(source, analysis: SourceEventAnalysis(profile: analysis.profile,
        events: [for (final event in analysis.events) event.identity == original.identity ? forged : event], diagnostics: []));
      expect(result.facts, isEmpty);
      expect(result.registry.records.every((record) => record.definitionOrNull == null), isTrue);
      expect(jsonEncode(result.semanticEvidence), contains('sourceSelfSwitchSourceMismatch'));
    });
    for (final (targetMap, value) in [(1, true), (8, true), (8, false)]) {
      test('writes $value only to target $targetMap event facts and selects its page after reload', () async {
        final target = _event(2, [
          _page([_command(101, ['Off'])]),
          _withCondition(_page([_command(101, ['On'])]),
              {'@self_switch_valid': true, '@self_switch_ch': 'B'}),
        ], x: 2, y: 0);
        final source = await _events([_page([
          _command(355, ['pbSetSelfSwitch(2, "B", $value, $targetMap)']), _command(0, []),
        ])], attestedScripts: true,
            extraEvents: targetMap == 1 ? {2: target} : null,
            extraMaps: targetMap == 8 ? {8: _map(events: {2: target})} : null);
        final analyzer = _analyzer(source);
        final result = _projectEvents(source);
        expect(result.registry.records.every((record) => record.definitionOrNull != null), isTrue);
        final fact = analyzer.selfFactId(targetMap, 2, 'B');
        expect(result.facts.map((entry) => entry.id), contains(sourceEventFactBindingId(fact)));
        final scene = result.scenes.singleWhere((scene) => scene.graph.nodes
            .map((node) => node.payload).whereType<SceneActionPayload>()
            .any((payload) => payload.consequence is SceneSetFactConsequence));
        final initial = value ? const GameState(saveId: 'foreign') :
            NarrativeFactRuntimeWriter(NarrativeFactRuntimeResolver.fromFacts(result.facts))
                .setFactValue(gameState: const GameState(saveId: 'foreign'),
                    factId: sourceEventFactBindingId(fact), value: NarrativeValue.boolean(true)).gameState;
        final run = await _runNumericScene(result, scene, initial: initial);
        final values = run.state.narrativeFactRuntimeState.valuesByFactId;
        expect(values[sourceEventFactBindingId(fact)]!.boolValue, value);
        expect(values[sourceEventFactBindingId(analyzer.selfFactId(1, 1, 'B'))]?.boolValue ?? false, isFalse);
        expect(values[sourceEventFactBindingId(analyzer.selfFactId(targetMap, 2, 'A'))]?.boolValue ?? false, isFalse);
        expect(analyzer.analyze().eventAt(targetMap, 2)!.selectPage(facts: {fact: values[sourceEventFactBindingId(fact)]!.boolValue})!.originalPageIndex, value ? 1 : 0);
      });
    }
    test('multiple literal statements keep execution order and the native dialogue suffix', () async {
      final source = await _events([_page([
        _command(355, ['pbSetSelfSwitch(2, "A", true); pbSetSelfSwitch(2, "A", false)']),
        _command(101, ['After']), _command(0, []),
      ])], attestedScripts: true, extraEvents: {2: _event(2, [_page([])], x: 2, y: 0)});
      final result = _projectEvents(source);
      final scene = result.scenes.singleWhere((scene) => scene.graph.nodes
          .map((node) => node.payload).whereType<SceneActionPayload>().isNotEmpty);
      final run = await _runNumericScene(result, scene);
      final fact = sourceEventFactBindingId(_analyzer(source).selfFactId(1, 2, 'A'));
      expect(run.state.narrativeFactRuntimeState.valuesByFactId[fact]!.boolValue, isFalse);
      expect(run.shown, ['After']);
    });
    for (final broken in [false, true]) {
      test('mutual interaction writes have no artificial cycle dependency broken=$broken', () async {
        final source = await _events([_page([
          _command(355, ['pbSetSelfSwitch(2, "A", true)']), _command(0, []),
        ])], attestedScripts: true, extraEvents: {2: _event(2, [_page([
          _command(355, ['pbSetSelfSwitch(1, "B", false)']), _command(0, []),
        ], character: broken ? 'MissingActor' : 'QualifiedNpc')], x: 2, y: 0)});
        final result = _projectEvents(source);
        expect(result.registry.records.every((record) => record.definitionOrNull != null), !broken);
        expect(result.facts.length, broken ? 0 : 2);
        if (broken) expect(jsonEncode(result.semanticEvidence), contains('sourceSelfSwitchTargetUnavailable'));
      });
    }
    for (final unavailable in ['map', 'event', 'quarantined', 'graphic']) {
      test('rejects an unavailable destination $unavailable', () async {
        final source = await _events([_page([
          _command(355, ['pbSetSelfSwitch(2, "A", true, 8)']), _command(0, []),
        ])], attestedScripts: true, extraMaps: {8: _map(events: {
          2: _event(2, [_page([
            if (unavailable == 'quarantined') _command(355, ['unsafe()']),
            _command(101, ['Target']),
          ], character: unavailable == 'graphic' ? 'MissingActor' : 'QualifiedNpc')]),
        })});
        final analysis = _analyzer(source).analyze();
        final result = _projectEvents(source,
            analysis: unavailable == 'event' ? SourceEventAnalysis(profile: analysis.profile,
              events: analysis.events.where((event) => event.sourceMapId == 1).toList(), diagnostics: []) : analysis,
            maps: unavailable == 'map' ? {1: _nativeMaps(source)[1]!} : _nativeMaps(source));
        expect(result.facts, isEmpty);
        expect(result.registry.records.first.definitionOrNull, isNull);
        expect(jsonEncode(result.semanticEvidence), contains('sourceSelfSwitchTargetUnavailable'));
      });
    }
    for (final forgery in ['fact', 'letter', 'value', 'removed']) {
      test('rejects a $forgery forgery against the raw source helper', () async {
        final source = await _events([_page([
          _command(355, ['pbSetSelfSwitch(2, "A", true)']), _command(101, ['After']), _command(0, []),
        ])], attestedScripts: true, extraEvents: {2: _event(2, [_page([])])});
        final analysis = _analyzer(source).analyze();
        final original = analysis.eventAt(1, 1)!;
        final page = original.pages.single;
        final node = page.body.nodes.first as SourceSelfSwitchNode;
        final forged = SourceEventDefinition(sourceMapId: original.sourceMapId,
          sourceEventId: original.sourceEventId, sourceFileId: original.sourceFileId,
          identity: original.identity, name: original.name, x: original.x, y: original.y,
          locator: original.locator, pages: [SourceEventPageAnalysis(
            sourcePage: page.sourcePage, locator: page.locator, condition: page.condition,
            graphic: page.graphic, rawDataRef: page.rawDataRef, diagnostics: [],
            body: SourceEventBlock(span: page.body.span, nodes: [
              if (forgery != 'removed') SourceSelfSwitchNode(node.span,
                factId: forgery == 'fact' ? _analyzer(source).selfFactId(1, 1, 'A') : node.factId,
                letter: forgery == 'letter' ? 'B' : node.letter,
                value: forgery == 'value' ? false : node.value),
              ...page.body.nodes.skip(1),
            ]))]);
        final result = _projectEvents(source,
          analysis: SourceEventAnalysis(profile: analysis.profile,
            events: [for (final event in analysis.events) event.identity == original.identity ? forged : event], diagnostics: []));
        expect(result.facts, isEmpty);
        expect(result.registry.records.first.definitionOrNull, isNull);
        expect(jsonEncode(result.semanticEvidence), contains('sourceSelfSwitchSourceMismatch'));
      });
    }
  }, skip: scriptsPath == null);
  group('generic native numeric control', () {
    test('annotations have no runtime effect and range writes persist', () async {
      final source = await _events([_page([
        _command(108, ['annotation']), _command(408, ['continued']),
        _command(122, [3, 5, 0, 0, 2147483647]),
        _command(101, ['done']), _command(0, []),
      ])], attestedScripts: true);
      final result = _projectEvents(source);
      expect(result.scenes, hasLength(1));
      expect(result.facts, hasLength(3));
      expect(result.facts.every((fact) => fact.initialValue == NarrativeValue.integer(0)), isTrue);
      final run = await _runNumericScene(result, result.scenes.single);
      expect(run.shown, ['done']);
      expect(run.state.narrativeFactRuntimeState.valuesByFactId.values,
          everyElement(NarrativeValue.integer(99999999)));
      expect(run.state.consumedEventIds, isEmpty);
      expect(result.registry.records.single.definitionOrNull!.reusePolicy,
          NarrativeEventReusePolicy.reusable);
      final evidence = jsonEncode(result.semanticEvidence);
      expect(evidence, contains('annotation'));
      expect(evidence, contains('integerVariableSet'));
    });
    test('generic writes use the same canonical identities as elevator and warp variables', () async {
      final source = await _events([_page([
        _command(122, [1, 3, 0, 0, 4]), _command(122, [10, 11, 0, 0, 2]), _command(0, []),
      ])], attestedScripts: true);
      final result = _projectEvents(source);
      final ids = {for (final id in [1, 2, 3, 10, 11]) sourceEventIntegerVariableBindingId(
        'source:${source.snapshot.logicalProjectNamespace.value}:variable:$id')};
      expect(result.facts.map((fact) => fact.id).toSet(), ids);
      final run = await _runNumericScene(result, result.scenes.single);
      expect(run.state.narrativeFactRuntimeState.valuesByFactId.keys.toSet(), ids);
    });
    test('literal annotations do not split one native text and choice dialogue', () async {
      final source = await _events([_page([
        _command(101, ['first']), _command(108, ['middle']), _command(401, ['second']),
        _command(108, ['choice']), _command(408, ['continued']),
        _command(102, [['Leave'], 0]), _command(402, [0, 'Leave']),
        _command(115, [], indent: 1), _command(404, []), _command(0, []),
      ])], attestedScripts: true);
      final result = _projectEvents(source);
      expect(result.scenes, hasLength(1));
      expect(result.dialogues, hasLength(1));
      final run = await _runNumericScene(result, result.scenes.single);
      expect(run.shown, ['first second']);
      final evidence = jsonEncode(result.semanticEvidence);
      expect(evidence, contains('continued'));
    });
    for (var operation = 0; operation < 6; operation++) {
      test('all six native integer comparisons match source $operation', () async {
        final source = await _events([_page([
          _command(111, [1, 7, 0, -1, operation]),
          _command(101, ['true'], indent: 1), _command(411, []),
          _command(101, ['false'], indent: 1), _command(412, []), _command(0, []),
        ])], attestedScripts: true);
        final result = _projectEvents(source);
        expect(result.scenes, hasLength(1));
        expect(result.facts, hasLength(1));
        for (final value in [-2, -1, 0]) {
          final initial = const GameState(saveId: 'comparisons').copyWith(
            narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(valuesByFactId: {
              result.facts.single.id: NarrativeValue.integer(value),
            }));
          final run = await _runNumericScene(result, result.scenes.single, initial: initial);
          final expected = [value == -1, value >= -1, value <= -1,
            value > -1, value < -1, value != -1][operation];
          expect(run.shown, [expected ? 'true' : 'false']);
        }
        final defaultRun = await _runNumericScene(result, result.scenes.single);
        expect(defaultRun.shown, [[false, true, false, true, false, true][operation] ? 'true' : 'false']);
      });
    }
    for (final nested in [false, true]) {
      test('exit ends the entire invocation from nested choice $nested', () async {
        final source = await _events([_page([
          _command(122, [7, 7, 0, 0, 1]),
          if (nested) ...[
            _command(102, [['Leave', 'Stay'], 0]), _command(402, [0, 'Leave']),
          ],
          _command(111, [1, 7, 0, 1, 0], indent: nested ? 1 : 0),
          _command(115, [], indent: nested ? 2 : 1),
          _command(122, [7, 7, 0, 0, 2], indent: nested ? 2 : 1),
          _command(412, [], indent: nested ? 1 : 0),
          if (nested) ...[
            _command(101, ['choice suffix'], indent: 1),
            _command(402, [1, 'Stay']), _command(101, ['stay'], indent: 1),
            _command(404, []),
          ],
          _command(122, [7, 7, 0, 0, 3]), _command(101, ['event suffix']),
          _command(0, []),
        ])], attestedScripts: true);
        final result = _projectEvents(source);
        expect(result.scenes, hasLength(1));
        final initial = const GameState(saveId: 'exit').copyWith(consumedEventIds: {'unrelated'});
        final first = await _runNumericScene(result, result.scenes.single, initial: initial);
        expect(first.shown.where((text) => text.contains('suffix')), isEmpty);
        expect(first.state.narrativeFactRuntimeState.valuesByFactId.values.single,
            NarrativeValue.integer(1));
        expect(first.state.consumedEventIds, {'unrelated'});
        final second = await _runNumericScene(result, result.scenes.single, initial: first.state);
        expect(second.state, first.state);
      });
    }
    test('a numeric page without an unconditional presence base remains inactive', () async {
      final page = _withCondition(_page([_command(101, ['conditional actor'])]), {
        '@variable_valid': true, '@variable_id': 7, '@variable_value': 0,
      });
      final result = _projectEvents(await _events([page], attestedScripts: true));
      expect(result.scenes, isEmpty);
      expect(result.facts, isEmpty);
      expect(jsonEncode(result.semanticEvidence), contains('pagePresenceExpressionUnsupported'));
    });
    test('numeric page conditions retain default zero and last true priority', () async {
      final high = _withCondition(_page([_command(101, ['high'])]), {
        '@variable_valid': true, '@variable_id': 7, '@variable_value': 1,
      });
      final result = _projectEvents(await _events([
        _page([_command(101, ['low'])]), high,
      ], attestedScripts: true));
      expect(result.scenes, hasLength(2));
      expect(result.facts, hasLength(1));
      final json = jsonEncode(result.registry.toJson());
      expect(json, contains('greaterThanOrEqual'));
      expect(result.facts.single.initialValue, NarrativeValue.integer(0));
      bool guard(NarrativeEventConditionExpression expression, int value) => switch (expression) {
        NarrativeEventConditionLeaf(:final condition) => condition.whenTyped(
          fact: (_, operation, expected) => NarrativeValue.integer(value).matches(operation, expected),
          narrativeEventConsumed: (_, __) => throw StateError('No consumed predicate')),
        NarrativeEventConditionAll(:final children) => children.every((child) => guard(child, value)),
        NarrativeEventConditionAny(:final children) => children.any((child) => guard(child, value)),
        NarrativeEventConditionNot(:final child) => !guard(child, value),
      };
      for (final value in [-1, 0, 1, 2]) {
        final selected = result.registry.records.map((record) => record.definitionOrNull!)
            .where((event) => guard(event.conditionExpression, value));
        expect(selected.single.priority, value >= 1 ? 1 : 0);
      }
    });
    for (final script in [r'pbSet(7, "name")', r'$game_variables[7] = []',
      r'pbSet(target_id, value)', r'$game_variables[target_id] = value',
      r'$game_variables[7] ||= []', r'$game_variables[7] &&= []',
      r'$game_variables[7] **= 2', r'$game_variables[7].replace([])',
      r'$game_variables[7].push(1)', r'value = $game_variables[7]; value.replace([])',
      r'value = pbGet(7); value.push(1)', r'value = pbGet 7; value.push(1)',
      r'pbSet 7, "name"', r'pbSet(7, "name"',
      r'$game_variables[targets[0]] = []', r'$game_variables[7',
      r'variables = $game_variables; variables[7] = []',
      r'pbGet(targets[0]).replace([])', r'pbGet(7 + offset).push(1)',
      r'pbSet(8, "name"', r'pbGet(8', r'$game_variables[8',
      r'value = $game_variables[7]',
    ]) {
      test('nonconverted script writer refuses integer binding $script', () async {
        final source = await _events([_page([
          _command(122, [7, 7, 0, 0, 3]), _command(0, []),
        ])], attestedScripts: true, extraEvents: {
          2: _event(2, [_page([_command(355, [script]), _command(0, [])])]),
        });
        final result = _projectEvents(source);
        expect(result.scenes, isEmpty);
        expect(result.facts, isEmpty);
        expect(jsonEncode(result.semanticEvidence), contains('sourceVariableWriterUnqualified'));
      });
    }
    for (final script in [r'$game_variables[8] ||= []', r'$game_variables[8].replace([])',
      r'value = pbGet(8); value.push(1)', r'pbSet 8, "name"',
      r'value = pbGet 8; value.push(1)', r'pbSet(8, ")")',
      r'pbSet(8, handler(0))']) {
      test('an opaque reference to a different static variable preserves independence $script', () async {
        final source = await _events([_page([
          _command(122, [7, 7, 0, 0, 3]), _command(0, []),
        ])], attestedScripts: true, extraEvents: {
          2: _event(2, [_page([_command(355, [script]), _command(0, [])])]),
        });
        final result = _projectEvents(source);
        expect(result.scenes, hasLength(1));
        expect(result.facts, hasLength(1));
        expect(result.facts.single.id, sourceEventIntegerVariableBindingId(
          'source:${source.snapshot.logicalProjectNamespace.value}:variable:7'));
      });
    }
    test('annotations containing Ruby variable references have no writer effect', () async {
      final source = await _events([_page([
        _command(108, [r'$game_variables[7].replace([])']),
        _command(408, [r'pbSet(dynamic_target, []); pbGet(7).push(1)']),
        _command(122, [7, 7, 0, 0, 3]), _command(0, []),
      ])], attestedScripts: true);
      final result = _projectEvents(source);
      expect(result.scenes, hasLength(1));
      expect(result.facts, hasLength(1));
      final run = await _runNumericScene(result, result.scenes.single);
      expect(run.state.narrativeFactRuntimeState.valuesByFactId.values.single,
          NarrativeValue.integer(3));
    });
    test('altered parsed integer commands cannot borrow source raw witnesses', () async {
      final source = await _events([_page([
        _command(122, [7, 7, 0, 0, 1]), _command(115, []), _command(0, []),
      ], character: '')], eventName: 'HiddenItem control', attestedScripts: true);
      final analysis = _analyzer(source).analyze();
      final original = analysis.events.single;
      final page = original.pages.single;
      final write = page.body.nodes.first as SourceVariableSetNode;
      final forged = SourceEventDefinition(sourceMapId: original.sourceMapId,
        sourceEventId: original.sourceEventId, sourceFileId: original.sourceFileId,
        identity: original.identity, name: original.name, x: original.x, y: original.y,
        locator: original.locator, pages: [SourceEventPageAnalysis(
          sourcePage: page.sourcePage, locator: page.locator, condition: page.condition,
          graphic: page.graphic, rawDataRef: page.rawDataRef, diagnostics: [],
          body: SourceEventBlock(span: page.body.span, nodes: [
            SourceVariableSetNode(write.span, firstId: write.firstId, lastId: write.lastId,
              sourceValue: 99, factIds: write.factIds), ...page.body.nodes.skip(1),
          ]))]);
      final result = const SourceEventProjector().project(source: source,
        analysis: SourceEventAnalysis(profile: analysis.profile, events: [forged], diagnostics: []),
        nativeMaps: _nativeMaps(source));
      expect(result.scenes, isEmpty);
      expect(result.facts, isEmpty);
      expect(jsonEncode(result.semanticEvidence), contains('sourceNumericControlSourceMismatch'));
    });
    for (final commands in [
      [_command(122, [7, 7, 0, 0, 1])],
      [_command(115, [])],
      [_command(108, ['annotation']), _command(408, ['continued'])],
      [_command(111, [1, 7, 0, 0, 0]), _command(115, [], indent: 1), _command(412, [])],
    ]) {
      test('removing every source control cannot activate the retained suffix $commands', () async {
        final source = await _events([_page([
          ...commands, _command(101, ['retained suffix']), _command(0, []),
        ], character: '')], eventName: 'HiddenItem control', attestedScripts: true);
        final analysis = _analyzer(source).analyze();
        final original = analysis.events.single;
        final page = original.pages.single;
        final forged = SourceEventDefinition(sourceMapId: original.sourceMapId,
          sourceEventId: original.sourceEventId, sourceFileId: original.sourceFileId,
          identity: original.identity, name: original.name, x: original.x, y: original.y,
          locator: original.locator, pages: [SourceEventPageAnalysis(
            sourcePage: page.sourcePage, locator: page.locator, condition: page.condition,
            graphic: page.graphic, rawDataRef: page.rawDataRef, diagnostics: [],
            body: SourceEventBlock(span: page.body.span,
              nodes: page.body.nodes.whereType<SourceTextNode>().toList()))]);
        final result = const SourceEventProjector().project(source: source,
          analysis: SourceEventAnalysis(profile: analysis.profile, events: [forged], diagnostics: []),
          nativeMaps: _nativeMaps(source));
        expect(result.scenes, isEmpty);
        expect(result.facts, isEmpty);
        expect(jsonEncode(result.semanticEvidence), contains('sourceNumericControlSourceMismatch'));
      });
    }
    for (final kind in ['forced', 'continuation', 'autonomous']) {
      for (final entry in [
        (r'$game_variables[7].replace([])', false),
        (r'$game_variables[target] = []', false),
        (r'variables = $game_variables; variables[7] = []', false),
        (r'$game_variables[8].replace([])', true),
      ]) {
        test('opaque $kind route script preserves numeric writer boundaries ${entry.$1}', () async {
          final move = _RubyObject('RPG::MoveCommand', {
            '@code': 45, '@parameters': [entry.$1],
          });
          final route = _RubyObject('RPG::MoveRoute', {
            '@repeat': false, '@skippable': false, '@list': [
              move, _RubyObject('RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]}),
            ],
          });
          final writer = _page([
            if (kind == 'forced') _command(209, [0, route]),
            if (kind == 'continuation') _command(509, [move]),
            _command(0, []),
          ]);
          if (kind == 'autonomous') {
            writer.fields['@move_type'] = 3;
            writer.fields['@move_route'] = route;
          }
          final source = await _events([_page([
            _command(122, [7, 7, 0, 0, 3]), _command(0, []),
          ])], attestedScripts: true, extraEvents: {2: _event(2, [writer])});
          final result = _projectEvents(source);
          expect(result.scenes, hasLength(entry.$2 ? 1 : 0));
          expect(result.facts, hasLength(entry.$2 ? 1 : 0));
          if (!entry.$2) {
            expect(jsonEncode(result.semanticEvidence), contains('sourceVariableWriterUnqualified'));
          }
        });
      }
    }
    for (final kind in ['branch', 'page']) {
      for (final entry in [
        (r'$game_variables[7].replace([])', false),
        (r'pbSet(target, [])', false),
        (r'variables = $game_variables; variables[7] = []', false),
        (r'$game_variables[8].replace([])', true),
      ]) {
        test('script switch $kind contributes opaque numeric references ${entry.$1}', () async {
          final writer = kind == 'branch'
              ? _page([_command(111, [0, 1, 0]), _command(412, []), _command(0, [])])
              : _withCondition(_page([_command(0, [])]), {'@switch1_valid': true});
          final source = await _events([_page([
            _command(122, [7, 7, 0, 0, 3]), _command(0, []),
          ])], attestedScripts: true, switches: ['', 's:${entry.$1}'],
            extraEvents: {2: _event(2, [writer])});
          final result = _projectEvents(source);
          expect(result.scenes, hasLength(entry.$2 ? 1 : 0));
          expect(result.facts, hasLength(entry.$2 ? 1 : 0));
        });
      }
    }
    for (final code in [103, 105]) {
      for (final entry in [(7, false), (8, true), ('target', false)]) {
        test('unsupported numeric input $code reserves its variable ${entry.$1}', () async {
          final source = await _events([_page([
            _command(122, [7, 7, 0, 0, 3]), _command(0, []),
          ])], attestedScripts: true, extraEvents: {2: _event(2, [_page([
            _command(code, [entry.$1, if (code == 103) 2]), _command(0, []),
          ])])});
          final result = _projectEvents(source);
          expect(result.scenes, hasLength(entry.$2 ? 1 : 0));
          expect(result.facts, hasLength(entry.$2 ? 1 : 0));
        });
      }
    }
    for (final trigger in [0, 2]) {
      test('malformed common events refuse numeric admission trigger $trigger', () async {
        final source = await _events([_page([
          _command(122, [7, 7, 0, 0, 3]), _command(0, []),
        ])], attestedScripts: true, commonEvents: [null, _RubyObject('RPG::CommonEvent', {
          '@id': 1, '@name': 'Opaque common event', '@trigger': trigger,
          '@switch_id': 1, '@list': 'malformed',
        })]);
        expect(source.snapshot.entries.any((entry) => entry.relativePath == 'Data/CommonEvents.rxdata'), isTrue);
        expect(source.archive.files.values.any((entry) => entry.entry.relativePath == 'Data/CommonEvents.rxdata'), isTrue);
        final result = _projectEvents(source);
        expect(result.scenes, isEmpty);
        expect(result.facts, isEmpty);
        expect(jsonEncode(result.semanticEvidence), contains('sourceVariableRubyCensusIncomplete'));
      });
    }
    test('common event invocation without audited common source refuses numeric admission', () async {
      final source = await _events([_page([
        _command(122, [7, 7, 0, 0, 3]), _command(0, []),
      ])], attestedScripts: true, extraEvents: {2: _event(2, [_page([
        _command(117, [1]), _command(0, []),
      ])])});
      final result = _projectEvents(source);
      expect(result.scenes, isEmpty);
      expect(result.facts, isEmpty);
      expect(jsonEncode(result.semanticEvidence), contains('sourceVariableRubyCensusIncomplete'));
    });
    for (final trigger in [0, 1, 2]) {
      for (final target in [1, 7]) {
        test('common event census isolates static writer target $target trigger $trigger', () async {
          final source = await _events([_page([
            _command(122, [7, 7, 0, 0, 3]), _command(0, []),
          ])], attestedScripts: true, commonEvents: [null, null, _RubyObject('RPG::CommonEvent', {
            '@id': 2, '@name': 'Common', '@trigger': trigger, '@switch_id': 1,
            '@list': [_command(355, ['\$game_variables[$target] = "ON"']), _command(0, [])],
          })]);
          final result = _projectEvents(source);
          expect(result.facts, hasLength(target == 1 ? 1 : 0));
          expect(result.scenes, hasLength(target == 1 ? 1 : 0));
          expect(jsonEncode(result.semanticEvidence), isNot(contains('sourceVariableRubyCensusIncomplete')));
        });
      }
    }
    for (final commands in <List<_RubyObject>>[
      [_command(122, [7, 7, 0, 0, 2])],
      [_command(122, [7, 8, 0, 1, 2])],
      [_command(103, [7, 2])], [_command(105, [7])],
      [_command(355, [r'$game_variables[target] = []'])],
      [_command(355, [r'variables = $game_variables'])],
      [_command(111, [12, r'pbGet(7).replace([])'])],
      [_command(355, [r'pbSet(']), _command(655, ['7, [])'])],
      [_command(122, ['dynamic', 7, 0, 0, 2])],
    ]) {
      test('common event census refuses unconverted writer ${jsonEncode(commands.map((c) => c.fields).toList())}', () async {
        final result = _projectEvents(await _events([_page([
          _command(122, [7, 7, 0, 0, 3]), _command(0, []),
        ])], attestedScripts: true, commonEvents: [null, _RubyObject('RPG::CommonEvent', {
          '@id': 1, '@name': 'Common', '@trigger': 0, '@switch_id': 1,
          '@list': [...commands, _command(0, [])],
        })]));
        expect(result.facts, isEmpty);
        expect(result.scenes, isEmpty);
      });
    }
    test('common event census resolves invocation coverage without executing calls', () async {
      final result = _projectEvents(await _events([_page([
        _command(122, [7, 7, 0, 0, 3]), _command(0, []),
      ])], attestedScripts: true, commonEvents: [null, _RubyObject('RPG::CommonEvent', {
        '@id': 1, '@name': 'Recursive inert call', '@trigger': 0, '@switch_id': 1,
        '@list': [_command(117, [1]), _command(108, [r'$game_variables[7] = []']),
          _command(408, [r'pbSet(7, [])']), _command(0, [])],
      })], extraEvents: {2: _event(2, [_page([_command(117, [1]), _command(0, [])])])}));
      expect(result.facts, hasLength(1));
      expect(result.scenes, hasLength(1));
      expect(result.registry.records.where((r) => r.definitionOrNull == null), hasLength(1));
      expect(jsonEncode(result.semanticEvidence), isNot(contains('sourceVariableRubyCensusIncomplete')));
    });
    test('common event census real archive isolates ON OFF variable from independent fixture variable', () async {
      final bytes = await File('${File(scriptsPath!).parent.path}/CommonEvents.rxdata').readAsBytes();
      expect(bytes, hasLength(7300));
      expect(_hash(bytes).value, 'bce4047ee1779de25f2e8fd087ea4f90dae513eecb8ead734743d1b37ee78cda');
      for (final id in [1, 7]) {
        final result = _projectEvents(await _events([_page([
          _command(122, [id, id, 0, 0, 3]), _command(0, []),
        ])], attestedScripts: true, commonEventBytes: bytes));
        expect(result.facts, hasLength(id == 7 ? 1 : 0));
        expect(result.scenes, hasLength(id == 7 ? 1 : 0));
        expect(jsonEncode(result.semanticEvidence), isNot(contains('sourceVariableRubyCensusIncomplete')));
      }
    });
    for (final code in [103, 105, 122]) {
      test('common event census static writer $code preserves unrelated variable', () async {
        final result = _projectEvents(await _events([_page([
          _command(122, [7, 7, 0, 0, 3]), _command(0, []),
        ])], attestedScripts: true, commonEvents: [null, _RubyObject('RPG::CommonEvent', {
          '@id': 1, '@name': 'Static writer', '@trigger': 0, '@switch_id': 1,
          '@list': [_command(code, code == 122 ? [8, 8, 0, 0, 2] : code == 103 ? [8, 2] : [8]), _command(0, [])],
        })]));
        expect(result.facts, hasLength(1));
        expect(result.scenes, hasLength(1));
      });
    }
    for (final code in [209, 509]) {
      for (final entry in [(r'$game_variables[7].replace([])', false),
          (r'$game_variables[target] = []', false), (r'$game_variables[8] = []', true)]) {
        test('common event census route $code isolates observed target ${entry.$1}', () async {
          final move = _RubyObject('RPG::MoveCommand', {'@code': 45, '@parameters': [entry.$1]});
          final result = _projectEvents(await _events([_page([
            _command(122, [7, 7, 0, 0, 3]), _command(0, []),
          ])], attestedScripts: true, commonEvents: [null, _RubyObject('RPG::CommonEvent', {
            '@id': 1, '@name': 'Route', '@trigger': 0, '@switch_id': 1,
            '@list': [_command(code, code == 509 ? [move] : [0,
              _RubyObject('RPG::MoveRoute', {'@list': [move]})]), _command(0, [])],
          })]));
          expect(result.facts, hasLength(entry.$2 ? 1 : 0));
          expect(result.scenes, hasLength(entry.$2 ? 1 : 0));
        });
      }
    }
    test('an incomplete variable census does not disable annotations and invocation exit', () async {
      final source = await _events([_page([
        _command(108, ['annotation']), _command(115, []), _command(0, []),
      ])], attestedScripts: true, commonEvents: [null]);
      final result = _projectEvents(source);
      expect(result.scenes, hasLength(1));
      expect(result.facts, isEmpty);
    });
    test('unsupported sibling or suffix keeps the whole event inactive', () async {
      for (final sibling in [false, true]) {
        final result = _projectEvents(await _events([
          _page([_command(122, [7, 7, 0, 0, 1]), _command(115, []),
            if (!sibling) _command(355, ['pbGivePokemon(:TEST)']), _command(0, [])]),
          if (sibling) _page([_command(118, ['label']), _command(0, [])]),
        ], attestedScripts: true));
        expect(result.scenes, isEmpty);
        expect(result.facts, isEmpty);
        expect(result.registry.records.single.definitionOrNull, isNull);
      }
    });
  }, skip: scriptsPath == null);
  group('generic static door source programs', () {
    List<_RubyObject> program({int mode = 0, int target = 8, int x = 1}) => [
      _command(250, [_RubyObject('RPG::AudioFile', {
        '@name': 'Exit Door', '@volume': 80, '@pitch': 100,
      })]),
      _command(223, [_tone([-255, -255, -255, 0]), 6]),
      _command(106, [8]),
      _command(201, [mode, target, x, 1, 0, 1]),
      _command(223, [_tone([0, 0, 0, 0]), 6]),
      _command(0, []),
    ];
    test('nonpinned single-page source program is attested with exact values', () async {
      final source = await _events([
        _page(program(), trigger: 1, character: ''),
      ], attestedScripts: true);
      final analysis = _analyzer(source).analyze();
      final programs = sourceStaticDoorPrograms(source: source, analysis: analysis);
      expect(programs.keys, [analysis.events.single.identity]);
      final bound = programs.values.single;
      expect(bound.sourceMapId, 1);
      expect(bound.targetSourceMapId, 8);
      expect(bound.isBoundTo(source: source, analysis: analysis,
          event: analysis.events.single), isTrue);
      expect(bound.toJson()['sourceScriptsExecuted'], 0);
    });
    for (final scenario in ['sibling', 'dynamic', 'outOfBounds', 'extraCommand', 'wrongTrigger']) {
      test('$scenario preserves the whole static door event inactive', () async {
        final commands = program(mode: scenario == 'dynamic' ? 1 : 0,
            x: scenario == 'outOfBounds' ? 3 : 1);
        if (scenario == 'extraCommand') commands.insert(3, _command(355, ['unknown()']));
        final source = await _events([
          _page(commands, trigger: scenario == 'wrongTrigger' ? 0 : 1, character: ''),
          if (scenario == 'sibling') _page([_command(355, ['unknown()'])], character: ''),
        ], attestedScripts: true);
        expect(sourceStaticDoorPrograms(source: source,
            analysis: _analyzer(source).analyze()), isEmpty);
      });
    }
    test('forged parsed values cannot borrow an archive attestation', () async {
      final source = await _events([
        _page(program(), trigger: 1, character: ''),
      ], attestedScripts: true);
      final actual = _analyzer(source).analyze();
      final event = actual.events.single;
      final page = event.pages.single;
      final sound = page.body.nodes.first as SourceSoundEffectNode;
      final alteredPage = SourceEventPageAnalysis(sourcePage: page.sourcePage,
          locator: page.locator, condition: page.condition, graphic: page.graphic,
          rawDataRef: page.rawDataRef, diagnostics: [], body: SourceEventBlock(
            span: page.body.span, nodes: [SourceSoundEffectNode(sound.span,
              name: sound.name, volume: 1, pitch: sound.pitch,
              rawDataRef: sound.rawDataRef, profileHash: sound.profileHash),
              ...page.body.nodes.skip(1)]));
      final alteredEvent = SourceEventDefinition(sourceMapId: event.sourceMapId,
          sourceEventId: event.sourceEventId, sourceFileId: event.sourceFileId,
          identity: event.identity, name: event.name, x: event.x, y: event.y,
          locator: event.locator, pages: [alteredPage]);
      final forged = SourceEventAnalysis(profile: actual.profile,
          events: [alteredEvent], diagnostics: []);
      expect(sourceStaticDoorPrograms(source: source, analysis: forged), isEmpty);
    });
    test('named invisible graphic retains its existing refusal', () async {
      final page = _page(program(), trigger: 1);
      (page.fields['@graphic'] as _RubyObject).fields['@opacity'] = 0;
      final source = await _events([page], attestedScripts: true);
      final result = _projectEvents(source);
      final row = (result.semanticEvidence['events'] as List).single as Map;
      expect(row['status'], 'quarantinedWholeEvent');
      expect(row['gaps'], contains('pageGraphicContractUnsupported'));
      expect(result.scenes, isEmpty);
    });
  }, skip: scriptsPath == null);
  test('invalid graphic on a later page keeps the whole event inactive',
      () async {
    final invalidPage = _page([_command(101, ['Invalid graphic'])], character: '');
    (invalidPage.fields['@graphic'] as _RubyObject).fields['@tile_id'] = 647;
    final source = await _events([
      _page([_command(101, ['Valid first page'])], character: ''),
      invalidPage,
    ]);
    expect(source.canPlan, isTrue);
    final analysis = _analyzer(source).analyze();
    expect(analysis.events.single.isQuarantined, isTrue);
    expect(
        analysis.diagnostics.map((entry) => entry.code),
        contains('events.invalid_event_graphic_reference'));
    final projector = const SourceEventProjector();
    final result = _projectEvents(source);
    expect(result.scenes, isEmpty);
    expect(result.dialogues, isEmpty);
    expect(result.registry.records, hasLength(1));
    expect(result.registry.records.single.definitionOrNull, isNull);
    for (final map in result.nativeMaps.values) {
      expect(map.entities, isEmpty);
      expect(map.triggers, isEmpty);
      expect(map.warps, isEmpty);
      expect(map.events, isEmpty);
    }
    expect(
        projector.characterImportCandidates(
            source: source, analysis: analysis, nativeMaps: _nativeMaps(source)),
        isEmpty);
    final event = (result.semanticEvidence['events'] as List).single as Map;
    expect(event['status'], 'quarantinedWholeEvent');
    expect(event['gaps'], contains('sourceQuarantined'));
  });
  group('item giver graphic byte identity', () {
    final sameHash = _hash([1, 2, 3, 4]);

    test('exact aliases with equal hash and length keep the same page graphic', () async {
      final source = await _graphicSource([
        _graphicEntry('A', hash: sameHash),
        _graphicEntry('B', hash: sameHash),
      ], names: ['A', 'B', 'A']);
      final first = _projectGiverGraphics(source);
      final second = _projectGiverGraphics(source);
      expect(jsonEncode(first.semanticEvidence), isNot(contains('pageGraphicChanges')));
      expect(canonicalJsonOf(first.semanticEvidence), canonicalJsonOf(second.semanticEvidence));
      expect(source.snapshot.entries.where((entry) => entry.relativePath.startsWith('Graphics/Characters/')), hasLength(2));
      expect(() => source.snapshot.entries.clear(), throwsUnsupportedError);
    });

    for (final changed in [
      (label: 'hash', hash: _hash([4, 3, 2, 1]), length: 4),
      (label: 'length', hash: sameHash, length: 5),
    ]) {
      test('different ${changed.label} remains a page graphic change', () async {
        final source = await _graphicSource([
          _graphicEntry('A', hash: sameHash),
          _graphicEntry('B', hash: changed.hash, length: changed.length),
        ]);
        expect(jsonEncode(_projectGiverGraphics(source).semanticEvidence), contains('pageGraphicChanges'));
      });
    }

    for (final fallback in ['wrong case', 'missing', 'directory']) {
      test('$fallback retains the original graphic name', () async {
        final source = await _graphicSource([
          _graphicEntry('A', hash: sameHash),
          if (fallback == 'wrong case') _graphicEntry('b', hash: sameHash),
          if (fallback == 'directory') _graphicEntry('B', kind: SourceNodeKind.directory),
        ]);
        expect(jsonEncode(_projectGiverGraphics(source).semanticEvidence), contains('pageGraphicChanges'));
      });
    }

    test('missing repeated names retain the same page graphic', () async {
      final source = await _graphicSource([], names: ['A', 'A', 'A']);
      expect(jsonEncode(_projectGiverGraphics(source).semanticEvidence), isNot(contains('pageGraphicChanges')));
    });

    test('ordinary dialogue still compares graphic names for equal bytes', () async {
      final source = await _graphicSource([
        _graphicEntry('A', hash: sameHash), _graphicEntry('B', hash: sameHash),
      ]);
      expect(jsonEncode(_projectEvents(source).semanticEvidence), contains('pageGraphicChanges'));
    });

    for (final kind in [SourceNodeKind.link, SourceNodeKind.special]) {
      test('complete snapshot rejects graphic ${kind.name}', () async {
        await expectLater(_graphicSource([
          _graphicEntry('A', hash: sameHash), _graphicEntry('B', kind: kind),
        ]), throwsA(isA<ContractError>().having((error) => error.code, 'code', 'source.snapshot_incomplete')));
      });
    }

    test('a new snapshot cannot reuse an earlier graphic identity', () async {
      final first = await _graphicSource([
        _graphicEntry('A', hash: sameHash), _graphicEntry('B', hash: sameHash),
      ]);
      final changed = await _graphicSource([
        _graphicEntry('A', hash: sameHash), _graphicEntry('B', hash: _hash([9, 8, 7, 6])),
      ]);
      expect(jsonEncode(_projectGiverGraphics(first).semanticEvidence), isNot(contains('pageGraphicChanges')));
      expect(jsonEncode(_projectGiverGraphics(changed).semanticEvidence), contains('pageGraphicChanges'));
      expect(jsonEncode(_projectGiverGraphics(first).semanticEvidence), isNot(contains('pageGraphicChanges')));
    });

    for (final aliases in [
      ['É', 'E\u0301'],
      ['S', 's', 'ſ'],
    ]) {
      test('complete snapshot rejects canonical aliases $aliases even with an exact member', () async {
        await expectLater(_graphicSource([
          for (final name in aliases) _graphicEntry(name, hash: sameHash),
        ], names: [aliases.first, aliases.last]),
          throwsA(isA<ContractError>().having((error) => error.code, 'code', 'source.snapshot_collision')));
      });
    }

    test('complete snapshot rejects a graphic without a hash', () async {
      await expectLater(_graphicSource([
        _graphicEntry('A', hash: sameHash), _graphicEntry('B'),
      ]), throwsA(isA<ContractError>().having((error) => error.code, 'code', 'source.snapshot_incomplete')));
    });
  });
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
      expect(profile['profile'], 'kanto-events-static-v6');
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
