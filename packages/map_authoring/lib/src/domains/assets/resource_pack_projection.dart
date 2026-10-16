import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../ports/file_backed_payload_store.dart';
import '../maps/canonical_border_ground_composer.dart';
import '../maps/canonical_border_snapshot_compiler.dart';

final class NativeResourcePackRef {
  NativeResourcePackRef({required this.kind, required this.id}) {
    if (id.isEmpty || id.trim() != id) throw ArgumentError.value(id, 'id');
  }
  final ResourcePackKind kind;
  final String id;
}

final class NativeResourcePackFile {
  const NativeResourcePackFile(
      {required this.id,
      required this.logicalPath,
      required this.byteLength,
      required this.rawSha256,
      required this.mediaType,
      required this.openRead});
  final String id;
  final String logicalPath;
  final int byteLength;
  final String rawSha256;
  final String mediaType;
  final Stream<List<int>> Function() openRead;
}

final class ResourcePackExportProjection {
  ResourcePackExportProjection._(
      {required this.catalog,
      required this.roots,
      required this.sourceRevision,
      required this.tileWidth,
      required this.tileHeight,
      required this.sources,
      required this.promotedResources,
      required this.removedOrganization,
      required this.nativeMappings});
  final String sourceRevision;
  final int tileWidth;
  final int tileHeight;
  final ResourcePackCatalog catalog;
  final List<ResourcePackRef> roots;
  final List<ResourcePackBuildSource> sources;
  final List<NativeResourcePackRef> promotedResources;
  final List<String> removedOrganization;
  final Map<String, String> nativeMappings;
}

final class ResourcePackProjectionBuilder {
  const ResourcePackProjectionBuilder(
      {this.policy = const ResourcePackSecurityPolicy()});
  final ResourcePackSecurityPolicy policy;

  Future<ResourcePackExportProjection> project(
      {required ProjectManifest manifest,
      required Iterable<NativeResourcePackRef> roots,
      required Iterable<NativeResourcePackFile> files,
      required String author,
      required String sourceRevision,
      String? sourceUrl,
      String? licenseText,
      Iterable<String> smartTilePatternIds = const [],
      bool acknowledgeOrganizationRemoval = false}) async {
    final projection = _Projection(manifest, files, policy);
    final selected = roots.toList()
      ..sort(
          (a, b) => _key(a.kind.name, a.id).compareTo(_key(b.kind.name, b.id)));
    final portableRoots = [
      for (final root in selected)
        ResourcePackRef(
            kind: root.kind, id: projection.reference(root.kind.name, root.id))
    ];
    final patterns = smartTilePatternIds.toSet().toList()..sort();
    for (final id in patterns) {
      projection.reference('smartTilePattern', id);
    }
    if (portableRoots.isEmpty && patterns.isEmpty) _fail('selection_empty');
    if (projection.removed.isNotEmpty && !acknowledgeOrganizationRemoval) {
      _fail('organization_acknowledgement_required');
    }
    final licenses = <String>[];
    final sources = <String, ResourcePackBuildSource>{};
    if (licenseText != null) {
      final bytes = Uint8List.fromList(utf8.encode(licenseText));
      final hash = sha256.convert(bytes).toString();
      final path = 'licenses/$hash.txt';
      licenses.add(path);
      sources[path] =
          _inlineSource(path, bytes, 'text/plain', policy.maxChunkBytes);
    }
    final bindings = <ResourcePackFileBinding>[];
    final blobAliases = <String, List<NativeResourcePackFile>>{};
    for (final key in projection.completed.keys
        .where((k) => projection.nodes[k]!.kind == 'file')
        .toList()
      ..sort()) {
      final node = projection.nodes[key]!;
      final file = projection.files[node.id]!;
      final path =
          'blobs/${file.rawSha256}.${file.mediaType == 'image/png' ? 'png' : 'glb'}';
      final id = projection.allocate(key);
      bindings.add(ResourcePackFileBinding(
          id: id,
          logicalPath: projection.filePaths[node.id]!,
          archivePath: path,
          byteLength: file.byteLength,
          mediaType: file.mediaType,
          rawSha256: file.rawSha256,
          provenanceId: 'declared',
          licenseIds: licenses));
      final aliases = blobAliases.putIfAbsent(path, () => []);
      if (aliases.isNotEmpty &&
          (aliases.first.byteLength != file.byteLength ||
              aliases.first.mediaType != file.mediaType)) {
        _fail('blob_identity_conflict');
      }
      aliases.add(file);
    }
    for (final entry in blobAliases.entries) {
      final aliases = List<NativeResourcePackFile>.unmodifiable(entry.value);
      final representative = aliases.first;
      sources[entry.key] = ResourcePackBuildSource(
          path: entry.key,
          byteLength: representative.byteLength,
          rawSha256: representative.rawSha256,
          mediaType: representative.mediaType,
          openRead: () async* {
            for (final alias in aliases.skip(1)) {
              await _verifyNativeAlias(alias, policy);
            }
            yield* representative.openRead();
          });
    }
    final json = projection.catalogJson(bindings, [
      ResourcePackProvenance(
          id: 'declared',
          author: author,
          sourceUrl: sourceUrl,
          licenseIds: licenses,
          resources: [
            for (final key in projection.completed.keys)
              if (ResourcePackKind.values
                  .any((kind) => kind.name == projection.nodes[key]!.kind))
                ResourcePackRef(
                    kind: ResourcePackKind.values
                        .byName(projection.nodes[key]!.kind),
                    id: projection.allocate(key))
          ])
    ]);
    var catalog = ResourcePackCatalog.fromJson(json);
    ResourcePackDependencyGraph.fromCatalog(catalog).validateAll();
    catalog = await projection.verifyBorders(catalog);
    return ResourcePackExportProjection._(
        catalog: catalog,
        sourceRevision: sourceRevision,
        tileWidth: manifest.settings.tileWidth,
        tileHeight: manifest.settings.tileHeight,
        roots: List.unmodifiable(portableRoots),
        sources: List.unmodifiable(
            sources.values.toList()..sort((a, b) => a.path.compareTo(b.path))),
        promotedResources: List.unmodifiable(projection.promoted),
        removedOrganization:
            List.unmodifiable(projection.removed.toList()..sort()),
        nativeMappings: Map.unmodifiable(projection.mapping));
  }
}

final class _NativeNode {
  _NativeNode(this.kind, this.id, this.value, {this.owner});
  final String kind;
  final String id;
  final String? owner;
  final Map<String, dynamic> value;
}

final class _Projection {
  _Projection(
      this.manifest, Iterable<NativeResourcePackFile> sources, this.policy) {
    void index(String kind, Iterable<Map<String, dynamic>> entries,
        {String? owner}) {
      for (final entry in entries) {
        final id = entry['id'] as String;
        final key = _key(kind, id, owner);
        if (nodes.containsKey(key)) _fail('duplicate_native_identity');
        nodes[key] = _NativeNode(kind, id, entry, owner: owner);
      }
    }

    index('element', manifest.elements.map((e) => e.toJson()));
    index('tileset', manifest.tilesets.map((e) => e.toJson()));
    index('model3d', manifest.models3d.map((e) => e.toJson()));
    index('character', manifest.characters.map((e) => e.toJson()));
    index('environmentPreset',
        encodeEnvironmentPresets(manifest.environmentPresets));
    for (final record in manifest.borderCatalog.records) {
      nodes[_key('borderBlueprint', record.id)] =
          _NativeNode('borderBlueprint', record.id, {
        'id': record.id,
        if (record.latestPublished != null)
          'latestPublished': encodeBorderBlueprintRevisionJson(
              record.latestPublished!,
              formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion),
        if (record.isDeprecated) 'isDeprecated': true,
      });
    }
    index(
        'resourceFamily',
        manifest.resourceLibraryCatalog.effectiveFamilies
            .map((e) => e.toJson()));
    index('elementCategory', manifest.elementCategories.map((e) => e.toJson()));
    index('tilesetFolder', manifest.tilesetFolders.map((e) => e.toJson()));
    for (final tile in manifest.tilesets) {
      index('tilesetElementGroup', tile.elementGroups.map((e) => e.toJson()),
          owner: tile.id);
    }
    final smart = manifest.smartTileCatalog;
    index('smartTileCategory', smart.categories.map((e) => e.toJson()));
    index('smartTileMaterial', smart.materials.map((e) => e.toJson()));
    index('smartTileAtlas', smart.atlases.map((e) => e.toJson()));
    index('smartTileAnimation', smart.animations.map((e) => e.toJson()));
    index('smartTilePattern', smart.patterns.map((e) => e.toJson()));
    index('smartTilePreset', smart.presets.map((e) => e.toJson()));
    index(
        'smartTileConnectionGroup',
        smart.materials
            .map((e) => e.connectionGroupId)
            .toSet()
            .map((id) => {'id': id}));
    index('characterPortraitState',
        manifest.characterStudioCatalog.portraitStates.map((e) => e.toJson()));
    index(
        'characterAnimationDefinition',
        manifest.characterStudioCatalog.customAnimationDefinitions
            .map((e) => e.toJson()));
    for (final snapshot in manifest.borderCatalog.visualSnapshots) {
      nodes[_key('borderSnapshot', snapshot.id)] = _NativeNode(
          'borderSnapshot',
          snapshot.id,
          Map<String, dynamic>.from(encodeBorderVisualSnapshotJson(snapshot)));
    }
    final paths = <String>{};
    for (final file in sources) {
      if (files.containsKey(file.id) || !paths.add(file.logicalPath)) {
        _fail('duplicate_native_file');
      }
      files[file.id] = file;
      nodes[_key('file', file.id)] =
          _NativeNode('file', file.id, {'id': file.id});
      filesByPath[file.logicalPath] = file.id;
    }
  }
  final ProjectManifest manifest;
  final ResourcePackSecurityPolicy policy;
  final Map<String, _NativeNode> nodes = {};
  final Map<String, Map<String, dynamic>> completed = {};
  final Map<String, NativeResourcePackFile> files = {};
  final Map<String, String> filesByPath = {};
  final Map<String, String> filePaths = {};
  final Map<String, String> mapping = {};
  final Map<String, String> reverseMapping = {};
  final Set<String> active = {};
  final Set<String> removed = {};
  final List<NativeResourcePackRef> promoted = [];
  final List<Map<String, dynamic>> classifications = [];
  int _resourceCount = 0;
  int _supportCount = 0;
  int _fileCount = 0;

  String allocate(String key) {
    final previous = mapping[key];
    if (previous != null) return previous;
    final id =
        'rp_${sha256.convert(utf8.encode('avelune.asset-pack.local.v1\n$key')).toString().substring(0, 48)}';
    if (reverseMapping.containsKey(id) && reverseMapping[id] != key) {
      _fail('id_collision');
    }
    reverseMapping[id] = key;
    mapping[key] = id;
    return id;
  }

  String reference(String kind, String id, [String? owner]) {
    final key = _key(kind, id, owner);
    final node = nodes[key];
    if (node == null) _fail('reference_missing', key);
    if (active.contains(key)) _fail('dependency_cycle', key);
    if (completed.containsKey(key)) {
      return kind == 'borderSnapshot' ? id : allocate(key);
    }
    if (active.length >= policy.maxJsonDepth) {
      _fail('dependency_depth_exceeded', key);
    }
    active.add(key);
    final value = _clone(node.value);
    value['id'] = kind == 'borderSnapshot' ? id : allocate(key);
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
        if (value['scope'] != 'global') removed.add('$key.scope');
        value['scope'] = 'global';
        if (value['isWorldTileset'] == true) removed.add('$key.isWorldTileset');
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
          final fileId = filesByPath[frame['relativeAssetPath']];
          if (fileId == null) _fail('file_path_missing');
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
        final file = files[id]!;
        if (file.mediaType != 'image/png' &&
            file.mediaType != 'model/gltf-binary') {
          _fail('file_type_unsupported', key);
        }
        filePaths.putIfAbsent(
            id,
            () =>
                'assets/resource_packs/${allocate(key)}.${file.mediaType == 'image/png' ? 'png' : 'glb'}');
      case 'smartTileCategory':
      case 'smartTileConnectionGroup':
      case 'characterPortraitState':
      case 'characterAnimationDefinition':
        break;
      default:
        _fail('reference_unsupported', key);
    }
    if (ResourcePackKind.values.any((k) => k.name == kind)) {
      final entry = manifest.resourceLibraryCatalog.entries
          .where((e) => e.resourceKind == kind && e.resourceId == id)
          .firstOrNull;
      if (entry != null) {
        final classification = Map<String, dynamic>.from(entry.toJson());
        classification['resourceId'] = value['id'];
        if (classification.remove('mapId') != null) {
          promoted.add(NativeResourcePackRef(
              kind: ResourcePackKind.values.byName(kind), id: id));
          removed.add('$key.mapId');
        }
        _field(classification, 'familyId', 'resourceFamily');
        classifications.add(classification);
      }
    }
    active.remove(key);
    completed[key] = value;
    if (ResourcePackKind.values.any((k) => k.name == kind)) {
      _resourceCount++;
    } else if (kind == 'file') {
      _fileCount++;
    } else {
      _supportCount++;
    }
    if (_resourceCount > policy.maxResources ||
        _supportCount > policy.maxSupports ||
        _fileCount > policy.maxPublishedFiles) {
      _fail('resource_limit_exceeded');
    }
    return kind == 'borderSnapshot' ? id : allocate(key);
  }

  Map<String, dynamic> _supportValue(String kind, String id, [String? owner]) {
    reference(kind, id, owner);
    return completed[_key(kind, id, owner)]!;
  }

  void _field(Map<String, dynamic> value, String field, String kind,
      {String? owner}) {
    final id = value[field];
    if (id is String && id.isNotEmpty) {
      value[field] = reference(kind, id, owner);
    }
  }

  void _remove(Map<String, dynamic> value, String field, String key) {
    if (value[field] != null) removed.add('$key.$field');
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

  String _file(String id, {String? logicalPath}) {
    if (logicalPath != null) {
      final previous = filePaths[id];
      if (previous != null && previous != logicalPath) {
        _fail('file_binding_path_conflict', id);
      }
      filePaths[id] = logicalPath;
    }
    return reference('file', id);
  }

  String _path(String path) {
    final id = filesByPath[path];
    if (id == null) _fail('file_path_missing', path);
    _file(id);
    return filePaths[id]!;
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

  Map<String, Object?> catalogJson(List<ResourcePackFileBinding> bindings,
      List<ResourcePackProvenance> provenance) {
    List<Map<String, dynamic>> entries(String kind) => [
          for (final key in completed.keys.toList()..sort())
            if (nodes[key]!.kind == kind) completed[key]!
        ];
    return {
      'tilesets': entries('tileset'),
      'elements': entries('element'),
      'models3d': entries('model3d'),
      'characters': entries('character'),
      'environmentPresets': entries('environmentPreset'),
      'elementCategories': entries('elementCategory'),
      'tilesetFolders': entries('tilesetFolder'),
      'resourceLibraryCatalog': {
        'formatVersion': ResourceLibraryCatalog.currentFormatVersion,
        'families': entries('resourceFamily'),
        'entries': classifications
          ..sort((a, b) => '${a['resourceKind']}:${a['resourceId']}'
              .compareTo('${b['resourceKind']}:${b['resourceId']}'))
      },
      'smartTileCatalog': {
        'formatVersion': ProjectSmartTileCatalog.currentFormatVersion,
        'categories': entries('smartTileCategory'),
        'materials': entries('smartTileMaterial'),
        'atlases': entries('smartTileAtlas'),
        'animations': entries('smartTileAnimation'),
        'presets': entries('smartTilePreset'),
        'patterns': entries('smartTilePattern')
      },
      'borderCatalog': {
        'formatVersion': ProjectBorderCatalog.latestSupportedFormatVersion,
        'records': entries('borderBlueprint'),
        'visualSnapshots': entries('borderSnapshot')
      },
      'characterStudioCatalog': {
        'portraitStates': entries('characterPortraitState'),
        'customAnimationDefinitions': entries('characterAnimationDefinition')
      },
      'files': [for (final binding in bindings) binding.toJson()],
      'provenance': [for (final entry in provenance) entry.toJson()],
      'extras': {
        'smartTilePatternIds':
            entries('smartTilePattern').map((p) => p['id']).toList()..sort()
      },
    };
  }

  Future<ResourcePackCatalog> verifyBorders(ResourcePackCatalog catalog) async {
    if (catalog.borderCatalog.records.isEmpty) return catalog;
    final portableManifest = manifest.copyWith(
        tilesets: catalog.tilesets,
        elements: catalog.elements,
        models3d: catalog.models3d,
        smartTileCatalog: catalog.smartTileCatalog);
    final originalByPortable = {
      for (final key
          in completed.keys.where((k) => nodes[k]!.kind == 'borderBlueprint'))
        allocate(key): manifest.borderCatalog.recordById(nodes[key]!.id)!
    };
    final portableFiles = {for (final file in catalog.files) file.id: file};
    Future<List<int>> readPortable(
        ProjectTilesetEntry tileset, String assetId) async {
      final source = files[reverseMapping[assetId] == null
          ? ''
          : nodes[reverseMapping[assetId]]!.id];
      if (source == null || !portableFiles.containsKey(assetId)) {
        _fail('file_missing');
      }
      return _readFile(source);
    }

    Future<List<int>> readOriginal(
        ProjectTilesetEntry tileset, String assetId) async {
      final id = assetId.isEmpty ? filesByPath[tileset.relativePath] : assetId;
      final source = files[id];
      if (source == null) _fail('file_missing');
      return _readFile(source);
    }

    final updatedJson = catalog.toJson();
    final updatedRecords =
        _objects((updatedJson['borderCatalog'] as Map)['records']);
    for (final record in catalog.borderCatalog.records) {
      final original = originalByPortable[record.id]!;
      final before = await _borderSources(manifest, original, readOriginal);
      projectResourcePackPublishedBorder(
          record: original,
          snapshots: manifest.borderCatalog.visualSnapshots,
          primitiveSourceFrames: before.$1,
          groundSourceFrames: before.$2);
      final after =
          await _borderSources(portableManifest, record, readPortable);
      try {
        projectResourcePackPublishedBorder(
            record: record,
            snapshots: catalog.borderCatalog.visualSnapshots,
            primitiveSourceFrames: after.$1,
            groundSourceFrames: after.$2);
      } on FormatException {
        _fail('border_remap_changes_pixels', record.id);
      }
      final jsonRecord =
          updatedRecords.singleWhere((value) => value['id'] == record.id);
      final definition =
          (jsonRecord['latestPublished'] as Map)['definition'] as Map;
      for (final primitive in _objects(definition['primitives'])) {
        final elementId = primitive['sourceElementId'];
        if (elementId == null) continue;
        final element =
            catalog.elements.singleWhere((element) => element.id == elementId);
        (primitive['publishedMetrics'] as Map)['assetFingerprint'] =
            await _elementSourceFingerprint(
                portableManifest, element, readPortable);
      }
    }
    return ResourcePackCatalog.fromJson(updatedJson);
  }

  Future<Uint8List> _readFile(NativeResourcePackFile source) async {
    if (source.byteLength > policy.maxFileBytes) _fail('file_too_large');
    final builder = BytesBuilder(copy: false);
    await for (final chunk in source.openRead()) {
      if (chunk.length > policy.maxChunkBytes ||
          builder.length + chunk.length > source.byteLength) {
        _fail('source_changed');
      }
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    if (bytes.length != source.byteLength ||
        sha256.convert(bytes).toString() != source.rawSha256) {
      _fail('source_changed');
    }
    return bytes;
  }
}

Future<
        (
          Map<String, List<BorderSnapshotContentFrame>>,
          Map<BorderGroundVariantRole, List<BorderSnapshotContentFrame>>
        )>
    _borderSources(ProjectManifest manifest, BorderBlueprintRecord record,
        CanonicalBorderPngReader read) async {
  final primitives = <String, List<BorderSnapshotContentFrame>>{};
  for (final primitive in record.latestPublished!.definition.primitives) {
    if (primitive.isSpatial) continue;
    final element = manifest.elements
        .where((e) => e.id == primitive.sourceElementId)
        .firstOrNull;
    if (element == null) _fail('border_source_missing');
    final prepared = await _prepareElement(manifest, element, read);
    primitives[primitive.id] = [
      for (var index = 0; index < prepared.files.length; index++)
        BorderSnapshotContentFrame(
            sourceRectPx: prepared.snapshot.frames[index].sourceRectPx,
            durationMs: prepared.snapshot.frames[index].durationMs,
            transparentColorArgb:
                prepared.snapshot.frames[index].transparentColorArgb,
            rgbaBytes: img
                .decodePng(prepared.files[index].bytes)!
                .getBytes(order: img.ChannelOrder.rgba))
    ];
  }
  final ground = record.latestPublished!.definition.ground;
  final grounds = ground == null
      ? <BorderGroundVariantRole, List<BorderSnapshotContentFrame>>{}
      : {
          for (final entry in (await const CanonicalBorderGroundComposer()
                  .composeAllRoles(
                      manifest: manifest,
                      sourceSmartTilePresetId: ground.sourceSmartTilePresetId,
                      readPng: read))
              .entries)
            entry.key: entry.value.map((frame) => frame.contentFrame).toList()
        };
  return (primitives, grounds);
}

Future<CanonicalBorderSnapshotPreparation> _prepareElement(
    ProjectManifest manifest,
    ProjectElementEntry element,
    CanonicalBorderPngReader read) async {
  final frames = <CanonicalBorderSourceFrame>[];
  for (final frame in element.frames) {
    final tileset = manifest.tilesets
        .where((t) =>
            t.id ==
            (frame.tilesetId.isEmpty ? element.tilesetId : frame.tilesetId))
        .firstOrNull;
    if (tileset == null || tileset.source == null) {
      _fail('border_source_missing');
    }
    final resolved = const ProjectTilesetVisualResolver().resolve(
        source: tileset.source!,
        selection:
            ProjectTilesetVisualSelection.regularAtlas(source: frame.source),
        cellWidth: manifest.settings.tileWidth,
        cellHeight: manifest.settings.tileHeight);
    for (final visual in resolved.frames) {
      final duration =
          frame.durationMs ?? (visual.durationMs > 0 ? visual.durationMs : 100);
      final color = tileset.transparentColor;
      final argb = color == null
          ? null
          : 0xff000000 | color.red << 16 | color.green << 8 | color.blue;
      final single = visual.slices.length == 1 ? visual.slices.single : null;
      if (single != null &&
          single.sourceRect.width == single.destinationRect.width &&
          single.sourceRect.height == single.destinationRect.height) {
        final rect = single.sourceRect;
        frames.add(CanonicalBorderSourceFrame(
            sourceProjectRelativePath: tileset.relativePath,
            encodedImageBytes: await read(tileset, single.assetId),
            sourceRectPx: BorderPixelRect(
                x: rect.x, y: rect.y, width: rect.width, height: rect.height),
            durationMs: duration,
            transparentColorArgb: argb));
        continue;
      }
      final pixels = img.Image(
          width: visual.bounds.width,
          height: visual.bounds.height,
          numChannels: 4);
      for (final slice in visual.slices) {
        final source = img
            .decodePng(Uint8List.fromList(await read(tileset, slice.assetId)));
        if (source == null) _fail('border_source_invalid');
        final rect = slice.sourceRect;
        if (rect.x < 0 ||
            rect.y < 0 ||
            rect.x + rect.width > source.width ||
            rect.y + rect.height > source.height) {
          _fail('border_source_invalid');
        }
        img.compositeImage(
            pixels,
            img.copyCrop(source,
                x: rect.x, y: rect.y, width: rect.width, height: rect.height),
            dstX: slice.destinationRect.x - visual.bounds.x,
            dstY: slice.destinationRect.y - visual.bounds.y,
            dstW: slice.destinationRect.width,
            dstH: slice.destinationRect.height);
      }
      frames.add(CanonicalBorderSourceFrame(
          sourceProjectRelativePath: tileset.relativePath,
          encodedImageBytes: img.encodePng(pixels),
          durationMs: duration,
          transparentColorArgb: argb));
    }
  }
  return const CanonicalBorderSnapshotCompiler()
      .prepare(sourceElementId: element.id, frames: frames);
}

String _key(String kind, String id, [String? owner]) =>
    jsonEncode([kind, owner, id]);
Map<String, dynamic> _clone(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
Iterable<Map<String, dynamic>> _objects(Object? value) =>
    value == null ? const [] : (value as List).cast<Map<String, dynamic>>();
ResourcePackBuildSource _inlineSource(
        String path, Uint8List bytes, String type, int chunkSize) =>
    ResourcePackBuildSource(
        path: path,
        byteLength: bytes.length,
        rawSha256: sha256.convert(bytes).toString(),
        mediaType: type,
        openRead: () async* {
          for (var start = 0; start < bytes.length; start += chunkSize) {
            yield Uint8List.sublistView(
                bytes,
                start,
                start + chunkSize < bytes.length
                    ? start + chunkSize
                    : bytes.length);
          }
        });
Never _fail(String code, [String? identity]) => throw FormatException(
    'resource_pack.$code${identity == null ? '' : ': $identity'}');

final class OwnedResourcePackExport {
  OwnedResourcePackExport._(
      this._store, this._scope, this._lease, this.inspection);
  final FileBackedPayloadStore _store;
  final FileBackedPayloadScope _scope;
  final FileBackedPayloadLease _lease;
  final ResourcePackInspection inspection;
  bool _disposed = false;
  StoredFilePayload get payload => _lease.payload;
  Future<T> withSource<T>(Future<T> Function(RandomAccessPackageSource) read) {
    if (_disposed) throw StateError('The exported pack has been released.');
    return _store.withSource(scope: _scope, handle: payload.handle, read: read);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _store.release(scope: _scope, leaseId: _lease.leaseId);
  }
}

final class CanonicalResourcePackExportService {
  const CanonicalResourcePackExportService(
      {required this.store,
      required this.scope,
      this.policy = const ResourcePackSecurityPolicy()});
  final FileBackedPayloadStore store;
  final FileBackedPayloadScope scope;
  final ResourcePackSecurityPolicy policy;
  Future<OwnedResourcePackExport> export(
      {required ResourcePackExportProjection projection,
      required ResourcePackMetadata metadata,
      required String expectedRevision,
      required Future<String> Function() readCurrentRevision}) async {
    if (projection.sourceRevision != expectedRevision ||
        await readCurrentRevision() != expectedRevision) {
      _fail('revision_changed');
    }
    final directory =
        await Directory.systemTemp.createTemp('avelune-pack-export-');
    FileBackedPayloadLease? lease;
    final file = File('${directory.path}/archive');
    final sink = _PrivateArchiveSink(file);
    try {
      final result = await ResourcePackBuilder(policy: policy).build(
          metadata: metadata,
          catalog: projection.catalog,
          tileWidth: projection.tileWidth,
          tileHeight: projection.tileHeight,
          sources: projection.sources,
          sink: sink);
      lease = await store.stage(
          scope: scope,
          chunks: _readChunks(file, policy.maxChunkBytes),
          byteLength: result.archiveBytes,
          expectedRawSha256: result.archiveRawSha256);
      final inspection = await store.withSource(
          scope: scope,
          handle: lease.payload.handle,
          read: (source) =>
              ResourcePackInspector(policy: policy).inspectSourceSync(source));
      if (inspection.archiveRawSha256 != result.archiveRawSha256 ||
          await readCurrentRevision() != expectedRevision) {
        _fail('revision_changed');
      }
      return OwnedResourcePackExport._(store, scope, lease, inspection);
    } catch (_) {
      await sink.abort();
      if (lease != null) {
        await store.release(scope: scope, leaseId: lease.leaseId);
      }
      rethrow;
    } finally {
      await sink.close();
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  }
}

final class _PrivateArchiveSink implements ResourcePackArchiveSink {
  _PrivateArchiveSink(this.file);
  final File file;
  RandomAccessFile? _writer;
  @override
  Future<void> write(Uint8List chunk) async {
    final writer = _writer ??= await file.open(mode: FileMode.writeOnly);
    await writer.writeFrom(chunk);
  }

  @override
  Future<void> finish() async {
    await _writer?.flush();
    await close();
  }

  Future<void> close() async {
    final writer = _writer;
    _writer = null;
    await writer?.close();
  }

  @override
  Future<void> abort() async {
    await close();
    if (await file.exists()) await file.delete();
  }
}

Stream<List<int>> _readChunks(File file, int size) async* {
  final reader = await file.open();
  try {
    while (true) {
      final chunk = await reader.read(size);
      if (chunk.isEmpty) return;
      yield chunk;
    }
  } finally {
    await reader.close();
  }
}

Future<String> _elementSourceFingerprint(ProjectManifest manifest,
        ProjectElementEntry element, CanonicalBorderPngReader read) async =>
    (await _prepareElement(manifest, element, read)).metrics.assetFingerprint;

Future<void> _verifyNativeAlias(
    NativeResourcePackFile file, ResourcePackSecurityPolicy policy) async {
  var length = 0;
  Stream<List<int>> checkedChunks() async* {
    await for (final chunk in file.openRead()) {
      if (chunk.length > policy.maxChunkBytes ||
          chunk.any((byte) => byte < 0 || byte > 255)) {
        _fail('source_chunk_invalid', file.id);
      }
      length += chunk.length;
      if (length > file.byteLength) {
        _fail('source_changed', file.id);
      }
      yield Uint8List.fromList(chunk);
    }
    if (length != file.byteLength) {
      _fail('source_changed', file.id);
    }
  }

  final digest = await sha256.bind(checkedChunks()).first;
  if (digest.toString() != file.rawSha256) {
    _fail('source_changed', file.id);
  }
}
