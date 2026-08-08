import 'package:flutter/material.dart';

@immutable
final class AveluneColors extends ThemeExtension<AveluneColors> {
  const AveluneColors({
    required this.canvas,
    required this.room,
    required this.glass,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceInset,
    required this.outline,
    required this.focus,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentBright,
    required this.glow,
    required this.brass,
    required this.success,
    required this.warning,
    required this.error,
    required this.shellNeutral,
    required this.shellHighlight,
    required this.wood,
    required this.woodHighlight,
    required this.ivory,
    required this.ivoryHighlight,
  });

  static const AveluneColors standard = AveluneColors(
    canvas: Color(0xFF07070A),
    room: Color(0xFF0D0B12),
    glass: Color(0xFF17131D),
    surface: Color(0xFF111116),
    surfaceRaised: Color(0xFF19171E),
    surfaceInset: Color(0xFF0B0A0E),
    outline: Color(0xFF453C4D),
    focus: Color(0xFFB481FF),
    textPrimary: Color(0xFFF6EFE4),
    textSecondary: Color(0xFFA9A2B0),
    accent: Color(0xFF7137DA),
    accentBright: Color(0xFFA66AFF),
    glow: Color(0xFF6D28D9),
    brass: Color(0xFFD8A64B),
    success: Color(0xFF73D69C),
    warning: Color(0xFFF0B85B),
    error: Color(0xFFE47777),
    shellNeutral: Color(0xFF211A2C),
    shellHighlight: Color(0xFF51346F),
    wood: Color(0xFF29170F),
    woodHighlight: Color(0xFF6A4028),
    ivory: Color(0xFFD8D0C2),
    ivoryHighlight: Color(0xFFF2ECE1),
  );

  final Color canvas;
  final Color room;
  final Color glass;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceInset;
  final Color outline;
  final Color focus;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color accentBright;
  final Color glow;
  final Color brass;
  final Color success;
  final Color warning;
  final Color error;
  final Color shellNeutral;
  final Color shellHighlight;
  final Color wood;
  final Color woodHighlight;
  final Color ivory;
  final Color ivoryHighlight;

  Color get background => canvas;
  Color get surfaceElevated => surfaceRaised;
  Color get primary => accent;
  Color get primaryBright => accentBright;
  Color get gold => brass;
  Color get shell => shellNeutral;
  Color get invalid => error;

  Map<String, Color> get values => <String, Color>{
        'canvas': canvas,
        'room': room,
        'glass': glass,
        'surface': surface,
        'surfaceRaised': surfaceRaised,
        'surfaceInset': surfaceInset,
        'outline': outline,
        'focus': focus,
        'textPrimary': textPrimary,
        'textSecondary': textSecondary,
        'accent': accent,
        'accentBright': accentBright,
        'glow': glow,
        'brass': brass,
        'success': success,
        'warning': warning,
        'error': error,
        'shellNeutral': shellNeutral,
        'shellHighlight': shellHighlight,
        'wood': wood,
        'woodHighlight': woodHighlight,
        'ivory': ivory,
        'ivoryHighlight': ivoryHighlight,
      };

  @override
  AveluneColors copyWith({
    Color? canvas,
    Color? room,
    Color? glass,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceInset,
    Color? outline,
    Color? focus,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? accentBright,
    Color? glow,
    Color? brass,
    Color? success,
    Color? warning,
    Color? error,
    Color? shellNeutral,
    Color? shellHighlight,
    Color? wood,
    Color? woodHighlight,
    Color? ivory,
    Color? ivoryHighlight,
    Color? background,
    Color? surfaceElevated,
    Color? primary,
    Color? primaryBright,
    Color? gold,
    Color? shell,
    Color? invalid,
  }) =>
      AveluneColors(
        canvas: canvas ?? background ?? this.canvas,
        room: room ?? this.room,
        glass: glass ?? this.glass,
        surface: surface ?? this.surface,
        surfaceRaised: surfaceRaised ?? surfaceElevated ?? this.surfaceRaised,
        surfaceInset: surfaceInset ?? this.surfaceInset,
        outline: outline ?? this.outline,
        focus: focus ?? this.focus,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        accent: accent ?? primary ?? this.accent,
        accentBright: accentBright ?? primaryBright ?? this.accentBright,
        glow: glow ?? this.glow,
        brass: brass ?? gold ?? this.brass,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        error: error ?? invalid ?? this.error,
        shellNeutral: shellNeutral ?? shell ?? this.shellNeutral,
        shellHighlight: shellHighlight ?? this.shellHighlight,
        wood: wood ?? this.wood,
        woodHighlight: woodHighlight ?? this.woodHighlight,
        ivory: ivory ?? this.ivory,
        ivoryHighlight: ivoryHighlight ?? this.ivoryHighlight,
      );

  @override
  AveluneColors lerp(covariant AveluneColors? other, double t) {
    if (other == null || t <= 0) return this;
    if (t >= 1) return other;
    return AveluneColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      room: Color.lerp(room, other.room, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceInset: Color.lerp(surfaceInset, other.surfaceInset, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentBright: Color.lerp(accentBright, other.accentBright, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      brass: Color.lerp(brass, other.brass, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      shellNeutral: Color.lerp(shellNeutral, other.shellNeutral, t)!,
      shellHighlight: Color.lerp(shellHighlight, other.shellHighlight, t)!,
      wood: Color.lerp(wood, other.wood, t)!,
      woodHighlight: Color.lerp(woodHighlight, other.woodHighlight, t)!,
      ivory: Color.lerp(ivory, other.ivory, t)!,
      ivoryHighlight: Color.lerp(ivoryHighlight, other.ivoryHighlight, t)!,
    );
  }
}

Color aveluneCabinFinishColor(AveluneColors colors, String id) => switch (id) {
      'ivory' => colors.ivory,
      'oak' => Color.lerp(colors.woodHighlight, colors.ivory, 0.3)!,
      'ash' => Color.lerp(colors.surfaceRaised, colors.ivory, 0.26)!,
      'mahogany' => Color.lerp(colors.wood, colors.accent, 0.18)!,
      'ebony' => colors.canvas,
      _ => colors.wood,
    };
