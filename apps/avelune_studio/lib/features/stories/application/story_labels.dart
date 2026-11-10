import 'package:map_core/map_core_domain.dart';

String storyTypeLabel(StorylineType type) => switch (type) {
  StorylineType.main => 'Principale',
  StorylineType.sideQuest => 'Secondaire',
  StorylineType.tutorial => 'Tutoriel',
  StorylineType.epilogue => 'Épilogue',
  StorylineType.episode => 'Épisode',
  StorylineType.postGame => 'Après l’aventure',
  StorylineType.hiddenEvent => 'Événement caché',
};

String storyStatusLabel(StorylineStatus status) => switch (status) {
  StorylineStatus.draft => 'Brouillon d’auteur',
  StorylineStatus.active => 'Active dans le projet',
  StorylineStatus.archived => 'Archivée',
  StorylineStatus.disabled => 'Désactivée',
};

List<StorylineChapter> orderedStoryChapters(StorylineAsset story) =>
    [...story.chapters]..sort((a, b) {
      final order = a.order.compareTo(b.order);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });

List<StorylineStep> orderedStorySteps(StorylineChapter chapter) =>
    [...chapter.steps]..sort((a, b) {
      final order = a.order.compareTo(b.order);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });

String progressionLabel(StorylineProgressionEdgeKind kind) => switch (kind) {
  StorylineProgressionEdgeKind.contains => 'Appartenance',
  StorylineProgressionEdgeKind.authorOrder => 'Ordre de présentation',
  StorylineProgressionEdgeKind.outcomeActivatesStep => 'Active l’étape',
  StorylineProgressionEdgeKind.outcomeCompletesStep => 'Accomplit l’étape',
  StorylineProgressionEdgeKind.requires => 'Nécessite',
  StorylineProgressionEdgeKind.blocks => 'Bloque',
  StorylineProgressionEdgeKind.convergesTo => 'Converge vers',
  StorylineProgressionEdgeKind.sideQuestAvailability =>
    'Rattachement secondaire',
  StorylineProgressionEdgeKind.entryCondition => 'Condition d’entrée',
  StorylineProgressionEdgeKind.completionCondition =>
    'Condition d’accomplissement',
};

({List<StorylineAsset> stories, Map<String, String?> matches})
filterStoryLibrary(
  List<StorylineAsset> stories,
  String search, {
  StorylineType? type,
}) {
  final query = search.trim().toLowerCase();
  final matches = <String, String?>{};
  for (final story in stories) {
    if (type != null && story.type != type) continue;
    if ('${story.title} ${story.id} ${story.description ?? ''}'
        .toLowerCase()
        .contains(query)) {
      matches[story.id] = null;
      continue;
    }
    final match = _storyInnerMatch(story, query);
    if (match != null) matches[story.id] = match;
  }
  final filtered = stories.where((s) => matches.containsKey(s.id)).toList()
    ..sort((a, b) {
      final order = (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
  return (stories: filtered, matches: matches);
}

String? _storyInnerMatch(StorylineAsset story, String query) {
  if (query.isEmpty) return null;
  for (final chapter in story.chapters) {
    if ('${chapter.title} ${chapter.id}'.toLowerCase().contains(query)) {
      return 'Chapitre : ${chapter.title}';
    }
    for (final step in chapter.steps) {
      if ('${step.title} ${step.id} ${step.description ?? ''}'
          .toLowerCase()
          .contains(query)) {
        return 'Étape : ${step.title} · ${chapter.title}';
      }
    }
  }
  return null;
}
