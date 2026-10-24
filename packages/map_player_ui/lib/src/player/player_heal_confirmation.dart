import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../foundation/player_paged_layout.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_heal_strings.dart';

/// Responsive healing confirmation driven entirely by a runtime snapshot.
class PlayerHealConfirmation extends StatelessWidget {
  const PlayerHealConfirmation({
    super.key,
    required this.snapshot,
    required this.onCommand,
  });

  final RuntimeWorldServiceSnapshot snapshot;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    final strings = PlayerHealStrings.of(context);
    final content = snapshot.content;
    if (content is! RuntimeHealServiceContent) {
      return _HealFailureFallback(
        strings: strings,
        onClose: () => _emit(RuntimeWorldServiceAction.close),
      );
    }
    final request = snapshot.request;
    if (snapshot.stage == RuntimeWorldServiceStage.applying &&
        request is OpenHealService &&
        !request.requiresConfirmation &&
        content.display != null &&
        content.display!.entityId == request.displayEntityId) {
      return const SizedBox.shrink();
    }
    final completed = snapshot.stage == RuntimeWorldServiceStage.completed;
    final applying = snapshot.stage == RuntimeWorldServiceStage.applying;
    final failed = snapshot.stage == RuntimeWorldServiceStage.failed;
    final canConfirm = snapshot.isActionEnabled(
      RuntimeWorldServiceAction.confirm,
    );
    final confirmReason = snapshot.unavailableReasonFor(
      RuntimeWorldServiceAction.confirm,
    );

    return PlayerMenuThemeScope(
      role: ProjectPresentationSurfaceRole.confirmation,
      child: Builder(
        builder: (context) => ColoredBox(
          color: context.playerColors.scrim,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 800,
                    maxHeight: 760,
                  ),
                  child: PlayerMenuPanel(
                    primary: true,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          content.title,
                          style: context.playerMenuTheme.title,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: PlayerPagedList(
                            children: [
                              Text(content.message),
                              if (applying) const LinearProgressIndicator(),
                              if (!completed) ...[
                                if (content.members.isEmpty)
                                  Text(strings.emptyParty),
                                for (final member in content.members)
                                  _HealPartyMember(member: member),
                              ],
                              if (snapshot.safeMessage case final message?
                                  when message.trim().isNotEmpty &&
                                      message != content.message)
                                Semantics(
                                  liveRegion: true,
                                  child: Text(message),
                                ),
                              if (confirmReason != null) Text(confirmReason),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (completed)
                          PlayerActionButton(
                            key: const ValueKey('heal-close'),
                            label: strings.returnToGame,
                            icon: Icons.check,
                            autofocus: true,
                            onPressed:
                                snapshot.isActionEnabled(
                                  RuntimeWorldServiceAction.close,
                                )
                                ? () => _emit(RuntimeWorldServiceAction.close)
                                : null,
                          )
                        else if (!applying)
                          Row(
                            children: [
                              Expanded(
                                child: PlayerActionButton(
                                  key: const ValueKey('heal-confirm'),
                                  label: failed
                                      ? strings.retry
                                      : strings.healParty,
                                  icon: Icons.healing,
                                  autofocus: true,
                                  onPressed: canConfirm
                                      ? () => _emit(
                                          RuntimeWorldServiceAction.confirm,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: PlayerActionButton(
                                  key: const ValueKey('heal-cancel'),
                                  label: strings.cancel,
                                  icon: Icons.close,
                                  secondary: true,
                                  onPressed:
                                      snapshot.isActionEnabled(
                                        RuntimeWorldServiceAction.cancel,
                                      )
                                      ? () => _emit(
                                          RuntimeWorldServiceAction.cancel,
                                        )
                                      : snapshot.isActionEnabled(
                                          RuntimeWorldServiceAction.close,
                                        )
                                      ? () => _emit(
                                          RuntimeWorldServiceAction.close,
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _emit(RuntimeWorldServiceAction action) {
    if (!snapshot.isActionEnabled(action)) return;
    onCommand(
      RuntimeWorldServiceCommand(
        action: action,
        snapshotRevision: snapshot.revision,
      ),
    );
  }
}

class _HealPartyMember extends StatelessWidget {
  const _HealPartyMember({required this.member});

  final RuntimeHealPartyMemberSnapshot member;

  @override
  Widget build(BuildContext context) {
    final strings = PlayerHealStrings.of(context);
    final hpRatio = (member.currentHp / member.maxHp).clamp(0.0, 1.0);
    return PlayerPanel(
      surfaceRole: ProjectPresentationSurfaceRole.confirmation,
      padding: const EdgeInsets.all(PlayerSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(member.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: PlayerSpacing.xs),
          LinearProgressIndicator(value: hpRatio),
          const SizedBox(height: PlayerSpacing.xxs),
          Text(strings.hp(member.currentHp, member.maxHp)),
          Wrap(
            spacing: PlayerSpacing.sm,
            runSpacing: PlayerSpacing.xxs,
            children: <Widget>[
              Text(strings.status(member.hasStatus)),
              Text(strings.pp(member.depletedMoveCount)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealFailureFallback extends StatelessWidget {
  const _HealFailureFallback({required this.strings, required this.onClose});

  final PlayerHealStrings strings;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.playerColors.scrim,
    child: Center(
      child: PlayerPanel(
        surfaceRole: ProjectPresentationSurfaceRole.confirmation,
        elevated: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(strings.unavailable),
            const SizedBox(height: PlayerSpacing.md),
            PlayerActionButton(
              label: strings.close,
              icon: Icons.close,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    ),
  );
}
