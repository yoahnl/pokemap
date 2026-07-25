import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('controller directions become layout-independent focus intents', () {
    final intent = RuntimePlayerInputIntent.fromCommand(
      const PlayerInputCommand.press(
        PlayerInputAction.down,
        source: PlayerInputSource.controller,
      ),
    );

    expect(intent.type, RuntimePlayerInputIntentType.moveFocus);
    expect(intent.direction, RuntimePlayerFocusDirection.down);
    expect(intent.source, PlayerInputSource.controller);
    expect(intent.isRepeat, isFalse);
  });

  test('keyboard confirm and Menu become shared player intents', () {
    final confirm = RuntimePlayerInputIntent.fromCommand(
      const PlayerInputCommand.press(
        PlayerInputAction.confirm,
        source: PlayerInputSource.keyboard,
      ),
    );
    final menu = RuntimePlayerInputIntent.fromCommand(
      const PlayerInputCommand.press(
        PlayerInputAction.menu,
        source: PlayerInputSource.keyboard,
      ),
    );

    expect(confirm.type, RuntimePlayerInputIntentType.confirm);
    expect(menu.type, RuntimePlayerInputIntentType.openMenu);
  });

  test('mouse and touch can activate an explicit pointer target', () {
    final mouse = RuntimePlayerInputIntent.activatePointerTarget(
      source: PlayerInputSource.mouse,
      targetId: 'pause.save',
    );
    final touch = RuntimePlayerInputIntent.activatePointerTarget(
      source: PlayerInputSource.touch,
      targetId: 'pause.resume',
    );

    expect(mouse.type, RuntimePlayerInputIntentType.activatePointerTarget);
    expect(mouse.targetId, 'pause.save');
    expect(touch.targetId, 'pause.resume');
  });

  test('pointer target activation rejects non-pointer sources', () {
    expect(
      () => RuntimePlayerInputIntent.activatePointerTarget(
        source: PlayerInputSource.controller,
        targetId: 'pause.save',
      ),
      throwsArgumentError,
    );
    expect(
      () => RuntimePlayerInputIntent.activatePointerTarget(
        source: PlayerInputSource.touch,
        targetId: '  ',
      ),
      throwsArgumentError,
    );
  });

  test('source changes preserve the logical selection', () {
    const initial = RuntimePlayerInputState(
      activeSource: PlayerInputSource.touch,
      logicalSelectionId: 'pause.bag',
    );

    final controllerState = initial.record(
      RuntimePlayerInputIntent.fromCommand(
        const PlayerInputCommand.press(
          PlayerInputAction.up,
          source: PlayerInputSource.controller,
        ),
      ),
    );

    expect(controllerState.activeSource, PlayerInputSource.controller);
    expect(controllerState.logicalSelectionId, 'pause.bag');
  });

  test('touch menu button stays visible but dims after controller input', () {
    expect(
      playerTouchMenuButtonPresentation(
        touchControlsAvailable: true,
        activeSource: PlayerInputSource.touch,
      ),
      PlayerTouchMenuButtonPresentation.prominent,
    );
    expect(
      playerTouchMenuButtonPresentation(
        touchControlsAvailable: true,
        activeSource: PlayerInputSource.controller,
      ),
      PlayerTouchMenuButtonPresentation.subdued,
    );
    expect(
      playerTouchMenuButtonPresentation(
        touchControlsAvailable: false,
        activeSource: PlayerInputSource.controller,
      ),
      PlayerTouchMenuButtonPresentation.hidden,
    );
  });
}
