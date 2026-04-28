import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Surface runtime playable host smoke', () {
    test(
      'loads a disk Surface project through RuntimeMapGame and renders animated pixels',
      () async {
        final fixture = await _SurfaceHostFixture.create(
          includePlayerSpawn: false,
        );
        addTearDown(fixture.dispose);

        final bundle = await loadRuntimeMapBundle(
          projectFilePath: fixture.projectFilePath,
          mapId: 'surface-host-test',
        );

        expect(bundle.map.layers.whereType<SurfaceLayer>(), hasLength(1));
        expect(bundle.manifest.surfaceCatalog.presets.single.id, 'water');
        expect(
          bundle.tilesetAbsolutePathsById,
          containsPair('surface-water', fixture.surfaceTilesetPath),
        );

        final game = RuntimeMapGame(bundle: bundle);
        game.onGameResize(Vector2(32, 32));
        await game.onLoad();

        expect(game.world.children.whereType<MapLayersComponent>(), hasLength(1));

        final firstFrame = await _renderRuntimeMapSurface(game);
        expect(await _pixelAt(firstFrame, 16, 16), _rgba(255, 0, 0, 255));

        game.update(0.1);
        final secondFrame = await _renderRuntimeMapSurface(game);
        expect(await _pixelAt(secondFrame, 16, 16), _rgba(0, 0, 255, 255));
      },
    );

    test(
      'PlayableMapGame starts and ticks with a disk SurfaceLayer project',
      () async {
        final fixture = await _SurfaceHostFixture.create(
          includePlayerSpawn: true,
        );
        addTearDown(fixture.dispose);

        final bundle = await loadRuntimeMapBundle(
          projectFilePath: fixture.projectFilePath,
          mapId: 'surface-host-test',
        );
        final game = PlayableMapGame(
          bundle: bundle,
          projectFilePath: fixture.projectFilePath,
        );

        game.onGameResize(Vector2(64, 32));
        await game.onLoad();
        game.update(0.1);

        expect(game.gameStateSnapshot.currentMapId, 'surface-host-test');
        expect(game.debugFlowPhaseName, 'overworld');
      },
    );
  });
}

class _SurfaceHostFixture {
  _SurfaceHostFixture({
    required this.root,
    required this.projectFilePath,
    required this.surfaceTilesetPath,
  });

  final Directory root;
  final String projectFilePath;
  final String surfaceTilesetPath;

  static Future<_SurfaceHostFixture> create({
    required bool includePlayerSpawn,
  }) async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_surface_host_smoke_',
    );
    final surfaceTilesetPath = await _writeSurfaceTilesetPng(root);
    final manifest = _surfaceProjectManifest();
    final map = _surfaceMap(includePlayerSpawn: includePlayerSpawn);
    final projectFilePath = await _writeProjectJson(root, manifest);
    await _writeMapJson(root, map);

    return _SurfaceHostFixture(
      root: root,
      projectFilePath: projectFilePath,
      surfaceTilesetPath: p.normalize(surfaceTilesetPath),
    );
  }

  Future<void> dispose() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }
}

Future<String> _writeSurfaceTilesetPng(Directory projectRoot) async {
  final tilesetFile = File(
    p.join(projectRoot.path, 'assets', 'tilesets', 'surface-water.png'),
  );
  await tilesetFile.parent.create(recursive: true);

  // A real two-frame PNG keeps this test close to the playable host pipeline:
  // the runtime must resolve a project-relative path, decode the image, then
  // let the Surface renderer advance from red to blue through its normal tick.
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
    name: 'Surface Runtime Playable Host Smoke',
    maps: const [
      ProjectMapEntry(
        id: 'surface-host-test',
        name: 'Surface Host Test',
        relativePath: 'maps/surface-host-test.json',
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

MapData _surfaceMap({required bool includePlayerSpawn}) {
  return MapData(
    id: 'surface-host-test',
    name: 'Surface Host Test',
    size: const GridSize(width: 1, height: 1),
    layers: const [
      MapLayer.surface(
        id: 'surfaces',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
        ],
      ),
    ],
    entities: includePlayerSpawn
        ? const [
            MapEntity(
              id: 'player-start',
              name: 'Player Start',
              kind: MapEntityKind.spawn,
              pos: GridPos(x: 0, y: 0),
              blocksMovement: false,
              spawn: MapEntitySpawnData(
                role: EntitySpawnRole.playerStart,
                facing: EntityFacing.south,
              ),
            ),
          ]
        : const [],
    mapMetadata: includePlayerSpawn
        ? const MapMetadata(defaultSpawnId: 'player-start')
        : const MapMetadata(),
  );
}

Future<String> _writeProjectJson(
  Directory projectRoot,
  ProjectManifest manifest,
) async {
  final projectFile = File(p.join(projectRoot.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return p.normalize(projectFile.path);
}

Future<void> _writeMapJson(Directory projectRoot, MapData map) async {
  final mapFile = File(
    p.join(projectRoot.path, 'maps', 'surface-host-test.json'),
  );
  await mapFile.parent.create(recursive: true);
  await mapFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(map.toJson()),
  );
}

Future<ui.Image> _renderRuntimeMapSurface(RuntimeMapGame game) {
  final component = game.world.children.whereType<MapLayersComponent>().single;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  // Rendering the mounted MapLayersComponent keeps the smoke deterministic in
  // a headless test while still proving that RuntimeMapGame performed the real
  // runtime image loading and component mount. Full GameWidget/camera rendering
  // is intentionally left out because it is covered by Flutter/Flame lifecycle
  // integration rather than the Surface asset pipeline itself.
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
