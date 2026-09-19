import 'package:flutter/material.dart';

abstract final class StudioMetrics {
  static const double controlRadius = 6;
  static const double panelRadius = 8;
  static const double controlHeight = 36;
  static const double compactControlHeight = 32;
  static const double panelPadding = 16;
  static const double gap = 12;
  static const double navigationWidth = 176;
  static const double compactNavigationWidth = 104;
}

@immutable
class StudioColors extends ThemeExtension<StudioColors> {
  const StudioColors({
    this.canvasSelection = const Color(0xff3bcef5),
    this.success = const Color(0xff25c49a),
    this.warning = const Color(0xfff1be58),
    this.featureAccent = const Color(0xff8256e8),
  });

  final Color canvasSelection, success, warning, featureAccent;

  static StudioColors of(BuildContext context) =>
      Theme.of(context).extension<StudioColors>() ?? const StudioColors();

  @override
  StudioColors copyWith({
    Color? canvasSelection,
    Color? success,
    Color? warning,
    Color? featureAccent,
  }) => StudioColors(
    canvasSelection: canvasSelection ?? this.canvasSelection,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    featureAccent: featureAccent ?? this.featureAccent,
  );

  @override
  StudioColors lerp(StudioColors? other, double t) => other == null
      ? this
      : StudioColors(
          canvasSelection: Color.lerp(
            canvasSelection,
            other.canvasSelection,
            t,
          )!,
          success: Color.lerp(success, other.success, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
          featureAccent: Color.lerp(featureAccent, other.featureAccent, t)!,
        );
}
