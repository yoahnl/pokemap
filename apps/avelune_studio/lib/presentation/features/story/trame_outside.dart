import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_rows.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_view.dart';
import 'package:avelune_studio/presentation/features/story/trame_behaviours.dart';
import 'package:avelune_studio/presentation/features/story/trame_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class TrameOutside extends StatelessWidget {
  const TrameOutside({
    super.key,
    required this.trame,
    required this.view,
    required this.behaviours,
    required this.navigate,
  });

  final StorylineTrameController trame;
  final StorylineTrameView view;
  final List<GameBehaviourRow> behaviours;
  final Future<bool> Function(String eventId) navigate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rows = [
      for (final row in behaviours)
        if (row.record case final record? when view.outside(record)) row,
    ];
    if (rows.isEmpty) {
      return StudioEmptyState(
        key: const ValueKey('trame-outside-empty'),
        icon: Icons.check_circle_outline,
        title: l10n.trameOutsideEmpty,
      );
    }
    final milestones = {
      for (final at in view.milestones)
        at.milestone.id: l10n.trameMilestoneOption(
          l10n.trameName(at.chapter.title, l10n.trameUnnamed),
          l10n.trameName(at.milestone.title, l10n.trameUnnamed),
        ),
    };
    return ListView.builder(
      key: const ValueKey('trame-outside-list'),
      padding: const EdgeInsets.all(StudioSpacing.xl),
      itemCount: rows.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: StudioSpacing.m),
            child: Text(
              l10n.trameOutsideHint,
              style: theme.textTheme.bodySmall,
            ),
          );
        }
        final row = rows[index - 1];
        final sceneId = row.record!.sceneId;
        final shared = sceneId == null
            ? 0
            : view.behavioursOfScene(sceneId).length;
        return Padding(
          padding: const EdgeInsets.only(bottom: StudioSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              trameBehaviourTile(trame, row, navigate),
              if (sceneId == null)
                Text(l10n.trameNeedsScene, style: theme.textTheme.bodySmall)
              else if (milestones.isNotEmpty)
                KeyedSubtree(
                  key: ValueKey('trame-outside-attach-${row.id}'),
                  child: StudioSelect(
                    label: shared > 1
                        ? l10n.trameAttachShared(shared)
                        : l10n.trameAttachTo,
                    value: null,
                    options: milestones,
                    onChanged: trame.staging.editable
                        ? (id) {
                            final at = view.milestone(id)!;
                            unawaited(
                              trame.attachScene(
                                at.storyline.id,
                                at.chapter.id,
                                id,
                                sceneId,
                              ),
                            );
                          }
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
