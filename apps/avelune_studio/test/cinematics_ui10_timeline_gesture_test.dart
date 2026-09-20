import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/m2_ui_fixture.dart';
import 'support/ui10_cinematic_fixture.dart';
import 'support/ui10_workspace_harness.dart';

void main() {
  testWidgets(
    'UI10 timeline drag reorders and duration handle commits once with undo redo',
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
      final controller = harness.page(tester).controller;
      final before = controller.active!.asset;
      final handle = find.byKey(const ValueKey('cinematic-duration-walk'));
      await tester.ensureVisible(handle);
      final scale = harness
          .page(tester)
          .views
          .forAsset(ui10CinematicId)
          .timelineScale;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(24, 0));
      await tester.pump();
      await gesture.moveBy(Offset(500 * scale, 0));
      await tester.pump();
      expect(controller.active!.asset.toJson(), before.toJson());
      await harness.capture(tester, 'ui10-03-duration-drag');
      await gesture.up();
      await tester.pump();
      final resized = controller.active!.asset;
      expect(
        resized.timeline.steps.singleWhere((s) => s.id == 'walk').durationMs,
        greaterThan(1200),
      );
      await tester.tap(find.byTooltip('Annuler la cinématique'));
      await tester.pump();
      expect(controller.active!.asset.toJson(), before.toJson());
      await tester.tap(find.byTooltip('Rétablir la cinématique'));
      await tester.pump();
      expect(controller.active!.asset.toJson(), resized.toJson());
      final block = find.byKey(const ValueKey('cinematic-clip-walk'));
      final move = await tester.startGesture(
        tester.getTopLeft(block) + const Offset(12, 12),
      );
      await move.moveBy(const Offset(24, 0));
      await tester.pump();
      await move.moveBy(Offset(3200 * scale, 0));
      await tester.pump();
      await harness.capture(tester, 'ui10-04-order-drag');
      await move.up();
      await tester.pump();
      expect(
        controller.active!.asset.timeline.steps.map((s) => s.id).toList(),
        isNot(resized.timeline.steps.map((s) => s.id).toList()),
      );
      await tester.tap(find.byTooltip('Annuler la cinématique'));
      await tester.pump();
      expect(controller.active!.asset.toJson(), resized.toJson());
      final cancel = await tester.startGesture(tester.getCenter(handle));
      await cancel.moveBy(const Offset(24, 0));
      await tester.pump();
      await cancel.moveBy(const Offset(30, 0));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await cancel.up();
      await tester.pump();
      expect(controller.active!.asset.toJson(), resized.toJson());
      expect(harness.port.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
