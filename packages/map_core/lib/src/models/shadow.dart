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
