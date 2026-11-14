import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_terrain_patterns.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_canvas_patterns_fixtures.dart';

void main() {
  for (final spatial in [false, true]) {
    test(
      '${spatial ? "3D" : "2D"} picker checks normalized stamp footprints without changing tiled recipes',
      () {
        final fixture = patternFixture(spatial: spatial);
        final compact = fixture.pattern.copyWith(
          id: 'compact',
          name: 'Raccord compact',
          repeatMode: SmartTilePatternRepeatMode.stamp,
        );
        final shifted = compact.copyWith(
          id: 'shifted',
          name: 'Raccord décalé',
          width: 8,
          cells: [
            for (final cell in compact.cells) cell.copyWith(x: cell.x + 6),
          ],
        );
        final shiftedVertical = compact.copyWith(
          id: 'shifted-vertical',
          name: 'Raccord décalé en profondeur',
          height: 8,
          cells: [
            for (final cell in compact.cells) cell.copyWith(y: cell.y + 6),
          ],
        );
        final emptyOrigin = shifted.copyWith(
          id: 'empty-origin',
          name: 'Raccord avec origine vide',
          cells: [
            const SmartTilePatternCell(x: 0, y: 0, eraseMaterial: true),
            ...shifted.cells,
          ],
        );
        final tiled = shifted.copyWith(
          id: 'shifted-tiled',
          name: 'Trame décalée',
          repeatMode: SmartTilePatternRepeatMode.tiled,
        );
        final project = fixture.project.copyWith(
          smartTileCatalog: ProjectSmartTileCatalog(
            materials: fixture.project.smartTileCatalog.materials,
            atlases: fixture.project.smartTileCatalog.atlases,
            presets: [fixture.preset],
            patterns: [compact, shifted, shiftedVertical, emptyOrigin, tiled],
          ),
        );
        final map = fixture.map.copyWith(layers: []);
        expect(
          availableTerrainPatterns(
            project: project,
            map: map,
            preset: fixture.preset,
          ).map((pattern) => pattern.id).toSet(),
          {
            compact.id,
            tiled.id,
            if (!spatial) ...{shifted.id, shiftedVertical.id, emptyOrigin.id},
          },
        );
        final view = MapEditingViewportSession()
          ..prepareTerrainPainting(fixture.preset);
        addTearDown(view.dispose);
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
        );
        view.selectTerrainPattern(compact);
        final stroke = MapCanvasStroke.start(
          map: map,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 1, y: 1),
        )!;
        document.commit(stroke.commit());
        expect(
          document.current.layers
              .whereType<SmartTileLayer>()
              .single
              .patternStrokes
              .single
              .cells,
          [const GridPos(x: 1, y: 1), const GridPos(x: 2, y: 1)],
        );
      },
    );
    for (final erase in [false, true]) {
      test(
        '${spatial ? "3D" : "2D"} diagonal ${erase ? "erase" : "paint"} uses one interpolation and preserves the opposite neighbour',
        () {
          final fixture = patternFixture(spatial: spatial);
          final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
          final source = replaceSmartTileLayer(
            fixture.map,
            layer: layer.copyWith(
              field: SmartTileField.cell(
                semanticCells: List.filled(64, erase ? 1 : 0),
              ),
              patternStrokes: [],
            ),
          );
          final document = EditableMapDocument(
            MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
          );
          final view = MapEditingViewportSession()
            ..prepareTerrainPainting(fixture.preset)
            ..tool = erase ? StudioMapTool.erase : StudioMapTool.terrain;
          addTearDown(view.dispose);
          final stroke = MapCanvasStroke.start(
            map: source,
            project: fixture.project,
            view: view,
            commands: MapEditingCommands(document, fixture.project),
            origin: const GridPos(x: 3, y: 2),
          )!;
          stroke.paint(const GridPos(x: 5, y: 3));
          final selected = {
            const GridPos(x: 3, y: 2),
            GridPos(x: 4, y: spatial ? 2 : 3),
            const GridPos(x: 5, y: 3),
          };
          final previewLayer = stroke.preview.layers
              .whereType<SmartTileLayer>()
              .single;
          final changed = <GridPos>{};
          for (var y = 0; y < source.size.height; y++) {
            for (var x = 0; x < source.size.width; x++) {
              final cell = GridPos(x: x, y: y);
              final painted =
                  smartTileMaterialIdAt(
                    previewLayer,
                    mapSize: source.size,
                    x: x,
                    y: y,
                  ) !=
                  null;
              if (painted != erase) changed.add(cell);
            }
          }
          expect(changed, selected);
          expect(changed.contains(GridPos(x: 4, y: spatial ? 3 : 2)), isFalse);
          expect(document.current, same(source));
          document.commit(stroke.commit());
          expect(document.current, stroke.preview);
          expect(document.undoCount, 1);
          document.restore(redo: false);
          expect(document.current, source);
        },
      );
    }
    test(
      '${spatial ? "3D" : "2D"} a new manifest changing the same ID to stamp reconciles the displayed mode and gesture',
      () {
        final fixture = patternFixture(spatial: spatial);
        final view = MapEditingViewportSession()
          ..prepareTerrainPainting(fixture.preset)
          ..selectTerrainPattern(fixture.pattern)
          ..terrainPatternMode = SmartTilePatternSelectionKind.line;
        addTearDown(view.dispose);
        final document = EditableMapDocument(
          MapWorkspaceDocument(
            map: fixture.map,
            mapId: fixture.map.id,
            revision: 'r0',
          ),
        );
        final stamp = fixture.pattern.copyWith(
          repeatMode: SmartTilePatternRepeatMode.stamp,
        );
        final currentProject = fixture.project.copyWith(
          smartTileCatalog: ProjectSmartTileCatalog(
            materials: fixture.project.smartTileCatalog.materials,
            atlases: fixture.project.smartTileCatalog.atlases,
            presets: [fixture.preset],
            patterns: [stamp],
          ),
        );
        view.reconcileResources(
          currentProject,
          mapId: fixture.map.id,
          map: fixture.map,
        );
        expect(view.terrainPatternId, stamp.id);
        expect(view.terrainPatternMode, SmartTilePatternSelectionKind.stamp);
        final stroke = MapCanvasStroke.start(
          map: fixture.map,
          project: currentProject,
          view: view,
          commands: MapEditingCommands(document, currentProject),
          origin: const GridPos(x: 0, y: 0),
        )!;
        stroke.paint(const GridPos(x: 6, y: 6));
        expect(stroke.patternMode, SmartTilePatternSelectionKind.stamp);
        document.commit(stroke.commit());
        expect(
          document.current.layers
              .whereType<SmartTileLayer>()
              .single
              .patternStrokes
              .last
              .cells,
          [const GridPos(x: 0, y: 0), const GridPos(x: 1, y: 0)],
        );
        document.restore(redo: false);
        expect(document.current, fixture.map);
      },
    );
  }
}
