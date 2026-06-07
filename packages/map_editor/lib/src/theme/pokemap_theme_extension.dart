import 'package:flutter/material.dart';
import 'pokemap_color_tokens.dart';

/// Extension on [BuildContext] to simplify access to the [PokeMapColorTokens]
/// design system colors from any widget.
///
/// Example:
/// ```dart
/// final primaryColor = context.pokeMapColors.brandPrimary;
/// ```
extension PokeMapThemeBuildContextX on BuildContext {
  /// Resolves the current [PokeMapColorTokens] for this context.
  ///
  /// First attempts to retrieve tokens registered in the Material [Theme] extension list.
  /// If not registered, it gracefully falls back to identifying the platform brightness
  /// from the device [MediaQuery], mapping it to [PokeMapColorTokens.light] or
  /// [PokeMapColorTokens.dark].
  PokeMapColorTokens get pokeMapColors {
    // 1. Check if the extension is registered in the current ThemeData
    final themeTokens = Theme.of(this).extension<PokeMapColorTokens>();
    if (themeTokens != null) {
      return themeTokens;
    }

    // 2. Safe fallback: detect platform brightness from MediaQuery, or default to light
    final Brightness brightness;
    Brightness? platformBrightness;
    try {
      platformBrightness = MediaQuery.maybeOf(this)?.platformBrightness;
    } catch (_) {
      // Suppress any errors if MediaQuery is not ready in test environments
    }
    brightness = platformBrightness ?? Brightness.light;

    return brightness == Brightness.dark
        ? PokeMapColorTokens.dark
        : PokeMapColorTokens.light;
  }
}
