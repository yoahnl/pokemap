import 'package:flutter/material.dart';

abstract final class PokeMapPlayerProjectColorResolver {
  static Color? tryHex(String? source) {
    if (source == null ||
        !RegExp(r'^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$').hasMatch(source)) {
      return null;
    }
    final hex = source.substring(1);
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Color.fromARGB(
      int.parse(hex.substring(6, 8), radix: 16),
      int.parse(hex.substring(0, 2), radix: 16),
      int.parse(hex.substring(2, 4), radix: 16),
      int.parse(hex.substring(4, 6), radix: 16),
    );
  }

  static Color? tryOpaqueHex(String? source) {
    if (source == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(source)) {
      return null;
    }
    return Color(int.parse('FF${source.substring(1)}', radix: 16));
  }
}

@immutable
final class PokeMapPlayerColors extends ThemeExtension<PokeMapPlayerColors> {
  const PokeMapPlayerColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.primary,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.success,
    required this.warning,
    required this.danger,
    required this.focus,
    required this.scrim,
    required this.highContrast,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color primary;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
  final Color success;
  final Color warning;
  final Color danger;
  final Color focus;
  final Color scrim;
  final bool highContrast;

  @override
  PokeMapPlayerColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? primary,
    Color? onPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? outline,
    Color? success,
    Color? warning,
    Color? danger,
    Color? focus,
    Color? scrim,
    bool? highContrast,
  }) =>
      PokeMapPlayerColors(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceElevated: surfaceElevated ?? this.surfaceElevated,
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        outline: outline ?? this.outline,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        focus: focus ?? this.focus,
        scrim: scrim ?? this.scrim,
        highContrast: highContrast ?? this.highContrast,
      );

  @override
  PokeMapPlayerColors lerp(
    covariant ThemeExtension<PokeMapPlayerColors>? other,
    double t,
  ) {
    if (other is! PokeMapPlayerColors) return this;
    return PokeMapPlayerColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      highContrast: t < 0.5 ? highContrast : other.highContrast,
    );
  }
}

@immutable
final class PokeMapPlayerSemanticTheme
    extends ThemeExtension<PokeMapPlayerSemanticTheme> {
  const PokeMapPlayerSemanticTheme({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.success,
    required this.warning,
    required this.danger,
    required this.titleSurface,
    required this.dialogueSurface,
    required this.menuSurface,
    required this.overworldHudSurface,
    required this.battleHudSurface,
  });

  factory PokeMapPlayerSemanticTheme.fromPlayerColors(
    PokeMapPlayerColors colors,
  ) =>
      PokeMapPlayerSemanticTheme(
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        background: colors.background,
        surface: colors.surface,
        surfaceElevated: colors.surfaceElevated,
        textPrimary: colors.textPrimary,
        textSecondary: colors.textSecondary,
        outline: colors.outline,
        success: colors.success,
        warning: colors.warning,
        danger: colors.danger,
        titleSurface: colors.surfaceElevated,
        dialogueSurface: colors.surfaceElevated,
        menuSurface: colors.surfaceElevated,
        overworldHudSurface: colors.surface,
        battleHudSurface: colors.surfaceElevated,
      );

  static PokeMapPlayerSemanticTheme? tryFromHex({
    required String primary,
    required String onPrimary,
    required String background,
    required String surface,
    required String surfaceElevated,
    required String textPrimary,
    required String textSecondary,
    required String outline,
    required String success,
    required String warning,
    required String danger,
    required String titleSurface,
    required String dialogueSurface,
    required String menuSurface,
    required String overworldHudSurface,
    required String battleHudSurface,
  }) {
    final values = <String>[
      primary,
      onPrimary,
      background,
      surface,
      surfaceElevated,
      textPrimary,
      textSecondary,
      outline,
      success,
      warning,
      danger,
      titleSurface,
      dialogueSurface,
      menuSurface,
      overworldHudSurface,
      battleHudSurface,
    ]
        .map(PokeMapPlayerProjectColorResolver.tryOpaqueHex)
        .toList(growable: false);
    if (values.any((color) => color == null)) return null;
    return PokeMapPlayerSemanticTheme(
      primary: values[0]!,
      onPrimary: values[1]!,
      background: values[2]!,
      surface: values[3]!,
      surfaceElevated: values[4]!,
      textPrimary: values[5]!,
      textSecondary: values[6]!,
      outline: values[7]!,
      success: values[8]!,
      warning: values[9]!,
      danger: values[10]!,
      titleSurface: values[11]!,
      dialogueSurface: values[12]!,
      menuSurface: values[13]!,
      overworldHudSurface: values[14]!,
      battleHudSurface: values[15]!,
    );
  }

  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
  final Color success;
  final Color warning;
  final Color danger;
  final Color titleSurface;
  final Color dialogueSurface;
  final Color menuSurface;
  final Color overworldHudSurface;
  final Color battleHudSurface;

  @override
  PokeMapPlayerSemanticTheme copyWith({
    Color? primary,
    Color? onPrimary,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? outline,
    Color? success,
    Color? warning,
    Color? danger,
    Color? titleSurface,
    Color? dialogueSurface,
    Color? menuSurface,
    Color? overworldHudSurface,
    Color? battleHudSurface,
  }) =>
      PokeMapPlayerSemanticTheme(
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceElevated: surfaceElevated ?? this.surfaceElevated,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        outline: outline ?? this.outline,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        titleSurface: titleSurface ?? this.titleSurface,
        dialogueSurface: dialogueSurface ?? this.dialogueSurface,
        menuSurface: menuSurface ?? this.menuSurface,
        overworldHudSurface: overworldHudSurface ?? this.overworldHudSurface,
        battleHudSurface: battleHudSurface ?? this.battleHudSurface,
      );

  @override
  PokeMapPlayerSemanticTheme lerp(
    covariant ThemeExtension<PokeMapPlayerSemanticTheme>? other,
    double t,
  ) {
    if (other is! PokeMapPlayerSemanticTheme) return this;
    return PokeMapPlayerSemanticTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      titleSurface: Color.lerp(titleSurface, other.titleSurface, t)!,
      dialogueSurface: Color.lerp(dialogueSurface, other.dialogueSurface, t)!,
      menuSurface: Color.lerp(menuSurface, other.menuSurface, t)!,
      overworldHudSurface:
          Color.lerp(overworldHudSurface, other.overworldHudSurface, t)!,
      battleHudSurface:
          Color.lerp(battleHudSurface, other.battleHudSurface, t)!,
    );
  }
}

@immutable
final class PokeMapPlayerMotion extends ThemeExtension<PokeMapPlayerMotion> {
  const PokeMapPlayerMotion({
    required this.fast,
    required this.standard,
    required this.slow,
  });

  final Duration fast;
  final Duration standard;
  final Duration slow;

  static const reduced = PokeMapPlayerMotion(
    fast: Duration.zero,
    standard: Duration.zero,
    slow: Duration.zero,
  );

  @override
  PokeMapPlayerMotion copyWith({
    Duration? fast,
    Duration? standard,
    Duration? slow,
  }) =>
      PokeMapPlayerMotion(
        fast: fast ?? this.fast,
        standard: standard ?? this.standard,
        slow: slow ?? this.slow,
      );

  @override
  PokeMapPlayerMotion lerp(
    covariant ThemeExtension<PokeMapPlayerMotion>? other,
    double t,
  ) =>
      t < 0.5 || other is! PokeMapPlayerMotion ? this : other;
}

@immutable
final class PokeMapPlayerTypography
    extends ThemeExtension<PokeMapPlayerTypography> {
  const PokeMapPlayerTypography({
    this.displayFamily,
    this.displayFallback = const <String>['sans-serif'],
    this.bodyFamily,
    this.bodyFallback = const <String>['sans-serif'],
    this.dialogueFamily,
    this.dialogueFallback = const <String>['sans-serif'],
    this.numbersFamily,
    this.numbersFallback = const <String>['monospace'],
  });

  final String? displayFamily;
  final List<String> displayFallback;
  final String? bodyFamily;
  final List<String> bodyFallback;
  final String? dialogueFamily;
  final List<String> dialogueFallback;
  final String? numbersFamily;
  final List<String> numbersFallback;

  TextStyle displayStyle(TextStyle base) => base.copyWith(
        fontFamily: displayFamily,
        fontFamilyFallback: displayFallback,
      );

  TextStyle bodyStyle(TextStyle base) => base.copyWith(
        fontFamily: bodyFamily,
        fontFamilyFallback: bodyFallback,
      );

  TextStyle dialogueStyle(TextStyle base) => base.copyWith(
        fontFamily: dialogueFamily,
        fontFamilyFallback: dialogueFallback,
      );

  TextStyle numbersStyle(TextStyle base) => base.copyWith(
        fontFamily: numbersFamily,
        fontFamilyFallback: numbersFallback,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      );

  @override
  PokeMapPlayerTypography copyWith({
    String? displayFamily,
    List<String>? displayFallback,
    String? bodyFamily,
    List<String>? bodyFallback,
    String? dialogueFamily,
    List<String>? dialogueFallback,
    String? numbersFamily,
    List<String>? numbersFallback,
  }) =>
      PokeMapPlayerTypography(
        displayFamily: displayFamily ?? this.displayFamily,
        displayFallback: displayFallback ?? this.displayFallback,
        bodyFamily: bodyFamily ?? this.bodyFamily,
        bodyFallback: bodyFallback ?? this.bodyFallback,
        dialogueFamily: dialogueFamily ?? this.dialogueFamily,
        dialogueFallback: dialogueFallback ?? this.dialogueFallback,
        numbersFamily: numbersFamily ?? this.numbersFamily,
        numbersFallback: numbersFallback ?? this.numbersFallback,
      );

  @override
  PokeMapPlayerTypography lerp(
    covariant ThemeExtension<PokeMapPlayerTypography>? other,
    double t,
  ) =>
      t < 0.5 || other is! PokeMapPlayerTypography ? this : other;
}

abstract final class PlayerSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class PlayerRadii {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 28;
  static const double pill = 999;
}

abstract final class PokeMapPlayerTheme {
  static ThemeData light({
    bool highContrast = false,
    bool reducedMotion = false,
  }) =>
      _theme(
        brightness: Brightness.light,
        highContrast: highContrast,
        reducedMotion: reducedMotion,
      );

  static ThemeData dark({
    bool highContrast = false,
    bool reducedMotion = false,
  }) =>
      _theme(
        brightness: Brightness.dark,
        highContrast: highContrast,
        reducedMotion: reducedMotion,
      );

  /// Projects runtime accessibility preferences without discarding authored
  /// project colors or typography.
  static ThemeData withAccessibility(
    ThemeData theme, {
    required bool highContrast,
    required bool reducedMotion,
  }) {
    final baseColors = theme.extension<PokeMapPlayerColors>();
    if (baseColors == null) return theme;
    final contrastOutline = theme.brightness == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);
    final colors = baseColors.copyWith(
      outline: highContrast ? contrastOutline : baseColors.outline,
      highContrast: highContrast,
    );
    final baseSemantic = theme.extension<PokeMapPlayerSemanticTheme>();
    final semantic = baseSemantic?.copyWith(outline: colors.outline);
    final extensions = theme.extensions.values
        .where(
          (extension) =>
              extension is! PokeMapPlayerColors &&
              extension is! PokeMapPlayerMotion &&
              extension is! PokeMapPlayerSemanticTheme,
        )
        .toList(growable: true)
      ..add(colors)
      ..add(
        reducedMotion
            ? PokeMapPlayerMotion.reduced
            : theme.extension<PokeMapPlayerMotion>() ??
                const PokeMapPlayerMotion(
                  fast: Duration(milliseconds: 120),
                  standard: Duration(milliseconds: 220),
                  slow: Duration(milliseconds: 420),
                ),
      );
    if (semantic != null) extensions.add(semantic);
    return theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(outline: colors.outline),
      extensions: extensions,
      focusColor: colors.focus,
    );
  }

  static ThemeData withTypography(
    ThemeData theme,
    PokeMapPlayerTypography typography,
  ) {
    final extensions = theme.extensions.values
        .where((extension) => extension is! PokeMapPlayerTypography)
        .toList(growable: true)
      ..add(typography);
    return theme.copyWith(extensions: extensions);
  }

  static ThemeData withSemanticTheme(
    ThemeData theme,
    PokeMapPlayerSemanticTheme semantic,
  ) {
    final baseColors = theme.extension<PokeMapPlayerColors>();
    if (baseColors == null) return theme;
    final colors = baseColors.copyWith(
      background: semantic.background,
      surface: semantic.surface,
      surfaceElevated: semantic.surfaceElevated,
      primary: semantic.primary,
      onPrimary: semantic.onPrimary,
      textPrimary: semantic.textPrimary,
      textSecondary: semantic.textSecondary,
      outline: semantic.outline,
      success: semantic.success,
      warning: semantic.warning,
      danger: semantic.danger,
    );
    final extensions = theme.extensions.values
        .where(
          (extension) =>
              extension is! PokeMapPlayerColors &&
              extension is! PokeMapPlayerSemanticTheme,
        )
        .toList(growable: true)
      ..add(colors)
      ..add(semantic);
    final colorScheme = theme.colorScheme.copyWith(
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      secondary: colors.success,
      onSecondary: colors.background,
      error: colors.danger,
      onError: colors.background,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      outline: colors.outline,
      inverseSurface: colors.textPrimary,
      onInverseSurface: colors.background,
      inversePrimary: colors.primary,
      surfaceTint: colors.primary,
    );
    final textTheme = theme.textTheme.copyWith(
      displaySmall:
          theme.textTheme.displaySmall?.copyWith(color: colors.textPrimary),
      headlineMedium:
          theme.textTheme.headlineMedium?.copyWith(color: colors.textPrimary),
      titleLarge:
          theme.textTheme.titleLarge?.copyWith(color: colors.textPrimary),
      bodyLarge: theme.textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
      bodyMedium:
          theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
    );
    return theme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: textTheme,
      extensions: extensions,
      disabledColor: colors.textSecondary.withValues(alpha: 0.45),
      cardTheme: theme.cardTheme.copyWith(color: colors.surface),
      navigationRailTheme: theme.navigationRailTheme.copyWith(
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withValues(alpha: 0.18),
        selectedIconTheme: IconThemeData(color: colors.primary),
        selectedLabelTextStyle:
            textTheme.labelLarge?.copyWith(color: colors.primary),
      ),
      navigationBarTheme: theme.navigationBarTheme.copyWith(
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withValues(alpha: 0.18),
      ),
    );
  }

  static ThemeData _theme({
    required Brightness brightness,
    required bool highContrast,
    required bool reducedMotion,
  }) {
    final isDark = brightness == Brightness.dark;
    final colors = PokeMapPlayerColors(
      background: isDark ? const Color(0xFF080C16) : const Color(0xFFF4F7FB),
      surface: isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF),
      surfaceElevated:
          isDark ? const Color(0xFF192235) : const Color(0xFFEAF0F8),
      primary: isDark ? const Color(0xFF78DCE8) : const Color(0xFF086D7A),
      onPrimary: isDark ? const Color(0xFF062D34) : const Color(0xFFFFFFFF),
      textPrimary: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF101827),
      textSecondary: isDark ? const Color(0xFFB8C3D6) : const Color(0xFF526176),
      outline: highContrast
          ? (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
          : (isDark ? const Color(0xFF46556C) : const Color(0xFFB7C2D0)),
      success: isDark ? const Color(0xFF70E0A1) : const Color(0xFF16794B),
      warning: isDark ? const Color(0xFFFFCB6B) : const Color(0xFF8A5100),
      danger: isDark ? const Color(0xFFFF8A9A) : const Color(0xFFB4233C),
      focus: isDark ? const Color(0xFFFFD166) : const Color(0xFF8A4B00),
      scrim: const Color(0xB3000000),
      highContrast: highContrast,
    );
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      secondary: colors.success,
      onSecondary: colors.background,
      error: colors.danger,
      onError: colors.background,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      outline: colors.outline,
      shadow: const Color(0x4D000000),
      scrim: colors.scrim,
      inverseSurface: colors.textPrimary,
      onInverseSurface: colors.background,
      inversePrimary: colors.primary,
      surfaceTint: colors.primary,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: 'Avenir Next',
      visualDensity: VisualDensity.standard,
    );
    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        color: colors.textPrimary,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: colors.textPrimary,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        height: 1.45,
        color: colors.textPrimary,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        height: 1.4,
        color: colors.textSecondary,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
    return base.copyWith(
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        colors,
        reducedMotion
            ? PokeMapPlayerMotion.reduced
            : const PokeMapPlayerMotion(
                fast: Duration(milliseconds: 120),
                standard: Duration(milliseconds: 220),
                slow: Duration(milliseconds: 420),
              ),
        const PokeMapPlayerTypography(),
        PokeMapPlayerSemanticTheme.fromPlayerColors(colors),
      ],
      focusColor: colors.focus,
      disabledColor: colors.textSecondary.withValues(alpha: 0.45),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlayerRadii.md),
          side: BorderSide(color: colors.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: PlayerSpacing.md,
            vertical: PlayerSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PlayerRadii.sm),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: PlayerSpacing.md,
            vertical: PlayerSpacing.sm,
          ),
          side: BorderSide(color: colors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PlayerRadii.sm),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withValues(alpha: 0.18),
        selectedIconTheme: IconThemeData(color: colors.primary),
        selectedLabelTextStyle:
            textTheme.labelLarge?.copyWith(color: colors.primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withValues(alpha: 0.18),
      ),
    );
  }
}

extension PlayerThemeContext on BuildContext {
  PokeMapPlayerColors get playerColors =>
      Theme.of(this).extension<PokeMapPlayerColors>()!;

  PokeMapPlayerMotion get playerMotion =>
      Theme.of(this).extension<PokeMapPlayerMotion>()!;

  PokeMapPlayerTypography get playerTypography =>
      Theme.of(this).extension<PokeMapPlayerTypography>() ??
      const PokeMapPlayerTypography();

  PokeMapPlayerSemanticTheme get playerSemanticTheme =>
      Theme.of(this).extension<PokeMapPlayerSemanticTheme>() ??
      PokeMapPlayerSemanticTheme.fromPlayerColors(playerColors);
}
