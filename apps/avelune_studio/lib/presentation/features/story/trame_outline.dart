import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_view.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'trame_chapters.dart';
import 'trame_create_story.dart';
import 'trame_labels.dart';
import 'trame_milestones.dart';
import 'trame_selection.dart';

class TrameOutline extends StatelessWidget {
  const TrameOutline({
    super.key,
    required this.trame,
    required this.view,
    required this.selection,
    required this.showArchived,
    required this.onShowArchived,
    required this.onSelected,
  });

  final StorylineTrameController trame;
  final StorylineTrameView view;
  final TrameSelection? selection;
  final bool showArchived;
  final ValueChanged<bool> onShowArchived;
  final ValueChanged<TrameSelection> onSelected;

  Future<void> _create(BuildContext context) async {
    final id = await showTrameCreateStory(context, trame);
    if (id != null && context.mounted) {
      onSelected((
        item: TrameItem.storyline,
        storylineId: id,
        chapterId: null,
        milestoneId: null,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stories = [
      for (final story in view.outline.storylines)
        if (showArchived || !trameArchived(story.status)) story,
    ];
    final selected = selection;
    final story =
        stories
            .where((story) => story.id == selected?.storylineId)
            .firstOrNull ??
        stories.firstOrNull;
    final chapters = [
      for (final chapter
          in story?.chapters ?? const <StorylineOutlineChapter>[])
        if (showArchived || !trameArchived(chapter.status)) chapter,
    ];
    final chapter =
        chapters
            .where((chapter) => chapter.id == selected?.chapterId)
            .firstOrNull ??
        chapters.firstOrNull;
    final editable = trame.staging.editable;
    final (horizontal, top) = switch (MediaQuery.sizeOf(context).width) {
      <= 1150 => (StudioSpacing.xl, 22.0),
      <= 1390 => (22.0, 28.0),
      _ => (28.0, 28.0),
    };
    return ListView(
      key: const ValueKey('trame-outline'),
      padding: EdgeInsets.fromLTRB(
        horizontal,
        top,
        horizontal,
        StudioSpacing.xl,
      ),
      children: [
        if (trame.refusal case final code?)
          StudioNotice(
            l10n.trameRefused(code),
            key: const ValueKey('trame-refusal'),
            isError: true,
          ),
        Wrap(
          spacing: StudioSpacing.l,
          runSpacing: StudioSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (stories.length > 1)
              SizedBox(
                width: 300,
                child: KeyedSubtree(
                  key: const ValueKey('trame-story-picker'),
                  child: StudioSelect(
                    label: l10n.trameStorylineName,
                    value: story?.id,
                    options: {
                      for (final item in stories)
                        item.id: l10n.trameName(item.title, l10n.trameUnnamed),
                    },
                    onChanged: (id) => onSelected((
                      item: TrameItem.storyline,
                      storylineId: id,
                      chapterId: null,
                      milestoneId: null,
                    )),
                  ),
                ),
              ),
            SizedBox(
              width: 240,
              child: StudioToggleRow(
                key: const ValueKey('trame-show-archived'),
                label: l10n.trameShowArchived,
                value: showArchived,
                onChanged: onShowArchived,
              ),
            ),
            StudioButton(
              key: const ValueKey('trame-story-add'),
              label: l10n.trameCreateStory,
              icon: Icons.add,
              variant: StudioButtonVariant.quiet,
              onPressed: editable ? () => unawaited(_create(context)) : null,
            ),
          ],
        ),
        if (story != null) ...[
          const SizedBox(height: StudioSpacing.l),
          StudioChoice(
            key: ValueKey('trame-storyline-${story.id}'),
            label: l10n.trameName(story.title, l10n.trameUnnamed),
            subtitle: l10n.trameType(story.type),
            leading: const Icon(Icons.menu_book_outlined),
            trailing: StudioBadge(
              l10n.trameChapterCount(story.chapters.length),
            ),
            selected:
                selected?.item == TrameItem.storyline &&
                selected?.storylineId == story.id,
            onTap: () => onSelected((
              item: TrameItem.storyline,
              storylineId: story.id,
              chapterId: null,
              milestoneId: null,
            )),
          ),
          const SizedBox(height: StudioSpacing.l),
          TrameChapters(
            story: story,
            chapters: chapters,
            selectedId: chapter?.id,
            onSelected: (id) => onSelected((
              item: TrameItem.chapter,
              storylineId: story.id,
              chapterId: id,
              milestoneId: null,
            )),
            onAdd: editable
                ? () => unawaited(
                    trame.createChapter(story.id, l10n.trameNewChapter),
                  )
                : null,
          ),
          const SizedBox(height: StudioSpacing.xl),
          if (chapter != null)
            TrameMilestones(
              trame: trame,
              view: view,
              story: story,
              chapter: chapter,
              selectedId: selected?.milestoneId,
              showArchived: showArchived,
              onSelected: (id) => onSelected((
                item: TrameItem.milestone,
                storylineId: story.id,
                chapterId: chapter.id,
                milestoneId: id,
              )),
            ),
        ] else
          StudioEmptyState(
            icon: Icons.archive_outlined,
            title: l10n.trameNoActiveStory,
          ),
        if (stories.any(
          (item) => item.id != story?.id && item.type != StorylineType.main,
        ))
          StudioSection(
            title: l10n.trameOtherStories,
            children: [
              for (final item in stories)
                if (item.id != story?.id && item.type != StorylineType.main)
                  StudioChoice(
                    key: ValueKey('trame-other-story-${item.id}'),
                    label: l10n.trameName(item.title, l10n.trameUnnamed),
                    subtitle:
                        '${l10n.trameType(item.type)} · ${l10n.trameChapterCount(item.chapters.length)}',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onSelected((
                      item: TrameItem.storyline,
                      storylineId: item.id,
                      chapterId: null,
                      milestoneId: null,
                    )),
                  ),
            ],
          ),
        const SizedBox(height: StudioSpacing.xl),
        StudioChoice(
          key: const ValueKey('trame-outside-outside'),
          label: l10n.trameOutside,
          subtitle: l10n.trameOutsideCount(view.outsideBehaviours.length),
          leading: const Icon(Icons.explore_outlined),
          trailing: const Icon(Icons.chevron_right),
          selected: selected?.item == TrameItem.outside,
          onTap: () => onSelected(trameOutside),
        ),
        const SizedBox(height: StudioSpacing.l),
        StudioNotice(l10n.trameOrganizationHint),
      ],
    );
  }
}
