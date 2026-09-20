import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'narrative_overview_view_state.dart';

class NarrativeOverviewNavigation extends StatelessWidget {
  const NarrativeOverviewNavigation({
    super.key,
    required this.state,
    required this.stories,
    required this.onChanged,
  });
  final NarrativeOverviewViewState state;
  final List<StorylineAsset> stories;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => StudioPanel(
    compact: true,
    title: 'Votre récit',
    children: [
      for (final item in const [
        (
          NarrativeOverviewTab.stories,
          'Histoires',
          Icons.auto_stories_outlined,
        ),
        (
          NarrativeOverviewTab.interactions,
          'Interactions',
          Icons.chat_outlined,
        ),
        (NarrativeOverviewTab.facts, 'États', Icons.flag_outlined),
      ]) ...[
        StudioChoice(
          label: item.$2,
          leading: Icon(item.$3, size: 18),
          selected: state.tab == item.$1,
          onTap: () {
            state.tab = item.$1;
            state.select();
            state.detailVisible = false;
            onChanged();
          },
        ),
        const SizedBox(height: 6),
      ],
      const SizedBox(height: 12),
      Text(
        'Histoires du projet',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: 8),
      Expanded(
        child: ListView.separated(
          key: const PageStorageKey('story-navigation'),
          itemCount: stories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (_, index) {
            final story = stories[index];
            return StudioChoice(
              key: ValueKey('story-${story.id}'),
              label: story.title,
              subtitle: '${story.chapters.length} chapitre(s)',
              selected:
                  state.tab == NarrativeOverviewTab.stories &&
                  state.storyId == story.id,
              onTap: () {
                state.tab = NarrativeOverviewTab.stories;
                state.storyId = story.id;
                state.select();
                state.detailVisible = false;
                onChanged();
              },
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Organisation du projet. La progression des joueurs reste dans leurs parties.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}
