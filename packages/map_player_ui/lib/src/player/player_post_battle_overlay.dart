import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
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
    final presentation =
        _presentationFor(snapshot.messageKind, context.playerL10n);
    return ColoredBox(
      color: context.playerColors.scrim,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(PlayerSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680, maxHeight: 620),
              child: PlayerPanel(
                elevated: true,
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: '${presentation.title}, ${snapshot.message}',
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                presentation.title,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            Text(
                              context.playerL10n.postBattleProgress(
                                snapshot.messageIndex + 1,
                                snapshot.messageCount,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: PlayerSpacing.sm),
                        LinearProgressIndicator(value: snapshot.progress),
                        const SizedBox(height: PlayerSpacing.lg),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: PlayerBadge(
                            label: presentation.title,
                            icon: presentation.icon,
                            tone: presentation.tone,
                          ),
                        ),
                        const SizedBox(height: PlayerSpacing.md),
                        Text(
                          snapshot.message,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: PlayerSpacing.lg),
                        if (snapshot.choices.isEmpty)
                          PlayerActionButton(
                            key: const ValueKey<String>('post-battle-advance'),
                            label: context.playerL10n.continueGame,
                            icon: snapshot.hasFailure
                                ? Icons.warning_amber_rounded
                                : Icons.navigate_next_rounded,
                            autofocus: true,
                            onPressed: snapshot.completed
                                ? null
                                : () => onCommand(
                                      PostBattleAdvanceCommand(
                                        snapshotRevision: snapshot.revision,
                                      ),
                                    ),
                          )
                        else
                          for (final choice in snapshot.choices) ...<Widget>[
                            PlayerActionButton(
                              key: ValueKey<String>(
                                'post-battle-choice-${choice.index}',
                              ),
                              label: choice.label,
                              icon: choice.selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              autofocus: choice.selected,
                              secondary: !choice.selected,
                              onPressed: snapshot.completed
                                  ? null
                                  : () => onCommand(
                                        PostBattleSelectDecisionCommand(
                                          snapshotRevision: snapshot.revision,
                                          decisionIndex: choice.index,
                                        ),
                                      ),
                            ),
                            if (choice != snapshot.choices.last)
                              const SizedBox(height: PlayerSpacing.xs),
                          ],
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
    RuntimePostBattleMessageKind.trainerDefeated =>
      (
        title: l10n.progression,
        icon: Icons.auto_awesome_rounded,
        tone: PlayerBadgeTone.success,
      ),
    RuntimePostBattleMessageKind.defeat ||
    RuntimePostBattleMessageKind.error =>
      (
        title: l10n.battleResult,
        icon: Icons.error_outline_rounded,
        tone: PlayerBadgeTone.danger,
      ),
    RuntimePostBattleMessageKind.money ||
    RuntimePostBattleMessageKind.item ||
    RuntimePostBattleMessageKind.badge ||
    RuntimePostBattleMessageKind.fieldAbility ||
    RuntimePostBattleMessageKind.captureDestination =>
      (
        title: l10n.reward,
        icon: Icons.redeem_rounded,
        tone: PlayerBadgeTone.warning,
      ),
    RuntimePostBattleMessageKind.moveLearningPrompt ||
    RuntimePostBattleMessageKind.moveReplacementPrompt ||
    RuntimePostBattleMessageKind.evolutionPrompt =>
      (
        title: l10n.decision,
        icon: Icons.touch_app_rounded,
        tone: PlayerBadgeTone.warning,
      ),
    RuntimePostBattleMessageKind.fled ||
    RuntimePostBattleMessageKind.experience ||
    RuntimePostBattleMessageKind.moveDeclined ||
    RuntimePostBattleMessageKind.evolutionRefused ||
    RuntimePostBattleMessageKind.flag =>
      (
        title: l10n.postBattle,
        icon: Icons.info_outline_rounded,
        tone: PlayerBadgeTone.neutral,
      ),
  };
}
