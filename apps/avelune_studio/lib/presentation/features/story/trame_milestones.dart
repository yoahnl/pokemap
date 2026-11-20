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
    final viewport = MediaQuery.sizeOf(context).width;
    final milestones = [
      for (final (index, milestone) in chapter.milestones.indexed)
        if (showArchived || !trameArchived(milestone.status))
          (index, milestone),
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
        if (milestones.isNotEmpty)
          LayoutBuilder(
            builder: (context, area) {
              final sceneWidth = viewport <= 1390 ? 145.0 : 190.0;
              final inline =
                  viewport > 1150 && area.maxWidth >= sceneWidth + 270;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, milestone) in milestones)
                    _row(
                      context,
                      milestone,
                      index + 1,
                      inline ? sceneWidth : null,
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    StorylineOutlineMilestone milestone,
    int number,
    double? sceneWidth,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final markerSize = MediaQuery.textScalerOf(context).scale(27);
    final archived = trameArchived(milestone.status);
    final scenes = milestone.sceneIds.isEmpty
        ? l10n.trameNoLinkedScene
        : milestone.sceneIds
              .map((id) => trame.sceneName(id) ?? l10n.behavioursSceneNotFound)
              .join(' · ');
    return StudioChoice(
      key: ValueKey('trame-milestone-${milestone.id}'),
      label: l10n.trameName(milestone.title, l10n.trameUnnamed),
      leading: Container(
        width: markerSize,
        height: markerSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.outline),
        ),
        child: Text(
          '$number'.padLeft(2, '0'),
          style: theme.textTheme.labelMedium?.copyWith(color: colors.primary),
        ),
      ),
      subtitle: [
        l10n.trameMilestoneSummary(
          view.behavioursOf(milestone).length,
          milestone.issues.length,
        ),
        if (sceneWidth == null) scenes,
        if (sceneWidth == null && archived) l10n.trameArchivedBadge,
      ].join('\n'),
      selected: milestone.id == selectedId,
      selectionAccent: true,
      trailing: sceneWidth == null
          ? null
          : SizedBox(
              width: sceneWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (archived) StudioBadge(l10n.trameArchivedBadge),
                  if (milestone.issues.isNotEmpty)
                    StudioBadge(l10n.trameEditorial, tone: StudioTone.warning),
                ],
              ),
            ),
      onTap: () => onSelected(milestone.id),
    );
  }
}
