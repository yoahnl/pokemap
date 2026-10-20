import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

List<LiteralFixtureEventCommand> _turn(
    {int indent = 0,
    int target = 0,
    int code = 25,
    bool repeat = false,
    bool corrupt = false}) {
  final step = LiteralFixtureObject(
      'RPG::MoveCommand', {'@code': code, '@parameters': <Object?>[]});
  return [
    LiteralFixtureEventCommand(
        209,
        [
          target,
          LiteralFixtureObject('RPG::MoveRoute', {
            '@repeat': repeat,
            '@skippable': false,
            '@list': [
              step,
              const LiteralFixtureObject(
                  'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})
            ]
          })
        ],
        indent: indent),
    LiteralFixtureEventCommand(
        509,
        [
          corrupt
              ? const LiteralFixtureObject(
                  'RPG::MoveCommand', {'@code': 16, '@parameters': <Object?>[]})
              : step
        ],
        indent: indent),
  ];
}

Future<SourceEventProjection> _project(
    {String defect = '',
    bool factFirst = false,
    bool choice = true,
    bool forge = false,
    String? passiveContext}) async {
  final commands = <LiteralFixtureEventCommand>[
    const LiteralFixtureEventCommand(101, ['A question.']),
    if (choice) ...const [
      LiteralFixtureEventCommand(102, [
        ['Yes', 'No'],
        2
      ]),
      LiteralFixtureEventCommand(402, [0, 'Yes']),
    ],
    if (factFirst)
      LiteralFixtureEventCommand(123, ['A', 0], indent: choice ? 1 : 0),
    if (defect == 'missingPickup')
      LiteralFixtureEventCommand(355, ['pbReceiveItem(:POTION)'],
          indent: choice ? 1 : 0),
    ..._turn(
        indent: choice ? 1 : 0,
        target: defect == 'player' ? -1 : 0,
        code: defect == 'movement' ? 1 : 25,
        repeat: defect == 'repeat',
        corrupt: defect == 'rawCopy'),
    if (!factFirst)
      LiteralFixtureEventCommand(123, ['A', 0], indent: choice ? 1 : 0),
    if (defect == 'common')
      LiteralFixtureEventCommand(117, [1], indent: choice ? 1 : 0),
    if (defect == 'orientation') ...[
      LiteralFixtureEventCommand(111, [6, 0, 2], indent: choice ? 1 : 0),
      LiteralFixtureEventCommand(101, ['Facing state.'],
          indent: choice ? 2 : 1),
      LiteralFixtureEventCommand(412, [], indent: choice ? 1 : 0),
    ],
    if (defect == 'warp')
      LiteralFixtureEventCommand(201, [0, 1, 0, 0, 2, 0],
          indent: choice ? 1 : 0),
    if (defect == 'ruby')
      LiteralFixtureEventCommand(355, ['unknown()'], indent: choice ? 1 : 0),
    if (choice) ...const [
      LiteralFixtureEventCommand(402, [1, 'No']),
      LiteralFixtureEventCommand(101, ['Declined.'], indent: 1),
      LiteralFixtureEventCommand(404, []),
    ],
    const LiteralFixtureEventCommand(0, []),
  ];
  final fixture = await LiteralTileFixture.create(
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    extraFiles: {'Graphics/Characters/Guide.png': literalFixtureAtlas()},
    maps: [
      LiteralFixtureMap(id: 1, width: 3, height: 3, layers: [
        List.filled(9, 384),
        List.filled(9, 0),
        List.filled(9, 0)
      ], events: [
        LiteralFixtureEvent(
            id: 1,
            x: 1,
            y: 1,
            name: defect == 'wide' ? 'Guide size(2,1)' : 'Guide',
            pages: [
              LiteralFixtureEventPage(
                  characterName: 'Guide',
                  moveType: defect == 'autonomy' ? 1 : 0,
                  through: defect == 'through',
                  directionFix: defect == 'fixed',
                  trigger: defect == 'touch' ? 1 : 0,
                  commands: commands),
              LiteralFixtureEventPage(
                  characterName: 'Guide',
                  selfSwitch: 'A',
                  direction: 8,
                  commands: const [
                    LiteralFixtureEventCommand(101, ['Changed page.']),
                    LiteralFixtureEventCommand(0, []),
                  ]),
            ]),
        if (defect == 'parallel' || defect == 'autorun')
          LiteralFixtureEvent(id: 2, x: 0, y: 0, pages: [
            LiteralFixtureEventPage(
                trigger: defect == 'parallel' ? 4 : 3,
                commands: const [
                  LiteralFixtureEventCommand(101, ['Concurrent.']),
                  LiteralFixtureEventCommand(0, [])
                ]),
          ]),
        if (passiveContext != null)
          LiteralFixtureEvent(id: 3, x: 0, y: 0, name: 'Television', pages: [
            LiteralFixtureEventPage(
                selfSwitch: passiveContext == 'missingCondition' ? null : 'A',
                trigger: passiveContext == 'parallel' ? 4 : 3,
                commands: [
                  LiteralFixtureEventCommand(101, [
                    passiveContext == 'textControl'
                        ? r'Unknown\ch[1,2,Yes,No]'
                        : 'A television programme.'
                  ]),
                  if (passiveContext == 'variable')
                    const LiteralFixtureEventCommand(122, [7, 7, 0, 0, 9]),
                  if (passiveContext == 'door') ...[
                    const LiteralFixtureEventCommand(
                        111, [12, 'get_self.onEvent?']),
                    ..._turn(indent: 1, target: -1, code: 1),
                    const LiteralFixtureEventCommand(210, [], indent: 1),
                    const LiteralFixtureEventCommand(412, []),
                  ],
                  LiteralFixtureEventCommand(123, [
                    passiveContext == 'foreignSelf' ? 'B' : 'A',
                    passiveContext == 'resetTrue' ? 0 : 1
                  ]),
                  const LiteralFixtureEventCommand(0, []),
                ]),
          ]),
      ])
    ],
  );
  final source = fixture.source;
  final analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  final owner = analysis.eventAt(1, 1)!;
  final actual = !forge
      ? analysis
      : SourceEventAnalysis(
          profile: analysis.profile,
          diagnostics: analysis.diagnostics,
          events: [
              SourceEventDefinition(
                  sourceMapId: owner.sourceMapId,
                  sourceEventId: owner.sourceEventId,
                  sourceFileId: owner.sourceFileId,
                  identity: owner.identity,
                  name: owner.name,
                  x: 2,
                  y: owner.y,
                  locator: owner.locator,
                  pages: owner.pages),
            ]);
  final charset = fixture.snapshot.entries.singleWhere(
      (entry) => entry.relativePath == 'Graphics/Characters/Guide.png');
  return const SourceEventProjector()
      .project(source: source, analysis: actual, nativeMaps: {
    1: MapData(
        id: 'map', name: 'Map', size: const GridSize(width: 3, height: 3))
  }, characterBindings: {
    if (defect != 'missingBinding')
      for (final direction in [2, 8])
        sourceEventCharacterBindingKey(
                characterName: 'Guide', pattern: 0, direction: direction):
            SourceEventCharacterBinding(
                characterId: 'guide',
                sourceSnapshotHash: fixture.snapshot.canonicalHash,
                sourceFileId: charset.fileId,
                sourceFileHash: defect == 'staleBinding'
                    ? Sha256Hash('0' * 64)
                    : charset.sha256!,
                sourcePattern: 0,
                sourceDirection: direction),
  });
}

void main() {
  for (final factFirst in [false, true]) {
    test(
        'attested television context keeps the facing and page refresh $factFirst',
        () async {
      final projection =
          await _project(factFirst: factFirst, passiveContext: 'safe');
      final row = (projection.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) => row['locator']['eventId'] == 1);
      expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
      final proof = (row['pages'] as List)
          .expand((page) => page['adaptedCommands'] as List)
          .cast<Map>()
          .singleWhere((command) =>
              command['nativeContract'] ==
              'sourceOrderedPlayerFacingEntityActorRoute');
      final contexts = proof['concurrentTextSelfResetAutoruns'] as List;
      expect(contexts, hasLength(1));
      expect(contexts.single['eventId'], 3);
      expect(contexts.single['rawDataRef'], isNotNull);
      expect(contexts.single['onlyEffect'], 'clearOwnSelfA');
      expect(contexts.single['nativeExecutionQualification'],
          'independentOriginalEventQualification');
      final map = projection.nativeMaps[1]!;
      final entity = map.entities
          .singleWhere((entity) => entity.npc?.characterId == 'guide');
      final project = ProjectManifest(
          name: 'Television context',
          tilesets: const [],
          maps: const [],
          facts: projection.facts);
      expect(
          resolveMapEntityPresentation(
                  project: project,
                  gameState: const GameState(saveId: 'test'),
                  map: map,
                  entity: entity)!
              .facing,
          EntityFacing.south);
      expect(
          resolveMapEntityPresentation(
                  project: project,
                  gameState: GameState(
                      saveId: 'test',
                      narrativeFactRuntimeState: NarrativeFactRuntimeState(
                          overridesByFactId: {
                            projection.facts.first.id: true
                          })),
                  map: map,
                  entity: entity)!
              .facing,
          EntityFacing.north);
    });
  }
  for (final concurrent in ['autorun', 'parallel']) {
    test('a safe television does not hide another concurrent $concurrent',
        () async {
      final projection =
          await _project(passiveContext: 'safe', defect: concurrent);
      final row = (projection.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) => row['locator']['eventId'] == 1);
      expect(row['status'], 'quarantinedWholeEvent');
    });
  }
  for (final context in [
    'variable',
    'foreignSelf',
    'resetTrue',
    'missingCondition',
    'textControl',
    'parallel',
    'door'
  ]) {
    test('refuses a modified television or another interpreter $context',
        () async {
      final projection = await _project(passiveContext: context);
      final row = (projection.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) => row['locator']['eventId'] == 1);
      expect(row['status'], 'quarantinedWholeEvent');
    });
  }
  for (final factFirst in [false, true]) {
    for (final facing in EntityFacing.values) {
      test(
          'explicit facing preserves source order and page refresh $factFirst/$facing',
          () async {
        final projection = await _project(factFirst: factFirst);
        expect(projection.scenes, hasLength(2));
        final map = projection.nativeMaps[1]!;
        final entity = map.entities.single;
        final project = ProjectManifest(
            name: 'Source ordered facing',
            tilesets: const [],
            maps: [
              ProjectMapEntry(
                  id: map.id, name: map.name, relativePath: 'maps/map.json')
            ],
            facts: projection.facts);
        expect(
            resolveMapEntityPresentation(
                    project: project,
                    gameState: const GameState(saveId: 'test'),
                    map: map,
                    entity: entity)!
                .facing,
            EntityFacing.south);
        expect(
            resolveMapEntityPresentation(
                    project: project,
                    gameState: GameState(
                        saveId: 'test',
                        narrativeFactRuntimeState: NarrativeFactRuntimeState(
                            overridesByFactId: {
                              projection.facts.single.id: true
                            })),
                    map: map,
                    entity: entity)!
                .facing,
            EntityFacing.north);
        final scene = SceneAsset.fromJson(
            jsonDecode(jsonEncode(projection.scenes.first.toJson())));
        final plan = buildSceneRuntimePlan(scene);
        expect(plan.plan, isNotNull);
        final order = <String>[];
        final result = await SceneRuntimeExecutor(
            callbacks: SceneRuntimeExecutionCallbacks(
          evaluateCondition: (intent) =>
              intent.conditionSource!.playerFacingDirection == facing
                  ? 'true'
                  : 'false',
          showDialogue: (_) {
            order.add('dialogue');
            return 'choice_0';
          },
          startBattle: (_) => throw StateError('Unexpected battle'),
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
          executeInteractiveCommand: (intent) {
            final command = intent.interactiveCommand;
            if (command is SceneActorRouteInteractiveCommand) {
              expect(command.target.kind, SceneActorTargetKind.entity);
              final face = command.steps.single as SceneActorFaceStep;
              expect(
                  face.direction,
                  switch (facing) {
                    EntityFacing.north => EntityFacing.south,
                    EntityFacing.south => EntityFacing.north,
                    EntityFacing.west => EntityFacing.east,
                    EntityFacing.east => EntityFacing.west,
                  });
              order.add('face');
            } else {
              expect(command, isA<SceneWaitForActorRoutesInteractiveCommand>());
              order.add('join');
            }
            return 'completed';
          },
          applyConsequence: (_) {
            order.add('refresh');
            return 'completed';
          },
        )).execute(plan.plan!);
        expect(result.status, SceneRuntimeExecutionStatus.completed);
        expect(
            order,
            factFirst
                ? ['dialogue', 'refresh', 'face', 'join']
                : ['dialogue', 'face', 'join', 'refresh']);
      });
    }
  }

  for (final defect in [
    'movement',
    'player',
    'repeat',
    'rawCopy',
    'warp',
    'ruby',
    'autonomy',
    'through',
    'fixed',
    'touch',
    'wide',
    'parallel',
    'autorun',
    'missingBinding',
    'staleBinding',
    'forgedOwner',
    'common',
    'orientation',
    'missingPickup'
  ]) {
    test('refuses unsafe or unbound facing program $defect', () async {
      final result =
          await _project(defect: defect, forge: defect == 'forgedOwner');
      final row = (result.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) => row['locator']['eventId'] == 1);
      expect(row['status'], 'quarantinedWholeEvent');
    });
  }
}
