import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';

class PlayerNotificationOverlay extends StatelessWidget {
  const PlayerNotificationOverlay({
    super.key,
    required this.snapshot,
  });

  final RuntimeNotificationSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = switch (snapshot.tone) {
      RuntimeNotificationTone.info => (
          Icons.info_outline_rounded,
          PlayerBadgeTone.neutral,
        ),
      RuntimeNotificationTone.success => (
          Icons.check_circle_outline_rounded,
          PlayerBadgeTone.success,
        ),
      RuntimeNotificationTone.warning => (
          Icons.warning_amber_rounded,
          PlayerBadgeTone.warning,
        ),
      RuntimeNotificationTone.error => (
          Icons.error_outline_rounded,
          PlayerBadgeTone.danger,
        ),
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(PlayerSpacing.sm),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: PlayerPanel(
              elevated: true,
              padding: const EdgeInsets.symmetric(
                horizontal: PlayerSpacing.md,
                vertical: PlayerSpacing.sm,
              ),
              child: Semantics(
                key: const ValueKey<String>('player-notification'),
                container: true,
                liveRegion: true,
                label: snapshot.text,
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PlayerBadge(label: snapshot.text, icon: icon, tone: tone),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
