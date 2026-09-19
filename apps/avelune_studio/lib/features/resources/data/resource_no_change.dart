import 'dart:convert';

import 'package:map_core/map_core_domain.dart';

bool resourceMutationIsUnchanged(
  ProjectManifest manifest,
  String action,
  Map<String, Object?> parameters,
) {
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
