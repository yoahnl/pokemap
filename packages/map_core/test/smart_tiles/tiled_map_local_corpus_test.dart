import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final rootPath = Platform.environment['POKEMAP_TMX_CORPUS_ROOT'];
  final expectedTileLayerCount = int.tryParse(
    Platform.environment['POKEMAP_TMX_EXPECT_TILE_LAYERS'] ?? '',
  );
  final expectedTilesetCount = int.tryParse(
    Platform.environment['POKEMAP_TMX_EXPECT_TILESETS'] ?? '',
  );
  final expectedTileObjectCount = int.tryParse(
    Platform.environment['POKEMAP_TMX_EXPECT_TILE_OBJECTS'] ?? '',
  );

  test(
    'parses every supported finite map in a local generic TMX corpus',
    () {
      final files = Directory(rootPath!)
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.tmx'))
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));
      expect(files, isNotEmpty);

      var parsed = 0;
      var rejectedNonPlayable = 0;
      var matchedExpectedShape = false;
      var compiledTileObjectCount = 0;
      for (final file in files) {
        try {
          final document = parseTiledMap(file.readAsStringSync());
          final result = compileTiledMapDocument(
            document,
            mapId: 'local-tmx-$parsed',
            mapName: file.uri.pathSegments.last,
            gridPolicy: const TiledMapGridPolicy.adoptSource(),
            tilesets: <TiledMapTilesetBinding>[
              for (var index = 0; index < document.tilesets.length; index++)
                TiledMapTilesetBinding(
                  source: document.tilesets[index].source,
                  tilesetId: 'local-tileset-$index',
                ),
            ],
          );
          MapValidator.validate(result.map);
          expect(MapData.fromJson(result.map.toJson()), result.map);
          expect(
            result.report.tileLayerCount,
            result.map.layers.whereType<TileLayer>().length,
          );
          expect(
            result.report.compiledTileObjectCount,
            result.map.layers.whereType<ObjectLayer>().fold<int>(
                  0,
                  (count, layer) => count + layer.tileObjects.length,
                ),
          );
          compiledTileObjectCount += result.report.compiledTileObjectCount;
          expect(result.report.sourceTilesetCount, document.tilesets.length);
          expect(
            result.report.referencedTilesetIds.length,
            document.tilesets.length,
          );
          if ((expectedTileLayerCount == null ||
                  result.report.tileLayerCount == expectedTileLayerCount) &&
              (expectedTilesetCount == null ||
                  result.report.sourceTilesetCount == expectedTilesetCount)) {
            matchedExpectedShape = true;
            expect(
              result.report.hasVisualLoss,
              isFalse,
              reason: '${file.path}: the requested reference map lost tiles.',
            );
          }
          parsed += 1;
        } on TiledMapImportException catch (error) {
          if (error.code == 'map.tiled.infinite_unsupported') {
            rejectedNonPlayable += 1;
            continue;
          }
          if (error.code == 'map.tiled.internal_dependency_unsupported') {
            rejectedNonPlayable += 1;
            continue;
          }
          fail('${file.path}: $error');
        }
      }

      expect(parsed, greaterThan(0));
      // A mixed corpus may contain automapping inputs. They remain explicit
      // rejections instead of being silently interpreted as playable maps.
      expect(parsed + rejectedNonPlayable, files.length);
      if (expectedTileObjectCount != null) {
        expect(compiledTileObjectCount, expectedTileObjectCount);
      }
      if (expectedTileLayerCount != null || expectedTilesetCount != null) {
        expect(
          matchedExpectedShape,
          isTrue,
          reason: 'No supported map matched the requested local shape '
              '(tileLayers=$expectedTileLayerCount, '
              'tilesets=$expectedTilesetCount).',
        );
      }
    },
    skip: rootPath == null
        ? 'Set POKEMAP_TMX_CORPUS_ROOT to a local generic Tiled map corpus.'
        : false,
  );
}
