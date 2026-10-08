import 'geometry.dart';

final class PlayerSpatialPosition {
  PlayerSpatialPosition({required this.x, required this.z}) {
    if (!x.isFinite || !z.isFinite || x < 0 || z < 0) {
      throw const FormatException('Invalid spatial player position.');
    }
  }

  static const schemaVersion = 1;
  final double x;
  final double z;

  void validateGridPosition(GridPos position) {
    if (position.x != x.floor() || position.y != z.floor()) {
      throw StateError('Spatial and grid player positions disagree.');
    }
  }

  factory PlayerSpatialPosition.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != schemaVersion ||
        json.keys.any((key) => !{'schemaVersion', 'x', 'z'}.contains(key)) ||
        json['x'] is! num ||
        json['z'] is! num) {
      throw const FormatException('Unsupported spatial player position.');
    }
    return PlayerSpatialPosition(
      x: (json['x'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'x': x,
        'z': z,
      };

  @override
  bool operator ==(Object other) =>
      other is PlayerSpatialPosition && x == other.x && z == other.z;

  @override
  int get hashCode => Object.hash(x, z);
}
