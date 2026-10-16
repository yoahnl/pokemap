import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart'
    show
        CanonicalBorderGroundComposer,
        BorderSmartTileGroundSnapshotErrorCode,
        BorderSmartTileGroundSnapshotException;
import 'package:path/path.dart' as p;

import 'border_asset_alpha_analyzer.dart';
import 'border_asset_snapshot_service.dart';

export 'package:map_authoring/map_authoring.dart'
    show
        BorderSmartTileGroundSnapshotErrorCode,
        BorderSmartTileGroundSnapshotException;

final class BorderSmartTileGroundSnapshotService {
  const BorderSmartTileGroundSnapshotService({
    this.snapshotService = const BorderAssetSnapshotService(),
  });
  final BorderAssetSnapshotService snapshotService;
  Future<Map<BorderGroundVariantRole, BorderAssetSnapshotPreparation>>
  prepareAllRoles({
    required ProjectManifest manifest,
    required String projectRootPath,
    required String sourceSmartTilePresetId,
  }) async {
    final root = await _resolveProjectRoot(projectRootPath);
    final compositions = await const CanonicalBorderGroundComposer()
        .composeAllRoles(
          manifest: manifest,
          sourceSmartTilePresetId: sourceSmartTilePresetId,
          readPng: (tileset, _) async =>
              img.encodePng(await _readTilesetImage(root, tileset)),
        );
    final result = <BorderGroundVariantRole, BorderAssetSnapshotPreparation>{};
    for (final entry in compositions.entries) {
      try {
        result[entry.key] = snapshotService.prepare(
          BorderAssetSnapshotRequest(
            sourceElementId: sourceSmartTilePresetId.trim(),
            frames: [
              for (final frame in entry.value)
                BorderAssetSnapshotSourceFrame(
                  sourceProjectRelativePath: frame.sourceProjectRelativePath,
                  encodedImageBytes: frame.encodedImageBytes,
                  durationMs: frame.durationMs,
                ),
            ],
          ),
        );
      } catch (error) {
        if (error is! BorderAssetSnapshotException &&
            error is! BorderAssetAlphaAnalysisException) {
          rethrow;
        }
        throw BorderSmartTileGroundSnapshotException(
          code: BorderSmartTileGroundSnapshotErrorCode.invalidSmartTileVisual,
          userMessage:
              'La variante Smart Tile « ${entry.key.name} » ne peut pas être préparée.',
          sourceSmartTilePresetId: sourceSmartTilePresetId,
          groundRole: entry.key,
          cause: error,
        );
      }
    }
    return Map.unmodifiable(result);
  }
}

Future<String> _resolveProjectRoot(String projectRootPath) async {
  final trimmed = projectRootPath.trim();
  if (trimmed.isEmpty) {
    throw const BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.invalidProjectRoot,
      userMessage: 'Ouvrez un projet avant de préparer le Smart Tile.',
    );
  }
  final root = Directory(p.normalize(p.absolute(trimmed)));
  if (!await root.exists()) {
    throw const BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.invalidProjectRoot,
      userMessage: 'Le dossier du projet est introuvable.',
    );
  }
  try {
    return p.normalize(await root.resolveSymbolicLinks());
  } on FileSystemException catch (error) {
    throw BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.invalidProjectRoot,
      userMessage: 'Le dossier du projet ne peut pas être ouvert.',
      cause: error,
    );
  }
}

Future<img.Image> _readTilesetImage(
  String projectRoot,
  ProjectTilesetEntry tileset,
) async {
  final relativePath = tileset.relativePath;
  if (!_isSafeProjectRelativePath(relativePath)) {
    throw BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.unsafeTilesetPath,
      userMessage: 'Le chemin du tileset Smart Tile sort du projet.',
      tilesetId: tileset.id,
      relativePath: relativePath,
    );
  }
  final candidate = p.normalize(
    p.joinAll(<String>[projectRoot, ...p.posix.split(relativePath)]),
  );
  if (!p.isWithin(projectRoot, candidate)) {
    throw BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.unsafeTilesetPath,
      userMessage: 'Le chemin du tileset Smart Tile sort du projet.',
      tilesetId: tileset.id,
      relativePath: relativePath,
    );
  }
  final file = File(candidate);
  if (!await file.exists()) {
    throw BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.missingTilesetFile,
      userMessage: 'Le fichier image du tileset Smart Tile est introuvable.',
      tilesetId: tileset.id,
      relativePath: relativePath,
    );
  }
  try {
    final resolvedFile = p.normalize(await file.resolveSymbolicLinks());
    if (!p.isWithin(projectRoot, resolvedFile)) {
      throw BorderSmartTileGroundSnapshotException(
        code: BorderSmartTileGroundSnapshotErrorCode.unsafeTilesetPath,
        userMessage: 'Le fichier du tileset Smart Tile sort du projet.',
        tilesetId: tileset.id,
        relativePath: relativePath,
      );
    }
    final bytes = await File(resolvedFile).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw BorderSmartTileGroundSnapshotException(
        code: BorderSmartTileGroundSnapshotErrorCode.unreadableTilesetFile,
        userMessage: 'Le fichier image Smart Tile ne peut pas être décodé.',
        tilesetId: tileset.id,
        relativePath: relativePath,
      );
    }
    final transparent = tileset.transparentColor;
    if (transparent != null) {
      for (final pixel in decoded) {
        if (pixel.r == transparent.red &&
            pixel.g == transparent.green &&
            pixel.b == transparent.blue) {
          pixel.setRgba(0, 0, 0, 0);
        }
      }
    }
    return decoded;
  } on BorderSmartTileGroundSnapshotException {
    rethrow;
  } on FileSystemException catch (error) {
    throw BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.unreadableTilesetFile,
      userMessage:
          'Le fichier image du tileset Smart Tile ne peut pas être lu.',
      tilesetId: tileset.id,
      relativePath: relativePath,
      cause: error,
    );
  }
}

bool _isSafeProjectRelativePath(String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.contains(r'\') ||
      path.contains(':') ||
      path.trim() != path) {
    return false;
  }
  return path
      .split('/')
      .every(
        (segment) => segment.isNotEmpty && segment != '.' && segment != '..',
      );
}
