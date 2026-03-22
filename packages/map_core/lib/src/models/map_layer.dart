import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_layer.freezed.dart';
part 'map_layer.g.dart';

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
    @Default([]) List<int> tiles, // Flattened array
  }) = TileLayer;

  @FreezedUnionValue('collision')
  const factory MapLayer.collision({
    required String id,
    required String name,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
    @Default([]) List<bool> collisions, // Flattened array
  }) = CollisionLayer;

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
