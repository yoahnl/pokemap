import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_responsive_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('toolbar drives play, pause, frame steps, loop and stop', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 2_000_000,
    );
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    await tester.tap(find.byKey(presentationStudioPlayPauseKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(controller.status, PresentationPlaybackStatus.playing);
    expect(controller.playheadUs, 250_000);

    await tester.tap(find.byKey(presentationStudioPlayPauseKey));
    await tester.pump(const Duration(milliseconds: 250));

    expect(controller.status, PresentationPlaybackStatus.paused);
    expect(controller.playheadUs, 250_000);

    await tester.tap(find.byKey(presentationStudioFrameForwardKey));
    await tester.pump();
    expect(controller.playheadUs, 283_333);

    await tester.tap(find.byKey(presentationStudioFrameBackwardKey));
    await tester.pump();
    expect(controller.playheadUs, 250_000);

    await tester.tap(find.byKey(presentationStudioLoopKey));
    await tester.pump();
    expect(controller.loop, isTrue);

    await tester.tap(find.byKey(presentationStudioStopKey));
    await tester.pump();
    expect(controller.status, PresentationPlaybackStatus.ready);
    expect(controller.playheadUs, 0);
  });

  testWidgets('desktop shortcuts control the focused temporal preview', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 2_000_000,
      playheadUs: 500_000,
    );
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    await tester.tap(find.byKey(presentationStudioTransportShortcutsKey));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.status, PresentationPlaybackStatus.playing);
    expect(controller.playheadUs, 600_000);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(controller.status, PresentationPlaybackStatus.paused);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.playheadUs, 633_333);

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(controller.playheadUs, 0);
  });

  testWidgets('loading and error states disable incoherent transports', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 2_000_000,
    );
    addTearDown(controller.dispose);
    controller.setLoading();
    await _pumpToolbar(tester, controller);

    expect(
      tester
          .widget<PokeMapIconButton>(find.byKey(presentationStudioPlayPauseKey))
          .onPressed,
      isNull,
    );
    expect(find.text('Chargement de l’aperçu'), findsOneWidget);

    controller.setError();
    await tester.pump();

    expect(
      tester
          .widget<PokeMapIconButton>(find.byKey(presentationStudioPlayPauseKey))
          .onPressed,
      isNull,
    );
    expect(find.text('Aperçu indisponible'), findsOneWidget);
  });

  testWidgets('interaction hold is distinct from a true pause', (tester) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 2_000_000,
    );
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    controller.play();
    controller.holdForInteraction();
    await tester.pump();

    expect(find.text('Interaction en attente'), findsOneWidget);
    expect(
      controller.mediaClockPolicy,
      PresentationMediaClockPolicy.continueAmbient,
    );

    await tester.tap(find.byKey(presentationStudioPlayPauseKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.status, PresentationPlaybackStatus.playing);
    expect(controller.playheadUs, 100_000);
  });

  testWidgets('route disposal cancels the ticker and ignores late frames', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 2_000_000,
    );
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    await tester.tap(find.byKey(presentationStudioPlayPauseKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.playheadUs, 100_000);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(controller.playheadUs, 100_000);
  });

  testWidgets('app lifecycle pause freezes narrative and media clocks', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 2_000_000,
    );
    addTearDown(controller.dispose);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await _pumpToolbar(tester, controller);

    await tester.tap(find.byKey(presentationStudioPlayPauseKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 1));

    expect(controller.status, PresentationPlaybackStatus.paused);
    expect(controller.playheadUs, 100_000);
    expect(controller.mediaClockPolicy, PresentationMediaClockPolicy.paused);
  });
}

Future<void> _pumpToolbar(
  WidgetTester tester,
  PresentationStudioResponsiveCanvasController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: PresentationStudioResponsiveToolbar(controller: controller),
        ),
      ),
    ),
  );
  await tester.pump();
}
