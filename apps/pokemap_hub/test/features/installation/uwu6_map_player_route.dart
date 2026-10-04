import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../../../avelune_studio/test/support/m2_ui_fixture.dart' show pumpIo;

Future<void> playUwu6AddedMap(
  WidgetTester tester,
  PlayableMapGame game,
  bool Function(RuntimeInputEvent) input,
  String addedMapId,
) async {
  Future<void> step(String mapId, GridPos position) async {
    expect(
      input(const RuntimeInputEvent.press(RuntimeInputControl.down)),
      true,
    );
    game.update(.016);
    input(const RuntimeInputEvent.release(RuntimeInputControl.down));
    for (var i = 0; i < 200; i++) {
      if (game.gameStateSnapshot.currentMapId == mapId &&
          game.debugLastCompletedMapActivation?.mapId == mapId &&
          !game.debugIsMapActivationDispatchInFlight &&
          !game.inputAuthoritySnapshot.isGameplayLocked) {
        break;
      }
      await pumpIo(tester, frames: 2);
    }
    expect(game.gameStateSnapshot.currentMapId, mapId);
    expect(game.debugPlayerGridPosition, position);
    print('UWU6_INSTALLED_PASSAGE=$mapId:${position.x},${position.y}');
  }

  expect(game.gameStateSnapshot.currentMapId, 'first-map');
  expect(game.debugPlayerGridPosition, const GridPos(x: 16, y: 16));
  await step(addedMapId, const GridPos(x: 2, y: 2));
  void press(RuntimeInputControl control) {
    expect(input(RuntimeInputEvent.press(control)), true);
    game.update(.016);
    input(RuntimeInputEvent.release(control));
    game.update(.3);
  }

  for (var i = 0; i < 31; i++) {
    press(RuntimeInputControl.right);
  }
  expect(game.debugPlayerGridPosition, const GridPos(x: 33, y: 2));
  press(RuntimeInputControl.right);
  expect(game.debugPlayerGridPosition, const GridPos(x: 33, y: 2));
  print('UWU6_INSTALLED_EXTENDED_SURFACE=33,2;collision=34,2');
  for (var i = 0; i < 31; i++) {
    press(RuntimeInputControl.left);
  }
  expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
  await step('first-map', const GridPos(x: 16, y: 16));
}
