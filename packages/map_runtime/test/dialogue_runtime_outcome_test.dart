import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/parse_yarn_dialogue.dart';
import 'package:map_runtime/src/presentation/flame/dialogue_overlay_component.dart';

void main() {
  group('Yarn dialogue outcomes', () {
    test('parser attaches each outcome to its choice and preserves content',
        () {
      final nodes = parseYarnFile('''
title: Start
---
Guide: Choisis.
-> Accepter
    <<outcome accepted>>
    Joueur: Oui.
    <<jump Accepted>>
-> Refuser
    <<outcome refused>>
    Joueur: Non.
===
title: Accepted
---
Guide: Continuons.
===
''');

      final choiceBlock = nodes.first.steps[1] as YarnStepChoiceBlock;
      expect(
        choiceBlock.choices.map((choice) => choice.outcomeId),
        ['accepted', 'refused'],
      );
      expect(choiceBlock.choices.first.text, 'Accepter');
      expect(choiceBlock.choices.first.steps, hasLength(2));
      expect(
        (choiceBlock.choices.first.steps.first as YarnStepLine).text,
        'Joueur: Oui.',
      );
      expect(
        (choiceBlock.choices.first.steps.last as YarnStepJump).targetNode,
        'Accepted',
      );
    });

    test('session preserves the selected outcome through lines and jumps', () {
      final nodes = parseYarnFile('''
title: Start
---
-> Accepter
    <<outcome accepted>>
    Joueur: Oui.
    <<jump Accepted>>
===
title: Accepted
---
Guide: Continuons.
===
''');

      var session = DialogueSession.start(nodes, 'Start')!;
      session = session.confirmChoice()!;
      expect(session.selectedOutcomeId, 'accepted');
      expect((session.state as DialogueShowingLine).text, 'Joueur: Oui.');

      session = session.advance()!;
      expect(session.currentNodeTitle, 'Accepted');
      expect(session.selectedOutcomeId, 'accepted');
      expect((session.state as DialogueShowingLine).text, 'Guide: Continuons.');
    });

    test('overlay returns the outcome when a choice branch ends immediately',
        () {
      final session = DialogueSession.start(
        [
          YarnNode(
            title: 'Start',
            steps: [
              YarnStepChoiceBlock([
                YarnChoice(
                  text: 'Accepter',
                  outcomeId: 'accepted',
                  steps: const [],
                ),
              ]),
            ],
          ),
        ],
        'Start',
      )!;
      String? finishedOutcome;
      final overlay = DialogueOverlayComponent(
        session: session,
        onFinished: (outcomeId) => finishedOutcome = outcomeId,
        viewportSize: Vector2(320, 240),
      );

      expect(overlay.confirmChoice(), isFalse);
      expect(finishedOutcome, 'accepted');
    });
  });
}
