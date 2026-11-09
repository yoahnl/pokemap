import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
    test(
        'periodic encounter capability and locator survive canonical export ${dimension.name}',
        () async {
      final root =
          await Directory.systemTemp.createTemp('periodic-encounter-export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialPayload();
      var project = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(files['project/project.json']!))
              as Map<String, dynamic>);
      if (dimension == ProjectDimension.twoD) {
        project = project.copyWith(
            version: ProjectVersion.v8,
            settings: project.settings
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
                  name: 'Start',
                  kind: MapEntityKind.spawn,
                  pos: GridPos(x: 1, y: 1),
                  spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart))
            ]).toJson()));
      }
      final policy = PeriodicEncounterDefinition(
          rewardId: 'daily-encounter',
          label: 'Visiteur',
          consumeOnOutcomes: {
            PeriodicEncounterOutcome.captured,
            PeriodicEncounterOutcome.fled
          });
      final reference = PeriodicRewardReference(
          sceneId: 'encounter', nodeId: 'battle', rewardId: policy.rewardId);
      final scene = SceneAsset(
          id: 'encounter',
          name: 'Encounter',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'available',
                kind: SceneNodeKind.condition,
                payload: SceneConditionPayload(
                    conditionSource:
                        SceneConditionSource.periodicRewardAvailable(
                            reference: reference, expectedValue: true))),
            SceneNode(
                id: 'battle',
                kind: SceneNodeKind.battle,
                payload: SceneBattlePayload(
                    battleKind: 'wild',
                    battleTemplateId: 'fixed',
                    periodicEncounter: policy)),
            SceneNode(id: 'end', kind: SceneNodeKind.end)
          ], edges: [
            _edge('enter', 'start', 'available'),
            _edge('yes', 'available', 'battle', 'true',
                SceneEdgeKind.conditionTrue),
            _edge('no', 'available', 'end', 'false',
                SceneEdgeKind.conditionFalse),
            _edge(
                'win', 'battle', 'end', 'victory', SceneEdgeKind.battleVictory),
            _edge('lose', 'battle', 'end', 'defeat', SceneEdgeKind.battleDefeat)
          ]));
      project = project.copyWith(
          scenes: [
            scene
          ],
          encounterTables: const [
            ProjectEncounterTable(
                id: 'fixed',
                name: 'Fixed',
                encounterKind: EncounterKind.walk,
                entries: [
                  ProjectEncounterEntry(
                      speciesId: 'target', minLevel: 2, maxLevel: 2)
                ])
          ],
          eventRegistry: NarrativeEventRegistry(
              schemaVersion: 1,
              mode: EventSystemMode.v2Only,
              legacyClaims: [],
              records: [
                NarrativeEventRecord.configuredStructurallyUnchecked(
                    NarrativeEventDefinition(
                        id: 'evt_018f0f8c-7b8a-7def-8000-000000000001',
                        name: 'Encounter',
                        source: NarrativeEventSourceRef.mapEnter('map'),
                        conditions: [],
                        sceneId: scene.id,
                        reusePolicy: NarrativeEventReusePolicy.reusable,
                        priority: 0,
                        order: 0),
                    enabled: true)
              ]));
      files['project/project.json'] = utf8.encode(jsonEncode(project.toJson()));
      for (final entry in files.entries) {
        final file =
            File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final before = await File('${root.path}/project.json').readAsBytes();
      final result = await const CanonicalGamePackageExportService().build(
          projectRoot: root,
          mode: GamePackageExportMode.localTest,
          profile: GamePackageExportProfile(
              gameId: 'games.test.periodic-encounter',
              gameVersion: '0.1.0',
              title: 'Encounter',
              authorName: 'Fixture',
              defaultLocale: 'fr',
              supportedLocales: ['fr']));
      expect(
          result.manifest.compatibility.requiredCapabilities,
          containsAll([
            SpatialGameplayCapabilities.periodicEncounterCapabilityId,
            SpatialGameplayCapabilities.periodicRewardConditionCapabilityId
          ]));
      expect(
          result.manifest.compatibility.requiredCapabilities,
          isNot(contains(
              SpatialGameplayCapabilities.periodicRewardCapabilityId)));
      final archive =
          ZipDecoder().decodeBytes(result.packageBytes, verify: true);
      final exported = PortableCatalogPublication.decodeProjectSync(
          jsonDecode(utf8
                  .decode(archive.findFile('project/project.json')!.content))
              as Map<String, dynamic>,
          readObject: (reference) => archive
              .findFile(
                  'project/${PortableCatalogPublication.objectPath(reference)}')!
              .content);
      final battle = exported.scenes.single.graph.nodes
          .singleWhere((node) => node.id == 'battle')
          .payload as SceneBattlePayload;
      expect(battle.periodicEncounter, policy);
      expect(
          resolvePeriodicRewardReference(
                  reference: reference,
                  lookupScenes: (id) =>
                      exported.scenes.where((scene) => scene.id == id))
              .periodicEncounter,
          policy);
      expect(await File('${root.path}/project.json').readAsBytes(), before);
      final profile = File('${root.path}/.pokemap/export-profile-v1.json');
      await profile.parent.create(recursive: true);
      await profile.writeAsString(jsonEncode(GamePackageExportProfile(
          gameId: 'games.test.periodic-encounter',
          gameVersion: '0.1.0',
          title: 'Encounter',
          authorName: 'Fixture',
          defaultLocale: 'fr',
          supportedLocales: ['fr']).toJson()));
      final output = File('${root.path}/exports/encounter.avelunegame');
      await output.parent.create();
      final worker = await Process.start(Platform.resolvedExecutable, [
        'run',
        'bin/pokemap_authoring.dart',
        '--root',
        root.path,
        '--export-root',
        output.parent.path
      ]);
      addTearDown(() async {
        if (await worker.exitCode
                .timeout(const Duration(seconds: 2), onTimeout: () => -1) ==
            -1) {
          worker.kill();
        }
      });
      final errors = worker.stderr.transform(utf8.decoder).join();
      final response = worker.stdout.transform(utf8.decoder).join();
      worker.stdin.writeln(jsonEncode({
        'id': 'export-encounter',
        'command': 'game_export',
        'args': {
          'projectRoot': root.path,
          'outputPath': output.path,
          'mode': 'localTest'
        }
      }));
      await worker.stdin.close();
      expect(await worker.exitCode.timeout(const Duration(seconds: 90)), 0,
          reason: await errors);
      final envelope =
          jsonDecode((await response).trim()) as Map<String, dynamic>;
      expect(envelope['status'], 'success', reason: jsonEncode(envelope));
      final cliArchive =
          ZipDecoder().decodeBytes(await output.readAsBytes(), verify: true);
      final cliProject = PortableCatalogPublication.decodeProjectSync(
          jsonDecode(utf8
                  .decode(cliArchive.findFile('project/project.json')!.content))
              as Map<String, dynamic>,
          readObject: (reference) => cliArchive
              .findFile(
                  'project/${PortableCatalogPublication.objectPath(reference)}')!
              .content);
      expect(
          (cliProject.scenes.single.graph.nodes
                  .singleWhere((node) => node.id == 'battle')
                  .payload as SceneBattlePayload)
              .periodicEncounter,
          policy);
      expect(
          GamePackageInspector(
                  hostCompatibility: AveluneRuntimeCompatibility.host())
              .inspect(result.packageBytes)
              .compatibility
              ?.decision,
          GamePackageCompatibilityDecision.accept);
      final current = AveluneRuntimeCompatibility.host();
      final old = GamePackageHostCompatibility(
          hubVersion: current.hubVersion,
          runtimeApiVersion: current.runtimeApiVersion,
          capabilities: {...current.capabilities}
            ..remove(SpatialGameplayCapabilities.periodicEncounterCapabilityId),
          supportedProjectFormats: current.supportedProjectFormats,
          currentProjectFormat: current.currentProjectFormat,
          currentProjectFormats: current.currentProjectFormats,
          supportedSaveFormats: current.supportedSaveFormats);
      expect(
          () => GamePackageInspector(hostCompatibility: old)
              .inspect(result.packageBytes),
          throwsA(isA<GamePackageFormatException>()));
    });
  }
}

SceneEdge _edge(String id, String from, String to,
        [String port = 'completed',
        SceneEdgeKind kind = SceneEdgeKind.defaultFlow]) =>
    SceneEdge(
        id: id, fromNodeId: from, fromPortId: port, toNodeId: to, kind: kind);
