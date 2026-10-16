import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

import '../operations/environment_preset_json_codec.dart';
import '../operations/resource_pack_publication.dart';
import '../operations/resource_pack_native_json.dart';
import 'border_catalog.dart';
import 'environment.dart';
import 'enums.dart';
import 'project_manifest.dart';
import 'project_model3d.dart';
import 'project_tileset_source.dart';
import 'resource_library_catalog.dart';
import 'resource_pack.dart';
import 'smart_tile.dart';

final class ResourcePackCatalog {
  ResourcePackCatalog({
    Iterable<ProjectTilesetEntry> tilesets = const [],
    Iterable<ProjectElementEntry> elements = const [],
    Iterable<ProjectModel3dEntry> models3d = const [],
    Iterable<ProjectCharacterEntry> characters = const [],
    Iterable<EnvironmentPreset> environmentPresets = const [],
    this.smartTileCatalog = const ProjectSmartTileCatalog.empty(),
    ProjectBorderCatalog? borderCatalog,
    this.resourceLibraryCatalog = const ResourceLibraryCatalog.empty(),
    Iterable<ProjectElementCategory> elementCategories = const [],
    Iterable<ProjectTilesetFolder> tilesetFolders = const [],
    this.characterStudioCatalog = const ProjectCharacterStudioCatalog(),
    Iterable<ResourcePackFileBinding> files = const [],
    Iterable<ResourcePackProvenance> provenance = const [],
    Iterable<String> smartTilePatternIds = const [],
  }) : tilesets = List.unmodifiable(tilesets),
       elements = List.unmodifiable(elements),
       models3d = List.unmodifiable(models3d),
       characters = List.unmodifiable(characters),
       environmentPresets = List.unmodifiable(environmentPresets),
       borderCatalog =
           borderCatalog ??
           ProjectBorderCatalog(
             formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
           ),
       elementCategories = List.unmodifiable(elementCategories),
       tilesetFolders = List.unmodifiable(tilesetFolders),
       files = List.unmodifiable(files),
       provenance = List.unmodifiable(provenance),
       smartTilePatternIds = List.unmodifiable(
         smartTilePatternIds.toList()..sort(),
       ) {
    _validate();
  }

  factory ResourcePackCatalog.fromJson(Map<String, Object?> json) {
    try {
      return _decode(json);
    } on FormatException {
      rethrow;
    } on ArgumentError catch (error) {
      throw FormatException('pack.catalog: invalid native value ($error)');
    } on TypeError catch (error) {
      throw FormatException('pack.catalog: invalid native value ($error)');
    } on AssertionError catch (error) {
      throw FormatException('pack.catalog: invalid native value ($error)');
    }
  }

  static ResourcePackCatalog _decode(Map<String, Object?> json) {
    const keys = {
      'tilesets',
      'elements',
      'models3d',
      'characters',
      'environmentPresets',
      'smartTileCatalog',
      'borderCatalog',
      'resourceLibraryCatalog',
      'elementCategories',
      'tilesetFolders',
      'characterStudioCatalog',
      'files',
      'provenance',
      'extras',
    };
    if (json.keys.any((key) => !keys.contains(key))) {
      throw const FormatException('pack.catalog: unknown section');
    }
    for (final key in ['tilesets', 'files', 'provenance']) {
      if (json[key] is! List) {
        throw FormatException('pack.catalog.$key: expected list');
      }
    }
    final smart = _object(json['smartTileCatalog'], 'smartTileCatalog');
    const smartKeys = {
      'formatVersion',
      'categories',
      'atlases',
      'materials',
      'animations',
      'presets',
      'patterns',
    };
    if (smart.keys.any((key) => !smartKeys.contains(key)) ||
        smart['formatVersion'] !=
            ProjectSmartTileCatalog.currentFormatVersion) {
      throw const FormatException(
        'pack.catalog: unsupported Smart Tile catalog',
      );
    }
    for (final (key, type) in [
      ('categories', 'ProjectSmartTileCategory'),
      ('atlases', 'ProjectSmartTileAtlas'),
      ('materials', 'ProjectSmartTileMaterial'),
      ('animations', 'ProjectSmartTileAnimation'),
      ('presets', 'ProjectSmartTilePreset'),
      ('patterns', 'ProjectSmartTilePattern'),
    ]) {
      for (final value in _list(smart[key], key)) {
        validateResourcePackNativeJson(
          value,
          type,
          path: 'smartTileCatalog.$key',
        );
      }
    }
    final border = _object(json['borderCatalog'], 'borderCatalog');
    if (border['formatVersion'] !=
        ProjectBorderCatalog.latestSupportedFormatVersion) {
      throw const FormatException('pack.catalog: unsupported Border catalog');
    }
    final extras = _object(json['extras'], 'extras');
    if (extras.keys.any((key) => key != 'smartTilePatternIds')) {
      throw const FormatException('pack.extras: unknown field');
    }
    return ResourcePackCatalog(
      tilesets: _nativeList(
        json['tilesets'],
        'ProjectTilesetEntry',
        ProjectTilesetEntry.fromJson,
      ),
      elements: _nativeList(
        json['elements'],
        'ProjectElementEntry',
        ProjectElementEntry.fromJson,
      ),
      models3d: [
        for (final item in _list(json['models3d'], 'models3d'))
          ProjectModel3dEntry.fromJson(_object(item, 'model3d')),
      ],
      characters: _nativeList(
        json['characters'],
        'ProjectCharacterEntry',
        ProjectCharacterEntry.fromJson,
      ),
      environmentPresets: _nativeList(
        json['environmentPresets'],
        'EnvironmentPreset',
        decodeEnvironmentPreset,
      ),
      smartTileCatalog: ProjectSmartTileCatalog.fromJson(smart),
      borderCatalog: decodeResourcePackBorderCatalog(border),
      resourceLibraryCatalog: ResourceLibraryCatalog.fromJson(
        _object(json['resourceLibraryCatalog'], 'resourceLibraryCatalog'),
      ),
      elementCategories: _nativeList(
        json['elementCategories'],
        'ProjectElementCategory',
        ProjectElementCategory.fromJson,
      ),
      tilesetFolders: _nativeList(
        json['tilesetFolders'],
        'ProjectTilesetFolder',
        ProjectTilesetFolder.fromJson,
      ),
      characterStudioCatalog: _native(
        _object(json['characterStudioCatalog'], 'characterStudioCatalog'),
        'ProjectCharacterStudioCatalog',
        ProjectCharacterStudioCatalog.fromJson,
      ),
      files: [
        for (final item in _list(json['files'], 'files'))
          ResourcePackFileBinding.fromJson(_object(item, 'file')),
      ],
      provenance: [
        for (final item in _list(json['provenance'], 'provenance'))
          ResourcePackProvenance.fromJson(_object(item, 'provenance')),
      ],
      smartTilePatternIds: [
        for (final id in _list(
          extras['smartTilePatternIds'],
          'smartTilePatternIds',
        ))
          if (id is String)
            id
          else
            throw const FormatException('pattern id must be string'),
      ],
    );
  }

  final List<ProjectTilesetEntry> tilesets;
  final List<ProjectElementEntry> elements;
  final List<ProjectModel3dEntry> models3d;
  final List<ProjectCharacterEntry> characters;
  final List<EnvironmentPreset> environmentPresets;
  final ProjectSmartTileCatalog smartTileCatalog;
  final ProjectBorderCatalog borderCatalog;
  final ResourceLibraryCatalog resourceLibraryCatalog;
  final List<ProjectElementCategory> elementCategories;
  final List<ProjectTilesetFolder> tilesetFolders;
  final ProjectCharacterStudioCatalog characterStudioCatalog;
  final List<ResourcePackFileBinding> files;
  final List<ResourcePackProvenance> provenance;
  final List<String> smartTilePatternIds;

  void _validate() {
    for (final (kind, ids) in [
      (ResourcePackKind.tileset, tilesets.map((e) => e.id)),
      (ResourcePackKind.element, elements.map((e) => e.id)),
      (ResourcePackKind.model3d, models3d.map((e) => e.id)),
      (ResourcePackKind.character, characters.map((e) => e.id)),
      (ResourcePackKind.environmentPreset, environmentPresets.map((e) => e.id)),
      (
        ResourcePackKind.smartTilePreset,
        smartTileCatalog.presets.map((e) => e.id),
      ),
      (
        ResourcePackKind.borderBlueprint,
        borderCatalog.records.map((e) => e.id),
      ),
    ]) {
      _unique(
        ids.map((id) => ResourcePackRef(kind: kind, id: id).id),
        kind.name,
      );
    }
    for (final (name, ids) in [
      ('elementCategories', elementCategories.map((e) => e.id)),
      ('tilesetFolders', tilesetFolders.map((e) => e.id)),
      ('families', resourceLibraryCatalog.families.map((e) => e.id)),
      ('smartTileCategories', smartTileCatalog.categories.map((e) => e.id)),
      ('smartTileAtlases', smartTileCatalog.atlases.map((e) => e.id)),
      ('smartTileMaterials', smartTileCatalog.materials.map((e) => e.id)),
      ('smartTileAnimations', smartTileCatalog.animations.map((e) => e.id)),
      ('smartTilePatterns', smartTileCatalog.patterns.map((e) => e.id)),
      (
        'portraitStates',
        characterStudioCatalog.portraitStates.map((e) => e.id),
      ),
      (
        'animationDefinitions',
        characterStudioCatalog.customAnimationDefinitions.map((e) => e.id),
      ),
    ]) {
      _unique(
        ids.map(
          (id) => ResourcePackRef(kind: ResourcePackKind.element, id: id).id,
        ),
        name,
      );
    }
    final resources = <String>{
      for (final e in tilesets) 'tileset:${e.id}',
      for (final e in elements) 'element:${e.id}',
      for (final e in models3d) 'model3d:${e.id}',
      for (final e in characters) 'character:${e.id}',
      for (final e in environmentPresets) 'environmentPreset:${e.id}',
      for (final e in smartTileCatalog.presets) 'smartTilePreset:${e.id}',
      for (final e in borderCatalog.records) 'borderBlueprint:${e.id}',
    };
    if (resourceLibraryCatalog.entries.any(
          (entry) => !resources.contains(entry.identity),
        ) ||
        provenance.any(
          (entry) =>
              entry.resources.any((ref) => !resources.contains(ref.identity)),
        )) {
      throw const FormatException(
        'pack.catalog: classification or provenance references an absent resource',
      );
    }
    if (smartTileCatalog.drafts.isNotEmpty) {
      throw const FormatException('pack.catalog: private drafts forbidden');
    }
    if (smartTileCatalog.presets.any(
      (p) => p.status != SmartTilePresetStatus.published,
    )) {
      throw const FormatException('pack.catalog: unpublished Smart Tile');
    }
    if (borderCatalog.formatVersion !=
            ProjectBorderCatalog.latestSupportedFormatVersion ||
        borderCatalog.records.any((r) => r.latestPublished == null)) {
      throw const FormatException('pack.catalog: unpublished Border');
    }
    for (final entry in resourceLibraryCatalog.entries) {
      if (entry.mapId != null) {
        throw const FormatException('pack.catalog: map scope forbidden');
      }
    }
    for (final tile in tilesets) {
      if (tile.scope != TilesetScope.global ||
          tile.isWorldTileset ||
          tile.groupId != null ||
          tile.paletteEntries.any((e) => e.recommendedLayerId != null)) {
        throw const FormatException(
          'pack.catalog: project organization forbidden',
        );
      }
      if (tile.source == null) {
        throw const FormatException(
          'pack.catalog: explicit tileset source required',
        );
      }
      validateResourcePackNativeJson(tile.toJson(), 'ProjectTilesetEntry');
    }
    for (final element in elements) {
      if (element.groupId != null || element.recommendedLayerId != null) {
        throw const FormatException(
          'pack.catalog: project organization forbidden',
        );
      }
    }
    _unique(files.map((e) => e.id), 'files');
    _unique(files.map((e) => e.logicalPath), 'files.logicalPath');
    final filesById = {for (final file in files) file.id: file};
    for (final tile in tilesets) {
      final sourceIds = switch (tile.source) {
        ProjectRegularAtlasTilesetSource(:final assetId) => [assetId],
        ProjectImageCollectionTilesetSource(:final pages) => pages.map(
          (page) => page.assetId,
        ),
        null => const <String>[],
      };
      if (!sourceIds.any(
        (id) => filesById[id]?.logicalPath == tile.relativePath,
      )) {
        throw const FormatException(
          'pack.tileset: source binding must own the declared source path',
        );
      }
    }
    for (final model in models3d) {
      if (filesById[model.sourceAssetId]?.logicalPath != model.relativePath) {
        throw const FormatException(
          'pack.model3d: canonical source path must resolve to its file binding',
        );
      }
    }
    _unique(provenance.map((e) => e.id), 'provenance');
    _unique(smartTilePatternIds, 'smartTilePatternIds');
    final patternIds = smartTilePatternIds.toSet();
    if (patternIds.length != smartTileCatalog.patterns.length ||
        smartTileCatalog.patterns.any((p) => !patternIds.contains(p.id))) {
      throw const FormatException(
        'pack.extras: patterns require explicit selection',
      );
    }
    final provenanceIds = provenance.map((entry) => entry.id).toSet();
    for (final file in files) {
      if (!provenanceIds.contains(file.provenanceId)) {
        throw const FormatException('pack.file: missing provenance');
      }
    }
  }

  Map<String, Object?> toJson() {
    final smart = smartTileCatalog.toJson(compact: false)..remove('drafts');
    return {
      'tilesets': [for (final e in tilesets) e.toJson()],
      'elements': [for (final e in elements) e.toJson()],
      'models3d': [for (final e in models3d) e.toJson()],
      'characters': [for (final e in characters) e.toJson()],
      'environmentPresets': encodeEnvironmentPresets(environmentPresets),
      'smartTileCatalog': smart,
      'borderCatalog': encodeResourcePackBorderCatalog(borderCatalog),
      'resourceLibraryCatalog': resourceLibraryCatalog.toJson(),
      'elementCategories': [for (final e in elementCategories) e.toJson()],
      'tilesetFolders': [for (final e in tilesetFolders) e.toJson()],
      'characterStudioCatalog': characterStudioCatalog.toJson(),
      'files': [for (final e in files) e.toJson()],
      'provenance': [for (final e in provenance) e.toJson()],
      'extras': {'smartTilePatternIds': smartTilePatternIds},
    };
  }

  @override
  bool operator ==(Object other) =>
      other is ResourcePackCatalog &&
      const DeepCollectionEquality().equals(toJson(), other.toJson());
  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

Map<String, dynamic> _object(Object? value, String path) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$path: expected object');
  }
  return Map<String, dynamic>.from(value);
}

List<Object?> _list(Object? value, String path) {
  if (value == null) return const [];
  if (value is! List) throw FormatException('$path: expected list');
  return value;
}

List<T> _nativeList<T>(
  Object? value,
  String type,
  T Function(Map<String, dynamic>) decode,
) => [
  for (final item in _list(value, type))
    _native(_object(item, type), type, decode),
];
T _native<T>(
  Map<String, dynamic> value,
  String type,
  T Function(Map<String, dynamic>) decode,
) {
  validateResourcePackNativeJson(value, type);
  try {
    return decode(value);
  } on TypeError catch (e) {
    throw FormatException('$type: $e');
  }
}

void _unique(Iterable<String> ids, String path) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) throw FormatException('$path: duplicate id $id');
  }
}
