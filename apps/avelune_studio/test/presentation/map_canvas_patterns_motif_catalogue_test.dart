import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_terrain_patterns.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/spatial_terrain_draft_test.dart' show spatialPathModel;
import 'map_canvas_patterns_fixtures.dart';

void main() {
  for (final spatial in [false, true]) {
    test(
      '${spatial ? "3D" : "2D"} Motif shows reusable catalogue recipes and keeps the material',
      () {
        final fixture = patternFixture(spatial: spatial);
        final stamp = fixture.pattern.copyWith(
          id: 'stamp',
          name: 'Bouquet isolé',
          repeatMode: SmartTilePatternRepeatMode.stamp,
        );
        final giant = fixture.pattern.copyWith(
          id: 'giant',
          name: 'Recette source entière',
          width: 9,
        );
        final unreferenced = fixture.pattern.copyWith(
          id: 'public-unused',
          name: 'Motif du catalogue',
        );
        final incompatible = fixture.pattern.copyWith(
          id: 'other-usage',
          name: 'Autre usage',
          usage: fixture.pattern.usage == SmartTileUsage.path
              ? SmartTileUsage.terrain
              : SmartTileUsage.path,
        );
        final unavailable = fixture.pattern.copyWith(
          id: 'unavailable',
          name: 'Source privée ailleurs',
          cells: [
            const SmartTilePatternCell(
              x: 0,
              y: 0,
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.model3d(modelId: 'other-model'),
                ),
              ],
            ),
          ],
        );
        final absolute = fixture.pattern.copyWith(
          id: 'absolute-water',
          name: 'Eau source à altitude fixe',
          cells: [
            const SmartTilePatternCell(
              x: 0,
              y: 0,
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.model3d(
                    modelId: 'oak',
                    followTerrain: false,
                    offsetY: -2.25,
                  ),
                ),
              ],
            ),
          ],
        );
        final project = fixture.project.copyWith(
          models3d: [
            ...fixture.project.models3d,
            spatialPathModel('other-model'),
          ],
          resourceLibraryCatalog: ResourceLibraryCatalog(
            entries: [
              ResourceLibraryEntry(
                resourceKind: 'model3d',
                resourceId: 'other-model',
                mapId: 'b',
              ),
            ],
          ),
          smartTileCatalog: ProjectSmartTileCatalog(
            materials: fixture.project.smartTileCatalog.materials,
            atlases: fixture.project.smartTileCatalog.atlases,
            presets: [fixture.preset],
            patterns: [
              fixture.pattern,
              stamp,
              giant,
              unreferenced,
              incompatible,
              unavailable,
              absolute,
            ],
          ),
        );
        final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
        final map = replaceSmartTileLayer(
          fixture.map,
          layer: layer.copyWith(
            patternStrokes: [
              ...layer.patternStrokes,
              for (final pattern in [stamp, giant, incompatible, unavailable])
                SmartTilePatternStroke(
                  id: pattern.id,
                  patternId: pattern.id,
                  cells: [const GridPos(x: 7, y: 7)],
                ),
            ],
          ),
        );
        expect(
          availableTerrainPatterns(
            project: project,
            map: map,
            preset: fixture.preset,
          ).map((pattern) => pattern.id).toSet(),
          {
            fixture.pattern.id,
            stamp.id,
            unreferenced.id,
            if (spatial) absolute.id,
          },
        );
        final view = MapEditingViewportSession()
          ..prepareTerrainPainting(fixture.preset);
        addTearDown(view.dispose);
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
        );
        final material = view.terrainMaterialId;
        view.selectTerrainPattern(fixture.pattern);
        expect(view.terrainPatternId, fixture.pattern.id);
        view.terrainPatternMode = SmartTilePatternSelectionKind.rectangle;
        expect(
          view.terrainPatternMode,
          SmartTilePatternSelectionKind.rectangle,
        );
        view.selectTerrainPattern(stamp);
        expect(view.terrainPatternMode, SmartTilePatternSelectionKind.stamp);
        view.selectTerrainPattern(null);
        expect(view.terrainPatternId, isNull);
        expect(view.terrainMaterialId, material);
        expect(document.current, same(map));
      },
    );
    test(
      '${spatial ? "3D" : "2D"} public motif creates an empty layer on an unused map and undoes exactly',
      () {
        final fixture = patternFixture(spatial: spatial);
        final source = fixture.map.copyWith(layers: []);
        expect(
          availableTerrainPatterns(
            project: fixture.project,
            map: source,
            preset: fixture.preset,
          ),
          [fixture.pattern],
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = MapEditingViewportSession()
          ..prepareTerrainPainting(fixture.preset)
          ..selectTerrainPattern(fixture.pattern);
        addTearDown(view.dispose);
        final material = view.terrainMaterialId;
        final stroke = MapCanvasStroke.start(
          map: source,
          project: fixture.project,
          view: view,
          commands: MapEditingCommands(document, fixture.project),
          origin: const GridPos(x: 1, y: 1),
        )!;
        expect(document.current, same(source));
        final previewLayer = stroke.preview.layers
            .whereType<SmartTileLayer>()
            .single;
        expect(smartTileSemanticCells(previewLayer), everyElement(0));
        expect(
          previewLayer.patternStrokes.single.patternId,
          fixture.pattern.id,
        );
        expect(previewLayer.patternStrokes.single.cells, [
          const GridPos(x: 1, y: 1),
          const GridPos(x: 2, y: 1),
        ]);
        document.commit(stroke.commit());
        expect(document.undoCount, 1);
        expect(view.terrainMaterialId, material);
        expect(
          document.current.spatialScene?.instances,
          spatial ? isEmpty : isNull,
        );
        document.restore(redo: false);
        expect(document.current, source);
      },
    );
    test(
      '${spatial ? "3D" : "2D"} motif availability respects the typed source map scope and allows components',
      () {
        final fixture = patternFixture(spatial: spatial);
        final sourceId = spatial
            ? 'oak'
            : fixture.project.smartTileCatalog.atlases.single.tilesetId;
        final project = fixture.project.copyWith(
          resourceLibraryCatalog: ResourceLibraryCatalog(
            entries: [
              ResourceLibraryEntry(
                resourceKind: spatial ? 'model3d' : 'tileset',
                resourceId: sourceId,
                mapId: fixture.map.id,
                role: ResourceLibraryRole.component,
              ),
            ],
          ),
        );
        expect(
          availableTerrainPatterns(
            project: project,
            map: fixture.map.copyWith(layers: []),
            preset: fixture.preset,
          ),
          [fixture.pattern],
        );
        expect(
          availableTerrainPatterns(
            project: project,
            map: fixture.map.copyWith(id: 'b', layers: []),
            preset: fixture.preset,
          ),
          isEmpty,
        );
        final view = MapEditingViewportSession()
          ..prepareTerrainPainting(fixture.preset)
          ..selectTerrainPattern(fixture.pattern);
        addTearDown(view.dispose);
        view.reconcileResources(
          project,
          mapId: 'b',
          map: fixture.map.copyWith(id: 'b', layers: []),
        );
        expect(view.terrainPatternId, isNull);
        expect(view.terrainMaterialId, fixture.preset.defaultMaterialId);
      },
    );
  }
}
