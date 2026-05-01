import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapLayersComponent PathPattern runtime render', () {
    test('render path runtime utilise le centerPattern 2x2', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: MapData(
            id: 'path-pattern-map',
            name: 'Path Pattern Map',
            size: const GridSize(width: 2, height: 2),
            layers: const [
              MapLayer.path(
                id: 'path',
                name: 'Path',
                presetId: 'water-base',
                cells: [true, true, true, true],
              ),
            ],
          ),
          pathPresets: const [
            ProjectPathPreset(
              id: 'water-base',
              name: 'Water Base',
              tilesetId: 'base',
              variants: [],
            ),
          ],
        ).copyWithManifestPathPatterns([
          ProjectPathPatternPreset(
            id: 'water-pattern',
            name: 'Water Pattern',
            basePathPresetId: 'water-base',
            centerPattern: PathCenterPattern(
              size: PathCenterPatternSize(width: 2, height: 2),
              cells: [
                PathCenterPatternCell(
                  localX: 0,
                  localY: 0,
                  frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
                ),
                PathCenterPatternCell(
                  localX: 1,
                  localY: 0,
                  frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0))],
                ),
                PathCenterPatternCell(
                  localX: 0,
                  localY: 1,
                  frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 2, y: 0))],
                ),
                PathCenterPatternCell(
                  localX: 1,
                  localY: 1,
                  frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 0))],
                ),
              ],
            ),
          ),
        ]),
        tileImagesByTilesetId: {
          'base': await runtimeTilesetImage(const [
            Color(0xFFFF0000),
            Color(0xFF00FF00),
            Color(0xFF0000FF),
            Color(0xFFFFFF00),
          ]),
        },
      );

      final image = await _renderComponent(component, 64, 64);

      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
      expect(await pixelAt(image, 48, 16), rgba(0, 255, 0, 255));
      expect(await pixelAt(image, 16, 48), rgba(0, 0, 255, 255));
      expect(await pixelAt(image, 48, 48), rgba(255, 255, 0, 255));
    });

    test('centerPattern animé change de frame selon elapsedMs', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: MapData(
            id: 'path-pattern-animated-map',
            name: 'Path Pattern Animated Map',
            size: const GridSize(width: 1, height: 1),
            layers: const [
              MapLayer.path(
                id: 'path',
                name: 'Path',
                presetId: 'water-base',
                cells: [true],
              ),
            ],
          ),
          pathPresets: const [
            ProjectPathPreset(
              id: 'water-base',
              name: 'Water Base',
              tilesetId: 'base',
              variants: [],
            ),
          ],
        ).copyWithManifestPathPatterns([
          ProjectPathPatternPreset(
            id: 'water-pattern',
            name: 'Water Pattern',
            basePathPresetId: 'water-base',
            centerPattern: PathCenterPattern(
              size: PathCenterPatternSize(width: 1, height: 1),
              cells: [
                PathCenterPatternCell(
                  localX: 0,
                  localY: 0,
                  frames: [
                    TilesetVisualFrame(
                      source: TilesetSourceRect(x: 0, y: 0),
                      durationMs: 200,
                    ),
                    TilesetVisualFrame(
                      source: TilesetSourceRect(x: 1, y: 0),
                      durationMs: 200,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
        tileImagesByTilesetId: {
          'base': await runtimeTilesetImage(const [
            Color(0xFFFF0000),
            Color(0xFF0000FF),
          ]),
        },
      );

      final frame0 = await _renderComponent(component, 32, 32);
      expect(await pixelAt(frame0, 16, 16), rgba(255, 0, 0, 255));

      component.update(0.2);
      final frame1 = await _renderComponent(component, 32, 32);
      expect(await pixelAt(frame1, 16, 16), rgba(0, 0, 255, 255));
    });

    test('absence image tileset ne crashe pas le rendu path', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: MapData(
            id: 'path-pattern-no-image-map',
            name: 'Path Pattern No Image Map',
            size: const GridSize(width: 1, height: 1),
            layers: const [
              MapLayer.path(
                id: 'path',
                name: 'Path',
                presetId: 'water-base',
                cells: [true],
              ),
            ],
          ),
          pathPresets: const [
            ProjectPathPreset(
              id: 'water-base',
              name: 'Water Base',
              tilesetId: 'base',
              variants: [],
            ),
          ],
        ).copyWithManifestPathPatterns([
          ProjectPathPatternPreset(
            id: 'water-pattern',
            name: 'Water Pattern',
            basePathPresetId: 'water-base',
            centerPattern: PathCenterPattern(
              size: PathCenterPatternSize(width: 1, height: 1),
              cells: [
                PathCenterPatternCell(
                  localX: 0,
                  localY: 0,
                  frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
                ),
              ],
            ),
          ),
        ]),
        tileImagesByTilesetId: const {},
      );

      await expectLater(_renderComponent(component, 32, 32), completes);
    });
  });
}

extension on RuntimeMapBundle {
  RuntimeMapBundle copyWithManifestPathPatterns(
    List<ProjectPathPatternPreset> pathPatterns,
  ) {
    return RuntimeMapBundle(
      manifest: manifest.copyWith(pathPatternPresets: pathPatterns),
      map: map,
      projectRootDirectory: projectRootDirectory,
      tilesetAbsolutePathsById: tilesetAbsolutePathsById,
    );
  }
}

Future<ui.Image> _renderComponent(
  MapLayersComponent component,
  int width,
  int height,
) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(width, height);
}
