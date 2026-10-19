import 'package:flame_3d/model.dart';

final _clipSourceIssues = Expando<List<String>>('spatial-model-clip-source');

void registerSpatialModelClipSource(
  Model model,
  Map<String, dynamic> document, {
  required bool hasMaterialAnimations,
}) {
  final issues = <String>{};
  bool hasEntries(Object? value) =>
      value != null && (value is! List || value.isNotEmpty);
  if (hasEntries(document['animations'])) issues.add('geometry_animation');
  if (hasEntries(document['skins'])) issues.add('skin');
  if (hasMaterialAnimations) issues.add('material_animation');
  for (final raw in (document['nodes'] as List?) ?? const []) {
    final node = raw as Map;
    if (node.containsKey('skin')) issues.add('skin');
    if (node.containsKey('weights')) issues.add('morph');
  }
  for (final raw in (document['meshes'] as List?) ?? const []) {
    final mesh = raw as Map;
    if (mesh.containsKey('weights')) issues.add('morph');
    for (final raw in (mesh['primitives'] as List?) ?? const []) {
      final primitive = raw as Map;
      if (primitive.containsKey('targets')) issues.add('morph');
      if ((primitive['mode'] ?? 4) != 4) issues.add('non_triangle_primitive');
      final attributes = primitive['attributes'] as Map? ?? const {};
      if (attributes.keys.any(
        (key) =>
            key is String &&
            (key.startsWith('JOINTS_') || key.startsWith('WEIGHTS_')),
      )) {
        issues.add('skin_attributes');
      }
    }
  }
  _clipSourceIssues[model] = List.unmodifiable(issues);
}

List<String>? spatialModelClipSourceIssues(Model model) =>
    _clipSourceIssues[model];

void inheritSpatialModelClipSource(Model source, Model derived) {
  final issues = _clipSourceIssues[source];
  if (issues == null || issues.isNotEmpty) {
    throw const FormatException(
      'A clipped model requires a qualified static source.',
    );
  }
  _clipSourceIssues[derived] = issues;
}
