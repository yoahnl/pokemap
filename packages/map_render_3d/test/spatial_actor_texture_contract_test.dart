import 'dart:ui';

import 'package:avelune_render_contracts/avelune_render_contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_render_3d/src/spatial_actor_visual.dart'
    show resolveSpatialActorTexture;

final class _ForeignActorTexture implements ActorTexture {
  @override
  int get width => 8;

  @override
  int get height => 6;
}

Image _image(int width, int height) {
  final recorder = PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xffffffff),
  );
  final picture = recorder.endRecording();
  final image = picture.toImageSync(width, height);
  picture.dispose();
  return image;
}

void main() {
  test(
    'a Flame actor texture is an Avelune handle with its dimensions',
    () async {
      final image = _image(8, 6);
      final ActorTexture texture = await SpatialActorTexture.fromImage(image);
      image.dispose();

      expect(texture.width, 8);
      expect(texture.height, 6);
      expect(resolveSpatialActorTexture(texture), same(texture));
    },
  );

  test('a handle created by another renderer is rejected explicitly', () {
    expect(
      () => resolveSpatialActorTexture(_ForeignActorTexture()),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('Flame 3D'),
        ),
      ),
    );
  });

  test('an actor visual refuses to anchor a foreign handle', () async {
    final image = _image(8, 8);
    final own = await SpatialActorTexture.fromImage(image);
    image.dispose();
    const frame = Rect.fromLTWH(0, 0, 8, 8);

    final ownVisual = SpatialActorVisual(
      x: 0,
      y: 0,
      z: 0,
      texture: own,
      frame: frame,
    );
    final foreignVisual = SpatialActorVisual(
      x: 0,
      y: 0,
      z: 0,
      texture: _ForeignActorTexture(),
      frame: frame,
    );

    expect(ownVisual.contactShadowFootAnchor, own.footAnchor(frame));
    expect(() => foreignVisual.contactShadowFootAnchor, throwsArgumentError);
  });
}
