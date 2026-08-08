import 'dart:math' as math;

import 'package:flutter/material.dart';

final class RmxpHueFilter {
  const RmxpHueFilter._();

  static const List<double> identityMatrix = <double>[
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static List<double> matrixForHue(int hueDegrees) {
    final normalized = hueDegrees % 360;
    if (normalized == 0) {
      return identityMatrix;
    }

    final radians = normalized * math.pi / 180.0;
    final cosValue = math.cos(radians);
    final sinValue = math.sin(radians);

    // RGSS hue changes rotate RGB around the luminance vector. This matrix is
    // the standard luma-preserving hue rotation used by image renderers.
    return <double>[
      0.213 + cosValue * 0.787 - sinValue * 0.213,
      0.715 - cosValue * 0.715 - sinValue * 0.715,
      0.072 - cosValue * 0.072 + sinValue * 0.928,
      0,
      0,
      0.213 - cosValue * 0.213 + sinValue * 0.143,
      0.715 + cosValue * 0.285 + sinValue * 0.140,
      0.072 - cosValue * 0.072 - sinValue * 0.283,
      0,
      0,
      0.213 - cosValue * 0.213 - sinValue * 0.787,
      0.715 - cosValue * 0.715 + sinValue * 0.715,
      0.072 + cosValue * 0.928 + sinValue * 0.072,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static final Map<int, ColorFilter> _filterByNormalizedHue =
      <int, ColorFilter>{};

  static ColorFilter? colorFilterForHue(int hueDegrees) {
    final normalized = hueDegrees % 360;
    if (normalized == 0) {
      return null;
    }
    // La matrice est périodique sur 360° : au plus 359 filtres distincts,
    // construits une fois au lieu d'une liste de 20 doubles par cellule
    // rendue par frame.
    return _filterByNormalizedHue[normalized] ??=
        ColorFilter.matrix(matrixForHue(normalized));
  }
}
