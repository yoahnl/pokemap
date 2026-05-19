import 'dart:math' as math;

import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';

/// Minimal placeholder for future time-aware projected building shadows.
///
/// ShadowV2-4 only models the authoring intent. It does not interpolate light,
/// inspect the clock, or affect runtime rendering.
enum ProjectedShadowTimeOfDayMode {
  fixed,
  followsSun,
}

/// Authored 2D direction for a future projected building shadow.
///
/// The raw values are intentionally preserved so the editor can keep the
/// author's intent. Consumers that need a unit vector can use [normalized].
@immutable
final class ProjectedShadowDirection {
  factory ProjectedShadowDirection({
    required double x,
    required double y,
  }) {
    _validateFinite(x, 'ProjectedShadowDirection.x');
    _validateFinite(y, 'ProjectedShadowDirection.y');
    if (x == 0 && y == 0) {
      throw const ValidationException(
        'ProjectedShadowDirection must not be the zero vector',
      );
    }
    return ProjectedShadowDirection._(x: x, y: y);
  }

  const ProjectedShadowDirection._({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;

  double get magnitude => math.sqrt(x * x + y * y);

  ProjectedShadowDirection get normalized {
    final length = magnitude;
    return ProjectedShadowDirection(x: x / length, y: y / length);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowDirection && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Local anchor on the source building asset, expressed as normalized ratios.
@immutable
final class ProjectedShadowAnchor {
  factory ProjectedShadowAnchor({
    required double xRatio,
    required double yRatio,
  }) {
    _validateRatio01(xRatio, 'ProjectedShadowAnchor.xRatio');
    _validateRatio01(yRatio, 'ProjectedShadowAnchor.yRatio');
    return ProjectedShadowAnchor._(xRatio: xRatio, yRatio: yRatio);
  }

  const ProjectedShadowAnchor._({
    required this.xRatio,
    required this.yRatio,
  });

  final double xRatio;
  final double yRatio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowAnchor &&
          other.xRatio == xRatio &&
          other.yRatio == yRatio;

  @override
  int get hashCode => Object.hash(xRatio, yRatio);
}

/// Local authored offset applied after the anchor is resolved.
@immutable
final class ProjectedShadowOffset {
  factory ProjectedShadowOffset({
    required double x,
    required double y,
  }) {
    _validateFinite(x, 'ProjectedShadowOffset.x');
    _validateFinite(y, 'ProjectedShadowOffset.y');
    return ProjectedShadowOffset._(x: x, y: y);
  }

  const ProjectedShadowOffset._({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowOffset && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Parametric shape tuning for a simple projected building shadow.
@immutable
final class ProjectedShadowShapeTuning {
  factory ProjectedShadowShapeTuning({
    required double lengthRatio,
    required double nearWidthRatio,
    required double farWidthRatio,
  }) {
    _validateNonNegativeFinite(
      lengthRatio,
      'ProjectedShadowShapeTuning.lengthRatio',
    );
    _validatePositiveFinite(
      nearWidthRatio,
      'ProjectedShadowShapeTuning.nearWidthRatio',
    );
    _validatePositiveFinite(
      farWidthRatio,
      'ProjectedShadowShapeTuning.farWidthRatio',
    );
    return ProjectedShadowShapeTuning._(
      lengthRatio: lengthRatio,
      nearWidthRatio: nearWidthRatio,
      farWidthRatio: farWidthRatio,
    );
  }

  const ProjectedShadowShapeTuning._({
    required this.lengthRatio,
    required this.nearWidthRatio,
    required this.farWidthRatio,
  });

  final double lengthRatio;
  final double nearWidthRatio;
  final double farWidthRatio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowShapeTuning &&
          other.lengthRatio == lengthRatio &&
          other.nearWidthRatio == nearWidthRatio &&
          other.farWidthRatio == farWidthRatio;

  @override
  int get hashCode => Object.hash(
        lengthRatio,
        nearWidthRatio,
        farWidthRatio,
      );
}

/// Simple visual appearance for a future projected building shadow.
@immutable
final class ProjectedShadowAppearance {
  factory ProjectedShadowAppearance({
    double opacity = 0.18,
    String colorHexRgb = '000000',
  }) {
    _validateOpacity(opacity, 'ProjectedShadowAppearance.opacity');
    return ProjectedShadowAppearance._(
      opacity: opacity,
      colorHexRgb: _normalizeColorHexRgb(colorHexRgb),
    );
  }

  const ProjectedShadowAppearance._({
    required this.opacity,
    required this.colorHexRgb,
  });

  final double opacity;
  final String colorHexRgb;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowAppearance &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb;

  @override
  int get hashCode => Object.hash(opacity, colorHexRgb);
}

/// Reusable parametric preset for a future authored building shadow.
///
/// This model is intentionally not connected to JSON, manifests, runtime
/// resolution, or editor UI in ShadowV2-5.
@immutable
final class ProjectBuildingShadowPreset {
  factory ProjectBuildingShadowPreset({
    required String id,
    required String name,
    required ProjectedShadowDirection direction,
    required ProjectedShadowShapeTuning shape,
    required ProjectedShadowAppearance appearance,
    required ProjectedShadowTimeOfDayMode timeOfDayMode,
    String? categoryId,
    int sortOrder = 0,
  }) {
    _validateNonBlank(id, 'ProjectBuildingShadowPreset.id');
    _validateNonBlank(name, 'ProjectBuildingShadowPreset.name');
    final category = categoryId;
    if (category != null) {
      _validateNonBlank(category, 'ProjectBuildingShadowPreset.categoryId');
    }
    return ProjectBuildingShadowPreset._(
      id: id,
      name: name,
      direction: direction,
      shape: shape,
      appearance: appearance,
      timeOfDayMode: timeOfDayMode,
      categoryId: categoryId,
      sortOrder: sortOrder,
    );
  }

  const ProjectBuildingShadowPreset._({
    required this.id,
    required this.name,
    required this.direction,
    required this.shape,
    required this.appearance,
    required this.timeOfDayMode,
    required this.categoryId,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final ProjectedShadowDirection direction;
  final ProjectedShadowShapeTuning shape;
  final ProjectedShadowAppearance appearance;
  final ProjectedShadowTimeOfDayMode timeOfDayMode;
  final String? categoryId;
  final int sortOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectBuildingShadowPreset &&
          other.id == id &&
          other.name == name &&
          other.direction == direction &&
          other.shape == shape &&
          other.appearance == appearance &&
          other.timeOfDayMode == timeOfDayMode &&
          other.categoryId == categoryId &&
          other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        direction,
        shape,
        appearance,
        timeOfDayMode,
        categoryId,
        sortOrder,
      );
}

void _validateNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, '$name must be non-empty');
  }
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('$name must be finite');
  }
}

void _validateRatio01(double value, String name) {
  _validateFinite(value, name);
  if (value < 0 || value > 1) {
    throw ValidationException('$name must be between 0 and 1');
  }
}

void _validateNonNegativeFinite(double value, String name) {
  _validateFinite(value, name);
  if (value < 0) {
    throw ValidationException('$name must be >= 0');
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException('$name must be > 0');
  }
}

void _validateOpacity(double value, String name) {
  _validateRatio01(value, name);
}

String _normalizeColorHexRgb(String value) {
  if (value.length != 6 || !_isHexRgb(value)) {
    throw ValidationException(
      'ProjectedShadowAppearance.colorHexRgb must contain exactly '
      '6 hexadecimal RGB characters without #',
    );
  }
  return value.toUpperCase();
}

bool _isHexRgb(String value) {
  for (var index = 0; index < value.length; index += 1) {
    final codeUnit = value.codeUnitAt(index);
    final isDigit = codeUnit >= 0x30 && codeUnit <= 0x39;
    final isUppercaseHex = codeUnit >= 0x41 && codeUnit <= 0x46;
    final isLowercaseHex = codeUnit >= 0x61 && codeUnit <= 0x66;
    if (!isDigit && !isUppercaseHex && !isLowercaseHex) {
      return false;
    }
  }
  return true;
}
