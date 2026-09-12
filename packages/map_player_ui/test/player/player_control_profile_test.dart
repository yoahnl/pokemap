import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('synthesized presses are ignored while releases can clear held input', () {
    final profile = PlayerControlProfile.standard;
    expect(
      profile.runtimeEventFromKeyEvent(const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
        synthesized: true,
      )),
      isNull,
    );
    expect(
      profile.runtimeEventFromKeyEvent(const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
        synthesized: true,
      )),
      const RuntimeInputEvent.release(RuntimeInputControl.right),
    );
  });

  test('gamepad keys use gamepad remapping independently of keyboard bindings',
      () {
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
    expect(
        profile.runtimeEventFromKeyEvent(const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.gameButtonX,
            logicalKey: LogicalKeyboardKey.gameButtonX,
            timeStamp: Duration.zero,
            deviceType: ui.KeyEventDeviceType.gamepad)),
        const RuntimeInputEvent.press(RuntimeInputControl.primary));
    expect(
        profile.runtimeEventFromKeyEvent(const KeyUpEvent(
            physicalKey: PhysicalKeyboardKey.gameButtonX,
            logicalKey: LogicalKeyboardKey.gameButtonX,
            timeStamp: Duration.zero,
            deviceType: ui.KeyEventDeviceType.gamepad)),
        const RuntimeInputEvent.release(RuntimeInputControl.primary));
    expect(
        profile.runtimeEventFromKeyEvent(const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.gameButtonA,
            logicalKey: LogicalKeyboardKey.gameButtonA,
            timeStamp: Duration.zero,
            deviceType: ui.KeyEventDeviceType.gamepad)),
        isNull);
  });

  test(
      'prompts follow mapping and only use explicitly known controller families',
      () {
    final profile = PlayerControlProfile.standard;
    expect(
        profile.promptFor(
            PlayerControlDevice.gamepad, RuntimeInputControl.primary),
        'Bouton sud');
    expect(
        profile.promptFor(
            PlayerControlDevice.gamepad, RuntimeInputControl.primary,
            family: PlayerControllerFamily.xbox),
        'A');
    expect(
        profile.promptFor(
            PlayerControlDevice.gamepad, RuntimeInputControl.primary,
            family: PlayerControllerFamily.playStation),
        '×');
    expect(
        profile.promptFor(
            PlayerControlDevice.gamepad, RuntimeInputControl.primary,
            family: PlayerControllerFamily.nintendo),
        'B');
    expect(
        profile.promptFor(
            PlayerControlDevice.touch, RuntimeInputControl.primary),
        isEmpty);
    final remapped = profile
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
    expect(
        remapped.promptFor(
            PlayerControlDevice.keyboard, RuntimeInputControl.primary),
        'Z');
    expect(
        remapped.promptFor(
            PlayerControlDevice.gamepad, RuntimeInputControl.primary),
        'Bouton ouest');
    expect(
        remapped.promptFor(
            PlayerControlDevice.gamepad, RuntimeInputControl.primary,
            family: PlayerControllerFamily.playStation),
        '□');
  });

  test('standard profile exposes sprint on every supported device', () {
    expect(
      PlayerControlProfile.standard.bindingFor(
        PlayerControlDevice.keyboard,
        RuntimeInputControl.sprint,
      ),
      'shiftLeft',
    );
    expect(
      PlayerControlProfile.standard.controlForGamepadButton(GamepadButton.y),
      RuntimeInputControl.sprint,
    );
    expect(
      PlayerControlProfile.standard.controlForTouchInput('sprintButton'),
      RuntimeInputControl.sprint,
    );
  });

  test('rejects a duplicate physical binding inside one device profile', () {
    final result = PlayerControlProfile.standard.rebind(
      device: PlayerControlDevice.keyboard,
      control: RuntimeInputControl.primary,
      inputId: 'escape',
    );

    expect(result.hasConflict, isTrue);
    expect(result.conflict?.control, RuntimeInputControl.secondary);
    expect(result.profile, PlayerControlProfile.standard);
  });

  test('custom keyboard and gamepad bindings emit canonical runtime controls',
      () {
    final keyboard = PlayerControlProfile.standard
        .rebind(
          device: PlayerControlDevice.keyboard,
          control: RuntimeInputControl.primary,
          inputId: 'keyZ',
        )
        .profile;
    final keyEvent = keyboard.runtimeEventFromKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyZ,
        logicalKey: LogicalKeyboardKey.keyZ,
        timeStamp: Duration.zero,
      ),
    );
    expect(
      keyEvent,
      const RuntimeInputEvent.press(RuntimeInputControl.primary),
    );

    final gamepad = keyboard
        .rebind(
          device: PlayerControlDevice.gamepad,
          control: RuntimeInputControl.primary,
          inputId: GamepadButton.x.name,
        )
        .profile;
    expect(
      gamepad.controlForGamepadButton(GamepadButton.x),
      RuntimeInputControl.primary,
    );
    final swappedTouch = gamepad.swapBindings(
      device: PlayerControlDevice.touch,
      first: RuntimeInputControl.primary,
      second: RuntimeInputControl.secondary,
    );
    expect(
      swappedTouch.controlForTouchInput('primaryButton'),
      RuntimeInputControl.secondary,
    );
  });

  test('round-trips persisted bindings and resets one device only', () {
    final customized = PlayerControlProfile.standard
        .rebind(
          device: PlayerControlDevice.keyboard,
          control: RuntimeInputControl.primary,
          inputId: 'keyZ',
        )
        .profile;
    final decoded = PlayerControlProfile.fromJson(customized.toJson());

    expect(decoded, customized);
    expect(
      decoded.resetDevice(PlayerControlDevice.keyboard).bindingFor(
            PlayerControlDevice.keyboard,
            RuntimeInputControl.primary,
          ),
      'keyE',
    );
    expect(
      decoded.glyphFor(
        PlayerControlDevice.keyboard,
        RuntimeInputControl.menu,
      ),
      'M',
    );
  });
}
