import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../storyline/storyline_widget_support.dart';
import 'story_memory_harness.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

EditableText _field(WidgetTester tester, String key) => tester.widget(
  find.descendant(of: _key(key), matching: find.byType(EditableText)),
);

void main() {
  testWidgets(
    'the empty Trame form can be filled by keyboard and its draft survives navigation',
    (tester) async {
      final reads = await openTrameStudio(tester, empty: true);
      await tester.tap(_key('trame-start-empty'));
      await settleMemory(tester);
      expect(
        _field(tester, 'trame-create-title').focusNode.hasPrimaryFocus,
        isTrue,
      );
      await tester.enterText(_key('trame-create-title'), 'Le passage');
      for (var index = 0; index < 2; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await settleMemory(tester);
      }
      expect(
        _field(tester, 'trame-create-chapter').focusNode.hasPrimaryFocus,
        isTrue,
      );
      await tester.enterText(_key('trame-create-chapter'), 'Le bourg');
      await settleMemory(tester);
      expect(
        _field(tester, 'trame-create-title').controller.text,
        'Le passage',
      );
      expect(
        _field(tester, 'trame-create-chapter').controller.text,
        'Le bourg',
      );
      expect(
        tester.widget<StudioButton>(_key('confirm-reviewed-plan')).onPressed,
        isNotNull,
      );
      await tester.tap(_key('confirm-reviewed-plan'));
      await tester.pumpAndSettle();

      expect(_key('trame-create-story'), findsNothing);
      expect(find.text('Le passage'), findsWidgets);
      expect(find.text('Le bourg'), findsWidgets);
      expect(reads.stories, isEmpty);
      await tester.tap(_key('story-section-behaviours'));
      await settleMemory(tester);
      await tester.tap(_key('story-section-trame'));
      await settleMemory(tester);
      expect(find.text('Le passage'), findsWidgets);
      expect(find.text('Le bourg'), findsWidgets);
      expect(reads.stories, isEmpty);
    },
  );
}
