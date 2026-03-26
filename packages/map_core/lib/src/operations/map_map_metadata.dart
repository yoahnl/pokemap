import '../models/map_data.dart';
import '../models/map_metadata.dart';
import '../models/project_manifest.dart';
import '../validation/validators.dart';

String? _nullIfBlank(String? s) {
  if (s == null) return null;
  final t = s.trim();
  return t.isEmpty ? null : t;
}

MapMetadata normalizeMapMetadata(MapMetadata input) {
  final tagsRaw = input.tags.map((t) => t.trim()).where((t) => t.isNotEmpty);
  final seen = <String>{};
  final ordered = <String>[];
  for (final t in tagsRaw) {
    if (seen.add(t)) ordered.add(t);
  }
  return input.copyWith(
    displayName: input.displayName.trim(),
    musicId: _nullIfBlank(input.musicId),
    defaultSpawnId: _nullIfBlank(input.defaultSpawnId),
    tags: ordered,
  );
}

MapData updateMapMetadataOnMap(
  MapData map,
  MapMetadata metadata, {
  ProjectManifest? projectDialogueContext,
}) {
  final normalized = normalizeMapMetadata(metadata);
  final next = map.copyWith(mapMetadata: normalized);
  MapValidator.validate(
    next,
    projectDialogueContext: projectDialogueContext,
  );
  return next;
}
