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

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorNotifierProvider);
    final project = editorState.project;
    final storylines = project?.storylines ?? const <StorylineAsset>[];
    final selectedStoryline = _selectedStoryline(storylines);
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
              storylines: storylines,
              selectedTab: _selectedTab,
              legacyGlobalStory: legacyGlobalStory,
              legacyStep: legacyStep,
              legacyStepCount: legacyStepCount,
              canCreateMainStoryline: _canCreateMainStoryline(storylines),
              onTabSelected: _selectTab,
              onCreateMainStoryline:
                  project == null || !_canCreateMainStoryline(storylines)
                      ? null
                      : () => _openCreateMainStorylineDialog(project),
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

  void _selectStoryline(StorylineAsset storyline) {
    if (_selectedStorylineId == storyline.id) {
      return;
    }
    setState(() {
      _selectedStorylineId = storyline.id;
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
      _selectedTab = _StorylineContentTab.graph;
    });
  }

  String _generateStorylineId(
    String title,
    List<StorylineAsset> storylines,
  ) {
    final existingIds = storylines.map((storyline) => storyline.id).toSet();
    final slug = _slugifyStorylineTitle(title);
    final base = 'storyline_${slug.isEmpty ? 'main' : slug}';
    if (!existingIds.contains(base)) {
      return base;
    }
    var suffix = 2;
    while (existingIds.contains('${base}_$suffix')) {
      suffix += 1;
    }
    return '${base}_$suffix';
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
    required this.storylines,
    required this.selectedTab,
    required this.legacyGlobalStory,
    required this.legacyStep,
    required this.legacyStepCount,
    required this.canCreateMainStoryline,
    required this.onTabSelected,
    required this.onCreateMainStoryline,
  });

  final StorylineAsset? selectedStoryline;
  final List<StorylineAsset> storylines;
  final _StorylineContentTab selectedTab;
  final NarrativeScenarioSummary? legacyGlobalStory;
  final NarrativeStepSummary? legacyStep;
  final int legacyStepCount;
  final bool canCreateMainStoryline;
  final ValueChanged<_StorylineContentTab> onTabSelected;
  final VoidCallback? onCreateMainStoryline;

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
                ? _StorylinesV1StructureSection(storyline: selectedStoryline)
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
    return PokeMapCard(
      key: const ValueKey('storylines-graph-target-read-only'),
      padding: const EdgeInsets.all(18),
      child: storyline == null
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
                            storyline!.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajoutez des chapitres dans Structure.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
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
  const _StorylinesV1StructureSection({required this.storyline});

  final StorylineAsset? storyline;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
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
                  const _StorylinesV1StructureBucket(
                    key: ValueKey('storylines-v1-structure-chapters'),
                    title: 'Chapitres',
                    body: 'Aucun chapitre pour le moment.',
                    action: 'Nouveau chapitre — bientôt',
                  ),
                  const SizedBox(height: 10),
                  const _StorylinesV1StructureBucket(
                    key: ValueKey('storylines-v1-structure-steps'),
                    title: 'Étapes narratives',
                    body: 'Les étapes seront organisées dans les chapitres.',
                  ),
                  const SizedBox(height: 10),
                  const _StorylinesV1StructureBucket(
                    key: ValueKey('storylines-v1-structure-scenes'),
                    title: 'Scènes liées',
                    body: 'Liens de scènes non branchés dans ce lot.',
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

class _StorylinesV1StructureBucket extends StatelessWidget {
  const _StorylinesV1StructureBucket({
    super.key,
    required this.title,
    required this.body,
    this.action,
  });

  final String title;
  final String body;
  final String? action;

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
              key: const ValueKey('storylines-new-chapter-disabled'),
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
