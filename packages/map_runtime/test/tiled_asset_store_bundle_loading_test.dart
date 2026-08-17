import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'support/project_manifest_test_support.dart';

void main() {
  test('runtime resolves imported atlas bytes from the canonical asset store',
      () async {
    final fixture = await _RuntimeAssetStoreFixture.create(
      catalogIncludesAsset: true,
      writeLegacyLogicalFile: false,
    );
    addTearDown(fixture.dispose);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: fixture.projectFile.path,
      mapId: 'imported',
    );

    expect(
      bundle.tilesetAbsolutePathsById['tiles'],
      p.join(fixture.root.path, assetBlobStorageKey(fixture.artifact)),
    );
    expect(
      await File(bundle.tilesetAbsolutePathsById['tiles']!).readAsBytes(),
      fixture.bytes,
    );
  });

  test('runtime preserves legacy logical paths when no catalog record exists',
      () async {
    final fixture = await _RuntimeAssetStoreFixture.create(
      catalogIncludesAsset: false,
      writeLegacyLogicalFile: true,
    );
    addTearDown(fixture.dispose);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: fixture.projectFile.path,
      mapId: 'imported',
    );

    expect(
      bundle.tilesetAbsolutePathsById['tiles'],
      p.join(fixture.root.path, 'assets', 'tiles.png'),
    );
  });

  test('runtime reports an invalid canonical asset catalog before playtest',
      () async {
    final fixture = await _RuntimeAssetStoreFixture.create(
      catalogIncludesAsset: true,
      writeLegacyLogicalFile: false,
    );
    addTearDown(fixture.dispose);
    await File(p.join(fixture.root.path, assetCatalogStorageKey))
        .writeAsString('{not-json');

    await expectLater(
      () => loadRuntimeMapBundle(
        projectFilePath: fixture.projectFile.path,
        mapId: 'imported',
      ),
      throwsA(
        isA<ProjectLoadException>().having(
          (error) => error.message,
          'message',
          contains('asset catalog'),
        ),
      ),
    );
  });
}

final class _RuntimeAssetStoreFixture {
  const _RuntimeAssetStoreFixture({
    required this.root,
    required this.projectFile,
    required this.artifact,
    required this.bytes,
  });

  final Directory root;
  final File projectFile;
  final ContentArtifactRef artifact;
  final List<int> bytes;

  static Future<_RuntimeAssetStoreFixture> create({
    required bool catalogIncludesAsset,
    required bool writeLegacyLogicalFile,
  }) async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap-runtime-asset-store-',
    );
    const bytes = <int>[1, 2, 3, 4];
    final artifact = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: 'image/png',
    );
    final projectFile = File(p.join(root.path, 'project.json'));
    final mapFile = File(p.join(root.path, 'maps', 'imported.json'));
    await mapFile.parent.create(recursive: true);
    const manifest = ProjectManifest(
      name: 'Runtime canonical asset fixture',
      version: ProjectVersion.v6,
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'imported',
          name: 'Imported',
          relativePath: 'maps/imported.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'tiles',
          name: 'Tiles',
          relativePath: 'assets/tiles.png',
          source: ProjectRegularAtlasTilesetSource(
            assetId: 'tiles-asset',
            pixelWidth: 1,
            pixelHeight: 1,
            tileWidth: 1,
            tileHeight: 1,
          ),
        ),
      ],
    );
    const map = MapData(
      id: 'imported',
      name: 'Imported',
      version: ProjectVersion.v6,
      size: GridSize(width: 1, height: 1),
      layers: <MapLayer>[
        TileLayer(
          id: 'ground',
          name: 'Ground',
          palette: <TileLayerPaletteEntry>[
            TileLayerPaletteEntry(tilesetId: 'tiles', localTileId: 0),
          ],
          cells: <int>[1],
        ),
      ],
    );
    await projectFile.writeAsString(
      jsonEncode(withPokeMapBetaPokemonRuleset(manifest.toJson())),
    );
    await mapFile.writeAsString(jsonEncode(map.toJson()));
    if (catalogIncludesAsset) {
      final catalog = AssetCatalog(
        records: <AssetRecord>[
          AssetRecord(
            id: 'tiles-asset',
            logicalPath: 'assets/tiles.png',
            artifact: artifact,
          ),
        ],
      );
      final catalogFile = File(p.join(root.path, assetCatalogStorageKey));
      await catalogFile.parent.create(recursive: true);
      await catalogFile.writeAsString(jsonEncode(catalog.toJson()));
      final blob = File(p.join(root.path, assetBlobStorageKey(artifact)));
      await blob.parent.create(recursive: true);
      await blob.writeAsBytes(bytes);
    }
    if (writeLegacyLogicalFile) {
      final legacy = File(p.join(root.path, 'assets', 'tiles.png'));
      await legacy.parent.create(recursive: true);
      await legacy.writeAsBytes(bytes);
    }
    return _RuntimeAssetStoreFixture(
      root: root,
      projectFile: projectFile,
      artifact: artifact,
      bytes: bytes,
    );
  }

  Future<void> dispose() => root.delete(recursive: true);
}
