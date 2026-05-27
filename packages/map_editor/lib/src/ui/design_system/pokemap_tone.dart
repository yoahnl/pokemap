import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Semantic accents available to product UI.
///
/// Screens should choose a tone instead of passing raw colors. The concrete
/// color mapping stays centralized in [PokeMapColorTokens].
enum PokeMapTone {
  neutral,
  brand,
  success,
  warning,
  danger,
  info,
  narrative,
  cinematic,
  dialogue,
  quest,
  fact,
  map,
}

/// Resolved colors for a semantic [PokeMapTone].
class PokeMapToneColors {
  const PokeMapToneColors({
    required this.icon,
    required this.soft,
    required this.border,
    required this.text,
  });

  final Color icon;
  final Color soft;
  final Color border;
  final Color text;
}

extension PokeMapToneX on PokeMapTone {
  PokeMapToneColors resolve(BuildContext context) {
    final colors = context.pokeMapColors;
    return switch (this) {
      PokeMapTone.neutral => PokeMapToneColors(
          icon: colors.textSecondary,
          soft: colors.controlSurface,
          border: colors.controlBorder,
          text: colors.textSecondary,
        ),
      PokeMapTone.brand => PokeMapToneColors(
          icon: colors.brandPrimary,
          soft: colors.brandPrimarySoft,
          border: colors.brandPrimaryBorder,
          text: colors.brandPrimary,
        ),
      PokeMapTone.success => PokeMapToneColors(
          icon: colors.success,
          soft: colors.successSoft,
          border: colors.successBorder,
          text: colors.success,
        ),
      PokeMapTone.warning => PokeMapToneColors(
          icon: colors.warning,
          soft: colors.warningSoft,
          border: colors.warningBorder,
          text: colors.warning,
        ),
      PokeMapTone.danger => PokeMapToneColors(
          icon: colors.error,
          soft: colors.errorSoft,
          border: colors.errorBorder,
          text: colors.error,
        ),
      PokeMapTone.info => PokeMapToneColors(
          icon: colors.info,
          soft: colors.infoSoft,
          border: colors.info.withValues(alpha: 0.28),
          text: colors.info,
        ),
      PokeMapTone.narrative => PokeMapToneColors(
          icon: colors.narrative,
          soft: colors.narrativeSoft,
          border: colors.narrative.withValues(alpha: 0.32),
          text: colors.narrative,
        ),
      PokeMapTone.cinematic => PokeMapToneColors(
          icon: colors.cinematic,
          soft: colors.narrativeSoft,
          border: colors.cinematic.withValues(alpha: 0.32),
          text: colors.cinematic,
        ),
      PokeMapTone.dialogue => PokeMapToneColors(
          icon: colors.dialogue,
          soft: colors.infoSoft,
          border: colors.dialogue.withValues(alpha: 0.32),
          text: colors.dialogue,
        ),
      PokeMapTone.quest => PokeMapToneColors(
          icon: colors.event,
          soft: colors.narrativeSoft,
          border: colors.event.withValues(alpha: 0.32),
          text: colors.event,
        ),
      PokeMapTone.fact => PokeMapToneColors(
          icon: colors.fact,
          soft: colors.warningSoft,
          border: colors.fact.withValues(alpha: 0.32),
          text: colors.fact,
        ),
      PokeMapTone.map => PokeMapToneColors(
          icon: colors.mapAccent,
          soft: colors.successSoft,
          border: colors.mapAccent.withValues(alpha: 0.32),
          text: colors.mapAccent,
        ),
    };
  }
}
