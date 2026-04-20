import 'dart:ui';

import 'package:map_runtime/map_runtime.dart';

const double kRuntimeTouchDeadZone = 0.35;

RuntimeInputControl? runtimeInputControlFromTouchVector(
  Offset vector, {
  double deadZone = kRuntimeTouchDeadZone,
}) {
  if (vector.distance <= deadZone) {
    return null;
  }
  if (vector.dx.abs() >= vector.dy.abs()) {
    return vector.dx >= 0
        ? RuntimeInputControl.right
        : RuntimeInputControl.left;
  }
  return vector.dy <= 0 ? RuntimeInputControl.up : RuntimeInputControl.down;
}

final class RuntimeTouchInputDriver {
  RuntimeTouchInputDriver({this.deadZone = kRuntimeTouchDeadZone});

  final double deadZone;
  RuntimeInputControl? _activeControl;

  List<RuntimeInputEvent> updateVector(Offset vector) {
    final nextControl =
        runtimeInputControlFromTouchVector(vector, deadZone: deadZone);
    if (nextControl == _activeControl) {
      return const <RuntimeInputEvent>[];
    }

    final events = <RuntimeInputEvent>[];
    final previousControl = _activeControl;
    if (previousControl != null) {
      events.add(RuntimeInputEvent.release(previousControl));
    }
    if (nextControl != null) {
      events.add(RuntimeInputEvent.press(nextControl));
    }
    _activeControl = nextControl;
    return events;
  }

  List<RuntimeInputEvent> release() => updateVector(Offset.zero);
}
