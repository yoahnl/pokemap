import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('tap never moves and reports its original pointer and position', () {
    final driver = RuntimePlayerFloatingTouchDriver();
    expect(driver.begin(4, const Offset(20, 30)), isTrue);
    expect(driver.update(4, const Offset(23, 31)), isEmpty);
    expect(driver.end(4), isEmpty);
    expect(driver.takeTapCandidate(),
        (position: const Offset(23, 31), pointer: 4));
  });

  test('drag captures permanently, deduplicates and ignores later pointers',
      () {
    final driver = RuntimePlayerFloatingTouchDriver();
    driver.begin(4, const Offset(20, 30));
    expect(driver.begin(5, const Offset(90, 30)), isFalse);
    expect(driver.update(5, const Offset(190, 30)), isEmpty);
    expect(driver.update(4, const Offset(50, 30)),
        const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
    expect(driver.update(4, const Offset(60, 30)), isEmpty);
    expect(driver.end(5), isEmpty);
    expect(driver.update(4, const Offset(20, 30)),
        const [RuntimeInputEvent.release(RuntimeInputControl.right)]);
    expect(driver.end(4), isEmpty);
    expect(driver.takeTapCandidate(), isNull);
  });

  test('diagonal jitter holds direction until the perpendicular axis wins', () {
    final driver = RuntimePlayerFloatingTouchDriver();
    driver.begin(1, Offset.zero);
    expect(driver.update(1, const Offset(30, 29)),
        const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
    expect(driver.update(1, const Offset(29, 30)), isEmpty);
    expect(driver.update(1, const Offset(28, 40)), const [
      RuntimeInputEvent.release(RuntimeInputControl.right),
      RuntimeInputEvent.press(RuntimeInputControl.down),
    ]);
    expect(driver.cancel(),
        const [RuntimeInputEvent.release(RuntimeInputControl.down)]);
    expect(driver.cancel(), isEmpty);
    expect(driver.takeTapCandidate(), isNull);
  });

  testWidgets('viewport mask passes UI and bands through and captures a drag',
      (tester) async {
    final events = <RuntimeInputEvent>[];
    final taps = <Offset>[];
    var recognized = 0;
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Stack(children: [
          Positioned.fill(
              child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => taps.add(event.localPosition))),
          Positioned.fill(
              child: RuntimePlayerTouchControls(
            dispatch: events.add,
            readGameplayViewport: () => const Rect.fromLTRB(100, 50, 700, 550),
            readExcludedRects: () => [const Rect.fromLTRB(200, 350, 270, 420)],
            onMovementGesture: () => recognized++,
          )),
        ])));
    for (final origin in [
      const Offset(50, 400),
      const Offset(220, 370),
      const Offset(150, 100)
    ]) {
      final pointer =
          await tester.startGesture(origin, kind: ui.PointerDeviceKind.touch);
      await pointer.moveTo(const Offset(300, 440));
      await pointer.up();
    }
    expect(taps, hasLength(3));
    expect(events, isEmpty);
    final pointer = await tester.startGesture(const Offset(110, 450),
        kind: ui.PointerDeviceKind.touch);
    await tester.pump();
    expect(events, isEmpty);
    final visual = tester.widget<PlayerOverworldJoystickVisual>(
        find.byType(PlayerOverworldJoystickVisual));
    expect(visual.anchor.dx, greaterThan(110));
    await pointer.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(events, const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
    expect(recognized, 1);
    await pointer.moveTo(const Offset(790, 450));
    await pointer.cancel();
    expect(events.last,
        const RuntimeInputEvent.release(RuntimeInputControl.right));
  });

  testWidgets('hardware switch cancels held pointer until a fresh drag',
      (tester) async {
    final events = <RuntimeInputEvent>[];
    var show = true;
    late StateSetter rebuild;
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: StatefulBuilder(builder: (context, setState) {
          rebuild = setState;
          return RuntimePlayerTouchControls(
              showControls: show,
              dispatch: events.add,
              readGameplayViewport: () => const Rect.fromLTWH(0, 0, 800, 600));
        })));
    final pointer = await tester.startGesture(const Offset(100, 400),
        kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(50, 0));
    await tester.pump();
    rebuild(() => show = false);
    await tester.pump();
    expect(events.last,
        const RuntimeInputEvent.release(RuntimeInputControl.right));
    await pointer.moveBy(const Offset(80, 0));
    await pointer.up();
    expect(events, hasLength(2));
    final fresh = await tester.startGesture(const Offset(100, 400),
        kind: ui.PointerDeviceKind.touch);
    expect(events, hasLength(2));
    await fresh.moveBy(const Offset(50, 0));
    expect(
        events.last, const RuntimeInputEvent.press(RuntimeInputControl.right));
    await fresh.up();
  });
  testWidgets('cancellation source invalidates a pending hardware-mode pointer',
      (tester) async {
    final cancellation = ChangeNotifier();
    final events = <RuntimeInputEvent>[];
    addTearDown(cancellation.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: RuntimePlayerTouchControls(
            showControls: false,
            dispatch: events.add,
            cancellationSignal: cancellation,
            readGameplayViewport: () => const Rect.fromLTWH(0, 0, 800, 600))));
    final pointer = await tester.startGesture(const Offset(100, 400),
        kind: ui.PointerDeviceKind.touch);
    cancellation.notifyListeners();
    await pointer.moveBy(const Offset(50, 0));
    await pointer.up();
    expect(events, isEmpty);
  });

  testWidgets('safe area and mirrored zone exclude asymmetric viewport bands',
      (tester) async {
    final events = <RuntimeInputEvent>[];
    final passed = <Offset>[];
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: MediaQuery(
            data: const MediaQueryData(
                padding: EdgeInsets.fromLTRB(130, 70, 30, 90)),
            child: Stack(children: [
              Positioned.fill(
                  child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) =>
                          passed.add(event.localPosition))),
              Positioned.fill(
                  child: RuntimePlayerTouchControls(
                      leftHanded: true,
                      dispatch: events.add,
                      readGameplayViewport: () =>
                          const Rect.fromLTRB(100, 40, 790, 560))),
            ]))));
    for (final origin in [
      const Offset(115, 400),
      const Offset(785, 400),
      const Offset(650, 530),
      const Offset(300, 400)
    ]) {
      final pointer =
          await tester.startGesture(origin, kind: ui.PointerDeviceKind.touch);
      await pointer.moveBy(const Offset(40, 0));
      await pointer.up();
    }
    expect(passed, hasLength(4));
    expect(events, isEmpty);
    final pointer = await tester.startGesture(const Offset(650, 400),
        kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(40, 0));
    expect(events.single,
        const RuntimeInputEvent.press(RuntimeInputControl.right));
    await pointer.up();
  });

  testWidgets(
      'viewport mutation orientation and disposal release the captured direction',
      (tester) async {
    final events = <RuntimeInputEvent>[];
    var viewport = const Rect.fromLTWH(0, 0, 800, 600);
    late StateSetter rebuild;
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: StatefulBuilder(builder: (context, setState) {
          rebuild = setState;
          return RuntimePlayerTouchControls(
              dispatch: events.add, readGameplayViewport: () => viewport);
        })));
    final pointer = await tester.startGesture(const Offset(100, 400),
        kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(40, 0));
    rebuild(() => viewport = const Rect.fromLTRB(50, 0, 800, 600));
    await tester.pump();
    expect(events.last,
        const RuntimeInputEvent.release(RuntimeInputControl.right));
    await pointer.moveBy(const Offset(40, 0));
    await pointer.up();
    expect(events, hasLength(2));
    final next = await tester.startGesture(const Offset(100, 400),
        kind: ui.PointerDeviceKind.touch);
    await next.moveBy(const Offset(40, 0));
    tester.binding.handleMetricsChanged();
    expect(events.last,
        const RuntimeInputEvent.release(RuntimeInputControl.right));
    await next.up();
    final last = await tester.startGesture(const Offset(100, 400),
        kind: ui.PointerDeviceKind.touch);
    await last.moveBy(const Offset(40, 0));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(events.last,
        const RuntimeInputEvent.release(RuntimeInputControl.right));
    expect(events, hasLength(6));
    await last.up();
  });

  testWidgets(
      'second pointer activates UI while the first keeps movement ownership',
      (tester) async {
    final events = <RuntimeInputEvent>[];
    var menu = 0;
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Stack(children: [
          Positioned(
              left: 200,
              top: 350,
              width: 60,
              height: 60,
              child: GestureDetector(
                  onTap: () => menu++, behavior: HitTestBehavior.opaque)),
          Positioned.fill(
              child: RuntimePlayerTouchControls(
                  dispatch: events.add,
                  readGameplayViewport: () =>
                      const Rect.fromLTWH(0, 0, 800, 600),
                  readExcludedRects: () =>
                      [const Rect.fromLTWH(200, 350, 60, 60)])),
        ])));
    final first = await tester.startGesture(const Offset(100, 400),
        pointer: 1, kind: ui.PointerDeviceKind.touch);
    await first.moveBy(const Offset(40, 0));
    final second = await tester.startGesture(const Offset(220, 370),
        pointer: 2, kind: ui.PointerDeviceKind.touch);
    await second.up();
    expect(menu, 1);
    expect(events, const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
    final third = await tester.startGesture(const Offset(300, 400),
        pointer: 3, kind: ui.PointerDeviceKind.touch);
    await third.moveBy(const Offset(-60, 0));
    await third.up();
    expect(events, hasLength(1));
    await first.up();
    expect(events.last,
        const RuntimeInputEvent.release(RuntimeInputControl.right));
  });

  testWidgets('absent viewport never captures and release cannot begin a drag',
      (tester) async {
    final events = <RuntimeInputEvent>[];
    final candidates = <RuntimePlayerTouchTapCandidate>[];
    var viewportAvailable = false;
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: RuntimePlayerTouchControls(
            dispatch: events.add,
            onTapCandidate: candidates.add,
            readGameplayViewport: () => viewportAvailable
                ? const Rect.fromLTWH(0, 0, 800, 600)
                : null)));
    final outside = await tester.startGesture(const Offset(100, 400),
        kind: ui.PointerDeviceKind.touch);
    viewportAvailable = true;
    await outside.moveBy(const Offset(40, 0));
    await outside.up();
    expect(events, isEmpty);
    expect(candidates, isEmpty);
    final pointer = await tester.createGesture(
        pointer: 9, kind: ui.PointerDeviceKind.touch);
    await pointer.down(const Offset(100, 400));
    await pointer.up();
    expect(events, isEmpty);
    expect(candidates.single.pointer, 9);
  });
  testWidgets('app suspension cancels a held drag without replay on resume',
      (tester) async {
    final events = <RuntimeInputEvent>[];
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: RuntimePlayerTouchControls(
            dispatch: events.add,
            readGameplayViewport: () => const Rect.fromLTWH(0, 0, 800, 600))));
    final pointer = await tester.startGesture(const Offset(100, 400),
        kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(50, 0));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(events.last,
        const RuntimeInputEvent.release(RuntimeInputControl.right));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pointer.moveBy(const Offset(50, 0));
    await pointer.up();
    expect(events, hasLength(2));
  });

  testWidgets('small viewport clips the visual without changing drag origin',
      (tester) async {
    final events = <RuntimeInputEvent>[];
    const viewport = Rect.fromLTWH(100, 300, 140, 100);
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: RuntimePlayerTouchControls(
            dispatch: events.add, readGameplayViewport: () => viewport)));
    final pointer = await tester.startGesture(const Offset(120, 380),
        kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(30, 0));
    await tester.pump();
    final clip = tester.widget<ClipRect>(
        find.byKey(const ValueKey('runtime-player-touch-viewport-clip')));
    expect(clip.clipper!.getClip(const Size(800, 600)), viewport);
    expect(clip.clipBehavior, Clip.hardEdge);
    expect(events.single,
        const RuntimeInputEvent.press(RuntimeInputControl.right));
    await pointer.up();
  });

  testWidgets('opaque accessibility keeps the joystick fully opaque',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: PlayerMenuEffectsScope(
            effects: RuntimePlayerMenuEffects.opaque,
            child: RuntimePlayerTouchControls(
                dispatch: (_) {},
                opacity: .45,
                readGameplayViewport: () =>
                    const Rect.fromLTWH(0, 0, 800, 600)))));
    final pointer = await tester.startGesture(const Offset(100, 400),
        kind: ui.PointerDeviceKind.touch);
    await tester.pump();
    expect(
        tester
            .widget<Opacity>(find
                .byKey(const ValueKey('runtime-player-touch-controls-opacity')))
            .opacity,
        1);
    await pointer.up();
  });
}
