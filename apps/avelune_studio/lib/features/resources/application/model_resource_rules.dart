import 'package:map_core/map_core.dart';

String modelDiagnosticLabel(String code) => switch (code) {
  'renderer.missing_material_magenta' =>
    'Ce modèle n’a pas de matériau. Les surfaces concernées sont affichées en rose.',
  'bounds.static_scene_only' =>
    'Les dimensions affichées correspondent à la pose de repos ; l’animation peut dépasser ce cadre.',
  'bounds.bind_pose_only' =>
    'Les dimensions correspondent à la pose initiale du squelette.',
  'renderer.ignored_color_0' =>
    'Les couleurs par sommet ne sont pas utilisées par cet aperçu.',
  'renderer.ignored_normalTexture' =>
    'La texture de relief fin n’est pas utilisée par cet aperçu.',
  'renderer.ignored_occlusionTexture' =>
    'La texture d’occlusion n’est pas utilisée par cet aperçu.',
  'renderer.ignored_emissiveTexture' || 'renderer.ignored_emissiveFactor' =>
    'L’effet lumineux du matériau n’est pas utilisé par cet aperçu.',
  'renderer.ignored_metallicRoughnessTexture' ||
  'renderer.ignored_metallicFactor' ||
  'renderer.ignored_roughnessFactor' =>
    'L’aspect métallique et la rugosité ne sont pas reproduits par cet aperçu.',
  _ =>
    'Ce modèle contient une propriété visuelle que cet aperçu ne reproduit pas.',
};

const modelScaleRefusal = 'L’échelle doit être un nombre positif.';

double? parseModelScale(String text) {
  final scale = double.tryParse(text.replaceAll(',', '.'));
  return scale == null || !scale.isFinite || scale <= 0 ? null : scale;
}

Map<String, Object?> modelFootPivotFields(ProjectModel3dEntry model) {
  final bounds = model.inspection.bounds;
  return {
    'pivot': {
      'x': (bounds.min.x + bounds.max.x) / 2,
      'y': bounds.min.y,
      'z': (bounds.min.z + bounds.max.z) / 2,
    },
  };
}

Map<String, Object?> modelShadowFields(bool castsShadowsByDefault) => {
  'castsShadowsByDefault': castsShadowsByDefault,
};

Map<String, Object?> modelLightFields(Model3dPointLight? light) => {
  'light': light?.toJson(),
};

Map<String, Object?> modelConfigurePayload(
  String modelId,
  Map<String, Object?> fields,
) => {'modelId': modelId, ...fields};
