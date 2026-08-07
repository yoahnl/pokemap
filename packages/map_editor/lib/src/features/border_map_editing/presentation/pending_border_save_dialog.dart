import 'package:flutter/material.dart' show Dialog, showDialog;
import 'package:flutter/widgets.dart';

import '../../../ui/design_system/design_system.dart';
import '../../../theme/theme.dart';
import '../../editor/state/editor_notifier.dart';
import '../application/pending_border_save_guard.dart';

/// Shared active-map save entry point for every World Maps save affordance.
Future<ActiveMapSaveOutcome> requestActiveMapSaveWithBorderPreviewGuard({
  required BuildContext context,
  required EditorNotifier notifier,
  bool confirmBulkPlacementLoss = false,
}) async {
  final initialOutcome = await notifier.saveActiveMap(
    confirmBulkPlacementLoss: confirmBulkPlacementLoss,
  );
  if (initialOutcome == ActiveMapSaveOutcome.bulkPlacementLossBlocked) {
    if (!context.mounted) return ActiveMapSaveOutcome.cancelled;
    final confirmed = await _confirmBulkPlacementLoss(
      context: context,
      savedCount: notifier.currentState.savedMapSnapshot?.placedElements.length,
      currentCount:
          notifier.currentState.activeMap?.placedElements.length,
    );
    if (!confirmed) return ActiveMapSaveOutcome.cancelled;
    if (!context.mounted) return ActiveMapSaveOutcome.cancelled;
    return requestActiveMapSaveWithBorderPreviewGuard(
      context: context,
      notifier: notifier,
      confirmBulkPlacementLoss: true,
    );
  }
  if (initialOutcome != ActiveMapSaveOutcome.pendingBorderDecisionRequired) {
    return initialOutcome;
  }
  if (!context.mounted) return ActiveMapSaveOutcome.cancelled;

  final decision = await showDialog<PendingBorderSaveDecision>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final colors = dialogContext.pokeMapColors;
      return Dialog(
        key: const Key('pending-border-save-dialog'),
        backgroundColor: colors.cardSurface,
        child: SizedBox(
          width: 600,
          child: PokeMapPanel(
            header: const Padding(
              padding: EdgeInsets.all(16),
              child: PokeMapSectionHeader(
                title: 'Aperçu de bordure en attente',
                description:
                    'La sauvegarde ne peut pas inclure un aperçu silencieusement.',
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Choisissez si cet aperçu doit être appliqué, abandonné ou '
                  'conservé sans sauvegarder.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    PokeMapButton(
                      onPressed: () => Navigator.of(dialogContext).pop(
                        PendingBorderSaveDecision.cancelSave,
                      ),
                      variant: PokeMapButtonVariant.secondary,
                      child: const Text('Annuler la sauvegarde'),
                    ),
                    PokeMapButton(
                      onPressed: () => Navigator.of(dialogContext).pop(
                        PendingBorderSaveDecision.discardAndSave,
                      ),
                      variant: PokeMapButtonVariant.danger,
                      child: const Text(
                        'Abandonner l’aperçu et sauvegarder',
                      ),
                    ),
                    PokeMapButton(
                      onPressed: () => Navigator.of(dialogContext).pop(
                        PendingBorderSaveDecision.applyAndSave,
                      ),
                      child: const Text('Appliquer et sauvegarder'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  if (!context.mounted) return ActiveMapSaveOutcome.cancelled;
  return notifier.saveActiveMap(
    confirmBulkPlacementLoss: confirmBulkPlacementLoss,
    pendingBorderDecision: decision ?? PendingBorderSaveDecision.cancelSave,
  );
}

/// Demande la confirmation d'une suppression massive de placements.
///
/// Le cœur refuse d'écrire une carte qui perd plus d'un quart de ses
/// placements, et il a raison quand la perte est accidentelle. Mais quand elle
/// est voulue, refuser sans rien proposer laisse l'auteur devant un mur : le
/// message parlait d'une confirmation explicite qui n'existait nulle part.
Future<bool> _confirmBulkPlacementLoss({
  required BuildContext context,
  required int? savedCount,
  required int? currentCount,
}) async {
  final lost = (savedCount ?? 0) - (currentCount ?? 0);
  final decision = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final colors = dialogContext.pokeMapColors;
      return Dialog(
        key: const Key('bulk-placement-loss-dialog'),
        backgroundColor: colors.cardSurface,
        child: SizedBox(
          width: 600,
          child: PokeMapPanel(
            header: const Padding(
              padding: EdgeInsets.all(16),
              child: PokeMapSectionHeader(
                title: 'Suppression massive de placements',
                description:
                    'Cette sauvegarde retire plus d’un quart des placements '
                    'de la carte.',
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Les placements passeraient de ${savedCount ?? 0} à '
                  '${currentCount ?? 0} : $lost seraient supprimés du fichier. '
                  'Si c’est bien ce que vous voulez, confirmez ; sinon, '
                  'annulez et rien ne sera écrit.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    PokeMapButton(
                      key: const Key('bulk-placement-loss-cancel'),
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      variant: PokeMapButtonVariant.secondary,
                      child: const Text('Annuler la sauvegarde'),
                    ),
                    PokeMapButton(
                      key: const Key('bulk-placement-loss-confirm'),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      variant: PokeMapButtonVariant.danger,
                      child: Text('Supprimer $lost placements et sauvegarder'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return decision ?? false;
}
