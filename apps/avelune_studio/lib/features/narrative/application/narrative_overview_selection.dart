import 'package:map_core/map_core_domain.dart';

import 'narrative_overview.dart';

enum NarrativeOverviewTab { stories, interactions, facts }

class NarrativeOverviewSelection {
  String query = '';
  final collapsedChapters = <String>{};
  NarrativeOverviewTab tab = NarrativeOverviewTab.stories;
  String? storyId;
  String? stepId;
  String? interactionId;
  String? factId;
  String? mapId;
  String? notice;
  bool onlyDirty = false;
  bool detailVisible = false;
  bool initialized = false;
  bool showOverview = true;

  List<StorylineAsset> visibleStories(NarrativeOverview overview) {
    final query = this.query.trim().toLowerCase();
    return overview.stories
        .where(
          (story) =>
              story.title.toLowerCase().contains(query) ||
              story.chapters.any(
                (chapter) =>
                    chapter.title.toLowerCase().contains(query) ||
                    chapter.steps.any(
                      (step) => step.title.toLowerCase().contains(query),
                    ),
              ),
        )
        .toList();
  }

  List<NarrativeOverviewInteraction> visibleInteractions(
    NarrativeOverview overview,
  ) {
    final query = this.query.trim().toLowerCase();
    return overview.interactions
        .where(
          (item) =>
              item.searchText.contains(query) &&
              (mapId == null || item.mapId == mapId) &&
              (!onlyDirty || item.dirty),
        )
        .toList();
  }

  List<NarrativeFactDefinition> visibleFacts(NarrativeOverview overview) {
    final query = this.query.trim().toLowerCase();
    return overview.facts
        .where((fact) => fact.label.toLowerCase().contains(query))
        .toList();
  }

  void reconcileSelection(NarrativeOverview overview) {
    switch (tab) {
      case NarrativeOverviewTab.stories:
        final story = visibleStories(overview)
            .where((item) => item.id == storyId)
            .firstOrNull;
        if (story == null) {
          storyId = null;
          stepId = null;
          detailVisible = false;
          notice = null;
        } else if (stepId != null &&
            !story.chapters.any(
              (chapter) => chapter.steps.any((step) => step.id == stepId),
            )) {
          stepId = null;
          detailVisible = false;
          notice = null;
        }
      case NarrativeOverviewTab.interactions:
        if (interactionId != null &&
            !visibleInteractions(overview)
                .any((item) => item.id == interactionId)) {
          interactionId = null;
          detailVisible = false;
          notice = null;
        }
      case NarrativeOverviewTab.facts:
        if (factId != null &&
            !visibleFacts(overview).any((item) => item.id == factId)) {
          factId = null;
          detailVisible = false;
          notice = null;
        }
    }
  }

  void select({String? step, String? interaction, String? fact}) {
    stepId = step;
    interactionId = interaction;
    factId = fact;
    detailVisible = true;
    notice = null;
  }
}

typedef NarrativeOverviewSearchMatch = ({
  String id,
  String kind,
  String title,
  String subtitle,
  String? storyId,
  String? stepId,
});

List<NarrativeOverviewSearchMatch> searchNarrativeOverview({
  required NarrativeOverview overview,
  required ProjectManifest project,
  required List<SceneAsset> scenes,
  required List<ProjectDialogueEntry> dialogues,
  required List<NarrativeEventRecord> events,
  required String query,
}) {
  final search = query.trim().toLowerCase();
  NarrativeOverviewSearchMatch match(
    String id,
    String kind,
    String title,
    String subtitle, {
    String? storyId,
    String? stepId,
  }) => (
    id: id,
    kind: kind,
    title: title,
    subtitle: subtitle,
    storyId: storyId,
    stepId: stepId,
  );
  return [
    for (final story in overview.stories)
      if ('${story.title} ${story.description ?? ''}'.toLowerCase().contains(
        search,
      ))
        match(
          story.id,
          'Histoire',
          story.title,
          narrativeOverviewStoryType(story.type),
        ),
    for (final story in overview.stories)
      for (final chapter in orderedNarrativeOverview(
        story.chapters,
        (item) => item.order,
      ))
        for (final step in orderedNarrativeOverview(
          chapter.steps,
          (item) => item.order,
        ))
          if ('${step.title} ${chapter.title} ${story.title}'
              .toLowerCase()
              .contains(search))
            match(
              '${story.id}/${step.id}',
              'Étape',
              step.title,
              story.title,
              storyId: story.id,
              stepId: step.id,
            ),
    for (final scene in scenes)
      if (scene.name.toLowerCase().contains(search))
        match(scene.id, 'Scène', scene.name, 'Éditeur de scène'),
    for (final dialogue in dialogues)
      if (dialogue.name.toLowerCase().contains(search))
        match(dialogue.id, 'Dialogue', dialogue.name, 'Éditeur de dialogue'),
    for (final event in events)
      if (narrativeOverviewEventName(event).toLowerCase().contains(search))
        match(
          event.id,
          'Événement',
          narrativeOverviewEventName(event),
          'Déclencheur',
        ),
    for (final item in overview.interactions)
      if (item.searchText.contains(search))
        match(item.id, 'Interaction', item.name, item.mapLabel),
    for (final map in project.maps)
      if (map.name.toLowerCase().contains(search))
        match(map.id, 'Carte', map.name, 'Carte du projet'),
  ];
}

String narrativeOverviewStoryType(StorylineType type) => switch (type) {
  StorylineType.main => 'Principale',
  StorylineType.sideQuest => 'Secondaire',
  StorylineType.tutorial => 'Tutoriel',
  StorylineType.epilogue => 'Épilogue',
  StorylineType.episode => 'Épisode',
  StorylineType.postGame => 'Après-jeu',
  StorylineType.hiddenEvent => 'Événement caché',
};

String narrativeOverviewEventName(NarrativeEventRecord record) =>
    record.definitionOrNull?.name ?? record.draftOrNull?.name ?? record.id;

Iterable<T> orderedNarrativeOverview<T>(List<T> values, int Function(T) order) {
  final indexed = values.indexed.toList()
    ..sort((a, b) {
      final compared = order(a.$2).compareTo(order(b.$2));
      return compared == 0 ? a.$1.compareTo(b.$1) : compared;
    });
  return indexed.map((entry) => entry.$2);
}
