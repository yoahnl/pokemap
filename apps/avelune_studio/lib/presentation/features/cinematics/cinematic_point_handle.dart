import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

class CinematicPointHandle extends StatefulWidget {
  const CinematicPointHandle({
    super.key,
    required this.point,
    required this.cell,
    required this.onMove,
    required this.enabled,
  });
  final CinematicStagePoint point;
  final Size cell;
  final ValueChanged<Offset> onMove;
  final bool enabled;
  @override
  State<CinematicPointHandle> createState() => _CinematicPointHandleState();
}

class _CinematicPointHandleState extends State<CinematicPointHandle> {
  Offset delta = Offset.zero;
  Offset down = Offset.zero;
  bool dragging = false;
  final focus = FocusNode();
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !widget.enabled,
    child: Focus(
      focusNode: focus,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          setState(() {
            delta = Offset.zero;
            dragging = false;
          });
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        key: ValueKey('cinematic-point-${widget.point.id}'),
        behavior: HitTestBehavior.opaque,
        onPanDown: (event) => down = event.localPosition,
        onPanStart: widget.enabled
            ? (event) {
                focus.requestFocus();
                setState(() {
                  dragging = true;
                  delta = event.localPosition - down;
                });
              }
            : null,
        onPanUpdate: widget.enabled
            ? (e) {
                if (dragging) setState(() => delta += e.delta);
              }
            : null,
        onPanCancel: () => setState(() {
          dragging = false;
          delta = Offset.zero;
        }),
        onPanEnd: (_) {
          if (dragging) {
            widget.onMove(
              Offset(
                (widget.point.x + delta.dx / widget.cell.width).roundToDouble(),
                (widget.point.y + delta.dy / widget.cell.height)
                    .roundToDouble(),
              ),
            );
          }
          setState(() {
            dragging = false;
            delta = Offset.zero;
          });
        },
        child: Transform.translate(
          offset: delta,
          child: Tooltip(
            message: '${widget.point.label} · glisser pour déplacer',
            child: Icon(
              Icons.control_point,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    ),
  );
}
