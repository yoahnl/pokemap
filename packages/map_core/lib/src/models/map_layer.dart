import 'package:freezed_annotation/freezed_annotation.dart';

import '../operations/border_layer_content_json_codec.dart';
import '../operations/environment_layer_content_json_codec.dart';
import 'border_layer.dart';
import 'enums.dart';
import 'environment.dart';
import 'project_manifest.dart';
import 'smart_tile.dart';
import 'smart_tile_field.dart';

part 'map_layer.freezed.dart';
part 'map_layer.g.dart';

const Object _explicitNullBorderLayerContent = Object();

Object? _readBorderLayerContent(Map json, String key) {
  if (!json.containsKey(key)) {
    return null;
  }
  return json[key] ?? _explicitNullBorderLayerContent;
}

BorderLayerContent _borderLayerContentFromJson(Object? json) {
  if (identical(json, _explicitNullBorderLayerContent)) {
    throw const FormatException(r'$.content: expected an object');
  }
  return decodeBorderLayerContentJson(json, path: r'$.content');
}

Map<String, Object?> _borderLayerContentToJson(BorderLayerContent content) =>
    encodeBorderLayerContentJson(content, path: r'$.content');

@freezed
class SurfaceCellPlacement with _$SurfaceCellPlacement {
  const factory SurfaceCellPlacement({
    required int x,
    required int y,
    required String surfacePresetId,
  }) = _SurfaceCellPlacement;

  factory SurfaceCellPlacement.fromJson(Map<String, dynamic> json) =>
      _$SurfaceCellPlacementFromJson(json);
}

@freezed
sealed class MapLayer with _$MapLayer {
  const MapLayer._();

  @FreezedUnionValue('tile')
  const factory MapLayer.tile({
    required String id,
    required String name,
    String? tilesetId,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
    @Default([]) List<int> tiles,
  }) = TileLayer;

  @FreezedUnionValue('collision')
  const factory MapLayer.collision({
    required String id,
    required String name,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
    @Default([]) List<bool> collisions,
  }) = CollisionLayer;

  @FreezedUnionValue('terrain')
  const factory MapLayer.terrain({
    required String id,
    required String name,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
    @Default([]) List<TerrainType> terrains,
  }) = TerrainLayer;

  @FreezedUnionValue('path')
  @JsonSerializable(explicitToJson: true)
  const factory MapLayer.path({
    required String id,
    required String name,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
    @Default('') String presetId,
    @Default([]) List<bool> cells,
    @Default(<String, String>{}) Map<String, String> properties,
    @Default(PathAnimationMode.triggered) PathAnimationMode animationMode,
    @Default([]) List<PathAnimationTriggerRule> animationTriggers,
  }) = PathLayer;

  @FreezedUnionValue('surface')
  @JsonSerializable(explicitToJson: true)
  const factory MapLayer.surface({
    required String id,
    required String name,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
    @Default([]) List<SurfaceCellPlacement> placements,
    @Default(<String, String>{}) Map<String, String> properties,
  }) = SurfaceLayer;

  @FreezedUnionValue('smart_tile')
  @JsonSerializable(explicitToJson: true)
  const factory MapLayer.smartTile({
    required String id,
    required String name,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
    required String presetId,
    required SmartTileUsage usage,
    @Default(<String>['']) List<String> materialPalette,
    required SmartTileField field,
    @Default(0) int layerSeed,
    @Default(<String, String>{}) Map<String, String> properties,
  }) = SmartTileLayer;

  @FreezedUnionValue('object')
  const factory MapLayer.object({
    required String id,
    required String name,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
  }) = ObjectLayer;

  @FreezedUnionValue('environment')
  @JsonSerializable(explicitToJson: true)
  const factory MapLayer.environment({
    required String id,
    required String name,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
    @JsonKey(
      fromJson: decodeEnvironmentLayerContent,
      toJson: encodeEnvironmentLayerContent,
    )
    @Default(EnvironmentLayerContent.emptyContent)
    EnvironmentLayerContent content,
    @Default(<String, String>{}) Map<String, String> properties,
  }) = EnvironmentLayer;

  @FreezedUnionValue('border')
  @JsonSerializable(explicitToJson: true)
  const factory MapLayer.border({
    required String id,
    required String name,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
    @JsonKey(
      readValue: _readBorderLayerContent,
      fromJson: _borderLayerContentFromJson,
      toJson: _borderLayerContentToJson,
    )
    @Default(BorderLayerContent.emptyContent)
    BorderLayerContent content,
    @Default(<String, String>{}) Map<String, String> properties,
  }) = BorderLayer;

  factory MapLayer.fromJson(Map<String, dynamic> json) =>
      _mapLayerFromJson(json);
}

MapLayer _mapLayerFromJson(Map<String, dynamic> json) {
  if (json['runtimeType'] == 'smart_tile' &&
      json.containsKey('layerSeed') &&
      json['layerSeed'] is! int) {
    throw const FormatException(
      'smart_tile_integer_invalid: layerSeed must be an exact JSON integer',
    );
  }
  return _$MapLayerFromJson(json);
}
