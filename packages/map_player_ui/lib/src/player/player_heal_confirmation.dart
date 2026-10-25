import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_heal_strings.dart';
import 'player_service_layout.dart';

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
                    maxWidth: 500,
                    maxHeight: 760,
                  ),
                  child: PlayerMenuPanel(
                    key: const ValueKey('heal-service-panel'),
                    primary: true,
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            MediaQuery.sizeOf(context).aspectRatio > 1 &&
                                constraints.maxWidth >= 400 &&
                                MediaQuery.textScalerOf(context).scale(1) < 1.5
                            ? 2
                            : 1;
                        return PlayerServiceContent(
                          contentIdentity: (
                            snapshot.revision,
                            snapshot.stage,
                            columns,
                          ),
                          title: Text(
                            content.title,
                            style: context.playerMenuTheme.title,
                          ),
                          actions: completed
                              ? PlayerActionButton(
                                  key: const ValueKey('heal-close'),
                                  label: strings.returnToGame,
                                  labelMaxLines: 8,
                                  icon: Icons.check,
                                  autofocus: true,
                                  onPressed:
                                      snapshot.isActionEnabled(
                                        RuntimeWorldServiceAction.close,
                                      )
                                      ? () => _emit(
                                          RuntimeWorldServiceAction.close,
                                        )
                                      : null,
                                )
                              : applying
                              ? null
                              : PlayerServiceActions(
                                  children: [
                                    PlayerActionButton(
                                      key: const ValueKey('heal-confirm'),
                                      label: failed
                                          ? strings.retry
                                          : strings.healParty,
                                      labelMaxLines: 8,
                                      icon: Icons.healing,
                                      autofocus: true,
                                      onPressed: canConfirm
                                          ? () => _emit(
                                              RuntimeWorldServiceAction.confirm,
                                            )
                                          : null,
                                    ),
                                    PlayerActionButton(
                                      key: const ValueKey('heal-cancel'),
                                      label: strings.cancel,
                                      labelMaxLines: 8,
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
                                  ],
                                ),
                          children: [
                            Text(content.message),
                            if (applying) const LinearProgressIndicator(),
                            if (!completed || content.members.isNotEmpty) ...[
                              if (content.members.isEmpty)
                                Text(strings.emptyParty),
                              for (
                                var i = 0;
                                i < content.members.length;
                                i += columns
                              )
                                if (columns == 1)
                                  _HealPartyMember(member: content.members[i])
                                else
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _HealPartyMember(
                                          member: content.members[i],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: i + 1 < content.members.length
                                            ? _HealPartyMember(
                                                member: content.members[i + 1],
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                            ],
                            if (snapshot.safeMessage case final message?
                                when message.trim().isNotEmpty &&
                                    message != content.message)
                              Semantics(liveRegion: true, child: Text(message)),
                            if (confirmReason != null) Text(confirmReason),
                          ],
                        );
                      },
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
    final theme = context.playerMenuTheme;
    return PlayerMenuPanel(
      key: ValueKey('heal-member-${member.partyIndex}'),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: [
              Expanded(
                child: Text(
                  member.label,
                  style: theme.label.copyWith(fontSize: 14, height: 1.25),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strings.hp(member.currentHp, member.maxHp),
                style: theme.meta.copyWith(fontSize: 11, height: 1.25),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              Text(
                strings.status(member.hasStatus),
                style: theme.meta.copyWith(fontSize: 11, height: 1.25),
              ),
              Text(
                strings.pp(member.depletedMoveCount),
                style: theme.meta.copyWith(fontSize: 11, height: 1.25),
              ),
            ],
          ),
          const SizedBox(height: 2),
          PlayerMenuGauge(
            value: member.currentHp.toDouble(),
            maximum: member.maxHp.toDouble(),
            label: strings.hp(member.currentHp, member.maxHp),
            showLabel: false,
            tone: member.currentHp / member.maxHp <= .2
                ? PlayerMenuGaugeTone.danger
                : member.currentHp / member.maxHp <= .5
                ? PlayerMenuGaugeTone.warning
                : PlayerMenuGaugeTone.normal,
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
  Widget build(BuildContext context) => PlayerMenuThemeScope(
    role: ProjectPresentationSurfaceRole.confirmation,
    child: Builder(
      builder: (context) => ColoredBox(
        color: context.playerColors.scrim,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: PlayerMenuPanel(
                  primary: true,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.unavailable,
                        style: context.playerMenuTheme.body,
                      ),
                      const SizedBox(height: 16),
                      PlayerActionButton(
                        label: strings.close,
                        icon: Icons.close,
                        onPressed: onClose,
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
