import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../ui/shared/cupertino_editor_widgets.dart';

/// Statut de résolution du fichier image pour l’aperçu Surface Studio (Lot 72).
enum SurfaceStudioAtlasImagePreviewResolveStatus {
  empty,
  resolved,
  missingFile,
  unresolved,
}

/// Résultat local de [resolveSurfaceStudioAtlasImagePreview] — pas de service global.
class SurfaceStudioAtlasImagePreviewResolution {
  const SurfaceStudioAtlasImagePreviewResolution({
    required this.status,
    this.resolvedAbsolutePath,
    required this.displayFileName,
    required this.relativePathForUi,
  });

  final SurfaceStudioAtlasImagePreviewResolveStatus status;
  final String? resolvedAbsolutePath;

  /// Nom de fichier affiché (basename du chemin manifeste).
  final String displayFileName;

  /// Chemin relatif projet ou message court pour l’UI secondaire.
  final String relativePathForUi;
}

/// Résout un chemin fichier absolu candidat pour l’aperçu atlas, sans I/O réseau ni scan projet.
///
/// Utilise uniquement [ProjectTilesetEntry.relativePath] et [projectRootPath] quand ils sont présents.
SurfaceStudioAtlasImagePreviewResolution resolveSurfaceStudioAtlasImagePreview({
  required String? projectRootPath,
  required List<ProjectTilesetEntry>? projectTilesets,
  required String? technicalTilesetId,
}) {
  final tid = technicalTilesetId?.trim() ?? '';
  if (tid.isEmpty) {
    return const SurfaceStudioAtlasImagePreviewResolution(
      status: SurfaceStudioAtlasImagePreviewResolveStatus.empty,
      displayFileName: '',
      relativePathForUi: '',
    );
  }

  final tilesets = projectTilesets;
  if (tilesets == null || tilesets.isEmpty) {
    return const SurfaceStudioAtlasImagePreviewResolution(
      status: SurfaceStudioAtlasImagePreviewResolveStatus.unresolved,
      displayFileName: '',
      relativePathForUi:
          'Aucune entrée jeu d’images dans le manifeste — impossible de résoudre le fichier.',
    );
  }

  ProjectTilesetEntry? entry;
  for (final e in tilesets) {
    if (e.id == tid) {
      entry = e;
      break;
    }
  }
  if (entry == null) {
    return const SurfaceStudioAtlasImagePreviewResolution(
      status: SurfaceStudioAtlasImagePreviewResolveStatus.unresolved,
      displayFileName: '',
      relativePathForUi:
          'Identifiant inconnu dans la liste des jeux d’images du projet.',
    );
  }

  final rel = entry.relativePath.trim();
  final baseName = rel.isNotEmpty ? p.basename(rel) : entry.name.trim();

  final root = projectRootPath?.trim();
  if (root == null || root.isEmpty) {
    return SurfaceStudioAtlasImagePreviewResolution(
      status: SurfaceStudioAtlasImagePreviewResolveStatus.unresolved,
      displayFileName: baseName.isNotEmpty ? baseName : entry.name,
      relativePathForUi: rel.isEmpty
          ? 'Chemin relatif absent dans le manifeste.'
          : 'Projet sans dossier ouvert sur disque — chemin manifeste : $rel',
    );
  }
  if (rel.isEmpty) {
    return SurfaceStudioAtlasImagePreviewResolution(
      status: SurfaceStudioAtlasImagePreviewResolveStatus.unresolved,
      displayFileName: entry.name,
      relativePathForUi: 'Chemin relatif absent dans le manifeste.',
    );
  }

  final abs = p.normalize(p.join(root, rel));
  if (File(abs).existsSync()) {
    return SurfaceStudioAtlasImagePreviewResolution(
      status: SurfaceStudioAtlasImagePreviewResolveStatus.resolved,
      resolvedAbsolutePath: abs,
      displayFileName: p.basename(rel),
      relativePathForUi: rel,
    );
  }

  return SurfaceStudioAtlasImagePreviewResolution(
    status: SurfaceStudioAtlasImagePreviewResolveStatus.missingFile,
    displayFileName: p.basename(rel),
    relativePathForUi: rel,
  );
}

const ValueKey<String> kSurfaceStudioAtlasImagePreviewSectionKey =
    ValueKey<String>('surface_studio_atlas_image_preview_section');

/// Aperçu fichier image source (cadre contraint) ou messages de repli (Lot 72).
///
/// Les octets sont mis en cache dans l’état pour éviter de relire le disque à
/// chaque reconstruction du formulaire et pour un décodage plus prévisible
/// dans les tests widget (évite [Image.file] + settle bloquant).
class SurfaceStudioAtlasImagePreview extends StatefulWidget {
  const SurfaceStudioAtlasImagePreview({
    super.key,
    required this.resolution,
    required this.label,
    required this.subtle,
  });

  final SurfaceStudioAtlasImagePreviewResolution resolution;
  final Color label;
  final Color subtle;

  @override
  State<SurfaceStudioAtlasImagePreview> createState() =>
      _SurfaceStudioAtlasImagePreviewState();
}

class _SurfaceStudioAtlasImagePreviewState
    extends State<SurfaceStudioAtlasImagePreview> {
  static const double _maxImageHeight = 160;

  String? _cachedPath;
  Uint8List? _cachedBytes;
  bool _cacheReadFailed = false;

  @override
  void didUpdateWidget(covariant SurfaceStudioAtlasImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCacheFromResolution();
  }

  @override
  void initState() {
    super.initState();
    _syncCacheFromResolution();
  }

  void _syncCacheFromResolution() {
    final r = widget.resolution;
    if (r.status != SurfaceStudioAtlasImagePreviewResolveStatus.resolved) {
      _cachedPath = null;
      _cachedBytes = null;
      _cacheReadFailed = false;
      return;
    }
    final path = r.resolvedAbsolutePath;
    if (path == null || path.isEmpty) {
      _cachedPath = null;
      _cachedBytes = null;
      _cacheReadFailed = false;
      return;
    }
    if (_cachedPath == path && _cachedBytes != null) {
      return;
    }
    _cachedPath = path;
    _cacheReadFailed = false;
    try {
      _cachedBytes = File(path).readAsBytesSync();
    } catch (_) {
      _cachedBytes = null;
      _cacheReadFailed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: kSurfaceStudioAtlasImagePreviewSectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aperçu de l’image source',
            style: TextStyle(
              color: widget.label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          ..._bodyForStatus(context),
        ],
      ),
    );
  }

  List<Widget> _bodyForStatus(BuildContext context) {
    switch (widget.resolution.status) {
      case SurfaceStudioAtlasImagePreviewResolveStatus.empty:
        return [
          Text(
            'Choisissez une image source pour afficher l’aperçu.',
            style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
          ),
        ];
      case SurfaceStudioAtlasImagePreviewResolveStatus.unresolved:
      case SurfaceStudioAtlasImagePreviewResolveStatus.missingFile:
        return [_fallbackBlock(context)];
      case SurfaceStudioAtlasImagePreviewResolveStatus.resolved:
        return [_resolvedBlock(context)];
    }
  }

  Widget _fallbackBlock(BuildContext context) {
    final r = widget.resolution;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          r.status == SurfaceStudioAtlasImagePreviewResolveStatus.missingFile
              ? 'Aperçu image indisponible pour cette source (fichier introuvable sur disque).'
              : 'Aperçu image indisponible pour cette source.',
          style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
        ),
        const SizedBox(height: 4),
        Text(
          'La grille symbolique reste disponible.',
          style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.3),
        ),
        if (r.relativePathForUi.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            r.relativePathForUi,
            style: TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.3),
          ),
        ],
      ],
    );
  }

  Widget _resolvedBlock(BuildContext context) {
    final r = widget.resolution;
    final path = r.resolvedAbsolutePath;
    if (path == null || path.isEmpty) {
      return _fallbackBlock(context);
    }
    if (_cacheReadFailed || _cachedBytes == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Impossible de charger l’image (format ou fichier).',
            style: TextStyle(color: widget.subtle, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            'Source : ${r.displayFileName}',
            style: TextStyle(color: widget.label, fontSize: 11.5),
          ),
          const SizedBox(height: 2),
          Text(
            'Chemin : ${r.relativePathForUi}',
            style: TextStyle(color: widget.subtle, fontSize: 11),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: material.Image.memory(
            _cachedBytes!,
            key: const ValueKey('surface_studio_atlas_image_preview_file'),
            fit: BoxFit.contain,
            height: _maxImageHeight,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Text(
              'Impossible de charger l’image (format ou fichier).',
              style: TextStyle(color: widget.subtle, fontSize: 11),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Source : ${r.displayFileName}',
          style: TextStyle(color: widget.label, fontSize: 11.5),
        ),
        const SizedBox(height: 2),
        Text(
          'Chemin : ${r.relativePathForUi}',
          style: TextStyle(color: widget.subtle, fontSize: 11),
        ),
        const SizedBox(height: 6),
        Text(
          'La grille symbolique de l’atlas reste disponible ci-dessous.',
          style: TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.3),
        ),
      ],
    );
  }
}
