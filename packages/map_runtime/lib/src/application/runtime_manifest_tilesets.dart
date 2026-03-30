import 'package:map_core/map_core.dart';

import 'runtime_character_refs.dart';

Map<TerrainType, ProjectTerrainPreset> runtimeTerrainPresetsByType(
  ProjectManifest manifest,
) {
  final sorted = List<ProjectTerrainPreset>.from(manifest.terrainPresets)
    ..sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      if (c != 0) {
        return c;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  final out = <TerrainType, ProjectTerrainPreset>{};
  for (final p in sorted) {
    out.putIfAbsent(p.terrainType, () => p);
  }
  return out;
}

Set<String> collectTilesetIdsReferencedOnMap(MapData map) {
  final ids = <String>{};
  void add(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isNotEmpty) {
      ids.add(t);
    }
  }

  add(map.tilesetId);
  for (final layer in map.layers) {
    layer.when(
      tile: (id, name, tilesetId, isVisible, opacity, tiles) => add(tilesetId),
      collision: (id, name, isVisible, opacity, collisions) {},
      terrain: (id, name, isVisible, opacity, terrains) {},
      path: (id, name, isVisible, opacity, presetId, cells, properties, animationMode, animationTriggers) {},
      object: (id, name, isVisible, opacity) {},
    );
  }
  return ids;
}

void addTerrainAndPathPresetTilesetIds(
  Set<String> ids,
  MapData map,
  ProjectManifest manifest,
) {
  final terrainByType = runtimeTerrainPresetsByType(manifest);
  for (final layer in map.layers) {
    layer.when(
      tile: (id, name, tilesetId, isVisible, opacity, tiles) {},
      collision: (id, name, isVisible, opacity, collisions) {},
      terrain: (id, name, isVisible, opacity, terrains) {
        for (final t in terrains) {
          if (t == TerrainType.none) {
            continue;
          }
          final preset = terrainByType[t];
          if (preset == null) {
            continue;
          }
          final presetTilesetId = preset.tilesetId.trim();
          if (presetTilesetId.isNotEmpty) {
            ids.add(presetTilesetId);
          }
          for (final variant in preset.variants) {
            for (final frame in variant.frames) {
              final overrideTilesetId = frame.tilesetId.trim();
              if (overrideTilesetId.isNotEmpty) {
                ids.add(overrideTilesetId);
              }
            }
          }
        }
      },
      path: (id, name, isVisible, opacity, presetId, cells, properties, animationMode, animationTriggers) {
        final pid = presetId.trim();
        if (pid.isEmpty) {
          return;
        }
        for (final p in manifest.pathPresets) {
          if (p.id == pid) {
            final presetTilesetId = p.tilesetId.trim();
            if (presetTilesetId.isNotEmpty) {
              ids.add(presetTilesetId);
            }
            for (final mapping in p.variants) {
              for (final frame in mapping.frames) {
                final overrideTilesetId = frame.tilesetId.trim();
                if (overrideTilesetId.isNotEmpty) {
                  ids.add(overrideTilesetId);
                }
              }
            }
            return;
          }
        }
      },
      object: (id, name, isVisible, opacity) {},
    );
  }
}

void addEntityVisualTilesetIds(
  Set<String> ids,
  MapData map,
  ProjectManifest manifest,
) {
  final elementById = {for (final e in manifest.elements) e.id: e};
  for (final entity in map.entities) {
    final elementId = entity.resolvedProjectElementIdForEditor?.trim();
    if (elementId == null || elementId.isEmpty) continue;
    final entry = elementById[elementId];
    if (entry == null || entry.frames.isEmpty) continue;
    for (final frame in entry.frames) {
      final tid = frame.tilesetId.trim().isNotEmpty
          ? frame.tilesetId.trim()
          : entry.tilesetId.trim();
      if (tid.isNotEmpty) ids.add(tid);
    }
  }
}

void addCharacterTilesetIds(
  Set<String> ids,
  MapData map,
  ProjectManifest manifest,
) {
  final charById = {for (final c in manifest.characters) c.id: c};
  final playerCharId = manifest.settings.defaultPlayerCharacterId?.trim();
  if (playerCharId != null && playerCharId.isNotEmpty) {
    final tid = charById[playerCharId]?.tilesetId.trim() ?? '';
    if (tid.isNotEmpty) ids.add(tid);
  }
  for (final entity in map.entities) {
    if (entity.kind != MapEntityKind.npc) continue;
    final charId = resolveNpcCharacterId(entity, manifest);
    if (charId == null || charId.isEmpty) continue;
    final tid = charById[charId]?.tilesetId.trim() ?? '';
    if (tid.isNotEmpty) ids.add(tid);
  }
}

Set<String> collectAllRuntimeTilesetIds(MapData map, ProjectManifest manifest) {
  final ids = collectTilesetIdsReferencedOnMap(map);
  addTerrainAndPathPresetTilesetIds(ids, map, manifest);
  addEntityVisualTilesetIds(ids, map, manifest);
  addCharacterTilesetIds(ids, map, manifest);
  return ids;
}
