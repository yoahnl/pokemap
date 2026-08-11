import 'dart:io';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../theme/pokemap_player_theme.dart';
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
  });

  final DialoguePresentationSnapshot snapshot;
  final ValueChanged<DialoguePresentationCommand> onCommand;
  final Widget Function(String speaker)? portraitBuilder;
  final Widget Function(ResolvedDialoguePortrait portrait)?
      resolvedPortraitBuilder;
  final bool showSpeakerName;

  @override
  Widget build(BuildContext context) {
    final portrait = snapshot.portrait;
    return PlayerDialogueSurface(
      data: PlayerDialogueViewData(
        revision: snapshot.revision,
        mode: switch (snapshot.mode) {
          DialoguePresentationMode.line => PlayerDialogueMode.line,
          DialoguePresentationMode.choices => PlayerDialogueMode.choices,
        },
        speaker: snapshot.speaker,
        text: snapshot.text,
        fullText: snapshot.fullText,
        isCurrentLineFullyRevealed: snapshot.isCurrentLineFullyRevealed,
        isLastContent: snapshot.isLastContent,
        choices: <PlayerDialogueChoiceViewData>[
          for (final choice in snapshot.choices)
            PlayerDialogueChoiceViewData(
              index: choice.index,
              label: choice.label,
              selected: choice.selected,
            ),
        ],
      ),
      onAction: (action) => onCommand(
        switch (action) {
          PlayerDialogueAdvanceAction() => DialogueAdvanceCommand(
              snapshotRevision: action.snapshotRevision,
            ),
          PlayerDialogueSelectChoiceAction(:final choiceIndex) =>
            DialogueSelectChoiceCommand(
              snapshotRevision: action.snapshotRevision,
              choiceIndex: choiceIndex,
            ),
        },
      ),
      portraitBuilder: portraitBuilder,
      showSpeakerName: showSpeakerName,
      resolvedPortrait: portrait == null
          ? null
          : KeyedSubtree(
              key: ValueKey<String>(portrait.assetId),
              child: resolvedPortraitBuilder?.call(portrait) ??
                  Image.file(
                    File(portrait.absoluteFilePath),
                    key: ValueKey<String>(
                      'dialogue-portrait-${portrait.assetId}',
                    ),
                    fit: switch (portrait.fitMode) {
                      CharacterPortraitFitMode.contain => BoxFit.contain,
                      CharacterPortraitFitMode.cover => BoxFit.cover,
                    },
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: context.playerColors.textSecondary,
                      ),
                    ),
                  ),
            ),
    );
  }
}
