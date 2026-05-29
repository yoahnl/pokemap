import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        ExpansionPanel,
        ExpansionPanelList,
        NoSplash,
        ReorderableDragStartListener,
        ReorderableListView,
        Theme;
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

typedef StorylineStepAction = void Function(
  StorylineChapter chapter,
  StorylineStep step,
);

typedef StorylineStepReorder = void Function(
  StorylineChapter chapter,
  int oldIndex,
  int newIndex,
);

class StorylinesStructureView extends StatelessWidget {
  const StorylinesStructureView({
    super.key,
    required this.storyline,
    required this.selectedChapter,
    required this.onChapterSelected,
    required this.onCreateChapter,
    required this.onEditChapter,
    required this.onCreateStep,
    required this.onEditStep,
    required this.onReorderSteps,
    required this.onAttachSideQuest,
  });

  final StorylineAsset? storyline;
  final StorylineChapter? selectedChapter;
  final ValueChanged<StorylineChapter?> onChapterSelected;
  final VoidCallback? onCreateChapter;
  final ValueChanged<StorylineChapter>? onEditChapter;
  final VoidCallback? onCreateStep;
  final StorylineStepAction? onEditStep;
  final StorylineStepReorder? onReorderSteps;
  final VoidCallback? onAttachSideQuest;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final storyline = this.storyline;
    if (storyline == null) {
      return KeyedSubtree(
        key: const ValueKey('storylines-structure-read-only'),
        child: Center(
          child: Text(
            'Créez une storyline pour commencer.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final chapters = _orderedChapters(storyline);
    final selectedChapter = _selectedChapterFrom(chapters);
    return KeyedSubtree(
      key: const ValueKey('storylines-structure-read-only'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            key: const ValueKey('storylines-structure-view'),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StructureToolbar(
                    storyline: storyline,
                    onCreateChapter: onCreateChapter,
                    onAttachSideQuest: onAttachSideQuest,
                  ),
                  const SizedBox(height: 12),
                  _ChapterAccordionList(
                    storyline: storyline,
                    chapters: chapters,
                    selectedChapter: selectedChapter,
                    onChapterSelected: onChapterSelected,
                    onEditChapter: onEditChapter,
                    onCreateStep: onCreateStep,
                    onEditStep: onEditStep,
                    onReorderSteps: onReorderSteps,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  StorylineChapter? _selectedChapterFrom(List<StorylineChapter> chapters) {
    final selectedChapter = this.selectedChapter;
    if (selectedChapter != null) {
      for (final chapter in chapters) {
        if (chapter.id == selectedChapter.id) {
          return chapter;
        }
      }
    }
    return null;
  }
}

class _StructureToolbar extends StatelessWidget {
  const _StructureToolbar({
    required this.storyline,
    required this.onCreateChapter,
    required this.onAttachSideQuest,
  });

  final StorylineAsset storyline;
  final VoidCallback? onCreateChapter;
  final VoidCallback? onAttachSideQuest;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('storylines-structure-toolbar'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.square_stack_3d_up,
                tone: PokeMapTone.narrative,
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chapitres',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      storyline.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StructureCompactMetric(
                value: storyline.chapters.length.toString(),
                label: 'Chapitres',
              ),
              const SizedBox(width: 8),
              _StructureCompactMetric(
                value: _storylineStepCount(storyline).toString(),
                label: 'Étapes',
              ),
              const SizedBox(width: 8),
              _StructureCompactMetric(
                value: storyline.sceneLinks.length.toString(),
                label: 'Scènes',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const PokeMapButton(
                key: ValueKey('storylines-structure-search-action'),
                onPressed: null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: Icon(CupertinoIcons.search),
                child: Text('Recherche'),
              ),
              const PokeMapButton(
                key: ValueKey('storylines-structure-filter-action'),
                onPressed: null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: Icon(CupertinoIcons.slider_horizontal_3),
                child: Text('Filtre'),
              ),
              const PokeMapButton(
                key: ValueKey('storylines-structure-sort-action'),
                onPressed: null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: Icon(CupertinoIcons.arrow_up_arrow_down),
                child: Text('Tri'),
              ),
              const PokeMapButton(
                key: ValueKey('storylines-link-scene-disabled'),
                onPressed: null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: Icon(CupertinoIcons.link),
                child: Text('Lier une scène'),
              ),
              if (storyline.type == StorylineType.sideQuest)
                PokeMapButton(
                  key: const ValueKey('storylines-attach-sidequest-action'),
                  onPressed: _sideQuestMainAttachment(storyline) == null
                      ? onAttachSideQuest
                      : null,
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.link),
                  child: Text(
                    _sideQuestMainAttachment(storyline) == null
                        ? 'Attacher'
                        : 'Déjà attachée',
                  ),
                ),
              PokeMapButton(
                key: const ValueKey('storylines-new-chapter-action'),
                onPressed: onCreateChapter,
                variant: PokeMapButtonVariant.primary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.add),
                child: const Text('Nouveau chapitre'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChapterAccordionList extends StatelessWidget {
  const _ChapterAccordionList({
    required this.storyline,
    required this.chapters,
    required this.selectedChapter,
    required this.onChapterSelected,
    required this.onEditChapter,
    required this.onCreateStep,
    required this.onEditStep,
    required this.onReorderSteps,
  });

  final StorylineAsset storyline;
  final List<StorylineChapter> chapters;
  final StorylineChapter? selectedChapter;
  final ValueChanged<StorylineChapter?> onChapterSelected;
  final ValueChanged<StorylineChapter>? onEditChapter;
  final VoidCallback? onCreateStep;
  final StorylineStepAction? onEditStep;
  final StorylineStepReorder? onReorderSteps;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    if (chapters.isEmpty) {
      return PokeMapCard(
        key: const ValueKey('storylines-structure-accordion-list'),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aucun chapitre',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez un premier chapitre pour organiser la progression de la storyline.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('storylines-structure-accordion-list'),
      child: Theme(
        data: Theme.of(context).copyWith(splashFactory: NoSplash.splashFactory),
        child: ExpansionPanelList(
          key: const ValueKey('storylines-chapter-native-panel-list'),
          elevation: 0,
          materialGapSize: 10,
          expandedHeaderPadding: EdgeInsets.zero,
          dividerColor: colors.borderSubtle,
          expansionCallback: (index, isExpanded) {
            onChapterSelected(isExpanded ? null : chapters[index]);
          },
          children: [
            for (final chapter in chapters)
              _chapterExpansionPanel(
                context: context,
                storyline: storyline,
                chapter: chapter,
                expanded: chapter.id == selectedChapter?.id,
              ),
          ],
        ),
      ),
    );
  }

  ExpansionPanel _chapterExpansionPanel({
    required BuildContext context,
    required StorylineAsset storyline,
    required StorylineChapter chapter,
    required bool expanded,
  }) {
    final colors = context.pokeMapColors;
    return ExpansionPanel(
      canTapOnHeader: true,
      isExpanded: expanded,
      backgroundColor: colors.cardSurface,
      headerBuilder: (context, isExpanded) => KeyedSubtree(
        key: ValueKey('storylines-chapter-accordion-${chapter.id}'),
        child: _ChapterAccordionHeader(
          storyline: storyline,
          chapter: chapter,
          expanded: expanded,
          onToggle: () => onChapterSelected(expanded ? null : chapter),
          onEditChapter:
              onEditChapter == null ? null : () => onEditChapter!(chapter),
        ),
      ),
      body: expanded
          ? Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: _ExpandedChapterBody(
                chapter: chapter,
                onCreateStep: onCreateStep,
                onEditStep: onEditStep,
                onReorderSteps: onReorderSteps,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _ChapterAccordionHeader extends StatelessWidget {
  const _ChapterAccordionHeader({
    required this.storyline,
    required this.chapter,
    required this.expanded,
    required this.onToggle,
    required this.onEditChapter,
  });

  final StorylineAsset storyline;
  final StorylineChapter chapter;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback? onEditChapter;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: GestureDetector(
        key: ValueKey('storylines-chapter-toggle-${chapter.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: KeyedSubtree(
          key: ValueKey(
            expanded
                ? 'storylines-chapter-expanded-${chapter.id}'
                : 'storylines-chapter-collapsed-${chapter.id}',
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.bookmark,
                tone: PokeMapTone.narrative,
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chapitre ${chapter.order + 1}',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      chapter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: expanded ? 16 : 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      chapter.description ?? 'Aucune description.',
                      maxLines: expanded ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ChapterHeaderMetrics(
                chapter: chapter,
                attachedSideQuestCount:
                    _attachedSideQuestCount(storyline, chapter),
              ),
              const SizedBox(width: 10),
              PokeMapButton(
                key: ValueKey('storylines-edit-chapter-action-${chapter.id}'),
                onPressed: onEditChapter,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.pencil),
                child: const Text('Modifier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterHeaderMetrics extends StatelessWidget {
  const _ChapterHeaderMetrics({
    required this.chapter,
    required this.attachedSideQuestCount,
  });

  final StorylineChapter chapter;
  final int attachedSideQuestCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        _StructureBadge(
          label: _formatCount(chapter.steps.length, 'étape', 'étapes'),
        ),
        _StructureBadge(
          label: _formatCount(
            _chapterSceneLinkCount(chapter),
            'scène liée',
            'scènes liées',
          ),
        ),
        if (attachedSideQuestCount > 0)
          _StructureBadge(
            label: _formatCount(
              attachedSideQuestCount,
              'quête disponible',
              'quêtes disponibles',
            ),
          ),
      ],
    );
  }
}

class _ExpandedChapterBody extends StatelessWidget {
  const _ExpandedChapterBody({
    required this.chapter,
    required this.onCreateStep,
    required this.onEditStep,
    required this.onReorderSteps,
  });

  final StorylineChapter chapter;
  final VoidCallback? onCreateStep;
  final StorylineStepAction? onEditStep;
  final StorylineStepReorder? onReorderSteps;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final steps = _orderedSteps(chapter);
    return Column(
      key: const ValueKey('storylines-v1-structure-steps'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Étapes narratives',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            PokeMapButton(
              key: const ValueKey('storylines-new-step-action'),
              onPressed: onCreateStep,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.add),
              child: const Text('Nouvelle étape narrative'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (steps.isEmpty)
          PokeMapCard(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Aucune étape narrative. Ajoutez une première étape pour définir la progression du chapitre.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          )
        else
          ReorderableListView.builder(
            key: ValueKey('storylines-steps-reorder-list-${chapter.id}'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (oldIndex, newIndex) {
              onReorderSteps?.call(chapter, oldIndex, newIndex);
            },
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return Padding(
                key: ValueKey('storylines-step-row-wrapper-${step.id}'),
                padding: const EdgeInsets.only(bottom: 8),
                child: _StructureStepRow(
                  chapter: chapter,
                  step: step,
                  index: index,
                  onEditStep: onEditStep,
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        const _SceneLinkNotice(),
      ],
    );
  }
}

class _StructureStepRow extends StatelessWidget {
  const _StructureStepRow({
    required this.chapter,
    required this.step,
    required this.index,
    required this.onEditStep,
  });

  final StorylineChapter chapter;
  final StorylineStep step;
  final int index;
  final StorylineStepAction? onEditStep;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final sceneLinkCount = step.sceneLinkIds.length;
    return PokeMapCard(
      key: ValueKey('storylines-step-row-${step.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            key: ValueKey('storylines-step-drag-${step.id}'),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(
                CupertinoIcons.line_horizontal_3,
                color: colors.textMuted,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _StructureBadge(label: 'Étape ${step.order + 1}'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description ?? 'Aucune description.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StructureBadge(
            label: sceneLinkCount == 0
                ? 'Aucune scène liée'
                : _formatCount(
                    sceneLinkCount,
                    'scène liée',
                    'scènes liées',
                  ),
          ),
          const SizedBox(width: 8),
          PokeMapButton(
            key: ValueKey('storylines-edit-step-action-${step.id}'),
            onPressed:
                onEditStep == null ? null : () => onEditStep!(chapter, step),
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.pencil),
            child: const Text('Éditer'),
          ),
        ],
      ),
    );
  }
}

class _SceneLinkNotice extends StatelessWidget {
  const _SceneLinkNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('storylines-v1-structure-scenes'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.link,
            tone: PokeMapTone.neutral,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Liaison de scène à venir : aucune scène placeholder ni sceneLink n’est créé depuis cette vue.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StructureCompactMetric extends StatelessWidget {
  const _StructureCompactMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StructureBadge extends StatelessWidget {
  const _StructureBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Text(
        label,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

List<StorylineChapter> _orderedChapters(StorylineAsset storyline) {
  return [...storyline.chapters]..sort((a, b) {
      final order = a.order.compareTo(b.order);
      if (order != 0) return order;
      final title = a.title.compareTo(b.title);
      if (title != 0) return title;
      return a.id.compareTo(b.id);
    });
}

List<StorylineStep> _orderedSteps(StorylineChapter chapter) {
  return [...chapter.steps]..sort((a, b) {
      final order = a.order.compareTo(b.order);
      if (order != 0) return order;
      final title = a.title.compareTo(b.title);
      if (title != 0) return title;
      return a.id.compareTo(b.id);
    });
}

int _storylineStepCount(StorylineAsset storyline) {
  return storyline.chapters.fold<int>(
    0,
    (total, chapter) => total + chapter.steps.length,
  );
}

int _chapterSceneLinkCount(StorylineChapter chapter) {
  return chapter.directSceneLinkIds.length +
      chapter.steps.fold<int>(
        0,
        (total, step) => total + step.sceneLinkIds.length,
      );
}

int _attachedSideQuestCount(
  StorylineAsset storyline,
  StorylineChapter chapter,
) {
  if (storyline.type != StorylineType.main) {
    return 0;
  }
  final chapterStepIds = chapter.steps.map((step) => step.id).toSet();
  var count = 0;
  for (final relationship in storyline.relationships) {
    if (relationship.kind !=
        StorylineRelationshipKind.sideQuestAvailableDuring) {
      continue;
    }
    final anchor =
        relationship.anchor ?? relationship.availability?.startAnchor;
    if (anchor == null) continue;
    if (anchor.kind == StorylineAnchorKind.chapter &&
        anchor.targetId == chapter.id) {
      count += 1;
    }
    if (anchor.kind == StorylineAnchorKind.step &&
        chapterStepIds.contains(anchor.targetId)) {
      count += 1;
    }
  }
  return count;
}

String _formatCount(int count, String singular, String plural) {
  return '$count ${count == 1 ? singular : plural}';
}

StorylineRelationship? _sideQuestMainAttachment(StorylineAsset storyline) {
  if (storyline.type != StorylineType.sideQuest) {
    return null;
  }
  for (final relationship in storyline.relationships) {
    if (relationship.kind ==
            StorylineRelationshipKind.sideQuestAvailableDuring ||
        relationship.kind == StorylineRelationshipKind.sideQuestUnlockedBy) {
      return relationship;
    }
  }
  return null;
}
