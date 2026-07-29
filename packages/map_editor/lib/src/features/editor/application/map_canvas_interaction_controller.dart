/// Device families understood by the map-canvas interaction contract.
///
/// This deliberately mirrors Flutter pointer kinds without coupling the pure
/// arbiter to the widget layer.
enum MapCanvasPointerKind {
  mouse,
  trackpad,
  touch,
  stylus,
  invertedStylus,
  unknown,
}

/// Keyboard modifiers captured once, when an interaction takes ownership.
class MapCanvasInteractionModifiers {
  const MapCanvasInteractionModifiers({
    this.shift = false,
    this.alt = false,
    this.control = false,
    this.meta = false,
    this.space = false,
  });

  final bool shift;
  final bool alt;
  final bool control;
  final bool meta;
  final bool space;

  @override
  bool operator ==(Object other) {
    return other is MapCanvasInteractionModifiers &&
        other.shift == shift &&
        other.alt == alt &&
        other.control == control &&
        other.meta == meta &&
        other.space == space;
  }

  @override
  int get hashCode => Object.hash(shift, alt, control, meta, space);
}

/// Stable editor target captured before an interaction can mutate the map.
class MapCanvasInteractionContext {
  const MapCanvasInteractionContext({
    required this.projectRootPath,
    required this.mapId,
    required this.activeMapPath,
    required this.layerId,
    required this.toolKey,
    required this.targetId,
    required this.guidedNavigation,
  });

  final String? projectRootPath;
  final String? mapId;
  final String? activeMapPath;
  final String? layerId;
  final String toolKey;
  final String? targetId;
  final bool guidedNavigation;

  @override
  bool operator ==(Object other) {
    return other is MapCanvasInteractionContext &&
        other.projectRootPath == projectRootPath &&
        other.mapId == mapId &&
        other.activeMapPath == activeMapPath &&
        other.layerId == layerId &&
        other.toolKey == toolKey &&
        other.targetId == targetId &&
        other.guidedNavigation == guidedNavigation;
  }

  @override
  int get hashCode => Object.hash(
        projectRootPath,
        mapId,
        activeMapPath,
        layerId,
        toolKey,
        targetId,
        guidedNavigation,
      );
}

class MapCanvasInteractionInput {
  const MapCanvasInteractionInput({
    required this.pointerId,
    required this.pointerKind,
    required this.buttons,
    required this.modifiers,
    required this.context,
  });

  final int pointerId;
  final MapCanvasPointerKind pointerKind;
  final int buttons;
  final MapCanvasInteractionModifiers modifiers;
  final MapCanvasInteractionContext context;
}

enum MapCanvasInteractionKind {
  pendingPrimary,
  panning,
  paintingStroke,
  drawingZone,
  borderGesture,
  trackpadPanZoom,
}

class MapCanvasInteractionSession {
  const MapCanvasInteractionSession({
    required this.interactionId,
    required this.pointerId,
    required this.kind,
    required this.pointerKind,
    required this.buttonsAtStart,
    required this.modifiersAtStart,
    required this.contextAtStart,
  });

  final int interactionId;
  final int pointerId;
  final MapCanvasInteractionKind kind;
  final MapCanvasPointerKind pointerKind;
  final int buttonsAtStart;
  final MapCanvasInteractionModifiers modifiersAtStart;
  final MapCanvasInteractionContext contextAtStart;

  MapCanvasInteractionSession withKind(MapCanvasInteractionKind nextKind) {
    return MapCanvasInteractionSession(
      interactionId: interactionId,
      pointerId: pointerId,
      kind: nextKind,
      pointerKind: pointerKind,
      buttonsAtStart: buttonsAtStart,
      modifiersAtStart: modifiersAtStart,
      contextAtStart: contextAtStart,
    );
  }
}

enum MapCanvasInteractionStartStatus {
  started,
  ignored,
  rejectedBusy,
  rejectedButtons,
  rejectedPointerKind,
}

class MapCanvasInteractionStartResult {
  const MapCanvasInteractionStartResult({
    required this.status,
    this.session,
  });

  final MapCanvasInteractionStartStatus status;
  final MapCanvasInteractionSession? session;
}

enum MapCanvasInteractionTerminal {
  commit,
  rollback,
}

class MapCanvasInteractionEndResult {
  const MapCanvasInteractionEndResult({
    required this.session,
    required this.terminal,
  });

  final MapCanvasInteractionSession session;
  final MapCanvasInteractionTerminal terminal;
}

/// Owns the one and only transient map-canvas interaction.
///
/// The widget adapter remains responsible for effects (paint, pan, commit,
/// rollback). This class only decides who owns the gesture and guarantees that
/// repeated/non-owner terminal events are harmless.
class MapCanvasInteractionController {
  static const int _primaryButton = 0x01;
  static const int _secondaryButton = 0x02;
  static const int _tertiaryButton = 0x04;

  int _nextInteractionId = 1;
  MapCanvasInteractionSession? _activeSession;

  MapCanvasInteractionSession? get activeSession => _activeSession;
  bool get isIdle => _activeSession == null;
  bool get acceptsScroll => isIdle;

  bool ownsPointer(int pointerId) {
    return _activeSession?.pointerId == pointerId;
  }

  MapCanvasInteractionStartResult beginPointer(
    MapCanvasInteractionInput input,
  ) {
    if (_activeSession != null) {
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.rejectedBusy,
      );
    }
    if (input.buttons == 0) {
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.ignored,
      );
    }

    final primaryOnly = input.buttons == _primaryButton;
    final secondaryOnly = input.buttons == _secondaryButton;
    final tertiaryOnly = input.buttons == _tertiaryButton;
    if (secondaryOnly) {
      // Reserved for a future context action. It must never pan or edit.
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.ignored,
      );
    }
    final navigationRequested =
        tertiaryOnly || (primaryOnly && input.modifiers.space);

    if (navigationRequested) {
      if (input.pointerKind != MapCanvasPointerKind.mouse) {
        return const MapCanvasInteractionStartResult(
          status: MapCanvasInteractionStartStatus.rejectedPointerKind,
        );
      }
      return _start(input, MapCanvasInteractionKind.panning);
    }
    if (!primaryOnly) {
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.rejectedButtons,
      );
    }
    if (!_supportsPrimaryEditing(input.pointerKind)) {
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.rejectedPointerKind,
      );
    }
    return _start(input, MapCanvasInteractionKind.pendingPrimary);
  }

  MapCanvasInteractionStartResult beginPanZoom(
    MapCanvasInteractionInput input,
  ) {
    if (_activeSession != null) {
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.rejectedBusy,
      );
    }
    if (input.pointerKind != MapCanvasPointerKind.trackpad) {
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.rejectedPointerKind,
      );
    }
    if (input.buttons != 0) {
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.rejectedButtons,
      );
    }
    return _start(input, MapCanvasInteractionKind.trackpadPanZoom);
  }

  MapCanvasInteractionSession? promotePending({
    required int pointerId,
    required MapCanvasInteractionKind kind,
  }) {
    final current = _activeSession;
    if (current == null ||
        current.pointerId != pointerId ||
        current.kind != MapCanvasInteractionKind.pendingPrimary ||
        !_isPrimaryPromotion(kind)) {
      return null;
    }
    final promoted = current.withKind(kind);
    _activeSession = promoted;
    return promoted;
  }

  MapCanvasInteractionEndResult? finishPointer(int pointerId) {
    return _end(pointerId, MapCanvasInteractionTerminal.commit);
  }

  MapCanvasInteractionEndResult? cancelPointer(int pointerId) {
    return _end(pointerId, MapCanvasInteractionTerminal.rollback);
  }

  MapCanvasInteractionEndResult? cancelActive() {
    final current = _activeSession;
    if (current == null) return null;
    _activeSession = null;
    return MapCanvasInteractionEndResult(
      session: current,
      terminal: MapCanvasInteractionTerminal.rollback,
    );
  }

  MapCanvasInteractionStartResult _start(
    MapCanvasInteractionInput input,
    MapCanvasInteractionKind kind,
  ) {
    final session = MapCanvasInteractionSession(
      interactionId: _nextInteractionId++,
      pointerId: input.pointerId,
      kind: kind,
      pointerKind: input.pointerKind,
      buttonsAtStart: input.buttons,
      modifiersAtStart: input.modifiers,
      contextAtStart: input.context,
    );
    _activeSession = session;
    return MapCanvasInteractionStartResult(
      status: MapCanvasInteractionStartStatus.started,
      session: session,
    );
  }

  MapCanvasInteractionEndResult? _end(
    int pointerId,
    MapCanvasInteractionTerminal terminal,
  ) {
    final current = _activeSession;
    if (current == null || current.pointerId != pointerId) return null;
    _activeSession = null;
    return MapCanvasInteractionEndResult(
      session: current,
      terminal: terminal,
    );
  }

  bool _supportsPrimaryEditing(MapCanvasPointerKind kind) {
    return kind == MapCanvasPointerKind.mouse ||
        kind == MapCanvasPointerKind.touch ||
        kind == MapCanvasPointerKind.stylus ||
        kind == MapCanvasPointerKind.invertedStylus;
  }

  bool _isPrimaryPromotion(MapCanvasInteractionKind kind) {
    return kind == MapCanvasInteractionKind.paintingStroke ||
        kind == MapCanvasInteractionKind.drawingZone ||
        kind == MapCanvasInteractionKind.borderGesture;
  }
}
