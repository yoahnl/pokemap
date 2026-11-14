part of 'map_editing_viewport_2d.dart';

extension _MapWorkspaceCanvasGestures on _MapEditingViewport2DState {
  void _cancel() {
    _borderErase = null;
    _borderErasePreview = null;
    _borderEraseTransform = null;
    _start = null;
    _preview = null;
    _hoverCell = null;
    _moving = null;
    _armed = false;
    _stroke = null;
    _encounterStroke = null;
    _environmentStroke = null;
    _environmentOwner = null;
    _environmentTool = null;
    _environmentProject = null;
    _gestureSource = null;
    _characterGesture = null;
    _panPointer = null;
    _panPosition = null;
    _secondaryPanStart = null;
    _secondaryPan = false;
    _decorDraft = null;
    _decorPointer = null;
    _modifierPress = null;
    _nudgeKeys.clear();
    _gestureTool = null;
  }

  void _translateViewport(Offset delta) {
    final matrix = Matrix4.copy(widget.view.transform.value);
    matrix.storage[12] += delta.dx;
    matrix.storage[13] += delta.dy;
    widget.view.transform.value = matrix;
  }

  void _pointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent ||
        event.kind != PointerDeviceKind.trackpad) {
      return;
    }
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (_) => _translateViewport(-event.scrollDelta),
    );
  }

  void _hover(PointerHoverEvent event) {
    final position = _cell(event.localPosition);
    if (widget.view.tool == StudioMapTool.border) {
      if (_borderErase != null) {
        _sampleBorderErase(event.localPosition);
        _refreshGesture();
        return;
      }
      _previewBorderAt(event.localPosition);
      return;
    }
    final cell =
        widget.view.tool == StudioMapTool.place && widget.view.brush != null
        ? position
        : null;
    if (cell != _hoverCell) _mutateGesture(() => _hoverCell = cell);
  }

  void _move(PointerMoveEvent event) {
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons & kSecondaryMouseButton != 0 &&
        _panPointer != event.pointer) {
      _cancel();
      _panPointer = event.pointer;
      _panPosition = event.position - event.delta;
      _secondaryPan = true;
    }
    final press = _modifierPress;
    if (press != null && press.pointer == event.pointer) {
      if ((event.localPosition - press.origin).distance <=
          computePanSlop(press.kind, null)) {
        return;
      }
      _modifierPress = null;
      widget.view.select(
        widget.document,
        MapSelectionFamily.decor,
        press.decor.id,
      );
      if (_canTransform(press.decor)) {
        _beginDecor(press.decor, press.origin);
        _decorPointer = event.pointer;
      }
      widget.onChanged();
    }
    if (_decorPointer == event.pointer && _decorDraft != null) {
      _decorDraft!.move(
        _pixelOffset(event.localPosition),
        precise: HardwareKeyboard.instance.isShiftPressed,
      );
      _refreshDecor();
      return;
    }
    if (_panPointer == event.pointer && _panPosition != null) {
      if (_secondaryPan && event.buttons & kSecondaryMouseButton == 0) {
        _secondaryPanStart = null;
        _panPosition = event.position;
        return;
      }
      final start = _secondaryPanStart;
      if (start != null) {
        if ((event.position - start.position).distance <=
            kPrecisePointerPanSlop) {
          return;
        }
        _secondaryPanStart = null;
      }
      _translateViewport(event.position - _panPosition!);
      _panPosition = event.position;
      return;
    }
    if (widget.view.tool == StudioMapTool.border) {
      if (_borderErase != null) {
        _sampleBorderErase(event.localPosition);
        _refreshGesture();
        return;
      }
      _previewBorderAt(event.localPosition);
      return;
    }
    if (_characterGesture != null) {
      _mutateGesture(() => _characterGesture!.move(_cell(event.localPosition)));
      return;
    }
    final start = _start;
    if (start == null) return;
    final cell = _cell(event.localPosition);
    if (widget.view.tool == StudioMapTool.environment) {
      if (!_ownsEnvironmentGesture) {
        _mutateGesture(_cancel);
        return;
      }
      if (_environmentStroke != null) {
        _mutateGesture(() => _environmentStroke!.paint(cell));
      } else {
        _mutateGesture(() => _preview = cell);
      }
      return;
    }
    if (_encounterStroke != null) {
      _mutateGesture(() => _encounterStroke!.paint(cell));
      return;
    }
    if (_stroke != null) {
      _paint(cell);
      return;
    }
    final moving = _moving;
    if (moving != null) {
      _mutateGesture(
        () => _preview = GridPos(
          x: moving.pos.x + cell.x - start.x,
          y: moving.pos.y + cell.y - start.y,
        ),
      );
    }
  }
}
