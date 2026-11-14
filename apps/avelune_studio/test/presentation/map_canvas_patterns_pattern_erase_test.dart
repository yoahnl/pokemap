import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_canvas_patterns_fixtures.dart';

void main() {
  for (final spatial in [true, false]) {
    test(
      'reactive path motifs synchronize material and erase: spatial $spatial',
      () {
        final fixture = patternFixture(spatial: spatial);
        final preset = fixture.preset.copyWith(usage: SmartTileUsage.path);
        final pattern = fixture.pattern.copyWith(usage: SmartTileUsage.path);
        final project = fixture.project.copyWith(
          smartTileCatalog: ProjectSmartTileCatalog(
            atlases: fixture.project.smartTileCatalog.atlases,
            materials: fixture.project.smartTileCatalog.materials,
            presets: [preset],
            patterns: [pattern],
          ),
        );
        final original = fixture.map.layers.whereType<SmartTileLayer>().single;
        final source = fixture.map.copyWith(
          layers: [
            original.copyWith(
              usage: SmartTileUsage.path,
              animationActivation: SmartTileAnimationActivation.onEnter,
              patternStrokes: [],
            ),
          ],
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = MapEditingViewportSession()
          ..prepareTerrainPainting(preset)
          ..selectTerrainPattern(pattern)
          ..terrainPatternMode = SmartTilePatternSelectionKind.stamp
          ..tool = StudioMapTool.terrain;
        addTearDown(view.dispose);
        final stroke = MapCanvasStroke.start(
          map: source,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 2, y: 3),
        )!;
        final painted = stroke.commit();
        final paintedLayer = painted.layers.whereType<SmartTileLayer>().single;
        expect(smartTileSemanticCells(paintedLayer)[26], 1);
        expect(smartTileSemanticCells(paintedLayer)[27], 1);
        expect(
          smartTileSemanticCells(paintedLayer).where((value) => value != 0),
          hasLength(2),
        );
        expect(
          smartTileSemanticCells(source.layers.single as SmartTileLayer)[26],
          0,
        );
        document.commit(painted);
        view.tool = StudioMapTool.erase;
        final erase = MapCanvasStroke.start(
          map: painted,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 2, y: 3),
        )!;
        final erased = erase.commit();
        final erasedLayer = erased.layers.whereType<SmartTileLayer>().single;
        expect(smartTileSemanticCells(erasedLayer)[26], 0);
        expect(smartTileSemanticCells(erasedLayer)[27], 1);
        expect(erasedLayer.patternStrokes.single.cells, [
          const GridPos(x: 3, y: 3),
        ]);
        document.commit(erased);
        document.restore(redo: false);
        expect(document.current, painted);
        expect(painted.spatialScene, source.spatialScene);
      },
    );
  }

  test('native erase commits visual-only pattern cells and interpolates without changing neighbours', () {
    final fixture = patternFixture(followTerrain: false);
    final source = fixture.map;
    final view = MapEditingViewportSession()..tool = StudioMapTool.erase;
    addTearDown(view.dispose);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
    );
    final stroke = MapCanvasStroke.start(
      map: source,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 3, y: 2),
    );
    expect(stroke, isNotNull);
    stroke!.paint(const GridPos(x: 5, y: 2));
    expect(document.current, same(source));
    final preview = stroke.preview.layers.whereType<SmartTileLayer>().single;
    expect(preview.patternStrokes.single.cells, [const GridPos(x: 2, y: 2)]);
    expect(preview.patternStrokes.single.phaseX, 1);
    expect(preview.patternStrokes.single.phaseY, 0);
    expect(
      preview.field,
      source.layers.whereType<SmartTileLayer>().single.field,
    );
    document.commit(stroke.commit());
    expect(document.current, stroke.preview);
    expect(document.undoCount, 1);
    expect(document.current.spatialScene, source.spatialScene);
    expect(
      resolveSpatialSmartTileInstances(
        map: document.current,
        catalog: fixture.project.smartTileCatalog,
      ),
      hasLength(1),
    );
    document.restore(redo: false);
    expect(document.current, source);
    expect(
      resolveSpatialSmartTileInstances(
        map: document.current,
        catalog: fixture.project.smartTileCatalog,
      ),
      hasLength(4),
    );
  });

  test('2D material erase preserves existing pattern ownership', () {
    final fixture = patternFixture(spatial: false);
    final spatial = fixture.map.layers.whereType<SmartTileLayer>().single;
    final layer = applySmartTileMaterialGesture(
      spatial,
      mapSize: fixture.map.size,
      cells: [const GridPos(x: 3, y: 2)],
      materialId: fixture.preset.defaultMaterialId,
    );
    final source = MapData(
      id: fixture.map.id,
      name: 'Plan 2D',
      version: ProjectVersion.v8,
      size: fixture.map.size,
      layers: [layer],
    );
    final view = MapEditingViewportSession()..tool = StudioMapTool.erase;
    addTearDown(view.dispose);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
    );
    final stroke = MapCanvasStroke.start(
      map: source,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 3, y: 2),
    )!;
    final erased = stroke.commit().layers.whereType<SmartTileLayer>().single;
    expect(
      smartTileMaterialIdAt(erased, mapSize: source.size, x: 3, y: 2),
      isNull,
    );
    expect(erased.patternStrokes, layer.patternStrokes);
    document.commit(stroke.commit());
    document.restore(redo: false);
    expect(document.current, source);
  });

  test('changing the selected recipe cancels a 2D pattern erase gesture', () {
    final fixture = patternFixture(spatial: false);
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: fixture.map,
        mapId: fixture.map.id,
        revision: 'r0',
      ),
    );
    final view = MapEditingViewportSession()
      ..prepareTerrainPainting(fixture.preset)
      ..selectTerrainPattern(fixture.pattern)
      ..tool = StudioMapTool.erase;
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: fixture.map,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 3, y: 2),
    )!;
    expect(stroke.matches(view), isTrue);
    view.terrainPatternId = 'another';
    expect(stroke.matches(view), isFalse);
    expect(document.current, fixture.map);
    expect(document.canUndo, isFalse);
  });

  test('2D pattern erase removes only ownership and preserves materials', () {
    final fixture = patternFixture(spatial: false);
    final sourceLayer = fixture.map.layers.whereType<SmartTileLayer>().single;
    final source = replaceSmartTileLayer(
      fixture.map,
      layer: applySmartTileMaterialGesture(
        sourceLayer,
        mapSize: fixture.map.size,
        cells: [const GridPos(x: 3, y: 2)],
        materialId: fixture.preset.defaultMaterialId,
      ),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
    );
    final view = MapEditingViewportSession()
      ..prepareTerrainPainting(fixture.preset)
      ..selectTerrainPattern(fixture.pattern)
      ..tool = StudioMapTool.erase;
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: source,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 3, y: 2),
    )!;
    document.commit(stroke.commit());
    final layer = document.current.layers.whereType<SmartTileLayer>().single;
    expect(
      smartTileMaterialIdAt(layer, mapSize: source.size, x: 3, y: 2),
      fixture.preset.defaultMaterialId,
    );
    expect(layer.patternStrokes.single.cells, [
      const GridPos(x: 2, y: 2),
      const GridPos(x: 4, y: 2),
      const GridPos(x: 5, y: 2),
    ]);
    document.restore(redo: false);
    expect(document.current, source);
  });
}
