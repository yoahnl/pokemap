import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_view.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'trame_labels.dart';

class TrameMilestones extends StatelessWidget {
  const TrameMilestones({
    super.key,
    required this.trame,
    required this.view,
    required this.story,
    required this.chapter,
    required this.selectedId,
    required this.showArchived,
    required this.onSelected,
  });

  final StorylineTrameController trame;
  final StorylineTrameView view;
  final StorylineOutlineStoryline story;
  final StorylineOutlineChapter chapter;
  final String? selectedId;
  final bool showArchived;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final milestones = [
      for (final milestone in chapter.milestones)
        if (showArchived || !trameArchived(milestone.status)) milestone,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioPageHeader(
          title: chapter.title,
          description: l10n.trameMilestoneCount(milestones.length),
          compact: true,
          alignActionsToEnd: true,
          actions: [
            StudioButton(
              key: const ValueKey('trame-outline-milestone-add'),
              label: l10n.trameAddMilestone,
              icon: Icons.add,
              variant: StudioButtonVariant.secondary,
              onPressed: trame.staging.editable
                  ? () => unawaited(
                      trame.createMilestone(
                        story.id,
                        chapter.id,
                        l10n.trameNewMilestone,
                      ),
                    )
                  : null,
            ),
          ],
        ),
        if (milestones.isEmpty) Text(l10n.trameNoMilestone),
        for (final milestone in milestones)
          StudioChoice(
            key: ValueKey('trame-milestone-${milestone.id}'),
            label: l10n.trameName(milestone.title, l10n.trameUnnamed),
            leading: Text(
              '${chapter.milestones.indexOf(milestone) + 1}'.padLeft(2, '0'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: l10n.trameMilestoneSummary(
              view.behavioursOf(milestone).length,
              milestone.issues.length,
            ),
            selected: milestone.id == selectedId,
            trailing: SizedBox(
              width: 190,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.sceneIds.isEmpty
                        ? l10n.trameNoLinkedScene
                        : milestone.sceneIds
                              .map(
                                (id) =>
                                    trame.sceneName(id) ??
                                    l10n.behavioursSceneNotFound,
                              )
                              .join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (trameArchived(milestone.status))
                    StudioBadge(l10n.trameArchivedBadge),
                  if (milestone.issues.isNotEmpty)
                    StudioBadge(l10n.trameEditorial, tone: StudioTone.warning),
                ],
              ),
            ),
            onTap: () => onSelected(milestone.id),
          ),
      ],
    );
  }
}
