import 'package:avelune_studio/features/events/application/behaviour/behaviour_line.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';

import 'behaviour_line_fixtures.dart';

void main() {
  test('detaching a localized line renews text ids and keeps its variants', () {
    final draft = createdDraft(['Bonjour']);
    final opened = readLocalizedDialogue(
      source: draft.dialogue.source,
      sourceLocale: 'fr',
    );
    final original = NarrativeDialogueSource(
      entry: draft.dialogue.entry.copyWith(
        localization: opened.localization.translate(
          opened.localization.units.single.id,
          'en',
          'Hello',
        ),
      ),
      source: draft.dialogue.source,
    );
    final ids = lineIdGenerator(['01a16b62-614a-7000-8000-000000000001'])
        .generate();
    final detached = detachBehaviourLine(
      line: readLine(draft.scene, original) as BehaviourLine,
      scene: draft.scene,
      ids: ids,
    );
    final copy = detached.line.dialogue;
    expect(copy.entry.id, ids.dialogueId);
    expect(copy.entry.relativePath, ids.dialoguePath);
    expect(behaviourLineDialogueId(detached.scene), ids.dialogueId);
    expect(behaviourLineDialogueId(draft.scene), original.entry.id);
    expect(
      copy.entry.localization!.units.single.id,
      isNot(original.entry.localization!.units.single.id),
    );
    expect(
      copy.entry.localization!.units.single.translations,
      original.entry.localization!.units.single.translations,
    );
    expect(copy.source, original.source);
    readLocalizedDialogue(
      source: copy.source,
      sourceLocale: 'fr',
      localization: copy.entry.localization,
    );
  });
}
