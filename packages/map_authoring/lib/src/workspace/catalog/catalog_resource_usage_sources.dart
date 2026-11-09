part of 'catalog_resource_usage_index.dart';

typedef _UsageSource = ({String owner, Set<String> targets, String? revision});

_UsageSource _usageSource(ResourceUsageDocument document) {
  final owner = document.kind == 'dialogueSource'
      ? 'dialogue:${document.id}'
      : document.identity;
  final targets = <String>{};
  for (final reference in resourceReferences(document.value)) {
    final kind = reference.kind == 'preset' &&
            RegExp(r'\.areas\[\d+\]\.presetId$').hasMatch(reference.path)
        ? 'environmentPreset'
        : reference.kind;
    targets.add('$kind:${reference.id}');
  }
  if (document.kind == 'scene') {
    final scene = SceneAsset.fromJson(document.value);
    for (final node in scene.graph.nodes) {
      if (node.payload case final SceneCinematicPayload payload) {
        targets.add('cinematic:${payload.cinematicId}');
      }
    }
  }
  return (owner: owner, targets: targets, revision: null);
}

Future<_UsageSource?> _catalogUsageSource(
    CatalogDefinitionUnit unit,
    Future<CatalogDefinitionUnit?> Function(CatalogDefinitionKey)
        lookup) async {
  const sections = {
    'tilesets': 'tileset',
    'elements': 'element',
    'models3d': 'model3d',
    'characters': 'character',
    'scenes': 'scene',
    'presentationCinematics': 'presentationCinematic',
    'cinematicMediaAssets': 'cinematicMedia',
    'cinematics': 'cinematic',
    'scripts': 'script',
    'dialogues': 'dialogue',
    'presentationPresets': 'presentationPreset',
    'environmentPresets': 'environmentPreset',
    'smartTileCatalog.presets': 'preset',
    'smartTileCatalog.drafts': 'smartTileDraft',
    'smartTileCatalog.materials': 'smartTileMaterial',
    'smartTileCatalog.assets': 'smartTileAsset',
    'smartTileCatalog.atlases': 'smartTileAtlas',
    'smartTileCatalog.animations': 'smartTileAnimation',
    'smartTileCatalog.patterns': 'smartTilePattern',
    'borderCatalog.records': 'border',
    'borderCatalog.visualSnapshots': 'borderSnapshot',
  };
  if (unit.key.kind == CatalogDefinitionKind.workspaceState) return null;
  final section = unit.payload['section'];
  final raw = unit.payload['value'];
  if (raw is! Map) return null;
  var data = Map<String, dynamic>.from(raw);
  var field = section as String?;
  if (section == r'$projectDefinition') {
    field = data['field'] as String;
    data = Map<String, dynamic>.from(data['definition'] as Map);
  } else if (section == r'$projectAggregateChunk') {
    return null;
  } else if (section == r'$projectAggregateHeader') {
    field = data['field'] as String;
    final count = data['chunkCount'];
    final length = data['byteLength'];
    if (count is! int ||
        count < 1 ||
        count > 4096 ||
        length is! int ||
        length > 16777216) {
      throw const FormatException('catalog.resource_usage.aggregate_limit');
    }
    final bytes = <int>[];
    for (var i = 0; i < count; i++) {
      final key = CatalogDefinitionKey(CatalogDefinitionKind.catalogMetadata,
          jsonEncode(['projectAggregateChunk', field, i]));
      final chunk = await lookup(key);
      if (chunk == null) {
        throw const FormatException('catalog.resource_usage.aggregate_missing');
      }
      bytes.addAll(
          base64.decode((chunk.payload['value'] as Map)['data'] as String));
      if (bytes.length > length) {
        throw const FormatException('catalog.resource_usage.aggregate_limit');
      }
    }
    if (bytes.length != length ||
        crypto.sha256.convert(bytes).toString() != data['sha256']) {
      throw const FormatException('catalog.resource_usage.aggregate_digest');
    }
    data = {field: jsonDecode(utf8.decode(bytes))};
  } else if (section == r'$shell') {
    data.remove('resourcePackInstallations');
    data.remove('borderCatalog');
  } else if (section == r'$virtual' || section == r'$provenanceMembership') {
    return null;
  }
  final kind = sections[field] ?? 'project';
  final id = kind == 'project'
      ? 'project'
      : '${data['id'] ?? data['targetPresetId'] ?? unit.payload['position']}';
  final result =
      _usageSource(ResourceUsageDocument(kind, id, id, unit.key.id, data));
  if (field == 'resourceLibraryCatalog.entries' && data['familyId'] is String) {
    result.targets.add('family:${data['familyId']}');
  }
  if (field == 'resourceLibraryCatalog.families' &&
      data['parentId'] is String) {
    result.targets.add('family:${data['parentId']}');
  }
  if (kind == 'cinematic' && data['mapId'] is String) {
    return (
      owner: 'map:${data['mapId']}',
      targets: {...result.targets, 'cinematic:$id'},
      revision: null
    );
  }
  return result;
}
