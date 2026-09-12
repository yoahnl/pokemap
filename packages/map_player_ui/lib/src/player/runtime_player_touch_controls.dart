import 'dart:math' as math;
import 'dart:ui' as ui show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:map_runtime/map_runtime.dart';

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

/// Runtime-owned mobile controls shared by Hub and future standalone players.
class RuntimePlayerTouchControls extends StatefulWidget {
  const RuntimePlayerTouchControls({
    super.key,
    required this.dispatch,
    this.opacity = 0.82,
    this.controlProfile,
    this.showControls = true,
    this.onMovementGesture,
  }) : assert(opacity >= 0.3 && opacity <= 1);

  final ValueChanged<RuntimeInputEvent> dispatch;
  final double opacity;
  final PlayerControlProfile? controlProfile;
  final bool showControls;
  final VoidCallback? onMovementGesture;

  @override
  State<RuntimePlayerTouchControls> createState() =>
      _RuntimePlayerTouchControlsState();
}

class _RuntimePlayerTouchControlsState
    extends State<RuntimePlayerTouchControls> {
  final RuntimePlayerTouchInputDriver _driver = RuntimePlayerTouchInputDriver();
  bool _movementInputAccepted = false;

  @override
  void initState() {
    super.initState();
    _movementInputAccepted = widget.showControls;
  }

  void _recognizeMovementPointer(ui.PointerDeviceKind kind) {
    if (kind != ui.PointerDeviceKind.touch) return;
    _movementInputAccepted = true;
    widget.onMovementGesture?.call();
  }

  @override
  void didUpdateWidget(covariant RuntimePlayerTouchControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showControls && !widget.showControls) {
      _movementInputAccepted = false;
      _dispatchAll(_driver.release());
    }
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
                opacity: widget.showControls ? widget.opacity : 0,
                child: ExcludeSemantics(
                  excluding: !widget.showControls,
                  child: Listener(
                    key: const ValueKey<String>('runtime-player-touch-movement-zone'),
                    onPointerDown: (event) {
                      _recognizeMovementPointer(event.kind);
                    },
                    child: SizedBox.square(
                  key: const ValueKey<String>(
                    'runtime-player-touch-joystick',
                  ),
                  dimension: joystickSize,
                  child: _joystick(context, joystickSize),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showControls) Positioned(
              right: horizontal + safePadding.right,
              bottom: bottom,
              child: Opacity(
                key: const ValueKey<String>(
                  'runtime-player-touch-actions-opacity',
                ),
                opacity: widget.opacity,
                child: _RuntimePlayerTouchActionCluster(
                  profile: widget.controlProfile ?? PlayerControlProfile.standard,
                  portrait: portrait,
                  buttonSize: actionSize,
                  onPrimaryChanged: (pressed) => _dispatchButton(
                    'primaryButton',
                    pressed,
                  ),
                  onSecondaryChanged: (pressed) => _dispatchButton(
                    'secondaryButton',
                    pressed,
                  ),
                  onSprintChanged: (pressed) => _dispatchButton(
                    'sprintButton',
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
          listener: (details) {
            if (_movementInputAccepted) {
              _dispatchAll(_driver.updateVector(Offset(details.x, details.y)));
            }
          },
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
    required this.onSprintChanged,
    required this.profile,
  });

  final bool portrait;
  final double buttonSize;
  final ValueChanged<bool> onPrimaryChanged;
  final ValueChanged<bool> onSecondaryChanged;
  final ValueChanged<bool> onSprintChanged;
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
    final sprint = _RuntimePlayerTouchButton(
      key: const ValueKey<String>('runtime-player-touch-sprint-button'),
      label: _label(context, 'sprintButton'),
      icon: _icon('sprintButton'),
      semanticLabel: _label(context, 'sprintButton'),
      size: buttonSize * .78,
      primary: false,
      onChanged: onSprintChanged,
    );
    const gap = SizedBox.square(dimension: PlayerSpacing.sm);
    return portrait
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[sprint, gap, secondary, gap, primary],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[sprint, gap, secondary, gap, primary],
          );
  }

  String _label(BuildContext context, String inputId) => switch (profile.controlForTouchInput(inputId)) {
    RuntimeInputControl.primary => context.playerL10n.interact,
    RuntimeInputControl.secondary => context.playerL10n.back,
    RuntimeInputControl.sprint => context.playerL10n.run,
    RuntimeInputControl.menu => context.playerL10n.pause,
    _ => profile.controlForTouchInput(inputId)?.name ?? '',
  };

  IconData _icon(String inputId) => switch (profile.controlForTouchInput(inputId)) {
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
              Icon(widget.icon, color: foreground, size: math.max(18, widget.size * .3)),
              Text(widget.label, style: TextStyle(color: foreground,
                fontWeight: FontWeight.w700, fontSize: 11)),
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
