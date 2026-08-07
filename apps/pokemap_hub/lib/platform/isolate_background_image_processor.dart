import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;

import 'package:pokemap_hub/features/appearance/domain/repositories/custom_background_repository_interface.dart';

/// Decodes and re-encodes background images on a background isolate.
///
/// `compute` is a Flutter platform capability, so this adapter belongs in
/// `platform/`, not in the appearance data layer.
final class AveluneIsolateBackgroundImageProcessor
    implements AveluneBackgroundImageProcessor {
  @override
  Future<AveluneProcessedBackground> process(Uint8List bytes) async {
    try {
      final result = await compute(_processBackground, bytes);
      return AveluneProcessedBackground(
        imageBytes: result['imageBytes']! as Uint8List,
        thumbnailBytes: result['thumbnailBytes']! as Uint8List,
        width: result['width']! as int,
        height: result['height']! as int,
      );
    } on Object {
      throw const AveluneCustomBackgroundException(
        AveluneCustomBackgroundErrorCode.decodeFailed,
        'Cette image ne peut pas être décodée.',
      );
    }
  }

  @override
  Future<bool> validateJpeg(Uint8List bytes) => compute(_validateJpeg, bytes);
}

Map<String, Object> _processBackground(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Image decode failed.');
  var oriented = image.bakeOrientation(decoded);
  final longest = max(oriented.width, oriented.height);
  if (longest > kAveluneMaximumCustomBackgroundDimension) {
    oriented = oriented.width >= oriented.height
        ? image.copyResize(
            oriented,
            width: kAveluneMaximumCustomBackgroundDimension,
            interpolation: image.Interpolation.cubic,
          )
        : image.copyResize(
            oriented,
            height: kAveluneMaximumCustomBackgroundDimension,
            interpolation: image.Interpolation.cubic,
          );
  }
  final opaque = image.Image(
    width: oriented.width,
    height: oriented.height,
  );
  image.fill(opaque, color: image.ColorRgb8(0x17, 0x12, 0x18));
  image.compositeImage(opaque, oriented);
  final thumbnail = opaque.width >= opaque.height
      ? image.copyResize(
          opaque,
          width: kAveluneThumbnailMaximumDimension,
          interpolation: image.Interpolation.cubic,
        )
      : image.copyResize(
          opaque,
          height: kAveluneThumbnailMaximumDimension,
          interpolation: image.Interpolation.cubic,
        );
  final imageBytes = image.encodeJpg(opaque, quality: 84);
  final thumbnailBytes = image.encodeJpg(thumbnail, quality: 78);
  if (!_validateJpeg(imageBytes) || !_validateJpeg(thumbnailBytes)) {
    throw const FormatException('Generated JPEG decode failed.');
  }
  return <String, Object>{
    'imageBytes': imageBytes,
    'thumbnailBytes': thumbnailBytes,
    'width': opaque.width,
    'height': opaque.height,
  };
}

bool _validateJpeg(Uint8List bytes) =>
    bytes.length >= 3 &&
    bytes[0] == 0xFF &&
    bytes[1] == 0xD8 &&
    bytes[2] == 0xFF &&
    image.decodeJpg(bytes) != null;
