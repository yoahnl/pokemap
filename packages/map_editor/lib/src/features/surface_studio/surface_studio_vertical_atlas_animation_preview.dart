import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_grid_overlay.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

/// Rectangle source (pixels atlas) pour une frame d’une colonne — preview locale uniquement.
@immutable
class SurfaceStudioVerticalAtlasAnimationSourceRect {
  const SurfaceStudioVerticalAtlasAnimationSourceRect({
    required this.sourceX,
    required this.sourceY,
    required this.sourceWidth,
    required this.sourceHeight,
  });

  final int sourceX;
  final int sourceY;
  final int sourceWidth;
  final int sourceHeight;
}

/// Résumé affichable pour la preview locale (aucune persistance catalogue).
@immutable
class SurfaceStudioVerticalAtlasAnimationPreviewSummary {
  const SurfaceStudioVerticalAtlasAnimationPreviewSummary({
    required this.columnIndex,
    required this.role,
    required this.frameCount,
    required this.currentFrameIndex,
    required this.tileWidth,
    required this.tileHeight,
    required this.sourceRect,
  });

  final int columnIndex;
  final SurfaceVariantRole role;
  final int frameCount;
  final int currentFrameIndex;
  final int tileWidth;
  final int tileHeight;
  final SurfaceStudioVerticalAtlasAnimationSourceRect sourceRect;
}

/// Calcule le rectangle source ; [frameIndex] est borné puis cyclé sur [0, frameCount-1].
SurfaceStudioVerticalAtlasAnimationPreviewSummary?
    surfaceStudioVerticalAtlasAnimationPreviewSummary({
  required int columnIndex,
  required SurfaceVariantRole role,
  required int frameIndex,
  required int tileWidth,
  required int tileHeight,
  required int rows,
}) {
  if (tileWidth <= 0 || tileHeight <= 0 || rows <= 0) {
    return null;
  }
  final frameCount = rows;
  final idx = frameIndex % frameCount;
  final sx = columnIndex * tileWidth;
  final sy = idx * tileHeight;
  return SurfaceStudioVerticalAtlasAnimationPreviewSummary(
    columnIndex: columnIndex,
    role: role,
    frameCount: frameCount,
    currentFrameIndex: idx,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    sourceRect: SurfaceStudioVerticalAtlasAnimationSourceRect(
      sourceX: sx,
      sourceY: sy,
      sourceWidth: tileWidth,
      sourceHeight: tileHeight,
    ),
  );
}

/// Dessine un crop de [image] vers la taille du canvas (preview locale).
class SurfaceStudioAtlasFrameCropPainter extends CustomPainter {
  SurfaceStudioAtlasFrameCropPainter({
    required this.image,
    required this.srcRect,
  });

  final ui.Image image;
  final Rect srcRect;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      image,
      srcRect,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant SurfaceStudioAtlasFrameCropPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.srcRect != srcRect;
  }
}

/// Preview locale des frames d’une colonne mappée — ne crée aucune animation catalogue.
class SurfaceStudioVerticalAtlasAnimationPreview extends StatefulWidget {
  const SurfaceStudioVerticalAtlasAnimationPreview({
    super.key,
    required this.label,
    required this.subtle,
    required this.mappingDraft,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    this.resolvedImagePath,
  });

  static const ValueKey<String> sectionKey =
      ValueKey<String>('surface_studio_vertical_atlas_animation_preview');

  final Color label;
  final Color subtle;
  final SurfaceStudioColumnRoleMappingDraft mappingDraft;
  final int? tileWidth;
  final int? tileHeight;
  final int? columns;
  final int? rows;
  final String? resolvedImagePath;

  @override
  State<SurfaceStudioVerticalAtlasAnimationPreview> createState() =>
      _SurfaceStudioVerticalAtlasAnimationPreviewState();
}

class _SurfaceStudioVerticalAtlasAnimationPreviewState
    extends State<SurfaceStudioVerticalAtlasAnimationPreview> {
  static const int _msPerFrame = 120;

  int? _selectedColumn;
  int _frameIndex = 0;
  bool _playing = false;
  Timer? _playTimer;
  ui.Image? _decoded;
  Uint8List? _bytes;
  String? _cachedPath;

  @override
  void dispose() {
    _playTimer?.cancel();
    _decoded?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioVerticalAtlasAnimationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pathChanged = widget.resolvedImagePath != oldWidget.resolvedImagePath;
    final draftChanged = widget.mappingDraft != oldWidget.mappingDraft;
    final layoutChanged = widget.tileWidth != oldWidget.tileWidth ||
        widget.tileHeight != oldWidget.tileHeight ||
        widget.rows != oldWidget.rows ||
        widget.columns != oldWidget.columns;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (pathChanged) {
        _reloadImageBytes();
      }
      if (pathChanged || draftChanged || layoutChanged) {
        _syncSelectedColumn();
        if (layoutChanged) {
          final r = widget.rows;
          if (r != null && r > 0) {
            setState(() {
              _frameIndex = _frameIndex % r;
            });
          }
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _reloadImageBytes();
      _syncSelectedColumn();
    });
  }

  void _syncSelectedColumn() {
    final assigned = widget.mappingDraft.assignments
        .where((a) => a.role != null)
        .map((a) => a.columnIndex)
        .toList()
      ..sort();
    if (assigned.isEmpty) {
      if (_selectedColumn != null) {
        setState(() {
          _selectedColumn = null;
          _frameIndex = 0;
        });
      }
      return;
    }
    if (_selectedColumn == null || !assigned.contains(_selectedColumn)) {
      setState(() {
        _selectedColumn = assigned.first;
        _frameIndex = 0;
      });
    }
  }

  void _reloadImageBytes() {
    final p = widget.resolvedImagePath?.trim();
    if (p == null || p.isEmpty) {
      if (_cachedPath != null || _bytes != null) {
        setState(() {
          _cachedPath = null;
          _bytes = null;
          _decoded?.dispose();
          _decoded = null;
        });
      }
      return;
    }
    if (_cachedPath == p && _bytes != null) {
      return;
    }
    _cachedPath = p;
    try {
      final b = File(p).readAsBytesSync();
      setState(() {
        _bytes = b;
        _decoded?.dispose();
        _decoded = null;
      });
      ui.decodeImageFromList(b, (ui.Image img) {
        if (!mounted) {
          img.dispose();
          return;
        }
        setState(() {
          _decoded?.dispose();
          _decoded = img;
        });
      });
    } catch (_) {
      setState(() {
        _bytes = null;
        _decoded?.dispose();
        _decoded = null;
      });
    }
  }

  void _togglePlay() {
    if (_playing) {
      _playTimer?.cancel();
      setState(() => _playing = false);
      return;
    }
    final tw = widget.tileWidth;
    final th = widget.tileHeight;
    final r = widget.rows;
    if (tw == null || th == null || r == null || r <= 0) {
      return;
    }
    setState(() => _playing = true);
    _playTimer?.cancel();
    _playTimer = Timer.periodic(const Duration(milliseconds: _msPerFrame), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _frameIndex = (_frameIndex + 1) % r;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gridOk = surfaceStudioAtlasGridOverlayDraftValid(
      widget.tileWidth,
      widget.tileHeight,
      widget.columns,
      widget.rows,
    );
    final tw = widget.tileWidth;
    final th = widget.tileHeight;
    final rws = widget.rows;

    return Container(
      key: SurfaceStudioVerticalAtlasAnimationPreview.sectionKey,
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
            'Aperçu animation par colonne',
            style: TextStyle(
              color: widget.label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          if (!gridOk) ...[
            Text(
              'Corrigez la grille avant de prévisualiser une animation.',
              style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
            ),
          ] else if (widget.mappingDraft.assignments
              .where((a) => a.role != null)
              .isEmpty) ...[
            Text(
              'Assignez un rôle à une colonne pour prévisualiser son animation.',
              style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
            ),
          ] else ...[
            _buildControls(context, tw!, th!, rws!),
          ],
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    int tw,
    int th,
    int rws,
  ) {
    final sel = _selectedColumn;
    if (sel == null) {
      return const SizedBox.shrink();
    }
    final role = widget.mappingDraft.roleForColumn(sel);
    if (role == null) {
      return const SizedBox.shrink();
    }
    final summary = surfaceStudioVerticalAtlasAnimationPreviewSummary(
      columnIndex: sel,
      role: role,
      frameIndex: _frameIndex,
      tileWidth: tw,
      tileHeight: th,
      rows: rws,
    );
    if (summary == null) {
      return const SizedBox.shrink();
    }
    final sr = summary.sourceRect;
    final assigned = widget.mappingDraft.assignments
        .where((a) => a.role != null)
        .toList()
      ..sort((a, b) => a.columnIndex.compareTo(b.columnIndex));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Rôle : ${SurfaceStudioRoleLabels.labelForRole(role)}',
          style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
        ),
        Text(
          'Colonne : $sel',
          style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
        ),
        Text(
          'Frames : ${summary.frameCount}',
          style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
        ),
        Text(
          'Frame courante : ${summary.currentFrameIndex + 1} / ${summary.frameCount}',
          style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
        ),
        Text(
          'Durée par frame : $_msPerFrame ms',
          style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
        ),
        const SizedBox(height: 6),
        Text(
          'Colonne affichée',
          style: TextStyle(color: widget.subtle, fontSize: 10.5),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 120),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final a in assigned)
                  ChoiceChip(
                    label: Text(
                      'Colonne ${a.columnIndex} — ${SurfaceStudioRoleLabels.labelForRole(a.role!)}',
                      style: TextStyle(
                        color: _selectedColumn == a.columnIndex
                            ? Colors.white
                            : widget.label,
                        fontSize: 11,
                      ),
                    ),
                    selected: _selectedColumn == a.columnIndex,
                    onSelected: (selected) {
                      if (!selected) {
                        return;
                      }
                      setState(() {
                        _selectedColumn = a.columnIndex;
                        _frameIndex = 0;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton(
              onPressed: rws <= 0
                  ? null
                  : () {
                      setState(() {
                        _frameIndex = (_frameIndex - 1 + rws) % rws;
                      });
                    },
              child: const Text('Frame précédente'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: rws <= 0
                  ? null
                  : () {
                      setState(() {
                        _frameIndex = (_frameIndex + 1) % rws;
                      });
                    },
              child: const Text('Frame suivante'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: rws <= 0 ? null : _togglePlay,
              child: Text(_playing ? 'Pause' : 'Lecture'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Source rect : x=${sr.sourceX}, y=${sr.sourceY}, ${sr.sourceWidth}×${sr.sourceHeight}',
          style: TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.35),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 96,
          width: 96,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: widget.label.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _buildPreviewVisual(sr, tw, th),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewVisual(
    SurfaceStudioVerticalAtlasAnimationSourceRect sr,
    int tw,
    int th,
  ) {
    final img = _decoded;
    if (img == null || _bytes == null) {
      return ColoredBox(
        color: Colors.black12,
        child: Center(
          child: Text(
            'Colonne $_selectedColumn\nFrame ${_frameIndex + 1}',
            textAlign: TextAlign.center,
            style: TextStyle(color: widget.subtle, fontSize: 10),
          ),
        ),
      );
    }
    final src = Rect.fromLTWH(
      sr.sourceX.toDouble(),
      sr.sourceY.toDouble(),
      sr.sourceWidth.toDouble(),
      sr.sourceHeight.toDouble(),
    );
    return CustomPaint(
      painter: SurfaceStudioAtlasFrameCropPainter(image: img, srcRect: src),
    );
  }
}
