import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

Future<void> verifyUwu5InstalledMovement(PlayableMapGame game) async {
  for (var x = 7; x >= 1; x--) {
    await _step(game, RuntimeInputControl.left);
    expect(game.gameStateSnapshot.playerPosition, GridPos(x: x, y: 8));
    if (x == 5) print('UWU5_INSTALLED_RENAMED_TERRAIN_TRAVERSED=5,8');
  }
  await _step(game, RuntimeInputControl.left);
  expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 8));
  print('UWU5_INSTALLED_COLLISION_BLOCKED=0,8');
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
