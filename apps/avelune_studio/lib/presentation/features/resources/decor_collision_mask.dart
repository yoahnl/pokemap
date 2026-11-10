import '../../../features/decors/application/decor_draft.dart';

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';

part 'decor_collision_overlay.dart';

class DecorCollisionMask extends StatefulWidget {
  DecorCollisionMask({
    super.key,
    required this.draft,
    required this.image,
    required this.onChanged,
    this.fine = false,
    this.erase = false,
    this.brushSize = 1,
    this.enabled = true,
  }) : width = draft.selection.width,
       height = draft.selection.height,
       tileWidth = draft.tileWidth,
       tileHeight = draft.tileHeight,
       blocked = {...draft.blocked},
       pixels = draft.collisionPixels,
       maskWidth = draft.pixelWidth,
       revision = draft.collisionRevision;

  final DecorDraft draft;
  final Widget image;
  final VoidCallback onChanged;
  final bool fine, erase, enabled;
  final int width,
      height,
      tileWidth,
      tileHeight,
      maskWidth,
      revision,
      brushSize;
  final Set<GridPos> blocked;
  final List<bool>? pixels;

  @override
  State<DecorCollisionMask> createState() => _DecorCollisionMaskState();
}

class _DecorCollisionMaskState extends State<DecorCollisionMask> {
  final transform = TransformationController();
  final focus = FocusNode();
  bool pan = false, fitted = false;
  GridPos? get cursor => widget.draft.collisionCursor;
  set cursor(GridPos? value) => widget.draft.collisionCursor = value;
  void _change(VoidCallback action) {
    setState(action);
    widget.onChanged();
  }

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

  KeyEventResult key(KeyEvent event) {
    if (event is! KeyDownEvent || !widget.enabled) {
      return KeyEventResult.ignored;
    }
    final offset = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => const GridPos(x: -1, y: 0),
      LogicalKeyboardKey.arrowRight => const GridPos(x: 1, y: 0),
      LogicalKeyboardKey.arrowUp => const GridPos(x: 0, y: -1),
      LogicalKeyboardKey.arrowDown => const GridPos(x: 0, y: 1),
      _ => null,
    };
    if (offset != null) {
      _change(
        () => widget.draft.moveCollisionCursor(offset, fine: widget.fine),
      );
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      _change(
        () => widget.draft.paintCollisionCursor(
          fine: widget.fine,
          solid: !widget.erase,
          size: widget.brushSize,
        ),
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void didUpdateWidget(DecorCollisionMask oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.draft, widget.draft)) {
      oldWidget.draft.cancelCollisionPointer();
    }
    if (oldWidget.width != widget.width || oldWidget.height != widget.height) {
      fitted = false;
    }
    if (oldWidget.fine != widget.fine) cursor = null;
  }

  @override
  void dispose() {
    widget.draft.cancelCollisionPointer();
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
                                  _change(
                                    () => widget.draft.beginCollisionPointer(
                                      event.localPosition.dx,
                                      event.localPosition.dy,
                                      fine: widget.fine,
                                      solid: !widget.erase,
                                      size: widget.brushSize,
                                    ),
                                  );
                                },
                          onPointerMove: pan || !widget.enabled
                              ? null
                              : (event) {
                                  if (widget.draft.collisionDrawing) {
                                    _change(
                                      () => widget.draft.moveCollisionPointer(
                                        event.localPosition.dx,
                                        event.localPosition.dy,
                                        fine: widget.fine,
                                        solid: !widget.erase,
                                        size: widget.brushSize,
                                      ),
                                    );
                                  }
                                },
                          onPointerUp: (_) {
                            if (widget.draft.collisionDrawing) {
                              _change(widget.draft.endCollisionPointer);
                            }
                          },
                          onPointerCancel: (_) {
                            if (widget.draft.collisionDrawing) {
                              _change(widget.draft.cancelCollisionPointer);
                            }
                          },
                          onPointerHover: (event) => setState(
                            () => cursor = widget.draft.collisionPoint(
                              event.localPosition.dx,
                              event.localPosition.dy,
                              fine: widget.fine,
                            ),
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
