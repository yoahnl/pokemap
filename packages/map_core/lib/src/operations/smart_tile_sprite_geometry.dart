import 'package:meta/meta.dart' show immutable;

import '../models/smart_tile.dart';

/// Stable persisted order of the eight elements of the D4 symmetry group.
///
/// Every transform applies [SmartTileSpriteTransform.flipX] in source
/// coordinates first, then clockwise quarter turns.
const List<SmartTileSpriteTransform> smartTileD4Transforms =
    <SmartTileSpriteTransform>[
  SmartTileSpriteTransform(),
  SmartTileSpriteTransform(quarterTurns: 1),
  SmartTileSpriteTransform(quarterTurns: 2),
  SmartTileSpriteTransform(quarterTurns: 3),
  SmartTileSpriteTransform(flipX: true),
  SmartTileSpriteTransform(quarterTurns: 1, flipX: true),
  SmartTileSpriteTransform(quarterTurns: 2, flipX: true),
  SmartTileSpriteTransform(quarterTurns: 3, flipX: true),
];

@immutable
final class SmartTileGeometryPoint {
  const SmartTileGeometryPoint({required this.x, required this.y});

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartTileGeometryPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'SmartTileGeometryPoint(x: $x, y: $y)';
}

@immutable
final class SmartTileGeometryRect {
  const SmartTileGeometryRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;

  bool intersects(SmartTileGeometryRect other) =>
      left < other.right &&
      right > other.left &&
      top < other.bottom &&
      bottom > other.top;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartTileGeometryRect &&
          other.left == left &&
          other.top == top &&
          other.width == width &&
          other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() =>
      'SmartTileGeometryRect(left: $left, top: $top, width: $width, '
      'height: $height)';
}

@immutable
final class SmartTileSpriteGeometry {
  const SmartTileSpriteGeometry({
    required this.destinationRect,
    required this.visualBounds,
    required this.anchorOffset,
    required this.transformedAnchorOffset,
    required this.transform,
  });

  /// Rectangle passed to the image draw before its D4 canvas transform.
  final SmartTileGeometryRect destinationRect;

  /// Axis-aligned bounds occupied after the D4 transform.
  final SmartTileGeometryRect visualBounds;

  /// Anchor in destination pixels before the D4 transform.
  final SmartTileGeometryPoint anchorOffset;

  /// Anchor transformed into the positive-bounds destination coordinates.
  final SmartTileGeometryPoint transformedAnchorOffset;

  final SmartTileSpriteTransform transform;
}

bool isIdentitySmartTileTransform(SmartTileSpriteTransform transform) =>
    transform.quarterTurns == 0 && !transform.flipX;

SmartTileGeometryPoint transformSmartTileVector(
  SmartTileGeometryPoint vector,
  SmartTileSpriteTransform transform,
) {
  var x = transform.flipX ? -vector.x : vector.x;
  var y = vector.y;
  switch (transform.quarterTurns) {
    case 0:
      break;
    case 1:
      final previousX = x;
      x = -y;
      y = previousX;
    case 2:
      x = -x;
      y = -y;
    case 3:
      final previousX = x;
      x = y;
      y = -previousX;
  }
  return SmartTileGeometryPoint(x: x, y: y);
}

/// Returns the D4 value obtained by applying [first], then [second].
SmartTileSpriteTransform composeSmartTileSpriteTransforms({
  required SmartTileSpriteTransform first,
  required SmartTileSpriteTransform second,
}) {
  final xAxis = transformSmartTileVector(
    transformSmartTileVector(
      const SmartTileGeometryPoint(x: 1, y: 0),
      first,
    ),
    second,
  );
  final yAxis = transformSmartTileVector(
    transformSmartTileVector(
      const SmartTileGeometryPoint(x: 0, y: 1),
      first,
    ),
    second,
  );
  for (final candidate in smartTileD4Transforms) {
    if (transformSmartTileVector(
              const SmartTileGeometryPoint(x: 1, y: 0),
              candidate,
            ) ==
            xAxis &&
        transformSmartTileVector(
              const SmartTileGeometryPoint(x: 0, y: 1),
              candidate,
            ) ==
            yAxis) {
      return candidate;
    }
  }
  throw StateError('The composed transform is not a D4 element.');
}

List<SmartTileSpriteTransform> smartTileAllowedTransforms(
  SmartTileTransformPolicy policy,
) {
  final generators = <SmartTileSpriteTransform>[
    if (policy.allowHFlip) const SmartTileSpriteTransform(flipX: true),
    if (policy.allowVFlip)
      const SmartTileSpriteTransform(quarterTurns: 2, flipX: true),
    if (policy.allowQuarterTurns)
      const SmartTileSpriteTransform(quarterTurns: 1),
  ];
  final generated = <SmartTileSpriteTransform>{
    const SmartTileSpriteTransform(),
  };
  var changed = true;
  while (changed) {
    changed = false;
    final snapshot = generated.toList(growable: false);
    for (final current in snapshot) {
      for (final generator in generators) {
        final composed = composeSmartTileSpriteTransforms(
          first: current,
          second: generator,
        );
        if (generated.add(composed)) changed = true;
      }
    }
  }
  return List<SmartTileSpriteTransform>.unmodifiable(
    smartTileD4Transforms.where(generated.contains),
  );
}

bool smartTileTransformPolicyAllows(
  SmartTileTransformPolicy policy,
  SmartTileSpriteTransform transform,
) =>
    smartTileAllowedTransforms(policy).contains(transform);

SmartTileSignature transformSmartTileSignature(
  SmartTileSignature signature,
  SmartTileSpriteTransform transform,
) {
  var north = const SmartTileSlotMatch.any();
  var northEast = const SmartTileSlotMatch.any();
  var east = const SmartTileSlotMatch.any();
  var southEast = const SmartTileSlotMatch.any();
  var south = const SmartTileSlotMatch.any();
  var southWest = const SmartTileSlotMatch.any();
  var west = const SmartTileSlotMatch.any();
  var northWest = const SmartTileSlotMatch.any();

  void place(
    SmartTileGeometryPoint sourcePosition,
    SmartTileSlotMatch match,
  ) {
    final destination = transformSmartTileVector(sourcePosition, transform);
    switch ((destination.x.toInt(), destination.y.toInt())) {
      case (0, -1):
        north = match;
      case (1, -1):
        northEast = match;
      case (1, 0):
        east = match;
      case (1, 1):
        southEast = match;
      case (0, 1):
        south = match;
      case (-1, 1):
        southWest = match;
      case (-1, 0):
        west = match;
      case (-1, -1):
        northWest = match;
      default:
        throw StateError('Invalid transformed Smart Tile signature slot.');
    }
  }

  place(const SmartTileGeometryPoint(x: 0, y: -1), signature.northEdge);
  place(
    const SmartTileGeometryPoint(x: 1, y: -1),
    signature.northEastCorner,
  );
  place(const SmartTileGeometryPoint(x: 1, y: 0), signature.eastEdge);
  place(
    const SmartTileGeometryPoint(x: 1, y: 1),
    signature.southEastCorner,
  );
  place(const SmartTileGeometryPoint(x: 0, y: 1), signature.southEdge);
  place(
    const SmartTileGeometryPoint(x: -1, y: 1),
    signature.southWestCorner,
  );
  place(const SmartTileGeometryPoint(x: -1, y: 0), signature.westEdge);
  place(
    const SmartTileGeometryPoint(x: -1, y: -1),
    signature.northWestCorner,
  );

  return SmartTileSignature(
    northEdge: north,
    northEastCorner: northEast,
    eastEdge: east,
    southEastCorner: southEast,
    southEdge: south,
    southWestCorner: southWest,
    westEdge: west,
    northWestCorner: northWest,
  );
}

SmartTileSpriteGeometry resolveSmartTileSpriteGeometry({
  required int cellX,
  required int cellY,
  required double destinationCellWidth,
  required double destinationCellHeight,
  required double sourceCellWidth,
  required double sourceCellHeight,
  required SmartTileOffsetUnit offsetUnit,
  required int offsetX,
  required int offsetY,
  required int atlasPixelOffsetX,
  required int atlasPixelOffsetY,
  required int footprintWidth,
  required int footprintHeight,
  required int anchorX,
  required int anchorY,
  required SmartTileSpriteTransform transform,
}) {
  if (destinationCellWidth <= 0 || destinationCellHeight <= 0) {
    throw ArgumentError('Destination cell dimensions must be positive.');
  }
  if (sourceCellWidth <= 0 || sourceCellHeight <= 0) {
    throw ArgumentError('Source cell dimensions must be positive.');
  }
  final scaleX = destinationCellWidth / sourceCellWidth;
  final scaleY = destinationCellHeight / sourceCellHeight;
  final resolvedOffsetX = offsetUnit == SmartTileOffsetUnit.cell
      ? offsetX * destinationCellWidth
      : offsetX * scaleX;
  final resolvedOffsetY = offsetUnit == SmartTileOffsetUnit.cell
      ? offsetY * destinationCellHeight
      : offsetY * scaleY;
  final anchorOffset = SmartTileGeometryPoint(
    x: anchorX * scaleX,
    y: anchorY * scaleY,
  );
  final width = footprintWidth * destinationCellWidth;
  final height = footprintHeight * destinationCellHeight;
  // Anchor the positive transformed bounds to the owner cell. Rotating around
  // the source-space origin would push an ordinary 1x1 autotile outside its
  // cell; [transformedAnchorOffset] still exposes the anchor in output space.
  final left = cellX * destinationCellWidth +
      resolvedOffsetX +
      atlasPixelOffsetX * scaleX -
      anchorOffset.x;
  final top = cellY * destinationCellHeight +
      resolvedOffsetY +
      atlasPixelOffsetY * scaleY -
      anchorOffset.y;
  final destinationRect = SmartTileGeometryRect(
    left: left,
    top: top,
    width: width,
    height: height,
  );
  final swapsAxes = transform.quarterTurns.isOdd;
  return SmartTileSpriteGeometry(
    destinationRect: destinationRect,
    visualBounds: SmartTileGeometryRect(
      left: left,
      top: top,
      width: swapsAxes ? height : width,
      height: swapsAxes ? width : height,
    ),
    anchorOffset: anchorOffset,
    transformedAnchorOffset: _transformPointInPositiveBounds(
      anchorOffset,
      width: width,
      height: height,
      transform: transform,
    ),
    transform: transform,
  );
}

SmartTileGeometryPoint _transformPointInPositiveBounds(
  SmartTileGeometryPoint point, {
  required double width,
  required double height,
  required SmartTileSpriteTransform transform,
}) {
  final x = transform.flipX ? width - point.x : point.x;
  final y = point.y;
  return switch (transform.quarterTurns) {
    0 => SmartTileGeometryPoint(x: x, y: y),
    1 => SmartTileGeometryPoint(x: height - y, y: x),
    2 => SmartTileGeometryPoint(x: width - x, y: height - y),
    3 => SmartTileGeometryPoint(x: y, y: width - x),
    _ => throw ArgumentError.value(
        transform.quarterTurns,
        'transform.quarterTurns',
        'must be between 0 and 3',
      ),
  };
}
