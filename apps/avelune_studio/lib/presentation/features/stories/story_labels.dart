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
