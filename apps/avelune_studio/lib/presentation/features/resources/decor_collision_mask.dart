import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';

part 'decor_collision_overlay.dart';

class DecorCollisionMask extends StatefulWidget {
  const DecorCollisionMask({
    super.key,
    required this.width,
    required this.height,
    required this.tileWidth,
    required this.tileHeight,
    required this.blocked,
    required this.image,
    required this.onPaint,
    required this.onStrokeStart,
    required this.onStrokeEnd,
    required this.onStrokeCancel,
    this.pixels,
    this.maskWidth = 0,
    this.revision = 0,
    this.fine = false,
    this.erase = false,
    this.brushSize = 1,
    this.enabled = true,
  });
  final int width,
      height,
      tileWidth,
      tileHeight,
      maskWidth,
      revision,
      brushSize;
  final Set<GridPos> blocked;
  final List<bool>? pixels;
  final Widget image;
  final ValueChanged<GridPos> onPaint;
  final VoidCallback onStrokeStart, onStrokeEnd, onStrokeCancel;
  final bool fine, erase, enabled;

  @override
  State<DecorCollisionMask> createState() => _DecorCollisionMaskState();
}

class _DecorCollisionMaskState extends State<DecorCollisionMask> {
  final transform = TransformationController();
  final focus = FocusNode();
  bool pan = false, fitted = false, drawing = false;
  GridPos? previous, cursor;
  Size viewport = Size.zero;
  Size get imageSize => Size(
    (widget.width * widget.tileWidth).toDouble(),
    (widget.height * widget.tileHeight).toDouble(),
  );

  void fit() {
    if (viewport.isEmpty || imageSize.isEmpty) return;
    final scale = math
        .min(
          (viewport.width - 24) / imageSize.width,
          (viewport.height - 24) / imageSize.height,
        )
        .clamp(.05, 12.0);
    transform.value = Matrix4.identity()
      ..translateByDouble(
        (viewport.width - imageSize.width * scale) / 2,
        (viewport.height - imageSize.height * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void zoom(double factor) {
    final scale = transform.value.getMaxScaleOnAxis();
    final ratio = (scale * factor).clamp(.05, 24.0) / scale;
    transform.value = transform.value.clone()
      ..scaleByDouble(ratio, ratio, 1, 1);
  }

  GridPos? point(Offset local) {
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx >= imageSize.width ||
        local.dy >= imageSize.height) {
      return null;
    }
    return GridPos(
      x: (local.dx / (widget.fine ? 1 : widget.tileWidth)).floor(),
      y: (local.dy / (widget.fine ? 1 : widget.tileHeight)).floor(),
    );
  }

  void paint(Offset local) {
    final next = point(local);
    if (next == null || next == previous) return;
    final before = previous ?? next;
    final steps = math.max(
      (next.x - before.x).abs(),
      (next.y - before.y).abs(),
    );
    for (var step = 0; step <= steps; step++) {
      final t = steps == 0 ? 1 : step / steps;
      widget.onPaint(
        GridPos(
          x: (before.x + (next.x - before.x) * t).round(),
          y: (before.y + (next.y - before.y) * t).round(),
        ),
      );
    }
    previous = next;
    setState(() => cursor = next);
  }

  KeyEventResult key(KeyEvent event) {
    if (event is! KeyDownEvent || !widget.enabled) {
      return KeyEventResult.ignored;
    }
    final current = cursor ?? const GridPos(x: 0, y: 0);
    final offset = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => const GridPos(x: -1, y: 0),
      LogicalKeyboardKey.arrowRight => const GridPos(x: 1, y: 0),
      LogicalKeyboardKey.arrowUp => const GridPos(x: 0, y: -1),
      LogicalKeyboardKey.arrowDown => const GridPos(x: 0, y: 1),
      _ => null,
    };
    if (offset != null) {
      setState(
        () => cursor = GridPos(
          x: (current.x + offset.x).clamp(
            0,
            (widget.fine ? imageSize.width.toInt() : widget.width) - 1,
          ),
          y: (current.y + offset.y).clamp(
            0,
            (widget.fine ? imageSize.height.toInt() : widget.height) - 1,
          ),
        ),
      );
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onStrokeStart();
      widget.onPaint(current);
      widget.onStrokeEnd();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void didUpdateWidget(DecorCollisionMask oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width || oldWidget.height != widget.height) {
      fitted = false;
    }
    if (oldWidget.fine != widget.fine) cursor = null;
  }

  @override
  void dispose() {
    focus.dispose();
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (imageSize.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StudioButton(
                label: 'Ajuster',
                secondary: true,
                icon: Icons.fit_screen,
                onPressed: fit,
              ),
              StudioButton(
                label: pan ? 'Peindre le masque' : 'Déplacer l’aperçu',
                secondary: true,
                icon: pan ? Icons.brush : Icons.pan_tool_outlined,
                onPressed: () => setState(() => pan = !pan),
              ),
              StudioButton(
                label: 'Zoom −',
                secondary: true,
                onPressed: () => zoom(.8),
              ),
              StudioButton(
                label: 'Zoom +',
                secondary: true,
                onPressed: () => zoom(1.25),
              ),
            ],
          ),
        ),
        Expanded(
          child: StudioAssetPreview(
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
                    maxScale: 24,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: Focus(
                      focusNode: focus,
                      onKeyEvent: (_, event) => key(event),
                      child: Semantics(
                        label:
                            'Collision sur le décor. Flèches pour viser, espace pour ${widget.erase ? 'effacer' : 'bloquer'}.',
                        child: Listener(
                          key: const ValueKey('decor-collision-canvas'),
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: pan || !widget.enabled
                              ? null
                              : (event) {
                                  if (event.buttons != kPrimaryMouseButton) {
                                    return;
                                  }
                                  focus.requestFocus();
                                  drawing = true;
                                  previous = null;
                                  widget.onStrokeStart();
                                  paint(event.localPosition);
                                },
                          onPointerMove: pan || !widget.enabled
                              ? null
                              : (event) {
                                  if (drawing) paint(event.localPosition);
                                },
                          onPointerUp: (_) {
                            if (drawing) widget.onStrokeEnd();
                            drawing = false;
                            previous = null;
                          },
                          onPointerCancel: (_) {
                            if (drawing) widget.onStrokeCancel();
                            drawing = false;
                            previous = null;
                          },
                          onPointerHover: (event) => setState(
                            () => cursor = point(event.localPosition),
                          ),
                          child: SizedBox.fromSize(
                            size: imageSize,
                            child: Stack(
                              children: [
                                Positioned.fill(child: widget.image),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _CollisionOverlay(
                                        widget,
                                        cursor,
                                        Theme.of(context).colorScheme,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
