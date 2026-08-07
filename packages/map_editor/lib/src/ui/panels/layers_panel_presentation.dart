import 'package:map_core/map_core.dart';

import '../../features/editor/application/map_layer_deletion_impact.dart';
import '../../features/editor/application/map_layer_grouping.dart';

final class LayerPanelActionCapability {
  const LayerPanelActionCapability({
    required this.enabled,
    this.disabledReason,
  }) : assert(enabled || disabledReason != null);

  const LayerPanelActionCapability.enabled()
      : enabled = true,
        disabledReason = null;

  const LayerPanelActionCapability.disabled(String reason)
      : enabled = false,
        disabledReason = reason;

  final bool enabled;
  final String? disabledReason;
}

final class LayerPanelPresentationRow {
  const LayerPanelPresentationRow({
    required this.layer,
    required this.groupIndex,
    required this.isActive,
    required this.activation,
    required this.visibility,
    required this.opacity,
    required this.rename,
    required this.delete,
    required this.moveUp,
    required this.moveDown,
    required this.deletionImpact,
    this.environmentAttachmentLabel,
    this.environmentWarningLabel,
    this.environmentTargetPendingLabel,
    this.technicalEnvironmentSelectionLabel,
    this.attachedEnvironmentLayerIds = const <String>[],
  });

  final MapLayer layer;
  final int groupIndex;
  final bool isActive;
  final LayerPanelActionCapability activation;
  final LayerPanelActionCapability visibility;
  final LayerPanelActionCapability opacity;
  final LayerPanelActionCapability rename;
  final LayerPanelActionCapability delete;
  final LayerPanelActionCapability moveUp;
  final LayerPanelActionCapability moveDown;
  final MapLayerDeletionImpact deletionImpact;
  final String? environmentAttachmentLabel;
  final String? environmentWarningLabel;

  /// Set on an Environment layer that simply has no target TileLayer yet.
  ///
  /// This is a legitimate step — the mask can already be painted — so it is
  /// deliberately kept apart from [environmentWarningLabel], which means the
  /// configured target points at something that cannot be decorated.
  final String? environmentTargetPendingLabel;
  final String? technicalEnvironmentSelectionLabel;
  final List<String> attachedEnvironmentLayerIds;

  bool get isTechnicalEnvironmentSelection =>
      technicalEnvironmentSelectionLabel != null;

  bool get hasAttachedEnvironmentLayers =>
      attachedEnvironmentLayerIds.isNotEmpty;

  bool get isDeleteProtectedByEnvironmentAttachment =>
      layer is TileLayer && hasAttachedEnvironmentLayers;
}

List<LayerPanelPresentationRow> buildLayerPanelPresentationRows(
  MapData map, {
  String? activeLayerId,
}) {
  final layersById = {
    for (final layer in map.layers) layer.id: layer,
  };
  const groupService = MapLayerGroupService();
  final groups = groupService.groupsTopFirst(map);
  final rows = <LayerPanelPresentationRow>[];
  for (var groupIndex = 0; groupIndex < groups.length; groupIndex += 1) {
    final group = groups[groupIndex];
    final layer = group.primaryLayer;
    final attachedEnvironmentLayerIds = group.attachedEnvironmentLayersTopFirst
        .map((environmentLayer) => environmentLayer.id)
        .toList(growable: false);
    final hasActiveTechnicalEnvironment =
        attachedEnvironmentLayerIds.contains(activeLayerId);
    final deletionImpact = const MapLayerDeletionImpactProjector().project(
      map: map,
      layerId: layer.id,
    );

    rows.add(
      LayerPanelPresentationRow(
        layer: layer,
        groupIndex: groupIndex,
        isActive: layer.id == activeLayerId || hasActiveTechnicalEnvironment,
        activation: const LayerPanelActionCapability.enabled(),
        visibility: const LayerPanelActionCapability.enabled(),
        opacity: const LayerPanelActionCapability.enabled(),
        rename: const LayerPanelActionCapability.enabled(),
        delete: deletionImpact.isBlocked
            ? LayerPanelActionCapability.disabled(
                deletionImpact.blockingReasons.join('\n'),
              )
            : const LayerPanelActionCapability.enabled(),
        moveUp: groupIndex == 0
            ? const LayerPanelActionCapability.disabled(
                'Ce calque est déjà tout en haut.',
              )
            : const LayerPanelActionCapability.enabled(),
        moveDown: groupIndex == groups.length - 1
            ? const LayerPanelActionCapability.disabled(
                'Ce calque est déjà tout en bas.',
              )
            : const LayerPanelActionCapability.enabled(),
        deletionImpact: deletionImpact,
        environmentAttachmentLabel:
            _environmentAttachmentLabel(attachedEnvironmentLayerIds.length),
        environmentWarningLabel: _environmentWarningLabel(layer, layersById),
        environmentTargetPendingLabel: _environmentTargetPendingLabel(layer),
        technicalEnvironmentSelectionLabel: hasActiveTechnicalEnvironment
            ? 'Environnement technique sélectionné'
            : null,
        attachedEnvironmentLayerIds: attachedEnvironmentLayerIds,
      ),
    );
  }

  return rows;
}

String? _environmentAttachmentLabel(int count) {
  if (count == 0) {
    return null;
  }
  if (count == 1) {
    return 'Environnement actif';
  }
  return '$count environnements attachés';
}

String? _environmentWarningLabel(
  MapLayer layer,
  Map<String, MapLayer> layersById,
) {
  if (layer is! EnvironmentLayer) {
    return null;
  }
  final targetLayerId = layer.content.targetTileLayerId?.trim();
  if (targetLayerId == null || targetLayerId.isEmpty) {
    // Not yet configured is not the same as misconfigured; see
    // [_environmentTargetPendingLabel].
    return null;
  }
  final targetLayer = layersById[targetLayerId];
  if (targetLayer is TileLayer) {
    return null;
  }
  return 'Cible invalide';
}

String? _environmentTargetPendingLabel(MapLayer layer) {
  if (layer is! EnvironmentLayer) {
    return null;
  }
  final targetLayerId = layer.content.targetTileLayerId?.trim();
  if (targetLayerId != null && targetLayerId.isNotEmpty) {
    return null;
  }
  return 'Cible à définir';
}
