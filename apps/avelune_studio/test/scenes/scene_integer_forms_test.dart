import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_condition_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  final project = ProjectManifest(name: 'Numbers', maps: [], tilesets: [], facts: [
    NarrativeFactDefinition(id: 'counter', label: 'Compteur', initialValue: NarrativeValue.integer(4)),
    NarrativeFactDefinition(id: 'flag', label: 'Drapeau'),
  ]);
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(MaterialApp(theme: studioTheme(),
    home: Scaffold(body: SingleChildScrollView(child: SizedBox(width: 500, child: child)))));
  testWidgets('Studio reopens numeric cancellation without losing typed data', (tester) async {
    final command = SceneInputIntegerToFactInteractiveCommand(factId: 'counter', prompt: SceneInteractionPrompt(localizationKey: 'number', fallbackText: 'Combien ?'),
      digits: 3, minimum: 0, maximum: 999, cancellationPolicy: SceneIntegerCancellationPolicy.restoreInitialAndComplete);
    SceneNodePayload? applied;
    await pump(tester, SceneActionForm(project: project, current: SceneActionPayload.interactive(command), onApply: (value) => applied = value));
    await tester.pump();
    final button = tester.widget<StudioButton>(find.byWidgetPredicate((widget) => widget is StudioButton && widget.label == 'Appliquer l’action'));
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    expect((applied as SceneActionPayload).interactiveCommand, command);
    expect(find.text('Compteur'), findsWidgets);
  });
  testWidgets('Studio reopens a typed Fact versus money comparison', (tester) async {
    final source = SceneConditionSource.integerComparison(left: SceneIntegerOperand.integerFact('counter'),
      comparison: NarrativeFactOperator.greaterThanOrEqual, right: SceneIntegerOperand.gameRead(SceneIntegerGameRead.money));
    SceneConditionSource? applied;
    await pump(tester, SceneConditionForm(project: project, current: SceneConditionPayload(conditionSource: source), onApply: (value) => applied = value));
    await tester.pump();
    final button = tester.widget<StudioButton>(find.byWidgetPredicate((widget) => widget is StudioButton && widget.label == 'Appliquer la condition'));
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    expect(applied, source);
  });
}
