import 'dart:math' as math;

import 'package:flutter/material.dart';

class PlayerWorldMapLoadingEmblem extends StatefulWidget {
  const PlayerWorldMapLoadingEmblem({
    super.key,
    required this.logo,
    required this.ambient,
    required this.reducedMotion,
  });

  final ImageProvider logo;
  final Animation<double> ambient;
  final bool reducedMotion;

  @override
  State<PlayerWorldMapLoadingEmblem> createState() =>
      _PlayerWorldMapLoadingEmblemState();
}

class _PlayerWorldMapLoadingEmblemState
    extends State<PlayerWorldMapLoadingEmblem>
    with SingleTickerProviderStateMixin {
  late final _sparkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  bool _lit = false;

  void _flash() {
    if (widget.reducedMotion) {
      setState(() => _lit = !_lit);
    } else {
      _sparkle.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(PlayerWorldMapLoadingEmblem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion != oldWidget.reducedMotion) {
      _sparkle.reset();
      _lit = false;
    }
  }

  @override
  void dispose() {
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: SizedBox.square(
      dimension: 66,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Material(
              type: MaterialType.transparency,
              child: IconButton(
                key: const ValueKey('player-world-loading-emblem'),
                tooltip: 'Avelune',
                onPressed: _flash,
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(52),
                  fixedSize: const Size.square(52),
                  padding: const EdgeInsets.all(4),
                  backgroundColor: const Color(0xff122a35),
                  foregroundColor: const Color(0xffa0efdb),
                  side: const BorderSide(color: Color(0xff638781)),
                ),
                icon: AnimatedBuilder(
                  animation: widget.ambient,
                  child: Image(
                    image: ResizeImage(widget.logo, width: 160),
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                  builder: (context, child) {
                    final sway = widget.reducedMotion
                        ? 0.0
                        : math.sin(widget.ambient.value * 2 * math.pi);
                    return Transform.translate(
                      offset: Offset(0, -sway * 1.6),
                      child: Transform.rotate(angle: sway * .06, child: child),
                    );
                  },
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _sparkle,
              builder: (context, _) {
                final phase = widget.reducedMotion
                    ? (_lit ? .35 : 0.0)
                    : _sparkle.value;
                if (phase == 0 || phase == 1) return const SizedBox.shrink();
                return CustomPaint(
                  key: const ValueKey('player-world-loading-sparkle'),
                  painter: _EmblemSparklePainter(phase),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmblemSparklePainter extends CustomPainter {
  const _EmblemSparklePainter(this.phase);

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final spread = Curves.easeOutCubic.transform(phase);
    final center = size.center(Offset.zero);
    final light = Paint()
      ..color = const Color(0xffffd6a1)
          .withValues(alpha: math.sin(phase * math.pi));
    for (final (angle, size) in const [(-2.4, 4.5), (-.67, 6.0), (.74, 3.0)]) {
      final star =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (17 + spread * 15);
      final tip = size * (1 - .3 * spread);
      canvas.drawPath(
        Path()
          ..moveTo(star.dx, star.dy - tip)
          ..quadraticBezierTo(star.dx + 1, star.dy - 1, star.dx + tip, star.dy)
          ..quadraticBezierTo(star.dx + 1, star.dy + 1, star.dx, star.dy + tip)
          ..quadraticBezierTo(star.dx - 1, star.dy + 1, star.dx - tip, star.dy)
          ..quadraticBezierTo(star.dx - 1, star.dy - 1, star.dx, star.dy - tip)
          ..close(),
        light,
      );
    }
  }

  @override
  bool shouldRepaint(_EmblemSparklePainter oldDelegate) =>
      phase != oldDelegate.phase;
}
