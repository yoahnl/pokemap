import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Surface runtime golden slice', () {
    test(
      'loads a disk project and renders an animated SurfaceLayer pixel',
      () async {
        final projectRoot =
            await Directory.systemTemp.createTemp('pokemap_surface_runtime_');
        addTearDown(() async {
          if (await projectRoot.exists()) {
            await projectRoot.delete(recursive: true);
          }
        });

        final tilesetPath = await _writeSurfaceTilesetPng(projectRoot);
        final manifest = _surfaceProjectManifest();
        final map = _surfaceMap();
        await _writeProjectJson(projectRoot, manifest);
        await _writeMapJson(projectRoot, map);

        final bundle = await loadRuntimeMapBundle(
          projectFilePath: p.join(projectRoot.path, 'project.json'),
          mapId: 'surface-test',
        );

        expect(bundle.projectRootDirectory, p.normalize(projectRoot.path));
        expect(bundle.manifest.surfaceCatalog.presets.single.id, 'water');
        expect(bundle.map.layers.whereType<SurfaceLayer>(), hasLength(1));
        expect(
          bundle.tilesetAbsolutePathsById,
          containsPair('surface-water', p.normalize(tilesetPath)),
        );

        final tileImages = await loadTilesetImagesById(
          bundle.tilesetAbsolutePathsById,
        );
        expect(tileImages, contains('surface-water'));

        final component = MapLayersComponent(
          bundle: bundle,
          tileImagesByTilesetId: tileImages,
        );

        final firstFrame = await _renderComponent(component);
        expect(await _pixelAt(firstFrame, 16, 16), _rgba(255, 0, 0, 255));

        component.update(0.1);
        final secondFrame = await _renderComponent(component);
        expect(await _pixelAt(secondFrame, 16, 16), _rgba(0, 0, 255, 255));
      },
    );
  });
}

Future<String> _writeSurfaceTilesetPng(Directory projectRoot) async {
  final tilesetFile = File(
    p.join(projectRoot.path, 'assets', 'tilesets', 'surface-water.png'),
  );
  await tilesetFile.parent.create(recursive: true);

  // The PNG is intentionally tiny but real: two 32x32 frames in one row. This
  // keeps the test independent from repository assets while still exercising
  // Flutter's image decoder and RuntimeTilesetImage loader.
  final image = img.Image(width: 64, height: 32);
  for (var y = 0; y < 32; y++) {
    for (var x = 0; x < 64; x++) {
      image.setPixel(
        x,
        y,
        x < 32
            ? img.ColorRgba8(255, 0, 0, 255)
            : img.ColorRgba8(0, 0, 255, 255),
      );
    }
  }
  await tilesetFile.writeAsBytes(img.encodePng(image, level: 0));
  return p.normalize(tilesetFile.path);
}

ProjectManifest _surfaceProjectManifest() {
  return ProjectManifest(
    name: 'Surface Runtime Golden Slice',
    maps: const [
      ProjectMapEntry(
        id: 'surface-test',
        name: 'Surface Test',
        relativePath: 'maps/surface-test.json',
      ),
    ],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'surface-water',
        name: 'Surface Water',
        relativePath: 'assets/tilesets/surface-water.png',
      ),
    ],
    settings: const ProjectSettings(
      tileWidth: 32,
      tileHeight: 32,
      displayScale: 1,
    ),
    surfaceCatalog: ProjectSurfaceCatalog(
      atlases: [
        ProjectSurfaceAtlas(
          id: 'water-atlas',
          name: 'Water Atlas',
          tilesetId: 'surface-water',
          geometry: SurfaceAtlasGeometry(
            tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
            gridSize: SurfaceAtlasGridSize(columns: 2, rows: 1),
          ),
        ),
      ],
      animations: [
        ProjectSurfaceAnimation(
          id: 'water-loop',
          name: 'Water Loop',
          timeline: SurfaceAnimationTimeline(
            frames: [
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: 'water-atlas',
                  column: 0,
                  row: 0,
                ),
                durationMs: 100,
              ),
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: 'water-atlas',
                  column: 1,
                  row: 0,
                ),
                durationMs: 100,
              ),
            ],
          ),
        ),
      ],
      presets: [
        ProjectSurfacePreset(
          id: 'water',
          name: 'Water',
          variantAnimations: SurfaceVariantAnimationRefSet(
            refs: [
              SurfaceVariantAnimationRef(
                role: SurfaceVariantRole.isolated,
                animationId: 'water-loop',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

MapData _surfaceMap() {
  return const MapData(
    id: 'surface-test',
    name: 'Surface Test',
    size: GridSize(width: 1, height: 1),
    layers: [
      MapLayer.surface(
        id: 'surfaces',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
        ],
      ),
    ],
  );
}

Future<void> _writeProjectJson(
  Directory projectRoot,
  ProjectManifest manifest,
) async {
  final projectFile = File(p.join(projectRoot.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
}

Future<void> _writeMapJson(Directory projectRoot, MapData map) async {
  final mapFile = File(p.join(projectRoot.path, 'maps', 'surface-test.json'));
  await mapFile.parent.create(recursive: true);
  await mapFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(map.toJson()),
  );
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
