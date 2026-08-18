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

      final frames = await cache.loadEmoteFrames(cinematicDefaultActorEmoteId);

      final entry =
          cinematicEmoteCatalogEntryById(cinematicDefaultActorEmoteId)!;
      expect(frames, hasLength(entry.frames.length));
      for (var index = 0; index < frames.length; index += 1) {
        expect(frames[index].srcPosition.x, entry.frames[index].x.toDouble());
        expect(frames[index].srcPosition.y, entry.frames[index].y.toDouble());
        expect(frames[index].srcSize.x, entry.frames[index].width.toDouble());
        expect(frames[index].srcSize.y, entry.frames[index].height.toDouble());
      }
      expect(requested.single, startsWith('packages/map_runtime/'));
    });

    test('an unknown emote yields null instead of throwing', () async {
      final cache = CinematicEmoteSpriteCache(
        imageLoader: (_) async => _atlasImage(),
      );

      // Un emote mal authoré ne doit pas faire tomber la carte : la surface
      // appelante retombe sur son rendu de repli.
      expect(await cache.loadEmoteFrames('not_an_emote'), isEmpty);
      expect(await cache.loadEmoteFrames(''), isEmpty);
      expect(await cache.loadEmoteFrames(null), isEmpty);
    });

    test('an atlas is decoded once for every emote it carries', () async {
      var decodes = 0;
      final cache = CinematicEmoteSpriteCache(
        imageLoader: (_) async {
          decodes += 1;
          return _atlasImage();
        },
      );

      await cache.loadEmoteFrames('exclamation');
      await cache.loadEmoteFrames('anger');
      await cache.loadEmoteFrames('exclamation');

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
        cache.loadEmoteFrames('exclamation'),
        throwsA(isA<Exception>()),
      );
      expect(await cache.loadEmoteFrames('exclamation'), isNotEmpty);
      expect(attempts, 2);
    });

    test('every drawn atlas cell is reachable through some emote', () async {
      // Les atlas dessinent 27 cases. Le catalogue n'en exposait que 11, si
      // bien que deux tiers du dessin étaient inatteignables et que cinq
      // identifiants pointaient sur l'image 2 du concept voisin.
      final claimed = <String, Set<String>>{};
      for (final entry in cinematicEmoteCatalog) {
        for (final frame in entry.frames) {
          claimed
              .putIfAbsent(entry.atlasId, () => <String>{})
              .add('${frame.x ~/ 16},${frame.y ~/ 16}');
        }
      }

      expect(claimed[cinematicEmoteDefaultReactionsAtlasId], hasLength(24));
      expect(claimed[cinematicEmoteNeutralBubblesAtlasId], hasLength(3));
    });

    test('an animated emote pairs two neighbouring cells of one row', () {
      // Les paires ne diffèrent que de quelques dizaines de pixels : ce sont
      // les deux images d'une animation. Une seconde image lointaine
      // signalerait un mauvais découpage plutôt qu'une animation.
      for (final entry in cinematicEmoteCatalog.where((e) => e.isAnimated)) {
        final first = entry.frame;
        final second = entry.secondFrame!;
        expect(second.y, first.y, reason: '${entry.id} spans two rows');
        expect(
          second.x - first.x,
          first.width,
          reason: '${entry.id} frames are not adjacent',
        );
      }
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
