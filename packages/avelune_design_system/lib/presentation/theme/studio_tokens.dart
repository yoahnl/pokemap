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

abstract final class StudioPokemonTypeColors {
  static const normal = Color(0xff8192a7);
  static const fire = Color(0xffe7754b);
  static const water = Color(0xff338edb);
  static const electric = Color(0xffd6a633);
  static const grass = Color(0xff48a978);
  static const ice = Color(0xff54b5c7);
  static const fighting = Color(0xffc96859);
  static const poison = Color(0xffa56bc6);
  static const ground = Color(0xffb58a5b);
  static const flying = Color(0xff779acb);
  static const psychic = Color(0xffd46c9a);
  static const bug = Color(0xff8eaa54);
  static const rock = Color(0xffab9876);
  static const ghost = Color(0xff8078bd);
  static const dragon = Color(0xff6276cf);
  static const dark = Color(0xff726b8b);
  static const steel = Color(0xff829eaa);
  static const fairy = Color(0xffd489b9);

  static Color forType(String? type, Color fallback) =>
      switch (type?.trim().toLowerCase()) {
        'normal' => normal,
        'fire' => fire,
        'water' => water,
        'electric' => electric,
        'grass' || 'plant' => grass,
        'ice' => ice,
        'fighting' => fighting,
        'poison' => poison,
        'ground' => ground,
        'flying' => flying,
        'psychic' => psychic,
        'bug' => bug,
        'rock' => rock,
        'ghost' => ghost,
        'dragon' => dragon,
        'dark' => dark,
        'steel' => steel,
        'fairy' => fairy,
        _ => fallback,
      };
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
