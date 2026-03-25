import 'package:freezed_annotation/freezed_annotation.dart';
import 'geometry.dart';
import 'enums.dart';
import 'map_entity_payloads.dart';
import 'map_layer.dart';

part 'map_data.freezed.dart';
part 'map_data.g.dart';

@freezed
class MapData with _$MapData {
  @JsonSerializable(explicitToJson: true)
  const factory MapData({
    required String id,
    required String name,
    required GridSize size,
    @Default(ProjectVersion.v1) ProjectVersion version,
    @Default('') String tilesetId,
    @Default([]) List<MapLayer> layers,
    @Default([]) List<MapEntity> entities,
    @Default([]) List<MapConnection> connections,
    @Default([]) List<MapWarp> warps,
    @Default([]) List<MapTrigger> triggers,
    @Default({}) Map<String, dynamic> properties,
  }) = _MapData;

  factory MapData.fromJson(Map<String, dynamic> json) =>
      _$MapDataFromJson(json);
}

@freezed
class MapEntity with _$MapEntity {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntity({
    required String id,
    @Default('') String name,
    required MapEntityKind kind,
    required GridPos pos,
    @Default(GridSize(width: 1, height: 1)) GridSize size,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    /// Propriétés libres (surtout pour [MapEntityKind.custom] et extensions).
    @Default({}) Map<String, String> properties,
  }) = _MapEntity;

  factory MapEntity.fromJson(Map<String, dynamic> json) =>
      _$MapEntityFromJson(migrateMapEntityJson(json));
}

extension MapEntityDisplayX on MapEntity {
  /// Libellé court pour listes / canvas (hors [id] technique).
  String get inspectorHeadline {
    switch (kind) {
      case MapEntityKind.npc:
        final d = npc?.displayName.trim();
        if (d != null && d.isNotEmpty) return d;
        break;
      case MapEntityKind.sign:
        final t = sign?.title.trim();
        if (t != null && t.isNotEmpty) return t;
        break;
      case MapEntityKind.item:
        final id = item?.gameItemId.trim();
        if (id != null && id.isNotEmpty) return id;
        break;
      case MapEntityKind.spawn:
        final k = spawn?.spawnKey.trim();
        if (k != null && k.isNotEmpty) return k;
        break;
      case MapEntityKind.custom:
        break;
    }
    final n = name.trim();
    return n.isNotEmpty ? n : id;
  }
}

@freezed
class MapWarp with _$MapWarp {
  @JsonSerializable(explicitToJson: true)
  const factory MapWarp({
    required String id,
    required GridPos pos,
    required String targetMapId,
    required GridPos targetPos,
  }) = _MapWarp;

  factory MapWarp.fromJson(Map<String, dynamic> json) =>
      _$MapWarpFromJson(json);
}

@freezed
class MapConnection with _$MapConnection {
  @JsonSerializable(explicitToJson: true)
  const factory MapConnection({
    required MapConnectionDirection direction,
    required String targetMapId,
    @Default(0) int offset,
  }) = _MapConnection;

  factory MapConnection.fromJson(Map<String, dynamic> json) =>
      _$MapConnectionFromJson(json);
}

@freezed
class MapTrigger with _$MapTrigger {
  @JsonSerializable(explicitToJson: true)
  const factory MapTrigger({
    required String id,
    @Default('') String name,
    required TriggerType type,
    required MapRect area,
    @Default({}) Map<String, String> properties,
  }) = _MapTrigger;

  factory MapTrigger.fromJson(Map<String, dynamic> json) =>
      _$MapTriggerFromJson(json);
}
