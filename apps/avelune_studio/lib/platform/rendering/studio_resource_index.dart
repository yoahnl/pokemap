import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:map_runtime/map_runtime.dart'
    show characterAnimationRuntimeImageId;

final class StudioResourceIndex {
  StudioResourceIndex(this.manifest) {
    for (final tileset in manifest.tilesets) {
      tilesets[tileset.id] = tileset;
      final source = tileset.source;
      final ids = source is ProjectImageCollectionTilesetSource
          ? source.pages.map((page) => page.assetId).toSet()
          : {tileset.id};
      _ids[tileset.id] = ids;
      for (final id in ids) {
        names[id] = tileset.name;
        if (tileset.transparentColor != null) {
          colors[id] = tileset.transparentColor!;
        }
      }
      if (tileset.relativePath.trim().isNotEmpty &&
          tileset.relativePath == tileset.relativePath.trim()) {
        supported.add(tileset.id);
      }
    }
    elements.addEntries(
      manifest.elements.map((entry) => MapEntry(entry.id, entry)),
    );
  }

  final ProjectManifest manifest;
  final Map<String, ProjectTilesetEntry> tilesets = {};
  final Map<String, ProjectElementEntry> elements = {};
  final Map<String, String> names = {};
  final Map<String, TilesetTransparentColor> colors = {};
  final Set<String> supported = {};
  final Map<String, Set<String>> _ids = {};
  final Expando<Set<String>> _mapDependencies = Expando();

  Set<String> expand(Iterable<String> ids) => {
    for (final id in ids) ...?_ids[id],
    for (final id in ids)
      if (!_ids.containsKey(id)) id,
  };

  Set<String> forElement(ProjectElementEntry element) => expand({
    for (final frame in element.frames)
      frame.tilesetId.isEmpty ? element.tilesetId : frame.tilesetId,
  });

  Set<String> forCharacter(ProjectCharacterEntry character) => expand({
    for (final animation in character.animations)
      if (animation.state == CharacterAnimationState.idle)
        if (animation.sourceAssetId?.trim().isNotEmpty ?? false)
          characterAnimationRuntimeImageId(animation.sourceAssetId!)
        else
          character.tilesetId,
  });

  Set<String> forTerrain(ProjectSmartTilePreset preset) {
    final ids = <String>{};
    addSmartTileTilesetIds(
      ids,
      MapData(
        id: 'brush',
        name: 'Brush',
        size: const GridSize(width: 1, height: 1),
        layers: [
          MapLayer.smartTile(
            id: 'brush',
            name: 'Brush',
            presetId: preset.id,
            usage: preset.usage,
            field: const SmartTileField.cell(semanticCells: [0]),
          ),
        ],
      ),
      manifest.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          atlases: manifest.smartTileCatalog.atlases,
          animations: manifest.smartTileCatalog.animations,
          presets: [preset],
        ),
      ),
    );
    return expand(ids);
  }

  Set<String> forTile(TileLayerPaletteEntry tile) {
    final source = tilesets[tile.tilesetId]?.source;
    if (source is! ProjectImageCollectionTilesetSource) {
      return expand({tile.tilesetId});
    }
    try {
      final visual = const ProjectTilesetVisualResolver().resolve(
        source: source,
        selection: ProjectTilesetVisualSelection.imageCollection(
          tileId: tile.localTileId,
        ),
        cellWidth: manifest.settings.tileWidth,
        cellHeight: manifest.settings.tileHeight,
      );
      return {
        for (final frame in visual.frames)
          for (final slice in frame.slices) slice.assetId,
      };
    } on Object {
      return {tile.tilesetId};
    }
  }

  Set<String> forMap(MapData map) {
    final cached = _mapDependencies[map];
    if (cached != null) return cached;
    final ids = collectAllRuntimeTilesetIds(
      map.copyWith(
        layers: [
          for (final layer in map.layers)
            if (layer is! TileLayer && layer is! ObjectLayer) layer,
        ],
      ),
      manifest,
    );
    if (tilesets[map.tilesetId]?.source
        is ProjectImageCollectionTilesetSource) {
      ids.remove(map.tilesetId);
    }
    final result = expand(ids);
    final characters = {
      for (final entry in manifest.characters) entry.id: entry,
    };
    for (final entity in map.entities) {
      final character = characters[entity.npc?.characterId];
      if (character != null) result.addAll(forCharacter(character));
    }
    for (final layer in map.layers) {
      if (!layer.isVisible || !mapLayerParticipatesInVisualComposition(layer)) {
        continue;
      }
      if (layer is TileLayer) {
        for (final index in layer.cells.toSet()) {
          if (index > 0 && index <= layer.palette.length) {
            result.addAll(forTile(layer.palette[index - 1]));
          }
        }
      } else if (layer is ObjectLayer) {
        for (final object in layer.tileObjects.where(
          (entry) => entry.isVisible,
        )) {
          result.addAll(forTile(object.tile));
        }
      }
    }
    return _mapDependencies[map] = result;
  }
}
