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
