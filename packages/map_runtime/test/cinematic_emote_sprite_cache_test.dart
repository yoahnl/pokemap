import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/cinematic_emote_sprite_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BETA-TRN-001 emote sprites reach the runtime', () {
    test('the exclamation is cut from its catalog frame, not the whole atlas',
        () async {
      final requested = <String>[];
      final cache = CinematicEmoteSpriteCache(
        imageLoader: (assetKey) async {
          requested.add(assetKey);
          return _atlasImage();
        },
      );

      final sprite = await cache.loadEmoteSprite(cinematicDefaultActorEmoteId);

      final entry =
          cinematicEmoteCatalogEntryById(cinematicDefaultActorEmoteId)!;
      expect(sprite, isNotNull);
      expect(sprite!.srcPosition.x, entry.frame.x.toDouble());
      expect(sprite.srcPosition.y, entry.frame.y.toDouble());
      expect(sprite.srcSize.x, entry.frame.width.toDouble());
      expect(sprite.srcSize.y, entry.frame.height.toDouble());
      expect(requested.single, startsWith('packages/map_runtime/'));
    });

    test('an unknown emote yields null instead of throwing', () async {
      final cache = CinematicEmoteSpriteCache(
        imageLoader: (_) async => _atlasImage(),
      );

      // Un emote mal authoré ne doit pas faire tomber la carte : la surface
      // appelante retombe sur son rendu de repli.
      expect(await cache.loadEmoteSprite('not_an_emote'), isNull);
      expect(await cache.loadEmoteSprite(''), isNull);
      expect(await cache.loadEmoteSprite(null), isNull);
    });

    test('an atlas is decoded once for every emote it carries', () async {
      var decodes = 0;
      final cache = CinematicEmoteSpriteCache(
        imageLoader: (_) async {
          decodes += 1;
          return _atlasImage();
        },
      );

      await cache.loadEmoteSprite('exclamation');
      await cache.loadEmoteSprite('anger');
      await cache.loadEmoteSprite('exclamation');

      expect(
        decodes,
        1,
        reason: 'exclamation and anger share the defaultReactions atlas',
      );
    });

    test('a failed decode is not cached as a permanent failure', () async {
      var attempts = 0;
      final cache = CinematicEmoteSpriteCache(
        imageLoader: (_) async {
          attempts += 1;
          if (attempts == 1) {
            throw Exception('transient bundle failure');
          }
          return _atlasImage();
        },
      );

      await expectLater(
        cache.loadEmoteSprite('exclamation'),
        throwsA(isA<Exception>()),
      );
      expect(await cache.loadEmoteSprite('exclamation'), isNotNull);
      expect(attempts, 2);
    });

    test('every catalog atlas is really shipped inside this package', () async {
      // Les atlas ne vivaient que dans map_editor : le runtime référençait des
      // sprites qu'il n'embarquait pas. Ce test échoue si un atlas du catalogue
      // n'est pas livré ici, plutôt que de laisser la carte afficher un vide.
      for (final atlas in cinematicEmoteAtlases) {
        final key = CinematicEmoteSpriteCache.runtimeAssetKeyFor(atlas);
        expect(
          () => rootBundle.load(key),
          returnsNormally,
          reason: '$key must ship with map_runtime',
        );
        final data = await rootBundle.load(key);
        expect(data.lengthInBytes, greaterThan(0), reason: '$key is empty');
      }
    });
  });
}

Future<ui.Image> _atlasImage() {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    Uint8List.fromList(List<int>.filled(128 * 128 * 4, 255)),
    128,
    128,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}
