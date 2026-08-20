import '../../application/dialogue_runtime_models.dart';
import '../../application/dialogue_portrait_resolver.dart';

enum DialoguePresentationMode { line, choices }

class DialoguePresentationChoice {
  const DialoguePresentationChoice({
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

/// Projection immutable d'un dialogue pour une présentation Flutter.
class DialoguePresentationSnapshot {
  const DialoguePresentationSnapshot({
    required this.revision,
    required this.mode,
    required this.nodeTitle,
    required this.speaker,
    required this.text,
    required this.fullText,
    required this.isCurrentLineFullyRevealed,
    required this.isLastContent,
    required this.choices,
    this.portrait,
  });

  final int revision;
  final DialoguePresentationMode mode;
  final String? nodeTitle;
  final String? speaker;
  final String text;
  final String fullText;
  final bool isCurrentLineFullyRevealed;
  final bool isLastContent;
  final List<DialoguePresentationChoice> choices;
  final ResolvedDialoguePortrait? portrait;
}

DialoguePresentationSnapshot buildDialoguePresentationSnapshot({
  required DialogueSession session,
  required int revision,
  required String visibleText,
  required bool isCurrentLineFullyRevealed,
  DialoguePortraitLookup? resolvePortrait,
}) {
  final state = session.state;
  return switch (state) {
    DialogueShowingLine(
      :final text,
      :final characterId,
      :final portraitStateId,
    ) =>
      () {
        final fullLine = _splitDialogueLine(text);
        final portrait = characterId == null || portraitStateId == null
            ? null
            : resolvePortrait?.call(
                characterId: characterId,
                portraitStateId: portraitStateId,
              );
        final speakerPrefix =
            fullLine.speaker == null ? null : '${fullLine.speaker}:';
        final visibleBody = speakerPrefix == null
            ? visibleText
            : visibleText.length <= speakerPrefix.length
                ? ''
                : visibleText.substring(speakerPrefix.length).trimLeft();
        return DialoguePresentationSnapshot(
          revision: revision,
          mode: DialoguePresentationMode.line,
          nodeTitle: session.currentNodeTitle,
          speaker: fullLine.speaker ?? portrait?.characterName,
          text: visibleBody,
          fullText: fullLine.text,
          isCurrentLineFullyRevealed: isCurrentLineFullyRevealed,
          isLastContent: session.isLastContent,
          choices: const <DialoguePresentationChoice>[],
          portrait: portrait,
        );
      }(),
    DialogueWaitingForChoice(
      :final choices,
      :final selectedIndex,
    ) =>
      DialoguePresentationSnapshot(
        revision: revision,
        mode: DialoguePresentationMode.choices,
        nodeTitle: session.currentNodeTitle,
        speaker: null,
        text: '',
        fullText: '',
        isCurrentLineFullyRevealed: true,
        isLastContent: false,
        choices: List<DialoguePresentationChoice>.unmodifiable(
          <DialoguePresentationChoice>[
            for (var index = 0; index < choices.length; index++)
              DialoguePresentationChoice(
                index: index,
                label: choices[index].text,
                selected: index == selectedIndex,
              ),
          ],
        ),
      ),
  };
}

/// Splits an authored "Name: text" dialogue line into speaker and body —
/// the single canonical rule shared by the world overlay and the
/// pre-session message box (BETA-CIN-074).
({String? speaker, String text}) splitDialogueSpeakerLine(String rawText) =>
    _splitDialogueLine(rawText);

({String? speaker, String text}) _splitDialogueLine(String rawText) {
  final separator = rawText.indexOf(':');
  if (separator <= 0 || separator > 40) {
    return (speaker: null, text: rawText);
  }
  final speaker = rawText.substring(0, separator).trim();
  final text = rawText.substring(separator + 1).trimLeft();
  if (speaker.isEmpty || text.isEmpty || speaker.contains('\n')) {
    return (speaker: null, text: rawText);
  }
  return (speaker: speaker, text: text);
}

sealed class DialoguePresentationCommand {
  const DialoguePresentationCommand({required this.snapshotRevision});

  final int snapshotRevision;
}

final class DialogueAdvanceCommand extends DialoguePresentationCommand {
  const DialogueAdvanceCommand({required super.snapshotRevision});
}

final class DialogueSelectChoiceCommand extends DialoguePresentationCommand {
  const DialogueSelectChoiceCommand({
    required super.snapshotRevision,
    required this.choiceIndex,
  });

  final int choiceIndex;
}

enum DialoguePresentationCommandRejection {
  staleSnapshot,
  wrongMode,
  choiceMissing,
}

class DialoguePresentationCommandValidation {
  const DialoguePresentationCommandValidation._({
    required this.accepted,
    this.rejection,
  });

  const DialoguePresentationCommandValidation.accepted()
      : this._(accepted: true);

  const DialoguePresentationCommandValidation.rejected(
    DialoguePresentationCommandRejection rejection,
  ) : this._(accepted: false, rejection: rejection);

  final bool accepted;
  final DialoguePresentationCommandRejection? rejection;
}

DialoguePresentationCommandValidation validateDialoguePresentationCommand(
  DialoguePresentationSnapshot snapshot,
  DialoguePresentationCommand command,
) {
  if (command.snapshotRevision != snapshot.revision) {
    return const DialoguePresentationCommandValidation.rejected(
      DialoguePresentationCommandRejection.staleSnapshot,
    );
  }
  return switch (command) {
    DialogueAdvanceCommand() => snapshot.mode == DialoguePresentationMode.line
        ? const DialoguePresentationCommandValidation.accepted()
        : const DialoguePresentationCommandValidation.rejected(
            DialoguePresentationCommandRejection.wrongMode,
          ),
    DialogueSelectChoiceCommand(:final choiceIndex) =>
      snapshot.mode != DialoguePresentationMode.choices
          ? const DialoguePresentationCommandValidation.rejected(
              DialoguePresentationCommandRejection.wrongMode,
            )
          : snapshot.choices.any((choice) => choice.index == choiceIndex)
              ? const DialoguePresentationCommandValidation.accepted()
              : const DialoguePresentationCommandValidation.rejected(
                  DialoguePresentationCommandRejection.choiceMissing,
                ),
  };
}
