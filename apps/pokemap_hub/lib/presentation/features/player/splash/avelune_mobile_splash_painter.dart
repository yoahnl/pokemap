import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'avelune_mobile_splash_palette.dart';

part 'lagoon_atmosphere.dart';
part 'lagoon_star.dart';
part 'lagoon_wordmark.dart';

const aveluneMobileSplashDuration = Duration(milliseconds: 4300);

abstract final class _SplashCue {
  static const seed = .20;
  static const wave = 1.0;
  static const star = 1.50;
  static const splash = 1.90;
  static const wobble = 2.24;
  static const landing = 2.76;
  static final duration = aveluneMobileSplashDuration.inMilliseconds / 1000;
}

const _pool = Offset(360, 573);
const _markCenter = Offset(453, 467);
const _starCenter = Offset(548, 346);
const _scale = .47;
final _dock = _pool + (_starCenter - _markCenter) * _scale;
const _touch = Offset(389, 647);
const _hang = Offset(270, 386);

final _crescent = Path()
  ..moveTo(554.306, 134.346)
  ..cubicTo(520.315, 128.289, 490.711, 127.126, 460.905, 129.951)
  ..cubicTo(427.365, 133.130, 393.571, 141.357, 361.455, 153.775)
  ..cubicTo(297.940, 178.334, 240.988, 219.284, 200.464, 273.584)
  ..cubicTo(130.084, 367.890, 109.255, 502.465, 157.270, 608.235)
  ..cubicTo(204.136, 711.470, 316.586, 787.264, 430.314, 794.234)
  ..cubicTo(541.756, 801.063, 654.425, 741.807, 719.616, 648.871)
  ..cubicTo(747.693, 608.844, 766.963, 562.570, 763.726, 513.733)
  ..cubicTo(762.745, 498.941, 759.700, 483.914, 750.879, 472.364)
  ..cubicTo(741.256, 459.764, 724.760, 451.303, 708.745, 449.801)
  ..cubicTo(694.844, 448.498, 681.306, 452.438, 669.111, 458.881)
  ..cubicTo(643.189, 472.575, 623.336, 497.573, 597.931, 512.369)
  ..cubicTo(572.350, 527.268, 541.141, 531.823, 512.039, 526.096)
  ..cubicTo(470.260, 517.874, 432.822, 488.463, 411.476, 451.385)
  ..cubicTo(388.177, 410.916, 384.047, 361.312, 395.914, 316.344)
  ..cubicTo(411.569, 257.022, 455.063, 205.768, 507.571, 173.780)
  ..cubicTo(526.843, 162.039, 547.329, 152.894, 564.921, 141.778)
  ..cubicTo(565.758, 141.250, 566.587, 140.717, 566.809, 140.132)
  ..cubicTo(566.965, 139.719, 566.818, 139.279, 566.571, 138.877)
  ..cubicTo(565.028, 136.357, 559.613, 135.292, 554.306, 134.346)
  ..close();

class AveluneMobileSplashPainter extends CustomPainter {
  AveluneMobileSplashPainter({
    required this.progress,
    required this.wordmark,
    required this.brand,
    required this.reducedMotion,
  }) : super(repaint: reducedMotion ? null : progress);

  final ValueListenable<double> progress;
  final ui.Image? wordmark;
  final AveluneMobileSplashPalette brand;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final duration = _SplashCue.duration;
    final t = reducedMotion ? duration : progress.value * duration;
    final landscape = size.width > size.height;
    final scale = math.min(
      size.width / 720,
      size.height / (landscape ? 864 : 1280),
    );
    final stageCenterY = landscape ? 622.0 : 640.0;
    canvas.drawColor(brand.background, BlendMode.src);
    canvas.save();
    canvas.translate(
      (size.width - 720 * scale) / 2,
      size.height / 2 - stageCenterY * scale,
    );
    canvas.scale(scale);
    _backdrop(canvas, t, brand, size.width / scale);
    _moon(canvas, t);
    _spray(canvas, t, brand);
    _guestStar(canvas, t, brand);
    final image = wordmark;
    if (image != null) _paintWordmark(canvas, t, image);
    canvas.restore();
  }

  void _moon(Canvas canvas, double t) {
    final reveal = Curves.easeInOutCubic.transform(_range(t, .31, 1.18));
    final angle = -1.24 - 4.91 * reveal;
    final origin = const Offset(451, 464);
    final sweep = Path()
      ..moveTo(origin.dx, origin.dy)
      ..arcTo(
        Rect.fromCircle(center: origin, radius: 620),
        -1.20,
        angle + 1.20,
        false,
      )
      ..close();
    final seed = _range(t, _SplashCue.seed - .055, .34);
    final glow = seed * (1 - _range(t, 1.02, 1.18));
    final edge = origin + Offset(math.cos(angle), math.sin(angle)) * 329;
    final bounce =
        _pulse(t, _SplashCue.splash, .42) *
        math.sin((t - _SplashCue.splash) * 20);
    canvas.save();
    canvas.translate(_pool.dx, _pool.dy + 4 * bounce);
    canvas.scale(_scale * (1 + .025 * bounce), _scale * (1 - .042 * bounce));
    canvas.translate(-_markCenter.dx, -_markCenter.dy);
    canvas.save();
    if (reveal < 1) canvas.clipPath(sweep);
    final moonBounds = _crescent.getBounds();
    canvas.drawPath(
      _crescent,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brand.moonLight, brand.moon, brand.moonShadow],
          stops: const [0, .39, 1],
        ).createShader(moonBounds),
    );
    canvas.save();
    canvas.clipPath(_crescent);
    _wave(canvas, t);
    canvas.restore();
    canvas.drawPath(
      _crescent,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xffd1dcff).withValues(alpha: .25),
    );
    canvas.restore();
    if (glow > 0) {
      final glint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xffd2edff).withValues(alpha: .86 * glow),
            const Color(0xff648aff).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: edge, radius: 45));
      canvas.drawCircle(edge, 45, glint);
      canvas.drawCircle(
        edge,
        5.5 * seed,
        Paint()..color = const Color(0xffe0f4ff).withValues(alpha: glow),
      );
    }
    canvas.restore();
  }

  void _wave(Canvas canvas, double t) {
    final lift =
        273 *
        (1 -
            Curves.easeOutCubic.transform(
              _range(t, _SplashCue.wave - .12, 1.57),
            ));
    final waveTime = math.max(0.0, t - _SplashCue.wave);
    final swell = 29 * math.sin(waveTime * 9) * math.exp(-waveTime * 3.0);
    final hitTime = math.max(0.0, t - _SplashCue.splash);
    final hit = 101 * math.sin(hitTime * 19) * math.exp(-hitTime * 5.3);
    final top = Path()
      ..moveTo(112, 659 + lift + swell)
      ..cubicTo(
        187,
        546 + lift + swell,
        275,
        507 + lift - swell,
        367,
        544 + lift - swell,
      )
      ..cubicTo(470, 585 + lift + hit, 536, 658 + lift + hit, 642, 652 + lift)
      ..cubicTo(707, 650 + lift, 752, 615 + lift + swell, 789, 559 + lift);
    final fill = Path.from(top)
      ..lineTo(861, 910)
      ..lineTo(80, 910)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [brand.waveLight, brand.wave, brand.waveShadow],
          stops: const [0, .34, 1],
        ).createShader(const Rect.fromLTRB(100, 513, 820, 815)),
    );
    canvas.drawPath(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4
        ..color = Color.lerp(
          brand.waveLight,
          const Color(0xffffffff),
          .48,
        )!.withValues(alpha: .61 - .35 * _range(t, 2.2, 3.3)),
    );
  }

  @override
  bool shouldRepaint(AveluneMobileSplashPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.reducedMotion != reducedMotion ||
      oldDelegate.wordmark != wordmark ||
      oldDelegate.brand != brand;
}

double _range(double t, double from, double to) =>
    ((t - from) / (to - from)).clamp(0, 1);

double _pulse(double t, double start, double length) {
  if (t < start || t > start + length) return 0;
  final p = _range(t, start, start + length);
  return math.sin(math.pi * math.pow(p, .53)) * (1 - .35 * p);
}
