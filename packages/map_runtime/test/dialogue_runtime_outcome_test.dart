import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/parse_yarn_dialogue.dart';
import 'package:map_runtime/src/presentation/flame/dialogue_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/dialogue_text_speed.dart';
import 'package:map_runtime/src/presentation/flutter/dialogue_presentation_snapshot.dart';

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

    test('overlay reveals a partial Unicode line before advancing the session',
        () async {
      final session = DialogueSession.start(
        [
          YarnNode(
            title: 'Start',
            steps: [
              YarnStepLine('Lysa: Hé 🌊'),
              YarnStepLine('Lysa: Suite.'),
            ],
          ),
        ],
        'Start',
      )!;
      final snapshots = <DialoguePresentationSnapshot>[];
      final overlay = DialogueOverlayComponent(
        session: session,
        textSpeed: RuntimeDialogueTextSpeed.normal,
        renderInFlame: false,
        onPresentationSnapshotChanged: (snapshot) {
          if (snapshot != null) snapshots.add(snapshot);
        },
        onFinished: (_) {},
        viewportSize: Vector2(320, 240),
      );
      await overlay.onLoad();

      expect(snapshots.single.speaker, 'Lysa');
      expect(snapshots.single.text, isEmpty);
      overlay.update(
        RuntimeDialogueTextSpeed.normal.revealInterval!.inMicroseconds /
            Duration.microsecondsPerSecond *
            3,
      );

      expect(overlay.visibleText.runes.length, 3);
      expect(snapshots.last.revision, greaterThan(snapshots.first.revision));
      expect(overlay.isCurrentLineFullyRevealed, isFalse);
      expect(
        (overlay.currentSession.state as DialogueShowingLine).text,
        'Lysa: Hé 🌊',
      );

      expect(overlay.advance(), isTrue);
      expect(overlay.isCurrentLineFullyRevealed, isTrue);
      expect(
        (overlay.currentSession.state as DialogueShowingLine).text,
        'Lysa: Hé 🌊',
      );

      expect(overlay.advance(), isTrue);
      expect(
        (overlay.currentSession.state as DialogueShowingLine).text,
        'Lysa: Suite.',
      );
      expect(overlay.visibleText, isEmpty);
    });
  });
}
