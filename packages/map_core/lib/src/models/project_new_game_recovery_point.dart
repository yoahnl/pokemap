import 'package:meta/meta.dart' show immutable;

import 'enums.dart';
import 'geometry.dart';

@immutable
final class ProjectNewGameRecoveryPoint {
  const ProjectNewGameRecoveryPoint({
    required this.mapId,
    required this.position,
    required this.facing,
  });

  factory ProjectNewGameRecoveryPoint.fromJson(Map<String, dynamic> json) {
    if (json.keys.any(
      (key) => !const {'mapId', 'position', 'facing'}.contains(key),
    )) {
      throw const FormatException(
        'initialRecoveryPoint contains unknown fields.',
      );
    }
    final mapId = json['mapId'];
    final position = json['position'];
    final facing = json['facing'];
    if (mapId is! String ||
        mapId.trim().isEmpty ||
        mapId != mapId.trim() ||
        position is! Map<String, dynamic> ||
        position.length != 2 ||
        !position.containsKey('x') ||
        !position.containsKey('y') ||
        position['x'] is! int ||
        position['y'] is! int ||
        (position['x'] as int) < 0 ||
        (position['y'] as int) < 0 ||
        facing is! String ||
        !EntityFacing.values.any((value) => value.name == facing)) {
      throw const FormatException(
        'initialRecoveryPoint requires a map, non-negative grid position and cardinal facing.',
      );
    }
    return ProjectNewGameRecoveryPoint(
      mapId: mapId,
      position: GridPos(x: position['x'] as int, y: position['y'] as int),
      facing: EntityFacing.values.byName(facing),
    );
  }

  final String mapId;
  final GridPos position;
  final EntityFacing facing;

  Map<String, dynamic> toJson() => {
    'mapId': mapId,
    'position': position.toJson(),
    'facing': facing.name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectNewGameRecoveryPoint &&
          other.mapId == mapId &&
          other.position == position &&
          other.facing == facing;

  @override
  int get hashCode => Object.hash(mapId, position, facing);
}
