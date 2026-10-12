import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/parse_yarn_dialogue.dart';
import 'package:map_runtime/src/presentation/flame/dialogue_overlay_component.dart';

void main() {
  test('disabled cancellation leaves the current cursor and dialogue unchanged', () {
    final session = _session().withChoicePolicies(const [
      SceneDialogueChoicePolicy(nodeName: 'Start'),
    ]).moveChoiceCursor(1);
    expect(session.choiceCancellationOutcomeId, isNull);
    expect(session.cancelChoice(), same(session));
    expect((session.state as DialogueWaitingForChoice).selectedIndex, 1);
  });

  test('cancel-to-choice follows that option content and outcome regardless of cursor', () {
    final session = _session().withChoicePolicies(const [
      SceneDialogueChoicePolicy(
        nodeName: 'Start',
        cancellation: SceneDialogueChoiceCancellation.choice('no'),
      ),
    ]);
    final next = session.cancelChoice()!;
    expect((next.state as DialogueShowingLine).text, 'Refus.');
    expect(next.selectedOutcomeId, 'no');
    expect(next.advance(), isNull);
  });

  test('separate cancellation completes with its own outcome and no extra choice', () {
    final session = _session().withChoicePolicies(const [
      SceneDialogueChoicePolicy(
        nodeName: 'Start',
        cancellation: SceneDialogueChoiceCancellation.branch('cancel'),
      ),
    ]);
    String? outcome;
    final overlay = DialogueOverlayComponent(
      session: session,
      viewportSize: Vector2(320, 240),
      onFinished: (value) => outcome = value,
    );
    expect((session.state as DialogueWaitingForChoice).choices, hasLength(2));
    expect(overlay.cancelChoice(), isFalse);
    expect(outcome, 'cancel');
  });

  test('default cursor is scoped and stays movable after interpolation', () {
    final session = _session().withChoicePolicies(const [
      SceneDialogueChoicePolicy(nodeName: 'Start', defaultOutcomeId: 'no'),
    ]);
    expect((session.state as DialogueWaitingForChoice).selectedIndex, 1);
    final moved = session.moveChoiceCursor(-1).mapText((text) => '$text!');
    expect((moved.state as DialogueWaitingForChoice).selectedIndex, 0);
    expect((moved.confirmChoice()!.state as DialogueShowingLine).text, 'Accord.!');
  });

  test('policy does not leak to a second choice after a Yarn jump', () {
    final session = DialogueSession.start(parseYarnFile('''
title: Start
---
-> Suivre
    <<outcome yes>>
    <<jump Next>>
===
title: Next
---
-> Finir
    <<outcome next>>
===
'''), 'Start')!.withChoicePolicies(const [
      SceneDialogueChoicePolicy(
        nodeName: 'Start',
        cancellation: SceneDialogueChoiceCancellation.choice('yes'),
      ),
    ]);
    final next = session.cancelChoice()!;
    expect(next.currentNodeTitle, 'Next');
    expect(next.choiceCancellationOutcomeId, isNull);
    expect(next.cancelChoice(), same(next));
  });

  test('rejects unknown scope, dangling choice, duplicate outcome and non-distinct cancel branch', () {
    for (final policy in const [
      SceneDialogueChoicePolicy(nodeName: 'Missing'),
      SceneDialogueChoicePolicy(nodeName: 'Start', choiceIndex: 1),
      SceneDialogueChoicePolicy(nodeName: 'Start', defaultOutcomeId: 'missing'),
      SceneDialogueChoicePolicy(nodeName: 'Start', cancellation: SceneDialogueChoiceCancellation.choice('missing')),
      SceneDialogueChoicePolicy(nodeName: 'Start', cancellation: SceneDialogueChoiceCancellation.branch('no')),
    ]) {
      expect(() => _session().withChoicePolicies([policy]), throwsArgumentError);
    }
    final duplicate = DialogueSession.start([
      YarnNode(title: 'Start', steps: [YarnStepChoiceBlock([
        YarnChoice(text: 'A', steps: const [], outcomeId: 'same'),
        YarnChoice(text: 'B', steps: const [], outcomeId: 'same'),
      ])]),
    ], 'Start')!;
    expect(() => duplicate.withChoicePolicies(const [
      SceneDialogueChoicePolicy(nodeName: 'Start', cancellation: SceneDialogueChoiceCancellation.choice('same')),
    ]), throwsArgumentError);
  });
}

DialogueSession _session() => DialogueSession.start(parseYarnFile('''
title: Start
---
-> Oui
    <<outcome yes>>
    Accord.
-> Non
    <<outcome no>>
    Refus.
===
'''), 'Start')!;
