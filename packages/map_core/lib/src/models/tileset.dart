import 'package:freezed_annotation/freezed_annotation.dart';

part 'tileset.freezed.dart';
part 'tileset.g.dart';

@freezed
class TilesetConfig with _$TilesetConfig {
  @JsonSerializable(explicitToJson: true)
  const factory TilesetConfig({
    required String id,
    required String name,
    required String relativePath, // path to the image asset
    @Default(32) int tileSize,
    @Default([]) List<TileProperties> tileProperties,
    @Default({}) Map<String, dynamic> customProperties,
  }) = _TilesetConfig;

  factory TilesetConfig.fromJson(Map<String, dynamic> json) => _$TilesetConfigFromJson(json);
}

@freezed
class TileProperties with _$TileProperties {
  const factory TileProperties({
    required int tileId,
    @Default(true) bool isPassable,
    @Default({}) Map<String, dynamic> properties,
  }) = _TileProperties;

  factory TileProperties.fromJson(Map<String, dynamic> json) => _$TilePropertiesFromJson(json);
}
