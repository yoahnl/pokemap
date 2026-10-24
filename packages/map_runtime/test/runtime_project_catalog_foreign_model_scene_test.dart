import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/map_activation.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_runtime_host_callbacks.dart';
import 'package:map_runtime/src/spatial/spatial_gameplay_events.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';

void main() {
  for (final partitioned in [false, true]) {
    test(
      'global scene validates a foreign map model without loading its GLB partitioned=$partitioned',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'foreign-scene-model-',
        );
        addTearDown(() => root.delete(recursive: true));
        final bounds = Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 1, z: 1),
        );
        final maps = {
          for (final id in ['chamber', 'outside'])
            id: MapData(
              id: id,
              name: id,
              version: ProjectVersion.v9,
              size: const GridSize(width: 8, height: 8),
              spatialScene: MapSpatialScene(
                width: 8,
                depth: 8,
                instances: [
                  SpatialModelInstance(
                    id: 'door',
                    modelId: '$id-model',
                    position: Model3dVector3(x: 1, y: 0, z: 1),
                  ),
                ],
              ),
            ),
        };
        final project = ProjectManifest(
          name: 'Foreign scene model',
          version: ProjectVersion.v9,
          settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile(
              projection: SpatialCameraProjection.orthographic,
              orthographicHeight: 13.5,
            ),
          ),
          maps: [
            for (final id in maps.keys)
              ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
          ],
          tilesets: [],
          models3d: [
            for (final id in ['chamber-model', 'outside-model', 'unused-model'])
              ProjectModel3dEntry(
                id: id,
                name: id,
                sourceAssetId: 'source-$id',
                relativePath: 'assets/models3d/$id.glb',
                inspection: Model3dInspection(
                  bounds: bounds,
                  meshCount: 1,
                  triangleCount: 1,
                  animations: [
                    Model3dAnimation(
                      index: 0,
                      name: 'open',
                      durationSeconds: 1,
                    ),
                  ],
                ),
              ),
          ],
          scenes: [
            SceneAsset(
              id: 'open-foreign-door',
              name: 'Open door',
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: [
                  SceneNode(id: 'start', kind: SceneNodeKind.start),
                  SceneNode(
                    id: 'open',
                    kind: SceneNodeKind.action,
                    payload: SceneActionPayload.interactive(
                      SceneInteractiveCommand.playModelAnimation(
                        mapId: 'outside',
                        instanceId: 'door',
                        animationIndex: 0,
                      ),
                    ),
                  ),
                  SceneNode(id: 'end', kind: SceneNodeKind.end),
                ],
                edges: [
                  SceneEdge(
                    id: 'enter',
                    fromNodeId: 'start',
                    fromPortId: 'completed',
                    toNodeId: 'open',
                    kind: SceneEdgeKind.defaultFlow,
                  ),
                  for (final port in ['completed', 'blocked', 'cancelled'])
                    SceneEdge(
                      id: port,
                      fromNodeId: 'open',
                      fromPortId: port,
                      toNodeId: 'end',
                      kind: SceneEdgeKind.actionCompleted,
                    ),
                ],
              ),
            ),
          ],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            legacyClaims: [],
            records: [
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: 'evt_12345678-1234-7123-8123-123456789abc',
                  name: 'Open door',
                  source: NarrativeEventSourceRef.mapEnter('outside'),
                  conditions: [],
                  sceneId: 'open-foreign-door',
                  reusePolicy: NarrativeEventReusePolicy.reusable,
                  priority: 0,
                  order: 0,
                ),
                enabled: true,
              ),
            ],
          ),
        );
        final file = File('${root.path}/project.json');
        if (partitioned) {
          final publication = PortableCatalogPublication.encodeProject(project);
          await file.writeAsString(jsonEncode(publication.descriptor));
          for (final object in publication.storage.objects.entries) {
            final target = File(
              '${root.path}/catalog/objects/${object.key}.json',
            );
            await target.parent.create(recursive: true);
            await target.writeAsBytes(object.value);
          }
        } else {
          await file.writeAsString(jsonEncode(project.toJson()));
        }
        final catalog = await RuntimeProjectCatalog.open(file.path);
        addTearDown(catalog.dispose);
        final chamber = await catalog.manifestForMap(maps['chamber']!);
        expect(chamber.settings, project.settings);
        expect(chamber.models3d.map((model) => model.id), ['chamber-model']);
        final snapshot = await NarrativeEventRuntimeSnapshot.build(
          project: chamber,
          loadMap: (id) async => (project: chamber, map: maps[id]!),
        );
        expect(
          snapshot.projectCatalog.scenes.every((scene) => scene.buildable),
          true,
          reason: snapshot.projectCatalog.diagnostics
              .map((d) => d.toDebugJson())
              .toString(),
        );
        expect(snapshot.project.models3d.map((model) => model.id).toSet(), {
          'chamber-model',
          'outside-model',
        });
        expect(chamber.models3d.map((model) => model.id), ['chamber-model']);
        var state = GameState(
          saveId: 'save',
          currentMapId: 'outside',
          playerPosition: const GridPos(x: 2, y: 2),
          playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 2.5),
        );
        var played = 0, sequence = 0;
        final events = await SpatialGameplayEvents.create(
          project: chamber,
          mapsById: maps,
          narrativeSnapshot: snapshot,
          readGameState: () => state,
          commitGameState: (next) => state = next,
          createSceneCallbacks: (_, _) => SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => 'true',
            showDialogue: (_) => 'completed',
            startBattle: (_) => 'victory',
            playCinematic: (_) => 'completed',
            executeInteractiveCommand: (_) {
              played++;
              return 'completed';
            },
          ),
          showEntityDialogue: (_, _) async {},
          startWildBattle: (_) async {},
          activityGate: NarrativeRuntimeActivityGate(),
          isActive: () => true,
          canProcessInput: () => true,
          runtimeIdFactory: (prefix) =>
              '${prefix}_019abcde-0000-7000-8000-${(++sequence).toRadixString(16).padLeft(12, '0')}',
        );
        addTearDown(events.dispose);
        await events.activateMap(
          MapActivation(
            activationId: 'outside',
            mapId: 'outside',
            reason: MapActivationReason.warp,
          ),
        );
        expect(played, 1);
        expect(await Directory('${root.path}/assets').exists(), false);
      },
    );
  }
}
