import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_atlas_image_loader.dart';

void main() {
  group('FileSmartTileAtlasImageLoader', () {
    test('loads a project-relative image with its real dimensions', () async {
      final projectRoot = await Directory.systemTemp.createTemp(
        'smart_tile_atlas_loader_',
      );
      addTearDown(() => projectRoot.delete(recursive: true));
      final imageDirectory = Directory(
        '${projectRoot.path}${Platform.pathSeparator}assets',
      )..createSync(recursive: true);
      final imageFile = File(
        '${imageDirectory.path}${Platform.pathSeparator}terrain.png',
      );
      final source = img.Image(width: 96, height: 64, numChannels: 4);
      source.setPixelRgba(0, 0, 42, 88, 24, 255);
      await imageFile.writeAsBytes(img.encodePng(source));

      final result = await const FileSmartTileAtlasImageLoader().load(
        projectRootPath: projectRoot.path,
        tileset: const ProjectTilesetEntry(
          id: 'terrain',
          name: 'Terrain',
          relativePath: 'assets/terrain.png',
        ),
      );

      expect(result.status, SmartTileAtlasImageLoadStatus.loaded);
      expect(result.image?.width, 96);
      expect(result.image?.height, 64);
      expect(result.image?.bytes, isNotEmpty);
      expect(result.image?.columnAlphaCoverage, hasLength(96));
      expect(result.image?.rowAlphaCoverage, hasLength(64));
    });

    test('rejects a tileset path outside the project root', () async {
      final projectRoot = await Directory.systemTemp.createTemp(
        'smart_tile_atlas_root_',
      );
      final outsideRoot = await Directory.systemTemp.createTemp(
        'smart_tile_atlas_outside_',
      );
      addTearDown(() async {
        await projectRoot.delete(recursive: true);
        await outsideRoot.delete(recursive: true);
      });
      final outsideFile = File(
        '${outsideRoot.path}${Platform.pathSeparator}outside.png',
      );
      await outsideFile.writeAsBytes(
        img.encodePng(img.Image(width: 32, height: 32)),
      );

      final result = await const FileSmartTileAtlasImageLoader().load(
        projectRootPath: projectRoot.path,
        tileset: ProjectTilesetEntry(
          id: 'outside',
          name: 'Outside',
          relativePath: outsideFile.path,
        ),
      );

      expect(result.status, SmartTileAtlasImageLoadStatus.outsideProject);
      expect(result.image, isNull);
    });

    test('reports an unavailable project root without touching disk', () async {
      final result = await const FileSmartTileAtlasImageLoader().load(
        projectRootPath: null,
        tileset: const ProjectTilesetEntry(
          id: 'terrain',
          name: 'Terrain',
          relativePath: 'assets/terrain.png',
        ),
      );

      expect(
        result.status,
        SmartTileAtlasImageLoadStatus.missingProjectRoot,
      );
      expect(result.image, isNull);
    });
  });
}
