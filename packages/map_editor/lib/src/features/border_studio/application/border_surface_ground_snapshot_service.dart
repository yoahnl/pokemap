import 'dart:io';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'border_asset_alpha_analyzer.dart';
import 'border_asset_snapshot_service.dart';

enum BorderSurfaceGroundSnapshotErrorCode {
  invalidProjectRoot,
  missingSurfacePreset,
  missingAnimation,
  missingAtlas,
  atlasFrameOutOfBounds,
  missingTileset,
  unsafeTilesetPath,
  missingTilesetFile,
  unreadableTilesetFile,
  invalidSurfaceVisual,
}

final class BorderSurfaceGroundSnapshotException implements Exception {
  const BorderSurfaceGroundSnapshotException({
    required this.code,
    required this.userMessage,
    this.sourceSurfacePresetId,
    this.surfaceRole,
    this.animationId,
    this.atlasId,
    this.tilesetId,
    this.relativePath,
    this.cause,
  });

  final BorderSurfaceGroundSnapshotErrorCode code;
  final String userMessage;
  final String? sourceSurfacePresetId;
  final SurfaceVariantRole? surfaceRole;
  final String? animationId;
  final String? atlasId;
  final String? tilesetId;
  final String? relativePath;
  final Object? cause;

  @override
  String toString() =>
      'BorderSurfaceGroundSnapshotException.${code.name}: $userMessage';
}

/// Freezes the current pixels of one Surface preset for every canonical role.
///
/// Role fallback intentionally mirrors the editor Surface preview contract:
/// exact role, then `isolated`, then the first authored reference. Once a
/// reference is selected, a broken animation/atlas/tileset link is reported
/// instead of silently choosing another visual.
final class BorderSurfaceGroundSnapshotService {
  const BorderSurfaceGroundSnapshotService({
    this.snapshotService = const BorderAssetSnapshotService(),
  });

  final BorderAssetSnapshotService snapshotService;

  Future<Map<SurfaceVariantRole, BorderAssetSnapshotPreparation>>
      prepareAllRoles({
    required ProjectManifest manifest,
    required String projectRootPath,
    required String sourceSurfacePresetId,
  }) async {
    final root = await _resolveProjectRoot(projectRootPath);
    final normalizedPresetId = sourceSurfacePresetId.trim();
    final catalog = manifest.surfaceCatalog;
    final preset = catalog.presetById(normalizedPresetId);
    if (preset == null) {
      throw BorderSurfaceGroundSnapshotException(
        code: BorderSurfaceGroundSnapshotErrorCode.missingSurfacePreset,
        userMessage: 'La Surface sélectionnée n’existe plus dans le projet.',
        sourceSurfacePresetId: normalizedPresetId,
      );
    }

    final bytesByTilesetId = <String, Uint8List>{};
    final result = <SurfaceVariantRole, BorderAssetSnapshotPreparation>{};
    for (final role in standardSurfaceVariantRoleOrder) {
      final animationId = _resolveAnimationId(preset, role);
      final animation = catalog.animationById(animationId);
      if (animation == null) {
        throw BorderSurfaceGroundSnapshotException(
          code: BorderSurfaceGroundSnapshotErrorCode.missingAnimation,
          userMessage:
              'L’animation de la variante Surface « ${role.name} » est introuvable.',
          sourceSurfacePresetId: normalizedPresetId,
          surfaceRole: role,
          animationId: animationId,
        );
      }

      final frames = <BorderAssetSnapshotSourceFrame>[];
      for (final frame in animation.timeline.frames) {
        final atlasId = frame.tileRef.atlasId.trim();
        final atlas = catalog.atlasById(atlasId);
        if (atlas == null) {
          throw BorderSurfaceGroundSnapshotException(
            code: BorderSurfaceGroundSnapshotErrorCode.missingAtlas,
            userMessage:
                'L’atlas de la variante Surface « ${role.name} » est introuvable.',
            sourceSurfacePresetId: normalizedPresetId,
            surfaceRole: role,
            animationId: animationId,
            atlasId: atlasId,
          );
        }
        if (!frame.tileRef.isInside(atlas.geometry)) {
          throw BorderSurfaceGroundSnapshotException(
            code: BorderSurfaceGroundSnapshotErrorCode.atlasFrameOutOfBounds,
            userMessage:
                'Une frame de la variante Surface « ${role.name} » dépasse son atlas.',
            sourceSurfacePresetId: normalizedPresetId,
            surfaceRole: role,
            animationId: animationId,
            atlasId: atlasId,
          );
        }

        final tilesetId = atlas.tilesetId.trim();
        final tileset = _findTileset(manifest, tilesetId);
        if (tileset == null) {
          throw BorderSurfaceGroundSnapshotException(
            code: BorderSurfaceGroundSnapshotErrorCode.missingTileset,
            userMessage:
                'Le tileset de la variante Surface « ${role.name} » est introuvable.',
            sourceSurfacePresetId: normalizedPresetId,
            surfaceRole: role,
            animationId: animationId,
            atlasId: atlasId,
            tilesetId: tilesetId,
          );
        }
        final bytes = bytesByTilesetId[tileset.id] ??=
            await _readTilesetBytes(root, tileset);
        final tileSize = atlas.geometry.tileSize;
        frames.add(
          BorderAssetSnapshotSourceFrame(
            sourceProjectRelativePath: tileset.relativePath,
            encodedImageBytes: bytes,
            sourceRectPx: BorderPixelRect(
              x: frame.tileRef.column * tileSize.width,
              y: frame.tileRef.row * tileSize.height,
              width: tileSize.width,
              height: tileSize.height,
            ),
            durationMs: frame.durationMs,
            transparentColorArgb: _transparentColorArgb(tileset),
          ),
        );
      }

      try {
        result[role] = snapshotService.prepare(
          BorderAssetSnapshotRequest(
            sourceElementId: normalizedPresetId,
            frames: frames,
          ),
        );
      } on BorderAssetSnapshotException catch (error) {
        throw BorderSurfaceGroundSnapshotException(
          code: BorderSurfaceGroundSnapshotErrorCode.invalidSurfaceVisual,
          userMessage:
              'La variante Surface « ${role.name} » ne peut pas être préparée : '
              '${error.userMessage}',
          sourceSurfacePresetId: normalizedPresetId,
          surfaceRole: role,
          animationId: animationId,
          cause: error,
        );
      } on BorderAssetAlphaAnalysisException catch (error) {
        throw BorderSurfaceGroundSnapshotException(
          code: BorderSurfaceGroundSnapshotErrorCode.invalidSurfaceVisual,
          userMessage:
              'La variante Surface « ${role.name} » ne peut pas être préparée : '
              '${error.userMessage}',
          sourceSurfacePresetId: normalizedPresetId,
          surfaceRole: role,
          animationId: animationId,
          cause: error,
        );
      }
    }
    return Map<SurfaceVariantRole, BorderAssetSnapshotPreparation>.unmodifiable(
      result,
    );
  }
}

String _resolveAnimationId(
  ProjectSurfacePreset preset,
  SurfaceVariantRole role,
) {
  final exact = preset.animationIdForRole(role)?.trim();
  if (exact != null && exact.isNotEmpty) return exact;

  final isolated =
      preset.animationIdForRole(SurfaceVariantRole.isolated)?.trim();
  if (isolated != null && isolated.isNotEmpty) return isolated;

  for (final ref in preset.variantAnimations.refs) {
    final animationId = ref.animationId.trim();
    if (animationId.isNotEmpty) return animationId;
  }
  throw BorderSurfaceGroundSnapshotException(
    code: BorderSurfaceGroundSnapshotErrorCode.missingAnimation,
    userMessage: 'La Surface sélectionnée ne référence aucune animation.',
    sourceSurfacePresetId: preset.id,
    surfaceRole: role,
  );
}

ProjectTilesetEntry? _findTileset(
  ProjectManifest manifest,
  String tilesetId,
) {
  for (final tileset in manifest.tilesets) {
    if (tileset.id == tilesetId) return tileset;
  }
  return null;
}

Future<String> _resolveProjectRoot(String projectRootPath) async {
  final trimmed = projectRootPath.trim();
  if (trimmed.isEmpty) {
    throw const BorderSurfaceGroundSnapshotException(
      code: BorderSurfaceGroundSnapshotErrorCode.invalidProjectRoot,
      userMessage: 'Ouvrez un projet avant de préparer la Surface.',
    );
  }
  final root = Directory(p.normalize(p.absolute(trimmed)));
  if (!await root.exists()) {
    throw const BorderSurfaceGroundSnapshotException(
      code: BorderSurfaceGroundSnapshotErrorCode.invalidProjectRoot,
      userMessage: 'Le dossier du projet est introuvable.',
    );
  }
  try {
    return p.normalize(await root.resolveSymbolicLinks());
  } on FileSystemException catch (error) {
    throw BorderSurfaceGroundSnapshotException(
      code: BorderSurfaceGroundSnapshotErrorCode.invalidProjectRoot,
      userMessage: 'Le dossier du projet ne peut pas être ouvert.',
      cause: error,
    );
  }
}

Future<Uint8List> _readTilesetBytes(
  String projectRoot,
  ProjectTilesetEntry tileset,
) async {
  final relativePath = tileset.relativePath;
  if (!_isSafeProjectRelativePath(relativePath)) {
    throw BorderSurfaceGroundSnapshotException(
      code: BorderSurfaceGroundSnapshotErrorCode.unsafeTilesetPath,
      userMessage: 'Le chemin du tileset Surface sort du projet.',
      tilesetId: tileset.id,
      relativePath: relativePath,
    );
  }
  final candidate = p.normalize(
    p.joinAll(<String>[projectRoot, ...p.posix.split(relativePath)]),
  );
  if (!p.isWithin(projectRoot, candidate)) {
    throw BorderSurfaceGroundSnapshotException(
      code: BorderSurfaceGroundSnapshotErrorCode.unsafeTilesetPath,
      userMessage: 'Le chemin du tileset Surface sort du projet.',
      tilesetId: tileset.id,
      relativePath: relativePath,
    );
  }

  final file = File(candidate);
  if (!await file.exists()) {
    throw BorderSurfaceGroundSnapshotException(
      code: BorderSurfaceGroundSnapshotErrorCode.missingTilesetFile,
      userMessage: 'Le fichier image du tileset Surface est introuvable.',
      tilesetId: tileset.id,
      relativePath: relativePath,
    );
  }
  try {
    final resolvedFile = p.normalize(await file.resolveSymbolicLinks());
    if (!p.isWithin(projectRoot, resolvedFile)) {
      throw BorderSurfaceGroundSnapshotException(
        code: BorderSurfaceGroundSnapshotErrorCode.unsafeTilesetPath,
        userMessage: 'Le fichier du tileset Surface sort du projet.',
        tilesetId: tileset.id,
        relativePath: relativePath,
      );
    }
    return Uint8List.fromList(await File(resolvedFile).readAsBytes());
  } on BorderSurfaceGroundSnapshotException {
    rethrow;
  } on FileSystemException catch (error) {
    throw BorderSurfaceGroundSnapshotException(
      code: BorderSurfaceGroundSnapshotErrorCode.unreadableTilesetFile,
      userMessage: 'Le fichier image du tileset Surface ne peut pas être lu.',
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
