import 'dart:ui';

import 'package:gamepads/gamepads.dart';
import 'package:map_runtime/map_runtime.dart';

import 'runtime_player_touch_controls.dart';
import 'player_control_profile.dart';

const double kRuntimePlayerGamepadPressedThreshold = .5;

/// Normalizes the supported physical gamepad controls into runtime events.
///
/// Platform-specific names are handled by `package:gamepads`; this class owns
/// only PokeMap's small A/B/Start/d-pad/left-stick contract.
final class RuntimePlayerGamepadBridge {
  static PlayerControllerFamily familyFor(NormalizedGamepadEvent event) =>
      switch ((event.rawEvent.vendorId, event.rawEvent.productId)) {
        (0x045e, 0x0b0c) => PlayerControllerFamily.xbox,
        (0x054c, 0x0ba0) => PlayerControllerFamily.playStation,
        (0x057e, 0x2009) => PlayerControllerFamily.nintendo,
        _ => PlayerControllerFamily.unknown,
      };

  RuntimePlayerGamepadBridge({
    double stickDeadZone = kRuntimePlayerTouchDeadZone,
    double stickReleaseDeadZone = .25,
    PlayerControlProfile? controlProfile,
  })  : assert(
            stickReleaseDeadZone >= 0 && stickReleaseDeadZone < stickDeadZone),
        _stickDeadZone = stickDeadZone,
        _stickReleaseDeadZone = stickReleaseDeadZone,
        _controlProfile = controlProfile ?? PlayerControlProfile.standard;

  final double _stickDeadZone;
  final double _stickReleaseDeadZone;
  final PlayerControlProfile _controlProfile;
  final Map<String, _RuntimePlayerGamepadState> _devices = {};
  final Map<String, Set<GamepadButton>> _blockedButtons = {};
  final Map<String, Offset> _blockedSticks = {};

  RuntimePlayerGamepadBridge rebind(PlayerControlProfile controlProfile) {
    final next = RuntimePlayerGamepadBridge(
      stickDeadZone: _stickDeadZone,
      stickReleaseDeadZone: _stickReleaseDeadZone,
      controlProfile: controlProfile,
    );
    for (final entry in _blockedButtons.entries) {
      next._blockedButtons[entry.key] = Set.of(entry.value);
    }
    next._blockedSticks.addAll(_blockedSticks);
    for (final entry in _devices.entries) {
      if (entry.value.physicalButtons.isNotEmpty) {
        next._blockedButtons.putIfAbsent(entry.key, () => {}).addAll(entry.value.physicalButtons);
      }
      if (entry.value.vector.distance > _stickReleaseDeadZone) {
        next._blockedSticks[entry.key] = entry.value.vector;
      }
    }
    return next;
  }

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
    if (!value.isFinite) return const [];
    final pressed = value >= kRuntimePlayerGamepadPressedThreshold;
    final blocked = _blockedButtons[gamepadId];
    if (blocked?.contains(button) ?? false) {
      if (!pressed) {
        blocked!.remove(button);
        if (blocked.isEmpty) _blockedButtons.remove(gamepadId);
      }
      return const [];
    }
    final state =
        _devices.putIfAbsent(gamepadId, _RuntimePlayerGamepadState.new);
    if (pressed) {
      state.physicalButtons.add(button);
    } else {
      state.physicalButtons.remove(button);
    }
    final control = _controlProfile.controlForGamepadButton(button);
    if (control == null) return const [];
    final previous = state.controls;
    if (pressed) {
      state.buttons[button] = control;
    } else {
      state.buttons.remove(button);
    }
    return _transitions(previous, state.controls);
  }

  List<RuntimeInputEvent> handleAxis({
    required String gamepadId,
    required GamepadAxis axis,
    required double value,
  }) {
    if (!value.isFinite) return const [];
    if (axis != GamepadAxis.leftStickX && axis != GamepadAxis.leftStickY) {
      return const [];
    }
    final blocked = _blockedSticks[gamepadId];
    if (blocked != null) {
      final next = axis == GamepadAxis.leftStickX
          ? Offset(value, blocked.dy)
          : Offset(blocked.dx, -value);
      if (next.distance <= _stickReleaseDeadZone) {
        _blockedSticks.remove(gamepadId);
      } else {
        _blockedSticks[gamepadId] = next;
      }
      return const [];
    }
    final state =
        _devices.putIfAbsent(gamepadId, _RuntimePlayerGamepadState.new);
    final previous = state.controls;
    state.vector = axis == GamepadAxis.leftStickX
        ? Offset(value, state.vector.dy)
        : Offset(state.vector.dx, -value);
    state.stickControl = runtimeInputControlFromTouchVector(
      state.vector,
      deadZone:
          state.stickControl == null ? _stickDeadZone : _stickReleaseDeadZone,
    );
    return _transitions(previous, state.controls);
  }

  List<RuntimeInputEvent> disconnect(String gamepadId) {
    final state = _devices.remove(gamepadId);
    if (state == null) return const [];
    if (state.physicalButtons.isNotEmpty) {
      _blockedButtons
          .putIfAbsent(gamepadId, () => {})
          .addAll(state.physicalButtons);
    }
    if (state.vector.distance > _stickReleaseDeadZone) {
      _blockedSticks[gamepadId] = state.vector;
    }
    return _transitions(state.controls, const {});
  }

  List<RuntimeInputEvent> _transitions(
    Set<RuntimeInputControl> previous,
    Set<RuntimeInputControl> next,
  ) {
    return [
      for (final control in previous.difference(next))
        RuntimeInputEvent.release(control),
      for (final control in next.difference(previous))
        RuntimeInputEvent.press(control),
    ];
  }
}

final class _RuntimePlayerGamepadState {
  final Set<GamepadButton> physicalButtons = {};
  final Map<GamepadButton, RuntimeInputControl> buttons = {};
  Offset vector = Offset.zero;
  RuntimeInputControl? stickControl;

  Set<RuntimeInputControl> get controls => {
        ...buttons.values,
        if (stickControl case final control?) control,
      };
}
