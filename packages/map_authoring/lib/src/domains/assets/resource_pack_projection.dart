import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../ports/file_backed_payload_store.dart';
import '../../support/authoring_fingerprint.dart';
import '../../infrastructure/local_resource_pack_store.dart';
import 'resource_pack_native_remapper.dart';
import 'resource_pack_dynamic_remapping.dart';
import 'resource_pack_border_sources.dart';
import '../maps/canonical_border_ground_composer.dart';

part 'resource_pack_native_attribution.dart';
part 'resource_pack_native_review.dart';

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
      required this.nativeMappings,
      required this.nativeSourceIds,
      required this.review});
  final String sourceRevision;
  final int tileWidth;
  final int tileHeight;
  final ResourcePackCatalog catalog;
  final List<ResourcePackRef> roots;
  final List<ResourcePackBuildSource> sources;
  final List<NativeResourcePackRef> promotedResources;
  final List<String> removedOrganization;
  final Map<String, String> nativeMappings;
  final Set<String> nativeSourceIds;
  final ResourcePackNativeReview review;
}

final class ResourcePackProjectionBuilder {
  const ResourcePackProjectionBuilder(
      {this.policy = const ResourcePackSecurityPolicy()});
  final ResourcePackSecurityPolicy policy;

  Future<CatalogBudgetReport> measureNativeSelection({
    required ProjectManifest manifest,
    required Iterable<NativeResourcePackRef> roots,
    required Iterable<NativeResourcePackFile> files,
    Iterable<String> smartTilePatternIds = const [],
  }) => Isolate.run(_nativeSelectionBudgetWorker(
    manifest,
    roots.toList(),
    [for (final file in files)
      (file.id, file.logicalPath, file.byteLength, file.rawSha256, file.mediaType)],
    smartTilePatternIds.toList(),
    policy,
  ));

  Future<Set<String>> selectedFileIds({
    required ProjectManifest manifest,
    required Iterable<NativeResourcePackRef> roots,
    required Iterable<NativeResourcePackFile> files,
    Iterable<String> smartTilePatternIds = const [],
  }) => Isolate.run(
    _requiredNativeFilesWorker(
      manifest,
      roots.toList(),
      [
        for (final file in files)
          (
            file.id,
            file.logicalPath,
            file.byteLength,
            file.rawSha256,
            file.mediaType,
          ),
      ],
      smartTilePatternIds.toList(),
      policy,
    ),
  );

  Future<ResourcePackExportProjection> project({
    required ProjectManifest manifest,
    required Iterable<NativeResourcePackRef> roots,
    required Iterable<NativeResourcePackFile> files,
    required String author,
    required String sourceRevision,
    String? sourceUrl,
    Iterable<ResourcePackBuildSource> localLicenses = const [],
    NativeResourcePackAttribution? attribution,
    Iterable<String> smartTilePatternIds = const [],
  }) async {
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
    projection.requireBudget();
    if (portableRoots.isEmpty && patterns.isEmpty) _fail('selection_empty');
    final inherited = _NativeAttributions(projection, attribution);
    final licenses = <String>[];
    final sources = <String, ResourcePackBuildSource>{};
    final localDocuments = <String, List<ResourcePackBuildSource>>{};
    for (final document in localLicenses) {
      document.inventory;
      if (document.path != 'licenses/${document.rawSha256}.txt' ||
          document.mediaType != 'text/plain' ||
          document.byteLength > policy.maxFileBytes) {
        _fail('license_document_invalid');
      }
      localDocuments.putIfAbsent(document.path, () => []).add(document);
    }
    for (final entry in localDocuments.entries) {
      licenses.add(entry.key);
      sources[entry.key] = _documentAliases(entry.value, policy);
    }
    final localResources = <ResourcePackRef>[];
    for (final key in projection.completed.keys) {
      final node = projection.nodes[key]!;
      if (!ResourcePackKind.values.any((kind) => kind.name == node.kind)) {
        continue;
      }
      final ref = ResourcePackRef(
          kind: ResourcePackKind.values.byName(node.kind),
          id: projection.allocate(key));
      if (!inherited.resourceOrigins.containsKey(key)) localResources.add(ref);
    }
    var hasLocalFiles = false;
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
      final attribution = inherited.fileOrigins[node.id];
      hasLocalFiles |= attribution == null;
      bindings.add(ResourcePackFileBinding(
          id: id,
          logicalPath: projection.filePaths[node.id]!,
          archivePath: path,
          byteLength: file.byteLength,
          mediaType: file.mediaType,
          rawSha256: file.rawSha256,
          provenanceId: attribution?.$1 ?? 'declared',
          licenseIds: attribution?.$2 ?? licenses));
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
    for (final entry in inherited.documentSources().entries) {
      final existing = sources[entry.key];
      sources[entry.key] = existing == null
          ? entry.value
          : _documentAliases([existing, entry.value], policy);
    }
    final origins = inherited.portableOrigins();
    if (localResources.isNotEmpty ||
        hasLocalFiles ||
        localDocuments.isNotEmpty) {
      origins.add(ResourcePackProvenance(
          id: 'declared',
          author: author,
          sourceUrl: sourceUrl,
          licenseIds: licenses,
          resources: localResources));
    }
    final json = projection.catalogJson(bindings, origins);
    var catalog = ResourcePackCatalog.fromJson(json);
    ResourcePackDependencyGraph.fromCatalog(catalog).validateAll();
    catalog = await projection.verifyBorders(catalog);
    final budget = CatalogBudgetCalculator(resourcePackPolicy: policy)
        .measureResourcePack(catalog, scope: 'preparedExport',
          files: [for (final source in sources.values)
            CatalogBudgetFile(path: source.path, byteLength: source.byteLength)]);
    if (!budget.accepted) throw CatalogBudgetExceededException(budget);
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
        nativeMappings: Map.unmodifiable(projection.mapping),
        review: _nativeReview(projection, catalog, selected, patterns,
            sources.values.toList(), inherited.documentFileIds),
        nativeSourceIds: Set.unmodifiable({
          for (final key in projection.completed.keys)
            if (projection.nodes[key]!.kind == 'file')
              projection.nodes[key]!.id,
          ...inherited.documentFileIds
        }));
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
  late final Map<String, CatalogDynamicDependency> dynamicDeclarations = () {
    final declarations = <String, CatalogDynamicDependency>{};
    for (final declaration
        in PortableCatalogPublication.projectDynamicDependencies(manifest)) {
      final key = resourcePackDynamicNativeKey(declaration.owner);
      if (declarations.containsKey(key)) _fail('dynamic_duplicate', key);
      declarations[key] = declaration;
    }
    return declarations;
  }();
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
    _remapper.remap(kind, id, value, owner);
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
    for (final target in dynamicDeclarations[key]?.targets ??
        const <CatalogDefinitionKey>[]) {
      remapResourcePackDynamicKey(target, reference);
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
    return kind == 'borderSnapshot' ? id : allocate(key);
  }

  CatalogBudgetReport measureBudget() {
    const scope = 'nativeSelection';
    CatalogBudgetMetric fact(String dimension, int observed, int? allowed,
        String label, String remedy) => CatalogBudgetMetric(
      scope: scope, dimension: dimension, observed: observed, allowed: allowed,
      unit: 'count', label: label, remedy: remedy,
    );
    final counts = <String, int>{};
    var largestFile = 0;
    final physicalFiles = <String, int>{};
    for (final key in completed.keys) {
      final node = nodes[key]!;
      counts.update(node.kind, (count) => count + 1, ifAbsent: () => 1);
      if (node.kind == 'file') {
        final file = files[node.id]!;
        largestFile = max(largestFile, file.byteLength);
        physicalFiles['${file.rawSha256}:${file.byteLength}:${file.mediaType}'] =
            file.byteLength;
      }
    }
    final definitions = const CatalogBudgetCalculator().measureJsonDocument(
      catalogJson([], []), scope: 'nativeSelectionDefinitions');
    return CatalogBudgetReport(
      scope: scope,
      metrics: [
        fact('resources', _resourceCount, policy.maxResources,
            'Ressources de la sélection et de ses dépendances',
            'Réduire la sélection ou partager les définitions équivalentes.'),
        fact('supports', _supportCount, policy.maxSupports,
            'Définitions techniques de la sélection',
            'Partager les matières, motifs et autres définitions équivalentes.'),
        fact('files', _fileCount, policy.maxPublishedFiles,
            'Fichiers logiques nécessaires',
            'Réduire la sélection ou regrouper les sources compatibles.'),
        CatalogBudgetMetric(scope: scope, dimension: 'fileBytes',
          observed: largestFile, allowed: policy.maxFileBytes, unit: 'bytes',
          label: 'Plus gros fichier source',
          remedy: 'Préparer une source plus petite en conservant les images entières.'),
        ...definitions.metrics,
      ],
      totals: {
        'resources': _resourceCount, 'supports': _supportCount,
        'files': _fileCount,
        'sourceBlobBytes': physicalFiles.values.fold<int>(0, (sum, n) => sum + n),
        'archiveBytes': null,
      },
      breakdown: [for (final kind in counts.keys.toList()..sort())
        fact(kind, counts[kind]!, null, kind, '')],
      unknownDimensions: const [
        'publicationMetadata', 'archiveBytes', 'publishedCatalogBytes',
        'imagePixels', 'licenses', 'mediaIntegrity',
      ],
    );
  }

  void requireBudget() {
    if (_resourceCount <= policy.maxResources &&
        _supportCount <= policy.maxSupports &&
        _fileCount <= policy.maxPublishedFiles &&
        completed.keys.where((key) => nodes[key]!.kind == 'file').every(
            (key) => files[nodes[key]!.id]!.byteLength <= policy.maxFileBytes)) {
      return;
    }
    final report = measureBudget();
    if (!report.accepted) throw CatalogBudgetExceededException(report);
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

  late final _remapper = ResourcePackNativeRemapper(
      reference: reference,
      allocate: allocate,
      file: _file,
      path: _path,
      supportValue: _supportValue,
      fileIdForPath: (path) =>
          filesByPath[path] ??
          (throw FormatException('resource_pack.file_path_missing: $path')),
      prepareFile: (id) {
        final file = files[id]!;
        if (file.mediaType != 'image/png' &&
            file.mediaType != 'model/gltf-binary') {
          _fail('file_type_unsupported');
        }
        filePaths.putIfAbsent(
            id,
            () =>
                'assets/resource_packs/${allocate(_key('file', id))}.${file.mediaType == 'image/png' ? 'png' : 'glb'}');
      },
      removed: removed.add);

  String _portableDynamicReference(String kind, String id, [String? owner]) {
    final mapped = reference(kind, id, owner);
    if (kind != 'borderSnapshot') return mapped;
    return resourcePackBorderSnapshotAlias(
        nodes[_key(kind, id, owner)]!.value['contentFingerprint'] as String);
  }

  Map<String, Object?> catalogJson(List<ResourcePackFileBinding> bindings,
      List<ResourcePackProvenance> provenance) {
    List<Map<String, dynamic>> entries(String kind) => [
          for (final key in completed.keys.toList()..sort())
            if (nodes[key]!.kind == kind) completed[key]!
        ];
    return {
      'dynamicDependencies': [
        for (final declaration in dynamicDeclarations.entries)
          if (completed.containsKey(declaration.key))
            remapResourcePackDynamicDependency(
                    declaration.value, _portableDynamicReference)
                .toJson(),
      ],
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
      final before = await prepareResourcePackBorderSources(
          manifest, original, readOriginal);
      projectResourcePackPublishedBorder(
          record: original,
          snapshots: manifest.borderCatalog.visualSnapshots,
          primitiveSourceFrames: before.$1,
          groundSourceFrames: before.$2);
      final after = await prepareResourcePackBorderSources(
          portableManifest, record, readPortable);
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

String _key(String kind, String id, [String? owner]) =>
    jsonEncode([kind, owner, id]);
Map<String, dynamic> _clone(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
Iterable<Map<String, dynamic>> _objects(Object? value) =>
    value == null ? const [] : (value as List).cast<Map<String, dynamic>>();
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

final class NativeResourcePackPreparedExport {
  NativeResourcePackPreparedExport._(this._store, this._scope, this.metadata,
      this.sourceRevision, this._snapshot, this._bindings, this._leases);
  final LocalResourcePackStore _store;
  final FileBackedPayloadScope _scope;
  final ResourcePackMetadata metadata;
  final String sourceRevision;
  final _NativeExportSnapshot _snapshot;
  final Map<String, List<StoredFilePayload>> _bindings;
  final List<FileBackedPayloadLease> _leases;
  bool _disposed = false;
  Future<void>? _closing;
  ResourcePackCatalog get catalog => _snapshot.catalog;
  ResourcePackNativeReview get review => _snapshot.review;
  Map<String, List<String>> get reachedNativeIds => review.reachedNativeIds;
  Set<String> get nativeSourceIds => _snapshot.nativeSourceIds;
  Map<String, String> get nativeMappings => _snapshot.nativeMappings;
  List<NativeResourcePackRef> get promotedResources =>
      _snapshot.promotedResources;
  List<String> get removedOrganization => _snapshot.removedOrganization;
  List<ResourcePackRef> get roots => _snapshot.roots;
  List<ResourcePackInventoryFile> get sourceInventory => _snapshot.sources;
  Iterable<String> get payloadHandles =>
      _leases.map((lease) => lease.payload.handle);
  late final String projectionFingerprint = computeAuthoringJsonFingerprint({
    'sourceRevision': sourceRevision,
    'metadata': metadata.toJson(),
    'catalog': catalog.toJson(),
    'roots': roots.map((root) => root.toJson()).toList(),
    'sources': sourceInventory.map((source) => source.toJson()).toList()
  }, logicalName: 'resource-pack-export-preparation');

  Future<NativeResourcePackPreparedExport> retain() async {
    if (_disposed) _failPrepared('preparation_released');
    final leases = <FileBackedPayloadLease>[];
    try {
      for (final handle in payloadHandles.toSet()) {
        leases.add(_store.retainForJob(scope: _scope, handle: handle));
      }
      return NativeResourcePackPreparedExport._(_store, _scope, metadata,
          sourceRevision, _snapshot, _bindings, List.unmodifiable(leases));
    } on Object {
      for (final lease in leases) {
        await _store.release(scope: _scope, leaseId: lease.leaseId);
      }
      rethrow;
    }
  }

  Future<void> dispose() {
    _disposed = true;
    return _closing ??= _release();
  }

  Future<void> _release() async {
    for (final lease in _leases) {
      await _store.release(scope: _scope, leaseId: lease.leaseId);
    }
  }
}

final class _NativeExportSnapshot {
  _NativeExportSnapshot(
      this.catalog,
      Iterable<ResourcePackRef> roots,
      this.tileWidth,
      this.tileHeight,
      Iterable<ResourcePackInventoryFile> sources,
      Iterable<String> nativeSourceIds,
      Iterable<NativeResourcePackRef> promotedResources,
      Iterable<String> removedOrganization,
      Map<String, String> nativeMappings,
      this.review)
      : roots = List.unmodifiable(roots),
        sources = List.unmodifiable(sources),
        nativeSourceIds = Set.unmodifiable(nativeSourceIds),
        promotedResources = List.unmodifiable(promotedResources),
        removedOrganization = List.unmodifiable(removedOrganization),
        nativeMappings = Map.unmodifiable(nativeMappings);
  final ResourcePackCatalog catalog;
  final List<ResourcePackRef> roots;
  final int tileWidth;
  final int tileHeight;
  final List<ResourcePackInventoryFile> sources;
  final Set<String> nativeSourceIds;
  final ResourcePackNativeReview review;
  final List<NativeResourcePackRef> promotedResources;
  final List<String> removedOrganization;
  final Map<String, String> nativeMappings;
}

final class CanonicalResourcePackExportService {
  const CanonicalResourcePackExportService(
      {required this.store,
      required this.scope,
      this.policy = const ResourcePackSecurityPolicy()});
  final FileBackedPayloadStore store;
  final FileBackedPayloadScope scope;
  final ResourcePackSecurityPolicy policy;
  Future<NativeResourcePackPreparedExport> prepareNative({
    required ProjectManifest manifest,
    required List<NativeResourcePackRef> roots,
    required List<String> smartTilePatternIds,
    required List<(String, String, StoredFilePayload, String)> files,
    required ResourcePackMetadata metadata,
    required String author,
    required String expectedRevision,
    required Future<String> Function() readCurrentRevision,
    List<StoredFilePayload> licenseDocuments = const [],
    String? sourceUrl,
    void Function()? checkCancelled,
  }) async {
    final local = store;
    if (local is! LocalResourcePackStore) {
      throw StateError('A disk worker is required.');
    }
    final selectedRoots = List<NativeResourcePackRef>.unmodifiable(roots);
    final selectedPatterns = List<String>.unmodifiable(smartTilePatternIds);
    final nativeFiles =
        List<(String, String, StoredFilePayload, String)>.unmodifiable(files);
    final documents = List<StoredFilePayload>.unmodifiable(licenseDocuments);
    final leases = <FileBackedPayloadLease>[];
    try {
      for (final handle in {
        ...nativeFiles.map((file) => file.$3.handle),
        ...documents.map((file) => file.handle)
      }) {
        leases.add(local.retainForJob(scope: scope, handle: handle));
      }
      if (await readCurrentRevision() != expectedRevision) {
        _failPrepared('revision_changed');
      }
      checkCancelled?.call();
      final snapshot = await local.withSourcesInIsolate(
          scope: scope,
          handles: leases.map((lease) => lease.payload.handle),
          read: _nativePrepareWorker(
              manifest,
              selectedRoots,
              selectedPatterns,
              nativeFiles,
              documents,
              author,
              expectedRevision,
              sourceUrl,
              policy));
      checkCancelled?.call();
      if (await readCurrentRevision() != expectedRevision) {
        _failPrepared('revision_changed');
      }
      final payloads = [
        for (final file in nativeFiles)
          if (snapshot.nativeSourceIds.contains(file.$1)) (file.$3, file.$4),
        for (final document in documents) (document, 'text/plain')
      ];
      final payloadsByContent =
          <(String, int, String), Map<String, StoredFilePayload>>{};
      for (final (payload, mediaType) in payloads) {
        payloadsByContent.putIfAbsent(
            (payload.rawSha256, payload.byteLength, mediaType),
            () => {})[payload.handle] = payload;
      }
      final bindings = <String, List<StoredFilePayload>>{};
      for (final descriptor in snapshot.sources) {
        final aliases = payloadsByContent[(
          descriptor.rawSha256,
          descriptor.byteLength,
          descriptor.mediaType
        )];
        if (aliases == null || aliases.isEmpty) {
          _failPrepared('prepared_source_missing');
        }
        bindings[descriptor.path] = List.unmodifiable(aliases.values);
      }
      final used = {
        for (final aliases in bindings.values)
          ...aliases.map((payload) => payload.handle)
      };
      for (final lease in leases
          .where((lease) => !used.contains(lease.payload.handle))
          .toList()) {
        await local.release(scope: scope, leaseId: lease.leaseId);
        leases.remove(lease);
      }
      return NativeResourcePackPreparedExport._(
          local,
          scope,
          metadata,
          expectedRevision,
          snapshot,
          Map.unmodifiable(bindings),
          List.unmodifiable(leases));
    } on Object {
      for (final lease in leases) {
        await local.release(scope: scope, leaseId: lease.leaseId);
      }
      rethrow;
    }
  }

  Future<OwnedResourcePackExport> exportPrepared(
      {required NativeResourcePackPreparedExport prepared,
      bool acknowledgeOrganizationRemoval = false,
      required Future<String> Function() readCurrentRevision,
      void Function()? checkCancelled}) async {
    if (!identical(prepared._store, store) || prepared._scope != scope) {
      _failPrepared('preparation_owner_mismatch');
    }
    if (prepared.review.requiresOrganizationAcknowledgement &&
        !acknowledgeOrganizationRemoval) {
      _failPrepared('organization_acknowledgement_required');
    }
    final owner = await prepared.retain();
    Directory? directory;
    FileBackedPayloadLease? lease;
    try {
      directory =
          await Directory.systemTemp.createTemp('avelune-native-export-');
      if (await readCurrentRevision() != owner.sourceRevision) {
        _failPrepared('revision_changed');
      }
      checkCancelled?.call();
      final result = await owner._store.withSourcesInIsolate(
          scope: scope,
          handles: owner.payloadHandles,
          read: _preparedExportWorker(owner._snapshot, owner.metadata,
              owner._bindings, directory.path, policy));
      checkCancelled?.call();
      if (await readCurrentRevision() != owner.sourceRevision) {
        _failPrepared('revision_changed');
      }
      lease = await store.stage(
          scope: scope,
          chunks: _readChunks(
              File('${directory.path}/archive'), policy.maxChunkBytes),
          byteLength: result.$1,
          expectedRawSha256: result.$2,
          checkCancelled: checkCancelled);
      final inspection = await owner._store.withSourceInIsolate(
          scope: scope,
          handle: lease.payload.handle,
          read: _exportInspector(policy));
      checkCancelled?.call();
      if (inspection.archiveRawSha256 != result.$2 ||
          await readCurrentRevision() != owner.sourceRevision) {
        _failPrepared('revision_changed');
      }
      return OwnedResourcePackExport._(store, scope, lease, inspection);
    } on Object {
      if (lease != null) {
        await store.release(scope: scope, leaseId: lease.leaseId);
      }
      rethrow;
    } finally {
      await owner.dispose();
      if (directory != null && await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  }

  Future<OwnedResourcePackExport> exportNative(
      {required ProjectManifest manifest,
      required List<NativeResourcePackRef> roots,
      required List<String> smartTilePatternIds,
      required List<(String, String, StoredFilePayload, String)> files,
      required ResourcePackMetadata metadata,
      required String author,
      required String expectedRevision,
      required Future<String> Function() readCurrentRevision,
      List<StoredFilePayload> licenseDocuments = const [],
      String? sourceUrl,
      bool acknowledgeOrganizationRemoval = false,
      void Function()? checkCancelled}) async {
    final prepared = await prepareNative(
        manifest: manifest,
        roots: roots,
        smartTilePatternIds: smartTilePatternIds,
        files: files,
        metadata: metadata,
        author: author,
        expectedRevision: expectedRevision,
        readCurrentRevision: readCurrentRevision,
        licenseDocuments: licenseDocuments,
        sourceUrl: sourceUrl,
        checkCancelled: checkCancelled);
    try {
      return await exportPrepared(
          prepared: prepared,
          acknowledgeOrganizationRemoval: acknowledgeOrganizationRemoval,
          readCurrentRevision: readCurrentRevision,
          checkCancelled: checkCancelled);
    } finally {
      await prepared.dispose();
    }
  }

  Future<OwnedResourcePackExport> export(
      {required ResourcePackExportProjection projection,
      bool acknowledgeOrganizationRemoval = false,
      required ResourcePackMetadata metadata,
      required String expectedRevision,
      required Future<String> Function() readCurrentRevision}) async {
    if (projection.review.requiresOrganizationAcknowledgement &&
        !acknowledgeOrganizationRemoval) {
      _failPrepared('organization_acknowledgement_required');
    }
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
    (await prepareResourcePackElementSource(manifest, element, read))
        .metrics
        .assetFingerprint;

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

ResourcePackInspection Function(RandomAccessPackageSource) _exportInspector(
  ResourcePackSecurityPolicy policy,
) =>
    (source) => ResourcePackInspector(policy: policy).inspectSourceSync(source);

Future<_NativeExportSnapshot> Function(Map<String, RandomAccessPackageSource>)
    _nativePrepareWorker(
            ProjectManifest manifest,
            List<NativeResourcePackRef> roots,
            List<String> patterns,
            List<(String, String, StoredFilePayload, String)> files,
            List<StoredFilePayload> documents,
            String author,
            String revision,
            String? sourceUrl,
            ResourcePackSecurityPolicy policy) =>
        (sources) async {
          final projection =
              await ResourcePackProjectionBuilder(policy: policy).project(
            manifest: manifest,
            roots: roots,
            files: [
              for (final file in files)
                NativeResourcePackFile(
                    id: file.$1,
                    logicalPath: file.$2,
                    byteLength: file.$3.byteLength,
                    rawSha256: file.$3.rawSha256,
                    mediaType: file.$4,
                    openRead: () => _nativeChunks(
                        sources[file.$3.handle]!, policy.maxChunkBytes))
            ],
            author: author,
            sourceRevision: revision,
            sourceUrl: sourceUrl,
            localLicenses: [
              for (final document in documents)
                ResourcePackBuildSource(
                    path: 'licenses/${document.rawSha256}.txt',
                    byteLength: document.byteLength,
                    rawSha256: document.rawSha256,
                    mediaType: 'text/plain',
                    openRead: () => _nativeChunks(
                        sources[document.handle]!, policy.maxChunkBytes))
            ],
            smartTilePatternIds: patterns,
          );
          for (final source in projection.sources
              .where((source) => source.mediaType == 'text/plain')) {
            await source.openRead().drain<void>();
          }
          return _NativeExportSnapshot(
              projection.catalog,
              projection.roots,
              projection.tileWidth,
              projection.tileHeight,
              projection.sources.map((source) => source.inventory).toList(),
              projection.nativeSourceIds,
              projection.promotedResources,
              projection.removedOrganization,
              projection.nativeMappings,
              projection.review);
        };

Future<(int, String)> Function(
    Map<String, RandomAccessPackageSource>) _preparedExportWorker(
        _NativeExportSnapshot snapshot,
        ResourcePackMetadata metadata,
        Map<String, List<StoredFilePayload>> bindings,
        String directory,
        ResourcePackSecurityPolicy policy) =>
    (sources) async {
      final sink = _PrivateArchiveSink(File('$directory/archive'));
      try {
        final built = await ResourcePackBuilder(policy: policy).build(
            metadata: metadata,
            catalog: snapshot.catalog,
            tileWidth: snapshot.tileWidth,
            tileHeight: snapshot.tileHeight,
            sources: [
              for (final descriptor in snapshot.sources)
                ResourcePackBuildSource(
                    path: descriptor.path,
                    byteLength: descriptor.byteLength,
                    rawSha256: descriptor.rawSha256,
                    mediaType: descriptor.mediaType,
                    openRead: () async* {
                      final aliases = bindings[descriptor.path]!;
                      for (final alias in aliases.skip(1)) {
                        await _verifyNativeAlias(
                            NativeResourcePackFile(
                                id: alias.handle,
                                logicalPath: descriptor.path,
                                byteLength: alias.byteLength,
                                rawSha256: alias.rawSha256,
                                mediaType: descriptor.mediaType,
                                openRead: () => _nativeChunks(
                                    sources[alias.handle]!,
                                    policy.maxChunkBytes)),
                            policy);
                      }
                      yield* _nativeChunks(
                          sources[aliases.first.handle]!, policy.maxChunkBytes);
                    })
            ],
            sink: sink);
        return (built.archiveBytes, built.archiveRawSha256);
      } on Object {
        await sink.abort();
        rethrow;
      } finally {
        await sink.close();
      }
    };

Stream<List<int>> _nativeChunks(
  RandomAccessPackageSource source,
  int chunk,
) async* {
  for (var offset = 0; offset < source.length; offset += chunk) {
    yield source.readAtSync(offset, min(chunk, source.length - offset));
  }
}

Set<String> Function() _requiredNativeFilesWorker(
  ProjectManifest manifest,
  List<NativeResourcePackRef> roots,
  List<(String, String, int, String, String)> files,
  List<String> patterns,
  ResourcePackSecurityPolicy policy,
) =>
    () {
      final projection = _Projection(
          manifest,
          [
            for (final file in files)
              NativeResourcePackFile(
                id: file.$1,
                logicalPath: file.$2,
                byteLength: file.$3,
                rawSha256: file.$4,
                mediaType: file.$5,
                openRead: _emptyNativeRead,
              ),
          ],
          policy);
      for (final root in roots) {
        projection.reference(root.kind.name, root.id);
      }
      for (final id in patterns) {
        projection.reference('smartTilePattern', id);
      }
      final inherited = _NativeAttributions(projection, null);
      projection.requireBudget();
      return {
        ...inherited.documentFileIds,
        for (final key in projection.completed.keys)
          if (projection.nodes[key]!.kind == 'file') projection.nodes[key]!.id,
      };
    };
Stream<List<int>> _emptyNativeRead() => const Stream.empty();

CatalogBudgetReport Function() _nativeSelectionBudgetWorker(
  ProjectManifest manifest,
  List<NativeResourcePackRef> roots,
  List<(String, String, int, String, String)> files,
  List<String> patterns,
  ResourcePackSecurityPolicy policy,
) => () {
  final projection = _Projection(manifest, [
    for (final file in files) NativeResourcePackFile(
      id: file.$1, logicalPath: file.$2, byteLength: file.$3,
      rawSha256: file.$4, mediaType: file.$5, openRead: _emptyNativeRead),
  ], policy);
  for (final root in roots) {
    projection.reference(root.kind.name, root.id);
  }
  for (final id in patterns) {
    projection.reference('smartTilePattern', id);
  }
  _NativeAttributions(projection, null);
  return projection.measureBudget();
};

ResourcePackBuildSource _documentAliases(
    List<ResourcePackBuildSource> aliases, ResourcePackSecurityPolicy policy) {
  final representative = aliases.first;
  if (aliases.any((source) =>
      source.path != representative.path ||
      source.rawSha256 != representative.rawSha256 ||
      source.byteLength != representative.byteLength ||
      source.mediaType != 'text/plain')) {
    _fail('license_document_changed');
  }
  return ResourcePackBuildSource(
      path: representative.path,
      byteLength: representative.byteLength,
      rawSha256: representative.rawSha256,
      mediaType: 'text/plain',
      openRead: () async* {
        for (final alias in aliases.skip(1)) {
          await _verifiedDocumentChunks(alias, policy).drain<void>();
        }
        yield* _verifiedDocumentChunks(representative, policy);
      });
}

final class ResourcePackExportException extends FormatException {
  ResourcePackExportException(String suffix)
      : code = 'resource_pack.$suffix',
        super('resource_pack.$suffix');
  final String code;
}

Never _failPrepared(String code) => throw ResourcePackExportException(code);
