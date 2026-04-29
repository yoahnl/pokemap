import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType, Slider;
import 'package:flutter/services.dart';

import '../surface_studio_atlas_view_geometry.dart';
import '../surface_studio_column_selection.dart';
import '../surface_studio_design_tokens.dart';
import '../surface_studio_drag_payload.dart';

class SurfaceStudioAtlasPanel extends StatelessWidget {
  const SurfaceStudioAtlasPanel({
    super.key,
    required this.columnCount,
    required this.frameCount,
    required this.tileWidth,
    required this.tileHeight,
    this.atlasImageBytes,
    this.atlasImageFallbackLabel,
    required this.selection,
    required this.zoomPercent,
    required this.onColumnSelectionChanged,
    required this.centerAssigned,
    required this.centerColumns,
    required this.onUseSelectionAsCenter,
    required this.onZoomChanged,
    required this.onReset,
    required this.onAutoSuggest,
  });

  final int columnCount;
  final int frameCount;
  final int tileWidth;
  final int tileHeight;
  final Uint8List? atlasImageBytes;
  final String? atlasImageFallbackLabel;
  final SurfaceStudioColumnSelection selection;
  final bool centerAssigned;
  final List<int> centerColumns;
  final double zoomPercent;
  final ValueChanged<SurfaceStudioColumnSelection> onColumnSelectionChanged;
  final VoidCallback onUseSelectionAsCenter;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onReset;
  final VoidCallback onAutoSuggest;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      key: const ValueKey('surfaceStudio.atlas.panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AtlasHeader(),
          const SizedBox(height: 10),
          Expanded(
            child: SurfaceStudioAtlasViewport(
              columnCount: columnCount,
              frameCount: frameCount,
              tileWidth: tileWidth,
              tileHeight: tileHeight,
              atlasImageBytes: atlasImageBytes,
              atlasImageFallbackLabel: atlasImageFallbackLabel,
              selection: selection,
              centerAssigned: centerAssigned,
              centerColumns: centerColumns,
              zoomPercent: zoomPercent,
              onColumnSelectionChanged: onColumnSelectionChanged,
              onUseSelectionAsCenter: onUseSelectionAsCenter,
            ),
          ),
          const SizedBox(height: 10),
          SurfaceStudioAtlasToolbar(
            zoomPercent: zoomPercent,
            columnCount: columnCount,
            frameCount: frameCount,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            onZoomChanged: onZoomChanged,
            onReset: onReset,
            onAutoSuggest: onAutoSuggest,
          ),
        ],
      ),
    );
  }
}

class SurfaceStudioAtlasViewport extends StatelessWidget {
  const SurfaceStudioAtlasViewport({
    super.key,
    required this.columnCount,
    required this.frameCount,
    required this.tileWidth,
    required this.tileHeight,
    this.atlasImageBytes,
    this.atlasImageFallbackLabel,
    required this.selection,
    required this.centerAssigned,
    required this.centerColumns,
    required this.zoomPercent,
    required this.onColumnSelectionChanged,
    required this.onUseSelectionAsCenter,
  });

  final int columnCount;
  final int frameCount;
  final int tileWidth;
  final int tileHeight;
  final Uint8List? atlasImageBytes;
  final String? atlasImageFallbackLabel;
  final SurfaceStudioColumnSelection selection;
  final bool centerAssigned;
  final List<int> centerColumns;
  final double zoomPercent;
  final ValueChanged<SurfaceStudioColumnSelection> onColumnSelectionChanged;
  final VoidCallback onUseSelectionAsCenter;

  @override
  Widget build(BuildContext context) {
    final payload = SurfaceStudioColumnDragPayload(
      columns: selection.columns,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      frameCount: frameCount,
    );
    return Container(
      key: const ValueKey('surfaceStudio.atlas.viewport'),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SurfaceStudioAtlasCanvas(
                    columnCount: columnCount,
                    frameCount: frameCount,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    atlasImageBytes: atlasImageBytes,
                    atlasImageFallbackLabel: atlasImageFallbackLabel,
                    selection: selection,
                    zoomPercent: zoomPercent,
                    onColumnSelectionChanged: onColumnSelectionChanged,
                  ),
                ),
                if (selection.isNotEmpty)
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Draggable<SurfaceStudioColumnDragPayload>(
                      data: payload,
                      feedback: _DragGhost(payload: payload),
                      childWhenDragging: Opacity(
                        opacity: 0.48,
                        child: _DragHandle(payload: payload),
                      ),
                      child: _DragHandle(payload: payload),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 35),
            decoration: BoxDecoration(
              color: SurfaceStudioDesignTokens.backgroundPanel
                  .withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text(
                    selection.microcopy,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: SurfaceStudioDesignTokens.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    selection.isEmpty
                        ? 'Colonnes sélectionnées : aucune'
                        : 'Colonnes sélectionnées : ${_formatColumns(selection.columns)}',
                    style: const TextStyle(
                      color: SurfaceStudioDesignTokens.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    centerAssigned
                        ? 'Plein(center) : colonnes ${_formatColumns(centerColumns)}'
                        : 'Plein(center) : non assigné',
                    style: TextStyle(
                      color: centerAssigned
                          ? SurfaceStudioDesignTokens.accentTeal
                          : SurfaceStudioDesignTokens.accentGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (selection.isNotEmpty)
                    CupertinoButton(
                      key: const ValueKey(
                        'surfaceStudio.atlas.useSelectionAsCenter',
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      minimumSize: const Size(0, 0),
                      color: SurfaceStudioDesignTokens.accentGoldSoft,
                      onPressed: onUseSelectionAsCenter,
                      child: const Text(
                        'Utiliser comme Plein(center)',
                        style: TextStyle(
                          color: SurfaceStudioDesignTokens.accentGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SurfaceStudioAtlasCanvas extends StatefulWidget {
  const SurfaceStudioAtlasCanvas({
    super.key,
    required this.columnCount,
    required this.frameCount,
    required this.tileWidth,
    required this.tileHeight,
    this.atlasImageBytes,
    this.atlasImageFallbackLabel,
    required this.selection,
    required this.zoomPercent,
    required this.onColumnSelectionChanged,
  });

  final int columnCount;
  final int frameCount;
  final int tileWidth;
  final int tileHeight;
  final Uint8List? atlasImageBytes;
  final String? atlasImageFallbackLabel;
  final SurfaceStudioColumnSelection selection;
  final double zoomPercent;
  final ValueChanged<SurfaceStudioColumnSelection> onColumnSelectionChanged;

  @override
  State<SurfaceStudioAtlasCanvas> createState() =>
      _SurfaceStudioAtlasCanvasState();
}

class _SurfaceStudioAtlasCanvasState extends State<SurfaceStudioAtlasCanvas> {
  ui.Image? _image;
  Object? _decodeToken;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioAtlasCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.atlasImageBytes != widget.atlasImageBytes) {
      _image?.dispose();
      _image = null;
      _decodeImage();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  void _decodeImage() {
    final bytes = widget.atlasImageBytes;
    if (bytes == null || bytes.isEmpty) {
      _decodeToken = null;
      return;
    }
    final token = Object();
    _decodeToken = token;
    ui.decodeImageFromList(bytes, (image) {
      if (!mounted || _decodeToken != token) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    });
  }

  void _selectColumn(int column) {
    final shift = HardwareKeyboard.instance.logicalKeysPressed.any(
      (key) =>
          key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight,
    );
    final next = shift && widget.selection.isNotEmpty
        ? widget.selection.selectContiguousTo(column)
        : widget.selection.selectSingle(column);
    widget.onColumnSelectionChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 1,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 1,
        );
        final image = _image;
        final imagePixelSize = image == null
            ? Size(
                (widget.columnCount * widget.tileWidth).toDouble(),
                (widget.frameCount * widget.tileHeight).toDouble(),
              )
            : Size(image.width.toDouble(), image.height.toDouble());
        final geometry = SurfaceStudioAtlasViewGeometry.fromContain(
          viewportSize: viewportSize,
          imagePixelSize: imagePixelSize,
          tileWidth: widget.tileWidth,
          tileHeight: widget.tileHeight,
          columnCount: widget.columnCount,
          frameCount: widget.frameCount,
        );
        return GestureDetector(
          key: const ValueKey('surfaceStudio.atlas.canvas'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final column = surfaceStudioColumnAtViewportOffset(
              localPosition: details.localPosition,
              geometry: geometry,
            );
            if (column != null) {
              _selectColumn(column);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _SurfaceStudioAtlasCanvasPainter(
                  atlasImage: image,
                  geometry: geometry,
                  selectedColumns: widget.selection.columns,
                  zoomPercent: widget.zoomPercent,
                  fallbackLabel: widget.atlasImageFallbackLabel ??
                      'Image source indisponible — aperçu illustratif.',
                ),
                child: const SizedBox.expand(),
              ),
              if (image == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.atlasImageFallbackLabel ??
                          'Image source indisponible — aperçu illustratif.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: SurfaceStudioDesignTokens.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              for (var column = 1; column <= widget.columnCount; column++)
                Positioned.fromRect(
                  rect: surfaceStudioColumnViewportRect(
                    uiColumn: column,
                    geometry: geometry,
                  ),
                  child: GestureDetector(
                    key: ValueKey('surfaceStudio.atlas.column.$column'),
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _selectColumn(column),
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SurfaceStudioAtlasCanvasPainter extends CustomPainter {
  const _SurfaceStudioAtlasCanvasPainter({
    required this.atlasImage,
    required this.geometry,
    required this.selectedColumns,
    required this.zoomPercent,
    required this.fallbackLabel,
  });

  final ui.Image? atlasImage;
  final SurfaceStudioAtlasViewGeometry geometry;
  final List<int> selectedColumns;
  final double zoomPercent;
  final String fallbackLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final viewportPaint = Paint()
      ..color = SurfaceStudioDesignTokens.backgroundDeep;
    canvas.drawRect(Offset.zero & size, viewportPaint);

    final imageRect = geometry.fittedImageRect;
    final image = atlasImage;
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        imageRect,
        Paint()..filterQuality = FilterQuality.none,
      );
    } else {
      _drawFallbackSurface(canvas, imageRect);
    }

    _drawGrid(canvas, imageRect);
    _drawColumnLabels(canvas);
    _drawSelection(canvas);
  }

  void _drawFallbackSurface(Canvas canvas, Rect imageRect) {
    final background = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF174A8B), Color(0xFF1A74D6), Color(0xFF123D3A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(imageRect);
    canvas.drawRect(imageRect, background);

    final safeColumnCount = geometry.columnCount.clamp(1, 9999).toInt();
    final safeFrameCount = geometry.frameCount.clamp(1, 9999).toInt();
    final tileW = imageRect.width / safeColumnCount;
    final tileH = imageRect.height / safeFrameCount;
    final wavePaint = Paint()
      ..color = SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var y = 0; y < geometry.frameCount; y += 2) {
      final centerY = imageRect.top + y * tileH + tileH / 2;
      for (var x = 0; x < geometry.columnCount; x += 2) {
        final left = imageRect.left + x * tileW + tileW * 0.18;
        final rect = Rect.fromLTWH(
            left, centerY - tileH * 0.22, tileW * 0.64, tileH * 0.44);
        canvas.drawArc(rect, 0, 3.14159, false, wavePaint);
      }
    }
  }

  void _drawGrid(Canvas canvas, Rect imageRect) {
    final columnCount = geometry.columnCount.clamp(1, 9999).toInt();
    final frameCount = geometry.frameCount.clamp(1, 9999).toInt();
    final columnWidth = imageRect.width / columnCount;
    final rowHeight = imageRect.height / frameCount;
    final linePaint = Paint()
      ..color = SurfaceStudioDesignTokens.textPrimary.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    final strongPaint = Paint()
      ..color = SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.24)
      ..strokeWidth = 1.1;

    canvas.save();
    canvas.clipRect(imageRect);
    for (var column = 0; column <= columnCount; column++) {
      final x = imageRect.left + column * columnWidth;
      canvas.drawLine(
        Offset(x, imageRect.top),
        Offset(x, imageRect.bottom),
        column.isEven ? strongPaint : linePaint,
      );
    }
    for (var row = 0; row <= frameCount; row++) {
      final y = imageRect.top + row * rowHeight;
      canvas.drawLine(
        Offset(imageRect.left, y),
        Offset(imageRect.right, y),
        row % 4 == 0 ? strongPaint : linePaint,
      );
    }
    canvas.restore();
  }

  void _drawColumnLabels(Canvas canvas) {
    for (var column = 1; column <= geometry.columnCount; column++) {
      final columnRect = surfaceStudioColumnViewportRect(
        uiColumn: column,
        geometry: geometry,
      );
      final isSelected = selectedColumns.contains(column);
      final labelText = TextPainter(
        text: TextSpan(
          text: '$column',
          style: TextStyle(
            color: isSelected
                ? SurfaceStudioDesignTokens.backgroundDeep
                : SurfaceStudioDesignTokens.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: columnRect.width);
      final desiredLabelWidth = labelText.width + 9;
      final labelWidth = columnRect.width < 18
          ? columnRect.width
          : desiredLabelWidth.clamp(18.0, columnRect.width).toDouble();
      final labelRect = Rect.fromLTWH(
        columnRect.center.dx - labelWidth / 2,
        geometry.fittedImageRect.top + 6,
        labelWidth,
        18,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(7)),
        Paint()
          ..color = isSelected
              ? SurfaceStudioDesignTokens.accentGold
              : SurfaceStudioDesignTokens.backgroundDeep.withValues(alpha: 0.7),
      );
      labelText.paint(
        canvas,
        Offset(
          labelRect.center.dx - labelText.width / 2,
          labelRect.center.dy - labelText.height / 2,
        ),
      );
    }
  }

  void _drawSelection(Canvas canvas) {
    if (selectedColumns.isEmpty) {
      return;
    }
    final fillPaint = Paint()
      ..color = SurfaceStudioDesignTokens.accentGold.withValues(alpha: 0.18);
    final strokePaint = Paint()
      ..color = SurfaceStudioDesignTokens.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final column in selectedColumns) {
      final rect = surfaceStudioColumnViewportRect(
        uiColumn: column,
        geometry: geometry,
      ).deflate(1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        fillPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SurfaceStudioAtlasCanvasPainter oldDelegate) =>
      oldDelegate.atlasImage != atlasImage ||
      oldDelegate.geometry != geometry ||
      oldDelegate.selectedColumns != selectedColumns ||
      oldDelegate.zoomPercent != zoomPercent ||
      oldDelegate.fallbackLabel != fallbackLabel;
}

String _formatColumns(List<int> columns) {
  if (columns.isEmpty) {
    return 'aucune';
  }
  if (columns.length == 1) {
    return '${columns.first}';
  }
  return '${columns.first}–${columns.last}';
}

class SurfaceStudioAtlasToolbar extends StatelessWidget {
  const SurfaceStudioAtlasToolbar({
    super.key,
    required this.zoomPercent,
    required this.columnCount,
    required this.frameCount,
    required this.tileWidth,
    required this.tileHeight,
    required this.onZoomChanged,
    required this.onReset,
    required this.onAutoSuggest,
  });

  final double zoomPercent;
  final int columnCount;
  final int frameCount;
  final int tileWidth;
  final int tileHeight;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onReset;
  final VoidCallback onAutoSuggest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanelAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolbarSection(
              title: 'Zoom',
              child: Row(
                children: [
                  _SquareButton(
                    icon: CupertinoIcons.minus,
                    onPressed: () => onZoomChanged(
                      (zoomPercent - 10).clamp(25, 400).toDouble(),
                    ),
                  ),
                  Material(
                    type: MaterialType.transparency,
                    child: SizedBox(
                      width: 128,
                      child: Slider(
                        key: const ValueKey('surfaceStudio.atlas.zoomSlider'),
                        value: zoomPercent,
                        min: 25,
                        max: 400,
                        divisions: 75,
                        onChanged: onZoomChanged,
                      ),
                    ),
                  ),
                  Text(
                    '${zoomPercent.round()}%',
                    style: const TextStyle(
                      color: SurfaceStudioDesignTokens.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _SquareButton(
                    icon: CupertinoIcons.plus,
                    onPressed: () => onZoomChanged(
                      (zoomPercent + 10).clamp(25, 400).toDouble(),
                    ),
                  ),
                  _SquareButton(
                    icon: CupertinoIcons.arrow_up_left_arrow_down_right,
                    onPressed: () => onZoomChanged(100),
                  ),
                ],
              ),
            ),
            _Divider(),
            _ToolbarSection(
              title: 'Détection auto',
              child: CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: SurfaceStudioDesignTokens.accentTealSoft,
                minimumSize: const Size.square(36),
                onPressed: onAutoSuggest,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.sparkles,
                      color: SurfaceStudioDesignTokens.accentTeal,
                      size: 16,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Analyser',
                      style: TextStyle(
                        color: SurfaceStudioDesignTokens.accentTeal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _Divider(),
            _ToolbarSection(
              title: 'Réinitialiser',
              child: _SquareButton(
                icon: CupertinoIcons.arrow_counterclockwise,
                onPressed: onReset,
              ),
            ),
            _Divider(),
            _ToolbarMetric(
                title: 'Découpage', value: '$tileWidth × $tileHeight'),
            _ToolbarMetric(title: 'Colonnes', value: '$columnCount'),
            _ToolbarMetric(title: 'Frames', value: '$frameCount'),
          ],
        ),
      ),
    );
  }
}

class _AtlasHeader extends StatelessWidget {
  const _AtlasHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          'Atlas source',
          style: TextStyle(
            color: SurfaceStudioDesignTokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Text(
            'Glissez pour sélectionner. Faites glisser vers le schéma.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: SurfaceStudioDesignTokens.textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanel,
        borderRadius:
            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      child: child,
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.payload});

  final SurfaceStudioColumnDragPayload payload;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surfaceStudio.atlas.dragHandle'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.accentGoldSoft.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurfaceStudioDesignTokens.accentGold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.hand_draw,
            color: SurfaceStudioDesignTokens.accentGold,
            size: 17,
          ),
          const SizedBox(width: 8),
          Text(
            payload.label,
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DragGhost extends StatelessWidget {
  const _DragGhost({required this.payload});

  final SurfaceStudioColumnDragPayload payload;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        key: const ValueKey('surfaceStudio.atlas.dragGhost'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: SurfaceStudioDesignTokens.backgroundElevated,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: SurfaceStudioDesignTokens.accentGold, width: 2),
          boxShadow: [
            BoxShadow(
              color:
                  SurfaceStudioDesignTokens.accentGold.withValues(alpha: 0.32),
              blurRadius: 18,
            ),
          ],
        ),
        child: Text(
          payload.label,
          style: const TextStyle(
            color: SurfaceStudioDesignTokens.accentGold,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _ToolbarSection extends StatelessWidget {
  const _ToolbarSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: SurfaceStudioDesignTokens.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

class _ToolbarMetric extends StatelessWidget {
  const _ToolbarMetric({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: _ToolbarSection(
        title: title,
        child: Container(
          constraints: const BoxConstraints(minWidth: 74),
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: SurfaceStudioDesignTokens.backgroundDeep,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size.square(34),
      onPressed: onPressed,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SurfaceStudioDesignTokens.backgroundDeep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
        ),
        child: Icon(icon,
            size: 16, color: SurfaceStudioDesignTokens.textSecondary),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 13),
      color: SurfaceStudioDesignTokens.borderStrong,
    );
  }
}
