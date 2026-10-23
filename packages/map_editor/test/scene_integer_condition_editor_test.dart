import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_integer_condition_editor.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('guided comparison preserves typed Fact versus money operands', (tester) async {
    SceneConditionSource? result;
    final source = SceneConditionSource.integerComparison(left: SceneIntegerOperand.integerFact('counter'),
      comparison: NarrativeFactOperator.greaterThanOrEqual, right: SceneIntegerOperand.gameRead(SceneIntegerGameRead.money));
    await tester.pumpWidget(MaterialApp(theme: PokeMapTheme.light(), home: Scaffold(body: SceneIntegerConditionEditor(
      current: source, facts: const {'counter': 'Compteur'}, items: const {}, onApply: (value) async { result = value; return true; }))));
    final button = tester.widget<PokeMapButton>(find.byKey(const ValueKey('scene-integer-comparison-apply')));
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    await tester.pump();
    expect(result, source);
    expect(find.text('Compteur'), findsWidgets);
    expect(find.text('Argent du joueur'), findsWidgets);
  });
}
