import 'dart:async';

import 'package:map_core/map_core_domain.dart';

import '../../events/domain/event_record_view.dart';
import '../../game_behaviours/application/game_behaviour_rows.dart';
import '../../game_behaviours/application/game_behaviour_source.dart';
import '../../game_memory/application/game_memory_resource.dart';
import '../../game_memory/domain/narrative_index_port.dart';
import '../../map_workspace/application/map_story_elements.dart';
import '../domain/scene_document.dart';
import 'scene_changed_facts.dart';
import 'scene_path_preview.dart';

typedef SceneOpener = void Function(String sceneId, String? behaviourId);

abstract interface class SceneFocusDraft {
  bool get editable;

  SceneAsset? touched(String sceneId);

  bool created(String sceneId);

  bool edit(SceneAsset next);

  String? detach(String eventId, String name);
}

typedef SceneLauncherPlace = ({
  String? mapName,
  MapStoryElementTarget? target,
  String? elementName,
});

final class SceneFocusController {
  SceneFocusController({
    required this.port,
    required this.draft,
    required this.source,
    required this.sceneId,
    required this.changed,
    this.behaviourId,
  });

  final NarrativeIndexPort port;
  final SceneFocusDraft draft;
  final GameBehaviourSource Function() source;
  final String sceneId;
  final String? behaviourId;
  final void Function() changed;
  final document = GameMemoryResource<SceneDocument>();
  final facts = GameMemoryResource<List<NarrativeTitle>>();
  final choices = <String, String>{};
  var previewing = false;

  Future<void> open() {
    unawaited(facts.load(() => port.titles(NarrativeTitleKind.facts), changed));
    return document.load(_read, changed);
  }

  Future<void> retry() => document.load(_read, changed, force: true);

  Future<SceneDocument> _read() async {
    if (draft.created(sceneId)) {
      return SceneDocument(
        scene: draft.touched(sceneId)!,
        dialogues: const [],
        missingDialogueIds: const [],
        events: const [],
        maps: const {},
        mapReads: 0,
      );
    }
    return port.sceneDocument(sceneId);
  }

  SceneAsset? get scene => draft.touched(sceneId) ?? document.value?.scene;

  List<NarrativeEventRecord> get launchers {
    final current = source();
    final records = {
      for (final record
          in current.registry?.records ?? const <NarrativeEventRecord>[])
        record.id: record,
    };
    final saved = document.value?.events ?? const <NarrativeEventRecord>[];
    final savedIds = {for (final event in saved) event.id};
    return [
      for (final event in saved)
        if ((current.touched(event.id) ? records[event.id] : event)
            case final live? when live.sceneId == sceneId)
          live,
      for (final record in records.values)
        if (!savedIds.contains(record.id) &&
            current.touched(record.id) &&
            record.sceneId == sceneId)
          record,
    ];
  }

  bool get shared => launchers.length > 1;

  bool get canDetach =>
      draft.editable &&
      shared &&
      launchers.any((record) => record.id == behaviourId);

  List<String> get changedFactIds => switch (scene) {
    final scene? => sceneChangedFactIds(scene.graph),
    null => const [],
  };

  String? factName(String id) {
    final name = facts.value
        ?.where((fact) => fact.id == id)
        .firstOrNull
        ?.title
        .trim();
    return name == null || name.isEmpty ? null : name;
  }

  SceneLauncherPlace place(NarrativeEventRecord record) {
    final at = mapStoryLocation(record);
    if (at == null) return (mapName: null, target: null, elementName: null);
    final current = source();
    final (mapId, target, elementId) = at;
    final kind = mapDirectoryKind(target);
    return (
      mapName:
          current.maps.where((entry) => entry.id == mapId).firstOrNull?.name ??
          document.value?.maps[mapId]?.name,
      target: target,
      elementName:
          current.elementName(mapId, target, elementId) ??
          (kind == null
              ? null
              : document.value?.maps[mapId]?.element(kind, elementId)?.name),
    );
  }

  ScenePath? get path => switch ((previewing, scene)) {
    (true, final scene?) => previewScenePath(scene.graph, choices),
    _ => null,
  };

  void togglePreview() {
    previewing = !previewing;
    choices.clear();
    changed();
  }

  void choose(String nodeId, String portId) {
    choices[nodeId] = portId;
    changed();
  }

  void restart() {
    choices.clear();
    changed();
  }

  bool edit(SceneAsset next) => next.id == sceneId && draft.edit(next);

  String? detach(String name) {
    final id = behaviourId;
    if (id == null || !canDetach) return null;
    return draft.detach(id, name);
  }
}
