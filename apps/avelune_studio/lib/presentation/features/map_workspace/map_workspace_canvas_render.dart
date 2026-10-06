part of 'map_workspace_canvas.dart';

extension _MapWorkspaceCanvasRender on _MapWorkspaceCanvasState {
  Widget _buildCanvas(BuildContext context) {
    final map = widget.document.current;
    final terrainHighlight = MapTerrainHighlight.resolve(
      map,
      widget.view,
      stroke: _stroke,
    );
    final environment = widget.view.tool == StudioMapTool.environment
        ? widget.view.environment
        : null;
    final environmentPreview =
        environment != null &&
            identical(environment.previewSource, map) &&
            identical(environment.previewProject, widget.project)
        ? environment.previewResult
        : null;
    final renderedMap =
        _characterGesture?.preview ??
        _stroke?.preview ??
        environmentPreview ??
        map;
    final selected =
        _decorDraft?.candidate ??
        (_preview == null
            ? widget.document.selected
            : widget.document.selected?.copyWith(pos: _preview!));
    final selectedElement = widget.project.elements
        .where((e) => e.id == selected?.elementId)
        .firstOrNull;
    final brush = widget.view.tool == StudioMapTool.place
        ? widget.view.brush
        : null;
    final hover = brush == null ? null : _hoverCell;
    final footprint = brush == null
        ? null
        : resolveMapPlacedElementFootprint(
            instance: MapPlacedElement(
              id: 'preview',
              layerId: '',
              elementId: brush.id,
              pos: hover ?? const GridPos(x: 0, y: 0),
            ),
            element: brush,
          ).destinationSize;
    return LayoutBuilder(
      builder: (context, constraints) {
        widget.view.attachViewport(
          constraints.biggest,
          Size(map.size.width * _width, map.size.height * _height),
          Size(_width, _height),
          mounted: () => mounted,
          surface: _surface,
        );
        return ClipRect(
          child: InteractiveViewer(
            key: const ValueKey('map-viewport'),
            transformationController: widget.view.transform,
            constrained: false,
            alignment: Alignment.topLeft,
            boundaryMargin: const EdgeInsets.all(400),
            minScale: .15,
            maxScale: 8,
            panEnabled: widget.view.tool == StudioMapTool.pan,
            child: Focus(
              focusNode: _focus,
              onFocusChange: (focused) {
                if (!focused && _gestureSource != null) _mutateGesture(_cancel);
              },
              onKeyEvent: (node, event) {
                final result = _decorKey(event);
                if (result == KeyEventResult.handled) return result;
                if (widget.view.tool == StudioMapTool.border &&
                    event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  _finishBorder();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: MouseRegion(
                onExit: (_) {
                  final draft = widget.view.borderDraft;
                  if (_hoverCell != null || draft?.hover != null) {
                    _mutateGesture(() {
                      _hoverCell = null;
                      if (draft != null) {
                        widget.view.borderDraft = draft.pointAt(null);
                      }
                    });
                  }
                },
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  key: const ValueKey('map-canvas'),
                  onPointerDown: _down,
                  onPointerHover: _hover,
                  onPointerMove: _move,
                  onPointerSignal: _pointerSignal,
                  onPointerUp: _up,
                  onPointerCancel: (_) => _mutateGesture(_cancel),
                  child: SizedBox(
                    key: _surface,
                    width: map.size.width * _width,
                    height: map.size.height * _height,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: widget.visuals.canvas(
                            renderedMap,
                            placedElementPreview: _decorDraft?.candidate,
                            collisionColor:
                                widget.view.tool == StudioMapTool.select &&
                                    widget.view.showDecorCollision
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                        ),
                        Positioned.fill(
                          child: MapCanvasSurfaceBounds(map: renderedMap),
                        ),
                        if (terrainHighlight != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                key: const ValueKey('terrain-highlight'),
                                painter: MapTerrainHighlightPainter(
                                  highlight: terrainHighlight,
                                  tile: Size(_width, _height),
                                  color: StudioColors.of(
                                    context,
                                  ).canvasSelection,
                                  addition: StudioColors.of(context).success,
                                  removal: Theme.of(context).colorScheme.error,
                                  background: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  dimOthers: widget.view.dimOtherTerrains,
                                  transform: widget.view.transform,
                                ),
                              ),
                            ),
                          ),
                        if (widget.view.tool == StudioMapTool.environment &&
                            widget.view.environment != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: MapEnvironmentOverlay(
                                document: widget.document,
                                project: widget.project,
                                session: widget.view.environment!,
                                tile: Size(_width, _height),
                                stroke: _environmentStroke?.cells ?? const [],
                                start: _start,
                                end: _preview,
                              ),
                            ),
                          ),
                        if (hover != null && footprint != null)
                          Positioned(
                            left: hover.x * _width,
                            top: hover.y * _height,
                            child: IgnorePointer(
                              child: Opacity(
                                key: const ValueKey('decor-placement-preview'),
                                opacity: .72,
                                child: widget.visuals.placementPreview(
                                  brush!,
                                  Size(
                                    footprint.width * _width,
                                    footprint.height * _height,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: buildEditingOverlay(
                                context: context,
                                map: map,
                                project: widget.project,
                                document: widget.document,
                                view: widget.view,
                                gesture: _characterGesture,
                                stroke: _stroke,
                                encounterStroke: _encounterStroke,
                                borderDraft:
                                    widget.view.tool == StudioMapTool.border
                                    ? widget.view.borderDraft
                                    : null,
                                borderCursor:
                                    widget.view.tool == StudioMapTool.border
                                    ? _hoverCell
                                    : null,
                                preview: _preview,
                                cellWidth: _width,
                                cellHeight: _height,
                              ),
                            ),
                          ),
                        ),
                        if (selected != null &&
                            selectedElement != null &&
                            widget.view.tool == StudioMapTool.select)
                          Positioned.fill(
                            child: MapDecorTransformOverlay(
                              instance: selected,
                              element: selectedElement,
                              project: widget.project,
                              transform: widget.view.transform,
                              resizable: _canTransform(selected),
                              invalid: _decorDraft?.error != null,
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
    );
  }
}
