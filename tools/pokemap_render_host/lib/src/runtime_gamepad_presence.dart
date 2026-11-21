import 'dart:async';

import 'package:gamepads/gamepads.dart';

typedef RuntimeConnectedGamepadCount = Future<int> Function();

Future<int> _defaultConnectedGamepadCount() async {
  final controllers = await Gamepads.list();
  try {
    return controllers.length;
  } finally {
    for (final controller in controllers) {
      unawaited(controller.dispose());
    }
  }
}

final class RuntimeGamepadPresence {
  RuntimeGamepadPresence({
    RuntimeConnectedGamepadCount? connectedGamepadCount,
  }) : connectedGamepadCount =
           connectedGamepadCount ?? _defaultConnectedGamepadCount;

  final RuntimeConnectedGamepadCount connectedGamepadCount;

  Future<bool> hasConnectedGamepads() async {
    return (await connectedGamepadCount()) > 0;
  }
}
