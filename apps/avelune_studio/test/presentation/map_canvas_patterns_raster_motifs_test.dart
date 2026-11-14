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
  for (final large in [false, true]) {
    test(
      '${large ? "large source" : "repeat"} 3D motif retains region erasure',
      () {
        final fixture = atomicStampFixture();
        final pattern = fixture.pattern.copyWith(
          width: large ? 57 : 3,
          height: large ? 36 : 3,
          repeatMode: large
              ? SmartTilePatternRepeatMode.stamp
              : SmartTilePatternRepeatMode.tiled,
        );
        final project = withStampPatterns(fixture.project, [pattern]);
        final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
        final document = EditableMapDocument(
          MapWorkspaceDocument(
            map: fixture.map,
            mapId: fixture.map.id,
            revision: 'r0',
          ),
        );
        final view = selectedStampEraseView(fixture.preset, pattern);
        addTearDown(view.dispose);
        final stroke = MapCanvasStroke.start(
          map: fixture.map,
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
        expect(
          erased.patternStrokes.single.cells,
          hasLength(layer.patternStrokes.single.cells.length - 1),
        );
        expect(erased.field, layer.field);
      },
    );
  }

  for (final animated in [false, true]) {
    test(
      '3D raster ${animated ? "animation" : "frame"} motifs paint native strokes and only expose visible ground channels',
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
            patterns: [pattern],
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
        final source = fixture.map.copyWith(
          version: ProjectVersion.v9,
          spatialScene: MapSpatialScene(width: 8, depth: 8),
          layers: [
            fixture.map.layers.whereType<SmartTileLayer>().single.copyWith(
              field: SmartTileField.cell(semanticCells: List.filled(64, 1)),
              patternStrokes: [],
            ),
          ],
        );
        for (final channel in SmartTileRenderChannel.values) {
          final candidate = pattern.copyWith(
            cells: [
              for (final cell in pattern.cells)
                cell.copyWith(
                  parts: [
                    for (final part in cell.parts)
                      part.copyWith(channel: channel),
                  ],
                ),
            ],
          );
          expect(
            availableTerrainPatterns(
              project: project.copyWith(
                smartTileCatalog: ProjectSmartTileCatalog(
                  atlases: project.smartTileCatalog.atlases,
                  materials: project.smartTileCatalog.materials,
                  presets: project.smartTileCatalog.presets,
                  animations: project.smartTileCatalog.animations,
                  patterns: [candidate],
                ),
              ),
              map: source,
              preset: fixture.preset,
            ),
            channel == SmartTileRenderChannel.ground ||
                    channel == SmartTileRenderChannel.understory
                ? [candidate]
                : isEmpty,
          );
        }
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = MapEditingViewportSession()
          ..prepareTerrainPainting(fixture.preset)
          ..selectTerrainPattern(pattern);
        addTearDown(view.dispose);
        final stroke = MapCanvasStroke.start(
          map: source,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 1, y: 1),
        )!;
        expect(document.current, same(source));
        expect(
          stroke.preview.layers
              .whereType<SmartTileLayer>()
              .single
              .patternStrokes
              .single
              .patternId,
          pattern.id,
        );
        document.commit(stroke.commit());
        expect(document.current.spatialScene, source.spatialScene);
        expect(document.undoCount, 1);
        final painted = document.current;
        view.tool = StudioMapTool.erase;
        final erasing = MapCanvasStroke.start(
          map: painted,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 1, y: 1),
        )!;
        final erased = erasing.commit();
        final erasedLayer = erased.layers.whereType<SmartTileLayer>().single;
        expect(
          erasedLayer.field,
          source.layers.whereType<SmartTileLayer>().single.field,
        );
        expect(erasedLayer.patternStrokes.single.cells, [
          const GridPos(x: 2, y: 1),
        ]);
        expect(erased.spatialScene, source.spatialScene);
        document.commit(erased);
        expect(document.undoCount, 2);
        document.restore(redo: false);
        expect(document.current, painted);
        document.restore(redo: false);
        expect(document.current, source);
        final privateProject = project.copyWith(
          resourceLibraryCatalog: ResourceLibraryCatalog(
            entries: [
              ResourceLibraryEntry(
                resourceKind: 'tileset',
                resourceId: project.smartTileCatalog.atlases.single.tilesetId,
                mapId: 'other-map',
              ),
            ],
          ),
        );
        expect(
          availableTerrainPatterns(
            project: privateProject,
            map: source,
            preset: fixture.preset,
          ),
          isEmpty,
        );
      },
    );
  }
}
