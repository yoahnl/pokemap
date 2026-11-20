part of 'scene_graph_canvas.dart';

final class _CardDrag {
  _CardDrag({
    required this.pointer,
    required this.press,
    required this.hit,
    required this.origins,
    required this.collapse,
  });

  final int pointer;
  final Offset press;
  final String hit;
  final Map<String, SceneGraphPoint> origins;
  final bool collapse;
  bool moved = false;
}

extension _SceneGraphCanvasPointer on SceneGraphCanvasState {
  void _down(PointerDownEvent event) {
    final camera = _camera;
    if (camera == null) return;
    _pointer = event.localPosition;
    _focus.requestFocus();
    if (_menu != null) {
      _closeMenu();
      return;
    }
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons & (kSecondaryMouseButton | kMiddleMouseButton) != 0) {
      _panPointer = event.pointer;
      if (event.buttons & kSecondaryMouseButton != 0) {
        _rightPress = (
          pointer: event.pointer,
          origin: event.localPosition,
          moved: false,
        );
      }
      return;
    }
    if (event.buttons & kPrimaryButton == 0) return;
    final world = camera.value.toWorld(event.localPosition);
    final keyboard = HardwareKeyboard.instance;
    if (_editable) {
      final exit = sceneGraphExitAt(
        _view,
        world,
        SceneGraphCanvasState._portReach / camera.value.scale,
      );
      if (exit != null) {
        if (keyboard.isAltPressed) {
          _unlink(exit);
        } else {
          _mutate(
            () => _wire = (
              pointer: event.pointer,
              from: exit,
              end: event.localPosition,
            ),
          );
        }
        return;
      }
    }
    final additive =
        keyboard.isShiftPressed ||
        keyboard.isMetaPressed ||
        keyboard.isControlPressed;
    final hit = sceneGraphCardAt(_view, world);
    if (hit != null) {
      final keep = !additive && _selected.contains(hit.id);
      _mutate(() {
        _selected = keep
            ? _selected
            : !additive
            ? {hit.id}
            : _selected.contains(hit.id)
            ? (_selected.toSet()..remove(hit.id))
            : {..._selected, hit.id};
      });
      if (_editable && !additive) {
        _drag = _CardDrag(
          pointer: event.pointer,
          press: event.localPosition,
          hit: hit.id,
          origins: {
            for (final card in _view.cards)
              if (_selected.contains(card.id)) card.id: card.position,
          },
          collapse: keep,
        );
      }
      return;
    }
    _mutate(() {
      _marqueePointer = event.pointer;
      _marqueeStart = event.localPosition;
      _marqueeEnd = event.localPosition;
      _marqueeBase = additive ? _selected : {};
      _selected = _marqueeBase;
    });
  }

  void _move(PointerMoveEvent event) {
    final camera = _camera;
    if (camera == null) return;
    _pointer = event.localPosition;
    if (event.pointer == _panPointer) {
      final press = _rightPress;
      if (press != null &&
          (event.localPosition - press.origin).distance >
              SceneGraphCanvasState._dragSlop) {
        _rightPress = (
          pointer: press.pointer,
          origin: press.origin,
          moved: true,
        );
      }
      camera.value = camera.value.panBy(event.localDelta);
      return;
    }
    final wire = _wire;
    if (wire != null && wire.pointer == event.pointer) {
      _mutate(
        () => _wire = (
          pointer: wire.pointer,
          from: wire.from,
          end: event.localPosition,
        ),
      );
      return;
    }
    final drag = _drag;
    if (drag != null && drag.pointer == event.pointer) {
      if (!drag.moved &&
          (event.localPosition - drag.press).distance <=
              SceneGraphCanvasState._dragSlop) {
        return;
      }
      drag.moved = true;
      final delta = (event.localPosition - drag.press) / camera.value.scale;
      _mutate(() {
        _moved = {
          for (final MapEntry(:key, :value) in drag.origins.entries)
            key: _snapped(Offset(value.x, value.y) + delta),
        };
      });
      return;
    }
    final start = _marqueeStart;
    if (event.pointer != _marqueePointer || start == null) return;
    final rect = Rect.fromPoints(
      camera.value.toWorld(start),
      camera.value.toWorld(event.localPosition),
    );
    _mutate(() {
      _marqueeEnd = event.localPosition;
      _selected = {..._marqueeBase, ...sceneGraphCardsIn(_view, rect)};
    });
  }

  void _up(PointerEvent event) {
    final camera = _camera;
    if (event.pointer == _panPointer) {
      _panPointer = null;
      final press = _rightPress;
      _rightPress = null;
      if (press != null &&
          !press.moved &&
          event is PointerUpEvent &&
          _editable &&
          camera != null) {
        _openContextMenu(event.localPosition, camera.value);
      }
    }
    final wire = _wire;
    if (wire != null && wire.pointer == event.pointer) {
      _mutate(() => _wire = null);
      if (event is PointerUpEvent && camera != null) {
        _dropWire(wire.from, event.localPosition);
      }
      return;
    }
    final drag = _drag;
    if (drag != null && drag.pointer == event.pointer) {
      _drag = null;
      if (drag.moved && event is PointerUpEvent) {
        _commitMove();
      } else {
        _mutate(() {
          _moved = const {};
          if (drag.collapse) _selected = {drag.hit};
        });
      }
      return;
    }
    if (event.pointer != _marqueePointer) return;
    _mutate(() {
      _marqueePointer = null;
      _marqueeStart = null;
      _marqueeEnd = null;
    });
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape && _menu != null) {
      _closeMenu();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && (_wire != null || _drag != null)) {
      _mutate(() {
        _wire = null;
        _drag = null;
        _moved = const {};
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      showAll();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f7) {
      _mutate(() => _selected = const {});
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.delete ||
            key == LogicalKeyboardKey.backspace) &&
        _editable &&
        _selected.isNotEmpty) {
      _removeSelection();
      return KeyEventResult.handled;
    }
    final command =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    if (!command || HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.keyA) {
      _mutate(() => _selected = _view.cards.map((card) => card.id).toSet());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyC && _selected.isNotEmpty) {
      _copy();
      return KeyEventResult.handled;
    }
    if (!_editable) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.keyX && _selected.isNotEmpty) {
      _cut();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyV &&
        SceneGraphCanvasState._clipboard != null) {
      _paste();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyD && _selected.isNotEmpty) {
      _duplicate();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _signal(PointerSignalEvent event) {
    final camera = _camera;
    if (event is! PointerScrollEvent || camera == null) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      camera.value = event.kind == PointerDeviceKind.trackpad
          ? camera.value.panBy(-event.scrollDelta)
          : camera.value.zoomAt(
              event.localPosition,
              math.exp(
                -event.scrollDelta.dy * SceneGraphCanvasState._wheelZoomRate,
              ),
              minimum: _minimumZoom,
            );
    });
  }

  void _pinch(PointerPanZoomUpdateEvent event) {
    final camera = _camera;
    if (camera == null) return;
    final factor = event.scale / _pinchScale;
    _pinchScale = event.scale;
    camera.value = camera.value
        .panBy(event.localPanDelta)
        .zoomAt(event.localPosition, factor, minimum: _minimumZoom);
  }

  SceneGraphPoint _snapped(Offset world) {
    const step = SceneGraphCanvasState._snap;
    return SceneGraphPoint(
      (world.dx / step).roundToDouble() * step,
      (world.dy / step).roundToDouble() * step,
    );
  }
}
