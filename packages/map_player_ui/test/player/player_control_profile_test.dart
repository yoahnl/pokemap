import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
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
