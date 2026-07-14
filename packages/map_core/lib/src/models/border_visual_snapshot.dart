import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'border_value_objects.dart';
import 'geometry.dart';

final RegExp _lowercaseSha256 = RegExp(r'^[0-9a-f]{64}$');

/// Pixel-derived metrics owned by a primitive definition.
///
/// The occupancy payload remains opaque here. Its strict bounded RLE codec is
/// a separate concern and is intentionally not decoded by this model.
@immutable
final class BorderPrimitiveAssetMetrics {
  BorderPrimitiveAssetMetrics({
    required this.assetFingerprint,
    required this.pixelSize,
    required this.opaqueBounds,
    required this.defaultAnchorPx,
    required this.occupancyMaskRle,
  }) {
    if (assetFingerprint.isEmpty) {
      throw const ValidationException(
        'BorderPrimitiveAssetMetrics.assetFingerprint must be non-empty',
      );
    }
    if (pixelSize.width <= 0 || pixelSize.height <= 0) {
      throw const ValidationException(
        'BorderPrimitiveAssetMetrics.pixelSize dimensions must be > 0',
      );
    }
    if (opaqueBounds.x < 0 ||
        opaqueBounds.y < 0 ||
        opaqueBounds.right > pixelSize.width ||
        opaqueBounds.bottom > pixelSize.height) {
      throw const ValidationException(
        'BorderPrimitiveAssetMetrics.opaqueBounds must fit pixelSize',
      );
    }
    if (occupancyMaskRle.isEmpty) {
      throw const ValidationException(
        'BorderPrimitiveAssetMetrics.occupancyMaskRle must be non-empty',
      );
    }
  }

  final String assetFingerprint;
  final GridSize pixelSize;
  final BorderPixelRect opaqueBounds;
  final BorderPixelPos defaultAnchorPx;
  final String occupancyMaskRle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPrimitiveAssetMetrics &&
          assetFingerprint == other.assetFingerprint &&
          pixelSize == other.pixelSize &&
          opaqueBounds == other.opaqueBounds &&
          defaultAnchorPx == other.defaultAnchorPx &&
          occupancyMaskRle == other.occupancyMaskRle;

  @override
  int get hashCode => Object.hash(
        assetFingerprint,
        pixelSize,
        opaqueBounds,
        defaultAnchorPx,
        occupancyMaskRle,
      );
}

/// One already-normalized frame of an immutable visual snapshot.
@immutable
final class BorderVisualFrameSnapshot {
  BorderVisualFrameSnapshot({
    required this.relativeAssetPath,
    required this.sourceRectPx,
    required this.durationMs,
    this.transparentColorArgb,
  }) {
    if (!_isSafeProjectRelativePath(relativeAssetPath)) {
      throw const ValidationException(
        'BorderVisualFrameSnapshot.relativeAssetPath must be a safe '
        'project-relative path',
      );
    }
    if (sourceRectPx.x < 0 || sourceRectPx.y < 0) {
      throw const ValidationException(
        'BorderVisualFrameSnapshot.sourceRectPx coordinates must be >= 0',
      );
    }
    if (durationMs <= 0) {
      throw const ValidationException(
        'BorderVisualFrameSnapshot.durationMs must be > 0',
      );
    }
    final transparentColor = transparentColorArgb;
    if (transparentColor != null &&
        (transparentColor < 0 || transparentColor > 0xffffffff)) {
      throw const ValidationException(
        'BorderVisualFrameSnapshot.transparentColorArgb must be a 32-bit '
        'ARGB value',
      );
    }
  }

  final String relativeAssetPath;
  final BorderPixelRect sourceRectPx;
  final int durationMs;
  final int? transparentColorArgb;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderVisualFrameSnapshot &&
          relativeAssetPath == other.relativeAssetPath &&
          sourceRectPx == other.sourceRectPx &&
          durationMs == other.durationMs &&
          transparentColorArgb == other.transparentColorArgb;

  @override
  int get hashCode => Object.hash(
        relativeAssetPath,
        sourceRectPx,
        durationMs,
        transparentColorArgb,
      );
}

/// Content-addressed immutable snapshot metadata.
@immutable
final class BorderVisualSnapshot {
  BorderVisualSnapshot({
    required this.id,
    required this.contentFingerprint,
    required List<BorderVisualFrameSnapshot> frames,
  }) : _frames = List<BorderVisualFrameSnapshot>.unmodifiable(frames) {
    if (!_lowercaseSha256.hasMatch(contentFingerprint)) {
      throw const ValidationException(
        'BorderVisualSnapshot.contentFingerprint must be 64 lowercase '
        'hexadecimal characters',
      );
    }
    if (id != 'border-snapshot-sha256:$contentFingerprint') {
      throw const ValidationException(
        'BorderVisualSnapshot.id must match contentFingerprint',
      );
    }
    if (_frames.isEmpty) {
      throw const ValidationException(
        'BorderVisualSnapshot.frames must be non-empty',
      );
    }

    final expectedWidth = _frames.first.sourceRectPx.width;
    final expectedHeight = _frames.first.sourceRectPx.height;
    for (final frame in _frames.skip(1)) {
      if (frame.sourceRectPx.width != expectedWidth ||
          frame.sourceRectPx.height != expectedHeight) {
        throw const ValidationException(
          'BorderVisualSnapshot.frames must share source dimensions',
        );
      }
    }
  }

  final String id;
  final String contentFingerprint;
  final List<BorderVisualFrameSnapshot> _frames;

  List<BorderVisualFrameSnapshot> get frames => _frames;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderVisualSnapshot &&
          id == other.id &&
          contentFingerprint == other.contentFingerprint &&
          _listsEqual(_frames, other._frames);

  @override
  int get hashCode => Object.hash(
        id,
        contentFingerprint,
        Object.hashAll(_frames),
      );
}

bool _isSafeProjectRelativePath(String path) {
  if (path.isEmpty ||
      !path.startsWith('assets/borders/snapshots/') ||
      path.startsWith('/') ||
      path.contains(r'\') ||
      path.contains(':')) {
    return false;
  }
  for (final codeUnit in path.codeUnits) {
    if (codeUnit < 0x20) {
      return false;
    }
  }
  final segments = path.split('/');
  return segments.every(
    (segment) => segment.isNotEmpty && segment != '.' && segment != '..',
  );
}

bool _listsEqual<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
