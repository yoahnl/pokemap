import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/artifact_ref.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/authoring_receipt.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import '../maps/map_lifecycle_adapter.dart';
import '../maps/smart_tile_native_transition_guard.dart';
import '../maps/smart_tile_tiled_wang_projection.dart';
import 'asset_actions.dart';
import 'asset_store.dart';
import 'raster_image_dimensions.dart';
import 'tileset_actions.dart';

/// Builds the complete immutable projection for a regular Tiled tileset.
///
/// This object does not invoke another authoring action and performs no I/O.
/// It composes three pure projectors, then emits one multi-resource draft for
/// the canonical transaction engine.
final class TiledTilesetImportProjector {
  const TiledTilesetImportProjector();

  AuthoringMutationDraft project({
    required ProjectSnapshot snapshot,
    required AssetRecord asset,
    required List<int> imageBytes,
    required ProjectTilesetEntry tileset,
    required TiledWangImportBundle wangBundle,
    required String importId,
  }) {
    final actualArtifact = ContentArtifactRef.fromBytes(
      imageBytes,
      mediaType: asset.artifact.mediaType,
    );
    if (actualArtifact.digest != asset.artifact.digest ||
        actualArtifact.byteLength != asset.artifact.byteLength) {
      throw AssetActionException(
        'asset.artifact_mismatch',
        'The staged image bytes do not match the inspected artifact.',
        details: <String, Object?>{'assetId': asset.id},
      );
    }
    final dimensions = decodeRasterImageDimensions(
      imageBytes,
      mediaType: asset.artifact.mediaType,
    );
    final source = tileset.source;
    if (dimensions == null ||
        source is! ProjectRegularAtlasTilesetSource ||
        source.pixelWidth != dimensions.width ||
        source.pixelHeight != dimensions.height ||
        source.tileWidth != wangBundle.atlas.cellWidth ||
        source.tileHeight != wangBundle.atlas.cellHeight ||
        source.marginX != wangBundle.atlas.marginX ||
        source.marginY != wangBundle.atlas.marginY ||
        source.spacingX != wangBundle.atlas.spacingX ||
        source.spacingY != wangBundle.atlas.spacingY ||
        source.pixelOffsetX != wangBundle.atlas.pixelOffsetX ||
        source.pixelOffsetY != wangBundle.atlas.pixelOffsetY ||
        source.columns != wangBundle.atlas.columns ||
        source.rows != wangBundle.atlas.rows) {
      throw VisualLibraryException(
        'tileset.tiled.image_geometry_mismatch',
        'The TSX grid and decoded image geometry must match exactly.',
        details: <String, Object?>{
          'tilesetId': tileset.id,
          if (dimensions != null) ...<String, Object?>{
            'decodedWidth': dimensions.width,
            'decodedHeight': dimensions.height,
          },
        },
      );
    }

    final catalogBeforeBytes =
        snapshot.findResourceBytes(assetCatalogResourceIdentity);
    final catalogBefore = _decodeAssetCatalog(catalogBeforeBytes);
    final assetProjection = const AssetImportProjector().project(
      catalogBefore,
      record: asset,
    );
    final catalogAfter = assetProjection.catalog;

    if (snapshot.manifest.tilesets.any((entry) => entry.id == tileset.id)) {
      throw VisualLibraryException(
        'tileset.id_conflict',
        'A canonical tileset already owns this identity.',
        details: <String, Object?>{'tilesetId': tileset.id},
      );
    }

    final withTileset = const TilesetImportProjector().project(
      snapshot.manifest,
      assets: catalogAfter,
      tileset: tileset,
    );
    final projectedManifest = const TiledWangImportProjector().project(
      withTileset,
      assets: catalogAfter,
      imageBytes: imageBytes,
      bundle: wangBundle,
    );
    try {
      ProjectValidator.validate(projectedManifest);
    } on Object catch (error) {
      throw VisualLibraryException(
        'visual.projected_state_invalid',
        'The Tiled tileset import would invalidate the project.',
        details: <String, Object?>{
          'validationType': error.runtimeType.toString(),
        },
      );
    }
    preflightNativeSmartTileMutation(
      snapshot: snapshot,
      projectedManifest: projectedManifest,
    );

    final changes = <AuthoringResourceChange>[
      AuthoringResourceChange(
        resource: AuthoringResourceRef(
          kind: 'assetCatalog',
          id: 'project',
          revision: snapshot.resourceFingerprints[assetCatalogResourceIdentity],
        ),
        storageKey: assetCatalogStorageKey,
        beforeBytes: catalogBeforeBytes,
        afterBytes: _encodeAssetCatalog(catalogAfter),
      ),
    ];
    final diff = <AuthoringDiffEntry>[
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.add,
        resource: changes.single.resource,
        path: '/records/${asset.id}',
        after: asset.toJson(),
      ),
    ];

    final existingBlob = snapshot.findResourceBytes(
      assetBlobResourceIdentity(asset.artifact.digest),
    );
    if (!assetProjection.deduplicated) {
      if (existingBlob != null) {
        throw AssetActionException(
          'asset.orphan_blob_conflict',
          'An unowned blob already occupies the imported artifact digest.',
          details: <String, Object?>{'digest': asset.artifact.digest},
        );
      }
      final blobResource = AuthoringResourceRef(
        kind: 'assetBlob',
        id: asset.artifact.digest,
      );
      changes.add(
        AuthoringResourceChange(
          resource: blobResource,
          storageKey: assetBlobStorageKey(asset.artifact),
          beforeBytes: null,
          afterBytes: imageBytes,
        ),
      );
      diff.add(
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: blobResource,
          path: '/',
          after: asset.artifact.toJson(),
        ),
      );
    } else {
      _validateDeduplicatedBlob(asset, imageBytes, existingBlob);
    }

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
        afterBytes: encodeProjectAuthoringDocument(
          snapshot,
          projectedManifest,
        ),
      ),
    );
    diff.add(
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: projectResource,
        path: '/tilesets/${tileset.id}',
        after: <String, Object?>{
          'tileset': tileset.toJson(),
          'wang': wangBundle.toJson(),
        },
      ),
    );

    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: changes,
        diff: AuthoringDiff(diff),
      ),
      preview: <String, Object?>{
        'operation': 'tileset.tiled.import',
        'importId': importId,
        'assetId': asset.id,
        'tilesetId': tileset.id,
        'atlasId': wangBundle.atlas.id,
        'presetCount': wangBundle.presets.length,
        'changeCount': changes.length,
        'blobDeduplicated': assetProjection.deduplicated,
      },
      referenceImpact: <String, Object?>{
        'assetId': asset.id,
        'tilesetId': tileset.id,
        'smartTileResourceIds': <String>[
          wangBundle.atlas.id,
          ...wangBundle.materials.map((item) => item.id),
          ...wangBundle.animations.map((item) => item.id),
          ...wangBundle.presets.map((item) => item.id),
        ],
      },
      artifacts: <AuthoringArtifactRef>[
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

  AuthoringMutationDraft deleteWangBundle({
    required ProjectSnapshot snapshot,
    required String importId,
  }) {
    final normalizedImportId = importId.trim();
    if (normalizedImportId.isEmpty || normalizedImportId != importId) {
      throw VisualLibraryException(
        'tileset.tiled.bundle_id_invalid',
        'The Tiled Wang bundle identity is invalid.',
      );
    }
    final manifest = snapshot.manifest;
    final catalog = manifest.smartTileCatalog;
    final atlasId = '$importId-atlas';
    final atlas =
        catalog.atlases.where((item) => item.id == atlasId).firstOrNull;
    if (atlas == null) {
      throw VisualLibraryException(
        'tileset.tiled.bundle_unknown',
        'The imported Tiled Wang bundle is unknown.',
        details: <String, Object?>{'importId': importId},
      );
    }
    final tileset = manifest.tilesets
        .where((item) => item.id == atlas.tilesetId)
        .firstOrNull;
    final source = tileset?.source;
    if (tileset == null || source is! ProjectRegularAtlasTilesetSource) {
      throw VisualLibraryException(
        'tileset.tiled.bundle_invalid',
        'The imported Tiled Wang bundle no longer owns a regular tileset.',
        details: <String, Object?>{'importId': importId},
      );
    }
    final presetPrefix = '$importId-w';
    final animationPrefix = '$importId-animation-';
    final presetIds = catalog.presets
        .where((item) => item.id.startsWith(presetPrefix))
        .map((item) => item.id)
        .toSet();
    final materialIds = catalog.materials
        .where((item) => item.id.startsWith(presetPrefix))
        .map((item) => item.id)
        .toSet();
    final animationIds = catalog.animations
        .where((item) => item.id.startsWith(animationPrefix))
        .map((item) => item.id)
        .toSet();
    if (presetIds.isEmpty || materialIds.isEmpty) {
      throw VisualLibraryException(
        'tileset.tiled.bundle_invalid',
        'The imported Tiled Wang bundle is structurally incomplete.',
        details: <String, Object?>{'importId': importId},
      );
    }
    final referencedLayers = <String>[
      for (final map in snapshot.maps)
        for (final layer in map.layers.whereType<SmartTileLayer>())
          if (presetIds.contains(layer.presetId)) '${map.id}:${layer.id}',
    ];
    if (referencedLayers.isNotEmpty) {
      throw VisualLibraryException(
        'tileset.tiled.bundle_references_blocking',
        'The imported Tiled Wang bundle is still referenced by map layers.',
        details: <String, Object?>{
          'importId': importId,
          'references': referencedLayers,
        },
      );
    }
    final projectedCatalog = ProjectSmartTileCatalog(
      categories: catalog.categories,
      atlases: catalog.atlases
          .where((item) => item.id != atlasId)
          .toList(growable: false),
      materials: catalog.materials
          .where((item) => !materialIds.contains(item.id))
          .toList(growable: false),
      animations: catalog.animations
          .where((item) => !animationIds.contains(item.id))
          .toList(growable: false),
      presets: catalog.presets
          .where((item) => !presetIds.contains(item.id))
          .toList(growable: false),
      patterns: catalog.patterns,
      drafts: catalog.drafts,
    );
    final withoutBundle = manifest.copyWith(
      smartTileCatalog: projectedCatalog,
    );
    final projectedManifest = const TilesetActions().delete(
      withoutBundle,
      maps: snapshot.maps,
      tilesetId: tileset.id,
    );
    final catalogBeforeBytes =
        snapshot.findResourceBytes(assetCatalogResourceIdentity);
    final assetCatalog = _decodeAssetCatalog(catalogBeforeBytes);
    final asset = assetCatalog.require(source.assetId);
    final derivedUsages = deriveAssetUsages(
      manifest: projectedManifest,
      maps: snapshot.maps,
      asset: asset,
    );
    if (derivedUsages.isNotEmpty) {
      throw VisualLibraryException(
        'tileset.tiled.bundle_references_blocking',
        'The imported Tiled Wang bundle asset is still referenced.',
        details: <String, Object?>{
          'importId': importId,
          'references': derivedUsages,
        },
      );
    }
    final remainingAssets = assetCatalog.records
        .where((item) => item.id != asset.id)
        .toList(growable: false);
    final projectedAssets = AssetCatalog(records: remainingAssets);
    final deletesBlob = !remainingAssets.any(
      (item) => item.artifact.digest == asset.artifact.digest,
    );
    final blobBytes = snapshot.findResourceBytes(
      assetBlobResourceIdentity(asset.artifact.digest),
    );
    if (deletesBlob && blobBytes == null) {
      throw AssetActionException(
        'asset.rollback_blob_required',
        'Deleting the last bundle asset requires its exact blob pre-image.',
        details: <String, Object?>{'assetId': asset.id},
      );
    }
    try {
      ProjectValidator.validate(projectedManifest);
    } on Object catch (error) {
      throw VisualLibraryException(
        'visual.projected_state_invalid',
        'Deleting the Tiled Wang bundle would invalidate the project.',
        details: <String, Object?>{
          'validationType': error.runtimeType.toString(),
        },
      );
    }
    preflightNativeSmartTileMutation(
      snapshot: snapshot,
      projectedManifest: projectedManifest,
    );
    final assetCatalogResource = AuthoringResourceRef(
      kind: 'assetCatalog',
      id: 'project',
      revision: snapshot.resourceFingerprints[assetCatalogResourceIdentity],
    );
    final projectResource = AuthoringResourceRef(
      kind: 'project',
      id: 'project',
      revision: snapshot.resourceFingerprints['project'],
    );
    final changes = <AuthoringResourceChange>[
      AuthoringResourceChange(
        resource: assetCatalogResource,
        storageKey: assetCatalogStorageKey,
        beforeBytes: catalogBeforeBytes,
        afterBytes: _encodeAssetCatalog(projectedAssets),
      ),
      if (deletesBlob)
        AuthoringResourceChange(
          resource: AuthoringResourceRef(
            kind: 'assetBlob',
            id: asset.artifact.digest,
            revision: snapshot.resourceFingerprints[
                assetBlobResourceIdentity(asset.artifact.digest)],
          ),
          storageKey: assetBlobStorageKey(asset.artifact),
          beforeBytes: blobBytes,
          afterBytes: null,
        ),
      AuthoringResourceChange(
        resource: projectResource,
        storageKey: 'project.json',
        beforeBytes: snapshot.resourceBytes('project'),
        afterBytes: _encodeProjectWithSmartTileCatalog(
          snapshot,
          projectedManifest,
        ),
      ),
    ];
    final diff = <AuthoringDiffEntry>[
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.remove,
        resource: assetCatalogResource,
        path: '/records/${asset.id}',
        before: asset.toJson(),
      ),
      if (deletesBlob)
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.remove,
          resource: changes[1].resource,
          path: '/',
          before: asset.artifact.toJson(),
        ),
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.remove,
        resource: projectResource,
        path: '/smartTileBundles/$importId',
        before: <String, Object?>{
          'atlasId': atlasId,
          'tilesetId': tileset.id,
          'presetIds': presetIds.toList()..sort(),
          'materialIds': materialIds.toList()..sort(),
          'animationIds': animationIds.toList()..sort(),
        },
      ),
    ];
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: changes,
        diff: AuthoringDiff(diff),
      ),
      preview: <String, Object?>{
        'operation': 'tileset.tiled.wang_bundle.delete',
        'importId': importId,
        'assetId': asset.id,
        'tilesetId': tileset.id,
        'atlasId': atlasId,
        'presetCount': presetIds.length,
        'materialCount': materialIds.length,
        'animationCount': animationIds.length,
        'blobDeleted': deletesBlob,
      },
      referenceImpact: <String, Object?>{
        'removedResourceIds': <String>[
          asset.id,
          tileset.id,
          atlasId,
          ...presetIds,
          ...materialIds,
          ...animationIds,
        ],
      },
    );
  }

  /// Projects generated image-collection pages, their asset records and the
  /// canonical tileset through one recoverable multi-resource transaction.
  AuthoringMutationDraft projectImageCollection({
    required ProjectSnapshot snapshot,
    required List<AssetRecord> assets,
    required Map<String, List<int>> pageBytes,
    required ProjectTilesetEntry tileset,
    required String importId,
    required int sourceImageCount,
  }) {
    final source = tileset.source;
    if (source is! ProjectImageCollectionTilesetSource ||
        assets.isEmpty ||
        source.pages.length != assets.length ||
        pageBytes.length != source.pages.length) {
      throw VisualLibraryException(
        'tileset.tiled.image_collection_projection_invalid',
        'The generated collection pages and canonical source must match.',
        details: <String, Object?>{'tilesetId': tileset.id},
      );
    }
    final assetsById = <String, AssetRecord>{
      for (final asset in assets) asset.id: asset,
    };
    final pagesById = <String, ProjectImageCollectionPage>{
      for (final page in source.pages) page.id: page,
    };
    for (final page in source.pages) {
      final asset = assetsById[page.assetId];
      final bytes = pageBytes[page.id];
      if (asset == null || bytes == null) {
        throw VisualLibraryException(
          'tileset.tiled.image_collection_projection_invalid',
          'A generated collection page is missing its asset or bytes.',
          details: <String, Object?>{'pageId': page.id},
        );
      }
      _validateGeneratedPage(page, asset, bytes);
    }
    if (pagesById.length != source.pages.length ||
        assetsById.length != assets.length) {
      throw VisualLibraryException(
        'tileset.tiled.image_collection_projection_invalid',
        'Generated collection page and asset identities must be unique.',
        details: <String, Object?>{'tilesetId': tileset.id},
      );
    }

    final catalogBeforeBytes =
        snapshot.findResourceBytes(assetCatalogResourceIdentity);
    final catalogBefore = _decodeAssetCatalog(catalogBeforeBytes);
    var catalogAfter = catalogBefore;
    for (final asset in assets) {
      final projection = const AssetImportProjector().project(
        catalogAfter,
        record: asset,
      );
      catalogAfter = projection.catalog;
    }

    if (snapshot.manifest.tilesets.any((entry) => entry.id == tileset.id)) {
      throw VisualLibraryException(
        'tileset.id_conflict',
        'A canonical tileset already owns this identity.',
        details: <String, Object?>{'tilesetId': tileset.id},
      );
    }
    final projectedManifest = const TilesetImportProjector().project(
      snapshot.manifest,
      assets: catalogAfter,
      tileset: tileset,
    );
    try {
      ProjectValidator.validate(projectedManifest);
    } on Object catch (error) {
      throw VisualLibraryException(
        'visual.projected_state_invalid',
        'The Tiled image collection import would invalidate the project.',
        details: <String, Object?>{
          'validationType': error.runtimeType.toString(),
        },
      );
    }
    preflightNativeSmartTileMutation(
      snapshot: snapshot,
      projectedManifest: projectedManifest,
    );

    final changes = <AuthoringResourceChange>[
      AuthoringResourceChange(
        resource: AuthoringResourceRef(
          kind: 'assetCatalog',
          id: 'project',
          revision: snapshot.resourceFingerprints[assetCatalogResourceIdentity],
        ),
        storageKey: assetCatalogStorageKey,
        beforeBytes: catalogBeforeBytes,
        afterBytes: _encodeAssetCatalog(catalogAfter),
      ),
    ];
    final diff = <AuthoringDiffEntry>[
      for (final asset in assets)
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: changes.single.resource,
          path: '/records/${asset.id}',
          after: asset.toJson(),
        ),
    ];
    final emittedDigests = <String>{};
    final existingDigests =
        catalogBefore.records.map((asset) => asset.artifact.digest).toSet();
    for (final page in source.pages) {
      final asset = assetsById[page.assetId]!;
      final bytes = pageBytes[page.id]!;
      if (!emittedDigests.add(asset.artifact.digest)) continue;
      final existingBlob = snapshot.findResourceBytes(
        assetBlobResourceIdentity(asset.artifact.digest),
      );
      if (existingDigests.contains(asset.artifact.digest)) {
        _validateDeduplicatedBlob(asset, bytes, existingBlob);
        continue;
      }
      if (existingBlob != null) {
        throw AssetActionException(
          'asset.orphan_blob_conflict',
          'An unowned blob already occupies an imported page digest.',
          details: <String, Object?>{'digest': asset.artifact.digest},
        );
      }
      final blobResource = AuthoringResourceRef(
        kind: 'assetBlob',
        id: asset.artifact.digest,
      );
      changes.add(
        AuthoringResourceChange(
          resource: blobResource,
          storageKey: assetBlobStorageKey(asset.artifact),
          beforeBytes: null,
          afterBytes: bytes,
        ),
      );
      diff.add(
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: blobResource,
          path: '/',
          after: asset.artifact.toJson(),
        ),
      );
    }

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
        afterBytes: encodeProjectAuthoringDocument(
          snapshot,
          projectedManifest,
        ),
      ),
    );
    diff.add(
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: projectResource,
        path: '/tilesets/${tileset.id}',
        after: <String, Object?>{'tileset': tileset.toJson()},
      ),
    );

    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: changes,
        diff: AuthoringDiff(diff),
      ),
      preview: <String, Object?>{
        'operation': 'tileset.tiled.import',
        'sourceKind': 'image_collection',
        'importId': importId,
        'tilesetId': tileset.id,
        'sourceImageCount': sourceImageCount,
        'generatedPageCount': source.pages.length,
        'tileCount': source.tileDefinitions.length,
        'changeCount': changes.length,
      },
      referenceImpact: <String, Object?>{
        'tilesetId': tileset.id,
        'assetIds': <String>[for (final asset in assets) asset.id],
      },
      artifacts: <AuthoringArtifactRef>[
        for (final asset in assets)
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
}

void _validateGeneratedPage(
  ProjectImageCollectionPage page,
  AssetRecord asset,
  List<int> bytes,
) {
  final actual = ContentArtifactRef.fromBytes(
    bytes,
    mediaType: asset.artifact.mediaType,
  );
  final dimensions = decodeRasterImageDimensions(
    bytes,
    mediaType: asset.artifact.mediaType,
  );
  if (asset.artifact.mediaType != 'image/png' ||
      actual != asset.artifact ||
      dimensions == null ||
      dimensions.width != page.pixelWidth ||
      dimensions.height != page.pixelHeight) {
    throw VisualLibraryException(
      'tileset.tiled.generated_page_invalid',
      'A generated image collection page does not match its declaration.',
      details: <String, Object?>{'pageId': page.id},
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

List<int> _encodeProjectWithSmartTileCatalog(
  ProjectSnapshot snapshot,
  ProjectManifest manifest,
) {
  final encoded = encodeProjectAuthoringDocument(snapshot, manifest);
  final decoded = Map<String, Object?>.from(
    jsonDecode(utf8.decode(encoded)) as Map,
  );
  decoded['smartTileCatalog'] = manifest.smartTileCatalog.toJson();
  return List<int>.unmodifiable(
    utf8.encode('${const JsonEncoder.withIndent('  ').convert(decoded)}\n'),
  );
}

void _validateDeduplicatedBlob(
  AssetRecord asset,
  List<int> imageBytes,
  List<int>? existingBlob,
) {
  if (existingBlob == null) {
    throw AssetActionException(
      'asset.deduplicated_blob_missing',
      'The deduplicated artifact blob is unavailable.',
      details: <String, Object?>{'digest': asset.artifact.digest},
    );
  }
  final actual = ContentArtifactRef.fromBytes(
    existingBlob,
    mediaType: asset.artifact.mediaType,
  );
  if (actual.digest != asset.artifact.digest ||
      actual.byteLength != asset.artifact.byteLength ||
      !_sameBytes(existingBlob, imageBytes)) {
    throw AssetActionException(
      'asset.deduplicated_blob_mismatch',
      'The deduplicated artifact blob does not match the staged image.',
      details: <String, Object?>{'digest': asset.artifact.digest},
    );
  }
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
