import 'package:map_core/map_core_domain.dart';

import '../../map_workspace/domain/map_workspace_port.dart';

class NarrativeDialogueSource {
  const NarrativeDialogueSource({
    required this.entry,
    required this.source,
    this.revision,
  });
  final ProjectDialogueEntry entry;
  final String source;
  final String? revision;
}

class NarrativePublication {
  const NarrativePublication({
    required this.base,
    required this.current,
    this.dialogues = const [],
    this.scenes = const [],
    this.cinematics = const [],
    this.facts = const [],
    this.storylines = const [],
    this.events = const [],
  });
  final MapWorkspaceDocument base;
  final MapData current;
  final List<NarrativeDialogueSource> dialogues;
  final List<SceneAsset> scenes;
  final List<CinematicAsset> cinematics;
  final List<NarrativeFactDefinition> facts;
  final List<StorylineAsset> storylines;
  final List<NarrativeEventRecord> events;
}

class NarrativePublicationReceipt {
  const NarrativePublicationReceipt({
    required this.beforeManifest,
    required this.manifest,
    required this.savedMap,
    required this.revision,
    required this.sourceRevisions,
    required this.changedPaths,
  });
  final ProjectManifest beforeManifest;
  final ProjectManifest manifest;
  final MapData savedMap;
  final String revision;
  final Map<String, String> sourceRevisions;
  final List<String> changedPaths;
}

abstract interface class NarrativePort {
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry);
  Future<NarrativePublicationReceipt> publish(NarrativePublication publication);
}

class NarrativeFailure implements Exception {
  const NarrativeFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
