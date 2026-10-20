import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<SourceEventProjection> _project({bool choices = true,
    bool hiddenPage = false, bool visibleStationaryPage = false,
    bool unknownEffect = false, bool randomWalk = false,
    bool forge = false, bool forgeHidden = false,
    bool unknownRoute = false, bool openLoop = false, bool invisibleFirst = false}) async {
  const turn = LiteralFixtureObject('RPG::MoveCommand',
      {'@code': 25, '@parameters': <Object?>[]});
  final commands = <LiteralFixtureEventCommand>[
    const LiteralFixtureEventCommand(108, ['Source annotation.']),
    const LiteralFixtureEventCommand(101, ['Want to know?']),
    if (choices) ...const [
      LiteralFixtureEventCommand(102, [['Yes', 'No'], 2]),
      LiteralFixtureEventCommand(402, [0, 'Yes']),
      LiteralFixtureEventCommand(101, ['The first answer.'], indent: 1),
      LiteralFixtureEventCommand(0, [], indent: 1),
      LiteralFixtureEventCommand(402, [1, 'No']),
      LiteralFixtureEventCommand(101, ['The second answer.'], indent: 1),
      LiteralFixtureEventCommand(0, [], indent: 1),
      LiteralFixtureEventCommand(404, []),
    ],
    if (unknownEffect) const LiteralFixtureEventCommand(355, ['arbitraryEffect()']),
    LiteralFixtureEventCommand(209, [0,
      const LiteralFixtureObject('RPG::MoveRoute', {'@repeat': false,
        '@skippable': false, '@list': [turn,
          LiteralFixtureObject('RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})]})]),
    const LiteralFixtureEventCommand(509, [turn]),
    const LiteralFixtureEventCommand(0, []),
  ];
  final fixture = await LiteralTileFixture.create(
    scriptsBytes: syntheticInterpretationArchive,
    interpretationProfile: syntheticSourceInterpretationProfile, includeEventSystem: true,
    extraFiles: {'Graphics/Characters/Guide.png': image.encodePng(image.Image(width: 128, height: 192))},
    maps: [LiteralFixtureMap(id: 1, width: 5, height: 5,
      layers: [List.filled(25, 384), List.filled(25, 0), List.filled(25, 0)],
      events: [LiteralFixtureEvent(id: 1, x: 2, y: 2, name: 'Patrolling guide', pages: [
        if (invisibleFirst) const LiteralFixtureEventPage(moveType: 3, through: true, autonomousRouteCodes: [3, 2, 0], commands: [LiteralFixtureEventCommand(0, [])]),
        LiteralFixtureEventPage(characterName: 'Guide', moveType: randomWalk ? 1 : 3,
          autonomousRouteCodes: unknownRoute ? [45, 0] : openLoop ? [3, 0] : [3, 2, 0],
          commands: commands),
        if (hiddenPage || visibleStationaryPage) LiteralFixtureEventPage(
          globalSwitch: 1, characterName: visibleStationaryPage ? 'Guide' : '', through: !visibleStationaryPage,
          commands: visibleStationaryPage ? commands : const [LiteralFixtureEventCommand(0, [])]),
      ])])]);
  final original = SourceEventAnalyzer.forProject(fixture.source,
    profile: SourceEventProfile.forProject(fixture.source)).analyze();
  final owner = original.events.single;
  final analysis = !forge && !forgeHidden ? original : SourceEventAnalysis(
    profile: original.profile, diagnostics: original.diagnostics,
    events: [SourceEventDefinition(identity: owner.identity,
      sourceFileId: owner.sourceFileId, sourceMapId: owner.sourceMapId,
      sourceEventId: owner.sourceEventId, name: forge ? 'Forged owner' : owner.name,
      x: owner.x, y: owner.y, locator: owner.locator,
      pages: [for (final page in owner.pages)
        if (!forgeHidden || page.originalPageIndex == 0) page else
          SourceEventPageAnalysis(sourcePage: page.sourcePage, locator: page.locator,
            condition: SourceEventCondition(kind: SourceEventConditionKind.always), body: page.body,
            rawDataRef: page.rawDataRef, diagnostics: page.diagnostics, graphic: page.graphic)])]);
  final imported = await const SourceEventCharacterImporter().read(
    snapshot: fixture.snapshot, files: fixture.files, charsetName: 'Guide',
    sourcePattern: 0, sourceDirection: 2);
  return const SourceEventProjector().project(source: fixture.source, analysis: analysis,
    nativeMaps: {1: const MapData(id: 'patrol-map', name: 'Patrol', size: GridSize(width: 5, height: 5))},
    characterBindings: {imported.bindingKey: imported.binding});
}

Map _row(SourceEventProjection projection) =>
    (projection.semanticEvidence['events'] as List).single as Map;

void main() {
  test('fixed patrol keeps choices and terminal face-player without losing movement', () async {
    final projection = await _project();
    expect(_row(projection)['status'], 'adaptedStaticSemantics', reason: '${_row(projection)['gaps']}');
    final npc = projection.nativeMaps[1]!.entities.single.npc!;
    expect(npc.movement.mode, MapEntityNpcMovementMode.fixedRoute);
    expect(npc.movement.routeSteps, hasLength(2));
    final scene = SceneAsset.fromJson(jsonDecode(jsonEncode(projection.scenes.single.toJson())));
    final labels = scene.graph.edges.map((edge) => edge.fromPortId).toSet();
    expect(labels, containsAll(['choice_0', 'choice_1']));
    expect((_row(projection)['nativeFixedRoute'] as Map)['sourceParity'], false);
  });

  test('fixed patrol permits an exact later empty invisible source page', () async {
    final projection = await _project(choices: false, hiddenPage: true);
    expect(_row(projection)['status'], 'adaptedStaticSemantics', reason: '${_row(projection)['gaps']}');
    expect(projection.nativeMaps[1]!.entities.single.npc!.movement.routeSteps, hasLength(2));
    expect(_row(projection)['pages'], hasLength(2));
    final map = projection.nativeMaps[1]!;
    final entity = map.entities.single;
    final project = ProjectManifest(name: 'Patrol', maps: const [],
      tilesets: const [], settings: const ProjectSettings(), facts: projection.facts,
      characters: [for (final id in entity.presentation!.variants
          .map((variant) => variant.characterId).whereType<String>().toSet())
        ProjectCharacterEntry(id: id, name: 'Guide', tilesetId: 'guide-atlas')]);
    final visible = projectMapEntityPresentation(project: project,
      gameState: const GameState(saveId: 'patrol'), map: map, entity: entity)!;
    expect(visible.npc!.movement.routeSteps, hasLength(2));
    expect(visible.blocksMovement, true);
    final hidden = projectMapEntityPresentation(project: project,
      gameState: GameState(saveId: 'patrol', narrativeFactRuntimeState:
        NarrativeFactRuntimeState(overridesByFactId:
          {for (final fact in projection.facts) fact.id: true})),
      map: map, entity: entity)!;
    expect(hidden.npc, isNull);
    expect(hidden.blocksMovement, false);
  });

  test('fixed route retains an earlier invisible page with the same qualified route', () async {
    final projection = await _project(choices: false, invisibleFirst: true);
    expect(_row(projection)['status'], 'adaptedStaticSemantics', reason: '${_row(projection)['gaps']}');
    expect((_row(projection)['nativeFixedRoute'] as Map)['pages'], hasLength(2));
  });

  for (final (name, run) in <(String, Future<SourceEventProjection> Function())>[
    ('unknown effect', () => _project(unknownEffect: true)),
    ('random walk', () => _project(randomWalk: true)),
    ('forged owner', () => _project(forge: true)),
    ('forged hidden condition', () => _project(choices: false, hiddenPage: true, forgeHidden: true)),
    ('unknown autonomous route', () => _project(unknownRoute: true)),
    ('open looping route', () => _project(openLoop: true)),
    ('visible stationary override', () => _project(visibleStationaryPage: true)),
  ]) {
    test('refuses $name', () async {
      final projection = await run();
      expect(_row(projection)['status'], 'quarantinedWholeEvent');
    });
  }
}
