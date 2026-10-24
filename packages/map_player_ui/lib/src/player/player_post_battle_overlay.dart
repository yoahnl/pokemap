import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_paged_layout.dart';
import '../theme/pokemap_player_battle_theme.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';

class PlayerPostBattleOverlay extends StatelessWidget {
  const PlayerPostBattleOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
  });

  final PostBattlePresentationSnapshot snapshot;
  final ValueChanged<PostBattlePresentationCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    final kind = snapshot.choices.isEmpty && snapshot.summaryMessages.isNotEmpty
        ? snapshot.summaryMessages.first.kind
        : snapshot.messageKind;
    final presentation = _presentationFor(kind, context.playerL10n);
    final chrome = context.playerBattleChrome;
    return ColoredBox(
      color: context.playerColors.scrim.withValues(alpha: .18),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final summary = snapshot.summaryMessages;
            final hasDecision = snapshot.choices.isNotEmpty;
            final height = landscape
                ? constraints.maxHeight - 32
                : constraints.maxHeight * .62;
            Widget action(PostBattlePresentationChoice choice) =>
                PlayerActionButton(
                  key: ValueKey<String>('post-battle-choice-${choice.index}'),
                  label: choice.label,
                  icon: choice.selected
                      ? Icons.check_rounded
                      : Icons.chevron_right_rounded,
                  autofocus: choice.selected,
                  secondary: !choice.selected,
                  minimumHeight: 48,
                  onPressed: snapshot.completed
                      ? null
                      : () => onCommand(
                          PostBattleSelectDecisionCommand(
                            snapshotRevision: snapshot.revision,
                            decisionIndex: choice.index,
                          ),
                        ),
                );
            return Align(
              alignment: landscape
                  ? Alignment.centerRight
                  : Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: landscape ? 16 : 0,
                  vertical: landscape ? 16 : 0,
                ),
                child: SizedBox(
                  width: landscape ? 420 : constraints.maxWidth,
                  height: height.clamp(0.0, 620.0),
                  child: PlayerPanel(
                    surfaceRole: switch (kind) {
                      RuntimePostBattleMessageKind.captured ||
                      RuntimePostBattleMessageKind.captureDestination =>
                        ProjectPresentationSurfaceRole.captureResult,
                      _ => ProjectPresentationSurfaceRole.battleResult,
                    },
                    windowStyleOverride: const ProjectWindowStyleProfile(
                      id: 'battle-result',
                      fillToken: 'battleHudSurface',
                      borderToken: 'outline',
                      borderWidth: 0,
                      cornerRadius: 3,
                      contentPadding: 16,
                      shadowElevation: 0,
                      shape: ProjectWindowShape.rounded,
                    ),
                    surfaceColorOverride: chrome.dockSurface,
                    textColorOverride: chrome.dockText,
                    child: Semantics(
                      container: true,
                      liveRegion: true,
                      label: '${presentation.title}, ${snapshot.message}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                presentation.icon,
                                color: chrome.focus,
                                size: 24,
                              ),
                              const SizedBox(width: PlayerSpacing.sm),
                              Expanded(
                                child: Text(
                                  presentation.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: chrome.dockText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              if (summary.isEmpty)
                                Text(
                                  context.playerL10n.postBattleProgress(
                                    snapshot.messageIndex + 1,
                                    snapshot.messageCount,
                                  ),
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(color: chrome.textSecondary),
                                ),
                            ],
                          ),
                          const SizedBox(height: PlayerSpacing.sm),
                          Expanded(
                            child: summary.isEmpty
                                ? Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      snapshot.message,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: chrome.dockText),
                                    ),
                                  )
                                : PlayerPagedList(
                                    spacing: 8,
                                    children: [
                                      if (hasDecision)
                                        Padding(
                                          key: const ValueKey(
                                            'post-battle-decision-prompt',
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            snapshot.message,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: chrome.dockText,
                                                ),
                                          ),
                                        ),
                                      for (
                                        var index = 0;
                                        index < summary.length;
                                        index++
                                      )
                                        Padding(
                                          key: ValueKey(
                                            'post-battle-fact-$index',
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                _presentationFor(
                                                  summary[index].kind,
                                                  context.playerL10n,
                                                ).icon,
                                                size: 20,
                                                color: chrome.focus,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  summary[index].text,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: chrome.dockText,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: PlayerSpacing.md),
                          if (!hasDecision)
                            PlayerActionButton(
                              key: const ValueKey<String>(
                                'post-battle-advance',
                              ),
                              label: context.playerL10n.continueGame,
                              icon: snapshot.hasFailure
                                  ? Icons.warning_amber_rounded
                                  : Icons.navigate_next_rounded,
                              autofocus: true,
                              minimumHeight: 48,
                              onPressed: snapshot.completed
                                  ? null
                                  : () => onCommand(
                                      PostBattleAdvanceCommand(
                                        snapshotRevision: snapshot.revision,
                                      ),
                                    ),
                            )
                          else if (snapshot.choices.length <= 2)
                            Row(
                              children: [
                                for (
                                  var index = 0;
                                  index < snapshot.choices.length;
                                  index++
                                ) ...[
                                  if (index > 0)
                                    const SizedBox(width: PlayerSpacing.xs),
                                  Expanded(
                                    child: action(snapshot.choices[index]),
                                  ),
                                ],
                              ],
                            )
                          else
                            Column(
                              children: [
                                for (
                                  var row = 0;
                                  row < (snapshot.choices.length / 2).ceil();
                                  row++
                                ) ...[
                                  if (row > 0)
                                    const SizedBox(height: PlayerSpacing.xs),
                                  Row(
                                    children: [
                                      for (
                                        var column = 0;
                                        column < 2;
                                        column++
                                      ) ...[
                                        if (column > 0)
                                          const SizedBox(
                                            width: PlayerSpacing.xs,
                                          ),
                                        Expanded(
                                          child:
                                              row * 2 + column <
                                                  snapshot.choices.length
                                              ? action(
                                                  snapshot.choices[row * 2 +
                                                      column],
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
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
      ),
    );
  }
}

({String title, IconData icon, PlayerBadgeTone tone}) _presentationFor(
  RuntimePostBattleMessageKind kind,
  PokeMapPlayerLocalizations l10n,
) {
  return switch (kind) {
    RuntimePostBattleMessageKind.victory ||
    RuntimePostBattleMessageKind.captured ||
    RuntimePostBattleMessageKind.levelUp ||
    RuntimePostBattleMessageKind.moveAutomaticallyLearned ||
    RuntimePostBattleMessageKind.moveLearned ||
    RuntimePostBattleMessageKind.moveReplaced ||
    RuntimePostBattleMessageKind.evolutionAccepted ||
    RuntimePostBattleMessageKind.trainerDefeated => (
      title: l10n.progression,
      icon: Icons.auto_awesome_rounded,
      tone: PlayerBadgeTone.success,
    ),
    RuntimePostBattleMessageKind.defeat ||
    RuntimePostBattleMessageKind.error => (
      title: l10n.battleResult,
      icon: Icons.error_outline_rounded,
      tone: PlayerBadgeTone.danger,
    ),
    RuntimePostBattleMessageKind.money ||
    RuntimePostBattleMessageKind.item ||
    RuntimePostBattleMessageKind.badge ||
    RuntimePostBattleMessageKind.fieldAbility ||
    RuntimePostBattleMessageKind.captureDestination => (
      title: l10n.reward,
      icon: Icons.redeem_rounded,
      tone: PlayerBadgeTone.warning,
    ),
    RuntimePostBattleMessageKind.moveLearningPrompt ||
    RuntimePostBattleMessageKind.moveReplacementPrompt ||
    RuntimePostBattleMessageKind.evolutionPrompt => (
      title: l10n.decision,
      icon: Icons.touch_app_rounded,
      tone: PlayerBadgeTone.warning,
    ),
    RuntimePostBattleMessageKind.fled ||
    RuntimePostBattleMessageKind.experience ||
    RuntimePostBattleMessageKind.moveDeclined ||
    RuntimePostBattleMessageKind.evolutionRefused ||
    RuntimePostBattleMessageKind.flag => (
      title: l10n.postBattle,
      icon: Icons.info_outline_rounded,
      tone: PlayerBadgeTone.neutral,
    ),
  };
}
