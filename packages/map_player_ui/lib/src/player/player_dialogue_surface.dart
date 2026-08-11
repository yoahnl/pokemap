import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_surface_palette_theme.dart';
import '../theme/pokemap_player_layout_theme.dart';

enum PlayerDialogueMode { line, choices }

@immutable
final class PlayerDialogueChoiceViewData {
  const PlayerDialogueChoiceViewData({
    required this.index,
    required this.label,
    required this.selected,
  });

  final int index;
  final String label;
  final bool selected;
}

@immutable
final class PlayerDialogueViewData {
  const PlayerDialogueViewData({
    required this.revision,
    required this.mode,
    required this.speaker,
    required this.text,
    required this.fullText,
    required this.isCurrentLineFullyRevealed,
    required this.isLastContent,
    required this.choices,
  });

  final int revision;
  final PlayerDialogueMode mode;
  final String? speaker;
  final String text;
  final String fullText;
  final bool isCurrentLineFullyRevealed;
  final bool isLastContent;
  final List<PlayerDialogueChoiceViewData> choices;
}

sealed class PlayerDialogueAction {
  const PlayerDialogueAction({required this.snapshotRevision});

  final int snapshotRevision;
}

final class PlayerDialogueAdvanceAction extends PlayerDialogueAction {
  const PlayerDialogueAdvanceAction({required super.snapshotRevision});
}

final class PlayerDialogueSelectChoiceAction extends PlayerDialogueAction {
  const PlayerDialogueSelectChoiceAction({
    required super.snapshotRevision,
    required this.choiceIndex,
  });

  final int choiceIndex;
}

/// Boîte de dialogue joueur rendue en Flutter à partir du data runtime.
class PlayerDialogueSurface extends StatelessWidget {
  const PlayerDialogueSurface({
    super.key,
    required this.data,
    required this.onAction,
    this.portraitBuilder,
    this.resolvedPortrait,
    this.showSpeakerName = true,
  });

  final PlayerDialogueViewData data;
  final ValueChanged<PlayerDialogueAction> onAction;
  final Widget Function(String speaker)? portraitBuilder;
  final Widget? resolvedPortrait;
  final bool showSpeakerName;

  @override
  Widget build(BuildContext context) => PlayerSurfacePaletteScope(
        role: ProjectPresentationSurfaceRole.dialogue,
        child: Builder(builder: _build),
      );

  Widget _build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final resolved = context.playerLayoutTheme?.resolve(
            ProjectPresentationSurfaceRole.dialogue,
            constraints,
          );
          final margin =
              PlayerSpacing.sm + (resolved?.additionalSafeAreaPadding ?? 0);
          final showPortrait = resolved == null ||
              resolved.variant.visibleSecondaryElements.contains(
                ProjectPresentationSecondaryElement.dialoguePortrait,
              );
          final alignment = switch (resolved?.variant.slot) {
            ProjectPresentationLayoutSlot.topCenter => Alignment.topCenter,
            ProjectPresentationLayoutSlot.center => Alignment.center,
            _ => Alignment.bottomCenter,
          };
          return Padding(
            padding: EdgeInsets.all(margin),
            child: Align(
              key: resolved == null
                  ? null
                  : ValueKey<String>(
                      'player-dialogue-responsive-'
                      '${resolved.breakpoint.name}',
                    ),
              alignment: alignment,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: resolved == null
                      ? 760
                      : constraints.maxWidth * resolved.maxWidthFactor,
                  maxHeight: resolved == null
                      ? constraints.maxHeight * 0.58
                      : constraints.maxHeight - margin * 2,
                ),
                child: PlayerPanel(
                  elevated: true,
                  role: PlayerPanelRole.dialogue,
                  surfaceRole: ProjectPresentationSurfaceRole.dialogue,
                  padding: EdgeInsets.all(
                    PlayerSpacing.md * (resolved?.spacingScale ?? 1),
                  ),
                  child: AnimatedSwitcher(
                    duration: context.playerMotion.fast,
                    child: Semantics(
                      key: ValueKey<int>(data.revision),
                      container: true,
                      liveRegion: true,
                      label: _semanticLabel(data, showSpeakerName),
                      child: switch (data.mode) {
                        PlayerDialogueMode.line => GestureDetector(
                            key: const ValueKey<String>('dialogue-tap-zone'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onAction(
                              PlayerDialogueAdvanceAction(
                                snapshotRevision: data.revision,
                              ),
                            ),
                            child: _DialogueLineContent(
                              data: data,
                              portraitBuilder:
                                  showPortrait ? portraitBuilder : null,
                              resolvedPortrait:
                                  showPortrait ? resolvedPortrait : null,
                              showSpeakerName: showSpeakerName,
                            ),
                          ),
                        PlayerDialogueMode.choices => _DialogueChoiceContent(
                            data: data,
                            onAction: onAction,
                          ),
                      },
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
}

class _DialogueLineContent extends StatelessWidget {
  const _DialogueLineContent({
    required this.data,
    required this.portraitBuilder,
    required this.resolvedPortrait,
    required this.showSpeakerName,
  });

  final PlayerDialogueViewData data;
  final Widget Function(String speaker)? portraitBuilder;
  final Widget? resolvedPortrait;
  final bool showSpeakerName;

  @override
  Widget build(BuildContext context) {
    if (resolvedPortrait case final portrait?) {
      return _DialogueLineWithResolvedPortrait(
        data: data,
        portrait: portrait,
        showSpeakerName: showSpeakerName,
      );
    }
    final speaker = data.speaker;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (speaker != null &&
              (portraitBuilder != null || showSpeakerName)) ...<Widget>[
            Row(
              children: <Widget>[
                if (portraitBuilder != null) ...<Widget>[
                  SizedBox.square(
                    dimension: 64,
                    child: portraitBuilder!(speaker),
                  ),
                  const SizedBox(width: PlayerSpacing.sm),
                ],
                if (showSpeakerName)
                  Expanded(
                    child: Text(
                      speaker,
                      style: context.playerTypography
                          .dialogueStyle(
                            Theme.of(context).textTheme.titleLarge ??
                                const TextStyle(),
                          )
                          .copyWith(color: context.playerColors.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: PlayerSpacing.sm),
          ],
          Text(
            data.text,
            style: context.playerTypography.dialogueStyle(
              Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
            ),
          ),
          const SizedBox(height: PlayerSpacing.md),
          _DialogueAdvanceLabel(data: data),
        ],
      ),
    );
  }
}

class _DialogueLineWithResolvedPortrait extends StatelessWidget {
  const _DialogueLineWithResolvedPortrait({
    required this.data,
    required this.portrait,
    required this.showSpeakerName,
  });

  final PlayerDialogueViewData data;
  final Widget portrait;
  final bool showSpeakerName;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final portraitDimension = constraints.maxWidth < 420 ? 72.0 : 96.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: AnimatedSwitcher(
                  duration: context.playerMotion.fast,
                  child: PlayerPortraitFrame(
                    key: portrait.key,
                    dimension: portraitDimension,
                    child: portrait,
                  ),
                ),
              ),
              const SizedBox(width: PlayerSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (data.speaker case final speaker?
                        when showSpeakerName) ...<Widget>[
                      Text(
                        speaker,
                        style: context.playerTypography
                            .dialogueStyle(
                              Theme.of(context).textTheme.titleLarge ??
                                  const TextStyle(),
                            )
                            .copyWith(color: context.playerColors.primary),
                      ),
                      const SizedBox(height: PlayerSpacing.sm),
                    ],
                    Text(
                      data.text,
                      style: context.playerTypography.dialogueStyle(
                        Theme.of(context).textTheme.bodyLarge ??
                            const TextStyle(),
                      ),
                    ),
                    const SizedBox(height: PlayerSpacing.md),
                    _DialogueAdvanceLabel(data: data),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DialogueAdvanceLabel extends StatelessWidget {
  const _DialogueAdvanceLabel({required this.data});

  final PlayerDialogueViewData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Icon(
          data.isCurrentLineFullyRevealed
              ? Icons.navigate_next_rounded
              : Icons.fast_forward_rounded,
        ),
        const SizedBox(width: PlayerSpacing.xxs),
        Text(
          !data.isCurrentLineFullyRevealed
              ? context.playerL10n.showFullText
              : data.isLastContent
                  ? context.playerL10n.close
                  : context.playerL10n.next,
        ),
      ],
    );
  }
}

class _DialogueChoiceContent extends StatelessWidget {
  const _DialogueChoiceContent({
    required this.data,
    required this.onAction,
  });

  final PlayerDialogueViewData data;
  final ValueChanged<PlayerDialogueAction> onAction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.playerL10n.yourChoice,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: PlayerSpacing.sm),
          for (final choice in data.choices) ...<Widget>[
            PlayerActionButton(
              key: ValueKey<String>('dialogue-choice-${choice.index}'),
              label: choice.label,
              icon: choice.selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              autofocus: choice.selected,
              secondary: !choice.selected,
              onPressed: () => onAction(
                PlayerDialogueSelectChoiceAction(
                  snapshotRevision: data.revision,
                  choiceIndex: choice.index,
                ),
              ),
            ),
            if (choice != data.choices.last)
              const SizedBox(height: PlayerSpacing.xs),
          ],
        ],
      ),
    );
  }
}

String _semanticLabel(PlayerDialogueViewData data, bool showSpeakerName) {
  return switch (data.mode) {
    PlayerDialogueMode.line =>
      '${data.speaker == null || !showSpeakerName ? '' : '${data.speaker}, '}${data.fullText}',
    PlayerDialogueMode.choices =>
      'Choix de dialogue, ${data.choices.length} options',
  };
}
