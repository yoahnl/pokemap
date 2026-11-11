import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/narrative/application/narrative_story_outline.dart';
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
    final outline = narrativeStoryOutline(story, state.search.text);
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
              narrativeStorySummary(story),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ];
    for (final (:chapter, :steps) in outline) {
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
              subtitle: narrativeStepLinkLabel(count),
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
}
