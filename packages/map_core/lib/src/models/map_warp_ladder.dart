import 'enums.dart';

enum MapWarpLadderDirection { up, down }

final class MapWarpLadder {
  MapWarpLadder({
    this.direction = MapWarpLadderDirection.up,
    this.facing = EntityFacing.north,
    this.heightCells = 2,
    this.durationSeconds = 16 / 30,
  }) {
    if (!heightCells.isFinite ||
        heightCells <= 0 ||
        heightCells > 16 ||
        !durationSeconds.isFinite ||
        durationSeconds <= 0 ||
        durationSeconds > 10) {
      throw const FormatException('Invalid ladder height or duration.');
    }
  }

  final MapWarpLadderDirection direction;
  final EntityFacing facing;
  final double heightCells;
  final double durationSeconds;

  factory MapWarpLadder.fromJson(Map<String, dynamic> json) {
    if (json.keys.any(
      (key) => !const {
        'direction',
        'facing',
        'heightCells',
        'durationSeconds',
      }.contains(key),
    )) {
      throw const FormatException('Unexpected ladder traversal field.');
    }
    final direction = MapWarpLadderDirection.values
        .where((v) => v.name == json['direction'])
        .firstOrNull;
    final facing = EntityFacing.values
        .where((v) => v.name == json['facing'])
        .firstOrNull;
    final height = json['heightCells'], duration = json['durationSeconds'];
    if (direction == null ||
        facing == null ||
        height is! num ||
        duration is! num) {
      throw const FormatException('Invalid ladder traversal values.');
    }
    return MapWarpLadder(
      direction: direction,
      facing: facing,
      heightCells: height.toDouble(),
      durationSeconds: duration.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'direction': direction.name,
    'facing': facing.name,
    'heightCells': heightCells,
    'durationSeconds': durationSeconds,
  };

  @override
  bool operator ==(Object other) =>
      other is MapWarpLadder &&
      direction == other.direction &&
      facing == other.facing &&
      heightCells == other.heightCells &&
      durationSeconds == other.durationSeconds;

  @override
  int get hashCode =>
      Object.hash(direction, facing, heightCells, durationSeconds);
}
