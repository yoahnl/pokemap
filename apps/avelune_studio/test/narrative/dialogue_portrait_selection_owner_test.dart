import 'package:avelune_studio/features/narrative/application/dialogue_draft_codec.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_portrait_selection.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'dialogue_draft_codec_test.dart' show dialogueFixture;

void main() {
  test('portrait names select canonical state without rewriting the line or speaker', () {
    const line = DialogueLineDraft(
      text: 'Bon voyage !',
      speakerId: 'chief',
      portraitStateId: 'neutral',
    );
    final selection = DialoguePortraitSelection.of(_project, line)!;
    expect(selection.characterId, 'chief');
    expect(selection.states, {'neutral': 'Calme', 'happy': 'Sourire'});
    expect(selection.missing, isFalse);

    final happyId = selection.states.entries
        .singleWhere((entry) => entry.value == 'Sourire')
        .key;
    final happy = DialoguePortraitSelection.choose(line, happyId);
    expect(happy.portraitStateId, 'happy');
    expect(happy.speakerId, 'chief');
    expect(happy.text, 'Bon voyage !');

    final draft = dialogueFixture();
    const codec = DialogueDraftCodec();
    final source = codec.encode(
      draft.copyWith(
        branches: [
          draft.branches.first.copyWith(lines: [happy]),
          ...draft.branches.skip(1),
        ],
      ),
    );
    expect(source.source, contains('<<portrait chief happy>>'));
    final decoded = codec.decode(source)!;
    final restored = decoded.branches.first.lines.single;
    expect(restored.portraitStateId, 'happy');
    expect(restored.speakerId, 'chief');
    expect(restored.text, 'Bon voyage !');

    final cleared = DialoguePortraitSelection.choose(happy, '');
    expect(cleared.portraitStateId, isNull);
    expect(cleared.speakerId, 'chief');
    expect(cleared.text, 'Bon voyage !');
    expect(DialoguePortraitSelection.choose(happy, null).portraitStateId, isNull);
    final silent = codec.encode(
      draft.copyWith(
        branches: [
          draft.branches.first.copyWith(lines: [cleared]),
          ...draft.branches.skip(1),
        ],
      ),
    );
    expect(silent.source, isNot(contains('<<portrait chief')));
  });

  test('portrait choice flags a missing state and ignores speakers without portraits', () {
    final missing = DialoguePortraitSelection.of(
      _project,
      const DialogueLineDraft(
        text: 'Bon voyage !',
        speakerId: 'chief',
        portraitStateId: 'angry',
      ),
    )!;
    expect(missing.missing, isTrue);
    expect(missing.states.keys, ['neutral', 'happy']);
    expect(
      DialoguePortraitSelection.of(
        _project,
        const DialogueLineDraft(text: 'Bonjour', speakerId: 'mute'),
      ),
      isNull,
    );
    expect(
      DialoguePortraitSelection.of(
        _project,
        const DialogueLineDraft(text: 'Bonjour', speakerId: 'absent'),
      ),
      isNull,
    );
    final unnamed = DialoguePortraitSelection.of(
      _project.copyWith(
        characterStudioCatalog: const ProjectCharacterStudioCatalog(
          portraitStates: [],
        ),
      ),
      const DialogueLineDraft(text: 'Bonjour', speakerId: 'chief'),
    )!;
    expect(unnamed.states, {
      'neutral': 'Portrait sans libellé',
      'happy': 'Portrait sans libellé',
    });
    expect(unnamed.missing, isFalse);
  });
}

const _project = ProjectManifest(
  name: 'Portraits',
  maps: [],
  tilesets: [],
  characterStudioCatalog: ProjectCharacterStudioCatalog(
    portraitStates: [
      CharacterPortraitStateDefinition(id: 'neutral', displayName: 'Calme'),
      CharacterPortraitStateDefinition(id: 'happy', displayName: 'Sourire'),
    ],
  ),
  characters: [
    ProjectCharacterEntry(
      id: 'chief',
      name: 'Chef',
      tilesetId: 'sprite',
      portraits: [
        CharacterPortraitVariant(
          portraitStateId: 'neutral',
          assetId: 'neutral-image',
        ),
        CharacterPortraitVariant(
          portraitStateId: 'happy',
          assetId: 'happy-image',
        ),
      ],
    ),
    ProjectCharacterEntry(id: 'mute', name: 'Muet', tilesetId: 'sprite'),
  ],
);
