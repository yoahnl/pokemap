part of 'story_graph_canvas.dart';

extension _StoryGraphSurface on _StoryGraphCanvasState {
  Widget _surface(BuildContext context) => Focus(
    focusNode: _focus,
    onKeyEvent: _keyboard,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final view = _state.viewport;
        view.size = constraints.biggest;
        if (!view.initialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !view.initialized) {
              _state.fit(_graph.bounds(_positions));
            }
          });
        }
        final positions = _positions;
        return ClipRect(
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent && _source == null) {
                  GestureBinding.instance.pointerSignalResolver.register(
                    event,
                    (_) => view.zoomAt(
                      view.zoom * (event.scrollDelta.dy > 0 ? .9 : 1.1),
                      event.localPosition,
                    ),
                  );
                }
              },
              onPointerPanZoomStart: (e) => view.startTrackpad(e.localPosition),
              onPointerPanZoomUpdate: (e) {
                if (_source == null) {
                  view.updateTrackpad(e.scale, e.pan, e.localPosition);
                }
              },
              onPointerPanZoomEnd: (_) => view.trackpadActive = false,
              child: Stack(
                key: _key,
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    key: const ValueKey('story-graph-pan-surface'),
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (e) {
                      _focus.requestFocus();
                      final edge = storyGraphEdgeAt(
                        _graph,
                        _state,
                        positions,
                        e.localPosition,
                      );
                      widget.onSelect(
                        edge == null ? null : StoryGraphSelection.edge(edge),
                      );
                    },
                    onPanUpdate: (e) {
                      if (_source == null && !view.trackpadActive) {
                        view.translate(e.delta);
                      }
                    },
                    child: CustomPaint(
                      painter: StoryGraphPainter(
                        graph: _graph,
                        state: _state,
                        positions: positions,
                        colors: Theme.of(context).colorScheme,
                        labelStyle: Theme.of(
                          context,
                        ).textTheme.labelSmall!.copyWith(fontSize: 11),
                        textScaler: MediaQuery.textScalerOf(context),
                        selectedId: widget.selection?.id,
                        previewStart: _source == null
                            ? null
                            : view.worldToLocal(
                                _graph.output(_source!.id, positions),
                              ),
                        previewEnd: _wireEnd,
                      ),
                    ),
                  ),
                  StoryGraphLayer(
                    graph: _graph,
                    state: _state,
                    positions: positions,
                    selection: widget.selection,
                    targetId: _targetId,
                    onSelect: (n) {
                      _focus.requestFocus();
                      widget.onSelect(StoryGraphSelection.node(n));
                    },
                    onDragStart: (id) {
                      _focus.requestFocus();
                      _rebuild(() {
                        _dragId = id;
                        _dragPosition = _graph.rect(id, positions).topLeft;
                      });
                    },
                    onDragMove: (delta) {
                      if (_dragPosition != null) {
                        _rebuild(
                          () => _dragPosition =
                              _dragPosition! + delta / view.zoom,
                        );
                      }
                    },
                    onDragEnd: () {
                      final id = _dragId, position = _dragPosition;
                      _cancel();
                      if (id != null && position != null) {
                        _state.moveGroup(id, position);
                      }
                    },
                    onCancel: _cancel,
                    onWireStart: (n) {
                      _focus.requestFocus();
                      _rebuild(() {
                        _source = n;
                        _wireEnd = view.worldToLocal(
                          _graph.output(n.id, positions),
                        );
                      });
                    },
                    onWireMove: _wireMove,
                    onWireEnd: _wireFinish,
                    onAddStep: widget.onAddStep,
                    onOpenScene: widget.onOpenScene,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: StoryGraphControls(
                      graph: _graph,
                      state: _state,
                      positions: positions,
                      selection: widget.selection,
                    ),
                  ),
                  if (_state.showMinimap &&
                      constraints.maxWidth > 450 &&
                      constraints.maxHeight > 300)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: StoryGraphMinimap(
                        graph: _graph,
                        state: _state,
                        positions: positions,
                      ),
                    ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Text(
                      _source == null
                          ? 'Pointillés : ordre de présentation · Déplacement visuel conservé pour cette session'
                          : 'Reliez une étape précise · Échap pour annuler',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
