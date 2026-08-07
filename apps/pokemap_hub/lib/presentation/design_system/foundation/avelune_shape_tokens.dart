import 'package:flutter/widgets.dart';

abstract final class AveluneShapes {
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusPill = 999;
  static const double focusStroke = 2;
  static const double minimumTouchTarget = 48;

  static const List<double> radii = <double>[
    radiusXs,
    radiusSm,
    radiusMd,
    radiusLg,
    radiusXl,
  ];

  static const BorderRadius xs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius md = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius pill =
      BorderRadius.all(Radius.circular(radiusPill));
}
