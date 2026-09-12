import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  const request = RuntimeOverworldInteractionRequest(
      sessionId: 'session',
      mapActivationId: 'activation',
      mapId: 'map',
      targetKind: RuntimeOverworldInteractionTargetKind.entity,
      targetId: 'npc',
      actionId: 'talk');

  testWidgets('world tap captures its visible target outside the movement zone',
      (tester) async {
    final taps = <RuntimeOverworldInteractionRequest>[];
    final movement = <RuntimeInputEvent>[];
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: RuntimePlayerTouchControls(
            dispatch: movement.add,
            readGameplayViewport: () => const Rect.fromLTRB(100, 50, 700, 550),
            resolveTapTarget: (position) =>
                const Rect.fromLTWH(500, 70, 80, 80).contains(position)
                    ? request
                    : null,
            onTap: taps.add)));
    final pointer = await tester.startGesture(const Offset(530, 100),
        kind: ui.PointerDeviceKind.touch);
    expect(taps, isEmpty);
    await pointer.up();
    expect(taps, [request]);
    expect(movement, isEmpty);
    expect(find.byKey(const ValueKey('runtime-player-touch-primary-button')),
        findsNothing);
    expect(find.byKey(const ValueKey('runtime-player-touch-secondary-button')),
        findsNothing);
  });

  testWidgets(
      'drag returning to its origin and targets appearing after down never tap',
      (tester) async {
    final taps = <RuntimeOverworldInteractionRequest>[];
    var targetVisible = true;
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: RuntimePlayerTouchControls(
            dispatch: (_) {},
            readGameplayViewport: () => const Rect.fromLTWH(0, 0, 800, 600),
            resolveTapTarget: (_) => targetVisible ? request : null,
            onTap: taps.add)));
    final drag = await tester.startGesture(const Offset(600, 100),
        kind: ui.PointerDeviceKind.touch);
    await drag.moveBy(const Offset(12, 0));
    await drag.moveTo(const Offset(600, 100));
    await drag.up();
    expect(taps, isEmpty);
    targetVisible = false;
    final stale = await tester.startGesture(const Offset(600, 100),
        kind: ui.PointerDeviceKind.touch);
    targetVisible = true;
    await stale.up();
    expect(taps, isEmpty);
  });

  testWidgets('second world tap leaves the first joystick pointer held',
      (tester) async {
    final taps = <RuntimeOverworldInteractionRequest>[];
    final movement = <RuntimeInputEvent>[];
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: RuntimePlayerTouchControls(
            dispatch: movement.add,
            readGameplayViewport: () => const Rect.fromLTWH(0, 0, 800, 600),
            resolveTapTarget: (position) => position.dx > 500 ? request : null,
            onTap: taps.add)));
    final joystick = await tester.startGesture(const Offset(100, 400),
        pointer: 1, kind: ui.PointerDeviceKind.touch);
    await joystick.moveBy(const Offset(30, 0));
    final action = await tester.startGesture(const Offset(600, 100),
        pointer: 2, kind: ui.PointerDeviceKind.touch);
    await action.up();
    expect(taps, [request]);
    expect(
        movement, const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
    await joystick.up();
    expect(movement.last,
        const RuntimeInputEvent.release(RuntimeInputControl.right));
  });

  testWidgets(
      'target A to B to A invalidates a tap immediately and preserves joystick',
      (tester) async {
    const other = RuntimeOverworldInteractionRequest(
        sessionId: 'session',
        mapActivationId: 'activation',
        mapId: 'map',
        targetKind: RuntimeOverworldInteractionTargetKind.entity,
        targetId: 'other',
        actionId: 'talk');
    RuntimeOverworldInteractionSnapshot snapshot(
            RuntimeOverworldInteractionRequest request) =>
        RuntimeOverworldInteractionSnapshot(
            sessionId: request.sessionId,
            mapActivationId: request.mapActivationId,
            mapId: request.mapId,
            primaryAction: RuntimeOverworldInteractionAction(
                request: request,
                verb: RuntimeOverworldInteractionVerb.talk,
                targetCell: const GridPos(x: 1, y: 1),
                targetBounds: const PixelRect(
                    leftPx: 20, topPx: 20, widthPx: 32, heightPx: 32)));
    final interaction = ValueNotifier(snapshot(request));
    addTearDown(interaction.dispose);
    final taps = <RuntimeOverworldInteractionRequest>[];
    final movement = <RuntimeInputEvent>[];
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: RuntimePlayerTouchControls(
            dispatch: movement.add,
            interactionChanges: interaction,
            readGameplayViewport: () => const Rect.fromLTWH(0, 0, 800, 600),
            resolveTapTarget: (_) => interaction.value.primaryAction?.request,
            onTap: taps.add)));
    final joystick = await tester.startGesture(const Offset(100, 400),
        pointer: 1, kind: ui.PointerDeviceKind.touch);
    await joystick.moveBy(const Offset(30, 0));
    final action = await tester.startGesture(const Offset(600, 100),
        pointer: 2, kind: ui.PointerDeviceKind.touch);
    interaction.value = snapshot(other);
    interaction.value = snapshot(request);
    await action.up();
    expect(taps, isEmpty);
    expect(
        movement, const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
    interaction.value = const RuntimeOverworldInteractionSnapshot(
        sessionId: 'session',
        mapActivationId: 'other-activation',
        mapId: 'map');
    expect(movement.last,
        const RuntimeInputEvent.release(RuntimeInputControl.right));
    await joystick.moveBy(const Offset(30, 0));
    await joystick.up();
    expect(movement, hasLength(2));
  });

  testWidgets('tap target change and viewport mutation reject pending actions',
      (tester) async {
    var available = true;
    var viewport = const Rect.fromLTWH(0, 0, 800, 600);
    final taps = <RuntimeOverworldInteractionRequest>[];
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: RuntimePlayerTouchControls(
            dispatch: (_) {},
            readGameplayViewport: () => viewport,
            resolveTapTarget: (_) => available ? request : null,
            onTap: taps.add)));
    final changedTarget = await tester.startGesture(const Offset(600, 100),
        kind: ui.PointerDeviceKind.touch);
    available = false;
    await changedTarget.up();
    expect(taps, isEmpty);
    available = true;
    final changedViewport = await tester.startGesture(const Offset(600, 100),
        kind: ui.PointerDeviceKind.touch);
    viewport = const Rect.fromLTRB(100, 0, 800, 600);
    await changedViewport.up();
    expect(taps, isEmpty);
  });

  testWidgets('first tap after hardware survives visual source activation once',
      (tester) async {
    var show = false;
    late StateSetter rebuild;
    final taps = <RuntimeOverworldInteractionRequest>[];
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: StatefulBuilder(builder: (context, setState) {
          rebuild = setState;
          return RuntimePlayerTouchControls(
              dispatch: (_) {},
              showControls: show,
              readGameplayViewport: () => const Rect.fromLTWH(0, 0, 800, 600),
              resolveTapTarget: (_) => request,
              onTap: taps.add);
        })));
    final action = await tester.startGesture(const Offset(600, 100),
        kind: ui.PointerDeviceKind.touch);
    rebuild(() => show = true);
    await tester.pump();
    await action.up();
    expect(taps, [request]);
  });

  testWidgets('bands safe insets and excluded UI never capture a world action',
      (tester) async {
    final taps = <RuntimeOverworldInteractionRequest>[];
    final passed = <Offset>[];
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: MediaQuery(
            data: const MediaQueryData(
                padding: EdgeInsets.fromLTRB(100, 80, 40, 60)),
            child: Stack(children: [
              Positioned.fill(
                  child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) =>
                          passed.add(event.localPosition))),
              Positioned.fill(
                  child: RuntimePlayerTouchControls(
                      dispatch: (_) {},
                      readGameplayViewport: () =>
                          const Rect.fromLTRB(70, 50, 780, 580),
                      readExcludedRects: () =>
                          [const Rect.fromLTWH(500, 100, 80, 60)],
                      resolveTapTarget: (_) => request,
                      onTap: taps.add)),
            ]))));
    for (final point in [
      const Offset(90, 100),
      const Offset(200, 60),
      const Offset(770, 400),
      const Offset(500, 550),
      const Offset(520, 120)
    ]) {
      final pointer =
          await tester.startGesture(point, kind: ui.PointerDeviceKind.touch);
      await pointer.up();
    }
    expect(passed, hasLength(5));
    expect(taps, isEmpty);
  });

  testWidgets(
      'world taps are cancelled by source lifecycle and pointer cancellation',
      (tester) async {
    final cancellation = ChangeNotifier();
    addTearDown(cancellation.dispose);
    final taps = <RuntimeOverworldInteractionRequest>[];
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: RuntimePlayerTouchControls(
            dispatch: (_) {},
            cancellationSignal: cancellation,
            readGameplayViewport: () => const Rect.fromLTWH(0, 0, 800, 600),
            resolveTapTarget: (_) => request,
            onTap: taps.add)));
    final source = await tester.startGesture(const Offset(600, 100),
        kind: ui.PointerDeviceKind.touch);
    cancellation.notifyListeners();
    await source.up();
    final background = await tester.startGesture(const Offset(600, 100),
        kind: ui.PointerDeviceKind.touch);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await background.up();
    final cancelled = await tester.startGesture(const Offset(600, 100),
        kind: ui.PointerDeviceKind.touch);
    await cancelled.cancel();
    expect(taps, isEmpty);
    final fresh = await tester.startGesture(const Offset(600, 100),
        kind: ui.PointerDeviceKind.touch);
    await fresh.up();
    expect(taps, [request]);
  });

  testWidgets(
      'cancelled secondary world pointer never cancels joystick ownership',
      (tester) async {
    final events = <RuntimeInputEvent>[];
    final taps = <RuntimeOverworldInteractionRequest>[];
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: RuntimePlayerTouchControls(
            dispatch: events.add,
            readGameplayViewport: () => const Rect.fromLTWH(0, 0, 800, 600),
            resolveTapTarget: (_) => request,
            onTap: taps.add)));
    final joystick = await tester.startGesture(const Offset(100, 400),
        pointer: 1, kind: ui.PointerDeviceKind.touch);
    await joystick.moveBy(const Offset(30, 0));
    final cancelled = await tester.startGesture(const Offset(600, 100),
        pointer: 2, kind: ui.PointerDeviceKind.touch);
    await cancelled.cancel();
    expect(events, const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
    expect(taps, isEmpty);
    await joystick.up();
    expect(events.last,
        const RuntimeInputEvent.release(RuntimeInputControl.right));
  });

  test('gesture sprint uses real origin thresholds and directional hysteresis',
      () {
    final driver = RuntimePlayerFloatingTouchDriver(sprintAllowed: true);
    driver.begin(1, const Offset(100, 400));
    expect(driver.update(1, const Offset(141, 400)),
        const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
    expect(driver.update(1, const Offset(142, 400)),
        const [RuntimeInputEvent.press(RuntimeInputControl.sprint)]);
    expect(driver.update(1, const Offset(140, 400)), isEmpty);
    expect(driver.update(1, const Offset(100, 440)), const [
      RuntimeInputEvent.release(RuntimeInputControl.right),
      RuntimeInputEvent.press(RuntimeInputControl.down),
    ]);
    expect(driver.update(1, const Offset(100, 431)), isEmpty);
    expect(driver.update(1, const Offset(100, 430)),
        const [RuntimeInputEvent.release(RuntimeInputControl.sprint)]);
    expect(driver.update(1, const Offset(100, 441)), isEmpty);
    expect(driver.update(1, const Offset(100, 442)),
        const [RuntimeInputEvent.press(RuntimeInputControl.sprint)]);
    expect(driver.cancel(), const [
      RuntimeInputEvent.release(RuntimeInputControl.sprint),
      RuntimeInputEvent.release(RuntimeInputControl.down),
    ]);
    expect(driver.cancel(), isEmpty);
  });

  test('revocation requires a fresh threshold crossing or gesture', () {
    final driver = RuntimePlayerFloatingTouchDriver(sprintAllowed: true);
    driver.begin(1, Offset.zero);
    driver.update(1, const Offset(50, 0));
    expect(driver.setSprintAllowed(false),
        const [RuntimeInputEvent.release(RuntimeInputControl.sprint)]);
    expect(driver.setSprintAllowed(true), isEmpty);
    expect(driver.update(1, const Offset(60, 0)), isEmpty);
    driver.update(1, const Offset(30, 0));
    expect(driver.update(1, const Offset(42, 0)),
        const [RuntimeInputEvent.press(RuntimeInputControl.sprint)]);
  });

  test('movement while forbidden cannot prearm a held gesture', () {
    for (final mode in [
      RuntimePlayerTouchRunMode.gesture,
      RuntimePlayerTouchRunMode.automatic
    ]) {
      final driver =
          RuntimePlayerFloatingTouchDriver(sprintAllowed: true, runMode: mode);
      driver.begin(1, Offset.zero);
      driver.update(1, const Offset(50, 0));
      driver.setSprintAllowed(false);
      driver.update(1, const Offset(30, 0));
      driver.update(1, const Offset(50, 0));
      driver.setSprintAllowed(true);
      expect(driver.update(1, const Offset(51, 0)), isEmpty);
      driver.cancel();
      driver.setSprintAllowed(false);
      driver.begin(2, Offset.zero);
      driver.update(2, const Offset(50, 0));
      driver.setSprintAllowed(true);
      expect(driver.update(2, const Offset(51, 0)), isEmpty);
    }
  });

  test('walking forbids sprint and automatic starts only with a drag', () {
    for (final mode in RuntimePlayerTouchRunMode.values) {
      final driver =
          RuntimePlayerFloatingTouchDriver(sprintAllowed: true, runMode: mode);
      driver.begin(1, Offset.zero);
      expect(driver.update(1, const Offset(5, 0)), isEmpty);
      final drag = driver.update(1, const Offset(20, 0));
      expect(drag.where((event) => event.control == RuntimeInputControl.sprint),
          mode == RuntimePlayerTouchRunMode.automatic ? hasLength(1) : isEmpty);
      final outer = driver.update(1, const Offset(100, 0));
      expect(
          outer.where((event) => event.control == RuntimeInputControl.sprint),
          mode == RuntimePlayerTouchRunMode.gesture ? hasLength(1) : isEmpty);
      driver.setSprintAllowed(false);
      driver.setSprintAllowed(true);
      expect(driver.update(1, const Offset(110, 0)), isEmpty);
    }
  });

  testWidgets(
      'running feedback waits for acceptance and revocation requires rearming',
      (tester) async {
    final events = <RuntimeInputEvent>[];
    var allowed = true;
    var accepted = false;
    var feedback = 0;
    late StateSetter rebuild;
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: StatefulBuilder(builder: (context, setState) {
          rebuild = setState;
          return RuntimePlayerTouchControls(
              dispatch: events.add,
              sprintAllowed: allowed,
              sprintAccepted: accepted,
              onSprintAccepted: () => feedback++,
              readGameplayViewport: () => const Rect.fromLTWH(0, 0, 800, 600));
        })));
    final pointer = await tester.startGesture(const Offset(100, 400),
        kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(50, 0));
    await tester.pump();
    expect(events.where((e) => e.control == RuntimeInputControl.sprint),
        const [RuntimeInputEvent.press(RuntimeInputControl.sprint)]);
    expect(
        tester
            .widget<PlayerOverworldJoystickVisual>(
                find.byType(PlayerOverworldJoystickVisual))
            .running,
        isFalse);
    expect(feedback, 0);
    rebuild(() => accepted = true);
    await tester.pump();
    expect(
        tester
            .widget<PlayerOverworldJoystickVisual>(
                find.byType(PlayerOverworldJoystickVisual))
            .running,
        isTrue);
    expect(feedback, 1);
    rebuild(() {});
    await tester.pump();
    expect(feedback, 1);
    rebuild(() {
      accepted = false;
      allowed = false;
    });
    await tester.pump();
    expect(events.last,
        const RuntimeInputEvent.release(RuntimeInputControl.sprint));
    rebuild(() => allowed = true);
    await tester.pump();
    final count = events.length;
    await pointer.moveBy(const Offset(20, 0));
    expect(events.length, count);
    await pointer.moveTo(const Offset(130, 400));
    await pointer.moveTo(const Offset(142, 400));
    expect(
        events.last, const RuntimeInputEvent.press(RuntimeInputControl.sprint));
    await pointer.cancel();
    expect(events.sublist(events.length - 2), const [
      RuntimeInputEvent.release(RuntimeInputControl.sprint),
      RuntimeInputEvent.release(RuntimeInputControl.right)
    ]);
    expect(find.byKey(const ValueKey('runtime-player-touch-sprint-button')),
        findsNothing);
  });

  testWidgets('run preference replacement cancels the owned sprint gesture',
      (tester) async {
    final events = <RuntimeInputEvent>[];
    var mode = RuntimePlayerTouchRunMode.gesture;
    late StateSetter rebuild;
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: StatefulBuilder(builder: (context, setState) {
          rebuild = setState;
          return RuntimePlayerTouchControls(
              dispatch: events.add,
              sprintAllowed: true,
              runMode: mode,
              readGameplayViewport: () => const Rect.fromLTWH(0, 0, 800, 600));
        })));
    final pointer = await tester.startGesture(const Offset(100, 400),
        kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(50, 0));
    rebuild(() => mode = RuntimePlayerTouchRunMode.walkOnly);
    await tester.pump();
    expect(events.sublist(events.length - 2), const [
      RuntimeInputEvent.release(RuntimeInputControl.sprint),
      RuntimeInputEvent.release(RuntimeInputControl.right)
    ]);
    final count = events.length;
    await pointer.moveBy(const Offset(50, 0));
    await pointer.up();
    expect(events.length, count);
  });

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
    expect(taps, hasLength(2));
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
    expect(passed, hasLength(3));
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
    final candidates = <RuntimeOverworldInteractionRequest>[];
    var viewportAvailable = false;
    await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: RuntimePlayerTouchControls(
            dispatch: events.add,
            resolveTapTarget: (_) => request,
            onTap: candidates.add,
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
    expect(candidates.single, request);
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
