import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_rows.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_view.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/features/story/trame_labels.dart';
import 'package:avelune_studio/presentation/features/story/trame_milestone_detail.dart';
import 'package:avelune_studio/presentation/features/story/trame_outside.dart';
import 'package:avelune_studio/presentation/features/story/trame_selection.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class TrameDetail extends StatelessWidget {
  const TrameDetail({
    super.key,
    required this.trame,
    required this.view,
    required this.selection,
    required this.behaviours,
    required this.navigate,
  });

  final StorylineTrameController trame;
  final StorylineTrameView view;
  final TrameSelection? selection;
  final List<GameBehaviourRow> behaviours;
  final Future<bool> Function(String eventId) navigate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = selection;
    final storyline = view.outline.storylines
        .where((item) => item.id == selected?.storylineId)
        .firstOrNull;
    final chapter = storyline?.chapters
        .where((item) => item.id == selected?.chapterId)
        .firstOrNull;
    final milestone = selected?.milestoneId == null
        ? null
        : view.milestone(selected!.milestoneId!);
    final editable = trame.staging.editable;
    return switch (selected?.item) {
      TrameItem.outside => TrameOutside(
        trame: trame,
        view: view,
        behaviours: behaviours,
        navigate: navigate,
      ),
      TrameItem.milestone when milestone != null => TrameMilestoneDetail(
        key: ValueKey('trame-milestone-detail-${milestone.milestone.id}'),
        trame: trame,
        view: view,
        at: milestone,
        behaviours: behaviours,
        navigate: navigate,
      ),
      TrameItem.chapter when storyline != null && chapter != null => ListView(
        key: ValueKey('trame-chapter-detail-${chapter.id}'),
        padding: const EdgeInsets.all(StudioSpacing.xl),
        children: [
          MapBuilderNameField(
            key: ValueKey('trame-chapter-name-${chapter.id}'),
            value: chapter.title,
            label: l10n.trameChapterName,
            enabled: editable,
            onCommit: (title) =>
                unawaited(trame.renameChapter(storyline.id, chapter.id, title)),
          ),
          StudioToggleRow(
            key: const ValueKey('trame-chapter-archived'),
            label: l10n.trameArchived,
            value: trameArchived(chapter.status),
            onChanged: editable
                ? (value) => unawaited(
                    trame.archiveChapter(
                      storyline.id,
                      chapter.id,
                      archived: value,
                    ),
                  )
                : null,
          ),
          Wrap(
            spacing: StudioSpacing.s,
            runSpacing: StudioSpacing.s,
            children: [
              for (final (delta, label, icon) in [
                (-1, l10n.trameMoveUp, Icons.arrow_upward),
                (1, l10n.trameMoveDown, Icons.arrow_downward),
              ])
                StudioButton(
                  key: ValueKey('trame-chapter-move-$delta'),
                  label: label,
                  icon: icon,
                  variant: StudioButtonVariant.secondary,
                  onPressed: editable
                      ? () => unawaited(
                          trame.moveChapter(storyline.id, chapter.id, delta),
                        )
                      : null,
                ),
              StudioButton(
                key: const ValueKey('trame-milestone-add'),
                label: l10n.trameAddMilestone,
                icon: Icons.add,
                onPressed: editable
                    ? () => unawaited(
                        trame.createMilestone(
                          storyline.id,
                          chapter.id,
                          l10n.trameNewMilestone,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
      TrameItem.storyline when storyline != null => ListView(
        key: ValueKey('trame-storyline-detail-${storyline.id}'),
        padding: const EdgeInsets.all(StudioSpacing.xl),
        children: [
          MapBuilderNameField(
            key: ValueKey('trame-storyline-name-${storyline.id}'),
            value: storyline.title,
            label: l10n.trameStorylineName,
            enabled: editable,
            onCommit: (title) =>
                unawaited(trame.renameStoryline(storyline.id, title)),
          ),
          const SizedBox(height: StudioSpacing.m),
          Text(l10n.trameType(storyline.type)),
          const SizedBox(height: StudioSpacing.l),
          if (trame.staging.draft
                  .entryOf(StoryDraftKind.story, storyline.id)
                  ?.creation ??
              false)
            Align(
              alignment: Alignment.centerLeft,
              child: StudioButton(
                key: const ValueKey('trame-storyline-discard'),
                label: l10n.trameDiscardStoryline,
                icon: Icons.undo,
                variant: StudioButtonVariant.secondary,
                onPressed: () => trame.discardStoryline(storyline.id),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: StudioButton(
              key: const ValueKey('trame-chapter-add'),
              label: l10n.trameAddChapter,
              icon: Icons.add,
              onPressed: editable
                  ? () => unawaited(
                      trame.createChapter(storyline.id, l10n.trameNewChapter),
                    )
                  : null,
            ),
          ),
        ],
      ),
      _ => StudioEmptyState(
        icon: Icons.account_tree_outlined,
        title: l10n.trameSelect,
      ),
    };
  }
}
