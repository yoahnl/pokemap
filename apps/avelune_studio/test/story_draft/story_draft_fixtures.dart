import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_saved.dart';
import 'package:map_core/map_core.dart';

final class SavedStore implements StoryDraftSaved {
  SavedStore([Iterable<Object> values = const []]) {
    values.forEach(save);
  }

  final _values = <StoryDraftRef, Object>{};
  var reads = 0;

  void save(Object value) {
    final kind = StoryDraftKind.of(value);
    _values[(kind: kind, id: kind.idOf(value))] = value;
  }

  void publish(StoryDraftEntry<Object> entry) {
    final current = entry.current;
    current == null ? _values.remove(entry.ref) : _values[entry.ref] = current;
  }

  @override
  Object? read(StoryDraftKind<Object> kind, String id) {
    reads++;
    return _values[(kind: kind, id: id)];
  }
}

String eventId(int index) =>
    'evt_00000000-0000-7000-8000-${index.toString().padLeft(12, '0')}';

NarrativeEventRecord event(int index, [String name = 'Event']) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: eventId(index),
        name: name,
        source: NarrativeEventSourceRef.mapEnter('map'),
        conditions: const [],
        sceneId: 'scene',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: index,
      ),
      enabled: false,
    );

SceneAsset scene(String id, [String name = 'Scene']) => SceneAsset(
  id: id,
  name: name,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'end', kind: SceneNodeKind.end, payload: SceneEndPayload()),
    ],
    edges: [
      SceneEdge(
        id: 'end',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

StoryDialogueSource dialogue(String id, [String text = 'Bonjour']) =>
    StoryDialogueSource(
      entry: ProjectDialogueEntry(
        id: id,
        name: id,
        relativePath: 'dialogues/$id.yarn',
      ),
      source: text,
    );

NarrativeFactDefinition fact(String id, [String label = 'Fact']) =>
    NarrativeFactDefinition(id: id, label: label);

StorylineAsset story(String id, [String title = 'Story']) =>
    StorylineAsset(id: id, type: StorylineType.main, title: title);

WorldRuleDefinition rule(String id, [String label = 'Rule']) =>
    WorldRuleDefinition(
      id: id,
      label: label,
      source: const WorldRuleSource(
        kind: WorldRuleSourceKind.fact,
        sourceId: 'fact',
        predicate: WorldRuleSourcePredicate.isTrue,
      ),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.narrativeEvent,
        mapId: 'map',
        eventId: 'event',
      ),
      effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventEnabled),
    );

NarrativeEventRegistry registry(List<NarrativeEventRecord> records) =>
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: records,
      legacyClaims: const [],
    );

ProjectManifest manifest({
  List<NarrativeEventRecord>? events,
  List<SceneAsset> scenes = const [],
  List<StoryDialogueSource> dialogues = const [],
  List<NarrativeFactDefinition> facts = const [],
  List<StorylineAsset> stories = const [],
  List<WorldRuleDefinition> rules = const [],
}) => ProjectManifest(
  name: 'Story draft',
  maps: const [],
  tilesets: const [],
  eventRegistry: events == null ? null : registry(events),
  scenes: scenes,
  dialogues: [for (final dialogue in dialogues) dialogue.entry],
  facts: facts,
  storylines: stories,
  worldRules: rules,
);
