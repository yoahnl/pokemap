import 'package:map_core/map_core_domain.dart';

import 'narrative_overview_selection.dart';

typedef NarrativeChapterOutline = ({
  StorylineChapter chapter,
  List<StorylineStep> steps,
});

List<NarrativeChapterOutline> narrativeStoryOutline(
  StorylineAsset story,
  String query,
) {
  final needle = query.trim().toLowerCase();
  final storyMatches = story.title.toLowerCase().contains(needle);
  final outline = <NarrativeChapterOutline>[];
  for (final chapter in orderedNarrativeOverview(
    story.chapters,
    (chapter) => chapter.order,
  )) {
    final chapterMatches = chapter.title.toLowerCase().contains(needle);
    final steps = orderedNarrativeOverview(chapter.steps, (step) => step.order)
        .where(
          (step) =>
              storyMatches ||
              chapterMatches ||
              step.title.toLowerCase().contains(needle),
        )
        .toList();
    if (steps.isEmpty && !storyMatches && !chapterMatches) continue;
    outline.add((chapter: chapter, steps: steps));
  }
  return outline;
}

String narrativeStorySummary(StorylineAsset story) =>
    '${story.chapters.length} chapitre(s) · ${story.chapters.expand((c) => c.steps).length} étape(s)';

String narrativeStepLinkLabel(int count) => count == 0
    ? 'Aucun lien trouvé dans les données consultées'
    : '$count interaction(s) liée(s)';

