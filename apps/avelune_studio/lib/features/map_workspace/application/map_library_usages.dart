import 'package:map_core/map_core_domain.dart';

import '../domain/map_workspace_port.dart';

enum MapLibraryUsageKind {
  map,
  scene,
  storyline,
  worldRule,
  event,
  cinematic,
  newGame,
  regionalMap,
  other,
}

final class MapLibraryUsage {
  const MapLibraryUsage(this.kind, this.label);

  final MapLibraryUsageKind kind;
  final String? label;

  @override
  bool operator ==(Object other) =>
      other is MapLibraryUsage && other.kind == kind && other.label == label;

  @override
  int get hashCode => Object.hash(kind, label);
}

String mapLibraryFailureText(Object failure) =>
    failure is MapWorkspaceFailure ? failure.message : '$failure';

List<MapLibraryUsage> mapLibraryUsages(
  Map<String, Object?> details,
  ProjectManifest project,
) {
  final dependents = details['dependents'];
  if (dependents is! List) return const [];
  final usages = <MapLibraryUsage>{};
  for (final dependent in dependents.whereType<Map>()) {
    usages.add(_usage(dependent, project));
  }
  return List.unmodifiable(usages);
}

MapLibraryUsage _usage(Map key, ProjectManifest project) {
  final kind = key['kind'];
  final id = key['id'];
  final parentId = key['parentId'];
  if (key['scope'] == 'map' && parentId is String) {
    return MapLibraryUsage(
      MapLibraryUsageKind.map,
      _mapName(project, parentId),
    );
  }
  if (kind == 'sourceMap' && key['sourceKind'] == 'newGame') {
    return const MapLibraryUsage(MapLibraryUsageKind.newGame, null);
  }
  return switch (kind) {
    'map' => MapLibraryUsage(MapLibraryUsageKind.map, _mapName(project, id)),
    'scene' => MapLibraryUsage(
      MapLibraryUsageKind.scene,
      _named(project.scenes.where((s) => s.id == id).map((s) => s.name)),
    ),
    'storyline' || 'chapter' || 'step' => MapLibraryUsage(
      MapLibraryUsageKind.storyline,
      _named(project.storylines.where((s) => s.id == id).map((s) => s.title)),
    ),
    'worldRule' => MapLibraryUsage(
      MapLibraryUsageKind.worldRule,
      _named(project.worldRules.where((r) => r.id == id).map((r) => r.label)),
    ),
    'cinematic' => MapLibraryUsage(
      MapLibraryUsageKind.cinematic,
      _named(project.cinematics.where((c) => c.id == id).map((c) => c.title)),
    ),
    'eventV2' ||
    'event' => const MapLibraryUsage(MapLibraryUsageKind.event, null),
    final String value when value.startsWith('regionalMap') =>
      const MapLibraryUsage(MapLibraryUsageKind.regionalMap, null),
    _ => const MapLibraryUsage(MapLibraryUsageKind.other, null),
  };
}

String? _mapName(ProjectManifest project, Object? id) =>
    _named(project.maps.where((map) => map.id == id).map((map) => map.name));

String? _named(Iterable<String> names) {
  final name = names.firstOrNull?.trim();
  return name == null || name.isEmpty ? null : name;
}
