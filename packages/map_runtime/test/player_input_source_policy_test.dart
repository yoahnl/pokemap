import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

const keyboard = PlayerInputOwner(PlayerInputSource.keyboard);
const touch = PlayerInputOwner(PlayerInputSource.touch);
const pad = PlayerInputOwner(PlayerInputSource.controller, deviceId: 'pad');

void main() {
  test('physical aliases act independently and release the last held direction',
      () {
    final policy = PlayerInputSourcePolicy(touchAvailable: true);
    const confirm = RuntimeInputEvent.press(RuntimeInputControl.primary);
    expect(policy.route(confirm, owner: keyboard, inputId: 'enter'), [confirm]);
    expect(policy.route(confirm, owner: keyboard, inputId: 'space'), [confirm]);
    expect(policy.route(confirm, owner: keyboard, inputId: 'space'), isEmpty);
    const right = RuntimeInputEvent.press(RuntimeInputControl.right);
    const releaseRight = RuntimeInputEvent.release(RuntimeInputControl.right);
    expect(policy.route(right, owner: keyboard, inputId: 'arrow'), [right]);
    expect(policy.route(right, owner: keyboard, inputId: 'd'), isEmpty);
    expect(
        policy.route(releaseRight, owner: keyboard, inputId: 'arrow'), isEmpty);
    expect(policy.route(releaseRight, owner: keyboard, inputId: 'd'),
        [releaseRight]);
  });

  test('startup distinguishes available devices from intentional source', () {
    final policy = PlayerInputSourcePolicy(touchAvailable: true);
    expect(policy.activeSource, PlayerInputSource.touch);
    policy.updateControllers({'pad'});
    expect(policy.activeSource, PlayerInputSource.controller);
    policy.recognizeTouch();
    expect(policy.activeSource, PlayerInputSource.touch);
    policy.updateControllers({'pad', 'second'});
    expect(policy.activeSource, PlayerInputSource.touch);
    expect(policy.connectedControllers, {'pad', 'second'});
  });

  test('a first press switches presentation and is forwarded exactly once', () {
    final policy = PlayerInputSourcePolicy(touchAvailable: true);
    const event = RuntimeInputEvent.press(RuntimeInputControl.primary);
    expect(policy.route(event, owner: pad), [event]);
    expect(policy.activeSource, PlayerInputSource.controller);
    expect(policy.route(event, owner: pad), isEmpty);
    expect(
        policy.route(
            const RuntimeInputEvent.press(RuntimeInputControl.primary,
                isRepeat: true),
            owner: pad),
        isEmpty);
  });

  test('movement takeover releases the old owner before the first new press',
      () {
    final policy = PlayerInputSourcePolicy(touchAvailable: true);
    policy.route(const RuntimeInputEvent.press(RuntimeInputControl.right),
        owner: pad);
    policy.route(const RuntimeInputEvent.press(RuntimeInputControl.sprint),
        owner: pad);
    expect(
        policy.route(const RuntimeInputEvent.press(RuntimeInputControl.right),
            owner: touch),
        [
          const RuntimeInputEvent.release(RuntimeInputControl.right),
          const RuntimeInputEvent.release(RuntimeInputControl.sprint),
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ]);
    expect(
        policy.route(const RuntimeInputEvent.release(RuntimeInputControl.right),
            owner: pad),
        isEmpty);
    expect(
        policy.route(const RuntimeInputEvent.release(RuntimeInputControl.right),
            owner: touch),
        [
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ]);
    expect(policy.activeSource, PlayerInputSource.touch);
  });

  test('release and repeat never take presentation or movement back', () {
    final policy = PlayerInputSourcePolicy(touchAvailable: true);
    policy.route(const RuntimeInputEvent.press(RuntimeInputControl.left),
        owner: keyboard);
    policy.route(const RuntimeInputEvent.press(RuntimeInputControl.right),
        owner: pad);
    expect(
        policy.route(
            const RuntimeInputEvent.press(RuntimeInputControl.left,
                isRepeat: true),
            owner: keyboard),
        isEmpty);
    expect(
        policy.route(const RuntimeInputEvent.release(RuntimeInputControl.left),
            owner: keyboard),
        isEmpty);
    expect(policy.activeSource, PlayerInputSource.controller);
  });

  test('disconnect releases only commands belonging to that controller', () {
    final policy = PlayerInputSourcePolicy(touchAvailable: true);
    policy.updateControllers({'pad'});
    policy.route(const RuntimeInputEvent.press(RuntimeInputControl.right),
        owner: pad);
    policy.route(const RuntimeInputEvent.press(RuntimeInputControl.sprint),
        owner: pad);
    expect(policy.updateControllers({}), [
      const RuntimeInputEvent.release(RuntimeInputControl.right),
      const RuntimeInputEvent.release(RuntimeInputControl.sprint),
    ]);
    expect(policy.activeSource, PlayerInputSource.touch);
    policy.updateControllers({'pad'});
    expect(policy.activeSource, PlayerInputSource.touch);
    expect(
        policy.route(const RuntimeInputEvent.release(RuntimeInputControl.right),
            owner: pad),
        isEmpty);
  });

  test('a second touch action does not release the movement pointer', () {
    final policy = PlayerInputSourcePolicy(touchAvailable: true);
    policy.route(const RuntimeInputEvent.press(RuntimeInputControl.left),
        owner: touch);
    expect(
        policy.route(const RuntimeInputEvent.press(RuntimeInputControl.primary),
            owner: touch),
        [
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ]);
    expect(policy.releaseMovement(),
        [const RuntimeInputEvent.release(RuntimeInputControl.left)]);
  });

  test('blocked movement cannot be revived by a held repeat', () {
    final policy = PlayerInputSourcePolicy(touchAvailable: false);
    policy.route(const RuntimeInputEvent.press(RuntimeInputControl.up),
        owner: keyboard);
    policy.releaseMovement();
    expect(
        policy.route(
            const RuntimeInputEvent.press(RuntimeInputControl.up,
                isRepeat: true),
            owner: keyboard),
        isEmpty);
    policy.route(const RuntimeInputEvent.release(RuntimeInputControl.up),
        owner: keyboard);
    expect(
        policy.route(const RuntimeInputEvent.press(RuntimeInputControl.up),
            owner: keyboard),
        isNotEmpty);
  });
}
