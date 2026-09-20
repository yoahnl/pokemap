import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/m2_ui_fixture.dart';
import 'support/ui10_workspace_harness.dart';
import 'support/ui10_cinematic_fixture.dart';

void main() {
  testWidgets(
    'UI10 full Studio frame early composition with isolated real project',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = (await tester.runAsync(
        () => Ui10WorkspaceHarness.create(tester),
      ))!;
      await tester.pumpWidget(harness.app());
      await pumpIo(tester);
      await harness.open(tester);
      final controller = harness.page(tester).controller;
      expect(controller.active, isNotNull);
      expect(
        find.byKey(const ValueKey('cinematic-map-viewport')),
        findsOneWidget,
      );
      await harness.capture(tester, 'ui10-01-early-composition');
      await tester.tap(find.byKey(const ValueKey('cinematic-clip-walk')));
      await tester.pump();
      await harness.capture(tester, 'ui10-01-final-selected-move');
      await tester.tap(find.text('Prévisualiser'));
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        controller.transport.playing,
        isTrue,
        reason: 'actual preview button starts transport',
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 700)),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(controller.transport.timeMs, greaterThan(400));
      controller.transport.pause();
      final authored = controller.active!.asset.toJson();
      final reads = harness.port.reads;
      final scale = harness
          .page(tester)
          .views
          .forAsset(ui10CinematicId)
          .timelineScale;
      final ruler = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('cinematic-timeline-ruler')),
      );
      for (final entry in [
        (1100, 'movement'),
        (2050, 'camera'),
        (2600, 'fade'),
      ]) {
        await tester.tapAt(ruler.localToGlobal(Offset(entry.$1 * scale, 10)));
        await tester.pump();
        expect(controller.transport.timeMs, closeTo(entry.$1, 1));
        if (entry.$2 == 'movement') {
          final actor = controller.transport.frame!.actorPoses.singleWhere(
            (p) => p.actorId == 'hero',
          );
          expect(actor.x, allOf(greaterThan(8), lessThan(13)));
        }
        await harness.capture(tester, 'ui10-preview-${entry.$2}');
      }
      await tester.tap(find.byTooltip('Arrêter et revenir au début'));
      await tester.pump();
      expect(controller.transport.timeMs, 0);
      await harness.capture(tester, 'ui10-preview-stopped');
      await tester.tap(find.byKey(const ValueKey('cinematic-clip-camera')));
      await tester.pump();
      await harness.capture(tester, 'ui10-inspector-camera');
      expect(controller.active!.asset.toJson(), authored);
      expect(harness.port.reads, reads);
      expect(harness.port.writes, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(harness.dispose);
    },
  );
}
