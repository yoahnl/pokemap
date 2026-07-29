import 'package:map_core/map_core.dart';

import '../../features/editor/application/map_layer_grouping.dart';

final class LayerPanelPresentationRow {
  const LayerPanelPresentationRow({
    required this.layer,
    required this.groupIndex,
    required this.isActive,
    this.environmentAttachmentLabel,
    this.environmentWarningLabel,
    this.technicalEnvironmentSelectionLabel,
    this.attachedEnvironmentLayerIds = const <String>[],
  });

  final MapLayer layer;
  final int groupIndex;
  final bool isActive;
  final String? environmentAttachmentLabel;
  final String? environmentWarningLabel;
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

    rows.add(
      LayerPanelPresentationRow(
        layer: layer,
        groupIndex: groupIndex,
        isActive: layer.id == activeLayerId || hasActiveTechnicalEnvironment,
        environmentAttachmentLabel:
            _environmentAttachmentLabel(attachedEnvironmentLayerIds.length),
        environmentWarningLabel: _environmentWarningLabel(layer, layersById),
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
    return 'Cible invalide';
  }
  final targetLayer = layersById[targetLayerId];
  if (targetLayer is TileLayer) {
    return null;
  }
  return 'Cible invalide';
}
