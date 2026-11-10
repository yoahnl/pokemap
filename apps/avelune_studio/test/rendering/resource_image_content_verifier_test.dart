import 'dart:typed_data';

import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/platform/rendering/resource_image_content_verifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

PickedResourceImage _picked(List<int> bytes) => PickedResourceImage(
  '/fixture/source.png',
  'Source',
  Uint8List.fromList(bytes),
  32,
  32,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native verification decodes a real single-frame PNG', () async {
    final source = image.Image(width: 32, height: 32);
    expect(
      await verifyResourceImageContent(_picked(image.encodePng(source))),
      isTrue,
    );
  });

  test('native verification refuses unreadable bytes', () async {
    expect(await verifyResourceImageContent(_picked([0, 1, 2, 3])), isFalse);
  });

  test('native verification refuses a decodable animated image', () async {
    final animation = image.Image(width: 32, height: 32);
    final second = image.Image(width: 32, height: 32);
    image.fill(second, color: image.ColorRgb8(200, 80, 30));
    animation.addFrame(second);
    expect(
      await verifyResourceImageContent(_picked(image.encodeGif(animation))),
      isFalse,
    );
  });
}
