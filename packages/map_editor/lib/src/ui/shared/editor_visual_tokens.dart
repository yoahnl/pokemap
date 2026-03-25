import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

/// Fonds **stables** : fenêtre, barre d’outils et grands îlots en couleurs unies
/// (plus de gros dégradés). La couleur vit dans les cartes et accents.
abstract final class EditorVisualTokens {
  static bool _dark(BuildContext context) =>
      MacosTheme.brightnessOf(context) == Brightness.dark;

  /// Fond fenêtre / chrome — bleu nuit aubergine, une seule teinte.
  static const Color windowChromeDark = Color(0xFF1A1626);

  /// Surface principale des grands panneaux (gauche, centre, droite).
  static const Color mainPanelDark = Color(0xFF272232);

  /// Capsules de la toolbar : un cran plus clair pour le contraste.
  /// Exposé pour mélanges (pulldowns, survols) dans [EditorChrome].
  static const Color toolbarCapsuleDark = Color(0xFF363046);

  static Color appBackground(BuildContext context) => _dark(context)
      ? windowChromeDark
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
      ? windowChromeDark
      : const Color(0xFFFFFFFF);

  /// Groupe d’icônes : surface unie.
  static Color toolbarCapsuleColor(BuildContext context) => _dark(context)
      ? toolbarCapsuleDark
      : const Color(0xFFECEEF3);

  /// Grand îlot : base unie ; [tint] pousse à peine la teinte (identité de zone).
  static Color mainIslandSurface(
    BuildContext context, {
    Color? tint,
  }) {
    if (!_dark(context)) {
      return const Color(0xFFFFFFFF);
    }
    if (tint == null) return mainPanelDark;
    return Color.lerp(mainPanelDark, tint, 0.072)!;
  }

  /// Listes / rangées à l’intérieur des panneaux.
  static Color islandFill(BuildContext context) => _dark(context)
      ? const Color(0xFF2F293C)
      : const Color(0xFFFFFFFF);

  static Color islandFillElevated(BuildContext context) => _dark(context)
      ? const Color(0xFF38324A)
      : const Color(0xFFF9F7FC);
}
