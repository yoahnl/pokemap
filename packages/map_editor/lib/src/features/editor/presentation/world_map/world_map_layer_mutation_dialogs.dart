import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/map_layer_deletion_impact.dart';

typedef WorldMapLayerRenameRequested = Future<String?> Function({
  required BuildContext context,
  required String layerId,
  required String currentName,
});

typedef WorldMapLayerDeleteRequested = Future<bool> Function({
  required BuildContext context,
  required MapLayerDeletionImpact impact,
});

Future<bool> runWorldMapLayerRenameFlow({
  required BuildContext context,
  required String layerId,
  required MapData? Function() readActiveMap,
  required WorldMapLayerRenameRequested onRenameRequested,
  required void Function(String layerId, String name) renameLayer,
}) async {
  final originalMap = readActiveMap();
  final originalLayer = originalMap?.layers
      .where((candidate) => candidate.id == layerId)
      .firstOrNull;
  if (originalMap == null || originalLayer == null) return false;
  final nextName = await onRenameRequested(
    context: context,
    layerId: layerId,
    currentName: originalLayer.name,
  );
  final normalizedName = nextName?.trim();
  if (normalizedName == null || normalizedName.isEmpty) return false;
  final currentMap = readActiveMap();
  final currentLayer = currentMap?.layers
      .where((candidate) => candidate.id == layerId)
      .firstOrNull;
  if (currentMap?.id != originalMap.id ||
      currentLayer == null ||
      currentLayer.name != originalLayer.name) {
    return false;
  }
  renameLayer(layerId, normalizedName);
  return true;
}

Future<bool> runWorldMapLayerDeleteFlow({
  required BuildContext context,
  required String layerId,
  required MapData? Function() readActiveMap,
  required WorldMapLayerDeleteRequested onDeleteRequested,
  required void Function(String layerId) deleteLayer,
}) async {
  final map = readActiveMap();
  if (map == null) return false;
  final impact = const MapLayerDeletionImpactProjector().project(
    map: map,
    layerId: layerId,
  );
  final confirmedPlacements = _placementsHostedByLayer(map, layerId);
  if (impact.isBlocked) return false;
  final confirmed = await onDeleteRequested(
    context: context,
    impact: impact,
  );
  if (!confirmed) return false;
  final currentMap = readActiveMap();
  if (currentMap == null ||
      currentMap.id != map.id ||
      !currentMap.layers.any((layer) => layer.id == layerId)) {
    return false;
  }
  final currentImpact = const MapLayerDeletionImpactProjector().project(
    map: currentMap,
    layerId: layerId,
  );
  if (currentImpact.isBlocked ||
      !_hasSameDeletionImpact(impact, currentImpact) ||
      !listEquals(
        confirmedPlacements,
        _placementsHostedByLayer(currentMap, layerId),
      )) {
    return false;
  }
  deleteLayer(layerId);
  return true;
}

Future<String?> showWorldMapLayerRenameDialog({
  required BuildContext context,
  required String layerId,
  required String currentName,
}) async {
  final controller = TextEditingController(text: currentName);
  try {
    final confirmed = await showPokeMapPromptDialog(
      context,
      title: 'Renommer le calque',
      controller: controller,
      placeholder: 'Nom du calque',
      cancelLabel: 'Annuler',
      confirmLabel: 'Renommer',
    );
    if (!confirmed) {
      return null;
    }
    final normalizedName = controller.text.trim();
    return normalizedName.isEmpty ? null : normalizedName;
  } finally {
    controller.dispose();
  }
}

Future<bool> showWorldMapLayerDeleteDialog({
  required BuildContext context,
  required MapLayerDeletionImpact impact,
}) async {
  final blocked = impact.blockingReasons.isNotEmpty;
  final result = await showPokeMapConfirmationDialog<bool>(
    context: context,
    title: blocked ? 'Suppression impossible' : 'Supprimer le calque',
    message: blocked
        ? 'Corrigez les dépendances ci-dessous avant de supprimer ce calque.'
        : 'Le calque et son contenu placé seront supprimés définitivement.',
    details: _MapLayerDeletionImpactDetails(impact: impact),
    actions: blocked
        ? const [
            PokeMapDialogAction(label: 'Fermer', value: false),
          ]
        : const [
            PokeMapDialogAction(label: 'Annuler', value: false),
            PokeMapDialogAction(
              label: 'Supprimer',
              value: true,
              variant: PokeMapButtonVariant.danger,
            ),
          ],
  );
  return !blocked && result == true;
}

final class _MapLayerDeletionImpactDetails extends StatelessWidget {
  const _MapLayerDeletionImpactDetails({required this.impact});

  final MapLayerDeletionImpact impact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeMapPanel(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ImpactRow(
                label: 'Éléments placés',
                value: '${impact.placedElementCount}',
              ),
              const SizedBox(height: 8),
              _ImpactRow(
                label: 'Événements de map',
                value: '${impact.affectedMapEventIds.length}',
              ),
              const SizedBox(height: 8),
              _ImpactRow(
                label: 'Éléments générés',
                value: '${impact.environmentGeneratedCount}',
              ),
              const SizedBox(height: 8),
              _ImpactRow(
                label: 'Environnements attachés',
                value: '${impact.environmentAttachmentCount}',
              ),
            ],
          ),
        ),
        if (impact.affectedMapEventIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Identifiants des événements concernés',
            style: TextStyle(
              color: context.pokeMapColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          for (final eventId in impact.affectedMapEventIds)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                eventId,
                style: TextStyle(
                  color: context.pokeMapColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
        if (impact.blockingReasons.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (var index = 0;
              index < impact.blockingReasons.length;
              index += 1) ...[
            if (index > 0) const SizedBox(height: 8),
            PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.error,
              title: 'Dépendance bloquante',
              message: impact.blockingReasons[index],
            ),
          ],
        ],
      ],
    );
  }
}

final class _ImpactRow extends StatelessWidget {
  const _ImpactRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

List<MapPlacedElement> _placementsHostedByLayer(
  MapData map,
  String layerId,
) {
  return map.placedElements
      .where((placement) => placement.layerId == layerId)
      .toList(growable: false);
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
