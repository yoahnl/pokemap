import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_rows.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_summary.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_view.dart';
import 'package:avelune_studio/presentation/features/story/game_behaviour_row.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

Widget trameBehaviourTile(
  StorylineTrameController trame,
  GameBehaviourRow row,
  Future<bool> Function(String eventId) navigate,
) {
  final scenes = {for (final scene in trame.source().scenes) scene.id: scene};
  final record = row.record;
  return GameBehaviourRowTile(
    key: ValueKey('trame-behaviour-${row.id}'),
    row: row,
    summary: record == null
        ? null
        : summarizeGameBehaviour(record, (id) => scenes[id]),
    factName: trame.factName,
    onTap: () => unawaited(navigate(row.id)),
  );
}

class TrameSceneGroup extends StatelessWidget {
  const TrameSceneGroup({
    super.key,
    required this.trame,
    required this.view,
    required this.sceneId,
    required this.behaviours,
    required this.navigate,
    required this.onDetach,
    this.onOpen,
  });

  final StorylineTrameController trame;
  final StorylineTrameView view;
  final String sceneId;
  final List<GameBehaviourRow> behaviours;
  final Future<bool> Function(String eventId) navigate;
  final VoidCallback? onDetach;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final records = {
      for (final record in view.behavioursOfScene(sceneId)) record.id,
    };
    final scene = trame
        .source()
        .scenes
        .where((scene) => scene.id == sceneId)
        .firstOrNull;
    return Padding(
      key: ValueKey('trame-scene-$sceneId'),
      padding: const EdgeInsets.only(bottom: StudioSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.trameScene(scene?.name ?? l10n.behavioursSceneNotFound),
                  style: theme.textTheme.labelLarge,
                ),
              ),
              if (onOpen case final open?)
                IconButton(
                  key: ValueKey('trame-scene-open-$sceneId'),
                  tooltip: l10n.sceneFocusOpen,
                  iconSize: 18,
                  onPressed: open,
                  icon: const Icon(Icons.open_in_full),
                ),
              StudioButton(
                key: ValueKey('trame-detach-$sceneId'),
                label: l10n.trameDetach,
                icon: Icons.link_off,
                variant: StudioButtonVariant.quiet,
                onPressed: onDetach,
              ),
            ],
          ),
          if (records.length > 1)
            Text(
              l10n.trameSharedScene(records.length),
              key: ValueKey('trame-shared-$sceneId'),
              style: theme.textTheme.bodySmall,
            ),
          for (final row in behaviours)
            if (records.contains(row.id))
              trameBehaviourTile(trame, row, navigate),
        ],
      ),
    );
  }
}
