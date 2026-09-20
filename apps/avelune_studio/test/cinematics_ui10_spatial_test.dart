import 'package:avelune_studio/presentation/features/cinematics/cinematic_workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/m2_ui_fixture.dart';
import 'support/ui10_cinematic_fixture.dart';
import 'support/ui10_workspace_harness.dart';

void main() {
  for (final tileSize in [16, 32]) {
    testWidgets(
      'UI10 destination uses $tileSize pixel cells after actual zoom pan and publication',
      (tester) async {
        tester.view.physicalSize = const Size(1536, 1024);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final harness = (await tester.runAsync(
          () => Ui10WorkspaceHarness.create(tester, tileSize: tileSize),
        ))!;
        await tester.pumpWidget(harness.app());
        await pumpIo(tester);
        await harness.open(tester);
        final mapBefore = (await tester.runAsync(harness.workspace.mapBytes))!;
        final controller = harness.page(tester).controller;
        final before = controller.active!.asset;
        await tester.tap(find.byKey(const ValueKey('cinematic-clip-walk')));
        await tester.pump();
        await tester.tap(find.byTooltip('Agrandir la carte'));
        await tester.pump();
        await tester.tap(find.byTooltip('Déplacer la vue'));
        await tester.pump();
        await tester.drag(
          find.byKey(const ValueKey('cinematic-map-viewport')),
          const Offset(25, 18),
        );
        await tester.pump();
        expect(
          harness.page(tester).views.forAsset(ui10CinematicId).selection,
          contains('walk'),
        );
        final button = find.text('Choisir la destination');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
        final box = tester.renderObject<RenderBox>(
          find.byKey(const ValueKey('cinematic-map-pick')),
        );
        await tester.tapAt(
          box.localToGlobal(Offset(tileSize * 12.4, tileSize * 10.4)),
        );
        await tester.pump();
        final changed = controller.active!.asset;
        final target = changed.timeline.steps
            .singleWhere((s) => s.id == 'walk')
            .targetId;
        final binding = changed.stageContext!.movementTargetBindings
            .singleWhere((b) => b.targetId == target);
        final point = changed.stageContext!.stagePoints.singleWhere(
          (p) => p.id == binding.sourceId,
        );
        expect((point.x, point.y), (12, 10));
        expect(
          changed.stageContext!.stagePoints
              .singleWhere((p) => p.id == 'arrival')
              .x,
          13,
        );
        expect(controller.active!.dirty, isTrue);
        controller.undo();
        await tester.pump();
        expect(controller.active!.asset.toJson(), before.toJson());
        controller.redo();
        await tester.pump();
        await harness.capture(tester, 'ui10-02-destination-$tileSize');
        await tester.tap(
          find
              .descendant(
                of: find.byType(CinematicWorkspacePage),
                matching: find.text('Enregistrer'),
              )
              .first,
        );
        await pumpIo(tester, frames: 25);
        expect(controller.error, isNull);
        expect(controller.active!.dirty, isFalse);
        expect(harness.port.writes, 1);
        final reopened = (await tester.runAsync(
          () => harness.port.delegate.load(ui10CinematicId),
        ))!;
        expect(reopened.asset.toJson(), changed.toJson());
        expect(await tester.runAsync(harness.workspace.mapBytes), mapBefore);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(harness.dispose);
      },
    );
  }
}
