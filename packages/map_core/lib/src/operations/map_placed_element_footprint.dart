import '../collision/pixel_rect.dart';
import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_placed_element_origin.dart';
import '../models/project_manifest.dart';
import '../models/project_tileset_source.dart';

const int maxMapPlacedElementPixelArea = 1048576;

final class MapPlacedElementGeometry {
  const MapPlacedElementGeometry({
    required this.logicalRect,
    required this.naturalPixelSize,
    required this.pixelSize,
    required this.cellBounds,
  });

  final PixelRect logicalRect;
  final PixelSize naturalPixelSize;
  final PixelSize pixelSize;
  final MapRect cellBounds;
}

MapPlacedElementGeometry resolveMapPlacedElementGeometry({
  required MapPlacedElement instance,
  required ProjectElementEntry element,
  required PixelSize tileSize,
}) {
  validateMapPlacedElementPixelGeometry(instance, tileSize: tileSize);
  final footprint = resolveMapPlacedElementFootprint(
    instance: instance,
    element: element,
  ).destinationSize;
  final naturalSize = PixelSize(
    width: _checkedPixelProduct(footprint.width, tileSize.width),
    height: _checkedPixelProduct(footprint.height, tileSize.height),
  );
  final size = instance.pixelSize ?? naturalSize;
  final left = _checkedPixelSum(
    _checkedPixelProduct(instance.pos.x, tileSize.width),
    instance.pixelOffset.x,
  );
  final top = _checkedPixelSum(
    _checkedPixelProduct(instance.pos.y, tileSize.height),
    instance.pixelOffset.y,
  );
  final right = _checkedPixelSum(left, size.width);
  final bottom = _checkedPixelSum(top, size.height);
  final cellX = _pixelFloorDivide(left, tileSize.width);
  final cellY = _pixelFloorDivide(top, tileSize.height);
  return MapPlacedElementGeometry(
    logicalRect: PixelRect(
      leftPx: left,
      topPx: top,
      widthPx: size.width,
      heightPx: size.height,
    ),
    naturalPixelSize: naturalSize,
    pixelSize: size,
    cellBounds: MapRect(
      pos: GridPos(x: cellX, y: cellY),
      size: GridSize(
        width: _pixelFloorDivide(right - 1, tileSize.width) + 1 - cellX,
        height: _pixelFloorDivide(bottom - 1, tileSize.height) + 1 - cellY,
      ),
    ),
  );
}

MapPlacedElement normalizeMapPlacedElementGeometry(
  MapPlacedElement instance, {
  required PixelSize tileSize,
}) {
  _requirePixelSize(tileSize);
  final x = _checkedPixelSum(
    _checkedPixelProduct(instance.pos.x, tileSize.width),
    instance.pixelOffset.x,
  );
  final y = _checkedPixelSum(
    _checkedPixelProduct(instance.pos.y, tileSize.height),
    instance.pixelOffset.y,
  );
  return instance.copyWith(
    pos: GridPos(
      x: _pixelFloorDivide(x, tileSize.width),
      y: _pixelFloorDivide(y, tileSize.height),
    ),
    pixelOffset: PixelOffset(x: x % tileSize.width, y: y % tileSize.height),
  );
}

PixelRect resolveMapPlacedElementVisualRect({
  required MapPlacedElementGeometry geometry,
  required ProjectTilesetSource? tilesetSource,
}) {
  final rect = geometry.logicalRect;
  if (tilesetSource is! ProjectRegularAtlasTilesetSource) return rect;
  final left = _checkedPixelSum(rect.leftPx, tilesetSource.pixelOffsetX);
  final top = _checkedPixelSum(rect.topPx, tilesetSource.pixelOffsetY);
  _checkedPixelSum(left, rect.widthPx);
  _checkedPixelSum(top, rect.heightPx);
  return PixelRect(
    leftPx: left,
    topPx: top,
    widthPx: rect.widthPx,
    heightPx: rect.heightPx,
  );
}

PixelRect resolveMapPlacedElementVisualBounds({
  required MapPlacedElement instance,
  required ProjectElementEntry element,
  required ProjectManifest manifest,
  Map<String, ProjectTilesetSource?>? tilesetSources,
}) {
  final geometry = resolveMapPlacedElementGeometry(
    instance: instance,
    element: element,
    tileSize: PixelSize(
      width: manifest.settings.tileWidth,
      height: manifest.settings.tileHeight,
    ),
  );
  final sources = tilesetSources ?? {
    for (final tileset in manifest.tilesets) tileset.id: tileset.source,
  };
  PixelRect? bounds;
  for (final frame in element.frames) {
    final tilesetId = frame.tilesetId.trim().isEmpty
        ? element.tilesetId.trim()
        : frame.tilesetId.trim();
    final rect = resolveMapPlacedElementVisualRect(
      geometry: geometry,
      tilesetSource: sources[tilesetId],
    );
    final current = bounds;
    if (current == null) {
      bounds = rect;
      continue;
    }
    final left = current.leftPx < rect.leftPx ? current.leftPx : rect.leftPx;
    final top = current.topPx < rect.topPx ? current.topPx : rect.topPx;
    final right = current.leftPx + current.widthPx > rect.leftPx + rect.widthPx
        ? current.leftPx + current.widthPx
        : rect.leftPx + rect.widthPx;
    final bottom = current.topPx + current.heightPx > rect.topPx + rect.heightPx
        ? current.topPx + current.heightPx
        : rect.topPx + rect.heightPx;
    bounds = PixelRect(
      leftPx: left,
      topPx: top,
      widthPx: _checkedPixelSum(right, -left),
      heightPx: _checkedPixelSum(bottom, -top),
    );
  }
  return bounds ?? geometry.logicalRect;
}

void validateMapPlacedElementPixelGeometry(
  MapPlacedElement instance, {
  PixelSize? tileSize,
}) {
  final offset = instance.pixelOffset;
  _requireExactPixelInteger(offset.x);
  _requireExactPixelInteger(offset.y);
  final size = instance.pixelSize;
  if (size != null) {
    _requirePixelSize(size);
    if (size.width > maxMapPlacedElementPixelArea ~/ size.height) {
      throw const ValidationException(
        'Placed element custom pixel area exceeds $maxMapPlacedElementPixelArea pixels',
      );
    }
  }
  final transformed = offset.x != 0 || offset.y != 0 || size != null;
  if (transformed && !isAuthoredMapPlacedElement(instance)) {
    throw const ValidationException(
      'Pixel transformations require an authored placed element',
    );
  }
  if (tileSize == null) {
    if (transformed) {
      throw const ValidationException(
        'Pixel transformation validation requires project tile dimensions',
      );
    }
    return;
  }
  _requirePixelSize(tileSize);
  if (offset.x < 0 ||
      offset.y < 0 ||
      offset.x >= tileSize.width ||
      offset.y >= tileSize.height) {
    throw const ValidationException(
      'Placed element pixel offsets must be normalized',
    );
  }
}

void validateMapPlacedElementGeometryBounds({
  required MapPlacedElementGeometry geometry,
  required GridSize mapSize,
  required PixelSize tileSize,
}) {
  final width = _checkedPixelProduct(mapSize.width, tileSize.width);
  final height = _checkedPixelProduct(mapSize.height, tileSize.height);
  final rect = geometry.logicalRect;
  if (rect.leftPx < 0 ||
      rect.topPx < 0 ||
      rect.leftPx + rect.widthPx > width ||
      rect.topPx + rect.heightPx > height) {
    throw const ValidationException(
      'Placed element pixel footprint exceeds map bounds',
    );
  }
}

void _requirePixelSize(PixelSize size) {
  _requireExactPixelInteger(size.width);
  _requireExactPixelInteger(size.height);
  if (size.width < 1 || size.height < 1) {
    throw const ValidationException('Pixel dimensions must be positive');
  }
}

int _pixelFloorDivide(int value, int divisor) =>
    value ~/ divisor - (value < 0 && value % divisor != 0 ? 1 : 0);

void _requireExactPixelInteger(int value) {
  if (value < -_maxExactlyRepresentableWebInteger ||
      value > _maxExactlyRepresentableWebInteger) {
    throw const ValidationException(
      'Pixel geometry exceeds exact integer representation',
    );
  }
}

int _checkedPixelProduct(int a, int b) {
  _requireExactPixelInteger(a);
  _requireExactPixelInteger(b);
  if (b != 0 && a.abs() > _maxExactlyRepresentableWebInteger ~/ b.abs()) {
    throw const ValidationException(
      'Pixel geometry exceeds exact integer representation',
    );
  }
  return a * b;
}

int _checkedPixelSum(int a, int b) {
  _requireExactPixelInteger(a);
  _requireExactPixelInteger(b);
  final result = a + b;
  _requireExactPixelInteger(result);
  return result;
}

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
/// the inverse quarter turn. The normalized centers are evaluated as exact
/// rational numbers so sampling stays stable at pixel boundaries and when
/// rendered tile width and height differ. Construction and coordinate
/// conversion reject invalid values in release mode.
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

  PixelRect sourcePixelRectToDestinationPixelRect(PixelRect source) {
    if (source.leftPx < 0 ||
        source.topPx < 0 ||
        source.widthPx <= 0 ||
        source.heightPx <= 0 ||
        source.widthPx > sourcePixelSize.width - source.leftPx ||
        source.heightPx > sourcePixelSize.height - source.topPx) {
      throw RangeError('Source pixel rectangle is outside the source bitmap');
    }
    final xLength = quarterTurns.isEven
        ? destinationPixelSize.width
        : destinationPixelSize.height;
    final yLength = quarterTurns.isEven
        ? destinationPixelSize.height
        : destinationPixelSize.width;
    var left = _inversePixelCenterBoundary(
      source.leftPx,
      sourcePixelSize.width,
      xLength,
    );
    var right = _inversePixelCenterBoundary(
      source.leftPx + source.widthPx,
      sourcePixelSize.width,
      xLength,
    );
    var top = _inversePixelCenterBoundary(
      source.topPx,
      sourcePixelSize.height,
      yLength,
    );
    var bottom = _inversePixelCenterBoundary(
      source.topPx + source.heightPx,
      sourcePixelSize.height,
      yLength,
    );
    if (quarterTurns == 2 || quarterTurns == 3) {
      (left, right) = (xLength - right, xLength - left);
    }
    if (quarterTurns == 1 || quarterTurns == 2) {
      (top, bottom) = (yLength - bottom, yLength - top);
    }
    return quarterTurns.isEven
        ? PixelRect(
            leftPx: left,
            topPx: top,
            widthPx: right - left,
            heightPx: bottom - top,
          )
        : PixelRect(
            leftPx: top,
            topPx: left,
            widthPx: bottom - top,
            heightPx: right - left,
          );
  }

  /// Inverse-samples one in-bounds destination pixel into the source bitmap.
  GridPos destinationPixelToSourcePixel(GridPos destination) {
    _requireCoordinateInBounds(
      destination,
      size: destinationPixelSize,
      argumentName: 'destination',
    );

    late final int sourceX;
    late final int sourceY;
    switch (quarterTurns) {
      case 0:
        sourceX = _samplePixelCenter(
          destinationCoordinate: destination.x,
          destinationLength: destinationPixelSize.width,
          sourceLength: sourcePixelSize.width,
        );
        sourceY = _samplePixelCenter(
          destinationCoordinate: destination.y,
          destinationLength: destinationPixelSize.height,
          sourceLength: sourcePixelSize.height,
        );
      case 1:
        sourceX = _samplePixelCenter(
          destinationCoordinate: destination.y,
          destinationLength: destinationPixelSize.height,
          sourceLength: sourcePixelSize.width,
        );
        sourceY = _samplePixelCenter(
          destinationCoordinate: destination.x,
          destinationLength: destinationPixelSize.width,
          sourceLength: sourcePixelSize.height,
          inverted: true,
        );
      case 2:
        sourceX = _samplePixelCenter(
          destinationCoordinate: destination.x,
          destinationLength: destinationPixelSize.width,
          sourceLength: sourcePixelSize.width,
          inverted: true,
        );
        sourceY = _samplePixelCenter(
          destinationCoordinate: destination.y,
          destinationLength: destinationPixelSize.height,
          sourceLength: sourcePixelSize.height,
          inverted: true,
        );
      case 3:
        sourceX = _samplePixelCenter(
          destinationCoordinate: destination.y,
          destinationLength: destinationPixelSize.height,
          sourceLength: sourcePixelSize.width,
          inverted: true,
        );
        sourceY = _samplePixelCenter(
          destinationCoordinate: destination.x,
          destinationLength: destinationPixelSize.width,
          sourceLength: sourcePixelSize.height,
        );
    }

    return GridPos(x: sourceX, y: sourceY);
  }
}

const int _maxExactlyRepresentableWebInteger = 9007199254740991;

int _inversePixelCenterBoundary(
  int boundary,
  int sourceLength,
  int destinationLength,
) {
  if (sourceLength <= _maxExactlyRepresentableWebInteger ~/ 2 &&
      destinationLength <= _maxExactlyRepresentableWebInteger ~/ 2 &&
      (boundary == 0 ||
          destinationLength * 2 <=
              _maxExactlyRepresentableWebInteger ~/ boundary)) {
    final numerator = destinationLength * 2 * boundary - sourceLength;
    final denominator = sourceLength * 2;
    final value =
        numerator ~/ denominator +
        (numerator > 0 && numerator % denominator != 0 ? 1 : 0);
    return value.clamp(0, destinationLength);
  }
  final numerator =
      BigInt.from(destinationLength) * BigInt.two * BigInt.from(boundary) -
      BigInt.from(sourceLength);
  final denominator = BigInt.from(sourceLength) * BigInt.two;
  final value =
      numerator ~/ denominator +
      (numerator > BigInt.zero && numerator % denominator != BigInt.zero
          ? BigInt.one
          : BigInt.zero);
  return value.toInt().clamp(0, destinationLength);
}

/// Evaluates an exact normalized center without floating-point intermediates.
///
/// This is equivalent to
/// `floor(sourceLength * (2 * center + 1) / (2 * destinationLength))`.
int _samplePixelCenter({
  required int destinationCoordinate,
  required int destinationLength,
  required int sourceLength,
  bool inverted = false,
}) {
  // Keep the common path on `int` only while every intermediate is exactly
  // representable by Dart's 53-bit web integers.
  if (destinationLength <= _maxExactlyRepresentableWebInteger ~/ 2) {
    final centerIndex = inverted
        ? destinationLength - 1 - destinationCoordinate
        : destinationCoordinate;
    final centerNumerator = centerIndex * 2 + 1;
    if (sourceLength <= _maxExactlyRepresentableWebInteger ~/ centerNumerator) {
      final sampled =
          (centerNumerator * sourceLength) ~/ (destinationLength * 2);
      return sampled.clamp(0, sourceLength - 1).toInt();
    }
  }

  final destinationLengthBig = BigInt.from(destinationLength);
  final destinationCoordinateBig = BigInt.from(destinationCoordinate);
  final centerIndexBig = inverted
      ? destinationLengthBig - BigInt.one - destinationCoordinateBig
      : destinationCoordinateBig;
  final sampled = ((centerIndexBig * BigInt.two + BigInt.one) *
          BigInt.from(sourceLength)) ~/
      (destinationLengthBig * BigInt.two);
  final sourceMax = BigInt.from(sourceLength) - BigInt.one;
  final clamped = sampled < BigInt.zero
      ? BigInt.zero
      : sampled > sourceMax
          ? sourceMax
          : sampled;
  return clamped.toInt();
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
