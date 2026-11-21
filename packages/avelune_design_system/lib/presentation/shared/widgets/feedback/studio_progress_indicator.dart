import 'package:flutter/material.dart';

import '../../../theme/studio_tokens.dart';
import 'studio_progress_painter.dart';

class StudioProgressIndicator extends StatefulWidget {
  const StudioProgressIndicator({super.key, this.label}) : size = null;

  const StudioProgressIndicator.compact({
    super.key,
    this.label,
    this.size = 16,
  });

  final String? label;
  final double? size;

  @override
  State<StudioProgressIndicator> createState() =>
      _StudioProgressIndicatorState();
}

class _StudioProgressIndicatorState extends State<StudioProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2150),
  );
  var _motion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (motion == _motion) return;
    _motion = motion;
    if (motion) {
      _animation.repeat();
    } else {
      _animation.stop();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Semantics(
      label: widget.label,
      child: SizedBox.square(
        dimension: widget.size ?? 36,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: StudioProgressPainter(
              animation: _motion ? _animation : null,
              colors: brightness == Brightness.light
                  ? StudioProgressColors.light
                  : StudioProgressColors.dark,
            ),
          ),
        ),
      ),
    );
  }
}
