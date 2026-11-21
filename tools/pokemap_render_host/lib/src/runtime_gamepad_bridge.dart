import 'dart:ui';

import 'package:gamepads/gamepads.dart';
import 'package:map_runtime/map_runtime.dart';

import 'runtime_touch_input_driver.dart';

const double kRuntimeGamepadPressedThreshold = 0.5;

final class RuntimeGamepadBridge {
  RuntimeGamepadBridge({double stickDeadZone = kRuntimeTouchDeadZone})
      : _stickDeadZone = stickDeadZone;

  final double _stickDeadZone;
  final Map<String, _RuntimeGamepadStickState> _stickStateByGamepadId =
      <String, _RuntimeGamepadStickState>{};

  List<RuntimeInputEvent> handleButton({
    required String gamepadId,
    required GamepadButton button,
    required double value,
  }) {
    final control = switch (button) {
      GamepadButton.a => RuntimeInputControl.primary,
      GamepadButton.b => RuntimeInputControl.secondary,
      GamepadButton.back => RuntimeInputControl.secondary,
      GamepadButton.dpadUp => RuntimeInputControl.up,
      GamepadButton.dpadDown => RuntimeInputControl.down,
      GamepadButton.dpadLeft => RuntimeInputControl.left,
      GamepadButton.dpadRight => RuntimeInputControl.right,
      _ => null,
    };
    if (control == null) {
      return const <RuntimeInputEvent>[];
    }
    final isPressed = value >= kRuntimeGamepadPressedThreshold;
    return <RuntimeInputEvent>[
      isPressed
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
    final state = _stickStateByGamepadId.putIfAbsent(
      gamepadId,
      () => _RuntimeGamepadStickState(
        driver: RuntimeTouchInputDriver(deadZone: _stickDeadZone),
      ),
    );
    if (axis == GamepadAxis.leftStickX) {
      state.x = value;
    } else {
      state.y = value;
    }
    return state.driver.updateVector(
      Offset(state.x, -state.y),
    );
  }
}

final class _RuntimeGamepadStickState {
  _RuntimeGamepadStickState({required this.driver});

  final RuntimeTouchInputDriver driver;
  double x = 0;
  double y = 0;
}
