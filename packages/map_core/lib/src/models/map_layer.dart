import 'package:freezed_annotation/freezed_annotation.dart';

import '../operations/border_layer_content_json_codec.dart';
import '../operations/environment_layer_content_json_codec.dart';
import 'border_layer.dart';
import 'environment.dart';
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

/// Une table vide n'écrit pas de clé : combiné à `includeIfNull: false`, cela
/// évite un `"candidateWeights":{}` sur chaque calque Smart Tile existant.
Map<String, int>? _candidateWeightsToJson(Map<String, int> weights) =>
    weights.isEmpty ? null : weights;

/// Declares whether a literal layer participates in the playable visual stack.
///
/// Data layers remain fully authored and inspectable, but runtime composition
/// excludes them even when an editor temporarily makes them visible.
@JsonEnum(alwaysCreate: true)
enum MapLayerPurpose {
  @JsonValue('visual')
  visual,
  @JsonValue('data')
  data,
}

/// One canonical visual reference interned by a [TileLayer].
///
/// [localTileId] is the exact zero-based/sparse identity owned by the
/// tileset. [transform] spans the eight D4 symmetries through quarter turns
/// and one reflection, matching Tiled without retaining Tiled flags.
@freezed
class TileLayerPaletteEntry with _$TileLayerPaletteEntry {
  @JsonSerializable(explicitToJson: true)
  const factory TileLayerPaletteEntry({
    required String tilesetId,
    required int localTileId,
    @Default(SmartTileSpriteTransform()) SmartTileSpriteTransform transform,
  }) = _TileLayerPaletteEntry;

  factory TileLayerPaletteEntry.fromJson(Map<String, dynamic> json) =>
      _$TileLayerPaletteEntryFromJson(json);
}

/// One visual-only tile object positioned in fractional map-cell space.
///
/// The anchor follows the bottom-left convention used by tile objects. This
/// model deliberately owns no collision or gameplay fields: importing a
/// visual object can never make a cell impassable without a separate explicit
/// authoring action.
@freezed
class MapPlacedTile with _$MapPlacedTile {
  @JsonSerializable(explicitToJson: true)
  const factory MapPlacedTile({
    required String id,
    @Default('') String name,
    @Default('') String className,
    required TileLayerPaletteEntry tile,
    required double anchorX,
    required double anchorY,
    required double width,
    required double height,
    @Default(0) int quarterTurns,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
    @Default(<String, Object?>{}) Map<String, Object?> importMetadata,
  }) = _MapPlacedTile;

  factory MapPlacedTile.fromJson(Map<String, dynamic> json) =>
      _$MapPlacedTileFromJson(json);
}

@freezed
sealed class MapLayer with _$MapLayer {
  const MapLayer._();

  @FreezedUnionValue('tile')
  @JsonSerializable(explicitToJson: true)
  const factory MapLayer.tile({
    required String id,
    required String name,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
    @Default(MapLayerPurpose.visual) MapLayerPurpose purpose,
    @Default(<TileLayerPaletteEntry>[]) List<TileLayerPaletteEntry> palette,
    @Default(<int>[]) List<int> cells,
  }) = TileLayer;

  @FreezedUnionValue('collision')
  const factory MapLayer.collision({
    required String id,
    required String name,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
    @Default([]) List<bool> collisions,
  }) = CollisionLayer;

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
    @Default(<SmartTilePatternStroke>[])
    List<SmartTilePatternStroke> patternStrokes,
    @Default(0) int layerSeed,

    /// Surcharge locale des poids de variantes du preset, par identifiant de
    /// candidat. Une clé absente prend le poids du preset ; `0` exclut le
    /// candidat du tirage sur ce calque. Table vide : le calque suit le
    /// preset, et la clé n'est pas sérialisée.
    @JsonKey(toJson: _candidateWeightsToJson, includeIfNull: false)
    @Default(<String, int>{})
    Map<String, int> candidateWeights,
    @Default(<String, String>{}) Map<String, String> properties,
  }) = SmartTileLayer;

  @FreezedUnionValue('object')
  @JsonSerializable(explicitToJson: true)
  const factory MapLayer.object({
    required String id,
    required String name,
    @Default(true) bool isVisible,
    @Default(1.0) double opacity,
    @Default(MapLayerPurpose.visual) MapLayerPurpose purpose,
    @Default(<MapPlacedTile>[]) List<MapPlacedTile> tileObjects,
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

MapLayerPurpose mapLayerPurpose(MapLayer layer) => switch (layer) {
      TileLayer value => value.purpose,
      ObjectLayer value => value.purpose,
      _ => MapLayerPurpose.visual,
    };

bool mapLayerParticipatesInVisualComposition(MapLayer layer) =>
    mapLayerPurpose(layer) == MapLayerPurpose.visual;

MapLayer _mapLayerFromJson(Map<String, dynamic> json) {
  final canonical = migrateLegacyTileLayerJson(json);
  if (canonical['runtimeType'] == 'smart_tile' &&
      canonical.containsKey('layerSeed') &&
      canonical['layerSeed'] is! int) {
    throw const FormatException(
      'smart_tile_integer_invalid: layerSeed must be an exact JSON integer',
    );
  }
  return _$MapLayerFromJson(canonical);
}

/// One-way compatibility bridge for the historical `tilesetId` + `tiles`
/// payload. Every successful decode returns the palette form and serializers
/// never emit the historical keys again.
Map<String, dynamic> migrateLegacyTileLayerJson(
  Map<String, dynamic> json, {
  String? fallbackTilesetId,
}) {
  if (json['runtimeType'] != 'tile') return json;
  final hasLegacy = json.containsKey('tiles') || json.containsKey('tilesetId');
  final hasCanonical = json.containsKey('palette') || json.containsKey('cells');
  if (!hasLegacy) return json;
  if (hasCanonical) {
    throw const FormatException(
      'tile_layer_mixed_encoding: legacy and palette fields cannot coexist',
    );
  }
  final rawTiles = json['tiles'] ?? const <Object?>[];
  if (rawTiles is! List ||
      rawTiles.any((value) => value is! int || value < 0)) {
    throw const FormatException(
      'tile_layer_legacy_tiles_invalid: tiles must be non-negative integers',
    );
  }
  final rawTilesetId = json['tilesetId'] ?? fallbackTilesetId;
  if (rawTilesetId != null && rawTilesetId is! String) {
    throw const FormatException(
      'tile_layer_legacy_tileset_invalid: tilesetId must be a string',
    );
  }
  final tilesetId = (rawTilesetId as String?)?.trim() ?? '';
  if (rawTiles.any((value) => value != 0) && tilesetId.isEmpty) {
    throw const FormatException(
      'tile_layer_legacy_tileset_required: non-empty cells need a tileset',
    );
  }
  final palette = <Map<String, Object?>>[];
  final paletteIndexByLocalTileId = <int, int>{};
  final cells = <int>[];
  for (final rawTile in rawTiles.cast<int>()) {
    if (rawTile == 0) {
      cells.add(0);
      continue;
    }
    final localTileId = rawTile - 1;
    final paletteIndex = paletteIndexByLocalTileId.putIfAbsent(localTileId, () {
      palette.add(<String, Object?>{
        'tilesetId': tilesetId,
        'localTileId': localTileId,
        'transform': const SmartTileSpriteTransform().toJson(),
      });
      return palette.length;
    });
    cells.add(paletteIndex);
  }
  return <String, dynamic>{
    for (final entry in json.entries)
      if (entry.key != 'tiles' && entry.key != 'tilesetId')
        entry.key: entry.value,
    'palette': palette,
    'cells': cells,
  };
}

TileLayerPaletteEntry? resolveTileLayerCell(TileLayer layer, int cellIndex) {
  if (cellIndex < 0 || cellIndex >= layer.cells.length) return null;
  final paletteCell = layer.cells[cellIndex];
  if (paletteCell <= 0 || paletteCell > layer.palette.length) return null;
  return layer.palette[paletteCell - 1];
}

String? tileLayerSingleTilesetId(TileLayer layer) {
  final ids = layer.palette.map((entry) => entry.tilesetId).toSet();
  return ids.length == 1 ? ids.single : null;
}
