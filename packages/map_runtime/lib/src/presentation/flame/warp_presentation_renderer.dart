import 'dart:math' as math;
import 'dart:ui';

import 'package:map_core/map_core.dart';

import '../../application/warp_presentation_controller.dart';
import '../../infrastructure/runtime_tileset_image.dart';

final class RuntimeWarpPresentationRenderer {
  RuntimeWarpPresentationRenderer({
    required this.presentation,
    required ProjectManifest project,
    Map<String, RuntimeTilesetImage> images = const {},
  }) : images = Map.unmodifiable(images),
       illustration = resolveSceneWarpPresentationVisual(
         presentation,
         project,
       ) {
    final visual = illustration;
    if (visual == null) return;
    for (final slice in visual.frame.slices) {
      final image = this.images[slice.assetId] ?? this.images[visual.tilesetId];
      if (image == null ||
          image.isDisposed ||
          !image.containsSourceRect(_rect(slice.sourceRect))) {
        throw StateError(
          'Warp illustration image is missing, disposed or outside its decoded atlas.',
        );
      }
    }
  }
  final SceneWarpPresentation presentation;
  final ResolvedSceneWarpIllustration? illustration;
  final Map<String, RuntimeTilesetImage> images;

  void render(Canvas canvas, Size size, RuntimeWarpPresentationFrame frame) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      throw ArgumentError.value(size, 'size');
    }
    final viewport = Offset.zero & size;
    canvas.save();
    try {
      canvas.clipRect(viewport);
      _fill(canvas, viewport, 0, frame.worldOpacity);
      if (frame.illustrationOpacity > 0 && illustration != null) {
        _drawIllustration(canvas, size, frame.illustrationOpacity);
      }
      if (frame.caveElapsedMs case final elapsed?) {
        _drawCave(canvas, size, elapsed);
      }
      if (frame.caveRecoveryOpacity > 0) {
        _fill(
          canvas,
          viewport,
          presentation.mode == SceneWarpPresentationMode.caveExit ? 255 : 0,
          frame.caveRecoveryOpacity,
        );
      }
    } finally {
      canvas.restore();
    }
  }

  void _drawIllustration(Canvas canvas, Size size, double opacity) {
    final visual = illustration!;
    final bounds = visual.frame.bounds;
    final scale = math.min(
      size.width / bounds.width,
      size.height / bounds.height,
    );
    final originX = (size.width - bounds.width * scale) / 2;
    final originY = (size.height - bounds.height * scale) / 2;
    _fill(canvas, Rect.fromLTWH(0, 0, size.width, originY), 0, opacity);
    _fill(
      canvas,
      Rect.fromLTWH(0, size.height - originY, size.width, originY),
      0,
      opacity,
    );
    _fill(
      canvas,
      Rect.fromLTWH(0, originY, originX, size.height - 2 * originY),
      0,
      opacity,
    );
    _fill(
      canvas,
      Rect.fromLTWH(
        size.width - originX,
        originY,
        originX,
        size.height - 2 * originY,
      ),
      0,
      opacity,
    );
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none
      ..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0));
    for (final slice in visual.frame.slices) {
      final image = images[slice.assetId] ?? images[visual.tilesetId];
      if (image == null || image.isDisposed) {
        throw StateError('Warp illustration image became unavailable.');
      }
      final destination = slice.destinationRect;
      image.drawImageRect(
        canvas,
        _rect(slice.sourceRect),
        Rect.fromLTWH(
          originX + (destination.x - bounds.x) * scale,
          originY + (destination.y - bounds.y) * scale,
          destination.width * scale,
          destination.height * scale,
        ),
        paint,
      );
    }
  }

  void _drawCave(Canvas canvas, Size size, int elapsedMs) {
    final exiting = presentation.mode == SceneWarpPresentationMode.caveExit;
    final start = exiting ? 0.0 : 255.0;
    final end = exiting ? 255.0 : 0.0;
    final bandTime = math.min(elapsedMs, SceneWarpPresentation.caveBandsMs);
    final bandWidth =
        (size.width / 2 - 12 * size.width / 512) /
        SceneWarpPresentation.caveBandCount;
    final bandHeight =
        (size.height / 2 - 10 * size.height / 384) /
        SceneWarpPresentation.caveBandCount;
    for (var band = 0; band < SceneWarpPresentation.caveBandCount; band++) {
      final progress =
          ((bandTime -
                      band *
                          SceneWarpPresentation.caveBandsMs /
                          SceneWarpPresentation.caveBandCount) /
                  SceneWarpPresentation.caveBandsMs)
              .clamp(0.0, 1.0);
      final gray = (start + (end - start) * progress).round();
      _fill(
        canvas,
        Rect.fromLTWH(
          band * bandWidth,
          band * bandHeight,
          size.width - 2 * band * bandWidth,
          size.height - 2 * band * bandHeight,
        ),
        gray,
        1,
      );
    }
    if (elapsedMs >= SceneWarpPresentation.caveBandsMs) {
      final opacity =
          ((elapsedMs - SceneWarpPresentation.caveBandsMs) /
                  SceneWarpPresentation.caveFillMs)
              .clamp(0.0, 1.0);
      _fill(canvas, Offset.zero & size, end.toInt(), opacity);
    }
  }

  static Rect _rect(ProjectTilesetPixelRect rect) => Rect.fromLTWH(
    rect.x.toDouble(),
    rect.y.toDouble(),
    rect.width.toDouble(),
    rect.height.toDouble(),
  );

  static void _fill(Canvas canvas, Rect rect, int gray, double opacity) {
    if (opacity <= 0) return;
    canvas.drawRect(
      rect,
      Paint()
        ..color = Color.fromRGBO(gray, gray, gray, opacity.clamp(0.0, 1.0)),
    );
  }
}
