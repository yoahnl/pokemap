import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class StorylinesStructureView extends StatelessWidget {
  const StorylinesStructureView({
    super.key,
    required this.storyline,
    required this.selectedChapter,
    required this.onChapterSelected,
    required this.onCreateChapter,
    required this.onCreateStep,
    required this.onAttachSideQuest,
  });

  final StorylineAsset? storyline;
  final StorylineChapter? selectedChapter;
  final ValueChanged<StorylineChapter> onChapterSelected;
  final VoidCallback? onCreateChapter;
  final VoidCallback? onCreateStep;
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

    final selectedChapter = this.selectedChapter;
    final collapsedChapters = storyline.chapters
        .where((chapter) => chapter.id != selectedChapter?.id)
        .toList();
    return KeyedSubtree(
      key: const ValueKey('storylines-structure-read-only'),
      child: SingleChildScrollView(
        key: const ValueKey('storylines-structure-view'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StructureActionBar(
              storyline: storyline,
              onCreateChapter: onCreateChapter,
              onAttachSideQuest: onAttachSideQuest,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _SelectedChapterPanel(
                    storyline: storyline,
                    chapter: selectedChapter,
                    onCreateStep: onCreateStep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _CollapsedChaptersPanel(
                    chapters: collapsedChapters,
                    hasSelectedChapter: selectedChapter != null,
                    onChapterSelected: onChapterSelected,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _StructureSceneLinksPanel(),
          ],
        ),
      ),
    );
  }
}

class _StructureActionBar extends StatelessWidget {
  const _StructureActionBar({
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
      key: const ValueKey('storylines-structure-action-bar'),
      padding: const EdgeInsets.all(14),
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
                      'Structure de la storyline',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
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
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StructureCompactMetric(
                value: storyline.chapters.length.toString(),
                label: 'Chapitres',
              ),
              _StructureCompactMetric(
                value: _storylineStepCount(storyline).toString(),
                label: 'Étapes',
              ),
              _StructureCompactMetric(
                value: storyline.sceneLinks.length.toString(),
                label: 'Scene links',
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

class _SelectedChapterPanel extends StatelessWidget {
  const _SelectedChapterPanel({
    required this.storyline,
    required this.chapter,
    required this.onCreateStep,
  });

  final StorylineAsset storyline;
  final StorylineChapter? chapter;
  final VoidCallback? onCreateStep;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final chapter = this.chapter;
    return KeyedSubtree(
      key: const ValueKey('storylines-selected-chapter-expanded'),
      child: PokeMapCard(
        key: chapter == null
            ? null
            : ValueKey('storylines-chapter-row-${chapter.id}'),
        padding: const EdgeInsets.all(18),
        selected: chapter != null,
        child: chapter == null
            ? _NoSelectedChapter(storyline: storyline)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PokeMapIconTile(
                        icon: CupertinoIcons.bookmark_fill,
                        tone: PokeMapTone.narrative,
                        size: 38,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Détail du chapitre',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              chapter.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              chapter.description ??
                                  'Aucune description renseignée.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
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
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StructureBadge(label: 'Ordre ${chapter.order}'),
                      _StructureBadge(
                        label: _formatCount(
                          chapter.steps.length,
                          'étape narrative',
                          'étapes narratives',
                        ),
                      ),
                      _StructureBadge(
                        label: _formatCount(
                          _chapterSceneLinkCount(chapter),
                          'scene link',
                          'scene links',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SelectedChapterSteps(chapter: chapter),
                ],
              ),
      ),
    );
  }
}

class _NoSelectedChapter extends StatelessWidget {
  const _NoSelectedChapter({required this.storyline});

  final StorylineAsset storyline;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
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
        const SizedBox(height: 8),
        Text(
          storyline.chapters.isEmpty
              ? 'Aucun chapitre\nCréez un premier chapitre pour organiser votre histoire.'
              : 'Sélectionnez un chapitre pour voir ses étapes narratives.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: const ValueKey('storylines-v1-structure-steps'),
          child: Text(
            'Étapes narratives',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedChapterSteps extends StatelessWidget {
  const _SelectedChapterSteps({required this.chapter});

  final StorylineChapter chapter;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      key: const ValueKey('storylines-v1-structure-steps'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Étapes narratives',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (chapter.steps.isEmpty)
          Text(
            'Aucune étape narrative\nAjoutez une première étape pour définir la progression du chapitre.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          )
        else
          ...chapter.steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StructureStepRow(step: step),
            ),
          ),
      ],
    );
  }
}

class _CollapsedChaptersPanel extends StatelessWidget {
  const _CollapsedChaptersPanel({
    required this.chapters,
    required this.hasSelectedChapter,
    required this.onChapterSelected,
  });

  final List<StorylineChapter> chapters;
  final bool hasSelectedChapter;
  final ValueChanged<StorylineChapter> onChapterSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      key: const ValueKey('storylines-structure-chapters-zone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                hasSelectedChapter ? 'Autres chapitres' : 'Chapitres',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              chapters.isEmpty && hasSelectedChapter
                  ? 'Aucun autre chapitre'
                  : _formatCount(chapters.length, 'chapitre', 'chapitres'),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (chapters.isEmpty)
          PokeMapCard(
            key: const ValueKey('storylines-collapsed-chapters'),
            padding: const EdgeInsets.all(12),
            child: Text(
              hasSelectedChapter
                  ? 'Le chapitre sélectionné est le seul chapitre.'
                  : 'Aucun chapitre fermé à afficher.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          )
        else
          Column(
            key: const ValueKey('storylines-collapsed-chapters'),
            children: [
              for (final chapter in chapters)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CollapsedChapterCard(
                    chapter: chapter,
                    onTap: () => onChapterSelected(chapter),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _CollapsedChapterCard extends StatelessWidget {
  const _CollapsedChapterCard({
    required this.chapter,
    required this.onTap,
  });

  final StorylineChapter chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: ValueKey('storylines-chapter-row-${chapter.id}'),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.bookmark,
            tone: PokeMapTone.neutral,
            size: 30,
          ),
          const SizedBox(width: 10),
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
                const SizedBox(height: 4),
                Text(
                  chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  chapter.description ?? 'Aucune description.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                _StructureBadge(
                  label: _formatCount(
                    chapter.steps.length,
                    'étape',
                    'étapes',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            CupertinoIcons.chevron_right,
            color: colors.textMuted,
            size: 14,
          ),
        ],
      ),
    );
  }
}

class _StructureStepRow extends StatelessWidget {
  const _StructureStepRow({required this.step});

  final StorylineStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final sceneLinkCount = step.sceneLinkIds.length;
    return PokeMapCard(
      key: ValueKey('storylines-step-row-${step.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.flag,
            tone: PokeMapTone.info,
            size: 28,
          ),
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
          const SizedBox(width: 12),
          _StructureBadge(
            label: sceneLinkCount == 0
                ? 'Aucune scène liée'
                : _formatCount(sceneLinkCount, 'scène liée', 'scènes liées'),
          ),
        ],
      ),
    );
  }
}

class _StructureSceneLinksPanel extends StatelessWidget {
  const _StructureSceneLinksPanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('storylines-v1-structure-scenes'),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scènes liées',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Scènes liées à venir. Les scènes seront reliées dans un prochain lot.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const PokeMapButton(
            key: ValueKey('storylines-link-scene-disabled'),
            onPressed: null,
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            child: Text('Lier une scène — bientôt'),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
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
