import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_rules.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_condition_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../game_memory/game_memory_fakes.dart';

void main() {
  testWidgets(
    'string comparisons preserve literal spaces and accept an empty value',
    (tester) async {
      final index = FakeNarrativeIndex()
        ..addFacts([
          memoryFact(
            'password',
            'Mot de passe',
            value: const NarrativeValue.string(''),
          ),
        ]);
      final memory = GameMemoryController(
        port: index,
        staging: FakeMemoryStaging(),
        changed: () {},
      );
      addTearDown(memory.dispose);
      await memory.open();
      GameMemoryRuleCondition condition = (
        factId: 'password',
        operator: NarrativeFactOperator.equals,
        value: const NarrativeValue.string('secret'),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => GameMemoryConditionFields(
                memory: memory,
                condition: condition,
                enabled: true,
                onChanged: (value) => setState(() => condition = value),
              ),
            ),
          ),
        ),
      );
      final field = find.descendant(
        of: find.byKey(const ValueKey('memory-rule-value')),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, '  mot  ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(condition.value, const NarrativeValue.string('  mot  '));
      await tester.enterText(field, '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(condition.value, const NarrativeValue.string(''));
    },
  );
}
