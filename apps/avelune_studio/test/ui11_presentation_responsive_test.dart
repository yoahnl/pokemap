import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/ui11_workspace_harness.dart';
import 'ui11_presentation_widget_test.dart' show tapUi11;

void main() {
  for (final size in [
    const Size(1536, 1024),
    const Size(1440, 900),
    const Size(1280, 800),
    const Size(1024, 640),
  ]) {
    testWidgets('UI11 responsive ${size.width.toInt()} portrait and compare', (
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
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        harness.app(textScale: size.width == 1024 ? 1.5 : 1),
      );
      await harness.settle(tester);
      await harness.capture(tester, 'ui11-04-landscape-${size.width.toInt()}');
      expect(tester.takeException(), isNull);
      await tapUi11(tester, harness, find.text('Paysage 16:9'));
      await tapUi11(tester, harness, find.text('Portrait 9:16').last);
      expect(
        harness.views.forAsset(harness.controller.active!.asset).portrait,
        isTrue,
      );
      await harness.capture(tester, 'ui11-05-portrait-${size.width.toInt()}');
      expect(tester.takeException(), isNull);
      await tapUi11(tester, harness, find.byTooltip('Comparer les formats'));
      expect(
        harness.views.forAsset(harness.controller.active!.asset).compare,
        isTrue,
      );
      await harness.capture(tester, 'ui11-06-compare-${size.width.toInt()}');
      expect(harness.controller.active!.dirty, isFalse);
      expect(harness.port.writes, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
