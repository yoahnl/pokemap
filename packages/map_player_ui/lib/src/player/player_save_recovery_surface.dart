import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_components.dart';
import '../foundation/player_input_scope.dart';
import '../foundation/player_menu_components.dart';
import '../foundation/player_paged_layout.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_window_theme.dart';
import '../theme/pokemap_player_layout_theme.dart';
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
    if (context.playerWindowTheme == null &&
        context.playerLayoutTheme == null) {
      return PlayerMenuThemeScope(
        role: ProjectPresentationSurfaceRole.notification,
        child: Builder(
          builder: (context) {
            final theme = context.playerMenuTheme;
            return ColoredBox(
              key: const ValueKey('player-save-recovery-scrim'),
              color: context.playerColors.scrim,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(
                      PlayerCompanionScope.of(context) ? 14 : 16,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).aspectRatio > 1
                            ? 500
                            : 440,
                        maxHeight: 600,
                      ),
                      child: _RecoveryCard(
                        key: surfaceKey,
                        title: strings.cause(diagnostic.code),
                        body: [if (versions != null) Text(versions)],
                        actions: [
                          for (final action in diagnostic.recommendedActions)
                            PlayerActionButton(
                              key: actionKey(action),
                              label: strings.action(action),
                              labelMaxLines: 8,
                              icon: null,
                              secondary:
                                  action != diagnostic.recommendedActions.first,
                              foregroundColor:
                                  action == SaveRecoveryAction.deleteSave
                                  ? theme.danger
                                  : null,
                              backgroundColor:
                                  action == SaveRecoveryAction.deleteSave
                                  ? Color.alphaBlend(
                                      theme.danger.withValues(alpha: .12),
                                      theme.panel,
                                    )
                                  : null,
                              onPressed: () => _activate(context, action),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return PlayerSessionPanel(
      key: surfaceKey,
      title: strings.cause(diagnostic.code),
      body: [if (versions != null) Text(versions)],
      actions: [
        for (final action in diagnostic.recommendedActions)
          PlayerActionButton(
            key: actionKey(action),
            label: strings.action(action),
            labelMaxLines: 3,
            icon: _iconFor(action),
            secondary: action != diagnostic.recommendedActions.first,
            onPressed: () => _activate(context, action),
          ),
      ],
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
      builder: (dialogContext) {
        final authored =
            context.playerWindowTheme != null ||
            context.playerLayoutTheme != null;
        return PlayerMenuThemeScope(
          role: ProjectPresentationSurfaceRole.notification,
          child: Builder(
            builder: (context) {
              final theme = context.playerMenuTheme;
              final actions = [
                PlayerActionButton(
                  key: const ValueKey<String>(
                    'player-save-recovery-delete-cancel',
                  ),
                  label: strings.deleteCancel,
                  labelMaxLines: 8,
                  icon: authored ? Icons.arrow_back : null,
                  autofocus: true,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                PlayerActionButton(
                  key: const ValueKey<String>(
                    'player-save-recovery-delete-accept',
                  ),
                  label: strings.deleteConfirm,
                  labelMaxLines: 8,
                  icon: authored ? Icons.delete_outline : null,
                  secondary: true,
                  foregroundColor: authored ? null : theme.danger,
                  backgroundColor: authored
                      ? null
                      : Color.alphaBlend(
                          theme.danger.withValues(alpha: .12),
                          theme.panel,
                        ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ];
              return Dialog(
                key: const ValueKey<String>(
                  'player-save-recovery-delete-confirm',
                ),
                insetPadding: const EdgeInsets.all(16),
                backgroundColor: authored
                    ? PokeMapPlayerMenuTheme.resolve(dialogContext).backdrop
                    : theme.panel,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                constraints: BoxConstraints(
                  maxWidth: authored ? 640 : 500,
                  maxHeight: 600,
                ),
                child: authored
                    ? PlayerSessionPanel(
                        title: strings.deleteConfirmTitle,
                        body: [Text(strings.deleteConfirmBody)],
                        actions: actions,
                      )
                    : _RecoveryCard(
                        title: strings.deleteConfirmTitle,
                        body: [Text(strings.deleteConfirmBody)],
                        actions: actions,
                      ),
              );
            },
          ),
        );
      },
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

class _RecoveryCard extends StatefulWidget {
  const _RecoveryCard({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
  });

  final String title;
  final List<Widget> body;
  final List<Widget> actions;

  @override
  State<_RecoveryCard> createState() => _RecoveryCardState();
}

class _RecoveryCardState extends State<_RecoveryCard> {
  double? _contentHeight;
  Object? _signature;

  @override
  Widget build(BuildContext context) => PlayerMenuPanel(
    key: const ValueKey('player-save-recovery-card'),
    padding: const EdgeInsets.all(18),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final signature = (
          constraints.maxWidth,
          MediaQuery.textScalerOf(context),
          widget.title,
          widget.body,
          widget.actions,
        );
        if (_signature != signature) {
          _signature = signature;
          _contentHeight = null;
        }
        final columns =
            MediaQuery.textScalerOf(context).scale(1) < 1.5 &&
                constraints.maxWidth >= 280
            ? 2
            : 1;
        return SizedBox(
          height: math.min(
            _contentHeight ?? constraints.maxHeight,
            constraints.maxHeight,
          ),
          child: PlayerPagedList(
            onContentHeightChanged: (height) {
              if (mounted &&
                  _signature == signature &&
                  (_contentHeight == null ||
                      (_contentHeight! - height).abs() > .5)) {
                setState(() => _contentHeight = height);
              }
            },
            children: [
              Text(
                widget.title,
                key: const ValueKey('player-session-title'),
                style: context.playerMenuTheme.title,
              ),
              ...widget.body,
              for (var i = 0; i < widget.actions.length; i += columns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (
                      var j = i;
                      j < math.min(i + columns, widget.actions.length);
                      j++
                    ) ...[
                      if (j > i) const SizedBox(width: 8),
                      Expanded(child: widget.actions[j]),
                    ],
                    if (columns == 2 &&
                        widget.actions.length > 1 &&
                        i + 1 == widget.actions.length) ...[
                      const SizedBox(width: 8),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    ),
  );
}
