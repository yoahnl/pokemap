import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'PokeMapAssetCard exposes disabled reason and ignores all activation paths',
    (tester) async {
      var activationCount = 0;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: PokeMapAssetCard(
              focusNode: focusNode,
              semanticLabel: 'Tuile 1',
              disabledReason:
                  'Assignez cette source au calque actif avant de peindre.',
              onPressed: null,
              child: const Text('Tuile 1'),
            ),
          ),
        ),
      );

      final card = find.byType(PokeMapAssetCard);
      final node = tester.getSemantics(card);
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.label, contains('Tuile 1'));
      expect(node.label, contains('Assignez cette source'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message,
        contains('Assignez cette source'),
      );

      await tester.tap(card);
      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(activationCount, 0);
      semantics.dispose();
    },
  );

  testWidgets('PokeMapAssetCard activates with pointer, Enter, and Space',
      (tester) async {
    var activationCount = 0;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: PokeMapAssetCard(
            focusNode: focusNode,
            semanticLabel: 'Objet Arbre',
            selected: true,
            onPressed: () => activationCount += 1,
            child: const Text('Arbre'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PokeMapAssetCard));
    expect(activationCount, 1);

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activationCount, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(activationCount, 3);
  });
}
