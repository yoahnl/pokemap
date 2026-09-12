import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final replaceProfile in [true, false]) {
    testWidgets(
        'OW007 gamepad rebind requires physical neutral: profile $replaceProfile',
        (tester) async {
      final coordinator = _Coordinator();
      final firstStream =
          StreamController<NormalizedGamepadEvent>.broadcast(sync: true);
      final secondStream =
          StreamController<NormalizedGamepadEvent>.broadcast(sync: true);
      final connected = ValueNotifier<Set<String>>({'pad'});
      final events = <RuntimeInputEvent>[];
      final initialProfile = PlayerControlProfile.standard.swapBindings(
        device: PlayerControlDevice.gamepad,
        first: RuntimeInputControl.sprint,
        second: RuntimeInputControl.left,
      );
      final updatedProfile = initialProfile.swapBindings(
        device: PlayerControlDevice.gamepad,
        first: RuntimeInputControl.sprint,
        second: RuntimeInputControl.right,
      );
      addTearDown(coordinator.changes.close);
      addTearDown(firstStream.close);
      addTearDown(secondStream.close);
      addTearDown(connected.dispose);

      Widget app(PlayerControlProfile profile,
              Stream<NormalizedGamepadEvent> stream) =>
          MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
            localizationsDelegates:
                PokeMapPlayerLocalizations.localizationsDelegates,
            theme: PokeMapPlayerTheme.dark(),
            home: PokeMapPlayerSessionView(
              controller: coordinator,
              titlePresentation: const RuntimePlayerTitlePresentation(
                  author: 'QA', description: 'Rebranchement manette'),
              gameSceneBuilder: (_) => const SizedBox.expand(),
              touchControlsAvailable: false,
              controllerInputEnabled: true,
              normalizedControllerInputEvents: stream,
              connectedControllerIds: connected,
              controlProfile: profile,
              gameplayInputRoute: (event) {
                events.add(event);
                return true;
              },
              hapticFeedback: () async {},
            ),
          );

      await tester.pumpWidget(app(initialProfile, firstStream.stream));
      firstStream.add(_axis(-.8));
      firstStream.add(_button(GamepadButton.dpadLeft, 1));
      await tester.pump();
      expect(events, const [
        RuntimeInputEvent.press(RuntimeInputControl.left),
        RuntimeInputEvent.press(RuntimeInputControl.sprint),
      ]);
      events.clear();

      final currentStream = replaceProfile ? firstStream : secondStream;
      final currentProfile = replaceProfile ? updatedProfile : initialProfile;
      await tester.pumpWidget(app(currentProfile, currentStream.stream));
      expect(
          events,
          unorderedEquals(const [
            RuntimeInputEvent.release(RuntimeInputControl.left),
            RuntimeInputEvent.release(RuntimeInputControl.sprint),
          ]));
      events.clear();

      if (!replaceProfile) {
        expect(firstStream.hasListener, isFalse);
        firstStream.add(_axis(.8));
        firstStream.add(_button(GamepadButton.dpadUp, 1));
      }
      currentStream.add(_axis(-.8));
      currentStream.add(_button(GamepadButton.dpadLeft, 1));
      await tester.pump();
      expect(events, isEmpty,
          reason: 'A re-emitted held axis or button is not a fresh intention.');

      currentStream.add(_axis(0));
      currentStream.add(_button(GamepadButton.dpadLeft, 0));
      await tester.pump();
      expect(events, isEmpty);

      final sprintButton =
          replaceProfile ? GamepadButton.dpadRight : GamepadButton.dpadLeft;
      currentStream.add(_axis(-.8));
      currentStream.add(_button(sprintButton, 1));
      currentStream.add(_axis(-.8));
      currentStream.add(_button(sprintButton, 1));
      await tester.pump();
      expect(events, const [
        RuntimeInputEvent.press(RuntimeInputControl.left),
        RuntimeInputEvent.press(RuntimeInputControl.sprint),
      ]);
      events.clear();
      currentStream.add(_axis(0));
      currentStream.add(_button(sprintButton, 0));
      await tester.pump();
      expect(
          events,
          unorderedEquals(const [
            RuntimeInputEvent.release(RuntimeInputControl.left),
            RuntimeInputEvent.release(RuntimeInputControl.sprint),
          ]));

      if (replaceProfile) {
        events.clear();
        currentStream.add(_button(GamepadButton.dpadLeft, 1));
        currentStream.add(_button(GamepadButton.dpadLeft, 0));
        await tester.pump();
        expect(events, const [
          RuntimeInputEvent.press(RuntimeInputControl.right),
          RuntimeInputEvent.release(RuntimeInputControl.right),
        ]);
      }
      await tester.pumpWidget(const SizedBox());
      expect(currentStream.hasListener, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}

NormalizedGamepadEvent _axis(double value) => NormalizedGamepadEvent(
      gamepadId: 'pad',
      timestamp: 1,
      value: value,
      axis: GamepadAxis.leftStickX,
      rawEvent: GamepadEvent(
          gamepadId: 'pad',
          timestamp: 1,
          type: KeyType.analog,
          key: GamepadAxis.leftStickX.name,
          value: value),
    );

NormalizedGamepadEvent _button(GamepadButton button, double value) =>
    NormalizedGamepadEvent(
      gamepadId: 'pad',
      timestamp: 1,
      value: value,
      button: button,
      rawEvent: GamepadEvent(
          gamepadId: 'pad',
          timestamp: 1,
          type: KeyType.button,
          key: button.name,
          value: value),
    );

final class _Coordinator implements RuntimePlayerViewController {
  final changes = StreamController<RuntimePlayerSnapshot>.broadcast();

  @override
  RuntimePlayerSnapshot get snapshot => RuntimePlayerSnapshot(
      revision: 1, phase: RuntimePlayerPhase.playing, gameTitle: 'QA');

  @override
  Stream<RuntimePlayerSnapshot> get snapshots => changes.stream;

  @override
  Future<RuntimePlayerCommandResult> dispatch(
          RuntimePlayerCommand command) async =>
      const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted);

  @override
  Future<RuntimePlayerCommandResult> requestBack(
          {required int snapshotRevision}) async =>
      const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted);

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
          RuntimeWorldServiceCommand command) async =>
      const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.accepted);
}
