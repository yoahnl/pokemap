// Éditeur de masques triple couche pour les éléments projet (PokeMap).
// Voir le rapport : reports/POKEMAP_MASKS_OCCLUSION_PLAYER_V2_REPORT.md

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:map_core/map_core.dart';

import '../../application/models/element_collision_truth_summary.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Mode de la surface d’édition : **aperçu** (lecture seule) ou peinture sur
/// un des deux masques métiers (collision vs occlusion).
///
/// Rappel produit :
/// - **Collision** = bloque le déplacement (gameplay).
/// - **Occlusion** = peut recouvrir le joueur au rendu quand il passe « derrière » ;
///   ne bloque pas par lui-même.
enum MaskSurfaceMode {
  /// Sprite + overlays + légende ; pas d’édition.
  preview,

  /// Pinceau / gomme sur [ElementCollisionProfile.collisionMask] (JSON `pixelMask`).
  collisionPaint,

  /// Pinceau / gomme sur [ElementCollisionProfile.occlusionMask].
  occlusionPaint,
}

enum _MaskStrokeOperation {
  paint,
  erase,
}

/// Éditeur **pixel-level** pour les masques d’un [ProjectElementEntry] :
/// visual (alpha), collision, occlusion — avec fond damier, zoom centré, légende.
///
/// ## Compatibilité
/// - Si seul l’ancien champ [ElementCollisionProfile.cells] est rempli, on
///   **dérive** un bitmap collision en remplissant chaque tuile « bloquante ».
/// - À chaque modification, on **ré-écrit** aussi `cells` via
///   [ElementCollisionMaskCodec.cellsFromPixelMask] pour les outils legacy.
///
/// ## Non-objectifs
/// - La grille affichée est un **repère** ; la vérité reste le masque pixel.
class ElementCollisionTripleMaskEditor extends StatefulWidget {
  const ElementCollisionTripleMaskEditor({
    super.key,
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.profile,
    required this.draftPadding,
    required this.onProfileChanged,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionProfile? profile;
  final WarpTriggerPadding draftPadding;
  final ValueChanged<ElementCollisionProfile?> onProfileChanged;

  @override
  State<ElementCollisionTripleMaskEditor> createState() =>
      _ElementCollisionTripleMaskEditorState();
}

class _ElementCollisionTripleMaskEditorState
    extends State<ElementCollisionTripleMaskEditor> {
  MaskSurfaceMode _mode = MaskSurfaceMode.collisionPaint;
  late _MaskStrokeOperation _strokeOperation;
  late int _brushSizePx;
  int _zoomPercent = 100;
  bool _showPixelGrid = false;
  math.Point<int>? _hoverPixel;

  late List<bool> _collisionBits;
  late List<bool> _occlusionBits;
  List<bool>? _visualBits;
  bool _loadingVisual = false;

  int get _wPx => math.max(1, widget.source.width * widget.tileWidth);
  int get _hPx => math.max(1, widget.source.height * widget.tileHeight);

  @override
  void initState() {
    super.initState();
    _collisionBits = _initialCollisionBits();
    _occlusionBits = _initialOcclusionBits();
    _strokeOperation = _initialStrokeOperation();
    _brushSizePx = _defaultBrushSizePx();
    _scheduleVisualLoad();
  }

  @override
  void didUpdateWidget(covariant ElementCollisionTripleMaskEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile ||
        oldWidget.source != widget.source ||
        oldWidget.tileWidth != widget.tileWidth ||
        oldWidget.tileHeight != widget.tileHeight) {
      setState(() {
        _collisionBits = _initialCollisionBits();
        _occlusionBits = _initialOcclusionBits();
        _visualBits = null;
        _loadingVisual = false;
        _hoverPixel = null;
      });
      _scheduleVisualLoad();
    }
  }

  void _scheduleVisualLoad() {
    final decoded = _decodeMask(widget.profile?.visualMask, _wPx, _hPx);
    if (decoded != null) {
      setState(() {
        _visualBits = decoded;
      });
      return;
    }
    _loadVisualFromImageAlpha();
  }

  /// Construit le masque « visible » depuis l’alpha du PNG si aucun [visualMask]
  /// n’est persisté — cohérent avec l’auto-génération (seuil alpha).
  Future<void> _loadVisualFromImageAlpha() async {
    setState(() {
      _loadingVisual = true;
    });
    final bd =
        await widget.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (!mounted) {
      return;
    }
    if (bd == null) {
      setState(() {
        _loadingVisual = false;
        _visualBits = List<bool>.filled(_wPx * _hPx, false);
      });
      return;
    }
    final bytes = bd.buffer.asUint8List();
    final srcLeft = widget.source.x * widget.tileWidth;
    final srcTop = widget.source.y * widget.tileHeight;
    final w = _wPx;
    final h = _hPx;
    final imgW = widget.image.width;
    final out = List<bool>.filled(w * h, false);
    const alphaThreshold = 12;
    for (var py = 0; py < h; py++) {
      for (var px = 0; px < w; px++) {
        final ix = srcLeft + px;
        final iy = srcTop + py;
        if (ix < 0 || iy < 0 || ix >= imgW || iy >= widget.image.height) {
          continue;
        }
        final o = (iy * imgW + ix) * 4;
        final a = bytes[o + 3];
        out[py * w + px] = a > alphaThreshold;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _visualBits = out;
      _loadingVisual = false;
    });
  }

  List<bool>? _decodeMask(ElementCollisionPixelMask? m, int w, int h) {
    if (m == null || m.widthPx != w || m.heightPx != h) {
      return null;
    }
    try {
      return ElementCollisionMaskCodec.decodePackedBits(
        widthPx: w,
        heightPx: h,
        dataBase64: m.dataBase64,
      );
    } catch (_) {
      return null;
    }
  }

  List<bool> _initialCollisionBits() {
    final decoded = _decodeMask(widget.profile?.collisionMask, _wPx, _hPx);
    if (decoded != null) {
      return decoded;
    }
    // Legacy : cellules → remplissage tuile par tuile.
    final out = List<bool>.filled(_wPx * _hPx, false);
    final cells = widget.profile?.cells ?? const <GridPos>[];
    for (final c in cells) {
      if (c.x < 0 ||
          c.y < 0 ||
          c.x >= widget.source.width ||
          c.y >= widget.source.height) {
        continue;
      }
      for (var ly = 0; ly < widget.tileHeight; ly++) {
        for (var lx = 0; lx < widget.tileWidth; lx++) {
          final px = c.x * widget.tileWidth + lx;
          final py = c.y * widget.tileHeight + ly;
          if (px < _wPx && py < _hPx) {
            out[py * _wPx + px] = true;
          }
        }
      }
    }
    return out;
  }

  List<bool> _initialOcclusionBits() {
    final decoded = _decodeMask(widget.profile?.occlusionMask, _wPx, _hPx);
    if (decoded != null) {
      return decoded;
    }
    return List<bool>.filled(_wPx * _hPx, false);
  }

  _MaskStrokeOperation _initialStrokeOperation() {
    final hasFineCollision = widget.profile?.collisionMask != null;
    final hasLegacyGridCollision =
        widget.profile?.cells.isNotEmpty == true && !hasFineCollision;
    return hasLegacyGridCollision
        ? _MaskStrokeOperation.erase
        : _MaskStrokeOperation.paint;
  }

  int _defaultBrushSizePx() {
    final tileEdge = math.min(widget.tileWidth, widget.tileHeight);
    return math.max(1, tileEdge ~/ 2);
  }

  List<int> _brushSizeOptions() {
    final tileEdge = math.max(1, math.min(widget.tileWidth, widget.tileHeight));
    final values = <int>{
      1,
      math.max(1, tileEdge ~/ 4),
      math.max(1, tileEdge ~/ 2),
      tileEdge,
    }.where((value) => value >= 1 && value <= tileEdge).toList()
      ..sort();
    return values;
  }

  double get _zoomScale => _zoomPercent / 100.0;

  ElementCollisionPixelMask _maskFromBits(List<bool> bits) {
    return ElementCollisionPixelMask(
      widthPx: _wPx,
      heightPx: _hPx,
      encoding: ElementCollisionMaskEncoding.packedBitsV1,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: _wPx,
        heightPx: _hPx,
        solidPixels: bits,
      ),
    );
  }

  void _emitProfile() {
    final collisionMask = _maskFromBits(_collisionBits);
    final occlusionMask = _maskFromBits(_occlusionBits);
    ElementCollisionPixelMask? visualMask;
    if (_visualBits != null && _visualBits!.length == _wPx * _hPx) {
      visualMask = _maskFromBits(_visualBits!);
    }
    final derivedCells = ElementCollisionMaskCodec.cellsFromPixelMask(
      mask: collisionMask,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      sourceWidthInTiles: widget.source.width,
      sourceHeightInTiles: widget.source.height,
    );
    widget.onProfileChanged(
      ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        padding: widget.profile?.padding ?? widget.draftPadding,
        visualMask: visualMask ?? widget.profile?.visualMask,
        collisionMask: collisionMask,
        occlusionMask: occlusionMask,
        cells: derivedCells,
      ),
    );
  }

  void _applyStroke(Offset local, Size boxSize, double boxHeight,
      {required bool erase}) {
    if (_mode == MaskSurfaceMode.preview) {
      return;
    }
    final pixel = _maskPixelFromLocal(local, boxSize, boxHeight);
    if (pixel == null) {
      return;
    }
    final next = _mode == MaskSurfaceMode.collisionPaint
        ? _collisionBits
        : _occlusionBits;
    _paintBrushFootprint(
      next,
      centerX: pixel.x,
      centerY: pixel.y,
      erase: erase,
    );
    setState(() => _hoverPixel = pixel);
    _emitProfile();
  }

  void _updateHoverPreview(Offset local, Size boxSize, double boxHeight) {
    if (_mode == MaskSurfaceMode.preview) {
      return;
    }
    final next = _maskPixelFromLocal(local, boxSize, boxHeight);
    if (next == _hoverPixel) {
      return;
    }
    setState(() => _hoverPixel = next);
  }

  math.Point<int>? _maskPixelFromLocal(
    Offset local,
    Size boxSize,
    double boxHeight,
  ) {
    final targetRect = fitCollisionPreviewRect(
      size: Size(boxSize.width, boxHeight),
      source: widget.source,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
    );
    if (!targetRect.contains(local)) {
      return null;
    }
    final lx = local.dx - targetRect.left;
    final ly = local.dy - targetRect.top;
    final px = (lx / targetRect.width * _wPx).floor().clamp(0, _wPx - 1);
    final py = (ly / targetRect.height * _hPx).floor().clamp(0, _hPx - 1);
    return math.Point<int>(px, py);
  }

  void _paintBrushFootprint(
    List<bool> bits, {
    required int centerX,
    required int centerY,
    required bool erase,
  }) {
    final size = _brushSizePx.clamp(1, math.max(_wPx, _hPx));
    final left = centerX - size ~/ 2;
    final top = centerY - size ~/ 2;
    for (var y = top; y < top + size; y++) {
      if (y < 0 || y >= _hPx) {
        continue;
      }
      for (var x = left; x < left + size; x++) {
        if (x < 0 || x >= _wPx) {
          continue;
        }
        bits[y * _wPx + x] = !erase;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final padding = widget.profile?.padding ?? widget.draftPadding;
    final truthSummary = summarizeElementCollisionTruth(widget.profile);
    final brushPreviewLabel =
        _mode == MaskSurfaceMode.preview || _hoverPixel == null
            ? null
            : 'Aperçu pinceau ${_brushSizePx}px';

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.015),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Masques pixel (visuel / collision / occlusion)',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${truthSummary.title}. ${truthSummary.description} ${truthSummary.detail}',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            'Masque collision : bloque le déplacement du joueur. '
            'Masque occlusion : rendu devant/derrière, ne bloque pas. '
            'Masque visuel : aide d’analyse / aperçu, ne bloque pas.',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          const SizedBox(height: 8),
          CupertinoSlidingSegmentedControl<int>(
            groupValue: _mode.index,
            children: const {
              0: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Text('Aperçu', style: TextStyle(fontSize: 11)),
              ),
              1: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child:
                    Text('Peindre collision', style: TextStyle(fontSize: 11)),
              ),
              2: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child:
                    Text('Peindre occlusion', style: TextStyle(fontSize: 11)),
              ),
            },
            onValueChanged: (int? v) {
              if (v != null) {
                setState(() => _mode = MaskSurfaceMode.values[v]);
              }
            },
          ),
          if (_mode != MaskSurfaceMode.preview) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CupertinoSlidingSegmentedControl<_MaskStrokeOperation>(
                  groupValue: _strokeOperation,
                  children: const {
                    _MaskStrokeOperation.paint: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Text('Peindre', style: TextStyle(fontSize: 11)),
                    ),
                    _MaskStrokeOperation.erase: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Text('Effacer', style: TextStyle(fontSize: 11)),
                    ),
                  },
                  onValueChanged: (next) {
                    if (next != null) {
                      setState(() => _strokeOperation = next);
                    }
                  },
                ),
                Text(
                  'Taille pinceau',
                  style: TextStyle(color: secondary, fontSize: 10),
                ),
                CupertinoSlidingSegmentedControl<int>(
                  groupValue: _brushSizePx,
                  children: {
                    for (final option in _brushSizeOptions())
                      option: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        child: Text(
                          '${option}px',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                  },
                  onValueChanged: (next) {
                    if (next != null) {
                      setState(() => _brushSizePx = next);
                    }
                  },
                ),
                Text(
                  'Zoom',
                  style: TextStyle(color: secondary, fontSize: 10),
                ),
                CupertinoSlidingSegmentedControl<int>(
                  groupValue: _zoomPercent,
                  children: const {
                    100: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Text('100%', style: TextStyle(fontSize: 11)),
                    ),
                    200: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Text('200%', style: TextStyle(fontSize: 11)),
                    ),
                    400: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Text('400%', style: TextStyle(fontSize: 11)),
                    ),
                  },
                  onValueChanged: (next) {
                    if (next != null) {
                      setState(() => _zoomPercent = next);
                    }
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              CupertinoSwitch(
                value: _showPixelGrid,
                onChanged: (v) => setState(() => _showPixelGrid = v),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Grille pixel (aide visuelle seulement)',
                  style: TextStyle(color: secondary, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Padding px: T${padding.top} R${padding.right} B${padding.bottom} L${padding.left} · '
            'cadre cyan = zone analysée par l’auto-génération',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          if (_loadingVisual)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Lecture du masque visuel depuis l’image…',
                style: TextStyle(color: secondary, fontSize: 10),
              ),
            ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final baseWidth = math.max(1.0, constraints.maxWidth);
              final baseHeight = math
                  .min(240, constraints.maxWidth * 0.72)
                  .toDouble()
                  .clamp(140.0, 260.0);
              final fittedBaseRect = fitCollisionPreviewRect(
                size: Size(baseWidth, baseHeight),
                source: widget.source,
                tileWidth: widget.tileWidth,
                tileHeight: widget.tileHeight,
              );
              final canvasSize = Size(
                fittedBaseRect.width * _zoomScale,
                fittedBaseRect.height * _zoomScale,
              );
              final scrollContentWidth = math.max(baseWidth, canvasSize.width);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: scrollContentWidth,
                  child: Align(
                    alignment: Alignment.center,
                    child: MouseRegion(
                      onExit: (_) {
                        if (_hoverPixel != null) {
                          setState(() => _hoverPixel = null);
                        }
                      },
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerHover: (e) {
                          _updateHoverPreview(
                            e.localPosition,
                            canvasSize,
                            canvasSize.height,
                          );
                        },
                        onPointerDown: (e) {
                          _applyStroke(
                            e.localPosition,
                            canvasSize,
                            canvasSize.height,
                            erase:
                                _strokeOperation == _MaskStrokeOperation.erase,
                          );
                        },
                        onPointerMove: (e) {
                          if (_mode == MaskSurfaceMode.preview) {
                            return;
                          }
                          // Le bouton secondaire reste une gomme rapide, même si
                          // l'outil visible est sur "Peindre".
                          final erase =
                              _strokeOperation == _MaskStrokeOperation.erase ||
                                  e.buttons == 2;
                          _applyStroke(
                            e.localPosition,
                            canvasSize,
                            canvasSize.height,
                            erase: erase,
                          );
                        },
                        child: SizedBox(
                          width: canvasSize.width,
                          height: canvasSize.height,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: CupertinoColors.separator
                                    .resolveFrom(context),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Semantics(
                                label: brushPreviewLabel,
                                child: CustomPaint(
                                  painter: _TripleMaskPixelPainter(
                                    image: widget.image,
                                    source: widget.source,
                                    tileWidth: widget.tileWidth,
                                    tileHeight: widget.tileHeight,
                                    padding: padding,
                                    visualBits: _visualBits,
                                    collisionBits: _collisionBits,
                                    occlusionBits: _occlusionBits,
                                    mode: _mode,
                                    showPixelGrid: _showPixelGrid,
                                    hoverPixel: _hoverPixel,
                                    brushSizePx: _brushSizePx,
                                    strokeOperation: _strokeOperation,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _legendRow(
            color: const Color(0xFFB71C1C).withValues(alpha: 0.55),
            border: const Color(0xFFB71C1C),
            text: 'Rouge : collision (bloque)',
            secondary: secondary,
          ),
          const SizedBox(height: 4),
          _legendRow(
            color: const Color(0xFF5E35B1).withValues(alpha: 0.45),
            border: const Color(0xFF4527A0),
            text: 'Violet : occlusion (couverture rendu, ne bloque pas)',
            secondary: secondary,
          ),
          const SizedBox(height: 4),
          _legendRow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
            border: const Color(0xFF1B5E20),
            text: 'Vert : passable (hors collision)',
            secondary: secondary,
          ),
          const SizedBox(height: 4),
          _legendRow(
            color: const Color(0xFF0277BD).withValues(alpha: 0.18),
            border: const Color(0xFF01579B),
            text: 'Bleu léger : matière visuelle (alpha) — repère seulement',
            secondary: secondary,
          ),
          const SizedBox(height: 6),
          Text(
            _mode == MaskSurfaceMode.preview
                ? 'Mode aperçu : édition désactivée.'
                : widget.profile?.collisionMask == null &&
                        widget.profile?.cells.isNotEmpty == true &&
                        _strokeOperation == _MaskStrokeOperation.erase
                    ? 'Profil grille détecté : Effacer est sélectionné pour creuser un masque fin depuis la grille existante.'
                    : _strokeOperation == _MaskStrokeOperation.erase
                        ? 'Mode ${_mode == MaskSurfaceMode.collisionPaint ? 'collision' : 'occlusion'} : '
                            'cliquez / tracez pour effacer.'
                        : 'Mode ${_mode == MaskSurfaceMode.collisionPaint ? 'collision' : 'occlusion'} : '
                            'cliquez / tracez pour peindre. Le bouton Effacer gomme la zone.',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _legendRow({
    required Color color,
    required Color border,
    required String text,
    required Color secondary,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: border, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: secondary, fontSize: 10),
          ),
        ),
      ],
    );
  }
}

/// Même géométrie que l’ancien `_fitCollisionPreviewRect` : garde le sprite **centré**
/// et le plus grand possible dans la boîte, **sans** déformer les pixels.
Rect fitCollisionPreviewRect({
  required Size size,
  required TilesetSourceRect source,
  required int tileWidth,
  required int tileHeight,
}) {
  final sourcePixelWidth = source.width * tileWidth.toDouble();
  final sourcePixelHeight = source.height * tileHeight.toDouble();
  if (sourcePixelWidth <= 0 || sourcePixelHeight <= 0) {
    return Rect.fromLTWH(0, 0, size.width, size.height);
  }
  final sourceAspect = sourcePixelWidth / sourcePixelHeight;
  final targetAspect = size.width <= 0 || size.height <= 0
      ? sourceAspect
      : size.width / size.height;
  if (sourceAspect > targetAspect) {
    final height = size.width / sourceAspect;
    final top = (size.height - height) / 2;
    return Rect.fromLTWH(0, top, size.width, height);
  }
  final width = size.height * sourceAspect;
  final left = (size.width - width) / 2;
  return Rect.fromLTWH(left, 0, width, size.height);
}

class _TripleMaskPixelPainter extends CustomPainter {
  _TripleMaskPixelPainter({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.padding,
    required this.visualBits,
    required this.collisionBits,
    required this.occlusionBits,
    required this.mode,
    required this.showPixelGrid,
    required this.hoverPixel,
    required this.brushSizePx,
    required this.strokeOperation,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final WarpTriggerPadding padding;
  final List<bool>? visualBits;
  final List<bool> collisionBits;
  final List<bool> occlusionBits;
  final MaskSurfaceMode mode;
  final bool showPixelGrid;
  final math.Point<int>? hoverPixel;
  final int brushSizePx;
  final _MaskStrokeOperation strokeOperation;

  @override
  void paint(Canvas canvas, Size size) {
    final wPx = math.max(1, source.width * tileWidth);
    final hPx = math.max(1, source.height * tileHeight);

    final targetRect = fitCollisionPreviewRect(
      size: size,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );

    // --- Fond damier (transparence lisible) ---
    _paintCheckerboard(canvas, targetRect);

    final sourceRect = Rect.fromLTWH(
      source.x * tileWidth.toDouble(),
      source.y * tileHeight.toDouble(),
      source.width * tileWidth.toDouble(),
      source.height * tileHeight.toDouble(),
    );
    if (sourceRect.right <= image.width && sourceRect.bottom <= image.height) {
      final imagePaint = Paint()
        ..isAntiAlias = false
        ..filterQuality = FilterQuality.none;
      canvas.drawImageRect(image, sourceRect, targetRect, imagePaint);
    }

    final scaleX = targetRect.width / wPx;
    final scaleY = targetRect.height / hPx;

    // --- Padding : zone exclue de l’analyse auto (assombrissement) ---
    final leftPad = padding.left * scaleX;
    final rightPad = padding.right * scaleX;
    final topPad = padding.top * scaleY;
    final bottomPad = padding.bottom * scaleY;
    final activeLeft = targetRect.left + leftPad;
    final activeTop = targetRect.top + topPad;
    final activeRight = targetRect.right - rightPad;
    final activeBottom = targetRect.bottom - bottomPad;
    final activeRect = Rect.fromLTRB(
      math.min(activeLeft, activeRight),
      math.min(activeTop, activeBottom),
      math.max(activeLeft, activeRight),
      math.max(activeTop, activeBottom),
    );
    _paintPaddingBands(
        canvas, targetRect, leftPad, rightPad, topPad, bottomPad);

    if (activeRect.width > 0 && activeRect.height > 0) {
      canvas.drawRect(
        activeRect,
        Paint()
          ..color = const Color(0xFF00BCD4).withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // --- Calque « matière visuelle » (optionnel) ---
    if (visualBits != null && visualBits!.length == wPx * hPx) {
      final vp = Paint()..style = PaintingStyle.fill;
      for (var py = 0; py < hPx; py++) {
        for (var px = 0; px < wPx; px++) {
          if (!visualBits![py * wPx + px]) {
            continue;
          }
          final cell = Rect.fromLTWH(
            targetRect.left + px * scaleX,
            targetRect.top + py * scaleY,
            scaleX,
            scaleY,
          );
          vp.color = const Color(0xFF0277BD).withValues(alpha: 0.12);
          canvas.drawRect(cell, vp);
        }
      }
    }

    // --- Collision : rouge ---
    for (var py = 0; py < hPx; py++) {
      for (var px = 0; px < wPx; px++) {
        final idx = py * wPx + px;
        if (idx >= collisionBits.length || !collisionBits[idx]) {
          continue;
        }
        final cell = Rect.fromLTWH(
          targetRect.left + px * scaleX,
          targetRect.top + py * scaleY,
          scaleX,
          scaleY,
        );
        canvas.drawRect(
          cell,
          Paint()..color = const Color(0xFFC62828).withValues(alpha: 0.38),
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = const Color(0xFFB71C1C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = mode == MaskSurfaceMode.collisionPaint ? 1.0 : 0.6,
        );
      }
    }

    // --- Occlusion : violet (au-dessus du rouge en alpha combiné) ---
    for (var py = 0; py < hPx; py++) {
      for (var px = 0; px < wPx; px++) {
        final idx = py * wPx + px;
        if (idx >= occlusionBits.length || !occlusionBits[idx]) {
          continue;
        }
        final cell = Rect.fromLTWH(
          targetRect.left + px * scaleX,
          targetRect.top + py * scaleY,
          scaleX,
          scaleY,
        );
        canvas.drawRect(
          cell,
          Paint()..color = const Color(0xFF5E35B1).withValues(alpha: 0.42),
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = const Color(0xFF4527A0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = mode == MaskSurfaceMode.occlusionPaint ? 1.0 : 0.55,
        );
      }
    }

    // --- Grille optionnelle (1 px logique) ---
    if (showPixelGrid) {
      final grid = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 0.5;
      for (var x = 0; x <= wPx; x += 4) {
        final dx = targetRect.left + x * scaleX;
        canvas.drawLine(
            Offset(dx, targetRect.top), Offset(dx, targetRect.bottom), grid);
      }
      for (var y = 0; y <= hPx; y += 4) {
        final dy = targetRect.top + y * scaleY;
        canvas.drawLine(
            Offset(targetRect.left, dy), Offset(targetRect.right, dy), grid);
      }
    }

    if (hoverPixel != null && mode != MaskSurfaceMode.preview) {
      _paintBrushPreview(
        canvas,
        targetRect,
        wPx: wPx,
        hPx: hPx,
        scaleX: scaleX,
        scaleY: scaleY,
      );
    }
  }

  void _paintBrushPreview(
    Canvas canvas,
    Rect targetRect, {
    required int wPx,
    required int hPx,
    required double scaleX,
    required double scaleY,
  }) {
    final center = hoverPixel!;
    final size = brushSizePx.clamp(1, math.max(wPx, hPx));
    final left = (center.x - size ~/ 2).clamp(0, wPx);
    final top = (center.y - size ~/ 2).clamp(0, hPx);
    final right = (center.x - size ~/ 2 + size).clamp(0, wPx);
    final bottom = (center.y - size ~/ 2 + size).clamp(0, hPx);
    if (right <= left || bottom <= top) {
      return;
    }
    final rect = Rect.fromLTRB(
      targetRect.left + left * scaleX,
      targetRect.top + top * scaleY,
      targetRect.left + right * scaleX,
      targetRect.top + bottom * scaleY,
    );
    final isErase = strokeOperation == _MaskStrokeOperation.erase;
    final baseColor = switch (mode) {
      MaskSurfaceMode.collisionPaint =>
        isErase ? const Color(0xFF4CAF50) : const Color(0xFFFFEB3B),
      MaskSurfaceMode.occlusionPaint => const Color(0xFFB388FF),
      MaskSurfaceMode.preview => const Color(0xFFFFFFFF),
    };
    canvas.drawRect(
      rect.inflate(2),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = baseColor.withValues(alpha: isErase ? 0.20 : 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = baseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintCheckerboard(Canvas canvas, Rect r) {
    const sq = 10.0;
    const light = Color(0xFFECEFF1);
    const dark = Color(0xFFD0D5D8);
    var row = 0;
    for (var y = r.top; y < r.bottom; y += sq) {
      var col = 0;
      for (var x = r.left; x < r.right; x += sq) {
        final cell = Rect.fromLTWH(
          x,
          y,
          math.min(sq, r.right - x),
          math.min(sq, r.bottom - y),
        );
        final paint = Paint()
          ..color = ((row + col) % 2 == 0) ? light : dark
          ..style = PaintingStyle.fill;
        canvas.drawRect(cell, paint);
        col++;
      }
      row++;
    }
  }

  void _paintPaddingBands(
    Canvas canvas,
    Rect targetRect,
    double leftPad,
    double rightPad,
    double topPad,
    double bottomPad,
  ) {
    final p = Paint()..color = Colors.black.withValues(alpha: 0.22);
    if (leftPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.left,
          targetRect.top,
          leftPad,
          targetRect.height,
        ),
        p,
      );
    }
    if (rightPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.right - rightPad,
          targetRect.top,
          rightPad,
          targetRect.height,
        ),
        p,
      );
    }
    if (topPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.left,
          targetRect.top,
          targetRect.width,
          topPad,
        ),
        p,
      );
    }
    if (bottomPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.left,
          targetRect.bottom - bottomPad,
          targetRect.width,
          bottomPad,
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TripleMaskPixelPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.source != source ||
        !_boolListEq(oldDelegate.collisionBits, collisionBits) ||
        !_boolListEq(oldDelegate.occlusionBits, occlusionBits) ||
        !_nullableBoolListEq(oldDelegate.visualBits, visualBits) ||
        oldDelegate.mode != mode ||
        oldDelegate.showPixelGrid != showPixelGrid ||
        oldDelegate.hoverPixel != hoverPixel ||
        oldDelegate.brushSizePx != brushSizePx ||
        oldDelegate.strokeOperation != strokeOperation ||
        oldDelegate.padding != padding;
  }

  static bool _boolListEq(List<bool> a, List<bool> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  static bool _nullableBoolListEq(List<bool>? a, List<bool>? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return _boolListEq(a, b);
  }
}
