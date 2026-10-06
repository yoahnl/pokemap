part of 'map_workspace_canvas.dart';

extension _MapWorkspaceCanvasGestures on _MapWorkspaceCanvasState {
  void _cancel() {
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
    _decorDraft = null;
    _decorPointer = null;
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
    if (_decorPointer == event.pointer && _decorDraft != null) {
      _decorDraft!.move(
        _pixelOffset(event.localPosition),
        precise: HardwareKeyboard.instance.isShiftPressed,
      );
      _refreshDecor();
      return;
    }
    if (_panPointer == event.pointer && _panPosition != null) {
      _translateViewport(event.position - _panPosition!);
      _panPosition = event.position;
      return;
    }
    if (widget.view.tool == StudioMapTool.border) {
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

  void _down(PointerDownEvent event) {
    if (event.buttons == kMiddleMouseButton ||
        (event.buttons == kPrimaryButton &&
            HardwareKeyboard.instance.isLogicalKeyPressed(
              LogicalKeyboardKey.space,
            ))) {
      _cancel();
      _panPointer = event.pointer;
      _panPosition = event.position;
      return;
    }
    if (event.buttons == kSecondaryButton) {
      _cancel();
      widget.document.stackPosition = _cell(event.localPosition);
      widget.document.stackPixelPosition = _pixel(event.localPosition);
      widget.onContextMenu?.call(_cell(event.localPosition), event.position);
      return;
    }
    if (event.buttons != kPrimaryButton ||
        widget.view.tool == StudioMapTool.pan) {
      return;
    }
    _focus.requestFocus();
    final cell = _cell(event.localPosition);
    final armed = widget.view.armedDecorIn(widget.document.current);
    final selected = widget.document.selected;
    if (widget.view.tool == StudioMapTool.select &&
        armed == null &&
        selected != null &&
        _canTransform(selected)) {
      final element = widget.project.elements
          .where((e) => e.id == selected.elementId)
          .firstOrNull;
      if (element != null) {
        final rect = decorLogicalRect(selected, element, widget.project);
        final radius = 7 / widget.view.transform.value.getMaxScaleOnAxis();
        for (final handle in DecorResizeHandle.values) {
          if ((handle.point(rect) - event.localPosition).distance <= radius) {
            _beginDecor(selected, event.localPosition, handle: handle);
            _decorPointer = event.pointer;
            _refreshGesture();
            return;
          }
        }
      }
    }
    if (armed == null) {
      try {
        _characterGesture = MapCharacterGesture.start(
          document: widget.document,
          project: widget.project,
          view: widget.view,
          origin: cell,
        );
        if (_characterGesture != null) {
          widget.onChanged();
          return;
        }
      } catch (error) {
        widget.document.error = error.toString();
        widget.onChanged();
        return;
      }
    }
    _start = cell;
    _gestureSource = widget.document.current;
    final tool = widget.view.tool;
    if (tool == StudioMapTool.environment) {
      final session = widget.view.environment;
      if (session == null) {
        _cancel();
        return;
      }
      _gestureTool = tool;
      _environmentOwner = session;
      _environmentTool = session.tool;
      _environmentProject = widget.project;
      _preview = cell;
      if (session.tool != EnvironmentPaintTool.rectangle) {
        _environmentStroke = MapEncounterCellStroke(
          widget.document.current.size,
          session.tool == EnvironmentPaintTool.erase,
          cell,
        );
      }
      _refreshGesture();
      return;
    }
    if (tool == StudioMapTool.eraseDecor) {
      final top = _commands
          .stackAtPixel(_pixel(event.localPosition))
          .firstOrNull;
      if (top != null) {
        widget.document.commit(
          removeMapPlacedElement(widget.document.current, instanceId: top.id),
        );
        if (widget.document.selectedId == top.id) {
          widget.view.clearSelection(widget.document);
        }
      }
      _cancel();
      widget.onChanged();
      return;
    }
    if (tool == StudioMapTool.border) {
      _addBorderAngle(event.localPosition);
      _cancel();
      return;
    }
    if (tool == StudioMapTool.encounterPaint ||
        tool == StudioMapTool.encounterErase) {
      _encounterStroke = MapEncounterCellStroke(
        widget.document.current.size,
        tool == StudioMapTool.encounterErase,
        cell,
      );
      _refreshGesture();
    } else if (tool == StudioMapTool.place) {
      final brush = widget.view.brush;
      final placed = brush == null ? null : _commands.place(brush, cell);
      if (placed != null) {
        widget.view.select(widget.document, MapSelectionFamily.decor, placed);
      }
      _cancel();
      widget.onChanged();
    } else if (tool == StudioMapTool.select) {
      final hits = _commands.stackAtPixel(_pixel(event.localPosition));
      final held = widget.view.selectedFor(
        widget.document.current.id,
        MapSelectionFamily.decor,
      );
      _armed = armed != null;
      _moving =
          armed ??
          (hits.any((e) => e.id == held)
              ? hits.firstWhere((e) => e.id == held)
              : hits.firstOrNull);
      final moving = _moving;
      if (moving == null) {
        widget.view.clearSelection(widget.document);
        _cancel();
        _panPointer = event.pointer;
        _panPosition = event.position;
      } else {
        widget.view.select(
          widget.document,
          MapSelectionFamily.decor,
          moving.id,
        );
        if (_canTransform(moving)) {
          _beginDecor(moving, event.localPosition);
          _decorPointer = event.pointer;
        }
      }
      widget.document.stackPosition = cell;
      widget.document.stackPixelPosition = _pixel(event.localPosition);
      widget.onChanged();
    } else {
      try {
        _stroke = MapCanvasStroke.start(
          map: widget.document.current,
          project: widget.project,
          view: widget.view,
          commands: _commands,
          origin: cell,
        );
        _refreshGesture();
      } catch (error) {
        widget.document.error = error.toString();
        _cancel();
        widget.onChanged();
      }
    }
  }
}
