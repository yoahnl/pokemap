import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/narrative/application/narrative_overview.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_empty_state.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'narrative_overview_view_state.dart';
import 'narrative_story_chapters.dart';

class NarrativeOverviewContent extends StatelessWidget {
  const NarrativeOverviewContent({
    super.key,
    required this.overview,
    required this.state,
    required this.story,
    required this.stories,
    required this.compact,
    required this.onChanged,
    required this.onCreateInteraction,
  });
  final NarrativeOverview overview;
  final NarrativeOverviewViewState state;
  final StorylineAsset? story;
  final List<StorylineAsset> stories;
  final bool compact;
  final VoidCallback onChanged, onCreateInteraction;

  @override
  Widget build(BuildContext context) => StudioPanel(
    compact: true,
    children: [
      if (state.tab == NarrativeOverviewTab.stories) ...[
        if (compact && stories.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            key: ValueKey('story-picker-${state.storyId}'),
            initialValue: stories.any((s) => s.id == state.storyId)
                ? state.storyId
                : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Histoire'),
            items: [
              for (final s in stories)
                DropdownMenuItem(
                  value: s.id,
                  child: Text(s.title, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) {
              state.storyId = id;
              state.select();
              state.detailVisible = false;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: story == null || !stories.contains(story)
              ? StudioEmptyState(
                  title: overview.stories.isEmpty
                      ? 'Aucune histoire structurée pour le moment'
                      : stories.isEmpty
                      ? 'Aucune histoire correspondante'
                      : 'Sélectionnez une histoire correspondante',
                  description:
                      'Consultez les interactions du monde ou créez une histoire.',
                )
              : NarrativeStoryChapters(
                  story: story!,
                  state: state,
                  linkCount: (id) => overview.stepLinks[id]?.length ?? 0,
                  onChanged: onChanged,
                ),
        ),
      ] else if (state.tab == NarrativeOverviewTab.interactions)
        ..._interactions(context)
      else
        ..._facts(context),
    ],
  );

  List<Widget> _interactions(BuildContext context) {
    final items = state.visibleInteractions(overview);
    final maps = {
      for (final item in overview.interactions)
        if (item.mapId != null) item.mapId!: item.mapLabel,
    };
    return [
      Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Interactions (${items.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          StudioButton(
            label: 'Créer une interaction',
            secondary: true,
            icon: Icons.add_location_alt_outlined,
            onPressed: onCreateInteraction,
          ),
        ],
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: ValueKey('map-filter-${state.mapId}'),
        initialValue: maps.containsKey(state.mapId) ? state.mapId : '',
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Carte'),
        items: [
          const DropdownMenuItem(value: '', child: Text('Toutes les cartes')),
          for (final entry in maps.entries)
            DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (id) {
          state.mapId = id == '' ? null : id;
          onChanged();
        },
      ),
      const SizedBox(height: 8),
      StudioToggleRow(
        label: 'Brouillons uniquement',
        value: state.onlyDirty,
        onChanged: (value) {
          state.onlyDirty = value;
          onChanged();
        },
      ),
      Text(
        'Recherche dans les noms, cartes et sources déjà connues. Le texte des dialogues n’est pas chargé.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      if (overview.stories.isEmpty) ...[
        const SizedBox(height: 8),
        const StudioNotice('Aucune histoire structurée pour le moment'),
      ],
      const SizedBox(height: 12),
      Expanded(
        child: items.isEmpty
            ? const StudioEmptyState(
                title: 'Aucune interaction correspondante',
                description: 'Modifiez la recherche ou le filtre de carte.',
              )
            : ListView.separated(
                controller: state.scroll,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return StudioChoice(
                    key: ValueKey('interaction-${item.id}'),
                    label:
                        '${item.name}${item.dirty ? ' · non enregistré' : ''}',
                    subtitle:
                        '${item.mapLabel} · ${item.sourceLabel}${item.advanced ? ' · avancée' : ''}',
                    leading: Icon(
                      item.advanced
                          ? Icons.lock_outline
                          : Icons.chat_bubble_outline,
                      size: 18,
                    ),
                    selected: state.interactionId == item.id,
                    onTap: () {
                      state.select(interaction: item.id);
                      onChanged();
                    },
                  );
                },
              ),
      ),
    ];
  }

  List<Widget> _facts(BuildContext context) {
    final items = state.visibleFacts(overview);
    return [
      Text(
        'États du monde (${items.length})',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      const Text('Définitions initiales du projet'),
      const SizedBox(height: 16),
      Expanded(
        child: items.isEmpty
            ? const StudioEmptyState(title: 'Aucun état correspondant')
            : ListView.separated(
                controller: state.scroll,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final fact = items[index];
                  return StudioChoice(
                    key: ValueKey('fact-${fact.id}'),
                    label: fact.label,
                    subtitle: fact.description.isEmpty
                        ? null
                        : fact.description,
                    leading: const Icon(Icons.flag_outlined, size: 18),
                    selected: state.factId == fact.id,
                    onTap: () {
                      state.select(fact: fact.id);
                      onChanged();
                    },
                  );
                },
              ),
      ),
    ];
  }
}
