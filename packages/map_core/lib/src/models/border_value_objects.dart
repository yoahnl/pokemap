import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';

final BigInt _minSignedInt64 = BigInt.parse('-9223372036854775808');
final BigInt _maxSignedInt64 = BigInt.parse('9223372036854775807');

/// Closed set of Border Studio templates supported by V1.
enum BorderBlueprintTemplate {
  organicEdge,
  masonryLine,
  postAndRailLine,
  connectedLine,
  stoneChainLine,
}

/// Coordinate space used by authored stroke points.
enum BorderStrokeAlignment { cellCenters, gridEdges }

/// Visual normal selected for an entire connected-line feature.
enum BorderLineSide { primary, inverted }

/// Authored cardinal orientation of one Border primitive.
enum BorderPrimitiveOrientation { legacyAxis, east, south, west, north }

/// Functional primitive roles supported by V1.
enum BorderPrimitiveRole {
  structureLarge,
  structureMedium,
  filler,
  accent,
  post,
  span,
  surfacePatch,
  outerAccent,
  lineCap,
  lineStraight,
  lineCorner,
}

/// Stable persisted spelling shared by strict codecs and fingerprints.
String borderBlueprintTemplateV1WireName(
  BorderBlueprintTemplate template,
) =>
    switch (template) {
      BorderBlueprintTemplate.organicEdge => 'organicEdge',
      BorderBlueprintTemplate.masonryLine => 'masonryLine',
      BorderBlueprintTemplate.postAndRailLine => 'postAndRailLine',
      BorderBlueprintTemplate.connectedLine => 'connectedLine',
      BorderBlueprintTemplate.stoneChainLine => 'stoneChainLine',
    };

/// Stable persisted spelling shared by strict codecs and fingerprints.
String borderStrokeAlignmentV1WireName(BorderStrokeAlignment alignment) =>
    switch (alignment) {
      BorderStrokeAlignment.cellCenters => 'cellCenters',
      BorderStrokeAlignment.gridEdges => 'gridEdges',
    };

/// Stable persisted spelling shared by strict codecs and fingerprints.
String borderPrimitiveOrientationV1WireName(
  BorderPrimitiveOrientation orientation,
) =>
    switch (orientation) {
      BorderPrimitiveOrientation.legacyAxis => 'legacyAxis',
      BorderPrimitiveOrientation.east => 'east',
      BorderPrimitiveOrientation.south => 'south',
      BorderPrimitiveOrientation.west => 'west',
      BorderPrimitiveOrientation.north => 'north',
    };

/// Fixed cardinal vocabulary used by V1 Border geometry and slot keys.
enum BorderCardinalDirection {
  east,
  south,
  west,
  north,
}

/// Stable V1 rank independent of enum declaration mechanics.
int borderCardinalDirectionV1Rank(BorderCardinalDirection direction) =>
    switch (direction) {
      BorderCardinalDirection.east => 0,
      BorderCardinalDirection.south => 1,
      BorderCardinalDirection.west => 2,
      BorderCardinalDirection.north => 3,
    };

/// Stable V1 wire spelling independent of enum declaration mechanics.
String borderCardinalDirectionV1WireName(
  BorderCardinalDirection direction,
) =>
    switch (direction) {
      BorderCardinalDirection.east => 'east',
      BorderCardinalDirection.south => 'south',
      BorderCardinalDirection.west => 'west',
      BorderCardinalDirection.north => 'north',
    };

/// Stable V1 primitive-role wire spelling shared by keys and fingerprints.
String borderPrimitiveRoleV1WireName(BorderPrimitiveRole role) =>
    switch (role) {
      BorderPrimitiveRole.structureLarge => 'structureLarge',
      BorderPrimitiveRole.structureMedium => 'structureMedium',
      BorderPrimitiveRole.filler => 'filler',
      BorderPrimitiveRole.accent => 'accent',
      BorderPrimitiveRole.post => 'post',
      BorderPrimitiveRole.span => 'span',
      BorderPrimitiveRole.surfacePatch => 'surfacePatch',
      BorderPrimitiveRole.outerAccent => 'outerAccent',
      BorderPrimitiveRole.lineCap => 'lineCap',
      BorderPrimitiveRole.lineStraight => 'lineStraight',
      BorderPrimitiveRole.lineCorner => 'lineCorner',
    };

/// Integer pixel position owned by the Border domain.
///
/// Coordinates may be negative because resolved visual bounds may extend past
/// the map canvas. This type deliberately has no dependency on collision code.
@immutable
final class BorderPixelPos {
  const BorderPixelPos({required this.x, required this.y});

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPixelPos && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'BorderPixelPos(x: $x, y: $y)';
}

/// Integer pixel rectangle owned by the Border domain.
///
/// [x] and [y] may be negative. Dimensions are always strictly positive.
@immutable
final class BorderPixelRect {
  factory BorderPixelRect({
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    _requireSignedInt64(x, 'BorderPixelRect.x');
    _requireSignedInt64(y, 'BorderPixelRect.y');
    _requireSignedInt64(width, 'BorderPixelRect.width');
    _requireSignedInt64(height, 'BorderPixelRect.height');
    if (width <= 0) {
      throw const ValidationException('BorderPixelRect.width must be > 0');
    }
    if (height <= 0) {
      throw const ValidationException('BorderPixelRect.height must be > 0');
    }
    if (BigInt.from(x) + BigInt.from(width) > _maxSignedInt64) {
      throw const ValidationException(
        'BorderPixelRect.right must fit signed 64-bit range',
      );
    }
    if (BigInt.from(y) + BigInt.from(height) > _maxSignedInt64) {
      throw const ValidationException(
        'BorderPixelRect.bottom must fit signed 64-bit range',
      );
    }
    return BorderPixelRect._(
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  const BorderPixelRect._({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  /// Exclusive right edge.
  int get right => x + width;

  /// Exclusive bottom edge.
  int get bottom => y + height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPixelRect &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() =>
      'BorderPixelRect(x: $x, y: $y, width: $width, height: $height)';
}

/// Pixel-art transforms explicitly permitted for one primitive.
///
/// Quarter turns are copied, validated, sorted, and exposed as an
/// unmodifiable canonical list.
@immutable
final class BorderTransformPolicy {
  BorderTransformPolicy({
    required this.allowFlipX,
    required List<int> allowedQuarterTurns,
  }) : _allowedQuarterTurns = _canonicalQuarterTurns(allowedQuarterTurns);

  final bool allowFlipX;
  final List<int> _allowedQuarterTurns;

  List<int> get allowedQuarterTurns => _allowedQuarterTurns;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderTransformPolicy &&
          allowFlipX == other.allowFlipX &&
          _listsEqual(_allowedQuarterTurns, other._allowedQuarterTurns);

  @override
  int get hashCode => Object.hash(
        allowFlipX,
        Object.hashAll(_allowedQuarterTurns),
      );
}

/// Integer-only deterministic generation controls.
@immutable
final class BorderGenerationParams {
  BorderGenerationParams({
    required this.irregularityPermille,
    required this.detailDensityPermille,
    required this.variationPermille,
    required this.maxOverlapPx,
    required this.gapTolerancePx,
    required this.depthRows,
    this.allowAutoRotation = true,
  }) {
    _requirePermille(irregularityPermille, 'irregularityPermille');
    _requirePermille(detailDensityPermille, 'detailDensityPermille');
    _requirePermille(variationPermille, 'variationPermille');
    _requireNonNegative(maxOverlapPx, 'maxOverlapPx');
    _requireNonNegative(gapTolerancePx, 'gapTolerancePx');
    if (depthRows < 1) {
      throw const ValidationException(
        'BorderGenerationParams.depthRows must be >= 1',
      );
    }
  }

  final int irregularityPermille;
  final int detailDensityPermille;
  final int variationPermille;
  final int maxOverlapPx;
  final int gapTolerancePx;
  final int depthRows;
  final bool allowAutoRotation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderGenerationParams &&
          irregularityPermille == other.irregularityPermille &&
          detailDensityPermille == other.detailDensityPermille &&
          variationPermille == other.variationPermille &&
          maxOverlapPx == other.maxOverlapPx &&
          gapTolerancePx == other.gapTolerancePx &&
          depthRows == other.depthRows &&
          allowAutoRotation == other.allowAutoRotation;

  @override
  int get hashCode => Object.hash(
        irregularityPermille,
        detailDensityPermille,
        variationPermille,
        maxOverlapPx,
        gapTolerancePx,
        depthRows,
        allowAutoRotation,
      );
}

List<int> _canonicalQuarterTurns(List<int> values) {
  final result = List<int>.from(values)..sort();
  for (var index = 0; index < result.length; index += 1) {
    final value = result[index];
    if (value < 0 || value > 3) {
      throw const ValidationException(
        'BorderTransformPolicy.allowedQuarterTurns must contain only 0..3',
      );
    }
    if (index > 0 && result[index - 1] == value) {
      throw const ValidationException(
        'BorderTransformPolicy.allowedQuarterTurns must be unique',
      );
    }
  }
  return List<int>.unmodifiable(result);
}

void _requirePermille(int value, String field) {
  if (value < 0 || value > 1000) {
    throw ValidationException(
      'BorderGenerationParams.$field must be between 0 and 1000',
    );
  }
}

void _requireNonNegative(int value, String field) {
  if (value < 0) {
    throw ValidationException('BorderGenerationParams.$field must be >= 0');
  }
}

void _requireSignedInt64(int value, String field) {
  final exactValue = BigInt.from(value);
  if (exactValue < _minSignedInt64 || exactValue > _maxSignedInt64) {
    throw ValidationException('$field must fit signed 64-bit range');
  }
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
