import 'dart:ui' show KeyEventDeviceType;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/runtime_input_key_bindings.dart';

void main() {
  group('runtimeInputEventFromKeyEvent', () {
    test('maps keyboard movement and confirm keys to runtime input events', () {
      expect(
        runtimeInputEventFromKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.arrowUp,
            logicalKey: LogicalKeyboardKey.arrowUp,
            timeStamp: Duration.zero,
          ),
        ),
        const RuntimeInputEvent.press(RuntimeInputControl.up),
      );
      expect(
        runtimeInputEventFromKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.keyW,
            logicalKey: LogicalKeyboardKey.keyW,
            timeStamp: Duration.zero,
          ),
        ),
        const RuntimeInputEvent.press(RuntimeInputControl.up),
      );
      expect(
        runtimeInputEventFromKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.enter,
            logicalKey: LogicalKeyboardKey.enter,
            timeStamp: Duration.zero,
          ),
        ),
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      expect(
        runtimeInputEventFromKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.escape,
            logicalKey: LogicalKeyboardKey.escape,
            timeStamp: Duration.zero,
          ),
        ),
        const RuntimeInputEvent.press(RuntimeInputControl.secondary),
      );
    });

    test('maps gamepad confirm and cancel buttons to runtime input events', () {
      expect(
        runtimeInputEventFromKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.enter,
            logicalKey: LogicalKeyboardKey.gameButtonA,
            timeStamp: Duration.zero,
            deviceType: KeyEventDeviceType.gamepad,
          ),
        ),
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      expect(
        runtimeInputEventFromKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.escape,
            logicalKey: LogicalKeyboardKey.gameButtonB,
            timeStamp: Duration.zero,
            deviceType: KeyEventDeviceType.gamepad,
          ),
        ),
        const RuntimeInputEvent.press(RuntimeInputControl.secondary),
      );
      expect(
        runtimeInputEventFromKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.enter,
            logicalKey: LogicalKeyboardKey.gameButton1,
            timeStamp: Duration.zero,
            deviceType: KeyEventDeviceType.gamepad,
          ),
        ),
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      expect(
        runtimeInputEventFromKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.escape,
            logicalKey: LogicalKeyboardKey.gameButton2,
            timeStamp: Duration.zero,
            deviceType: KeyEventDeviceType.gamepad,
          ),
        ),
        const RuntimeInputEvent.press(RuntimeInputControl.secondary),
      );
    });

    test('preserves repeat and release semantics', () {
      expect(
        runtimeInputEventFromKeyEvent(
          const KeyRepeatEvent(
            physicalKey: PhysicalKeyboardKey.arrowRight,
            logicalKey: LogicalKeyboardKey.arrowRight,
            timeStamp: Duration.zero,
          ),
        ),
        const RuntimeInputEvent.press(
          RuntimeInputControl.right,
          isRepeat: true,
        ),
      );
      expect(
        runtimeInputEventFromKeyEvent(
          const KeyUpEvent(
            physicalKey: PhysicalKeyboardKey.arrowRight,
            logicalKey: LogicalKeyboardKey.arrowRight,
            timeStamp: Duration.zero,
          ),
        ),
        const RuntimeInputEvent.release(RuntimeInputControl.right),
      );
    });

    test('ignores unsupported keys', () {
      expect(
        runtimeInputEventFromKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.shiftLeft,
            logicalKey: LogicalKeyboardKey.shiftLeft,
            timeStamp: Duration.zero,
          ),
        ),
        isNull,
      );
    });
  });
}
