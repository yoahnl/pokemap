import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart' show MacosTheme;
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
  /// If not registered (e.g. within legacy macOS app layout hierarchies without a Material
  /// Theme ancestor), it gracefully falls back to identifying the brightness of the nearby
  /// [MacosTheme] or device [MediaQuery], mapping it to [PokeMapColorTokens.light] or
  /// [PokeMapColorTokens.dark].
  PokeMapColorTokens get pokeMapColors {
    // 1. Check if the extension is registered in the current ThemeData
    final themeTokens = Theme.of(this).extension<PokeMapColorTokens>();
    if (themeTokens != null) {
      return themeTokens;
    }

    // 2. Safe fallback: detect brightness from MacosTheme, MediaQuery, or default to light
    final Brightness brightness;
    
    // Check MacosTheme brightness since the desktop editor currently uses MacosTheme
    final macosTheme = MacosTheme.maybeOf(this);
    if (macosTheme != null) {
      brightness = macosTheme.brightness;
    } else {
      // Fallback to platform brightness from MediaQuery
      Brightness? platformBrightness;
      try {
        platformBrightness = MediaQuery.maybeOf(this)?.platformBrightness;
      } catch (_) {
        // Suppress any errors if MediaQuery is not ready in test environments
      }
      brightness = platformBrightness ?? Brightness.light;
    }

    return brightness == Brightness.dark
        ? PokeMapColorTokens.dark
        : PokeMapColorTokens.light;
  }
}
