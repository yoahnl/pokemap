import 'package:avelune_studio/features/scenes/application/scene_action_draft.dart';
import 'package:avelune_studio/features/scenes/application/scene_integer_condition_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  final project = ProjectManifest(
    name: 'Numbers',
    maps: [],
    tilesets: [],
    facts: [
      NarrativeFactDefinition(
        id: 'counter',
        label: 'Compteur',
        initialValue: NarrativeValue.integer(4),
      ),
      NarrativeFactDefinition(id: 'flag', label: 'Drapeau'),
    ],
  );
  test('numeric action reopens cancellation without losing typed data', () {
    final command = SceneInputIntegerToFactInteractiveCommand(
      factId: 'counter',
      prompt: SceneInteractionPrompt(
        localizationKey: 'number',
        fallbackText: 'Combien ?',
      ),
      digits: 3,
      minimum: 0,
      maximum: 999,
      cancellationPolicy:
          SceneIntegerCancellationPolicy.restoreInitialAndComplete,
    );
    final draft = SceneActionDraft(
      project: project,
      current: SceneActionPayload.interactive(command),
      changed: () {},
    );
    addTearDown(draft.dispose);
    expect(draft.valid, isTrue);
    expect(
      (draft.buildPayload() as SceneActionPayload).interactiveCommand,
      command,
    );
    expect(draft.options(NarrativeCommandParameterKind.integerFacts), {
      'counter': 'Compteur',
    });
  });
  test('condition owner reopens a typed fact versus money comparison', () {
    final source = SceneConditionSource.integerComparison(
      left: SceneIntegerOperand.integerFact('counter'),
      comparison: NarrativeFactOperator.greaterThanOrEqual,
      right: SceneIntegerOperand.gameRead(SceneIntegerGameRead.money),
    );
    final draft = SceneIntegerConditionDraft(
      project: project,
      current: source,
      changed: () {},
    );
    addTearDown(draft.dispose);
    expect(draft.prepared, source);
    expect(draft.current, same(source));
  });
}
