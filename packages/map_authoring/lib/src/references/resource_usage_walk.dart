import 'resource_usage_report.dart';

const _referenceFields = {
  'imagePath': {
    'relativePath',
    'sourceProjectRelativePath',
    'path',
    'frontStatic',
    'backStatic',
    'frontShinyStatic',
    'backShinyStatic',
    'icon',
    'party',
    'overworld',
    'portrait',
    'cry',
    'iconPath',
    'coverPath',
    'heroPath',
    'filePath',
    'sourcePath',
    'sheet',
    'relativeAssetPath',
    'projectPath',
    'imagePath',
    'posterPath'
  },
  'tileset': {'tilesetId', 'sourceTilesetIds', 'tilesetIds'},
  'element': {
    'elementId',
    'sourceElementId',
    'capElementId',
    'straightElementId',
    'cornerElementId'
  },
  'preset': {
    'presetId',
    'smartTilePresetId',
    'terrainPresetId',
    'sourcePresetId',
    'targetPresetId'
  },
  'smartTileDraft': {'draftId', 'sourceDraftId'},
  'smartTileMaterial': {
    'materialId',
    'materialIds',
    'defaultMaterialId',
    'allowedMaterialIds'
  },
  'smartTileAtlas': {'atlasId', 'primaryAtlasId'},
  'smartTileAnimation': {'animationId'},
  'smartTilePattern': {'patternId'},
  'character': {'characterId', 'characterKey', 'speakerCharacterId'},
  'border': {'blueprintId', 'borderBlueprintId'},
  'borderSnapshot': {'snapshotId', 'visualSnapshotId'},
  'cinematicMedia': {
    'mediaAssetId',
    'imageAssetId',
    'assetId',
    'sourceAssetId'
  },
  'projectMediaCatalog': {'mediaId'},
  'asset': {'assetId', 'sourceAssetId'},
};

Iterable<String> resourceReferencePaths(
  Object? value,
  String kind,
  String? id, {
  String path = r'$',
  String field = '',
}) sync* {
  final fields = _referenceFields[kind] ?? const <String>{};
  if (value is String) {
    if ((id == null || value == id) && fields.contains(field)) yield path;
  } else if (value is List) {
    for (var i = 0; i < value.length; i++) {
      yield* resourceReferencePaths(value[i], kind, id,
          path: '$path[$i]', field: field);
    }
  } else if (value is Map) {
    for (final entry in value.entries) {
      yield* resourceReferencePaths(entry.value, kind, id,
          path: '$path.${entry.key}', field: '${entry.key}');
    }
  }
}

Iterable<({String kind, String id, String path})> resourceReferences(
  Object? value, {
  String path = r'$',
  String field = '',
}) sync* {
  if (value is String) {
    for (final entry in _referenceFields.entries) {
      if (entry.value.contains(field)) {
        yield (kind: entry.key, id: value, path: path);
      }
    }
  } else if (value is List) {
    for (var i = 0; i < value.length; i++) {
      yield* resourceReferences(value[i], path: '$path[$i]', field: field);
    }
  } else if (value is Map) {
    for (final entry in value.entries) {
      yield* resourceReferences(entry.value,
          path: '$path.${entry.key}', field: '${entry.key}');
    }
  }
}

ResourceUsageRelation resourceUsageRelationFor(String kind) =>
    kind == 'borderSnapshot' || kind == 'smartTileDraft'
        ? ResourceUsageRelation.technical
        : ResourceUsageRelation.direct;

String? usageEntityId(Map<String, dynamic> document, String path) {
  final match = RegExp(r'^\$\.(placedElements|entities|borders)\[(\d+)\]')
      .firstMatch(path);
  if (match == null) return null;
  final entries = document[match.group(1)];
  if (entries is! List) return null;
  final entry = entries[int.parse(match.group(2)!)];
  return entry is Map ? entry['id'] as String? : null;
}
