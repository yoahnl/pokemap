import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_canvas_patterns_fixtures.dart';

void main() {
  test('selected clipped small 3D stamp erases only its existing cells', () {
    final fixture = atomicStampFixture(origin: const GridPos(x: 6, y: 6));
    final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
    expect(layer.patternStrokes.single.cells, hasLength(4));
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: fixture.map,
        mapId: fixture.map.id,
        revision: 'r0',
      ),
    );
    final view = selectedStampEraseView(fixture.preset, fixture.pattern);
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: fixture.map,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 7, y: 7),
    )!;
    expect(
      stroke.preview.layers.whereType<SmartTileLayer>().single.patternStrokes,
      isEmpty,
    );
    expect(
      stroke.commit().layers.whereType<SmartTileLayer>().single.field,
      layer.field,
    );
  });

  test('selected small 3D stamp refuses a scattered or oversized historical stroke', () {
    final fixture = atomicStampFixture();
    for (final cells in [
      [const GridPos(x: 2, y: 2), const GridPos(x: 7, y: 7)],
      [
        for (var y = 2; y < 6; y++)
          for (var x = 2; x < 6; x++) GridPos(x: x, y: y),
      ],
    ]) {
      final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
      final source = replaceSmartTileLayer(
        fixture.map,
        layer: layer.copyWith(
          patternStrokes: [layer.patternStrokes.single.copyWith(cells: cells)],
        ),
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
      );
      final view = selectedStampEraseView(fixture.preset, fixture.pattern);
      addTearDown(view.dispose);
      expect(
        MapCanvasStroke.start(
          map: source,
          project: fixture.project,
          view: view,
          commands: MapEditingCommands(document, fixture.project),
          origin: cells.first,
        ),
        isNull,
      );
    }
  });

  for (final bottomToTop in [false, true]) {
    test(
      'selected small stamp does not erase through a foreign owner on a ${bottomToTop ? "back-first" : "front-first"} upper layer',
      () {
        final fixture = atomicStampFixture();
        final foreign = fixture.pattern.copyWith(id: 'foreign-unit');
        final project = withStampPatterns(fixture.project, [
          fixture.pattern,
          foreign,
        ]);
        final lower = fixture.map.layers.whereType<SmartTileLayer>().single;
        final upper = lower.copyWith(
          id: 'upper',
          patternStrokes: [
            lower.patternStrokes.single.copyWith(
              id: 'upper-unit',
              patternId: foreign.id,
            ),
          ],
        );
        final source = fixture.map.copyWith(
          layers: bottomToTop ? [lower, upper] : [upper, lower],
          properties: bottomToTop ? {'tileLayerOrder': 'bottom_to_top'} : {},
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = selectedStampEraseView(fixture.preset, fixture.pattern);
        addTearDown(view.dispose);
        expect(
          MapCanvasStroke.start(
            map: source,
            project: project,
            view: view,
            commands: MapEditingCommands(document, project),
            origin: const GridPos(x: 3, y: 3),
          ),
          isNull,
        );
        expect(document.current, same(source));
        expect(document.undoCount, 0);
      },
    );
  }

  for (final kind in ['frame', 'animation', 'mixed']) {
    test(
      'selected 3D $kind stamp keeps cell-region erasure and protects native ownership beneath it',
      () {
        final fixture = atomicStampFixture();
        final raster = patternFixture(spatial: false);
        final frame =
            (raster.pattern.cells.first.parts.first.source
                    as SmartTileFrameSource)
                .frame;
        final part = SmartTileVisualPart(
          source: kind == 'animation'
              ? const SmartTileVisualSource.animation(
                  animationId: 'raster-animation',
                )
              : SmartTileVisualSource.frame(frame: frame),
        );
        final pattern = fixture.pattern.copyWith(
          id: 'raster-stamp',
          cells: [
            SmartTilePatternCell(
              x: 0,
              y: 0,
              parts: [
                part,
                if (kind == 'mixed') fixture.pattern.cells.first.parts.first,
              ],
            ),
          ],
        );
        final project = fixture.project.copyWith(
          tilesets: raster.project.tilesets,
          smartTileCatalog: ProjectSmartTileCatalog(
            atlases: raster.project.smartTileCatalog.atlases,
            materials: fixture.project.smartTileCatalog.materials,
            presets: fixture.project.smartTileCatalog.presets,
            patterns: [fixture.pattern, pattern],
            animations: [
              if (kind == 'animation')
                ProjectSmartTileAnimation(
                  id: 'raster-animation',
                  name: 'Eau',
                  frames: [
                    ProjectSmartTileAnimationFrame(
                      frame: frame,
                      durationMs: 100,
                    ),
                  ],
                ),
            ],
          ),
        );
        final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
        final rasterStroke = layer.patternStrokes.single.copyWith(
          patternId: pattern.id,
        );
        final source = replaceSmartTileLayer(
          fixture.map,
          layer: layer.copyWith(patternStrokes: [rasterStroke]),
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = selectedStampEraseView(fixture.preset, pattern);
        addTearDown(view.dispose);
        final stroke = MapCanvasStroke.start(
          map: source,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 3, y: 3),
        )!;
        final erased = stroke
            .commit()
            .layers
            .whereType<SmartTileLayer>()
            .single;
        expect(erased.patternStrokes.single.cells, hasLength(8));
        expect(
          erased.patternStrokes.single.cells,
          contains(const GridPos(x: 2, y: 2)),
        );
        expect(erased.field, layer.field);
        final covered = replaceSmartTileLayer(
          fixture.map,
          layer: layer.copyWith(
            patternStrokes: [
              ...layer.patternStrokes,
              rasterStroke.copyWith(id: 'covering-raster'),
            ],
          ),
        );
        view.selectTerrainPattern(fixture.pattern);
        view.tool = StudioMapTool.erase;
        expect(
          MapCanvasStroke.start(
            map: covered,
            project: project,
            view: view,
            commands: MapEditingCommands(document, project),
            origin: const GridPos(x: 3, y: 3),
          ),
          isNull,
        );
      },
    );
  }
}
