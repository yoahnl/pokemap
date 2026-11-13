import 'package:avelune_studio/features/map_workspace/coordination/editor_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {

  testWidgets('delete and Cmd+K do nothing while a text field is edited', (
    tester,
  ) async {
    var deleted = 0, opened = 0;
    final field = FocusNode();
    final outer = FocusNode();
    addTearDown(field.dispose);
    addTearDown(outer.dispose);
    await tester.pumpWidget(
      _app(
        CallbackShortcuts(
          bindings: textAwareEditorShortcuts({
            const SingleActivator(LogicalKeyboardKey.delete): () => deleted++,
            const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
                opened++,
          }),
          child: Focus(
            focusNode: outer,
            child: TextField(focusNode: field),
          ),
        ),
      ),
    );
    field.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    expect(deleted, 0);
    expect(opened, 0);
    outer.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(deleted, 1);
  });

}
