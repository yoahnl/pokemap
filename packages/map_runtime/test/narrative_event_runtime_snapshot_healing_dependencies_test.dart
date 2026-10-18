import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';

void main() {
  for (final partitioned in [false, true]) {
    test(
      'global narrative validation retains another map healing visuals lazy=$partitioned',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'narrative-healing-closure-',
        );
        addTearDown(() => root.delete(recursive: true));
        final center = MapData(
          id: 'center',
          name: 'Center',
          size: const GridSize(width: 8, height: 8),
          entities: [
            MapEntity(
              id: 'healing-balls',
              kind: MapEntityKind.custom,
              pos: const GridPos(x: 3, y: 3),
              blocksMovement: false,
              healingDisplay: MapEntityHealingDisplayData(
                variantElementIds: [for (var i = 1; i <= 6; i++) 'healing-$i'],
              ),
            ),
          ],
        );
        const mart = MapData(
          id: 'mart',
          name: 'Mart',
          size: GridSize(width: 8, height: 8),
        );
        final project = ProjectManifest(
          name: 'Services',
          maps: const [
            ProjectMapEntry(
              id: 'mart',
              name: 'Mart',
              relativePath: 'maps/mart.json',
            ),
            ProjectMapEntry(
              id: 'center',
              name: 'Center',
              relativePath: 'maps/center.json',
            ),
          ],
          elementCategories: const [
            ProjectElementCategory(id: 'healing', name: 'Healing'),
          ],
          tilesets: [
            ProjectTilesetEntry(
              id: 'healing-sheet',
              name: 'Healing',
              relativePath: 'healing.png',
              source: ProjectRegularAtlasTilesetSource(
                assetId: 'healing-sheet',
                pixelWidth: 256,
                pixelHeight: 192,
                tileWidth: 64,
                tileHeight: 48,
              ),
            ),
          ],
          elements: [
            for (var i = 1; i <= 6; i++)
              ProjectElementEntry(
                id: 'healing-$i',
                name: 'Healing $i',
                tilesetId: 'healing-sheet',
                categoryId: 'healing',
                frames: [
                  TilesetVisualFrame(
                    source: TilesetSourceRect(x: 0, y: (i - 1) % 3 + 1),
                    durationMs: 125,
                  ),
                ],
              ),
          ],
          scenes: [
            SceneAsset(
              id: 'nurse',
              name: 'Nurse',
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: [
                  SceneNode(id: 'start', kind: SceneNodeKind.start),
                  SceneNode(
                    id: 'heal',
                    kind: SceneNodeKind.action,
                    payload: SceneActionPayload.interactive(
                      SceneInteractiveCommand.openHeal(
                        displayEntityId: 'healing-balls',
                      ),
                    ),
                  ),
                  SceneNode(
                    id: 'end',
                    kind: SceneNodeKind.end,
                    payload: SceneEndPayload(),
                  ),
                ],
                edges: [
                  SceneEdge(
                    id: 'start-heal',
                    fromNodeId: 'start',
                    fromPortId: 'completed',
                    toNodeId: 'heal',
                    kind: SceneEdgeKind.defaultFlow,
                  ),
                  for (final port in ['completed', 'cancelled'])
                    SceneEdge(
                      id: 'heal-$port',
                      fromNodeId: 'heal',
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
            records: const [],
            legacyClaims: const [],
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
        final selected = await catalog.manifestForMap(mart);
        expect(selected.elements, isEmpty);
        expect(selected.tilesets, isEmpty);
        expect(
          diagnoseSceneAgainstProject(
            project.scenes.single,
            project,
            mapsById: {'center': center, 'mart': mart},
          ).errorCount,
          0,
        );
        expect(
          diagnoseSceneAgainstProject(
            project.scenes.single,
            selected,
            mapsById: {'center': center, 'mart': mart},
          ).byCode(SceneDiagnosticCode.commandInvalidHealingDisplay),
          hasLength(1),
        );
        final missing = await NarrativeEventRuntimeSnapshot.build(
          project: selected,
          loadMap: (id) async {
            final map = id == 'center'
                ? center.copyWith(entities: const [])
                : mart;
            return (project: selected, map: map);
          },
        );
        expect(missing.projectCatalog.scenes.single.buildable, isFalse);
        expect(
          missing.projectCatalog.diagnostics.map(
            (diagnostic) => diagnostic.code,
          ),
          contains('sceneNotBuildable'),
        );
        final otherOwner = await RuntimeProjectCatalog.open(file.path);
        addTearDown(otherOwner.dispose);
        await expectLater(
          NarrativeEventRuntimeSnapshot.build(
            project: selected,
            loadMap: (id) async {
              final map = id == 'center' ? center : mart;
              return (project: await otherOwner.manifestForMap(map), map: map);
            },
          ),
          throwsStateError,
        );
        final snapshot = await NarrativeEventRuntimeSnapshot.build(
          project: selected,
          loadMap: (id) async {
            final map = id == 'center' ? center : mart;
            return (project: selected, map: map);
          },
        );
        expect(
          snapshot.projectCatalog.scenes.single.buildable,
          isTrue,
          reason: snapshot.projectCatalog.diagnostics
              .map((diagnostic) => diagnostic.code)
              .join(','),
        );
        expect(
          snapshot.projectCatalog.diagnostics.where(
            (diagnostic) =>
                diagnostic.severity ==
                NarrativeEventProjectDiagnosticSeverity.error,
          ),
          isEmpty,
        );
        expect(snapshot.matchesProject(selected), isTrue);
        expect(identical(snapshot.project, selected), isTrue);
        expect(selected.elements, isEmpty);
        expect(selected.tilesets, isEmpty);
      },
    );
  }
}
