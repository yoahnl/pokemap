import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_source.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:map_core/map_core_domain.dart';

String behaviourId(int index) =>
    'evt_00000000-0000-7000-8000-${index.toString().padLeft(12, '0')}';

NarrativeEventRecord behaviour(
  int index,
  String name, {
  NarrativeEventSourceRef? source,
  String? sceneId,
  bool? enabled,
  List<NarrativeEventCondition> conditions = const [],
}) {
  final draft = NarrativeEventDraft(
    id: behaviourId(index),
    name: name,
    source: source,
    sceneId: sceneId,
    conditions: conditions,
    priority: 0,
    order: index,
  );
  if (enabled == null) return NarrativeEventRecord.draft(draft);
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: draft.id,
      name: name,
      source: source!,
      conditions: conditions,
      sceneId: sceneId ?? 'talk',
      reusePolicy: NarrativeEventReusePolicy.reusable,
      resetPolicy: const NarrativeEventResetPolicy.never(),
      priority: 0,
      order: index,
    ),
    enabled: enabled,
  );
}

final class FakeBehaviourSource implements GameBehaviourSource {
  FakeBehaviourSource({
    List<NarrativeEventRecord> records = const [],
    this.maps = const [],
    this.scenes = const [],
    this.touchedIds = const {},
    this.names = const {},
    this.present = const {},
  }) : registry = NarrativeEventRegistry(
         schemaVersion: 1,
         mode: EventSystemMode.v2Only,
         records: records,
         legacyClaims: const [],
       );

  @override
  NarrativeEventRegistry? registry;
  @override
  final List<ProjectMapEntry> maps;
  @override
  final List<SceneAsset> scenes;
  final Set<String> touchedIds;
  final Map<String, String> names;
  final Map<String, bool> present;
  @override
  Object? revision;

  @override
  bool touched(String id) => touchedIds.contains(id);

  @override
  String? elementName(String mapId, MapStoryElementTarget target, String id) =>
      names['$mapId/${target.name}:$id'];

  @override
  bool? elementPresent(String mapId, MapStoryElementTarget target, String id) =>
      present['$mapId/${target.name}:$id'];
}
