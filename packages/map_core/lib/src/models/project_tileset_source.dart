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

/// One animation timeline rooted at a regular-atlas local tile identity.
@freezed
class ProjectRegularAtlasTileAnimation with _$ProjectRegularAtlasTileAnimation {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectRegularAtlasTileAnimation({
    required int tileId,
    required List<ProjectImageCollectionAnimationFrame> frames,
  }) = _ProjectRegularAtlasTileAnimation;

  factory ProjectRegularAtlasTileAnimation.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$ProjectRegularAtlasTileAnimationFromJson(json);
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
    @Default(0) int marginX,
    @Default(0) int marginY,
    @Default(0) int spacingX,
    @Default(0) int spacingY,
    @Default(0) int pixelOffsetX,
    @Default(0) int pixelOffsetY,
    @Default(<VisualTileProperty>[]) List<VisualTileProperty> tileProperties,
    @Default(<ProjectRegularAtlasTileAnimation>[])
    List<ProjectRegularAtlasTileAnimation> tileAnimations,
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
    this.marginX = 0,
    this.marginY = 0,
    this.spacingX = 0,
    this.spacingY = 0,
    this.pixelOffsetX = 0,
    this.pixelOffsetY = 0,
    this.tileProperties = const <VisualTileProperty>[],
    this.tileAnimations = const <ProjectRegularAtlasTileAnimation>[],
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
      'marginX',
      'marginY',
      'spacingX',
      'spacingY',
      'pixelOffsetX',
      'pixelOffsetY',
      'tileProperties',
      'tileAnimations',
    };
    if (json.keys.any((key) => !allowed.contains(key)) ||
        json['assetId'] is! String ||
        json['pixelWidth'] is! int ||
        json['pixelHeight'] is! int ||
        json['tileWidth'] is! int ||
        json['tileHeight'] is! int ||
        json['tileProperties'] is! List ||
        (json['tileAnimations'] != null && json['tileAnimations'] is! List)) {
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
      marginX: _optionalJsonInt(json, 'marginX'),
      marginY: _optionalJsonInt(json, 'marginY'),
      spacingX: _optionalJsonInt(json, 'spacingX'),
      spacingY: _optionalJsonInt(json, 'spacingY'),
      pixelOffsetX: _optionalJsonInt(json, 'pixelOffsetX'),
      pixelOffsetY: _optionalJsonInt(json, 'pixelOffsetY'),
      tileProperties: <VisualTileProperty>[
        for (final raw in json['tileProperties']! as List)
          if (raw is Map)
            VisualTileProperty.fromJson(Map<String, dynamic>.from(raw))
          else
            throw const FormatException(
              r'$.source.tileProperties: expected objects',
            ),
      ],
      tileAnimations: _parseObjectList(
        (json['tileAnimations'] as List?) ?? const <Object?>[],
        path: r'$.source.tileAnimations',
        parse: ProjectRegularAtlasTileAnimation.fromJson,
      ),
    );
  }

  final String assetId;
  final int pixelWidth;
  final int pixelHeight;
  final int tileWidth;
  final int tileHeight;
  final int marginX;
  final int marginY;
  final int spacingX;
  final int spacingY;
  final int pixelOffsetX;
  final int pixelOffsetY;
  final List<VisualTileProperty> tileProperties;
  final List<ProjectRegularAtlasTileAnimation> tileAnimations;

  int get columns => _regularAtlasAxisCount(
        pixelExtent: pixelWidth,
        tileExtent: tileWidth,
        margin: marginX,
        spacing: spacingX,
      );
  int get rows => _regularAtlasAxisCount(
        pixelExtent: pixelHeight,
        tileExtent: tileHeight,
        margin: marginY,
        spacing: spacingY,
      );
  int get tileCount => columns * rows;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': 'regular_atlas',
        'assetId': assetId,
        'pixelWidth': pixelWidth,
        'pixelHeight': pixelHeight,
        'tileWidth': tileWidth,
        'tileHeight': tileHeight,
        if (marginX != 0) 'marginX': marginX,
        if (marginY != 0) 'marginY': marginY,
        if (spacingX != 0) 'spacingX': spacingX,
        if (spacingY != 0) 'spacingY': spacingY,
        if (pixelOffsetX != 0) 'pixelOffsetX': pixelOffsetX,
        if (pixelOffsetY != 0) 'pixelOffsetY': pixelOffsetY,
        'tileProperties': <Object?>[
          for (final property in tileProperties) property.toJson(),
        ],
        if (tileAnimations.isNotEmpty)
          'tileAnimations': <Object?>[
            for (final animation in tileAnimations) animation.toJson(),
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
          other.marginX == marginX &&
          other.marginY == marginY &&
          other.spacingX == spacingX &&
          other.spacingY == spacingY &&
          other.pixelOffsetX == pixelOffsetX &&
          other.pixelOffsetY == pixelOffsetY &&
          _listEquals(other.tileProperties, tileProperties) &&
          _listEquals(other.tileAnimations, tileAnimations);

  @override
  int get hashCode => Object.hash(
        assetId,
        pixelWidth,
        pixelHeight,
        tileWidth,
        tileHeight,
        marginX,
        marginY,
        spacingX,
        spacingY,
        pixelOffsetX,
        pixelOffsetY,
        Object.hashAll(tileProperties),
        Object.hashAll(tileAnimations),
      );
}

int _optionalJsonInt(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return 0;
  if (value is! int) {
    throw FormatException(r'$.source.' '$field: expected an integer');
  }
  return value;
}

int _regularAtlasAxisCount({
  required int pixelExtent,
  required int tileExtent,
  required int margin,
  required int spacing,
}) {
  final usable = pixelExtent - margin * 2;
  if (usable < tileExtent || tileExtent <= 0 || spacing < 0) return 0;
  return (usable + spacing) ~/ (tileExtent + spacing);
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
