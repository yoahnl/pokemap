import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'pokemap_player_surface_palette_theme.dart';
import 'pokemap_player_theme.dart';

@immutable
final class PokeMapPlayerMenuTheme {
  const PokeMapPlayerMenuTheme({
    this.backdrop = const Color(0xFF131923),
    this.base = const Color(0xFF191E28),
    this.panel = const Color(0xFF202735),
    this.recessed = const Color(0xFF252E3D),
    this.header = const Color(0xFF202735),
    this.text = const Color(0xFFF4F6FA),
    this.secondary = const Color(0xFFABB6C6),
    this.disabled = const Color(0xFFA6AFBC),
    this.border = const Color(0xFF455164),
    this.focus = const Color(0xFFF44D59),
    this.accent = const Color(0xFFF44D59),
    this.selectionTop = const Color(0xFF080C13),
    this.selectionBottom = const Color(0xFF080C13),
    this.selectionText = const Color(0xFFFFFFFF),
    this.health = const Color(0xFF32C654),
    this.warning = const Color(0xFFEFBD64),
    this.danger = const Color(0xFFFF8C99),
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
    final theme = Theme.of(context);
    final preset = theme.brightness == Brightness.dark
        ? const PokeMapPlayerMenuTheme()
        : const PokeMapPlayerMenuTheme(
            backdrop: Color(0xFFF1F3F5),
            base: Color(0xFFF9FAFB),
            panel: Color(0xFFFFFFFF),
            recessed: Color(0xFFE8EDF2),
            header: Color(0xFFFFFFFF),
            text: Color(0xFF11151D),
            secondary: Color(0xFF626A75),
            disabled: Color(0xFF7C848D),
            border: Color(0xFFD8DDE2),
            selectionTop: Color(0xFF11151D),
            selectionBottom: Color(0xFF11151D),
            warning: Color(0xFF936607),
            danger: Color(0xFFB83748),
          );
    final palette = context.playerSurfacePalette(role);
    final authored = theme
        .extension<PokeMapPlayerAuthoredSemanticTheme>()
        ?.semantic;
    final colors = theme.extension<PokeMapPlayerColors>();
    final media = MediaQuery.maybeOf(context);
    final effects = PlayerMenuEffectsScope.of(context);
    final contrast =
        (media?.highContrast ?? false) || (colors?.highContrast ?? false);
    Color resolve(String? value, Color fallback) =>
        PokeMapPlayerProjectColorResolver.tryOpaqueHex(value) ?? fallback;
    final base = resolve(
      palette?.background,
      authored?.background ?? preset.base,
    );
    final panel = resolve(
      palette?.surface,
      authored?.menuSurface ?? preset.panel,
    );
    final text = resolve(palette?.text, authored?.textPrimary ?? preset.text);
    final selection = resolve(
      palette?.selection,
      authored?.primary ?? preset.selectionTop,
    );
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
      text: contrast ? preset.contrastText : text,
      secondary: contrast
          ? preset.contrastText
          : palette?.text == null
          ? authored?.textSecondary ?? preset.secondary
          : text,
      disabled: contrast ? preset.contrastText : preset.disabled,
      border: contrast
          ? preset.contrastText
          : resolve(palette?.border, authored?.outline ?? preset.border),
      focus: contrast ? preset.contrastText : preset.focus,
      accent: contrast
          ? preset.contrastText
          : resolve(palette?.accent, authored?.primary ?? preset.accent),
      selectionTop: contrast ? preset.contrastText : selection,
      selectionBottom: contrast
          ? preset.contrastText
          : resolve(
              palette?.selection,
              authored?.primary ?? preset.selectionBottom,
            ),
      selectionText: contrast ? preset.shadow : selectedText,
      health: contrast
          ? preset.contrastText
          : authored?.success ?? preset.health,
      warning: contrast
          ? preset.contrastText
          : authored?.warning ?? preset.warning,
      danger: contrast
          ? preset.contrastText
          : authored?.danger ?? preset.danger,
      highContrast: contrast,
      reducedMotion:
          (media?.disableAnimations ?? false) ||
          effects != RuntimePlayerMenuEffects.full ||
          (media?.accessibleNavigation ?? false) ||
          theme.extension<PokeMapPlayerMotion>()?.standard == Duration.zero,
      opaque: opaque || contrast || effects == RuntimePlayerMenuEffects.opaque,
      typography: context.playerTypography,
    );
  }

  static Color _readableText(Color background, PokeMapPlayerMenuTheme preset) {
    final preferred =
        _contrast(preset.text, background) >
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
    bool readable(List<Color> backgrounds) => backgrounds.every(
      (background) => _contrast(selectionText, background) >= 4.5,
    );
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
      contrastText,
    ];
    for (final candidate in candidates) {
      if (backgrounds.every(
        (background) => _contrast(candidate, background) >= 4.5,
      )) {
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

  static const double frameRadius = 4;
  static const double rowRadius = 0;
  static const double panelRadius = 4;
  static const double badgeRadius = 3;

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
  double get panelOpacity => 1;

  TextStyle _style(double size, double height, FontWeight weight) => TextStyle(
    fontFamily: 'packages/map_player_ui/PokeMapSplashDMSans',
    fontSize: size,
    height: height / size,
    fontWeight: weight,
    color: text,
  );

  TextStyle get body => _bodyStyle(_style(16, 22, FontWeight.w400));
  TextStyle get label => _bodyStyle(_style(16, 22, FontWeight.w600));
  TextStyle get actionLabel => _bodyStyle(_style(15, 20, FontWeight.w600));
  TextStyle get title => _displayStyle(_style(24, 28, FontWeight.w700));
  TextStyle get subtitle => _displayStyle(_style(20, 26, FontWeight.w600));
  TextStyle get meta => _bodyStyle(_style(12, 17, FontWeight.w400));
  TextStyle get numbers {
    final base = _style(16, 22, FontWeight.w600);
    return (typography.numbersFamily == null &&
                typography.numbersMetrics == null
            ? base
            : typography
                  .copyWith(
                    numbersFamily: typography.numbersFamily ?? base.fontFamily,
                  )
                  .numbersStyle(base))
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  }

  TextStyle _bodyStyle(TextStyle base) =>
      typography.bodyFamily == null && typography.bodyMetrics == null
      ? base
      : typography
            .copyWith(bodyFamily: typography.bodyFamily ?? base.fontFamily)
            .bodyStyle(base);

  TextStyle _displayStyle(TextStyle base) =>
      typography.displayFamily == null && typography.displayMetrics == null
      ? base
      : typography
            .copyWith(
              displayFamily: typography.displayFamily ?? base.fontFamily,
            )
            .displayStyle(base);

  BoxDecoration panelDecoration({bool primary = false}) => BoxDecoration(
    color: panel,
    borderRadius: BorderRadius.circular(primary ? frameRadius : panelRadius),
    border: highContrast ? Border.all(color: border) : null,
  );
}

class PlayerMenuEffectsScope extends InheritedTheme {
  const PlayerMenuEffectsScope({
    super.key,
    required this.effects,
    required super.child,
  });

  final RuntimePlayerMenuEffects effects;

  static RuntimePlayerMenuEffects of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<PlayerMenuEffectsScope>()
          ?.effects ??
      RuntimePlayerMenuEffects.full;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      PlayerMenuEffectsScope(effects: effects, child: child);

  @override
  bool updateShouldNotify(PlayerMenuEffectsScope oldWidget) =>
      effects != oldWidget.effects;
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
        'Player menu components require PlayerMenuThemeScope.',
      );
    }
    return PokeMapPlayerMenuTheme.resolve(
      this,
      role: scope.role,
      opaque: scope.opaque,
    );
  }
}
