import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/m2_ui_fixture.dart';
import 'support/ui10_cinematic_fixture.dart';
import 'support/ui10_workspace_harness.dart';

void main() {
  for (final size in [
    const Size(1440, 900),
    const Size(1280, 800),
    const Size(1024, 640),
  ]) {
    testWidgets(
      'UI10 ${size.width}x${size.height} inspector edit keyboard save and reopen',
      (tester) async {
        tester.view.physicalSize = const Size(1536, 1024);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final harness = (await tester.runAsync(
          () => Ui10WorkspaceHarness.create(tester),
        ))!;
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(harness.dispose);
        });
        await tester.pumpWidget(harness.app());
        await pumpIo(tester);
        await harness.open(tester);
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          harness.app(textScale: size.width == 1024 ? 1.5 : 1),
        );
        await pumpIo(tester);
        final field = find.descendant(
          of: find.byKey(const ValueKey('cinematic-title-$ui10CinematicId')),
          matching: find.byType(TextField),
        );
        if (field.evaluate().isEmpty) {
          await tester.tap(find.byTooltip('Inspecteur de cinématique'));
          await tester.pump();
        }
        await tester.ensureVisible(field);
        final title = 'Rencontre ${size.width.toInt()}';
        await tester.enterText(field, title);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await pumpIo(tester, frames: 25);
        final controller = harness.page(tester).controller;
        expect(controller.active!.asset.title, title);
        expect(controller.active!.dirty, isFalse);
        expect(harness.port.writes, 1);
        expect(
          (await tester.runAsync(
            () => harness.port.delegate.load(ui10CinematicId),
          ))!.asset.title,
          title,
        );
        expect(tester.takeException(), isNull);
        await harness.capture(tester, 'ui10-responsive-${size.width.toInt()}');
      },
    );
  }
}
