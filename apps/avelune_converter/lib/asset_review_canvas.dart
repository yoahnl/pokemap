import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef AssetCanvasCell = ({int x, int y});

class ConverterAssetSourceCanvas extends StatefulWidget {
  const ConverterAssetSourceCanvas({
    super.key,
    required this.source,
    required this.image,
    required this.parts,
    required this.selectedCells,
    required this.onSelectionChanged,
    this.enabled = true,
  });

  final SourceImage source;
  final ui.Image? image;
  final List<AssetPart> parts;
  final List<AssetCanvasCell> selectedCells;
  final ValueChanged<List<AssetCanvasCell>> onSelectionChanged;
  final bool enabled;

  @override
  State<ConverterAssetSourceCanvas> createState() =>
      _ConverterAssetSourceCanvasState();
}

class _ConverterAssetSourceCanvasState
    extends State<ConverterAssetSourceCanvas> {
  final _transform = TransformationController();
  final _focus = FocusNode();
  String _tool = 'pan';
  bool _grid = true;
  Offset? _start;
  Offset? _end;
  int? _pointer;
  Size _viewport = Size.zero;

  Sha256Hash _regions(ConverterAssetSourceCanvas canvas) => canonicalHashOf([
    for (final part in canvas.parts)
      if (part.sourceFileId == canvas.source.fileId) part.sourceRect.toJson(),
  ]);

  @override
  void initState() {
    super.initState();
    _centerAfterLayout();
  }

  @override
  void didUpdateWidget(ConverterAssetSourceCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source.fileId != widget.source.fileId ||
        _regions(oldWidget) != _regions(widget)) {
      _centerAfterLayout();
    }
  }

  void _centerAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fit(selection: true);
    });
  }

  @override
  void dispose() {
    _transform.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _zoom(double scale) {
    final center = Offset(_viewport.width / 2, _viewport.height / 2);
    final source = _transform.toScene(center);
    _transform.value =
        Matrix4.translationValues(
            center.dx - source.dx * scale,
            center.dy - source.dy * scale,
            0,
          )
          ..setEntry(0, 0, scale)
          ..setEntry(1, 1, scale);
  }

  void _fit({bool selection = false}) {
    if (_viewport.width <= 16 || _viewport.height <= 16) return;
    final rects = selection
        ? widget.parts
              .where((p) => p.sourceFileId == widget.source.fileId)
              .map(
                (p) => Rect.fromLTWH(
                  p.sourceRect.x.toDouble(),
                  p.sourceRect.y.toDouble(),
                  p.sourceRect.width.toDouble(),
                  p.sourceRect.height.toDouble(),
                ),
              )
              .toList()
        : <Rect>[];
    final rect = rects.isEmpty
        ? Rect.fromLTWH(
            0,
            0,
            widget.source.pixelWidth.toDouble(),
            widget.source.pixelHeight.toDouble(),
          )
        : rects.reduce((a, b) => a.expandToInclude(b));
    final scale = math
        .min(
          (_viewport.width - 16) / rect.width,
          (_viewport.height - 16) / rect.height,
        )
        .clamp(.01, 8.0);
    _transform.value =
        Matrix4.translationValues(
            (_viewport.width - rect.width * scale) / 2 - rect.left * scale,
            (_viewport.height - rect.height * scale) / 2 - rect.top * scale,
            0,
          )
          ..setEntry(0, 0, scale)
          ..setEntry(1, 1, scale);
  }

  AssetCanvasCell? _cell(Offset point) {
    if (point.dx < 0 ||
        point.dy < 0 ||
        point.dx >= widget.source.pixelWidth ||
        point.dy >= widget.source.pixelHeight) {
      return null;
    }
    final cell = (x: point.dx ~/ 32, y: point.dy ~/ 32);
    if ((cell.x + 1) * 32 > widget.source.pixelWidth ||
        (cell.y + 1) * 32 > widget.source.pixelHeight) {
      return null;
    }
    return cell;
  }

  void _down(PointerDownEvent event) {
    _focus.requestFocus();
    if (!widget.enabled ||
        widget.image == null ||
        _tool == 'pan' ||
        _pointer != null) {
      return;
    }
    final point = _transform.toScene(event.localPosition);
    if (_cell(point) == null) return;
    setState(() {
      _pointer = event.pointer;
      _start = point;
      _end = point;
    });
  }

  void _move(PointerMoveEvent event) {
    if (_pointer != event.pointer) return;
    setState(() => _end = _transform.toScene(event.localPosition));
  }

  void _up(PointerUpEvent event) {
    if (_pointer != event.pointer || _start == null) return;
    final first = _cell(_start!);
    final point = _transform.toScene(event.localPosition);
    final last = _cell(
      Offset(
        point.dx.clamp(0.0, widget.source.pixelWidth - .001),
        point.dy.clamp(0.0, widget.source.pixelHeight - .001),
      ),
    );
    final selection = widget.selectedCells.toSet();
    if (first != null && last != null) {
      if (_tool == 'cell') {
        if (!selection.remove(first)) selection.add(first);
      } else {
        for (
          var y = math.min(first.y, last.y);
          y <= math.max(first.y, last.y);
          y++
        ) {
          for (
            var x = math.min(first.x, last.x);
            x <= math.max(first.x, last.x);
            x++
          ) {
            selection.add((x: x, y: y));
          }
        }
      }
      final sorted = selection.toList()
        ..sort((a, b) => a.y == b.y ? a.x.compareTo(b.x) : a.y.compareTo(b.y));
      widget.onSelectionChanged(List.unmodifiable(sorted));
    }
    setState(() {
      _pointer = null;
      _start = null;
      _end = null;
    });
  }

  void _clearGesture() => setState(() {
    _pointer = null;
    _start = null;
    _end = null;
  });

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focus,
    onKeyEvent: (_, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape &&
          widget.enabled) {
        _clearGesture();
        widget.onSelectionChanged(const []);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (tool, label) in [
              ('pan', 'Déplacer'),
              ('cell', 'Cellule'),
              ('rectangle', 'Rectangle'),
            ])
              StudioTool(
                key: ValueKey('asset-tool-$tool'),
                label: label,
                icon: switch (tool) {
                  'pan' => Icons.pan_tool_outlined,
                  'cell' => Icons.grid_on_outlined,
                  _ => Icons.crop_square_outlined,
                },
                selected: _tool == tool,
                onPressed: widget.enabled
                    ? () => setState(() => _tool = tool)
                    : null,
              ),
            for (final scale in [1, 2, 4])
              StudioButton(
                key: ValueKey('asset-zoom-${scale * 100}'),
                label: '${scale * 100} %',
                secondary: true,
                onPressed: () => _zoom(scale.toDouble()),
              ),
            StudioButton(label: 'Ajuster', secondary: true, onPressed: _fit),
            StudioButton(
              label: 'Centrer l’objet',
              secondary: true,
              onPressed: () => _fit(selection: true),
            ),
          ],
        ),
        Text(
          'Outil : ${switch (_tool) {
            'cell' => 'Cellule',
            'rectangle' => 'Rectangle',
            _ => 'Déplacer',
          }}',
        ),
        StudioToggleRow(
          label: 'Grille source de 32 px',
          value: _grid,
          onChanged: (value) => setState(() => _grid = value),
        ),
        Expanded(
          child: StudioAssetPreview(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _viewport = Size(constraints.maxWidth, constraints.maxHeight);
                return SizedBox.expand(
                  child: Listener(
                    onPointerDown: _down,
                    onPointerMove: _move,
                    onPointerUp: _up,
                    onPointerCancel: (_) => _clearGesture(),
                    child: InteractiveViewer(
                      key: const ValueKey('asset-source-view'),
                      transformationController: _transform,
                      constrained: false,
                      alignment: Alignment.topLeft,
                      panEnabled: _tool == 'pan',
                      minScale: .01,
                      maxScale: 8,
                      boundaryMargin: const EdgeInsets.all(8192),
                      child: CustomPaint(
                        size: Size(
                          widget.source.pixelWidth.toDouble(),
                          widget.source.pixelHeight.toDouble(),
                        ),
                        painter: _AssetSourcePainter(
                          image: widget.image,
                          parts: widget.parts
                              .where(
                                (p) => p.sourceFileId == widget.source.fileId,
                              )
                              .toList(),
                          selected: widget.selectedCells,
                          grid: _grid,
                          selectionColor: StudioColors.of(context)
                              .canvasSelection,
                          gridColor: Theme.of(context)
                              .colorScheme
                              .outlineVariant,
                          gesture: _start == null || _end == null
                              ? null
                              : Rect.fromPoints(_start!, _end!),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Text(
          '${widget.source.pixelWidth} × ${widget.source.pixelHeight} px · ${widget.selectedCells.length} cellule(s) sélectionnée(s)',
        ),
      ],
    ),
  );
}

class _AssetSourcePainter extends CustomPainter {
  const _AssetSourcePainter({
    required this.image,
    required this.parts,
    required this.selected,
    required this.grid,
    required this.selectionColor,
    required this.gridColor,
    required this.gesture,
  });
  final ui.Image? image;
  final List<AssetPart> parts;
  final List<AssetCanvasCell> selected;
  final bool grid;
  final Color selectionColor, gridColor;
  final Rect? gesture;

  @override
  void paint(Canvas canvas, Size size) {
    if (image case final source?) {
      canvas.drawImage(
        source,
        Offset.zero,
        Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false,
      );
    }
    if (grid) {
      final line = Paint()
        ..color = gridColor
        ..strokeWidth = 1;
      for (var x = 0; x <= size.width; x += 32) {
        canvas.drawLine(
          Offset(x.toDouble(), 0),
          Offset(x.toDouble(), size.height),
          line,
        );
      }
      for (var y = 0; y <= size.height; y += 32) {
        canvas.drawLine(
          Offset(0, y.toDouble()),
          Offset(size.width, y.toDouble()),
          line,
        );
      }
    }
    final border = Paint()
      ..color = selectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final part in parts) {
      final r = part.sourceRect;
      canvas.drawRect(
        Rect.fromLTWH(
          r.x.toDouble(),
          r.y.toDouble(),
          r.width.toDouble(),
          r.height.toDouble(),
        ),
        border,
      );
    }
    for (final cell in selected) {
      final rect = Rect.fromLTWH(cell.x * 32.0, cell.y * 32.0, 32, 32);
      canvas.drawRect(
        rect,
        Paint()..color = selectionColor.withValues(alpha: .2),
      );
      canvas.drawRect(rect, border);
    }
    if (gesture case final rect?) canvas.drawRect(rect, border);
  }

  @override
  bool shouldRepaint(_AssetSourcePainter old) =>
      image != old.image ||
      parts != old.parts ||
      selected != old.selected ||
      grid != old.grid ||
      gesture != old.gesture ||
      selectionColor != old.selectionColor ||
      gridColor != old.gridColor;
}
