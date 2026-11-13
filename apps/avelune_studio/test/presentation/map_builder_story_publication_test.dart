import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

class _Port implements EventPort {
  _Port(this.maps);

  final MapWorkspaceController maps;
  final calls = <String>[];

  @override
  Future<ResourceMutationReceipt> publishEvent({
    required String id,
    required NarrativeEventRecord? base,
    required NarrativeEventRecord? current,
  }) async {
    calls.add(_call('one', {id: current?.name}));
    return _receipt([(id: id, base: base, current: current)]);
  }

  ResourceMutationReceipt _receipt(List<EventRecordChange> changes) {
    final before = maps.project!;
    final written = {for (final change in changes) change.id: change.current};
    final kept = [
      for (final record in before.eventRegistry!.records)
        if (!written.containsKey(record.id)) record else ?written[record.id],
    ];
    final ids = {for (final record in kept) record.id};
    return ResourceMutationReceipt(
      before: before,
      manifest: before.copyWith(
        eventRegistry: _registry([
          ...kept,
          for (final change in changes)
            if (!ids.contains(change.id)) ?change.current,
        ]),
      ),
      beforeRevision: 'r${calls.length - 1}',
      revision: 'r${calls.length}',
      changedPaths: const ['project.json'],
    );
  }
}

class _BatchPort extends _Port implements EventBatchPort {
  _BatchPort(super.maps);

  @override
  Future<ResourceMutationReceipt> publishEvents(
    List<EventRecordChange> changes,
  ) async {
    calls.add(
      _call('batch', {
        for (final change in changes) change.id: change.current?.name,
      }),
    );
    return _receipt(changes);
  }
}

String _call(String port, Map<String, String?> names) =>
    '$port ${[for (final MapEntry(:key, :value) in names.entries) '$key=$value'].join(' ')}';

NarrativeEventRegistry _registry(List<NarrativeEventRecord> records) =>
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: records,
      legacyClaims: const [],
    );

String _id(int index) =>
    'evt_00000000-0000-7000-8000-${index.toString().padLeft(12, '0')}';

NarrativeEventRecord _event(int index) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: _id(index),
        name: 'event $index',
        source: NarrativeEventSourceRef.mapEnter('a'),
        conditions: const [],
        sceneId: 'scene',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: index,
      ),
      enabled: false,
    );

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
  const count = 133;
  late MapWorkspaceController maps;
  late MapBuilderStoryBinding story;

  setUp(() async {
    final memory = WorkspaceMemoryPort(
      manifest: workspaceProject.copyWith(
        scenes: [_scene],
        eventRegistry: _registry([
          for (var index = 1; index <= count; index++) _event(index),
        ]),
      ),
    );
    memory.saved['a'] = workspaceMap('a');
    maps = MapWorkspaceController(workspaceSession, memory);
    await maps.initialize();
    final view = MapEditingViewportSession();
    story = MapBuilderStoryBinding(
      maps: maps,
      changed: () {},
      view: () => view,
    );
  });

  tearDown(() => maps.dispose());

  NarrativeEventRecord saved(int index) => maps.project!.eventRegistry!.records
      .singleWhere((record) => record.id == _id(index));

  void deleteThenRename() {
    expect(story.deleteBehaviour(saved(1)), isTrue, reason: story.error);
    for (var index = 2; index <= count - 1; index++) {
      expect(story.renameBehaviour(saved(index), 'renamed $index'), isTrue);
    }
    expect(story.deleteBehaviour(saved(count)), isTrue, reason: story.error);
  }

  test('a batch port gets slices of 128 then one call per deletion', () async {
    final port = _BatchPort(maps);
    deleteThenRename();

    expect(await story.publish(port), isTrue, reason: story.error);

    String renamed(int from, int to) => _call('batch', {
      for (var index = from; index <= to; index++) _id(index): 'renamed $index',
    });
    expect(port.calls, [
      renamed(2, 129),
      renamed(130, count - 1),
      _call('one', {_id(1): null}),
      _call('one', {_id(count): null}),
    ]);
    expect(story.dirty, isFalse);
    expect(maps.project!.eventRegistry!.records, hasLength(count - 2));
  });

  test('a single-record port gets one call per renamed behaviour', () async {
    final port = _Port(maps);
    for (var index = 2; index <= 4; index++) {
      expect(story.renameBehaviour(saved(index), 'renamed $index'), isTrue);
    }

    expect(await story.publish(port), isTrue, reason: story.error);

    expect(port.calls, [
      for (var index = 2; index <= 4; index++)
        _call('one', {_id(index): 'renamed $index'}),
    ]);
    expect(story.dirty, isFalse);
  });

  test('an edit saved then undone is published back as a change', () async {
    final port = _BatchPort(maps);
    expect(story.renameBehaviour(saved(2), 'Rencontre'), isTrue);
    expect(await story.publish(port), isTrue, reason: story.error);
    expect(story.dirty, isFalse);
    expect(story.canUndo, isTrue);

    story.undo();
    expect(story.dirty, isTrue);
    expect(await story.publish(port), isTrue, reason: story.error);

    expect(port.calls, [
      _call('batch', {_id(2): 'Rencontre'}),
      _call('batch', {_id(2): 'event 2'}),
    ]);
    expect(saved(2).name, 'event 2');
    expect(story.dirty, isFalse);

    story.redo();
    expect(story.dirty, isTrue);
    expect(story.canUndo, isTrue);
  });
}
