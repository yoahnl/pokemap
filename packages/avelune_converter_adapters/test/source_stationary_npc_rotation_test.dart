import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

List<LiteralFixtureEventCommand> _rotation(int direction,
    {bool barrier = false, int target = 0, bool repeat = false, int indent = 0}) {
  final step = LiteralFixtureObject('RPG::MoveCommand',
      {'@code': direction, '@parameters': <Object?>[]});
  return [
    LiteralFixtureEventCommand(209, [
      target,
      LiteralFixtureObject('RPG::MoveRoute', {
        '@repeat': repeat,
        '@skippable': false,
        '@list': [
          step,
          const LiteralFixtureObject('RPG::MoveCommand',
              {'@code': 0, '@parameters': <Object?>[]}),
        ]
      })
    ], indent: indent),
    LiteralFixtureEventCommand(509, [step], indent: indent),
    if (barrier) LiteralFixtureEventCommand(210, [], indent: indent),
  ];
}

Future<SourceEventProjection> _project({
  int direction = 17,
  bool barrier = false,
  int target = 0,
  bool repeat = false,
  bool through = false,
  bool fixed = false,
  int moveType = 0,
  int trigger = 0,
  bool choice = false,
  bool warp = false,
  bool forge = false,
}) async {
  final fixture = await LiteralTileFixture.create(
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    extraFiles: {'Graphics/Characters/Npc.png': literalFixtureAtlas()},
    maps: [
      LiteralFixtureMap(id: 1, events: [
        LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [
          LiteralFixtureEventPage(
            characterName: 'Npc',
            through: through,
            directionFix: fixed,
            moveType: moveType,
            trigger: trigger,
            commands: [
              const LiteralFixtureEventCommand(101, ['First message.']),
              if (choice) ...[
                const LiteralFixtureEventCommand(102, [['Yes', 'No'], 2]),
                const LiteralFixtureEventCommand(402, [0, 'Yes']),
                const LiteralFixtureEventCommand(101, ['Accepted.'], indent: 1),
              ] else
                const LiteralFixtureEventCommand(101, ['Second message.']),
              ..._rotation(direction,
                  barrier: barrier, target: target, repeat: repeat,
                  indent: choice ? 1 : 0),
              if (warp)
                LiteralFixtureEventCommand(201, [0, 1, 2, 0, 0, 1],
                    indent: choice ? 1 : 0),
              if (choice) ...[
                const LiteralFixtureEventCommand(123, ['A', 0], indent: 1),
                const LiteralFixtureEventCommand(402, [1, 'No']),
                const LiteralFixtureEventCommand(101, ['Declined.'], indent: 1),
                ..._rotation(direction, indent: 1),
                const LiteralFixtureEventCommand(404, []),
              ],
            ],
          ),
          if (choice)
            LiteralFixtureEventPage(characterName: 'Npc', selfSwitch: 'A',
                commands: [
                  const LiteralFixtureEventCommand(101, ['We already spoke.']),
                  ..._rotation(direction),
                ]),
        ]),
      ])
    ],
  );
  final source = fixture.source;
  final original = SourceEventAnalyzer.forProject(source,
      profile: SourceEventProfile.forProject(source)).analyze();
  final event = original.events.single;
  final analysis = !forge ? original : SourceEventAnalysis(
    profile: original.profile,
    diagnostics: original.diagnostics,
    events: [SourceEventDefinition(
      sourceMapId: event.sourceMapId, sourceEventId: event.sourceEventId,
      sourceFileId: event.sourceFileId, identity: event.identity, name: event.name,
      x: event.x, y: event.y, locator: event.locator,
      pages: [for (final page in event.pages) SourceEventPageAnalysis(
        sourcePage: page.sourcePage, locator: page.locator,
        condition: page.condition, graphic: page.graphic,
        rawDataRef: page.rawDataRef, diagnostics: page.diagnostics,
        body: SourceEventBlock(span: page.body.span, nodes: [
          for (final node in page.body.nodes)
            if (node is! SourceForcedMoveRouteNode) node else
              SourceForcedMoveRouteNode(node.span,
                targetSourceCharacterId: node.targetSourceCharacterId,
                repeat: node.repeat, skippable: node.skippable,
                rawDataRefs: node.rawDataRefs,
                terminatorNodeId: node.terminatorNodeId,
                profileHash: node.profileHash,
                steps: [for (final step in node.steps) SourceMoveRouteStep(
                  kind: SourceMoveRouteStepKind.turnUp, sourceCode: 19,
                  rawDataRef: step.rawDataRef, routeNodeId: step.routeNodeId)],
              ),
        ]),
      )],
    )],
  );
  final charset = fixture.snapshot.entries.singleWhere(
      (entry) => entry.relativePath == 'Graphics/Characters/Npc.png');
  return const SourceEventProjector().project(
    source: source,
    analysis: analysis,
    nativeMaps: {1: MapData(id: 'map', name: 'Map',
        size: const GridSize(width: 3, height: 1))},
    characterBindings: {
      sourceEventCharacterBindingKey(characterName: 'Npc', pattern: 0, direction: 2):
        SourceEventCharacterBinding(characterId: 'npc',
            sourceSnapshotHash: fixture.snapshot.canonicalHash,
            sourceFileId: charset.fileId, sourceFileHash: charset.sha256!,
            sourcePattern: 0, sourceDirection: 2),
    },
  );
}

Iterable<SceneActorRouteInteractiveCommand> _routes(SourceEventProjection result) =>
    result.scenes.expand((scene) => scene.graph.nodes)
        .map((node) => node.payload).whereType<SceneActionPayload>()
        .map((payload) => payload.interactiveCommand)
        .whereType<SceneActorRouteInteractiveCommand>();

void main() {
  for (final sample in [
    (code: 16, facing: EntityFacing.south),
    (code: 17, facing: EntityFacing.west),
    (code: 18, facing: EntityFacing.east),
    (code: 19, facing: EntityFacing.north),
  ]) {
    for (final barrier in [false, true]) {
      test('stationary source cardinal rotation ${sample.code} barrier=$barrier', () async {
        final result = await _project(direction: sample.code, barrier: barrier);
        expect(result.registry.records.single.definitionOrNull, isNotNull);
        final route = _routes(result).single;
        expect(route.target.kind, SceneActorTargetKind.entity);
        expect(route.target.mapId, 'map');
        expect(route.steps, hasLength(1));
        expect(route.steps.single, isA<SceneActorFaceStep>()
            .having((step) => step.direction, 'direction', sample.facing));
      });
    }
  }

  test('choice branches and later pages keep their rotations and state effects', () async {
    final result = await _project(choice: true);
    expect(result.registry.records.map((record) => record.definitionOrNull),
        everyElement(isNotNull));
    expect(result.scenes, hasLength(2));
    expect(_routes(result), hasLength(3));
    expect(result.facts, hasLength(1));
  });

  for (final defect in ['player', 'repeat', 'through', 'fixed', 'moving',
    'touch', 'movement', 'relative', 'random', 'forged', 'warp', 'nestedWarp']) {
    test('stationary rotation refuses $defect', () async {
      final result = await _project(
        target: defect == 'player' ? -1 : 0,
        repeat: defect == 'repeat', through: defect == 'through',
        fixed: defect == 'fixed', moveType: defect == 'moving' ? 1 : 0,
        trigger: defect == 'touch' ? 1 : 0,
        direction: switch (defect) {'movement' => 1, 'relative' => 20,
          'random' => 24, _ => 17}, forge: defect == 'forged',
        warp: defect == 'warp' || defect == 'nestedWarp',
        choice: defect == 'nestedWarp',
      );
      expect(result.scenes, isEmpty);
      expect(result.registry.records.every((record) => record.definitionOrNull == null), isTrue);
    });
  }
}
