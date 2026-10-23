import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_world_presentation_controller.dart';
import 'package:map_runtime/src/presentation/flame/world_presentation_renderer.dart';

void main() {
  test(
    'picture keeps its native bounds inside a letterboxed reference viewport',
    () async {
      final source = ui.PictureRecorder();
      ui.Canvas(source).drawRect(
        const ui.Rect.fromLTWH(0, 0, 4, 4),
        ui.Paint()..color = const ui.Color(0xff00ff00),
      );
      final image = await source.endRecording().toImage(4, 4);
      addTearDown(image.dispose);
      final controller = SceneWorldPresentationController();
      controller.apply(
        SceneInteractiveCommand.worldPresentation(
          operation: SceneWorldPresentationOperation.showPicture,
          slotId: 1,
          mediaAssetId: 'portrait',
          referenceWidth: 100,
          referenceHeight: 100,
          x: 25,
          y: 25,
        ) as SceneWorldPresentationInteractiveCommand,
      );
      final recorder = ui.PictureRecorder();
      RuntimeWorldPresentationRenderer(
        images: {'portrait': image},
      ).render(ui.Canvas(recorder), const ui.Size(200, 100), controller.frame);
      final rendered = await recorder.endRecording().toImage(200, 100);
      addTearDown(rendered.dispose);
      final bytes = (await rendered.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      int alpha(int x, int y) => bytes.getUint8((y * 200 + x) * 4 + 3);
      expect(alpha(76, 26), 255);
      expect(alpha(5, 5), 0);
      expect(alpha(100, 50), 0);
    },
  );
}
