import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_dialogue_theme.dart';
import '../theme/pokemap_player_surface_palette_theme.dart';
import '../theme/pokemap_player_layout_theme.dart';

enum PlayerDialogueMode { line, choices }

@immutable
final class PlayerDialogueChoiceViewData {
  const PlayerDialogueChoiceViewData({
    required this.index,
    required this.label,
    required this.selected,
    this.enabled = true,
  });

  final int index;
  final String label;
  final bool selected;
  final bool enabled;
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
          final dialogue = context.playerDialogueProfile;
          final resolved = context.playerLayoutTheme?.resolve(
            ProjectPresentationSurfaceRole.dialogue,
            constraints,
          );
          final margin = dialogue?.margin ??
              PlayerSpacing.sm + (resolved?.additionalSafeAreaPadding ?? 0);
          final showPortrait = resolved == null ||
              resolved.variant.visibleSecondaryElements.contains(
                ProjectPresentationSecondaryElement.dialoguePortrait,
              );
          final alignment = dialogue == null
              ? switch (resolved?.variant.slot) {
                  ProjectPresentationLayoutSlot.topCenter =>
                    Alignment.topCenter,
                  ProjectPresentationLayoutSlot.center => Alignment.center,
                  _ => Alignment.bottomCenter,
                }
              : switch (dialogue.placement) {
                  ProjectDialoguePlacement.top => Alignment.topCenter,
                  ProjectDialoguePlacement.center => Alignment.center,
                  ProjectDialoguePlacement.bottom => Alignment.bottomCenter,
                };
          return Padding(
            padding: EdgeInsets.all(margin),
            child: Align(
              key: dialogue != null
                  ? const ValueKey<String>('player-dialogue-authored-bubble')
                  : resolved == null
                      ? null
                      : ValueKey<String>(
                          'player-dialogue-responsive-'
                          '${resolved.breakpoint.name}',
                        ),
              alignment: alignment,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: resolved == null
                      ? dialogue == null
                          ? 760
                          : constraints.maxWidth * dialogue.maxWidthFactor
                      : dialogue == null
                          ? constraints.maxWidth * resolved.maxWidthFactor
                          : constraints.maxWidth * dialogue.maxWidthFactor,
                  maxHeight: resolved == null
                      ? constraints.maxHeight * 0.58
                      : constraints.maxHeight - margin * 2,
                ),
                child: PlayerPanel(
                  elevated: true,
                  role: PlayerPanelRole.dialogue,
                  surfaceRole: ProjectPresentationSurfaceRole.dialogue,
                  padding: EdgeInsets.all(
                    dialogue?.contentPadding ??
                        PlayerSpacing.md * (resolved?.spacingScale ?? 1),
                  ),
                  windowStyleOverride: dialogue == null
                      ? null
                      : ProjectWindowStyleProfile(
                          id: 'dialogue-v9',
                          shape: dialogue.shape,
                          borderWidth: dialogue.borderWidth.round(),
                          cornerRadius: dialogue.cornerRadius.round(),
                          contentPadding: dialogue.contentPadding.round(),
                          shadowElevation: 8,
                          fillOpacity: dialogue.fillOpacity,
                          fillToken: 'dialogueSurface',
                          borderToken: 'outline',
                        ),
                  surfaceColorOverride:
                      PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                    dialogue?.surfaceColor,
                  ),
                  borderColorOverride:
                      PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                    dialogue?.borderColor,
                  ),
                  textColorOverride:
                      PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                    dialogue?.textColor,
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
                              dialogue: dialogue,
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
    required this.dialogue,
    required this.portraitBuilder,
    required this.resolvedPortrait,
    required this.showSpeakerName,
  });

  final PlayerDialogueViewData data;
  final ProjectDialoguePresentationProfile? dialogue;
  final Widget Function(String speaker)? portraitBuilder;
  final Widget? resolvedPortrait;
  final bool showSpeakerName;

  @override
  Widget build(BuildContext context) {
    if (dialogue case final dialogue?) {
      final speaker = data.speaker;
      return _DialogueLineWithAuthoredPortrait(
        data: data,
        dialogue: dialogue,
        portrait: resolvedPortrait ??
            (speaker == null || portraitBuilder == null
                ? null
                : portraitBuilder!(speaker)),
        showSpeakerName: showSpeakerName,
      );
    }
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

class _DialogueLineWithAuthoredPortrait extends StatelessWidget {
  const _DialogueLineWithAuthoredPortrait({
    required this.data,
    required this.dialogue,
    required this.portrait,
    required this.showSpeakerName,
  });

  final PlayerDialogueViewData data;
  final ProjectDialoguePresentationProfile dialogue;
  final Widget? portrait;
  final bool showSpeakerName;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final portraitDimension = constraints.maxWidth < 320
              ? dialogue.portraitSize.clamp(48.0, 72.0)
              : dialogue.portraitSize;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (data.speaker case final speaker?
                  when showSpeakerName) ...<Widget>[
                _DialogueNameplate(
                  speaker: speaker,
                  dialogue: dialogue,
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
          );
          final portrait = this.portrait;
          if (portrait == null) return text;
          final framedPortrait = _DialoguePortraitFrame(
            key: portrait.key,
            dimension: portraitDimension,
            shape: dialogue.portraitShape,
            borderWidth: dialogue.portraitFrameWidth,
            borderColor: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                  dialogue.portraitFrameColor,
                ) ??
                context.playerColors.outline,
            child: portrait,
          );
          final motionDisabled = context.playerMotion.fast == Duration.zero;
          final transition = motionDisabled
              ? ProjectDialoguePortraitTransition.none
              : dialogue.portraitTransition;
          final transitionedPortrait = AnimatedSwitcher(
            key: ValueKey<String>(
              'dialogue-portrait-transition-${transition.name}',
            ),
            duration: transition == ProjectDialoguePortraitTransition.none
                ? Duration.zero
                : Duration(
                    milliseconds: dialogue.portraitTransitionMilliseconds,
                  ),
            transitionBuilder: (child, animation) => switch (transition) {
              ProjectDialoguePortraitTransition.none => child,
              ProjectDialoguePortraitTransition.fade =>
                FadeTransition(opacity: animation, child: child),
              ProjectDialoguePortraitTransition.scale => ScaleTransition(
                  scale: Tween<double>(begin: .9, end: 1).animate(animation),
                  child: child,
                ),
              ProjectDialoguePortraitTransition.slide => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(.08, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
            },
            child: framedPortrait,
          );
          final semanticPortrait = data.speaker == null || showSpeakerName
              ? ExcludeSemantics(child: transitionedPortrait)
              : Semantics(
                  image: true,
                  label: 'Portrait de ${data.speaker}',
                  child: transitionedPortrait,
                );
          final portraitKey = ValueKey<String>(
            'dialogue-portrait-${dialogue.portraitSide.name}',
          );
          if (constraints.maxWidth < 360 ||
              MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
            return Column(
              key: portraitKey,
              crossAxisAlignment:
                  dialogue.portraitSide == ProjectDialoguePortraitSide.start
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                semanticPortrait,
                const SizedBox(height: PlayerSpacing.sm),
                SizedBox(width: double.infinity, child: text),
              ],
            );
          }
          return Row(
            key: portraitKey,
            textDirection:
                dialogue.portraitSide == ProjectDialoguePortraitSide.start
                    ? Directionality.of(context)
                    : _opposite(Directionality.of(context)),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              semanticPortrait,
              const SizedBox(width: PlayerSpacing.md),
              Expanded(child: text),
            ],
          );
        },
      ),
    );
  }
}

class _DialoguePortraitFrame extends StatelessWidget {
  const _DialoguePortraitFrame({
    super.key,
    required this.dimension,
    required this.shape,
    required this.borderWidth,
    required this.borderColor,
    required this.child,
  });

  final double dimension;
  final ProjectDialoguePortraitShape shape;
  final double borderWidth;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(color: borderColor, width: borderWidth);
    final frameShape = switch (shape) {
      ProjectDialoguePortraitShape.circle => CircleBorder(side: side),
      ProjectDialoguePortraitShape.rounded => RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: side,
        ),
      ProjectDialoguePortraitShape.square => RoundedRectangleBorder(side: side),
      ProjectDialoguePortraitShape.cutCorner => BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: side,
        ),
    };
    return Material(
      key: ValueKey<String>('dialogue-portrait-shape-${shape.name}'),
      color: context.playerColors.surface,
      shape: frameShape,
      clipBehavior: Clip.antiAlias,
      child: SizedBox.square(dimension: dimension, child: child),
    );
  }
}

class _DialogueNameplate extends StatelessWidget {
  const _DialogueNameplate({
    required this.speaker,
    required this.dialogue,
  });

  final String speaker;
  final ProjectDialoguePresentationProfile dialogue;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      speaker,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: context.playerTypography
          .dialogueStyle(
            Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
          )
          .copyWith(
            color: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                  dialogue.nameplateTextColor,
                ) ??
                context.playerColors.primary,
          ),
    );
    if (dialogue.nameplateStyle == ProjectDialogueNameplateStyle.inline) {
      return KeyedSubtree(
        key: const ValueKey<String>('dialogue-nameplate-inline'),
        child: text,
      );
    }
    final badge = Material(
      key: ValueKey<String>(
        'dialogue-nameplate-${dialogue.nameplateStyle.name}',
      ),
      color: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
            dialogue.nameplateSurfaceColor,
          ) ??
          context.playerColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                dialogue.nameplateBorderColor,
              ) ??
              context.playerColors.outline,
          width: dialogue.nameplateBorderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: text,
      ),
    );
    return dialogue.nameplateStyle == ProjectDialogueNameplateStyle.floating
        ? Transform.translate(offset: const Offset(0, -6), child: badge)
        : badge;
  }
}

TextDirection _opposite(TextDirection direction) =>
    direction == TextDirection.ltr ? TextDirection.rtl : TextDirection.ltr;

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
    final dialogue = context.playerDialogueProfile;
    final kind = data.isCurrentLineFullyRevealed
        ? dialogue?.progressIndicator ??
            ProjectDialogueProgressIndicator.chevron
        : ProjectDialogueProgressIndicator.arrow;
    final color = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
      dialogue?.progressIndicatorColor,
    );
    final icon = switch (kind) {
      ProjectDialogueProgressIndicator.chevron => Icons.navigate_next_rounded,
      ProjectDialogueProgressIndicator.arrow => Icons.arrow_forward_rounded,
      ProjectDialogueProgressIndicator.dots => Icons.more_horiz_rounded,
      ProjectDialogueProgressIndicator.none => null,
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(
            icon,
            key: ValueKey<String>('dialogue-progress-indicator-${kind.name}'),
            color: color,
          ),
          const SizedBox(width: PlayerSpacing.xxs),
        ] else
          const SizedBox.shrink(
            key: ValueKey<String>('dialogue-progress-indicator-none'),
          ),
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
    final dialogue = context.playerDialogueProfile;
    final spacing = dialogue?.choiceSpacing ?? PlayerSpacing.xs;
    final selectedColor = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
      dialogue?.choiceSelectedColor,
    );
    final selectedForeground = selectedColor == null
        ? null
        : ThemeData.estimateBrightnessForColor(selectedColor) == Brightness.dark
            ? context.playerColors.onPrimary
            : context.playerColors.textPrimary;
    final shape = switch (dialogue?.choiceShape) {
      ProjectDialogueChoiceShape.pill => const StadiumBorder(),
      ProjectDialogueChoiceShape.rectangle => const RoundedRectangleBorder(),
      ProjectDialogueChoiceShape.cutCorner => const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      _ => const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
    };
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
              selected: choice.selected,
              secondary: !choice.selected,
              shape: shape,
              backgroundColor: choice.selected ? selectedColor : null,
              foregroundColor: choice.selected ? selectedForeground : null,
              disabledOpacity: dialogue?.choiceDisabledOpacity ?? 1,
              onPressed: choice.enabled
                  ? () => onAction(
                        PlayerDialogueSelectChoiceAction(
                          snapshotRevision: data.revision,
                          choiceIndex: choice.index,
                        ),
                      )
                  : null,
            ),
            if (choice != data.choices.last)
              SizedBox(
                key:
                    ValueKey<String>('dialogue-choice-spacing-${choice.index}'),
                height: spacing,
              ),
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
