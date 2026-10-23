import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import '../../application/scene_runtime/scene_world_presentation_controller.dart';

final class RuntimeWorldPresentationRenderer {
  const RuntimeWorldPresentationRenderer({required this.images});
  final Map<String, ui.Image> images;

  void render(
    ui.Canvas canvas,
    ui.Size viewport,
    SceneWorldPresentationFrame frame,
  ) {
    for (final picture in frame.pictures) {
      final image = images[picture.mediaAssetId];
      if (image == null) {
        continue;
      }
      final fit = math.min(
        viewport.width / picture.referenceWidth,
        viewport.height / picture.referenceHeight,
      );
      final composition = picture.composition;
      final width = image.width * composition.scaleX * fit;
      final height = image.height * composition.scaleY * fit;
      final center = picture.origin == ScenePictureOrigin.center;
      final left =
          (viewport.width - picture.referenceWidth * fit) / 2 +
          composition.translateX * picture.referenceWidth * fit -
          (center ? width / 2 : 0);
      final top =
          (viewport.height - picture.referenceHeight * fit) / 2 +
          composition.translateY * picture.referenceHeight * fit -
          (center ? height / 2 : 0);
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        ui.Rect.fromLTWH(left, top, width, height),
        ui.Paint()
          ..color = ui.Color.fromRGBO(255, 255, 255, composition.opacity)
          ..filterQuality = ui.FilterQuality.none,
      );
    }
    for (final flash in frame.flashes) {
      canvas.drawRect(
        ui.Offset.zero & viewport,
        ui.Paint()
          ..color = ui.Color.fromARGB(
            flash.alpha.round(),
            flash.red.round(),
            flash.green.round(),
            flash.blue.round(),
          ),
      );
    }
  }
}
