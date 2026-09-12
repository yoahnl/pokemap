import 'dart:ui' as ui show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_overworld_components.dart';
import '../theme/pokemap_player_overworld_theme.dart';

import 'player_control_profile.dart';

const double kRuntimePlayerTouchDeadZone = 0.35;

RuntimeInputControl? runtimeInputControlFromTouchVector(
  Offset vector, {
  double deadZone = kRuntimePlayerTouchDeadZone,
}) {
  if (vector.distance <= deadZone) return null;
  if (vector.dx.abs() >= vector.dy.abs()) {
    return vector.dx >= 0
        ? RuntimeInputControl.right
        : RuntimeInputControl.left;
  }
  return vector.dy <= 0 ? RuntimeInputControl.up : RuntimeInputControl.down;
}

/// Converts one continuous pointer/controller vector into digital transitions.
///
/// The runtime stays unaware of the physical input source and receives the
/// same canonical press/release events as it does for the keyboard.
final class RuntimePlayerTouchInputDriver {
  RuntimePlayerTouchInputDriver({
    this.deadZone = kRuntimePlayerTouchDeadZone,
  });

  final double deadZone;
  RuntimeInputControl? _activeControl;

  List<RuntimeInputEvent> updateVector(Offset vector) {
    final next = runtimeInputControlFromTouchVector(vector, deadZone: deadZone);
    if (next == _activeControl) return const <RuntimeInputEvent>[];
    final events = <RuntimeInputEvent>[];
    if (_activeControl case final previous?) {
      events.add(RuntimeInputEvent.release(previous));
    }
    if (next != null) events.add(RuntimeInputEvent.press(next));
    _activeControl = next;
    return events;
  }

  List<RuntimeInputEvent> release() => updateVector(Offset.zero);
}

typedef RuntimePlayerTouchTapCandidate = ({Offset position, int pointer});

final class RuntimePlayerFloatingTouchDriver {
  RuntimePlayerFloatingTouchDriver(
      {this.dragThreshold = 12,
      this.deadZone = 8,
      this.directionHysteresis = 1.2,
      this.runMode = RuntimePlayerTouchRunMode.gesture,
      bool sprintAllowed = false})
      : _sprintAllowed = sprintAllowed;

  final RuntimePlayerTouchRunMode runMode;
  static const usefulRadius = 56.0;
  static const sprintEntry = .75;
  static const sprintExit = .55;
  bool _sprintAllowed;
  bool _sprintPressed = false;
  bool _sprintArmed = true;
  double get amplitude => (displacement.distance / usefulRadius).clamp(0, 1);

  List<RuntimeInputEvent> setSprintAllowed(bool allowed) {
    if (_sprintAllowed == allowed) return const [];
    _sprintAllowed = allowed;
    if (!allowed) {
      _sprintArmed = false;
      return _sprintTransition(false);
    }
    return const [];
  }

  List<RuntimeInputEvent> _sprintTransition(bool pressed) {
    if (_sprintPressed == pressed) return const [];
    _sprintPressed = pressed;
    return [
      pressed
          ? const RuntimeInputEvent.press(RuntimeInputControl.sprint)
          : const RuntimeInputEvent.release(RuntimeInputControl.sprint)
    ];
  }

  final double dragThreshold;
  final double deadZone;
  final double directionHysteresis;
  int? pointer;
  Offset? origin;
  Offset displacement = Offset.zero;
  bool dragging = false;
  RuntimeInputControl? _activeControl;
  RuntimePlayerTouchTapCandidate? _tapCandidate;

  bool begin(int pointer, Offset position) {
    if (this.pointer != null) return false;
    this.pointer = pointer;
    _sprintArmed = _sprintAllowed;
    origin = position;
    displacement = Offset.zero;
    dragging = false;
    _tapCandidate = null;
    return true;
  }

  List<RuntimeInputEvent> update(int pointer, Offset position) {
    if (this.pointer != pointer) return const [];
    displacement = position - origin!;
    if (!dragging && displacement.distance < dragThreshold) return const [];
    dragging = true;
    RuntimeInputControl? next;
    if (displacement.distance > deadZone) {
      final x = displacement.dx;
      final y = displacement.dy;
      final horizontal = _activeControl == RuntimeInputControl.left ||
          _activeControl == RuntimeInputControl.right;
      final vertical = _activeControl == RuntimeInputControl.up ||
          _activeControl == RuntimeInputControl.down;
      final keepHorizontal =
          horizontal && y.abs() <= x.abs() * directionHysteresis;
      final keepVertical = vertical && x.abs() <= y.abs() * directionHysteresis;
      if (keepHorizontal || (!keepVertical && x.abs() >= y.abs())) {
        next = x >= 0 ? RuntimeInputControl.right : RuntimeInputControl.left;
      } else {
        next = y >= 0 ? RuntimeInputControl.down : RuntimeInputControl.up;
      }
    }
    if (_sprintAllowed && amplitude <= sprintExit) _sprintArmed = true;
    final wantsSprint = _sprintAllowed &&
        _sprintArmed &&
        next != null &&
        switch (runMode) {
          RuntimePlayerTouchRunMode.walkOnly => false,
          RuntimePlayerTouchRunMode.automatic => true,
          RuntimePlayerTouchRunMode.gesture =>
            _sprintPressed ? amplitude > sprintExit : amplitude >= sprintEntry,
        };
    return [..._sprintTransition(wantsSprint), ..._transition(next)];
  }

  List<RuntimeInputEvent> end(int pointer) {
    if (this.pointer != pointer) return const [];
    final candidate =
        !dragging ? (position: origin! + displacement, pointer: pointer) : null;
    final events = cancel();
    _tapCandidate = candidate;
    return events;
  }

  RuntimePlayerTouchTapCandidate? takeTapCandidate() {
    final candidate = _tapCandidate;
    _tapCandidate = null;
    return candidate;
  }

  List<RuntimeInputEvent> cancel() {
    pointer = null;
    origin = null;
    displacement = Offset.zero;
    dragging = false;
    _tapCandidate = null;
    return [..._sprintTransition(false), ..._transition(null)];
  }

  List<RuntimeInputEvent> _transition(RuntimeInputControl? next) {
    if (_activeControl == next) return const [];
    final events = <RuntimeInputEvent>[
      if (_activeControl case final previous?)
        RuntimeInputEvent.release(previous),
      if (next != null) RuntimeInputEvent.press(next),
    ];
    _activeControl = next;
    return events;
  }
}

class RuntimePlayerTouchControls extends StatefulWidget {
  const RuntimePlayerTouchControls({
    super.key,
    required this.dispatch,
    this.opacity = 0.82,
    this.controlProfile,
    this.showControls = true,
    this.onMovementGesture,
    this.readGameplayViewport,
    this.readExcludedRects,
    this.leftHanded = false,
    this.resolveTapTarget,
    this.onTap,
    this.interactionChanges,
    this.cancellationSignal,
    this.sprintAllowed = false,
    this.sprintAccepted = false,
    this.runMode = RuntimePlayerTouchRunMode.gesture,
    this.onSprintAccepted,
  }) : assert(opacity >= 0.3 && opacity <= 1);

  final ValueChanged<RuntimeInputEvent> dispatch;
  final double opacity;
  final PlayerControlProfile? controlProfile;
  final bool showControls;
  final VoidCallback? onMovementGesture;
  final Rect? Function()? readGameplayViewport;
  final Iterable<Rect> Function()? readExcludedRects;
  final bool leftHanded;
  final RuntimeOverworldInteractionRequest? Function(Offset)? resolveTapTarget;
  final ValueChanged<RuntimeOverworldInteractionRequest>? onTap;
  final ValueListenable<RuntimeOverworldInteractionSnapshot>?
      interactionChanges;
  final Listenable? cancellationSignal;
  final bool sprintAllowed;
  final bool sprintAccepted;
  final RuntimePlayerTouchRunMode runMode;
  final VoidCallback? onSprintAccepted;

  @override
  State<RuntimePlayerTouchControls> createState() =>
      _RuntimePlayerTouchControlsState();
}

class _RuntimePlayerTouchControlsState extends State<RuntimePlayerTouchControls>
    with WidgetsBindingObserver {
  late RuntimePlayerFloatingTouchDriver _driver;
  final _tapCandidates = <int,
      ({
    Offset origin,
    RuntimeOverworldInteractionRequest request,
    int generation
  })>{};
  RuntimeOverworldInteractionSnapshot? _interactionSnapshot;
  int _tapGeneration = 0;
  Rect? _gestureViewport;
  Offset? _anchor;
  EdgeInsets _safePadding = EdgeInsets.zero;
  Size _size = Size.zero;
  bool _geometryCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _driver = RuntimePlayerFloatingTouchDriver(
        sprintAllowed: widget.sprintAllowed, runMode: widget.runMode);
    WidgetsBinding.instance.addObserver(this);
    widget.cancellationSignal?.addListener(_cancel);
    _interactionSnapshot = widget.interactionChanges?.value;
    widget.interactionChanges?.addListener(_handleInteractionChanged);
  }

  @override
  void didChangeMetrics() => _cancel();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _cancel();
  }

  @override
  void didUpdateWidget(covariant RuntimePlayerTouchControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interactionChanges != widget.interactionChanges) {
      oldWidget.interactionChanges?.removeListener(_handleInteractionChanged);
      _interactionSnapshot = widget.interactionChanges?.value;
      widget.interactionChanges?.addListener(_handleInteractionChanged);
      _cancel(rebuild: false);
    }
    if (oldWidget.runMode != widget.runMode) {
      _cancel(rebuild: false);
      _driver = RuntimePlayerFloatingTouchDriver(
          sprintAllowed: widget.sprintAllowed, runMode: widget.runMode);
    }
    _dispatchAll(_driver.setSprintAllowed(widget.sprintAllowed));
    if (!oldWidget.sprintAccepted &&
        widget.sprintAccepted &&
        _driver.dragging) {
      widget.onSprintAccepted?.call();
    }
    if (oldWidget.cancellationSignal != widget.cancellationSignal) {
      oldWidget.cancellationSignal?.removeListener(_cancel);
      widget.cancellationSignal?.addListener(_cancel);
      _cancel(rebuild: false);
    }
    if ((oldWidget.showControls && !widget.showControls) ||
        oldWidget.leftHanded != widget.leftHanded ||
        oldWidget.controlProfile != widget.controlProfile) {
      _cancel(rebuild: false);
    }
    _scheduleGeometryCheck();
  }

  Rect? _viewport() {
    final game = widget.readGameplayViewport?.call();
    if (game == null || _size.isEmpty) return null;
    final safe = Rect.fromLTRB(_safePadding.left, _safePadding.top,
        _size.width - _safePadding.right, _size.height - _safePadding.bottom);
    final viewport = game.intersect(safe);
    return viewport.isEmpty ? null : viewport;
  }

  bool _accepts(Offset position) {
    final viewport = _viewport();
    return viewport != null &&
        viewport.contains(position) &&
        !(widget.readExcludedRects?.call() ?? const <Rect>[])
            .any((rect) => rect.contains(position));
  }

  bool _acceptsMovement(Offset position) {
    final viewport = _viewport();
    if (viewport == null) return false;
    return Rect.fromLTRB(
      widget.leftHanded ? viewport.left + viewport.width * .4 : viewport.left,
      viewport.top + viewport.height * .4,
      widget.leftHanded ? viewport.right : viewport.left + viewport.width * .6,
      viewport.bottom,
    ).contains(position);
  }

  void _invalidateTaps() {
    _tapGeneration++;
    _tapCandidates.clear();
  }

  void _handleInteractionChanged() {
    final previous = _interactionSnapshot;
    final next = widget.interactionChanges?.value;
    if (previous == next) return;
    _interactionSnapshot = next;
    if (previous?.sessionId != next?.sessionId ||
        previous?.mapActivationId != next?.mapActivationId ||
        previous?.mapId != next?.mapId) {
      _cancel();
    } else {
      _invalidateTaps();
    }
  }

  bool get _hasActivePointers =>
      _driver.pointer != null || _tapCandidates.isNotEmpty;

  void _scheduleGeometryCheck() {
    if (_geometryCheckScheduled) return;
    _geometryCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geometryCheckScheduled = false;
      if (mounted && _hasActivePointers && _viewport() != _gestureViewport) {
        _cancel();
      }
      if (mounted && _hasActivePointers) _scheduleGeometryCheck();
    });
  }

  bool _checkGeometry() {
    if (_hasActivePointers && _viewport() != _gestureViewport) {
      _cancel();
      return false;
    }
    return true;
  }

  void _down(PointerDownEvent event) {
    if (event.kind != ui.PointerDeviceKind.touch ||
        !_accepts(event.localPosition)) {
      return;
    }
    if (!_checkGeometry()) return;
    if (!_hasActivePointers) _gestureViewport = _viewport();
    final request = widget.resolveTapTarget?.call(event.localPosition);
    if (request != null) {
      _tapCandidates[event.pointer] = (
        origin: event.localPosition,
        request: request,
        generation: _tapGeneration
      );
    }
    _scheduleGeometryCheck();
    if (!_acceptsMovement(event.localPosition) ||
        !_driver.begin(event.pointer, event.localPosition)) {
      return;
    }
    final viewport = _gestureViewport!;
    const radius = PokeMapPlayerOverworldTheme.joystickSize / 2;
    double clampAnchor(double value, double min, double max) =>
        max - min < radius * 2
            ? (min + max) / 2
            : value.clamp(min + radius, max - radius);
    setState(() => _anchor = Offset(
          clampAnchor(event.localPosition.dx, viewport.left, viewport.right),
          clampAnchor(event.localPosition.dy, viewport.top, viewport.bottom),
        ));
  }

  void _move(PointerMoveEvent event) {
    if (!_checkGeometry()) return;
    final tap = _tapCandidates[event.pointer];
    if (tap != null &&
        (event.localPosition - tap.origin).distance >= _driver.dragThreshold) {
      _tapCandidates.remove(event.pointer);
    }
    if (_driver.pointer != event.pointer) return;
    final wasDragging = _driver.dragging;
    final events = _driver.update(event.pointer, event.localPosition);
    if (!wasDragging && _driver.dragging) widget.onMovementGesture?.call();
    _dispatchAll(events);
    setState(() {});
  }

  void _up(PointerUpEvent event) {
    if (!_checkGeometry()) return;
    final tap = _tapCandidates.remove(event.pointer);
    if (_driver.pointer == event.pointer) {
      _dispatchAll(_driver.end(event.pointer));
      setState(() => _anchor = null);
    }
    if (tap != null &&
        tap.generation == _tapGeneration &&
        (event.localPosition - tap.origin).distance < _driver.dragThreshold &&
        _accepts(event.localPosition) &&
        widget.resolveTapTarget?.call(event.localPosition) == tap.request) {
      widget.onTap?.call(tap.request);
    }
  }

  void _cancel({bool rebuild = true}) {
    _invalidateTaps();
    _dispatchAll(_driver.cancel());
    _gestureViewport = null;
    _anchor = null;
    if (rebuild && mounted) setState(() {});
  }

  void _dispatchAll(Iterable<RuntimeInputEvent> events) {
    for (final event in events) {
      widget.dispatch(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = constraints.biggest;
      _safePadding = MediaQuery.paddingOf(context);
      _scheduleGeometryCheck();
      return Stack(fit: StackFit.expand, children: [
        Positioned.fill(
            child: _RuntimePlayerTouchHitRegion(
          accepts: _accepts,
          onLayout: _scheduleGeometryCheck,
          child: Listener(
            key: const ValueKey('runtime-player-touch-movement-zone'),
            behavior: HitTestBehavior.opaque,
            onPointerDown: _down,
            onPointerMove: _move,
            onPointerUp: _up,
            onPointerCancel: (event) {
              _tapCandidates.remove(event.pointer);
              if (event.pointer == _driver.pointer) _cancel();
            },
            child: Opacity(
              key: const ValueKey('runtime-player-touch-controls-opacity'),
              opacity: widget.showControls
                  ? (context.playerOverworldTheme.opaque ? 1 : widget.opacity)
                  : 0,
              child: ClipRect(
                key: const ValueKey('runtime-player-touch-viewport-clip'),
                clipper: _RuntimePlayerViewportClipper(
                    _gestureViewport ?? _viewport() ?? Rect.zero),
                child: Stack(children: [
                  if (_anchor case final anchor?)
                    PlayerOverworldJoystickVisual(
                      key: const ValueKey('runtime-player-touch-joystick'),
                      anchor: anchor,
                      running: widget.sprintAccepted,
                      displacement: _driver.displacement /
                          PokeMapPlayerOverworldTheme.joystickTravel,
                    ),
                ]),
              ),
            ),
          ),
        )),
      ]);
    });
  }

  @override
  void dispose() {
    widget.cancellationSignal?.removeListener(_cancel);
    widget.interactionChanges?.removeListener(_handleInteractionChanged);
    _invalidateTaps();
    WidgetsBinding.instance.removeObserver(this);
    _dispatchAll(_driver.cancel());
    super.dispose();
  }
}

class _RuntimePlayerViewportClipper extends CustomClipper<Rect> {
  const _RuntimePlayerViewportClipper(this.viewport);
  final Rect viewport;

  @override
  Rect getClip(Size size) => viewport;

  @override
  bool shouldReclip(_RuntimePlayerViewportClipper oldClipper) =>
      oldClipper.viewport != viewport;
}

class _RuntimePlayerTouchHitRegion extends SingleChildRenderObjectWidget {
  const _RuntimePlayerTouchHitRegion(
      {required this.accepts, required this.onLayout, required super.child});
  final bool Function(Offset) accepts;
  final VoidCallback onLayout;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RuntimePlayerTouchHitBox(accepts, onLayout);

  @override
  void updateRenderObject(
      BuildContext context, covariant _RuntimePlayerTouchHitBox renderObject) {
    renderObject.accepts = accepts;
    renderObject.onLayout = onLayout;
  }
}

class _RuntimePlayerTouchHitBox extends RenderProxyBox {
  _RuntimePlayerTouchHitBox(this.accepts, this.onLayout);
  bool Function(Offset) accepts;
  VoidCallback onLayout;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      accepts(position) && super.hitTest(result, position: position);

  @override
  void performLayout() {
    super.performLayout();
    onLayout();
  }
}
