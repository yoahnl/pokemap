import 'package:map_core/map_core.dart';

/// Maps displayed by the runtime host and the map selected for launch.
final class RuntimeHostProjectMapSelection {
  const RuntimeHostProjectMapSelection({
    required this.maps,
    required this.selectedMapId,
  });

  final List<ProjectMapEntry> maps;
  final String? selectedMapId;
}

/// Resolves the first bundle that the runtime host must load for a project.
///
/// Priority is deliberate:
/// 1. a versioned launch save restores its authored map;
/// 2. a valid enabled New Game start map boots a fresh project correctly;
/// 3. a valid persisted host selection resumes a legacy project's last map;
/// 4. legacy projects fall back to the first map in picker order.
RuntimeHostProjectMapSelection resolveRuntimeHostProjectMapSelection(
  ProjectManifest manifest, {
  String? versionedLaunchMapId,
  String? preferredMapId,
}) {
  final maps = List<ProjectMapEntry>.of(manifest.maps)
    ..sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  final immutableMaps = List<ProjectMapEntry>.unmodifiable(maps);

  String? validMapId(String? candidate) {
    final normalized = candidate?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return immutableMaps.any((map) => map.id == normalized) ? normalized : null;
  }

  final selectedMapId = validMapId(versionedLaunchMapId) ??
      (manifest.newGame.enabled
          ? validMapId(manifest.newGame.startMapId)
          : null) ??
      validMapId(preferredMapId) ??
      (immutableMaps.isEmpty ? null : immutableMaps.first.id);

  return RuntimeHostProjectMapSelection(
    maps: immutableMaps,
    selectedMapId: selectedMapId,
  );
}
