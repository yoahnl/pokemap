import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'project_manifest.dart';

part 'map_layer.freezed.dart';
part 'map_layer.g.dart';

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

  @FreezedUnionValue('object')
  const factory MapLayer.object({
    required String id,
    required String name,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
  }) = ObjectLayer;

  factory MapLayer.fromJson(Map<String, dynamic> json) =>
      _$MapLayerFromJson(json);
}
