import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/artifact_ref.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/authoring_receipt.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/artifact_store.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import '../assets/asset_actions.dart';
import '../assets/asset_store.dart';
import '../assets/raster_image_dimensions.dart';
import '../assets/tiled_image_collection_packer.dart';
import '../assets/tileset_actions.dart';
import 'map_lifecycle_adapter.dart';
import 'semantic_map_action_support.dart';

/// Canonical TMX map import boundary.
///
/// TMX, TSX and staged rasters are inputs only. Planning compiles the complete
/// native map and freezes every asset, blob, tileset and manifest change into
/// one recoverable authoring transaction.
final class TiledMapImportActions {
  const TiledMapImportActions({
    required this.artifactStore,
    this.imageCollectionRasterCodec,
  });

  final ArtifactStore artifactStore;
  final TiledImageCollectionRasterCodec? imageCollectionRasterCodec;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      visualLibraryDescriptor(
        'map.tiled.import',
        'Inspect and import one Tiled map as canonical PokeMap resources',
        resourceKinds: const <String>[
          'project',
          'map',
          'asset',
          'tileset',
        ],
      ),
    ],
  );

  Future<AuthoringMutationDraft> build(
    AuthoringPlanningContext context,
  ) async {
    final parameters = _TiledMapImportParameters(context.request.parameters)
      ..allow(const <String>{
        'mapId',
        'displayName',
        'groupId',
        'role',
        'tmx',
        'tilesets',
        'layerModes',
      });
    final mapId = _mapId(parameters.string('mapId'));
    final displayName = _mapName(parameters.string('displayName'));
    final groupId = parameters.optionalString('groupId');
    final role = _mapRole(parameters.optionalString('role') ?? 'exterior');
    final source = _parseMap(parameters.text('tmx'));
    final specs = _parseTilesetSpecs(parameters.list('tilesets'));
    final layerModes = _parseLayerModes(parameters.optionalMap('layerModes'));
    _requireExactTilesetClosure(source, specs);
    _requireAvailableMapTarget(
      context.snapshot.manifest,
      mapId: mapId,
      groupId: groupId,
    );

    final prepared = <_PreparedTiledTileset>[];
    for (final reference in source.tilesets) {
      final spec = specs.singleWhere(
        (candidate) => candidate.source == reference.source,
      );
      prepared.add(await _prepareTileset(spec, mapId: mapId));
    }
    _validateReferencedTileIds(source, prepared);

    final catalogBeforeBytes =
        context.snapshot.findResourceBytes(assetCatalogResourceIdentity);
    final catalogBefore = _decodeAssetCatalog(catalogBeforeBytes);
    final resolved = <_PreparedTiledTileset>[
      for (final item in prepared)
        _reuseExistingTileset(
          item,
          manifest: context.snapshot.manifest,
          catalog: catalogBefore,
          snapshot: context.snapshot,
        ),
    ];

    final TiledMapCompilationResult compilation;
    try {
      compilation = compileTiledMapDocument(
        source,
        mapId: mapId,
        mapName: displayName,
        gridPolicy: const TiledMapGridPolicy.adoptSource(),
        tilesets: <TiledMapTilesetBinding>[
          for (final item in resolved)
            TiledMapTilesetBinding(
              source: item.source,
              tilesetId: item.tileset.id,
            ),
        ],
        layerModes: layerModes,
      );
    } on TiledMapCompilationException catch (error) {
      throw semanticFailure(error.code, error.message, details: error.details);
    }

    var catalogAfter = catalogBefore;
    final assets = <AssetRecord>[];
    final bytesByAssetId = <String, List<int>>{};
    for (final item in resolved.where((item) => !item.isReused)) {
      for (final asset in item.assets) {
        final bytes = item.bytesByAssetId[asset.id]!;
        catalogAfter = const AssetImportProjector()
            .project(catalogAfter, record: asset)
            .catalog;
        assets.add(asset);
        bytesByAssetId[asset.id] = bytes;
      }
    }

    var projectedManifest = context.snapshot.manifest;
    for (final item in resolved.where((item) => !item.isReused)) {
      projectedManifest = const TilesetImportProjector().project(
        projectedManifest,
        assets: catalogAfter,
        tileset: item.tileset,
      );
    }
    final mapPath = 'maps/$mapId.json';
    projectedManifest = projectedManifest.copyWith(
      maps: <ProjectMapEntry>[
        ...projectedManifest.maps,
        ProjectMapEntry(
          id: mapId,
          name: displayName,
          relativePath: mapPath,
          groupId: groupId,
          role: role,
        ),
      ],
    );
    _validateProjectedState(
      manifest: projectedManifest,
      map: compilation.map,
    );
    final referencedTilesetIds = resolved
        .map((item) => item.tileset.id)
        .toSet()
        .toList(growable: false)
      ..sort();
    final referencedAssetIds = <String>{};
    for (final item in resolved) {
      switch (item.tileset.source) {
        case ProjectRegularAtlasTilesetSource source:
          referencedAssetIds.add(source.assetId);
        case ProjectImageCollectionTilesetSource source:
          referencedAssetIds.addAll(source.pages.map((page) => page.assetId));
        case null:
          break;
      }
    }
    final sortedReferencedAssetIds = referencedAssetIds.toList(growable: false)
      ..sort();

    return _projectTransaction(
      snapshot: context.snapshot,
      manifest: projectedManifest,
      map: compilation.map,
      mapPath: mapPath,
      assetsBefore: catalogBefore,
      assetsAfter: catalogAfter,
      importedAssets: assets,
      bytesByAssetId: bytesByAssetId,
      tilesets: <ProjectTilesetEntry>[
        for (final item in resolved)
          if (!item.isReused) item.tileset,
      ],
      referencedTilesetIds: referencedTilesetIds,
      referencedAssetIds: sortedReferencedAssetIds,
      report: compilation.report,
    );
  }

  Future<_PreparedTiledTileset> _prepareTileset(
    _TiledMapTilesetSpec spec, {
    required String mapId,
  }) async {
    final TiledTilesetDocument document;
    try {
      document = parseTiledTileset(spec.tsx);
    } on TiledTilesetImportException catch (error) {
      throw semanticFailure(error.code, error.message);
    }
    final artifacts = await _readExactArtifacts(
      spec.imageArtifacts,
      document.dependencyClosure.images,
    );
    return switch (document.layout) {
      final TiledRegularAtlasLayout layout => _prepareRegularAtlas(
          spec,
          document,
          layout,
          artifacts,
          mapId: mapId,
        ),
      TiledImageCollectionLayout() => _prepareImageCollection(
          spec,
          document,
          artifacts,
          mapId: mapId,
        ),
    };
  }

  Future<Map<String, _StagedTiledImage>> _readExactArtifacts(
    List<_TiledMapImageArtifact> supplied,
    List<TiledTilesetImageDependency> dependencies,
  ) async {
    final handlesBySource = <String, String>{
      for (final item in supplied) item.source: item.artifactHandle,
    };
    if (handlesBySource.length != supplied.length) {
      throw semanticFailure(
        'map.tiled.image_dependency_duplicate',
        'A TSX image dependency is staged more than once.',
      );
    }
    final expected = dependencies.map((item) => item.source).toSet();
    final missing = expected.difference(handlesBySource.keys.toSet()).toList()
      ..sort();
    final unknown = handlesBySource.keys.toSet().difference(expected).toList()
      ..sort();
    if (missing.isNotEmpty || unknown.isNotEmpty) {
      throw semanticFailure(
        'map.tiled.image_dependency_mismatch',
        'Staged images must exactly match the TSX dependency closure.',
        details: <String, Object?>{
          'missingSources': missing,
          'unknownSources': unknown,
        },
      );
    }

    final output = <String, _StagedTiledImage>{};
    for (final dependency in dependencies) {
      final handle = handlesBySource[dependency.source]!;
      final artifact = artifactStore.inspect(handle);
      if (artifact == null) {
        throw const ArtifactStoreException(
          'artifact.unknown',
          'A staged TMX image handle is unknown or has expired.',
        );
      }
      if (!artifact.mediaType.startsWith('image/')) {
        throw semanticFailure(
          'map.tiled.image_media_type_invalid',
          'Every TMX tileset dependency must be a raster image.',
          details: <String, Object?>{'source': dependency.source},
        );
      }
      final bytes = await artifactStore.read(artifact.handle);
      final exact = ContentArtifactRef.fromBytes(
        bytes,
        mediaType: artifact.mediaType,
      );
      if (exact.digest != artifact.digest ||
          exact.byteLength != artifact.byteLength) {
        throw semanticFailure(
          'map.tiled.image_artifact_mismatch',
          'A staged TMX image changed after inspection.',
          details: <String, Object?>{'source': dependency.source},
        );
      }
      output[dependency.source] = _StagedTiledImage(
        artifact: artifact,
        bytes: bytes,
      );
    }
    return Map<String, _StagedTiledImage>.unmodifiable(output);
  }

  _PreparedTiledTileset _prepareRegularAtlas(
    _TiledMapTilesetSpec spec,
    TiledTilesetDocument document,
    TiledRegularAtlasLayout layout,
    Map<String, _StagedTiledImage> staged, {
    required String mapId,
  }) {
    final image = staged[layout.image.source]!;
    final dimensions = decodeRasterImageDimensions(
      image.bytes,
      mediaType: image.artifact.mediaType,
    );
    if (dimensions == null ||
        dimensions.width != layout.image.pixelWidth ||
        dimensions.height != layout.image.pixelHeight) {
      throw semanticFailure(
        'map.tiled.image_dimensions_mismatch',
        'The decoded atlas dimensions do not match the TSX declaration.',
        details: <String, Object?>{'source': layout.image.source},
      );
    }
    final asset = AssetRecord(
      id: spec.assetId,
      logicalPath: spec.logicalPath,
      artifact: image.artifact,
      tags: const <String>['tiled', 'tmx-import'],
      usages: <String>['map:$mapId'],
    );
    final tileset = ProjectTilesetEntry(
      id: spec.tilesetId,
      name: document.name,
      relativePath: asset.logicalPath,
      transparentColor: layout.image.transparentColor,
      source: ProjectRegularAtlasTilesetSource(
        assetId: asset.id,
        pixelWidth: layout.image.pixelWidth,
        pixelHeight: layout.image.pixelHeight,
        tileWidth: document.tileWidth,
        tileHeight: document.tileHeight,
        marginX: layout.margin,
        marginY: layout.margin,
        spacingX: layout.spacing,
        spacingY: layout.spacing,
        pixelOffsetX: document.tileOffsetX,
        pixelOffsetY: document.tileOffsetY,
        tileAnimations: _regularAtlasAnimations(document),
      ),
    );
    return _PreparedTiledTileset(
      source: spec.source,
      document: document,
      tileset: tileset,
      assets: <AssetRecord>[asset],
      bytesByAssetId: <String, List<int>>{asset.id: image.bytes},
    );
  }

  _PreparedTiledTileset _prepareImageCollection(
    _TiledMapTilesetSpec spec,
    TiledTilesetDocument document,
    Map<String, _StagedTiledImage> staged, {
    required String mapId,
  }) {
    final codec = imageCollectionRasterCodec;
    if (codec == null) {
      throw semanticFailure(
        'map.tiled.image_codec_unavailable',
        'This authoring transport cannot pack TSX image collections.',
      );
    }
    late final TiledImageCollectionPackingResult packing;
    try {
      packing = TiledImageCollectionPacker(codec: codec).pack(
        <TiledImageCollectionPackingInput>[
          for (final dependency in document.dependencyClosure.images)
            TiledImageCollectionPackingInput(
              source: dependency.source,
              bytes: staged[dependency.source]!.bytes,
              declaredPixelWidth: dependency.pixelWidth,
              declaredPixelHeight: dependency.pixelHeight,
              transparentColor: dependency.transparentColor,
            ),
        ],
      );
    } on TiledImageCollectionPackingException catch (error) {
      throw semanticFailure(
        error.code,
        error.message,
        details: <String, Object?>{
          if (error.source != null) 'source': error.source,
        },
      );
    }
    final prefix = spec.logicalPath.replaceFirst(RegExp(r'/+$'), '');
    final assets = <AssetRecord>[
      for (final page in packing.pages)
        AssetRecord(
          id: '${spec.assetId}-${page.id}',
          logicalPath: '$prefix/${page.id}.png',
          artifact: page.artifact,
          tags: const <String>['tiled', 'tmx-import'],
          usages: <String>['map:$mapId'],
        ),
    ];
    final assetsByPageId = <String, AssetRecord>{
      for (var index = 0; index < packing.pages.length; index++)
        packing.pages[index].id: assets[index],
    };
    return _PreparedTiledTileset(
      source: spec.source,
      document: document,
      tileset: ProjectTilesetEntry(
        id: spec.tilesetId,
        name: document.name,
        relativePath: prefix,
        source: _imageCollectionSource(document, packing, assetsByPageId),
      ),
      assets: assets,
      bytesByAssetId: <String, List<int>>{
        for (var index = 0; index < packing.pages.length; index++)
          assets[index].id: packing.pages[index].bytes,
      },
    );
  }
}

_PreparedTiledTileset _reuseExistingTileset(
  _PreparedTiledTileset candidate, {
  required ProjectManifest manifest,
  required AssetCatalog catalog,
  required ProjectSnapshot snapshot,
}) {
  final candidateAssets = <String, AssetRecord>{
    for (final asset in candidate.assets) asset.id: asset,
  };
  final candidateIdentity = _tilesetSemanticIdentity(
    candidate.tileset,
    assetForId: (assetId) => candidateAssets[assetId],
  );
  if (candidateIdentity == null) return candidate;

  for (final existing in manifest.tilesets) {
    final existingIdentity = _tilesetSemanticIdentity(
      existing,
      assetForId: catalog.find,
    );
    if (existingIdentity == candidateIdentity &&
        _hasExactStoredAssets(existing, catalog, snapshot)) {
      return candidate.reuse(existing);
    }
  }
  return candidate;
}

String? _tilesetSemanticIdentity(
  ProjectTilesetEntry tileset, {
  required AssetRecord? Function(String assetId) assetForId,
}) {
  final source = tileset.source;
  if (source == null) return null;
  final sourceJson = Map<String, Object?>.from(source.toJson());

  switch (source) {
    case ProjectRegularAtlasTilesetSource():
      final asset = assetForId(source.assetId);
      if (asset == null) return null;
      sourceJson
        ..remove('assetId')
        ..['artifact'] = _artifactIdentity(asset);
    case ProjectImageCollectionTilesetSource():
      final pages = <Object?>[];
      for (final page in source.pages) {
        final asset = assetForId(page.assetId);
        if (asset == null) return null;
        pages.add(<String, Object?>{
          ...page.toJson(),
          'artifact': _artifactIdentity(asset),
        }..remove('assetId'));
      }
      sourceJson['pages'] = pages;
  }

  final tilesetJson = tileset.toJson();
  return jsonEncode(<String, Object?>{
    'source': sourceJson,
    'scope': tilesetJson['scope'],
    'groupId': tilesetJson['groupId'],
    'isWorldTileset': tilesetJson['isWorldTileset'],
    'transparentColor': tilesetJson['transparentColor'],
  });
}

Map<String, Object?> _artifactIdentity(AssetRecord asset) => <String, Object?>{
      'digest': asset.artifact.digest,
      'mediaType': asset.artifact.mediaType,
      'byteLength': asset.artifact.byteLength,
    };

bool _hasExactStoredAssets(
  ProjectTilesetEntry tileset,
  AssetCatalog catalog,
  ProjectSnapshot snapshot,
) {
  final source = tileset.source;
  if (source == null) return false;
  final assetIds = switch (source) {
    ProjectRegularAtlasTilesetSource() => <String>[source.assetId],
    ProjectImageCollectionTilesetSource() => <String>[
        for (final page in source.pages) page.assetId,
      ],
  };
  for (final assetId in assetIds) {
    final asset = catalog.find(assetId);
    if (asset == null) return false;
    final bytes = snapshot.findResourceBytes(
      assetBlobResourceIdentity(asset.artifact.digest),
    );
    if (bytes == null) return false;
    final exact = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: asset.artifact.mediaType,
    );
    if (exact.digest != asset.artifact.digest ||
        exact.byteLength != asset.artifact.byteLength) {
      return false;
    }
  }
  return true;
}

AuthoringMutationDraft _projectTransaction({
  required ProjectSnapshot snapshot,
  required ProjectManifest manifest,
  required MapData map,
  required String mapPath,
  required AssetCatalog assetsBefore,
  required AssetCatalog assetsAfter,
  required List<AssetRecord> importedAssets,
  required Map<String, List<int>> bytesByAssetId,
  required List<ProjectTilesetEntry> tilesets,
  required List<String> referencedTilesetIds,
  required List<String> referencedAssetIds,
  required TiledMapCompilationReport report,
}) {
  final changes = <AuthoringResourceChange>[];
  final diff = <AuthoringDiffEntry>[];
  if (importedAssets.isNotEmpty) {
    final catalogResource = AuthoringResourceRef(
      kind: 'assetCatalog',
      id: 'project',
      revision: snapshot.resourceFingerprints[assetCatalogResourceIdentity],
    );
    changes.add(
      AuthoringResourceChange(
        resource: catalogResource,
        storageKey: assetCatalogStorageKey,
        beforeBytes: snapshot.findResourceBytes(assetCatalogResourceIdentity),
        afterBytes: _encodeAssetCatalog(assetsAfter),
      ),
    );
    for (final asset in importedAssets) {
      diff.add(
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: catalogResource,
          path: '/records/${asset.id}',
          after: asset.toJson(),
        ),
      );
    }
  }

  final emittedDigests = <String>{};
  final existingDigests =
      assetsBefore.records.map((asset) => asset.artifact.digest).toSet();
  for (final asset in importedAssets) {
    final bytes = bytesByAssetId[asset.id]!;
    if (!emittedDigests.add(asset.artifact.digest)) continue;
    final existing = snapshot.findResourceBytes(
      assetBlobResourceIdentity(asset.artifact.digest),
    );
    if (existingDigests.contains(asset.artifact.digest)) {
      _requireExactBlob(asset, bytes, existing);
      continue;
    }
    if (existing != null) {
      throw AssetActionException(
        'asset.orphan_blob_conflict',
        'An unowned blob already occupies an imported TMX digest.',
        details: <String, Object?>{'digest': asset.artifact.digest},
      );
    }
    final resource = AuthoringResourceRef(
      kind: 'assetBlob',
      id: asset.artifact.digest,
    );
    changes.add(
      AuthoringResourceChange(
        resource: resource,
        storageKey: assetBlobStorageKey(asset.artifact),
        beforeBytes: null,
        afterBytes: bytes,
      ),
    );
    diff.add(
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.add,
        resource: resource,
        path: '/',
        after: asset.artifact.toJson(),
      ),
    );
  }

  final mapResource = AuthoringResourceRef(kind: 'map', id: map.id);
  changes.add(
    AuthoringResourceChange(
      resource: mapResource,
      storageKey: mapPath,
      beforeBytes: null,
      afterBytes: encodeMapAuthoringDocument(map),
    ),
  );
  diff.add(
    AuthoringDiffEntry(
      operation: AuthoringDiffOperation.add,
      resource: mapResource,
      path: '/',
      after: <String, Object?>{
        'id': map.id,
        'name': map.name,
        'width': map.size.width,
        'height': map.size.height,
        'layerCount': map.layers.length,
      },
    ),
  );

  final projectResource = AuthoringResourceRef(
    kind: 'project',
    id: 'project',
    revision: snapshot.resourceFingerprints['project'],
  );
  changes.add(
    AuthoringResourceChange(
      resource: projectResource,
      storageKey: 'project.json',
      beforeBytes: snapshot.resourceBytes('project'),
      afterBytes: encodeProjectAuthoringDocument(snapshot, manifest),
    ),
  );
  for (final tileset in tilesets) {
    diff.add(
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.add,
        resource: projectResource,
        path: '/tilesets/${tileset.id}',
        after: tileset.toJson(),
      ),
    );
  }
  final mapEntry = manifest.maps.singleWhere((entry) => entry.id == map.id);
  diff.add(
    AuthoringDiffEntry(
      operation: AuthoringDiffOperation.add,
      resource: projectResource,
      path: '/maps/${map.id}',
      after: mapEntry.toJson(),
    ),
  );
  final artifactAssetsByDigest = <String, AssetRecord>{};
  for (final asset in importedAssets) {
    artifactAssetsByDigest.putIfAbsent(asset.artifact.digest, () => asset);
  }

  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: changes,
      diff: AuthoringDiff(diff),
    ),
    preview: <String, Object?>{
      'operation': 'map.tiled.import',
      'mapId': map.id,
      'mapName': map.name,
      'width': map.size.width,
      'height': map.size.height,
      'layerCount': map.layers.length,
      'tileLayerCount': report.tileLayerCount,
      'compiledTileObjectCount': report.compiledTileObjectCount,
      'deferredObjectCount': report.deferredObjectCount,
      'dataLayerCount': report.dataLayerCount,
      'hiddenLayerCount': report.hiddenLayerCount,
      'ignoredLayerCount': report.ignoredLayerCount,
      'tilesetCount': tilesets.length,
      'assetCount': importedAssets.length,
      'fidelity': report.fidelity.name,
      'hasVisualLoss': report.hasVisualLoss,
      'diagnostics': <Map<String, Object?>>[
        for (final diagnostic in report.diagnostics)
          <String, Object?>{
            'code': diagnostic.code,
            'severity': diagnostic.severity.name,
            'message': diagnostic.message,
            if (diagnostic.sourceLayerId != null)
              'sourceLayerId': diagnostic.sourceLayerId,
            'details': diagnostic.details,
          },
      ],
      'changeCount': changes.length,
      'storageGuarantee': 'recoverable',
    },
    referenceImpact: <String, Object?>{
      'mapId': map.id,
      'tilesetIds': referencedTilesetIds,
      'assetIds': referencedAssetIds,
    },
    artifacts: <AuthoringArtifactRef>[
      for (final asset in artifactAssetsByDigest.values)
        AuthoringArtifactRef(
          id: asset.artifact.digest,
          mediaType: asset.artifact.mediaType,
          uri: asset.artifact.handle,
          byteLength: asset.artifact.byteLength,
          sha256: asset.artifact.digest,
        ),
    ],
  );
}

void _validateProjectedState({
  required ProjectManifest manifest,
  required MapData map,
}) {
  try {
    ProjectValidator.validate(manifest);
    MapValidator.validate(map, projectDialogueContext: manifest);
  } on Object catch (error) {
    throw semanticFailure(
      'map.tiled.projected_state_invalid',
      'The imported TMX bundle would invalidate the PokeMap project.',
      details: <String, Object?>{
        'validationType': error.runtimeType.toString(),
        'validationMessage': error.toString(),
      },
    );
  }
}

void _requireExactBlob(
  AssetRecord asset,
  List<int> expected,
  List<int>? existing,
) {
  if (existing == null || !_sameBytes(existing, expected)) {
    throw AssetActionException(
      'asset.deduplicated_blob_mismatch',
      'A deduplicated TMX artifact does not match its stored blob.',
      details: <String, Object?>{'digest': asset.artifact.digest},
    );
  }
  final exact = ContentArtifactRef.fromBytes(
    existing,
    mediaType: asset.artifact.mediaType,
  );
  if (exact.digest != asset.artifact.digest ||
      exact.byteLength != asset.artifact.byteLength) {
    throw AssetActionException(
      'asset.deduplicated_blob_mismatch',
      'A deduplicated TMX artifact does not match its catalog identity.',
      details: <String, Object?>{'digest': asset.artifact.digest},
    );
  }
}

AssetCatalog _decodeAssetCatalog(List<int>? bytes) {
  if (bytes == null) return AssetCatalog();
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException();
    return AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
  } on Object {
    throw AssetActionException(
      'asset.catalog_invalid',
      'The current project asset catalog is invalid.',
    );
  }
}

List<int> _encodeAssetCatalog(AssetCatalog catalog) => List<int>.unmodifiable(
      utf8.encode(
        '${const JsonEncoder.withIndent('  ').convert(catalog.toJson())}\n',
      ),
    );

TiledMapDocument _parseMap(String source) {
  try {
    return parseTiledMap(source);
  } on TiledMapImportException catch (error) {
    throw semanticFailure(error.code, error.message);
  }
}

void _requireExactTilesetClosure(
  TiledMapDocument document,
  List<_TiledMapTilesetSpec> specs,
) {
  final expected = document.tilesets.map((item) => item.source).toSet();
  final actual = specs.map((item) => item.source).toSet();
  if (actual.length != specs.length ||
      expected.length != specs.length ||
      !expected.containsAll(actual)) {
    final missing = expected.difference(actual).toList()..sort();
    final unknown = actual.difference(expected).toList()..sort();
    throw semanticFailure(
      'map.tiled.tileset_dependency_mismatch',
      'TSX inputs must exactly match the TMX dependency closure.',
      details: <String, Object?>{
        'missingSources': missing,
        'unknownSources': unknown,
      },
    );
  }
}

void _validateReferencedTileIds(
  TiledMapDocument map,
  List<_PreparedTiledTileset> tilesets,
) {
  final documents = <String, TiledTilesetDocument>{
    for (final item in tilesets) item.source: item.document,
  };
  void validateTile(TiledMapTileReference tile) {
    final document = documents[tile.tileset.source]!;
    final valid = switch (document.layout) {
      TiledRegularAtlasLayout() => tile.localTileId < document.tileCount,
      TiledImageCollectionLayout() =>
        document.tiles.containsKey(tile.localTileId),
    };
    if (!valid) {
      throw semanticFailure(
        'map.tiled.tile_id_out_of_range',
        'The TMX references a tile identity absent from its TSX.',
        details: <String, Object?>{
          'source': tile.tileset.source,
          'localTileId': tile.localTileId,
        },
      );
    }
  }

  void visit(TiledMapLayer layer) {
    switch (layer) {
      case TiledMapTileLayer():
        for (final tile in layer.cells) {
          if (tile != null) {
            validateTile(tile);
          }
        }
      case TiledMapObjectLayer():
        for (final object in layer.objects) {
          if (object.tile case final tile?) {
            validateTile(tile);
          }
        }
      case TiledMapGroupLayer():
        for (final child in layer.layers) {
          visit(child);
        }
    }
  }

  for (final layer in map.layers) {
    visit(layer);
  }
}

void _requireAvailableMapTarget(
  ProjectManifest manifest, {
  required String mapId,
  required String? groupId,
}) {
  if (manifest.maps.any((entry) => entry.id.toLowerCase() == mapId)) {
    throw semanticFailure(
      'map.id_conflict',
      'A map already owns the requested import identity.',
      details: <String, Object?>{'mapId': mapId},
    );
  }
  final path = 'maps/$mapId.json';
  if (manifest.maps.any(
    (entry) => entry.relativePath.toLowerCase() == path.toLowerCase(),
  )) {
    throw semanticFailure(
      'map.path_conflict',
      'A map already owns the requested import document path.',
      details: <String, Object?>{'mapId': mapId},
    );
  }
  if (groupId != null && !manifest.groups.any((group) => group.id == groupId)) {
    throw semanticFailure(
      'map.group_missing',
      'The requested map group does not exist.',
      details: <String, Object?>{'groupId': groupId},
    );
  }
}

String _mapId(String value) {
  if (value.length > 64 ||
      !RegExp(r'^[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?$').hasMatch(value) ||
      _windowsReservedMapIds.contains(value)) {
    throw semanticFailure(
      'map.id_invalid',
      'Map IDs must be portable lowercase filename-safe identifiers.',
      details: <String, Object?>{'mapId': value},
    );
  }
  return value;
}

String _mapName(String value) {
  if (value.length > 160) {
    throw semanticFailure(
      'map.name_invalid',
      'Map names must contain at most 160 characters.',
    );
  }
  return value;
}

MapRole _mapRole(String value) {
  for (final role in MapRole.values) {
    if (role.name == value) return role;
  }
  throw semanticFailure(
    'map.role_invalid',
    'The requested map role is unsupported.',
    details: <String, Object?>{'role': value},
  );
}

List<_TiledMapTilesetSpec> _parseTilesetSpecs(List<Object?> values) =>
    List<_TiledMapTilesetSpec>.unmodifiable(
      <_TiledMapTilesetSpec>[
        for (var index = 0; index < values.length; index++)
          _TiledMapTilesetSpec.fromJson(values[index], index),
      ],
    );

ProjectImageCollectionTilesetSource _imageCollectionSource(
  TiledTilesetDocument document,
  TiledImageCollectionPackingResult packing,
  Map<String, AssetRecord> assetsByPageId,
) {
  final tiles = document.tiles.values.toList()
    ..sort((left, right) => left.tileId.compareTo(right.tileId));
  return ProjectImageCollectionTilesetSource(
    pages: <ProjectImageCollectionPage>[
      for (final page in packing.pages)
        ProjectImageCollectionPage(
          id: page.id,
          assetId: assetsByPageId[page.id]!.id,
          pixelWidth: page.pixelWidth,
          pixelHeight: page.pixelHeight,
        ),
    ],
    tileDefinitions: <ProjectImageCollectionTileDefinition>[
      for (final tile in tiles) _imageCollectionTile(document, packing, tile),
    ],
    properties: _projectProperties(document.properties),
  );
}

ProjectImageCollectionTileDefinition _imageCollectionTile(
  TiledTilesetDocument document,
  TiledImageCollectionPackingResult packing,
  TiledTileMetadata tile,
) {
  final image = tile.image;
  if (image == null) {
    throw semanticFailure(
      'map.tiled.image_reference_missing',
      'Every image collection tile must reference one image.',
      details: <String, Object?>{'tileId': tile.tileId},
    );
  }
  final placement = packing.placementForSource(image.source);
  return ProjectImageCollectionTileDefinition(
    tileId: tile.tileId,
    pageId: placement.pageId,
    sourceRect: placement.sourceRect,
    offsetX: document.tileOffsetX,
    offsetY: document.tileOffsetY,
    animation: <ProjectImageCollectionAnimationFrame>[
      for (final frame in tile.animation)
        ProjectImageCollectionAnimationFrame(
          tileId: frame.tileId,
          durationMs: frame.durationMs,
        ),
    ],
    properties: <ProjectTilesetProperty>[
      ..._projectProperties(tile.properties),
      if (tile.probability != 1)
        ProjectTilesetProperty(
          name: 'tiled:probability',
          type: ProjectTilesetPropertyType.decimal,
          value: tile.probability,
        ),
    ],
    collisionObjects: <ProjectTilesetCollisionObject>[
      for (final object in tile.collisionObjects)
        ProjectTilesetCollisionObject(
          id: object.id,
          name: object.name,
          type: object.className,
          shape: _projectCollisionShape(object.shape),
          x: object.x,
          y: object.y,
          width: object.width,
          height: object.height,
          rotation: object.rotation,
          points: <ProjectTilesetPixelPoint>[
            for (final point in object.points)
              ProjectTilesetPixelPoint(x: point.x, y: point.y),
          ],
          properties: _projectProperties(object.properties),
        ),
    ],
  );
}

List<ProjectTilesetProperty> _projectProperties(
  Iterable<TiledProperty> properties,
) =>
    List<ProjectTilesetProperty>.unmodifiable(
      properties.map(
        (property) => ProjectTilesetProperty(
          name: property.name,
          type: _projectPropertyType(property.type),
          value: _projectPropertyValue(property),
          customType: property.customType,
        ),
      ),
    );

Object? _projectPropertyValue(TiledProperty property) =>
    property.type == TiledPropertyValueType.structured
        ? <String, Object?>{
            for (final member in property.members)
              member.name: _projectPropertyValue(member),
          }
        : property.value;

ProjectTilesetPropertyType _projectPropertyType(TiledPropertyValueType type) =>
    switch (type) {
      TiledPropertyValueType.string => ProjectTilesetPropertyType.string,
      TiledPropertyValueType.integer => ProjectTilesetPropertyType.integer,
      TiledPropertyValueType.decimal => ProjectTilesetPropertyType.decimal,
      TiledPropertyValueType.boolean => ProjectTilesetPropertyType.boolean,
      TiledPropertyValueType.color => ProjectTilesetPropertyType.color,
      TiledPropertyValueType.file => ProjectTilesetPropertyType.assetReference,
      TiledPropertyValueType.object =>
        ProjectTilesetPropertyType.objectReference,
      TiledPropertyValueType.structured =>
        ProjectTilesetPropertyType.structured,
    };

ProjectTilesetCollisionShape _projectCollisionShape(
  TiledCollisionShape shape,
) =>
    switch (shape) {
      TiledCollisionShape.rectangle => ProjectTilesetCollisionShape.rectangle,
      TiledCollisionShape.ellipse => ProjectTilesetCollisionShape.ellipse,
      TiledCollisionShape.polygon => ProjectTilesetCollisionShape.polygon,
      TiledCollisionShape.polyline => ProjectTilesetCollisionShape.polyline,
      TiledCollisionShape.point => ProjectTilesetCollisionShape.point,
    };

final class _PreparedTiledTileset {
  const _PreparedTiledTileset({
    required this.source,
    required this.document,
    required this.tileset,
    required this.assets,
    required this.bytesByAssetId,
    this.isReused = false,
  });

  final String source;
  final TiledTilesetDocument document;
  final ProjectTilesetEntry tileset;
  final List<AssetRecord> assets;
  final Map<String, List<int>> bytesByAssetId;
  final bool isReused;

  _PreparedTiledTileset reuse(ProjectTilesetEntry existing) =>
      _PreparedTiledTileset(
        source: source,
        document: document,
        tileset: existing,
        assets: const <AssetRecord>[],
        bytesByAssetId: const <String, List<int>>{},
        isReused: true,
      );
}

final class _StagedTiledImage {
  const _StagedTiledImage({required this.artifact, required this.bytes});

  final ContentArtifactRef artifact;
  final List<int> bytes;
}

final class _TiledMapTilesetSpec {
  const _TiledMapTilesetSpec({
    required this.source,
    required this.tsx,
    required this.tilesetId,
    required this.assetId,
    required this.logicalPath,
    required this.imageArtifacts,
  });

  factory _TiledMapTilesetSpec.fromJson(Object? value, int index) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw semanticFailure(
        'map.tiled.tileset_input_invalid',
        'Every TMX tileset input must be a JSON object.',
        details: <String, Object?>{'tilesetIndex': index},
      );
    }
    final parameters = _TiledMapImportParameters(
      Map<String, Object?>.from(value),
    )..allow(const <String>{
        'source',
        'tsx',
        'tilesetId',
        'assetId',
        'logicalPath',
        'imageArtifacts',
      });
    final artifacts = <_TiledMapImageArtifact>[];
    final rawArtifacts = parameters.list('imageArtifacts');
    for (var artifactIndex = 0;
        artifactIndex < rawArtifacts.length;
        artifactIndex++) {
      artifacts.add(
        _TiledMapImageArtifact.fromJson(
          rawArtifacts[artifactIndex],
          tilesetIndex: index,
          artifactIndex: artifactIndex,
        ),
      );
    }
    return _TiledMapTilesetSpec(
      source: parameters.string('source'),
      tsx: parameters.text('tsx'),
      tilesetId: parameters.string('tilesetId'),
      assetId: parameters.string('assetId'),
      logicalPath: parameters.string('logicalPath'),
      imageArtifacts: List<_TiledMapImageArtifact>.unmodifiable(artifacts),
    );
  }

  final String source;
  final String tsx;
  final String tilesetId;
  final String assetId;
  final String logicalPath;
  final List<_TiledMapImageArtifact> imageArtifacts;
}

final class _TiledMapImageArtifact {
  const _TiledMapImageArtifact({
    required this.source,
    required this.artifactHandle,
  });

  factory _TiledMapImageArtifact.fromJson(
    Object? value, {
    required int tilesetIndex,
    required int artifactIndex,
  }) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw semanticFailure(
        'map.tiled.image_artifact_invalid',
        'Every TMX image artifact must be a JSON object.',
        details: <String, Object?>{
          'tilesetIndex': tilesetIndex,
          'artifactIndex': artifactIndex,
        },
      );
    }
    final parameters = _TiledMapImportParameters(
      Map<String, Object?>.from(value),
    )..allow(const <String>{'source', 'artifactHandle'});
    return _TiledMapImageArtifact(
      source: parameters.string('source'),
      artifactHandle: parameters.string('artifactHandle'),
    );
  }

  final String source;
  final String artifactHandle;
}

final class _TiledMapImportParameters {
  _TiledMapImportParameters(Map<String, Object?> values)
      : _values = Map<String, Object?>.unmodifiable(values);

  final Map<String, Object?> _values;

  void allow(Set<String> allowed) {
    final unknown = _values.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw semanticFailure(
        'map.tiled.parameter_unknown',
        'The TMX import contains unsupported parameters.',
        details: <String, Object?>{'parameters': unknown},
      );
    }
  }

  String string(String key) {
    final value = _values[key];
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw semanticFailure(
        'map.tiled.parameter_invalid',
        'A required TMX import parameter is invalid.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }

  String text(String key) {
    final value = _values[key];
    if (value is! String || value.trim().isEmpty) {
      throw semanticFailure(
        'map.tiled.parameter_invalid',
        'A required TMX import document is invalid.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }

  String? optionalString(String key) {
    final value = _values[key];
    return value == null ? null : string(key);
  }

  List<Object?> list(String key) {
    final value = _values[key];
    if (value is! List) {
      throw semanticFailure(
        'map.tiled.parameter_invalid',
        'A required TMX import list is invalid.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return List<Object?>.unmodifiable(value);
  }

  Map<String, Object?>? optionalMap(String key) {
    final value = _values[key];
    if (value == null) return null;
    if (value is! Map) {
      throw semanticFailure(
        'map.tiled.parameter_invalid',
        'An optional TMX import object is invalid.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return Map<String, Object?>.unmodifiable(
      value.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}

Map<int, TiledMapLayerImportMode> _parseLayerModes(
  Map<String, Object?>? raw,
) {
  if (raw == null) return const <int, TiledMapLayerImportMode>{};
  final modes = <int, TiledMapLayerImportMode>{};
  for (final entry in raw.entries) {
    final layerId = int.tryParse(entry.key);
    final value = entry.value;
    final mode = switch (value) {
      'render' => TiledMapLayerImportMode.render,
      'data' => TiledMapLayerImportMode.data,
      'hidden' => TiledMapLayerImportMode.hidden,
      'ignore' => TiledMapLayerImportMode.ignore,
      _ => null,
    };
    if (layerId == null ||
        layerId < 0 ||
        '$layerId' != entry.key ||
        mode == null) {
      throw semanticFailure(
        'map.tiled.layer_mode_invalid',
        'Every TMX layer mode must use a canonical source layer ID and a supported value.',
        details: <String, Object?>{
          'sourceLayerId': entry.key,
          'mode': value,
        },
      );
    }
    modes[layerId] = mode;
  }
  return Map<int, TiledMapLayerImportMode>.unmodifiable(modes);
}

List<ProjectRegularAtlasTileAnimation> _regularAtlasAnimations(
  TiledTilesetDocument document,
) =>
    <ProjectRegularAtlasTileAnimation>[
      for (final tile in document.tiles.values)
        if (tile.animation.isNotEmpty)
          ProjectRegularAtlasTileAnimation(
            tileId: tile.tileId,
            frames: <ProjectImageCollectionAnimationFrame>[
              for (final frame in tile.animation)
                ProjectImageCollectionAnimationFrame(
                  tileId: frame.tileId,
                  durationMs: frame.durationMs,
                ),
            ],
          ),
    ];

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

const Set<String> _windowsReservedMapIds = <String>{
  'con',
  'prn',
  'aux',
  'nul',
  'com1',
  'com2',
  'com3',
  'com4',
  'com5',
  'com6',
  'com7',
  'com8',
  'com9',
  'lpt1',
  'lpt2',
  'lpt3',
  'lpt4',
  'lpt5',
  'lpt6',
  'lpt7',
  'lpt8',
  'lpt9',
};
