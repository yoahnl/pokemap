import 'package:flutter/material.dart';
import 'studio_tokens.dart';

ThemeData studioTheme() {
  const colors = ColorScheme.dark(
    primary: Color(0xff2163df),
    onPrimary: Color(0xffedf4ff),
    primaryContainer: Color(0xff173e70),
    onPrimaryContainer: Color(0xffedf3ff),
    secondary: Color(0xffa4b5d2),
    secondaryContainer: Color(0xff233b5e),
    onSecondaryContainer: Color(0xffedf3ff),
    surface: Color(0xff0d1d2c),
    surfaceContainerLowest: Color(0xff071522),
    surfaceContainerLow: Color(0xff0a1928),
    surfaceContainer: Color(0xff14283b),
    surfaceContainerHigh: Color(0xff1b3249),
    surfaceContainerHighest: Color(0xff263e55),
    onSurface: Color(0xffedf4ff),
    onSurfaceVariant: Color(0xffa4b7cd),
    outline: Color(0xff29445f),
    outlineVariant: Color(0xff20364b),
    error: Color(0xffe45c69),
    errorContainer: Color(0xff492b34),
    onErrorContainer: Color(0xffffdad6),
    tertiary: Color(0xff25c49a),
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
  );
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surfaceContainerLowest,
    fontFamily: 'Helvetica Neue',
    visualDensity: VisualDensity.compact,
  );
  final text = base.textTheme.apply(
    bodyColor: colors.onSurface,
    displayColor: colors.onSurface,
  );
  final button = ButtonStyle(
    visualDensity: VisualDensity.standard,
    minimumSize: const WidgetStatePropertyAll(
      Size(0, StudioMetrics.controlHeight),
    ),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    ),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    shape: WidgetStatePropertyAll(shape),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevation: const WidgetStatePropertyAll(0),
    animationDuration: const Duration(milliseconds: 100),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return colors.primary.withValues(alpha: .20);
      }
      if (states.contains(WidgetState.hovered)) {
        return colors.primary.withValues(alpha: .10);
      }
      return null;
    }),
    side: WidgetStateProperty.resolveWith(
      (states) => BorderSide(
        color: states.contains(WidgetState.focused)
            ? colors.onSurface
            : colors.outline,
        width: states.contains(WidgetState.focused) ? 2 : 1,
      ),
    ),
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
    borderSide: BorderSide(color: colors.outline),
  );
  return base.copyWith(
    extensions: const [StudioColors()],
    textTheme: text.copyWith(
      bodyLarge: text.bodyLarge?.copyWith(fontSize: 14),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 14),
      bodySmall: text.bodySmall?.copyWith(
        fontSize: 12,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: text.labelLarge?.copyWith(fontSize: 13),
      labelMedium: text.labelMedium?.copyWith(fontSize: 12),
      titleLarge: text.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: text.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: text.titleSmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    ),
    iconTheme: IconThemeData(size: 18, color: colors.onSurfaceVariant),
    dividerTheme: DividerThemeData(
      color: colors.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    focusColor: colors.primary.withValues(alpha: .18),
    hoverColor: colors.primary.withValues(alpha: .08),
    splashFactory: NoSplash.splashFactory,
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: colors.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      hintStyle: TextStyle(
        fontFamily: 'Helvetica Neue',
        color: colors.onSurfaceVariant,
        fontSize: 12,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: button.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.surfaceContainerHigh
              : colors.primary,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.onSurfaceVariant.withValues(alpha: .45)
              : colors.onPrimary,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: button.copyWith(
        backgroundColor: WidgetStatePropertyAll(colors.surfaceContainer),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.onSurfaceVariant.withValues(alpha: .45)
              : colors.onSurface,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: button.copyWith(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.onSurfaceVariant.withValues(alpha: .45)
              : colors.onSurface,
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? BorderSide(color: colors.primary, width: 2)
              : BorderSide.none,
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      textStyle: TextStyle(
        fontFamily: 'Helvetica Neue',
        color: colors.onSurface,
        fontSize: 12,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outline),
      ),
      titleTextStyle: text.titleMedium,
      contentTextStyle: text.bodyMedium,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(color: colors.outline),
      ),
      textStyle: text.bodyMedium,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(3),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? colors.primary
            : colors.outline,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
  );
}
