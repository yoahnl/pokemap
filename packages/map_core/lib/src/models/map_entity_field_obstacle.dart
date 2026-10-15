import 'package:meta/meta.dart';

import 'enums.dart';

enum FieldObstacleKind { cutTree }

enum FieldObstacleResetPolicy { mapInstance }

@immutable
final class MapEntityFieldObstacleData {
  const MapEntityFieldObstacleData({
    this.kind = FieldObstacleKind.cutTree,
    this.resetPolicy = FieldObstacleResetPolicy.mapInstance,
  });

  final FieldObstacleKind kind;
  final FieldObstacleResetPolicy resetPolicy;
  FieldAbility get ability => switch (kind) {
    FieldObstacleKind.cutTree => FieldAbility.cut,
  };

  factory MapEntityFieldObstacleData.fromJson(Map<String, dynamic> json) {
    if (json.length != 2 ||
        !json.keys.every(const {'kind', 'resetPolicy'}.contains) ||
        json['kind'] != 'cutTree' ||
        json['resetPolicy'] != 'mapInstance') {
      throw const FormatException('Unsupported field obstacle contract.');
    }
    return const MapEntityFieldObstacleData();
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'resetPolicy': resetPolicy.name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapEntityFieldObstacleData &&
          other.kind == kind &&
          other.resetPolicy == resetPolicy;
  @override
  int get hashCode => Object.hash(kind, resetPolicy);
}
