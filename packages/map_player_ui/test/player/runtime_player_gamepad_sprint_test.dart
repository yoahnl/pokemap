import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('holding B runs in the overworld and releasing B stops running',
      (tester) async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.app());
    fixture.button(GamepadButton.dpadRight, 1);
    fixture.button(GamepadButton.b, 1);
    fixture.button(GamepadButton.b, 1);
    await tester.pump();
    expect(fixture.events, const [
      RuntimeInputEvent.press(RuntimeInputControl.right),
      RuntimeInputEvent.press(RuntimeInputControl.sprint),
    ]);
    fixture.button(GamepadButton.b, 0);
    await tester.pump();
    expect(fixture.events.last,
        const RuntimeInputEvent.release(RuntimeInputControl.sprint));
    fixture.button(GamepadButton.dpadRight, 0);
    await tester.pump();
    expect(fixture.events.last,
        const RuntimeInputEvent.release(RuntimeInputControl.right));
    await tester.pumpWidget(const SizedBox());
  });

  for (final context in RuntimeInputContext.values
      .where((value) => value != RuntimeInputContext.overworld)) {
    testWidgets('B keeps its secondary action in $context', (tester) async {
      final fixture = _Fixture(context: context);
      addTearDown(fixture.dispose);
      await tester.pumpWidget(fixture.app());
      fixture.button(GamepadButton.b, 1);
      fixture.button(GamepadButton.b, 0);
      await tester.pump();
      expect(fixture.events, const [
        RuntimeInputEvent.press(RuntimeInputControl.secondary),
        RuntimeInputEvent.release(RuntimeInputControl.secondary),
      ]);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('held B is neutralized across battle transitions',
      (tester) async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.app());
    fixture.button(GamepadButton.b, 1);
    await tester.pump();
    fixture.authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.battle,
    );
    await tester.pump();
    expect(fixture.events, const [
      RuntimeInputEvent.press(RuntimeInputControl.sprint),
      RuntimeInputEvent.release(RuntimeInputControl.sprint),
    ]);
    fixture.events.clear();
    fixture.button(GamepadButton.b, 1);
    fixture.button(GamepadButton.b, 0);
    await tester.pump();
    expect(fixture.events, isEmpty);
    fixture.button(GamepadButton.b, 1);
    await tester.pump();
    expect(fixture.events,
        const [RuntimeInputEvent.press(RuntimeInputControl.secondary)]);
    fixture.authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld,
      sprintAllowed: true,
    );
    await tester.pump();
    fixture.events.clear();
    fixture.button(GamepadButton.b, 1);
    fixture.button(GamepadButton.b, 0);
    await tester.pump();
    expect(fixture.events, isEmpty);
    fixture.button(GamepadButton.b, 1);
    fixture.button(GamepadButton.b, 0);
    await tester.pump();
    expect(fixture.events, const [
      RuntimeInputEvent.press(RuntimeInputControl.sprint),
      RuntimeInputEvent.release(RuntimeInputControl.sprint),
    ]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('disconnecting releases B sprint and requires a fresh press',
      (tester) async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.app());
    fixture.button(GamepadButton.b, 1);
    await tester.pump();
    fixture.controllers.value = {};
    await tester.pump();
    expect(fixture.events, const [
      RuntimeInputEvent.press(RuntimeInputControl.sprint),
      RuntimeInputEvent.release(RuntimeInputControl.sprint),
    ]);
    fixture.events.clear();
    fixture.controllers.value = {'pad'};
    fixture.button(GamepadButton.b, 1);
    fixture.button(GamepadButton.b, 0);
    await tester.pump();
    expect(fixture.events, isEmpty);
    fixture.button(GamepadButton.b, 1);
    fixture.button(GamepadButton.b, 0);
    await tester.pump();
    expect(fixture.events, const [
      RuntimeInputEvent.press(RuntimeInputControl.sprint),
      RuntimeInputEvent.release(RuntimeInputControl.sprint),
    ]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('B and the existing sprint button share one held sprint',
      (tester) async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.app());
    fixture.button(GamepadButton.y, 1);
    fixture.button(GamepadButton.b, 1);
    fixture.button(GamepadButton.y, 0);
    await tester.pump();
    expect(fixture.events,
        const [RuntimeInputEvent.press(RuntimeInputControl.sprint)]);
    fixture.button(GamepadButton.b, 0);
    await tester.pump();
    expect(fixture.events.last,
        const RuntimeInputEvent.release(RuntimeInputControl.sprint));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('B cancels the pause menu instead of running', (tester) async {
    final fixture = _Fixture()..phase = RuntimePlayerPhase.paused;
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.app());
    fixture.button(GamepadButton.b, 1);
    fixture.button(GamepadButton.b, 0);
    await tester.pump();
    expect(fixture.backRequests, 1);
    expect(fixture.events, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('custom button bindings retain their assigned actions',
      (tester) async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    final profile = PlayerControlProfile.standard.swapBindings(
      device: PlayerControlDevice.gamepad,
      first: RuntimeInputControl.primary,
      second: RuntimeInputControl.secondary,
    );
    await tester.pumpWidget(fixture.app(profile: profile));
    fixture.button(GamepadButton.b, 1);
    fixture.button(GamepadButton.b, 0);
    await tester.pump();
    expect(fixture.events, const [
      RuntimeInputEvent.press(RuntimeInputControl.primary),
      RuntimeInputEvent.release(RuntimeInputControl.primary),
    ]);
    await tester.pumpWidget(const SizedBox());
  });
}

final class _Fixture implements RuntimePlayerViewController {
  _Fixture({RuntimeInputContext context = RuntimeInputContext.overworld})
      : authority = ValueNotifier(RuntimeInputAuthoritySnapshot(
          context: context,
          sprintAllowed: context == RuntimeInputContext.overworld,
        ));

  final ValueNotifier<RuntimeInputAuthoritySnapshot> authority;
  final controllers = ValueNotifier<Set<String>>({'pad'});
  final inputs = StreamController<NormalizedGamepadEvent>.broadcast();
  final changes = StreamController<RuntimePlayerSnapshot>.broadcast();
  final events = <RuntimeInputEvent>[];
  var phase = RuntimePlayerPhase.playing;
  var backRequests = 0;

  Widget app({PlayerControlProfile? profile}) => MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: PokeMapPlayerTheme.dark(),
        home: PokeMapPlayerSessionView(
          controller: this,
          controlProfile: profile,
          titlePresentation: const RuntimePlayerTitlePresentation(
              author: 'QA', description: 'Controller sprint'),
          gameSceneBuilder: (_) => const SizedBox.expand(),
          touchControlsAvailable: false,
          normalizedControllerInputEvents: inputs.stream,
          connectedControllerIds: controllers,
          gameplayInputAuthority: authority,
          hapticFeedback: () async {},
          gameplayInputRoute: (event) {
            events.add(event);
            return true;
          },
        ),
      );

  void button(GamepadButton button, double value) =>
      inputs.add(NormalizedGamepadEvent(
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
      ));

  Future<void> dispose() async {
    await inputs.close();
    await changes.close();
    authority.dispose();
    controllers.dispose();
  }

  @override
  RuntimePlayerSnapshot get snapshot =>
      RuntimePlayerSnapshot(revision: 1, phase: phase, gameTitle: 'Sprint');

  @override
  Stream<RuntimePlayerSnapshot> get snapshots => changes.stream;

  @override
  Future<RuntimePlayerCommandResult> dispatch(
          RuntimePlayerCommand command) async =>
      const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted);

  @override
  Future<RuntimePlayerCommandResult> requestBack(
      {required int snapshotRevision}) async {
    backRequests++;
    return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.accepted);
  }

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
          RuntimeWorldServiceCommand command) async =>
      const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.accepted);
}
