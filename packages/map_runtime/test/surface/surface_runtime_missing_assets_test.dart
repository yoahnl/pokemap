import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:path/path.dart' as p;

import 'surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Surface runtime missing asset hardening', () {
    test('skips missing Surface tileset image and keeps other layers rendering',
        () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [
              surfaceTestLayer(),
              const MapLayer.tile(
                id: 'tile',
                name: 'Tile',
                tilesetId: 'base',
                tiles: [1],
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'base': await runtimeTilesetImage([const Color(0xFFFF0000)]),
        },
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
    });

    test('skips incomplete Surface catalog references without debug fallback',
        () async {
      final cases = <String, ProjectSurfaceCatalog>{
        'missing preset': surfaceTestCatalog(includePreset: false),
        'missing animation': surfaceTestCatalog(includeAnimation: false),
        'missing atlas': surfaceTestCatalog(includeAtlas: false),
        'source outside atlas': surfaceTestCatalog(
          atlasColumns: 1,
          sourceColumn: 2,
        ),
      };

      for (final entry in cases.entries) {
        final component = MapLayersComponent(
          bundle: surfaceTestBundle(
            surfaceCatalog: entry.value,
            map: surfaceTestMap(layers: [surfaceTestLayer()]),
          ),
          tileImagesByTilesetId: {
            'surface-water':
                await runtimeTilesetImage([const Color(0xFFFFFF00)]),
          },
        );

        final image = await renderSurfaceTestComponent(component);

        expect(
          await pixelAt(image, 16, 16),
          rgba(0, 0, 0, 0),
          reason: entry.key,
        );
      }
    });

    test('reports a controlled error when manifest omits a required tileset',
        () async {
      final projectRoot =
          await Directory.systemTemp.createTemp('pokemap_surface_missing_');
      addTearDown(() async {
        if (await projectRoot.exists()) {
          await projectRoot.delete(recursive: true);
        }
      });
      await _writeDiskProject(
        projectRoot,
        tilesets: const <ProjectTilesetEntry>[],
      );

      expect(
        () => loadRuntimeMapBundle(
          projectFilePath: p.join(projectRoot.path, 'project.json'),
          mapId: 'surface-test',
        ),
        throwsA(isA<AssetNotFoundException>()),
      );
    });

    test('reports a controlled error when the Surface PNG is missing',
        () async {
      final projectRoot =
          await Directory.systemTemp.createTemp('pokemap_surface_missing_png_');
      addTearDown(() async {
        if (await projectRoot.exists()) {
          await projectRoot.delete(recursive: true);
        }
      });
      await _writeDiskProject(
        projectRoot,
        tilesets: const [
          ProjectTilesetEntry(
            id: 'surface-water',
            name: 'Surface Water',
            relativePath: 'assets/tilesets/missing-water.png',
          ),
        ],
      );

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: p.join(projectRoot.path, 'project.json'),
        mapId: 'surface-test',
      );

      expect(
        () => loadTilesetImagesById(bundle.tilesetAbsolutePathsById),
        throwsA(isA<AssetNotFoundException>()),
      );
    });
  });
}

Future<void> _writeDiskProject(
  Directory projectRoot, {
  required List<ProjectTilesetEntry> tilesets,
}) async {
  await _writeProjectJson(
    projectRoot,
    ProjectManifest(
      name: 'Surface Missing Asset Test',
      maps: const [
        ProjectMapEntry(
          id: 'surface-test',
          name: 'Surface Test',
          relativePath: 'maps/surface-test.json',
        ),
      ],
      tilesets: tilesets,
      settings: const ProjectSettings(
        tileWidth: surfaceTestTileSize,
        tileHeight: surfaceTestTileSize,
        displayScale: 1,
      ),
      surfaceCatalog: surfaceTestCatalog(),
    ),
  );
  await _writeMapJson(
    projectRoot,
    surfaceTestMap(layers: [surfaceTestLayer()]),
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
