import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';

/// Wraps an arbitrary quarter-turn count into the canonical `0..3` range.
///
/// Positive values rotate clockwise.
int normalizeQuarterTurns(int value) {
  final remainder = value % 4;
  return remainder < 0 ? remainder + 4 : remainder;
}

/// Maps a rectangular source grid into its clockwise-rotated bounding box.
///
/// The transform never translates the placement origin: callers keep the
/// top-left of the destination bounding box as their anchor. Construction and
/// coordinate conversion reject invalid values in release mode.
final class QuarterTurnGridTransform {
  QuarterTurnGridTransform({
    required this.sourceSize,
    required this.quarterTurns,
  }) {
    _requirePositiveSize(sourceSize, argumentName: 'sourceSize');
    _requireNormalizedQuarterTurns(quarterTurns);
  }

  /// Unrotated element footprint in grid cells.
  final GridSize sourceSize;

  /// Canonical clockwise quarter turns in `0..3`.
  final int quarterTurns;

  /// Bounding-box size after applying [quarterTurns].
  GridSize get destinationSize {
    if (quarterTurns.isEven) return sourceSize;
    return GridSize(
      width: sourceSize.height,
      height: sourceSize.width,
    );
  }

  /// Maps an in-bounds source cell to its destination cell.
  GridPos sourceToDestination(GridPos source) {
    _requireCoordinateInBounds(
      source,
      size: sourceSize,
      argumentName: 'source',
    );
    return switch (quarterTurns) {
      0 => source,
      1 => GridPos(
          x: sourceSize.height - 1 - source.y,
          y: source.x,
        ),
      2 => GridPos(
          x: sourceSize.width - 1 - source.x,
          y: sourceSize.height - 1 - source.y,
        ),
      3 => GridPos(
          x: source.y,
          y: sourceSize.width - 1 - source.x,
        ),
      _ => throw StateError('Unreachable quarter-turn value: $quarterTurns'),
    };
  }

  /// Maps an in-bounds destination cell back to its source cell.
  GridPos destinationToSource(GridPos destination) {
    _requireCoordinateInBounds(
      destination,
      size: destinationSize,
      argumentName: 'destination',
    );
    return switch (quarterTurns) {
      0 => destination,
      1 => GridPos(
          x: destination.y,
          y: sourceSize.height - 1 - destination.x,
        ),
      2 => GridPos(
          x: sourceSize.width - 1 - destination.x,
          y: sourceSize.height - 1 - destination.y,
        ),
      3 => GridPos(
          x: sourceSize.width - 1 - destination.y,
          y: destination.x,
        ),
      _ => throw StateError('Unreachable quarter-turn value: $quarterTurns'),
    };
  }
}

/// Resolves one placed element's canonical grid transform from its primary
/// visual frame.
///
/// Non-positive legacy frame dimensions retain the historical one-cell
/// fallback used by validation and resize. Direct transform construction
/// remains strict.
QuarterTurnGridTransform resolveMapPlacedElementFootprint({
  required MapPlacedElement instance,
  required ProjectElementEntry element,
}) {
  final source = element.frames.primarySource;
  final sourceSize = GridSize(
    // Preserve the historical defensive footprint used by map validation and
    // resize when handed project data that has not yet been validated.
    width: source.width <= 0 ? 1 : source.width,
    height: source.height <= 0 ? 1 : source.height,
  );
  return QuarterTurnGridTransform(
    sourceSize: sourceSize,
    quarterTurns: instance.quarterTurns,
  );
}

/// Inverse-samples a rotated destination bitmap from source pixel centers.
///
/// Destination pixel centers are converted to normalized coordinates before
/// the inverse quarter turn. This keeps sampling canonical when rendered tile
/// width and height differ. Construction and coordinate conversion reject
/// invalid values in release mode.
final class QuarterTurnPixelTransform {
  QuarterTurnPixelTransform({
    required this.sourcePixelSize,
    required this.destinationPixelSize,
    required this.quarterTurns,
  }) {
    _requirePositiveSize(
      sourcePixelSize,
      argumentName: 'sourcePixelSize',
    );
    _requirePositiveSize(
      destinationPixelSize,
      argumentName: 'destinationPixelSize',
    );
    _requireNormalizedQuarterTurns(quarterTurns);
  }

  /// Unrotated source bitmap size in pixels.
  final GridSize sourcePixelSize;

  /// Rendered rotated bounding-box size in pixels.
  final GridSize destinationPixelSize;

  /// Canonical clockwise quarter turns in `0..3`.
  final int quarterTurns;

  /// Inverse-samples one in-bounds destination pixel into the source bitmap.
  GridPos destinationPixelToSourcePixel(GridPos destination) {
    _requireCoordinateInBounds(
      destination,
      size: destinationPixelSize,
      argumentName: 'destination',
    );

    final u = (destination.x + 0.5) / destinationPixelSize.width;
    final v = (destination.y + 0.5) / destinationPixelSize.height;
    late final double sourceU;
    late final double sourceV;
    switch (quarterTurns) {
      case 0:
        sourceU = u;
        sourceV = v;
      case 1:
        sourceU = v;
        sourceV = 1 - u;
      case 2:
        sourceU = 1 - u;
        sourceV = 1 - v;
      case 3:
        sourceU = 1 - v;
        sourceV = u;
    }

    final sourceX = (sourceU * sourcePixelSize.width)
        .floor()
        .clamp(0, sourcePixelSize.width - 1)
        .toInt();
    final sourceY = (sourceV * sourcePixelSize.height)
        .floor()
        .clamp(0, sourcePixelSize.height - 1)
        .toInt();
    return GridPos(x: sourceX, y: sourceY);
  }
}

void _requirePositiveSize(
  GridSize size, {
  required String argumentName,
}) {
  if (size.width <= 0 || size.height <= 0) {
    throw ArgumentError.value(
      size,
      argumentName,
      'width and height must be positive',
    );
  }
}

void _requireNormalizedQuarterTurns(int quarterTurns) {
  if (quarterTurns < 0 || quarterTurns > 3) {
    throw RangeError.range(
      quarterTurns,
      0,
      3,
      'quarterTurns',
    );
  }
}

void _requireCoordinateInBounds(
  GridPos coordinate, {
  required GridSize size,
  required String argumentName,
}) {
  if (coordinate.x < 0 ||
      coordinate.y < 0 ||
      coordinate.x >= size.width ||
      coordinate.y >= size.height) {
    throw RangeError(
      '$argumentName coordinate (${coordinate.x}, ${coordinate.y}) is outside '
      '${size.width}x${size.height}',
    );
  }
}
