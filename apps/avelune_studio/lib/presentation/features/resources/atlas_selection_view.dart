import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

class AtlasSelectionView extends StatefulWidget {
  const AtlasSelectionView({
    super.key,
    required this.source,
    required this.selected,
    required this.image,
    required this.onSelected,
    this.singleCell = false,
  });
  final ProjectRegularAtlasTilesetSource source;
  final TilesetSourceRect selected;
  final Widget image;
  final ValueChanged<TilesetSourceRect> onSelected;
  final bool singleCell;
  @override
  State<AtlasSelectionView> createState() => _AtlasSelectionViewState();
}

class _AtlasSelectionViewState extends State<AtlasSelectionView> {
  final transform = TransformationController();
  GridPos? start;
  bool pan = false;
  bool fitted = false;
  Size viewport = Size.zero;

  void fit() {
    final source = widget.source;
    if (viewport.isEmpty || source.pixelWidth <= 0 || source.pixelHeight <= 0) {
      return;
    }
    final scale = math
        .min(
          (viewport.width - 24) / source.pixelWidth,
          (viewport.height - 24) / source.pixelHeight,
        )
        .clamp(.05, 4.0);
    transform.value = Matrix4.identity()
      ..translateByDouble(
        (viewport.width - source.pixelWidth * scale) / 2,
        (viewport.height - source.pixelHeight * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void zoom(double factor) {
    final current = transform.value.getMaxScaleOnAxis();
    final ratio = (current * factor).clamp(.05, 12.0) / current;
    transform.value = transform.value.clone()
      ..scaleByDouble(ratio, ratio, 1, 1);
  }

  @override
  void didUpdateWidget(AtlasSelectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source.assetId != widget.source.assetId ||
        oldWidget.source.pixelWidth != widget.source.pixelWidth ||
        oldWidget.source.pixelHeight != widget.source.pixelHeight) {
      fitted = false;
    }
  }

  GridPos? cell(Offset point) {
    final s = widget.source;
    if (s.tileWidth <= 0 ||
        s.tileHeight <= 0 ||
        s.spacingX < 0 ||
        s.spacingY < 0) {
      return null;
    }
    final x = point.dx - s.marginX;
    final y = point.dy - s.marginY;
    if (x < 0 || y < 0) return null;
    final col = (x / (s.tileWidth + s.spacingX)).floor();
    final row = (y / (s.tileHeight + s.spacingY)).floor();
    if (col >= s.columns ||
        row >= s.rows ||
        x % (s.tileWidth + s.spacingX) >= s.tileWidth ||
        y % (s.tileHeight + s.spacingY) >= s.tileHeight) {
      return null;
    }
    return GridPos(x: col, y: row);
  }

  void select(Offset point, {bool begin = false}) {
    final current = cell(point);
    if (begin) start = current;
    if (current == null) return;
    final origin = start;
    if (origin == null) return;
    widget.onSelected(
      TilesetSourceRect(
        x: widget.singleCell ? current.x : math.min(origin.x, current.x),
        y: widget.singleCell ? current.y : math.min(origin.y, current.y),
        width: widget.singleCell ? 1 : (origin.x - current.x).abs() + 1,
        height: widget.singleCell ? 1 : (origin.y - current.y).abs() + 1,
      ),
    );
  }

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.source;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Source · ${s.tileWidth} × ${s.tileHeight} px',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Ajuster la source',
                onPressed: fit,
                icon: const Icon(Icons.fit_screen),
              ),
              IconButton(
                tooltip: pan ? 'Sélectionner' : 'Déplacer la source',
                onPressed: () => setState(() => pan = !pan),
                icon: Icon(pan ? Icons.crop_free : Icons.pan_tool_outlined),
              ),
              IconButton(
                tooltip: 'Zoom arrière',
                icon: const Icon(Icons.remove),
                onPressed: () => zoom(.8),
              ),
              IconButton(
                tooltip: 'Zoom avant',
                icon: const Icon(Icons.add),
                onPressed: () => zoom(1.25),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              viewport = constraints.biggest;
              if (!fitted) {
                fitted = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) fit();
                });
              }
              return ClipRect(
                child: InteractiveViewer(
                  transformationController: transform,
                  constrained: false,
                  panEnabled: pan,
                  minScale: .05,
                  maxScale: 12,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: Listener(
                    key: const ValueKey('atlas-selection'),
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: pan
                        ? null
                        : (e) => select(e.localPosition, begin: true),
                    onPointerMove: pan ? null : (e) => select(e.localPosition),
                    onPointerUp: (_) => start = null,
                    onPointerCancel: (_) => start = null,
                    child: SizedBox(
                      width: s.pixelWidth.toDouble(),
                      height: s.pixelHeight.toDouble(),
                      child: Stack(
                        children: [
                          Positioned.fill(child: widget.image),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _AtlasGrid(
                                  s,
                                  widget.selected,
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AtlasGrid extends CustomPainter {
  _AtlasGrid(this.source, this.selection, this.color);
  final ProjectRegularAtlasTilesetSource source;
  final TilesetSourceRect selection;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final s = source;
    final stroke = Paint()
      ..color = color.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6;
    final grid = Path();
    final left = s.marginX.toDouble();
    final top = s.marginY.toDouble();
    final right =
        left +
        s.columns * s.tileWidth +
        math.max(0, s.columns - 1) * s.spacingX;
    final bottom =
        top + s.rows * s.tileHeight + math.max(0, s.rows - 1) * s.spacingY;
    for (var x = 0; x < s.columns; x++) {
      final start = left + x * (s.tileWidth + s.spacingX);
      grid
        ..moveTo(start, top)
        ..lineTo(start, bottom)
        ..moveTo(start + s.tileWidth, top)
        ..lineTo(start + s.tileWidth, bottom);
    }
    for (var y = 0; y < s.rows; y++) {
      final start = top + y * (s.tileHeight + s.spacingY);
      grid
        ..moveTo(left, start)
        ..lineTo(right, start)
        ..moveTo(left, start + s.tileHeight)
        ..lineTo(right, start + s.tileHeight);
    }
    canvas.drawPath(grid, stroke);
    final r = selection;
    canvas.drawRect(
      Rect.fromLTWH(
        (s.marginX + r.x * (s.tileWidth + s.spacingX)).toDouble(),
        (s.marginY + r.y * (s.tileHeight + s.spacingY)).toDouble(),
        (r.width * s.tileWidth + (r.width - 1) * s.spacingX).toDouble(),
        (r.height * s.tileHeight + (r.height - 1) * s.spacingY).toDouble(),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_AtlasGrid old) =>
      old.selection != selection || old.source != source || old.color != color;
}
