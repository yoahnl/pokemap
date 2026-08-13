// Éditeur de masques triple couche pour les éléments projet (PokeMap).
// Voir le rapport : reports/POKEMAP_MASKS_OCCLUSION_PLAYER_V2_REPORT.md

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:map_core/map_core.dart';

import '../../application/models/element_collision_truth_summary.dart';
import '../../application/services/editor_performance_telemetry.dart';
import '../../application/services/fine_mask_performance_telemetry.dart';
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

enum _MaskStrokeOperation { paint, erase }

final class ElementCollisionFineMaskController {
  ElementCollisionProfile? Function()? _commit;
  VoidCallback? _cancel;

  ElementCollisionProfile? commitActiveStroke() => _commit?.call();
  void cancelActiveStroke() => _cancel?.call();

  void _attach({
    required ElementCollisionProfile? Function() commit,
    required VoidCallback cancel,
  }) {
    _commit = commit;
    _cancel = cancel;
  }

  void _detach() {
    _commit = null;
    _cancel = null;
  }
}

enum FineMaskLayer { collision, occlusion }

@immutable
final class FineMaskMutation {
  const FineMaskMutation({
    required this.changedPixelCount,
    required this.dirtyBounds,
  });

  final int changedPixelCount;
  final Rect dirtyBounds;
}

final class FineMaskDraft {
  FineMaskDraft._({
    required this.width,
    required this.height,
    required Uint8List collisionBytes,
    required Uint8List occlusionBytes,
  }) : _collisionBytes = collisionBytes,
       _occlusionBytes = occlusionBytes;

  factory FineMaskDraft.empty({required int width, required int height}) {
    final length = width * height;
    return FineMaskDraft._(
      width: width,
      height: height,
      collisionBytes: Uint8List(length),
      occlusionBytes: Uint8List(length),
    );
  }

  factory FineMaskDraft.fromMasks({
    required int width,
    required int height,
    required List<bool> collision,
    required List<bool> occlusion,
  }) {
    final length = width * height;
    final collisionBytes = Uint8List(length);
    final occlusionBytes = Uint8List(length);
    for (var index = 0; index < length; index += 1) {
      if (index < collision.length && collision[index]) {
        collisionBytes[index] = 1;
      }
      if (index < occlusion.length && occlusion[index]) {
        occlusionBytes[index] = 1;
      }
    }
    return FineMaskDraft._(
      width: width,
      height: height,
      collisionBytes: collisionBytes,
      occlusionBytes: occlusionBytes,
    );
  }

  final int width;
  final int height;
  final Uint8List _collisionBytes;
  final Uint8List _occlusionBytes;

  int get storageByteLength =>
      _collisionBytes.lengthInBytes + _occlusionBytes.lengthInBytes;

  Uint8List get collisionBytes => _collisionBytes;
  Uint8List get occlusionBytes => _occlusionBytes;

  bool collisionAt(int x, int y) => _collisionBytes[y * width + x] != 0;

  FineMaskStroke beginStroke(FineMaskLayer layer) {
    return FineMaskStroke._(
      width: width,
      height: height,
      layer: layer,
      bytes: layer == FineMaskLayer.collision
          ? _collisionBytes
          : _occlusionBytes,
    );
  }

  FineMaskMutation paintCollision({
    required int centerX,
    required int centerY,
    required int brushSize,
    required bool erase,
  }) {
    final stroke = beginStroke(FineMaskLayer.collision);
    return stroke.paint(
      centerX: centerX,
      centerY: centerY,
      brushSize: brushSize,
      erase: erase,
    );
  }

  List<bool> collisionBoolList() =>
      _collisionBytes.map((value) => value != 0).toList(growable: false);

  List<bool> occlusionBoolList() =>
      _occlusionBytes.map((value) => value != 0).toList(growable: false);
}

final class FineMaskStroke {
  FineMaskStroke._({
    required this.width,
    required this.height,
    required this.layer,
    required Uint8List bytes,
  }) : _bytes = bytes,
       _before = Uint8List.fromList(bytes);

  final int width;
  final int height;
  final FineMaskLayer layer;
  final Uint8List _bytes;
  final Uint8List _before;
  bool _closed = false;
  bool _dirty = false;

  bool get isDirty => _dirty;

  FineMaskMutation paint({
    required int centerX,
    required int centerY,
    required int brushSize,
    required bool erase,
  }) {
    if (_closed) {
      return const FineMaskMutation(
        changedPixelCount: 0,
        dirtyBounds: Rect.zero,
      );
    }
    final size = brushSize.clamp(1, math.max(width, height));
    final left = centerX - size ~/ 2;
    final top = centerY - size ~/ 2;
    final value = erase ? 0 : 1;
    var changed = 0;
    var minX = width;
    var minY = height;
    var maxX = -1;
    var maxY = -1;
    for (var y = top; y < top + size; y += 1) {
      if (y < 0 || y >= height) continue;
      for (var x = left; x < left + size; x += 1) {
        if (x < 0 || x >= width) continue;
        final index = y * width + x;
        if (_bytes[index] == value) continue;
        _bytes[index] = value;
        changed += 1;
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);
      }
    }
    if (changed == 0) {
      return const FineMaskMutation(
        changedPixelCount: 0,
        dirtyBounds: Rect.zero,
      );
    }
    _dirty = true;
    return FineMaskMutation(
      changedPixelCount: changed,
      dirtyBounds: Rect.fromLTRB(
        minX.toDouble(),
        minY.toDouble(),
        (maxX + 1).toDouble(),
        (maxY + 1).toDouble(),
      ),
    );
  }

  void commit() {
    _closed = true;
  }

  void rollback() {
    if (_closed) return;
    _bytes.setAll(0, _before);
    _closed = true;
  }
}

final class FineMaskVisualAlphaRegion {
  const FineMaskVisualAlphaRegion({
    required this.width,
    required this.height,
    required this.alphaBytes,
  });

  final int width;
  final int height;
  final Uint8List alphaBytes;
  int get readbackPixelCount => alphaBytes.length;
}

typedef FineMaskVisualAlphaReader =
    Future<FineMaskVisualAlphaRegion> Function({
      required ui.Image image,
      required Rect sourceRect,
    });

Future<FineMaskVisualAlphaRegion> readFineMaskVisualAlphaRegion({
  required ui.Image image,
  required Rect sourceRect,
}) async {
  final width = math.max(1, sourceRect.width.ceil());
  final height = math.max(1, sourceRect.height.ceil());
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final imageBounds = Rect.fromLTWH(
    0,
    0,
    image.width.toDouble(),
    image.height.toDouble(),
  );
  final clipped = sourceRect.intersect(imageBounds);
  if (!clipped.isEmpty) {
    final destination = Rect.fromLTWH(
      clipped.left - sourceRect.left,
      clipped.top - sourceRect.top,
      clipped.width,
      clipped.height,
    );
    canvas.drawImageRect(
      image,
      clipped,
      destination,
      Paint()
        ..isAntiAlias = false
        ..filterQuality = FilterQuality.none,
    );
  }
  final picture = recorder.endRecording();
  final cropped = await picture.toImage(width, height);
  picture.dispose();
  try {
    final data = await cropped.toByteData(format: ui.ImageByteFormat.rawRgba);
    final alpha = Uint8List(width * height);
    if (data != null) {
      final rgba = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      for (var index = 0; index < alpha.length; index += 1) {
        alpha[index] = rgba[index * 4 + 3];
      }
    }
    return FineMaskVisualAlphaRegion(
      width: width,
      height: height,
      alphaBytes: alpha,
    );
  } finally {
    cropped.dispose();
  }
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
    this.controller,
    this.visualAlphaReader = readFineMaskVisualAlphaRegion,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionProfile? profile;
  final WarpTriggerPadding draftPadding;
  final ValueChanged<ElementCollisionProfile?> onProfileChanged;
  final ElementCollisionFineMaskController? controller;
  final FineMaskVisualAlphaReader visualAlphaReader;

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

  late FineMaskDraft _draft;
  late FineMaskPaintRunCache _collisionRunCache;
  late FineMaskPaintRunCache _occlusionRunCache;
  FineMaskPaintRunCache? _visualRunCache;
  Uint8List? _visualBits;
  bool _loadingVisual = false;
  FineMaskStroke? _activeStroke;
  int _maskRevision = 0;
  int _visualLoadGeneration = 0;

  int get _wPx => math.max(1, widget.source.width * widget.tileWidth);
  int get _hPx => math.max(1, widget.source.height * widget.tileHeight);

  @override
  void initState() {
    super.initState();
    _resetDraft();
    _strokeOperation = _initialStrokeOperation();
    _brushSizePx = _defaultBrushSizePx();
    _scheduleVisualLoad();
    widget.controller?._attach(commit: _commitStroke, cancel: _cancelStroke);
  }

  @override
  void didUpdateWidget(covariant ElementCollisionTripleMaskEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach();
      widget.controller?._attach(commit: _commitStroke, cancel: _cancelStroke);
    }
    if (oldWidget.profile != widget.profile ||
        oldWidget.source != widget.source ||
        oldWidget.tileWidth != widget.tileWidth ||
        oldWidget.tileHeight != widget.tileHeight) {
      setState(() {
        _activeStroke?.rollback();
        _activeStroke = null;
        _resetDraft();
        _visualBits = null;
        _visualRunCache = null;
        _loadingVisual = false;
        _hoverPixel = null;
        _maskRevision += 1;
      });
      _scheduleVisualLoad();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  void _resetDraft() {
    _draft = FineMaskDraft.fromMasks(
      width: _wPx,
      height: _hPx,
      collision: _initialCollisionBits(),
      occlusion: _initialOcclusionBits(),
    );
    _collisionRunCache = FineMaskPaintRunCache(
      _draft.collisionBytes,
      width: _wPx,
      height: _hPx,
    );
    _occlusionRunCache = FineMaskPaintRunCache(
      _draft.occlusionBytes,
      width: _wPx,
      height: _hPx,
    );
  }

  void _scheduleVisualLoad() {
    final generation = ++_visualLoadGeneration;
    final decoded = _decodeMask(widget.profile?.visualMask, _wPx, _hPx);
    if (decoded != null) {
      setState(() {
        _visualBits = decoded;
        _visualRunCache = FineMaskPaintRunCache(
          decoded,
          width: _wPx,
          height: _hPx,
        );
        _maskRevision += 1;
      });
      return;
    }
    _loadVisualFromImageAlpha(
      generation: generation,
      image: widget.image,
      sourceRect: Rect.fromLTWH(
        widget.source.x * widget.tileWidth.toDouble(),
        widget.source.y * widget.tileHeight.toDouble(),
        _wPx.toDouble(),
        _hPx.toDouble(),
      ),
      width: _wPx,
      height: _hPx,
    );
  }

  /// Construit le masque « visible » depuis l’alpha du PNG si aucun [visualMask]
  /// n’est persisté — cohérent avec l’auto-génération (seuil alpha).
  Future<void> _loadVisualFromImageAlpha({
    required int generation,
    required ui.Image image,
    required Rect sourceRect,
    required int width,
    required int height,
  }) async {
    final span = EditorPerformanceTelemetry.startSpan(
      FineMaskPerformanceSpanName.readback,
    );
    try {
      setState(() {
        _loadingVisual = true;
      });
      final region = await widget.visualAlphaReader(
        image: image,
        sourceRect: sourceRect,
      );
      if (!mounted || generation != _visualLoadGeneration) {
        return;
      }
      final out = Uint8List(width * height);
      const alphaThreshold = 12;
      for (var index = 0; index < out.length; index += 1) {
        out[index] = region.alphaBytes[index] > alphaThreshold ? 1 : 0;
      }
      if (!mounted || generation != _visualLoadGeneration) {
        return;
      }
      setState(() {
        _visualBits = out;
        _visualRunCache = FineMaskPaintRunCache(
          out,
          width: width,
          height: height,
        );
        _loadingVisual = false;
        _maskRevision += 1;
      });
    } finally {
      span?.finish();
    }
  }

  Uint8List? _decodeMask(ElementCollisionPixelMask? m, int w, int h) {
    if (m == null || m.widthPx != w || m.heightPx != h) {
      return null;
    }
    try {
      final decoded = EditorPerformanceTelemetry.decodePackedCollisionMask(
        widthPx: w,
        heightPx: h,
        dataBase64: m.dataBase64,
      );
      return Uint8List.fromList(
        decoded.map((value) => value ? 1 : 0).toList(growable: false),
      );
    } catch (_) {
      return null;
    }
  }

  List<bool> _initialCollisionBits() {
    final decoded = _decodeMask(widget.profile?.collisionMask, _wPx, _hPx);
    if (decoded != null) {
      return decoded.map((value) => value != 0).toList(growable: false);
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
      return decoded.map((value) => value != 0).toList(growable: false);
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
    }.where((value) => value >= 1 && value <= tileEdge).toList()..sort();
    return values;
  }

  double get _zoomScale => _zoomPercent / 100.0;

  ElementCollisionPixelMask _maskFromBits(Uint8List bits) {
    return ElementCollisionPixelMask(
      widthPx: _wPx,
      heightPx: _hPx,
      encoding: ElementCollisionMaskEncoding.packedBitsV1,
      dataBase64: EditorPerformanceTelemetry.encodePackedCollisionMask(
        widthPx: _wPx,
        heightPx: _hPx,
        solidPixels: bits.map((value) => value != 0).toList(growable: false),
      ),
    );
  }

  ElementCollisionProfile _emitProfile() {
    final collisionMask = _maskFromBits(_draft.collisionBytes);
    final occlusionMask = _maskFromBits(_draft.occlusionBytes);
    ElementCollisionPixelMask? visualMask;
    if (_visualBits != null && _visualBits!.length == _wPx * _hPx) {
      visualMask = _maskFromBits(_visualBits!);
    }
    final derivedCells = EditorPerformanceTelemetry.collisionCellsFromPixelMask(
      mask: collisionMask,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      sourceWidthInTiles: widget.source.width,
      sourceHeightInTiles: widget.source.height,
    );
    final profile = ElementCollisionProfile(
      source: ElementCollisionProfileSource.manual,
      padding: widget.profile?.padding ?? widget.draftPadding,
      visualMask: visualMask ?? widget.profile?.visualMask,
      collisionMask: collisionMask,
      occlusionMask: occlusionMask,
      cells: derivedCells,
    );
    widget.onProfileChanged(profile);
    return profile;
  }

  void _applyStroke(
    Offset local,
    Size boxSize,
    double boxHeight, {
    required bool erase,
  }) {
    final stroke = _activeStroke;
    if (_mode == MaskSurfaceMode.preview || stroke == null) {
      return;
    }
    final pixel = _maskPixelFromLocal(local, boxSize, boxHeight);
    if (pixel == null) {
      return;
    }
    final mutation = stroke.paint(
      centerX: pixel.x,
      centerY: pixel.y,
      brushSize: _brushSizePx,
      erase: erase,
    );
    if (mutation.changedPixelCount > 0) {
      final cache = stroke.layer == FineMaskLayer.collision
          ? _collisionRunCache
          : _occlusionRunCache;
      cache.rebuild(mutation.dirtyBounds);
      _maskRevision += 1;
    }
    setState(() => _hoverPixel = pixel);
  }

  void _beginStroke() {
    if (_mode == MaskSurfaceMode.preview) return;
    _activeStroke?.rollback();
    _activeStroke = _draft.beginStroke(
      _mode == MaskSurfaceMode.collisionPaint
          ? FineMaskLayer.collision
          : FineMaskLayer.occlusion,
    );
  }

  ElementCollisionProfile? _commitStroke() {
    final stroke = _activeStroke;
    if (stroke == null) return null;
    final span = EditorPerformanceTelemetry.startSpan(
      FineMaskPerformanceSpanName.commit,
    );
    try {
      _activeStroke = null;
      stroke.commit();
      if (stroke.isDirty) return _emitProfile();
      return null;
    } finally {
      span?.finish();
    }
  }

  void _cancelStroke() {
    final stroke = _activeStroke;
    if (stroke == null) return;
    _activeStroke = null;
    stroke.rollback();
    final cache = stroke.layer == FineMaskLayer.collision
        ? _collisionRunCache
        : _occlusionRunCache;
    cache.rebuild(Rect.fromLTWH(0, 0, _wPx.toDouble(), _hPx.toDouble()));
    _maskRevision += 1;
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final span = EditorPerformanceTelemetry.startSpan(
      FineMaskPerformanceSpanName.build,
    );
    try {
      return _build(context);
    } finally {
      span?.finish();
    }
  }

  Widget _build(BuildContext context) {
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
                child: Text(
                  'Peindre collision',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              2: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Text(
                  'Peindre occlusion',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            },
            onValueChanged: (int? v) {
              if (v != null) {
                _commitStroke();
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text('Peindre', style: TextStyle(fontSize: 11)),
                    ),
                    _MaskStrokeOperation.erase: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
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
                Text('Zoom', style: TextStyle(color: secondary, fontSize: 10)),
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
                          _beginStroke();
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
                          final span = EditorPerformanceTelemetry.startSpan(
                            FineMaskPerformanceSpanName.pointerMove,
                          );
                          try {
                            _applyStroke(
                              e.localPosition,
                              canvasSize,
                              canvasSize.height,
                              erase: erase,
                            );
                          } finally {
                            span?.finish();
                          }
                        },
                        onPointerUp: (_) => _commitStroke(),
                        onPointerCancel: (_) => _cancelStroke(),
                        child: SizedBox(
                          width: canvasSize.width,
                          height: canvasSize.height,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: CupertinoColors.separator.resolveFrom(
                                  context,
                                ),
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
                                    visualRuns: _visualRunCache,
                                    collisionRuns: _collisionRunCache,
                                    occlusionRuns: _occlusionRunCache,
                                    maskRevision: _maskRevision,
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
          child: Text(text, style: TextStyle(color: secondary, fontSize: 10)),
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

@immutable
final class CollisionMaskPaintRun {
  const CollisionMaskPaintRun({
    required this.x,
    required this.y,
    required this.length,
  });

  final int x;
  final int y;
  final int length;

  @override
  bool operator ==(Object other) =>
      other is CollisionMaskPaintRun &&
      x == other.x &&
      y == other.y &&
      length == other.length;

  @override
  int get hashCode => Object.hash(x, y, length);
}

List<CollisionMaskPaintRun> buildCollisionMaskPaintRuns(
  List<Object> bits, {
  required int width,
  required int height,
}) {
  final runs = <CollisionMaskPaintRun>[];
  for (var y = 0; y < height; y += 1) {
    var x = 0;
    while (x < width) {
      final index = y * width + x;
      if (index >= bits.length || !_maskValueIsSet(bits[index])) {
        x += 1;
        continue;
      }
      final start = x;
      do {
        x += 1;
      } while (x < width &&
          y * width + x < bits.length &&
          _maskValueIsSet(bits[y * width + x]));
      runs.add(CollisionMaskPaintRun(x: start, y: y, length: x - start));
    }
  }
  return runs;
}

bool _maskValueIsSet(Object value) => value == true || value == 1;

final class FineMaskPaintRunCache {
  FineMaskPaintRunCache(this._bits, {required this.width, required this.height})
    : _chunkColumns = (width + _chunkSize - 1) ~/ _chunkSize,
      _rowChunks = List<List<List<CollisionMaskPaintRun>>>.generate(
        height,
        (_) => List<List<CollisionMaskPaintRun>>.filled(
          (width + _chunkSize - 1) ~/ _chunkSize,
          const <CollisionMaskPaintRun>[],
        ),
      ) {
    rebuild(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  }

  static const int _chunkSize = 32;
  final Uint8List _bits;
  final int width;
  final int height;
  final int _chunkColumns;
  final List<List<List<CollisionMaskPaintRun>>> _rowChunks;
  int lastRebuiltPixelCount = 0;

  List<CollisionMaskPaintRun> chunkRunsForRow(int y, int chunkX) =>
      _rowChunks[y][chunkX];

  Iterable<CollisionMaskPaintRun> get runs sync* {
    for (var y = 0; y < height; y += 1) {
      CollisionMaskPaintRun? pending;
      for (var chunkX = 0; chunkX < _chunkColumns; chunkX += 1) {
        for (final run in _rowChunks[y][chunkX]) {
          if (pending != null && pending.x + pending.length == run.x) {
            pending = CollisionMaskPaintRun(
              x: pending.x,
              y: y,
              length: pending.length + run.length,
            );
          } else {
            if (pending != null) yield pending;
            pending = run;
          }
        }
      }
      if (pending != null) yield pending;
    }
  }

  void rebuild(Rect dirtyBounds) {
    if (dirtyBounds.isEmpty) return;
    lastRebuiltPixelCount = 0;
    final firstY = dirtyBounds.top.floor().clamp(0, height - 1);
    final lastY = (dirtyBounds.bottom.ceil() - 1).clamp(0, height - 1);
    final firstChunkX =
        dirtyBounds.left.floor().clamp(0, width - 1) ~/ _chunkSize;
    final lastChunkX =
        (dirtyBounds.right.ceil() - 1).clamp(0, width - 1) ~/ _chunkSize;
    for (var y = firstY; y <= lastY; y += 1) {
      for (var chunkX = firstChunkX; chunkX <= lastChunkX; chunkX += 1) {
        final runs = <CollisionMaskPaintRun>[];
        final startX = chunkX * _chunkSize;
        final endX = math.min(width, startX + _chunkSize);
        lastRebuiltPixelCount += endX - startX;
        var x = startX;
        while (x < endX) {
          if (_bits[y * width + x] == 0) {
            x += 1;
            continue;
          }
          final start = x;
          do {
            x += 1;
          } while (x < endX && _bits[y * width + x] != 0);
          runs.add(CollisionMaskPaintRun(x: start, y: y, length: x - start));
        }
        _rowChunks[y][chunkX] = List<CollisionMaskPaintRun>.unmodifiable(runs);
      }
    }
  }
}

class _TripleMaskPixelPainter extends CustomPainter {
  _TripleMaskPixelPainter({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.padding,
    required this.visualRuns,
    required this.collisionRuns,
    required this.occlusionRuns,
    required this.maskRevision,
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
  final FineMaskPaintRunCache? visualRuns;
  final FineMaskPaintRunCache collisionRuns;
  final FineMaskPaintRunCache occlusionRuns;
  final int maskRevision;
  final MaskSurfaceMode mode;
  final bool showPixelGrid;
  final math.Point<int>? hoverPixel;
  final int brushSizePx;
  final _MaskStrokeOperation strokeOperation;

  @override
  void paint(Canvas canvas, Size size) {
    final span = EditorPerformanceTelemetry.startSpan(
      FineMaskPerformanceSpanName.paint,
    );
    try {
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
      if (sourceRect.right <= image.width &&
          sourceRect.bottom <= image.height) {
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
        canvas,
        targetRect,
        leftPad,
        rightPad,
        topPad,
        bottomPad,
      );

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
      if (visualRuns != null) {
        final paint = Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFF0277BD).withValues(alpha: 0.12);
        for (final run in visualRuns!.runs) {
          canvas.drawRect(_runRect(run, targetRect, scaleX, scaleY), paint);
        }
      }

      final collisionFill = Paint()
        ..color = const Color(0xFFC62828).withValues(alpha: 0.38);
      final collisionStroke = Paint()
        ..color = const Color(0xFFB71C1C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = mode == MaskSurfaceMode.collisionPaint ? 1.0 : 0.6;
      for (final run in collisionRuns.runs) {
        final rect = _runRect(run, targetRect, scaleX, scaleY);
        canvas.drawRect(rect, collisionFill);
        canvas.drawRect(rect, collisionStroke);
      }

      final occlusionFill = Paint()
        ..color = const Color(0xFF5E35B1).withValues(alpha: 0.42);
      final occlusionStroke = Paint()
        ..color = const Color(0xFF4527A0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = mode == MaskSurfaceMode.occlusionPaint ? 1.0 : 0.55;
      for (final run in occlusionRuns.runs) {
        final rect = _runRect(run, targetRect, scaleX, scaleY);
        canvas.drawRect(rect, occlusionFill);
        canvas.drawRect(rect, occlusionStroke);
      }

      // --- Grille optionnelle (1 px logique) ---
      if (showPixelGrid) {
        final grid = Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..strokeWidth = 0.5;
        for (var x = 0; x <= wPx; x += 4) {
          final dx = targetRect.left + x * scaleX;
          canvas.drawLine(
            Offset(dx, targetRect.top),
            Offset(dx, targetRect.bottom),
            grid,
          );
        }
        for (var y = 0; y <= hPx; y += 4) {
          final dy = targetRect.top + y * scaleY;
          canvas.drawLine(
            Offset(targetRect.left, dy),
            Offset(targetRect.right, dy),
            grid,
          );
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
    } finally {
      span?.finish();
    }
  }

  Rect _runRect(
    CollisionMaskPaintRun run,
    Rect targetRect,
    double scaleX,
    double scaleY,
  ) {
    return Rect.fromLTWH(
      targetRect.left + run.x * scaleX,
      targetRect.top + run.y * scaleY,
      run.length * scaleX,
      scaleY,
    );
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
        oldDelegate.maskRevision != maskRevision ||
        oldDelegate.mode != mode ||
        oldDelegate.showPixelGrid != showPixelGrid ||
        oldDelegate.hoverPixel != hoverPixel ||
        oldDelegate.brushSizePx != brushSizePx ||
        oldDelegate.strokeOperation != strokeOperation ||
        oldDelegate.padding != padding;
  }
}
