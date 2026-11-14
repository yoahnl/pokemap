part of 'map_editing_viewport_2d.dart';

extension _MapWorkspaceCanvasPointerUp on _MapEditingViewport2DState {
  void _paint(GridPos cell) {
    try {
      if (_stroke?.matches(widget.view) == false) {
        _cancel();
      } else {
        _stroke?.paint(cell);
      }
    } on Object catch (error) {
      widget.document.error = error.toString();
      _cancel();
      widget.onChanged();
    }
    _refreshGesture();
  }

  void _up(PointerUpEvent event) {
    final press = _modifierPress;
    if (press != null && press.pointer == event.pointer) {
      _modifierPress = null;
      widget.view.toggleDecorInSelection(widget.document, press.decor.id);
      widget.onChanged();
      return;
    }
    if (_borderErase != null) {
      try {
        if (_ownsBorderEraseGesture) {
          _sampleBorderErase(event.localPosition);
          final draft = _borderErase;
          if (draft != null && _ownsBorderEraseGesture) {
            MapBorderEditingCommands(
              widget.document,
              widget.project,
            ).finishErase(draft);
            widget.view.repairBorderSelection(widget.document.current);
          }
        }
      } on Object catch (failure) {
        widget.document.error = failure.toString();
      }
      _mutateGesture(_cancel);
      widget.onChanged();
      return;
    }
    if (_decorPointer == event.pointer && _decorDraft != null) {
      _decorDraft!.move(
        _pixelOffset(event.localPosition),
        precise: HardwareKeyboard.instance.isShiftPressed,
      );
      _commitDecor();
      return;
    }
    if (_panPointer == event.pointer) {
      final contextStart = _secondaryPanStart;
      _cancel();
      if (contextStart != null) {
        final cell = _cell(contextStart.localPosition);
        widget.document.stackPosition = cell;
        widget.document.stackPixelPosition = _pixel(contextStart.localPosition);
        widget.onContextMenu?.call(cell, contextStart.position);
      }
      return;
    }
    if (_characterGesture != null) {
      final zone = _characterGesture!.commit();
      _mutateGesture(_cancel);
      widget.onChanged();
      if (zone != null) widget.onZoneDrawn?.call(zone);
      return;
    }
    if (_gestureSource != widget.document.current) {
      _cancel();
      return;
    }
    if (_environmentOwner != null && !_ownsEnvironmentGesture) {
      _mutateGesture(_cancel);
      return;
    }
    final moving = _moving;
    final preview = _preview;
    if (moving != null && preview != null) _commands.move(moving.id, preview);
    if (_armed) widget.view.pendingMove = null;
    final encounterStroke = _encounterStroke;
    final environment = _environmentOwner;
    if (widget.view.tool == StudioMapTool.environment &&
        environment != null &&
        _start != null) {
      try {
        final commands = EnvironmentEditingCommands(
          widget.document,
          widget.project,
        );
        if (environment.tool == EnvironmentPaintTool.rectangle) {
          commands.paintRectangle(
            environment,
            _start!,
            _cell(event.localPosition),
          );
        } else if (_environmentStroke != null) {
          _environmentStroke!.paint(_cell(event.localPosition));
          commands.paint(
            environment,
            _environmentStroke!.cells,
            erase: environment.tool == EnvironmentPaintTool.erase,
          );
        }
      } on Object catch (failure) {
        widget.document.error = environmentEditingMessage(failure);
      }
    }
    if (encounterStroke != null) {
      try {
        final zone =
            GameplayZoneEditingCommands(
              widget.document,
              widget.project,
            ).paintEncounterCells(
              encounterStroke.cells,
              erase: encounterStroke.erase,
              selectedZoneId: widget.view.selectedFor(
                widget.document.current.id,
                MapSelectionFamily.zone,
              ),
            );
        if (zone != null) {
          widget.view.select(widget.document, MapSelectionFamily.zone, zone.id);
        }
      } catch (error) {
        widget.document.error = error.toString();
      }
    }
    final stroke = _stroke;
    if (stroke != null) {
      try {
        if (identical(stroke.project, widget.project) &&
            stroke.matches(widget.view)) {
          widget.document.commit(stroke.commit());
        }
      } catch (_) {
        widget.document.error =
            'Ce trait ne peut pas être appliqué à cette carte.';
      }
    }
    _mutateGesture(_cancel);
    widget.onChanged();
  }
}
