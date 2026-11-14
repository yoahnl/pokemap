import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_fact_rows.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_resource.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'game_memory_fakes.dart';

void main() {
  late FakeNarrativeIndex index;
  late FakeMemoryStaging staging;
  late GameMemoryController memory;
  var changes = 0;

  setUp(() {
    changes = 0;
    index = FakeNarrativeIndex()
      ..addFacts([
        memoryFact('met', 'Rencontre'),
        memoryFact('coins', 'Pièces', value: NarrativeValue.integer(3)),
        for (var i = 0; i < 40; i++) memoryFact('unused_$i', 'Inutile $i'),
      ]);
    staging = FakeMemoryStaging();
    memory = GameMemoryController(
      port: index,
      staging: staging,
      changed: () => changes++,
    );
    addTearDown(memory.dispose);
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test('the list comes from the index and reads only revealed facts', () async {
    await memory.open();

    expect(memory.rows, hasLength(42));
    expect(memory.rows.first.value, isNull);
    expect(index.factRequests, isEmpty);

    memory
      ..reveal('met')
      ..reveal('coins')
      ..reveal('met');
    await flush();

    expect(index.factRequests, [
      ['met', 'coins'],
    ]);
    expect(memory.rows[1].value, NarrativeValue.integer(3));
    expect(memory.rows[5].value, isNull);
    expect(changes, greaterThan(0));
  });

  test('search and filters narrow the list from the usage index', () async {
    index.users['met'] = NarrativeUsages(
      owners: const [
        NarrativeOwner(
          kind: NarrativeOwnerKind.scene,
          id: 'gate',
          role: NarrativeFactRole.read,
        ),
      ],
      notCovered: const ['maps'],
    );
    index.users['coins'] = NarrativeUsages(
      owners: const [
        NarrativeOwner(
          kind: NarrativeOwnerKind.scene,
          id: 'gate',
          role: NarrativeFactRole.write,
        ),
      ],
      notCovered: const ['maps'],
    );
    await memory.open();

    memory.search('pIèc');
    expect([for (final row in memory.rows) row.id], ['coins']);
    memory.search('');

    memory.toggle(GameMemoryFactFilter.neverWritten);
    expect(memory.usagesFilter.loading, isTrue);
    await flush();
    expect(index.userRequests.single, hasLength(42));
    expect(memory.rows.map((row) => row.id), isNot(contains('coins')));
    expect(memory.rows.map((row) => row.id), contains('met'));

    memory.toggle(GameMemoryFactFilter.neverRead);
    expect(memory.rows.map((row) => row.id), isNot(contains('met')));
    expect(memory.rows, hasLength(40));
    expect(index.userRequests, hasLength(1));
  });

  test(
    'a missing preparation and a non catalog project are reported',
    () async {
      index.titleFailure = const NarrativeIndexPreparationRequired(
        'narrativeTitles',
      );
      await memory.open();
      expect(memory.facts.problem, GameMemoryProblem.preparationRequired);

      index.titleFailure = const NarrativeIndexUnavailable();
      await memory.retry();
      expect(memory.facts.problem, GameMemoryProblem.unavailable);

      index.titleFailure = StateError('disque absent');
      await memory.retry();
      expect(memory.facts.problem, GameMemoryProblem.failed);
      expect('${memory.facts.cause}', contains('disque absent'));

      index.titleFailure = null;
      await memory.retry();
      expect(memory.facts.ready, isTrue);
    },
  );

  test('a created fact is staged with a canonical unique id', () async {
    index.addFacts([memoryFact('fact_rencontre', 'Rencontre')]);
    await memory.open();

    final id = memory.createFact('Rencontre', NarrativeValueKind.integer);

    expect(id, 'fact_rencontre_2');
    expect(staging.stages, 1);
    final entry = staging.draft.entryOf(StoryDraftKind.fact, id!)!;
    expect(entry.creation, isTrue);
    expect(entry.current!.initialValue, NarrativeValue.integer(0));
    final row = memory.rows.last;
    expect((row.id, row.created, row.unsaved), (id, true, true));
    expect(memory.selectedFact, id);

    expect(memory.discardCreated(id), isTrue);
    expect(staging.draft.isTouched(StoryDraftKind.fact, id), isFalse);
    expect(memory.rows.map((row) => row.id), isNot(contains(id)));
  });

  test('a rename keeps the saved fact as base and its type', () async {
    await memory.open();
    memory.reveal('coins');
    await flush();

    expect(memory.renameFact('coins', '  Or  '), isTrue);

    expect(staging.facts['coins'], index.definitions['coins']);
    final entry = staging.draft.entryOf(StoryDraftKind.fact, 'coins')!;
    expect(entry.base, index.definitions['coins']);
    expect(entry.current!.label, 'Or');
    expect(entry.current!.initialValue, NarrativeValue.integer(3));
    expect(memory.rows[1].label, 'Or');
    expect(memory.rows[1].unsaved, isTrue);
  });

  test(
    'a saved project refreshes the index instead of keeping stale names',
    () async {
      await memory.open();
      memory.reveal('met');
      await flush();
      memory.sync();
      expect(index.titleRequests, hasLength(1));

      index.addFacts([memoryFact('met', 'Rencontre avec Léo')]);
      staging.revision = Object();
      memory.sync();
      await flush();
      await flush();

      expect(index.titleRequests, hasLength(2));
      expect(memory.details, isEmpty);
      expect(memory.rows.first.label, 'Rencontre avec Léo');
    },
  );

  test('a read only memory stages nothing', () async {
    staging.editable = false;
    await memory.open();
    memory.reveal('met');
    await flush();

    expect(memory.createFact('Nouveau', NarrativeValueKind.boolean), isNull);
    expect(memory.renameFact('met', 'Autre'), isFalse);
    expect(staging.stages, 0);
  });

  test('selecting a fact reads its users and their names', () async {
    index.users['met'] = NarrativeUsages(
      owners: const [
        NarrativeOwner(
          kind: NarrativeOwnerKind.worldRule,
          id: 'world_rule_door',
          role: NarrativeFactRole.read,
        ),
      ],
      notCovered: const ['maps'],
    );
    index.titlesByKind[NarrativeTitleKind.worldRules] = const [
      NarrativeTitle(id: 'world_rule_door', title: 'Porte'),
    ];
    await memory.open();

    memory.select('met');
    await flush();
    await flush();

    expect(index.userRequests, [
      ['met'],
    ]);
    expect(
      memory.names.name(NarrativeTitleKind.worldRules, 'world_rule_door'),
      'Porte',
    );
    expect(index.titleRequests, isNot(contains(NarrativeTitleKind.scenes)));
  });

  test('rules are edited and created through the draft', () async {
    final door = WorldRuleDefinition(
      id: 'world_rule_door',
      label: 'Porte',
      source: const WorldRuleSource(
        kind: WorldRuleSourceKind.fact,
        sourceId: 'met',
        predicate: WorldRuleSourcePredicate.isTrue,
      ),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: 'town',
        entityId: 'npc',
      ),
      effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
    );
    index.rules = [door];
    await memory.open();
    await memory.rules.open();
    memory.reveal('coins');
    await flush();

    expect(
      memory.rules.update(door.id, effect: WorldRuleEffectKind.eventEnabled),
      isFalse,
    );
    expect(
      memory.rules.update(door.id, effect: WorldRuleEffectKind.entityVisible),
      isTrue,
    );
    expect(staging.rules[door.id], door);
    final edited = staging.draft.entryOf(StoryDraftKind.worldRule, door.id)!;
    expect(edited.base, door);
    expect(edited.current!.effect.kind, WorldRuleEffectKind.entityVisible);

    final id = memory.rules.create(
      label: 'Porte',
      condition: (
        factId: 'coins',
        operator: NarrativeFactOperator.greaterThan,
        value: NarrativeValue.integer(2),
      ),
      map: const ProjectMapEntry(
        id: 'town',
        name: 'Bourg',
        relativePath: 'maps/town.json',
      ),
      character: (id: 'npc', name: 'Léo'),
      visible: false,
    );

    expect(id, 'world_rule_porte');
    final created = staging.draft.entryOf(StoryDraftKind.worldRule, id!)!;
    expect(created.creation, isTrue);
    expect(created.current!.target.label, 'Léo');
    expect(
      created.current!.source.expectedFactValue,
      NarrativeValue.integer(2),
    );
    expect(memory.rules.rows.map((row) => row.rule.id), [door.id, id]);
    expect(memory.rules.selected, id);
  });
}
