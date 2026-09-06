import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'pokemap_player_surface_palette_theme.dart';
import 'pokemap_player_theme.dart';

@immutable
final class PokeMapPlayerMenuTheme {
  const PokeMapPlayerMenuTheme({
    this.backdrop = const Color(0xFF07121D),
    this.base = const Color(0xFF0D1D2B),
    this.panel = const Color(0xFF132A3D),
    this.recessed = const Color(0xFF0A1927),
    this.header = const Color(0xFF102644),
    this.text = const Color(0xFFF4F7FC),
    this.secondary = const Color(0xFFB9C9D9),
    this.disabled = const Color(0xFF7F92A5),
    this.border = const Color(0xFF668095),
    this.focus = const Color(0xFFD4EDFF),
    this.accent = const Color(0xFF76B9FF),
    this.selectionTop = const Color(0xFFA3D8FF),
    this.selectionBottom = const Color(0xFF5EA8EF),
    this.selectionText = const Color(0xFF082A45),
    this.health = const Color(0xFF67C86C),
    this.warning = const Color(0xFFF3C35E),
    this.danger = const Color(0xFFED737A),
    this.shadow = const Color(0xFF000000),
    this.contrastText = const Color(0xFFFFFFFF),
    this.highContrast = false,
    this.reducedMotion = false,
    this.opaque = false,
    this.typography = const PokeMapPlayerTypography(),
  });

  final Color backdrop;
  final Color base;
  final Color panel;
  final Color recessed;
  final Color header;
  final Color text;
  final Color secondary;
  final Color disabled;
  final Color border;
  final Color focus;
  final Color accent;
  final Color selectionTop;
  final Color selectionBottom;
  final Color selectionText;
  final Color health;
  final Color warning;
  final Color danger;
  final Color shadow;
  final Color contrastText;
  final bool highContrast;
  final bool reducedMotion;
  final bool opaque;
  final PokeMapPlayerTypography typography;

  static PokeMapPlayerMenuTheme resolve(
    BuildContext context, {
    ProjectPresentationSurfaceRole role =
        ProjectPresentationSurfaceRole.pauseMenu,
    bool opaque = false,
  }) {
    const preset = PokeMapPlayerMenuTheme();
    final theme = Theme.of(context);
    final palette = context.playerSurfacePalette(role);
    final authored =
        theme.extension<PokeMapPlayerAuthoredSemanticTheme>()?.semantic;
    final colors = theme.extension<PokeMapPlayerColors>();
    final media = MediaQuery.maybeOf(context);
    final contrast =
        (media?.highContrast ?? false) || (colors?.highContrast ?? false);
    Color resolve(String? value, Color fallback) =>
        PokeMapPlayerProjectColorResolver.tryOpaqueHex(value) ?? fallback;
    final base =
        resolve(palette?.background, authored?.background ?? preset.base);
    final panel =
        resolve(palette?.surface, authored?.menuSurface ?? preset.panel);
    final text = resolve(palette?.text, authored?.textPrimary ?? preset.text);
    final selection =
        resolve(palette?.selection, authored?.primary ?? preset.selectionTop);
    final selectedText = palette?.selection == null && authored == null
        ? preset.selectionText
        : _readableText(selection, preset);
    return PokeMapPlayerMenuTheme(
      backdrop: palette?.background == null
          ? authored?.background ?? preset.backdrop
          : base,
      base: contrast ? preset.shadow : base,
      panel: contrast ? preset.shadow : panel,
      recessed: contrast
          ? preset.shadow
          : palette?.background == null
              ? authored?.surface ?? preset.recessed
              : base,
      header: contrast
          ? preset.shadow
          : palette?.surface == null
              ? authored?.menuSurface ?? preset.header
              : panel,
      text: contrast ? preset.text : text,
      secondary: contrast
          ? preset.text
          : palette?.text == null
              ? authored?.textSecondary ?? preset.secondary
              : text,
      disabled: contrast ? preset.text : preset.disabled,
      border: contrast
          ? preset.text
          : resolve(palette?.border, authored?.outline ?? preset.border),
      focus: contrast ? preset.text : preset.focus,
      accent: contrast
          ? preset.text
          : resolve(palette?.accent, authored?.primary ?? preset.accent),
      selectionTop: contrast ? preset.text : selection,
      selectionBottom: contrast
          ? preset.text
          : resolve(
              palette?.selection, authored?.primary ?? preset.selectionBottom),
      selectionText: contrast ? preset.shadow : selectedText,
      health: contrast ? preset.text : authored?.success ?? preset.health,
      warning: contrast ? preset.text : authored?.warning ?? preset.warning,
      danger: contrast ? preset.text : authored?.danger ?? preset.danger,
      highContrast: contrast,
      reducedMotion: (media?.disableAnimations ?? false) ||
          (media?.accessibleNavigation ?? false) ||
          theme.extension<PokeMapPlayerMotion>()?.standard == Duration.zero,
      opaque: opaque || contrast,
      typography: context.playerTypography,
    );
  }

  static Color _readableText(Color background, PokeMapPlayerMenuTheme preset) {
    final preferred = _contrast(preset.text, background) >
            _contrast(preset.selectionText, background)
        ? preset.text
        : preset.selectionText;
    return _contrast(preferred, background) >= 4.5
        ? preferred
        : _contrast(preset.shadow, background) >= 4.5
            ? preset.shadow
            : preset.contrastText;
  }

  List<Color> selectionGradientColors({double shade = 0}) {
    List<Color> colors(double alpha) => [
          Color.alphaBlend(shadow.withValues(alpha: alpha), selectionTop),
          Color.alphaBlend(shadow.withValues(alpha: alpha), selectionBottom),
        ];
    bool readable(List<Color> backgrounds) => backgrounds
        .every((background) => _contrast(selectionText, background) >= 4.5);
    final requested = shade.clamp(0.0, 1.0);
    final target = colors(requested);
    if (readable(target)) return target;
    var lower = 0.0;
    var upper = requested;
    for (var iteration = 0; iteration < 12; iteration++) {
      final candidate = (lower + upper) / 2;
      if (readable(colors(candidate))) {
        lower = candidate;
      } else {
        upper = candidate;
      }
    }
    return colors(lower);
  }

  ({List<Color> backgrounds, Color foreground}) rowPresentation(
    List<Color> backgrounds, {
    required Color preferredForeground,
  }) {
    final candidates = [
      preferredForeground,
      text,
      selectionText,
      shadow,
      contrastText
    ];
    for (final candidate in candidates) {
      if (backgrounds
          .every((background) => _contrast(candidate, background) >= 4.5)) {
        return (backgrounds: backgrounds, foreground: candidate);
      }
    }
    final middle = Color.lerp(backgrounds.first, backgrounds.last, .5)!;
    final foreground = _contrast(shadow, middle) >= 4.5 ? shadow : contrastText;
    return (backgrounds: [middle, middle], foreground: foreground);
  }

  static double _contrast(Color a, Color b) {
    final first = a.computeLuminance();
    final second = b.computeLuminance();
    return (first > second ? first + .05 : second + .05) /
        (first > second ? second + .05 : first + .05);
  }

  static const double frameRadius = PlayerRadii.md;
  static const double rowRadius = PlayerRadii.sm;
  static const double panelRadius = 12;
  static const double badgeRadius = 8;

  Color get backdropLight => text;
  Color get backdropPattern => accent;
  Color get backdropContrast => shadow;

  Duration get hoverDuration => Duration(milliseconds: reducedMotion ? 0 : 120);
  Duration get pressDuration => Duration(milliseconds: reducedMotion ? 0 : 80);
  Duration get selectionDuration =>
      Duration(milliseconds: reducedMotion ? 0 : 140);
  Duration get openDuration => Duration(milliseconds: reducedMotion ? 80 : 220);
  Duration get closeDuration =>
      Duration(milliseconds: reducedMotion ? 80 : 160);
  Duration get detailDuration =>
      Duration(milliseconds: reducedMotion ? 80 : 180);
  double get openTranslation => reducedMotion ? 0 : 8;
  double get backdropOpacity => opaque ? .72 : .58;
  double get panelOpacity => opaque ? 1 : .96;

  TextStyle _style(double size, double height, FontWeight weight) => TextStyle(
        fontFamily: 'packages/map_player_ui/PokeMapSplashDMSans',
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        color: text,
      );

  TextStyle get body => _bodyStyle(_style(18, 26, FontWeight.w400));
  TextStyle get label => _bodyStyle(_style(18, 24, FontWeight.w500));
  TextStyle get title => _displayStyle(_style(26, 32, FontWeight.w600));
  TextStyle get subtitle => _displayStyle(_style(22, 28, FontWeight.w500));
  TextStyle get meta => _bodyStyle(_style(15, 20, FontWeight.w400));
  TextStyle get numbers {
    final base = _style(18, 26, FontWeight.w500);
    return (typography.numbersFamily == null &&
                typography.numbersMetrics == null
            ? base
            : typography
                .copyWith(
                    numbersFamily: typography.numbersFamily ?? base.fontFamily)
                .numbersStyle(base))
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  }

  TextStyle _bodyStyle(TextStyle base) =>
      typography.bodyFamily == null && typography.bodyMetrics == null
          ? base
          : typography
              .copyWith(bodyFamily: typography.bodyFamily ?? base.fontFamily)
              .bodyStyle(base);

  TextStyle _displayStyle(TextStyle base) => typography.displayFamily == null &&
          typography.displayMetrics == null
      ? base
      : typography
          .copyWith(displayFamily: typography.displayFamily ?? base.fontFamily)
          .displayStyle(base);

  BoxDecoration panelDecoration({bool primary = false}) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            panel.withValues(alpha: panelOpacity),
            base.withValues(alpha: panelOpacity)
          ],
        ),
        borderRadius:
            BorderRadius.circular(primary ? frameRadius : panelRadius),
        border:
            Border.all(color: border.withValues(alpha: highContrast ? 1 : .70)),
        boxShadow: [
          BoxShadow(
            color: shadow.withValues(alpha: primary ? .26 : .18),
            offset: Offset(0, primary ? 12 : 4),
            blurRadius: primary ? 28 : 14,
          ),
        ],
      );
}

class PlayerMenuThemeScope extends InheritedWidget {
  const PlayerMenuThemeScope({
    super.key,
    required super.child,
    this.role = ProjectPresentationSurfaceRole.pauseMenu,
    this.opaque = false,
  });

  final ProjectPresentationSurfaceRole role;
  final bool opaque;

  @override
  bool updateShouldNotify(PlayerMenuThemeScope oldWidget) =>
      role != oldWidget.role || opaque != oldWidget.opaque;
}

extension PlayerMenuThemeContext on BuildContext {
  PokeMapPlayerMenuTheme get playerMenuTheme {
    final scope = dependOnInheritedWidgetOfExactType<PlayerMenuThemeScope>();
    if (scope == null) {
      throw FlutterError(
          'Player menu components require PlayerMenuThemeScope.');
    }
    return PokeMapPlayerMenuTheme.resolve(this,
        role: scope.role, opaque: scope.opaque);
  }
}
