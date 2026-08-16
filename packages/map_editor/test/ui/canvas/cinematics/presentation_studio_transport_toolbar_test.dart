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
    expect(controller.playheadUs, inInclusiveRange(600_000, 650_000));

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(controller.status, PresentationPlaybackStatus.paused);
    final pausedPlayheadUs = controller.playheadUs;

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.playheadUs, pausedPlayheadUs + 33_333);

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(controller.playheadUs, 0);
  });

  testWidgets('space toggles playback while another Studio control has focus', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 2_000_000,
    );
    final workspaceFocusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(workspaceFocusNode.dispose);
    await _pumpToolbar(
      tester,
      controller,
      leading: Focus(
        focusNode: workspaceFocusNode,
        child: const SizedBox(width: 32, height: 32),
      ),
    );

    workspaceFocusNode.requestFocus();
    await tester.pump();
    expect(workspaceFocusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(controller.status, PresentationPlaybackStatus.playing);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(controller.status, PresentationPlaybackStatus.paused);
  });

  testWidgets('space remains available while editing text', (tester) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 2_000_000,
    );
    final textFocusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(textFocusNode.dispose);
    await _pumpToolbar(
      tester,
      controller,
      leading: TextField(focusNode: textFocusNode),
    );

    textFocusNode.requestFocus();
    await tester.pump();
    expect(textFocusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(controller.status, PresentationPlaybackStatus.ready);
  });

  testWidgets('temporal counter keeps a stable width during playback', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 12_000_000,
    );
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    final slot = find.byKey(presentationStudioTemporalStatusSlotKey);
    expect(slot, findsOneWidget);
    final initialWidth = tester.getSize(slot).width;
    expect(initialWidth, 176);

    await tester.tap(find.byKey(presentationStudioPlayPauseKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 7783));

    expect(tester.getSize(slot).width, initialWidth);
  });

  testWidgets('temporal counter contains the maximum supported duration', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 900_000_000,
    );
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    final counterText = find.descendant(
      of: find.byKey(presentationStudioTemporalStatusSlotKey),
      matching: find.byType(Text),
    );
    expect(counterText, findsOneWidget);
    expect(find.text('00:00.000 / 15:00.000'), findsOneWidget);
    final text = tester.widget<Text>(counterText);
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
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
  PresentationStudioResponsiveCanvasController controller, {
  Widget? leading,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) SizedBox(width: 240, child: leading),
            PresentationStudioResponsiveToolbar(controller: controller),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}
