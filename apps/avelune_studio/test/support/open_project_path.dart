import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_path_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder studioProjectPathField() => find.descendant(
  of: find.byType(StudioPathField),
  matching: find.byType(TextField),
);

Future<void> revealProjectPath(WidgetTester tester) async {
  if (studioProjectPathField().evaluate().isEmpty) {
    final control = find.byKey(const ValueKey('exact-project-path'));
    final scroll = find.byKey(const ValueKey('home-local-content-scroll'));
    if (scroll.evaluate().isNotEmpty) {
      for (var i = 0; i < 20 && control.hitTestable().evaluate().isEmpty; i++) {
        await tester.drag(scroll, const Offset(0, -160));
        await tester.pumpAndSettle();
      }
    }
    await tapVisible(tester, control);
    await tester.pumpAndSettle();
  }
  final field = studioProjectPathField();
  final scroll = find.byKey(const ValueKey('home-local-content-scroll'));
  if (scroll.evaluate().isNotEmpty) {
    for (var i = 0; i < 20 && field.hitTestable().evaluate().isEmpty; i++) {
      await tester.drag(scroll, const Offset(0, -160));
      await tester.pumpAndSettle();
    }
  }
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
}

Future<void> enterProjectPath(WidgetTester tester, String path) async {
  await revealProjectPath(tester);
  await tester.enterText(studioProjectPathField(), path);
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 100));
  final scroll = find.byKey(const ValueKey('home-local-content-scroll'));
  if (target.hitTestable().evaluate().isEmpty && scroll.evaluate().isNotEmpty) {
    final list = find.descendant(of: scroll, matching: find.byType(Scrollable));
    tester.state<ScrollableState>(list.first).position.jumpTo(0);
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 100));
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
}
