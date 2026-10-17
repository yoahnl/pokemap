import 'dart:convert';

typedef ResourcePackReferenceMapping = String Function(String kind, String id,
    [String? owner]);
typedef ResourcePackFileMapping = String Function(String id,
    {String? logicalPath});
typedef ResourcePackSupportValue = Map<String, dynamic>
    Function(String kind, String id, [String? owner]);

final class ResourcePackNativeRemapper {
  const ResourcePackNativeRemapper(
      {required this.reference,
      required this.allocate,
      required ResourcePackFileMapping file,
      required String Function(String) path,
      required ResourcePackSupportValue supportValue,
      required this.fileIdForPath,
      required this.prepareFile,
      required this.removed})
      : _file = file,
        _path = path,
        _supportValue = supportValue;
  final ResourcePackReferenceMapping reference;
  final String Function(String) allocate;
  final ResourcePackFileMapping _file;
  final String Function(String) _path;
  final ResourcePackSupportValue _supportValue;
  final String Function(String) fileIdForPath;
  final void Function(String) prepareFile;
  final void Function(String) removed;

  void remap(String kind, String id, Map<String, dynamic> value,
      [String? owner]) {
    final key = _key(kind, id, owner);
    switch (kind) {
      case 'element':
        final tileset = value['tilesetId'] as String;
        value['tilesetId'] = reference('tileset', tileset);
        _field(value, 'categoryId', 'elementCategory');
        _field(value, 'tilesetGroupId', 'tilesetElementGroup', owner: tileset);
        _frames(value);
        _remove(value, 'groupId', key);
        _remove(value, 'recommendedLayerId', key);
      case 'tileset':
        _field(value, 'folderId', 'tilesetFolder');
        _remove(value, 'groupId', key);
        if (value['scope'] != 'global') removed('$key.scope');
        value['scope'] = 'global';
        if (value['isWorldTileset'] == true) removed('$key.isWorldTileset');
        value['isWorldTileset'] = false;
        value['elementGroups'] = [
          for (final group in _objects(value['elementGroups']))
            _supportValue('tilesetElementGroup', group['id'] as String, id)
        ];
        for (final entry in _objects(value['paletteEntries'])) {
          entry['id'] =
              allocate(_key('paletteEntry', entry['id'] as String, id));
          _remove(entry, 'recommendedLayerId', key);
          _frames(entry, owner: id);
        }
        final source = value['source'];
        if (source is! Map<String, dynamic>) {
          _fail('tileset_source_missing', key);
        }
        if (source['kind'] == 'regular_atlas') {
          source['assetId'] = _file(source['assetId'] as String);
        } else if (source['kind'] == 'image_collection') {
          for (final page in _objects(source['pages'])) {
            page['id'] =
                allocate(_key('tilesetPage', page['id'] as String, id));
            page['assetId'] = _file(page['assetId'] as String);
          }
          _properties(source['properties']);
          for (final tile in _objects(source['tileDefinitions'])) {
            tile['pageId'] =
                allocate(_key('tilesetPage', tile['pageId'] as String, id));
            _properties(tile['properties']);
            for (final object in _objects(tile['collisionObjects'])) {
              _properties(object['properties']);
            }
          }
        } else {
          _fail('tileset_source_unsupported', key);
        }
        value['relativePath'] = _path(value['relativePath'] as String);
      case 'model3d':
        final asset = value['sourceAssetId'] as String;
        final path = 'assets/models3d/${value['id']}.glb';
        value['sourceAssetId'] = _file(asset, logicalPath: path);
        value['relativePath'] = path;
      case 'character':
        value['tilesetId'] = reference('tileset', value['tilesetId'] as String);
        for (final portrait in _objects(value['portraits'])) {
          _field(portrait, 'portraitStateId', 'characterPortraitState');
          portrait['assetId'] = _file(portrait['assetId'] as String);
        }
        for (final animation in _objects(value['animations'])) {
          if (animation['sourceAssetId'] != null) {
            animation['sourceAssetId'] =
                _file(animation['sourceAssetId'] as String);
          }
        }
        for (final animation in _objects(value['customAnimations'])) {
          _field(animation, 'definitionId', 'characterAnimationDefinition');
          animation['sourceAssetId'] =
              _file(animation['sourceAssetId'] as String);
        }
      case 'environmentPreset':
        _field(value, 'categoryId', 'elementCategory');
        for (final item in _objects(value['palette'])) {
          _field(item, 'elementId', 'element');
          _field(item, 'modelId', 'model3d');
        }
      case 'smartTilePreset':
        if (value['status'] != 'published') {
          _fail('smart_tile_unpublished', key);
        }
        _field(value, 'categoryId', 'smartTileCategory');
        _smart(value, id, root: true);
      case 'smartTileMaterial':
        _field(value, 'connectionGroupId', 'smartTileConnectionGroup');
        _field(value, 'categoryId', 'smartTileCategory');
      case 'smartTileAtlas':
        _field(value, 'tilesetId', 'tileset');
      case 'smartTileAnimation':
        for (final frame in _objects(value['frames'])) {
          _smart(frame, id);
        }
      case 'smartTilePattern':
        _field(value, 'categoryId', 'smartTileCategory');
        _smart(value, id, root: true);
      case 'resourceFamily':
        _field(value, 'parentId', 'resourceFamily');
      case 'elementCategory':
        _field(value, 'parentCategoryId', 'elementCategory');
      case 'tilesetFolder':
        _field(value, 'parentFolderId', 'tilesetFolder');
      case 'tilesetElementGroup':
        _field(value, 'parentGroupId', 'tilesetElementGroup', owner: owner);
      case 'borderSnapshot':
        var frameIndex = 0;
        for (final frame in _objects(value['frames'])) {
          final fileId = fileIdForPath(frame['relativeAssetPath'] as String);
          final path =
              'assets/borders/snapshots/${value['contentFingerprint']}/frame_${frameIndex.toString().padLeft(4, '0')}.png';
          _file(fileId, logicalPath: path);
          frame['relativeAssetPath'] = path;
          frameIndex++;
        }
      case 'borderBlueprint':
        final publication = value['latestPublished'];
        if (publication is! Map<String, dynamic>) {
          _fail('border_unpublished', key);
        }
        final definition = publication['definition'] as Map<String, dynamic>;
        _field(definition, 'categoryId', 'elementCategory');
        for (final primitive in _objects(definition['primitives'])) {
          primitive['id'] =
              allocate(_key('borderPrimitive', primitive['id'] as String, id));
          _field(primitive, 'sourceElementId', 'element');
          _field(primitive, 'sourceModelId', 'model3d');
          _field(primitive, 'visualSnapshotId', 'borderSnapshot');
          for (final surface in _objects(primitive['groundSurfaces'])) {
            _field(surface, 'sourceSmartTilePresetId', 'smartTilePreset');
            _field(surface, 'materialId', 'smartTileMaterial');
          }
        }
        final ground = definition['ground'];
        if (ground is Map<String, dynamic>) {
          _field(ground, 'sourceSmartTilePresetId', 'smartTilePreset');
          final snapshots =
              ground['visualSnapshotIdsByRole'] as Map<String, dynamic>;
          for (final role in snapshots.keys.toList()) {
            snapshots[role] =
                reference('borderSnapshot', snapshots[role] as String);
          }
        }
      case 'file':
        prepareFile(id);
      case 'smartTileCategory':
      case 'smartTileConnectionGroup':
      case 'characterPortraitState':
      case 'characterAnimationDefinition':
        break;
      default:
        _fail('reference_unsupported', key);
    }
  }

  void field(Map<String, dynamic> value, String field, String kind,
          {String? owner}) =>
      _field(value, field, kind, owner: owner);
  void _field(Map<String, dynamic> value, String field, String kind,
      {String? owner}) {
    final id = value[field];
    if (id is String && id.isNotEmpty) {
      value[field] = reference(kind, id, owner);
    }
  }

  void _remove(Map<String, dynamic> value, String field, String key) {
    if (value[field] != null) removed('$key.$field');
    value[field] = null;
  }

  void _frames(Map<String, dynamic> value, {String? owner}) {
    for (final frame in _objects(value['frames'])) {
      final id = frame['tilesetId'];
      if (id == owner && owner != null) {
        frame['tilesetId'] = allocate(_key('tileset', owner));
      } else {
        _field(frame, 'tilesetId', 'tileset');
      }
    }
  }

  void _properties(Object? raw) {
    for (final property in _objects(raw)) {
      if (property['type'] == 'asset_reference') {
        property['value'] = _file(property['value'] as String);
      }
      if (property['type'] == 'structured') {
        _fail('property_reference_unsupported');
      }
    }
  }

  void _smart(Map<String, dynamic> value, String owner,
      {bool root = false, String path = ''}) {
    final localId = value['id'];
    for (final key in value.keys.toList()) {
      final item = value[key];
      if (item is String && item.isNotEmpty) {
        switch (key) {
          case 'id':
            if (!root) {
              value[key] = allocate(_key('smartLocal', item, '$owner/$path'));
            }
          case 'atlasId':
            value[key] = reference('smartTileAtlas', item);
          case 'animationId':
            value[key] = reference('smartTileAnimation', item);
          case 'modelId':
            value[key] = reference('model3d', item);
          case 'materialId':
          case 'centerMaterialId':
          case 'defaultMaterialId':
            value[key] = reference('smartTileMaterial', item);
          case 'fallbackRuleId':
            value[key] = allocate(_key('smartLocal', item, '$owner/rules'));
          case 'northEdge':
          case 'northEastCorner':
          case 'eastEdge':
          case 'southEastCorner':
          case 'southEdge':
          case 'southWestCorner':
          case 'westEdge':
          case 'northWestCorner':
            value[key] = reference('smartTileMaterial', item);
        }
      } else if (key == 'allowedMaterialIds' && item is List) {
        value[key] = [
          for (final id in item) reference('smartTileMaterial', id as String)
        ];
      } else if (item is Map<String, dynamic>) {
        _smart(item, owner, path: path.isEmpty ? key : '$path/$key');
      } else if (item is List) {
        for (final child in item.whereType<Map<String, dynamic>>()) {
          _smart(child, owner,
              path: path.isEmpty
                  ? key
                  : key == 'candidates' && localId is String
                      ? '$path/$localId/$key'
                      : '$path/$key');
        }
      }
    }
  }
}

String _key(String kind, String id, [String? owner]) =>
    '["$kind",${owner == null ? 'null' : _quote(owner)},${_quote(id)}]';
String _quote(String value) => jsonEncode(value);
Iterable<Map<String, dynamic>> _objects(Object? value) =>
    value == null ? const [] : (value as List).cast<Map<String, dynamic>>();
Never _fail(String code, [String? identity]) => throw FormatException(
    'resource_pack.$code${identity == null ? '' : ': $identity'}');
