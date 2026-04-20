import 'dart:async';

import 'package:flutter/services.dart';
import 'package:map_runtime/map_runtime.dart';

const EventChannel _runtimeIosControllerChannel =
    EventChannel('playable_runtime_host/game_controller');

RuntimeInputEvent? runtimeInputEventFromIosControllerMessage(Object? message) {
  if (message is! Map) {
    return null;
  }
  final controlName = message['control']?.toString().trim();
  final phaseName = message['phase']?.toString().trim();
  if (controlName == null ||
      controlName.isEmpty ||
      phaseName == null ||
      phaseName.isEmpty) {
    return null;
  }

  final control = switch (controlName) {
    'up' => RuntimeInputControl.up,
    'down' => RuntimeInputControl.down,
    'left' => RuntimeInputControl.left,
    'right' => RuntimeInputControl.right,
    'primary' => RuntimeInputControl.primary,
    'secondary' => RuntimeInputControl.secondary,
    _ => null,
  };
  if (control == null) {
    return null;
  }

  return switch (phaseName) {
    'press' => RuntimeInputEvent.press(control),
    'release' => RuntimeInputEvent.release(control),
    _ => null,
  };
}

StreamSubscription<Object?> listenToRuntimeIosControllerEvents({
  required bool Function(RuntimeInputEvent event) dispatch,
  Stream<Object?>? eventStream,
  EventChannel channel = _runtimeIosControllerChannel,
}) {
  final stream = eventStream ?? channel.receiveBroadcastStream();
  return stream.listen((message) {
    final event = runtimeInputEventFromIosControllerMessage(message);
    if (event == null) {
      return;
    }
    dispatch(event);
  });
}
