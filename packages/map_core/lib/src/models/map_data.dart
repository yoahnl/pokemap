import 'package:freezed_annotation/freezed_annotation.dart';
import 'geometry.dart';
import 'enums.dart';

part 'map_data.freezed.dart';
part 'map_data.g.dart';

@freezed
class MapData with _$MapData {
  @JsonSerializable(explicitToJson: true)
  const factory MapData({
    required String id,
    required String name,
    required GridSize size,
    @Default('v1') String version,
    required String tilesetId,
    @Default([]) List<MapLayerData> layers,
    @Default([]) List<MapEntity> entities,
    @Default([]) List<MapWarp> warps,
    @Default([]) List<MapTrigger> triggers,
    @Default({}) Map<String, dynamic> properties,
  }) = _MapData;

  factory MapData.fromJson(Map<String, dynamic> json) => _$MapDataFromJson(json);
}

@freezed
class MapLayerData with _$MapLayerData {
  @JsonSerializable(explicitToJson: true)
  const factory MapLayerData({
    required String id,
    required String name,
    required LayerType type,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
    // For Tile Layers
    @Default([]) List<int> tiles, // Flattened array
    // For Collision Layers
    @Default([]) List<bool> collisions, // Flattened array
  }) = _MapLayerData;

  factory MapLayerData.fromJson(Map<String, dynamic> json) => _$MapLayerDataFromJson(json);
}

@freezed
class MapEntity with _$MapEntity {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntity({
    required String id,
    required EntityType type,
    required GridPos pos,
    @Default({}) Map<String, dynamic> properties,
  }) = _MapEntity;

  factory MapEntity.fromJson(Map<String, dynamic> json) => _$MapEntityFromJson(json);
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

  factory MapWarp.fromJson(Map<String, dynamic> json) => _$MapWarpFromJson(json);
}

@freezed
class MapTrigger with _$MapTrigger {
  @JsonSerializable(explicitToJson: true)
  const factory MapTrigger({
    required String id,
    required TriggerType type,
    required GridPos pos,
    required MapRect zone, // Triggers can be zones
    @Default({}) Map<String, dynamic> properties,
  }) = _MapTrigger;

  factory MapTrigger.fromJson(Map<String, dynamic> json) => _$MapTriggerFromJson(json);
}
