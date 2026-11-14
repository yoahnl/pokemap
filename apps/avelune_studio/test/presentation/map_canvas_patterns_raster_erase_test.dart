import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_canvas_patterns_fixtures.dart';

void main() {
  for (final animated in [false, true]) {
    for (final bottomToTop in [false, true]) {
      for (final coveredByEmptyStroke in [false, true]) {
        test(
          'native raster erase targets ${animated ? "animation" : "frame"} parts with ${bottomToTop ? "back-first" : "front-first"} layers and ${coveredByEmptyStroke ? "overlapping" : "single"} stamps',
          () {
            final fixture = patternFixture(spatial: false);
            final frame =
                (fixture.pattern.cells.first.parts.first.source
                        as SmartTileFrameSource)
                    .frame;
            final pattern = fixture.pattern.copyWith(
              cells: [
                for (final cell in fixture.pattern.cells)
                  cell.copyWith(
                    parts: [
                      SmartTileVisualPart(
                        source: animated
                            ? SmartTileVisualSource.animation(
                                animationId: 'raster-animation',
                              )
                            : SmartTileVisualSource.frame(frame: frame),
                      ),
                    ],
                  ),
              ],
            );
            final sparse = pattern.copyWith(
              id: 'sparse-raster',
              cells: [pattern.cells.first],
            );
            final project = fixture.project.copyWith(
              version: ProjectVersion.v9,
              settings: fixture.project.settings.copyWith(
                dimension: ProjectDimension.threeD,
                spatialCamera: SpatialCameraProfile(),
              ),
              smartTileCatalog: ProjectSmartTileCatalog(
                atlases: fixture.project.smartTileCatalog.atlases,
                materials: fixture.project.smartTileCatalog.materials,
                presets: fixture.project.smartTileCatalog.presets,
                patterns: [pattern, sparse],
                animations: [
                  if (animated)
                    ProjectSmartTileAnimation(
                      id: 'raster-animation',
                      name: 'Sol animé',
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
            final lower = fixture.map.layers.whereType<SmartTileLayer>().single;
            final upper = lower.copyWith(
              id: 'raster-layer',
              patternStrokes: [
                if (coveredByEmptyStroke) ...lower.patternStrokes,
                lower.patternStrokes.single.copyWith(
                  id: 'sparse-raster-stroke',
                  patternId: sparse.id,
                ),
              ],
            );
            final source = fixture.map.copyWith(
              version: ProjectVersion.v9,
              spatialScene: MapSpatialScene(width: 8, depth: 8),
              properties: bottomToTop
                  ? {'tileLayerOrder': 'bottom_to_top'}
                  : {},
              layers: bottomToTop ? [lower, upper] : [upper, lower],
            );
            final document = EditableMapDocument(
              MapWorkspaceDocument(
                map: source,
                mapId: source.id,
                revision: 'r0',
              ),
            );
            final view = MapEditingViewportSession()
              ..tool = StudioMapTool.erase;
            addTearDown(view.dispose);
            final commands = MapEditingCommands(document, project);
            final emptyUpperStroke = MapCanvasStroke.start(
              map: source,
              project: project,
              view: view,
              commands: commands,
              origin: const GridPos(x: 4, y: 2),
            );
            expect(emptyUpperStroke, isNotNull);
            expect(emptyUpperStroke!.buffer.layerId, lower.id);
            expect(
              emptyUpperStroke.commit().layers.firstWhere(
                (layer) => layer.id == upper.id,
              ),
              upper,
            );
            final stroke = MapCanvasStroke.start(
              map: source,
              project: project,
              view: view,
              commands: commands,
              origin: const GridPos(x: 3, y: 2),
            );
            expect(stroke, isNotNull);
            expect(stroke!.buffer.layerId, upper.id);
            expect(document.current, same(source));
            final erased = stroke.commit();
            expect(
              erased.layers.firstWhere((layer) => layer.id == lower.id),
              lower,
            );
            final erasedUpper = erased.layers
                .whereType<SmartTileLayer>()
                .firstWhere((layer) => layer.id == upper.id);
            for (final remaining in erasedUpper.patternStrokes) {
              expect(remaining.cells, [
                const GridPos(x: 2, y: 2),
                const GridPos(x: 4, y: 2),
                const GridPos(x: 5, y: 2),
              ]);
            }
            expect(erasedUpper.field, upper.field);
            expect(erased.spatialScene, source.spatialScene);
            document.commit(erased);
            expect(document.undoCount, 1);
            document.restore(redo: false);
            expect(document.current, source);
          },
        );
      }
    }
  }
}
