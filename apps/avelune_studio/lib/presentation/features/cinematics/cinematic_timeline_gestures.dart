part of 'cinematic_timeline_editor.dart';

extension _CinematicTimelineGestures on _CinematicTimelineEditorState {
  void fitOnce(double width, int duration) {
    if (widget.view.timelineFitted) return;
    widget.view.timelineFitted = true;
    if (widget.view.timelineScale != .06) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.view.timelineScale = (width / math.max(1000, duration)).clamp(
        .008,
        .5,
      );
      widget.changed();
    });
  }

  void select(String id) {
    if (widget.beforeSelection?.call() == false) return;
    if (HardwareKeyboard.instance.isShiftPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed) {
      if (!widget.view.selection.add(id)) widget.view.selection.remove(id);
      widget.changed();
    } else {
      widget.onSelect(id);
    }
    focus.requestFocus();
  }

  Widget _clip(
    CinematicTimelineTimeBlock block,
    CinematicTimelineTimeLayoutReadModel original,
    BuildContext context,
  ) {
    final step = widget.asset.timeline.steps[block.stepIndex];
    final scale = widget.view.timelineScale;
    return StudioTimelineClip(
      key: ValueKey('cinematic-clip-${block.stepId}'),
      handleKey: ValueKey('cinematic-duration-${block.stepId}'),
      label:
          '${step.label ?? cinematicActionLabel(step.kind)} · ${block.durationMs == null ? 'variable' : cinematicTime(block.durationMs!)}',
      accent: cinematicActionColor(context, block.kind),
      selected: widget.view.selection.contains(block.stepId),
      onSelect: () => select(block.stepId),
      onDragStart: () {
        if (widget.beforeSelection?.call() == false) return;
        if (!widget.view.selection.contains(block.stepId)) {
          widget.onSelect(block.stepId);
        }
        focus.requestFocus();
        mutate(() {
          dragging = block.stepId;
          delta = 0;
        });
      },
      onDragUpdate: (value) {
        if (dragging != block.stepId) return;
        mutate(() {
          delta += value;
          final time = block.startMs + delta / scale;
          insertion = original.blocks
              .where((b) => time >= (b.startMs + b.endMs) / 2)
              .length;
        });
      },
      onDragEnd: () {
        final target = insertion;
        if (dragging != null && target != null) widget.onMove(target);
        cancel();
      },
      onResizeStart: !cinematicDurationEditable(step)
          ? null
          : () {
              if (widget.beforeSelection?.call() == false) return;
              widget.onSelect(step.id);
              focus.requestFocus();
              mutate(() {
                resizing = step.id;
                delta = 0;
                draftDuration = step.durationMs;
              });
            },
      onResizeUpdate: (value) {
        if (resizing != step.id) return;
        mutate(() {
          delta += value;
          final source = widget.asset.timeline.steps.firstWhere(
            (s) => s.id == step.id,
          );
          draftDuration = (source.durationMs! + delta / scale).round().clamp(
            1,
            3600000,
          );
        });
      },
      onResizeEnd: () {
        if (resizing != null && draftDuration != null) {
          widget.onDuration(resizing!, draftDuration!);
        }
        cancel();
      },
    );
  }
}
