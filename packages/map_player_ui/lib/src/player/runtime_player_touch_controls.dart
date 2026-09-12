import 'dart:math' as math;
import 'dart:ui' as ui show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_overworld_components.dart';
import '../theme/pokemap_player_overworld_theme.dart';

import '../theme/pokemap_player_theme.dart';
import '../localization/player_localizations.dart';
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
    this.onTapCandidate,
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
  final ValueChanged<RuntimePlayerTouchTapCandidate>? onTapCandidate;
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
  final _surfaceKey = GlobalKey();
  final _actionsKey = GlobalKey();
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
    if (viewport == null) return false;
    final zone = Rect.fromLTRB(
      widget.leftHanded ? viewport.left + viewport.width * .4 : viewport.left,
      viewport.top + viewport.height * .4,
      widget.leftHanded ? viewport.right : viewport.left + viewport.width * .6,
      viewport.bottom,
    );
    if (!zone.contains(position)) return false;
    final actions = _actionsKey.currentContext?.findRenderObject();
    final surface = _surfaceKey.currentContext?.findRenderObject();
    if (actions is RenderBox &&
        actions.hasSize &&
        surface is RenderBox &&
        surface.hasSize) {
      final rect = MatrixUtils.transformRect(
          actions.getTransformTo(surface), Offset.zero & actions.size);
      if (rect.contains(position)) return false;
    }
    return !(widget.readExcludedRects?.call() ?? const <Rect>[])
        .any((rect) => rect.contains(position));
  }

  void _scheduleGeometryCheck() {
    if (_geometryCheckScheduled) return;
    _geometryCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geometryCheckScheduled = false;
      if (mounted &&
          _driver.pointer != null &&
          _viewport() != _gestureViewport) {
        _cancel();
      }
      if (mounted && _driver.pointer != null) _scheduleGeometryCheck();
    });
  }

  bool _checkGeometry() {
    if (_driver.pointer != null && _viewport() != _gestureViewport) {
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
    if (!_driver.begin(event.pointer, event.localPosition)) return;
    _gestureViewport = _viewport();
    _scheduleGeometryCheck();
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
    if (!_checkGeometry() || _driver.pointer != event.pointer) return;
    final wasDragging = _driver.dragging;
    final events = _driver.update(event.pointer, event.localPosition);
    if (!wasDragging && _driver.dragging) widget.onMovementGesture?.call();
    _dispatchAll(events);
    setState(() {});
  }

  void _up(PointerUpEvent event) {
    if (!_checkGeometry() || _driver.pointer != event.pointer) return;
    _dispatchAll(_driver.end(event.pointer));
    final candidate = _driver.takeTapCandidate();
    setState(() => _anchor = null);
    if (candidate != null) widget.onTapCandidate?.call(candidate);
  }

  void _cancel({bool rebuild = true}) {
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

  void _dispatchButton(String inputId, bool pressed) {
    final control = (widget.controlProfile ?? PlayerControlProfile.standard)
        .controlForTouchInput(inputId);
    if (control == null) return;
    widget.dispatch(pressed
        ? RuntimeInputEvent.press(control)
        : RuntimeInputEvent.release(control));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = constraints.biggest;
      _safePadding = MediaQuery.paddingOf(context);
      _scheduleGeometryCheck();
      final portrait = _size.height >= _size.width;
      final actionSize = (portrait
              ? _size.width.clamp(0, 520) * .17
              : _size.height.clamp(0, 720) * .19)
          .clamp(62.0, 88.0);
      final bottom =
          (portrait ? (_size.height * .075).clamp(54.0, 84.0) : 12.0) +
              _safePadding.bottom;
      final horizontal = portrait ? 18.0 : 22.0;
      return Stack(key: _surfaceKey, fit: StackFit.expand, children: [
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
        if (widget.showControls)
          Positioned(
            left: widget.leftHanded ? horizontal + _safePadding.left : null,
            right: widget.leftHanded ? null : horizontal + _safePadding.right,
            bottom: bottom,
            child: SizedBox(
                key: _actionsKey,
                child: Opacity(
                  key: const ValueKey('runtime-player-touch-actions-opacity'),
                  opacity: widget.opacity,
                  child: _RuntimePlayerTouchActionCluster(
                    profile:
                        widget.controlProfile ?? PlayerControlProfile.standard,
                    portrait: portrait,
                    buttonSize: actionSize,
                    onPrimaryChanged: (pressed) =>
                        _dispatchButton('primaryButton', pressed),
                    onSecondaryChanged: (pressed) =>
                        _dispatchButton('secondaryButton', pressed),
                  ),
                )),
          ),
      ]);
    });
  }

  @override
  void dispose() {
    widget.cancellationSignal?.removeListener(_cancel);
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

class _RuntimePlayerTouchActionCluster extends StatelessWidget {
  const _RuntimePlayerTouchActionCluster({
    required this.portrait,
    required this.buttonSize,
    required this.onPrimaryChanged,
    required this.onSecondaryChanged,
    required this.profile,
  });

  final bool portrait;
  final double buttonSize;
  final ValueChanged<bool> onPrimaryChanged;
  final ValueChanged<bool> onSecondaryChanged;
  final PlayerControlProfile profile;

  @override
  Widget build(BuildContext context) {
    final secondary = _RuntimePlayerTouchButton(
      key: const ValueKey<String>(
        'runtime-player-touch-secondary-button',
      ),
      label: _label(context, 'secondaryButton'),
      icon: _icon('secondaryButton'),
      semanticLabel: _label(context, 'secondaryButton'),
      size: buttonSize,
      primary: false,
      onChanged: onSecondaryChanged,
    );
    final primary = _RuntimePlayerTouchButton(
      key: const ValueKey<String>(
        'runtime-player-touch-primary-button',
      ),
      label: _label(context, 'primaryButton'),
      icon: _icon('primaryButton'),
      semanticLabel: _label(context, 'primaryButton'),
      size: buttonSize,
      primary: true,
      onChanged: onPrimaryChanged,
    );
    const gap = SizedBox.square(dimension: PlayerSpacing.sm);
    return portrait
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[secondary, gap, primary],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[secondary, gap, primary],
          );
  }

  String _label(BuildContext context, String inputId) =>
      switch (profile.controlForTouchInput(inputId)) {
        RuntimeInputControl.primary => context.playerL10n.interact,
        RuntimeInputControl.secondary => context.playerL10n.back,
        RuntimeInputControl.sprint => context.playerL10n.run,
        RuntimeInputControl.menu => context.playerL10n.pause,
        _ => profile.controlForTouchInput(inputId)?.name ?? '',
      };

  IconData _icon(String inputId) =>
      switch (profile.controlForTouchInput(inputId)) {
        RuntimeInputControl.primary => Icons.touch_app_rounded,
        RuntimeInputControl.secondary => Icons.arrow_back_rounded,
        RuntimeInputControl.sprint => Icons.directions_run_rounded,
        RuntimeInputControl.menu => Icons.menu_rounded,
        _ => Icons.navigation_rounded,
      };
}

class _RuntimePlayerTouchButton extends StatefulWidget {
  const _RuntimePlayerTouchButton({
    super.key,
    required this.label,
    required this.icon,
    required this.semanticLabel,
    required this.size,
    required this.primary,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String semanticLabel;
  final double size;
  final bool primary;
  final ValueChanged<bool> onChanged;

  @override
  State<_RuntimePlayerTouchButton> createState() =>
      _RuntimePlayerTouchButtonState();
}

class _RuntimePlayerTouchButtonState extends State<_RuntimePlayerTouchButton> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
    widget.onChanged(pressed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final semantic = context.playerSemanticTheme;
    final fill = widget.primary ? colors.primary : semantic.overworldHudSurface;
    final foreground = widget.primary ? colors.onPrimary : colors.textPrimary;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedContainer(
          duration: context.playerMotion.fast,
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill.withValues(alpha: _pressed ? .98 : .86),
            border: Border.all(
              color: colors.focus.withValues(alpha: _pressed ? 1 : .74),
              width: 2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.scrim.withValues(alpha: _pressed ? .22 : .16),
                blurRadius: _pressed ? 6 : 10,
                offset: Offset(0, _pressed ? 2 : 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  color: foreground, size: math.max(18, widget.size * .3)),
              Text(widget.label,
                  style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_pressed) widget.onChanged(false);
    super.dispose();
  }
}
