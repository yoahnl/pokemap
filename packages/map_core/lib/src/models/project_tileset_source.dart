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

@JsonEnum(alwaysCreate: true)
enum ProjectTilesetPropertyType {
  @JsonValue('string')
  string,
  @JsonValue('integer')
  integer,
  @JsonValue('decimal')
  decimal,
  @JsonValue('boolean')
  boolean,
  @JsonValue('color')
  color,
  @JsonValue('asset_reference')
  assetReference,
  @JsonValue('object_reference')
  objectReference,
  @JsonValue('structured')
  structured,
}

@JsonEnum(alwaysCreate: true)
enum ProjectTilesetCollisionShape {
  rectangle,
  ellipse,
  polygon,
  polyline,
  point,
}

/// One explicitly typed metadata value attached to imported tileset data.
///
/// This is deliberately format-neutral: importers map their native property
/// model to these stable value kinds before the data enters a project.
@freezed
class ProjectTilesetProperty with _$ProjectTilesetProperty {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectTilesetProperty({
    required String name,
    required ProjectTilesetPropertyType type,
    Object? value,
    @JsonKey(includeIfNull: false) String? customType,
  }) = _ProjectTilesetProperty;

  factory ProjectTilesetProperty.fromJson(Map<String, dynamic> json) =>
      _$ProjectTilesetPropertyFromJson(json);
}

@freezed
class ProjectTilesetPixelRect with _$ProjectTilesetPixelRect {
  const factory ProjectTilesetPixelRect({
    required int x,
    required int y,
    required int width,
    required int height,
  }) = _ProjectTilesetPixelRect;

  factory ProjectTilesetPixelRect.fromJson(Map<String, dynamic> json) =>
      _$ProjectTilesetPixelRectFromJson(json);
}

@freezed
class ProjectTilesetPixelPoint with _$ProjectTilesetPixelPoint {
  const factory ProjectTilesetPixelPoint({
    required double x,
    required double y,
  }) = _ProjectTilesetPixelPoint;

  factory ProjectTilesetPixelPoint.fromJson(Map<String, dynamic> json) =>
      _$ProjectTilesetPixelPointFromJson(json);
}

/// Canonical collision geometry preserved from one visual tile.
///
/// The geometry remains authoring metadata until an explicit project rule
/// turns it into gameplay collision. Importing it never changes walkability by
/// itself.
@freezed
class ProjectTilesetCollisionObject with _$ProjectTilesetCollisionObject {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectTilesetCollisionObject({
    required int id,
    @Default('') String name,
    @Default('') String type,
    @Default(ProjectTilesetCollisionShape.rectangle)
    ProjectTilesetCollisionShape shape,
    required double x,
    required double y,
    @Default(0) double width,
    @Default(0) double height,
    @Default(0) double rotation,
    @Default(<ProjectTilesetPixelPoint>[])
    List<ProjectTilesetPixelPoint> points,
    @Default(<ProjectTilesetProperty>[])
    List<ProjectTilesetProperty> properties,
  }) = _ProjectTilesetCollisionObject;

  factory ProjectTilesetCollisionObject.fromJson(Map<String, dynamic> json) =>
      _$ProjectTilesetCollisionObjectFromJson(json);
}

@freezed
class ProjectImageCollectionPage with _$ProjectImageCollectionPage {
  const factory ProjectImageCollectionPage({
    required String id,
    required String assetId,
    required int pixelWidth,
    required int pixelHeight,
  }) = _ProjectImageCollectionPage;

  factory ProjectImageCollectionPage.fromJson(Map<String, dynamic> json) =>
      _$ProjectImageCollectionPageFromJson(json);
}

@freezed
class ProjectImageCollectionAnimationFrame
    with _$ProjectImageCollectionAnimationFrame {
  const factory ProjectImageCollectionAnimationFrame({
    required int tileId,
    required int durationMs,
  }) = _ProjectImageCollectionAnimationFrame;

  factory ProjectImageCollectionAnimationFrame.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$ProjectImageCollectionAnimationFrameFromJson(json);
}

@freezed
class ProjectImageCollectionTileDefinition
    with _$ProjectImageCollectionTileDefinition {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectImageCollectionTileDefinition({
    required int tileId,
    required String pageId,
    required ProjectTilesetPixelRect sourceRect,
    @Default(0) int offsetX,
    @Default(0) int offsetY,
    @Default(<ProjectImageCollectionAnimationFrame>[])
    List<ProjectImageCollectionAnimationFrame> animation,
    @Default(<ProjectTilesetProperty>[])
    List<ProjectTilesetProperty> properties,
    @Default(<ProjectTilesetCollisionObject>[])
    List<ProjectTilesetCollisionObject> collisionObjects,
  }) = _ProjectImageCollectionTileDefinition;

  factory ProjectImageCollectionTileDefinition.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$ProjectImageCollectionTileDefinitionFromJson(json);
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

  const factory ProjectTilesetSource.imageCollection({
    required List<ProjectImageCollectionPage> pages,
    required List<ProjectImageCollectionTileDefinition> tileDefinitions,
    @Default(<ProjectTilesetProperty>[])
    List<ProjectTilesetProperty> properties,
  }) = ProjectImageCollectionTilesetSource;

  factory ProjectTilesetSource.fromJson(Map<String, dynamic> json) {
    return switch (json['kind']) {
      'regular_atlas' => ProjectRegularAtlasTilesetSource.fromJson(json),
      'image_collection' => ProjectImageCollectionTilesetSource.fromJson(json),
      final kind => throw FormatException(
          r'$.source.kind: tileset_source_kind_invalid ('
          '$kind)',
        ),
    };
  }

  Map<String, Object?> toJson();
}

final class ProjectImageCollectionTilesetSource extends ProjectTilesetSource {
  const ProjectImageCollectionTilesetSource({
    required this.pages,
    required this.tileDefinitions,
    this.properties = const <ProjectTilesetProperty>[],
  });

  factory ProjectImageCollectionTilesetSource.fromJson(
    Map<String, dynamic> json,
  ) {
    const allowed = <String>{
      'kind',
      'pages',
      'tileDefinitions',
      'properties',
    };
    if (json.keys.any((key) => !allowed.contains(key)) ||
        json['pages'] is! List ||
        json['tileDefinitions'] is! List ||
        json['properties'] is! List) {
      throw const FormatException(
        r'$.source: image_collection_tileset_source_invalid',
      );
    }
    return ProjectImageCollectionTilesetSource(
      pages: _parseObjectList(
        json['pages']! as List,
        path: r'$.source.pages',
        parse: ProjectImageCollectionPage.fromJson,
      ),
      tileDefinitions: _parseObjectList(
        json['tileDefinitions']! as List,
        path: r'$.source.tileDefinitions',
        parse: ProjectImageCollectionTileDefinition.fromJson,
      ),
      properties: _parseObjectList(
        json['properties']! as List,
        path: r'$.source.properties',
        parse: ProjectTilesetProperty.fromJson,
      ),
    );
  }

  final List<ProjectImageCollectionPage> pages;
  final List<ProjectImageCollectionTileDefinition> tileDefinitions;
  final List<ProjectTilesetProperty> properties;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': 'image_collection',
        'pages': <Object?>[for (final page in pages) page.toJson()],
        'tileDefinitions': <Object?>[
          for (final tile in tileDefinitions) tile.toJson(),
        ],
        'properties': <Object?>[
          for (final property in properties) property.toJson(),
        ],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectImageCollectionTilesetSource &&
          _listEquals(other.pages, pages) &&
          _listEquals(other.tileDefinitions, tileDefinitions) &&
          _listEquals(other.properties, properties);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(pages),
        Object.hashAll(tileDefinitions),
        Object.hashAll(properties),
      );
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

List<T> _parseObjectList<T>(
  List<dynamic> values, {
  required String path,
  required T Function(Map<String, dynamic>) parse,
}) {
  return <T>[
    for (final raw in values)
      if (raw is Map)
        parse(Map<String, dynamic>.from(raw))
      else
        throw FormatException('$path: expected objects'),
  ];
}
