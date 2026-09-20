import 'package:avelune_studio/features/cinematics/data/local_cinematic_adapter.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_playback_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/m2_ui_fixture.dart';
import 'support/capture_m3_widget.dart';
import 'support/ui08_workspace_harness.dart';
import 'support/ui10_cinematic_fixture.dart';
import 'support/ui10_parity_fixture.dart';
import 'support/ui10_widget_port.dart';
import 'support/ui10_workspace_harness.dart';

void main() {
  testWidgets(
    'preview camera zoom shake fade uses playback transform and Stop restores author view',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = (await tester.runAsync(() async {
        final fixture = await createUi10ParityFixture(tileHeight: 24);
        final workspace = await Ui08WorkspaceHarness.create(
          tester,
          fixture: fixture,
        );
        final map = await fixture.maps.loadMap(
          fixture.session,
          workspace.maps.project!.maps.first,
        );
        workspace.visuals.setActiveMap(map.map);
        await workspace.visuals.settled;
        return Ui10WorkspaceHarness(
          workspace,
          Ui10WidgetPort(
            LocalCinematicAdapter(
              session: fixture.session,
              mapAdapter: fixture.maps,
            ),
            tester,
          ),
        );
      }))!;
      await tester.pumpWidget(harness.app());
      await pumpIo(tester);
      await harness.open(tester);
      final page = harness.page(tester);
      final view = page.views.forAsset(ui10CinematicId);
      final authored = page.controller.active!.asset.toJson();
      final work = view.mapTransform.value.clone();
      final frames = <int, Matrix4>{};
      for (final ms in [0, 1000, 1950, 2450, 3200, 3749]) {
        page.controller.transport.seek(ms);
        await tester.pump();
        expect(find.byType(CinematicPlaybackViewport), findsOneWidget);
        final transform = tester.widget<Transform>(
          find.byKey(const ValueKey('cinematic-runtime-transform')),
        );
        frames[ms] = transform.transform.clone();
        final fade = tester.widget<ColoredBox>(
          find.byKey(const ValueKey('cinematic-preview-fade')),
        );
        expect(fade.color.a, ms < 2900 ? 0 : greaterThan(0));
        if (ms == 3749) expect(fade.color.a, 1);
        expect(view.mapTransform.value, work);
        await harness.capture(tester, 'parity-studio-$ms');
        final originalViewport = tester.widget<CinematicPlaybackViewport>(
          find.byType(CinematicPlaybackViewport),
        );
        final key = GlobalKey();
        final overlay = Overlay.of(
          tester.element(find.byType(CinematicPlaybackViewport)),
        );
        final entry = OverlayEntry(
          builder: (_) => Center(
            child: SizedBox(
              width: 960,
              height: 640,
              child: RepaintBoundary(
                key: key,
                child: CinematicPlaybackViewport(
                  model: originalViewport.model,
                  transport: originalViewport.transport,
                  viewport: const Size(960, 640),
                  cell: originalViewport.cell,
                  child: originalViewport.child,
                ),
              ),
            ),
          ),
        );
        overlay.insert(entry);
        await tester.pump();
        await pumpIo(tester, frames: 3);
        await captureM3Widget(tester, key, 'parity-preview-$ms');
        entry.remove();
        entry.dispose();
        await tester.pump();
      }
      expect(frames[1950], isNot(frames[0]));
      expect(frames[2450], isNot(frames[1950]));
      await tester.tap(find.byTooltip('Arrêter et revenir au début'));
      await tester.pump();
      expect(page.controller.transport.timeMs, 0);
      expect(find.byType(CinematicPlaybackViewport), findsNothing);
      expect(view.mapTransform.value, work);
      expect(page.controller.active!.asset.toJson(), authored);
      expect(harness.port.writes, 0);
      expect(tester.takeException(), isNull);
      await harness.capture(tester, 'parity-studio-stopped');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(harness.dispose);
    },
  );
}
