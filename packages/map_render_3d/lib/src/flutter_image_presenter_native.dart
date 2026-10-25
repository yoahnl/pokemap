import 'dart:ui';

import 'package:flutter_gpu/gpu.dart' as gpu;

Image Function(Image) createFlutterImagePresenter() {
  gpu.GpuImageSurface? surface;

  return (image) {
    final context = gpu.gpuContext;
    final source = gpu.Texture.fromImage(context, image);
    gpu.GpuImageSurfaceFrame? frame;
    try {
      var current = surface;
      if (current == null || current.format != source.format) {
        current = context.createImageSurface(
          image.width,
          image.height,
          format: source.format,
        );
        surface = current;
      } else if (current.width != image.width ||
          current.height != image.height) {
        current.resize(image.width, image.height);
      }
      frame = current.acquireNextFrame();
      final commands = context.createCommandBuffer();
      commands.copyTextureToTexture(
        gpu.TextureRegion(source),
        gpu.TextureDestinationRegion(frame.colorTexture),
      );
      frame.present(commands);
      commands.submit();
      final presented = current.currentImage;
      if (presented == null) {
        throw StateError('The rendered frame could not be presented.');
      }
      return presented;
    } catch (_) {
      surface = null;
      rethrow;
    } finally {
      frame?.discard();
    }
  };
}
