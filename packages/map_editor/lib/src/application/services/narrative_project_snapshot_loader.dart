import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../domain/repositories/repositories.dart';

/// Immutable project-wide input shared by narrative diagnostics and pickers.
///
/// The active editor document deliberately wins over its disk counterpart so
/// authoring never diagnoses stale data while the other maps remain visible.
final class NarrativeProjectSnapshot {
  NarrativeProjectSnapshot({
    required this.project,
    required List<MapData> maps,
  }) : maps = List<MapData>.unmodifiable(maps);

  final ProjectManifest project;
  final List<MapData> maps;

  MapData? mapById(String mapId) =>
      maps.where((map) => map.id == mapId).firstOrNull;
}

final class NarrativeProjectSnapshotLoader {
  const NarrativeProjectSnapshotLoader({
    required MapRepository mapRepository,
  }) : _mapRepository = mapRepository;

  final MapRepository _mapRepository;

  Future<NarrativeProjectSnapshot> load({
    required ProjectManifest project,
    required String projectRootPath,
    MapData? activeMap,
  }) async {
    final root = p.normalize(p.absolute(projectRootPath.trim()));
    if (projectRootPath.trim().isEmpty) {
      throw ArgumentError.value(
        projectRootPath,
        'projectRootPath',
        'must not be empty',
      );
    }
    final maps = <MapData>[];
    final seen = <String>{};
    for (final entry in project.maps) {
      if (!seen.add(entry.id)) {
        throw StateError('Duplicate project map id "${entry.id}".');
      }
      if (activeMap?.id == entry.id) {
        maps.add(activeMap!);
        continue;
      }
      final path = _resolveWithinRoot(root, entry.relativePath);
      final map = await _mapRepository.loadMap(path);
      if (map.id != entry.id) {
        throw StateError(
          'Map "${entry.id}" loaded "${map.id}" from ${entry.relativePath}.',
        );
      }
      maps.add(map);
    }
    if (activeMap != null && !seen.contains(activeMap.id)) {
      // A newly created unsaved map can briefly precede its manifest entry.
      maps.add(activeMap);
    }
    return NarrativeProjectSnapshot(project: project, maps: maps);
  }
}

String _resolveWithinRoot(String root, String relativePath) {
  final relative = relativePath.trim();
  if (relative.isEmpty || p.isAbsolute(relative)) {
    throw ArgumentError.value(
      relativePath,
      'relativePath',
      'must be a non-empty project-relative path',
    );
  }
  final candidate = p.normalize(p.join(root, relative));
  if (candidate != root && !p.isWithin(root, candidate)) {
    throw ArgumentError.value(
      relativePath,
      'relativePath',
      'must stay within the project root',
    );
  }
  return candidate;
}
