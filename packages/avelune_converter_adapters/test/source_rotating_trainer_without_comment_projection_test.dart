import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_trainer_fixture.dart';

Future<
    ({
      NormalizedSourceProject source,
      SourceEventAnalysis analysis,
      SourceTrainerEventBindings bindings,
      SourceEventProjection projection
    })> _fixture(List<int> rotations, {bool blocked = false}) async {
  const roster = (type: 'FRLG_CAMPER', name: 'Bryce', version: 0);
  final original = nativeTrainerFixtureEvent(roster, 1);
  final fixture = await LiteralTileFixture.create(
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    tilesets: [
      LiteralFixtureTileset(
          id: 1,
          passages: blocked ? {384: 15} : {},
          terrainTags: blocked ? {384: 7} : {})
    ],
    extraFiles: {
      ...nativeTrainerFixtureFiles([roster]),
      'PBS/pokemon.txt': utf8.encode('[RATTATA]\nName = Rattata\n'),
      'Data/species.dat': literalFixtureMarshal({
        const LiteralFixtureSymbol('RATTATA'):
            const LiteralFixtureObject('GameData::Species', {
          '@id': LiteralFixtureSymbol('RATTATA'),
          '@species': LiteralFixtureSymbol('RATTATA'),
          '@form': 0,
          '@real_name': 'Rattata',
        }),
      }),
      'Graphics/Characters/OriginalTrainer.png':
          image.encodePng(image.Image(width: 128, height: 192)),
    },
    maps: [
      LiteralFixtureMap(id: 239, width: 5, height: 5, layers: [
        List.filled(25, 384),
        List.filled(25, 0),
        List.filled(25, 0),
      ], events: [
        LiteralFixtureEvent(
            id: 5,
            x: 2,
            y: 2,
            name: 'Camper Bryce Trainer(3)',
            pages: [
              LiteralFixtureEventPage(
                  characterName: 'OriginalTrainer',
                  trigger: 2,
                  moveType: 3,
                  autonomousRouteCodes: rotations,
                  commands: [
                    ...original.pages.first.commands
                        .where((command) => command.code != 108),
                  ]),
              LiteralFixtureEventPage(
                  characterName: 'OriginalTrainer',
                  selfSwitch: 'A',
                  moveType: 3,
                  autonomousRouteCodes: rotations,
                  commands: const [
                    LiteralFixtureEventCommand(101, ['See you!']),
                    LiteralFixtureEventCommand(0, []),
                  ]),
            ])
      ])
    ],
  );
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot,
      files: fixture.files,
      interpretationProfile: syntheticSourceInterpretationProfile,
      includeEventSystem: true);
  final analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  final bindings = await const SourceTrainerEventBindingResolver()
      .read(source: source, analysis: analysis, files: fixture.files);
  final imported = await const SourceEventCharacterImporter().read(
      snapshot: source.snapshot,
      files: fixture.files,
      charsetName: 'OriginalTrainer',
      sourcePattern: 0,
      sourceDirection: 2);
  final semantic = SourceSemanticResolver.forProject(source);
  final collisions = SourceCollisionProjection.resolve(cells: [
    for (var y = 0; y < 5; y++)
      for (var x = 0; x < 5; x++) semantic.cellAt(239, x, y),
  ], resolver: semantic, mapSize: const GridSize(width: 5, height: 5));
  final projection = const SourceEventProjector().project(
      source: source,
      analysis: analysis,
      nativeMaps: {
        239: MapData(
            id: 'native_239',
            name: 'Route',
            size: const GridSize(width: 5, height: 5),
            layers: [
              MapLayer.collision(
                  id: 'passages',
                  name: 'Source passages',
                  collisions: collisions.fullyBlockedCells)
            ])
      },
      characterBindings: {
        sourceEventCharacterBindingKey(
            characterName: 'OriginalTrainer',
            pattern: 0,
            direction: 2): imported.binding
      },
      trainerBindings: bindings.byEventIdentity);
  return (
    source: source,
    analysis: analysis,
    bindings: bindings,
    projection: projection
  );
}

Iterable<SceneNode> _reachable(
    SceneAsset scene, String battleId, String port) sync* {
  final pending = scene.graph.edges
      .where((edge) => edge.fromNodeId == battleId && edge.fromPortId == port)
      .map((edge) => edge.toNodeId)
      .toList();
  final seen = <String>{};
  while (pending.isNotEmpty) {
    final id = pending.removeLast();
    if (!seen.add(id)) continue;
    yield scene.graph.nodes.singleWhere((node) => node.id == id);
    pending.addAll(scene.graph.edges
        .where((edge) => edge.fromNodeId == id)
        .map((edge) => edge.toNodeId));
  }
}

List<SceneConsequence> _consequences(Iterable<SceneNode> nodes) => [
      for (final node in nodes)
        if (node.payload case SceneActionPayload(:final consequence?))
          consequence,
    ];

void main() {
  for (final rotations in [
    [17, 18, 0],
    [24, 0],
    [18, 19, 17, 16, 0]
  ]) {
    test(
        'native no-comment rotating trainer preserves route and victory dispatch $rotations',
        () async {
      final fixture = await _fixture(rotations);
      final (:source, :analysis, :bindings, :projection) = fixture;
      expect(analysis.events.single.isQuarantined, isFalse);
      expect(bindings.refusals, isEmpty);
      final binding = bindings.byEventIdentity.values.single;
      expect(
          binding.isBoundToEvent(
              source: source,
              analysis: analysis,
              event: analysis.events.single),
          isTrue);
      expect(binding.nativeTrainer.team.single.speciesId, 'rattata');
      expect(binding.nativeTrainer.team.single.level, 16);
      expect(
          binding.nativeTrainer.team.single.moves,
          nativeTrainerDefaultMoveIds(
              NativePsdkTrainerBundle.builtin()
                  .learnsetsBySpeciesId['rattata']!,
              16));
      expect(binding.nativeVictorySpeech, 'Good game!');
      final row = (projection.semanticEvidence['events'] as List).single as Map;
      expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
      expect(row['gaps'], isEmpty);
      final map = projection.nativeMaps[239]!;
      final entity = map.entities.single;
      final movement = entity.npc!.movement;
      expect(movement.mode, MapEntityNpcMovementMode.fixedRoute);
      expect(movement.routeSteps, hasLength(rotations.length - 1));
      expect(movement.routeSteps.whereType<MapEntityNpcMoveStep>(), isEmpty);
      expect(movement.suspendWhenInstanceBoolean?.key,
          'npc.autonomousRouteStopped');
      expect(entity.npc!.lineOfSightRange, 3);
      expect(entity.npc!.trainerId, binding.nativeTrainer.id);
      bool sees(MapData current, GridPos player) => checkLineOfSight(
          npcPos: entity.pos,
          npcFacing: entity.npc!.facing,
          lineOfSightRange: entity.npc!.lineOfSightRange,
          playerPos: player,
          world: GameplayWorldState.initial(map: current, playerPos: player));
      expect(sees(map, const GridPos(x: 2, y: 4)), isTrue);
      expect(sees(map, const GridPos(x: 2, y: 0)), isFalse);
      expect(
          sees(
              map.copyWith(layers: [
                MapLayer.collision(
                    id: 'wall',
                    name: 'Wall',
                    collisions: List.generate(25, (index) => index == 17))
              ]),
              const GridPos(x: 2, y: 4)),
          isFalse);
      final routeProof = row['nativeFixedRoute'] as Map;
      expect((routeProof['pages'] as List), hasLength(2));
      expect(
          (routeProof['pages'] as List)
              .every((dynamic page) => page['sourceParity'] == false),
          isTrue);
      SceneAsset scene(int page) => projection.scenes
          .singleWhere((scene) => scene.metadata['sourcePageIndex'] == '$page');
      final before = scene(0);
      final battle = before.graph.nodes
          .singleWhere((node) => node.payload is SceneBattlePayload);
      final winner = _consequences(_reachable(before, battle.id, 'victory'));
      final loser = _consequences(_reachable(before, battle.id, 'defeat'));
      final stop =
          winner.whereType<SceneSetMapEventInstanceBooleanConsequence>().single;
      expect(stop.key, 'npc.autonomousRouteStopped');
      expect(stop.mapId, map.id);
      expect(stop.eventId, entity.id);
      expect(stop.value, isTrue);
      expect(winner.whereType<SceneSetFactConsequence>(), hasLength(1));
      expect(loser.whereType<SceneSetMapEventInstanceBooleanConsequence>(),
          isEmpty);
      expect(loser.whereType<SceneSetFactConsequence>(), isEmpty);
      expect(
          scene(1)
              .graph
              .nodes
              .where((node) => node.payload is SceneBattlePayload),
          isEmpty);
      expect(
          _consequences(scene(1).graph.nodes)
              .whereType<SceneSetMapEventInstanceBooleanConsequence>(),
          isEmpty);
      final project = ProjectManifest(
          name: 'Rotating trainer',
          tilesets: const [],
          maps: [
            ProjectMapEntry(
                id: map.id,
                name: map.name,
                relativePath: 'maps/native_239.json')
          ],
          eventRegistry: projection.registry,
          facts: projection.facts,
          scenes: projection.scenes,
          dialogues: projection.dialogues,
          trainers: [binding.nativeTrainer]);
      final authority = NarrativeEventDispatchAuthority.prepare(
          registryResult:
              EventRegistryDecodeResult.decoded(projection.registry),
          occurrence: NarrativeEventOccurrence(
              source:
                  NarrativeEventSourceRef.entityInteract(map.id, entity.id)),
          factResolver:
              NarrativeFactRuntimeResolver.fromFacts(projection.facts),
          projectCatalog:
              buildNarrativeEventProjectCatalog(project: project, maps: [map]),
          project: project,
          maps: [map]);
      expect(authority, isA<NarrativeEventDispatchAuthorityReady>());
      final sourceAnalyzer =
          SourceEventAnalyzer.forProject(source, profile: analysis.profile);
      for (final won in [false, true]) {
        final state = GameState.fromJson(GameState(
            saveId: 'route',
            narrativeFactRuntimeState:
                NarrativeFactRuntimeState(overridesByFactId: {
              sourceEventFactBindingId(sourceAnalyzer.selfFactId(239, 5, 'A')):
                  won,
            })).toJson());
        final selected = (authority as NarrativeEventDispatchAuthorityReady)
            .plan(gameState: state);
        expect(selected, isA<NarrativeEventDispatchHandled>());
        expect((selected as NarrativeEventDispatchHandled).sceneId,
            scene(won ? 1 : 0).id);
      }
    });
  }

  test('no-comment rotating trainer retains blocked-water anchor refusal',
      () async {
    final fixture = await _fixture([24, 0], blocked: true);
    expect(fixture.analysis.events.single.isQuarantined, isFalse);
    expect(fixture.bindings.byEventIdentity, hasLength(1));
    final row =
        (fixture.projection.semanticEvidence['events'] as List).single as Map;
    expect(row['status'], 'quarantinedWholeEvent');
    expect(row['gaps'], contains('sourceTrainerAnchorPassageUnqualified'));
    expect(fixture.projection.nativeMaps[239]!.entities, isEmpty);
  });
}
