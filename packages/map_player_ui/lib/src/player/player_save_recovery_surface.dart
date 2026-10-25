import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'player_session_surfaces.dart';
import 'player_save_recovery_strings.dart';

class PlayerSaveRecoverySurface extends StatelessWidget {
  const PlayerSaveRecoverySurface({
    super.key,
    required this.diagnostic,
    required this.onAction,
  });

  final SaveLoadDiagnostic diagnostic;
  final ValueChanged<SaveRecoveryAction> onAction;

  static const ValueKey<String> surfaceKey = ValueKey<String>(
    'player-save-recovery',
  );

  static ValueKey<String> actionKey(SaveRecoveryAction action) =>
      ValueKey<String>('player-save-recovery-${action.name}');

  @override
  Widget build(BuildContext context) {
    final strings = PlayerSaveRecoveryStrings.of(context);
    final versions = strings.versions(
      detected: diagnostic.detectedSchemaVersion,
      expected: diagnostic.expectedSchemaVersion,
    );
    return PlayerMenuThemeScope(
      role: ProjectPresentationSurfaceRole.notification,
      child: Builder(
        builder: (context) => LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 640.0;
            final columns =
                width >= 600 && MediaQuery.textScalerOf(context).scale(1) < 1.5
                ? 2
                : 1;
            return PlayerMenuPanel(
              key: surfaceKey,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.cause(diagnostic.code),
                    style: context.playerMenuTheme.subtitle,
                  ),
                  if (versions != null) ...[
                    const SizedBox(height: 8),
                    Text(versions, style: context.playerMenuTheme.body),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final action in diagnostic.recommendedActions)
                        SizedBox(
                          width: (width - 32 - (columns - 1) * 8) / columns,
                          child: PlayerActionButton(
                            key: actionKey(action),
                            label: strings.action(action),
                            labelMaxLines: 3,
                            icon: _iconFor(action),
                            secondary:
                                action != diagnostic.recommendedActions.first,
                            onPressed: () => _activate(context, action),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
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
      builder: (dialogContext) => Dialog(
        key: const ValueKey<String>('player-save-recovery-delete-confirm'),
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: PokeMapPlayerMenuTheme.resolve(dialogContext).backdrop,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 600),
        child: PlayerSessionPanel(
          title: strings.deleteConfirmTitle,
          body: [Text(strings.deleteConfirmBody)],
          actions: [
            PlayerActionButton(
              key: const ValueKey<String>('player-save-recovery-delete-cancel'),
              label: strings.deleteCancel,
              labelMaxLines: 3,
              icon: Icons.arrow_back,
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            PlayerActionButton(
              key: const ValueKey<String>('player-save-recovery-delete-accept'),
              label: strings.deleteConfirm,
              labelMaxLines: 3,
              icon: Icons.delete_outline,
              secondary: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
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
