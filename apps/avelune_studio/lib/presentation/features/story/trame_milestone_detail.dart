import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_rows.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_view.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/features/story/trame_behaviours.dart';
import 'package:avelune_studio/presentation/features/story/trame_journal.dart';
import 'package:avelune_studio/presentation/features/story/trame_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class TrameMilestoneDetail extends StatelessWidget {
  const TrameMilestoneDetail({
    super.key,
    required this.trame,
    required this.view,
    required this.at,
    required this.behaviours,
    required this.navigate,
    this.openScene,
  });

  final StorylineTrameController trame;
  final StorylineTrameView view;
  final StorylineMilestoneAt at;
  final List<GameBehaviourRow> behaviours;
  final Future<bool> Function(String eventId) navigate;
  final SceneOpener? openScene;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final milestone = at.milestone;
    final storylineId = at.storyline.id;
    final chapterId = at.chapter.id;
    final editable = trame.staging.editable;
    final position = at.chapter.milestones.indexOf(milestone);
    final maps = {for (final map in trame.source().maps) map.id: map.name};
    final factId = milestone.completionFactId;
    final factName = factId == null ? null : trame.factName(factId);
    final outside = [
      for (final row in behaviours)
        if (row.record case final record?
            when view.outside(record) && record.sceneId != null)
          row,
    ];
    void move(String targetChapterId, int targetIndex) => unawaited(
      trame.moveMilestone(
        storylineId,
        chapterId,
        milestone.id,
        targetChapterId: targetChapterId,
        targetIndex: targetIndex,
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(StudioSpacing.xl),
      children: [
        MapBuilderNameField(
          key: ValueKey('trame-milestone-name-${milestone.id}'),
          value: milestone.title,
          label: l10n.trameMilestoneName,
          enabled: editable,
          onCommit: (title) => unawaited(
            trame.renameMilestone(
              storylineId,
              chapterId,
              milestone.id,
              title,
              completionFactId: factId,
            ),
          ),
        ),
        StudioToggleRow(
          key: const ValueKey('trame-milestone-archived'),
          label: l10n.trameArchived,
          value: trameArchived(milestone.status),
          onChanged: editable
              ? (value) => unawaited(
                  trame.archiveMilestone(
                    storylineId,
                    chapterId,
                    milestone.id,
                    archived: value,
                  ),
                )
              : null,
        ),
        Wrap(
          spacing: StudioSpacing.s,
          runSpacing: StudioSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StudioButton(
              key: const ValueKey('trame-milestone-up'),
              label: l10n.trameMoveUp,
              icon: Icons.arrow_upward,
              variant: StudioButtonVariant.secondary,
              onPressed: editable && position > 0
                  ? () => move(chapterId, position - 1)
                  : null,
            ),
            StudioButton(
              key: const ValueKey('trame-milestone-down'),
              label: l10n.trameMoveDown,
              icon: Icons.arrow_downward,
              variant: StudioButtonVariant.secondary,
              onPressed: editable && position < at.chapter.milestones.length - 1
                  ? () => move(chapterId, position + 1)
                  : null,
            ),
            SizedBox(
              width: 240,
              child: KeyedSubtree(
                key: const ValueKey('trame-milestone-chapter'),
                child: StudioSelect(
                  label: l10n.trameMilestoneChapter,
                  value: chapterId,
                  options: {
                    for (final chapter in at.storyline.chapters)
                      chapter.id: l10n.trameName(
                        chapter.title,
                        l10n.trameUnnamed,
                      ),
                  },
                  onChanged: editable
                      ? (target) => move(
                          target,
                          at.storyline.chapters
                              .firstWhere((chapter) => chapter.id == target)
                              .milestones
                              .length,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        StudioSection(
          title: l10n.trameMilestoneFacts,
          children: [
            Text(
              milestone.mapIds.isEmpty
                  ? l10n.trameNoMap
                  : l10n.trameMaps(
                      milestone.mapIds
                          .map((id) => maps[id] ?? l10n.behavioursMissingMap)
                          .join(', '),
                    ),
              key: const ValueKey('trame-milestone-maps'),
            ),
            Text(l10n.trameBehaviourCount(view.behavioursOf(milestone).length)),
            Text(
              factId == null
                  ? l10n.trameNoCompletion
                  : l10n.trameCompletion(factName ?? l10n.memoryUnknownFact),
              key: const ValueKey('trame-milestone-completion'),
            ),
            for (final issue in milestone.issues) ...[
              const SizedBox(height: StudioSpacing.s),
              StudioNotice(
                key: ValueKey('trame-issue-${issue.name}'),
                l10n.trameIssue(issue),
              ),
            ],
          ],
        ),
        TrameMilestoneJournal(
          trame: trame,
          storylineId: storylineId,
          chapterId: chapterId,
          milestoneId: milestone.id,
          milestoneTitle: milestone.title,
        ),
        StudioSection(
          title: l10n.trameStartsWith,
          children: [
            if (milestone.sceneIds.isEmpty)
              Text(l10n.trameNoBehaviour, style: theme.textTheme.bodySmall),
            for (final sceneId in milestone.sceneIds)
              TrameSceneGroup(
                trame: trame,
                view: view,
                sceneId: sceneId,
                behaviours: behaviours,
                navigate: navigate,
                onOpen: openScene == null
                    ? null
                    : () => openScene!(sceneId, null),
                onDetach: editable
                    ? () => unawaited(
                        trame.detachScene(
                          storylineId,
                          chapterId,
                          milestone.id,
                          sceneId,
                        ),
                      )
                    : null,
              ),
            const SizedBox(height: StudioSpacing.m),
            if (outside.isNotEmpty)
              KeyedSubtree(
                key: const ValueKey('trame-attach'),
                child: StudioSelect(
                  label: l10n.trameAttach,
                  value: null,
                  options: {
                    for (final row in outside)
                      row.id: l10n.trameBehaviourOption(
                        row.name,
                        row.mapName ?? l10n.behavioursWithoutMap,
                      ),
                  },
                  onChanged: editable
                      ? (id) => unawaited(
                          trame.attachScene(
                            storylineId,
                            chapterId,
                            milestone.id,
                            outside
                                .firstWhere((row) => row.id == id)
                                .record!
                                .sceneId!,
                          ),
                        )
                      : null,
                ),
              ),
            Text(l10n.trameAttachWholeScene, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
