import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'gameplay_intent.dart';
import 'gameplay_step_result.dart';
import 'gameplay_world_state.dart';

GameplayStepResult stepGameplayWorld(
  GameplayWorldState world,
  GameplayIntent intent,
) {
  return switch (intent) {
    MoveIntent(:final direction) => _resolveMove(world, direction),
  };
}

GameplayStepResult _resolveMove(GameplayWorldState world, Direction direction) {
  final facingWorld = world.withPlayer(
    world.player.copyWith(facing: direction),
  );

  final tx = world.player.pos.x + direction.dx;
  final ty = world.player.pos.y + direction.dy;

  if (facingWorld.isBlocked(tx, ty)) {
    return Blocked(facingWorld);
  }

  final movedWorld = facingWorld.withPlayer(
    facingWorld.player.copyWith(pos: GridPos(x: tx, y: ty)),
  );

  final warp = movedWorld.warpAt(tx, ty);
  if (warp != null) {
    return WarpTriggered(
      movedWorld,
      TriggeredWarp(
        warpId: warp.id,
        targetMapId: warp.targetMapId,
        targetPos: warp.targetPos,
      ),
    );
  }

  return Moved(movedWorld);
}
