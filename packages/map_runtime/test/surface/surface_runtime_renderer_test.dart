import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapLayersComponent Surface runtime rendering', () {
    test('draws a visible SurfaceLayer in the background pass', () async {
      final component = MapLayersComponent(
        bundle: _bundle(
          layer: const SurfaceLayer(
            id: 'surface',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await _runtimeTilesetImage([
            const Color(0xFFFF0000),
            const Color(0xFF0000FF),
          ]),
        },
      );

      final image = await _renderComponent(component);

      expect(await _pixelAt(image, 16, 16), _rgba(255, 0, 0, 255));
    });

    test('uses _animElapsed to render the current Surface animation frame',
        () async {
      final component = MapLayersComponent(
        bundle: _bundle(
          layer: const SurfaceLayer(
            id: 'surface',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await _runtimeTilesetImage([
            const Color(0xFFFF0000),
            const Color(0xFF0000FF),
          ]),
        },
      )..update(0.1);

      final image = await _renderComponent(component);

      expect(await _pixelAt(image, 16, 16), _rgba(0, 0, 255, 255));
    });

    test('does not draw SurfaceLayer in the foreground pass', () async {
      final component = MapLayersComponent(
        bundle: _bundle(
          layer: const SurfaceLayer(
            id: 'surface',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await _runtimeTilesetImage([
            const Color(0xFFFF0000),
            const Color(0xFF0000FF),
          ]),
        },
        renderPass: MapLayerRenderPass.foreground,
      );

      final image = await _renderComponent(component);

      expect(await _pixelAt(image, 16, 16), _rgba(0, 0, 0, 0));
    });

    test('skips missing tileset images and invalid source rects without crash',
        () async {
      final missingImage = MapLayersComponent(
        bundle: _bundle(
          layer: const SurfaceLayer(
            id: 'surface',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
            ],
          ),
        ),
        tileImagesByTilesetId: const {},
      );

      final missingImageFrame = await _renderComponent(missingImage);
      expect(await _pixelAt(missingImageFrame, 16, 16), _rgba(0, 0, 0, 0));

      final invalidSource = MapLayersComponent(
        bundle: _bundle(
          layer: const SurfaceLayer(
            id: 'surface',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'outside'),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water':
              await _runtimeTilesetImage([const Color(0xFFFF0000)]),
        },
      );

      final invalidSourceFrame = await _renderComponent(invalidSource);
      expect(await _pixelAt(invalidSourceFrame, 16, 16), _rgba(0, 0, 0, 0));
    });

    test('skips invisible SurfaceLayer and opacity zero SurfaceLayer',
        () async {
      final invisible = MapLayersComponent(
        bundle: _bundle(
          layer: const SurfaceLayer(
            id: 'surface',
            name: 'Surfaces',
            isVisible: false,
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water':
              await _runtimeTilesetImage([const Color(0xFFFF0000)]),
        },
      );
      expect(
        await _pixelAt(await _renderComponent(invisible), 16, 16),
        _rgba(0, 0, 0, 0),
      );

      final transparent = MapLayersComponent(
        bundle: _bundle(
          layer: const SurfaceLayer(
            id: 'surface',
            name: 'Surfaces',
            opacity: 0,
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water':
              await _runtimeTilesetImage([const Color(0xFFFF0000)]),
        },
      );
      expect(
        await _pixelAt(await _renderComponent(transparent), 16, 16),
        _rgba(0, 0, 0, 0),
      );
    });
  });
}

RuntimeMapBundle _bundle({required SurfaceLayer layer}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Surface Runtime',
      maps: const [],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'surface-water',
          name: 'Surface Water',
          relativePath: 'tilesets/water.png',
        ),
      ],
      settings: const ProjectSettings(
        tileWidth: 32,
        tileHeight: 32,
        displayScale: 1,
      ),
      surfaceCatalog: ProjectSurfaceCatalog(
        atlases: [
          _atlas(
            id: 'water-atlas',
            tilesetId: 'surface-water',
            columns: 2,
          ),
        ],
        animations: [
          _animation(
            id: 'water-loop',
            frames: [
              _frame(atlasId: 'water-atlas', column: 0, durationMs: 100),
              _frame(atlasId: 'water-atlas', column: 1, durationMs: 100),
            ],
          ),
          _animation(
            id: 'outside-loop',
            frames: [
              _frame(atlasId: 'water-atlas', column: 3, durationMs: 100),
            ],
          ),
        ],
        presets: [
          _preset(id: 'water', animationId: 'water-loop'),
          _preset(id: 'outside', animationId: 'outside-loop'),
        ],
      ),
    ),
    map: MapData(
      id: 'route-1',
      name: 'Route 1',
      size: const GridSize(width: 1, height: 1),
      layers: [layer],
    ),
    projectRootDirectory: '/tmp/project',
    tilesetAbsolutePathsById: const {},
  );
}

ProjectSurfaceAtlas _atlas({
  required String id,
  required String tilesetId,
  int columns = 1,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: id,
    tilesetId: tilesetId,
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: columns, rows: 1),
    ),
  );
}

ProjectSurfaceAnimation _animation({
  required String id,
  required List<SurfaceAnimationFrame> frames,
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(frames: frames),
  );
}

SurfaceAnimationFrame _frame({
  required String atlasId,
  required int column,
  required int durationMs,
}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: atlasId, column: column, row: 0),
    durationMs: durationMs,
  );
}

ProjectSurfacePreset _preset({
  required String id,
  required String animationId,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: id,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: animationId,
        ),
      ],
    ),
  );
}

Future<RuntimeTilesetImage> _runtimeTilesetImage(List<Color> colors) async {
  final image = await _tilesetImage(colors);
  return RuntimeTilesetImage(
    images: [image],
    chunks: [
      RuntimeTilesetChunk(top: 0, height: 32, width: colors.length * 32),
    ],
    width: colors.length * 32,
    height: 32,
  );
}

Future<ui.Image> _tilesetImage(List<Color> colors) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (var i = 0; i < colors.length; i++) {
    canvas.drawRect(
      Rect.fromLTWH((i * 32).toDouble(), 0, 32, 32),
      Paint()..color = colors[i],
    );
  }
  return recorder.endRecording().toImage(colors.length * 32, 32);
}

Future<ui.Image> _renderComponent(MapLayersComponent component) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(32, 32);
}

Future<List<int>> _pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return [
    data!.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}

List<int> _rgba(int red, int green, int blue, int alpha) {
  return [red, green, blue, alpha];
}
