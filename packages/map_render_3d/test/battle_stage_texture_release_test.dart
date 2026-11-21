import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/map_render_3d.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an evicted texture is released only once its retirement is purged', () async {
    final first = _image();
    final next = _image();
    addTearDown(first.dispose);
    addTearDown(next.dispose);
    final created = <ui.Image, SpatialActorTexture>{};
    final cache = BattleStageTextureCache(
      importer: (image) async =>
          created[image] = await SpatialActorTexture.fromImage(image),
    );
    addTearDown(cache.close);
    cache.sync({first});
    await cache.settled;
    final evicted = cache.textureFor(first)!;

    cache.sync({next});
    expect(evicted.isReleased, isFalse);

    cache.releaseRetired();
    await cache.settled;
    expect(evicted.isReleased, isTrue);
    expect(cache.textureFor(next)!.isReleased, isFalse);
  });

  test('closing the cache releases every resident texture', () async {
    final first = _image();
    final second = _image();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final cache = BattleStageTextureCache(
      importer: SpatialActorTexture.fromImage,
    );
    cache.sync({first, second});
    await cache.settled;
    final resident = [cache.textureFor(first)!, cache.textureFor(second)!];

    cache.close();
    cache.close();

    expect(resident.every((texture) => texture.isReleased), isTrue);
  });

  test('a texture imported after the cache closed is released', () async {
    final image = _image();
    addTearDown(image.dispose);
    final entered = Completer<void>();
    final finish = Completer<void>();
    SpatialActorTexture? late;
    final failures = <Object>[];
    final cache = BattleStageTextureCache(
      importer: (image) async {
        entered.complete();
        await finish.future;
        return late = await SpatialActorTexture.fromImage(image);
      },
      onError: (error, _) => failures.add(error),
    );
    cache.sync({image});
    await entered.future;

    cache.close();
    finish.complete();
    await cache.settled;

    expect(late, isNotNull);
    expect(late!.isReleased, isTrue);
    expect(failures, isEmpty);
  });

  test('a texture imported for an obsolete source is released', () async {
    final first = _image();
    final next = _image();
    addTearDown(first.dispose);
    addTearDown(next.dispose);
    final entered = Completer<void>();
    final finish = Completer<void>();
    final created = <SpatialActorTexture>[];
    final cache = BattleStageTextureCache(
      importer: (image) async {
        if (!entered.isCompleted) {
          entered.complete();
          await finish.future;
        }
        final texture = await SpatialActorTexture.fromImage(image);
        created.add(texture);
        return texture;
      },
    );
    addTearDown(cache.close);
    cache.sync({first});
    await entered.future;

    cache.sync({next});
    finish.complete();
    await cache.settled;

    expect(cache.textureFor(first), isNull);
    expect(created, hasLength(2));
    expect(created.first.isReleased, isTrue);
    expect(cache.textureFor(next), same(created.last));
    expect(created.last.isReleased, isFalse);
  });
}

ui.Image _image() {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(const ui.Rect.fromLTWH(0, 0, 2, 2), ui.Paint());
  final picture = recorder.endRecording();
  try {
    return picture.toImageSync(2, 2);
  } finally {
    picture.dispose();
  }
}
