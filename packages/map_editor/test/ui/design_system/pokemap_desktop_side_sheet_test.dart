import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
      'side sheet takes initial focus, closes on Escape and restores focus',
      (tester) async {
    final launcherFocusNode = FocusNode();
    final sheetFocusNode = FocusNode();
    addTearDown(launcherFocusNode.dispose);
    addTearDown(sheetFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              focusNode: launcherFocusNode,
              onPressed: () {
                launcherFocusNode.requestFocus();
                showPokeMapDesktopSideSheet<void>(
                  context: context,
                  title: 'Bibliothèque d’éléments',
                  semanticLabel: 'Bibliothèque d’éléments de l’événement',
                  initialFocusNode: sheetFocusNode,
                  builder: (_) => TextField(
                    focusNode: sheetFocusNode,
                    decoration: const InputDecoration(labelText: 'Filtrer'),
                  ),
                );
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);
    expect(sheetFocusNode.hasFocus, isTrue);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.scopesRoute == true &&
            widget.properties.namesRoute == true &&
            widget.properties.label == 'Bibliothèque d’éléments de l’événement',
      ),
      findsOneWidget,
    );

    final surface = tester.widget<Material>(
      find.descendant(
        of: find.byType(PokeMapDesktopSideSheet),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Material &&
              widget.color == PokeMapColorTokens.dark.surfaceRaised,
        ),
      ),
    );
    expect(surface.color, PokeMapColorTokens.dark.surfaceRaised);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(PokeMapDesktopSideSheet), findsNothing);
    expect(launcherFocusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'side sheet has a dismissible labelled barrier and restores focus',
      (tester) async {
    final launcherFocusNode = FocusNode();
    addTearDown(launcherFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              focusNode: launcherFocusNode,
              onPressed: () {
                launcherFocusNode.requestFocus();
                showPokeMapDesktopSideSheet<void>(
                  context: context,
                  title: 'Créer un événement',
                  barrierLabel: 'Fermer la création d’événement',
                  width: 360,
                  builder: (_) => const Text('Contenu du panneau'),
                );
              },
              child: const Text('Créer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);
    expect(find.byTooltip('Fermer'), findsOneWidget);
    expect(find.bySemanticsLabel('Fermer la création d’événement'),
        findsOneWidget);

    await tester.tapAt(const Offset(40, 300));
    await tester.pumpAndSettle();

    expect(find.byType(PokeMapDesktopSideSheet), findsNothing);
    expect(launcherFocusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}
