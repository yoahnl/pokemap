import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final (platform, left, right) in [
    (GamepadPlatform.ios, 'leftShoulder', 'rightShoulder'),
    (GamepadPlatform.android, 'KEYCODE_BUTTON_L1', 'KEYCODE_BUTTON_R1'),
  ]) {
    test(
      '$platform normalizer routes bumpers to tabs with one held transition',
      () {
        final normalizer = GamepadNormalizer.forPlatform(platform);
        final bridge = RuntimePlayerGamepadBridge();
        for (final (key, control) in [
          (left, RuntimeInputControl.previousTab),
          (right, RuntimeInputControl.nextTab),
        ]) {
          List<RuntimeInputEvent> send(double value) => normalizer
              .normalize(
                GamepadEvent(
                  gamepadId: 'mobile-pad',
                  timestamp: 1,
                  type: KeyType.button,
                  key: key,
                  value: value,
                ),
              )
              .expand(bridge.handle)
              .toList();
          expect(send(1), [RuntimeInputEvent.press(control)]);
          expect(send(1), isEmpty);
          expect(send(0), [RuntimeInputEvent.release(control)]);
        }
      },
    );
  }
  for (final first in ['hardware', 'normalized']) {
    for (final control in [
      RuntimeInputControl.primary,
      RuntimeInputControl.right,
    ]) {
      test(
        'controller mux $first first coalesces duplicate $control until both release',
        () {
          final mux = RuntimePlayerControllerInputMux();
          final second = first == 'hardware' ? 'normalized' : 'hardware';
          final firstId = first == 'hardware' ? 'hardware-gamepad' : 'pad';
          final secondId = first == 'hardware' ? 'pad' : firstId;
          final press = mux.route(
            RuntimeInputEvent.press(control),
            path: first,
            deviceId: firstId,
          );
          expect(press?.event, RuntimeInputEvent.press(control));
          expect(
            mux.route(
              RuntimeInputEvent.press(control),
              path: second,
              deviceId: secondId,
            ),
            isNull,
          );
          final ownerId = 'pad';
          expect(
            mux
                .route(
                  RuntimeInputEvent.press(control, isRepeat: true),
                  path: first,
                  deviceId: ownerId,
                )
                ?.event,
            RuntimeInputEvent.press(control, isRepeat: true),
          );
          expect(
            mux.route(
              RuntimeInputEvent.press(control, isRepeat: true),
              path: second,
              deviceId: ownerId,
            ),
            isNull,
          );
          expect(
            mux.route(
              RuntimeInputEvent.release(control),
              path: first,
              deviceId: ownerId,
            ),
            isNull,
          );
          final release = mux.route(
            RuntimeInputEvent.release(control),
            path: second,
            deviceId: ownerId,
          );
          expect(release?.event, RuntimeInputEvent.release(control));
          expect(release?.deviceId, 'pad');
          expect(
            mux
                .route(
                  RuntimeInputEvent.press(control),
                  path: first,
                  deviceId: firstId,
                )
                ?.event,
            RuntimeInputEvent.press(control),
          );
        },
      );
    }
  }

  test('hardware-first owner adopts normalized identity and disconnect releases held movement once', () {
    final policy = PlayerInputSourcePolicy(touchAvailable: true);
    final mux = RuntimePlayerControllerInputMux(
      onDeviceAdopted: policy.adoptControllerId,
    );
    final first = mux.route(
      const RuntimeInputEvent.press(RuntimeInputControl.right),
      path: 'hardware',
      deviceId: 'hardware-gamepad',
    )!;
    expect(
      policy.route(
        first.event,
        owner: PlayerInputOwner(
          PlayerInputSource.controller,
          deviceId: first.deviceId,
        ),
        inputId: 'right',
      ),
      hasLength(1),
    );
    expect(
      mux.route(
        const RuntimeInputEvent.press(RuntimeInputControl.right),
        path: 'normalized',
        deviceId: 'pad',
      ),
      isNull,
    );
    expect(policy.activeControllerId, 'pad');
    expect(policy.connectedControllers, {'pad'});
    mux.disconnect('pad');
    expect(policy.updateControllers({}), [
      const RuntimeInputEvent.release(RuntimeInputControl.right),
    ]);
    expect(policy.updateControllers({}), isEmpty);
    expect(
      policy.route(
        const RuntimeInputEvent.release(RuntimeInputControl.right),
        owner: const PlayerInputOwner(
          PlayerInputSource.controller,
          deviceId: 'pad',
        ),
        inputId: 'right',
      ),
      isEmpty,
    );
    expect(
      mux.route(
        const RuntimeInputEvent.release(RuntimeInputControl.right),
        path: 'hardware',
        deviceId: 'pad',
      ),
      isNull,
    );
  });

  group('RuntimePlayerGamepadBridge', () {
    for (final key in ['AXIS_Y', 'AXIS_HAT_Y']) {
      for (final (value, control) in [
        (1.0, RuntimeInputControl.up),
        (-1.0, RuntimeInputControl.down),
      ]) {
        test('Android plugin $key keeps ${control.name} after normalization', () {
          final normalizer = GamepadNormalizer.forPlatform(GamepadPlatform.android);
          final bridge = RuntimePlayerGamepadBridge();
          final inputs = normalizer.normalize(GamepadEvent(
            gamepadId: 'android-controller', timestamp: 0,
            type: KeyType.analog, key: key, value: value,
          )).expand(bridge.handle).toList();
          expect(inputs, [RuntimeInputEvent.press(control)]);
          final release = normalizer.normalize(GamepadEvent(
            gamepadId: 'android-controller', timestamp: 1,
            type: KeyType.analog, key: key, value: 0,
          )).expand(bridge.handle).toList();
          expect(release, [RuntimeInputEvent.release(control)]);
        });
      }
    }
    test('a newly mapped held button must be released before activation', () {
      final first = RuntimePlayerGamepadBridge();
      expect(first.handleButton(gamepadId: 'pad', button: GamepadButton.x, value: 1), isEmpty);
      final remapped = first.rebind(PlayerControlProfile.standard.rebind(
        device: PlayerControlDevice.gamepad,
        control: RuntimeInputControl.primary,
        inputId: GamepadButton.x.name,
      ).profile);
      expect(remapped.handleButton(gamepadId: 'pad', button: GamepadButton.x, value: 1), isEmpty);
      expect(remapped.handleButton(gamepadId: 'pad', button: GamepadButton.x, value: 0), isEmpty);
      expect(remapped.handleButton(gamepadId: 'pad', button: GamepadButton.x, value: 1),
        const [RuntimeInputEvent.press(RuntimeInputControl.primary)]);
    });

    test('a released unmapped button can be rebound without a second release', () {
      final first = RuntimePlayerGamepadBridge();
      first.handleButton(gamepadId: 'pad', button: GamepadButton.a, value: 1);
      final remapped = first.rebind(PlayerControlProfile.standard.rebind(
        device: PlayerControlDevice.gamepad,
        control: RuntimeInputControl.primary,
        inputId: GamepadButton.x.name,
      ).profile);
      expect(remapped.handleButton(gamepadId: 'pad', button: GamepadButton.a, value: 0), isEmpty);
      final restored = remapped.rebind(PlayerControlProfile.standard);
      expect(restored.handleButton(gamepadId: 'pad', button: GamepadButton.a, value: 1),
        const [RuntimeInputEvent.press(RuntimeInputControl.primary)]);
    });

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
