import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import 'pokemap_theme_extension.dart';

/// Transitional color bridge for legacy editor surfaces.
///
/// Use this only while migrating old Cupertino/Macos UI to the PokeMap design
/// system. Product files should reference these names instead of raw Flutter
/// palettes or inline color literals, then graduate to semantic tokens.
abstract final class PokeMapLegacyColors {
  static const transparent = Color(0x00000000);
  static const black = Color(0xFF000000);
  static const black87 = Color(0xDD000000);
  static const black26 = Color(0x42000000);
  static const white = Color(0xFFFFFFFF);
  static const white60 = Color(0x99FFFFFF);
  static const white12 = Color(0x1FFFFFFF);
  static const white10 = Color(0x1AFFFFFF);

  static const cyanAccent = Color(0xFF18FFFF);
  static const greenAccent = Color(0xFF69F0AE);
  static const redAccent = Color(0xFFFF5252);
  static const orangeAccent = Color(0xFFFFAB40);
  static const purpleAccent = Color(0xFFE040FB);
  static const yellowAccent = Color(0xFFFFFF00);
  static const tealAccent = Color(0xFF64FFDA);
  static const lightBlueAccent = Color(0xFF40C4FF);
  static const blueAccent = Color(0xFF448AFF);
  static const amberAccent = Color(0xFFFFD740);
  static const deepOrangeAccent = Color(0xFFFF6E40);
  static const lightGreenAccent = Color(0xFFB2FF59);
  static const pinkAccent = Color(0xFFFF4081);
  static const deepPurpleAccent = Color(0xFF7C4DFF);

  static const teal = Color(0xFF009688);
  static const green = Color(0xFF4CAF50);
  static const orange = Color(0xFFFF9800);
  static const purple = Color(0xFF9C27B0);
  static const deepOrange = Color(0xFFFF5722);
  static const blueGrey = Color(0xFF607D8B);
  static const grey = Color(0xFF9E9E9E);

  static const purpleShade100 = Color(0xFFE1BEE7);
  static const orangeShade100 = Color(0xFFFFE0B2);
  static const greenShade900 = Color(0xFF1B5E20);
  static const orangeShade900 = Color(0xFFE65100);
  static const blueGreyShade200 = Color(0xFFB0BEC5);
  static const blueGreyShade900 = Color(0xFF263238);
  static const greyShade800 = Color(0xFF424242);

  static const accentPrimary = Color(0xFF5488EC);
  static const accentCyan = Color(0xFF24C8D6);
  static const accentJade = Color(0xFF47D16C);
  static const accentWarm = Color(0xFFF4B84A);
  static const accentCoral = Color(0xFFFF6B7C);
  static const accentPrune = Color(0xFF7D6FF0);
  static const accentLilac = Color(0xFFA77CFF);
  static const accentRose = Color(0xFFC98AA6);
  static const accentMagentaDeep = Color(0xFF5D4777);
  static const islandCoolTint = Color(0xFF1B2A3F);
  static const islandNeutralTint = Color(0xFF221B3D);
  static const islandWarmTint = Color(0xFF33250A);
  static const inspectorJoyApricot = Color(0xFFEFA65A);

  static const toolbarPulldownTrackLight = Color(0xFFE8ECF2);
  static const lightHoverOverlay = Color(0x14000000);
  static const lightSidebarHoverOverlay = Color(0x10000000);
  static const lightDisclosureHoverOverlay = Color(0x0E000000);
  static const lightIslandRim = Color(0x22000000);
  static const panelLightStart = Color(0xFFFFFFFF);
  static const panelLightEnd = Color(0xFFF1F4F8);
  static const lightPanelShadow = Color(0x12000000);
  static const lightSectionShadow = Color(0x0C000000);
  static const darkTileShadowStrong = Color(0x72000000);
  static const darkTileShadowSoft = Color(0x28000000);
  static const lightTileShadow = Color(0x1A000000);
  static const darkToolbarShadowStrong = Color(0x5C000000);
  static const darkToolbarShadowSoft = Color(0x22000000);
  static const lightToolbarShadow = Color(0x10000000);
  static const subtleWhiteBorder = Color(0x08FFFFFF);

  static const collisionAllowedFill = Color(0x664CAF50);
  static const collisionAllowedStroke = Color(0x992E7D32);
  static const maskEraseFill = Color(0x66FF7043);
  static const maskPaintFill = Color(0x6626C6DA);
  static const maskEraseStroke = Color(0xFFFFB199);
  static const maskPaintStroke = Color(0xFF80DEEA);
  static const cyanTag = Color(0xFF35E5D7);
  static const deepCyanText = Color(0xFF0A4955);
  static const blackOverlayStrong = Color(0xCC000000);
  static const darkLabelPlate = Color(0xFF13212D);
  static const terrainDirt = Color(0xFFA46E3D);
  static const terrainIndoor = Color(0xFFD8C3A5);
  static const terrainDirtDark = Color(0xFF6D4524);
  static const terrainIndoorDark = Color(0xFF8D6E63);

  static const gameplayEncounter = Color(0xFF66FF99);
  static const gameplayMovement = Color(0xFF66AAFF);
  static const gameplayMovementEffect = Color(0xFF66D9FF);
  static const gameplayHazard = Color(0xFFFF6666);
  static const gameplaySpecial = Color(0xFFCC66FF);
  static const gameplayCustom = Color(0xFF66FFFF);
  static const entityNpc = Color(0xFF55D0FF);
  static const entitySign = Color(0xFFFFC857);
  static const entityItem = Color(0xFF7CE38B);
  static const entitySpawn = Color(0xFFFF7B7B);
  static const entityCustom = Color(0xFFC18CFF);

  static const editorChipDark = Color(0xFF2C2C2E);
  static const editorChipLight = Color(0xFFECECEC);
  static const genericDropShadow = Color(0x66000000);

  static Color label(BuildContext context) => context.pokeMapColors.textPrimary;

  static Color secondaryLabel(BuildContext context) =>
      context.pokeMapColors.textSecondary;

  static Color tertiaryLabel(BuildContext context) =>
      context.pokeMapColors.textMuted;

  static Color separator(BuildContext context) =>
      context.pokeMapColors.borderSubtle;

  static Color systemGrey6(BuildContext context) =>
      context.pokeMapColors.controlSurface;

  static Color systemBackground(BuildContext context) =>
      context.pokeMapColors.cardSurface;

  static Color systemFill(BuildContext context) =>
      context.pokeMapColors.controlSurface;

  static Color appleRed(BuildContext context) => context.pokeMapColors.error;

  static Color sidebarSelection({
    required AccentColor accent,
    required bool isDark,
    required bool isMainWindow,
  }) {
    if (isDark) {
      if (!isMainWindow) {
        return const Color.fromRGBO(72, 56, 118, 0.7);
      }
      return switch (accent) {
        AccentColor.blue => const Color.fromRGBO(88, 62, 152, 0.74),
        AccentColor.purple => const Color.fromRGBO(154, 53, 173, 0.7),
        AccentColor.pink => const Color.fromRGBO(201, 81, 146, 0.7),
        AccentColor.red => const Color.fromRGBO(183, 72, 86, 0.72),
        AccentColor.orange => const Color.fromRGBO(187, 120, 53, 0.72),
        AccentColor.yellow => const Color.fromRGBO(188, 157, 71, 0.72),
        AccentColor.green => const Color.fromRGBO(72, 142, 98, 0.72),
        AccentColor.graphite => const Color.fromRGBO(112, 117, 124, 0.78),
      };
    }

    if (!isMainWindow) {
      return const Color.fromRGBO(213, 213, 208, 1.0);
    }

    return switch (accent) {
      AccentColor.blue => const Color.fromRGBO(9, 129, 255, 0.749),
      AccentColor.purple => const Color.fromRGBO(162, 28, 165, 0.749),
      AccentColor.pink => const Color.fromRGBO(234, 81, 152, 0.749),
      AccentColor.red => const Color.fromRGBO(220, 32, 40, 0.749),
      AccentColor.orange => const Color.fromRGBO(245, 113, 0, 0.749),
      AccentColor.yellow => const Color.fromRGBO(240, 180, 2, 0.749),
      AccentColor.green => const Color.fromRGBO(66, 174, 33, 0.749),
      AccentColor.graphite => const Color.fromRGBO(174, 174, 167, 0.847),
    };
  }
}
