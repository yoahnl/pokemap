import 'package:flutter/material.dart';

@immutable
final class AveluneMotionTokens extends ThemeExtension<AveluneMotionTokens> {
  const AveluneMotionTokens({
    required this.press,
    required this.selection,
    required this.exchange,
    required this.insertionAlign,
    required this.insertionDescend,
    required this.insertionLatch,
    required this.insertionLaunchDelay,
    required this.detailsHero,
    required this.ambientFloat,
    required this.movementCurve,
    required this.pressCurve,
    required this.descentCurve,
    required this.ambientFloatAmplitude,
  });

  static const AveluneMotionTokens standard = AveluneMotionTokens(
    press: Duration(milliseconds: 100),
    selection: Duration(milliseconds: 180),
    exchange: Duration(milliseconds: 440),
    // The console changes LED colour at every step — violet at rest, amber
    // while inserting, green once latched, bright violet while booting. The old
    // 620 ms total ran the whole sequence faster than it could be read.
    insertionAlign: Duration(milliseconds: 280),
    insertionDescend: Duration(milliseconds: 640),
    insertionLatch: Duration(milliseconds: 460),
    insertionLaunchDelay: Duration(milliseconds: 720),
    detailsHero: Duration(milliseconds: 420),
    ambientFloat: Duration(milliseconds: 2800),
    movementCurve: Cubic(0.2, 0.8, 0.2, 1),
    pressCurve: Curves.easeOutCubic,
    descentCurve: Curves.easeInCubic,
    ambientFloatAmplitude: 4,
  );

  static const AveluneMotionTokens reduced = AveluneMotionTokens(
    press: Duration(milliseconds: 80),
    selection: Duration(milliseconds: 120),
    exchange: Duration(milliseconds: 120),
    insertionAlign: Duration.zero,
    insertionDescend: Duration(milliseconds: 120),
    insertionLatch: Duration.zero,
    insertionLaunchDelay: Duration.zero,
    detailsHero: Duration(milliseconds: 120),
    ambientFloat: Duration.zero,
    movementCurve: Curves.easeOut,
    pressCurve: Curves.easeOut,
    descentCurve: Curves.easeOut,
    ambientFloatAmplitude: 0,
  );

  final Duration press;
  final Duration selection;
  final Duration exchange;
  final Duration insertionAlign;
  final Duration insertionDescend;
  final Duration insertionLatch;
  final Duration insertionLaunchDelay;
  final Duration detailsHero;
  final Duration ambientFloat;
  final Curve movementCurve;
  final Curve pressCurve;
  final Curve descentCurve;
  final double ambientFloatAmplitude;

  Map<String, Duration> get values => <String, Duration>{
        'press': press,
        'selection': selection,
        'exchange': exchange,
        'insertionAlign': insertionAlign,
        'insertionDescend': insertionDescend,
        'insertionLatch': insertionLatch,
        'insertionLaunchDelay': insertionLaunchDelay,
        'detailsHero': detailsHero,
        'ambientFloat': ambientFloat,
      };

  @override
  AveluneMotionTokens copyWith({
    Duration? press,
    Duration? selection,
    Duration? exchange,
    Duration? insertionAlign,
    Duration? insertionDescend,
    Duration? insertionLatch,
    Duration? insertionLaunchDelay,
    Duration? detailsHero,
    Duration? ambientFloat,
    Curve? movementCurve,
    Curve? pressCurve,
    Curve? descentCurve,
    double? ambientFloatAmplitude,
  }) =>
      AveluneMotionTokens(
        press: press ?? this.press,
        selection: selection ?? this.selection,
        exchange: exchange ?? this.exchange,
        insertionAlign: insertionAlign ?? this.insertionAlign,
        insertionDescend: insertionDescend ?? this.insertionDescend,
        insertionLatch: insertionLatch ?? this.insertionLatch,
        insertionLaunchDelay: insertionLaunchDelay ?? this.insertionLaunchDelay,
        detailsHero: detailsHero ?? this.detailsHero,
        ambientFloat: ambientFloat ?? this.ambientFloat,
        movementCurve: movementCurve ?? this.movementCurve,
        pressCurve: pressCurve ?? this.pressCurve,
        descentCurve: descentCurve ?? this.descentCurve,
        ambientFloatAmplitude:
            ambientFloatAmplitude ?? this.ambientFloatAmplitude,
      );

  @override
  AveluneMotionTokens lerp(
    covariant AveluneMotionTokens? other,
    double t,
  ) {
    if (other == null || t <= 0) return this;
    if (t >= 1) return other;
    return AveluneMotionTokens(
      press: _lerpDuration(press, other.press, t),
      selection: _lerpDuration(selection, other.selection, t),
      exchange: _lerpDuration(exchange, other.exchange, t),
      insertionAlign: _lerpDuration(insertionAlign, other.insertionAlign, t),
      insertionDescend:
          _lerpDuration(insertionDescend, other.insertionDescend, t),
      insertionLatch: _lerpDuration(insertionLatch, other.insertionLatch, t),
      insertionLaunchDelay:
          _lerpDuration(insertionLaunchDelay, other.insertionLaunchDelay, t),
      detailsHero: _lerpDuration(detailsHero, other.detailsHero, t),
      ambientFloat: _lerpDuration(ambientFloat, other.ambientFloat, t),
      movementCurve: t < 0.5 ? movementCurve : other.movementCurve,
      pressCurve: t < 0.5 ? pressCurve : other.pressCurve,
      descentCurve: t < 0.5 ? descentCurve : other.descentCurve,
      ambientFloatAmplitude: ambientFloatAmplitude +
          (other.ambientFloatAmplitude - ambientFloatAmplitude) * t,
    );
  }

  static Duration _lerpDuration(Duration a, Duration b, double t) => Duration(
        microseconds:
            (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
                .round(),
      );
}
