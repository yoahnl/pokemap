import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_player_ui/presentation_renderer.dart';
import 'support/ui11_workspace_harness.dart';
import 'ui11_presentation_widget_test.dart' show tapUi11;

void main() {
  for (final mode in ['scale', 'rotate']) {
    testWidgets('UI11 real $mode handle preview cancel and one undo', (
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
      final canvas = find.byKey(const ValueKey('presentation-canvas'));
      await tapUi11(tester, harness, canvas);
      final controller = harness.controller;
      final before = controller.active!.asset;
      final view = harness.views.forAsset(before);
      expect(view.selectedId, 'title.clip');
      final frame = tester.widget<PresentationFrameRenderer>(
        find
            .descendant(
              of: canvas,
              matching: find.byType(PresentationFrameRenderer),
            )
            .first,
      );
      final shape = frame.geometry!.snapshot().singleWhere(
        (s) => s.clipId == 'title.clip',
      );
      final local = mode == 'scale'
          ? shape.corners[2]
          : shape.bounds.topCenter - const Offset(0, 22);
      final origin = tester.getTopLeft(canvas) + local;
      final gesture = await tester.startGesture(origin);
      await gesture.moveBy(const Offset(48, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(40, 25));
      await tester.pump();
      expect(
        controller.active!.asset,
        before,
        reason: 'A drag preview must remain local until pointer up',
      );
      await gesture.up();
      await harness.settle(tester);
      final text = controller.active!.asset.tracks
          .expand((t) => t.clips)
          .whereType<PresentationTextClip>()
          .single;
      if (mode == 'scale') {
        expect(text.from.scaleX, isNot(1));
        expect(text.from.scaleY, text.from.scaleX);
        expect(text.from.translateX, 0);
      } else {
        expect(text.from.rotationTurns, isNot(0));
        expect(text.from.translateX, 0);
      }
      expect(view.selectedId, 'title.clip');
      await harness.capture(tester, 'ui11-02-title-$mode-transformed');
      await tapUi11(tester, harness, find.byTooltip('Annuler'));
      expect(controller.active!.asset, before);
      expect(controller.canUndo, isFalse);
      final cancelled = await tester.startGesture(origin);
      await cancelled.moveBy(const Offset(48, 0));
      await tester.pump();
      await cancelled.moveBy(const Offset(30, 30));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await cancelled.up();
      await harness.settle(tester);
      expect(controller.active!.asset, before);
      expect(controller.canUndo, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
