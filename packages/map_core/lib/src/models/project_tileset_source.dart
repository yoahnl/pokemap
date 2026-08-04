// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_tileset_source.freezed.dart';
part 'project_tileset_source.g.dart';

@freezed
class VisualTileProperty with _$VisualTileProperty {
  const factory VisualTileProperty({
    required int tileId,
    @Default(true) bool passable,
    @Default(<String>[]) List<String> tags,
  }) = _VisualTileProperty;

  factory VisualTileProperty.fromJson(Map<String, dynamic> json) =>
      _$VisualTilePropertyFromJson(json);
}

/// Canonical source data required to resolve one project tileset.
///
/// The explicit discriminator is intentionally introduced before image
/// collections so future source kinds do not require another manifest shape
/// migration.
sealed class ProjectTilesetSource {
  const ProjectTilesetSource();

  const factory ProjectTilesetSource.regularAtlas({
    required String assetId,
    required int pixelWidth,
    required int pixelHeight,
    required int tileWidth,
    required int tileHeight,
    @Default(<VisualTileProperty>[]) List<VisualTileProperty> tileProperties,
  }) = ProjectRegularAtlasTilesetSource;

  factory ProjectTilesetSource.fromJson(Map<String, dynamic> json) {
    if (json['kind'] != 'regular_atlas') {
      throw FormatException(
        r'$.source.kind: tileset_source_kind_invalid ('
        '${json['kind']})',
      );
    }
    return ProjectRegularAtlasTilesetSource.fromJson(json);
  }

  Map<String, Object?> toJson();
}

final class ProjectRegularAtlasTilesetSource extends ProjectTilesetSource {
  const ProjectRegularAtlasTilesetSource({
    required this.assetId,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.tileWidth,
    required this.tileHeight,
    this.tileProperties = const <VisualTileProperty>[],
  });

  factory ProjectRegularAtlasTilesetSource.fromJson(
    Map<String, dynamic> json,
  ) {
    const allowed = <String>{
      'kind',
      'assetId',
      'pixelWidth',
      'pixelHeight',
      'tileWidth',
      'tileHeight',
      'tileProperties',
    };
    if (json.keys.any((key) => !allowed.contains(key)) ||
        json['assetId'] is! String ||
        json['pixelWidth'] is! int ||
        json['pixelHeight'] is! int ||
        json['tileWidth'] is! int ||
        json['tileHeight'] is! int ||
        json['tileProperties'] is! List) {
      throw const FormatException(
        r'$.source: regular_atlas_tileset_source_invalid',
      );
    }
    return ProjectRegularAtlasTilesetSource(
      assetId: json['assetId']! as String,
      pixelWidth: json['pixelWidth']! as int,
      pixelHeight: json['pixelHeight']! as int,
      tileWidth: json['tileWidth']! as int,
      tileHeight: json['tileHeight']! as int,
      tileProperties: <VisualTileProperty>[
        for (final raw in json['tileProperties']! as List)
          if (raw is Map)
            VisualTileProperty.fromJson(Map<String, dynamic>.from(raw))
          else
            throw const FormatException(
              r'$.source.tileProperties: expected objects',
            ),
      ],
    );
  }

  final String assetId;
  final int pixelWidth;
  final int pixelHeight;
  final int tileWidth;
  final int tileHeight;
  final List<VisualTileProperty> tileProperties;

  int get columns => pixelWidth ~/ tileWidth;
  int get rows => pixelHeight ~/ tileHeight;
  int get tileCount => columns * rows;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': 'regular_atlas',
        'assetId': assetId,
        'pixelWidth': pixelWidth,
        'pixelHeight': pixelHeight,
        'tileWidth': tileWidth,
        'tileHeight': tileHeight,
        'tileProperties': <Object?>[
          for (final property in tileProperties) property.toJson(),
        ],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectRegularAtlasTilesetSource &&
          other.assetId == assetId &&
          other.pixelWidth == pixelWidth &&
          other.pixelHeight == pixelHeight &&
          other.tileWidth == tileWidth &&
          other.tileHeight == tileHeight &&
          _listEquals(other.tileProperties, tileProperties);

  @override
  int get hashCode => Object.hash(
        assetId,
        pixelWidth,
        pixelHeight,
        tileWidth,
        tileHeight,
        Object.hashAll(tileProperties),
      );
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
