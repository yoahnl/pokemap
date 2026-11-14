import 'package:map_core/map_core_domain.dart';

import '../../game_memory/domain/map_directory.dart';
import '../../story_draft/domain/story_dialogue_source.dart';

final class SceneDocument {
  SceneDocument({
    required this.scene,
    required List<StoryDialogueSource> dialogues,
    required List<String> missingDialogueIds,
    required List<NarrativeEventRecord> events,
    required Map<String, MapDirectoryPage> maps,
    required this.mapReads,
  }) : dialogues = List.unmodifiable(dialogues),
       missingDialogueIds = List.unmodifiable(missingDialogueIds),
       events = List.unmodifiable(events),
       maps = Map.unmodifiable(maps);

  final SceneAsset scene;
  final List<StoryDialogueSource> dialogues;
  final List<String> missingDialogueIds;
  final List<NarrativeEventRecord> events;
  final Map<String, MapDirectoryPage> maps;
  final int mapReads;
}
