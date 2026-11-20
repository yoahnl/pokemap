part of 'avelune_mobile_splash_painter.dart';

const _whiteWordmark = ColorFilter.mode(Color(0xffffffff), BlendMode.srcIn);

void _paintWordmark(Canvas canvas, double time, ui.Image wordmark) {
  final age = time - _SplashCue.landing;
  if (age <= 0) return;

  final arrival = _range(age, 0, .34);
  final color = _range(age, .44, 1.04);
  final rise = Curves.easeOutCubic.transform(arrival);
  final source = Rect.fromLTWH(
    0,
    0,
    wordmark.width.toDouble(),
    wordmark.height.toDouble(),
  );
  final target = Rect.fromCenter(
    center: Offset(360, 803 + (1 - rise) * 24),
    width: 266,
    height: 266 * source.height / source.width,
  );

  if (color < 1) {
    _paintWordmarkLayer(
      canvas,
      wordmark,
      source,
      target,
      tint: _whiteWordmark,
      hidden: arrival < 1 ? _arrivalWave(target, arrival) : null,
      feather: 3.1,
    );
  }
  if (color > 0) {
    _paintWordmarkLayer(
      canvas,
      wordmark,
      source,
      target,
      hidden: color < 1 ? _descendingWave(target, color) : null,
      feather: 2.25,
    );
  }
}

Path _arrivalWave(Rect target, double progress) {
  const overscan = 38.0;
  final front =
      target.left -
      overscan +
      (target.width + 2 * overscan) * Curves.easeInOutSine.transform(progress);
  final top = target.top;
  final height = target.height;
  return Path()
    ..moveTo(front - 11, top - overscan)
    ..cubicTo(
      front - 23,
      top + height * .11,
      front + 27,
      top + height * .31,
      front + 14,
      top + height * .55,
    )
    ..cubicTo(
      front + 3,
      top + height * .75,
      front - 24,
      top + height * .88,
      front - 6,
      target.bottom + overscan,
    )
    ..lineTo(target.right + 2 * overscan, target.bottom + overscan)
    ..lineTo(target.right + 2 * overscan, top - overscan)
    ..close();
}

Path _descendingWave(Rect target, double progress) {
  const overscan = 19.0;
  const steps = 32;
  final slope = Curves.easeInOutSine.transform(progress);
  final height = target.top - overscan + (target.height + 2 * overscan) * slope;
  final left = target.left - overscan;
  final right = target.right + overscan;
  final bottom = target.bottom + overscan;
  final path = Path()..moveTo(left, bottom);
  for (var i = 0; i <= steps; i++) {
    final fraction = i / steps;
    final phase = 2 * math.pi * (fraction * 1.48 - progress * .63);
    final crest =
        target.height *
        (.145 * math.sin(phase) + .032 * math.sin(2 * phase + .6));
    path.lineTo(left + (right - left) * fraction, height + crest);
  }
  return path
    ..lineTo(right, bottom)
    ..close();
}

void _paintWordmarkLayer(
  Canvas canvas,
  ui.Image wordmark,
  Rect source,
  Rect target, {
  ColorFilter? tint,
  Path? hidden,
  required double feather,
}) {
  final paint = Paint()
    ..filterQuality = FilterQuality.medium
    ..colorFilter = tint;
  if (hidden == null) {
    canvas.drawImageRect(wordmark, source, target, paint);
    return;
  }
  canvas.saveLayer(target.inflate(6), Paint());
  canvas.drawImageRect(wordmark, source, target, paint);
  canvas.drawPath(
    hidden,
    Paint()
      ..blendMode = BlendMode.dstOut
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, feather),
  );
  canvas.restore();
}
