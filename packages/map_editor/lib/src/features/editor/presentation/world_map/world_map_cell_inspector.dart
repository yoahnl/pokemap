import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../state/editor_notifier.dart';

class WorldMapCellInspector extends ConsumerWidget {
  const WorldMapCellInspector({
    super.key,
    required this.cell,
    required this.layerId,
  });

  final GridPos cell;
  final String? layerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(
      editorNotifierProvider.select(
        (state) => (
          project: state.project,
          map: state.activeMap,
        ),
      ),
    );
    final facts = _projectCellFacts(
      project: snapshot.project,
      map: snapshot.map,
      cell: cell,
      layerId: layerId,
    );

    return Semantics(
      container: true,
      label: 'Détails en lecture seule de la cellule ${facts.coordinate}',
      child: Padding(
        key: const ValueKey<String>('world-map-cell-inspector'),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PokeMapSectionHeader(
              title: 'Cellule sélectionnée',
              description:
                  'Valeurs enregistrées sur le calque actif, sans modification.',
            ),
            const SizedBox(height: 8),
            _CellFactCard(
              key: const ValueKey<String>('world-map-cell-coordinate'),
              label: 'Coordonnées',
              value: facts.coordinate,
            ),
            const SizedBox(height: 8),
            _CellFactCard(
              key: const ValueKey<String>('world-map-cell-layer'),
              label: 'Calque',
              value: facts.layer,
            ),
            const SizedBox(height: 8),
            _CellFactCard(
              key: const ValueKey<String>('world-map-cell-type'),
              label: 'Type',
              value: facts.type,
            ),
            const SizedBox(height: 8),
            _CellFactCard(
              key: const ValueKey<String>('world-map-cell-value'),
              label: 'Valeur',
              value: facts.value,
            ),
          ],
        ),
      ),
    );
  }
}

class _CellFactCard extends StatelessWidget {
  const _CellFactCard({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

typedef _CellFacts = ({
  String coordinate,
  String layer,
  String type,
  String value,
});

_CellFacts _projectCellFacts({
  required ProjectManifest? project,
  required MapData? map,
  required GridPos cell,
  required String? layerId,
}) {
  final coordinate = '(${cell.x}, ${cell.y})';
  if (map == null) {
    return (
      coordinate: coordinate,
      layer: layerId ?? 'Aucun calque',
      type: 'Inconnu',
      value: 'Aucune carte active',
    );
  }

  final layer = _findLayer(map, layerId);
  if (layer == null) {
    return (
      coordinate: coordinate,
      layer: layerId ?? 'Aucun calque',
      type: 'Inconnu',
      value: 'Calque introuvable',
    );
  }

  final index = _cellIndex(map.size, cell);
  return (
    coordinate: coordinate,
    layer: '${layer.name} (${layer.id})',
    type: _layerTypeLabel(layer),
    value: _cellValue(
      project: project,
      map: map,
      layer: layer,
      cell: cell,
      index: index,
    ),
  );
}

MapLayer? _findLayer(MapData map, String? layerId) {
  if (layerId == null) {
    return null;
  }
  for (final layer in map.layers) {
    if (layer.id == layerId) {
      return layer;
    }
  }
  return null;
}

int? _cellIndex(GridSize size, GridPos cell) {
  if (cell.x < 0 ||
      cell.y < 0 ||
      cell.x >= size.width ||
      cell.y >= size.height) {
    return null;
  }
  return cell.y * size.width + cell.x;
}

String _layerTypeLabel(MapLayer layer) {
  return switch (layer) {
    TileLayer() => 'Tuiles',
    CollisionLayer() => 'Collision',
    TerrainLayer() => 'Terrain',
    PathLayer() => 'Path',
    SurfaceLayer() => 'Surface',
    SmartTileLayer() => 'Smart Tile',
    ObjectLayer() => 'Objets',
    EnvironmentLayer() => 'Environnement',
    BorderLayer() => 'Bordures',
  };
}

String _cellValue({
  required ProjectManifest? project,
  required MapData map,
  required MapLayer layer,
  required GridPos cell,
  required int? index,
}) {
  if (index == null) {
    return 'Hors de la carte';
  }
  return switch (layer) {
    TileLayer(:final tiles, :final tilesetId) => _tileValue(
        project: project,
        map: map,
        tiles: tiles,
        tilesetId: tilesetId,
        index: index,
      ),
    CollisionLayer(:final collisions) => index >= collisions.length
        ? 'Donnée indisponible'
        : collisions[index]
            ? 'Bloquée'
            : 'Libre',
    TerrainLayer(:final terrains) =>
      index >= terrains.length ? 'Donnée indisponible' : terrains[index].name,
    PathLayer(:final cells, :final presetId) => index >= cells.length
        ? 'Donnée indisponible'
        : _pathValue(cells[index], presetId),
    SurfaceLayer(:final placements) => _surfaceValue(placements, cell),
    SmartTileLayer(:final materialCells, :final materialPalette) =>
      index >= materialCells.length
          ? 'Donnée indisponible'
          : materialCells[index] == 0
              ? 'Vide'
              : materialCells[index] < materialPalette.length
                  ? materialPalette[materialCells[index]]
                  : 'Index de matériau invalide',
    ObjectLayer() ||
    EnvironmentLayer() ||
    BorderLayer() =>
      'Aucune valeur par cellule',
  };
}

String _tileValue({
  required ProjectManifest? project,
  required MapData map,
  required List<int> tiles,
  required String? tilesetId,
  required int index,
}) {
  if (index >= tiles.length) {
    return 'Donnée indisponible';
  }
  final tileId = tiles[index];
  if (tileId <= 0) {
    return 'Vide';
  }
  final effectiveTilesetId = _nonEmpty(tilesetId) ?? _nonEmpty(map.tilesetId);
  if (effectiveTilesetId == null) {
    return 'Tuile $tileId · Tileset non assigné';
  }
  final tilesetName = _tilesetName(project, effectiveTilesetId);
  return tilesetName == null
      ? 'Tuile $tileId · Tileset $effectiveTilesetId'
      : 'Tuile $tileId · Tileset $tilesetName ($effectiveTilesetId)';
}

String? _nonEmpty(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String? _tilesetName(ProjectManifest? project, String tilesetId) {
  for (final tileset in project?.tilesets ?? const <ProjectTilesetEntry>[]) {
    if (tileset.id == tilesetId) {
      return tileset.name;
    }
  }
  return null;
}

String _pathValue(bool present, String presetId) {
  if (!present) {
    return 'Absent';
  }
  final normalizedPresetId = presetId.trim();
  return normalizedPresetId.isEmpty
      ? 'Présent · Aucun preset'
      : 'Présent · Preset $normalizedPresetId';
}

String _surfaceValue(
  List<SurfaceCellPlacement> placements,
  GridPos cell,
) {
  final ids = <String>{
    for (final placement in placements)
      if (placement.x == cell.x && placement.y == cell.y)
        placement.surfacePresetId,
  }.toList()
    ..sort();
  return ids.isEmpty ? 'Aucune' : ids.join(', ');
}
