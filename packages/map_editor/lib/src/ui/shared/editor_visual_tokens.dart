import 'package:flutter/cupertino.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

import '../../theme/theme.dart';

/// Fonds **stables** : fenêtre, barre d’outils et grands îlots en couleurs unies
/// (plus de gros dégradés). La couleur vit dans les cartes et accents.
abstract final class EditorVisualTokens {
  static bool _dark(BuildContext context) =>
      MacosTheme.brightnessOf(context) == Brightness.dark;

  static Color appBackground(BuildContext context) => _dark(context)
      ? context.pokeMapColors.chromeBackground
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
      ? context.pokeMapColors.topBarBackground
      : const Color(0xFFFFFFFF);

  /// Groupe d’icônes : surface unie.
  static Color toolbarCapsuleColor(BuildContext context) => _dark(context)
      ? context.pokeMapColors.controlSurface
      : const Color(0xFFECEEF3);

  /// Grand îlot : base unie ; [tint] pousse à peine la teinte (identité de zone).
  static Color mainIslandSurface(
    BuildContext context, {
    Color? tint,
  }) {
    if (!_dark(context)) {
      return const Color(0xFFFFFFFF);
    }
    final base = context.pokeMapColors.contentSurface;
    if (tint == null) return base;
    return Color.lerp(base, tint, 0.048)!;
  }

  /// Listes / rangées à l’intérieur des panneaux.
  static Color islandFill(BuildContext context) => _dark(context)
      ? context.pokeMapColors.contentSurface
      : const Color(0xFFFFFFFF);

  static Color islandFillElevated(BuildContext context) => _dark(context)
      ? context.pokeMapColors.cardSurface
      : const Color(0xFFF9F7FC);
}
