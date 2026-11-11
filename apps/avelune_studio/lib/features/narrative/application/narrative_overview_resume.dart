import 'package:map_core/map_core_domain.dart';

import 'narrative_overview.dart';
import 'narrative_overview_selection.dart';

const narrativeResumeVisibleLimit = 5;

enum NarrativeResumeKind { story, scene, dialogue, interaction, event }

typedef NarrativeResumeItem = ({
  NarrativeResumeKind kind,
  String id,
  String title,
  String subtitle,
});

List<NarrativeResumeItem> narrativeResumeItems({
  required NarrativeOverview overview,
  required List<SceneAsset> scenes,
  required List<ProjectDialogueEntry> dialogues,
  required List<NarrativeEventRecord> events,
  String? activeStoryId,
  String? activeSceneId,
  String? activeDialogueId,
  String? activeEventId,
  Set<String> dirtyStoryIds = const {},
  Set<String> dirtySceneIds = const {},
  Set<String> dirtyDialogueIds = const {},
  Set<String> dirtyEventIds = const {},
}) => [
  for (final story in overview.stories)
    if (story.id == activeStoryId || dirtyStoryIds.contains(story.id))
      (
        kind: NarrativeResumeKind.story,
        id: story.id,
        title: story.title,
        subtitle: dirtyStoryIds.contains(story.id)
            ? 'Histoire · brouillon'
            : 'Histoire ouverte',
      ),
  for (final scene in scenes)
    if (scene.id == activeSceneId || dirtySceneIds.contains(scene.id))
      (
        kind: NarrativeResumeKind.scene,
        id: scene.id,
        title: scene.name,
        subtitle: dirtySceneIds.contains(scene.id)
            ? 'Scène · brouillon'
            : 'Scène ouverte',
      ),
  for (final dialogue in dialogues)
    if (dialogue.id == activeDialogueId || dirtyDialogueIds.contains(dialogue.id))
      (
        kind: NarrativeResumeKind.dialogue,
        id: dialogue.id,
        title: dialogue.name,
        subtitle: dirtyDialogueIds.contains(dialogue.id)
            ? 'Dialogue · brouillon'
            : 'Dialogue ouvert',
      ),
  for (final interaction in overview.interactions)
    if (interaction.dirty)
      (
        kind: NarrativeResumeKind.interaction,
        id: interaction.id,
        title: interaction.name,
        subtitle: 'Interaction · brouillon',
      ),
  for (final event in events)
    if (event.id == activeEventId || dirtyEventIds.contains(event.id))
      (
        kind: NarrativeResumeKind.event,
        id: event.id,
        title: narrativeOverviewEventName(event),
        subtitle: dirtyEventIds.contains(event.id)
            ? 'Événement · brouillon'
            : 'Événement ouvert',
      ),
];

({List<NarrativeResumeItem> shown, int hidden}) splitNarrativeResume(
  List<NarrativeResumeItem> items,
) => (
  shown: items.take(narrativeResumeVisibleLimit).toList(),
  hidden: items.length > narrativeResumeVisibleLimit
      ? items.length - narrativeResumeVisibleLimit
      : 0,
);
