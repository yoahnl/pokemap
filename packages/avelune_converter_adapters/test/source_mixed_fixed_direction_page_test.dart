import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

List<LiteralFixtureEventCommand> _rotation(
    {int code = 19,
    int target = 0,
    bool repeat = false,
    bool corrupt = false,
    bool barrier = false}) {
  final step = LiteralFixtureObject(
      'RPG::MoveCommand', {'@code': code, '@parameters': <Object?>[]});
  return [
    LiteralFixtureEventCommand(209, [
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
    ]),
    LiteralFixtureEventCommand(509, [
      corrupt
          ? const LiteralFixtureObject(
              'RPG::MoveCommand', {'@code': 16, '@parameters': <Object?>[]})
          : step
    ]),
    if (barrier) const LiteralFixtureEventCommand(210, []),
  ];
}

Future<
        ({
          SourceEventProjection projection,
          List<SourceEventCharacterImport> characters
        })>
    _project(
        {String defect = '',
        int code = 19,
        bool barrier = false,
        String forge = ''}) async {
  final fixture = await LiteralTileFixture.create(
      scriptsBytes: syntheticInterpretationArchive,
      interpretationProfile: syntheticSourceInterpretationProfile,
      includeEventSystem: true,
      switchNames: List.generate(
          87, (index) => index == 0 ? null : 'Source switch $index'),
      variableNames: List.generate(
          40, (index) => index == 0 ? null : 'Source variable $index'),
      extraFiles: {
        'Graphics/Characters/Bill.png': literalFixtureAtlas()
      },
      maps: [
        LiteralFixtureMap(id: 227, width: 3, height: 3, layers: [
          List.filled(9, 384),
          List.filled(9, 0),
          List.filled(9, 0)
        ], events: [
          LiteralFixtureEvent(id: 8, x: 1, y: 1, name: 'Bill', pages: [
            LiteralFixtureEventPage(
                characterName: 'Bill',
                direction: 8,
                directionFix: true,
                commands: [
                  const LiteralFixtureEventCommand(101, [r'\bHmm...']),
                  const LiteralFixtureEventCommand(
                      101, [r'\bHow about we try this like this...']),
                  if (defect == 'fixedRotation' || defect == 'fixedFacing')
                    ..._rotation(code: defect == 'fixedFacing' ? 25 : 19),
                ]),
            LiteralFixtureEventPage(
                characterName: 'Bill',
                direction: 8,
                globalSwitch: 86,
                directionFix: defect == 'allFixed',
                moveType: defect == 'autonomy' ? 1 : 0,
                through: defect == 'through',
                trigger: defect == 'touch' ? 1 : 0,
                commands: [
                  const LiteralFixtureEventCommand(101, [r'\bOh, hey!']),
                  const LiteralFixtureEventCommand(
                      101, [r'\bWe got the PC working!']),
                  const LiteralFixtureEventCommand(
                      101, [r'\bI have things to show Celio.']),
                  const LiteralFixtureEventCommand(
                      101, [r'\bPlease go for a stroll.']),
                  ..._rotation(
                      code: defect == 'movement' ? 1 : code,
                      target: defect == 'player'
                          ? -1
                          : defect == 'foreign'
                              ? 3
                              : 0,
                      repeat: defect == 'repeat',
                      corrupt: defect == 'rawCopy',
                      barrier: barrier),
                  if (defect == 'ruby')
                    const LiteralFixtureEventCommand(355, ['unknown()']),
                  if (defect == 'common')
                    const LiteralFixtureEventCommand(117, [1]),
                  if (defect == 'warp')
                    const LiteralFixtureEventCommand(201, [0, 227, 0, 0, 2, 0]),
                ]),
            const LiteralFixtureEventPage(
                globalSwitch: 79,
                through: true,
                direction: 8,
                commands: [LiteralFixtureEventCommand(0, [])]),
            const LiteralFixtureEventPage(
                variableId: 39,
                variableThreshold: 1,
                through: true,
                commands: [LiteralFixtureEventCommand(0, [])]),
          ])
        ])
      ]);
  final original = SourceEventAnalyzer.forProject(fixture.source,
          profile: SourceEventProfile.forProject(fixture.source))
      .analyze();
  final owner = original.events.single;
  final analysis = forge.isEmpty
      ? original
      : SourceEventAnalysis(
          profile: original.profile,
          diagnostics: original.diagnostics,
          events: [
              SourceEventDefinition(
                  identity: owner.identity,
                  sourceFileId: owner.sourceFileId,
                  sourceMapId: owner.sourceMapId,
                  sourceEventId: owner.sourceEventId,
                  name: owner.name,
                  x: forge == 'position' ? 0 : owner.x,
                  y: owner.y,
                  locator: owner.locator,
                  pages: [
                    for (final page in owner.pages)
                      SourceEventPageAnalysis(
                          sourcePage: page.sourcePage,
                          locator: page.locator,
                          graphic: page.graphic,
                          condition: forge == 'condition' &&
                                  page.originalPageIndex == 1
                              ? owner.pages.first.condition
                              : page.condition,
                          rawDataRef: forge == 'rawReference' &&
                                  page.originalPageIndex == 1
                              ? owner.pages.first.rawDataRef
                              : page.rawDataRef,
                          diagnostics: page.diagnostics,
                          body: forge == 'routeBody' &&
                                  page.originalPageIndex == 1
                              ? SourceEventBlock(
                                  span: page.body.span,
                                  nodes: page.body.nodes
                                      .where((n) =>
                                          n is! SourceForcedMoveRouteNode)
                                      .toList())
                              : page.body)
                  ])
            ]);
  final characters = <SourceEventCharacterImport>[];
  final bindings = <String, SourceEventCharacterBinding>{};
  for (final page in analysis.events.single.pages) {
    final graphic = page.graphic!;
    if (graphic.characterName.isEmpty) continue;
    final imported = await const SourceEventCharacterImporter().read(
        snapshot: fixture.snapshot,
        files: fixture.files,
        charsetName: graphic.characterName,
        sourcePattern: graphic.pattern,
        sourceDirection: graphic.direction,
        fixedDirection: graphic.directionFix);
    characters.add(imported);
    bindings[imported.bindingKey] = imported.binding;
  }
  return (
    projection: const SourceEventProjector().project(
        source: fixture.source,
        analysis: analysis,
        nativeMaps: {
          227: MapData(
              id: 'map227',
              name: 'Map',
              size: const GridSize(width: 3, height: 3))
        },
        characterBindings: bindings),
    characters: characters
  );
}

Map _evidence(SourceEventProjection projection) =>
    (projection.semanticEvidence['events'] as List).single as Map;

void main() {
  for (final code in [16, 17, 18, 19]) {
    test('fixed text page coexists with source-bound nonfixed rotation $code',
        () async {
      final result = await _project(code: code, barrier: true);
      expect(_evidence(result.projection)['gaps'], isEmpty);
      expect(_evidence(result.projection)['status'], 'adaptedStaticSemantics');
      expect(result.characters.map((c) => c.binding.fixedDirection),
          [true, false]);
      expect(
          result.characters.map((c) => c.character.id).toSet(), hasLength(2));
      final records = result.projection.registry.records;
      expect(records, hasLength(4));
      expect(
          records.every((r) =>
              r.when(draft: (_) => false, configured: (_, enabled) => enabled)),
          isTrue);
      final scenes = result.projection.scenes
          .where((s) => s.metadata['sourcePageIndex'] == '1');
      final actions = scenes
          .expand((s) => s.graph.nodes)
          .map((n) => n.payload)
          .whereType<SceneActionPayload>()
          .map((p) => p.interactiveCommand)
          .toList();
      final route =
          actions.whereType<SceneActorRouteInteractiveCommand>().single;
      expect(route.target.kind, SceneActorTargetKind.entity);
      expect(route.steps.single, isA<SceneActorFaceStep>());
      expect(
          (route.steps.single as SceneActorFaceStep).direction,
          {
            16: EntityFacing.south,
            17: EntityFacing.west,
            18: EntityFacing.east,
            19: EntityFacing.north
          }[code]);
      expect(actions.whereType<SceneWaitForActorRoutesInteractiveCommand>(),
          hasLength(1));
      expect(
          result.projection.scenes
              .where((s) => s.metadata['sourcePageIndex'] == '0')
              .expand((s) => s.graph.nodes)
              .map((n) => n.payload)
              .whereType<SceneActionPayload>()
              .map((p) => p.interactiveCommand)
              .whereType<SceneActorRouteInteractiveCommand>(),
          isEmpty);
    });
  }
  test('Bill source rotation without barrier retains its existing semantics',
      () async {
    final result = await _project();
    expect(_evidence(result.projection)['gaps'], isEmpty);
  });
  for (final defect in [
    'fixedRotation',
    'fixedFacing',
    'allFixed',
    'movement',
    'player',
    'foreign',
    'repeat',
    'rawCopy',
    'ruby',
    'common',
    'warp',
    'autonomy',
    'through',
    'touch'
  ]) {
    test('mixed fixed presentation refuses $defect', () async {
      final result = await _project(defect: defect);
      expect(_evidence(result.projection)['gaps'], isNotEmpty);
      expect(result.projection.nativeMaps[227]!.entities, isEmpty);
    });
  }
  for (final forge in ['position', 'condition', 'rawReference', 'routeBody']) {
    test('mixed pages reject source/analysis divergence $forge', () async {
      final result = await _project(forge: forge);
      expect(_evidence(result.projection)['gaps'],
          contains('pageGraphicContractUnsupported'));
      expect(result.projection.nativeMaps[227]!.entities, isEmpty);
    });
  }
}
