import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/ui11_workspace_harness.dart';
import 'ui11_presentation_widget_test.dart' show tapUi11;

void main() {
  testWidgets('UI11 a slow creation shows progress and blocks a second start', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = (await tester.runAsync(
      () => Ui11WorkspaceHarness.create(tester),
    ))!;
    addTearDown(() => harness.shutdown(tester));
    await tester.pumpWidget(harness.app());
    await harness.settle(tester);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    final slow = Completer<void>();
    harness.port.gate = slow.future;
    await tapUi11(tester, harness, find.text('Nouvelle cinématique'));
    await tester.enterText(find.byType(TextField).last, 'Montage lent');
    await tapUi11(tester, harness, find.text('Créer'));
    await tester.tap(find.text('Composition vide'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(harness.controller.busy, isTrue);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final pending = tester.widget<OutlinedButton>(
      find
          .ancestor(
            of: find.text('Nouvelle cinématique'),
            matching: find.byType(OutlinedButton),
          )
          .first,
    );
    expect(
      pending.onPressed,
      isNull,
      reason: 'A second creation must not start while the first is preparing',
    );
    await harness.capture(tester, 'ui11-03-busy-create');

    slow.complete();
    harness.port.gate = null;
    await tester.pump();
    await harness.settle(tester);

    expect(harness.controller.busy, isFalse);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(harness.controller.active?.asset.title, 'Montage lent');
    expect(tester.takeException(), isNull);
  });
}
