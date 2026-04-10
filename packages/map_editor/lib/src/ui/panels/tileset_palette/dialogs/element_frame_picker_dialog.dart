part of 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';

// The frame picker dialog and its painter are kept together because the painter
// is only meaningful inside this modal interaction flow.

Future<TilesetSourceRect?> _showElementFramePickerDialog(
  BuildContext context, {
  required ui.Image image,
  required int tileWidth,
  required int tileHeight,
  required int frameWidthTiles,
  required int frameHeightTiles,
  required TilesetSourceRect initial,
}) async {
  final colsTiles = image.width ~/ math.max(1, tileWidth);
  final rowsTiles = image.height ~/ math.max(1, tileHeight);
  final colsFrames = colsTiles ~/ math.max(1, frameWidthTiles);
  final rowsFrames = rowsTiles ~/ math.max(1, frameHeightTiles);
  if (colsFrames <= 0 || rowsFrames <= 0) {
    return null;
  }
  final initialX = (initial.x ~/ frameWidthTiles).clamp(0, colsFrames - 1);
  final initialY = (initial.y ~/ frameHeightTiles).clamp(0, rowsFrames - 1);
  GridPos selected = GridPos(x: initialX, y: initialY);
  final horizontalController = ScrollController();
  final verticalController = ScrollController();
  bool shouldSave = false;
  double zoom = 3.0;
  GridPos toCell(Offset local, double cw, double ch) {
    final x = (local.dx / cw).floor().clamp(0, colsFrames - 1);
    final y = (local.dy / ch).floor().clamp(0, rowsFrames - 1);
    return GridPos(x: x, y: y);
  }

  await showMacosEditorTallSheet<void>(
    context: context,
    maxWidth: 720,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setStateDialog) {
        final baseCellWidth = (frameWidthTiles * tileWidth).toDouble();
        final baseCellHeight = (frameHeightTiles * tileHeight).toDouble();
        final cellWidth = math.max(16.0, baseCellWidth * zoom);
        final cellHeight = math.max(16.0, baseCellHeight * zoom);
        final canvasWidth = colsFrames * cellWidth;
        final canvasHeight = rowsFrames * cellHeight;
        return ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text('Pick frame source', style: editorMacosSheetTitleStyle(ctx)),
            const SizedBox(height: 8),
            Text(
              'Frame size: $frameWidthTiles x $frameHeightTiles tiles',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Zoom',
                  style: TextStyle(
                    fontSize: 12,
                    color: EditorPaintColors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(24, 24),
                  color: EditorPaintColors.white24,
                  onPressed: () {
                    setStateDialog(() {
                      zoom = (zoom - 0.25).clamp(0.75, 8.0);
                    });
                  },
                  child: const Text('-', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 170,
                  child: CupertinoSlider(
                    value: zoom,
                    min: 0.75,
                    max: 8.0,
                    divisions: 29,
                    onChanged: (v) {
                      setStateDialog(() {
                        zoom = v;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(24, 24),
                  color: EditorPaintColors.white24,
                  onPressed: () {
                    setStateDialog(() {
                      zoom = (zoom + 0.25).clamp(0.75, 8.0);
                    });
                  },
                  child: const Text('+', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Text(
                  '${zoom.toStringAsFixed(2)}x',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 420,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: CupertinoColors.separator.resolveFrom(ctx),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  controller: horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: verticalController,
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      width: canvasWidth,
                      height: canvasHeight,
                      child: GestureDetector(
                        onTapUp: (details) {
                          setStateDialog(() {
                            selected = toCell(
                              details.localPosition,
                              cellWidth,
                              cellHeight,
                            );
                          });
                        },
                        onPanStart: (details) {
                          setStateDialog(() {
                            selected = toCell(
                              details.localPosition,
                              cellWidth,
                              cellHeight,
                            );
                          });
                        },
                        onPanUpdate: (details) {
                          setStateDialog(() {
                            selected = toCell(
                              details.localPosition,
                              cellWidth,
                              cellHeight,
                            );
                          });
                        },
                        child: CustomPaint(
                          painter: _ElementFramePickerPainter(
                            image: image,
                            frameColumns: colsFrames,
                            frameRows: rowsFrames,
                            frameWidthTiles: frameWidthTiles,
                            frameHeightTiles: frameHeightTiles,
                            tileWidth: tileWidth,
                            tileHeight: tileHeight,
                            selected: selected,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected: (${selected.x * frameWidthTiles}, ${selected.y * frameHeightTiles})',
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.large,
                  secondary: true,
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: () {
                    shouldSave = true;
                    Navigator.pop(ctx);
                  },
                  child: const Text('Use frame'),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
  horizontalController.dispose();
  verticalController.dispose();
  if (!shouldSave) {
    return null;
  }
  return TilesetSourceRect(
    x: selected.x * frameWidthTiles,
    y: selected.y * frameHeightTiles,
    width: frameWidthTiles,
    height: frameHeightTiles,
  );
}

class _ElementFramePickerPainter extends CustomPainter {
  _ElementFramePickerPainter({
    required this.image,
    required this.frameColumns,
    required this.frameRows,
    required this.frameWidthTiles,
    required this.frameHeightTiles,
    required this.tileWidth,
    required this.tileHeight,
    required this.selected,
  });

  final ui.Image image;
  final int frameColumns;
  final int frameRows;
  final int frameWidthTiles;
  final int frameHeightTiles;
  final int tileWidth;
  final int tileHeight;
  final GridPos selected;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / frameColumns;
    final cellHeight = size.height / frameRows;
    for (var y = 0; y < frameRows; y++) {
      for (var x = 0; x < frameColumns; x++) {
        final srcRect = Rect.fromLTWH(
          (x * frameWidthTiles * tileWidth).toDouble(),
          (y * frameHeightTiles * tileHeight).toDouble(),
          (frameWidthTiles * tileWidth).toDouble(),
          (frameHeightTiles * tileHeight).toDouble(),
        );
        final dstRect = Rect.fromLTWH(
          x * cellWidth,
          y * cellHeight,
          cellWidth,
          cellHeight,
        );
        canvas.drawImageRect(
          image,
          srcRect,
          dstRect,
          Paint()..filterQuality = FilterQuality.none,
        );
      }
    }
    final gridPaint = Paint()
      ..color = EditorPaintColors.white24
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var x = 0; x <= frameColumns; x++) {
      final dx = x * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (var y = 0; y <= frameRows; y++) {
      final dy = y * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }
    final selectedRect = Rect.fromLTWH(
      selected.x * cellWidth,
      selected.y * cellHeight,
      cellWidth,
      cellHeight,
    );
    canvas.drawRect(
      selectedRect,
      Paint()..color = EditorPaintColors.orange.withValues(alpha: 0.22),
    );
    canvas.drawRect(
      selectedRect,
      Paint()
        ..color = EditorPaintColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ElementFramePickerPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.frameColumns != frameColumns ||
        oldDelegate.frameRows != frameRows ||
        oldDelegate.frameWidthTiles != frameWidthTiles ||
        oldDelegate.frameHeightTiles != frameHeightTiles ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        oldDelegate.selected != selected;
  }
}

class _CompactSwitchRow extends StatelessWidget {
  const _CompactSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: label,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Transform.scale(
          scale: 0.85,
          child: CupertinoSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _CompactStepperRow extends StatelessWidget {
  const _CompactStepperRow({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.onReset,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final textColor = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(
              color: secondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          minimumSize: Size.zero,
          onPressed: onMinus,
          child: const Text('-', style: TextStyle(fontSize: 12)),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          minimumSize: Size.zero,
          onPressed: onPlus,
          child: const Text('+', style: TextStyle(fontSize: 12)),
        ),
        if (onReset != null)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            minimumSize: Size.zero,
            onPressed: onReset,
            child: Text(
              'Auto',
              style: TextStyle(
                fontSize: 10,
                color: textColor,
              ),
            ),
          ),
      ],
    );
  }
}

enum _ElementCollisionPaintMode { preview, add, remove }

