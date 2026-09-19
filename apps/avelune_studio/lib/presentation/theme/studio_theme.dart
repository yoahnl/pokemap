import 'package:flutter/material.dart';

ThemeData studioTheme() {
  const background = Color(0xff11151d);
  const surface = Color(0xff1b2230);
  const outline = Color(0xff414e62);
  const primary = Color(0xffb4c8ff);
  const text = Color(0xffeff3fa);
  const muted = Color(0xffb7c0cf);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: background,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: muted,
      outline: outline,
      error: Color(0xffffb4ab),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        shape: WidgetStatePropertyAll(shape),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? const BorderSide(color: text, width: 3)
              : BorderSide.none,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        shape: WidgetStatePropertyAll(shape),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.focused) ? primary : outline,
            width: states.contains(WidgetState.focused) ? 2 : 1,
          ),
        ),
      ),
    ),
  );
}
