import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/dialogue_portrait_resolver.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/dialogue_variable_interpolation.dart';
import 'package:map_runtime/src/presentation/flutter/dialogue_presentation_snapshot.dart';

void main() {
  test(
    'choices retain their immediate resolved question and canonical speaker',
    () {
      final initial = DialogueSession.start([
        YarnNode(
          title: 'Start',
          steps: [
            YarnStepLine('Léa: Prêt, {{ player }} ?'),
            YarnStepChoiceBlock([
              YarnChoice(
                text: 'Oui',
                outcomeId: 'accept',
                steps: [YarnStepLine('Départ')],
              ),
              YarnChoice(
                text: 'Non',
                outcomeId: 'refuse',
                steps: [YarnStepLine('Attends')],
              ),
            ]),
          ],
        ),
      ], 'Start')!;
      final localized = interpolateDialogueVariables(
        initial,
        const ScriptVariables(
          values: {'player': ScriptVariableValue.string('Zoé')},
        ),
      );
      expect(localized.choicePrompt, isNull);
      final choice = localized.advance()!;
      final before = choice.state as DialogueWaitingForChoice;
      final snapshot = buildDialoguePresentationSnapshot(
        session: choice,
        revision: 9,
        visibleText: '',
        isCurrentLineFullyRevealed: true,
      );
      expect(choice.choicePrompt?.text, 'Léa: Prêt, Zoé ?');
      expect(snapshot.speaker, 'Léa');
      expect(snapshot.text, 'Prêt, Zoé ?');
      expect(snapshot.fullText, 'Prêt, Zoé ?');
      expect(snapshot.choices.map((e) => e.label), ['Oui', 'Non']);
      expect(identical(choice.state, before), isTrue);
      expect(choice.confirmChoice()?.selectedOutcomeId, 'accept');
      expect(
        validateDialoguePresentationCommand(
          snapshot,
          const DialogueSelectChoiceCommand(
            snapshotRevision: 8,
            choiceIndex: 0,
          ),
        ).accepted,
        isFalse,
      );
    },
  );

  test(
    'choice question keeps structured feedback and authored portrait identity',
    () {
      const text = 'Heure: encore un départ ?';
      final session = DialogueSession.start([
        YarnNode(
          title: 'Start',
          steps: [
            YarnStepLine(
              text,
              characterId: 'lea',
              portraitStateId: 'happy',
              feedback: DialogueLineFeedback(
                segments: [DialogueTextSegment(text)],
              ),
            ),
            YarnStepChoiceBlock([YarnChoice(text: 'Oui', steps: [])]),
          ],
        ),
      ], 'Start')!.advance()!;
      const portrait = ResolvedDialoguePortrait(
        characterId: 'lea',
        characterName: 'Léa',
        portraitStateId: 'happy',
        portraitStateName: 'Souriante',
        assetId: 'lea.happy',
        absoluteFilePath: '/project/lea.png',
        fitMode: CharacterPortraitFitMode.contain,
      );
      final snapshot = buildDialoguePresentationSnapshot(
        session: session,
        revision: 3,
        visibleText: '',
        isCurrentLineFullyRevealed: true,
        resolvePortrait: ({required characterId, required portraitStateId}) {
          expect(characterId, 'lea');
          expect(portraitStateId, 'happy');
          return portrait;
        },
      );
      expect(snapshot.speaker, 'Léa');
      expect(snapshot.fullText, text);
      expect(snapshot.segments.single, isA<DialogueTextSegment>());
      expect((snapshot.segments.single as DialogueTextSegment).text, text);
      expect(snapshot.portrait, same(portrait));
    },
  );

  test(
    'choices never borrow a question from another node or a prior block',
    () {
      final startsAtChoice = DialogueSession.start([
        YarnNode(
          title: 'Start',
          steps: [
            YarnStepChoiceBlock([YarnChoice(text: 'Oui', steps: [])]),
          ],
        ),
      ], 'Start')!;
      final afterJump = DialogueSession.start([
        YarnNode(
          title: 'Start',
          steps: [
            YarnStepLine('Léa: Ancienne question'),
            YarnStepJump('Other'),
          ],
        ),
        YarnNode(
          title: 'Other',
          steps: [
            YarnStepChoiceBlock([YarnChoice(text: 'Oui', steps: [])]),
          ],
        ),
      ], 'Start')!.advance()!;
      final nested = DialogueSession.start([
        YarnNode(
          title: 'Start',
          steps: [
            YarnStepLine('Léa: Ancienne question'),
            YarnStepChoiceBlock([
              YarnChoice(
                text: 'Entrer',
                steps: [
                  YarnStepChoiceBlock([YarnChoice(text: 'Oui', steps: [])]),
                ],
              ),
            ]),
          ],
        ),
      ], 'Start')!.advance()!.confirmChoice()!;
      for (final session in [startsAtChoice, afterJump, nested]) {
        expect(session.choicePrompt, isNull);
        final snapshot = buildDialoguePresentationSnapshot(
          session: session,
          revision: 1,
          visibleText: '',
          isCurrentLineFullyRevealed: true,
        );
        expect(snapshot.speaker, isNull);
        expect(snapshot.fullText, isEmpty);
        expect(snapshot.portrait, isNull);
      }
    },
  );

  test('projects speaker, visible line and continuation state', () {
    final session = DialogueSession.start(<YarnNode>[
      YarnNode(
        title: 'intro',
        steps: <YarnStep>[
          YarnStepLine('Lysa: Bienvenue à Bourg-Palette !'),
          YarnStepLine('La route est ouverte.'),
        ],
      ),
    ], 'intro')!;

    final snapshot = buildDialoguePresentationSnapshot(
      session: session,
      revision: 3,
      visibleText: 'Lysa: Bienvenue',
      isCurrentLineFullyRevealed: false,
    );

    expect(snapshot.mode, DialoguePresentationMode.line);
    expect(snapshot.speaker, 'Lysa');
    expect(snapshot.text, 'Bienvenue');
    expect(snapshot.fullText, 'Bienvenue à Bourg-Palette !');
    expect(snapshot.isCurrentLineFullyRevealed, isFalse);
    expect(snapshot.isLastContent, isFalse);
  });

  test('validates direct choice selection against the current revision', () {
    final session = DialogueSession.start(<YarnNode>[
      YarnNode(
        title: 'choice',
        steps: <YarnStep>[
          YarnStepChoiceBlock(<YarnChoice>[
            YarnChoice(text: 'Oui', steps: <YarnStep>[YarnStepLine('OK')]),
            YarnChoice(text: 'Non', steps: <YarnStep>[YarnStepLine('NON')]),
          ]),
        ],
      ),
    ], 'choice')!;
    final snapshot = buildDialoguePresentationSnapshot(
      session: session,
      revision: 8,
      visibleText: '',
      isCurrentLineFullyRevealed: true,
    );

    expect(snapshot.mode, DialoguePresentationMode.choices);
    expect(snapshot.choices.map((choice) => choice.label), <String>[
      'Oui',
      'Non',
    ]);
    expect(
      validateDialoguePresentationCommand(
        snapshot,
        const DialogueSelectChoiceCommand(snapshotRevision: 8, choiceIndex: 1),
      ).accepted,
      isTrue,
    );
    expect(
      validateDialoguePresentationCommand(
        snapshot,
        const DialogueSelectChoiceCommand(snapshotRevision: 7, choiceIndex: 1),
      ).rejection,
      DialoguePresentationCommandRejection.staleSnapshot,
    );
  });

  test(
    'projects structured portrait metadata without changing legacy text',
    () {
      final session = DialogueSession.start(<YarnNode>[
        YarnNode(
          title: 'portrait',
          steps: <YarnStep>[
            YarnStepLine(
              'Élia: Attends… tu as vu ça ?',
              characterId: 'elia',
              portraitStateId: 'surprised',
            ),
          ],
        ),
      ], 'portrait')!;
      const portrait = ResolvedDialoguePortrait(
        characterId: 'elia',
        characterName: 'Élia',
        portraitStateId: 'surprised',
        portraitStateName: 'Surprise',
        assetId: 'portrait.elia.surprised',
        absoluteFilePath: '/project/assets/.pokemap-store/portrait.blob',
        fitMode: CharacterPortraitFitMode.cover,
      );

      final snapshot = buildDialoguePresentationSnapshot(
        session: session,
        revision: 9,
        visibleText: 'Élia: Attends…',
        isCurrentLineFullyRevealed: false,
        resolvePortrait: ({required characterId, required portraitStateId}) =>
            portrait,
      );

      expect(snapshot.speaker, 'Élia');
      expect(snapshot.text, 'Attends…');
      expect(snapshot.fullText, 'Attends… tu as vu ça ?');
      expect(snapshot.portrait, portrait);
    },
  );
}
