import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../theme/theme.dart';

/// Fonds **stables** : fenêtre, barre d’outils et grands îlots en couleurs unies
/// (plus de gros dégradés). La couleur vit dans les cartes et accents.
abstract final class EditorVisualTokens {
  static bool _dark(BuildContext context) =>
      MacosTheme.brightnessOf(context) == Brightness.dark;

  /// Fond fenêtre / chrome — bleu nuit, une seule teinte.
  static const Color windowChromeDark = Color(0xFF06111F);

  /// Surface principale des grands panneaux (gauche, centre, droite).
  static const Color mainPanelDark = Color(0xFF0D1B2E);

  /// Capsules de la toolbar : un cran plus clair pour le contraste.
  /// Exposé pour mélanges (pulldowns, survols) dans [EditorChrome].
  static const Color toolbarCapsuleDark = Color(0xFF11243A);

  static Color appBackground(BuildContext context) => _dark(context)
      ? context.pokeMapColors.backgroundApp
      : const Color(0xFFF6F1EC);

  /// Clair : léger dégradé chaud. Sombre : **plat** (évite bandes / artefacts).
  static LinearGradient? appBackgroundGradient(BuildContext context) {
    if (_dark(context)) return null;
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFF6EDE4),
      ],
    );
  }

  /// Barre d’outils : même couleur que la fenêtre en sombre (intégration nette).
  static Color toolbarBarColor(BuildContext context) => _dark(context)
      ? context.pokeMapColors.backgroundShell
      : const Color(0xFFFFFFFF);

  /// Groupe d’icônes : surface unie.
  static Color toolbarCapsuleColor(BuildContext context) => _dark(context)
      ? context.pokeMapColors.surfaceRaised
      : const Color(0xFFECEEF3);

  /// Grand îlot : base unie ; [tint] pousse à peine la teinte (identité de zone).
  static Color mainIslandSurface(
    BuildContext context, {
    Color? tint,
  }) {
    if (!_dark(context)) {
      return const Color(0xFFFFFFFF);
    }
    final base = context.pokeMapColors.surfaceBase;
    if (tint == null) return base;
    return Color.lerp(base, tint, 0.072)!;
  }

  /// Listes / rangées à l’intérieur des panneaux.
  static Color islandFill(BuildContext context) => _dark(context)
      ? context.pokeMapColors.surfaceSubtle
      : const Color(0xFFFFFFFF);

  static Color islandFillElevated(BuildContext context) => _dark(context)
      ? context.pokeMapColors.surfaceRaised
      : const Color(0xFFF9F7FC);
}
