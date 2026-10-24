import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../theme/pokemap_player_theme.dart';
import '../foundation/player_image.dart';
import 'player_dialogue_surface.dart';

export 'player_dialogue_surface.dart';

class PlayerDialogueOverlay extends StatelessWidget {
  const PlayerDialogueOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
    this.portraitBuilder,
    this.resolvedPortraitBuilder,
    this.showSpeakerName = true,
    this.paginationController,
  });

  final DialoguePresentationSnapshot snapshot;
  final ValueChanged<DialoguePresentationCommand> onCommand;
  final Widget Function(String speaker)? portraitBuilder;
  final Widget Function(ResolvedDialoguePortrait portrait)?
  resolvedPortraitBuilder;
  final bool showSpeakerName;
  final PlayerDialoguePaginationController? paginationController;

  @override
  Widget build(BuildContext context) {
    final portrait = snapshot.portrait;
    return PlayerDialogueSurface(
      paginationController: paginationController,
      data: PlayerDialogueViewData(
        revision: snapshot.revision,
        mode: switch (snapshot.mode) {
          DialoguePresentationMode.line => PlayerDialogueMode.line,
          DialoguePresentationMode.choices => PlayerDialogueMode.choices,
        },
        speaker: snapshot.speaker,
        text: snapshot.text,
        lineSpan: _lineSpan(),
        fullText: snapshot.fullText,
        isCurrentLineFullyRevealed: snapshot.isCurrentLineFullyRevealed,
        isLastContent: snapshot.isLastContent,
        isAdvanceAvailable: snapshot.isAdvanceAvailable,
        choices: <PlayerDialogueChoiceViewData>[
          for (final choice in snapshot.choices)
            PlayerDialogueChoiceViewData(
              index: choice.index,
              label: choice.label,
              selected: choice.selected,
              enabled: choice.enabled,
            ),
        ],
      ),
      onAction: (action) => onCommand(switch (action) {
        PlayerDialogueAdvanceAction() => DialogueAdvanceCommand(
          snapshotRevision: action.snapshotRevision,
        ),
        PlayerDialogueSelectChoiceAction(:final choiceIndex) =>
          DialogueSelectChoiceCommand(
            snapshotRevision: action.snapshotRevision,
            choiceIndex: choiceIndex,
          ),
      }),
      portraitBuilder: portraitBuilder,
      showSpeakerName: showSpeakerName,
      resolvedPortrait: portrait == null
          ? null
          : KeyedSubtree(
              key: ValueKey<String>(portrait.assetId),
              child:
                  resolvedPortraitBuilder?.call(portrait) ??
                  PlayerFileImage(
                    path: portrait.absoluteFilePath,
                    key: ValueKey<String>(
                      'dialogue-portrait-${portrait.assetId}',
                    ),
                    fit: switch (portrait.fitMode) {
                      CharacterPortraitFitMode.contain => BoxFit.contain,
                      CharacterPortraitFitMode.cover => BoxFit.cover,
                    },
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stack) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: context.playerColors.textSecondary,
                      ),
                    ),
                  ),
            ),
    );
  }

  InlineSpan? _lineSpan() {
    if (snapshot.segments.isEmpty) return null;
    return TextSpan(
      children: [
        for (final segment in snapshot.segments)
          switch (segment) {
            DialogueTextSegment(:final text, :final style) => TextSpan(
              text: text,
              style: TextStyle(
                color: style?.colorArgb == null
                    ? null
                    : Color(style!.colorArgb!),
                shadows: style?.shadowColorArgb == null
                    ? null
                    : [
                        Shadow(
                          color: Color(style!.shadowColorArgb!),
                          offset: const Offset(1, 1),
                        ),
                      ],
              ),
            ),
            DialogueIconSegment(
              :final assetId,
              :final widthPx,
              :final heightPx,
            ) =>
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: RawImage(
                  image:
                      snapshot.iconImages[assetId] ??
                      (throw StateError(
                        'Missing decoded dialogue icon: $assetId.',
                      )),
                  key: ValueKey<String>('dialogue-inline-icon-$assetId'),
                  width: widthPx.toDouble(),
                  height: heightPx.toDouble(),
                  filterQuality: FilterQuality.none,
                  fit: BoxFit.fill,
                ),
              ),
          },
      ],
    );
  }
}
