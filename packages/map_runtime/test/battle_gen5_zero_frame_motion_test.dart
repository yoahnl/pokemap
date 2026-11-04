import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_actor_motion.dart';

void main() {
  test('zero-frame position step reaches its destination in one tick', () {
    BattleGen5ActorPose? pose;
    final controller = BattleGen5ActorMotionController(
      claim: (_, _) => true,
      apply: (_, _, value) {
        pose = value;
        return true;
      },
      release: (_, _) {},
    );
    controller.start(
      actor: 'user',
      channel: BattleGen5ActorMotionChannel.position,
      type: 1,
      xFx32: 0,
      yFx32: -81920,
      frames: 0,
      wait: 0,
      times: 0,
    );
    controller.tick();
    expect(pose?.offsetYFx32, -81920);
    expect(controller.isBusy, isFalse);
    controller.cancel();
  });
}
