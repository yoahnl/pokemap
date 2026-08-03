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
  for (final layer in map.layers.whereType<TileLayer>()) {
    add(layer.tilesetId);
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
    if (layer is TerrainLayer) {
      for (final terrain in layer.terrains) {
        if (terrain == TerrainType.none) {
          continue;
        }
        final preset = terrainByType[terrain];
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
      continue;
    }
    if (layer is PathLayer) {
      final presetId = layer.presetId.trim();
      if (presetId.isEmpty) {
        continue;
      }
      for (final preset in manifest.pathPresets) {
        if (preset.id == presetId) {
          final presetTilesetId = preset.tilesetId.trim();
          if (presetTilesetId.isNotEmpty) {
            ids.add(presetTilesetId);
          }
          for (final mapping in preset.variants) {
            for (final frame in mapping.frames) {
              final overrideTilesetId = frame.tilesetId.trim();
              if (overrideTilesetId.isNotEmpty) {
                ids.add(overrideTilesetId);
              }
            }
          }
          for (final pattern in manifest.pathPatternPresets) {
            if (pattern.basePathPresetId != presetId) {
              continue;
            }
            for (final cell in pattern.centerPattern.cells) {
              for (final frame in cell.frames) {
                final overrideTilesetId = frame.tilesetId.trim();
                if (overrideTilesetId.isNotEmpty) {
                  ids.add(overrideTilesetId);
                }
              }
            }
          }
          break;
        }
      }
    }
  }
}

void addSmartTileTilesetIds(
  Set<String> ids,
  MapData map,
  ProjectManifest manifest,
) {
  final catalog = manifest.smartTileCatalog;
  if (catalog.isEmpty) return;
  final atlasById = <String, ProjectSmartTileAtlas>{
    for (final atlas in catalog.atlases) atlas.id: atlas,
  };
  final animationById = <String, ProjectSmartTileAnimation>{
    for (final animation in catalog.animations) animation.id: animation,
  };
  final presetById = <String, ProjectSmartTilePreset>{
    for (final preset in catalog.presets) preset.id: preset,
  };

  void addFrame(SmartTileFrameRef frame) {
    final tilesetId = atlasById[frame.atlasId]?.tilesetId.trim() ?? '';
    if (tilesetId.isNotEmpty) ids.add(tilesetId);
  }

  void addSource(SmartTileVisualSource source) {
    source.map(
      frame: (source) => addFrame(source.frame),
      animation: (source) {
        final animation = animationById[source.animationId];
        if (animation == null) return;
        for (final frame in animation.frames) {
          addFrame(frame.frame);
        }
      },
    );
  }

  for (final layer in map.layers.whereType<SmartTileLayer>()) {
    final preset = presetById[layer.presetId];
    if (preset == null || preset.usage != layer.usage) continue;
    for (final rule in preset.rules) {
      for (final candidate in rule.candidates) {
        for (final part in candidate.parts) {
          addSource(part.source);
        }
      }
    }
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

void addPlacedElementVisualTilesetIds(
  Set<String> ids,
  MapData map,
  ProjectManifest manifest,
) {
  final elementById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final placed in map.placedElements) {
    final elementId = placed.elementId.trim();
    if (elementId.isEmpty) continue;
    final element = elementById[elementId];
    if (element == null || element.frames.isEmpty) continue;
    for (final frame in element.frames) {
      final frameTilesetId = frame.tilesetId.trim();
      final tilesetId =
          frameTilesetId.isEmpty ? element.tilesetId.trim() : frameTilesetId;
      if (tilesetId.isNotEmpty) ids.add(tilesetId);
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
  addSmartTileTilesetIds(ids, map, manifest);
  addEntityVisualTilesetIds(ids, map, manifest);
  addCharacterTilesetIds(ids, map, manifest);
  // Append placed-element visuals after the established sources so their
  // relative insertion order remains unchanged while the set deduplicates.
  addPlacedElementVisualTilesetIds(ids, map, manifest);
  return ids;
}
