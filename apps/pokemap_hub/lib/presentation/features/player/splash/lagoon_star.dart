part of 'avelune_mobile_splash_painter.dart';

final _star = Path()
  ..moveTo(0, -74)
  ..cubicTo(6, -31, 20, -11, 57, 0)
  ..cubicTo(20, 10, 6, 30, 0, 73)
  ..cubicTo(-6, 30, -20, 10, -57, 0)
  ..cubicTo(-20, -11, -6, -31, 0, -74)
  ..close();

void _guestStar(Canvas canvas, double t, AveluneMobileSplashPalette brand) {
  if (t < _SplashCue.star) return;
  final at = _starAt(t);
  final entry = Curves.easeOut.transform(_range(t, _SplashCue.star, 1.62));
  final squeeze = _pulse(t, _SplashCue.splash - .018, .14);
  final landing = _pulse(t, _SplashCue.landing, .36);
  final onOrbit = 1 - _range(t, _SplashCue.landing, 3.14);
  for (var i = 9; i > 0; i--) {
    final behind = t - .018 * i;
    if (behind < _SplashCue.star) continue;
    final opacity = (1 - i / 10) * .31 * entry * onOrbit;
    final trail = _starAt(behind);
    if ((trail - at).distance < 12) continue;
    canvas.drawCircle(
      trail,
      1.8 + (9 - i) * .50,
      Paint()..color = brand.star.withValues(alpha: opacity),
    );
  }
  final halo = Rect.fromCircle(center: at, radius: 96 + 35 * landing);
  canvas.drawCircle(
    at,
    halo.width / 2,
    Paint()
      ..shader = RadialGradient(
        colors: [
          brand.star.withValues(alpha: entry * (.22 + .17 * landing)),
          brand.star.withValues(alpha: 0),
        ],
      ).createShader(halo),
  );
  final flip = _range(t, _SplashCue.splash, _SplashCue.landing);
  final roll = -math.pi * 2 * Curves.easeOutCubic.transform(flip);
  final wobble = _pulse(t, _SplashCue.wobble, .23);
  final tilt =
      .51 * (1 - _range(t, _SplashCue.star, _SplashCue.splash)) +
      .22 * wobble * math.sin((t - _SplashCue.wobble) * 49) +
      roll;
  final size = _scale * entry;
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(tilt);
  canvas.scale(
    size * (1 + .34 * squeeze + .11 * landing),
    size * (1 - .30 * squeeze + .11 * landing),
  );
  canvas.drawPath(
    _star,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomRight,
        colors: [brand.starLight, brand.star, brand.starShadow],
        stops: const [0, .51, 1],
      ).createShader(const Rect.fromLTRB(-57, -74, 57, 73)),
  );
  canvas.restore();
  final glint = _pulse(t, _SplashCue.landing, .62);
  for (var i = 0; i < 5; i++) {
    final angle = i * 1.2566 + .19;
    final radius = 41 + _range(t, _SplashCue.landing, 3.38) * (27 + i * 4);
    final direction = Offset(math.cos(angle), math.sin(angle));
    canvas.drawLine(
      at + direction * radius,
      at + direction * (radius + 11 * glint),
      Paint()
        ..color = brand.star.withValues(alpha: .72 * glint)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.7,
    );
  }
  if (wobble > 0) {
    final flick = Paint()
      ..color = brand.star.withValues(alpha: .64 * wobble)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      at + const Offset(-40, -12),
      at + const Offset(-56, -18),
      flick,
    );
    canvas.drawLine(
      at + const Offset(-33, -27),
      at + const Offset(-41, -42),
      flick,
    );
  }
}

Offset _starAt(double t) {
  if (t < _SplashCue.splash) {
    return _bezier(
      const Offset(648, 337),
      const Offset(572, 339),
      const Offset(475, 446),
      _touch,
      _range(t, _SplashCue.star, _SplashCue.splash),
    );
  }
  if (t < _SplashCue.wobble) {
    return _bezier(
      _touch,
      const Offset(348, 465),
      const Offset(246, 420),
      _hang,
      _range(t, _SplashCue.splash, _SplashCue.wobble),
    );
  }
  final p = _range(t, _SplashCue.wobble, _SplashCue.landing);
  return _bezier(
    _hang,
    const Offset(282, 354),
    const Offset(418, 377),
    _dock,
    p,
  );
}

Offset _bezier(Offset a, Offset b, Offset c, Offset d, double t) {
  final u = 1 - t;
  return a * (u * u * u) +
      b * (3 * u * u * t) +
      c * (3 * u * t * t) +
      d * (t * t * t);
}
