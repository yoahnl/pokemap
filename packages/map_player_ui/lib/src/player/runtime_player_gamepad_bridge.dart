import 'dart:ui';

import 'package:gamepads/gamepads.dart';
import 'package:map_runtime/map_runtime.dart';

import 'runtime_player_touch_controls.dart';

const double kRuntimePlayerGamepadPressedThreshold = .5;

/// Normalizes the supported physical gamepad controls into runtime events.
///
/// Platform-specific names are handled by `package:gamepads`; this class owns
/// only PokeMap's small A/B/Start/d-pad/left-stick contract.
final class RuntimePlayerGamepadBridge {
  RuntimePlayerGamepadBridge({
    double stickDeadZone = kRuntimePlayerTouchDeadZone,
  }) : _stickDeadZone = stickDeadZone;

  final double _stickDeadZone;
  final Map<String, _RuntimePlayerGamepadStickState> _sticks =
      <String, _RuntimePlayerGamepadStickState>{};
  final Map<String, bool> _buttonStates = <String, bool>{};

  List<RuntimeInputEvent> handle(NormalizedGamepadEvent event) {
    if (event.button case final button?) {
      return handleButton(
        gamepadId: event.gamepadId,
        button: button,
        value: event.value,
      );
    }
    return handleAxis(
      gamepadId: event.gamepadId,
      axis: event.axis!,
      value: event.value,
    );
  }

  List<RuntimeInputEvent> handleButton({
    required String gamepadId,
    required GamepadButton button,
    required double value,
  }) {
    final control = switch (button) {
      GamepadButton.a => RuntimeInputControl.primary,
      GamepadButton.b || GamepadButton.back => RuntimeInputControl.secondary,
      GamepadButton.start => RuntimeInputControl.menu,
      GamepadButton.dpadUp => RuntimeInputControl.up,
      GamepadButton.dpadDown => RuntimeInputControl.down,
      GamepadButton.dpadLeft => RuntimeInputControl.left,
      GamepadButton.dpadRight => RuntimeInputControl.right,
      _ => null,
    };
    if (control == null) return const <RuntimeInputEvent>[];
    final pressed = value >= kRuntimePlayerGamepadPressedThreshold;
    final stateKey = '$gamepadId:${button.name}';
    if (_buttonStates[stateKey] == pressed) {
      return const <RuntimeInputEvent>[];
    }
    _buttonStates[stateKey] = pressed;
    return <RuntimeInputEvent>[
      pressed
          ? RuntimeInputEvent.press(control)
          : RuntimeInputEvent.release(control),
    ];
  }

  List<RuntimeInputEvent> handleAxis({
    required String gamepadId,
    required GamepadAxis axis,
    required double value,
  }) {
    if (axis != GamepadAxis.leftStickX && axis != GamepadAxis.leftStickY) {
      return const <RuntimeInputEvent>[];
    }
    final state = _sticks.putIfAbsent(
      gamepadId,
      () => _RuntimePlayerGamepadStickState(
        driver: RuntimePlayerTouchInputDriver(
          deadZone: _stickDeadZone,
        ),
      ),
    );
    if (axis == GamepadAxis.leftStickX) {
      state.x = value;
    } else {
      state.y = value;
    }
    return state.driver.updateVector(Offset(state.x, -state.y));
  }
}

final class _RuntimePlayerGamepadStickState {
  _RuntimePlayerGamepadStickState({required this.driver});

  final RuntimePlayerTouchInputDriver driver;
  double x = 0;
  double y = 0;
}
