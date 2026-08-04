import 'package:map_core/map_core.dart';

import 'runtime_character_refs.dart';

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
    for (final entry in layer.palette) {
      add(entry.tilesetId);
    }
  }
  for (final layer in map.layers.whereType<ObjectLayer>()) {
    for (final object in layer.tileObjects) {
      add(object.tile.tilesetId);
    }
  }
  return ids;
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
  addSmartTileTilesetIds(ids, map, manifest);
  addEntityVisualTilesetIds(ids, map, manifest);
  addCharacterTilesetIds(ids, map, manifest);
  // Append placed-element visuals after the established sources so their
  // relative insertion order remains unchanged while the set deduplicates.
  addPlacedElementVisualTilesetIds(ids, map, manifest);
  return ids;
}
