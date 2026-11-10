import 'dart:math';
import 'dart:ui' as ui;

import '../../features/resources/domain/resource_image_picker.dart';

Future<bool> verifyResourceImageContent(PickedResourceImage image) async {
  try {
    final codec = await ui.instantiateImageCodec(
      image.bytes,
      targetWidth: min(image.width, 256),
    );
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      return codec.frameCount == 1;
    } finally {
      codec.dispose();
    }
  } on Object {
    return false;
  }
}
