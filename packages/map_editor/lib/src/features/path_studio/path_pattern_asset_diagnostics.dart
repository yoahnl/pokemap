import 'package:map_core/map_core.dart';

import 'path_pattern_diagnostics.dart';

/// Statut de lecture d’une image tileset sur disque (Lot PathPattern-41).
enum PathPatternTilesetImageStatus {
  ok,
  missingFile,
  unreadable,
}

/// Infos image pour un tileset projet (largeur/hauteur pixels après décodage).
final class PathPatternTilesetImageInfo {
  const PathPatternTilesetImageInfo({
    required this.tilesetId,
    required this.status,
    this.widthPx,
    this.heightPx,
    this.message,
  });

  final String tilesetId;
  final PathPatternTilesetImageStatus status;
  final int? widthPx;
  final int? heightPx;
  final String? message;
}

/// Tileset effectif pour une frame : override non vide, sinon tileset du path de base.
///
/// Règle Lot 41 : `tilesetId == ""` → base ; jamais traité comme tileset manquant.
String effectivePathPatternFrameTilesetId({
  required TilesetVisualFrame frame,
  required ProjectPathPreset basePathPreset,
}) {
  final override = frame.tilesetId.trim();
  if (override.isNotEmpty) {
    return override;
  }
  return basePathPreset.tilesetId.trim();
}

ProjectTilesetEntry? _tilesetEntryById(
  ProjectManifest manifest,
  String tilesetId,
) {
  for (final t in manifest.tilesets) {
    if (t.id.trim() == tilesetId) {
      return t;
    }
  }
  return null;
}

String _pathCenterCellLetter(
  PathCenterPattern pattern,
  PathCenterPatternCell cell,
) {
  final w = pattern.size.width;
  final index = cell.localY * w + cell.localX;
  return String.fromCharCode(65 + index);
}

/// Diagnostics asset / bounds purs — aucune I/O (infos injectées par le caller).
List<PathPatternDiagnostic> createPathPatternAssetDiagnostics({
  required ProjectManifest manifest,
  required ProjectPathPatternPreset pathPatternPreset,
  required ProjectPathPreset? basePathPreset,
  required Map<String, PathPatternTilesetImageInfo>? tilesetImageInfoById,
  required int tileWidth,
  required int tileHeight,
  required bool emitAssetValidationUnavailable,
}) {
  final runnable =
      tilesetImageInfoById != null && tileWidth > 0 && tileHeight > 0;

  if (!runnable) {
    if (emitAssetValidationUnavailable) {
      return const [
        PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.assetValidationUnavailable,
          severity: PathPatternDiagnosticSeverity.info,
          title: 'Validation image non disponible',
          description:
              'Les diagnostics de fichier et de bounds nécessitent un projet ouvert sur disque.',
        ),
      ];
    }
    return [];
  }

  if (basePathPreset == null) {
    return [];
  }

  final knownTilesetIds = manifest.tilesets
      .map((t) => t.id.trim())
      .where((id) => id.isNotEmpty)
      .toSet();

  final imageMap = tilesetImageInfoById;
  final out = <PathPatternDiagnostic>[];
  final reportedMissingFile = <String>{};
  final reportedUnreadable = <String>{};

  void visitFrame(
    TilesetVisualFrame frame,
    String contextLabel,
    int frameIndexOneBased,
  ) {
    final effectiveId = effectivePathPatternFrameTilesetId(
      frame: frame,
      basePathPreset: basePathPreset,
    );
    if (effectiveId.isEmpty) {
      return;
    }

    final override = frame.tilesetId.trim();
    if (override.isNotEmpty && !knownTilesetIds.contains(override)) {
      return;
    }

    final entry = _tilesetEntryById(manifest, effectiveId);
    if (entry == null) {
      return;
    }

    final info = imageMap[effectiveId];
    if (info == null) {
      return;
    }

    switch (info.status) {
      case PathPatternTilesetImageStatus.missingFile:
        if (reportedMissingFile.add(effectiveId)) {
          out.add(
            PathPatternDiagnostic(
              code: PathPatternDiagnosticCode.missingTilesetImageFile,
              severity: PathPatternDiagnosticSeverity.blocking,
              title: 'Image de tileset introuvable',
              description:
                  'Le tileset "${entry.name}" pointe vers "${entry.relativePath}", mais le fichier est absent.',
              relatedId: effectiveId,
            ),
          );
        }
        return;
      case PathPatternTilesetImageStatus.unreadable:
        if (reportedUnreadable.add(effectiveId)) {
          out.add(
            const PathPatternDiagnostic(
              code: PathPatternDiagnosticCode.unreadableTilesetImageFile,
              severity: PathPatternDiagnosticSeverity.blocking,
              title: 'Image de tileset illisible',
              description:
                  'Le fichier existe mais n\'a pas pu être décodé comme image.',
            ),
          );
        }
        return;
      case PathPatternTilesetImageStatus.ok:
        break;
    }

    final src = frame.source;
    if (src.width != 1 || src.height != 1) {
      out.add(
        PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.unsupportedPathPatternFrameSize,
          severity: PathPatternDiagnosticSeverity.warning,
          title: 'Taille de frame potentiellement non supportée',
          description:
              '$contextLabel (frame $frameIndexOneBased) utilise une source '
              '${src.width}×${src.height}. Le rendu PathPattern V0 est conçu pour des tuiles 1×1.',
        ),
      );
    }

    final wPx = info.widthPx;
    final hPx = info.heightPx;
    if (wPx == null || hPx == null) {
      return;
    }

    final leftPx = src.x * tileWidth;
    final topPx = src.y * tileHeight;
    final rightPx = (src.x + src.width) * tileWidth;
    final bottomPx = (src.y + src.height) * tileHeight;

    if (leftPx < 0 ||
        topPx < 0 ||
        rightPx > wPx ||
        bottomPx > hPx) {
      out.add(
        PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.frameSourceOutOfBounds,
          severity: PathPatternDiagnosticSeverity.blocking,
          title: 'Frame hors image',
          description:
              '$contextLabel (frame $frameIndexOneBased) utilise la source x=${src.x}, y=${src.y} '
              '(${src.width}×${src.height} tuiles) hors des limites de l’image ($wPx×$hPx px).',
        ),
      );
    }
  }

  for (final cell in pathPatternPreset.centerPattern.cells) {
    final letter =
        _pathCenterCellLetter(pathPatternPreset.centerPattern, cell);
    for (var i = 0; i < cell.frames.length; i++) {
      visitFrame(
        cell.frames[i],
        'La cellule $letter',
        i + 1,
      );
    }
  }

  for (final mapping in basePathPreset.variants) {
    final vlabel = mapping.variant.name;
    for (var i = 0; i < mapping.frames.length; i++) {
      visitFrame(
        mapping.frames[i],
        'Le variant $vlabel',
        i + 1,
      );
    }
  }

  return out;
}
