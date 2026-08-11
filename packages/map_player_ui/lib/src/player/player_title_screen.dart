import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_action_availability.dart';
import 'player_title_surface.dart';
import 'runtime_player_focus_controller.dart';

export 'player_title_surface.dart';

@immutable
final class PlayerTitleViewData {
  PlayerTitleViewData({
    required this.gameTitle,
    required this.author,
    this.description,
    this.background,
    this.backgroundContent,
    this.logo,
    this.accentColor,
    this.layoutVariant = PlayerTitleLayoutVariant.standard,
    required Map<PlayerTitleMenuAction, PlayerActionAvailability> actions,
    Map<PlayerTitleMenuAction, String> actionLabels = const {},
    Map<PlayerTitleMenuAction, ProjectTitleActionIcon> actionIcons = const {},
    this.initialSelection,
    this.continueSave,
  })  : actions = Map.unmodifiable(actions),
        actionLabels = Map.unmodifiable(actionLabels),
        actionIcons = Map.unmodifiable(actionIcons);

  final String gameTitle;
  final String author;
  final String? description;
  final ImageProvider? background;
  final Widget? backgroundContent;
  final ImageProvider? logo;
  final Color? accentColor;
  final PlayerTitleLayoutVariant layoutVariant;
  final Map<PlayerTitleMenuAction, PlayerActionAvailability> actions;
  final Map<PlayerTitleMenuAction, String> actionLabels;
  final Map<PlayerTitleMenuAction, ProjectTitleActionIcon> actionIcons;
  final PlayerTitleMenuAction? initialSelection;
  final PlayerSaveSummary? continueSave;
}

class PlayerTitleScreen extends StatelessWidget {
  const PlayerTitleScreen({
    super.key,
    required this.data,
    required this.onSelected,
    this.focusController,
  });

  final PlayerTitleViewData data;
  final ValueChanged<PlayerTitleMenuAction> onSelected;
  final RuntimePlayerFocusController? focusController;

  @override
  Widget build(BuildContext context) {
    final save = data.continueSave;
    return PlayerTitleSurface(
      data: PlayerTitleSurfaceData(
        gameTitle: data.gameTitle,
        author: data.author,
        description: data.description,
        background: data.background,
        backgroundContent: data.backgroundContent,
        logo: data.logo,
        accentColor: data.accentColor,
        layoutVariant: data.layoutVariant,
        actions: data.actions,
        actionLabels: data.actionLabels,
        actionIcons: data.actionIcons,
        initialSelection: data.initialSelection,
        continueSave: save == null
            ? null
            : PlayerTitleContinueSaveData(
                updatedAt: save.updatedAt,
                playTimeSeconds: save.playTimeSeconds,
                locationLabel: save.locationLabel,
              ),
      ),
      onSelected: onSelected,
      focusController: focusController,
    );
  }
}
