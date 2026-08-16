import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_save_recovery_strings.dart';

class PlayerSaveRecoverySurface extends StatelessWidget {
  const PlayerSaveRecoverySurface({
    super.key,
    required this.diagnostic,
    required this.onAction,
  });

  final SaveLoadDiagnostic diagnostic;
  final ValueChanged<SaveRecoveryAction> onAction;

  static const ValueKey<String> surfaceKey =
      ValueKey<String>('player-save-recovery');

  static ValueKey<String> actionKey(SaveRecoveryAction action) =>
      ValueKey<String>('player-save-recovery-${action.name}');

  @override
  Widget build(BuildContext context) {
    final strings = PlayerSaveRecoveryStrings.of(context);
    final versions = strings.versions(
      detected: diagnostic.detectedSchemaVersion,
      expected: diagnostic.expectedSchemaVersion,
    );
    return PlayerPanel(
      key: surfaceKey,
      elevated: true,
      surfaceRole: ProjectPresentationSurfaceRole.notification,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(strings.cause(diagnostic.code), textAlign: TextAlign.center),
          if (versions != null) ...<Widget>[
            const SizedBox(height: PlayerSpacing.xs),
            Text(
              versions,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          for (final action in diagnostic.recommendedActions) ...<Widget>[
            const SizedBox(height: PlayerSpacing.sm),
            PlayerActionButton(
              key: actionKey(action),
              label: strings.action(action),
              icon: _iconFor(action),
              secondary: action != diagnostic.recommendedActions.first,
              onPressed: () => _activate(context, action),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _activate(
    BuildContext context,
    SaveRecoveryAction action,
  ) async {
    if (action != SaveRecoveryAction.deleteSave) {
      onAction(action);
      return;
    }
    final strings = PlayerSaveRecoveryStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey<String>('player-save-recovery-delete-confirm'),
        title: Text(strings.deleteConfirmTitle),
        content: Text(strings.deleteConfirmBody),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('player-save-recovery-delete-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.deleteCancel),
          ),
          TextButton(
            key: const ValueKey<String>('player-save-recovery-delete-accept'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.deleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed ?? false) onAction(action);
  }

  static IconData _iconFor(SaveRecoveryAction action) => switch (action) {
        SaveRecoveryAction.retry => Icons.refresh_rounded,
        SaveRecoveryAction.restoreBackup => Icons.restore_rounded,
        SaveRecoveryAction.migrate => Icons.upgrade_rounded,
        SaveRecoveryAction.deleteSave => Icons.delete_outline_rounded,
        SaveRecoveryAction.returnToTitle => Icons.home_rounded,
      };
}
