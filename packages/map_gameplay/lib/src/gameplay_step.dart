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
    InteractIntent() => _resolveInteract(world),
  };
}

GameplayStepResult _resolveMove(GameplayWorldState world, Direction direction) {
  final facingWorld = world.withPlayer(
    world.player.copyWith(facing: direction),
  );

  final tx = world.player.pos.x + direction.dx;
  final ty = world.player.pos.y + direction.dy;
  final isOutOfBounds = tx < 0 ||
      ty < 0 ||
      tx >= world.map.size.width ||
      ty >= world.map.size.height;

  if (isOutOfBounds) {
    final connectionDirection = _connectionDirectionForMove(direction);
    final connection = findMapConnection(world.map, connectionDirection);
    if (connection == null) {
      return Blocked(facingWorld);
    }
    return ConnectionTriggered(
      facingWorld,
      TriggeredConnection(
        direction: connection.direction,
        targetMapId: connection.targetMapId,
        offset: connection.offset,
        sourcePos: world.player.pos,
      ),
    );
  }

  if (facingWorld.isBlocked(tx, ty)) {
    final bumpWarp = facingWorld.warpOnBumpAt(tx, ty, direction);
    if (bumpWarp != null) {
      return WarpTriggered(
        facingWorld,
        TriggeredWarp(
          warpId: bumpWarp.id,
          targetMapId: bumpWarp.targetMapId,
          targetPos: bumpWarp.targetPos,
          triggerMode: bumpWarp.triggerMode,
        ),
      );
    }
    final bumpBehavior = facingWorld.placedElementBehaviorOnBumpAt(tx, ty);
    if (bumpBehavior != null) {
      return PlacedElementInteracted(
        facingWorld,
        bumpBehavior.element,
        bumpBehavior.behavior,
        MapPlacedElementTriggerType.onBump,
      );
    }
    return Blocked(facingWorld);
  }

  final movedWorld = facingWorld.withPlayer(
    facingWorld.player.copyWith(pos: GridPos(x: tx, y: ty)),
  );
  final previousPos = facingWorld.player.pos;

  final warp = movedWorld.warpOnEnterAt(tx, ty, direction);
  if (warp != null) {
    return WarpTriggered(
      movedWorld,
      TriggeredWarp(
        warpId: warp.id,
        targetMapId: warp.targetMapId,
        targetPos: warp.targetPos,
        triggerMode: warp.triggerMode,
      ),
    );
  }

  final enterBehavior = movedWorld.placedElementBehaviorOnEnterAt(tx, ty);
  if (enterBehavior != null) {
    return PlacedElementInteracted(
      movedWorld,
      enterBehavior.element,
      enterBehavior.behavior,
      MapPlacedElementTriggerType.onEnter,
    );
  }

  final exitBehavior = movedWorld.placedElementBehaviorOnExitTransition(
    from: previousPos,
    to: movedWorld.player.pos,
  );
  if (exitBehavior != null) {
    return PlacedElementInteracted(
      movedWorld,
      exitBehavior.element,
      exitBehavior.behavior,
      MapPlacedElementTriggerType.onExit,
    );
  }

  final nearBehavior = movedWorld.placedElementBehaviorOnNearTransition(
    from: previousPos,
    to: movedWorld.player.pos,
  );
  if (nearBehavior != null) {
    return PlacedElementInteracted(
      movedWorld,
      nearBehavior.element,
      nearBehavior.behavior,
      MapPlacedElementTriggerType.onNear,
    );
  }

  return Moved(movedWorld);
}

MapConnectionDirection _connectionDirectionForMove(Direction direction) {
  return switch (direction) {
    Direction.north => MapConnectionDirection.north,
    Direction.south => MapConnectionDirection.south,
    Direction.east => MapConnectionDirection.east,
    Direction.west => MapConnectionDirection.west,
  };
}

GameplayStepResult _resolveInteract(GameplayWorldState world) {
  final facing = world.player.facing;
  final tx = world.player.pos.x + facing.dx;
  final ty = world.player.pos.y + facing.dy;
  final entity = world.entityAt(tx, ty);

  if (entity != null) {
    return switch (entity.kind) {
      MapEntityKind.npc => NpcInteracted(world, entity),
      MapEntityKind.sign => SignInteracted(world, entity),
      MapEntityKind.item => ItemInteracted(world, entity),
      _ => EntityInteracted(world, entity),
    };
  }

  final actionBehavior = world.placedElementBehaviorOnActionAt(tx, ty);
  if (actionBehavior != null) {
    return PlacedElementInteracted(
      world,
      actionBehavior.element,
      actionBehavior.behavior,
      MapPlacedElementTriggerType.onAction,
    );
  }

  return NothingToInteract(world);
}
