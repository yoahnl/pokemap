import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/border_materialization.dart';
import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import '../models/geometry.dart';

final BigInt _maximumPortableJsonInteger = BigInt.parse('9007199254740991');
final BigInt _minimumPortableJsonInteger = -_maximumPortableJsonInteger;

/// Exact integer geometry of one native-size Border sprite placement.
///
/// V1 treats source orientation as tangent-East (`quarterTurns == 0`). The
/// transform is always a horizontal source flip followed by clockwise quarter
/// turns. No scale, crop, half-pixel translation, or collision data is used.
@immutable
final class BorderResolvedSpriteGeometry {
  const BorderResolvedSpriteGeometry._({
    required this.transformedPixelSize,
    required this.transformedAnchorPx,
    required this.transformedOpaqueBoundsPx,
    required this.topLeftWorldPx,
    required this.opaqueWorldBoundsPx,
  });

  final GridSize transformedPixelSize;
  final BorderPixelPos transformedAnchorPx;
  final BorderPixelRect transformedOpaqueBoundsPx;
  final BorderPixelPos topLeftWorldPx;
  final BorderPixelRect opaqueWorldBoundsPx;

  /// Largest axis of the transformed opaque half-open rectangle.
  int get maximumOpaqueExtentPx =>
      transformedOpaqueBoundsPx.width > transformedOpaqueBoundsPx.height
          ? transformedOpaqueBoundsPx.width
          : transformedOpaqueBoundsPx.height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderResolvedSpriteGeometry &&
          transformedPixelSize == other.transformedPixelSize &&
          transformedAnchorPx == other.transformedAnchorPx &&
          transformedOpaqueBoundsPx == other.transformedOpaqueBoundsPx &&
          topLeftWorldPx == other.topLeftWorldPx &&
          opaqueWorldBoundsPx == other.opaqueWorldBoundsPx;

  @override
  int get hashCode => Object.hash(
        transformedPixelSize,
        transformedAnchorPx,
        transformedOpaqueBoundsPx,
        topLeftWorldPx,
        opaqueWorldBoundsPx,
      );
}

/// Resolves an exact native-size sprite placement around a world-space anchor.
///
/// [sourceAnchorPx] is transformed using the same pixel-coordinate convention
/// as the source pixels. [metrics.opaqueBounds] is transformed as a half-open
/// rectangle, avoiding off-by-one errors for both even and odd dimensions.
/// Every persisted/result integer is constrained to the exact portable I-JSON
/// domain; all intermediate arithmetic uses [BigInt].
BorderResolvedSpriteGeometry resolveBorderSpriteGeometry({
  required BorderPrimitiveAssetMetrics metrics,
  required BorderPixelPos sourceAnchorPx,
  required BorderSpriteTransform transform,
  required BorderPixelPos targetAnchorWorldPx,
}) {
  final sourceWidth = _positivePortable(
    metrics.pixelSize.width,
    'metrics.pixelSize.width',
  );
  final sourceHeight = _positivePortable(
    metrics.pixelSize.height,
    'metrics.pixelSize.height',
  );
  final sourceAnchorX = _portable(
    sourceAnchorPx.x,
    'sourceAnchorPx.x',
  );
  final sourceAnchorY = _portable(
    sourceAnchorPx.y,
    'sourceAnchorPx.y',
  );
  if (sourceAnchorX < BigInt.zero ||
      sourceAnchorX >= sourceWidth ||
      sourceAnchorY < BigInt.zero ||
      sourceAnchorY >= sourceHeight) {
    throw const ValidationException(
      'sourceAnchorPx must identify a pixel inside metrics.pixelSize',
    );
  }

  final sourceOpaque = _validatedSourceOpaqueBounds(
    metrics.opaqueBounds,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );
  final targetX = _portable(
    targetAnchorWorldPx.x,
    'targetAnchorWorldPx.x',
  );
  final targetY = _portable(
    targetAnchorWorldPx.y,
    'targetAnchorWorldPx.y',
  );

  final flippedAnchorX = transform.flipX
      ? sourceWidth - BigInt.one - sourceAnchorX
      : sourceAnchorX;
  final flippedOpaque = transform.flipX
      ? _BigRect(
          left: sourceWidth - sourceOpaque.right,
          top: sourceOpaque.top,
          right: sourceWidth - sourceOpaque.left,
          bottom: sourceOpaque.bottom,
        )
      : sourceOpaque;

  final transformedAnchor = _rotatePointClockwise(
    x: flippedAnchorX,
    y: sourceAnchorY,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    quarterTurns: transform.quarterTurns,
  );
  final transformedOpaque = _rotateHalfOpenRectClockwise(
    flippedOpaque,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    quarterTurns: transform.quarterTurns,
  );
  final transformedWidth =
      transform.quarterTurns.isEven ? sourceWidth : sourceHeight;
  final transformedHeight =
      transform.quarterTurns.isEven ? sourceHeight : sourceWidth;

  final topLeftX = targetX - transformedAnchor.x;
  final topLeftY = targetY - transformedAnchor.y;
  final worldOpaqueLeft = topLeftX + transformedOpaque.left;
  final worldOpaqueTop = topLeftY + transformedOpaque.top;
  final topLeftXInt = _portableInt(topLeftX, 'topLeftWorldPx.x');
  final topLeftYInt = _portableInt(topLeftY, 'topLeftWorldPx.y');
  final worldOpaqueLeftInt = _portableInt(
    worldOpaqueLeft,
    'opaqueWorldBoundsPx.x',
  );
  final worldOpaqueTopInt = _portableInt(
    worldOpaqueTop,
    'opaqueWorldBoundsPx.y',
  );
  _requirePortableEdge(
    topLeftX + transformedWidth,
    'transformedWorldBoundsPx.right',
  );
  _requirePortableEdge(
    topLeftY + transformedHeight,
    'transformedWorldBoundsPx.bottom',
  );
  _requirePortableEdge(
    worldOpaqueLeft + transformedOpaque.width,
    'opaqueWorldBoundsPx.right',
  );
  _requirePortableEdge(
    worldOpaqueTop + transformedOpaque.height,
    'opaqueWorldBoundsPx.bottom',
  );

  return BorderResolvedSpriteGeometry._(
    transformedPixelSize: GridSize(
      width: _portableInt(transformedWidth, 'transformedPixelSize.width'),
      height: _portableInt(transformedHeight, 'transformedPixelSize.height'),
    ),
    transformedAnchorPx: BorderPixelPos(
      x: _portableInt(transformedAnchor.x, 'transformedAnchorPx.x'),
      y: _portableInt(transformedAnchor.y, 'transformedAnchorPx.y'),
    ),
    transformedOpaqueBoundsPx: _rectFromBigInt(
      transformedOpaque,
      'transformedOpaqueBoundsPx',
    ),
    topLeftWorldPx: BorderPixelPos(
      x: topLeftXInt,
      y: topLeftYInt,
    ),
    opaqueWorldBoundsPx: BorderPixelRect(
      x: worldOpaqueLeftInt,
      y: worldOpaqueTopInt,
      width: _portableInt(
        transformedOpaque.width,
        'opaqueWorldBoundsPx.width',
      ),
      height: _portableInt(
        transformedOpaque.height,
        'opaqueWorldBoundsPx.height',
      ),
    ),
  );
}

/// True when two half-open pixel domains overlap with positive area.
bool borderPixelRectIntersectsCanvas({
  required BorderPixelRect rect,
  required GridSize canvasSizePx,
}) {
  final canvasWidth = _positivePortable(
    canvasSizePx.width,
    'canvasSizePx.width',
  );
  final canvasHeight = _positivePortable(
    canvasSizePx.height,
    'canvasSizePx.height',
  );
  final left = _portable(rect.x, 'rect.x');
  final top = _portable(rect.y, 'rect.y');
  final width = _positivePortable(rect.width, 'rect.width');
  final height = _positivePortable(rect.height, 'rect.height');
  final right = left + width;
  final bottom = top + height;
  _requirePortableEdge(right, 'rect.right');
  _requirePortableEdge(bottom, 'rect.bottom');

  return left < canvasWidth &&
      right > BigInt.zero &&
      top < canvasHeight &&
      bottom > BigInt.zero;
}

/// Largest opaque axis extent among native-size primitives.
///
/// Flip and quarter turns only swap opaque width and height, so the maximum
/// axis is invariant across every allowed V1 transform.
int maximumBorderTransformedOpaqueExtentPx(
  Iterable<BorderPrimitiveAssetMetrics> metrics,
) {
  var maximum = BigInt.zero;
  for (final candidate in metrics) {
    final sourceWidth = _positivePortable(
      candidate.pixelSize.width,
      'metrics.pixelSize.width',
    );
    final sourceHeight = _positivePortable(
      candidate.pixelSize.height,
      'metrics.pixelSize.height',
    );
    final opaque = _validatedSourceOpaqueBounds(
      candidate.opaqueBounds,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
    );
    final extent = opaque.width > opaque.height ? opaque.width : opaque.height;
    if (extent > maximum) {
      maximum = extent;
    }
  }
  return _portableInt(maximum, 'maximumTransformedOpaqueExtentPx');
}

/// V1 jitter bound: `floor(irregularityPermille * tileSizePx / 4000)`.
int computeBorderJitterMaxPx({
  required int irregularityPermille,
  required int tileSizePx,
}) {
  final irregularity = _portable(
    irregularityPermille,
    'irregularityPermille',
  );
  if (irregularity < BigInt.zero || irregularity > BigInt.from(1000)) {
    throw const ValidationException(
      'irregularityPermille must be between 0 and 1000',
    );
  }
  final tileSize = _positivePortable(tileSizePx, 'tileSizePx');
  return _portableInt(
    (irregularity * tileSize) ~/ BigInt.from(4000),
    'jitterMaxPx',
  );
}

/// Computes the approved V1 pixel-only dirty-halo radius.
int computeBorderDirtyHaloRadiusPx({
  required int depthRows,
  required int tileSizePx,
  required int largestTransformedOpaqueExtentPx,
  required int jitterMaxPx,
  required int maxOverlapPx,
  required int gapTolerancePx,
}) {
  final depth = _positivePortable(depthRows, 'depthRows');
  final tileSize = _positivePortable(tileSizePx, 'tileSizePx');
  final opaqueExtent = _nonNegativePortable(
    largestTransformedOpaqueExtentPx,
    'largestTransformedOpaqueExtentPx',
  );
  final jitter = _nonNegativePortable(jitterMaxPx, 'jitterMaxPx');
  final overlap = _nonNegativePortable(maxOverlapPx, 'maxOverlapPx');
  final gap = _nonNegativePortable(gapTolerancePx, 'gapTolerancePx');

  return _portableInt(
    depth * tileSize + opaqueExtent + jitter + overlap + gap,
    'dirtyHaloRadiusPx',
  );
}

_BigPoint _rotatePointClockwise({
  required BigInt x,
  required BigInt y,
  required BigInt sourceWidth,
  required BigInt sourceHeight,
  required int quarterTurns,
}) =>
    switch (quarterTurns) {
      0 => _BigPoint(x: x, y: y),
      1 => _BigPoint(x: sourceHeight - BigInt.one - y, y: x),
      2 => _BigPoint(
          x: sourceWidth - BigInt.one - x,
          y: sourceHeight - BigInt.one - y,
        ),
      3 => _BigPoint(x: y, y: sourceWidth - BigInt.one - x),
      _ => throw const ValidationException(
          'transform.quarterTurns must be between 0 and 3',
        ),
    };

_BigRect _rotateHalfOpenRectClockwise(
  _BigRect rect, {
  required BigInt sourceWidth,
  required BigInt sourceHeight,
  required int quarterTurns,
}) =>
    switch (quarterTurns) {
      0 => rect,
      1 => _BigRect(
          left: sourceHeight - rect.bottom,
          top: rect.left,
          right: sourceHeight - rect.top,
          bottom: rect.right,
        ),
      2 => _BigRect(
          left: sourceWidth - rect.right,
          top: sourceHeight - rect.bottom,
          right: sourceWidth - rect.left,
          bottom: sourceHeight - rect.top,
        ),
      3 => _BigRect(
          left: rect.top,
          top: sourceWidth - rect.right,
          right: rect.bottom,
          bottom: sourceWidth - rect.left,
        ),
      _ => throw const ValidationException(
          'transform.quarterTurns must be between 0 and 3',
        ),
    };

_BigRect _validatedSourceOpaqueBounds(
  BorderPixelRect rect, {
  required BigInt sourceWidth,
  required BigInt sourceHeight,
}) {
  final left = _portable(rect.x, 'metrics.opaqueBounds.x');
  final top = _portable(rect.y, 'metrics.opaqueBounds.y');
  final width = _positivePortable(
    rect.width,
    'metrics.opaqueBounds.width',
  );
  final height = _positivePortable(
    rect.height,
    'metrics.opaqueBounds.height',
  );
  final result = _BigRect(
    left: left,
    top: top,
    right: left + width,
    bottom: top + height,
  );
  if (result.left < BigInt.zero ||
      result.top < BigInt.zero ||
      result.right > sourceWidth ||
      result.bottom > sourceHeight) {
    throw const ValidationException(
      'metrics.opaqueBounds must fit metrics.pixelSize',
    );
  }
  return result;
}

BorderPixelRect _rectFromBigInt(_BigRect rect, String field) => BorderPixelRect(
      x: _portableInt(rect.left, '$field.x'),
      y: _portableInt(rect.top, '$field.y'),
      width: _portableInt(rect.width, '$field.width'),
      height: _portableInt(rect.height, '$field.height'),
    );

BigInt _portable(int value, String field) {
  final result = BigInt.from(value);
  if (result < _minimumPortableJsonInteger ||
      result > _maximumPortableJsonInteger) {
    throw ValidationException(
      '$field must fit the portable I-JSON integer range',
    );
  }
  return result;
}

BigInt _positivePortable(int value, String field) {
  final result = _portable(value, field);
  if (result <= BigInt.zero) {
    throw ValidationException('$field must be > 0');
  }
  return result;
}

BigInt _nonNegativePortable(int value, String field) {
  final result = _portable(value, field);
  if (result < BigInt.zero) {
    throw ValidationException('$field must be >= 0');
  }
  return result;
}

int _portableInt(BigInt value, String field) {
  if (value < _minimumPortableJsonInteger ||
      value > _maximumPortableJsonInteger) {
    throw ValidationException(
      '$field must fit the portable I-JSON integer range',
    );
  }
  return value.toInt();
}

void _requirePortableEdge(BigInt value, String field) {
  _portableInt(value, field);
}

final class _BigPoint {
  const _BigPoint({required this.x, required this.y});

  final BigInt x;
  final BigInt y;
}

final class _BigRect {
  const _BigRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final BigInt left;
  final BigInt top;
  final BigInt right;
  final BigInt bottom;

  BigInt get width => right - left;
  BigInt get height => bottom - top;
}
