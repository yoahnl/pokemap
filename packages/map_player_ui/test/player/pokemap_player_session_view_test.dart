import 'dart:async';
import 'dart:ui' as ui show KeyEventDeviceType, PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_options.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final enabled in [false, true]) {
    testWidgets('OW005 accepted sprint haptic respects preference $enabled', (tester) async {
      var haptics = 0;
      final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1,
        phase: RuntimePlayerPhase.playing,
        preferences: PlayerPreferencesSnapshot(locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(hapticsEnabled: enabled))));
      final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.overworld, sprintAllowed: true));
      addTearDown(controller.dispose);
      addTearDown(authority.dispose);
      await tester.pumpWidget(_app(_view(controller,
        touchControlsAvailable: true, gameplayInputAuthority: authority,
        gameplayInputRoute: (_) => true,
        hapticFeedback: () async { haptics++; throw MissingPluginException(); },
      )));
      final pointer = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
      await pointer.moveBy(const Offset(20, 0));
      await tester.pump();
      final beforeSprint = haptics;
      await pointer.moveBy(const Offset(30, 0));
      await tester.pump();
      expect(haptics, beforeSprint);
      authority.value = const RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.overworld, sprintAllowed: true, sprintAccepted: true);
      await tester.pump();
      expect(haptics, beforeSprint + (enabled ? 1 : 0));
      await pointer.moveBy(const Offset(5, 0));
      await tester.pump();
      expect(haptics, beforeSprint + (enabled ? 1 : 0));
      expect(tester.takeException(), isNull);
      await pointer.up();
    });
  }

  testWidgets('OW005 authority revocation releases sprint synchronously without revival', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld, sprintAllowed: true));
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.dispose);
    addTearDown(authority.dispose);
    await tester.pumpWidget(_app(_view(controller,
      touchControlsAvailable: true, gameplayInputAuthority: authority,
      gameplayInputRoute: (event) { events.add(event); return true; })));
    final pointer = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(50, 0));
    expect(events.where((e) => e.control == RuntimeInputControl.sprint),
      const [RuntimeInputEvent.press(RuntimeInputControl.sprint)]);
    authority.value = const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.dialogue);
    expect(events.where((e) => e.control == RuntimeInputControl.sprint), const [
      RuntimeInputEvent.press(RuntimeInputControl.sprint), RuntimeInputEvent.release(RuntimeInputControl.sprint)]);
    authority.value = const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld, sprintAllowed: true);
    await tester.pump();
    await pointer.moveBy(const Offset(50, 0));
    await pointer.up();
    expect(events.where((e) => e.control == RuntimeInputControl.sprint), hasLength(2));
  });

  testWidgets('OW005 hardware sprint preserves its existing route and haptic', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final input = StreamController<RuntimeInputEvent>.broadcast();
    final events = <RuntimeInputEvent>[];
    var haptics = 0;
    addTearDown(controller.dispose);
    addTearDown(input.close);
    await tester.pumpWidget(_app(_view(controller,
      controllerInputEvents: input.stream,
      gameplayInputRoute: (event) { events.add(event); return true; },
      hapticFeedback: () async => haptics++)));
    input.add(const RuntimeInputEvent.press(RuntimeInputControl.sprint));
    await tester.pump();
    input.add(const RuntimeInputEvent.release(RuntimeInputControl.sprint));
    await tester.pump();
    expect(events, const [RuntimeInputEvent.press(RuntimeInputControl.sprint),
      RuntimeInputEvent.release(RuntimeInputControl.sprint)]);
    expect(haptics, 1);
  });

  testWidgets('OW004 measures scaled gameplay viewport in session coordinates', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final viewportKey = GlobalKey();
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(_view(controller,
      gameplayViewportKey: viewportKey,
      gameSceneBuilder: (_) => Stack(children: [Positioned(left: 100, top: 40,
        child: Transform.scale(scale: .5, alignment: Alignment.topLeft,
          child: SizedBox(key: viewportKey, width: 400, height: 600)))]),
      touchControlsAvailable: true,
      gameplayInputRoute: (event) { events.add(event); return true; },
    )));
    for (final origin in [const Offset(350, 240), const Offset(120, 400)]) {
      final pointer = await tester.startGesture(origin, kind: ui.PointerDeviceKind.touch);
      await pointer.moveBy(const Offset(50, 0));
      await pointer.up();
    }
    expect(events, isEmpty);
    final pointer = await tester.startGesture(const Offset(120, 240), kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(50, 0));
    expect(events.single, const RuntimeInputEvent.press(RuntimeInputControl.right));
    await pointer.up();
    expect(events.last, const RuntimeInputEvent.release(RuntimeInputControl.right));
  });

  testWidgets('OW004 viewport translation cancels stationary pointer without session rebuild', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final viewportKey = GlobalKey();
    final events = <RuntimeInputEvent>[];
    var offset = 0.0;
    late StateSetter moveViewport;
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(_view(controller,
      gameplayViewportKey: viewportKey,
      gameSceneBuilder: (_) => StatefulBuilder(builder: (context, setState) {
        moveViewport = setState;
        return Stack(children: [Positioned(left: offset, top: 0,
          child: SizedBox(key: viewportKey, width: 500, height: 600))]);
      }),
      touchControlsAvailable: true,
      gameplayInputRoute: (event) { events.add(event); return true; },
    )));
    final pointer = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(50, 0));
    await tester.pump();
    expect(events.single, const RuntimeInputEvent.press(RuntimeInputControl.right));
    moveViewport(() => offset = 30);
    await tester.pump();
    expect(events.last, const RuntimeInputEvent.release(RuntimeInputControl.right));
    await pointer.moveBy(const Offset(50, 0));
    await pointer.up();
    expect(events, hasLength(2));
  });

  testWidgets('OW004 authority change immediately releases and cancels the gesture', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld));
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.dispose);
    addTearDown(authority.dispose);
    await tester.pumpWidget(_app(_view(controller,
      touchControlsAvailable: true, gameplayInputAuthority: authority,
      gameplayInputRoute: (event) { events.add(event); return true; },
    )));
    final pointer = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(50, 0));
    expect(events.single, const RuntimeInputEvent.press(RuntimeInputControl.right));
    authority.value = const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.dialogue);
    expect(events.last, const RuntimeInputEvent.release(RuntimeInputControl.right));
    authority.value = const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld);
    await tester.pump();
    await pointer.moveBy(const Offset(50, 0));
    await pointer.up();
    expect(events, hasLength(2));
  });

  testWidgets('OW004 lifecycle snapshot preserves accepted touch release while blocked', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(_view(controller,
      touchControlsAvailable: true,
      gameplayInputRoute: (event) { events.add(event); return true; },
    )));
    final pointer = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(50, 0));
    controller.publish(_snapshot(revision: 2, phase: RuntimePlayerPhase.lifecyclePaused));
    await tester.pump();
    expect(events, const [RuntimeInputEvent.press(RuntimeInputControl.right),
      RuntimeInputEvent.release(RuntimeInputControl.right)]);
    controller.publish(_snapshot(revision: 3, phase: RuntimePlayerPhase.playing));
    await tester.pump();
    await pointer.moveBy(const Offset(50, 0));
    await pointer.up();
    expect(events, hasLength(2));
  });

  testWidgets('OW004 measured Menu excludes gesture capture and cancels first finger', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1,
      phase: RuntimePlayerPhase.playing,
      preferences: const PlayerPreferencesSnapshot(locale: 'fr',
        accessibility: GameSessionAccessibilityOptions(), leftHandedTouchControls: true),
      actions: const [RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu)]));
    final viewportKey = GlobalKey();
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(_view(controller,
      gameplayViewportKey: viewportKey,
      gameSceneBuilder: (_) => Stack(children: [Positioned(left: 250, top: 0,
        child: SizedBox(key: viewportKey, width: 140, height: 100))]),
      touchControlsAvailable: true,
      gameplayInputRoute: (event) { events.add(event); return true; },
    )));
    final first = await tester.startGesture(const Offset(320, 85), pointer: 1, kind: ui.PointerDeviceKind.touch);
    await first.moveBy(const Offset(-30, 0));
    expect(events.single, const RuntimeInputEvent.press(RuntimeInputControl.left));
    final menu = await tester.startGesture(const Offset(350, 50), pointer: 2, kind: ui.PointerDeviceKind.touch);
    await menu.up();
    await tester.pump();
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
    expect(events.last, const RuntimeInputEvent.release(RuntimeInputControl.left));
    await first.moveBy(const Offset(80, 0));
    await first.up();
    expect(events, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  for (final replaceController in [true, false]) {
    testWidgets('OW004 replacement releases old owner when controller changes $replaceController', (tester) async {
      final oldController = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final newController = _FakeRuntimePlayerCoordinator(_snapshot(revision: 2, phase: RuntimePlayerPhase.playing));
      final oldAuthority = ValueNotifier(const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld));
      final newAuthority = ValueNotifier(const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld));
      final viewportKey = GlobalKey();
      final oldEvents = <RuntimeInputEvent>[];
      final newEvents = <RuntimeInputEvent>[];
      addTearDown(oldController.dispose);
      addTearDown(newController.dispose);
      addTearDown(oldAuthority.dispose);
      addTearDown(newAuthority.dispose);
      await tester.pumpWidget(_app(_view(oldController,
        gameplayViewportKey: viewportKey, gameplayInputAuthority: oldAuthority,
        touchControlsAvailable: true,
        gameplayInputRoute: (event) { oldEvents.add(event); return true; },
      )));
      final held = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
      await held.moveBy(const Offset(50, 0));
      expect(oldEvents.single, const RuntimeInputEvent.press(RuntimeInputControl.right));
      await tester.pumpWidget(_app(_view(replaceController ? newController : oldController,
        gameplayViewportKey: viewportKey,
        gameplayInputAuthority: replaceController ? oldAuthority : newAuthority,
        touchControlsAvailable: true,
        gameplayInputRoute: (event) { newEvents.add(event); return true; },
      )));
      expect(oldEvents, const [RuntimeInputEvent.press(RuntimeInputControl.right),
        RuntimeInputEvent.release(RuntimeInputControl.right)]);
      expect(newEvents, isEmpty);
      await held.moveBy(const Offset(-100, 0));
      await held.up();
      expect(newEvents, isEmpty);
      final fresh = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
      await fresh.moveBy(const Offset(-30, 0));
      expect(newEvents.single, const RuntimeInputEvent.press(RuntimeInputControl.left));
      await fresh.up();
      expect(newEvents.last, const RuntimeInputEvent.release(RuntimeInputControl.left));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('OW004 ordinary route closure rebuild preserves the active gesture', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final viewportKey = GlobalKey();
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.dispose);
    Widget view() => _app(_view(controller,
      gameplayViewportKey: viewportKey, touchControlsAvailable: true,
      gameplayInputRoute: (event) { events.add(event); return true; },
    ));
    await tester.pumpWidget(view());
    final held = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
    await held.moveBy(const Offset(50, 0));
    await tester.pumpWidget(view());
    expect(events.single, const RuntimeInputEvent.press(RuntimeInputControl.right));
    await held.moveBy(const Offset(20, 0));
    expect(events, hasLength(1));
    await held.up();
    expect(events.last, const RuntimeInputEvent.release(RuntimeInputControl.right));
  });

  group('OW002 adaptive input', () {
    for (final initiallyConnected in [false, true]) {
      testWidgets(
          'starts mobile with controller availability $initiallyConnected',
          (tester) async {
        final controller = _FakeRuntimePlayerCoordinator(
            _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
        final connected =
            ValueNotifier<Set<String>>(initiallyConnected ? {'pad'} : {});
        final events = StreamController<NormalizedGamepadEvent>.broadcast();
        addTearDown(controller.dispose);
        addTearDown(connected.dispose);
        addTearDown(events.close);
        await tester.pumpWidget(_app(_view(controller,
            touchControlsAvailable: true,
            connectedControllerIds: connected,
            normalizedControllerInputEvents: events.stream,
            gameplayInputRoute: (_) => true)));
        _expectTouchControls(tester, !initiallyConnected);
        expect(find.byKey(const ValueKey('runtime-player-touch-movement-zone')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'executes first controller and touch gestures once while connected',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final connected = ValueNotifier<Set<String>>({'pad'});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await tester.pumpWidget(_app(_view(controller,
          touchControlsAvailable: true,
          connectedControllerIds: connected,
          normalizedControllerInputEvents: events.stream,
          gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      events.add(_padInput(button: GamepadButton.a));
      events.add(_padInput(button: GamepadButton.a));
      await tester.pump();
      expect(
          routed, const [RuntimeInputEvent.press(RuntimeInputControl.primary)]);
      events.add(_padInput(button: GamepadButton.a, value: 0));
      await tester.pump();
      final zone =
          find.byKey(const ValueKey('runtime-player-touch-movement-zone'));
      final gesture = await tester.startGesture(tester.getCenter(zone),
          kind: ui.PointerDeviceKind.touch);
      await tester.pump();
      await gesture.moveBy(const Offset(55, 0));
      await tester.pump(const Duration(milliseconds: 80));
      _expectTouchControls(tester, true);
      expect(
          routed.where((event) =>
              event ==
              const RuntimeInputEvent.press(RuntimeInputControl.right)),
          hasLength(1));
      await gesture.up();
      await tester.pump();
      events.add(_padInput(button: GamepadButton.a));
      await tester.pump();
      await tester.pump();
      _expectTouchControls(tester, false);
      expect(
          routed.where((event) =>
              event ==
              const RuntimeInputEvent.press(RuntimeInputControl.primary)),
          hasLength(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ignores drift releases unmapped keys and pointer hover',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final connected = ValueNotifier<Set<String>>({});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await tester.pumpWidget(_app(_view(controller,
          touchControlsAvailable: true,
          connectedControllerIds: connected,
          normalizedControllerInputEvents: events.stream,
          gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      await tester.tap(
          find.byKey(const ValueKey('runtime-player-touch-primary-button')));
      await tester.pump();
      routed.clear();
      connected.value = {'pad'};
      events.add(_padInput(axis: GamepadAxis.leftStickX, value: .12));
      events.add(_padInput(axis: GamepadAxis.leftStickX, value: 0));
      events.add(_padInput(button: GamepadButton.a, value: 0));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      final mouse =
          await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(300, 200));
      await mouse.moveTo(const Offset(330, 200));
      await tester.pump();
      _expectTouchControls(tester, true);
      expect(routed, isEmpty);
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'disconnect neutralizes owned direction and sprint without replay',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final connected = ValueNotifier<Set<String>>({'pad'});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await tester.pumpWidget(_app(_view(controller,
          touchControlsAvailable: true,
          connectedControllerIds: connected,
          normalizedControllerInputEvents: events.stream,
          gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      events.add(_padInput(axis: GamepadAxis.leftStickX, value: .8));
      events.add(_padInput(button: GamepadButton.y));
      await tester.pump();
      routed.clear();
      connected.value = {};
      await tester.pump();
      expect(
          routed,
          unorderedEquals(const [
            RuntimeInputEvent.release(RuntimeInputControl.right),
            RuntimeInputEvent.release(RuntimeInputControl.sprint)
          ]));
      _expectTouchControls(tester, true);
      routed.clear();
      connected.value = {'pad'};
      events.add(_padInput(axis: GamepadAxis.leftStickX, value: .8));
      events.add(_padInput(button: GamepadButton.y));
      await tester.pump();
      expect(routed, isEmpty);
      _expectTouchControls(tester, true);
    });

    testWidgets('late controller release leaves new touch movement owned',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final connected = ValueNotifier<Set<String>>({'pad'});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await tester.pumpWidget(_app(_view(controller,
          touchControlsAvailable: true,
          connectedControllerIds: connected,
          normalizedControllerInputEvents: events.stream,
          gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      events.add(_padInput(axis: GamepadAxis.leftStickX, value: .8));
      await tester.pump();
      final gesture = await tester.startGesture(
          tester.getCenter(
              find.byKey(const ValueKey('runtime-player-touch-movement-zone'))),
          kind: ui.PointerDeviceKind.touch);
      await tester.pump();
      await gesture.moveBy(const Offset(55, 0));
      await tester.pump(const Duration(milliseconds: 80));
      expect(routed, const [
        RuntimeInputEvent.press(RuntimeInputControl.right),
        RuntimeInputEvent.release(RuntimeInputControl.right),
        RuntimeInputEvent.press(RuntimeInputControl.right)
      ]);
      routed.clear();
      events.add(_padInput(axis: GamepadAxis.leftStickX, value: 0));
      await tester.pump();
      expect(routed, isEmpty);
      _expectTouchControls(tester, true);
      await gesture.up();
      await tester.pump();
      expect(
          routed, const [RuntimeInputEvent.release(RuntimeInputControl.right)]);
    });

    testWidgets(
        'prompts follow remapping and normalized controller input owns duplicates',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(_snapshot(
          revision: 1,
          phase: RuntimePlayerPhase.playing,
          preferences: const PlayerPreferencesSnapshot(
              locale: 'fr',
              accessibility: GameSessionAccessibilityOptions(),
              showInputHints: true)));
      final connected = ValueNotifier<Set<String>>({});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      final profile = PlayerControlProfile.standard
          .rebind(
              device: PlayerControlDevice.keyboard,
              control: RuntimeInputControl.primary,
              inputId: 'keyZ')
          .profile
          .rebind(
              device: PlayerControlDevice.gamepad,
              control: RuntimeInputControl.primary,
              inputId: 'x')
          .profile;
      addTearDown(controller.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await tester.pumpWidget(_app(_view(controller,
          connectedControllerIds: connected,
          normalizedControllerInputEvents: events.stream,
          controlProfile: profile, gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      expect(find.text('Z · M Pause'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      expect(routed, const [
        RuntimeInputEvent.press(RuntimeInputControl.primary),
        RuntimeInputEvent.release(RuntimeInputControl.primary)
      ]);
      routed.clear();
      connected.value = {'pad'};
      final authority = tester.widget<Focus>(find
          .byKey(const ValueKey('runtime-player-keyboard-input-authority')));
      final node = FocusNode();
      addTearDown(node.dispose);
      expect(
          authority.onKeyEvent!(
              node,
              const KeyDownEvent(
                  physicalKey: PhysicalKeyboardKey.gameButtonX,
                  logicalKey: LogicalKeyboardKey.gameButtonX,
                  timeStamp: Duration.zero,
                  deviceType: ui.KeyEventDeviceType.gamepad)),
          KeyEventResult.handled);
      expect(
          authority.onKeyEvent!(
              node,
              const KeyUpEvent(
                  physicalKey: PhysicalKeyboardKey.gameButtonX,
                  logicalKey: LogicalKeyboardKey.gameButtonX,
                  timeStamp: Duration.zero,
                  deviceType: ui.KeyEventDeviceType.gamepad)),
          KeyEventResult.handled);
      events.add(_padInput(button: GamepadButton.x));
      await tester.pump();
      await tester.pump();
      expect(
          routed, const [RuntimeInputEvent.press(RuntimeInputControl.primary)]);
      expect(find.text('Bouton ouest · Menu Pause'), findsOneWidget);
      events.add(_padInput(button: GamepadButton.x, value: 0));
      await tester.pump();
      expect(routed, const [
        RuntimeInputEvent.press(RuntimeInputControl.primary),
        RuntimeInputEvent.release(RuntimeInputControl.primary)
      ]);
    });
    testWidgets(
        'keyboard repeat and release do not retake an active touch gesture',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_view(controller,
          touchControlsAvailable: true, gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyE);
      await tester.pump();
      _expectTouchControls(tester, false);
      final gesture = await tester.startGesture(
          tester.getCenter(
              find.byKey(const ValueKey('runtime-player-touch-movement-zone'))),
          kind: ui.PointerDeviceKind.touch);
      await tester.pump();
      await gesture.moveBy(const Offset(55, 0));
      await tester.pump(const Duration(milliseconds: 80));
      _expectTouchControls(tester, true);
      routed.clear();
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyE);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyE);
      await tester.pump();
      _expectTouchControls(tester, true);
      expect(routed.where((event) => event.isPress), isEmpty);
      await gesture.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'focused text and composing IME keep gameplay and presentation idle',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final focus = FocusNode();
      final text = TextEditingController();
      final connected = ValueNotifier<Set<String>>({'pad'});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      addTearDown(text.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await tester.pumpWidget(_app(PokeMapPlayerSessionView(
          controller: controller,
          titlePresentation: const RuntimePlayerTitlePresentation(
              author: 'Studio Test', description: 'Une aventure de test.'),
          gameSceneBuilder: (_) => Align(
              alignment: Alignment.topCenter,
              child: Material(
                  child: TextField(focusNode: focus, controller: text))),
          touchControlsAvailable: true,
          controllerInputEnabled: true,
          connectedControllerIds: connected,
          normalizedControllerInputEvents: events.stream,
          gameplayInputRoute: (event) {
            routed.add(event);
            return true;
          })));
      focus.requestFocus();
      await tester.pump();
      tester.testTextInput.updateEditingValue(const TextEditingValue(
          text: 'é', composing: TextRange(start: 0, end: 1)));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(text.text, 'é');
      expect(routed, isEmpty);
      _expectTouchControls(tester, false);
      expect(tester.takeException(), isNull);
    });

    testWidgets('held touch timer cannot reclaim input after hardware resumes',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final connected = ValueNotifier<Set<String>>({});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await tester.pumpWidget(_app(_view(controller,
          touchControlsAvailable: true,
          connectedControllerIds: connected,
          normalizedControllerInputEvents: events.stream,
          gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      final gesture = await tester.startGesture(
          tester.getCenter(
              find.byKey(const ValueKey('runtime-player-touch-movement-zone'))),
          kind: ui.PointerDeviceKind.touch);
      await gesture.moveBy(const Offset(55, 0));
      await tester.pump(const Duration(milliseconds: 80));
      expect(
          routed, const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
      connected.value = {'pad'};
      events.add(_padInput(axis: GamepadAxis.leftStickX, value: .8));
      await tester.pump();
      await tester.pump();
      _expectTouchControls(tester, false);
      expect(routed, const [
        RuntimeInputEvent.press(RuntimeInputControl.right),
        RuntimeInputEvent.release(RuntimeInputControl.right),
        RuntimeInputEvent.press(RuntimeInputControl.right),
      ]);
      routed.clear();
      await tester.pump(const Duration(milliseconds: 180));
      await gesture.moveBy(const Offset(-90, 0));
      await tester.pump(const Duration(milliseconds: 80));
      _expectTouchControls(tester, false);
      expect(routed, isEmpty);
      await gesture.up();
      await tester.pump();
      expect(routed, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('synthesized mapped key down neither selects keyboard nor acts',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_view(controller,
          touchControlsAvailable: true, gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      HardwareKeyboard.instance.handleKeyEvent(const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyE,
        logicalKey: LogicalKeyboardKey.keyE,
        timeStamp: Duration.zero,
        synthesized: true,
      ));
      await tester.pump();
      _expectTouchControls(tester, true);
      expect(routed, isEmpty);
      HardwareKeyboard.instance.handleKeyEvent(const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.keyE,
        logicalKey: LogicalKeyboardKey.keyE,
        timeStamp: Duration.zero,
        synthesized: true,
      ));
      await tester.pump();
      _expectTouchControls(tester, true);
      expect(routed, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'controller identity refreshes reliable family prompts between pads',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(_snapshot(
        revision: 1,
        phase: RuntimePlayerPhase.playing,
        preferences: const PlayerPreferencesSnapshot(
            locale: 'fr',
            accessibility: GameSessionAccessibilityOptions(),
            showInputHints: true),
      ));
      final connected = ValueNotifier<Set<String>>({'xbox', 'sony'});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await tester.pumpWidget(_app(_view(
        controller,
        touchControlsAvailable: true,
        connectedControllerIds: connected,
        normalizedControllerInputEvents: events.stream,
        gameplayInputRoute: (event) {
          routed.add(event);
          return true;
        },
      )));
      events.add(_padInput(
          gamepadId: 'xbox',
          button: GamepadButton.a,
          vendorId: 0x045e,
          productId: 0x0b0c));
      await tester.pump();
      await tester.pump();
      expect(find.text('A · Menu Pause'), findsOneWidget);
      events.add(_padInput(
          gamepadId: 'xbox',
          button: GamepadButton.a,
          value: 0,
          vendorId: 0x045e,
          productId: 0x0b0c));
      events.add(_padInput(
          gamepadId: 'sony',
          button: GamepadButton.a,
          vendorId: 0x054c,
          productId: 0x0ba0));
      await tester.pump();
      await tester.pump();
      expect(find.text('× · Menu Pause'), findsOneWidget);
      events.add(_padInput(
          gamepadId: 'sony',
          button: GamepadButton.a,
          value: 0,
          vendorId: 0x054c,
          productId: 0x0ba0));
      await tester.pump();
      expect(
          routed.where((event) =>
              event ==
              const RuntimeInputEvent.press(RuntimeInputControl.primary)),
          hasLength(2));
      final gesture = await tester.startGesture(
          tester.getCenter(
              find.byKey(const ValueKey('runtime-player-touch-movement-zone'))),
          kind: ui.PointerDeviceKind.touch);
      await tester.pump();
      await gesture.moveBy(const Offset(55, 0));
      await tester.pump(const Duration(milliseconds: 80));
      _expectTouchControls(tester, true);
      await gesture.up();
      await tester.pump();
      events.add(_padInput(
          gamepadId: 'xbox',
          button: GamepadButton.a,
          vendorId: 0x045e,
          productId: 0x0b0c));
      await tester.pump();
      await tester.pump();
      _expectTouchControls(tester, false);
      expect(find.text('A · Menu Pause'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a popup touch action takes over from keyboard navigation',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(_titleOptionsSnapshot());
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_view(controller)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('options-text-speed-choice')),
          kind: ui.PointerDeviceKind.touch);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<RuntimePlayerOptions>(
                  find.byType(RuntimePlayerOptions, skipOffstage: false))
              .activeInputSource,
          PlayerInputSource.keyboard);
      await tester.tap(find.byKey(const ValueKey('options-choice-fast')),
          kind: ui.PointerDeviceKind.touch);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<RuntimePlayerOptions>(find.byType(RuntimePlayerOptions))
              .activeInputSource,
          PlayerInputSource.touch);
      expect(controller.commands, hasLength(1));
      expect(controller.commands.single.action,
          RuntimePlayerAction.updatePreferences);
      expect(
          (controller.commands.single.payload! as PlayerPreferencesSnapshot)
              .dialogueTextSpeed,
          RuntimeDialogueTextSpeed.fast);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('routes one canonical surface for every player phase',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 1,
      phase: RuntimePlayerPhase.title,
      actions: <RuntimePlayerActionAvailability>[
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.continueGame,
        ),
      ],
    ));
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller)));
    expect(_surfaceFinder(RuntimePlayerPhase.title), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('test-game-scene')), findsNothing);

    for (final phase in <RuntimePlayerPhase>[
      RuntimePlayerPhase.preSession,
      RuntimePlayerPhase.preparingSession,
      RuntimePlayerPhase.loadingSession,
      RuntimePlayerPhase.playing,
      RuntimePlayerPhase.paused,
      RuntimePlayerPhase.saving,
      RuntimePlayerPhase.lifecyclePaused,
      RuntimePlayerPhase.completing,
      RuntimePlayerPhase.result,
      RuntimePlayerPhase.credits,
      RuntimePlayerPhase.disposingSession,
      RuntimePlayerPhase.externalExit,
      RuntimePlayerPhase.error,
    ]) {
      controller.publish(_snapshot(revision: 2 + phase.index, phase: phase));
      await tester.pump();

      expect(
        _surfaceFinder(phase),
        findsOneWidget,
        reason: 'The ${phase.name} phase must have one canonical surface.',
      );
      expect(_allCanonicalSurfaces(), findsOneWidget);
    }
  });

  testWidgets(
    'renders the active Presentation frame through the shared Player renderer',
    (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
        _snapshot(revision: 15, phase: RuntimePlayerPhase.playing),
      );
      final frame = _presentationFrame();
      final presentation = ValueNotifier<RuntimePresentationFrameSnapshot?>(
        RuntimePresentationFrameSnapshot(
          assetRevision: 'opening-revision-7',
          frame: frame,
          orientation: PresentationFrameOrientation.portrait,
          mediaBindings: const <PresentationFrameMediaBinding>[
            PresentationFrameMediaBinding(
              clipId: 'opening-visual',
              kind: PresentationFrameMediaKind.image,
              landscapeResourceId: 'opening-landscape',
              portraitResourceId: 'opening-portrait',
            ),
          ],
        ),
      );
      final contentPort = _PresentationContentPort();
      var skipCalls = 0;
      addTearDown(controller.dispose);
      addTearDown(presentation.dispose);

      await tester.pumpWidget(
        _app(
          _view(
            controller,
            presentationFrame: presentation,
            presentationContentPort: contentPort,
            onPresentationSkip: () async => skipCalls += 1,
            touchControlsAvailable: true,
            gameplayInputRoute: (_) => true,
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey<String>('runtime-presentation-frame-surface'),
        ),
        findsOneWidget,
      );
      final renderer = tester.widget<PresentationFrameRenderer>(
        find.byType(PresentationFrameRenderer),
      );
      expect(identical(renderer.frame, frame), isTrue);
      expect(
        identical(
          (renderer.contentPort as PresentationResponsiveFrameContentPort)
              .delegate,
          contentPort,
        ),
        isTrue,
      );
      expect(renderer.orientation, PresentationFrameOrientation.portrait);
      expect(contentPort.visualRequests, <String>['opening-portrait']);
      expect(find.byKey(const ValueKey<String>('test-game-scene')),
          findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('runtime-player-touch-movement-zone')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('runtime-presentation-skip')),
      );
      await tester.pump();
      expect(skipCalls, 1);

      presentation.value = null;
      await tester.pump();

      expect(find.byType(PresentationFrameRenderer), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('runtime-player-touch-movement-zone')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dispatches title actions with the current snapshot revision',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 7,
      phase: RuntimePlayerPhase.title,
      actions: <RuntimePlayerActionAvailability>[
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.continueGame,
        ),
        RuntimePlayerActionAvailability.disabled(
          RuntimePlayerAction.newGame,
          reason: 'Profil requis',
        ),
      ],
    ));
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller)));
    await tester.tap(find.text('Continuer'));

    expect(controller.commands, hasLength(1));
    expect(controller.commands.single.action, RuntimePlayerAction.continueGame);
    expect(controller.commands.single.snapshotRevision, 7);

    final newGameButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Nouveau jeu'),
    );
    expect(newGameButton.onPressed, isNull);
    expect(controller.commands, hasLength(1));
  });

  testWidgets(
    'renders title options without a game scene and returns on Escape',
    (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(
        tester.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final controller = _FakeRuntimePlayerCoordinator(
        RuntimePlayerSnapshot(
          revision: 8,
          phase: RuntimePlayerPhase.title,
          gameTitle: 'Aube',
          pauseSection: RuntimePlayerPauseSection.options,
          defaultPreferences: const PlayerPreferencesSnapshot(
            locale: 'en',
            accessibility: GameSessionAccessibilityOptions(),
            audioMix: RuntimeAudioMix(musicVolume: 0.8, effectsVolume: 0.8),
          ),
          preferences: const PlayerPreferencesSnapshot(
            locale: 'fr',
            accessibility: GameSessionAccessibilityOptions(),
          ),
          actions: const <RuntimePlayerActionAvailability>[
            RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.openOptions,
            ),
            RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.updatePreferences,
            ),
            RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.returnToTitle,
            ),
          ],
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(_view(controller)));

      final options = tester.widget<RuntimePlayerOptions>(
        find.byType(RuntimePlayerOptions),
      );
      expect(options.defaultPreferences.locale, 'en');
      expect(options.defaultPreferences.audioMix.musicVolume, 0.8);

      expect(
        find.byKey(
          const ValueKey<String>('runtime-player-title-options'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('options-text-speed-choice'),
        ),
        findsOneWidget,
      );
      expect(
          find.byKey(const ValueKey<String>('test-game-scene')), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(controller.backRequests, <int>[8]);
      expect(controller.commands, isEmpty);
    },
  );

  testWidgets(
      'title options route controller slider changes and back through the coordinator',
      (tester) async {
    final events = StreamController<RuntimeInputEvent>.broadcast();
    addTearDown(events.close);
    final controller = _FakeRuntimePlayerCoordinator(_titleOptionsSnapshot());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
        _app(_view(controller, controllerInputEvents: events.stream)));
    await _selectOptionsCategory(tester, 'audio');
    final slider = find.byKey(const ValueKey('options-master-slider'));
    await tester.ensureVisible(slider);
    tester.widget<Slider>(slider).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    events.add(const RuntimeInputEvent.press(RuntimeInputControl.left));
    await tester.pumpAndSettle();
    expect(controller.commands, hasLength(1));
    expect(controller.commands.single.action,
        RuntimePlayerAction.updatePreferences);
    expect(controller.commands.single.snapshotRevision, 86);
    expect(
        (controller.commands.single.payload! as PlayerPreferencesSnapshot)
            .audioMix
            .masterVolume,
        .95);
    expect(tester.widget<Slider>(slider).value, .95);
    events.add(const RuntimeInputEvent.press(RuntimeInputControl.right));
    await tester.pumpAndSettle();
    expect(controller.commands, hasLength(2));
    expect(
        (controller.commands.last.payload! as PlayerPreferencesSnapshot)
            .audioMix
            .masterVolume,
        1);
    events.add(const RuntimeInputEvent.press(RuntimeInputControl.secondary));
    await tester.pumpAndSettle();
    expect(controller.commands, hasLength(3));
    expect(controller.commands.last.action, RuntimePlayerAction.returnToTitle);
    expect(controller.commands.last.snapshotRevision, 86);
    controller.publish(controller.snapshot.next(clearPauseSection: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('runtime-player-title-options')),
        findsNothing);
    expect(find.byKey(const ValueKey('test-game-scene')), findsNothing);
  });

  testWidgets(
      'title options receive controller keyboard and touch source changes',
      (tester) async {
    final events = StreamController<RuntimeInputEvent>.broadcast();
    addTearDown(events.close);
    final controller = _FakeRuntimePlayerCoordinator(_titleOptionsSnapshot());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
        _app(_view(controller, controllerInputEvents: events.stream)));
    await _selectOptionsCategory(tester, 'controls');
    events.add(const RuntimeInputEvent.press(RuntimeInputControl.sprint));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<RuntimePlayerOptions>(find.byType(RuntimePlayerOptions))
            .activeInputSource,
        PlayerInputSource.controller);
    expect(find.text('Manette'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<RuntimePlayerOptions>(find.byType(RuntimePlayerOptions))
            .activeInputSource,
        PlayerInputSource.keyboard);
    expect(find.text('Clavier'), findsOneWidget);
    await tester.tapAt(
        tester.getTopLeft(find.byKey(const ValueKey('options-settings'))) +
            const Offset(8, 8),
        kind: ui.PointerDeviceKind.touch);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<RuntimePlayerOptions>(find.byType(RuntimePlayerOptions))
            .activeInputSource,
        PlayerInputSource.keyboard);
    await _selectOptionsCategory(tester, 'controls');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<RuntimePlayerOptions>(find.byType(RuntimePlayerOptions))
            .activeInputSource,
        PlayerInputSource.touch);
    expect(find.text('Tactile'), findsOneWidget);
    expect(controller.commands, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('title option popups consume duplicate hardware gamepad events',
      (tester) async {
    final events = StreamController<RuntimeInputEvent>.broadcast();
    addTearDown(events.close);
    final controller = _FakeRuntimePlayerCoordinator(_titleOptionsSnapshot());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
        _app(_view(controller, controllerInputEvents: events.stream)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('options-text-speed-choice')));
    await tester.pumpAndSettle();
    await _hardwareGamepadPress(
        tester, LogicalKeyboardKey.keyE, PhysicalKeyboardKey.gameButtonA);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('options-choice-back')), findsOneWidget);
    expect(controller.commands, isEmpty);
    events.add(const RuntimeInputEvent.press(RuntimeInputControl.primary));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('options-choice-back')), findsNothing);
    expect(controller.commands, hasLength(1));
    expect(controller.commands.single.action,
        RuntimePlayerAction.updatePreferences);
    Focus.of(tester.element(find
            .descendant(
              of: find.byKey(const ValueKey('options-text-speed-choice')),
              matching: find.byType(GestureDetector),
            )
            .first))
        .requestFocus();
    await tester.pump();
    await _hardwareGamepadPress(
        tester, LogicalKeyboardKey.keyE, PhysicalKeyboardKey.gameButtonA);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('options-choice-back')), findsNothing);
    expect(controller.commands, hasLength(1));
    await tester.tap(find.byKey(const ValueKey('options-text-speed-choice')));
    await tester.pumpAndSettle();
    events.add(const RuntimeInputEvent.press(RuntimeInputControl.secondary));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('options-choice-back')), findsNothing);
    expect(controller.commands, hasLength(1));
    Focus.of(tester.element(find
            .descendant(
              of: find.byKey(const ValueKey('options-text-speed-choice')),
              matching: find.byType(GestureDetector),
            )
            .first))
        .requestFocus();
    await tester.pump();
    await _hardwareGamepadPress(
        tester, LogicalKeyboardKey.escape, PhysicalKeyboardKey.gameButtonB);
    await tester.pumpAndSettle();
    expect(controller.commands, hasLength(1));
    expect(controller.backRequests, isEmpty);
  });

  testWidgets('projects readability preferences and accessible input hints',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(
      RuntimePlayerSnapshot(
        revision: 81,
        phase: RuntimePlayerPhase.title,
        gameTitle: 'Aube',
        preferences: const PlayerPreferencesSnapshot(
          locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(
            reducedMotion: true,
            textScale: 1.4,
            hapticsEnabled: false,
          ),
          highContrast: true,
          showInputHints: false,
        ),
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.25),
          ),
          child: _view(controller),
        ),
      ),
    );

    final accessibilityContext = tester.element(
      find.byKey(
        const ValueKey<String>('runtime-player-session-accessibility'),
      ),
    );
    expect(
      MediaQuery.of(accessibilityContext).textScaler.scale(10),
      closeTo(17.5, 0.001),
    );
    expect(MediaQuery.of(accessibilityContext).disableAnimations, isTrue);
    expect(
      Theme.of(accessibilityContext)
          .extension<PokeMapPlayerColors>()
          ?.highContrast,
      isTrue,
    );
    expect(
      Theme.of(accessibilityContext).extension<PokeMapPlayerMotion>()?.fast,
      Duration.zero,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-player-input-hints')),
      findsNothing,
    );

    controller.publish(
      RuntimePlayerSnapshot(
        revision: 82,
        phase: RuntimePlayerPhase.title,
        gameTitle: 'Aube',
        preferences: const PlayerPreferencesSnapshot(
          locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(
            reducedMotion: true,
            textScale: 1.4,
            hapticsEnabled: false,
          ),
          highContrast: true,
          showInputHints: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final hints = find.byKey(
      const ValueKey<String>('runtime-player-input-hints'),
    );
    expect(hints, findsOneWidget);
    expect(tester.getSemantics(hints).label, 'E · M Pause');
  });

  testWidgets('pause footer replaces world input hints', (tester) async {
    const preferences = PlayerPreferencesSnapshot(
      locale: 'fr',
      accessibility: GameSessionAccessibilityOptions(),
      showInputHints: true,
    );
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 1,
        phase: RuntimePlayerPhase.playing,
        preferences: preferences,
      ),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(_view(controller)));
    await tester.pumpAndSettle();
    final hints = find.byKey(
      const ValueKey<String>('runtime-player-input-hints'),
    );
    expect(hints, findsOneWidget);

    controller.publish(
      _snapshot(
        revision: 2,
        phase: RuntimePlayerPhase.paused,
        preferences: preferences,
      ),
    );
    await tester.pumpAndSettle();
    expect(hints, findsNothing);
  });

  testWidgets('runtime haptics follow the projected preference',
      (tester) async {
    var hapticCalls = 0;
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 83,
        phase: RuntimePlayerPhase.playing,
        preferences: const PlayerPreferencesSnapshot(
          locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(
            hapticsEnabled: false,
          ),
        ),
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          gameplayInputRoute: (_) => true,
          touchControlsAvailable: true,
          hapticFeedback: () async => hapticCalls++,
        ),
      ),
    );
    final primary = find.byKey(
      const ValueKey<String>('runtime-player-touch-primary-button'),
    );
    await tester.tap(primary);
    expect(hapticCalls, 0);

    controller.publish(
      _snapshot(
        revision: 84,
        phase: RuntimePlayerPhase.playing,
        preferences: const PlayerPreferencesSnapshot(
          locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(
            hapticsEnabled: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(primary);
    expect(hapticCalls, 1);
  });

  for (final platform in [TargetPlatform.macOS, TargetPlatform.android]) {
    testWidgets(
        'title options expose supported accessibility preferences on $platform',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
        RuntimePlayerSnapshot(
          revision: 85,
          phase: RuntimePlayerPhase.title,
          gameTitle: 'Aube',
          pauseSection: RuntimePlayerPauseSection.options,
          preferences: const PlayerPreferencesSnapshot(
            locale: 'fr',
            accessibility: GameSessionAccessibilityOptions(),
          ),
          actions: const <RuntimePlayerActionAvailability>[
            RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.updatePreferences,
            ),
          ],
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(_view(controller), platform: platform));
      await _selectOptionsCategory(tester, 'accessibility');

      expect(
        find.byKey(
          const ValueKey<String>('runtime-player-reduced-motion-toggle'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('runtime-player-high-contrast-toggle'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('runtime-player-haptics-toggle')),
        platform == TargetPlatform.android ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('runtime-player-text-scale-slider')),
        findsOneWidget,
      );

      await tester.ensureVisible(find.byKey(
        const ValueKey<String>('runtime-player-high-contrast-toggle'),
      ));
      await tester.tap(
        find.byKey(
          const ValueKey<String>('runtime-player-high-contrast-toggle'),
        ),
      );
      await tester.pump();
      final command = controller.commands.single;
      expect(command.action, RuntimePlayerAction.updatePreferences);
      expect(
        (command.payload! as PlayerPreferencesSnapshot).highContrast,
        isTrue,
      );
      await _selectOptionsCategory(tester, 'controls');
      final hints = find
          .byKey(const ValueKey<String>('runtime-player-input-hints-toggle'));
      expect(hints, findsOneWidget);
      await tester.ensureVisible(hints);
      await tester.tap(hints);
      await tester.pumpAndSettle();
      expect(controller.commands, hasLength(2));
      expect(controller.commands.last.action,
          RuntimePlayerAction.updatePreferences);
      final updated =
          controller.commands.last.payload! as PlayerPreferencesSnapshot;
      expect(updated.showInputHints, isFalse);
      expect(updated.highContrast, isTrue);
    });
  }

  testWidgets('shows localized title credits before game completion',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(
      RuntimePlayerSnapshot(
        revision: 10,
        phase: RuntimePlayerPhase.credits,
        gameTitle: 'Aube',
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.finishCredits,
          ),
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.returnToTitle,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller)));

    expect(find.text('Studio Test'), findsOneWidget);
    expect(find.text('Une aventure de test.'), findsOneWidget);
    await tester.tap(find.text('Retour au titre'));

    expect(controller.commands, hasLength(1));
    expect(
      controller.commands.single.action,
      RuntimePlayerAction.returnToTitle,
    );
  });

  testWidgets(
    'dispatches New Game without a host identity dialog',
    (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
        _snapshot(
          revision: 9,
          phase: RuntimePlayerPhase.title,
          actions: const <RuntimePlayerActionAvailability>[
            RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.newGame,
            ),
          ],
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
            ),
            child: _view(
              controller,
              payloadForAction: (_) => const RuntimePlayerLoadSlot(
                profileId: 'player',
                slotId: 'slot_1',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Nouveau jeu'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>('player-new-game-identity-dialog'),
        ),
        findsNothing,
      );

      expect(controller.commands, hasLength(1));
      final command = controller.commands.single;
      expect(command.action, RuntimePlayerAction.newGame);
      expect(command.snapshotRevision, 9);
      final slot = command.payload! as RuntimePlayerLoadSlot;
      expect(slot.profileId, 'player');
      expect(slot.slotId, 'slot_1');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows runtime loading progress and dispatches cancellation',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 11,
      phase: RuntimePlayerPhase.loadingSession,
      loadingProgress: const GameSessionLoadingProgress(
        stage: 'catalogues',
        current: 2,
        total: 4,
      ),
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.cancel),
      ],
    ));
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller)));

    expect(find.text('catalogues'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .value,
      .5,
    );

    await tester.tap(find.text('Annuler'));
    expect(controller.commands.single.action, RuntimePlayerAction.cancel);
    expect(controller.commands.single.snapshotRevision, 11);
  });

  testWidgets('routes a preSession result through the Player command',
      (tester) async {
    final request = SceneInteractionRequest.message(
      requestId: 'pre-session-intro',
      revision: 3,
      prompt: SceneInteractionPrompt(
        localizationKey: 'test.pre_session.intro',
        fallbackText: 'Bienvenue à Avelune.',
      ),
    );
    final controller = _FakeRuntimePlayerCoordinator(
      RuntimePlayerSnapshot(
        revision: 12,
        phase: RuntimePlayerPhase.preSession,
        gameTitle: 'Aube',
        preSessionRequest: request,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.resolvePreSessionInteraction,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller)));
    final tapZone =
        find.byKey(const ValueKey<String>('dialogue-tap-zone')).first;
    await tester.tap(tapZone);
    await tester.pump();
    expect(
      find.text('Bienvenue à Avelune.'),
      findsOneWidget,
      reason: 'the first press completed the typewriter',
    );
    await tester.tap(tapZone);
    await tester.pump();

    final command = controller.commands.single;
    expect(
      command.action,
      RuntimePlayerAction.resolvePreSessionInteraction,
    );
    expect(command.snapshotRevision, 12);
    expect(
      command.payload,
      isA<SceneAcknowledgedInteractionResult>()
          .having((result) => result.requestId, 'requestId', request.requestId)
          .having((result) => result.revision, 'revision', request.revision),
    );
  });

  testWidgets(
    'keeps a Presentation cue interaction above the active frame',
    (tester) async {
      final request = SceneInteractionRequest.message(
        requestId: 'presentation-cue',
        revision: 4,
        prompt: SceneInteractionPrompt(
          localizationKey: 'test.pre_session.cue',
          fallbackText: 'Quel est ton prénom ?',
        ),
      );
      final controller = _FakeRuntimePlayerCoordinator(
        RuntimePlayerSnapshot(
          revision: 18,
          phase: RuntimePlayerPhase.preSession,
          gameTitle: 'Aube',
          preSessionRequest: request,
          actions: const <RuntimePlayerActionAvailability>[
            RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.resolvePreSessionInteraction,
            ),
          ],
        ),
      );
      final presentation = ValueNotifier<RuntimePresentationFrameSnapshot?>(
        RuntimePresentationFrameSnapshot(
          assetRevision: 'opening-revision-8',
          frame: _presentationFrame(),
          orientation: PresentationFrameOrientation.portrait,
        ),
      );
      addTearDown(controller.dispose);
      addTearDown(presentation.dispose);

      await tester.pumpWidget(
        _app(
          _view(
            controller,
            presentationFrame: presentation,
            presentationContentPort: _PresentationContentPort(),
          ),
        ),
      );

      final tapZone =
          find.byKey(const ValueKey<String>('dialogue-tap-zone')).first;
      await tester.tap(tapZone);
      await tester.pump();
      expect(find.text('Quel est ton prénom ?'), findsOneWidget);
      await tester.tap(tapZone);
      await tester.pump();

      expect(controller.commands, hasLength(1));
      expect(
        controller.commands.single.action,
        RuntimePlayerAction.resolvePreSessionInteraction,
      );
      expect(controller.commands.single.snapshotRevision, 18);
    },
  );

  testWidgets(
    'keeps preSession presentation chrome out of the cinematic',
    (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
        RuntimePlayerSnapshot(
          revision: 19,
          phase: RuntimePlayerPhase.preSession,
          gameTitle: 'Aube',
          preferences: const PlayerPreferencesSnapshot(
            locale: 'fr',
            accessibility: GameSessionAccessibilityOptions(),
            showInputHints: true,
          ),
        ),
      );
      final presentation = ValueNotifier<RuntimePresentationFrameSnapshot?>(
        RuntimePresentationFrameSnapshot(
          assetRevision: 'opening-revision-9',
          frame: _presentationFrame(),
          orientation: PresentationFrameOrientation.landscape,
        ),
      );
      var skipCalls = 0;
      addTearDown(controller.dispose);
      addTearDown(presentation.dispose);

      await tester.pumpWidget(
        _app(
          _view(
            controller,
            presentationFrame: presentation,
            presentationContentPort: _PresentationContentPort(),
            onPresentationSkip: () async => skipCalls += 1,
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('runtime-presentation-skip')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('runtime-player-input-hints')),
        findsNothing,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(skipCalls, 0);
    },
  );

  testWidgets('leaves keyboard letters to a focused preSession text field',
      (tester) async {
    final request = SceneInteractionRequest.text(
      requestId: 'player-name',
      revision: 1,
      prompt: SceneInteractionPrompt(
        localizationKey: 'newGame.playerName.prompt',
        fallbackText: 'Quel est ton prénom ?',
      ),
      constraints: SceneTextInputConstraints(
        minGraphemes: 1,
        maxGraphemes: 24,
      ),
    );
    final controller = _FakeRuntimePlayerCoordinator(
      RuntimePlayerSnapshot(
        revision: 20,
        phase: RuntimePlayerPhase.preSession,
        gameTitle: 'Aube',
        preSessionRequest: request,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.resolvePreSessionInteraction,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller)));
    await tester.tap(
      find.byKey(const ValueKey<String>('scene-interaction-text-field')),
    );
    await tester.pumpAndSettle();

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'Scene interaction text',
    );
    final inputAuthority = tester.widget<Focus>(
      find.byKey(
        const ValueKey<String>('runtime-player-keyboard-input-authority'),
      ),
    );
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    for (final key in const <(PhysicalKeyboardKey, LogicalKeyboardKey)>[
      (PhysicalKeyboardKey.keyW, LogicalKeyboardKey.keyW),
      (PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA),
      (PhysicalKeyboardKey.keyS, LogicalKeyboardKey.keyS),
      (PhysicalKeyboardKey.keyD, LogicalKeyboardKey.keyD),
    ]) {
      expect(
        inputAuthority.onKeyEvent!(
          focusNode,
          KeyDownEvent(
            physicalKey: key.$1,
            logicalKey: key.$2,
            timeStamp: Duration.zero,
          ),
        ),
        KeyEventResult.ignored,
      );
    }

    expect(controller.commands, isEmpty);
  });

  testWidgets('keeps the game scene mounted only across live session phases',
      (tester) async {
    final lifecycle = _SceneLifecycle();
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(revision: 1, phase: RuntimePlayerPhase.loadingSession),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller, lifecycle: lifecycle)));
    expect(lifecycle.mounts, 1);
    expect(lifecycle.disposals, 0);

    for (final phase in <RuntimePlayerPhase>[
      RuntimePlayerPhase.playing,
      RuntimePlayerPhase.paused,
      RuntimePlayerPhase.saving,
      RuntimePlayerPhase.lifecyclePaused,
      RuntimePlayerPhase.completing,
      RuntimePlayerPhase.disposingSession,
    ]) {
      controller.publish(_snapshot(revision: phase.index + 10, phase: phase));
      await tester.pump();
      expect(lifecycle.mounts, 1);
      expect(lifecycle.disposals, 0);
    }

    controller.publish(_snapshot(
      revision: 30,
      phase: RuntimePlayerPhase.result,
    ));
    await tester.pump();
    expect(lifecycle.disposals, 1);
  });

  testWidgets('renders a contextual shop over the mounted runtime scene',
      (tester) async {
    final lifecycle = _SceneLifecycle();
    final service = RuntimeWorldServiceSnapshot(
      revision: 4,
      request: const OpenShopService(
        interactionId: 'npc.merchant',
        shopId: 'mart',
      ),
      stage: RuntimeWorldServiceStage.active,
      content: RuntimeShopServiceContent(
        title: 'Boutique du Port',
        message: 'Bienvenue !',
        money: 500,
        entries: const <RuntimeShopEntrySnapshot>[
          RuntimeShopEntrySnapshot(
            itemId: 'potion',
            label: 'Potion',
            unitPrice: 60,
          ),
        ],
        selectedItemId: 'potion',
        totalPrice: 60,
      ),
      actions: const <RuntimeWorldServiceActionAvailability>[
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.confirm,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.close,
        ),
      ],
    );
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 18,
        phase: RuntimePlayerPhase.playing,
        worldService: service,
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller, lifecycle: lifecycle)));

    expect(
        find.byKey(const ValueKey<String>('test-game-scene')), findsOneWidget);
    expect(find.text('Boutique du Port'), findsOneWidget);
    expect(lifecycle.mounts, 1);

    await tester.tap(find.byKey(const ValueKey<String>('shop-close')));
    expect(controller.worldServiceCommands.single.action,
        RuntimeWorldServiceAction.close);
    expect(controller.worldServiceCommands.single.snapshotRevision, 4);
  });

  testWidgets('renders contextual healing over the mounted runtime scene',
      (tester) async {
    final lifecycle = _SceneLifecycle();
    final service = RuntimeWorldServiceSnapshot(
      revision: 12,
      request: const OpenHealService(interactionId: 'npc.nurse'),
      stage: RuntimeWorldServiceStage.active,
      content: RuntimeHealServiceContent(
        title: 'Centre Pokémon',
        message: 'Soigner l’équipe ?',
        members: const <RuntimeHealPartyMemberSnapshot>[
          RuntimeHealPartyMemberSnapshot(
            partyIndex: 0,
            label: 'Sproutle',
            currentHp: 3,
            maxHp: 24,
            hasStatus: true,
            depletedMoveCount: 1,
          ),
        ],
      ),
      actions: const <RuntimeWorldServiceActionAvailability>[
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.confirm,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.cancel,
        ),
      ],
    );
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 21,
        phase: RuntimePlayerPhase.playing,
        worldService: service,
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller, lifecycle: lifecycle)));

    expect(
        find.byKey(const ValueKey<String>('test-game-scene')), findsOneWidget);
    expect(find.text('Centre Pokémon'), findsOneWidget);
    expect(lifecycle.mounts, 1);
    await tester.tap(find.byKey(const ValueKey<String>('heal-confirm')));
    expect(controller.worldServiceCommands.single.action,
        RuntimeWorldServiceAction.confirm);
    expect(controller.worldServiceCommands.single.snapshotRevision, 12);
  });

  testWidgets('renders the contextual PC over the mounted runtime scene',
      (tester) async {
    final lifecycle = _SceneLifecycle();
    final service = RuntimeWorldServiceSnapshot(
      revision: 14,
      request: const OpenPcService(
        interactionId: 'terminal.harbor',
        storageId: 'box-a',
      ),
      stage: RuntimeWorldServiceStage.active,
      content: RuntimePcServiceContent(
        title: 'PC Pokémon',
        message: 'Organisez votre équipe.',
        selectedBoxId: 'box-a',
        boxes: const <RuntimePcBoxSnapshot>[
          RuntimePcBoxSnapshot(
            boxId: 'box-a',
            label: 'Box A',
            count: 0,
            capacity: 30,
          ),
        ],
      ),
      actions: const <RuntimeWorldServiceActionAvailability>[
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.select,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.close,
        ),
      ],
    );
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 22,
        phase: RuntimePlayerPhase.playing,
        worldService: service,
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller, lifecycle: lifecycle)));

    expect(
        find.byKey(const ValueKey<String>('test-game-scene')), findsOneWidget);
    expect(find.text('PC Pokémon'), findsOneWidget);
    expect(lifecycle.mounts, 1);
    await tester.tap(find.byKey(const ValueKey<String>('pc-close')));
    expect(controller.worldServiceCommands.single.action,
        RuntimeWorldServiceAction.close);
    expect(controller.worldServiceCommands.single.snapshotRevision, 14);
  });

  testWidgets('keeps an actionable new game error readable on a phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 19,
      phase: RuntimePlayerPhase.error,
      failure: const GameSessionFailure(
        code: GameSessionFailureCode.runtime,
        diagnosticCode: 'new_game.seed_commit_stale_project',
        recoverability: GameSessionFailureRecoverability.retry,
        safeMessage: 'Le contenu du jeu a changé pendant la préparation. '
            'Relancez la création de la partie.',
      ),
      actions: const [
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.retry),
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.cancel),
      ],
    ));
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(_view(controller)));
    await tester.pump(const Duration(seconds: 30));
    expect(find.textContaining('changé'), findsOneWidget);
    expect(find.text('new_game.seed_commit_stale_project'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Fermer'));
    await tester.tap(find.text('Fermer'));
    expect(controller.commands.single.action, RuntimePlayerAction.cancel);
  });

  testWidgets('shows safe error context and optional diagnostics',
      (tester) async {
    var diagnosticCalls = 0;
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 19,
      phase: RuntimePlayerPhase.error,
      loadingProgress: const GameSessionLoadingProgress(
        stage: 'project',
        current: 1,
        total: 3,
      ),
      failure: const GameSessionFailure(
        code: GameSessionFailureCode.integrity,
        recoverability: GameSessionFailureRecoverability.repair,
        safeMessage: 'Un fichier du jeu est invalide.',
      ),
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.retry),
      ],
    ));
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(
      controller,
      onShowDiagnostics: () => diagnosticCalls++,
    )));

    expect(find.text('Un fichier du jeu est invalide.'), findsOneWidget);
    expect(find.textContaining('project'), findsOneWidget);
    expect(find.textContaining('integrity'), findsOneWidget);
    expect(find.textContaining('réparez'), findsOneWidget);

    await tester.tap(find.text('Diagnostics'));
    expect(diagnosticCalls, 1);
  });

  testWidgets(
      'owns responsive virtual controls in portrait and landscape gameplay',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final gameplayEvents = <RuntimeInputEvent>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 23,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          touchControlsAvailable: true,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-movement-zone')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-primary-button'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-secondary-button'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-primary-button'),
      ),
    );
    expect(
      gameplayEvents,
      const <RuntimeInputEvent>[
        RuntimeInputEvent.press(RuntimeInputControl.primary),
        RuntimeInputEvent.release(RuntimeInputControl.primary),
      ],
    );

    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-movement-zone')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'hides every touch affordance outside authoritative overworld input',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final authority = ValueNotifier<RuntimeInputAuthoritySnapshot>(
      const RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.overworld,
      ),
    );
    addTearDown(authority.dispose);
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 25,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          touchControlsAvailable: true,
          gameplayInputRoute: (_) => true,
          gameplayInputAuthority: authority,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-movement-zone')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-menu-open')),
      findsOneWidget,
    );

    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.battle,
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-movement-zone')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-primary-button'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-secondary-button'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-menu-open')),
      findsNothing,
    );

    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.dialogue,
    );
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-primary-button'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-menu-open')),
      findsNothing,
    );

    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld,
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-movement-zone')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-primary-button'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders the runtime dialogue overlay and routes a panel tap',
      (tester) async {
    final authority = ValueNotifier<RuntimeInputAuthoritySnapshot>(
      const RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.dialogue,
      ),
    );
    final dialogue = ValueNotifier<DialoguePresentationSnapshot?>(
      const DialoguePresentationSnapshot(
        revision: 8,
        mode: DialoguePresentationMode.line,
        nodeTitle: 'intro',
        speaker: 'Lysa',
        text: 'Appuie ici pour continuer.',
        fullText: 'Appuie ici pour continuer.',
        isCurrentLineFullyRevealed: true,
        isLastContent: false,
        choices: <DialoguePresentationChoice>[],
      ),
    );
    addTearDown(authority.dispose);
    addTearDown(dialogue.dispose);
    final commands = <DialoguePresentationCommand>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 26,
        phase: RuntimePlayerPhase.playing,
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          touchControlsAvailable: true,
          gameplayInputRoute: (_) => true,
          gameplayInputAuthority: authority,
          dialoguePresentation: dialogue,
          onDialogueCommand: commands.add,
        ),
      ),
    );

    expect(find.text('Appuie ici pour continuer.'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('dialogue-tap-zone')),
    );
    expect(
      commands.single,
      isA<DialogueAdvanceCommand>().having(
        (command) => command.snapshotRevision,
        'revision',
        8,
      ),
    );
    final preservedDialogue = dialogue.value;
    controller
        .publish(_snapshot(revision: 27, phase: RuntimePlayerPhase.paused));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dialogue-tap-zone')), findsNothing);
    expect(dialogue.value, same(preservedDialogue));
    controller
        .publish(_snapshot(revision: 28, phase: RuntimePlayerPhase.playing));
    await tester.pumpAndSettle();
    expect(find.text('Appuie ici pour continuer.'), findsOneWidget);
    expect(commands, hasLength(1));
  });

  testWidgets('renders the canonical battle overlay and routes its command',
      (tester) async {
    final battle = ValueNotifier<BattleCommandOverlaySnapshot?>(
      const BattleCommandOverlaySnapshot(
        revision: 12,
        mode: BattleCommandOverlayMode.root,
        viewportSize: Size(800, 600),
        panelRect: Rect.fromLTWH(0, 300, 800, 300),
        enemyHud: BattleCommandOverlayHudSnapshot(
          rect: Rect.fromLTWH(20, 20, 240, 80),
          ownerLabel: 'Adversaire',
          speciesLabel: 'Roucool',
          level: 7,
          currentHp: 20,
          maxHp: 20,
          isPlayerSide: false,
        ),
        playerHud: BattleCommandOverlayHudSnapshot(
          rect: Rect.fromLTWH(540, 200, 240, 80),
          ownerLabel: 'Joueur',
          speciesLabel: 'Brindibou',
          level: 8,
          currentHp: 24,
          maxHp: 24,
          isPlayerSide: true,
        ),
        battleLabel: 'Combat sauvage',
        title: 'Roucool sauvage',
        prompt: 'Que doit faire Brindibou ?',
        narrationLines: <String>[],
        entries: <BattleCommandOverlayEntry>[
          BattleCommandOverlayEntry(
            index: 0,
            kind: BattleCommandOverlayEntryKind.root,
            primaryLabel: 'Attaque',
            secondaryLabel: 'Choisir une capacité',
            enabled: true,
            selected: true,
            tone: BattleCommandOverlayEntryTone.attack,
          ),
        ],
        interactionsEnabled: true,
        canGoBack: false,
      ),
    );
    addTearDown(battle.dispose);
    final commands = <BattlePresentationCommand>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 27,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu),
        ],
        preferences: const PlayerPreferencesSnapshot(
          locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(),
          showInputHints: true,
        ),
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          battlePresentation: battle,
          onBattleCommand: commands.add,
        ),
      ),
    );

    expect(find.byType(PlayerBattleOverlay), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('runtime-player-input-hints')),
      findsNothing,
    );
    expect(find.text('Roucool'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();
    expect(controller.commands, isEmpty);
    await tester.tap(
      find.byKey(const ValueKey<String>('battle-entry-0')),
    );
    expect(
      commands.single,
      isA<BattleSelectEntryCommand>()
          .having((command) => command.snapshotRevision, 'revision', 12)
          .having((command) => command.entryIndex, 'entry', 0),
    );

    battle.value = null;
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
    expect(
      find.byKey(const ValueKey<String>('runtime-player-input-hints')),
      findsOneWidget,
    );
  });

  testWidgets('applies touch opacity and clamps floating visual inside viewport',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 27,
        phase: RuntimePlayerPhase.playing,
        preferences: const PlayerPreferencesSnapshot(
          locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(),
          touchControlsOpacity: .45,
        ),
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          touchControlsAvailable: true,
          gameplayInputRoute: (_) => true,
        ),
      ),
    );

    final gesture = await tester.startGesture(const Offset(20, 820), kind: ui.PointerDeviceKind.touch);
    await tester.pump();
    expect(
      tester
          .getBottomLeft(
            find.byKey(
              const ValueKey<String>('runtime-player-touch-joystick'),
            ),
          )
          .dy,
      lessThanOrEqualTo(844),
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(
              const ValueKey<String>('runtime-player-touch-controls-opacity'),
            ),
          )
          .opacity,
      .45,
    );
    await gesture.up();
  });

  testWidgets('rejects exploration menu input while battle owns input',
      (tester) async {
    final authority = ValueNotifier<RuntimeInputAuthoritySnapshot>(
      const RuntimeInputAuthoritySnapshot(
          context: RuntimeInputContext.overworld),
    );
    final controllerEvents = StreamController<RuntimeInputEvent>.broadcast();
    final gameplayEvents = <RuntimeInputEvent>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 24,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu),
        ],
      ),
    );
    addTearDown(authority.dispose);
    addTearDown(controllerEvents.close);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(_view(
      controller,
      touchControlsAvailable: true,
      gameplayInputAuthority: authority,
      controllerInputEvents: controllerEvents.stream,
      gameplayInputRoute: (event) {
        gameplayEvents.add(event);
        return true;
      },
    )));

    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.battle,
    );
    await tester.tap(find.byKey(
      const ValueKey<String>('runtime-player-touch-menu-open'),
    ));
    await tester.pump();
    expect(controller.commands, isEmpty);

    for (final context in [
      RuntimeInputContext.battle,
      RuntimeInputContext.transition,
    ]) {
      authority.value = RuntimeInputAuthoritySnapshot(context: context);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      controllerEvents.add(
        const RuntimeInputEvent.press(RuntimeInputControl.menu),
      );
      await tester.pump();
      expect(controller.commands, isEmpty, reason: context.name);
    }
    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.battle,
    );
    controllerEvents.add(
      const RuntimeInputEvent.press(RuntimeInputControl.primary),
    );
    await tester.pump();
    expect(gameplayEvents.last.control, RuntimeInputControl.primary);

    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
  });

  testWidgets('preserves exploration pause during dialogue', (tester) async {
    final authority = ValueNotifier<RuntimeInputAuthoritySnapshot>(
      const RuntimeInputAuthoritySnapshot(
          context: RuntimeInputContext.dialogue),
    );
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 24,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu),
        ],
      ),
    );
    addTearDown(authority.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(_view(
      controller,
      gameplayInputAuthority: authority,
    )));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
  });

  testWidgets('routes controller gameplay and reserves Start for pause',
      (tester) async {
    final controllerEvents = StreamController<RuntimeInputEvent>.broadcast();
    addTearDown(controllerEvents.close);
    final gameplayEvents = <RuntimeInputEvent>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 24,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          controllerInputEvents: controllerEvents.stream,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );

    controllerEvents.add(
      const RuntimeInputEvent.press(RuntimeInputControl.right),
    );
    await tester.pump();
    expect(
      gameplayEvents,
      const <RuntimeInputEvent>[
        RuntimeInputEvent.press(RuntimeInputControl.right),
      ],
    );

    controllerEvents.add(
      const RuntimeInputEvent.press(RuntimeInputControl.menu),
    );
    await tester.pump();
    expect(gameplayEvents, hasLength(2));
    expect(
      gameplayEvents.skip(1),
      const <RuntimeInputEvent>[
        RuntimeInputEvent.release(RuntimeInputControl.right),
      ],
    );
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
    expect(controller.commands.single.snapshotRevision, 24);
  });

  testWidgets('routes keyboard gameplay and Menu through one player ingress',
      (tester) async {
    final gameplayEvents = <RuntimeInputEvent>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 31,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          controllerInputEnabled: true,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();

    expect(
      gameplayEvents,
      const <RuntimeInputEvent>[
        RuntimeInputEvent.press(RuntimeInputControl.right),
        RuntimeInputEvent.release(RuntimeInputControl.right),
      ],
    );
    expect(controller.commands, hasLength(1));
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
    expect(controller.commands.single.snapshotRevision, 31);
  });

  testWidgets('routes a remapped keyboard profile through the canonical seam',
      (tester) async {
    final gameplayEvents = <RuntimeInputEvent>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(revision: 32, phase: RuntimePlayerPhase.playing),
    );
    addTearDown(controller.dispose);
    final profile = PlayerControlProfile.standard
        .rebind(
          device: PlayerControlDevice.keyboard,
          control: RuntimeInputControl.primary,
          inputId: 'keyZ',
        )
        .profile;

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          controlProfile: profile,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.pump();

    expect(
      gameplayEvents,
      const <RuntimeInputEvent>[
        RuntimeInputEvent.press(RuntimeInputControl.primary),
        RuntimeInputEvent.release(RuntimeInputControl.primary),
      ],
    );
  });

  testWidgets('consumes repeated Menu and plugin-owned hardware gamepad keys',
      (tester) async {
    final gameplayEvents = <RuntimeInputEvent>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 32,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          controllerInputEnabled: true,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );

    final inputAuthority = tester.widget<Focus>(
      find.byKey(
        const ValueKey<String>('runtime-player-keyboard-input-authority'),
      ),
    );
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    expect(
      inputAuthority.onKeyEvent!(
        focusNode,
        const KeyRepeatEvent(
          physicalKey: PhysicalKeyboardKey.keyM,
          logicalKey: LogicalKeyboardKey.keyM,
          timeStamp: Duration.zero,
        ),
      ),
      KeyEventResult.handled,
    );
    expect(
      inputAuthority.onKeyEvent!(
        focusNode,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.gameButtonA,
          logicalKey: LogicalKeyboardKey.gameButtonA,
          timeStamp: Duration.zero,
          deviceType: ui.KeyEventDeviceType.gamepad,
        ),
      ),
      KeyEventResult.handled,
    );
    await tester.pump();

    expect(gameplayEvents, isEmpty);
    expect(controller.commands, isEmpty);

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          controllerInputEnabled: false,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );
    final hardwareFallback = tester.widget<Focus>(
      find.byKey(
        const ValueKey<String>('runtime-player-keyboard-input-authority'),
      ),
    );
    expect(
      hardwareFallback.onKeyEvent!(
        focusNode,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.gameButtonA,
          logicalKey: LogicalKeyboardKey.gameButtonA,
          timeStamp: Duration.zero,
          deviceType: ui.KeyEventDeviceType.gamepad,
        ),
      ),
      KeyEventResult.handled,
    );
    await tester.pump();
    expect(
      gameplayEvents,
      const <RuntimeInputEvent>[
        RuntimeInputEvent.press(RuntimeInputControl.primary),
      ],
      reason:
          'Standalone embedders can opt into Flutter hardware gamepad keys.',
    );
  });

  testWidgets('blocks gameplay while an asynchronous Menu transition settles',
      (tester) async {
    final menuTransition = Completer<RuntimePlayerCommandResult>();
    final gameplayEvents = <RuntimeInputEvent>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 33,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
      commandCompleter: menuTransition,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );
    final inputAuthority = tester.widget<Focus>(
      find.byKey(
        const ValueKey<String>('runtime-player-keyboard-input-authority'),
      ),
    );
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    inputAuthority.onKeyEvent!(
      focusNode,
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyM,
        logicalKey: LogicalKeyboardKey.keyM,
        timeStamp: Duration.zero,
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-menu-open'),
      ),
    );
    await tester.pump();
    inputAuthority.onKeyEvent!(
      focusNode,
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      ),
    );
    await tester.pump();

    expect(controller.commands, hasLength(1));
    expect(
      gameplayEvents,
      isEmpty,
      reason: 'No new gameplay press may enter while Menu is opening.',
    );

    controller.publish(
      _snapshot(
        revision: 34,
        phase: RuntimePlayerPhase.paused,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.resume,
          ),
        ],
      ),
    );
    menuTransition.complete(
      const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.accepted,
      ),
    );
    await tester.pump();
  });
}

void _expectTouchControls(WidgetTester tester, bool visible) {
  final opacity = tester
      .widget<Opacity>(
          find.byKey(const ValueKey('runtime-player-touch-controls-opacity')))
      .opacity;
  expect(opacity, visible ? greaterThan(0) : 0);
  expect(find.byKey(const ValueKey('runtime-player-touch-primary-button')),
      visible ? findsOneWidget : findsNothing);
}

NormalizedGamepadEvent _padInput(
        {GamepadButton? button,
        GamepadAxis? axis,
        double value = 1,
        String gamepadId = 'pad',
        int? vendorId,
        int? productId}) =>
    NormalizedGamepadEvent(
      gamepadId: gamepadId,
      timestamp: 1,
      value: value,
      button: button,
      axis: axis,
      rawEvent: GamepadEvent(
          gamepadId: gamepadId,
          vendorId: vendorId,
          productId: productId,
          timestamp: 1,
          type: button == null ? KeyType.analog : KeyType.button,
          key: (button?.name ?? axis!.name),
          value: value),
    );

PokeMapPlayerSessionView _view(
  RuntimePlayerViewController controller, {
  _SceneLifecycle? lifecycle,
  GlobalKey? gameplayViewportKey,
  WidgetBuilder? gameSceneBuilder,
  VoidCallback? onShowDiagnostics,
  bool touchControlsAvailable = false,
  PlayerGameplayInputRoute? gameplayInputRoute,
  Stream<RuntimeInputEvent>? controllerInputEvents,
  Stream<NormalizedGamepadEvent>? normalizedControllerInputEvents,
  ValueListenable<Set<String>>? connectedControllerIds,
  ValueListenable<RuntimeInputAuthoritySnapshot>? gameplayInputAuthority,
  ValueListenable<DialoguePresentationSnapshot?>? dialoguePresentation,
  ValueChanged<DialoguePresentationCommand>? onDialogueCommand,
  ValueListenable<BattleCommandOverlaySnapshot?>? battlePresentation,
  ValueChanged<BattlePresentationCommand>? onBattleCommand,
  bool? controllerInputEnabled,
  RuntimePlayerActionPayloadBuilder? payloadForAction,
  Future<void> Function()? hapticFeedback,
  PlayerControlProfile? controlProfile,
  ValueListenable<RuntimePresentationFrameSnapshot?>? presentationFrame,
  PresentationFrameContentPort? presentationContentPort,
  Future<void> Function()? onPresentationSkip,
}) {
  final viewportKey = gameplayViewportKey ?? GlobalKey();
  return PokeMapPlayerSessionView(
    gameplayViewportKey: viewportKey,
    controller: controller,
    titlePresentation: const RuntimePlayerTitlePresentation(
      author: 'Studio Test',
      description: 'Une aventure de test.',
    ),
    payloadForAction: payloadForAction,
    gameSceneBuilder: gameSceneBuilder ?? (_) => SizedBox.expand(key: viewportKey, child: _SceneProbe(
      key: const ValueKey<String>('test-game-scene'),
      lifecycle: lifecycle ?? _SceneLifecycle(),
    )),
    touchControlsAvailable: touchControlsAvailable,
    gameplayInputRoute: gameplayInputRoute,
    gameplayInputAuthority: gameplayInputAuthority,
    dialoguePresentation: dialoguePresentation,
    onDialogueCommand: onDialogueCommand,
    battlePresentation: battlePresentation,
    onBattleCommand: onBattleCommand,
    controllerInputEvents: controllerInputEvents,
    normalizedControllerInputEvents: normalizedControllerInputEvents,
    connectedControllerIds: connectedControllerIds,
    controllerInputEnabled: controllerInputEnabled ??
        (controllerInputEvents != null ||
            normalizedControllerInputEvents != null),
    onShowDiagnostics: onShowDiagnostics,
    hapticFeedback: hapticFeedback,
    controlProfile: controlProfile,
    presentationFrame: presentationFrame,
    presentationContentPort: presentationContentPort,
    onPresentationSkip: onPresentationSkip,
  );
}

RuntimePlayerSnapshot _snapshot({
  required int revision,
  required RuntimePlayerPhase phase,
  List<RuntimePlayerActionAvailability> actions =
      const <RuntimePlayerActionAvailability>[],
  GameSessionLoadingProgress? loadingProgress,
  GameSessionFailure? failure,
  RuntimeWorldServiceSnapshot? worldService,
  PlayerPreferencesSnapshot? preferences,
}) {
  return RuntimePlayerSnapshot(
    revision: revision,
    phase: phase,
    gameTitle: 'Aube',
    pauseSection: phase == RuntimePlayerPhase.paused
        ? RuntimePlayerPauseSection.root
        : null,
    actions: actions,
    loadingProgress: loadingProgress,
    failure: failure,
    worldService: worldService,
    preferences: preferences,
    result: phase == RuntimePlayerPhase.result
        ? const GameResultSnapshot(
            title: 'Victoire',
            summary: 'La région est sauvée.',
          )
        : null,
    credits: phase == RuntimePlayerPhase.result ||
            phase == RuntimePlayerPhase.credits
        ? const GameCreditsSnapshot(
            title: 'Aube',
            author: 'Studio Test',
            endingLabel: 'Fin principale',
          )
        : null,
  );
}

Finder _surfaceFinder(RuntimePlayerPhase phase) => find.byKey(
      ValueKey<String>('runtime-player-surface-${phase.name}'),
    );

Finder _allCanonicalSurfaces() => find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          ((widget.key! as ValueKey<String>).value)
              .startsWith('runtime-player-surface-'),
    );

Future<void> _hardwareGamepadPress(WidgetTester tester,
    LogicalKeyboardKey logical, PhysicalKeyboardKey physical) async {
  Future<bool> send(bool isDown) async {
    final response = Completer<bool>();
    final data = KeyEventSimulator.getKeyData(logical,
        platform: 'android', isDown: isDown, physicalKey: physical)
      ..['source'] = 0x00000401;
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.keyEvent.name,
      SystemChannels.keyEvent.codec.encodeMessage(data),
      (reply) {
        final value = SystemChannels.keyEvent.codec.decodeMessage(reply)
            as Map<Object?, Object?>?;
        response.complete(value?['handled'] == true);
      },
    );
    return response.future;
  }

  try {
    expect(await send(true), isTrue);
  } finally {
    await send(false);
  }
}

RuntimePlayerSnapshot _titleOptionsSnapshot() => RuntimePlayerSnapshot(
      revision: 86,
      phase: RuntimePlayerPhase.title,
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.options,
      preferences: const PlayerPreferencesSnapshot(
          locale: 'fr', accessibility: GameSessionAccessibilityOptions()),
      actions: const [
        RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openOptions),
        RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.updatePreferences),
        RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.returnToTitle),
      ],
    );

Future<void> _selectOptionsCategory(
    WidgetTester tester, String category) async {
  final target = find.byKey(ValueKey('options-category-$category'));
  if (target.evaluate().isEmpty) {
    await tester.tap(find.byKey(const ValueKey('options-category-picker')));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Widget _app(Widget child, {TargetPlatform? platform}) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark().copyWith(platform: platform),
      home: child,
    );

final class _FakeRuntimePlayerCoordinator
    implements RuntimePlayerViewController {
  _FakeRuntimePlayerCoordinator(
    this._snapshot, {
    this.commandCompleter,
  });

  final _snapshots = StreamController<RuntimePlayerSnapshot>.broadcast();
  final Completer<RuntimePlayerCommandResult>? commandCompleter;
  final commands = <RuntimePlayerCommand>[];
  final backRequests = <int>[];
  final worldServiceCommands = <RuntimeWorldServiceCommand>[];
  RuntimePlayerSnapshot _snapshot;

  @override
  RuntimePlayerSnapshot get snapshot => _snapshot;

  @override
  Stream<RuntimePlayerSnapshot> get snapshots => _snapshots.stream;

  void publish(RuntimePlayerSnapshot snapshot) {
    _snapshot = snapshot;
    _snapshots.add(snapshot);
  }

  @override
  Future<RuntimePlayerCommandResult> dispatch(
    RuntimePlayerCommand command,
  ) async {
    commands.add(command);
    final pending = commandCompleter;
    if (pending != null) return pending.future;
    return const RuntimePlayerCommandResult(
      status: RuntimePlayerCommandStatus.accepted,
    );
  }

  @override
  Future<RuntimePlayerCommandResult> requestBack({
    required int snapshotRevision,
  }) async {
    backRequests.add(snapshotRevision);
    return const RuntimePlayerCommandResult(
      status: RuntimePlayerCommandStatus.accepted,
    );
  }

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  ) async {
    worldServiceCommands.add(command);
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
    );
  }

  Future<void> dispose() => _snapshots.close();
}

final class _SceneLifecycle {
  int mounts = 0;
  int disposals = 0;
}

class _SceneProbe extends StatefulWidget {
  const _SceneProbe({
    super.key,
    required this.lifecycle,
  });

  final _SceneLifecycle lifecycle;

  @override
  State<_SceneProbe> createState() => _SceneProbeState();
}

class _SceneProbeState extends State<_SceneProbe> {
  @override
  void initState() {
    super.initState();
    widget.lifecycle.mounts++;
  }

  @override
  void dispose() {
    widget.lifecycle.disposals++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.black);
}

final class _PresentationContentPort implements PresentationFrameContentPort {
  final visualRequests = <String>[];

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) {
    visualRequests.add(clip.resourceId);
    return const PresentationVisualReady(child: SizedBox.expand());
  }

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) =>
      const PresentationCaptionReady(text: 'Sous-titre');
}

PresentationFrame _presentationFrame() => PresentationFrame(
      cinematicId: 'opening',
      timeUs: 750000,
      durationUs: 2000000,
      visuals: <PresentationVisualFrameClip>[
        PresentationVisualFrameClip(
          clipId: 'opening-visual',
          trackId: 'visuals',
          layerId: 'background',
          zIndex: 0,
          resourceId: 'opening-shared',
          startUs: 0,
          durationUs: 2000000,
          elapsedUs: 750000,
          progress: .375,
          easedProgress: .375,
          easing: PresentationEasing.linear,
          composition: PresentationVisualComposition(),
          reducedMotionComposition: PresentationVisualComposition(),
        ),
      ],
    );
