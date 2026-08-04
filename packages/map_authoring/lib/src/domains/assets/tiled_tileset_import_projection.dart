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

    final catalogBeforeBytes =
        snapshot.findResourceBytes(assetCatalogResourceIdentity);
    final catalogBefore = _decodeAssetCatalog(catalogBeforeBytes);
    final assetProjection = const AssetImportProjector().project(
      catalogBefore,
      record: asset,
    );
    final catalogAfter = assetProjection.catalog;

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
