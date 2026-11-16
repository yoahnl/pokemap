import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_rows.dart';
import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/features/storyline/application/storyline_scene_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_view.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'trame_behaviours.dart';

class TrameSceneLinks extends StatefulWidget {
  const TrameSceneLinks({
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
  State<TrameSceneLinks> createState() => _TrameSceneLinksState();
}

class _TrameSceneLinksState extends State<TrameSceneLinks> {
  int _pickerEpoch = 0;

  Future<void> _attach(BuildContext context, String sceneId) async {
    final trame = widget.trame;
    final view = widget.view;
    final at = widget.at;
    await trame.attachSceneReviewed(
      at.storyline.id,
      at.chapter.id,
      at.milestone.id,
      sceneId,
      confirmMove: (origins) async {
        if (!context.mounted) return false;
        final l10n = context.l10n;
        final titles = [
          for (final origin in origins)
            if (view.milestone(origin.stepId) case final location?)
              '${location.storyline.title} · ${location.chapter.title} · ${location.milestone.title}',
        ];
        if (titles.length != origins.length) return false;
        return await showDialog<bool>(
              context: context,
              builder: (context) => StudioReviewDialog(
                key: const ValueKey('trame-move-scene-review'),
                title: l10n.trameMoveSceneTitle,
                content: Text(
                  l10n.trameMoveSceneHint(
                    titles.join(', '),
                    '${at.storyline.title} · ${at.chapter.title} · ${at.milestone.title}',
                  ),
                ),
                confirmLabel: l10n.trameMoveSceneConfirm,
                cancelLabel: l10n.memoryCancel,
                onConfirmed: () => Navigator.of(context).pop(true),
                onCancelled: () => Navigator.of(context).pop(false),
              ),
            ) ??
            false;
      },
    );
    if (mounted) setState(() => _pickerEpoch++);
  }

  @override
  Widget build(BuildContext context) {
    final trame = widget.trame;
    final view = widget.view;
    final at = widget.at;
    final l10n = context.l10n;
    final editable = trame.staging.editable;
    final titles = <String, String>{
      for (final title in trame.sceneTitles.value ?? const [])
        title.id: title.title,
      for (final scene in trame.source().scenes) scene.id: scene.name,
    };
    final options = {
      for (final entry in titles.entries)
        if (!at.milestone.sceneIds.contains(entry.key) &&
            !(trame.staging.draft.isTouched(StoryDraftKind.scene, entry.key) &&
                trame.staging.draft
                        .entryOf(StoryDraftKind.scene, entry.key)!
                        .current ==
                    null))
          entry.key: entry.value,
    };
    return StudioSection(
      title: l10n.trameStartsWith,
      children: [
        if (at.milestone.sceneIds.isEmpty) Text(l10n.trameNoLinkedScene),
        for (final sceneId in at.milestone.sceneIds)
          TrameSceneGroup(
            trame: trame,
            view: view,
            sceneId: sceneId,
            behaviours: widget.behaviours,
            navigate: widget.navigate,
            onOpen: widget.openScene == null
                ? null
                : () => widget.openScene!(sceneId, null),
            onDetach: editable
                ? () => unawaited(
                    trame.detachScene(
                      at.storyline.id,
                      at.chapter.id,
                      at.milestone.id,
                      sceneId,
                    ),
                  )
                : null,
          ),
        if (options.isNotEmpty)
          KeyedSubtree(
            key: const ValueKey('trame-link-scene'),
            child: StudioSelect(
              key: ValueKey(_pickerEpoch),
              label: l10n.trameLinkScene,
              value: null,
              options: options,
              onChanged: editable
                  ? (id) => unawaited(_attach(context, id))
                  : null,
            ),
          ),
        const SizedBox(height: StudioSpacing.s),
        Text(
          l10n.trameAttachWholeScene,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
