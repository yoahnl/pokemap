part of 'map_editing_viewport_2d.dart';

extension _MapWorkspaceCanvasPointerDown on _MapEditingViewport2DState {
  void _down(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons & kSecondaryMouseButton != 0) {
      _cancel();
      _panPointer = event.pointer;
      _panPosition = event.position;
      _secondaryPanStart = event;
      _secondaryPan = true;
      return;
    }
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
    widget.view.reconcileLocks(widget.document);
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
      if (widget.view.borderEditingMode == BorderStrokeEditingMode.erase) {
        _startBorderErase(event.localPosition);
        _refreshGesture();
        return;
      }
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
      final keys = HardwareKeyboard.instance;
      if (moving != null &&
          armed == null &&
          (keys.isShiftPressed || keys.isMetaPressed)) {
        _cancel();
        _modifierPress = (
          pointer: event.pointer,
          decor: moving,
          origin: event.localPosition,
          kind: event.kind,
        );
      } else if (moving == null) {
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
