import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart';

Future<LiteralTileFixture> _fixture({
  int direction = 2,
  int actor = -1,
  bool repeat = false,
  int stepCode = 12,
  int copyCode = 12,
  bool interrupted = false,
  bool extraEffect = false,
  List<int>? autonomousRouteCodes,
}) {
  LiteralFixtureObject step(int code) => LiteralFixtureObject(
      'RPG::MoveCommand', {'@code': code, '@parameters': <Object?>[]});
  LiteralFixtureUserDefined tone(double value) {
    final bytes = ByteData(32);
    for (var axis = 0; axis < 3; axis++) {
      bytes.setFloat64(axis * 8, value, Endian.little);
    }
    return LiteralFixtureUserDefined('Tone', bytes.buffer.asUint8List());
  }

  return LiteralTileFixture.create(
    scriptsBytes: syntheticInterpretationArchive,
    interpretationProfile: syntheticSourceInterpretationProfile,
    includeEventSystem: true,
    extraFiles: {
      'Data/map_connections.dat': literalFixtureMarshal([]),
      'Audio/SE/Exit Door.wav': sourceMapMusicFixtureWav(),
      'Game.ini': latin1.encode([
        '[Game]',
        'Library=RGSS104E.dll',
        'Scripts=Data/Scripts.rxdata',
        'Title=Original transfer fixture',
        'RTP1=',
        'RTP2=',
        'RTP3=',
        '',
      ].join('\r\n')),
    },
    maps: [
      LiteralFixtureMap(id: 7, width: 5, height: 5, layers: [
        List.filled(25, 384),
        List.filled(25, 0),
        List.filled(25, 0)
      ], events: [
        LiteralFixtureEvent(id: 1, x: 2, y: 2, pages: [
          LiteralFixtureEventPage(trigger: 1, commands: [
            const LiteralFixtureEventCommand(250, [
              LiteralFixtureObject('RPG::AudioFile',
                  {'@name': 'Exit Door', '@volume': 80, '@pitch': 100})
            ]),
            LiteralFixtureEventCommand(223, [tone(-255), 6]),
            const LiteralFixtureEventCommand(106, [8]),
            LiteralFixtureEventCommand(201, [0, 9, 2, 2, direction, 1]),
            if (interrupted) const LiteralFixtureEventCommand(106, [1]),
            LiteralFixtureEventCommand(209, [
              actor,
              LiteralFixtureObject('RPG::MoveRoute', {
                '@repeat': repeat,
                '@skippable': false,
                '@list': [step(stepCode), step(0)],
              })
            ]),
            LiteralFixtureEventCommand(509, [step(copyCode)]),
            LiteralFixtureEventCommand(223, [tone(0), 6]),
            if (extraEffect)
              const LiteralFixtureEventCommand(355, ['unknown()']),
            const LiteralFixtureEventCommand(0, []),
          ]),
        ]),
        if (autonomousRouteCodes != null)
          LiteralFixtureEvent(id: 2, x: 4, y: 4, pages: [
            LiteralFixtureEventPage(
                characterName: 'Ambient',
                moveType: 3,
                autonomousRouteCodes: autonomousRouteCodes,
                commands: const [LiteralFixtureEventCommand(0, [])]),
          ]),
      ]),
      LiteralFixtureMap(id: 9, width: 5, height: 5, layers: [
        List.filled(25, 384),
        List.filled(25, 0),
        List.filled(25, 0)
      ]),
    ],
  );
}

Future<SourceEventProjection> _project(LiteralTileFixture fixture,
    {bool includeContext = true,
    bool changedMap = false,
    bool existingActor = false,
    String? expectedContextRefusal}) async {
  final snapshot = SourceSnapshot(
    logicalProjectNamespace: fixture.snapshot.logicalProjectNamespace,
    policyHash: fixture.snapshot.policyHash,
    entries: [
      ...fixture.snapshot.entries,
      for (final row in [
        (
          'Game.exe',
          14732288,
          '5c75e92fcbb6ec50b9f8fc61913d751a8945d6a1fc69c3017c7b8686b532bf04'
        ),
        (
          'mkxp.json',
          6212,
          '90a3aee82895e48e6c767f973b637d27856cccfd575f48b78d04191cb3e7d35f'
        ),
      ])
        SourceFileEntry(
            fileId: ConverterId('fixture-${row.$1}'),
            relativePath: row.$1,
            kind: SourceNodeKind.file,
            byteLength: row.$2,
            sha256: Sha256Hash(row.$3),
            format: 'unknown',
            family: 'project')
    ],
    diagnostics: [],
    excludedPaths: [],
    profileEvidence: fixture.snapshot.profileEvidence,
    state: SourceScanState.complete,
  );
  final files = LiteralFixtureFiles(snapshot, fixture.sourceBytes);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: files,
      interpretationProfile: syntheticSourceInterpretationProfile,
      includeEventSystem: true,
      includeConnections: true);
  final analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  final programs = sourceStaticDoorPrograms(source: source, analysis: analysis);
  final maps = {
    for (final id in [7, 9])
      id: MapData(
          id: 'map_$id',
          name: 'Map $id',
          size: const GridSize(width: 5, height: 5),
          layers: []),
  };
  if (existingActor) {
    maps[9] = maps[9]!.copyWith(entities: [
      MapEntity(
          id: 'unknown_actor',
          name: 'Unknown',
          kind: MapEntityKind.npc,
          pos: const GridPos(x: 1, y: 1),
          size: const GridSize(width: 1, height: 1),
          npc: const MapEntityNpcData(
              characterId: 'unknown', displayName: 'Unknown')),
    ]);
  }
  final base = NativeProjectDraft(
    source: source,
    projectName: 'Post transfer step',
    parentPath: '/private/tmp',
    folderName: 'unused-post-transfer-step',
    mapIds: {for (final entry in maps.entries) entry.key: entry.value.id},
    artifacts: [],
    compositionEvidence: const {'sourceSemantics': {}},
    mutations: [
      for (final entry in maps.entries)
        NativeMutation(
            operationId: ConverterId('map_${entry.key}'),
            actionId: 'map.save',
            sourceEntityIds: [source.mapIdentity(entry.key)],
            targetEntityIds: [ConverterId(entry.value.id)],
            parameters: {'mapId': entry.value.id, 'map': entry.value.toJson()})
    ],
  );
  final contexts = includeContext
      ? await const SourceEventExecutionContextResolver().readStaticTransfers(
          source: source,
          base: base,
          nativeMaps: maps,
          files: files,
          programs: programs,
          analysis: analysis)
      : <ConverterId, SourceEventExecutionContext>{};
  for (final value in contexts.values) {
    expect(
        value.refusals,
        existingActor
            ? contains('sourceForcedRouteActorSetUnsupported')
            : expectedContextRefusal != null
                ? contains(expectedContextRefusal)
                : isEmpty);
  }
  if (changedMap) {
    maps[9] = maps[9]!.copyWith(name: 'Changed after qualification');
  }
  final sound = await const SourceEventSoundResolver()
      .read(source: source, files: files, name: 'Exit Door');
  return const SourceEventProjector().project(
    source: source,
    analysis: analysis,
    nativeMaps: maps,
    staticDoorPrograms: programs,
    staticDoorContexts: contexts,
    soundBindings: {'Exit Door': sound},
    retentionPolicy: MapInstanceRetentionPolicy(
        viewportWidthTiles: 20, viewportHeightTiles: 15, marginTiles: 1),
  );
}

void main() {
  for (final direction in [0, 2]) {
    test('blocked post transfer step still restores the world tone, facing=$direction', () async {
      final projection = await _project(await _fixture(direction: direction));
      final plan = buildSceneRuntimePlan(SceneAsset.fromJson(jsonDecode(
          jsonEncode(projection.scenes.single.toJson()))));
      final tones = <double>[];
      final result = await SceneRuntimeExecutor(callbacks: SceneRuntimeExecutionCallbacks(
          evaluateCondition: (intent) => intent.conditionSource!.playerFacingDirection == EntityFacing.south
              ? 'true' : 'false',
          showDialogue: (_) => throw StateError('No dialogue expected'),
          startBattle: (_) => throw StateError('No battle expected'),
          playCinematic: (_) => throw StateError('No cinematic expected'),
          applyConsequence: (_) => 'completed',
          executeInteractiveCommand: (intent) {
            final command = intent.interactiveCommand!;
            if (command is SceneWorldToneInteractiveCommand) tones.add(command.red);
            return command is SceneActorRouteInteractiveCommand ? 'blocked' : 'completed';
          })).execute(plan.plan!);
      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(tones, [-255.0, 0.0]);
    });
  }
  test(
      'local random movement and animation flags do not produce a forced route',
      () async {
    final projection =
        await _project(await _fixture(autonomousRouteCodes: [32, 9, 0]));
    final rows = (projection.semanticEvidence['events'] as List).cast<Map>();
    expect(rows.singleWhere((row) => row['locator']['eventId'] == 1)['status'],
        'adaptedStaticSemantics');
    expect(rows.singleWhere((row) => row['locator']['eventId'] == 2)['status'],
        'quarantinedWholeEvent');
    expect(
        projection.nativeMaps[7]!.entities
            .where((entity) => entity.name == 'Ambient'),
        isEmpty);
  });
  for (final code in [27, 28, 41, 45]) {
    test('ambient context still refuses stateful or opaque route $code',
        () async {
      final projection = await _project(
          await _fixture(autonomousRouteCodes: [32, code, 0]),
          expectedContextRefusal: 'sourceMapAutonomyContextUnsupported');
      expect(projection.scenes, isEmpty);
    });
  }
  test(
      'post transfer forward step preserves the player facing when warp keeps it',
      () async {
    final fixture = await _fixture(direction: 0);
    final projection = await _project(fixture);
    final row = (projection.semanticEvidence['events'] as List).single as Map;
    expect(row['status'], 'adaptedStaticSemantics', reason: row.toString());
    final scene = projection.scenes.single;
    final commands = scene.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((node) => node.interactiveCommand)
        .whereType<SceneInteractiveCommand>()
        .map((node) => node.toJson())
        .toList();
    final routes =
        commands.where((node) => node['kind'] == 'actorRoute').toList();
    expect(routes, hasLength(4));
    expect(
        routes
            .map((node) => ((node['steps'] as List).single as Map)['direction'])
            .toSet(),
        {'south', 'west', 'east', 'north'});
    expect(
        scene.graph.nodes
            .map((node) => node.payload)
            .whereType<SceneConditionPayload>()
            .where((node) =>
                node.conditionSource?.sourceKind ==
                SceneConditionSourceKind.playerFacing),
        hasLength(4));
    expect(routes.every((node) => (node['target'] as Map)['mapId'] == 'map_9'),
        isTrue);
    final plan = buildSceneRuntimePlan(
        SceneAsset.fromJson(jsonDecode(jsonEncode(scene.toJson()))));
    expect(plan.plan, isNotNull);
    for (final facing in EntityFacing.values) {
      final map = projection.nativeMaps[9]!;
      final world = GameplayWorldState.initial(
              map: map,
              playerPos: const GridPos(x: 2, y: 2),
              tileWidth: 32,
              tileHeight: 32)
          .withPlayer(GameplayPlayerState.fromGridSpawn(
              cell: const GridPos(x: 2, y: 2),
              facing: Direction.values.byName(facing.name),
              tileWidthPx: 32,
              tileHeightPx: 32,
              mapWidthCells: 5,
              mapHeightCells: 5));
      final executed = <SceneActorRouteInteractiveCommand>[];
      final result = await SceneRuntimeExecutor(
          callbacks: SceneRuntimeExecutionCallbacks(
              evaluateCondition: (intent) => evaluateScenePlayerFacing(
                      source: intent.conditionSource!, world: world)
                  ? 'true'
                  : 'false',
              showDialogue: (_) => throw StateError('No dialogue expected'),
              startBattle: (_) => throw StateError('No battle expected'),
              playCinematic: (_) => throw StateError('No cinematic expected'),
              applyConsequence: (_) => 'completed',
              executeInteractiveCommand: (intent) {
                if (intent.interactiveCommand
                    case final SceneActorRouteInteractiveCommand route) {
                  executed.add(route);
                }
                return 'completed';
              })).execute(plan.plan!);
      expect(result.status, SceneRuntimeExecutionStatus.completed,
          reason: result.message);
      expect(executed, hasLength(1));
      expect((executed.single.toJson()['steps'] as List).single,
          containsPair('direction', facing.name));
    }
  });
  for (final entry in {
    2: SourceMoveRouteStepKind.moveDown,
    4: SourceMoveRouteStepKind.moveLeft,
    6: SourceMoveRouteStepKind.moveRight,
    8: SourceMoveRouteStepKind.moveUp,
  }.entries) {
    test('post transfer forward step keeps explicit facing ${entry.key}',
        () async {
      final fixture = await _fixture(direction: entry.key);
      final analysis = SourceEventAnalyzer.forProject(fixture.source,
              profile: SourceEventProfile.forProject(fixture.source))
          .analyze();
      final event = analysis.events.single;
      expect(event.isQuarantined, isFalse);
      final route = event.pages.single.body.nodes
          .whereType<SourceForcedMoveRouteNode>()
          .single;
      expect(route.steps.single.sourceCode, 12);
      expect(route.steps.single.kind, entry.value);
      expect(
          sourceStaticDoorPrograms(source: fixture.source, analysis: analysis),
          contains(event.identity));
      final projection = await _project(fixture);
      final row = (projection.semanticEvidence['events'] as List).single as Map;
      expect(row['status'], 'adaptedStaticSemantics', reason: row.toString());
      final commands = projection.scenes.single.graph.nodes
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((node) => node.interactiveCommand)
          .whereType<SceneInteractiveCommand>()
          .map((node) => node.toJson())
          .toList();
      final native =
          commands.singleWhere((node) => node['kind'] == 'actorRoute');
      expect((native['target'] as Map)['mapId'], 'map_9');
      expect(
          (native['steps'] as List).single,
          containsPair('direction',
              {2: 'south', 4: 'west', 6: 'east', 8: 'north'}[entry.key]));
      expect(commands.where((node) => node['kind'] == 'waitForActorRoutes'),
          isEmpty);
      expect(projection.allEnabledOriginalEventsHaveExecutionContext, isTrue);
    });
  }

  for (final defect in [
    'invalidFacing',
    'eventActor',
    'repeat',
    'copy',
    'interrupted',
    'extraEffect'
  ]) {
    test('post transfer step refuses $defect without borrowing a door contract',
        () async {
      final fixture = await _fixture(
          direction: defect == 'invalidFacing' ? 1 : 2,
          actor: defect == 'eventActor' ? 0 : -1,
          repeat: defect == 'repeat',
          copyCode: defect == 'copy' ? 1 : 12,
          interrupted: defect == 'interrupted',
          extraEffect: defect == 'extraEffect');
      final analysis = SourceEventAnalyzer.forProject(fixture.source,
              profile: SourceEventProfile.forProject(fixture.source))
          .analyze();
      expect(
          sourceStaticDoorPrograms(source: fixture.source, analysis: analysis),
          isEmpty);
      expect((await _project(fixture)).scenes, isEmpty);
    });
  }

  for (final defect in ['missingContext', 'changedMap', 'existingActor']) {
    test('post transfer step refuses $defect', () async {
      final projection = await _project(await _fixture(),
          includeContext: defect != 'missingContext',
          changedMap: defect == 'changedMap',
          existingActor: defect == 'existingActor');
      expect(projection.scenes, isEmpty);
    });
  }
}
