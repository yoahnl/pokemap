import 'package:map_core/map_core.dart';

import '../../scenes/domain/scene_document.dart';
import '../../story_draft/domain/story_dialogue_source.dart';
import '../domain/map_directory.dart';
import 'local_map_directory_codec.dart';

SceneDocument sceneDocument(Map<String, Object?> item) {
  final dialogues = <StoryDialogueSource>[];
  final missing = <String>[];
  for (final raw in item['dialogues'] as List? ?? const []) {
    final dialogue = Map<String, Object?>.from(raw as Map);
    final entry = ProjectDialogueEntry.fromJson(
      Map<String, dynamic>.from(dialogue['entry'] as Map),
    );
    if (dialogue['source'] case final String source) {
      dialogues.add(
        StoryDialogueSource(
          entry: entry,
          source: source,
          revision: dialogue['revision'] as String?,
        ),
      );
    } else {
      missing.add(entry.id);
    }
  }
  final pages = <String, MapDirectoryPage>{};
  for (final raw in item['mapDirectory'] as List? ?? const []) {
    final page = mapDirectoryPage(Map<String, Object?>.from(raw as Map));
    pages[page.mapId] = page;
  }
  final reads = item['reads'];
  return SceneDocument(
    scene: SceneAsset.fromJson(Map<String, dynamic>.from(item['scene'] as Map)),
    dialogues: dialogues,
    missingDialogueIds: missing,
    events: [
      for (final raw in item['events'] as List? ?? const [])
        NarrativeEventRecord.fromJson(raw),
    ],
    maps: pages,
    mapReads: reads is Map && reads['maps'] is int ? reads['maps'] as int : 0,
  );
}
