import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/authoring_query_adapter.dart';
import 'smart_tile_atlas_image_loader.dart';

final class SmartTileSourceCanonicalSnapshot {
  const SmartTileSourceCanonicalSnapshot({
    required this.revision,
    required this.manifest,
  });

  final String revision;
  final ProjectManifest manifest;
}

abstract interface class SmartTileSourceAssetGateway {
  Future<ContentArtifactRef> stageExactFile({
    required String projectRootPath,
    required String sourcePath,
  });

  Future<String> apply({
    required String projectRootPath,
    required String actionId,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  });

  Future<SmartTileSourceCanonicalSnapshot> load({
    required String projectRootPath,
  });
}

final class CanonicalSmartTileSourceAssetGateway
    implements SmartTileSourceAssetGateway {
  const CanonicalSmartTileSourceAssetGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  })  : _mutations = mutations,
        _queries = queries;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;

  @override
  Future<ContentArtifactRef> stageExactFile({
    required String projectRootPath,
    required String sourcePath,
  }) async {
    final staged = await _mutations.stageArtifact(
      projectRootPath,
      sourcePath: sourcePath,
    );
    return staged.reference;
  }

  @override
  Future<String> apply({
    required String projectRootPath,
    required String actionId,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  }) async {
    final plan = await _mutations.plan(
      projectRootPath,
      actionId: actionId,
      parameters: parameters,
      expectedRevision: expectedRevision,
      idempotencyKey: idempotencyKey,
      requestId: idempotencyKey,
    );
    final applied = await _mutations.apply(
      plan,
      operationId: '$idempotencyKey-apply',
    );
    return applied.snapshotRevision;
  }

  @override
  Future<SmartTileSourceCanonicalSnapshot> load({
    required String projectRootPath,
  }) async {
    final session = await _queries.open(projectRootPath);
    return SmartTileSourceCanonicalSnapshot(
      revision: session.snapshotRevision,
      manifest: session.manifest,
    );
  }
}

final class SmartTileSourceImportResult {
  const SmartTileSourceImportResult({
    required this.manifest,
    required this.tileset,
    required this.image,
    required this.assetId,
  });

  final ProjectManifest manifest;
  final ProjectTilesetEntry tileset;
  final SmartTileAtlasImage image;
  final String assetId;
}

final class SmartTileSourceImportException implements Exception {
  const SmartTileSourceImportException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'SmartTileSourceImportException($code): $message';
}

/// Canonical import pipeline for one external Smart Tile source image.
///
/// The machine path exists only during opaque staging. Every subsequent read
/// uses the content-addressed blob inside the authorized project root.
final class SmartTileSourceAssetImportService {
  const SmartTileSourceAssetImportService({
    required SmartTileSourceAssetGateway gateway,
    required SmartTileAtlasImageLoader imageLoader,
  })  : _gateway = gateway,
        _imageLoader = imageLoader;

  final SmartTileSourceAssetGateway _gateway;
  final SmartTileAtlasImageLoader _imageLoader;

  Future<SmartTileSourceImportResult> importImage({
    required String projectRootPath,
    required String sourcePath,
    required String displayName,
  }) async {
    final staged = await _gateway.stageExactFile(
      projectRootPath: projectRootPath,
      sourcePath: sourcePath,
    );
    if (!staged.mediaType.startsWith('image/')) {
      throw const SmartTileSourceImportException(
        'smart_tile.source_not_image',
        'Le fichier sélectionné n’est pas une image reconnue.',
      );
    }
    final suffix = staged.hexDigest.substring(0, 16);
    final assetId = 'smart-tile-image-$suffix';
    final tilesetId = 'smart-tile-tileset-$suffix';
    final logicalPath = assetBlobStorageKey(staged);
    final initial = await _gateway.load(projectRootPath: projectRootPath);
    final assetRevision = await _gateway.apply(
      projectRootPath: projectRootPath,
      actionId: 'asset.import',
      parameters: <String, Object?>{
        'artifactHandle': staged.handle,
        'assetId': assetId,
        'logicalPath': logicalPath,
        'tags': const <String>['smart-tile-source'],
        'usages': const <String>['smart-tiles-studio'],
      },
      expectedRevision: initial.revision,
      idempotencyKey: 'smart-tile-source-asset-${staged.hexDigest}',
    );
    final tileset = ProjectTilesetEntry(
      id: tilesetId,
      name: _displayName(displayName),
      relativePath: logicalPath,
    );
    final loaded = await _imageLoader.load(
      projectRootPath: projectRootPath,
      tileset: tileset,
    );
    final image = loaded.image;
    if (!loaded.isLoaded || image == null) {
      throw SmartTileSourceImportException(
        'smart_tile.imported_image_unreadable',
        loaded.message,
      );
    }
    final canonicalTilesetDraft = tileset.copyWith(
      source: ProjectTilesetSource.regularAtlas(
        assetId: assetId,
        pixelWidth: image.width,
        pixelHeight: image.height,
        tileWidth: 1,
        tileHeight: 1,
      ),
    );
    final tilesetRevision = await _gateway.apply(
      projectRootPath: projectRootPath,
      actionId: 'tileset.upsert',
      parameters: <String, Object?>{
        'tileset': canonicalTilesetDraft.toJson(),
      },
      expectedRevision: assetRevision,
      idempotencyKey: 'smart-tile-source-tileset-${staged.hexDigest}',
    );
    final canonical = await _gateway.load(projectRootPath: projectRootPath);
    if (canonical.revision != tilesetRevision) {
      throw const SmartTileSourceImportException(
        'smart_tile.import_snapshot_stale',
        'Le snapshot canonique de l’image importée est obsolète.',
      );
    }
    final canonicalTileset = canonical.manifest.tilesets
        .where((candidate) => candidate.id == tilesetId)
        .firstOrNull;
    if (canonicalTileset == null) {
      throw const SmartTileSourceImportException(
        'smart_tile.import_tileset_missing',
        'Le tileset importé est absent du snapshot canonique.',
      );
    }
    return SmartTileSourceImportResult(
      manifest: canonical.manifest,
      tileset: canonicalTileset,
      image: image,
      assetId: assetId,
    );
  }
}

String _displayName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Image Smart Tile';
  final dot = trimmed.lastIndexOf('.');
  return dot > 0 ? trimmed.substring(0, dot) : trimmed;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
