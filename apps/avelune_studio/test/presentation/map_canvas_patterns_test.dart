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
  test('fixed-height whole models remain available only in native spatial channels', () {
    final fixture = patternFixture();
    for (final channel in SmartTileRenderChannel.values) {
      final original = fixture.pattern.cells.first.parts.first;
      final source = original.source as SmartTileModel3dSource;
      final part = original.copyWith(
        channel: channel,
        source: source.copyWith(followTerrain: false),
      );
      final pattern = fixture.pattern.copyWith(
        cells: [
          SmartTilePatternCell(x: 0, y: 0, parts: [part]),
        ],
      );
      final patterns = availableTerrainPatterns(
        project: withStampPatterns(fixture.project, [pattern]),
        map: fixture.map,
        preset: fixture.preset,
      );
      expect(
        patterns.map((p) => p.id).contains(pattern.id),
        [
          SmartTileRenderChannel.ground,
          SmartTileRenderChannel.understory,
          SmartTileRenderChannel.canopy,
        ].contains(channel),
        reason: channel.name,
      );
    }
  });

  test(
    'fixed-height static clipped walls remain available in native channels',
    () {
      final fixture = patternFixture();
      for (final channel in SmartTileRenderChannel.values) {
        final original = fixture.pattern.cells.first.parts.first;
        final source = original.source as SmartTileModel3dSource;
        final part = original.copyWith(
          channel: channel,
          source: source.copyWith(followTerrain: false),
          spatialClip: SmartTileSpatialClip(
            left: 0,
            top: 0,
            right: 1,
            bottom: 1,
          ),
        );
        final pattern = fixture.pattern.copyWith(
          cells: [
            SmartTilePatternCell(x: 0, y: 0, parts: [part]),
          ],
        );
        final patterns = availableTerrainPatterns(
          project: withStampPatterns(fixture.project, [pattern]),
          map: fixture.map,
          preset: fixture.preset,
        );
        expect(
          patterns.map((p) => p.id).contains(pattern.id),
          [
            SmartTileRenderChannel.ground,
            SmartTileRenderChannel.understory,
            SmartTileRenderChannel.canopy,
          ].contains(channel),
          reason: channel.name,
        );
      }
    },
  );

  test('whole fixed native stamp previews nothing at an edge and commits a complete anchored envelope', () {
    final fixture = adaptiveBridgeFixture();
    final pattern = fixture.pattern.copyWith(
      construction: null,
      repeatMode: SmartTilePatternRepeatMode.stamp,
      clippingPolicy: SmartTilePatternClippingPolicy.reject,
      anchorX: 2,
      anchorY: 1,
    );
    final catalog = fixture.project.smartTileCatalog;
    final project = fixture.project.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        categories: catalog.categories,
        atlases: catalog.atlases,
        materials: catalog.materials,
        presets: catalog.presets,
        patterns: [pattern],
      ),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: fixture.map,
        mapId: fixture.map.id,
        revision: 'r0',
      ),
    );
    final view = MapEditingViewportSession()
      ..prepareTerrainPainting(fixture.preset)
      ..selectTerrainPattern(pattern);
    addTearDown(view.dispose);
    final invalid = MapCanvasStroke.start(
      map: fixture.map,
      project: project,
      view: view,
      commands: MapEditingCommands(document, project),
      origin: const GridPos(x: 0, y: 0),
    )!;
    expect(invalid.preview, fixture.map);
    expect(
      () => invalid.commit(),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.message,
          'message',
          'Le motif entier doit tenir dans la carte.',
        ),
      ),
    );
    expect(document.undoCount, 0);
    final valid = MapCanvasStroke.start(
      map: fixture.map,
      project: project,
      view: view,
      commands: MapEditingCommands(document, project),
      origin: const GridPos(x: 2, y: 1),
    )!;
    expect(
      valid.preview.layers
          .whereType<SmartTileLayer>()
          .single
          .patternStrokes
          .single
          .cells,
      hasLength(20),
    );
    document.commit(valid.commit());
    document.restore(redo: false);
    expect(document.current, fixture.map);
  });

  test('stamp clips at an edge and keeps its authored anchor phase', () {
    final fixture = patternFixture();
    final pattern = fixture.pattern.copyWith(anchorX: 1);
    final project = fixture.project.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: fixture.project.smartTileCatalog.materials,
        presets: [fixture.preset],
        patterns: [pattern],
      ),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: fixture.map,
        mapId: fixture.map.id,
        revision: 'r0',
      ),
    );
    final view = MapEditingViewportSession()
      ..prepareTerrainPainting(fixture.preset)
      ..selectTerrainPattern(pattern);
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: fixture.map,
      project: project,
      view: view,
      commands: MapEditingCommands(document, project),
      origin: const GridPos(x: 0, y: 0),
    )!;
    final placed = stroke
        .commit()
        .layers
        .whereType<SmartTileLayer>()
        .single
        .patternStrokes
        .last;
    expect(placed.cells, [const GridPos(x: 0, y: 0)]);
    expect(placed.phaseX, 1);
    expect(placed.phaseY, 0);
    expect(
      smartTilePatternCellAt(
        pattern: pattern,
        stroke: placed,
        cell: const GridPos(x: 0, y: 0),
      )!.x,
      1,
    );
  });

  test('an excessive rectangle is rejected without a commit or undo entry', () {
    final fixture = patternFixture();
    final sourceLayer = fixture.map.layers.whereType<SmartTileLayer>().single;
    final map = fixture.map.copyWith(
      size: const GridSize(width: 80, height: 80),
      spatialScene: MapSpatialScene(width: 80, depth: 80),
      layers: [
        sourceLayer.copyWith(
          field: SmartTileField.cell(semanticCells: List.filled(6400, 0)),
        ),
      ],
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
    );
    final view = MapEditingViewportSession()
      ..prepareTerrainPainting(fixture.preset)
      ..selectTerrainPattern(fixture.pattern)
      ..terrainPatternMode = SmartTilePatternSelectionKind.rectangle;
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: map,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 0, y: 0),
    )!;
    expect(
      () => stroke.paint(const GridPos(x: 64, y: 64)),
      throwsA(isA<SmartTileGestureLimitException>()),
    );
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
  });
}
