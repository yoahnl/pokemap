import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tall_grass_tsx_asset_importer.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';
import 'package:path/path.dart' as p;

void main() {
  group('importTallGrassTsxAssets', () {
    test('links the TSX image as a project tileset and imports animations', () {
      final sdkProject = _sdkProject();
      final loaded = _loadSdkTsx('TECH-Animations.tsx');

      final result = importTallGrassTsxAssets(
        manifest: _manifest(tilesets: const []),
        projectRootPath: sdkProject.path,
        loadedFile: loaded,
      );

      expect(result.errors, isEmpty);
      expect(result.manifest, isNotNull);
      expect(result.createdTileset, isTrue);
      expect(result.tileset?.id, 'tech-nature-animations');
      expect(
        result.tileset?.relativePath,
        'Data/Tiled/Assets/TECH-Nature-animations.png',
      );
      expect(result.importedAnimationCount, 242);
      expect(result.candidateAnimationIds, hasLength(242));
      expect(result.candidateAnimationIds, contains('tech-animations-tile-99'));

      final manifest = result.manifest!;
      expect(manifest.tilesets, hasLength(1));
      expect(manifest.surfaceCatalog.atlasCount, 1);
      expect(manifest.surfaceCatalog.animationCount, 242);
      expect(
        manifest.surfaceCatalog.containsAtlas('tech-animations'),
        isTrue,
      );
    });

    test('reuses an existing matching project tileset by basename', () {
      final loaded = _loadSdkTsx('TECH-Animations.tsx');

      final result = importTallGrassTsxAssets(
        manifest: _manifest(
          tilesets: const [
            ProjectTilesetEntry(
              id: 'existing-tech-animations',
              name: 'Existing TECH Animations',
              relativePath: 'Data/Tiled/Assets/TECH-Nature-animations.png',
            ),
          ],
        ),
        projectRootPath: null,
        loadedFile: loaded,
      );

      expect(result.errors, isEmpty);
      expect(result.createdTileset, isFalse);
      expect(result.tileset?.id, 'existing-tech-animations');
      expect(result.manifest?.tilesets, hasLength(1));
      expect(result.manifest?.surfaceCatalog.animationCount, 242);
    });

    test('imports TECH-Nature as the static tall grass visual source', () {
      final sdkProject = _sdkProject();
      final loaded = _loadSdkTsx('TECH-Nature.tsx');

      final result = importTallGrassTsxAssets(
        manifest: _manifest(tilesets: const []),
        projectRootPath: sdkProject.path,
        loadedFile: loaded,
      );

      expect(result.errors, isEmpty);
      expect(result.manifest, isNotNull);
      expect(result.createdTileset, isTrue);
      expect(result.tileset?.id, 'tech-nature');
      expect(result.tileset?.relativePath, 'Data/Tiled/Assets/TECH-Nature.png');
      expect(result.importedAnimationCount, 0);
      expect(result.visualCandidateTileIds, hasLength(34));
      expect(result.visualCandidateTileIds, containsAll([433, 629, 772]));
      expect(result.sdkParticleTags, containsAll([1, 2]));

      final manifest = result.manifest!;
      expect(manifest.surfaceCatalog.atlasCount, 1);
      expect(manifest.surfaceCatalog.animationCount, 0);
      expect(manifest.surfaceCatalog.containsAtlas('hgss-nature'), isTrue);
      expect(
        result.messages,
        contains(
          'Import hautes herbes prêt : atlas statique lié, 34 tuiles candidates extraites.',
        ),
      );
      expect(
        result.messages,
        contains(
          'Particules SDK : TGrass -> 1, TTallGrass -> 2.',
        ),
      );
    });

    test('copies the TSX image into the project when it starts outside root',
        () {
      final loaded = _loadSdkTsx('TECH-Animations.tsx');
      final projectRoot = Directory.systemTemp.createTempSync(
        'pokemap_tall_grass_import_',
      );
      addTearDown(() {
        if (projectRoot.existsSync()) {
          projectRoot.deleteSync(recursive: true);
        }
      });

      final result = importTallGrassTsxAssets(
        manifest: _manifest(tilesets: const []),
        projectRootPath: projectRoot.path,
        loadedFile: loaded,
      );

      expect(result.errors, isEmpty);
      expect(result.manifest, isNotNull);
      expect(result.tileset?.relativePath,
          'assets/tilesets/tech-nature-animations.png');
      expect(
        File(p.join(projectRoot.path, result.tileset!.relativePath))
            .existsSync(),
        isTrue,
      );
      expect(result.importedAnimationCount, 242);
      expect(
        result.messages,
        contains(
          'Image TSX copiée dans le projet : assets/tilesets/tech-nature-animations.png.',
        ),
      );
    });

    test('imports TSX data when the image copy is refused', () {
      final loaded = _loadSdkTsx('TECH-Animations.tsx');
      final projectRoot = Directory.systemTemp.createTempSync(
        'pokemap_tall_grass_import_blocked_',
      );
      addTearDown(() {
        if (projectRoot.existsSync()) {
          projectRoot.deleteSync(recursive: true);
        }
      });
      File(p.join(projectRoot.path, 'assets')).writeAsStringSync('blocked');

      final result = importTallGrassTsxAssets(
        manifest: _manifest(tilesets: const []),
        projectRootPath: projectRoot.path,
        loadedFile: loaded,
      );

      expect(result.errors, isEmpty);
      expect(result.manifest, isNotNull);
      expect(result.tileset?.relativePath,
          'assets/tilesets/tech-nature-animations.png');
      expect(result.importedAnimationCount, 242);
      expect(
        File(p.join(projectRoot.path, result.tileset!.relativePath))
            .existsSync(),
        isFalse,
      );
      expect(
        result.messages,
        contains(startsWith('Image TSX non copiée dans le projet')),
      );
    });
  });
}

ProjectManifest _manifest({
  required List<ProjectTilesetEntry> tilesets,
}) {
  return ProjectManifest(
    name: 'Test',
    maps: const [],
    tilesets: tilesets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

TiledTsxLoadedFile _loadSdkTsx(String fileName) {
  final file = File(
    p.join(_sdkProject().path, 'Data', 'Tiled', 'Tilesets', fileName),
  );
  return TiledTsxLoadedFile(
    path: file.path,
    fileName: fileName,
    xml: file.readAsStringSync(),
  );
}

Directory _sdkProject() {
  final repoRoot = Directory.current.parent.parent;
  return repoRoot
      .listSync()
      .whereType<Directory>()
      .firstWhere((dir) => p.basename(dir.path).contains('sdk_test_project'));
}
