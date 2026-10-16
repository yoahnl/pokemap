import 'package:meta/meta.dart';

import 'enums.dart';

enum FieldObstacleKind { cutTree, strengthBoulder, rockSmashRock }

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
    FieldObstacleKind.strengthBoulder => FieldAbility.strength,
    FieldObstacleKind.rockSmashRock => FieldAbility.rockSmash,
  };

  factory MapEntityFieldObstacleData.fromJson(Map<String, dynamic> json) {
    if (json.length != 2 ||
        !json.keys.every(const {'kind', 'resetPolicy'}.contains) ||
        !FieldObstacleKind.values.any((kind) => kind.name == json['kind']) ||
        json['resetPolicy'] != 'mapInstance') {
      throw const FormatException('Unsupported field obstacle contract.');
    }
    return MapEntityFieldObstacleData(
      kind: FieldObstacleKind.values.singleWhere(
        (kind) => kind.name == json['kind'],
      ),
    );
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
