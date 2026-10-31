import 'package:archive/archive.dart';
import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';
import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  for (final dimension in [ProjectDimension.twoD, ProjectDimension.threeD]) {
    for (final scenario in [
      'unused',
      'known',
      if (dimension == ProjectDimension.threeD) 'known-enabled',
      'unknown',
      'absent',
      'condition-scene',
      'condition-world',
      'condition-event',
      'condition-presentation',
    ]) {
      final periodic = scenario != 'unused';
      test(
          'periodic export validates item before dimension branch dimension=${dimension.name} scenario=$scenario',
          () async {
        final qa = Directory(Platform.environment['AVELUNE_QA_ROOT'] ??
            '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/periodic-availability-runtime');
        await qa.create(recursive: true);
        final root = await qa.createTemp('export-');
        addTearDown(() => root.delete(recursive: true));
        final files = spatialPayload();
        var original = ProjectManifest.fromJson(
            jsonDecode(utf8.decode(files['project/project.json']!))
                as Map<String, dynamic>);
        if (dimension == ProjectDimension.twoD) {
          original = original.copyWith(
              version: ProjectVersion.v8,
              settings: original.settings
                  .copyWith(dimension: dimension, spatialCamera: null),
              models3d: [],
              newGame: const ProjectNewGameConfig(
                  enabled: true,
                  startMapId: 'map',
                  startSpawnId: 'spawn.player'));
          files['project/maps/map.json'] = utf8.encode(jsonEncode(const MapData(
              id: 'map',
              name: 'Map',
              version: ProjectVersion.v8,
              size: GridSize(width: 8, height: 8),
              layers: [MapLayer.object(id: 'events', name: 'Events')],
              mapMetadata: MapMetadata(defaultSpawnId: 'spawn.player'),
              entities: [
                MapEntity(
                    id: 'spawn.player',
                    name: 'Player start',
                    kind: MapEntityKind.spawn,
                    pos: GridPos(x: 1, y: 1),
                    spawn:
                        MapEntitySpawnData(role: EntitySpawnRole.playerStart))
              ]).toJson()));
        }
        final command = SceneInteractiveCommand.claimPeriodicReward(
            definition: PeriodicItemRewardDefinition(
                rewardId: 'tree-fruit',
                label: 'Fruit',
                itemId: scenario == 'unknown' ? 'missing' : 'fruit',
                quantity: 2));
        final scene = SceneAsset(
            id: 'reward',
            name: 'Reward',
            graph: SceneGraph(startNodeId: 'start', nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                  id: 'reward',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.interactive(command)),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ], edges: [
              SceneEdge(
                  id: 'enter',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'reward',
                  kind: SceneEdgeKind.defaultFlow),
              for (final port in command.outputPortIds)
                SceneEdge(
                    id: port,
                    fromNodeId: 'reward',
                    fromPortId: port,
                    toNodeId: 'end',
                    kind: SceneEdgeKind.actionCompleted),
            ]));
        var project = original.copyWith(
            scenes: periodic ? [scene] : [],
            eventRegistry: periodic
                ? NarrativeEventRegistry(
                    schemaVersion: 1,
                    mode: EventSystemMode.v2Only,
                    legacyClaims: const [],
                    records: [
                        NarrativeEventRecord.configuredStructurallyUnchecked(
                            NarrativeEventDefinition(
                                id: 'evt_018f0f8c-7b8a-7def-8000-000000000001',
                                name: 'Récompense quotidienne',
                                source: NarrativeEventSourceRef.mapEnter('map'),
                                conditions: const [],
                                sceneId: 'reward',
                                reusePolicy: NarrativeEventReusePolicy.reusable,
                                priority: 0,
                                order: 0),
                            enabled: true)
                      ])
                : null,
            pokemon: original.pokemon.copyWith(
                enabled: scenario == 'known-enabled',
                catalogFiles:
                    scenario == 'absent' ? const {} : {'items': 'items.json'}));
        if (scenario.startsWith('condition-')) {
          final reference = PeriodicRewardReference(
              sceneId: 'reward', nodeId: 'reward', rewardId: 'tree-fruit');
          final leaf = NarrativeEventCondition.periodicRewardAvailable(
              reference: reference, expectedValue: true);
          if (scenario == 'condition-scene') {
            project = project.copyWith(scenes: [
              SceneAsset(
                  id: scene.id,
                  name: scene.name,
                  graph: SceneGraph(
                      startNodeId: scene.graph.startNodeId,
                      nodes: [
                        ...scene.graph.nodes,
                        SceneNode(
                            id: 'availability',
                            kind: SceneNodeKind.condition,
                            payload: SceneConditionPayload(
                                conditionSource: SceneConditionSource
                                    .periodicRewardAvailable(
                                        reference: reference,
                                        expectedValue: true)))
                      ],
                      edges: [
                        for (final edge in scene.graph.edges)
                          if (edge.fromNodeId != 'start') edge,
                        SceneEdge(id: 'start-availability', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'availability', kind: SceneEdgeKind.defaultFlow),
                        for (final expected in [true, false]) SceneEdge(id: 'availability-$expected', fromNodeId: 'availability', fromPortId: '$expected', toNodeId: 'reward', kind: expected ? SceneEdgeKind.conditionTrue : SceneEdgeKind.conditionFalse),
                      ]))
            ]);
          } else if (scenario == 'condition-world') {
            project = project.copyWith(worldRules: [
              WorldRuleDefinition(
                  id: 'daily',
                  label: 'Daily',
                  source: WorldRuleSource.periodicRewardAvailable(
                      reference: reference, expectedValue: true),
                  target: const WorldRuleTarget(
                      kind: WorldRuleTargetKind.mapEntity,
                      mapId: 'map',
                      entityId: 'spawn.player'),
                  effect: const WorldRuleEffect(
                      kind: WorldRuleEffectKind.entityVisible))
            ]);
          } else if (scenario == 'condition-event') {
            project = project.copyWith(
                eventRegistry: NarrativeEventRegistry(
                    schemaVersion: 1,
                    mode: EventSystemMode.v2Only,
                    legacyClaims: const [],
                    records: [
                  NarrativeEventRecord.configuredStructurallyUnchecked(
                      NarrativeEventDefinition(
                          id: 'evt_018f0f8c-7b8a-7def-8000-000000000001',
                          name: 'Daily',
                          source: NarrativeEventSourceRef.mapEnter('map'),
                          conditions: [leaf],
                          sceneId: 'reward',
                          reusePolicy: NarrativeEventReusePolicy.reusable,
                          priority: 0,
                          order: 0),
                      enabled: true)
                ]));
          } else {
            final map = MapData.fromJson(Map<String, dynamic>.from(
                jsonDecode(utf8.decode(files['project/maps/map.json']!))
                    as Map));
            files['project/maps/map.json'] =
                utf8.encode(jsonEncode(map.copyWith(entities: [
              ...map.entities,
              MapEntity(
                  id: 'daily-visual',
                  kind: MapEntityKind.custom,
                  pos: const GridPos(x: 2, y: 2),
                  presentation: MapEntityPresentation(variants: [
                    MapEntityPresentationVariant(
                        id: 'daily',
                        condition: NarrativeEventConditionExpression.leaf(leaf),
                        blocksMovement: false)
                  ]))
            ]).toJson()));
          }
        }
        files['project/project.json'] =
            utf8.encode(jsonEncode(project.toJson()));
        files['project/items.json'] = utf8.encode(jsonEncode(
            encodeProjectItemCatalog(const ProjectItemCatalog(
                schemaVersion: 1,
                entries: [
              ProjectItemDefinition(
                  id: 'fruit', displayName: 'Fruit', pocketId: 'materials')
            ]))));
        for (final entry in files.entries) {
          final file =
              File('${root.path}/${entry.key.substring('project/'.length)}');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(entry.value);
        }
        final before = await File('${root.path}/project.json').readAsBytes();
        final itemBytes = await File('${root.path}/items.json').readAsBytes();
        final profile = GamePackageExportProfile(
            gameId: 'games.test.periodic',
            gameVersion: '0.1.0',
            title: 'Periodic',
            authorName: 'Fixture',
            defaultLocale: 'fr',
            supportedLocales: ['fr']);
        if (scenario == 'unknown' || scenario == 'absent') {
          await expectLater(
              const CanonicalGamePackageExportService().build(
                  projectRoot: root,
                  profile: profile,
                  mode: GamePackageExportMode.localTest),
              throwsA(isA<GamePackageExportException>()
                  .having(
                      (error) => error.code, 'code', 'gameplayReadinessFailed')
                  .having(
                      (error) => error.message,
                      'message',
                      contains(scenario == 'absent'
                          ? 'periodicRewardItemCatalogUnavailable'
                          : 'periodicRewardUnknownItem'))));
          expect(await File('${root.path}/project.json').readAsBytes(), before);
          expect(
              await File('${root.path}/items.json').readAsBytes(), itemBytes);
          return;
        }
        final service = scenario == 'known-enabled'
            ? CanonicalGamePackageExportService(
                pokemonValidator: (
                        {required reader,
                        required projectRoot,
                        required manifest}) async =>
                    PokemonCatalogCoherenceReport(
                        const <PokemonCatalogDiagnostic>[]))
            : const CanonicalGamePackageExportService();
        final result = await service.build(
            projectRoot: root,
            profile: profile,
            mode: GamePackageExportMode.localTest);
        expect(
            result.manifest.compatibility.requiredCapabilities.contains(
                SpatialGameplayCapabilities.periodicRewardCapabilityId),
            periodic);
        expect(result.manifest.compatibility.requiredCapabilities.contains(SpatialGameplayCapabilities.periodicRewardConditionCapabilityId), scenario.startsWith('condition-'));
        final unpacked = const GamePackageInspector().inspect(result.packageBytes);
        expect(unpacked.manifest.compatibility.requiredCapabilities, result.manifest.compatibility.requiredCapabilities);
        if (scenario.startsWith('condition-')) {
          final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
          final descriptor = Map<String, dynamic>.from(jsonDecode(utf8.decode(archive.findFile('project/project.json')!.content)) as Map);
          final exported = PortableCatalogPublication.decodeProjectSync(descriptor, readObject: (ref) => archive.findFile('project/${PortableCatalogPublication.objectPath(ref)}')!.content);
          final exportedMap = MapData.fromJson(Map<String, dynamic>.from(jsonDecode(utf8.decode(archive.findFile('project/maps/map.json')!.content)) as Map));
          final locator = PeriodicRewardReference(sceneId: 'reward', nodeId: 'reward', rewardId: 'tree-fruit');
          expect(resolvePeriodicRewardReference(reference: locator, lookupScenes: (id) => exported.scenes.where((scene) => scene.id == id)).isResolved, isTrue);
          if (scenario == 'condition-scene') expect((exported.scenes.single.graph.nodes.singleWhere((node) => node.id == 'availability').payload as SceneConditionPayload).conditionSource!.rewardReference, locator);
          if (scenario == 'condition-world') expect(exported.worldRules.single.source.rewardReference, locator);
          if (scenario == 'condition-event') expect(exported.eventRegistry!.records.single.definitionOrNull!.conditions.single.rewardReference, locator);
          if (scenario == 'condition-presentation') expect(exportedMap.entities.singleWhere((entity) => entity.id == 'daily-visual').presentation!.variants.single.condition.leaves.single.rewardReference, locator);
          final bytes = List<int>.of(result.packageBytes);
          final host = AveluneRuntimeCompatibility.host();
          final oldHost = GamePackageHostCompatibility(hubVersion: host.hubVersion, runtimeApiVersion: host.runtimeApiVersion, capabilities: {...host.capabilities}..remove(SpatialGameplayCapabilities.periodicRewardConditionCapabilityId), supportedProjectFormats: host.supportedProjectFormats, currentProjectFormat: host.currentProjectFormat, currentProjectFormats: host.currentProjectFormats, supportedSaveFormats: host.supportedSaveFormats);
          expect(() => GamePackageInspector(hostCompatibility: oldHost).inspect(result.packageBytes), throwsA(isA<GamePackageFormatException>()));
          expect(result.packageBytes, bytes);
        }
        final current = AveluneRuntimeCompatibility.host();
        final old = GamePackageHostCompatibility(
            hubVersion: current.hubVersion,
            runtimeApiVersion: current.runtimeApiVersion,
            capabilities: {...current.capabilities}
              ..remove(scenario.startsWith('condition-') ? SpatialGameplayCapabilities.periodicRewardConditionCapabilityId : SpatialGameplayCapabilities.periodicRewardCapabilityId),
            supportedProjectFormats: current.supportedProjectFormats,
            currentProjectFormat: current.currentProjectFormat,
            currentProjectFormats: current.currentProjectFormats,
            supportedSaveFormats: current.supportedSaveFormats);
        final compatibility = const GamePackageCompatibilityEvaluator()
            .evaluate(result.manifest, old);
        expect(
            compatibility.decision,
            periodic
                ? GamePackageCompatibilityDecision.reject
                : GamePackageCompatibilityDecision.accept);
        expect(
            const GamePackageInspector()
                .inspect(result.packageBytes)
                .manifest
                .gameId,
            'games.test.periodic');
        expect(await File('${root.path}/project.json').readAsBytes(), before);
      });
    }
  }
  test(
      'package conditions cannot omit capability and old host refuses declared capability',
      () {
    final files = spatialPayload();
    final original = ProjectManifest.fromJson(Map<String, dynamic>.from(
        jsonDecode(utf8.decode(files['project/project.json']!)) as Map));
    final source = SceneConditionSource.periodicRewardAvailable(
        reference: PeriodicRewardReference(
            sceneId: 'source', nodeId: 'claim', rewardId: 'daily'),
        expectedValue: true);
    final project = original.copyWith(scenes: [
      SceneAsset(
          id: 'availability',
          name: 'Availability',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'condition',
                kind: SceneNodeKind.condition,
                payload: SceneConditionPayload(conditionSource: source)),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ], edges: const []))
    ]);
    files['project/project.json'] = utf8.encode(jsonEncode(project.toJson()));
    final manifest = spatialManifest();
    expect(
        () => const GamePackageBuilder()
            .build(manifest: manifest, payloadFiles: files),
        throwsA(isA<GamePackageFormatException>().having(
            (error) => error.message,
            'message',
            contains('gameplay.periodic-reward-condition@1'))));
    final declared = const GamePackageManifestCodec().decodeJson({
      ...manifest.toJson(),
      'compatibility': {
        ...manifest.toJson()['compatibility'] as Map<String, dynamic>,
        'requiredCapabilities': [
          'map3d@1',
          SpatialGameplayCapabilities.periodicRewardConditionCapabilityId
        ],
      }
    });
    final current = AveluneRuntimeCompatibility.host();
    final old = GamePackageHostCompatibility(hubVersion: current.hubVersion, runtimeApiVersion: current.runtimeApiVersion, capabilities: {...current.capabilities}..remove(SpatialGameplayCapabilities.periodicRewardConditionCapabilityId), supportedProjectFormats: current.supportedProjectFormats, currentProjectFormat: current.currentProjectFormat, currentProjectFormats: current.currentProjectFormats, supportedSaveFormats: current.supportedSaveFormats);
    final result = const GamePackageCompatibilityEvaluator().evaluate(declared, old);
    expect(result.decision, GamePackageCompatibilityDecision.reject);
    expect(
        result.missingCapabilities,
        contains(
            SpatialGameplayCapabilities.periodicRewardConditionCapabilityId));
  });
}
