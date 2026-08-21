import 'package:flutter/widgets.dart';

import '../theme/pokemap_player_theme.dart';

/// The three HP bands every player surface reads the same way.
enum PlayerHpTone { healthy, warning, danger }

/// The canonical thresholds: at or below a fifth is danger, at or below a half
/// is warning. The battle HUD already applied these; the summary sheet applied
/// none, so a Pokémon at 20/48 looked healthy on one surface and damaged on the
/// other. One resolver, so the two cannot drift again.
PlayerHpTone playerHpToneFor(double hpRatio) {
  final ratio = hpRatio.isFinite ? hpRatio.clamp(0.0, 1.0) : 0.0;
  if (ratio <= 0.2) return PlayerHpTone.danger;
  if (ratio <= 0.5) return PlayerHpTone.warning;
  return PlayerHpTone.healthy;
}

/// Resolves the tone to a colour, letting an authored V10 profile override each
/// band exactly as the battle HUD does.
Color playerHpColorFor(
  BuildContext context,
  double hpRatio, {
  String? healthyHex,
  String? warningHex,
  String? dangerHex,
}) {
  final colors = context.playerColors;
  return switch (playerHpToneFor(hpRatio)) {
    PlayerHpTone.danger =>
      PokeMapPlayerProjectColorResolver.tryOpaqueHex(dangerHex) ??
          colors.danger,
    PlayerHpTone.warning =>
      PokeMapPlayerProjectColorResolver.tryOpaqueHex(warningHex) ??
          colors.warning,
    PlayerHpTone.healthy =>
      PokeMapPlayerProjectColorResolver.tryOpaqueHex(healthyHex) ??
          colors.success,
  };
}
