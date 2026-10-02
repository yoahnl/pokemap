import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

Future<void> verifyUwu6BorderVisualSemantics(PlayableMapGame game) async {
  expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 8, y: 8));
  await _step(game, RuntimeInputControl.right);
  expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 9, y: 8));
  await _step(game, RuntimeInputControl.right);
  expect(
    game.gameStateSnapshot.playerPosition,
    const GridPos(x: 10, y: 8),
    reason: 'A visual border has no collision contract by itself.',
  );
  print('UWU6_INSTALLED_VISUAL_BORDER_CROSSED=10,8 automaticCollision=false');
  await _step(game, RuntimeInputControl.right);
  expect(
    game.gameStateSnapshot.playerPosition,
    const GridPos(x: 10, y: 8),
    reason: 'The collision painted explicitly on (11,8) must block movement.',
  );
  print('UWU6_INSTALLED_EXPLICIT_BORDER_COLLISION_BLOCKED=11,8 position=10,8');
  await _step(game, RuntimeInputControl.left);
  expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 9, y: 8));
  await _step(game, RuntimeInputControl.left);
  expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 8, y: 8));
}

Future<void> _step(PlayableMapGame game, RuntimeInputControl control) async {
  final before = game.gameStateSnapshot.playerPosition;
  expect(game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)), true);
  for (
    var i = 0;
    i < 80 && game.gameStateSnapshot.playerPosition == before;
    i++
  ) {
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  for (var i = 0; i < 80; i++) {
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
    if (!game.debugIsPlayerStepping && i > 0) return;
  }
  throw StateError('Installed Player movement did not finish.');
}
