import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../../../ui/panels/layers_panel_presentation.dart';
import '../../application/map_layer_deletion_impact.dart';
import '../../state/editor_notifier.dart';
import 'world_map_layer_mutation_dialogs.dart';

enum WorldMapLayerCreationKind {
  tile,
  collision,
  terrain,
  path,
  object,
  environment,
  border,
  surface,
}

class WorldMapLayersInspector extends ConsumerWidget {
  const WorldMapLayersInspector({
    super.key,
    this.onRenameRequested = showWorldMapLayerRenameDialog,
    this.onDeleteRequested = showWorldMapLayerDeleteDialog,
  });

  final WorldMapLayerRenameRequested onRenameRequested;
  final WorldMapLayerDeleteRequested onDeleteRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(
      editorNotifierProvider.select(
        (state) => (
          map: state.activeMap,
          activeLayerId: state.activeLayerId,
        ),
      ),
    );
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = snapshot.map;
    if (map == null) {
      return const PokeMapEmptyState(
        icon: Icon(Icons.layers_clear_outlined),
        title: 'Aucune carte chargée',
        description: 'Ouvrez une carte pour gérer ses calques.',
      );
    }
    final rows = buildLayerPanelPresentationRows(
      map,
      activeLayerId: snapshot.activeLayerId,
    );

    return Semantics(
      container: true,
      label: 'Calques de la carte, du premier plan vers l’arrière-plan',
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PokeMapSectionHeader(
              title: 'Calques',
              description: '${rows.length} calque(s) visible(s)',
              trailing: PokeMapSplitButton<WorldMapLayerCreationKind>(
                key: const ValueKey<String>('world-map-layer-add'),
                onPressed: () => _addLayer(
                  notifier,
                  WorldMapLayerCreationKind.tile,
                ),
                items: [
                  for (final kind in WorldMapLayerCreationKind.values)
                    PokeMapMenuItem<WorldMapLayerCreationKind>(
                      value: kind,
                      label: _creationKindLabel(kind),
                    ),
                ],
                onSelected: (kind) => _addLayer(notifier, kind),
                tooltip: 'Ajouter un calque de tuiles',
                menuTooltip: 'Choisir le type de calque',
                child: const Text('Ajouter'),
              ),
            ),
            const SizedBox(height: 8),
            const PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.info,
              title: 'Calque d’environnement',
              message: 'Zone auteur pour environnements organiques : forêts, '
                  'bosquets, prairies, côtes rocheuses.',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                key: const ValueKey<String>('world-map-layer-list'),
                itemCount: rows.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _WorldMapLayerRow(
                  key: ValueKey<String>(
                    'world-map-layer-row-${rows[index].layer.id}',
                  ),
                  row: rows[index],
                  notifier: notifier,
                  readActiveMap: () =>
                      ref.read(editorNotifierProvider).activeMap,
                  onRenameRequested: onRenameRequested,
                  onDeleteRequested: onDeleteRequested,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _WorldMapLayerRow extends StatelessWidget {
  const _WorldMapLayerRow({
    required this.row,
    required this.notifier,
    required this.readActiveMap,
    required this.onRenameRequested,
    required this.onDeleteRequested,
    super.key,
  });

  final LayerPanelPresentationRow row;
  final EditorNotifier notifier;
  final MapData? Function() readActiveMap;
  final WorldMapLayerRenameRequested onRenameRequested;
  final WorldMapLayerDeleteRequested onDeleteRequested;

  @override
  Widget build(BuildContext context) {
    final layer = row.layer;
    final layerId = layer.id;
    return PokeMapPanel(
      borderRadius: 8,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: PokeMapButton(
                  key: ValueKey<String>('world-map-layer-activate-$layerId'),
                  onPressed: row.activation.enabled
                      ? () => notifier.setActiveLayer(layerId)
                      : null,
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.compact,
                  isSelected: row.isActive,
                  leading: row.isActive
                      ? Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey<String>(
                            'world-map-layer-active-$layerId',
                          ),
                        )
                      : Icon(_layerIcon(layer)),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(layer.name),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PokeMapIconButton(
                key: ValueKey<String>('world-map-layer-visibility-$layerId'),
                tooltip: layer.isVisible
                    ? 'Masquer le calque'
                    : 'Afficher le calque',
                isSelected: layer.isVisible,
                onPressed: row.visibility.enabled
                    ? () => notifier.setMapLayerVisibility(
                          layerId,
                          !layer.isVisible,
                        )
                    : null,
                icon: Icon(
                  layer.isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              PokeMapIconButton(
                key: ValueKey<String>('world-map-layer-rename-$layerId'),
                tooltip: row.rename.disabledReason ?? 'Renommer le calque',
                onPressed: row.rename.enabled
                    ? () => _renameLayer(context, layer)
                    : null,
                icon: const Icon(Icons.edit_outlined),
              ),
              PokeMapIconButton(
                key: ValueKey<String>('world-map-layer-delete-$layerId'),
                tooltip: row.delete.disabledReason ?? 'Supprimer le calque',
                variant: PokeMapIconButtonVariant.danger,
                onPressed: row.delete.enabled
                    ? () => _deleteLayer(context, layerId)
                    : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          if (row.environmentAttachmentLabel case final label?) ...[
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: context.pokeMapColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
          if (row.environmentWarningLabel case final warning?) ...[
            const SizedBox(height: 6),
            PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.warning,
              message: warning,
            ),
          ],
          const SizedBox(height: 8),
          PokeMapGuidedSlider(
            key: ValueKey<String>('world-map-layer-opacity-$layerId'),
            label: 'Opacité',
            value: (layer.opacity * 100).round(),
            onChanged: row.opacity.enabled
                ? (value) => notifier.setMapLayerOpacity(
                      layerId,
                      value / 100,
                    )
                : (_) {},
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PokeMapIconButton(
                key: ValueKey<String>('world-map-layer-move-up-$layerId'),
                tooltip: row.moveUp.disabledReason ?? 'Monter le calque',
                onPressed: row.moveUp.enabled
                    ? () => notifier.moveMapLayerGroupUp(layerId)
                    : null,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
              const SizedBox(width: 4),
              PokeMapIconButton(
                key: ValueKey<String>('world-map-layer-move-down-$layerId'),
                tooltip: row.moveDown.disabledReason ?? 'Descendre le calque',
                onPressed: row.moveDown.enabled
                    ? () => notifier.moveMapLayerGroupDown(layerId)
                    : null,
                icon: const Icon(Icons.arrow_downward_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _renameLayer(BuildContext context, MapLayer layer) async {
    final originalMap = readActiveMap();
    if (originalMap == null ||
        !originalMap.layers.any((candidate) => candidate.id == layer.id)) {
      return;
    }
    final nextName = await onRenameRequested(
      context: context,
      layerId: layer.id,
      currentName: layer.name,
    );
    final normalizedName = nextName?.trim();
    if (normalizedName == null || normalizedName.isEmpty) {
      return;
    }
    final currentMap = readActiveMap();
    final currentLayer = currentMap?.layers
        .where((candidate) => candidate.id == layer.id)
        .firstOrNull;
    if (currentMap?.id != originalMap.id ||
        currentLayer == null ||
        currentLayer.name != layer.name) {
      return;
    }
    notifier.renameMapLayer(layer.id, normalizedName);
  }

  Future<void> _deleteLayer(BuildContext context, String layerId) async {
    final map = readActiveMap();
    if (map == null) {
      return;
    }
    final impact = const MapLayerDeletionImpactProjector().project(
      map: map,
      layerId: layerId,
    );
    if (impact.isBlocked) {
      return;
    }
    final confirmed = await onDeleteRequested(
      context: context,
      impact: impact,
    );
    if (!confirmed) {
      return;
    }
    final currentMap = readActiveMap();
    if (currentMap == null ||
        currentMap.id != map.id ||
        !currentMap.layers.any((layer) => layer.id == layerId)) {
      return;
    }
    final currentImpact = const MapLayerDeletionImpactProjector().project(
      map: currentMap,
      layerId: layerId,
    );
    if (currentImpact.isBlocked ||
        !_hasSameDeletionImpact(impact, currentImpact)) {
      return;
    }
    notifier.deleteMapLayer(layerId);
  }
}

bool _hasSameDeletionImpact(
  MapLayerDeletionImpact confirmed,
  MapLayerDeletionImpact current,
) {
  return confirmed.layerId == current.layerId &&
      confirmed.placedElementCount == current.placedElementCount &&
      listEquals(confirmed.affectedMapEventIds, current.affectedMapEventIds) &&
      confirmed.environmentGeneratedCount ==
          current.environmentGeneratedCount &&
      confirmed.environmentAttachmentCount ==
          current.environmentAttachmentCount &&
      listEquals(confirmed.blockingReasons, current.blockingReasons);
}

void _addLayer(
  EditorNotifier notifier,
  WorldMapLayerCreationKind kind,
) {
  switch (kind) {
    case WorldMapLayerCreationKind.surface:
      notifier.addSurfaceLayer(name: _creationKindDefaultName(kind));
    case WorldMapLayerCreationKind.tile:
    case WorldMapLayerCreationKind.collision:
    case WorldMapLayerCreationKind.terrain:
    case WorldMapLayerCreationKind.path:
    case WorldMapLayerCreationKind.object:
    case WorldMapLayerCreationKind.environment:
    case WorldMapLayerCreationKind.border:
      notifier.addMapLayer(
        kind: _mapLayerKind(kind),
        name: _creationKindDefaultName(kind),
      );
  }
}

MapLayerKind _mapLayerKind(WorldMapLayerCreationKind kind) {
  return switch (kind) {
    WorldMapLayerCreationKind.tile => MapLayerKind.tile,
    WorldMapLayerCreationKind.collision => MapLayerKind.collision,
    WorldMapLayerCreationKind.terrain => MapLayerKind.terrain,
    WorldMapLayerCreationKind.path => MapLayerKind.path,
    WorldMapLayerCreationKind.object => MapLayerKind.object,
    WorldMapLayerCreationKind.environment => MapLayerKind.environment,
    WorldMapLayerCreationKind.border => MapLayerKind.border,
    WorldMapLayerCreationKind.surface => throw StateError(
        'Surface layers must use addSurfaceLayer.',
      ),
  };
}

String _creationKindLabel(WorldMapLayerCreationKind kind) {
  return switch (kind) {
    WorldMapLayerCreationKind.tile => 'Couche de tuiles (Tile)',
    WorldMapLayerCreationKind.collision => 'Couche de collision',
    WorldMapLayerCreationKind.terrain => 'Couche de terrain',
    WorldMapLayerCreationKind.path => 'Couche de chemin (Path)',
    WorldMapLayerCreationKind.object => 'Couche d’objets',
    WorldMapLayerCreationKind.environment => 'Couche d’environnement',
    WorldMapLayerCreationKind.border => 'Couche de bordures',
    WorldMapLayerCreationKind.surface => 'Couche de surface',
  };
}

String _creationKindDefaultName(WorldMapLayerCreationKind kind) {
  return switch (kind) {
    WorldMapLayerCreationKind.tile => 'Tuiles',
    WorldMapLayerCreationKind.collision => 'Collision',
    WorldMapLayerCreationKind.terrain => 'Terrain',
    WorldMapLayerCreationKind.path => 'Chemins',
    WorldMapLayerCreationKind.object => 'Objets',
    WorldMapLayerCreationKind.environment => 'Environnement',
    WorldMapLayerCreationKind.border => 'Bordures',
    WorldMapLayerCreationKind.surface => 'Surfaces',
  };
}

IconData _layerIcon(MapLayer layer) {
  return switch (layer) {
    TileLayer() => Icons.grid_view_rounded,
    CollisionLayer() => Icons.block_outlined,
    TerrainLayer() => Icons.landscape_outlined,
    PathLayer() => Icons.route_outlined,
    ObjectLayer() => Icons.category_outlined,
    EnvironmentLayer() => Icons.park_outlined,
    BorderLayer() => Icons.border_outer_rounded,
    SurfaceLayer() => Icons.layers_outlined,
  };
}
