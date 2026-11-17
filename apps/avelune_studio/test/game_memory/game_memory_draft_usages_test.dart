import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_fact_rows.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'game_memory_fakes.dart';

const triggerId = 'evt_00000000-0000-7000-8000-000000000001';

NarrativeEventRecord triggerReading(String fact) => NarrativeEventRecord.draft(
  NarrativeEventDraft(
    id: triggerId,
    name: 'Deuxième cas de Maman',
    source: NarrativeEventSourceRef.entityInteract('maison', 'absente'),
    conditions: [NarrativeEventCondition.fact(fact, true)],
    priority: 0,
    order: 1,
  ),
);

SceneAsset sceneWriting(String fact) => SceneAsset(
  id: 'shared',
  name: 'Scène partagée',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'write',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: fact, value: true),
        ),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'enter',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'write',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

void main() {
  late FakeNarrativeIndex index;
  late FakeMemoryStaging staging;
  late GameMemoryController memory;
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    index = FakeNarrativeIndex()
      ..addFacts([memoryFact('met', 'Rencontre'), memoryFact('door', 'Porte')]);
    index.users['met'] = NarrativeUsages(
      owners: const [
        NarrativeOwner(
          kind: NarrativeOwnerKind.event,
          id: triggerId,
          role: NarrativeFactRole.read,
        ),
        NarrativeOwner(
          kind: NarrativeOwnerKind.scene,
          id: 'shared',
          role: NarrativeFactRole.write,
        ),
        NarrativeOwner(kind: NarrativeOwnerKind.storyline, id: 'reference'),
      ],
      notCovered: const ['maps', 'dialogueTextFacts'],
    );
    index.users['door'] = NarrativeUsages(
      owners: const [],
      notCovered: const ['maps', 'dialogueTextFacts'],
    );
    staging = FakeMemoryStaging();
    memory = GameMemoryController(
      port: index,
      staging: staging,
      changed: () {},
    );
    addTearDown(memory.dispose);
    await memory.open();
    memory.select('met');
    await flush();
    memory.select('door');
    await flush();
  });

  test('draft conditions and consequences replace only their owner and undo restores both roles', () {
    final before = triggerReading('met');
    final scene = sceneWriting('met');
    staging.draft
      ..load(StoryDraftKind.event, triggerId, before)
      ..load(StoryDraftKind.scene, scene.id, scene)
      ..put(StoryDraftKind.event, triggerReading('door'))
      ..put(StoryDraftKind.scene, sceneWriting('door'));
    expect(memory.usages['met']!.owners, const [
      NarrativeOwner(kind: NarrativeOwnerKind.storyline, id: 'reference'),
    ]);
    expect(
      memory.usages['door']!.withRole(NarrativeFactRole.read).single.id,
      triggerId,
    );
    expect(
      memory.usages['door']!.withRole(NarrativeFactRole.write).single.id,
      'shared',
    );
    expect(memory.usages['met']!.notCovered, ['maps', 'dialogueTextFacts']);
    staging.draft.undo();
    expect(
      memory.usages['met']!.withRole(NarrativeFactRole.write).single.id,
      'shared',
    );
    expect(memory.usages['door']!.withRole(NarrativeFactRole.write), isEmpty);
    staging.draft.undo();
    expect(memory.usages['met']!.owners, index.users['met']!.owners);
    expect(memory.usages['door']!.owners, isEmpty);
    staging.draft.redo();
    expect(
      memory.usages['door']!.withRole(NarrativeFactRole.read).single.id,
      triggerId,
    );
    expect(index.userRequests, hasLength(2));
    expect(index.directoryRequests, isEmpty);
  });

  test('deleting a draft owner removes all of its saved roles', () {
    final scene = sceneWriting('met');
    staging.draft
      ..load(StoryDraftKind.scene, scene.id, scene)
      ..remove(StoryDraftKind.scene, scene.id);
    expect(memory.usages['met']!.withRole(NarrativeFactRole.write), isEmpty);
    expect(
      memory.usages['met']!.withRole(NarrativeFactRole.read).single.id,
      triggerId,
    );
  });

  test(
    'a created fact used by a draft trigger is neither unused nor discardable',
    () async {
      final id = memory.createFact(
        'Nouvelle rencontre',
        NarrativeValueKind.boolean,
      )!;
      await flush();
      staging.draft
        ..load(StoryDraftKind.event, triggerId, triggerReading('met'))
        ..put(StoryDraftKind.event, triggerReading(id));
      memory.toggle(GameMemoryFactFilter.neverRead);
      await flush();
      expect(
        memory.usages[id]
            ?.withRole(NarrativeFactRole.read)
            .map((owner) => owner.id),
        [triggerId],
      );
      expect(memory.rows.map((row) => row.id), isNot(contains(id)));
      expect(memory.discardCreated(id), isFalse);
      expect(staging.draft.currentOf(StoryDraftKind.fact, id), isNotNull);
      staging.draft.undo();
      expect(memory.discardCreated(id), isTrue);
    },
  );

  test('creating a string fact preserves its type and a saved label rename keeps its identity', () async {
    final id = memory.createFact('Mot de passe', NarrativeValueKind.string)!;
    expect(memory.current(id)!.initialValue, const NarrativeValue.string(''));
    memory.select('met');
    await flush();
    expect(memory.renameFact('met', 'Maman rencontrée'), isTrue);
    expect(memory.current('met')!.id, 'met');
    expect(memory.current('met')!.valueKind, NarrativeValueKind.boolean);
    expect(index.users['met']!.owners, memory.usages['met']!.owners);
  });
}
