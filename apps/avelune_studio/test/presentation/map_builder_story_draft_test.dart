import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'map_builder_story_support.dart';

class _RecordingPort implements EventPort {
  _RecordingPort(this.maps);

  final MapWorkspaceController maps;
  final published = <({String id, String? base, String? current})>[];

  @override
  Future<ResourceMutationReceipt> publishEvent({
    required String id,
    required NarrativeEventRecord? base,
    required NarrativeEventRecord? current,
  }) async {
    published.add((id: id, base: base?.name, current: current?.name));
    final before = maps.project!;
    final registry = before.eventRegistry!;
    return ResourceMutationReceipt(
      before: before,
      manifest: before.copyWith(
        eventRegistry: _registry([
          for (final record in registry.records)
            if (record.id != id) record else ?current,
        ]),
      ),
      beforeRevision: 'r${published.length - 1}',
      revision: 'r${published.length}',
      changedPaths: const ['project.json'],
    );
  }
}

NarrativeEventRegistry _registry(List<NarrativeEventRecord> records) =>
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: records,
      legacyClaims: const [],
    );

NarrativeEventRecord _event(
  int index,
  String name,
  NarrativeEventSourceRef source,
) => NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: 'evt_00000000-0000-7000-8000-${index.toString().padLeft(12, '0')}',
    name: name,
    source: source,
    conditions: const [],
    sceneId: 'scene',
    reusePolicy: NarrativeEventReusePolicy.oneShot,
    priority: 0,
    order: index,
  ),
  enabled: true,
);

final _meeting = _event(
  1,
  'meeting',
  NarrativeEventSourceRef.entityInteract('a', 'luth'),
);
final _arrival = _event(2, 'arrival', NarrativeEventSourceRef.mapEnter('a'));

final _scene = SceneAsset(
  id: 'scene',
  name: 'Scène',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'start-end',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

void main() {
  late MapWorkspaceController maps;
  late MapBuilderStoryBinding story;
  late _RecordingPort port;

  setUp(() async {
    final memory = WorkspaceMemoryPort(
      manifest: workspaceProject.copyWith(
        scenes: [_scene],
        eventRegistry: _registry([_meeting, _arrival]),
      ),
    );
    memory.saved['a'] = workspaceMap('a').copyWith(
      entities: const [
        MapEntity(
          id: 'luth',
          name: 'Luth',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 3, y: 2),
          npc: MapEntityNpcData(displayName: 'Luth'),
        ),
      ],
    );
    maps = MapWorkspaceController(workspaceSession, memory);
    await maps.initialize();
    final view = MapEditingViewportSession();
    story = MapBuilderStoryBinding(
      maps: maps,
      changed: () {},
      view: () => view,
    );
    port = _RecordingPort(maps);
  });

  tearDown(() => maps.dispose());

  NarrativeEventRecord saved(String id) => maps.project!.eventRegistry!.records
      .singleWhere((record) => record.id == id);

  void changeOutside(NarrativeEventRecord replacement) {
    final before = maps.project!;
    maps.acceptResources(
      before,
      before.copyWith(
        eventRegistry: _registry([
          for (final record in before.eventRegistry!.records)
            record.id == replacement.id ? replacement : record,
        ]),
      ),
    );
  }

  test(
    'saving behaviours never overwrites an event changed elsewhere',
    () async {
      expect(story.renameBehaviour(saved(_meeting.id), 'Rencontre'), isTrue);
      changeOutside(
        _event(2, 'arrivée MCP', NarrativeEventSourceRef.mapEnter('a')),
      );

      expect(
        await story.publish(storyEvents(story, port)),
        isTrue,
        reason: story.error,
      );

      expect(port.published, [
        (id: _meeting.id, base: 'meeting', current: 'Rencontre'),
      ]);
      expect(saved(_arrival.id).name, 'arrivée MCP');
      expect(saved(_meeting.id).name, 'Rencontre');
      expect(story.dirty, isFalse);
    },
  );

  test('the same event changed on both sides is reported and kept', () async {
    expect(story.renameBehaviour(saved(_meeting.id), 'Rencontre'), isTrue);
    changeOutside(
      _event(
        1,
        'réunion MCP',
        NarrativeEventSourceRef.entityInteract('a', 'luth'),
      ),
    );

    expect(await story.publish(storyEvents(story, port)), isFalse);

    expect(port.published, isEmpty);
    expect(saved(_meeting.id).name, 'réunion MCP');
    expect(story.dirty, isTrue);
    expect(story.error, contains('Rencontre'));
    expect(
      story.behaviours
          .registry(maps.project!)!
          .records
          .singleWhere((record) => record.id == _meeting.id)
          .name,
      'Rencontre',
    );
  });

  test('a conflict does not hold back the other behaviours', () async {
    expect(story.renameBehaviour(saved(_meeting.id), 'Rencontre'), isTrue);
    expect(story.renameBehaviour(saved(_arrival.id), 'Arrivée'), isTrue);
    changeOutside(
      _event(
        1,
        'réunion MCP',
        NarrativeEventSourceRef.entityInteract('a', 'luth'),
      ),
    );

    expect(await story.publish(storyEvents(story, port)), isFalse);

    expect(port.published, [
      (id: _arrival.id, base: 'arrival', current: 'Arrivée'),
    ]);
    expect(saved(_arrival.id).name, 'Arrivée');
    expect(story.dirty, isTrue);
  });
}
