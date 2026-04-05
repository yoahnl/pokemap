import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
import 'package:map_editor/src/ui/canvas/step_studio/step_flow_canvas.dart';

void main() {
  group('StepFlowCanvas (polish final — titres & honnêteté)', () {
    /// `flowUnlocksStepId` reste dans le JSON mais ne doit pas apparaître sur le
    /// canvas : c’était un signal « faux lien » vers une step suivante.
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

    testWidgets('uses creator-facing titles on canvas', (tester) async {
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
      expect(find.text('Après cette étape'), findsOneWidget);
      expect(find.text('Quand ça commence'), findsOneWidget);
    });
  });
}
