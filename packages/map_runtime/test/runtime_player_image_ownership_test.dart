import 'dart:io';

import 'package:flame/components.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Player evicts an unused transparency variant and preserves active pixels',
    () async {
      final root = await Directory.systemTemp.createTemp('player-variants-');
      addTearDown(() => root.delete(recursive: true));
      final bytes = img.encodePng(img.Image(width: 8, height: 8));
      final activeFile = File('${root.path}/active.png');
      final variantFile = File('${root.path}/variant.png');
      await activeFile.writeAsBytes(bytes);
      await variantFile.writeAsBytes(bytes);
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(maximumResidentBytes: 512),
      );
      final cache = RuntimeTilesetImageSingleFlightCache(
        loader: loadTilesetImagesById,
        resourceBudget: budget,
        identity: 'project@version',
      );
      final original = await cache.loadById({
        'active': activeFile.path,
        'variant': variantFile.path,
      });
      final bundle = RuntimeMapBundle(
        manifest: ProjectManifest(
          name: 'Transparency variants',
          version: ProjectVersion.v8,
          maps: const [],
          tilesets: [
            ProjectTilesetEntry(
              id: 'active',
              name: 'Active',
              relativePath: 'active.png',
            ),
            ProjectTilesetEntry(
              id: 'variant',
              name: 'Variant',
              relativePath: 'variant.png',
              transparentColor: TilesetTransparentColor(
                red: 1,
                green: 2,
                blue: 3,
              ),
            ),
          ],
          settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
        ),
        map: MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v8,
          tilesetId: 'active',
          size: const GridSize(width: 2, height: 2),
          layers: const [],
        ),
        projectRootDirectory: root.path,
        tilesetAbsolutePathsById: {
          'active': activeFile.path,
          'variant': variantFile.path,
        },
        resourceBudget: budget,
      );
      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: '${root.path}/project.json',
        initialTilesetImageCache: cache,
      );
      var removed = false;
      addTearDown(() {
        if (!removed) game.onRemove();
        budget.dispose();
      });
      game.onGameResize(Vector2(32, 32));
      await game.onLoad();
      expect(original['variant']!.isDisposed, isTrue);
      expect(original['active']!.isDisposed, isFalse);
      expect(cache.loadedImages, hasLength(2));
      expect(budget.residentBytes, 512);
      game.onRemove();
      removed = true;
      expect(budget.residentBytes, 0);
    },
  );

  for (final warm in [false, true]) {
    test(
      'Player admits the requested map and preserves its warm pixels: $warm',
      () async {
        final root = await Directory.systemTemp.createTemp('player-images-');
        addTearDown(() => root.delete(recursive: true));
        final png = img.encodePng(img.Image(width: 8, height: 8));
        final target = File('${root.path}/target.png');
        final unused = File('${root.path}/unused.png');
        await target.writeAsBytes(png);
        await unused.writeAsBytes(png);
        final budget = RuntimeResourceBudget(
          profile: RuntimeResourceProfile(
            maximumResidentBytes: warm ? 512 : 256,
          ),
        );
        final cache = RuntimeTilesetImageSingleFlightCache(
          loader: loadTilesetImagesById,
          resourceBudget: budget,
        );
        final old = (await cache.loadById({'unused': unused.path}))['unused']!;
        if (warm) {
          await cache.loadById({'target': target.path});
          await target.delete();
        }
        final bundle = RuntimeMapBundle(
          manifest: ProjectManifest(
            name: 'Player memory',
            version: ProjectVersion.v8,
            maps: const [],
            tilesets: const [
              ProjectTilesetEntry(
                id: 'target',
                name: 'Target',
                relativePath: 'target.png',
              ),
            ],
            settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
          ),
          map: MapData(
            id: 'map',
            name: 'Map',
            version: ProjectVersion.v8,
            tilesetId: 'target',
            size: const GridSize(width: 2, height: 2),
            layers: const [],
          ),
          projectRootDirectory: root.path,
          tilesetAbsolutePathsById: {'target': target.path},
          resourceBudget: budget,
        );
        final game = PlayableMapGame(
          bundle: bundle,
          projectFilePath: '${root.path}/project.json',
          initialTilesetImageCache: cache,
        );
        var removed = false;
        addTearDown(() {
          if (!removed) game.onRemove();
          budget.dispose();
        });
        game.onGameResize(Vector2(32, 32));
        await game.onLoad();
        expect(old.isDisposed, isTrue);
        expect(budget.residentBytes, 256);
        final active = cache.loadedImages.single;
        if (warm) {
          final extra = (await cache.loadById({
            'unused': unused.path,
          }))['unused']!;
          expect(budget.residentBytes, 512);
          game.didHaveMemoryPressure();
          expect(extra.isDisposed, isTrue);
        } else {
          game.didHaveMemoryPressure();
        }
        expect(active.isDisposed, isFalse);
        expect(budget.residentBytes, 256);
        game.onRemove();
        removed = true;
        expect(active.isDisposed, isTrue);
        expect(budget.residentBytes, 0);
      },
    );
  }
}
