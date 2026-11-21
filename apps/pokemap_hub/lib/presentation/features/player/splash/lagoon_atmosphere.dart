part of 'avelune_splash_painter.dart';

final _sky = List.generate(45, (i) {
  final random = math.Random(92 + i * 7);
  return (
    at: Offset(18 + random.nextDouble() * 684, 82 + random.nextDouble() * 1070),
    radius: .65 + random.nextDouble() * 1.75,
    opacity: .12 + random.nextDouble() * .29,
    depth: .28 + random.nextDouble() * .72,
    phase: random.nextDouble() * math.pi * 2,
  );
});

const _waitingStars = [
  Offset(.09, .20),
  Offset(.21, .29),
  Offset(.31, .19),
  Offset(.44, .14),
  Offset(.57, .22),
  Offset(.67, .17),
  Offset(.79, .25),
  Offset(.91, .18),
  Offset(.12, .38),
  Offset(.22, .45),
  Offset(.78, .38),
  Offset(.89, .42),
  Offset(.08, .56),
  Offset(.23, .60),
  Offset(.81, .58),
  Offset(.93, .55),
  Offset(.16, .70),
  Offset(.36, .77),
  Offset(.64, .73),
  Offset(.86, .71),
];

void _backdrop(
  Canvas canvas,
  double t,
  double ambientPhase,
  AveluneSplashPalette brand,
  Rect viewport,
) {
  final spread = math.max(1.0, viewport.width / 850);
  final bloom = Curves.easeOutCubic.transform(_range(t, .15, 1.95));
  final tide = _pulse(t, _SplashCue.wave - .10, .98);
  final impact = _pulse(t, _SplashCue.splash, .72);
  final landing = _pulse(t, _SplashCue.landing, 1.26);
  final finalHold = Curves.easeInOut.transform(
    _range(t, 3.03, _SplashCue.duration),
  );
  final drift = math.sin(ambientPhase);
  final lift = math.cos(ambientPhase) - 1;

  _glow(
    canvas,
    Offset(
      289 + 100 * math.sin(t * 1.18 - .48) + 64 * drift,
      516 + 34 * math.sin(t * .95) + 21 * lift,
    ),
    (800 + 65 * bloom) * spread,
    842,
    brand.skyGlow,
    .33 + .30 * bloom + .065 * landing + .075 * drift,
  );
  _glow(
    canvas,
    Offset(
      465 - 191 * tide + 36 * math.sin(1.9 * t) - 42 * drift,
      732 - 107 * tide + 32 * impact - 14 * lift,
    ),
    (726 + 112 * impact) * spread,
    476 + 94 * tide,
    Color.lerp(brand.background, brand.wave, .54)!,
    .13 + .25 * bloom + .26 * tide + .22 * impact - .035 * lift,
  );

  if (t >= _SplashCue.star && t < _SplashCue.landing + .6) {
    final light =
        _range(t, _SplashCue.star, _SplashCue.star + .15) *
        (1 - _range(t, _SplashCue.landing, _SplashCue.landing + .60));
    _glow(canvas, _starAt(t), 354, 314, brand.star, .15 * light);
  }

  _drawCurrent(
    canvas,
    t,
    ambientPhase,
    tide,
    impact,
    bloom * (1 - .39 * finalHold - .13 * lift),
    brand,
  );
  _drawWake(canvas, t, brand);
  _drawDriftingLights(canvas, t, ambientPhase, bloom, impact, finalHold, brand);
  final starFade = Curves.easeOut.transform(
    _range(t, 3.55, _SplashCue.duration),
  );
  if (starFade > 0) {
    _drawWaitingStars(canvas, viewport, ambientPhase, starFade, brand);
  }
}

void _drawWaitingStars(
  Canvas canvas,
  Rect viewport,
  double phase,
  double fade,
  AveluneSplashPalette brand,
) {
  final paint = Paint()..strokeCap = StrokeCap.round;
  final color = Color.lerp(brand.moonLight, brand.starLight, .24)!;
  for (var i = 0; i < _waitingStars.length; i++) {
    final position = _waitingStars[i];
    final angle = i * 2.39996;
    final shimmer = .5 + .5 * math.sin(angle + phase * (2 + i % 2));
    final pulse = shimmer * shimmer;
    final radius = 1.7 + (i % 3) * .4 + 1.7 * pulse;
    final center = Offset(
      viewport.left + viewport.width * position.dx + 5 * math.sin(phase),
      viewport.top + viewport.height * position.dy + 3 * (math.cos(phase) - 1),
    );
    paint.color = color.withValues(alpha: fade * (.13 + .59 * pulse));
    canvas.drawCircle(center, radius * .68, paint);
    if (i.isEven) {
      final arm = radius * (1 + .85 * pulse);
      paint
        ..strokeWidth = 1.3
        ..color = color.withValues(alpha: fade * (.07 + .34 * pulse));
      canvas.drawLine(center - Offset(0, arm), center + Offset(0, arm), paint);
      canvas.drawLine(
        center - Offset(arm * .65, 0),
        center + Offset(arm * .65, 0),
        paint,
      );
    }
  }
}

void _glow(
  Canvas canvas,
  Offset at,
  double width,
  double height,
  Color color,
  double alpha,
) {
  final bounds = Rect.fromCenter(center: at, width: width, height: height);
  canvas.drawOval(
    bounds,
    Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * .36),
          color.withValues(alpha: 0),
        ],
        stops: const [0, .52, 1],
      ).createShader(bounds),
  );
}

void _drawCurrent(
  Canvas canvas,
  double t,
  double ambientPhase,
  double tide,
  double impact,
  double clarity,
  AveluneSplashPalette brand,
) {
  final phase = t * 1.73 + .64 * math.sin(ambientPhase);
  final roll =
      1 - Curves.easeOutCubic.transform(_range(t, _SplashCue.wave - .18, 1.70));
  final drift = 31 * math.sin(phase * .73);
  final height = 758 + 73 * roll + drift - 92 * tide;
  final skew = 86 + 66 * tide + 44 * impact;
  final crest = 52 * math.sin(phase + .63);
  final foam = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final sweep = Rect.fromLTWH(-70 + 110 * math.sin(t * .91 - .94), 0, 840, 1);
  for (var i = 0; i < 6; i++) {
    final y = height + i * 17;
    final lift = math.sin(phase + i * .25) * (26 + 15 * tide);
    final curve = Path()
      ..moveTo(-178, y + 91 - lift)
      ..cubicTo(4, y + 61 - lift, 82, y - skew + crest, 272, y - .67 * skew)
      ..cubicTo(
        462,
        y - .43 * skew - lift,
        582,
        y + 18 + crest,
        887,
        y - 147 + lift,
      );
    final opacity = (.08 + .17 * tide + .15 * impact) * clarity * (1 - i * .14);
    foam.strokeWidth = 1.6 - i * .15;
    foam.shader = LinearGradient(
      colors: [
        const Color(0xff68b5f6).withValues(alpha: 0),
        brand.wave.withValues(alpha: opacity),
        const Color(0xff9ecdf5).withValues(alpha: opacity * .66),
        const Color(0xff79c1e1).withValues(alpha: 0),
      ],
      stops: const [0, .34, .64, 1],
    ).createShader(sweep);
    canvas.drawPath(curve, foam);
  }
}

void _drawWake(Canvas canvas, double t, AveluneSplashPalette brand) {
  final paint = Paint()..style = PaintingStyle.stroke;
  for (var i = 0; i < 4; i++) {
    final start = _SplashCue.splash + .064 * i;
    final progress = _range(t, start, start + 1.03 + .085 * i);
    if (progress <= 0 || progress >= 1) continue;
    final expansion = Curves.easeOutQuart.transform(progress);
    final radius = 24 + 380 * expansion;
    final bounds = Rect.fromCenter(
      center: _touch + Offset(0, 70 * expansion),
      width: radius * 2,
      height: radius * .52,
    );
    final alpha =
        math.sin(math.pi * math.pow(progress, .32)) * (.35 - .043 * i);
    paint.shader = LinearGradient(
      colors: [
        brand.wave.withValues(alpha: 0),
        brand.waveLight.withValues(alpha: alpha),
        const Color(0xff89a8eb).withValues(alpha: alpha * .64),
        brand.wave.withValues(alpha: 0),
      ],
      stops: const [0, .24, .74, 1],
    ).createShader(bounds);
    paint.strokeWidth = 2.25 - 1.1 * expansion;
    canvas.drawOval(bounds, paint);
  }
}

void _drawDriftingLights(
  Canvas canvas,
  double t,
  double ambientPhase,
  double bloom,
  double impact,
  double finalHold,
  AveluneSplashPalette brand,
) {
  final paint = Paint();
  final flow = _range(t, _SplashCue.wave - .17, 1.89);
  final waveFront =
      40 + 430 * Curves.easeOut.transform(_range(t, _SplashCue.splash, 2.85));
  for (final light in _sky) {
    final drift = Offset(
      (t * 20 + 26 * math.sin(light.phase + 1.23 * t)) * light.depth,
      (-t * 15 + 23 * math.cos(light.phase + .85 * t) - 24 * flow) *
          light.depth,
    );
    final at = light.at + drift;
    final outward = at - _touch;
    final distance = outward.distance;
    final push = math.max(0.0, 1 - (distance - waveFront).abs() / 140) * impact;
    final twinkle =
        .10 *
        (math.sin(light.phase + 2 * ambientPhase) - math.sin(light.phase));
    final brightness =
        (.42 +
            .32 * bloom +
            .32 * push +
            .18 * math.sin(t * 2.03 + light.phase) +
            twinkle) *
        (1 - .31 * finalHold);
    final center = at + outward / math.max(distance, 1) * (32 * push);
    paint.color = Color.lerp(
      const Color(0xff9bbdff),
      brand.waveLight,
      push,
    )!.withValues(alpha: brightness * light.opacity);
    canvas.drawCircle(center, light.radius * (1 + .6 * push), paint);
  }
}

void _spray(Canvas canvas, double t, AveluneSplashPalette brand) {
  final p = _range(t, _SplashCue.splash, 2.52);
  if (p <= 0 || p >= 1) return;
  for (var i = 0; i < 11; i++) {
    final dx = (i - 5) * (19 + (i % 3) * 8);
    final lift = 65 + (i * 41) % 112;
    final position = _touch + Offset(dx * p, -lift * 4 * p * (1 - p) + 43 * p);
    final size = (2.7 + (i % 4) * 1.08) * (1 - p * .7);
    canvas.drawCircle(
      position,
      size,
      Paint()
        ..color = Color.lerp(
          brand.wave,
          brand.waveLight,
          (i % 4) / 4,
        )!.withValues(alpha: (1 - p) * .87),
    );
  }
}
