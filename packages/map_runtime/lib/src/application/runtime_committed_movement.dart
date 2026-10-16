import 'package:map_gameplay/map_gameplay.dart';

typedef RuntimeCommittedMovementSink = void Function(
  RuntimeCommittedMovement movement,
);

final class RuntimeCommittedMovement {
  const RuntimeCommittedMovement({
    required this.mapId,
    required this.mapActivationId,
    required this.revision,
    required this.movement,
  });

  final String mapId;
  final String mapActivationId;
  final int revision;
  final CommittedMovement movement;

  String get operationId => '$mapActivationId:movement:$revision';
}
