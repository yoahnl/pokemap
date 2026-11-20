import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'trame_labels.dart';

class TrameChapters extends StatelessWidget {
  const TrameChapters({
    super.key,
    required this.story,
    required this.chapters,
    required this.selectedId,
    required this.onSelected,
    required this.onAdd,
  });

  final StorylineOutlineStoryline story;
  final List<StorylineOutlineChapter> chapters;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: const ValueKey('trame-chapters'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioPageHeader(
          title: l10n.trameChapters,
          description: l10n.trameChaptersHint,
          compact: true,
          alignActionsToEnd: true,
          actions: [
            StudioButton(
              key: const ValueKey('trame-outline-chapter-add'),
              label: l10n.trameAddChapter,
              icon: Icons.add,
              variant: StudioButtonVariant.quiet,
              onPressed: onAdd,
            ),
          ],
        ),
        if (chapters.isEmpty)
          Text(l10n.trameNoChapter)
        else
          LayoutBuilder(
            builder: (context, area) {
              final gaps = (chapters.length - 1) * StudioSpacing.m;
              final width = ((area.maxWidth - gaps) / chapters.length).clamp(
                160.0,
                260.0,
              );
              final theme = Theme.of(context);
              return SingleChildScrollView(
                key: PageStorageKey('trame-chapters-${story.id}'),
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: StudioSpacing.m,
                  children: [
                    for (final chapter in chapters)
                      SizedBox(
                        width: width,
                        child: StudioChoice(
                          key: ValueKey('trame-chapter-${chapter.id}'),
                          leading: Text(
                            '${story.chapters.indexOf(chapter) + 1}'.padLeft(
                              2,
                              '0',
                            ),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: StudioAccent.water.color(context),
                            ),
                          ),
                          label: l10n.trameName(
                            chapter.title,
                            l10n.trameUnnamed,
                          ),
                          subtitle: l10n.trameMilestoneCount(
                            chapter.milestones.length,
                          ),
                          trailing: trameArchived(chapter.status)
                              ? StudioBadge(l10n.trameArchivedBadge)
                              : const Icon(Icons.chevron_right, size: 16),
                          selected: chapter.id == selectedId,
                          onTap: () => onSelected(chapter.id),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
