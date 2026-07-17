import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
      'search field is compact, labelled and clears without losing focus',
      (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final changes = <String>[];
    var cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              child: PokeMapSearchField(
                hintText: 'Rechercher un événement…',
                semanticLabel: 'Rechercher un événement',
                focusNode: focusNode,
                onChanged: changes.add,
                onClear: () => cleared = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(PokeMapSearchField)).height, 34);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Rechercher un événement' &&
            widget.properties.textField == true,
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'port');
    await tester.pump();

    expect(changes, contains('port'));
    expect(find.byTooltip('Effacer la recherche'), findsOneWidget);

    await tester.tap(find.byTooltip('Effacer la recherche'));
    await tester.pump();

    expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    expect(changes.last, '');
    expect(cleared, isTrue);
    expect(focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search field mirrors an external controller', (tester) async {
    final controller = TextEditingController(text: 'port');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PokeMapSearchField(
            controller: controller,
            hintText: 'Rechercher',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byTooltip('Effacer la recherche'), findsOneWidget);

    controller.clear();
    await tester.pump();

    expect(find.byTooltip('Effacer la recherche'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
