import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';

void main() {
  testWidgets('enter and focus loss submit a synchronous edit once', (
    tester,
  ) async {
    final names = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapBuilderNameField(
            value: 'Initial',
            label: 'Nom',
            enabled: true,
            onCommit: names.add,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Nouveau');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(names, ['Nouveau']);
    await tester.tap(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(names, ['Nouveau', 'Nouveau']);
  });

  testWidgets(
    'pending asynchronous edits coalesce and refused edits can retry',
    (tester) async {
      var attempts = 0;
      final pending = Completer<bool>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapBuilderNameField(
              value: 'Initial',
              label: 'Nom',
              enabled: true,
              onSubmit: (_) {
                attempts++;
                return attempts == 1 ? pending.future : Future.value(true);
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Nouveau');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(attempts, 1);
      pending.complete(false);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Initial',
      );
      await tester.enterText(find.byType(TextField), 'Nouveau');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(attempts, 2);
    },
  );
}
