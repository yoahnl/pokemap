import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('text field exposes label, validation and keyboard submit',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var submitted = '';

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: PokeMapTextField(
              label: 'Nom de l’événement',
              controller: controller,
              hintText: 'Rencontre au port',
              errorText: 'Le nom est obligatoire.',
              onSubmitted: (value) => submitted = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nom de l’événement'), findsOneWidget);
    expect(find.text('Le nom est obligatoire.'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Nom de l’événement' &&
            widget.properties.textField == true,
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Rencontre au port');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted, 'Rencontre au port');
    expect(tester.takeException(), isNull);
  });
}
