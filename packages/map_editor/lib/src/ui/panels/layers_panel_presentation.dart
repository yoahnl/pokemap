import 'package:map_core/map_core.dart';

final class LayerPanelPresentationRow {
  const LayerPanelPresentationRow({
    required this.layer,
    required this.layerIndex,
    required this.isActive,
    this.environmentAttachmentLabel,
    this.environmentWarningLabel,
    this.technicalEnvironmentSelectionLabel,
    this.attachedEnvironmentLayerIds = const <String>[],
  });

  final MapLayer layer;
  final int layerIndex;
  final bool isActive;
  final String? environmentAttachmentLabel;
  final String? environmentWarningLabel;
  final String? technicalEnvironmentSelectionLabel;
  final List<String> attachedEnvironmentLayerIds;

  bool get isTechnicalEnvironmentSelection =>
      technicalEnvironmentSelectionLabel != null;
}

List<LayerPanelPresentationRow> buildLayerPanelPresentationRows(
  MapData map, {
  String? activeLayerId,
}) {
  final layersById = {
    for (final layer in map.layers) layer.id: layer,
  };
  final attachedEnvironmentLayersByTarget = <String, List<EnvironmentLayer>>{};
  final hiddenEnvironmentLayerIds = <String>{};

  for (final layer in map.layers.whereType<EnvironmentLayer>()) {
    final targetLayerId = layer.content.targetTileLayerId?.trim();
    if (targetLayerId == null || targetLayerId.isEmpty) {
      continue;
    }
    final targetLayer = layersById[targetLayerId];
    if (targetLayer is! TileLayer) {
      continue;
    }
    attachedEnvironmentLayersByTarget
        .putIfAbsent(targetLayer.id, () => <EnvironmentLayer>[])
        .add(layer);
    hiddenEnvironmentLayerIds.add(layer.id);
  }

  final rows = <LayerPanelPresentationRow>[];
  for (var index = 0; index < map.layers.length; index += 1) {
    final layer = map.layers[index];
    if (hiddenEnvironmentLayerIds.contains(layer.id)) {
      continue;
    }

    final attachedEnvironmentLayers = layer is TileLayer
        ? attachedEnvironmentLayersByTarget[layer.id] ??
            const <EnvironmentLayer>[]
        : const <EnvironmentLayer>[];
    final attachedEnvironmentLayerIds = attachedEnvironmentLayers
        .map((environmentLayer) => environmentLayer.id)
        .toList(growable: false);
    final hasActiveTechnicalEnvironment =
        attachedEnvironmentLayerIds.contains(activeLayerId);

    rows.add(
      LayerPanelPresentationRow(
        layer: layer,
        layerIndex: index,
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
