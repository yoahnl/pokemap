import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';

class StorylinesWorkspace extends ConsumerStatefulWidget {
  const StorylinesWorkspace({
    super.key,
    required this.projection,
    required this.selectedGlobalStoryId,
  });

  final NarrativeWorkspaceProjection projection;
  final String? selectedGlobalStoryId;

  @override
  ConsumerState<StorylinesWorkspace> createState() =>
      _StorylinesWorkspaceState();
}

class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
  _StorylineContentTab _selectedTab = _StorylineContentTab.graph;
  String? _selectedStorylineId;
  String? _selectedChapterId;

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorNotifierProvider);
    final project = editorState.project;
    final storylines = project?.storylines ?? const <StorylineAsset>[];
    final selectedStoryline = _selectedStoryline(storylines);
    final selectedChapter = _selectedChapter(selectedStoryline);
    final legacyGlobalStory = widget.projection.globalStories.isEmpty
        ? null
        : widget.projection.globalStories.first;
    final legacyStep =
        widget.projection.steps.isEmpty ? null : widget.projection.steps.first;
    final legacyStepCount = widget.projection.steps.length;

    return PokeMapPageSurface(
      key: const ValueKey('storylines-workspace-shell'),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 240,
            child: _StorylinesV1SecondaryPanel(
              storylines: storylines,
              selectedStorylineId: selectedStoryline?.id,
              legacyGlobalStory: legacyGlobalStory,
              onStorylineSelected: _selectStoryline,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StorylinesV1MainPanel(
              selectedStoryline: selectedStoryline,
              selectedChapter: selectedChapter,
              storylines: storylines,
              selectedTab: _selectedTab,
              legacyGlobalStory: legacyGlobalStory,
              legacyStep: legacyStep,
              legacyStepCount: legacyStepCount,
              canCreateMainStoryline: _canCreateMainStoryline(storylines),
              onTabSelected: _selectTab,
              onChapterSelected: _selectChapter,
              onCreateMainStoryline:
                  project == null || !_canCreateMainStoryline(storylines)
                      ? null
                      : () => _openCreateMainStorylineDialog(project),
              onCreateChapter: project == null || selectedStoryline == null
                  ? null
                  : () => _openCreateChapterDialog(project, selectedStoryline),
              onCreateStep: project == null ||
                      selectedStoryline == null ||
                      selectedChapter == null
                  ? null
                  : () => _openCreateStepDialog(
                        project,
                        selectedStoryline,
                        selectedChapter,
                      ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 280,
            child: _StorylinesV1InspectorPanel(
              selectedStoryline: selectedStoryline,
            ),
          ),
        ],
      ),
    );
  }

  StorylineAsset? _selectedStoryline(List<StorylineAsset> storylines) {
    final targetId = _selectedStorylineId;
    if (targetId != null) {
      for (final storyline in storylines) {
        if (storyline.id == targetId) {
          return storyline;
        }
      }
    }
    return storylines.isEmpty ? null : storylines.first;
  }

  bool _canCreateMainStoryline(List<StorylineAsset> storylines) {
    return !storylines.any((storyline) => storyline.type == StorylineType.main);
  }

  StorylineChapter? _selectedChapter(StorylineAsset? storyline) {
    if (storyline == null || storyline.chapters.isEmpty) {
      return null;
    }
    final targetId = _selectedChapterId;
    if (targetId != null) {
      for (final chapter in storyline.chapters) {
        if (chapter.id == targetId) {
          return chapter;
        }
      }
    }
    return storyline.chapters.first;
  }

  void _selectStoryline(StorylineAsset storyline) {
    if (_selectedStorylineId == storyline.id) {
      return;
    }
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId =
          storyline.chapters.isEmpty ? null : storyline.chapters.first.id;
    });
  }

  void _selectChapter(StorylineChapter chapter) {
    if (_selectedChapterId == chapter.id) {
      return;
    }
    setState(() {
      _selectedChapterId = chapter.id;
    });
  }

  void _selectTab(_StorylineContentTab tab) {
    if (_selectedTab == tab) {
      return;
    }
    setState(() {
      _selectedTab = tab;
    });
  }

  Future<void> _openCreateMainStorylineDialog(ProjectManifest project) async {
    final draft = await showCupertinoDialog<_CreateMainStorylineDraft>(
      context: context,
      builder: (context) => _CreateMainStorylineDialog(
        existingIds:
            project.storylines.map((storyline) => storyline.id).toSet(),
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    final storyline = StorylineAsset(
      id: _generateStorylineId(draft.title, project.storylines),
      type: StorylineType.main,
      status: StorylineStatus.draft,
      title: draft.title,
      description: draft.description,
    );
    final updated = project.copyWith(
      storylines: [...project.storylines, storyline],
    );
    ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
          updated,
          statusMessage: 'Storyline principale créée',
        );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = null;
      _selectedTab = _StorylineContentTab.graph;
    });
  }

  Future<void> _openCreateChapterDialog(
    ProjectManifest project,
    StorylineAsset storyline,
  ) async {
    final draft = await showCupertinoDialog<_StructureItemDraft>(
      context: context,
      builder: (context) => const _CreateStructureItemDialog(
        dialogKey: ValueKey('storylines-create-chapter-dialog'),
        title: 'Nouveau chapitre',
        titleFieldKey: ValueKey('storylines-create-chapter-title-field'),
        descriptionFieldKey: ValueKey(
          'storylines-create-chapter-description-field',
        ),
        cancelKey: ValueKey('storylines-create-chapter-cancel'),
        submitKey: ValueKey('storylines-create-chapter-submit'),
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    final chapter = StorylineChapter(
      id: _generateScopedId(
        prefix: 'chapter',
        title: draft.title,
        existingIds: storyline.chapters.map((chapter) => chapter.id).toSet(),
      ),
      title: draft.title,
      description: draft.description,
      order: _nextChapterOrder(storyline),
    );
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: [...storyline.chapters, chapter],
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
      statusMessage: 'Chapitre créé',
    );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = chapter.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  Future<void> _openCreateStepDialog(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
  ) async {
    final draft = await showCupertinoDialog<_StructureItemDraft>(
      context: context,
      builder: (context) => const _CreateStructureItemDialog(
        dialogKey: ValueKey('storylines-create-step-dialog'),
        title: 'Nouvelle étape narrative',
        titleFieldKey: ValueKey('storylines-create-step-title-field'),
        descriptionFieldKey: ValueKey(
          'storylines-create-step-description-field',
        ),
        cancelKey: ValueKey('storylines-create-step-cancel'),
        submitKey: ValueKey('storylines-create-step-submit'),
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    final step = StorylineStep(
      id: _generateScopedId(
        prefix: 'step',
        title: draft.title,
        existingIds: _storylineStepIds(storyline),
      ),
      title: draft.title,
      description: draft.description,
      order: _nextStepOrder(chapter),
    );
    final updatedChapter = _copyChapterWith(
      chapter,
      steps: [...chapter.steps, step],
    );
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: storyline.chapters
          .map(
            (current) => current.id == chapter.id ? updatedChapter : current,
          )
          .toList(growable: false),
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
      statusMessage: 'Étape narrative créée',
    );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = chapter.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  String _generateStorylineId(
    String title,
    List<StorylineAsset> storylines,
  ) {
    final existingIds = storylines.map((storyline) => storyline.id).toSet();
    return _generateScopedId(
      prefix: 'storyline',
      title: title,
      existingIds: existingIds,
      fallback: 'main',
    );
  }

  String _generateScopedId({
    required String prefix,
    required String title,
    required Set<String> existingIds,
    String fallback = 'item',
  }) {
    final slug = _slugifyStorylineTitle(title);
    final base = '${prefix}_${slug.isEmpty ? fallback : slug}';
    if (!existingIds.contains(base)) {
      return base;
    }
    var suffix = 2;
    while (existingIds.contains('${base}_$suffix')) {
      suffix += 1;
    }
    return '${base}_$suffix';
  }

  Set<String> _storylineStepIds(StorylineAsset storyline) {
    return {
      for (final chapter in storyline.chapters)
        for (final step in chapter.steps) step.id,
    };
  }

  int _nextChapterOrder(StorylineAsset storyline) {
    var nextOrder = 0;
    for (final chapter in storyline.chapters) {
      if (chapter.order >= nextOrder) {
        nextOrder = chapter.order + 1;
      }
    }
    return nextOrder;
  }

  int _nextStepOrder(StorylineChapter chapter) {
    var nextOrder = 0;
    for (final step in chapter.steps) {
      if (step.order >= nextOrder) {
        nextOrder = step.order + 1;
      }
    }
    return nextOrder;
  }

  void _applyStorylineUpdate(
    ProjectManifest project,
    StorylineAsset updatedStoryline, {
    required String statusMessage,
  }) {
    final updated = project.copyWith(
      storylines: project.storylines
          .map(
            (storyline) => storyline.id == updatedStoryline.id
                ? updatedStoryline
                : storyline,
          )
          .toList(growable: false),
    );
    ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
          updated,
          statusMessage: statusMessage,
        );
  }

  String _slugifyStorylineTitle(String title) {
    final normalized = title.trim().toLowerCase();
    final buffer = StringBuffer();
    var lastWasSeparator = false;
    for (final rune in normalized.runes) {
      final char = String.fromCharCode(rune);
      final replacement = switch (char) {
        'à' || 'á' || 'â' || 'ä' || 'ã' || 'å' => 'a',
        'ç' => 'c',
        'è' || 'é' || 'ê' || 'ë' => 'e',
        'ì' || 'í' || 'î' || 'ï' => 'i',
        'ñ' => 'n',
        'ò' || 'ó' || 'ô' || 'ö' || 'õ' => 'o',
        'ù' || 'ú' || 'û' || 'ü' => 'u',
        'ý' || 'ÿ' => 'y',
        _ => char,
      };
      final isAlphaNumeric = RegExp(r'[a-z0-9]').hasMatch(replacement);
      if (isAlphaNumeric) {
        buffer.write(replacement);
        lastWasSeparator = false;
      } else if (!lastWasSeparator && buffer.isNotEmpty) {
        buffer.write('_');
        lastWasSeparator = true;
      }
    }
    return buffer.toString().replaceAll(RegExp(r'_+$'), '');
  }
}

StorylineAsset _copyStorylineWith(
  StorylineAsset storyline, {
  List<StorylineChapter>? chapters,
}) {
  return StorylineAsset(
    id: storyline.id,
    schemaVersion: storyline.schemaVersion,
    type: storyline.type,
    status: storyline.status,
    title: storyline.title,
    description: storyline.description,
    sortOrder: storyline.sortOrder,
    locale: storyline.locale,
    chapters: chapters ?? storyline.chapters,
    sceneLinks: storyline.sceneLinks,
    relationships: storyline.relationships,
    legacySource: storyline.legacySource,
    authorNotes: storyline.authorNotes,
    metadata: storyline.metadata,
  );
}

StorylineChapter _copyChapterWith(
  StorylineChapter chapter, {
  List<StorylineStep>? steps,
}) {
  return StorylineChapter(
    id: chapter.id,
    title: chapter.title,
    description: chapter.description,
    order: chapter.order,
    steps: steps ?? chapter.steps,
    directSceneLinkIds: chapter.directSceneLinkIds,
    status: chapter.status,
    authorNotes: chapter.authorNotes,
    metadata: chapter.metadata,
  );
}

int _storylineStepCount(StorylineAsset storyline) {
  return storyline.chapters.fold<int>(
    0,
    (total, chapter) => total + chapter.steps.length,
  );
}

String _formatCount(int count, String singular, String plural) {
  return '$count ${count == 1 ? singular : plural}';
}

class _StorylinesV1SecondaryPanel extends StatelessWidget {
  const _StorylinesV1SecondaryPanel({
    required this.storylines,
    required this.selectedStorylineId,
    required this.legacyGlobalStory,
    required this.onStorylineSelected,
  });

  final List<StorylineAsset> storylines;
  final String? selectedStorylineId;
  final NarrativeScenarioSummary? legacyGlobalStory;
  final ValueChanged<StorylineAsset> onStorylineSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('storylines-secondary-panel'),
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StorylinesSectionLabel(
            label: 'STORYLINES',
            color: colors.textMuted,
          ),
          const SizedBox(height: 12),
          if (storylines.isEmpty)
            const _StorylinesV1EmptyList()
          else
            ...storylines.map(
              (storyline) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _StorylinesV1Row(
                  storyline: storyline,
                  selected: storyline.id == selectedStorylineId,
                  onTap: () => onStorylineSelected(storyline),
                ),
              ),
            ),
          const Spacer(),
          if (storylines.isEmpty && legacyGlobalStory != null)
            PokeMapCard(
              key: const ValueKey('storylines-legacy-global-story-note'),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ancienne Global Story détectée',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    legacyGlobalStory!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Import manuel à venir.',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StorylinesV1EmptyList extends StatelessWidget {
  const _StorylinesV1EmptyList();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('storylines-v1-secondary-empty'),
      padding: const EdgeInsets.all(12),
      child: Text(
        'Aucune storyline auteur',
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StorylinesV1Row extends StatelessWidget {
  const _StorylinesV1Row({
    required this.storyline,
    required this.selected,
    required this.onTap,
  });

  final StorylineAsset storyline;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return KeyedSubtree(
      key: ValueKey('storylines-v1-row-${storyline.id}'),
      child: PokeMapCard(
        padding: const EdgeInsets.all(12),
        selected: selected,
        onTap: onTap,
        child: Row(
          children: [
            const PokeMapIconTile(
              icon: CupertinoIcons.book,
              tone: PokeMapTone.narrative,
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storyline.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _storylineTypeLabel(storyline.type),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (storyline.chapters.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      "${_formatCount(storyline.chapters.length, 'chapitre', 'chapitres')} · ${_formatCount(_storylineStepCount(storyline), 'étape', 'étapes')}",
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorylinesV1MainPanel extends StatelessWidget {
  const _StorylinesV1MainPanel({
    required this.selectedStoryline,
    required this.selectedChapter,
    required this.storylines,
    required this.selectedTab,
    required this.legacyGlobalStory,
    required this.legacyStep,
    required this.legacyStepCount,
    required this.canCreateMainStoryline,
    required this.onTabSelected,
    required this.onChapterSelected,
    required this.onCreateMainStoryline,
    required this.onCreateChapter,
    required this.onCreateStep,
  });

  final StorylineAsset? selectedStoryline;
  final StorylineChapter? selectedChapter;
  final List<StorylineAsset> storylines;
  final _StorylineContentTab selectedTab;
  final NarrativeScenarioSummary? legacyGlobalStory;
  final NarrativeStepSummary? legacyStep;
  final int legacyStepCount;
  final bool canCreateMainStoryline;
  final ValueChanged<_StorylineContentTab> onTabSelected;
  final ValueChanged<StorylineChapter> onChapterSelected;
  final VoidCallback? onCreateMainStoryline;
  final VoidCallback? onCreateChapter;
  final VoidCallback? onCreateStep;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      key: const ValueKey('storylines-main-panel'),
      expandChild: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StorylinesV1Header(
            selectedStoryline: selectedStoryline,
            canCreateMainStoryline: canCreateMainStoryline,
            onCreateMainStoryline: onCreateMainStoryline,
          ),
          const SizedBox(height: 12),
          _StorylineTabsRow(
            selectedTab: selectedTab,
            onTabSelected: onTabSelected,
          ),
          const SizedBox(height: 12),
          _StorylinesV1KpiStrip(storylines: storylines),
          const SizedBox(height: 16),
          Expanded(
            child: selectedTab == _StorylineContentTab.structure
                ? _StorylinesV1StructureSection(
                    storyline: selectedStoryline,
                    selectedChapter: selectedChapter,
                    onChapterSelected: onChapterSelected,
                    onCreateChapter: onCreateChapter,
                    onCreateStep: onCreateStep,
                  )
                : _StorylinesV1GraphSection(
                    storyline: selectedStoryline,
                    legacyGlobalStory: legacyGlobalStory,
                    legacyStep: legacyStep,
                    legacyStepCount: legacyStepCount,
                  ),
          ),
        ],
      ),
    );
  }
}

class _StorylinesV1Header extends StatelessWidget {
  const _StorylinesV1Header({
    required this.selectedStoryline,
    required this.canCreateMainStoryline,
    required this.onCreateMainStoryline,
  });

  final StorylineAsset? selectedStoryline;
  final bool canCreateMainStoryline;
  final VoidCallback? onCreateMainStoryline;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return KeyedSubtree(
      key: const ValueKey('storylines-header-section'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedStoryline?.title ?? 'Storylines',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedStoryline == null
                      ? 'Créez une histoire principale pour commencer à structurer votre jeu.'
                      : selectedStoryline!.description ??
                          'Storyline principale prête à structurer.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PokeMapButton(
            key: const ValueKey('storylines-create-main-cta'),
            onPressed: canCreateMainStoryline ? onCreateMainStoryline : null,
            variant: PokeMapButtonVariant.primary,
            leading: const Icon(CupertinoIcons.plus, size: 16),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Nouvelle'),
                Text(' storyline'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StorylinesV1KpiStrip extends StatelessWidget {
  const _StorylinesV1KpiStrip({required this.storylines});

  final List<StorylineAsset> storylines;

  @override
  Widget build(BuildContext context) {
    final chapterCount = storylines.fold<int>(
      0,
      (total, storyline) => total + storyline.chapters.length,
    );
    final stepCount = storylines.fold<int>(
      0,
      (total, storyline) =>
          total +
          storyline.chapters.fold<int>(
            0,
            (chapterTotal, chapter) => chapterTotal + chapter.steps.length,
          ),
    );
    final sceneLinkCount = storylines.fold<int>(
      0,
      (total, storyline) => total + storyline.sceneLinks.length,
    );
    return KeyedSubtree(
      key: const ValueKey('storylines-kpi-strip'),
      child: SizedBox(
        height: 128,
        child: Row(
          children: [
            Expanded(
              child: PokeMapMetricCard(
                title: 'Storylines',
                value: storylines.length.toString(),
                icon: CupertinoIcons.book,
                tone: PokeMapTone.narrative,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PokeMapMetricCard(
                title: 'Chapters',
                value: chapterCount.toString(),
                icon: CupertinoIcons.square_list,
                tone: PokeMapTone.neutral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PokeMapMetricCard(
                title: 'Story Steps',
                value: stepCount.toString(),
                icon: CupertinoIcons.list_bullet,
                tone: PokeMapTone.neutral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PokeMapMetricCard(
                title: 'Scene Links',
                value: sceneLinkCount.toString(),
                icon: CupertinoIcons.link,
                tone: PokeMapTone.neutral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorylinesV1GraphSection extends StatelessWidget {
  const _StorylinesV1GraphSection({
    required this.storyline,
    required this.legacyGlobalStory,
    required this.legacyStep,
    required this.legacyStepCount,
  });

  final StorylineAsset? storyline;
  final NarrativeScenarioSummary? legacyGlobalStory;
  final NarrativeStepSummary? legacyStep;
  final int legacyStepCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final selectedStoryline = storyline;
    final chapterCount = selectedStoryline?.chapters.length ?? 0;
    final stepCount =
        selectedStoryline == null ? 0 : _storylineStepCount(selectedStoryline);
    return PokeMapCard(
      key: const ValueKey('storylines-graph-target-read-only'),
      padding: const EdgeInsets.all(18),
      child: selectedStoryline == null
          ? _StorylinesV1NoStorylineState(
              legacyGlobalStory: legacyGlobalStory,
              legacyStep: legacyStep,
              legacyStepCount: legacyStepCount,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const PokeMapIconTile(
                      icon: CupertinoIcons.arrow_branch,
                      tone: PokeMapTone.narrative,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Graph de compréhension',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vue générée depuis StorylineAsset. Lecture seule en V1 initial.',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Center(
                    child: PokeMapCard(
                      key: const ValueKey('storylines-v1-graph-empty-canvas'),
                      padding: const EdgeInsets.all(18),
                      selected: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedStoryline.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            chapterCount == 0
                                ? 'Ajoutez des chapitres dans Structure.'
                                : "${_formatCount(chapterCount, 'chapitre', 'chapitres')} · ${_formatCount(stepCount, 'étape', 'étapes')}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (chapterCount > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Graph détaillé à venir au lot Graph From StorylineAsset.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StorylinesV1NoStorylineState extends StatelessWidget {
  const _StorylinesV1NoStorylineState({
    required this.legacyGlobalStory,
    required this.legacyStep,
    required this.legacyStepCount,
  });

  final NarrativeScenarioSummary? legacyGlobalStory;
  final NarrativeStepSummary? legacyStep;
  final int legacyStepCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PokeMapIconTile(
              icon: CupertinoIcons.book,
              tone: PokeMapTone.narrative,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              'Aucune storyline auteur',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez une histoire principale pour commencer à structurer votre jeu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            if (legacyGlobalStory != null) ...[
              const SizedBox(height: 12),
              Text(
                'Une ancienne Global Story peut exister dans les scénarios legacy. Elle ne sera pas importée automatiquement.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              PokeMapCard(
                key: const ValueKey('storylines-v1-legacy-preview-card'),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode lecture seule',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      legacyGlobalStory!.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (legacyGlobalStory!.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        legacyGlobalStory!.description,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Graph read-only',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (legacyStep != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        legacyStep!.name,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      legacyStepCount.toString(),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StorylinesV1StructureSection extends StatelessWidget {
  const _StorylinesV1StructureSection({
    required this.storyline,
    required this.selectedChapter,
    required this.onChapterSelected,
    required this.onCreateChapter,
    required this.onCreateStep,
  });

  final StorylineAsset? storyline;
  final StorylineChapter? selectedChapter;
  final ValueChanged<StorylineChapter> onChapterSelected;
  final VoidCallback? onCreateChapter;
  final VoidCallback? onCreateStep;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final chapter = selectedChapter;
    return PokeMapCard(
      key: const ValueKey('storylines-structure-read-only'),
      padding: const EdgeInsets.all(18),
      child: storyline == null
          ? Center(
              child: Text(
                'Créez une storyline pour commencer.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StorylinesV1StructureSummary(storyline: storyline!),
                  const SizedBox(height: 12),
                  _StorylinesV1ChaptersSection(
                    key: const ValueKey('storylines-v1-structure-chapters'),
                    storyline: storyline!,
                    selectedChapter: chapter,
                    onChapterSelected: onChapterSelected,
                    onCreateChapter: onCreateChapter,
                  ),
                  const SizedBox(height: 10),
                  _StorylinesV1ChapterDetail(
                    chapter: chapter,
                    onCreateStep: onCreateStep,
                  ),
                  const SizedBox(height: 10),
                  _StorylinesV1StepsSection(
                    key: const ValueKey('storylines-v1-structure-steps'),
                    chapter: chapter,
                  ),
                  const SizedBox(height: 10),
                  const _StorylinesV1StructureBucket(
                    key: ValueKey('storylines-v1-structure-scenes'),
                    title: 'Scènes liées',
                    body:
                        'Scènes liées à venir. Les scènes seront reliées dans un prochain lot.',
                    action: 'Lier une scène — bientôt',
                    actionKey: ValueKey('storylines-link-scene-disabled'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StorylinesV1StructureSummary extends StatelessWidget {
  const _StorylinesV1StructureSummary({required this.storyline});

  final StorylineAsset storyline;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.all(14),
      selected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            storyline.title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            storyline.description ?? 'Aucune description renseignée.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StorylinesV1Badge(label: _storylineTypeLabel(storyline.type)),
              const _StorylinesV1Badge(label: 'Draft'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorylinesV1ChaptersSection extends StatelessWidget {
  const _StorylinesV1ChaptersSection({
    super.key,
    required this.storyline,
    required this.selectedChapter,
    required this.onChapterSelected,
    required this.onCreateChapter,
  });

  final StorylineAsset storyline;
  final StorylineChapter? selectedChapter;
  final ValueChanged<StorylineChapter> onChapterSelected;
  final VoidCallback? onCreateChapter;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chapitres',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
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
          const SizedBox(height: 10),
          if (storyline.chapters.isEmpty)
            Text(
              'Aucun chapitre\nCréez un premier chapitre pour organiser votre histoire.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            )
          else
            ...storyline.chapters.map(
              (chapter) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _StorylinesV1ChapterRow(
                  chapter: chapter,
                  selected: chapter.id == selectedChapter?.id,
                  onTap: () => onChapterSelected(chapter),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StorylinesV1ChapterRow extends StatelessWidget {
  const _StorylinesV1ChapterRow({
    required this.chapter,
    required this.selected,
    required this.onTap,
  });

  final StorylineChapter chapter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: ValueKey('storylines-chapter-row-${chapter.id}'),
      padding: const EdgeInsets.all(12),
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          PokeMapIconTile(
            icon: CupertinoIcons.bookmark,
            tone: selected ? PokeMapTone.narrative : PokeMapTone.neutral,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 3),
                Text(
                  '${_formatCount(chapter.steps.length, 'étape narrative', 'étapes narratives')} · ordre ${chapter.order}',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StorylinesV1ChapterDetail extends StatelessWidget {
  const _StorylinesV1ChapterDetail({
    required this.chapter,
    required this.onCreateStep,
  });

  final StorylineChapter? chapter;
  final VoidCallback? onCreateStep;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('storylines-v1-chapter-detail'),
      padding: const EdgeInsets.all(14),
      selected: chapter != null,
      child: chapter == null
          ? Text(
              'Détail du chapitre\nCréez ou sélectionnez un chapitre pour ajouter des étapes narratives.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            chapter!.title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            chapter!.description ?? 'Aucune description.',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ordre ${chapter!.order} · ${_formatCount(chapter!.steps.length, 'étape', 'étapes')}',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
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
              ],
            ),
    );
  }
}

class _StorylinesV1StepsSection extends StatelessWidget {
  const _StorylinesV1StepsSection({
    super.key,
    required this.chapter,
  });

  final StorylineChapter? chapter;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Étapes narratives',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (chapter == null)
            Text(
              'Sélectionnez un chapitre pour voir ses étapes.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            )
          else if (chapter!.steps.isEmpty)
            Text(
              'Aucune étape narrative\nAjoutez une première étape pour définir la progression du chapitre.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            )
          else
            ...chapter!.steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _StorylinesV1StepRow(step: step),
              ),
            ),
        ],
      ),
    );
  }
}

class _StorylinesV1StepRow extends StatelessWidget {
  const _StorylinesV1StepRow({required this.step});

  final StorylineStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: ValueKey('storylines-step-row-${step.id}'),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.flag,
            tone: PokeMapTone.info,
            size: 28,
          ),
          const SizedBox(width: 10),
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.description ?? 'Aucune description.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const _StorylinesV1Badge(label: 'Aucune scène liée'),
        ],
      ),
    );
  }
}

class _StorylinesV1StructureBucket extends StatelessWidget {
  const _StorylinesV1StructureBucket({
    super.key,
    required this.title,
    required this.body,
    this.action,
    this.actionKey,
  });

  final String title;
  final String body;
  final String? action;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 10),
            PokeMapButton(
              key: actionKey,
              onPressed: null,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              child: Text(action!),
            ),
          ],
        ],
      ),
    );
  }
}

class _StorylinesV1Badge extends StatelessWidget {
  const _StorylinesV1Badge({required this.label});

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

class _StorylinesV1InspectorPanel extends StatelessWidget {
  const _StorylinesV1InspectorPanel({required this.selectedStoryline});

  final StorylineAsset? selectedStoryline;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('storylines-inspector-read-only'),
      expandChild: true,
      padding: const EdgeInsets.all(14),
      child: selectedStoryline == null
          ? Center(
              child: Text(
                'Aucune storyline sélectionnée.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DÉTAILS STORYLINE',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  selectedStoryline!.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedStoryline!.description ?? 'Aucune description.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                _StorylineInspectorTextLine(
                  label: 'Type',
                  value: _storylineTypeLabel(selectedStoryline!.type),
                ),
                const _StorylineInspectorTextLine(
                  label: 'Statut',
                  value: 'Draft',
                ),
                _StorylineInspectorTextLine(
                  label: 'Chapitres',
                  value: selectedStoryline!.chapters.length.toString(),
                ),
                _StorylineInspectorTextLine(
                  label: 'Étapes',
                  value: _storylineStepCount(selectedStoryline!).toString(),
                ),
                _StorylineInspectorTextLine(
                  label: 'Scene links',
                  value: selectedStoryline!.sceneLinks.length.toString(),
                ),
              ],
            ),
    );
  }
}

class _CreateMainStorylineDraft {
  const _CreateMainStorylineDraft({
    required this.title,
    required this.description,
  });

  final String title;
  final String? description;
}

class _StructureItemDraft {
  const _StructureItemDraft({
    required this.title,
    required this.description,
  });

  final String title;
  final String? description;
}

class _CreateStructureItemDialog extends StatefulWidget {
  const _CreateStructureItemDialog({
    required this.dialogKey,
    required this.title,
    required this.titleFieldKey,
    required this.descriptionFieldKey,
    required this.cancelKey,
    required this.submitKey,
  });

  final Key dialogKey;
  final String title;
  final Key titleFieldKey;
  final Key descriptionFieldKey;
  final Key cancelKey;
  final Key submitKey;

  @override
  State<_CreateStructureItemDialog> createState() =>
      _CreateStructureItemDialogState();
}

class _CreateStructureItemDialogState
    extends State<_CreateStructureItemDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final title = _titleController.text.trim();
    return Center(
      child: SizedBox(
        width: 460,
        child: PokeMapPanel(
          key: widget.dialogKey,
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _StorylinesV1TextField(
                key: widget.titleFieldKey,
                controller: _titleController,
                placeholder: 'Titre',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _StorylinesV1TextField(
                key: widget.descriptionFieldKey,
                controller: _descriptionController,
                placeholder: 'Description optionnelle',
                maxLines: 3,
              ),
              if (title.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Titre obligatoire.',
                  style: TextStyle(
                    color: colors.warning,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PokeMapButton(
                    key: widget.cancelKey,
                    onPressed: () => Navigator.of(context).pop(),
                    variant: PokeMapButtonVariant.secondary,
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 10),
                  PokeMapButton(
                    key: widget.submitKey,
                    onPressed: title.isEmpty
                        ? null
                        : () {
                            final description =
                                _descriptionController.text.trim();
                            Navigator.of(context).pop(
                              _StructureItemDraft(
                                title: title,
                                description:
                                    description.isEmpty ? null : description,
                              ),
                            );
                          },
                    variant: PokeMapButtonVariant.primary,
                    child: const Text('Créer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateMainStorylineDialog extends StatefulWidget {
  const _CreateMainStorylineDialog({required this.existingIds});

  final Set<String> existingIds;

  @override
  State<_CreateMainStorylineDialog> createState() =>
      _CreateMainStorylineDialogState();
}

class _CreateMainStorylineDialogState
    extends State<_CreateMainStorylineDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final title = _titleController.text.trim();
    return Center(
      child: SizedBox(
        width: 460,
        child: PokeMapPanel(
          key: const ValueKey('storylines-create-main-dialog'),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nouvelle storyline',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const _StorylinesV1Badge(label: 'Histoire principale'),
              const SizedBox(height: 14),
              _StorylinesV1TextField(
                key: const ValueKey('storylines-create-title-field'),
                controller: _titleController,
                placeholder: 'Titre',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _StorylinesV1TextField(
                key: const ValueKey('storylines-create-description-field'),
                controller: _descriptionController,
                placeholder: 'Description optionnelle',
                maxLines: 3,
              ),
              if (title.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Titre obligatoire.',
                  style: TextStyle(
                    color: colors.warning,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PokeMapButton(
                    key: const ValueKey('storylines-create-cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    variant: PokeMapButtonVariant.secondary,
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 10),
                  PokeMapButton(
                    key: const ValueKey('storylines-create-submit'),
                    onPressed: title.isEmpty
                        ? null
                        : () {
                            final description =
                                _descriptionController.text.trim();
                            Navigator.of(context).pop(
                              _CreateMainStorylineDraft(
                                title: title,
                                description:
                                    description.isEmpty ? null : description,
                              ),
                            );
                          },
                    variant: PokeMapButtonVariant.primary,
                    child: const Text('Créer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorylinesV1TextField extends StatelessWidget {
  const _StorylinesV1TextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return CupertinoTextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      placeholder: placeholder,
      style: TextStyle(color: colors.textPrimary, fontSize: 13),
      placeholderStyle: TextStyle(color: colors.textMuted, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
    );
  }
}

String _storylineTypeLabel(StorylineType type) {
  return switch (type) {
    StorylineType.main => 'Histoire principale',
    StorylineType.sideQuest => 'Storyline secondaire',
    StorylineType.tutorial => 'Tutoriel',
    StorylineType.epilogue => 'Épilogue',
    StorylineType.episode => 'Épisode',
    StorylineType.postGame => 'Post-game',
    StorylineType.hiddenEvent => 'Événement caché',
  };
}

enum _StorylineContentTab { graph, structure }

class _StorylineTabsRow extends StatelessWidget {
  const _StorylineTabsRow({
    required this.selectedTab,
    required this.onTabSelected,
  });

  final _StorylineContentTab selectedTab;
  final ValueChanged<_StorylineContentTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('storylines-tabs'),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: PokeMapSegmentedTabs(
          tabs: [
            PokeMapSegmentedTab(
              label: 'Graph',
              selected: selectedTab == _StorylineContentTab.graph,
              icon: CupertinoIcons.arrow_branch,
              onTap: () => onTabSelected(_StorylineContentTab.graph),
            ),
            PokeMapSegmentedTab(
              label: 'Structure',
              selected: selectedTab == _StorylineContentTab.structure,
              icon: CupertinoIcons.square_list,
              onTap: () => onTabSelected(_StorylineContentTab.structure),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorylinesSectionLabel extends StatelessWidget {
  const _StorylinesSectionLabel({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _StorylineInspectorTextLine extends StatelessWidget {
  const _StorylineInspectorTextLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
