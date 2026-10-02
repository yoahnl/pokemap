import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import '../../contracts/artifact_ref.dart';
import '../../references/resource_usage_documents.dart';
import '../../references/resource_usage_projection.dart';
import '../../references/resource_usage_report.dart';
import '../../references/resource_usage_walk.dart';
import '../../workspace/project_snapshot.dart';
import 'asset_store.dart';
import 'tileset_actions.dart';

AssetCatalog readResourceAssetCatalog(ProjectSnapshot snapshot) {
  final bytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
  if (bytes == null) {
    throw VisualLibraryException('tileset.asset_catalog_required',
        'The source is not managed by the canonical asset catalog.');
  }
  try {
    return AssetCatalog.fromJson(
        Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map));
  } on Object {
    throw VisualLibraryException('tileset.asset_catalog_invalid',
        'Repair the asset catalog before mutating its sources.');
  }
}

AssetRecord requireResourceSourceAsset(
    ProjectTilesetEntry tileset, AssetCatalog catalog) {
  final source = tileset.source;
  if (source is! ProjectRegularAtlasTilesetSource) {
    throw VisualLibraryException('tileset.source_not_supported',
        'Only a managed regular PNG atlas can be replaced or removed with its source. Multi-page and historical sources require their owner.');
  }
  final asset = catalog.find(source.assetId);
  if (asset == null || asset.logicalPath != tileset.relativePath) {
    throw VisualLibraryException('tileset.source_identity_invalid',
        'The tileset asset identity and logical path do not resolve together.');
  }
  return asset;
}

List<int> requireResourceSourceBytes(
    ProjectSnapshot snapshot, AssetRecord asset) {
  final bytes = snapshot.findResourceBytes(
      asset.logicalPath == assetBlobStorageKey(asset.artifact)
          ? assetBlobResourceIdentity(asset.artifact.digest)
          : 'assetLogical:${asset.id}');
  if (bytes == null ||
      ContentArtifactRef.fromBytes(bytes,
              mediaType: asset.artifact.mediaType) !=
          asset.artifact) {
    throw VisualLibraryException('tileset.source_bytes_unavailable',
        'The actual runtime image is missing or differs from its registered asset.');
  }
  return bytes;
}

void requireResourceSourceCoverage(ProjectSnapshot snapshot) {
  final issues = <String>[];
  resourceUsageDocuments(snapshot, issues);
  if (issues.isNotEmpty) {
    throw VisualLibraryException('resource.source.inventory_incomplete',
        'Repair incomplete project references before this source mutation.',
        details: {'coverageIssues': issues});
  }
}

void requireResourceSourceUnused(
    ProjectSnapshot snapshot, ProjectTilesetEntry tileset) {
  final report = const ResourceUsageProjection()
      .analyze(snapshot, ResourceUsageTarget(family: 'images', id: tileset.id));
  if (!report.complete) {
    throw VisualLibraryException('resource.source.inventory_incomplete',
        'The complete project inventory is required before removal.',
        details: {'coverageIssues': report.coverageIssues});
  }
  final issues = <String>[];
  final blockers = <Map<String, Object?>>[
    for (final doc in resourceUsageDocuments(snapshot, issues))
      if (doc.kind != 'tileset' || doc.id != tileset.id)
        for (final path
            in resourceReferencePaths(doc.value, 'tileset', tileset.id))
          {
            'ownerKind': doc.kind,
            'ownerId': doc.id,
            'location': '${doc.origin}:$path'
          }
  ];
  if (blockers.isNotEmpty) {
    throw VisualLibraryException('tileset.references_blocking',
        'The tileset has live, immutable or unresolved project references.',
        details: {'references': blockers});
  }
}

void requireResourceAssetUnused(
    ProjectSnapshot snapshot, ProjectManifest projected, AssetRecord asset) {
  requireResourceSourceCoverage(snapshot);
  final issues = <String>[];
  final documents = resourceUsageDocuments(snapshot, issues);
  final additional = <String, Object?>{};
  for (final doc in documents) {
    if (doc.kind == 'pokemonMedia' ||
        doc.kind == 'dialogueSource' ||
        doc.kind == 'media') {
      additional[doc.identity] = doc.value;
    }
  }
  final values = {
    'project': projected.toJson(),
    for (final map in snapshot.maps) 'map:${map.id}': map.toJson(),
    ...additional
  };
  final references = <String>[
    for (final entry in values.entries)
      for (final path in {
        ...resourceReferencePaths(entry.value, 'asset', asset.id),
        ...resourceReferencePaths(entry.value, 'imagePath', asset.logicalPath)
      })
        '${entry.key}:$path'
  ];
  if (references.isNotEmpty) {
    throw VisualLibraryException('asset.references_blocking',
        'Only the removed tileset reference may be excluded from source removal.',
        details: {'references': references});
  }
}

void validateResourceSourcePng(
    ProjectSnapshot snapshot,
    ProjectTilesetEntry tileset,
    AssetRecord asset,
    ContentArtifactRef candidate,
    List<int> bytes) {
  if (candidate.mediaType != 'image/png' ||
      bytes.length < 33 ||
      bytes.length > 256 * 1024 * 1024 ||
      ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png').digest !=
          candidate.digest) {
    throw VisualLibraryException('tileset.candidate_invalid',
        'The retained candidate must contain the inspected PNG bytes.');
  }
  final header = ByteData.sublistView(Uint8List.fromList(bytes));
  final width = header.getUint32(16);
  final height = header.getUint32(20);
  if (width < 1 ||
      height < 1 ||
      width > 8192 ||
      height > 8192 ||
      width * height > 64 * 1024 * 1024) {
    throw VisualLibraryException('tileset.candidate_limits',
        'The candidate exceeds supported atlas dimensions or decoded pixel limits.');
  }
  final source = tileset.source as ProjectRegularAtlasTilesetSource;
  requireResourceSourceBytes(snapshot, asset);
  if (width != source.pixelWidth || height != source.pixelHeight) {
    throw VisualLibraryException('tileset.candidate_geometry',
        'Replacement must preserve the exact atlas pixel dimensions and slicing.');
  }
  try {
    final decoded = image.decodePng(Uint8List.fromList(bytes));
    if (decoded == null ||
        decoded.width != width ||
        decoded.height != height ||
        decoded.numFrames != 1) {
      throw const FormatException('A single-frame PNG is required.');
    }
  } on Object {
    throw VisualLibraryException('tileset.candidate_decode_failed',
        'The candidate does not decode as a complete supported PNG.');
  }
  final atlases = readTilesetAtlases(snapshot.manifest);
  validateManifestFrames(snapshot.manifest, atlases);
  for (final entry in snapshot.manifest.tilesets
      .where((entry) => entry.relativePath == asset.logicalPath)) {
    final associated = entry.source;
    if (associated is! ProjectRegularAtlasTilesetSource ||
        associated.assetId != asset.id ||
        associated.pixelWidth != width ||
        associated.pixelHeight != height) {
      throw VisualLibraryException('tileset.shared_geometry_invalid',
          'Every tileset referencing this logical image must preserve its geometry.');
    }
  }
  final ownerIds = snapshot.manifest.tilesets
      .where((entry) => entry.relativePath == asset.logicalPath)
      .map((entry) => entry.id)
      .toSet();
  if (snapshot.manifest.characters
      .any((entry) => ownerIds.contains(entry.tilesetId))) {
    throw VisualLibraryException('tileset.character_owner_required',
        'This source belongs to Character Studio. Replace its portrait or clip through that owner.');
  }
}
