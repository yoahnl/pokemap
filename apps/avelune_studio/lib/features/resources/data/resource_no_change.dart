import 'dart:convert';

import 'package:map_core/map_core.dart';

bool resourceMutationIsUnchanged(
  ProjectManifest manifest,
  String action,
  Map<String, Object?> parameters,
) {
  if (action == 'model3d.configure' &&
      parameters.length == 2 &&
      parameters['modelId'] is String &&
      parameters['castsShadowsByDefault'] is bool) {
    final models = manifest.models3d;
    final id = parameters['modelId'] as String;
    final model = models is ProjectModel3dEntries
        ? models.lookup(id)
        : models.where((entry) => entry.id == id).firstOrNull;
    return model != null &&
        model.castsShadowsByDefault == parameters['castsShadowsByDefault'];
  }
  if (parameters.length != 1) return false;
  final (key, candidates) = switch (action) {
    'element.upsert' => (
      'element',
      manifest.elements.map((entry) => entry.toJson()),
    ),
    'smart_tile.preset.draft.upsert' => (
      'draft',
      manifest.smartTileCatalog.drafts.map((entry) => entry.toJson()),
    ),
    _ => ('', <Map<String, dynamic>>[]),
  };
  final proposed = parameters[key];
  if (proposed is! Map<String, Object?>) return false;
  final encoded = jsonEncode(proposed);
  return candidates.any((candidate) => jsonEncode(candidate) == encoded);
}
