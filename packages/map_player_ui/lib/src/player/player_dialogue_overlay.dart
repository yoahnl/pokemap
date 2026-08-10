import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import 'player_dialogue_surface.dart';

export 'player_dialogue_surface.dart';

class PlayerDialogueOverlay extends StatelessWidget {
  const PlayerDialogueOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
    this.portraitBuilder,
  });

  final DialoguePresentationSnapshot snapshot;
  final ValueChanged<DialoguePresentationCommand> onCommand;
  final Widget Function(String speaker)? portraitBuilder;

  @override
  Widget build(BuildContext context) => PlayerDialogueSurface(
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
      );
}
