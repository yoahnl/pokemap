import 'package:flutter/material.dart';
import '../../../theme/studio_tokens.dart';
import 'studio_badge.dart';

class StudioIconTile extends StatelessWidget {
  const StudioIconTile({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 36,
  });
  final IconData icon;
  final StudioTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = tone.color(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
        border: Border.all(color: color.withValues(alpha: .5)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: .38), color.withValues(alpha: .12)],
        ),
      ),
      child: Icon(icon, color: color, size: size * .55),
    );
  }
}
