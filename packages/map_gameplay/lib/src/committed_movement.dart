import 'package:map_core/map_core.dart';

enum CommittedMovementKind {
  walk,
  forced,
  bicycle,
  surf,
  mapConnection,
  warp,
  blocked,
}

final class CommittedMovement {
  const CommittedMovement({
    required this.kind,
    required this.fromCell,
    required this.toCell,
  });

  final CommittedMovementKind kind;
  final GridPos fromCell;
  final GridPos toCell;
}

enum ForcedMovementStepPolicy {
  include,
  exclude,
}

final class CommittedMovementStepPolicy {
  const CommittedMovementStepPolicy({required this.forcedMovement});

  final ForcedMovementStepPolicy forcedMovement;

  int unitsFor(CommittedMovement movement) {
    final countsTraversal = switch (movement.kind) {
      CommittedMovementKind.walk ||
      CommittedMovementKind.bicycle ||
      CommittedMovementKind.surf =>
        true,
      CommittedMovementKind.forced =>
        forcedMovement == ForcedMovementStepPolicy.include,
      CommittedMovementKind.mapConnection ||
      CommittedMovementKind.warp ||
      CommittedMovementKind.blocked =>
        false,
    };
    if (!countsTraversal) return 0;
    final dx = (movement.toCell.x - movement.fromCell.x).abs();
    final dy = (movement.toCell.y - movement.fromCell.y).abs();
    return dx <= 1 && dy <= 1 && dx + dy > 0 ? 1 : 0;
  }
}
