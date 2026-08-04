import 'package:map_core/map_core.dart';

import '../../contracts/artifact_ref.dart';
import '../assets/asset_store.dart';
import '../assets/raster_image_dimensions.dart';
import 'semantic_map_action_support.dart';

/// Pure Wang importer projection.
///
/// All dependencies are explicit immutable values. No resource is read or
/// written here, which makes this projector safe to compose into a larger
/// transaction plan.
final class TiledWangImportProjector {
  const TiledWangImportProjector();

  ProjectManifest project(
    ProjectManifest manifest, {
    required AssetCatalog assets,
    required List<int> imageBytes,
    required TiledWangImportBundle bundle,
  }) {
    validateSmartTileAtlasImageBounds(
      manifest: manifest,
      assets: assets,
      imageBytes: imageBytes,
      atlas: bundle.atlas,
    );

    final current = manifest.smartTileCatalog;
    final conflicts = <String>[
      if (current.atlases.any((item) => item.id == bundle.atlas.id))
        'atlas:${bundle.atlas.id}',
      ..._importConflicts(
        current.materials,
        bundle.materials,
        (item) => item.id,
        'material',
      ),
      ..._importConflicts(
        current.animations,
        bundle.animations,
        (item) => item.id,
        'animation',
      ),
      ..._importConflicts(
        current.presets,
        bundle.presets,
        (item) => item.id,
        'preset',
      ),
    ]..sort();
    if (conflicts.isNotEmpty) {
      throw semanticFailure(
        'smart_tile.tiled_wang.id_conflict',
        'The Tiled Wang import would replace existing Smart Tile resources.',
        details: <String, Object?>{'conflicts': conflicts},
        remediation: const <String>[
          'Choose another import namespace or remove the previous import.',
        ],
      );
    }

    return manifest.copyWith(
      version: ProjectVersion.v6,
      smartTileCatalog: ProjectSmartTileCatalog(
        categories: current.categories,
        atlases: _appendAndSortById(
          current.atlases,
          <ProjectSmartTileAtlas>[bundle.atlas],
          (item) => item.id,
        ),
        materials: _appendAndSortById(
          current.materials,
          bundle.materials,
          (item) => item.id,
        ),
        animations: _appendAndSortById(
          current.animations,
          bundle.animations,
          (item) => item.id,
        ),
        presets: _appendAndSortById(
          current.presets,
          bundle.presets,
          (item) => item.id,
        ),
        patterns: current.patterns,
        drafts: current.drafts,
      ),
    );
  }
}

void validateSmartTileAtlasImageBounds({
  required ProjectManifest manifest,
  required AssetCatalog assets,
  required List<int> imageBytes,
  required ProjectSmartTileAtlas atlas,
}) {
  ProjectTilesetEntry? tileset;
  for (final entry in manifest.tilesets) {
    if (entry.id == atlas.tilesetId) {
      tileset = entry;
      break;
    }
  }
  if (tileset == null) {
    throw semanticFailure(
      'smart_tile.atlas.tileset_missing',
      'The Smart Tile atlas references an unknown tileset.',
      details: <String, Object?>{'tilesetId': atlas.tilesetId},
    );
  }
  final source = tileset.source;
  AssetRecord? asset;
  if (source is ProjectRegularAtlasTilesetSource) {
    asset = assets.find(source.assetId);
  }
  asset ??= assets.records
      .where((record) => record.logicalPath == tileset!.relativePath)
      .firstOrNull;
  if (asset == null || !asset.artifact.mediaType.startsWith('image/')) {
    throw semanticFailure(
      'smart_tile.atlas.image_asset_missing',
      'The tileset does not resolve to a canonical image asset.',
      details: <String, Object?>{
        'tilesetId': tileset.id,
        'logicalPath': tileset.relativePath,
      },
    );
  }
  final actualArtifact = ContentArtifactRef.fromBytes(
    imageBytes,
    mediaType: asset.artifact.mediaType,
  );
  if (actualArtifact.digest != asset.artifact.digest ||
      actualArtifact.byteLength != asset.artifact.byteLength) {
    throw semanticFailure(
      'smart_tile.atlas.image_blob_mismatch',
      'The supplied atlas bytes do not match the canonical image asset.',
      details: <String, Object?>{'assetId': asset.id},
    );
  }
  final dimensions = decodeRasterImageDimensions(
    imageBytes,
    mediaType: asset.artifact.mediaType,
  );
  if (dimensions == null) {
    throw semanticFailure(
      'smart_tile.atlas.image_decode_failed',
      'The canonical tileset image dimensions cannot be decoded.',
      details: <String, Object?>{'assetId': asset.id},
    );
  }

  final right = atlas.originX +
      atlas.marginX +
      (atlas.columns - 1) * (atlas.cellWidth + atlas.spacingX) +
      atlas.cellWidth;
  final bottom = atlas.originY +
      atlas.marginY +
      (atlas.rows - 1) * (atlas.cellHeight + atlas.spacingY) +
      atlas.cellHeight;
  if (right > dimensions.width || bottom > dimensions.height) {
    throw semanticFailure(
      'smart_tile.atlas.out_of_image',
      'The Smart Tile atlas grid extends outside the decoded image.',
      details: <String, Object?>{
        'atlasId': atlas.id,
        'imageWidth': dimensions.width,
        'imageHeight': dimensions.height,
        'requiredWidth': right,
        'requiredHeight': bottom,
      },
      remediation: const <String>[
        'Reduce the grid, origin, margins, or spacing to stay in the image.',
      ],
    );
  }
}

List<T> _appendAndSortById<T>(
  Iterable<T> current,
  Iterable<T> imported,
  String Function(T) idOf,
) {
  final result = <T>[...current, ...imported]
    ..sort((left, right) => idOf(left).compareTo(idOf(right)));
  return List<T>.unmodifiable(result);
}

List<String> _importConflicts<T>(
  Iterable<T> current,
  Iterable<T> imported,
  String Function(T) idOf,
  String kind,
) {
  final existingIds = current.map(idOf).toSet();
  return <String>[
    for (final item in imported)
      if (existingIds.contains(idOf(item))) '$kind:${idOf(item)}',
  ];
}
