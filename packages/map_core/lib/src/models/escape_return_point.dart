import 'enums.dart';
import 'geometry.dart';
import 'player_spatial_position.dart';

final class EscapeReturnPoint {
  const EscapeReturnPoint({
    required this.dungeonId,
    required this.mapId,
    required this.position,
    required this.facing,
    this.spatialPosition,
  });

  factory EscapeReturnPoint.fromJson(Map<String, dynamic> json) {
    final dungeonId = json['dungeonId'];
    final mapId = json['mapId'];
    final position = json['position'];
    final facing = json['facing'];
    if (dungeonId is! String ||
        dungeonId.trim().isEmpty ||
        dungeonId != dungeonId.trim() ||
        mapId is! String ||
        mapId.trim().isEmpty ||
        mapId != mapId.trim() ||
        position is! Map<String, dynamic> ||
        !EntityFacing.values.any((value) => value.name == facing)) {
      throw const FormatException('Invalid escape return point');
    }
    final point = GridPos.fromJson(position);
    if (point.x < 0 || point.y < 0) {
      throw const FormatException('Invalid escape return position');
    }
    PlayerSpatialPosition? spatialPosition;
    if (json['spatialPosition'] != null) {
      final raw = json['spatialPosition'];
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid spatial escape return position');
      }
      spatialPosition = PlayerSpatialPosition.fromJson(raw);
      try {
        spatialPosition.validateGridPosition(point);
      } on StateError {
        throw const FormatException('Spatial escape return position disagrees with its cell');
      }
    }
    return EscapeReturnPoint(
      dungeonId: dungeonId,
      mapId: mapId,
      position: point,
      facing: EntityFacing.values.byName(facing as String),
      spatialPosition: spatialPosition,
    );
  }

  final String dungeonId;
  final String mapId;
  final GridPos position;
  final EntityFacing facing;
  final PlayerSpatialPosition? spatialPosition;

  Map<String, dynamic> toJson() => {
    'dungeonId': dungeonId,
    'mapId': mapId,
    'position': position.toJson(),
    'facing': facing.name,
    if (spatialPosition != null) 'spatialPosition': spatialPosition!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is EscapeReturnPoint &&
      dungeonId == other.dungeonId &&
      mapId == other.mapId &&
      position == other.position &&
      facing == other.facing &&
      spatialPosition == other.spatialPosition;

  @override
  int get hashCode => Object.hash(dungeonId, mapId, position, facing, spatialPosition);
}
