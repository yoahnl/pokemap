import 'dart:io';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'border_asset_snapshot_service.dart';

enum BorderProjectElementAssetErrorCode {
  invalidProjectRoot,
  missingElement,
  elementHasNoFrames,
  missingTileset,
  invalidTileSize,
  unsafeTilesetPath,
  missingTilesetFile,
  unreadableTilesetFile,
}

final class BorderProjectElementAssetException implements Exception {
  const BorderProjectElementAssetException({
    required this.code,
    required this.userMessage,
    this.sourceElementId,
    this.tilesetId,
    this.relativePath,
    this.cause,
  });

  final BorderProjectElementAssetErrorCode code;
  final String userMessage;
  final String? sourceElementId;
  final String? tilesetId;
  final String? relativePath;
  final Object? cause;

  @override
  String toString() =>
      'BorderProjectElementAssetException.${code.name}: $userMessage';
}

/// Prepared current-source data for one editable Border primitive.
///
/// The normal project element remains the authoring provenance while the
/// snapshot preparation owns the immutable pixels that may later be staged.
final class BorderPreparedProjectElementAsset {
  const BorderPreparedProjectElementAsset({
    required this.sourceElement,
    required this.primitive,
    required this.preparation,
  });

  final ProjectElementEntry sourceElement;
  final BorderPrimitiveDraft primitive;
  final BorderAssetSnapshotPreparation preparation;
}

/// Resolves one existing project element into Border-ready current metrics.
///
/// This service intentionally performs no manifest write and no publication.
/// Re-running it always reads the current tileset files, which lets the Studio
/// explicitly detect source changes after a project reload.
final class BorderProjectElementAssetService {
  const BorderProjectElementAssetService({
    this.snapshotService = const BorderAssetSnapshotService(),
  });

  final BorderAssetSnapshotService snapshotService;

  Future<BorderPreparedProjectElementAsset> prepare({
    required ProjectManifest manifest,
    required String projectRootPath,
    required String sourceElementId,
    required String primitiveId,
    required BorderPrimitiveRole role,
    required int weight,
    required BorderTransformPolicy transforms,
    BorderPixelPos? anchorPx,
  }) async {
    final root = await _resolveProjectRoot(projectRootPath);
    final element = _findElement(manifest, sourceElementId);
    if (element.frames.isEmpty) {
      throw BorderProjectElementAssetException(
        code: BorderProjectElementAssetErrorCode.elementHasNoFrames,
        userMessage: 'Cet élément ne possède aucune frame visuelle.',
        sourceElementId: sourceElementId,
      );
    }
    final tileWidth = manifest.settings.tileWidth;
    final tileHeight = manifest.settings.tileHeight;
    if (tileWidth <= 0 || tileHeight <= 0) {
      throw const BorderProjectElementAssetException(
        code: BorderProjectElementAssetErrorCode.invalidTileSize,
        userMessage: 'Les dimensions de tuile du projet sont invalides.',
      );
    }

    final bytesByTilesetId = <String, Uint8List>{};
    final sourceFrames = <BorderAssetSnapshotSourceFrame>[];
    for (final frame in element.frames) {
      final tilesetId =
          frame.tilesetId.isEmpty ? element.tilesetId : frame.tilesetId;
      final tileset = _findTileset(manifest, tilesetId, sourceElementId);
      final bytes = bytesByTilesetId[tileset.id] ??=
          await _readTilesetBytes(root, tileset);
      final source = frame.source;
      sourceFrames.add(
        BorderAssetSnapshotSourceFrame(
          sourceProjectRelativePath: tileset.relativePath,
          encodedImageBytes: bytes,
          sourceRectPx: BorderPixelRect(
            x: source.x * tileWidth,
            y: source.y * tileHeight,
            width: source.width * tileWidth,
            height: source.height * tileHeight,
          ),
          durationMs: frame.durationMs,
          transparentColorArgb: _transparentColorArgb(tileset),
        ),
      );
    }

    final preparation = snapshotService.prepare(
      BorderAssetSnapshotRequest(
        sourceElementId: sourceElementId,
        frames: sourceFrames,
        anchorPx: anchorPx,
      ),
    );
    return BorderPreparedProjectElementAsset(
      sourceElement: element,
      preparation: preparation,
      primitive: BorderPrimitiveDraft(
        id: primitiveId,
        sourceElementId: sourceElementId,
        role: role,
        weight: weight,
        anchorPx: anchorPx ?? preparation.metrics.defaultAnchorPx,
        transforms: transforms,
        currentMetrics: preparation.metrics,
      ),
    );
  }

  /// Re-reads the element identified by [primitive] while preserving authored
  /// role, weight, transforms, and anchor.
  Future<BorderPreparedProjectElementAsset> reanalyze({
    required ProjectManifest manifest,
    required String projectRootPath,
    required BorderPrimitiveDraft primitive,
  }) {
    return prepare(
      manifest: manifest,
      projectRootPath: projectRootPath,
      sourceElementId: primitive.sourceElementId,
      primitiveId: primitive.id,
      role: primitive.role,
      weight: primitive.weight,
      transforms: primitive.transforms,
      anchorPx: primitive.anchorPx,
    );
  }
}

Future<String> _resolveProjectRoot(String projectRootPath) async {
  final trimmed = projectRootPath.trim();
  if (trimmed.isEmpty) {
    throw const BorderProjectElementAssetException(
      code: BorderProjectElementAssetErrorCode.invalidProjectRoot,
      userMessage: 'Ouvrez un projet avant de sélectionner un asset.',
    );
  }
  final root = Directory(p.normalize(p.absolute(trimmed)));
  if (!await root.exists()) {
    throw const BorderProjectElementAssetException(
      code: BorderProjectElementAssetErrorCode.invalidProjectRoot,
      userMessage: 'Le dossier du projet est introuvable.',
    );
  }
  try {
    return p.normalize(await root.resolveSymbolicLinks());
  } on FileSystemException catch (error) {
    throw BorderProjectElementAssetException(
      code: BorderProjectElementAssetErrorCode.invalidProjectRoot,
      userMessage: 'Le dossier du projet ne peut pas être ouvert.',
      cause: error,
    );
  }
}

ProjectElementEntry _findElement(
  ProjectManifest manifest,
  String sourceElementId,
) {
  for (final element in manifest.elements) {
    if (element.id == sourceElementId) return element;
  }
  throw BorderProjectElementAssetException(
    code: BorderProjectElementAssetErrorCode.missingElement,
    userMessage: 'L’élément sélectionné n’existe plus dans le projet.',
    sourceElementId: sourceElementId,
  );
}

ProjectTilesetEntry _findTileset(
  ProjectManifest manifest,
  String tilesetId,
  String sourceElementId,
) {
  for (final tileset in manifest.tilesets) {
    if (tileset.id == tilesetId) return tileset;
  }
  throw BorderProjectElementAssetException(
    code: BorderProjectElementAssetErrorCode.missingTileset,
    userMessage: 'Le tileset d’une frame est introuvable dans le projet.',
    sourceElementId: sourceElementId,
    tilesetId: tilesetId,
  );
}

Future<Uint8List> _readTilesetBytes(
  String projectRoot,
  ProjectTilesetEntry tileset,
) async {
  final relativePath = tileset.relativePath;
  if (!_isSafeProjectRelativePath(relativePath)) {
    throw BorderProjectElementAssetException(
      code: BorderProjectElementAssetErrorCode.unsafeTilesetPath,
      userMessage: 'Le chemin du tileset sort du projet.',
      tilesetId: tileset.id,
      relativePath: relativePath,
    );
  }
  final candidate = p.normalize(
    p.joinAll(<String>[projectRoot, ...p.posix.split(relativePath)]),
  );
  if (!p.isWithin(projectRoot, candidate)) {
    throw BorderProjectElementAssetException(
      code: BorderProjectElementAssetErrorCode.unsafeTilesetPath,
      userMessage: 'Le chemin du tileset sort du projet.',
      tilesetId: tileset.id,
      relativePath: relativePath,
    );
  }
  final file = File(candidate);
  if (!await file.exists()) {
    throw BorderProjectElementAssetException(
      code: BorderProjectElementAssetErrorCode.missingTilesetFile,
      userMessage: 'Le fichier image du tileset est introuvable.',
      tilesetId: tileset.id,
      relativePath: relativePath,
    );
  }
  try {
    final resolvedFile = p.normalize(await file.resolveSymbolicLinks());
    if (!p.isWithin(projectRoot, resolvedFile)) {
      throw BorderProjectElementAssetException(
        code: BorderProjectElementAssetErrorCode.unsafeTilesetPath,
        userMessage: 'Le fichier du tileset sort du projet.',
        tilesetId: tileset.id,
        relativePath: relativePath,
      );
    }
    return Uint8List.fromList(await File(resolvedFile).readAsBytes());
  } on BorderProjectElementAssetException {
    rethrow;
  } on FileSystemException catch (error) {
    throw BorderProjectElementAssetException(
      code: BorderProjectElementAssetErrorCode.unreadableTilesetFile,
      userMessage: 'Le fichier image du tileset ne peut pas être lu.',
      tilesetId: tileset.id,
      relativePath: relativePath,
      cause: error,
    );
  }
}

int? _transparentColorArgb(ProjectTilesetEntry tileset) {
  final color = tileset.transparentColor;
  if (color == null) return null;
  return 0xff000000 | (color.red << 16) | (color.green << 8) | color.blue;
}

bool _isSafeProjectRelativePath(String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.contains(r'\') ||
      path.contains(':') ||
      path.trim() != path) {
    return false;
  }
  return path.split('/').every(
        (segment) => segment.isNotEmpty && segment != '.' && segment != '..',
      );
}
