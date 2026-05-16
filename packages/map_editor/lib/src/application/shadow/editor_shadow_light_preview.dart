import 'dart:math' as math;

final class EditorShadowLightPreviewPreset {
  EditorShadowLightPreviewPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.directionX,
    required this.directionY,
    required this.lengthMultiplier,
    required this.scaleXMultiplier,
    required this.scaleYMultiplier,
    required this.opacityMultiplier,
  }) {
    _validateNonBlank(id, 'id');
    _validateNonBlank(label, 'label');
    _validateNonBlank(description, 'description');
    _validateFinite(directionX, 'directionX');
    _validateFinite(directionY, 'directionY');
    _validateNonNegativeFinite(lengthMultiplier, 'lengthMultiplier');
    _validatePositiveFinite(scaleXMultiplier, 'scaleXMultiplier');
    _validatePositiveFinite(scaleYMultiplier, 'scaleYMultiplier');
    _validateFinite(opacityMultiplier, 'opacityMultiplier');
  }

  final String id;
  final String label;
  final String description;
  final double directionX;
  final double directionY;
  final double lengthMultiplier;
  final double scaleXMultiplier;
  final double scaleYMultiplier;
  final double opacityMultiplier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorShadowLightPreviewPreset &&
          other.id == id &&
          other.label == label &&
          other.description == description &&
          other.directionX == directionX &&
          other.directionY == directionY &&
          other.lengthMultiplier == lengthMultiplier &&
          other.scaleXMultiplier == scaleXMultiplier &&
          other.scaleYMultiplier == scaleYMultiplier &&
          other.opacityMultiplier == opacityMultiplier;

  @override
  int get hashCode => Object.hash(
        id,
        label,
        description,
        directionX,
        directionY,
        lengthMultiplier,
        scaleXMultiplier,
        scaleYMultiplier,
        opacityMultiplier,
      );
}

final class EditorShadowLightPreviewResult {
  EditorShadowLightPreviewResult({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.opacity,
  }) {
    _validateFinite(left, 'left');
    _validateFinite(top, 'top');
    _validatePositiveFinite(width, 'width');
    _validatePositiveFinite(height, 'height');
    _validateFinite(opacity, 'opacity');
  }

  final double left;
  final double top;
  final double width;
  final double height;
  final double opacity;

  double get centerX => left + width / 2;
  double get centerY => top + height / 2;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorShadowLightPreviewResult &&
          other.left == left &&
          other.top == top &&
          other.width == width &&
          other.height == height &&
          other.opacity == opacity;

  @override
  int get hashCode => Object.hash(left, top, width, height, opacity);
}

List<EditorShadowLightPreviewPreset> createEditorShadowLightPreviewPresets() {
  return _editorShadowLightPreviewPresets;
}

EditorShadowLightPreviewPreset? editorShadowLightPreviewPresetById(String id) {
  final normalizedId = id.trim();
  for (final preset in _editorShadowLightPreviewPresets) {
    if (preset.id == normalizedId) {
      return preset;
    }
  }
  return null;
}

EditorShadowLightPreviewResult applyEditorShadowLightPreviewPreset({
  required double left,
  required double top,
  required double width,
  required double height,
  required double opacity,
  required double visualHeight,
  required EditorShadowLightPreviewPreset preset,
}) {
  _validateFinite(left, 'left');
  _validateFinite(top, 'top');
  _validatePositiveFinite(width, 'width');
  _validatePositiveFinite(height, 'height');
  _validateFinite(opacity, 'opacity');
  _validatePositiveFinite(visualHeight, 'visualHeight');

  final directionLength = math.sqrt(
    preset.directionX * preset.directionX +
        preset.directionY * preset.directionY,
  );
  final distance = visualHeight * preset.lengthMultiplier;
  final unitX =
      directionLength == 0 ? 0.0 : preset.directionX / directionLength;
  final unitY =
      directionLength == 0 ? 0.0 : preset.directionY / directionLength;
  final nextWidth = width * preset.scaleXMultiplier;
  final nextHeight = height * preset.scaleYMultiplier;
  final nextCenterX = left + width / 2 + unitX * distance;
  final nextCenterY = top + height / 2 + unitY * distance;

  return EditorShadowLightPreviewResult(
    left: nextCenterX - nextWidth / 2,
    top: nextCenterY - nextHeight / 2,
    width: nextWidth,
    height: nextHeight,
    opacity: _clamp01(opacity * preset.opacityMultiplier),
  );
}

final EditorShadowLightPreviewPreset neutralEditorShadowLightPreviewPreset =
    _editorShadowLightPreviewPresets.first;

final List<EditorShadowLightPreviewPreset> _editorShadowLightPreviewPresets =
    List<EditorShadowLightPreviewPreset>.unmodifiable([
  EditorShadowLightPreviewPreset(
    id: 'neutral',
    label: 'Neutre',
    description: 'Preview actuelle sans transformation de lumiere.',
    directionX: 0,
    directionY: 0,
    lengthMultiplier: 0,
    scaleXMultiplier: 1,
    scaleYMultiplier: 1,
    opacityMultiplier: 1,
  ),
  EditorShadowLightPreviewPreset(
    id: 'noon',
    label: 'Midi',
    description: 'Ombre courte, centree et plus discrete.',
    directionX: 0,
    directionY: 0,
    lengthMultiplier: 0,
    scaleXMultiplier: 0.72,
    scaleYMultiplier: 0.45,
    opacityMultiplier: 0.72,
  ),
  EditorShadowLightPreviewPreset(
    id: 'morning',
    label: 'Matin',
    description: 'Ombre portee vers le bas-droite.',
    directionX: 1,
    directionY: 0.45,
    lengthMultiplier: 0.38,
    scaleXMultiplier: 1.12,
    scaleYMultiplier: 0.72,
    opacityMultiplier: 0.9,
  ),
  EditorShadowLightPreviewPreset(
    id: 'evening',
    label: 'Soir',
    description: 'Ombre portee vers le bas-gauche.',
    directionX: -1,
    directionY: 0.45,
    lengthMultiplier: 0.38,
    scaleXMultiplier: 1.12,
    scaleYMultiplier: 0.72,
    opacityMultiplier: 0.9,
  ),
  EditorShadowLightPreviewPreset(
    id: 'soft-night',
    label: 'Nuit douce',
    description: 'Ombre courte et fortement attenuee.',
    directionX: 0,
    directionY: 0,
    lengthMultiplier: 0,
    scaleXMultiplier: 0.65,
    scaleYMultiplier: 0.5,
    opacityMultiplier: 0.42,
  ),
]);

void _validateNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, name, 'must be finite');
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ArgumentError.value(value, name, 'must be > 0');
  }
}

void _validateNonNegativeFinite(double value, String name) {
  _validateFinite(value, name);
  if (value < 0) {
    throw ArgumentError.value(value, name, 'must be >= 0');
  }
}

double _clamp01(double value) {
  if (value < 0) {
    return 0;
  }
  if (value > 1) {
    return 1;
  }
  return value;
}
