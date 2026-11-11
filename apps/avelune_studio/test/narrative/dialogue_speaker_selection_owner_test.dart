import 'package:avelune_studio/features/narrative/application/dialogue_portrait_selection.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  const line = DialogueLineDraft(
    text: 'Bon voyage !',
    speakerId: 'mute',
    portraitStateId: 'stale',
  );

  test('choosing a speaker takes its first prepared portrait and keeps the text', () {
    final chosen = DialoguePortraitSelection.chooseSpeaker(_project, line, 'chief');
    expect(chosen.speakerId, 'chief');
    expect(chosen.portraitStateId, 'neutral');
    expect(chosen.text, 'Bon voyage !');
  });

  test('choosing a speaker without portrait drops the previous portrait state', () {
    final chosen = DialoguePortraitSelection.chooseSpeaker(_project, line, 'mute');
    expect(chosen.speakerId, 'mute');
    expect(chosen.portraitStateId, isNull);
    expect(chosen.text, 'Bon voyage !');
  });

  test('choosing the empty option or an unknown character clears speaker and portrait', () {
    for (final id in ['', 'absent', null]) {
      final chosen = DialoguePortraitSelection.chooseSpeaker(_project, line, id);
      expect(chosen.speakerId, isNull, reason: '$id');
      expect(chosen.portraitStateId, isNull, reason: '$id');
      expect(chosen.text, 'Bon voyage !');
    }
  });

  test('editing the text keeps speaker and portrait', () {
    final edited = DialoguePortraitSelection.withText(
      const DialogueLineDraft(
        text: 'Avant',
        speakerId: 'chief',
        portraitStateId: 'happy',
      ),
      'Après',
    );
    expect(edited.text, 'Après');
    expect(edited.speakerId, 'chief');
    expect(edited.portraitStateId, 'happy');
  });

  test('only a known speaker without prepared portrait triggers the notice', () {
    DialogueLineDraft speaker(String? id) =>
        DialogueLineDraft(text: '', speakerId: id);
    expect(DialoguePortraitSelection.speakerLacksPortraits(_project, speaker('mute')), isTrue);
    expect(DialoguePortraitSelection.speakerLacksPortraits(_project, speaker('chief')), isFalse);
    expect(DialoguePortraitSelection.speakerLacksPortraits(_project, speaker('absent')), isFalse);
    expect(DialoguePortraitSelection.speakerLacksPortraits(_project, speaker(null)), isFalse);
  });
}

const _project = ProjectManifest(
  name: 'Portraits',
  maps: [],
  tilesets: [],
  characters: [
    ProjectCharacterEntry(
      id: 'chief',
      name: 'Chef',
      tilesetId: 'sprite',
      portraits: [
        CharacterPortraitVariant(portraitStateId: 'neutral', assetId: 'neutral-image'),
        CharacterPortraitVariant(portraitStateId: 'happy', assetId: 'happy-image'),
      ],
    ),
    ProjectCharacterEntry(id: 'mute', name: 'Muet', tilesetId: 'sprite'),
  ],
);
