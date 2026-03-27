import 'package:map_core/map_core.dart';

import 'gameplay_world_state.dart';

class TriggeredWarp {
  const TriggeredWarp({
    required this.warpId,
    required this.targetMapId,
    required this.targetPos,
  });

  final String warpId;
  final String targetMapId;
  final GridPos targetPos;
}

sealed class GameplayStepResult {
  const GameplayStepResult(this.world);
  final GameplayWorldState world;
}

final class Moved extends GameplayStepResult {
  const Moved(super.world);
}

final class Blocked extends GameplayStepResult {
  const Blocked(super.world);
}

final class WarpTriggered extends GameplayStepResult {
  const WarpTriggered(super.world, this.warp);
  final TriggeredWarp warp;
}

final class NothingToInteract extends GameplayStepResult {
  const NothingToInteract(super.world);
}

final class NpcInteracted extends GameplayStepResult {
  const NpcInteracted(super.world, this.entity);
  final MapEntity entity;
}

final class SignInteracted extends GameplayStepResult {
  const SignInteracted(super.world, this.entity);
  final MapEntity entity;
}

final class ItemInteracted extends GameplayStepResult {
  const ItemInteracted(super.world, this.entity);
  final MapEntity entity;
}

final class EntityInteracted extends GameplayStepResult {
  const EntityInteracted(super.world, this.entity);
  final MapEntity entity;
}
