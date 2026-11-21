import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../theme/studio_tokens.dart';
import 'studio_progress_paths.dart';

class StudioProgressPainter extends CustomPainter {
  StudioProgressPainter({required this.animation, required this.colors})
    : super(repaint: animation);

  static const _view = Rect.fromLTWH(94, 92, 720, 744);
  static const _moonFill = Rect.fromLTWH(90, 100, 740, 730);
  static const _ease = Cubic(.2, .75, .25, 1);
  static const _turnStart = Cubic(.28, .05, .62, .85);
  static const _turnFinish = Cubic(.22, .5, .46, 1);
  static final _moonMetric = crescentPath.computeMetrics().single;
  static final _moonBounds = crescentPath.getBounds();
  static final _waveBounds = wavePath.getBounds();
  static final _starBounds = starPath.getBounds();

  final Animation<double>? animation;
  final StudioProgressColors colors;

  late final _moon = Paint()
    ..shader = ui.Gradient.linear(
      _moonBounds.topLeft,
      Offset(_moonBounds.left + _moonBounds.width * .8, _moonBounds.bottom),
      colors.moon,
      const [0, .45, 1],
    );
  late final _outline = Paint()
    ..shader = _moon.shader
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  late final _wave = Paint()
    ..shader = ui.Gradient.linear(
      _waveBounds.topLeft,
      Offset(_waveBounds.right, _waveBounds.top + _waveBounds.height * .65),
      colors.wave,
      const [0, .56, 1],
    );
  late final _star = Paint()..color = colors.star;
  final _layer = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final factor = math.min(
      size.width / _view.width,
      size.height / _view.height,
    );
    final frame = animation?.value;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(factor);
    if (frame != null) {
      final turn = frame < .74
          ? 338 * _phase(frame, 0, .74, _turnStart)
          : 338 + 22 * _phase(frame, .74, 1, _turnFinish);
      canvas.rotate(turn * math.pi / 180);
    }
    canvas.translate(-_view.center.dx, -_view.center.dy);
    if (frame == null) {
      canvas.drawPath(crescentPath, _moon);
      _paintWave(canvas, 0, 1);
      canvas.drawPath(starPath, _star);
    } else {
      _paintFrame(canvas, frame, math.min(size.width, size.height) <= 16);
    }
    canvas.restore();
  }

  void _paintFrame(Canvas canvas, double frame, bool compact) {
    final opacity = frame < .08
        ? .7 + .3 * _phase(frame, 0, .08)
        : 1 - .82 * _phase(frame, .9, 1);
    if (opacity < 1) {
      canvas.saveLayer(
        _view.inflate(30),
        _layer..color = Color.from(alpha: opacity, red: 1, green: 1, blue: 1),
      );
    }

    final fill = _phase(frame, .23, .49, _ease);
    if (fill > 0) {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(
          _moonFill.left,
          _moonFill.bottom - _moonFill.height * fill,
          _moonFill.right,
          _moonFill.bottom,
        ),
      );
      canvas.drawPath(crescentPath, _moon);
      canvas.restore();
    }

    if (frame > .44) {
      final shift = frame < .68
          ? 1.05 - 1.075 * _phase(frame, .44, .68, _ease)
          : -.025 * (1 - _phase(frame, .68, .77, _ease));
      _paintWave(canvas, shift, _phase(frame, .44, .51, _ease));
    }

    if (frame < .54) {
      final trace = .06 + .94 * _phase(frame, 0, .34);
      final outlineOpacity = frame < .34
          ? .86 + .14 * _phase(frame, 0, .34)
          : 1 - .32 * _phase(frame, .34, .43) - .68 * _phase(frame, .43, .54);
      final outline = _moonMetric.extractPath(0, _moonMetric.length * trace);
      _outline.strokeWidth = compact ? 46 : 32;
      canvas.saveLayer(
        _moonBounds.inflate(25),
        _layer
          ..color = Color.from(
            alpha: outlineOpacity.clamp(0.0, 1.0),
            red: 1,
            green: 1,
            blue: 1,
          ),
      );
      canvas.drawPath(outline, _outline);
      canvas.restore();
    }

    if (frame > .65) _paintStar(canvas, frame);
    if (opacity < 1) canvas.restore();
  }

  void _paintWave(Canvas canvas, double shift, double opacity) {
    canvas.save();
    canvas.clipPath(crescentPath);
    if (opacity < 1) {
      canvas.saveLayer(
        _moonBounds,
        _layer..color = Color.from(alpha: opacity, red: 1, green: 1, blue: 1),
      );
    }
    canvas.translate(0, shift * _waveBounds.height);
    canvas.drawPath(wavePath, _wave);
    if (opacity < 1) canvas.restore();
    canvas.restore();
  }

  void _paintStar(Canvas canvas, double frame) {
    final rise = _phase(frame, .65, .79, _ease);
    final settle = _phase(frame, .79, .87, _ease);
    final shift = .56 - .62 * rise + .06 * settle;
    final angle = -22 + 30 * rise - 8 * settle;
    final scale = .2 + .92 * rise - .12 * settle;
    canvas.save();
    canvas.translate(
      _starBounds.center.dx,
      _starBounds.center.dy + shift * _starBounds.height,
    );
    canvas.rotate(angle * math.pi / 180);
    canvas.scale(scale);
    canvas.translate(-_starBounds.center.dx, -_starBounds.center.dy);
    canvas.drawPath(
      starPath,
      _star..color = colors.star.withValues(alpha: rise),
    );
    canvas.restore();
  }

  static double _phase(
    double frame,
    double start,
    double end, [
    Curve curve = Curves.linear,
  ]) => curve.transform(((frame - start) / (end - start)).clamp(0.0, 1.0));

  @override
  bool shouldRepaint(StudioProgressPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.colors != colors;
}
