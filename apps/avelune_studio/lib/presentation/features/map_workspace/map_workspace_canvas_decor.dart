part of 'map_workspace_canvas.dart';

extension _MapWorkspaceCanvasDecor on _MapWorkspaceCanvasState {
  bool _canTransform(MapPlacedElement instance) {
    if (!identical(_ownershipMap, widget.document.current)) {
      _ownershipMap = widget.document.current;
      _environmentOwnedIds = environmentOwnedMapPlacedElementIds(
        widget.document.current,
      );
    }
    return isAuthoredMapPlacedElement(instance) &&
        !_environmentOwnedIds.contains(instance.id) &&
        widget.project.elements.any(
          (element) => element.id == instance.elementId,
        );
  }

  void _beginDecor(
    MapPlacedElement instance,
    Offset pointer, {
    DecorResizeHandle? handle,
  }) {
    _decorDraft = MapDecorTransformDraft(
      source: widget.document.current,
      project: widget.project,
      original: instance,
      pointer: _pixelOffset(pointer),
      precise: HardwareKeyboard.instance.isShiftPressed,
      handle: handle,
      lockRatio: widget.view.lockDecorProportions,
    );
    _gestureTool = widget.view.tool;
    _gestureSource = widget.document.current;
  }

  void _refreshDecor() {
    if (_previewScheduled) return;
    _previewScheduled = true;
    WidgetsBinding.instance.scheduleFrameCallback((_) {
      _previewScheduled = false;
      if (mounted) _mutateGesture(() {});
    });
  }

  void _commitDecor() {
    final draft = _decorDraft;
    if (draft != null &&
        identical(draft.source, widget.document.current) &&
        identical(draft.project, widget.project) &&
        draft.original.id == widget.document.selectedId) {
      if (draft.error != null) {
        widget.document.error = draft.error;
      } else if (draft.candidate != draft.original) {
        final rect = draft.geometry.logicalRect;
        _commands.setGeometry(
          draft.original.id,
          x: rect.leftPx,
          y: rect.topPx,
          size: draft.candidate.pixelSize,
        );
      }
    }
    if (_armed) widget.view.pendingMove = null;
    _mutateGesture(_cancel);
    widget.onChanged();
  }

  KeyEventResult _decorKey(KeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape && _decorDraft != null) {
      _mutateGesture(_cancel);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      _decorDraft?.rebasePrecision(HardwareKeyboard.instance.isShiftPressed);
    }
    if (event is KeyUpEvent && _nudgeKeys.remove(key)) {
      if (_nudgeKeys.isEmpty) _commitDecor();
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        !HardwareKeyboard.instance.isShiftPressed ||
        widget.view.tool != StudioMapTool.select ||
        _decorPointer != null) {
      return KeyEventResult.ignored;
    }
    final delta = switch (key) {
      LogicalKeyboardKey.arrowLeft => const Offset(-1, 0),
      LogicalKeyboardKey.arrowRight => const Offset(1, 0),
      LogicalKeyboardKey.arrowUp => const Offset(0, -1),
      LogicalKeyboardKey.arrowDown => const Offset(0, 1),
      _ => null,
    };
    final selected = widget.document.selected;
    if (delta == null || selected == null || !_canTransform(selected)) {
      return KeyEventResult.ignored;
    }
    if (_decorDraft == null) _beginDecor(selected, Offset.zero);
    _nudgeKeys.add(key);
    _decorDraft!.nudge(delta.dx.toInt(), delta.dy.toInt());
    _refreshDecor();
    return KeyEventResult.handled;
  }
}
