import 'package:flutter/services.dart';

import 'runtime_input_event.dart';

RuntimeInputControl? runtimeInputControlFromLogicalKey(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
    return RuntimeInputControl.up;
  }
  if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
    return RuntimeInputControl.down;
  }
  if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
    return RuntimeInputControl.left;
  }
  if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
    return RuntimeInputControl.right;
  }
  if (key == LogicalKeyboardKey.keyE ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.gameButtonA ||
      key == LogicalKeyboardKey.gameButton1) {
    return RuntimeInputControl.primary;
  }
  if (key == LogicalKeyboardKey.escape ||
      key == LogicalKeyboardKey.gameButtonB ||
      key == LogicalKeyboardKey.gameButton2) {
    return RuntimeInputControl.secondary;
  }
  return null;
}

/// Bridge clavier/manette minimal vers le seam runtime public.
///
/// Frontière volontaire:
/// - on convertit uniquement les touches déjà supportées aujourd'hui;
/// - on ne prétend pas gérer ici les sticks analogiques, triggers ou remapping
///   produit complet;
/// - les directions de manette restent supportées via les touches directionnelles
///   remontées par la plateforme / Flutter.
RuntimeInputEvent? runtimeInputEventFromKeyEvent(KeyEvent event) {
  final control = runtimeInputControlFromLogicalKey(event.logicalKey);
  if (control == null) {
    return null;
  }
  if (event is KeyDownEvent) {
    return RuntimeInputEvent.press(control);
  }
  if (event is KeyRepeatEvent) {
    return RuntimeInputEvent.press(control, isRepeat: true);
  }
  if (event is KeyUpEvent) {
    return RuntimeInputEvent.release(control);
  }
  return null;
}
