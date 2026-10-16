import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../map_authoring/test/domains/maps/map_catalog_fixture.dart';
import '../tool/ac14_catalog_reference_fixture.dart';
import 'support/source_catalog_preservation.dart';

void main() {
  test(
      'canonical trainer declaration accepts native moves before Pokemon documents and enables its NPC',
      () {
    const trainer = ProjectTrainerEntry(
        id: 'source-pbs-91c8b6c3da55831f2c60dcc3',
        name: 'Brent',
        trainerClass: 'FRLG_BUGCATCHER',
        team: [
          ProjectTrainerPokemonEntry(
              speciesId: 'beedrill',
              level: 19,
              abilityId: 'swarm',
              moves: ['fury_attack', 'twineedle', 'rage', 'pursuit']),
          ProjectTrainerPokemonEntry(
              speciesId: 'beedrill',
              level: 19,
              abilityId: 'swarm',
              moves: ['fury_attack', 'twineedle', 'rage', 'pursuit']),
        ]);
    final map = catalogMap('route');
    final initial = catalogSnapshot([map]).manifest.copyWith(
        pokemon: const ProjectPokemonConfig(
            enabled: true, ruleset: PokemonRulesetProfile.pokeMapBetaV1));
    final entity = _entity(trainer.id);
    expect(
        () => _entityDraft(initial, map, entity),
        throwsA(isA<MapAuthoringException>().having((error) => error.code,
            'code', 'map.semantic_projected_state_invalid')));
    final declaration = const CampaignContentActions().build(catalogContext(
        _snapshot(initial, map),
        'campaign.trainer.upsert',
        {'value': trainer.toJson()}));
    final declared = ProjectManifest.fromJson(jsonDecode(
            utf8.decode(declaration.changeSet.changes.single.afterBytes!))
        as Map<String, dynamic>);
    expect(declared.trainers.single, trainer);
    expect(declared.pokemon.enabled, isTrue);
    expect(_entityDraft(declared, map, entity).changeSet.changes, hasLength(1));
    final scene = _scene(trainer.id);
    expect(
        () => const SceneActions().upsert(initial, maps: [map], scene: scene),
        throwsA(isA<NarrativeAuthoringException>()));
    expect(
        const SceneActions()
            .upsert(declared, maps: [map], scene: scene)
            .scenes
            .single,
        scene);
  });

  final scripts = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  group('catalog and event dependency merge', () {
    late Directory temporary;
    late Ac14CatalogReferenceComposition original;
    late NativeProjectDraft base;
    late NativeProjectDraft unchanged;
    setUpAll(() async {
      temporary = await Directory.systemTemp.createTemp('catalog-event-order-');
      original = await composeAc14CatalogReferenceFixture(
          sourceScriptsPath: scripts!,
          outputParentPath: temporary.path,
          includeBrokenReferences: false);
      final evidence =
          Map<String, Object?>.from(original.draft.compositionEvidence);
      final ids =
          ((evidence.remove('sourceCatalogs') as Map)['operationIds'] as List)
              .cast<String>()
              .toSet();
      const config =
          ProjectPokemonConfig(ruleset: PokemonRulesetProfile.pokeMapBetaV1);
      base = _copyBase(original.draft, evidence: evidence, mutations: [
        ...original.draft.mutations
            .where((mutation) => !ids.contains(mutation.operationId.value)),
        _mutation('pokemon.configuration.set_enabled', 'initial-enabled',
            {'enabled': true}),
        _mutation('pokemon.catalog.write', 'initial-items', {
          'relativePath': config.catalogFiles['items']!,
          'document': encodeProjectItemCatalog(
              const ProjectItemCatalog(schemaVersion: 1, entries: [])),
        }),
      ]);
      final control = await const SourceCatalogStudyComposer().compose(
          source: original.sourceFixture.source,
          base: base,
          files: original.sourceFixture.files,
          limits: ac14CatalogReferenceLimits);
      unchanged = control!.draft;
    });
    tearDownAll(() async {
      await temporary.delete(recursive: true);
    });

    for (final sceneFirst in [false, true]) {
      test(
          'refuses a source-only trainer ${sceneFirst ? 'Scene battle' : 'NPC'} consumer',
          () async {
        final trainer =
            preservedCatalogTrainers(original.catalogs.projection).single;
        final mapId = base.mapIds[98]!;
        final entity = _mutation('entity.upsert', 'consumer-npc',
            {'mapId': mapId, 'entity': _entity(trainer.id).toJson()});
        final scene = _mutation('scene.upsert', 'consumer-scene',
            {'scene': _scene(trainer.id).toJson()});
        final consumers = sceneFirst ? [scene, entity] : [entity, scene];
        final preceding =
            _copyBase(base, mutations: [...base.mutations, ...consumers]);
        await expectLater(
            const SourceCatalogStudyComposer().compose(
                source: original.sourceFixture.source,
                base: preceding,
                files: original.sourceFixture.files,
                limits: ac14CatalogReferenceLimits),
            throwsA(isA<NativeWriteException>().having((error) => error.code,
                'code', 'catalogs.trainer.unqualified')));
      });
    }

    test(
        'unconsumed trainer and every other catalog mutation retain the prior order',
        () async {
      final composed = await const SourceCatalogStudyComposer().compose(
          source: original.sourceFixture.source,
          base: base,
          files: original.sourceFixture.files,
          limits: ac14CatalogReferenceLimits);
      expect(composed!.draft.mutations.map((mutation) => mutation.toJson(0)),
          unchanged.mutations.map((mutation) => mutation.toJson(0)));
    });
  }, skip: scripts == null ? 'AVELUNE_AC13_SOURCE_SCRIPTS is required' : false);
}

MapEntity _entity(String trainerId) => MapEntity(
    id: 'trainer-npc',
    kind: MapEntityKind.npc,
    pos: const GridPos(x: 1, y: 1),
    npc: MapEntityNpcData(displayName: 'Trainer', trainerId: trainerId));

AuthoringMutationDraft _entityDraft(
        ProjectManifest project, MapData map, MapEntity entity) =>
    const EntityActions().build(catalogContext(_snapshot(project, map),
        'entity.upsert', {'mapId': map.id, 'entity': entity.toJson()}));

ProjectSnapshot _snapshot(ProjectManifest project, MapData map) {
  final source = catalogSnapshot([map], project: project);
  return ProjectSnapshot(
      projectHandle: source.projectHandle,
      revision: source.revision,
      manifest: project,
      maps: [map],
      resourceFingerprints: source.resourceFingerprints,
      resourceBytes: {
        'project': source.resourceBytes('project'),
        'map:${map.id}': source.resourceBytes('map:${map.id}')
      },
      itemCatalog: const ProjectItemCatalog(schemaVersion: 1, entries: []));
}

SceneAsset _scene(String trainerId) => SceneAsset(
    id: 'trainer-battle',
    name: 'Trainer battle',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
              battleKind: 'trainer',
              trainerId: trainerId,
              declaredOutcomes: const ['victory', 'defeat'])),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(
          id: 'enter',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow),
      SceneEdge(
          id: 'won',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'end',
          kind: SceneEdgeKind.battleVictory),
      SceneEdge(
          id: 'lost',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'end',
          kind: SceneEdgeKind.battleDefeat),
    ]));

NativeMutation _mutation(
        String action, String id, Map<String, Object?> parameters) =>
    NativeMutation(
        operationId: ConverterId(id),
        actionId: action,
        sourceEntityIds: [ConverterId('source-consumer')],
        targetEntityIds: [ConverterId(id)],
        parameters: parameters);

NativeProjectDraft _copyBase(NativeProjectDraft base,
        {Map<String, Object?>? evidence,
        required List<NativeMutation> mutations}) =>
    NativeProjectDraft(
        source: base.source,
        projectName: base.projectName,
        parentPath: base.parentPath,
        folderName: base.folderName,
        sourceRootPath: base.sourceRootPath,
        mapIds: base.mapIds,
        artifacts: base.artifacts,
        sourceArtifacts: base.sourceArtifacts,
        mutations: mutations,
        compositionEvidence: evidence ?? base.compositionEvidence,
        defaultMapWidth: base.defaultMapWidth,
        defaultMapHeight: base.defaultMapHeight,
        limits: ac14CatalogReferenceLimits);
