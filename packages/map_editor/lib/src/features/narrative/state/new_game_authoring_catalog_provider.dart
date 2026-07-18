import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../app/providers/core/repository_providers.dart';

final class NewGameSpawnAuthoringOption {
  const NewGameSpawnAuthoringOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

final class NewGameMapAuthoringOption {
  const NewGameMapAuthoringOption({
    required this.id,
    required this.label,
    this.spawns = const <NewGameSpawnAuthoringOption>[],
    this.loadFailed = false,
  });

  final String id;
  final String label;
  final List<NewGameSpawnAuthoringOption> spawns;
  final bool loadFailed;
}

final class NewGameMapAuthoringCatalog {
  const NewGameMapAuthoringCatalog({
    required this.maps,
    this.failedMapLabels = const <String>[],
  });

  final List<NewGameMapAuthoringOption> maps;
  final List<String> failedMapLabels;
}

final class NewGameMapAuthoringCatalogRequest {
  NewGameMapAuthoringCatalogRequest({
    required this.projectRootPath,
    required List<ProjectMapEntry> maps,
  }) : maps = List<ProjectMapEntry>.unmodifiable(maps);

  final String projectRootPath;
  final List<ProjectMapEntry> maps;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NewGameMapAuthoringCatalogRequest ||
        other.projectRootPath != projectRootPath ||
        other.maps.length != maps.length) {
      return false;
    }
    for (var index = 0; index < maps.length; index += 1) {
      if (other.maps[index] != maps[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(projectRootPath, Object.hashAll(maps));
}

final newGameMapAuthoringCatalogProvider = FutureProvider.autoDispose
    .family<NewGameMapAuthoringCatalog, NewGameMapAuthoringCatalogRequest>(
        (ref, request) async {
  final repository = ref.watch(mapRepositoryProvider);
  final workspace = ref
      .watch(projectWorkspaceFactoryProvider)
      .create(request.projectRootPath);
  final entries = request.maps.toList(growable: false)
    ..sort((left, right) {
      final byOrder = left.sortOrder.compareTo(right.sortOrder);
      if (byOrder != 0) return byOrder;
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
  final maps = <NewGameMapAuthoringOption>[];
  final failedMapLabels = <String>[];

  for (final entry in entries) {
    try {
      final map = await repository.loadMap(
        workspace.resolveMapPath(entry.relativePath),
      );
      final spawns = <NewGameSpawnAuthoringOption>[
        for (final entity in map.entities)
          if (entity.kind == MapEntityKind.spawn)
            NewGameSpawnAuthoringOption(
              id: entity.id,
              label: _spawnLabel(
                entity,
                isDefault: map.mapMetadata.defaultSpawnId == entity.id,
              ),
            ),
      ]..sort((left, right) {
          return left.label.toLowerCase().compareTo(right.label.toLowerCase());
        });
      maps.add(
        NewGameMapAuthoringOption(
          id: entry.id,
          label: entry.name.trim().isEmpty ? entry.id : entry.name.trim(),
          spawns: List<NewGameSpawnAuthoringOption>.unmodifiable(spawns),
        ),
      );
    } catch (_) {
      final label = entry.name.trim().isEmpty ? entry.id : entry.name.trim();
      failedMapLabels.add(label);
      maps.add(
        NewGameMapAuthoringOption(
          id: entry.id,
          label: label,
          loadFailed: true,
        ),
      );
    }
  }

  return NewGameMapAuthoringCatalog(
    maps: List<NewGameMapAuthoringOption>.unmodifiable(maps),
    failedMapLabels: List<String>.unmodifiable(failedMapLabels),
  );
});

String _spawnLabel(MapEntity entity, {required bool isDefault}) {
  final authoredLabel = entity.spawn?.spawnKey.trim();
  final entityName = entity.name.trim();
  final label = authoredLabel != null && authoredLabel.isNotEmpty
      ? authoredLabel
      : entityName.isNotEmpty
          ? entityName
          : entity.id;
  return isDefault ? '$label · spawn par défaut' : label;
}
