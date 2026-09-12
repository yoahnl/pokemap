import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart' show RuntimePlayerMenuEffects;

import 'pokemap_player_menu_theme.dart';
import 'pokemap_player_surface_palette_theme.dart';
import 'pokemap_player_theme.dart';

@immutable
final class PokeMapPlayerOverworldTheme {
  const PokeMapPlayerOverworldTheme({
    this.surface = const Color(0xFF15223D),
    this.text = const Color(0xFFF4F5FF),
    this.accent = const Color(0xFF91A6FF),
    this.border = const Color(0xFF9CACE3),
    this.focus = const Color(0xFFE0E6FF),
    this.disabled = const Color(0xFF9BA6BF),
    this.shadow = const Color(0xFF050B19),
    this.highContrast = false,
    this.reducedMotion = false,
    this.opaque = false,
    this.typography = const PokeMapPlayerTypography(),
  });

  final Color surface;
  final Color text;
  final Color accent;
  final Color border;
  final Color focus;
  final Color disabled;
  final Color shadow;
  final bool highContrast;
  final bool reducedMotion;
  final bool opaque;
  final PokeMapPlayerTypography typography;

  static const menuSize = 52.0;
  static const minimumTarget = 48.0;
  static const iconSize = 24.0;
  static const glyphSize = 28.0;
  static const glyphInset = PlayerSpacing.xxs;
  static const actionGap = PlayerSpacing.sm;
  static const contentGap = PlayerSpacing.xs;
  static const compactInset = PlayerSpacing.md;
  static const wideInset = PlayerSpacing.lg;
  static const wideBreakpoint = 600.0;
  static const capsuleMaxWidth = 360.0;
  static const capsuleRadius = menuSize / 2;
  static const glyphRadius = PlayerRadii.sm;
  static const joystickSize = 112.0;
  static const joystickKnobSize = 48.0;
  static const joystickTravel = 28.0;
  static const runningInset = 6.0;
  static const runningWidth = 5.0;
  static const pressedScale = .97;

  static PokeMapPlayerOverworldTheme resolve(BuildContext context) {
    const preset = PokeMapPlayerOverworldTheme();
    final theme = Theme.of(context);
    final authored =
        theme.extension<PokeMapPlayerAuthoredSemanticTheme>()?.semantic;
    final palette = context
        .playerSurfacePalette(ProjectPresentationSurfaceRole.overworldHud);
    final media = MediaQuery.maybeOf(context);
    final effects = PlayerMenuEffectsScope.of(context);
    final highContrast = (media?.highContrast ?? false) ||
        (theme.extension<PokeMapPlayerColors>()?.highContrast ?? false);
    Color color(String? value, Color fallback) =>
        PokeMapPlayerProjectColorResolver.tryOpaqueHex(value) ?? fallback;
    return PokeMapPlayerOverworldTheme(
      surface: highContrast
          ? preset.shadow
          : color(palette?.surface,
              authored?.overworldHudSurface ?? preset.surface),
      text: highContrast
          ? preset.text
          : color(palette?.text, authored?.textPrimary ?? preset.text),
      accent: highContrast
          ? preset.text
          : color(palette?.accent, authored?.primary ?? preset.accent),
      border: highContrast
          ? preset.text
          : color(palette?.border, authored?.outline ?? preset.border),
      focus: highContrast ? preset.text : preset.focus,
      disabled: highContrast ? preset.text : preset.disabled,
      highContrast: highContrast,
      reducedMotion: (media?.disableAnimations ?? false) ||
          (media?.accessibleNavigation ?? false) ||
          effects != RuntimePlayerMenuEffects.full ||
          theme.extension<PokeMapPlayerMotion>()?.standard == Duration.zero,
      opaque: highContrast || effects == RuntimePlayerMenuEffects.opaque,
      typography: context.playerTypography,
    );
  }

  Duration get pressDuration =>
      reducedMotion ? Duration.zero : const Duration(milliseconds: 100);
  Duration get appearanceDuration =>
      reducedMotion ? Duration.zero : const Duration(milliseconds: 150);

  TextStyle get label => typography.bodyStyle(TextStyle(
        decoration: TextDecoration.none,
        fontFamily: typography.bodyFamily ??
            'packages/map_player_ui/PokeMapSplashDMSans',
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: text,
      ));

  TextStyle get glyphLabel =>
      label.copyWith(fontSize: 12, fontWeight: FontWeight.w600);

  BoxDecoration surfaceDecoration(
      {bool focused = false,
      bool pressed = false,
      bool enabled = true,
      bool knob = false,
      bool circular = false,
      bool glyph = false}) {
    final fill = knob ? accent : surface;
    return BoxDecoration(
      color: fill.withValues(
          alpha: opaque
              ? 1
              : knob
                  ? .86
                  : .88),
      borderRadius: BorderRadius.circular(circular
          ? PlayerRadii.pill
          : glyph
              ? glyphRadius
              : capsuleRadius),
      border: Border.all(
          color: focused
              ? focus
              : enabled
                  ? border
                  : disabled,
          width: focused
              ? 3
              : highContrast
                  ? 2
                  : 1),
      boxShadow: opaque
          ? const []
          : [
              BoxShadow(
                  color: accent.withValues(
                      alpha: focused || pressed || knob ? .28 : .12),
                  blurRadius: 14,
                  spreadRadius: 1),
              BoxShadow(
                  color: shadow.withValues(alpha: .32),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
            ],
    );
  }
}

extension PlayerOverworldThemeContext on BuildContext {
  PokeMapPlayerOverworldTheme get playerOverworldTheme =>
      PokeMapPlayerOverworldTheme.resolve(this);
}
