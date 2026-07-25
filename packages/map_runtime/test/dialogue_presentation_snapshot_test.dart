import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/presentation/flutter/dialogue_presentation_snapshot.dart';

void main() {
  test('projects speaker, visible line and continuation state', () {
    final session = DialogueSession.start(
      <YarnNode>[
        YarnNode(
          title: 'intro',
          steps: <YarnStep>[
            YarnStepLine('Lysa: Bienvenue à Bourg-Palette !'),
            YarnStepLine('La route est ouverte.'),
          ],
        ),
      ],
      'intro',
    )!;

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
    final session = DialogueSession.start(
      <YarnNode>[
        YarnNode(
          title: 'choice',
          steps: <YarnStep>[
            YarnStepChoiceBlock(<YarnChoice>[
              YarnChoice(text: 'Oui', steps: <YarnStep>[YarnStepLine('OK')]),
              YarnChoice(text: 'Non', steps: <YarnStep>[YarnStepLine('NON')]),
            ]),
          ],
        ),
      ],
      'choice',
    )!;
    final snapshot = buildDialoguePresentationSnapshot(
      session: session,
      revision: 8,
      visibleText: '',
      isCurrentLineFullyRevealed: true,
    );

    expect(snapshot.mode, DialoguePresentationMode.choices);
    expect(
        snapshot.choices.map((choice) => choice.label), <String>['Oui', 'Non']);
    expect(
      validateDialoguePresentationCommand(
        snapshot,
        const DialogueSelectChoiceCommand(
          snapshotRevision: 8,
          choiceIndex: 1,
        ),
      ).accepted,
      isTrue,
    );
    expect(
      validateDialoguePresentationCommand(
        snapshot,
        const DialogueSelectChoiceCommand(
          snapshotRevision: 7,
          choiceIndex: 1,
        ),
      ).rejection,
      DialoguePresentationCommandRejection.staleSnapshot,
    );
  });
}
