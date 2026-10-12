import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/scene_dialogue_choice_policy_authoring_gateway.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_dialogue_choice_policy_dialog.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

const _data = SceneDialogueChoicePolicyEditorData(
  scopes: [
    SceneDialogueChoiceScopeOption(
      nodeName: 'Start',
      choiceIndex: 0,
      labels: ['Oui', 'Non'],
      choices: [
        SceneDialogueChoiceOption(outcomeId: 'yes', label: 'Oui'),
        SceneDialogueChoiceOption(outcomeId: 'no', label: 'Non'),
      ],
      branches: [
        SceneDialogueChoiceOption(
          outcomeId: 'cancel',
          label: 'Retour à la carte',
        ),
      ],
    ),
    SceneDialogueChoiceScopeOption(
      nodeName: 'Start',
      choiceIndex: 1,
      labels: ['Continuer', 'Revenir'],
      choices: [
        SceneDialogueChoiceOption(outcomeId: 'next', label: 'Continuer'),
        SceneDialogueChoiceOption(outcomeId: 'back', label: 'Revenir'),
      ],
      branches: [],
    ),
  ],
  policies: [
    SceneDialogueChoicePolicy(
      nodeName: 'Start',
      choiceIndex: 1,
      defaultOutcomeId: 'back',
      cancellation: SceneDialogueChoiceCancellation.choice('next'),
    ),
  ],
);

void main() {
  testWidgets(
    'offers human labels and existing scene branches for the selected exact choice',
    (tester) async {
      SceneDialogueChoicePolicy? result;
      await _open(tester, onResult: (value) => result = value);
      expect(find.text('Oui · Non'), findsOneWidget);
      expect(find.byType(PokeMapTextField), findsNothing);
      await _select(tester, 'scene-choice-default', 'Non');
      await _select(
        tester,
        'scene-choice-cancellation',
        'Une branche de la scène',
      );
      expect(find.text('Retour à la carte'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('scene-choice-policy-confirm')),
      );
      await tester.pumpAndSettle();
      expect(
        result,
        const SceneDialogueChoicePolicy(
          nodeName: 'Start',
          defaultOutcomeId: 'no',
          cancellation: SceneDialogueChoiceCancellation.branch('cancel'),
        ),
      );
    },
  );

  testWidgets(
    'switches scopes without leaking defaults or cancellation and saves a visible option',
    (tester) async {
      SceneDialogueChoicePolicy? result;
      await _open(tester, onResult: (value) => result = value);
      await _select(tester, 'scene-choice-scope', 'Start · Choix 2');
      expect(find.text('Continuer · Revenir'), findsOneWidget);
      expect(
        tester
            .widget<PokeMapDropdownField<String>>(
              find.byKey(const ValueKey('scene-choice-default')),
            )
            .value,
        'back',
      );
      final kind = tester
          .widget<PokeMapDropdownField<SceneDialogueChoiceCancellationKind>>(
            find.byKey(const ValueKey('scene-choice-cancellation')),
          );
      expect(
        kind.items.map((item) => item.value),
        isNot(contains(SceneDialogueChoiceCancellationKind.branch)),
      );
      await _select(tester, 'scene-choice-target', 'Revenir');
      await tester.tap(
        find.byKey(const ValueKey('scene-choice-policy-confirm')),
      );
      await tester.pumpAndSettle();
      expect(
        result,
        const SceneDialogueChoicePolicy(
          nodeName: 'Start',
          choiceIndex: 1,
          defaultOutcomeId: 'back',
          cancellation: SceneDialogueChoiceCancellation.choice('back'),
        ),
      );
    },
  );

  testWidgets(
    'disabled cancellation has no target picker and closing makes no edit',
    (tester) async {
      var called = false;
      SceneDialogueChoicePolicy? result;
      await _open(
        tester,
        onResult: (value) {
          called = true;
          result = value;
        },
      );
      expect(find.byKey(const ValueKey('scene-choice-target')), findsNothing);
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
      expect(result, isNull);
    },
  );
}

Future<void> _open(
  WidgetTester tester, {
  required ValueChanged<SceneDialogueChoicePolicy?> onResult,
}) async {
  await tester.binding.setSurfaceSize(const Size(1100, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) => PokeMapButton(
            onPressed: () async => onResult(
              await showDialog<SceneDialogueChoicePolicy>(
                context: context,
                builder: (_) =>
                    const SceneDialogueChoicePolicyDialog(data: _data),
              ),
            ),
            child: const Text('Configurer'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Configurer'));
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, String key, String label) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}
