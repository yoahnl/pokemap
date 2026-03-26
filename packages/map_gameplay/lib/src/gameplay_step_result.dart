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
