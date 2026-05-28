import 'package:flutter/cupertino.dart';

import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';

class StorylinesWorkspace extends StatelessWidget {
  const StorylinesWorkspace({
    super.key,
    required this.projection,
    required this.selectedGlobalStoryId,
  });

  final NarrativeWorkspaceProjection projection;
  final String? selectedGlobalStoryId;

  @override
  Widget build(BuildContext context) {
    final selectedStory = _selectedStory;
    final relatedSteps = selectedStory == null
        ? <NarrativeStepSummary>[]
        : projection.steps
            .where((step) => step.globalScenarioId == selectedStory.id)
            .toList(growable: false);
    final stepCountsByStoryId = <String, int>{
      for (final story in projection.globalStories)
        story.id: projection.steps
            .where((step) => step.globalScenarioId == story.id)
            .length,
    };

    return PokeMapPageSurface(
      key: const ValueKey('storylines-workspace-shell'),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 240,
            child: _StorylinesSecondaryPanel(
              stories: projection.globalStories,
              selectedStoryId: selectedStory?.id,
              stepCountsByStoryId: stepCountsByStoryId,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StorylineMainPanel(
              selectedStory: selectedStory,
              stepCount: relatedSteps.length,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 280,
            child: _StorylineInspectorPlaceholder(
              selectedStory: selectedStory,
              stepCount: relatedSteps.length,
            ),
          ),
        ],
      ),
    );
  }

  NarrativeScenarioSummary? get _selectedStory {
    for (final story in projection.globalStories) {
      if (story.id == selectedGlobalStoryId) {
        return story;
      }
    }
    return projection.globalStories.isEmpty
        ? null
        : projection.globalStories.first;
  }
}

class _StorylinesSecondaryPanel extends StatelessWidget {
  const _StorylinesSecondaryPanel({
    required this.stories,
    required this.selectedStoryId,
    required this.stepCountsByStoryId,
  });

  final List<NarrativeScenarioSummary> stories;
  final String? selectedStoryId;
  final Map<String, int> stepCountsByStoryId;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('storylines-secondary-panel'),
      expandChild: true,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Storylines',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Semantics(
              key: const ValueKey('storylines-secondary-create-action'),
              button: true,
              enabled: false,
              label: 'Créer une storyline - à venir',
              child: const PokeMapButton(
                onPressed: null,
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.secondary,
                leading: Icon(CupertinoIcons.add),
                child: Text('+'),
              ),
            ),
          ],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PokeMapStatusTile(
              key: ValueKey('storylines-secondary-search-disabled'),
              label: 'Recherche à venir',
              value: 'Filtrage bientôt disponible',
              icon: CupertinoIcons.search,
              tone: PokeMapTone.neutral,
            ),
            const SizedBox(height: 12),
            _StorylinesSectionLabel(
              label: 'Histoire principale',
              color: colors.textSecondary,
            ),
            const SizedBox(height: 8),
            if (stories.isEmpty)
              Text(
                'Aucune storyline principale disponible.',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              )
            else
              ...stories.map(
                (story) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StorylineSummaryRow(
                    story: story,
                    selected: story.id == selectedStoryId,
                    stepCount: stepCountsByStoryId[story.id] ?? 0,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _StorylinesSectionLabel(
              label: 'Quêtes annexes',
              color: colors.textSecondary,
            ),
            const SizedBox(height: 8),
            const PokeMapStatusTile(
              key: ValueKey('storylines-secondary-side-quests-disabled'),
              label: 'Quêtes annexes',
              value: 'À venir',
              icon: CupertinoIcons.lock,
              tone: PokeMapTone.neutral,
            ),
            const SizedBox(height: 8),
            Text(
              'À venir — aucun modèle de quête annexe n’est encore branché.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11.5,
                height: 1.25,
              ),
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

class _StorylineSummaryRow extends StatelessWidget {
  const _StorylineSummaryRow({
    required this.story,
    required this.selected,
    required this.stepCount,
  });

  final NarrativeScenarioSummary story;
  final bool selected;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final description = story.description.trim();
    return PokeMapCard(
      key: ValueKey('storylines-secondary-row-${story.id}'),
      selected: selected,
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.book,
            tone: PokeMapTone.narrative,
            size: 30,
            iconSize: 15,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.name,
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
                  description.isEmpty
                      ? 'Description non renseignée.'
                      : description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Storyline principale',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatStepCount(stepCount),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Read-only / Source réelle',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatStepCount(int count) {
    return count == 1 ? '1 étape narrative' : '$count étapes narratives';
  }
}

class _StorylineMainPanel extends StatelessWidget {
  const _StorylineMainPanel({
    required this.selectedStory,
    required this.stepCount,
  });

  final NarrativeScenarioSummary? selectedStory;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final description = selectedStory?.description.trim();
    return PokeMapInspectorPanel(
      key: const ValueKey('storylines-main-panel'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.link,
                tone: PokeMapTone.narrative,
                size: 42,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedStory?.name ?? 'Storyline non disponible',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description == null || description.isEmpty
                          ? 'Description non renseignée dans le scénario.'
                          : description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const PokeMapStatusTile(
                label: 'Mode lecture seule',
                value: 'Storylines V0',
                icon: CupertinoIcons.lock,
                tone: PokeMapTone.info,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              PokeMapStatusTile(
                label: 'Étapes réelles',
                value: '$stepCount',
                icon: CupertinoIcons.list_bullet,
                tone: PokeMapTone.narrative,
              ),
              const PokeMapStatusTile(
                label: 'Graph — à venir',
                value: 'Placeholder',
                icon: CupertinoIcons.arrow_branch,
                tone: PokeMapTone.neutral,
              ),
              const PokeMapStatusTile(
                label: 'Chapitres — à venir',
                value: 'Read model prochain',
                icon: CupertinoIcons.square_list,
                tone: PokeMapTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 360,
            child: PokeMapPageSurface(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zone centrale Storyline',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Le graph macro et les chapitres resteront read-only tant que leurs sources ne sont pas stabilisées.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const PokeMapStatusTile(
                    label: 'Créer un chapitre',
                    value: 'À venir',
                    icon: CupertinoIcons.lock,
                    tone: PokeMapTone.neutral,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorylineInspectorPlaceholder extends StatelessWidget {
  const _StorylineInspectorPlaceholder({
    required this.selectedStory,
    required this.stepCount,
  });

  final NarrativeScenarioSummary? selectedStory;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapInspectorPanel(
      key: const ValueKey('storylines-inspector-placeholder'),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Text(
          'Inspecteur Storyline — à venir',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapStatusTile(
            label: 'Source',
            value: selectedStory == null
                ? 'Aucun scénario'
                : 'ScenarioAsset globalStory',
            icon: CupertinoIcons.doc_text,
            tone: PokeMapTone.narrative,
          ),
          const SizedBox(height: 10),
          PokeMapStatusTile(
            label: 'Étapes',
            value: '$stepCount',
            icon: CupertinoIcons.list_bullet,
            tone: PokeMapTone.info,
          ),
          const SizedBox(height: 10),
          const PokeMapStatusTile(
            label: 'Tags',
            value: 'À venir',
            icon: CupertinoIcons.tag,
            tone: PokeMapTone.neutral,
          ),
          const SizedBox(height: 10),
          const PokeMapStatusTile(
            label: 'Règles du monde',
            value: 'Non branché',
            icon: CupertinoIcons.lock,
            tone: PokeMapTone.neutral,
          ),
          const SizedBox(height: 18),
          const PokeMapStatusTile(
            label: 'Valider',
            value: 'Désactivé',
            icon: CupertinoIcons.shield,
            tone: PokeMapTone.neutral,
          ),
        ],
      ),
    );
  }
}
