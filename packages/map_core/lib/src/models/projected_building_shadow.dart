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

enum ProjectedBuildingShadowGeometryMode {
  directional,
  footprint,
}

enum ProjectedBuildingShadowCasterKind {
  building,
  largeVolume,
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

/// Parametric footprint tuning for a broad building shadow attached to bounds.
@immutable
final class ProjectedShadowFootprintTuning {
  factory ProjectedShadowFootprintTuning({
    double attachYRatio = 0.86,
    double frontWidthRatio = 1.10,
    double rearWidthRatio = 1.20,
    double depthRatio = 0.28,
    double skewXRatio = 0.10,
  }) {
    _validateRatio01(
      attachYRatio,
      'ProjectedShadowFootprintTuning.attachYRatio',
    );
    _validatePositiveRatioMax(
      frontWidthRatio,
      'ProjectedShadowFootprintTuning.frontWidthRatio',
      2.0,
    );
    _validatePositiveRatioMax(
      rearWidthRatio,
      'ProjectedShadowFootprintTuning.rearWidthRatio',
      2.0,
    );
    _validatePositiveRatioMax(
      depthRatio,
      'ProjectedShadowFootprintTuning.depthRatio',
      1.0,
    );
    _validateFinite(skewXRatio, 'ProjectedShadowFootprintTuning.skewXRatio');
    if (skewXRatio < -0.5 || skewXRatio > 0.5) {
      throw const ValidationException(
        'ProjectedShadowFootprintTuning.skewXRatio must be between -0.5 and 0.5',
      );
    }
    return ProjectedShadowFootprintTuning._(
      attachYRatio: attachYRatio,
      frontWidthRatio: frontWidthRatio,
      rearWidthRatio: rearWidthRatio,
      depthRatio: depthRatio,
      skewXRatio: skewXRatio,
    );
  }

  const ProjectedShadowFootprintTuning._({
    required this.attachYRatio,
    required this.frontWidthRatio,
    required this.rearWidthRatio,
    required this.depthRatio,
    required this.skewXRatio,
  });

  final double attachYRatio;
  final double frontWidthRatio;
  final double rearWidthRatio;
  final double depthRatio;
  final double skewXRatio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowFootprintTuning &&
          other.attachYRatio == attachYRatio &&
          other.frontWidthRatio == frontWidthRatio &&
          other.rearWidthRatio == rearWidthRatio &&
          other.depthRatio == depthRatio &&
          other.skewXRatio == skewXRatio;

  @override
  int get hashCode => Object.hash(
        attachYRatio,
        frontWidthRatio,
        rearWidthRatio,
        depthRatio,
        skewXRatio,
      );
}

@immutable
sealed class ProjectedShadowFootprintTuningStrategy {
  const ProjectedShadowFootprintTuningStrategy();
}

@immutable
final class ProjectedShadowFootprintFixedTuning
    extends ProjectedShadowFootprintTuningStrategy {
  const ProjectedShadowFootprintFixedTuning({
    required this.tuning,
  });

  final ProjectedShadowFootprintTuning tuning;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowFootprintFixedTuning && other.tuning == tuning;

  @override
  int get hashCode => tuning.hashCode;
}

@immutable
final class ProjectedShadowAdaptiveDepthGate {
  factory ProjectedShadowAdaptiveDepthGate({
    double referenceHeight = 80,
    double targetHeight = 112,
    double referenceRatio = 1.25,
    double targetRatio = 1.75,
  }) {
    _validatePositiveFinite(
      referenceHeight,
      'ProjectedShadowAdaptiveDepthGate.referenceHeight',
    );
    _validatePositiveFinite(
      targetHeight,
      'ProjectedShadowAdaptiveDepthGate.targetHeight',
    );
    if (targetHeight <= referenceHeight) {
      throw const ValidationException(
        'ProjectedShadowAdaptiveDepthGate.targetHeight must be greater than referenceHeight',
      );
    }
    _validatePositiveFinite(
      referenceRatio,
      'ProjectedShadowAdaptiveDepthGate.referenceRatio',
    );
    _validatePositiveFinite(
      targetRatio,
      'ProjectedShadowAdaptiveDepthGate.targetRatio',
    );
    if (targetRatio <= referenceRatio) {
      throw const ValidationException(
        'ProjectedShadowAdaptiveDepthGate.targetRatio must be greater than referenceRatio',
      );
    }
    return ProjectedShadowAdaptiveDepthGate._(
      referenceHeight: referenceHeight,
      targetHeight: targetHeight,
      referenceRatio: referenceRatio,
      targetRatio: targetRatio,
    );
  }

  const ProjectedShadowAdaptiveDepthGate._({
    required this.referenceHeight,
    required this.targetHeight,
    required this.referenceRatio,
    required this.targetRatio,
  });

  final double referenceHeight;
  final double targetHeight;
  final double referenceRatio;
  final double targetRatio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowAdaptiveDepthGate &&
          other.referenceHeight == referenceHeight &&
          other.targetHeight == targetHeight &&
          other.referenceRatio == referenceRatio &&
          other.targetRatio == targetRatio;

  @override
  int get hashCode => Object.hash(
        referenceHeight,
        targetHeight,
        referenceRatio,
        targetRatio,
      );
}

@immutable
final class ProjectedShadowFootprintAdaptiveDepthTuning
    extends ProjectedShadowFootprintTuningStrategy {
  factory ProjectedShadowFootprintAdaptiveDepthTuning({
    required ProjectedShadowFootprintTuning base,
    required ProjectedShadowFootprintTuning target,
    required ProjectedShadowAdaptiveDepthGate gate,
    required double baseOpacity,
    required double targetOpacity,
  }) {
    _validateOpacity(
      baseOpacity,
      'ProjectedShadowFootprintAdaptiveDepthTuning.baseOpacity',
    );
    _validateOpacity(
      targetOpacity,
      'ProjectedShadowFootprintAdaptiveDepthTuning.targetOpacity',
    );
    return ProjectedShadowFootprintAdaptiveDepthTuning._(
      base: base,
      target: target,
      gate: gate,
      baseOpacity: baseOpacity,
      targetOpacity: targetOpacity,
    );
  }

  const ProjectedShadowFootprintAdaptiveDepthTuning._({
    required this.base,
    required this.target,
    required this.gate,
    required this.baseOpacity,
    required this.targetOpacity,
  });

  final ProjectedShadowFootprintTuning base;
  final ProjectedShadowFootprintTuning target;
  final ProjectedShadowAdaptiveDepthGate gate;
  final double baseOpacity;
  final double targetOpacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowFootprintAdaptiveDepthTuning &&
          other.base == base &&
          other.target == target &&
          other.gate == gate &&
          other.baseOpacity == baseOpacity &&
          other.targetOpacity == targetOpacity;

  @override
  int get hashCode => Object.hash(
        base,
        target,
        gate,
        baseOpacity,
        targetOpacity,
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
    ProjectedBuildingShadowGeometryMode geometryMode =
        ProjectedBuildingShadowGeometryMode.directional,
    ProjectedShadowFootprintTuning? footprint,
    String? categoryId,
    int sortOrder = 0,
  }) {
    _validateNonBlank(id, 'ProjectBuildingShadowPreset.id');
    _validateNonBlank(name, 'ProjectBuildingShadowPreset.name');
    final category = categoryId;
    if (category != null) {
      _validateNonBlank(category, 'ProjectBuildingShadowPreset.categoryId');
    }
    _validateProjectedBuildingShadowGeometryMode(
      geometryMode: geometryMode,
      footprint: footprint,
    );
    return ProjectBuildingShadowPreset._(
      id: id,
      name: name,
      direction: direction,
      shape: shape,
      appearance: appearance,
      timeOfDayMode: timeOfDayMode,
      geometryMode: geometryMode,
      footprint: footprint,
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
    required this.geometryMode,
    required this.footprint,
    required this.categoryId,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final ProjectedShadowDirection direction;
  final ProjectedShadowShapeTuning shape;
  final ProjectedShadowAppearance appearance;
  final ProjectedShadowTimeOfDayMode timeOfDayMode;
  final ProjectedBuildingShadowGeometryMode geometryMode;
  final ProjectedShadowFootprintTuning? footprint;
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
          other.geometryMode == geometryMode &&
          other.footprint == footprint &&
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
        geometryMode,
        footprint,
        categoryId,
        sortOrder,
      );
}

/// Ordered in-memory catalog of future projected building shadow presets.
///
/// ShadowV2-6 keeps this as a pure domain collection. It has no JSON shape,
/// manifest integration, default presets, editor behavior, or runtime behavior.
@immutable
final class ProjectBuildingShadowPresetCatalog {
  ProjectBuildingShadowPresetCatalog({
    List<ProjectBuildingShadowPreset> presets = const [],
  }) : _presets = _copyBuildingShadowPresets(presets);

  const ProjectBuildingShadowPresetCatalog.empty() : _presets = const [];

  final List<ProjectBuildingShadowPreset> _presets;

  /// Presets in authored order. The returned list is unmodifiable.
  List<ProjectBuildingShadowPreset> get presets => _presets;

  int get length => _presets.length;

  bool get isEmpty => _presets.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Exact, case-sensitive lookup by [ProjectBuildingShadowPreset.id].
  ProjectBuildingShadowPreset? presetById(String id) {
    for (final preset in _presets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }

  bool containsPresetId(String id) => presetById(id) != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectBuildingShadowPresetCatalog &&
          _projectBuildingShadowPresetsEqualInOrder(_presets, other._presets);

  @override
  int get hashCode => Object.hashAll(_presets);
}

List<ProjectBuildingShadowPreset> _copyBuildingShadowPresets(
  List<ProjectBuildingShadowPreset> presets,
) {
  final copiedPresets = List<ProjectBuildingShadowPreset>.from(presets);
  _rejectDuplicateBuildingShadowPresetIds(copiedPresets);
  return List<ProjectBuildingShadowPreset>.unmodifiable(copiedPresets);
}

void _rejectDuplicateBuildingShadowPresetIds(
  List<ProjectBuildingShadowPreset> presets,
) {
  final seen = <String>{};
  for (final preset in presets) {
    if (!seen.add(preset.id)) {
      throw ArgumentError.value(
        preset.id,
        'presets',
        'ProjectBuildingShadowPresetCatalog.presets must not contain duplicate ProjectBuildingShadowPreset.id',
      );
    }
  }
}

bool _projectBuildingShadowPresetsEqualInOrder(
  List<ProjectBuildingShadowPreset> a,
  List<ProjectBuildingShadowPreset> b,
) {
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

/// Element-level opt-in config for a future projected building shadow.
///
/// ShadowV2-7 keeps this as a pure domain value. It is not attached to
/// ProjectElementEntry, JSON, manifests, runtime resolution, or editor UI.
@immutable
final class ProjectElementProjectedBuildingShadowConfig {
  factory ProjectElementProjectedBuildingShadowConfig({
    required bool enabled,
    required String presetId,
    required ProjectedShadowAnchor anchor,
    required ProjectedShadowOffset localOffset,
  }) {
    _validateNonBlank(
      presetId,
      'ProjectElementProjectedBuildingShadowConfig.presetId',
    );
    return ProjectElementProjectedBuildingShadowConfig._(
      enabled: enabled,
      presetId: presetId,
      anchor: anchor,
      localOffset: localOffset,
    );
  }

  const ProjectElementProjectedBuildingShadowConfig._({
    required this.enabled,
    required this.presetId,
    required this.anchor,
    required this.localOffset,
  });

  final bool enabled;
  final String presetId;
  final ProjectedShadowAnchor anchor;
  final ProjectedShadowOffset localOffset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectElementProjectedBuildingShadowConfig &&
          other.enabled == enabled &&
          other.presetId == presetId &&
          other.anchor == anchor &&
          other.localOffset == localOffset;

  @override
  int get hashCode => Object.hash(
        enabled,
        presetId,
        anchor,
        localOffset,
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

void _validatePositiveRatioMax(double value, String name, double max) {
  _validatePositiveFinite(value, name);
  if (value > max) {
    throw ValidationException('$name must be <= $max');
  }
}

void _validateProjectedBuildingShadowGeometryMode({
  required ProjectedBuildingShadowGeometryMode geometryMode,
  required ProjectedShadowFootprintTuning? footprint,
}) {
  switch (geometryMode) {
    case ProjectedBuildingShadowGeometryMode.directional:
      if (footprint != null) {
        throw const ValidationException(
          'ProjectBuildingShadowPreset.footprint must be null for directional geometry',
        );
      }
    case ProjectedBuildingShadowGeometryMode.footprint:
      if (footprint == null) {
        throw const ValidationException(
          'ProjectBuildingShadowPreset.footprint is required for footprint geometry',
        );
      }
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
