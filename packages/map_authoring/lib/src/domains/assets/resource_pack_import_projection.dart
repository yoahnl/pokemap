import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import '../maps/canonical_border_ground_composer.dart';
import 'resource_pack_border_sources.dart';
import 'resource_pack_native_remapper.dart';

final class ResourcePackImportProjection {
  ResourcePackImportProjection(
      {required this.inspection,
      required this.closure,
      required this.copyOrdinal,
      ResourcePackInstallation? previous})
      : previous = previous {
    namespace = CanonicalJson.sha256Hex({
      'packId': inspection.manifest.pack.id,
      'version': inspection.manifest.pack.version,
      'archiveRawSha256': inspection.archiveRawSha256,
      'copyOrdinal': copyOrdinal,
    }).substring(0, 16);
    sourceNodes = indexResourcePackDefinitions(inspection.catalog.toJson());
    for (final snapshot in inspection.catalog.borderCatalog.visualSnapshots) {
      final nativeKey = resourcePackNativeKey('borderSnapshot', snapshot.id);
      sourceNodes[resourcePackNativeKey('borderSnapshot',
              resourcePackBorderSnapshotAlias(snapshot.contentFingerprint))] =
          sourceNodes.remove(nativeKey)!;
    }
    for (final node in closure.nodes) {
      final kind =
          node.resource?.kind.name ?? node.support?.kind.name ?? 'file';
      final id = node.resource?.id ?? node.support?.id ?? node.fileId!;
      final owner = node.support?.owner?.id;
      final key = resourcePackNativeKey(kind, id, owner);
      selectedKeys.add(key);
      mapping[key] = kind == 'borderSnapshot'
          ? sourceNodes[key]!['id'] as String
          : _allocate(key);
    }
    if (previous != null) {
      for (final item in previous.resources) {
        _requireMapping(
            resourcePackNativeKey(item.source.kind.name, item.source.id),
            item.targetId);
      }
      for (final item in previous.supports) {
        _requireMapping(
            resourcePackNativeKey(
                item.kind.name, item.sourceId, item.owner?.id),
            item.targetId);
      }
    }
    final selectedFiles = closure.files.toSet();
    for (final file in inspection.catalog.files
        .where((f) => selectedFiles.contains(f.id))) {
      filePaths[file.id] =
          'assets/resource_packs/$namespace/${mapping[resourcePackNativeKey('file', file.id)]}.${file.mediaType == 'image/png' ? 'png' : 'glb'}';
      fileIdsByPath[file.logicalPath] = file.id;
    }
    for (final model in inspection.catalog.models3d.where(
        (m) => selectedKeys.contains(resourcePackNativeKey('model3d', m.id)))) {
      filePaths[model.sourceAssetId] =
          'assets/models3d/${reference('model3d', model.id)}.glb';
    }
    for (final snapshot in inspection.catalog.borderCatalog.visualSnapshots
        .where((s) => selectedKeys.contains(resourcePackNativeKey(
            'borderSnapshot',
            resourcePackBorderSnapshotAlias(s.contentFingerprint))))) {
      for (var i = 0; i < snapshot.frames.length; i++) {
        final file = fileIdsByPath[snapshot.frames[i].relativeAssetPath];
        if (file == null) _fail('file_path_missing');
        filePaths[file] =
            'assets/borders/snapshots/${snapshot.contentFingerprint}/frame_${i.toString().padLeft(4, '0')}.png';
      }
    }
    if (previous != null) {
      for (final item
          in previous.assets.where((a) => selectedFiles.contains(a.fileId))) {
        if (filePaths[item.fileId] != item.targetPath) {
          _fail('mapping_conflict');
        }
        mapping[resourcePackNativeKey('file', item.fileId)] = item.assetId;
      }
    }
  }
  final ResourcePackInspection inspection;
  final ResourcePackClosure closure;
  final int copyOrdinal;
  final ResourcePackInstallation? previous;
  late final String namespace;
  late final Map<String, Map<String, dynamic>> sourceNodes;
  final Set<String> selectedKeys = {};
  final Map<String, String> mapping = {};
  final Map<String, String> internalMappings = {};
  final Map<String, String> filePaths = {};
  final Map<String, String> fileIdsByPath = {};
  final Map<String, Map<String, dynamic>> definitions = {};
  final Set<String> _active = {};
  late ResourcePackCatalog catalog;

  String _allocate(String key) {
    final parts = jsonDecode(key) as List;
    final kind = parts[0] as String;
    final localId =
        parts[1] == null ? parts[2] as String : '${parts[1]}:${parts[2]}';
    return 'rp_${namespace}_${sha256.convert(utf8.encode('$kind:$localId')).toString().substring(0, 24)}';
  }

  void _requireMapping(String key, String expected) {
    if (selectedKeys.contains(key) && mapping[key] != expected) {
      _fail('mapping_conflict');
    }
  }

  String allocateInternal(String key) =>
      mapping[key] ?? internalMappings.putIfAbsent(key, () => _allocate(key));
  String reference(String kind, String id, [String? owner]) {
    if (kind == 'borderSnapshot') {
      final snapshot = inspection.catalog.borderCatalog.visualSnapshots
          .where((s) => s.id == id)
          .firstOrNull;
      if (snapshot != null) {
        id = resourcePackBorderSnapshotAlias(snapshot.contentFingerprint);
      }
    }
    return mapping[resourcePackNativeKey(kind, id, owner)] ??
        (throw FormatException('resource_pack.mapping_missing: $kind:$id'));
  }

  String file(String id, {String? logicalPath}) {
    if (!filePaths.containsKey(id) ||
        logicalPath != null && logicalPath != filePaths[id]) {
      _fail('file_binding_path_conflict');
    }
    return reference('file', id);
  }

  Map<String, dynamic> _value(String kind, String id, [String? owner]) {
    final key = resourcePackNativeKey(kind, id, owner);
    final completed = definitions[key];
    if (completed != null) return completed;
    if (!selectedKeys.contains(key) || !_active.add(key)) {
      _fail('reference_invalid');
    }
    final source = sourceNodes[key];
    if (source == null) _fail('reference_missing');
    final value =
        Map<String, dynamic>.from(jsonDecode(jsonEncode(source)) as Map);
    value['id'] = reference(kind, id, owner);
    _remapper.remap(kind, id, value, owner);
    _active.remove(key);
    return definitions[key] = value;
  }

  late final _remapper = ResourcePackNativeRemapper(
      reference: reference,
      allocate: allocateInternal,
      file: file,
      path: (path) =>
          filePaths[fileIdsByPath[path]] ??
          (throw const FormatException('resource_pack.file_path_missing')),
      supportValue: _value,
      fileIdForPath: (path) =>
          fileIdsByPath[path] ??
          (throw const FormatException('resource_pack.file_path_missing')),
      prepareFile: (_) {},
      removed: (_) {});

  void project() {
    for (final key in selectedKeys) {
      final parts = jsonDecode(key) as List;
      if (parts[0] != 'file') {
        _value(parts[0] as String, parts[2] as String, parts[1] as String?);
      }
    }
    final json = inspection.catalog.toJson();
    List<Map<String, dynamic>> values(String kind) => [
          for (final key in selectedKeys.toList()..sort())
            if ((jsonDecode(key) as List)[0] == kind) definitions[key]!
        ];
    json['tilesets'] = values('tileset');
    json['elements'] = values('element');
    json['models3d'] = values('model3d');
    json['characters'] = values('character');
    json['environmentPresets'] = values('environmentPreset');
    json['elementCategories'] = values('elementCategory');
    json['tilesetFolders'] = values('tilesetFolder');
    json['resourceLibraryCatalog'] = {
      'formatVersion': ResourceLibraryCatalog.currentFormatVersion,
      'families': values('resourceFamily'),
      'entries': [
        for (final entry in inspection.catalog.resourceLibraryCatalog.entries)
          if (selectedKeys.contains(
              resourcePackNativeKey(entry.resourceKind, entry.resourceId)))
            {
              ...entry.toJson(),
              'resourceId': reference(entry.resourceKind, entry.resourceId),
              if (entry.familyId != null)
                'familyId': reference('resourceFamily', entry.familyId!),
              'mapId': null,
            }
      ]
    };
    json['smartTileCatalog'] = {
      'formatVersion': ProjectSmartTileCatalog.currentFormatVersion,
      'categories': values('smartTileCategory'),
      'materials': values('smartTileMaterial'),
      'atlases': values('smartTileAtlas'),
      'animations': values('smartTileAnimation'),
      'presets': values('smartTilePreset'),
      'patterns': values('smartTilePattern')
    };
    json['borderCatalog'] = {
      'formatVersion': ProjectBorderCatalog.latestSupportedFormatVersion,
      'records': values('borderBlueprint'),
      'visualSnapshots': values('borderSnapshot')
    };
    json['characterStudioCatalog'] = {
      'portraitStates': values('characterPortraitState'),
      'customAnimationDefinitions': values('characterAnimationDefinition')
    };
    json['files'] = [
      for (final binding in inspection.catalog.files)
        if (filePaths.containsKey(binding.id))
          {
            ...binding.toJson(),
            'id': reference('file', binding.id),
            'logicalPath': filePaths[binding.id]
          }
    ];
    json['provenance'] = [
      for (final entry in inspection.catalog.provenance)
        {
          ...entry.toJson(),
          'resources': [
            for (final root in entry.resources)
              if (selectedKeys
                  .contains(resourcePackNativeKey(root.kind.name, root.id)))
                {
                  'resourceKind': root.kind.name,
                  'id': reference(root.kind.name, root.id)
                }
          ]
        }
    ];
    json['extras'] = {
      'smartTilePatternIds': [
        for (final id in inspection.catalog.smartTilePatternIds)
          if (selectedKeys
              .contains(resourcePackNativeKey('smartTilePattern', id)))
            reference('smartTilePattern', id)
      ]
    };
    catalog = ResourcePackCatalog.fromJson(json);
    ResourcePackDependencyGraph.fromCatalog(catalog).validateAll();
  }

  Future<void> certifyBorders(
      ProjectManifest target,
      CanonicalBorderPngReader read,
      CanonicalBorderPngReader readPortable) async {
    if (catalog.borderCatalog.records.isEmpty) return;
    final portable = inspection.catalog;
    final sourceManifest = target.copyWith(
        tilesets: portable.tilesets,
        elements: portable.elements,
        models3d: portable.models3d,
        smartTileCatalog: portable.smartTileCatalog);
    for (final record in portable.borderCatalog.records.where((record) =>
        selectedKeys
            .contains(resourcePackNativeKey('borderBlueprint', record.id)))) {
      final sources = await prepareResourcePackBorderSources(
          sourceManifest, record, readPortable);
      projectResourcePackPublishedBorder(
          record: record,
          snapshots: portable.borderCatalog.visualSnapshots,
          primitiveSourceFrames: sources.$1,
          groundSourceFrames: sources.$2);
    }
    final manifest = target.copyWith(
        tilesets: catalog.tilesets,
        elements: catalog.elements,
        models3d: catalog.models3d,
        smartTileCatalog: catalog.smartTileCatalog);
    final json = catalog.toJson();
    final records = (json['borderCatalog'] as Map)['records'] as List;
    for (final record in catalog.borderCatalog.records) {
      final sources =
          await prepareResourcePackBorderSources(manifest, record, read);
      try {
        projectResourcePackPublishedBorder(
            record: record,
            snapshots: catalog.borderCatalog.visualSnapshots,
            primitiveSourceFrames: sources.$1,
            groundSourceFrames: sources.$2);
      } on FormatException {
        _fail('border_remap_changes_pixels');
      }
      final raw =
          records.cast<Map>().singleWhere((raw) => raw['id'] == record.id);
      final primitives = ((raw['latestPublished'] as Map)['definition']
          as Map)['primitives'] as List;
      for (final primitive in primitives.cast<Map>()) {
        final elementId = primitive['sourceElementId'];
        if (elementId == null) continue;
        final element = catalog.elements.singleWhere((e) => e.id == elementId);
        (primitive['publishedMetrics'] as Map)['assetFingerprint'] =
            (await prepareResourcePackElementSource(manifest, element, read))
                .metrics
                .assetFingerprint;
      }
    }
    catalog = ResourcePackCatalog.fromJson(json);
    final expected = indexResourcePackDefinitions(catalog.toJson());
    for (final key in definitions.keys.toList()) {
      final parts = jsonDecode(key) as List;
      final mappedKey = resourcePackNativeKey(parts[0] as String, mapping[key]!,
          parts[1] == null ? null : reference('tileset', parts[1] as String));
      definitions[key] = expected[mappedKey]!;
    }
  }
}

Map<String, Map<String, dynamic>> indexResourcePackDefinitions(
    Map<String, Object?> json) {
  final result = <String, Map<String, dynamic>>{};
  void index(String kind, Object? values, [String? owner]) {
    if (values is! List) return;
    for (final raw in values.cast<Map>()) {
      final value = Map<String, dynamic>.from(raw);
      final key = resourcePackNativeKey(kind, value['id'] as String, owner);
      if (result.containsKey(key)) _fail('duplicate_native_identity');
      result[key] = value;
    }
  }

  for (final entry in const {
    'tilesets': 'tileset',
    'elements': 'element',
    'models3d': 'model3d',
    'characters': 'character',
    'environmentPresets': 'environmentPreset',
    'elementCategories': 'elementCategory',
    'tilesetFolders': 'tilesetFolder'
  }.entries) {
    index(entry.value, json[entry.key]);
  }
  for (final raw in (json['tilesets'] as List? ?? const []).cast<Map>()) {
    index('tilesetElementGroup', raw['elementGroups'], raw['id'] as String);
  }
  final library = json['resourceLibraryCatalog'] as Map? ?? const {};
  index('resourceFamily', library['families']);
  final smart = json['smartTileCatalog'] as Map? ?? const {};
  for (final entry in const {
    'categories': 'smartTileCategory',
    'materials': 'smartTileMaterial',
    'atlases': 'smartTileAtlas',
    'animations': 'smartTileAnimation',
    'presets': 'smartTilePreset',
    'patterns': 'smartTilePattern'
  }.entries) {
    index(entry.value, smart[entry.key]);
  }
  for (final group in (smart['materials'] as List? ?? const [])
      .cast<Map>()
      .map((m) => m['connectionGroupId'] as String)
      .toSet()) {
    result[resourcePackNativeKey('smartTileConnectionGroup', group)] = {
      'id': group
    };
  }
  final border = json['borderCatalog'] as Map? ?? const {};
  index('borderBlueprint', border['records']);
  index('borderSnapshot', border['visualSnapshots']);
  final characters = json['characterStudioCatalog'] as Map? ?? const {};
  index('characterPortraitState', characters['portraitStates']);
  index(
      'characterAnimationDefinition', characters['customAnimationDefinitions']);
  return result;
}

String resourcePackNativeKey(String kind, String id, [String? owner]) =>
    jsonEncode([kind, owner, id]);
Never _fail(String code) => throw FormatException('resource_pack.$code');
