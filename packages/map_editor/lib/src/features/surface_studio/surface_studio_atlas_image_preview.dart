import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_grid_overlay.dart';

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

const ValueKey<String> kSurfaceStudioAtlasImageGridOverlayKey =
    ValueKey<String>('surface_studio_atlas_image_grid_overlay');

/// Aperçu fichier image source (cadre contraint) ou messages de repli (Lot 72 + overlay grille Lot 73).
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
    this.draftTileWidth,
    this.draftTileHeight,
    this.draftColumns,
    this.draftRows,
    this.draftLayoutLabel,
  });

  final SurfaceStudioAtlasImagePreviewResolution resolution;
  final Color label;
  final Color subtle;

  /// Brouillon atlas : dimensions grille pour overlay et libellés (Lot 73).
  final int? draftTileWidth;
  final int? draftTileHeight;
  final int? draftColumns;
  final int? draftRows;
  final String? draftLayoutLabel;

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
  int? _imageNaturalWidth;
  int? _imageNaturalHeight;

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
      _imageNaturalWidth = null;
      _imageNaturalHeight = null;
      return;
    }
    final path = r.resolvedAbsolutePath;
    if (path == null || path.isEmpty) {
      _cachedPath = null;
      _cachedBytes = null;
      _cacheReadFailed = false;
      _imageNaturalWidth = null;
      _imageNaturalHeight = null;
      return;
    }
    if (_cachedPath == path && _cachedBytes != null) {
      return;
    }
    _cachedPath = path;
    _cacheReadFailed = false;
    _imageNaturalWidth = null;
    _imageNaturalHeight = null;
    try {
      _cachedBytes = File(path).readAsBytesSync();
      final dims = decodeRasterImageSizeFromBytes(_cachedBytes);
      _imageNaturalWidth = dims.width;
      _imageNaturalHeight = dims.height;
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

    final tw = widget.draftTileWidth;
    final th = widget.draftTileHeight;
    final cols = widget.draftColumns;
    final rows = widget.draftRows;
    final gridValid = surfaceStudioAtlasGridOverlayDraftValid(tw, th, cols, rows);
    final natW = _imageNaturalWidth;
    final natH = _imageNaturalHeight;
    final naturalKnown =
        natW != null && natH != null && natW > 0 && natH > 0;
    final nw = natW ?? 0;
    final nh = natH ?? 0;

    int? expW;
    int? expH;
    int? totalCells;
    var overlayColumns = 1;
    var overlayRows = 1;
    if (gridValid && tw != null && th != null && cols != null && rows != null) {
      expW = surfaceStudioAtlasGridExpectedWidthPx(tw, cols);
      expH = surfaceStudioAtlasGridExpectedHeightPx(th, rows);
      totalCells = cols * rows;
      overlayColumns = cols;
      overlayRows = rows;
    }

    var dense = false;
    var stepX = 1;
    var stepY = 1;
    if (gridValid) {
      dense = surfaceStudioAtlasGridOverlayIsDense(overlayColumns, overlayRows);
      stepX = dense ? surfaceStudioAtlasGridOverlayLineStep(overlayColumns) : 1;
      stepY = dense ? surfaceStudioAtlasGridOverlayLineStep(overlayRows) : 1;
    }

    final showOverlay = gridValid && naturalKnown;

    final dimMatch = naturalKnown &&
        gridValid &&
        expW != null &&
        expH != null &&
        nw == expW &&
        nh == expH;

    final gridLineColor =
        Color.lerp(widget.label, const Color(0xFFFFFFFF), 0.35)!
            .withValues(alpha: 0.72);

    final metrics = <Widget>[
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
      if (naturalKnown)
        Text(
          'Image : $nw×$nh px',
          style: TextStyle(color: widget.label, fontSize: 11.5),
        )
      else ...[
        Text(
          'Dimensions réelles non lues.',
          style: TextStyle(color: widget.subtle, fontSize: 11),
        ),
        Text(
          'Superposition sur l’image désactivée tant que les dimensions du fichier ne sont pas lues.',
          style: TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.3),
        ),
      ],
      if (gridValid && expW != null && expH != null) ...[
        const SizedBox(height: 4),
        Text(
          'Grille attendue : $expW×$expH px',
          style: TextStyle(color: widget.label, fontSize: 11.5),
        ),
      ],
      if (gridValid && cols != null && rows != null && tw != null && th != null) ...[
        const SizedBox(height: 2),
        Text(
          'Grille : $cols colonnes × $rows lignes',
          style: TextStyle(color: widget.label, fontSize: 11.5),
        ),
        Text(
          'Tile : $tw×$th px',
          style: TextStyle(color: widget.label, fontSize: 11.5),
        ),
        if (totalCells != null)
          Text(
            'Total : $totalCells cases',
            style: TextStyle(color: widget.subtle, fontSize: 11),
          ),
        if (widget.draftLayoutLabel != null &&
            widget.draftLayoutLabel!.trim().isNotEmpty)
          Text(
            'Disposition : ${widget.draftLayoutLabel}',
            style: TextStyle(color: widget.subtle, fontSize: 10.5),
          ),
      ],
      if (naturalKnown && gridValid) ...[
        const SizedBox(height: 4),
        Text(
          dimMatch
              ? 'La grille correspond aux dimensions attendues.'
              : 'La grille ne correspond pas exactement aux dimensions de l’image.',
          style: TextStyle(
            color: dimMatch
                ? const Color(0xFF5EEAD4)
                : const Color(0xFFE8B87A),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      if (dense) ...[
        const SizedBox(height: 4),
        Text(
          'Grille dense — aperçu visuel simplifié.',
          style: TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.3),
        ),
      ],
      if (!gridValid) ...[
        const SizedBox(height: 4),
        Text(
          'Corrigez les dimensions de grille pour afficher l’overlay.',
          style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.3),
        ),
      ],
      if (showOverlay) ...[
        const SizedBox(height: 4),
        Text(
          'Grille superposée',
          style: TextStyle(
            color: widget.label,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
      const SizedBox(height: 8),
    ];

    final imageStack = naturalKnown
        ? LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
                  ? constraints.maxWidth
                  : 360.0;
              const maxH = _maxImageHeight;
              final scale = math.min(maxW / nw, maxH / nh);
              final dw = nw * scale;
              final dh = nh * scale;
              return Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: dw,
                    height: dh,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        material.Image.memory(
                          _cachedBytes!,
                          key: const ValueKey(
                            'surface_studio_atlas_image_preview_file',
                          ),
                          fit: material.BoxFit.fill,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              'Impossible de charger l’image (format ou fichier).',
                              style: TextStyle(color: widget.subtle, fontSize: 11),
                            ),
                          ),
                        ),
                        if (showOverlay)
                          material.CustomPaint(
                            key: kSurfaceStudioAtlasImageGridOverlayKey,
                            painter: SurfaceStudioAtlasImageGridPainter(
                              columns: overlayColumns,
                              rows: overlayRows,
                              lineColor: gridLineColor,
                              stepX: stepX,
                              stepY: stepY,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: material.Image.memory(
              _cachedBytes!,
              key: const ValueKey('surface_studio_atlas_image_preview_file'),
              fit: material.BoxFit.contain,
              height: _maxImageHeight,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Text(
                'Impossible de charger l’image (format ou fichier).',
                style: TextStyle(color: widget.subtle, fontSize: 11),
              ),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...metrics,
        imageStack,
        const SizedBox(height: 6),
        Text(
          'La grille symbolique de l’atlas reste disponible ci-dessous.',
          style: TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.3),
        ),
      ],
    );
  }
}
