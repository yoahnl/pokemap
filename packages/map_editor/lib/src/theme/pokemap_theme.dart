import 'package:flutter/material.dart';
import 'pokemap_color_tokens.dart';

/// Exposes the static light and dark [ThemeData] configurations
/// for the PokeMap application.
///
/// Use this when configuring the top-level Material [Theme] or MaterialApp.
///
/// Example:
/// ```dart
/// MaterialApp(
///   theme: PokeMapTheme.light(),
///   darkTheme: PokeMapTheme.dark(),
///   themeMode: ThemeMode.system,
///   ...
/// )
/// ```
abstract final class PokeMapTheme {
  /// Builds the Light Mode [ThemeData] using [PokeMapColorTokens.light].
  static ThemeData light() {
    const tokens = PokeMapColorTokens.light;
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: tokens.backgroundApp,
      colorScheme: ColorScheme.light(
        primary: tokens.brandPrimary,
        onPrimary: tokens.textInverse,
        secondary: tokens.brandCyan,
        onSecondary: tokens.textInverse,
        surface: tokens.surfaceBase,
        onSurface: tokens.textPrimary,
        error: tokens.error,
        onError: tokens.textInverse,
        outline: tokens.borderSubtle,
      ),
      cardTheme: CardThemeData(
        color: tokens.surfaceBase,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.borderSubtle),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.brandPrimary, width: 1.5),
        ),
        labelStyle: TextStyle(color: tokens.textSecondary),
        hintStyle: TextStyle(color: tokens.textMuted),
      ),
      iconTheme: IconThemeData(
        color: tokens.textSecondary,
        size: 20,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        tokens,
      ],
    );
  }

  /// Builds the Dark Mode [ThemeData] using [PokeMapColorTokens.dark].
  static ThemeData dark() {
    const tokens = PokeMapColorTokens.dark;
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: tokens.backgroundApp,
      colorScheme: ColorScheme.dark(
        primary: tokens.brandPrimary,
        onPrimary: tokens.textInverse,
        secondary: tokens.brandCyan,
        onSecondary: tokens.textInverse,
        surface: tokens.surfaceBase,
        onSurface: tokens.textPrimary,
        error: tokens.error,
        onError: tokens.textInverse,
        outline: tokens.borderSubtle,
      ),
      cardTheme: CardThemeData(
        color: tokens.surfaceRaised,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.borderSubtle),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.brandPrimary, width: 1.5),
        ),
        labelStyle: TextStyle(color: tokens.textSecondary),
        hintStyle: TextStyle(color: tokens.textMuted),
      ),
      iconTheme: IconThemeData(
        color: tokens.textSecondary,
        size: 20,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        tokens,
      ],
    );
  }
}
