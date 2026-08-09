
import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart';

import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';
import 'package:pokemap_hub/presentation/shared/artwork/local_artwork_image.dart';

final class HubUiActions {
  const HubUiActions({
    this.onImportRequested,
    this.onContinue,
    this.onNewGame,
    this.onUpdate,
    this.onRepair,
    this.onManageSaves,
    this.onUninstall,
  });

  final VoidCallback? onImportRequested;
  final ValueChanged<HubGameView>? onContinue;
  final ValueChanged<HubGameView>? onNewGame;
  final ValueChanged<HubGameView>? onUpdate;
  final ValueChanged<HubGameView>? onRepair;
  final ValueChanged<HubGameView>? onManageSaves;
  final Future<void> Function(HubGameView)? onUninstall;
}

class HubArtwork extends StatelessWidget {
  const HubArtwork({
    super.key,
    required this.path,
    required this.icon,
    this.accentColor,
  });

  final String? path;
  final IconData icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? context.playerColors.primary;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.32),
            context.playerColors.surfaceElevated,
          ],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 64, color: accent),
      ),
    );
    final assetPath = path;
    if (assetPath == null) return fallback;
    return Image(
      image: requireLocalArtworkImage(assetPath),
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

Color? decodeHubAccentColor(String? source) {
  if (source == null || !source.startsWith('#')) return null;
  final hex = source.substring(1);
  try {
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color.fromARGB(
        int.parse(hex.substring(6, 8), radix: 16),
        int.parse(hex.substring(0, 2), radix: 16),
        int.parse(hex.substring(2, 4), radix: 16),
        int.parse(hex.substring(4, 6), radix: 16),
      );
    }
  } on FormatException {
    return null;
  }
  return null;
}
