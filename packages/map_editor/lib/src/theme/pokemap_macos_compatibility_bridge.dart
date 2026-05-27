import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import 'pokemap_color_tokens.dart';

/// A temporary compatibility bridge that provides a [MacosTheme] in the widget tree.
///
/// Since the PokeMap root application has been migrated from [MacosApp] to [MaterialApp],
/// many legacy widgets in the editor tree still rely on [MacosTheme.of] or [MacosTheme.brightnessOf].
///
/// This bridge reads the active Material [Theme] brightness and maps it to a matching [MacosThemeData]
/// with appropriate primary and canvas colors matching legacy main.dart settings.
///
/// Once all legacy `macos_ui` components have been migrated to use PokeMap's design system
/// (`context.pokeMapColors`), this bridge can be safely deleted.
class PokeMapMacosCompatibilityBridge extends StatelessWidget {
  const PokeMapMacosCompatibilityBridge({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final materialTheme = Theme.of(context);
    final isDark = materialTheme.brightness == Brightness.dark;
    final colors = materialTheme.extension<PokeMapColorTokens>() ??
        (isDark ? PokeMapColorTokens.dark : PokeMapColorTokens.light);

    // Replicate the custom macos theme overrides that main.dart used to configure
    final macosThemeData = isDark
        ? MacosThemeData.dark().copyWith(
            accentColor: AccentColor.blue,
            primaryColor: colors.brandPrimary,
            canvasColor: colors.backgroundApp,
            dividerColor: colors.divider,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -0.25),
          )
        : MacosThemeData.light().copyWith(
            accentColor: AccentColor.blue,
            primaryColor: colors.brandPrimary,
            canvasColor: colors.backgroundApp,
            dividerColor: colors.divider,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -0.25),
          );

    return MacosTheme(
      data: macosThemeData,
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}
