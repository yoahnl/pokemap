import 'dart:ui' as ui;

import 'package:flame/sprite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_bundle_cache.dart';

Future<ui.Image> _fakeImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xFFFF8844),
  );
  return recorder.endRecording().toImage(4, 4);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BattleFxBundleCache', () {
    test('loadImage uses catalog asset key', () async {
      String? loadedAssetKey;
      final cache = BattleFxBundleCache(
        imageLoader: (assetKey) async {
          loadedAssetKey = assetKey;
          return _fakeImage();
        },
      );

      await cache.loadImage('aerial_ace');

      expect(
        loadedAssetKey,
        equals('packages/map_runtime/assets/battle_animations/aerial_ace.png'),
      );
    });

    test('second load of same effect reuses cache', () async {
      var loadCount = 0;
      final cache = BattleFxBundleCache(
        imageLoader: (assetKey) async {
          loadCount += 1;
          return _fakeImage();
        },
      );

      final first = await cache.loadImage('shadowball');
      final second = await cache.loadImage('shadowball');

      expect(loadCount, equals(1));
      expect(identical(first, second), isTrue);
    });

    test('loadSprite reuses underlying cached image', () async {
      var loadCount = 0;
      final cache = BattleFxBundleCache(
        imageLoader: (assetKey) async {
          loadCount += 1;
          return _fakeImage();
        },
      );

      final image = await cache.loadImage('impact');
      final sprite = await cache.loadSprite('impact');

      expect(loadCount, equals(1));
      expect(sprite, isA<Sprite>());
      expect(identical(sprite.image, image), isTrue);
    });

    test('prewarm loads every requested effect exactly once', () async {
      final loadedKeys = <String>[];
      final cache = BattleFxBundleCache(
        imageLoader: (assetKey) async {
          loadedKeys.add(assetKey);
          return _fakeImage();
        },
      );

      await cache.prewarm(<String>['aerial_ace', 'stat_up', 'aerial_ace']);

      expect(
        loadedKeys,
        equals(<String>[
          'packages/map_runtime/assets/battle_animations/aerial_ace.png',
          'packages/map_runtime/assets/battle_animations/stat_up.png',
        ]),
      );
    });

    test('unknown effect id throws', () async {
      final cache = BattleFxBundleCache(
        imageLoader: (assetKey) => _fakeImage(),
      );

      await expectLater(
        cache.loadImage('nope'),
        throwsStateError,
      );
    });

    test('clear empties cache', () async {
      var loadCount = 0;
      final cache = BattleFxBundleCache(
        imageLoader: (assetKey) async {
          loadCount += 1;
          return _fakeImage();
        },
      );

      await cache.loadImage('aerial_ace');
      cache.clear();
      await cache.loadImage('aerial_ace');

      expect(loadCount, equals(2));
    });
  });
}
