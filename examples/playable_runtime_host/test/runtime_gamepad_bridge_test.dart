import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:PokeMap_Loader/src/runtime_gamepad_bridge.dart';

void main() {
  group('RuntimeGamepadBridge', () {
    test('maps digital face buttons to runtime primary and secondary actions',
        () {
      final bridge = RuntimeGamepadBridge();

      expect(
        bridge.handleButton(
          gamepadId: 'pad-1',
          button: GamepadButton.a,
          value: 1,
        ),
        const <RuntimeInputEvent>[
          RuntimeInputEvent.press(RuntimeInputControl.primary),
        ],
      );
      expect(
        bridge.handleButton(
          gamepadId: 'pad-1',
          button: GamepadButton.b,
          value: 1,
        ),
        const <RuntimeInputEvent>[
          RuntimeInputEvent.press(RuntimeInputControl.secondary),
        ],
      );
      expect(
        bridge.handleButton(
          gamepadId: 'pad-1',
          button: GamepadButton.a,
          value: 0,
        ),
        const <RuntimeInputEvent>[
          RuntimeInputEvent.release(RuntimeInputControl.primary),
        ],
      );
    });

    test('translates left stick axes into bounded digital movement', () {
      final bridge = RuntimeGamepadBridge();

      expect(
        bridge.handleAxis(
          gamepadId: 'pad-1',
          axis: GamepadAxis.leftStickX,
          value: 0.85,
        ),
        const <RuntimeInputEvent>[
          RuntimeInputEvent.press(RuntimeInputControl.right),
        ],
      );
      expect(
        bridge.handleAxis(
          gamepadId: 'pad-1',
          axis: GamepadAxis.leftStickY,
          value: 1,
        ),
        const <RuntimeInputEvent>[
          RuntimeInputEvent.release(RuntimeInputControl.right),
          RuntimeInputEvent.press(RuntimeInputControl.up),
        ],
      );
      expect(
        bridge.handleAxis(
          gamepadId: 'pad-1',
          axis: GamepadAxis.leftStickY,
          value: 0,
        ),
        const <RuntimeInputEvent>[
          RuntimeInputEvent.release(RuntimeInputControl.up),
          RuntimeInputEvent.press(RuntimeInputControl.right),
        ],
      );
      expect(
        bridge.handleAxis(
          gamepadId: 'pad-1',
          axis: GamepadAxis.leftStickX,
          value: 0,
        ),
        const <RuntimeInputEvent>[
          RuntimeInputEvent.release(RuntimeInputControl.right),
        ],
      );
    });
  });
}
