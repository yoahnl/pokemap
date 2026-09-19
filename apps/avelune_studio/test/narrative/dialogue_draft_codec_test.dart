import 'package:avelune_studio/features/narrative/application/dialogue_draft_codec.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

DialogueDraft dialogueFixture({String text = 'Bonjour à vous !'}) =>
    DialogueDraft(
      entry: const ProjectDialogueEntry(
        id: 'station',
        name: 'Gare',
        relativePath: 'dialogues/station.yarn',
      ),
      branches: [
        DialogueBranchDraft(
          id: 'start',
          name: 'Accueil',
          lines: [DialogueLineDraft(text: text)],
          choices: const [
            DialogueChoiceDraft(
              text: 'Je vous aide',
              targetId: 'accept',
              outcomeId: 'accepted',
            ),
            DialogueChoiceDraft(text: 'Pas maintenant', targetId: 'refuse'),
          ],
        ),
        const DialogueBranchDraft(
          id: 'accept',
          name: 'Acceptation',
          lines: [DialogueLineDraft(text: 'Merci !')],
        ),
        const DialogueBranchDraft(
          id: 'refuse',
          name: 'Refus',
          lines: [DialogueLineDraft(text: 'À bientôt.')],
        ),
      ],
    );

void main() {
  const codec = DialogueDraftCodec();
  test(
    'speaker without portrait survives canonical compiler and visual reopening',
    () {
      final draft = dialogueFixture();
      final encoded = codec.encode(
        draft.copyWith(
          branches: [
            draft.branches.first.copyWith(
              lines: const [
                DialogueLineDraft(text: 'Bonjour', speakerId: 'chief'),
              ],
            ),
            ...draft.branches.skip(1),
          ],
        ),
      );
      final decoded = codec.decode(encoded)!;
      expect(decoded.branches.first.lines.single.speakerId, 'chief');
      expect(decoded.branches.first.lines.single.portraitStateId, isNull);
    },
  );
  test(
    'literal text preserves quotes accents newlines and reserved commands',
    () {
      const text =
          ' Éléonore : "oui"\n-> faux choix\n===\n<<jump refuse>>\n<<evil command>>\n  fin ';
      final encoded = codec.encode(dialogueFixture(text: text));
      final compiled = const DialogueAuthoringCompiler().compile(
        entry: encoded.entry,
        source: encoded.source,
      );
      expect(compiled.canPublish, true);
      expect(
        (compiled.document!.nodes.first.steps.first as RuntimeDialogueLine)
            .text,
        text,
      );
      const runtimeCodec = RuntimeDialogueDocumentCodec();
      expect(
        runtimeCodec.decodeUtf8(runtimeCodec.encodeUtf8(compiled.document!)),
        compiled.document,
      );
      final accepted = const DialogueSimulationService().simulate(compiled);
      final refused = const DialogueSimulationService().simulate(
        compiled,
        choices: {'start': 1},
      );
      expect(accepted.transcript, [text, 'Merci !']);
      expect(accepted.outcomes, ['accepted']);
      expect(refused.transcript, [text, 'À bientôt.']);
      expect(refused.outcomes, isEmpty);
      expect(codec.encode(codec.decode(encoded)!).source, encoded.source);
    },
  );
  test('advanced source even bearing visual tag remains read only', () {
    final encoded = codec.encode(dialogueFixture());
    final advanced = NarrativeDialogueSource(
      entry: encoded.entry,
      source: encoded.source.replaceFirst('---', '---\n<<unknown preserved>>'),
    );
    expect(codec.decode(advanced), isNull);
    expect(advanced.source, contains('<<unknown preserved>>'));
  });
  test('missing choice destination blocks publication', () {
    final draft = dialogueFixture();
    expect(
      () => codec.encode(draft.copyWith(branches: [draft.branches.first])),
      throwsA(isA<NarrativeFailure>()),
    );
  });
}
