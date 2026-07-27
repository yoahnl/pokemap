import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
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
    final completed = snapshot.stage == RuntimeWorldServiceStage.completed;
    final applying = snapshot.stage == RuntimeWorldServiceStage.applying;
    final failed = snapshot.stage == RuntimeWorldServiceStage.failed;
    final canConfirm =
        snapshot.isActionEnabled(RuntimeWorldServiceAction.confirm);
    final confirmReason = snapshot.unavailableReasonFor(
      RuntimeWorldServiceAction.confirm,
    );

    return ColoredBox(
      color: context.playerColors.scrim,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(PlayerSpacing.md),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth < 600 ? 520 : 680,
                ),
                child: PlayerPanel(
                  elevated: true,
                  padding: const EdgeInsets.all(PlayerSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            completed
                                ? Icons.check_circle_outline
                                : Icons.healing_outlined,
                            color: completed
                                ? context.playerColors.success
                                : context.playerColors.primary,
                          ),
                          const SizedBox(width: PlayerSpacing.sm),
                          Expanded(
                            child: Text(
                              content.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: PlayerSpacing.xs),
                      Text(content.message),
                      if (applying) ...<Widget>[
                        const SizedBox(height: PlayerSpacing.md),
                        const LinearProgressIndicator(),
                      ],
                      if (!completed && content.members.isNotEmpty) ...<Widget>[
                        const SizedBox(height: PlayerSpacing.md),
                        for (final member in content.members)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: PlayerSpacing.xs,
                            ),
                            child: _HealPartyMember(member: member),
                          ),
                      ],
                      if (!completed && content.members.isEmpty) ...<Widget>[
                        const SizedBox(height: PlayerSpacing.md),
                        PlayerEmptyState(
                          icon: Icons.catching_pokemon,
                          title: strings.emptyTitle,
                          message: strings.emptyParty,
                        ),
                      ],
                      if (snapshot.safeMessage case final message?
                          when message.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: PlayerSpacing.md),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                      const SizedBox(height: PlayerSpacing.md),
                      if (completed)
                        PlayerActionButton(
                          key: const ValueKey<String>('heal-close'),
                          label: strings.returnToGame,
                          icon: Icons.check,
                          autofocus: true,
                          onPressed: () =>
                              _emit(RuntimeWorldServiceAction.close),
                        )
                      else if (!applying) ...<Widget>[
                        PlayerActionButton(
                          key: const ValueKey<String>('heal-confirm'),
                          label: failed ? strings.retry : strings.healParty,
                          icon: Icons.healing,
                          autofocus: true,
                          disabledReason: confirmReason,
                          onPressed: canConfirm
                              ? () => _emit(
                                    RuntimeWorldServiceAction.confirm,
                                  )
                              : null,
                        ),
                        const SizedBox(height: PlayerSpacing.xs),
                        PlayerActionButton(
                          key: const ValueKey<String>('heal-cancel'),
                          label: strings.cancel,
                          icon: Icons.close,
                          secondary: true,
                          onPressed: snapshot.isActionEnabled(
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
                      ],
                    ],
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
  const _HealFailureFallback({
    required this.strings,
    required this.onClose,
  });

  final PlayerHealStrings strings;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: context.playerColors.scrim,
        child: Center(
          child: PlayerPanel(
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
