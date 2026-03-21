import 'package:freezed_annotation/freezed_annotation.dart';

part 'tileset.freezed.dart';
part 'tileset.g.dart';

@freezed
class TilesetConfig with _$TilesetConfig {
  const factory TilesetConfig({
    required String id,
    required String name,
    required String relativePath,
    required int tileSize,
    @Default([]) List<TileProperties> tileProperties,
  }) = _TilesetConfig;

  factory TilesetConfig.fromJson(Map<String, dynamic> json) => _$TilesetConfigFromJson(json);
}

@freezed
class TileProperties with _$TileProperties {
  const factory TileProperties({
    required int id,
    @Default({}) Map<String, dynamic> customProperties,
    @Default(false) bool isPassable,
  }) = _TileProperties;

  factory TileProperties.fromJson(Map<String, dynamic> json) => _$TilePropertiesFromJson(json);
}
