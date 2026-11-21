import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:map_runtime/map_runtime.dart';

import 'runtime_touch_input_driver.dart';

class RuntimeTouchControls extends StatefulWidget {
  const RuntimeTouchControls({
    super.key,
    required this.dispatch,
  });

  final ValueChanged<RuntimeInputEvent> dispatch;

  @override
  State<RuntimeTouchControls> createState() => _RuntimeTouchControlsState();
}

class _RuntimeTouchControlsState extends State<RuntimeTouchControls> {
  final RuntimeTouchInputDriver _driver = RuntimeTouchInputDriver();

  void _dispatchAll(Iterable<RuntimeInputEvent> events) {
    for (final event in events) {
      widget.dispatch(event);
    }
  }

  void _dispatchButton(RuntimeInputControl control, bool isPress) {
    widget.dispatch(
      isPress
          ? RuntimeInputEvent.press(control)
          : RuntimeInputEvent.release(control),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final isPortrait = size.height >= size.width;
          final joystickSize = isPortrait
              ? size.width.clamp(0, 520) * 0.28
              : size.height.clamp(0, 720) * 0.24;
          final actionButtonSize = isPortrait
              ? size.width.clamp(0, 520) * 0.17
              : size.height.clamp(0, 720) * 0.14;
          final safeBottom = MediaQuery.paddingOf(context).bottom;
          final safeLeft = MediaQuery.paddingOf(context).left;
          final safeRight = MediaQuery.paddingOf(context).right;
          final bottomPadding =
              (isPortrait ? 18.0 : 14.0) + safeBottom;
          final horizontalPadding = isPortrait ? 18.0 : 22.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: horizontalPadding + safeLeft,
                bottom: bottomPadding,
                child: SizedBox(
                  key: const Key('runtime-touch-joystick'),
                  width: joystickSize.clamp(112.0, 156.0),
                  height: joystickSize.clamp(112.0, 156.0),
                  child: _buildJoystick(),
                ),
              ),
              Positioned(
                right: horizontalPadding + safeRight,
                bottom: bottomPadding,
                child: _RuntimeTouchActionCluster(
                  isPortrait: isPortrait,
                  buttonSize: actionButtonSize.clamp(68.0, 90.0),
                  onPrimaryChanged: (isPress) => _dispatchButton(
                    RuntimeInputControl.primary,
                    isPress,
                  ),
                  onSecondaryChanged: (isPress) => _dispatchButton(
                    RuntimeInputControl.secondary,
                    isPress,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildJoystick() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.5,
        ),
      ),
      child: Joystick(
        includeInitialAnimation: false,
        mode: JoystickMode.horizontalAndVertical,
        period: const Duration(milliseconds: 60),
        base: JoystickBase(
          size: 140,
          decoration: JoystickBaseDecoration(
            drawArrows: false,
            outerCircleColor: Colors.white.withValues(alpha: 0.12),
            middleCircleColor: Colors.white.withValues(alpha: 0.10),
            innerCircleColor: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        stick: const _RuntimeJoystickStick(),
        listener: (details) {
          _dispatchAll(_driver.updateVector(Offset(details.x, details.y)));
        },
        onStickDragEnd: () {
          _dispatchAll(_driver.release());
        },
      ),
    );
  }
}

class _RuntimeTouchActionCluster extends StatelessWidget {
  const _RuntimeTouchActionCluster({
    required this.isPortrait,
    required this.buttonSize,
    required this.onPrimaryChanged,
    required this.onSecondaryChanged,
  });

  final bool isPortrait;
  final double buttonSize;
  final ValueChanged<bool> onPrimaryChanged;
  final ValueChanged<bool> onSecondaryChanged;

  @override
  Widget build(BuildContext context) {
    final spacing = isPortrait ? 14.0 : 12.0;
    final secondaryButton = _RuntimeTouchButton(
      key: const Key('runtime-touch-secondary-button'),
      label: 'B',
      size: buttonSize,
      color: const Color(0xFF51607C),
      onChanged: onSecondaryChanged,
    );
    final primaryButton = _RuntimeTouchButton(
      key: const Key('runtime-touch-primary-button'),
      label: 'A',
      size: buttonSize,
      color: const Color(0xFF6F55C6),
      onChanged: onPrimaryChanged,
    );

    if (isPortrait) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          secondaryButton,
          SizedBox(height: spacing),
          primaryButton,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        secondaryButton,
        SizedBox(width: spacing),
        primaryButton,
      ],
    );
  }
}

class _RuntimeTouchButton extends StatefulWidget {
  const _RuntimeTouchButton({
    super.key,
    required this.label,
    required this.size,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final double size;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  State<_RuntimeTouchButton> createState() => _RuntimeTouchButtonState();
}

class _RuntimeTouchButtonState extends State<_RuntimeTouchButton> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
    widget.onChanged(pressed);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _pressed ? 0.96 : 0.84),
          border: Border.all(
            color: Colors.white.withValues(alpha: _pressed ? 0.95 : 0.75),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _pressed ? 0.20 : 0.12),
              blurRadius: _pressed ? 6 : 10,
              offset: Offset(0, _pressed ? 2 : 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: math.max(24, size * 0.34),
          ),
        ),
      ),
    );
  }
}

class _RuntimeJoystickStick extends StatelessWidget {
  const _RuntimeJoystickStick();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.9),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}
