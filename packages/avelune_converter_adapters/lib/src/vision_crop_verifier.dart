import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;

import 'native_project_writer.dart';
import 'vision_runtime.dart';
import 'vision_support.dart';

Future<void> verifyVisionCrops(
    {required VisionMaterial material,
    required SourceFilePort sourceFiles,
    required ScanCancellation cancellation}) async {
  try {
    final sources = <ConverterId, image.Image>{};
    final hashes = <ConverterId, Sha256Hash>{};
    for (final crop in material.crops) {
      checkVisionCancellation(cancellation);
      if (!sources.containsKey(crop.fileId)) {
        final bytes = await sourceFiles.read(crop.fileId);
        checkVisionCancellation(cancellation);
        requireVision(bytes.length <= 16777216, 'vision.sourceQuota');
        final hash = Sha256Hash(sha256.convert(bytes).toString());
        requireVision(hash == crop.sourceHash, 'vision.sourceChanged');
        const NativePngValidator().validate(bytes);
        requireVision(bytes[24] <= 8, 'vision.sourceFormat');
        final raster = image.decodePng(Uint8List.fromList(bytes));
        requireVision(
            raster != null && raster.numFrames == 1, 'vision.sourceFormat');
        sources[crop.fileId] = raster!;
        hashes[crop.fileId] = hash;
      }
      requireVision(
          hashes[crop.fileId] == crop.sourceHash, 'vision.sourceChanged');
      final source = sources[crop.fileId]!;
      final x = crop.sourceRect['x'] as int;
      final y = crop.sourceRect['y'] as int;
      final w = crop.sourceRect['width'] as int;
      final h = crop.sourceRect['height'] as int;
      requireVision(
          x + w <= source.width && y + h <= source.height, 'vision.cropBounds');
      _validateTransmittedChunks(crop.pngBytes);
      const NativePngValidator().validate(crop.pngBytes,
          limits: NativeWriteLimits(
              maxArtifactBytes: material.limits.maxImageBytes,
              maxImagePixels: material.limits.maxPixels));
      final transmitted = image.decodePng(Uint8List.fromList(crop.pngBytes));
      requireVision(
          transmitted != null &&
              transmitted.width == crop.transmittedWidth &&
              transmitted.height == crop.transmittedHeight &&
              crop.pngBytes[24] <= 8,
          'vision.cropFormat');
      requireVision(
          transmitted!.width == (crop.quarterTurns.isOdd ? h : w) &&
              transmitted.height == (crop.quarterTurns.isOdd ? w : h),
          'vision.cropTransform');
      for (var sy = 0; sy < h; sy++) {
        checkVisionCancellation(cancellation);
        for (var sx = 0; sx < w; sx++) {
          final mx = crop.reflected ? w - 1 - sx : sx;
          final (tx, ty) = switch (crop.quarterTurns) {
            0 => (mx, sy),
            1 => (h - 1 - sy, mx),
            2 => (w - 1 - mx, h - 1 - sy),
            3 => (sy, w - 1 - mx),
            _ => throw const VisionAssistanceException('vision.cropTransform'),
          };
          final a = source.getPixel(x + sx, y + sy);
          final b = transmitted.getPixel(tx, ty);
          requireVision(a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a,
              'vision.cropPixels');
        }
      }
    }
  } on VisionAssistanceException {
    rethrow;
  } catch (_) {
    throw const VisionAssistanceException('vision.cropInvalid');
  }
}

void _validateTransmittedChunks(List<int> bytes) {
  var offset = 8;
  var chunks = 0;
  while (offset < bytes.length) {
    requireVision(
        offset <= bytes.length - 12 && ++chunks <= 1024, 'vision.cropMetadata');
    final length = (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    requireVision(
        const {'IHDR', 'IDAT', 'IEND'}.contains(type) &&
            length >= 0 &&
            length <= bytes.length - offset - 12,
        'vision.cropMetadata');
    offset += 12 + length;
  }
  requireVision(offset == bytes.length, 'vision.cropMetadata');
}
