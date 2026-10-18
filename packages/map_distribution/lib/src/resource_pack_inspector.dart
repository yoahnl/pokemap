import 'dart:convert';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:image/image.dart' as img;

import 'canonical_json.dart';
import 'catalog_budget_report.dart';
import 'game_package_format_exception.dart';
import 'game_package_security_policy.dart';
import 'glb_model3d_inspector.dart';
import 'random_access_package_source.dart';
import 'random_access_zip_structure_reader.dart';
import 'raster_image_dimensions.dart';
import 'resource_pack_manifest_codec.dart';
import 'resource_pack_security_policy.dart';
import 'strict_json_structure_validator.dart';
import 'static_png_validation.dart';

final class ResourcePackInspection {
  ResourcePackInspection(
      {required this.manifest,
      required this.catalog,
      required this.archiveRawSha256,
      required this.archiveBytes,
      required this.manifestBytes,
      required this.payloadBytes,
      required this.fileCount,
      required this.resourceCount,
      required this.supportCount,
      required this.provenanceStatus,
      required Map<String, Model3dInspection> modelInspections,
      this.budgetReport,
      Map<String, RasterImageDimensions> imageDimensions = const {}})
      : modelInspections = Map.unmodifiable(modelInspections),
        imageDimensions = Map.unmodifiable(imageDimensions);
  final ResourcePackManifest manifest;
  final ResourcePackCatalog catalog;
  final String archiveRawSha256;
  final int archiveBytes;
  final int manifestBytes;
  final int payloadBytes;
  final int fileCount;
  final int resourceCount;
  final int supportCount;
  final ResourcePackProvenanceStatus provenanceStatus;
  final Map<String, Model3dInspection> modelInspections;
  final Map<String, RasterImageDimensions> imageDimensions;
  final CatalogBudgetReport? budgetReport;
}

abstract final class ResourcePackCapabilities {
  static const supported = <String>{
    'images.png',
    'models.glb',
    'resources.element',
    'resources.model3d',
    'resources.smart-tile-preset',
    'resources.tileset',
    'resources.border-blueprint',
    'resources.environment-preset',
    'resources.character',
    'smart_tiles.patterns',
  };
  static List<String> requiredFor(
      ResourcePackCatalog catalog, Iterable<ResourcePackInventoryFile> files) {
    final capabilities = <String>{
      if (files.any((f) => f.mediaType == 'image/png')) 'images.png',
      if (files.any((f) => f.mediaType == 'model/gltf-binary')) 'models.glb',
      if (catalog.elements.isNotEmpty) 'resources.element',
      if (catalog.models3d.isNotEmpty) 'resources.model3d',
      if (catalog.smartTileCatalog.presets.isNotEmpty)
        'resources.smart-tile-preset',
      if (catalog.tilesets.isNotEmpty) 'resources.tileset',
      if (catalog.borderCatalog.records.isNotEmpty)
        'resources.border-blueprint',
      if (catalog.environmentPresets.isNotEmpty) 'resources.environment-preset',
      if (catalog.characters.isNotEmpty) 'resources.character',
      if (catalog.smartTileCatalog.patterns.isNotEmpty) 'smart_tiles.patterns',
    };
    return List.unmodifiable(capabilities.toList()..sort());
  }
}

final class ResourcePackInspector {
  const ResourcePackInspector(
      {this.policy = const ResourcePackSecurityPolicy()});
  final ResourcePackSecurityPolicy policy;

  ResourcePackInspection inspectSourceSync(RandomAccessPackageSource source) {
    try {
      return _inspect(source);
    } on GamePackageFormatException catch (error) {
      if (error.code.startsWith('resource_pack.')) rethrow;
      _fail(error.code, error.path, error.message);
    } on FormatException {
      _fail('catalog_invalid', 'catalog.json',
          'The portable catalog or its dependencies are invalid.');
    } on ResourcePackDependencyException {
      _fail('reference_invalid', 'catalog.json',
          'A catalog dependency is missing or cyclic.');
    }
  }

  ResourcePackInspection _inspect(RandomAccessPackageSource source) {
    final length = source.length;
    if (length < 0 || length > policy.maxArchiveBytes) {
      _fail('archive_too_large', r'$', 'The archive exceeds its byte limit.',
          budgetReport:
              length < 0 ? null : _partialBudgetReport(archiveBytes: length));
    }
    final structure = RandomAccessZipStructureReader(
      const GamePackageSecurityPolicy(),
      entryNameValidator: _validateName,
      maxTotalEntries: policy.maxZipEntries,
      readChunkBytes: policy.maxChunkBytes,
    ).read(source);
    final entries = {for (final e in structure.entries) e.name: e};
    final manifestEntry = entries['manifest.json'];
    if (manifestEntry == null) {
      _fail('manifest_missing', 'manifest.json',
          'The archive must contain its manifest.');
    }
    if (manifestEntry.size > policy.maxManifestBytes) {
      _fail('manifest_too_large', 'manifest.json',
          'The manifest exceeds its byte limit.',
          budgetReport: _partialBudgetReport(
              archiveBytes: length, manifestBytes: manifestEntry.size));
    }
    final manifestPayload = _stream(source, manifestEntry, collect: true);
    late final ResourcePackManifest manifest;
    try {
      manifest = ResourcePackManifestCodec(policy: policy)
          .decodeUtf8(manifestPayload.bytes);
    } on GamePackageFormatException catch (error) {
      if (error.code != 'resource_pack.json_complexity') rethrow;
      final partial = _partialBudgetReport(
          archiveBytes: length, manifestBytes: manifestEntry.size);
      throw GamePackageFormatException(
          code: error.code,
          path: error.path,
          message: error.message,
          relatedCodes: error.relatedCodes,
          details: {
            'budgetReport': _jsonGuardReport(partial, 'manifest.json')
                .toBoundedJson(maximumBytes: 96 * 1024)
          });
    }
    final declared = manifest.compatibility.requiredCapabilities;
    if (declared.any((c) => !ResourcePackCapabilities.supported.contains(c))) {
      _fail('capability_mismatch', 'manifest.json',
          'The pack requires an unsupported capability.');
    }
    final inventory = <String, ResourcePackInventoryFile>{
      manifest.content.catalog.path: manifest.content.catalog,
      for (final file in manifest.content.files) file.path: file,
    };
    if (entries.keys.any(
        (name) => name != 'manifest.json' && !inventory.containsKey(name))) {
      _fail('unlisted_file', r'$',
          'The archive contains a file absent from the inventory.');
    }
    if (inventory.keys.any((name) => !entries.containsKey(name))) {
      _fail('missing_file', r'$',
          'An inventoried file is absent from the archive.');
    }
    for (final file in inventory.values) {
      if (entries[file.path]!.size != file.byteLength) {
        _fail('size_mismatch', file.path,
            'The ZIP entry and manifest declare different byte lengths.');
      }
    }
    final partialBudget = _partialBudgetReport(
        archiveBytes: length,
        manifestBytes: manifestEntry.size,
        inventory: inventory.values);
    if (manifest.content.catalog.byteLength > policy.maxCatalogBytes) {
      final content = _stream(source, entries['catalog.json']!);
      if (content.rawSha256 != manifest.content.catalog.rawSha256) {
        _fail('hash_mismatch', 'catalog.json',
            'The raw SHA-256 differs from the inventoried digest.');
      }
      _fail('catalog_too_large', 'catalog.json',
          'The catalog exceeds its byte limit.',
          budgetReport: partialBudget);
    }
    if (resourcePackTreeSha256(
            manifest.content.catalog, manifest.content.files) !=
        manifest.content.treeSha256) {
      _fail('tree_mismatch', 'manifest.json',
          'The content tree digest does not match the inventory.');
    }
    final catalogPayload =
        _stream(source, entries['catalog.json']!, collect: true);
    if (catalogPayload.rawSha256 != manifest.content.catalog.rawSha256) {
      _fail('hash_mismatch', 'catalog.json',
          'The raw SHA-256 differs from the inventoried digest.');
    }
    final json = _decodeJson(catalogPayload.bytes, 'catalog.json',
        budgetReport: partialBudget);
    if (json is! Map<String, dynamic>) {
      _fail('catalog_invalid', 'catalog.json',
          'The portable catalog must be an object.');
    }
    _validateHierarchies(json, enforceLimits: false);
    final catalog = ResourcePackCatalog.fromJson(json);
    final graph = ResourcePackDependencyGraph.fromCatalog(catalog);
    final closure = graph.validateAll();
    final resources = closure.resources.length;
    final builtinFamilies = ResourceLibraryCatalog.predefinedFamilies
        .map((family) => family.id)
        .toSet();
    final explicitFamilies = catalog.resourceLibraryCatalog.families
        .map((family) => family.id)
        .toSet();
    builtinFamilies.removeAll(explicitFamilies);
    final supports = closure.supports
        .where((support) =>
            support.kind != ResourcePackSupportKind.resourceFamily ||
            !builtinFamilies.contains(support.id))
        .length;
    final measuredBudget = CatalogBudgetCalculator(resourcePackPolicy: policy)
        .measureResourcePack(catalog,
            archiveBytes: length,
            manifestBytes: manifestEntry.size,
            files: [
          for (final file in manifest.content.files)
            CatalogBudgetFile(
                path: file.path,
                byteLength: file.byteLength,
                isPreview: file.path.startsWith('previews/')),
        ]);
    final rawJsonBudget = const CatalogBudgetCalculator().measureJsonDocument(
        json,
        scope: 'resourcePack',
        maxBytes: policy.maxCatalogBytes,
        maxNodes: policy.maxJsonNodes,
        maxDepth: policy.maxJsonDepth);
    final budgetMetrics = <(String, String), CatalogBudgetMetric>{
      for (final metric in measuredBudget.metrics)
        (metric.scope, metric.dimension): metric,
      for (final metric in rawJsonBudget.metrics)
        (metric.scope, metric.dimension): metric,
      for (final metric in partialBudget.metrics)
        (metric.scope, metric.dimension): metric,
    };
    final budgetReport = CatalogBudgetReport(
        scope: 'resourcePack',
        metrics: budgetMetrics.values,
        totals: {
          ...measuredBudget.totals,
          ...rawJsonBudget.totals,
          ...partialBudget.totals
        },
        breakdown: measuredBudget.breakdown,
        omittedBreakdownEntries: measuredBudget.omittedBreakdownEntries,
        unknownDimensions: measuredBudget.unknownDimensions);
    _validateHierarchies(json, budgetReport: budgetReport);
    var payloadBytes = 0;
    var previews = 0;
    for (final file in inventory.values) {
      if (file.path != 'catalog.json' &&
          file.byteLength > policy.maxFileBytes) {
        _fail('file_too_large', file.path,
            'The payload exceeds its individual byte limit.',
            budgetReport: budgetReport);
      }
      if (file.path.endsWith('.glb') && file.byteLength > 128 * 1024 * 1024) {
        _fail('model_too_large', file.path,
            'The GLB exceeds the native 128 MiB limit.');
      }
      payloadBytes += file.byteLength;
      if (payloadBytes > policy.maxTotalPayloadBytes) {
        _fail('payload_too_large', r'$',
            'The useful payload exceeds its cumulative byte limit.',
            budgetReport: budgetReport);
      }
      if (file.path.startsWith('previews/')) {
        previews++;
        if (file.byteLength > policy.maxPreviewBytes ||
            previews > policy.maxPreviewFiles) {
          _fail('preview_limit', file.path,
              'The preview byte or count quota is exceeded.',
              budgetReport: budgetReport);
        }
      }
    }
    if (resources > policy.maxResources) {
      _fail('resource_limit', 'catalog.json', 'The resource quota is exceeded.',
          budgetReport: budgetReport);
    }
    if (supports > policy.maxSupports) {
      _fail('support_limit', 'catalog.json',
          'The support and pattern quota is exceeded.',
          budgetReport: budgetReport);
    }
    final imageBounds = <String, RasterImageDimensions>{};
    for (final file in manifest.content.files) {
      final content = _stream(source, entries[file.path]!,
          collect: file.mediaType == 'image/png',
          text: file.mediaType == 'text/plain');
      if (content.rawSha256 != file.rawSha256) {
        _fail('hash_mismatch', file.path,
            'The raw SHA-256 differs from the inventoried digest.');
      }
      if (file.mediaType == 'image/png') {
        imageBounds[file.path] = _inspectPngDimensions(file.path, content.bytes,
            budgetReport: budgetReport);
      }
    }
    final calculated =
        ResourcePackCapabilities.requiredFor(catalog, manifest.content.files);
    if (declared.length != calculated.length ||
        Iterable<int>.generate(declared.length)
            .any((i) => declared[i] != calculated[i])) {
      _fail('capability_mismatch', 'manifest.json',
          'Required capabilities must exactly describe the portable definitions and media.');
    }
    _validateBindings(catalog, inventory);
    _validateNativeSemantics(catalog, manifest.compatibility);
    _validateNativeMedia(catalog, manifest.compatibility, imageBounds);
    _validateSnapshots(catalog, entries, source);
    final modelInspections = <String, Model3dInspection>{};
    final bindingsById = {
      for (final binding in catalog.files) binding.id: binding
    };
    final modelsByPath = <String, List<ProjectModel3dEntry>>{};
    for (final model in catalog.models3d) {
      final path = bindingsById[model.sourceAssetId]!.archivePath;
      modelsByPath.putIfAbsent(path, () => []).add(model);
    }
    for (final file in manifest.content.files
        .where((file) => file.mediaType == 'model/gltf-binary')) {
      final content = _stream(source, entries[file.path]!, collect: true);
      if (content.rawSha256 != file.rawSha256) {
        _fail('hash_mismatch', file.path, 'The GLB changed during inspection.');
      }
      final bytes = content.bytes;
      if (bytes.length < 28) {
        _fail('model_invalid', file.path,
            'A complete standalone GLB is required.');
      }
      final data = ByteData.sublistView(bytes);
      final jsonLength = data.getUint32(12, Endian.little);
      if (jsonLength > 8 * 1024 * 1024 || jsonLength + 20 > bytes.length) {
        _fail('model_invalid', file.path,
            'The GLB JSON chunk exceeds its native bounds.');
      }
      _decodeJson(Uint8List.sublistView(bytes, 20, 20 + jsonLength), file.path);
      late final Model3dInspection actual;
      try {
        actual = GlbModel3dInspector(
                requireStaticTextures: true,
                maxTextureDimension: math.min(policy.maxImageDimension, 4096),
                maxTexturePixels: math.min(policy.maxImagePixels, 16777216))
            .inspect(bytes);
      } on Object {
        _fail('model_invalid', file.path,
            'The GLB is invalid, external, or exceeds native media bounds.');
      }
      modelInspections[file.path] = actual;
      for (final model
          in modelsByPath[file.path] ?? const <ProjectModel3dEntry>[]) {
        if (model.inspection != actual) {
          _fail('model_inspection_mismatch', file.path,
              'The announced model inspection differs from the verified geometry.');
        }
      }
    }
    if (source.length != length) {
      _fail('source_changed', r'$', 'The archive changed during inspection.');
    }
    final rawSha256 = _hashSource(source, length);
    if (source.length != length) {
      _fail('source_changed', r'$',
          'The archive changed while the receipt was created.');
    }
    final measuredImageDimensions = {
      for (final path in imageBounds.keys) '$path.imageDimensions',
    };
    final imagePixels = imageBounds.values.fold<int>(
        0, (total, dimensions) => total + dimensions.width * dimensions.height);
    final finalBudgetReport = CatalogBudgetReport(
        scope: budgetReport.scope,
        metrics: [
          ...budgetReport.metrics,
          for (final entry in imageBounds.entries)
            ..._imageMetrics(entry.key, entry.value)
        ],
        totals: {
          ...budgetReport.totals,
          'imagePixels': imagePixels,
          'rgba8BytesEstimate': imagePixels * 4
        },
        breakdown: budgetReport.breakdown,
        omittedBreakdownEntries: budgetReport.omittedBreakdownEntries,
        unknownDimensions: budgetReport.unknownDimensions.where(
            (dimension) => !measuredImageDimensions.contains(dimension)));
    final attributedResources =
        catalog.provenance.expand((entry) => entry.resources).toSet();
    return ResourcePackInspection(
        manifest: manifest,
        catalog: catalog,
        archiveRawSha256: rawSha256,
        archiveBytes: length,
        manifestBytes: manifestEntry.size,
        payloadBytes: payloadBytes,
        fileCount: inventory.length,
        resourceCount: resources,
        supportCount: supports,
        provenanceStatus: catalog.smartTilePatternIds.isEmpty &&
                closure.resources.isNotEmpty &&
                closure.resources.every(attributedResources.contains)
            ? ResourcePackProvenanceStatus.declared
            : ResourcePackProvenanceStatus.unqualified,
        modelInspections: modelInspections,
        imageDimensions: imageBounds,
        budgetReport: finalBudgetReport);
  }

  CatalogBudgetReport _jsonGuardReport(
          CatalogBudgetReport report, String path) =>
      CatalogBudgetReport(
          scope: report.scope,
          metrics: [
            ...report.metrics,
            CatalogBudgetMetric(
                scope: path,
                dimension: 'jsonComplexityGuard',
                observed: 1,
                allowed: 0,
                unit: 'refus',
                label: 'Garde de complexité JSON déclenchée',
                remedy: 'Réduire la complexité du document JSON.')
          ],
          totals: report.totals,
          unknownDimensions: report.unknownDimensions);

  CatalogBudgetReport _partialBudgetReport(
      {required int archiveBytes,
      int? manifestBytes,
      Iterable<ResourcePackInventoryFile>? inventory}) {
    final metrics = <CatalogBudgetMetric>[];
    final totals = <String, int?>{};
    final unknown = <String>{
      'jsonNodes',
      'jsonDepth',
      'resources',
      'supports',
      'hierarchies',
      'publishedFiles'
    };
    void add(
        String scope, String dimension, int observed, int allowed, String label,
        {String unit = 'octets'}) {
      metrics.add(CatalogBudgetMetric(
          scope: scope,
          dimension: dimension,
          observed: observed,
          allowed: allowed,
          unit: unit,
          label: label,
          remedy: 'Réduire la sélection ou la complexité du pack.'));
      if (scope == 'resourcePack') totals[dimension] = observed;
    }

    add('resourcePack', 'archiveBytes', archiveBytes, policy.maxArchiveBytes,
        'Taille de l’archive');
    if (manifestBytes == null) {
      unknown.add('manifestBytes');
    } else {
      add('resourcePack', 'manifestBytes', manifestBytes,
          policy.maxManifestBytes, 'Taille du manifeste');
    }
    if (inventory == null) {
      unknown.addAll(['catalogBytes', 'payloadBytes', 'files']);
    } else {
      var payloadBytes = 0;
      var previews = 0;
      final files = inventory.toList();
      for (final file in files) {
        payloadBytes += file.byteLength;
        if (file.path == 'catalog.json') {
          add('resourcePack', 'catalogBytes', file.byteLength,
              policy.maxCatalogBytes, 'Taille du catalogue JSON');
        } else {
          add(file.path, 'fileBytes', file.byteLength, policy.maxFileBytes,
              'Taille du fichier');
        }
        if (file.path.startsWith('previews/')) {
          previews++;
          add(file.path, 'previewBytes', file.byteLength,
              policy.maxPreviewBytes, 'Taille de l’aperçu');
        }
        if (file.mediaType == 'image/png') {
          unknown.add('${file.path}.imageDimensions');
        }
      }
      add('resourcePack', 'payloadBytes', payloadBytes,
          policy.maxTotalPayloadBytes, 'Charge utile');
      add('resourcePack', 'zipEntries', files.length + 1, policy.maxZipEntries,
          'Entrées ZIP',
          unit: 'unités');
      add('resourcePack', 'previewFiles', previews, policy.maxPreviewFiles,
          'Aperçus',
          unit: 'unités');
    }
    return CatalogBudgetReport(
        scope: 'resourcePack',
        metrics: metrics,
        totals: totals,
        unknownDimensions: unknown);
  }

  void _validateHierarchies(Map<String, dynamic> json,
      {CatalogBudgetReport? budgetReport, bool enforceLimits = true}) {
    void hierarchy(Object? value, String parent) {
      if (value is! List) return;
      if (enforceLimits && value.length > policy.maxHierarchyEntries) {
        _fail('hierarchy_limit', 'catalog.json',
            'A native hierarchy exceeds its entry limit.',
            budgetReport: budgetReport);
      }
      final parents = <String, String?>{};
      for (final item in value) {
        if (item is Map &&
            item['id'] is String &&
            (item[parent] == null || item[parent] is String)) {
          parents[item['id'] as String] = item[parent] as String?;
        }
      }
      if (!enforceLimits) {
        final completed = <String>{};
        for (final id in parents.keys) {
          final active = <String>{};
          String? current = id;
          while (current != null &&
              parents.containsKey(current) &&
              !completed.contains(current)) {
            if (!active.add(current)) {
              _fail('hierarchy_limit', 'catalog.json',
                  'A native hierarchy is cyclic or exceeds its depth limit.');
            }
            current = parents[current];
          }
          completed.addAll(active);
        }
        return;
      }
      for (final id in parents.keys) {
        final seen = <String>{};
        String? current = id;
        while (current != null && parents.containsKey(current)) {
          if (!seen.add(current) || seen.length > policy.maxHierarchyDepth) {
            _fail('hierarchy_limit', 'catalog.json',
                'A native hierarchy is cyclic or exceeds its depth limit.',
                budgetReport: budgetReport);
          }
          current = parents[current];
        }
      }
    }

    hierarchy(json['tilesetFolders'], 'parentFolderId');
    hierarchy(json['elementCategories'], 'parentCategoryId');
    final library = json['resourceLibraryCatalog'];
    if (library is Map) hierarchy(library['families'], 'parentId');
    final tilesets = json['tilesets'];
    if (tilesets is List) {
      for (final tile in tilesets) {
        if (tile is Map) hierarchy(tile['elementGroups'], 'parentGroupId');
      }
    }
  }

  void _validateSnapshots(
      ResourcePackCatalog catalog,
      Map<String, RandomAccessZipStructureEntry> entries,
      RandomAccessPackageSource source) {
    final bindings = {
      for (final binding in catalog.files) binding.logicalPath: binding
    };
    for (final snapshot in catalog.borderCatalog.visualSnapshots) {
      try {
        BorderSnapshotContentFrame decode(int index) {
          final frame = snapshot.frames[index];
          final binding = bindings[frame.relativeAssetPath];
          if (binding == null || binding.mediaType != 'image/png') {
            _fail('snapshot_invalid', frame.relativeAssetPath,
                'A snapshot frame must resolve to its verified PNG binding.');
          }
          final content =
              _stream(source, entries[binding.archivePath]!, collect: true);
          if (content.rawSha256 != binding.rawSha256) {
            _fail('hash_mismatch', binding.archivePath,
                'The snapshot PNG changed during inspection.');
          }
          final decoded = _decodeStaticPng(binding.archivePath, content.bytes);
          final rect = frame.sourceRectPx;
          if (rect.x < 0 ||
              rect.y < 0 ||
              rect.right > decoded.width ||
              rect.bottom > decoded.height) {
            _fail('snapshot_invalid', binding.archivePath,
                'The snapshot source rectangle exceeds its decoded PNG.');
          }
          checkedBorderRleCellCount(width: rect.width, height: rect.height);
          final rgba = Uint8List(rect.width * rect.height * 4);
          final transparent = frame.transparentColorArgb == null
              ? null
              : frame.transparentColorArgb! & 0xffffff;
          for (var y = 0; y < rect.height; y++) {
            for (var x = 0; x < rect.width; x++) {
              final pixel = decoded.getPixel(rect.x + x, rect.y + y);
              final offset = (y * rect.width + x) * 4;
              final r = pixel.r.toInt(),
                  g = pixel.g.toInt(),
                  b = pixel.b.toInt();
              rgba[offset] = r;
              rgba[offset + 1] = g;
              rgba[offset + 2] = b;
              rgba[offset + 3] =
                  transparent == (r << 16 | g << 8 | b) ? 0 : pixel.a.toInt();
            }
          }
          return BorderSnapshotContentFrame(
              sourceRectPx: rect,
              durationMs: frame.durationMs,
              transparentColorArgb: frame.transparentColorArgb,
              rgbaBytes: rgba);
        }

        final actual = computeBorderSnapshotContentFingerprint(
            frames: _DecodedSnapshotFrames(snapshot.frames.length, decode));
        if (actual != snapshot.contentFingerprint) {
          _fail('snapshot_invalid', 'catalog.json',
              'The snapshot fingerprint differs from its verified pixels and frame metadata.');
        }
      } on GamePackageFormatException {
        rethrow;
      } on Object {
        _fail('snapshot_invalid', 'catalog.json',
            'The snapshot PNG or native frame metadata is invalid.');
      }
    }
  }

  void _validateNativeSemantics(
      ResourcePackCatalog catalog, ResourcePackCompatibility compatibility) {
    final projection = ProjectManifest(
      name: 'Resource pack validation',
      version: ProjectVersion.v9,
      maps: const [],
      tilesets: catalog.tilesets,
      elements: catalog.elements,
      models3d: catalog.models3d,
      characters: catalog.characters,
      smartTileCatalog: catalog.smartTileCatalog,
      borderCatalog: catalog.borderCatalog,
      environmentPresets: catalog.environmentPresets,
      resourceLibraryCatalog: catalog.resourceLibraryCatalog,
      elementCategories: catalog.elementCategories,
      tilesetFolders: catalog.tilesetFolders,
      characterStudioCatalog: catalog.characterStudioCatalog,
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
          tileWidth: compatibility.tileWidth,
          tileHeight: compatibility.tileHeight),
    );
    try {
      ProjectValidator.validate(projection);
    } on ValidationException {
      _fail('native_invalid', 'catalog.json',
          'A portable definition violates the native resource semantics.');
    }
  }

  void _validateBindings(ResourcePackCatalog catalog,
      Map<String, ResourcePackInventoryFile> inventory) {
    for (final binding in catalog.files) {
      final file = inventory[binding.archivePath];
      if (file == null ||
          file.rawSha256 != binding.rawSha256 ||
          file.byteLength != binding.byteLength ||
          file.mediaType != binding.mediaType) {
        _fail('binding_mismatch', binding.archivePath,
            'A portable file binding differs from its inventory entry.');
      }
    }
    for (final license in {
      ...catalog.files.expand((f) => f.licenseIds),
      ...catalog.provenance.expand((p) => p.licenseIds)
    }) {
      final file = inventory[license];
      if (file == null ||
          !license.startsWith('licenses/') ||
          file.mediaType != 'text/plain') {
        _fail('license_missing', license,
            'A licence must resolve to an inventoried UTF-8 text document.');
      }
    }
  }

  void _validateNativeMedia(
      ResourcePackCatalog catalog,
      ResourcePackCompatibility compatibility,
      Map<String, RasterImageDimensions> imageBounds) {
    final bindings = {for (final file in catalog.files) file.id: file};
    final tilesets = {for (final tile in catalog.tilesets) tile.id: tile};
    RasterImageDimensions png(String id, {int? width, int? height}) {
      final binding = bindings[id];
      if (binding == null || binding.mediaType != 'image/png') {
        _fail('media_mismatch', id,
            'This native source requires a PNG file binding.');
      }
      final dimensions = imageBounds[binding.archivePath];
      if (dimensions == null ||
          width != null && dimensions.width != width ||
          height != null && dimensions.height != height) {
        _fail('image_dimensions_mismatch', binding.archivePath,
            'The PNG dimensions differ from the native source definition.');
      }
      return dimensions;
    }

    ProjectRegularAtlasTilesetSource raster(String id) {
      final source = tilesets[id]?.source;
      if (source is! ProjectRegularAtlasTilesetSource) {
        _fail('media_mismatch', id,
            'A rectangular raster frame requires a regular atlas source.');
      }
      return source;
    }

    void grid(String id, TilesetSourceRect rect) {
      final source = raster(id);
      if (rect.x < 0 ||
          rect.y < 0 ||
          rect.width < 1 ||
          rect.height < 1 ||
          rect.x + rect.width > source.columns ||
          rect.y + rect.height > source.rows) {
        _fail('frame_out_of_bounds', id,
            'The visual frame exceeds the canonical atlas cell grid.');
      }
    }

    void pixels(String id, TilesetSourceRect rect) {
      final image = png(id);
      if (rect.x < 0 ||
          rect.y < 0 ||
          rect.width < 1 ||
          rect.height < 1 ||
          rect.x + rect.width > image.width ||
          rect.y + rect.height > image.height) {
        _fail('frame_out_of_bounds', id,
            'The dedicated animation frame exceeds its verified PNG pixels.');
      }
    }

    for (final tile in catalog.tilesets) {
      switch (tile.source) {
        case ProjectRegularAtlasTilesetSource(
            :final assetId,
            :final pixelWidth,
            :final pixelHeight,
            :final tileWidth,
            :final tileHeight
          ):
          if (tileWidth != compatibility.tileWidth ||
              tileHeight != compatibility.tileHeight) {
            _fail('cell_dimensions_mismatch', 'catalog.json',
                'The atlas cell size differs from pack compatibility.');
          }
          png(assetId, width: pixelWidth, height: pixelHeight);
        case ProjectImageCollectionTilesetSource(:final pages):
          for (final page in pages) {
            png(page.assetId, width: page.pixelWidth, height: page.pixelHeight);
          }
        case null:
          _fail('media_mismatch', 'catalog.json',
              'A portable tileset requires a native source.');
      }
      for (final entry in tile.paletteEntries) {
        for (final frame in entry.frames) {
          grid(frame.tilesetId.isEmpty ? tile.id : frame.tilesetId,
              frame.source);
        }
      }
    }
    for (final element in catalog.elements) {
      for (final frame in element.frames) {
        grid(frame.tilesetId.isEmpty ? element.tilesetId : frame.tilesetId,
            frame.source);
      }
    }
    for (final character in catalog.characters) {
      for (final portrait in character.portraits) {
        png(portrait.assetId);
      }
      for (final animation in character.animations) {
        for (final frame in animation.frames) {
          final assetId = animation.sourceAssetId;
          if (assetId == null) {
            final atlas = raster(character.tilesetId);
            final image = png(atlas.assetId);
            final width = character.frameWidth.clamp(2, 1 << 20) *
                compatibility.tileWidth;
            final height = character.frameHeight.clamp(2, 1 << 20) *
                compatibility.tileHeight;
            if (frame.source.x < 0 ||
                frame.source.y < 0 ||
                frame.source.x >= image.width ~/ width ||
                frame.source.y >= image.height ~/ height) {
              _fail('frame_out_of_bounds', character.id,
                  'The effective character-grid frame exceeds its verified PNG pixels.');
            }
          } else {
            pixels(assetId, frame.source);
          }
        }
      }
      for (final animation in character.customAnimations) {
        for (final frame in animation.frames) {
          pixels(animation.sourceAssetId, frame.source);
        }
      }
    }
    for (final atlas in catalog.smartTileCatalog.atlases) {
      final source = raster(atlas.tilesetId);
      final image = png(source.assetId);
      final width = image.width - atlas.originX - atlas.marginX;
      final height = image.height - atlas.originY - atlas.marginY;
      if (atlas.columns < 1 ||
          atlas.rows < 1 ||
          atlas.cellWidth < 1 ||
          atlas.cellHeight < 1 ||
          atlas.originX < 0 ||
          atlas.originY < 0 ||
          atlas.marginX < 0 ||
          atlas.marginY < 0 ||
          atlas.spacingX < 0 ||
          atlas.spacingY < 0 ||
          width < atlas.cellWidth ||
          height < atlas.cellHeight ||
          atlas.columns >
              (width + atlas.spacingX) ~/ (atlas.cellWidth + atlas.spacingX) ||
          atlas.rows >
              (height + atlas.spacingY) ~/
                  (atlas.cellHeight + atlas.spacingY)) {
        _fail('frame_out_of_bounds', atlas.id,
            'The Smart Tile atlas grid exceeds its verified raster pixels.');
      }
    }
    for (final model in catalog.models3d) {
      if (bindings[model.sourceAssetId]?.mediaType != 'model/gltf-binary') {
        _fail('media_mismatch', model.relativePath,
            'A model source requires a standalone GLB binding.');
      }
    }
  }

  RasterImageDimensions _inspectPngDimensions(String path, Uint8List bytes,
      {CatalogBudgetReport? budgetReport}) {
    final decoded = _decodeStaticPng(path, bytes, budgetReport: budgetReport);
    return RasterImageDimensions(width: decoded.width, height: decoded.height);
  }

  img.Image _decodeStaticPng(String path, Uint8List bytes,
      {CatalogBudgetReport? budgetReport}) {
    _validatePng(path, bytes, budgetReport: budgetReport);
    try {
      final decoder = validatedStaticPngDecoder(bytes,
          maxDimension: policy.maxImageDimension,
          maxPixels: policy.maxImagePixels);
      final decoded = decoder.decodeFrame(0);
      final dimensions =
          decodeRasterImageDimensions(bytes, mediaType: 'image/png')!;
      if (decoded == null ||
          decoded.width != dimensions.width ||
          decoded.height != dimensions.height) {
        _fail('image_invalid', path,
            'The PNG payload cannot be decoded completely.');
      }
      return decoded;
    } on GamePackageFormatException {
      rethrow;
    } on Object {
      _fail('image_invalid', path, 'The PNG payload is corrupt or incomplete.');
    }
  }

  List<CatalogBudgetMetric> _imageMetrics(
          String path, RasterImageDimensions dimensions) =>
      [
        CatalogBudgetMetric(
            scope: path,
            dimension: 'imageWidth',
            observed: dimensions.width,
            allowed: policy.maxImageDimension,
            unit: 'pixels',
            label: 'Largeur de l’image',
            remedy: 'Réduire la largeur de l’image.'),
        CatalogBudgetMetric(
            scope: path,
            dimension: 'imageHeight',
            observed: dimensions.height,
            allowed: policy.maxImageDimension,
            unit: 'pixels',
            label: 'Hauteur de l’image',
            remedy: 'Réduire la hauteur de l’image.'),
        CatalogBudgetMetric(
            scope: path,
            dimension: 'imagePixels',
            observed: dimensions.width * dimensions.height,
            allowed: policy.maxImagePixels,
            unit: 'pixels',
            label: 'Surface de l’image',
            remedy: 'Réduire les dimensions de l’image.'),
        CatalogBudgetMetric(
            scope: path,
            dimension: 'rgba8BytesEstimate',
            observed: dimensions.width * dimensions.height * 4,
            unit: 'octets',
            label:
                'Estimation de surface RGBA8, hors mémoire réelle du processus',
            remedy: 'Mesure informative.'),
      ];

  CatalogBudgetReport _imageBudgetReport(CatalogBudgetReport? report,
      String path, RasterImageDimensions dimensions) {
    return CatalogBudgetReport(
        scope: report?.scope ?? 'resourcePack',
        metrics: [...?report?.metrics, ..._imageMetrics(path, dimensions)],
        totals: report?.totals ?? const {},
        breakdown: report?.breakdown ?? const [],
        omittedBreakdownEntries: report?.omittedBreakdownEntries ?? 0,
        unknownDimensions: (report?.unknownDimensions ??
                ['resources', 'supports', 'catalogBytes'])
            .where((dimension) => dimension != '$path.imageDimensions'));
  }

  void _validatePng(String path, Uint8List header,
      {CatalogBudgetReport? budgetReport}) {
    final dimensions =
        decodeRasterImageDimensions(header, mediaType: 'image/png');
    if (dimensions == null) {
      _fail('media_mismatch', path,
          'The payload does not have a valid PNG header.');
    }
    if (dimensions.width > policy.maxImageDimension ||
        dimensions.height > policy.maxImageDimension ||
        dimensions.width * dimensions.height > policy.maxImagePixels) {
      _fail('image_limit', path,
          'The decoded image dimensions exceed native pixel bounds.',
          budgetReport: _imageBudgetReport(budgetReport, path, dimensions));
    }
  }

  Object? _decodeJson(List<int> bytes, String path,
      {CatalogBudgetReport? budgetReport}) {
    late final String text;
    try {
      text = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      _fail('invalid_utf8', path, 'The document must contain valid UTF-8.');
    }
    try {
      const StrictJsonStructureValidator().validate(text,
          path: path,
          maxDepth: policy.maxJsonDepth,
          maxNodes: policy.maxJsonNodes,
          duplicateCode: 'resource_pack.json_duplicate_key');
      final value = jsonDecode(text);
      CanonicalJson.encode(value);
      return value;
    } on GamePackageFormatException catch (error) {
      if (error.code == 'resource_pack.json_duplicate_key') rethrow;
      _fail(
          error.code == 'entryTooLarge' ? 'json_complexity' : 'invalid_json',
          path,
          'The JSON document is malformed or exceeds its complexity bounds.',
          budgetReport: error.code == 'entryTooLarge' && budgetReport != null
              ? _jsonGuardReport(budgetReport, path)
              : null);
    } on FormatException {
      _fail('invalid_json', path, 'The JSON document contains invalid values.');
    }
  }

  ({String rawSha256, Uint8List bytes}) _stream(
      RandomAccessPackageSource source, RandomAccessZipStructureEntry entry,
      {bool collect = false, bool text = false}) {
    final digest = _DigestSink();
    final hash = sha256.startChunkedConversion(digest);
    final buffer = BytesBuilder(copy: false);
    final decoder = text
        ? const Utf8Decoder(allowMalformed: false)
            .startChunkedConversion(const _DiscardText())
        : null;
    var crc = 0;
    var collected = 0;
    for (var offset = 0; offset < entry.size;) {
      final bytes = _read(source, entry.dataOffset + offset,
          math.min(policy.maxChunkBytes, entry.size - offset));
      hash.add(bytes);
      crc = getCrc32(bytes, crc);
      try {
        decoder?.add(bytes);
      } on FormatException {
        _fail('invalid_utf8', entry.name,
            'A licence document contains invalid UTF-8.');
      }
      final take = collect
          ? bytes.length
          : math.min(bytes.length, math.max(0, 33 - collected));
      if (take > 0) {
        buffer.add(Uint8List.sublistView(bytes, 0, take));
        collected += take;
      }
      offset += bytes.length;
    }
    try {
      decoder?.close();
    } on FormatException {
      _fail('invalid_utf8', entry.name,
          'A licence document ends with incomplete UTF-8.');
    }
    hash.close();
    if (crc != entry.crc32) {
      _fail('crc_mismatch', entry.name,
          'The ZIP CRC differs from its verified payload.');
    }
    return (rawSha256: digest.value, bytes: buffer.takeBytes());
  }

  String _hashSource(RandomAccessPackageSource source, int length) {
    final result = _DigestSink();
    final sink = sha256.startChunkedConversion(result);
    for (var offset = 0; offset < length; offset += policy.maxChunkBytes) {
      sink.add(_read(
          source, offset, math.min(policy.maxChunkBytes, length - offset)));
    }
    sink.close();
    return result.value;
  }

  Uint8List _read(RandomAccessPackageSource source, int offset, int length) {
    final output = Uint8List(length);
    for (var copied = 0; copied < length;) {
      final count = math.min(policy.maxChunkBytes, length - copied);
      final part = source.readAtSync(offset + copied, count);
      if (part.length != count) {
        _fail('source_changed', r'$', 'A bounded source read was truncated.');
      }
      output.setRange(copied, copied + count, part);
      copied += count;
    }
    return output;
  }
}

void _validateName(String name) {
  if (name == 'manifest.json' ||
      name == 'catalog.json' ||
      RegExp(r'^blobs/[a-f0-9]{64}\.(png|glb)$').hasMatch(name) ||
      RegExp(r'^licenses/[a-f0-9]{64}\.txt$').hasMatch(name) ||
      RegExp(r'^previews/[a-f0-9]{64}\.png$').hasMatch(name)) {
    return;
  }
  _fail('path_invalid', name,
      'The entry is outside the exact portable asset pack layout.');
}

final class _DigestSink implements Sink<Digest> {
  String? _value;
  String get value => _value ?? (throw StateError('Digest unfinished.'));
  @override
  void add(Digest value) {
    _value = value.toString();
  }

  @override
  void close() {}
}

final class _DiscardText implements Sink<String> {
  const _DiscardText();
  @override
  void add(String value) {}
  @override
  void close() {}
}

Never _fail(String code, String path, String message,
        {CatalogBudgetReport? budgetReport}) =>
    throw GamePackageFormatException(
        code: 'resource_pack.$code',
        path: path,
        message: message,
        details: budgetReport == null
            ? null
            : {
                'budgetReport':
                    budgetReport.toBoundedJson(maximumBytes: 96 * 1024)
              });

final class _DecodedSnapshotFrames
    extends ListBase<BorderSnapshotContentFrame> {
  _DecodedSnapshotFrames(this.length, this.decode);
  @override
  final int length;
  final BorderSnapshotContentFrame Function(int index) decode;
  @override
  set length(int value) => throw UnsupportedError('Immutable snapshot frames.');
  @override
  BorderSnapshotContentFrame operator [](int index) => decode(index);
  @override
  void operator []=(int index, BorderSnapshotContentFrame value) =>
      throw UnsupportedError('Immutable snapshot frames.');
}
