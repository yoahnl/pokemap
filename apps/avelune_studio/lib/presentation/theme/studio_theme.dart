import 'package:flutter/material.dart';

ThemeData studioTheme() {
  const colors = ColorScheme.dark(
    primary: Color(0xff82a5ff),
    onPrimary: Color(0xff0a1427),
    primaryContainer: Color(0xff254881),
    onPrimaryContainer: Color(0xffedf3ff),
    secondary: Color(0xffa4b5d2),
    secondaryContainer: Color(0xff233b5e),
    onSecondaryContainer: Color(0xffedf3ff),
    surface: Color(0xff111d2e),
    surfaceContainerLowest: Color(0xff09111d),
    surfaceContainerLow: Color(0xff0d1624),
    surfaceContainer: Color(0xff172438),
    surfaceContainerHigh: Color(0xff22324a),
    surfaceContainerHighest: Color(0xff2c3c54),
    onSurface: Color(0xffe8edf7),
    onSurfaceVariant: Color(0xffa6b4cc),
    outline: Color(0xff3a4b64),
    outlineVariant: Color(0xff28374c),
    error: Color(0xffffb4ab),
    errorContainer: Color(0xff492b34),
    onErrorContainer: Color(0xffffdad6),
    tertiary: Color(0xff79d2b4),
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(5));
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
    minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
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
    borderRadius: BorderRadius.circular(5),
    borderSide: BorderSide(color: colors.outline),
  );
  return base.copyWith(
    textTheme: text.copyWith(
      bodyLarge: text.bodyLarge?.copyWith(fontSize: 14),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 13),
      bodySmall: text.bodySmall?.copyWith(
        fontSize: 12,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: text.labelLarge?.copyWith(fontSize: 13),
      labelMedium: text.labelMedium?.copyWith(fontSize: 12),
      titleLarge: text.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: text.titleMedium?.copyWith(
        fontSize: 14,
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
      fillColor: colors.surfaceContainerLow,
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
              : colors.primaryContainer,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.onSurfaceVariant.withValues(alpha: .45)
              : colors.onPrimaryContainer,
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
