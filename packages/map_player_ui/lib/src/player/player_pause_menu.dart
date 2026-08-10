import 'package:flutter/material.dart';

import '../foundation/player_action_availability.dart';
import 'player_pause_surface.dart';

export 'player_pause_surface.dart';

class PlayerPauseMenu extends StatelessWidget {
  const PlayerPauseMenu({
    super.key,
    required this.gameTitle,
    required this.actions,
    required this.onSelected,
    this.labels = const PlayerPauseMenuLabels(),
  });

  final String gameTitle;
  final Map<PlayerPauseAction, PlayerActionAvailability> actions;
  final ValueChanged<PlayerPauseAction> onSelected;
  final PlayerPauseMenuLabels labels;

  @override
  Widget build(BuildContext context) => PlayerPauseSurface(
        gameTitle: gameTitle,
        actions: actions,
        onSelected: onSelected,
        labels: labels,
      );
}
