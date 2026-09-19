import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_path_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder studioProjectPathField() => find.descendant(
  of: find.byType(StudioPathField),
  matching: find.byType(TextField),
);

Future<void> revealProjectPath(WidgetTester tester) async {
  if (studioProjectPathField().evaluate().isEmpty) {
    await tapVisible(tester, find.byKey(const ValueKey('exact-project-path')));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(studioProjectPathField());
  await tester.pumpAndSettle();
}

Future<void> enterProjectPath(WidgetTester tester, String path) async {
  await revealProjectPath(tester);
  await tester.enterText(studioProjectPathField(), path);
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 100));
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
}
