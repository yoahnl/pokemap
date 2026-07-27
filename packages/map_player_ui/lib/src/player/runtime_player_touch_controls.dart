import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:map_runtime/map_runtime.dart';

import '../theme/pokemap_player_theme.dart';

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

/// Runtime-owned mobile controls shared by Hub and future standalone players.
class RuntimePlayerTouchControls extends StatefulWidget {
  const RuntimePlayerTouchControls({
    super.key,
    required this.dispatch,
    this.opacity = 0.82,
  }) : assert(opacity >= 0.3 && opacity <= 1);

  final ValueChanged<RuntimeInputEvent> dispatch;
  final double opacity;

  @override
  State<RuntimePlayerTouchControls> createState() =>
      _RuntimePlayerTouchControlsState();
}

class _RuntimePlayerTouchControlsState
    extends State<RuntimePlayerTouchControls> {
  final RuntimePlayerTouchInputDriver _driver = RuntimePlayerTouchInputDriver();

  void _dispatchAll(Iterable<RuntimeInputEvent> events) {
    for (final event in events) {
      widget.dispatch(event);
    }
  }

  void _dispatchButton(RuntimeInputControl control, bool pressed) {
    widget.dispatch(
      pressed
          ? RuntimeInputEvent.press(control)
          : RuntimeInputEvent.release(control),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final portrait = size.height >= size.width;
        final joystickSize = (portrait
                ? size.width.clamp(0, 520) * .28
                : size.height.clamp(0, 720) * .32)
            .clamp(108.0, 152.0);
        final actionSize = (portrait
                ? size.width.clamp(0, 520) * .17
                : size.height.clamp(0, 720) * .19)
            .clamp(62.0, 88.0);
        final safePadding = MediaQuery.paddingOf(context);
        final portraitLift = (size.height * 0.075).clamp(54.0, 84.0);
        final bottom = (portrait ? portraitLift : 12.0) + safePadding.bottom;
        final horizontal = portrait ? 18.0 : 22.0;

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              left: horizontal + safePadding.left,
              bottom: bottom,
              child: Opacity(
                key: const ValueKey<String>(
                  'runtime-player-touch-controls-opacity',
                ),
                opacity: widget.opacity,
                child: SizedBox.square(
                  key: const ValueKey<String>(
                    'runtime-player-touch-joystick',
                  ),
                  dimension: joystickSize,
                  child: _joystick(context, joystickSize),
                ),
              ),
            ),
            Positioned(
              right: horizontal + safePadding.right,
              bottom: bottom,
              child: Opacity(
                key: const ValueKey<String>(
                  'runtime-player-touch-actions-opacity',
                ),
                opacity: widget.opacity,
                child: _RuntimePlayerTouchActionCluster(
                  portrait: portrait,
                  buttonSize: actionSize,
                  onPrimaryChanged: (pressed) => _dispatchButton(
                    RuntimeInputControl.primary,
                    pressed,
                  ),
                  onSecondaryChanged: (pressed) => _dispatchButton(
                    RuntimeInputControl.secondary,
                    pressed,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _joystick(BuildContext context, double size) {
    final colors = context.playerColors;
    final semantic = context.playerSemanticTheme;
    return Semantics(
      label: 'Joystick',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.scrim.withValues(alpha: .28),
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.outline.withValues(alpha: .72),
            width: 1.5,
          ),
        ),
        child: Joystick(
          includeInitialAnimation: false,
          mode: JoystickMode.horizontalAndVertical,
          period: const Duration(milliseconds: 60),
          base: JoystickBase(
            size: size,
            decoration: JoystickBaseDecoration(
              drawArrows: false,
              outerCircleColor:
                  semantic.overworldHudSurface.withValues(alpha: .34),
              middleCircleColor: colors.surfaceElevated.withValues(alpha: .42),
              innerCircleColor: colors.outline.withValues(alpha: .30),
            ),
          ),
          stick: const _RuntimePlayerJoystickStick(),
          listener: (details) => _dispatchAll(
            _driver.updateVector(Offset(details.x, details.y)),
          ),
          onStickDragEnd: () => _dispatchAll(_driver.release()),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispatchAll(_driver.release());
    super.dispose();
  }
}

class _RuntimePlayerTouchActionCluster extends StatelessWidget {
  const _RuntimePlayerTouchActionCluster({
    required this.portrait,
    required this.buttonSize,
    required this.onPrimaryChanged,
    required this.onSecondaryChanged,
  });

  final bool portrait;
  final double buttonSize;
  final ValueChanged<bool> onPrimaryChanged;
  final ValueChanged<bool> onSecondaryChanged;

  @override
  Widget build(BuildContext context) {
    final secondary = _RuntimePlayerTouchButton(
      key: const ValueKey<String>(
        'runtime-player-touch-secondary-button',
      ),
      label: 'B',
      semanticLabel: 'Action secondaire',
      size: buttonSize,
      primary: false,
      onChanged: onSecondaryChanged,
    );
    final primary = _RuntimePlayerTouchButton(
      key: const ValueKey<String>(
        'runtime-player-touch-primary-button',
      ),
      label: 'A',
      semanticLabel: 'Action principale',
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
}

class _RuntimePlayerTouchButton extends StatefulWidget {
  const _RuntimePlayerTouchButton({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.size,
    required this.primary,
    required this.onChanged,
  });

  final String label;
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
          child: Text(
            widget.label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontSize: math.max(22, widget.size * .34),
            ),
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

class _RuntimePlayerJoystickStick extends StatelessWidget {
  const _RuntimePlayerJoystickStick();

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.textPrimary.withValues(alpha: .92),
        border: Border.all(
          color: colors.outline.withValues(alpha: .72),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.scrim.withValues(alpha: .22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}
