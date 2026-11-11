import 'package:map_core/map_core_domain.dart';

import '../domain/dialogue_draft.dart';

class DialoguePortraitSelection {
  const DialoguePortraitSelection._({
    required this.characterId,
    required this.states,
    required this.missing,
  });

  final String characterId;
  final Map<String, String> states;
  final bool missing;

  static DialoguePortraitSelection? of(
    ProjectManifest project,
    DialogueLineDraft line,
  ) {
    final character = project.characters
        .where((entry) => entry.id == line.speakerId)
        .firstOrNull;
    if (character == null || character.portraits.isEmpty) return null;
    final definitions = {
      for (final state in project.characterStudioCatalog.portraitStates)
        state.id: state.displayName,
    };
    final states = {
      for (final entry in character.portraits)
        entry.portraitStateId:
            definitions[entry.portraitStateId] ?? 'Portrait sans libellé',
    };
    return DialoguePortraitSelection._(
      characterId: character.id,
      states: states,
      missing:
          line.portraitStateId != null &&
          !states.containsKey(line.portraitStateId),
    );
  }

  static DialogueLineDraft choose(DialogueLineDraft line, String? state) =>
      DialogueLineDraft(
        text: line.text,
        speakerId: line.speakerId,
        portraitStateId: state == null || state.isEmpty ? null : state,
      );

  static DialogueLineDraft chooseSpeaker(
    ProjectManifest project,
    DialogueLineDraft line,
    String? characterId,
  ) {
    final character = project.characters
        .where((entry) => entry.id == characterId)
        .firstOrNull;
    return DialogueLineDraft(
      text: line.text,
      speakerId: character?.id,
      portraitStateId: character?.portraits.firstOrNull?.portraitStateId,
    );
  }

  static DialogueLineDraft withText(DialogueLineDraft line, String text) =>
      DialogueLineDraft(
        text: text,
        speakerId: line.speakerId,
        portraitStateId: line.portraitStateId,
      );

  static bool speakerLacksPortraits(
    ProjectManifest project,
    DialogueLineDraft line,
  ) => project.characters.any(
    (entry) => entry.id == line.speakerId && entry.portraits.isEmpty,
  );
}
