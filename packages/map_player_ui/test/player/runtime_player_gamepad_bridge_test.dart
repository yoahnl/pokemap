import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('RuntimePlayerGamepadBridge', () {
    test('recognizes only identified controller models and keeps unknowns neutral', () {
      for (final (vendor, product, family) in [
        (0x045e, 0x0b0c, PlayerControllerFamily.xbox),
        (0x054c, 0x0ba0, PlayerControllerFamily.playStation),
        (0x057e, 0x2009, PlayerControllerFamily.nintendo),
        (0x045e, 0xffff, PlayerControllerFamily.unknown),
        (null, null, PlayerControllerFamily.unknown),
      ]) {
        final raw = GamepadEvent(gamepadId: 'pad', timestamp: 0,
          type: KeyType.button, key: 'a', value: 1, vendorId: vendor, productId: product);
        final event = NormalizedGamepadEvent(gamepadId: 'pad', timestamp: 0,
          value: 1, rawEvent: raw, button: GamepadButton.a);
        expect(RuntimePlayerGamepadBridge.familyFor(event), family);
      }
    });

    test('ignores unknown releases and non-finite values', () {
      final bridge = RuntimePlayerGamepadBridge();
      expect(
          bridge.handleButton(
              gamepadId: 'p', button: GamepadButton.a, value: 0),
          isEmpty);
      expect(
          bridge.handleButton(
              gamepadId: 'p', button: GamepadButton.a, value: double.nan),
          isEmpty);
      expect(
          bridge.handleAxis(
              gamepadId: 'p',
              axis: GamepadAxis.leftStickX,
              value: double.infinity),
          isEmpty);
    });

    test(
        'holds a stick direction across dead zone noise until release threshold',
        () {
      final bridge = RuntimePlayerGamepadBridge();
      List<RuntimeInputEvent> x(double value) => bridge.handleAxis(
          gamepadId: 'p', axis: GamepadAxis.leftStickX, value: value);
      expect(x(.34), isEmpty);
      expect(
          x(.36), const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
      expect(x(.34), isEmpty);
      expect(x(.26), isEmpty);
      expect(
          x(.25), const [RuntimeInputEvent.release(RuntimeInputControl.right)]);
      expect(x(.34), isEmpty);
    });

    test('coalesces d-pad and stick ownership on one controller', () {
      final bridge = RuntimePlayerGamepadBridge();
      expect(
          bridge.handleButton(
              gamepadId: 'p', button: GamepadButton.dpadRight, value: 1),
          const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
      expect(
          bridge.handleAxis(
              gamepadId: 'p', axis: GamepadAxis.leftStickX, value: .8),
          isEmpty);
      expect(
          bridge.handleButton(
              gamepadId: 'p', button: GamepadButton.dpadRight, value: 0),
          isEmpty);
      expect(
          bridge.handleAxis(
              gamepadId: 'p', axis: GamepadAxis.leftStickX, value: 0),
          const [RuntimeInputEvent.release(RuntimeInputControl.right)]);
    });

    test(
        'disconnect releases locally and requires neutral before held inputs resume',
        () {
      final bridge = RuntimePlayerGamepadBridge();
      bridge.handleButton(gamepadId: 'p', button: GamepadButton.y, value: 1);
      bridge.handleAxis(
          gamepadId: 'p', axis: GamepadAxis.leftStickX, value: .8);
      bridge.handleButton(
          gamepadId: 'other', button: GamepadButton.y, value: 1);
      expect(
          bridge.disconnect('p'),
          unorderedEquals(const [
            RuntimeInputEvent.release(RuntimeInputControl.sprint),
            RuntimeInputEvent.release(RuntimeInputControl.right)
          ]));
      expect(bridge.disconnect('p'), isEmpty);
      expect(
          bridge.handleButton(
              gamepadId: 'p', button: GamepadButton.y, value: 1),
          isEmpty);
      expect(
          bridge.handleAxis(
              gamepadId: 'p', axis: GamepadAxis.leftStickX, value: .8),
          isEmpty);
      expect(
          bridge.handleButton(
              gamepadId: 'p', button: GamepadButton.a, value: 1),
          const [RuntimeInputEvent.press(RuntimeInputControl.primary)]);
      expect(
          bridge.handleButton(
              gamepadId: 'p', button: GamepadButton.y, value: 0),
          isEmpty);
      expect(
          bridge.handleAxis(
              gamepadId: 'p', axis: GamepadAxis.leftStickX, value: 0),
          isEmpty);
      expect(
          bridge.handleButton(
              gamepadId: 'p', button: GamepadButton.y, value: 1),
          const [RuntimeInputEvent.press(RuntimeInputControl.sprint)]);
      expect(
          bridge.handleAxis(
              gamepadId: 'p', axis: GamepadAxis.leftStickX, value: .8),
          const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
      expect(
          bridge.handleButton(
              gamepadId: 'other', button: GamepadButton.y, value: 0),
          const [RuntimeInputEvent.release(RuntimeInputControl.sprint)]);
    });

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
