import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import 'narrative_overview_view_state.dart';

class NarrativeStoryChapters extends StatelessWidget {
  const NarrativeStoryChapters({
    super.key,
    required this.story,
    required this.state,
    required this.linkCount,
    required this.onChanged,
  });
  final StorylineAsset story;
  final NarrativeOverviewViewState state;
  final int Function(String) linkCount;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final query = state.search.text.trim().toLowerCase();
    final storyMatches = story.title.toLowerCase().contains(query);
    final entries = <WidgetBuilder>[
      (_) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(story.title, style: Theme.of(context).textTheme.titleLarge),
            if (story.description case final description?) ...[
              const SizedBox(height: 6),
              Text(description),
            ],
            const SizedBox(height: 6),
            Text(
              '${story.chapters.length} chapitre(s) · ${story.chapters.expand((c) => c.steps).length} étape(s)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ];
    final chapters = _ordered(story.chapters, (chapter) => chapter.order);
    for (final chapter in chapters) {
      final chapterMatches = chapter.title.toLowerCase().contains(query);
      final steps = _ordered(chapter.steps, (step) => step.order)
          .where(
            (step) =>
                storyMatches ||
                chapterMatches ||
                step.title.toLowerCase().contains(query),
          )
          .toList();
      if (steps.isEmpty && !storyMatches && !chapterMatches) continue;
      final collapsed = state.collapsedChapters.contains(chapter.id);
      entries.add(
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: StudioChoice(
            key: ValueKey('chapter-${chapter.id}'),
            label: chapter.title,
            subtitle: chapter.description,
            leading: Icon(collapsed ? Icons.chevron_right : Icons.expand_more),
            onTap: () {
              if (collapsed) {
                state.collapsedChapters.remove(chapter.id);
              } else {
                state.collapsedChapters.add(chapter.id);
              }
              onChanged();
            },
          ),
        ),
      );
      if (collapsed) continue;
      for (final step in steps) {
        final count = linkCount(step.id);
        entries.add(
          (_) => Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: StudioChoice(
              key: ValueKey('step-${step.id}'),
              label: step.title,
              subtitle: count == 0
                  ? 'Aucun lien trouvé dans les données consultées'
                  : '$count interaction(s) liée(s)',
              leading: Icon(
                count == 0 ? Icons.radio_button_unchecked : Icons.link,
                size: 18,
              ),
              selected: state.stepId == step.id,
              onTap: () {
                state.select(step: step.id);
                onChanged();
              },
            ),
          ),
        );
      }
      entries.add((_) => const SizedBox(height: 12));
    }
    return ListView.builder(
      controller: state.scroll,
      itemCount: entries.length,
      itemBuilder: (context, index) => entries[index](context),
    );
  }

  List<T> _ordered<T>(List<T> values, int Function(T) order) {
    final indexed = values.indexed.toList()
      ..sort((a, b) {
        final compared = order(a.$2).compareTo(order(b.$2));
        return compared == 0 ? a.$1.compareTo(b.$1) : compared;
      });
    return indexed.map((entry) => entry.$2).toList();
  }
}
