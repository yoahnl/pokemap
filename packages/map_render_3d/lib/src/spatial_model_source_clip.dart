import 'package:map_core/map_core.dart';

import 'spatial_model_triangle_clip.dart';

SpatialModelClipRect? spatialModelSourceClip(
  SpatialModelInstance instance,
  ProjectModel3dEntry definition,
) {
  final clip = instance.clip;
  if (clip == null) return null;
  final scale = instance.scale * definition.scale;
  if (!scale.isFinite || scale <= 0) {
    throw const FormatException(
      'Model clip scale must remain finite and positive.',
    );
  }
  final result = SpatialModelClipRect(
    left: definition.pivot.x + clip.left / scale,
    top: definition.pivot.z + clip.top / scale,
    right: definition.pivot.x + clip.right / scale,
    bottom: definition.pivot.z + clip.bottom / scale,
  );
  if (![
        result.left,
        result.top,
        result.right,
        result.bottom,
      ].every((value) => value.isFinite) ||
      result.left >= result.right ||
      result.top >= result.bottom) {
    throw const FormatException(
      'Model clip coordinates lose their finite source extent.',
    );
  }
  return result;
}
