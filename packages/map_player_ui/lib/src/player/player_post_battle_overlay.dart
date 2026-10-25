import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_paged_layout.dart';
import '../foundation/player_input_scope.dart';
import '../theme/pokemap_player_menu_theme.dart';
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
    final kind = snapshot.hasFailure
        ? RuntimePostBattleMessageKind.error
        : snapshot.choices.isEmpty && snapshot.summaryMessages.isNotEmpty
        ? snapshot.summaryMessages.first.kind
        : snapshot.messageKind;
    return PlayerMenuThemeScope(
      role: switch (kind) {
        RuntimePostBattleMessageKind.captured ||
        RuntimePostBattleMessageKind.captureDestination =>
          ProjectPresentationSurfaceRole.captureResult,
        _ => ProjectPresentationSurfaceRole.battleResult,
      },
      child: Builder(builder: (context) => _buildContent(context, kind)),
    );
  }

  Widget _buildContent(
    BuildContext context,
    RuntimePostBattleMessageKind kind,
  ) {
    final presentation = _presentationFor(kind, context.playerL10n);
    final theme = context.playerMenuTheme;
    final viewport = MediaQuery.sizeOf(context);
    final expandedLearningPrompt =
        kind == RuntimePostBattleMessageKind.moveLearningPrompt &&
        viewport.width > viewport.height &&
        !PlayerCompanionScope.of(context);
    return ColoredBox(
      color: context.playerColors.scrim.withValues(alpha: .18),
      child: SafeArea(
        minimum: expandedLearningPrompt
            ? const EdgeInsets.all(20)
            : EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final summary = snapshot.summaryMessages;
            final hasDecision = snapshot.choices.isNotEmpty;
            final companion = PlayerCompanionScope.of(context);
            final grouped = summary.isNotEmpty;
            final expandedDecision = snapshot.choices.length > 2;
            final height = companion
                ? constraints.maxHeight
                : expandedLearningPrompt
                ? constraints.maxHeight
                : landscape
                ? constraints.maxHeight -
                      (grouped || expandedDecision ? 40 : 100)
                : grouped
                ? 460.0
                : snapshot.choices.length > 2
                ? 480.0
                : 380.0;
            Widget action(PostBattlePresentationChoice choice) =>
                _PostBattleAction(
                  key: ValueKey<String>('post-battle-choice-${choice.index}'),
                  label: choice.label,
                  selected: choice.selected,
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
              alignment: companion
                  ? Alignment.center
                  : landscape
                  ? Alignment.bottomRight
                  : Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: companion || expandedLearningPrompt
                      ? 0
                      : landscape
                      ? (grouped ? 20 : 44)
                      : 0,
                  vertical: companion || expandedLearningPrompt
                      ? 0
                      : landscape
                      ? 20
                      : 0,
                ),
                child: SizedBox(
                  width: companion
                      ? constraints.maxWidth
                      : landscape
                      ? (grouped || expandedLearningPrompt ? 400 : 332)
                      : constraints.maxWidth,
                  height: height.clamp(0.0, constraints.maxHeight),
                  child: DecoratedBox(
                    key: const ValueKey('post-battle-result-panel'),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: theme.accent, width: 6),
                      ),
                    ),
                    position: DecorationPosition.foreground,
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
                        cornerRadius: 0,
                        contentPadding: 18,
                        shadowElevation: 0,
                        shape: ProjectWindowShape.rectangle,
                      ),
                      surfaceColorOverride: theme.base,
                      textColorOverride: theme.text,
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
                                  color: theme.accent,
                                  size: 24,
                                ),
                                const SizedBox(width: PlayerSpacing.sm),
                                Expanded(
                                  child: Text(
                                    presentation.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: theme.text,
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: theme.secondary),
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
                                            ?.copyWith(color: theme.text),
                                      ),
                                    )
                                  : PlayerPagedList(
                                      spacing: 8,
                                      children: [
                                        if (hasDecision || snapshot.hasFailure)
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
                                                  ?.copyWith(color: theme.text),
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
                                                  color: theme.accent,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    summary[index].text,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color: theme.text,
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
                              _PostBattleAction(
                                key: const ValueKey<String>(
                                  'post-battle-advance',
                                ),
                                selected: true,
                                label: context.playerL10n.continueGame,
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
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PostBattleAction extends StatelessWidget {
  const _PostBattleAction({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    final background = selected ? theme.selectionTop : theme.panel;
    final foreground = selected ? theme.selectionText : theme.text;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: background,
        shape: _PostBattleBevel(selected ? theme.accent : null),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          autofocus: selected,
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: theme.actionLabel.copyWith(
                  color: onPressed == null ? theme.disabled : foreground,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostBattleBevel extends ShapeBorder {
  const _PostBattleBevel(this.accent);

  final Color? accent;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..moveTo(rect.left + 12, rect.top)
    ..lineTo(rect.right, rect.top)
    ..lineTo(rect.right - 12, rect.bottom)
    ..lineTo(rect.left, rect.bottom)
    ..close();

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  ShapeBorder scale(double t) => this;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (accent == null) return;
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - 6, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right - 12, rect.bottom)
        ..lineTo(rect.right - 18, rect.bottom)
        ..close(),
      Paint()..color = accent!,
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
