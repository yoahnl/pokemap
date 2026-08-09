import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/pokemap_player_theme.dart';

class PlayerCinematicStage extends StatelessWidget {
  const PlayerCinematicStage({
    super.key,
    required this.child,
    this.compactBreakpoint = 760,
  });

  final Widget child;
  final double compactBreakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final framed = size.width > compactBreakpoint &&
              size.width / size.height > 4 / 3;
          if (!framed) return child;
          final width = math.min(size.width, size.height * 16 / 9);
          final height = width * 9 / 16;
          return ColoredBox(
            color: context.playerColors.scrim.withValues(alpha: 1),
            child: Center(
              child: SizedBox(
                key: const ValueKey<String>('player-cinematic-stage'),
                width: width,
                height: height,
                child: child,
              ),
            ),
          );
        },
      );
}
