import 'package:meta/meta.dart';

import 'enums.dart';

enum FieldObstacleKind { cutTree, strengthBoulder, rockSmashRock, iceBlock }

enum FieldObstacleResetPolicy { mapInstance, persistent }

@immutable
final class MapEntityFieldObstacleData {
  const MapEntityFieldObstacleData({
    this.kind = FieldObstacleKind.cutTree,
    this.resetPolicy = FieldObstacleResetPolicy.mapInstance,
  });

  final FieldObstacleKind kind;
  final FieldObstacleResetPolicy resetPolicy;
  bool get isPushable =>
      kind == FieldObstacleKind.strengthBoulder ||
      kind == FieldObstacleKind.iceBlock;

  FieldAbility? get ability => switch (kind) {
    FieldObstacleKind.cutTree => FieldAbility.cut,
    FieldObstacleKind.strengthBoulder => FieldAbility.strength,
    FieldObstacleKind.rockSmashRock => FieldAbility.rockSmash,
    FieldObstacleKind.iceBlock => null,
  };

  factory MapEntityFieldObstacleData.fromJson(Map<String, dynamic> json) {
    if (json.length != 2 ||
        !json.keys.every(const {'kind', 'resetPolicy'}.contains) ||
        !FieldObstacleKind.values.any((kind) => kind.name == json['kind']) ||
        !FieldObstacleResetPolicy.values.any((policy) => policy.name == json['resetPolicy'])) {
      throw const FormatException('Unsupported field obstacle contract.');
    }
    final value = MapEntityFieldObstacleData(
      kind: FieldObstacleKind.values.singleWhere(
        (kind) => kind.name == json['kind'],
      ),
      resetPolicy: FieldObstacleResetPolicy.values.singleWhere(
        (policy) => policy.name == json['resetPolicy']),
    );
    value._validatePolicy();
    return value;
  }

  void _validatePolicy() {
    if (kind == FieldObstacleKind.iceBlock && resetPolicy == FieldObstacleResetPolicy.persistent) {
      throw const FormatException('Ice blocks cannot retain persistent positions.');
    }
  }

  Map<String, dynamic> toJson() {
    _validatePolicy();
    return {
    'kind': kind.name,
    'resetPolicy': resetPolicy.name,
  };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapEntityFieldObstacleData &&
          other.kind == kind &&
          other.resetPolicy == resetPolicy;
  @override
  int get hashCode => Object.hash(kind, resetPolicy);
}
