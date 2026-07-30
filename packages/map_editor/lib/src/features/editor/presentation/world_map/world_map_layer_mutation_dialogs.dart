import 'dart:async';

import 'package:flutter/material.dart';

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
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 250),
        controller.dispose,
      ),
    );
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
