import 'package:flutter/material.dart';

@immutable
final class AveluneMaterialTokens
    extends ThemeExtension<AveluneMaterialTokens> {
  const AveluneMaterialTokens({
    required this.absGrainOpacity,
    required this.consoleGrainOpacity,
    required this.cartridgeWearOpacity,
    required this.consoleWearOpacity,
    required this.glassHighlightOpacity,
    required this.woodGrainOpacity,
    required this.ivoryPatinaOpacity,
    required this.brassReflectionOpacity,
  });

  static const double defaultAbsGrainOpacity = 0.18;
  static const double defaultConsoleGrainOpacity = 0.28;
  static const double defaultCartridgeWearOpacity = 0.86;
  static const double defaultConsoleWearOpacity = 0.72;

  static const AveluneMaterialTokens standard = AveluneMaterialTokens(
    absGrainOpacity: defaultAbsGrainOpacity,
    consoleGrainOpacity: defaultConsoleGrainOpacity,
    cartridgeWearOpacity: defaultCartridgeWearOpacity,
    consoleWearOpacity: defaultConsoleWearOpacity,
    glassHighlightOpacity: 0.18,
    woodGrainOpacity: 0.92,
    ivoryPatinaOpacity: 0.34,
    brassReflectionOpacity: 0.82,
  );

  final double absGrainOpacity;
  final double consoleGrainOpacity;
  final double cartridgeWearOpacity;
  final double consoleWearOpacity;
  final double glassHighlightOpacity;
  final double woodGrainOpacity;
  final double ivoryPatinaOpacity;
  final double brassReflectionOpacity;

  Map<String, double> get values => <String, double>{
        'absGrainOpacity': absGrainOpacity,
        'consoleGrainOpacity': consoleGrainOpacity,
        'cartridgeWearOpacity': cartridgeWearOpacity,
        'consoleWearOpacity': consoleWearOpacity,
        'glassHighlightOpacity': glassHighlightOpacity,
        'woodGrainOpacity': woodGrainOpacity,
        'ivoryPatinaOpacity': ivoryPatinaOpacity,
        'brassReflectionOpacity': brassReflectionOpacity,
      };

  @override
  AveluneMaterialTokens copyWith({
    double? absGrainOpacity,
    double? consoleGrainOpacity,
    double? cartridgeWearOpacity,
    double? consoleWearOpacity,
    double? glassHighlightOpacity,
    double? woodGrainOpacity,
    double? ivoryPatinaOpacity,
    double? brassReflectionOpacity,
  }) =>
      AveluneMaterialTokens(
        absGrainOpacity: absGrainOpacity ?? this.absGrainOpacity,
        consoleGrainOpacity: consoleGrainOpacity ?? this.consoleGrainOpacity,
        cartridgeWearOpacity: cartridgeWearOpacity ?? this.cartridgeWearOpacity,
        consoleWearOpacity: consoleWearOpacity ?? this.consoleWearOpacity,
        glassHighlightOpacity:
            glassHighlightOpacity ?? this.glassHighlightOpacity,
        woodGrainOpacity: woodGrainOpacity ?? this.woodGrainOpacity,
        ivoryPatinaOpacity: ivoryPatinaOpacity ?? this.ivoryPatinaOpacity,
        brassReflectionOpacity:
            brassReflectionOpacity ?? this.brassReflectionOpacity,
      );

  @override
  AveluneMaterialTokens lerp(
    covariant AveluneMaterialTokens? other,
    double t,
  ) {
    if (other == null || t <= 0) return this;
    if (t >= 1) return other;
    return AveluneMaterialTokens(
      absGrainOpacity: _lerpDouble(absGrainOpacity, other.absGrainOpacity, t),
      consoleGrainOpacity:
          _lerpDouble(consoleGrainOpacity, other.consoleGrainOpacity, t),
      cartridgeWearOpacity:
          _lerpDouble(cartridgeWearOpacity, other.cartridgeWearOpacity, t),
      consoleWearOpacity:
          _lerpDouble(consoleWearOpacity, other.consoleWearOpacity, t),
      glassHighlightOpacity:
          _lerpDouble(glassHighlightOpacity, other.glassHighlightOpacity, t),
      woodGrainOpacity:
          _lerpDouble(woodGrainOpacity, other.woodGrainOpacity, t),
      ivoryPatinaOpacity:
          _lerpDouble(ivoryPatinaOpacity, other.ivoryPatinaOpacity, t),
      brassReflectionOpacity: _lerpDouble(
        brassReflectionOpacity,
        other.brassReflectionOpacity,
        t,
      ),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
