import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';

/// How a project shadow profile describes its V0 shape.
enum ShadowCasterMode {
  /// Valid profile that intentionally emits no shadow.
  none,

  /// Small contact shadow for an actor or small object.
  contactBlob,

  /// Elliptical ground shadow for a simple static object.
  ellipse,
}

/// Constrained visual pass for V0 shadow rendering.
enum ShadowRenderPass {
  /// Ground-level shadow for static map elements.
  groundStatic,

  /// Contact shadow tied to a dynamic actor.
  actorContact,
}

/// V0 softness contract. Runtime blur is intentionally not represented.
enum ShadowSoftnessMode {
  /// Pixel-art friendly hard edge with no runtime blur.
  hardEdge,
}

/// Pure authoring profile for a simple V0 shadow.
///
/// This model has no JSON API and no dependency on Flutter or Flame.
@immutable
final class ProjectShadowProfile {
  ProjectShadowProfile({
    required this.id,
    required this.name,
    required this.mode,
    required this.renderPass,
    this.offsetX = 0,
    this.offsetY = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.opacity = 0.35,
    String colorHexRgb = '000000',
    this.softnessMode = ShadowSoftnessMode.hardEdge,
  }) : colorHexRgb = _normalizeColorHexRgb(colorHexRgb) {
    _validateNonBlank(id, 'id');
    _validateNonBlank(name, 'name');
    _validateFinite(offsetX, 'offsetX');
    _validateFinite(offsetY, 'offsetY');
    _validatePositiveFinite(scaleX, 'scaleX');
    _validatePositiveFinite(scaleY, 'scaleY');
    _validateOpacity(opacity);
  }

  final String id;
  final String name;
  final ShadowCasterMode mode;
  final ShadowRenderPass renderPass;
  final double offsetX;
  final double offsetY;
  final double scaleX;
  final double scaleY;
  final double opacity;
  final String colorHexRgb;
  final ShadowSoftnessMode softnessMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectShadowProfile &&
          other.id == id &&
          other.name == name &&
          other.mode == mode &&
          other.renderPass == renderPass &&
          other.offsetX == offsetX &&
          other.offsetY == offsetY &&
          other.scaleX == scaleX &&
          other.scaleY == scaleY &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb &&
          other.softnessMode == softnessMode;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        mode,
        renderPass,
        offsetX,
        offsetY,
        scaleX,
        scaleY,
        opacity,
        colorHexRgb,
        softnessMode,
      );
}

/// Optional default shadow configuration carried by a project element.
///
/// This is an authoring contract only. It does not affect collision,
/// occlusion, cells, gameplay, Flutter, or Flame.
@immutable
final class ProjectElementShadowConfig {
  ProjectElementShadowConfig({
    this.castsShadow = false,
    this.shadowProfileId,
    this.offsetX,
    this.offsetY,
    this.scaleX,
    this.scaleY,
    this.opacity,
  }) {
    final profileId = shadowProfileId;
    if (profileId != null) {
      _validateProjectElementShadowProfileId(profileId);
    }
    if (castsShadow && profileId == null) {
      throw const ValidationException(
        'ProjectElementShadowConfig.shadowProfileId is required when castsShadow is true',
      );
    }
    _validateProjectElementShadowOptionalFinite(offsetX, 'offsetX');
    _validateProjectElementShadowOptionalFinite(offsetY, 'offsetY');
    _validateProjectElementShadowOptionalPositive(scaleX, 'scaleX');
    _validateProjectElementShadowOptionalPositive(scaleY, 'scaleY');
    _validateProjectElementShadowOptionalOpacity(opacity);
  }

  /// Whether the element should cast its default shadow.
  final bool castsShadow;

  /// Reference to a future [ProjectShadowProfile].
  ///
  /// Shadow-4 intentionally does not resolve this id against a catalog.
  final String? shadowProfileId;

  /// Optional numeric overrides applied later by the Shadow resolver.
  final double? offsetX;
  final double? offsetY;
  final double? scaleX;
  final double? scaleY;
  final double? opacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectElementShadowConfig &&
          other.castsShadow == castsShadow &&
          other.shadowProfileId == shadowProfileId &&
          other.offsetX == offsetX &&
          other.offsetY == offsetY &&
          other.scaleX == scaleX &&
          other.scaleY == scaleY &&
          other.opacity == opacity;

  @override
  int get hashCode => Object.hash(
        castsShadow,
        shadowProfileId,
        offsetX,
        offsetY,
        scaleX,
        scaleY,
        opacity,
      );
}

void _validateProjectElementShadowProfileId(String value) {
  if (value.trim().isEmpty) {
    throw const ValidationException(
      'ProjectElementShadowConfig.shadowProfileId must be non-empty',
    );
  }
}

void _validateProjectElementShadowOptionalFinite(
  double? value,
  String name,
) {
  if (value == null) {
    return;
  }
  if (!value.isFinite) {
    throw ValidationException(
      'ProjectElementShadowConfig.$name must be finite',
    );
  }
}

void _validateProjectElementShadowOptionalPositive(
  double? value,
  String name,
) {
  _validateProjectElementShadowOptionalFinite(value, name);
  if (value != null && value <= 0) {
    throw ValidationException(
      'ProjectElementShadowConfig.$name must be > 0',
    );
  }
}

void _validateProjectElementShadowOptionalOpacity(double? value) {
  _validateProjectElementShadowOptionalFinite(value, 'opacity');
  if (value != null && (value < 0 || value > 1)) {
    throw const ValidationException(
      'ProjectElementShadowConfig.opacity must be between 0 and 1',
    );
  }
}

void _validateNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ValidationException('ProjectShadowProfile.$name must be non-empty');
  }
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('ProjectShadowProfile.$name must be finite');
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException('ProjectShadowProfile.$name must be > 0');
  }
}

void _validateOpacity(double value) {
  _validateFinite(value, 'opacity');
  if (value < 0 || value > 1) {
    throw const ValidationException(
      'ProjectShadowProfile.opacity must be between 0 and 1',
    );
  }
}

String _normalizeColorHexRgb(String value) {
  if (value.length != 6 || !_isHexRgb(value)) {
    throw ValidationException(
      'ProjectShadowProfile.colorHexRgb must contain exactly 6 hexadecimal RGB characters without #',
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
