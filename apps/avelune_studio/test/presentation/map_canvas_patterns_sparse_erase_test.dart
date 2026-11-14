import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_canvas_patterns_fixtures.dart';

void main() {
  for (final bottomToTop in [false, true]) {
    for (final coveredByEmptyStroke in [false, true]) {
      test(
        'native erase skips sparse empty ownership with ${bottomToTop ? "back-first" : "front-first"} layers and ${coveredByEmptyStroke ? "overlapping" : "single"} stamps',
        () {
          final fixture = patternFixture();
          final sparse = fixture.pattern.copyWith(
            id: 'sparse',
            cells: [fixture.pattern.cells.first],
          );
          final project = fixture.project.copyWith(
            smartTileCatalog: ProjectSmartTileCatalog(
              atlases: fixture.project.smartTileCatalog.atlases,
              materials: fixture.project.smartTileCatalog.materials,
              presets: fixture.project.smartTileCatalog.presets,
              patterns: [fixture.pattern, sparse],
            ),
          );
          final lower = fixture.map.layers.whereType<SmartTileLayer>().single;
          final upper = lower.copyWith(
            id: 'sparse-layer',
            name: 'Clôture',
            patternStrokes: [
              if (coveredByEmptyStroke) ...lower.patternStrokes,
              lower.patternStrokes.single.copyWith(
                id: 'sparse-stroke',
                patternId: sparse.id,
              ),
            ],
          );
          final source = fixture.map.copyWith(
            properties: bottomToTop ? {'tileLayerOrder': 'bottom_to_top'} : {},
            layers: bottomToTop ? [lower, upper] : [upper, lower],
          );
          final document = EditableMapDocument(
            MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
          );
          final view = MapEditingViewportSession()..tool = StudioMapTool.erase;
          addTearDown(view.dispose);
          final stroke = MapCanvasStroke.start(
            map: source,
            project: project,
            view: view,
            commands: MapEditingCommands(document, project),
            origin: const GridPos(x: 4, y: 2),
          )!;
          expect(stroke.buffer.layerId, lower.id);
          final erased = stroke.commit();
          expect(
            erased.layers.firstWhere((layer) => layer.id == upper.id),
            upper,
          );
          expect(
            erased.layers
                .whereType<SmartTileLayer>()
                .firstWhere((layer) => layer.id == lower.id)
                .patternStrokes
                .single
                .cells,
            [
              const GridPos(x: 2, y: 2),
              const GridPos(x: 3, y: 2),
              const GridPos(x: 5, y: 2),
            ],
          );
          document.commit(erased);
          expect(document.undoCount, 1);
          document.restore(redo: false);
          expect(document.current, source);
        },
      );
    }
  }

  test(
    'native erase still selects a sparse cell containing a visible part',
    () {
      final fixture = patternFixture();
      final sparse = fixture.pattern.copyWith(
        id: 'sparse',
        cells: [fixture.pattern.cells.first],
      );
      final project = fixture.project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          atlases: fixture.project.smartTileCatalog.atlases,
          materials: fixture.project.smartTileCatalog.materials,
          presets: fixture.project.smartTileCatalog.presets,
          patterns: [fixture.pattern, sparse],
        ),
      );
      final lower = fixture.map.layers.whereType<SmartTileLayer>().single;
      final upper = lower.copyWith(
        id: 'sparse-layer',
        patternStrokes: [
          lower.patternStrokes.single.copyWith(
            id: 'sparse-stroke',
            patternId: sparse.id,
          ),
        ],
      );
      final source = fixture.map.copyWith(layers: [upper, lower]);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
      );
      final view = MapEditingViewportSession()..tool = StudioMapTool.erase;
      addTearDown(view.dispose);
      final stroke = MapCanvasStroke.start(
        map: source,
        project: project,
        view: view,
        commands: MapEditingCommands(document, project),
        origin: const GridPos(x: 3, y: 2),
      )!;
      expect(stroke.buffer.layerId, upper.id);
      expect(stroke.commit().layers.last, lower);
      final emptySource = source.copyWith(layers: [upper]);
      expect(
        MapCanvasStroke.start(
          map: emptySource,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 4, y: 2),
        ),
        isNull,
      );
      final materialUpper = applySmartTileMaterialGesture(
        upper,
        mapSize: source.size,
        cells: [const GridPos(x: 4, y: 2)],
        materialId: fixture.preset.defaultMaterialId,
      );
      final materialSource = source.copyWith(layers: [materialUpper, lower]);
      final materialStroke = MapCanvasStroke.start(
        map: materialSource,
        project: project,
        view: view,
        commands: MapEditingCommands(document, project),
        origin: const GridPos(x: 4, y: 2),
      )!;
      expect(materialStroke.buffer.layerId, upper.id);
      final materialErased = materialStroke.commit();
      expect(materialErased.layers.last, lower);
      expect(
        smartTileMaterialIdAt(
          materialErased.layers.whereType<SmartTileLayer>().first,
          mapSize: source.size,
          x: 4,
          y: 2,
        ),
        isNull,
      );
    },
  );
}
