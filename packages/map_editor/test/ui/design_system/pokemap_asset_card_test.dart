import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'PokeMapAssetCard renders the complete asset contract with a 36px target',
    (tester) async {
      var activationCount = 0;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: PokeMapAssetCard(
                focusNode: focusNode,
                thumbnail: const SizedBox.square(
                  dimension: 24,
                  child: Icon(Icons.park_outlined),
                ),
                label: 'Arbre centenaire',
                description: 'Décoration extérieure réutilisable',
                trailing: const Icon(Icons.chevron_right_rounded),
                selected: true,
                onPressed: () => activationCount += 1,
              ),
            ),
          ),
        ),
      );

      final card = find.byType(PokeMapAssetCard);
      expect(find.text('Arbre centenaire'), findsOneWidget);
      expect(
        find.text('Décoration extérieure réutilisable'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.park_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(tester.getSize(card).height, greaterThanOrEqualTo(36));
      final node = tester.getSemantics(card);
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      expect(node.label, contains('Arbre centenaire'));
      expect(node.label, contains('Décoration extérieure réutilisable'));

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.tap(card);
      expect(activationCount, 3);
      semantics.dispose();
    },
  );

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
              thumbnail: const Icon(Icons.grid_4x4_rounded),
              label: 'Tuile 1',
              disabledReason:
                  'Assignez cette source au calque actif avant de peindre.',
              onPressed: null,
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

  testWidgets('semantic tap activates only an enabled PokeMapAssetCard',
      (tester) async {
    var activationCount = 0;
    final semantics = tester.ensureSemantics();

    Widget buildCard(VoidCallback? onPressed) {
      return MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PokeMapAssetCard(
            thumbnail: const Icon(Icons.park_outlined),
            label: 'Objet Arbre',
            disabledReason:
                onPressed == null ? 'Assignez d’abord cette source.' : null,
            onPressed: onPressed,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildCard(() => activationCount += 1));

    final enabledFinder = find.semantics.byLabel('Objet Arbre');
    final enabledNode = enabledFinder.evaluate().single;
    expect(
      enabledNode.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    tester.semantics.tap(enabledFinder);
    await tester.pump();
    expect(activationCount, 1);

    await tester.pumpWidget(buildCard(null));

    final disabledFinder = find.semantics.byLabel(RegExp('Objet Arbre'));
    final disabledNode = disabledFinder.evaluate().single;
    expect(
      disabledNode.getSemanticsData().hasAction(SemanticsAction.tap),
      isFalse,
    );
    tester.semantics.performAction(
      disabledFinder,
      SemanticsAction.tap,
      checkForAction: false,
    );
    await tester.pump();
    expect(activationCount, 1);
    semantics.dispose();
  });

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
            thumbnail: const Icon(Icons.park_outlined),
            label: 'Objet Arbre',
            selected: true,
            onPressed: () => activationCount += 1,
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

  testWidgets(
    'Tab follows card order and skips a disabled asset',
    (tester) async {
      final first = FocusNode(debugLabel: 'asset first');
      final disabled = FocusNode(debugLabel: 'asset disabled');
      final last = FocusNode(debugLabel: 'asset last');
      addTearDown(first.dispose);
      addTearDown(disabled.dispose);
      addTearDown(last.dispose);

      PokeMapAssetCard card(
        String label,
        FocusNode focusNode,
        VoidCallback? onPressed,
      ) {
        return PokeMapAssetCard(
          focusNode: focusNode,
          thumbnail: const Icon(Icons.grid_4x4_rounded),
          label: label,
          disabledReason: onPressed == null ? 'Source incompatible.' : null,
          onPressed: onPressed,
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: Column(
              children: [
                card('Premier', first, () {}),
                card('Désactivé', disabled, null),
                card('Dernier', last, () {}),
              ],
            ),
          ),
        ),
      );

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(first.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(disabled.hasFocus, isFalse);
      expect(last.hasFocus, isTrue);
    },
  );
}
