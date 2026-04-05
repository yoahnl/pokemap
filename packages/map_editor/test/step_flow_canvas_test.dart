import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
import 'package:map_editor/src/ui/canvas/step_studio/step_flow_canvas.dart';

void main() {
  group('StepFlowCanvas (wording lock final)', () {
    /// `flowUnlocksStepId` reste dans le JSON mais ne doit pas apparaître sur le
    /// canvas : c’était un signal « faux lien » vers une autre étape.
    testWidgets('does not display flowUnlocksStepId on canvas', (tester) async {
      const secretId = 'step_should_not_appear_on_canvas';
      final step = StepStudioStep(
        id: 'step_a',
        name: 'Step A',
        description: '',
        order: 0,
        activation: const StepStudioActivationRule(
          mode: StepStudioActivationMode.atGameStart,
        ),
        completion: const StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
        flowExitLabel: 'Quelque chose en sortie',
        flowUnlocksStepId: secretId,
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: StepFlowCanvas(
              step: step,
              selected: null,
              onSelect: (_) {},
              resolveCutsceneName: (id) => id,
            ),
          ),
        ),
      );

      expect(find.textContaining(secretId), findsNothing);
    });

    testWidgets('shows flowExitLabel on canvas', (tester) async {
      const exitText = 'Débloquer le rival (note auteur)';
      final step = StepStudioStep(
        id: 'step_b',
        name: 'B',
        description: '',
        order: 0,
        activation: const StepStudioActivationRule(
          mode: StepStudioActivationMode.atGameStart,
        ),
        completion: const StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
        flowExitLabel: exitText,
        flowUnlocksStepId: 'other',
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: StepFlowCanvas(
              step: step,
              selected: null,
              onSelect: (_) {},
              resolveCutsceneName: (id) => id,
            ),
          ),
        ),
      );

      expect(find.text(exitText), findsOneWidget);
    });

    testWidgets('uses locked creator-facing titles on canvas', (tester) async {
      final step = StepStudioStep(
        id: 'step_c',
        name: 'C',
        description: '',
        order: 0,
        activation: const StepStudioActivationRule(
          mode: StepStudioActivationMode.atGameStart,
        ),
        completion: const StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: StepFlowCanvas(
              step: step,
              selected: null,
              onSelect: (_) {},
              resolveCutsceneName: (id) => id,
            ),
          ),
        ),
      );

      expect(find.text('Cette étape'), findsOneWidget);
      expect(find.text('Quand ça commence'), findsOneWidget);
      expect(find.text('Objectif'), findsOneWidget);
      expect(find.text('Scènes liées'), findsOneWidget);
      expect(find.text('Issues possibles'), findsOneWidget);
      expect(find.text('Quand l’étape se termine'), findsOneWidget);
      expect(find.text('Résultats pour l’histoire'), findsOneWidget);
      expect(find.text('Note de transition'), findsOneWidget);
      expect(find.text('Changements sur la carte'), findsOneWidget);
    });

    testWidgets('avoids regressive misleading canvas wording', (tester) async {
      final step = StepStudioStep(
        id: 'step_d',
        name: 'D',
        description: '',
        order: 0,
        activation: const StepStudioActivationRule(
          mode: StepStudioActivationMode.atGameStart,
        ),
        completion: const StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: StepFlowCanvas(
              step: step,
              selected: null,
              onSelect: (_) {},
              resolveCutsceneName: (id) => id,
            ),
          ),
        ),
      );

      expect(find.text('Après cette étape'), findsNothing);
      expect(find.text('Quand l’étape devient disponible'), findsNothing);
      expect(find.textContaining('flowUnlocksStepId'), findsNothing);
      expect(find.textContaining('Portée'), findsNothing);
      expect(find.textContaining('Validation'), findsNothing);
    });
  });
}
