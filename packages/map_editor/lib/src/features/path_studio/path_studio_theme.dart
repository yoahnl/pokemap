import 'package:flutter/cupertino.dart';

/// Tokens visuels locaux au Path Studio.
///
/// Le lot 13 pose une direction dark mode identifiable sans transformer le
/// thème global de `map_editor`. Ces couleurs restent donc volontairement
/// privées à la feature Path Studio : les futurs lots pourront les promouvoir
/// si plusieurs studios finissent par partager exactement cette DA.
abstract final class PathStudioTheme {
  static const Color background = Color(0xFF171523);
  static const Color backgroundAlt = Color(0xFF191726);
  static const Color surface = Color(0xFF211F31);
  static const Color surfaceRaised = Color(0xFF26233A);
  static const Color surfaceStrong = Color(0xFF2B2840);
  static const Color border = Color(0xFF3A3654);
  static const Color borderStrong = Color(0xFF514B70);
  static const Color textPrimary = Color(0xFFF4F2FF);
  static const Color textSecondary = Color(0xFFB8B3D3);
  static const Color textMuted = Color(0xFF8F89AE);
  static const Color accent = Color(0xFF4E8CFF);
  static const Color accentHover = Color(0xFF6BA4FF);
  static const Color accentCyan = Color(0xFF3ECFCD);
  static const Color success = Color(0xFF4CC38A);
  static const Color warning = Color(0xFFF2B84B);
  static const Color error = Color(0xFFF06A6A);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      background,
      backgroundAlt,
      Color(0xFF141221),
    ],
  );

  /// Ombre courte et sobre : le shell doit avoir du relief, mais rester un
  /// outil de travail dense plutôt qu'une landing page décorative.
  static List<BoxShadow> panelShadow() {
    return const [
      BoxShadow(
        color: Color(0x73000000),
        blurRadius: 0,
        offset: Offset(0, 2),
      ),
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 10,
        offset: Offset(0, 8),
      ),
    ];
  }

  static BoxDecoration panelDecoration({
    Color color = surface,
    Color borderColor = border,
    double radius = 22,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: panelShadow(),
    );
  }

  static BoxDecoration subtleDecoration({
    Color color = surfaceRaised,
    Color borderColor = border,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor.withValues(alpha: 0.84)),
    );
  }
}
