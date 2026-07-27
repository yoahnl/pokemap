import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('RuntimePlayerGamepadBridge', () {
    test('maps face, d-pad, and Start buttons to canonical runtime inputs', () {
      final bridge = RuntimePlayerGamepadBridge();

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
          button: GamepadButton.dpadLeft,
          value: 1,
        ),
        const <RuntimeInputEvent>[
          RuntimeInputEvent.press(RuntimeInputControl.left),
        ],
      );
      expect(
        bridge.handleButton(
          gamepadId: 'pad-1',
          button: GamepadButton.start,
          value: 1,
        ),
        const <RuntimeInputEvent>[
          RuntimeInputEvent.press(RuntimeInputControl.menu),
        ],
      );
      expect(
        bridge.handleButton(
          gamepadId: 'pad-1',
          button: GamepadButton.start,
          value: 1,
        ),
        isEmpty,
        reason: 'A held Start button must not toggle pause repeatedly.',
      );
    });

    test('uses a remapped gamepad profile and exposes its glyph', () {
      final profile = PlayerControlProfile.standard
          .rebind(
            device: PlayerControlDevice.gamepad,
            control: RuntimeInputControl.primary,
            inputId: GamepadButton.x.name,
          )
          .profile;
      final bridge = RuntimePlayerGamepadBridge(controlProfile: profile);

      expect(
        bridge.handleButton(
          gamepadId: 'pad-remapped',
          button: GamepadButton.x,
          value: 1,
        ),
        const <RuntimeInputEvent>[
          RuntimeInputEvent.press(RuntimeInputControl.primary),
        ],
      );
      expect(
        profile.glyphFor(
          PlayerControlDevice.gamepad,
          RuntimeInputControl.primary,
        ),
        'X',
      );
    });

    test('maps the normalized left stick through a digital dead zone', () {
      final bridge = RuntimePlayerGamepadBridge();

      expect(
        bridge.handleAxis(
          gamepadId: 'pad-1',
          axis: GamepadAxis.leftStickX,
          value: .8,
        ),
        const <RuntimeInputEvent>[
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
