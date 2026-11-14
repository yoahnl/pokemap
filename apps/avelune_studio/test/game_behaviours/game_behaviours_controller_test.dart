import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_groups.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviours_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_resource.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../game_memory/game_memory_fakes.dart';
import 'game_behaviour_fakes.dart';

void main() {
  late FakeNarrativeIndex index;
  late FakeBehaviourSource source;
  late GameBehavioursController behaviours;

  setUp(() {
    source = FakeBehaviourSource(
      records: [
        behaviour(
          1,
          'Parler',
          source: NarrativeEventSourceRef.mapEnter('town'),
          enabled: true,
        ),
        behaviour(2, 'Sans carte'),
      ],
      maps: const [
        ProjectMapEntry(
          id: 'town',
          name: 'Bourg',
          relativePath: 'maps/town.json',
        ),
      ],
    );
    index = FakeNarrativeIndex()
      ..addFacts([memoryFact('met', 'Rencontre')])
      ..titlesByKind[NarrativeTitleKind.events] = [
        NarrativeTitle(id: behaviourId(1), title: 'Parler'),
        NarrativeTitle(id: behaviourId(2), title: 'Sans carte'),
      ];
    index.users['met'] = NarrativeUsages(
      owners: [
        NarrativeOwner(
          kind: NarrativeOwnerKind.event,
          id: behaviourId(1),
          role: NarrativeFactRole.read,
        ),
      ],
      notCovered: const [],
    );
    behaviours = GameBehavioursController(
      port: index,
      source: () => source,
      changed: () {},
    );
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test('opening reads the behaviour and state title pages only', () async {
    await behaviours.open();
    await flush();

    expect(index.titleRequests.toSet(), {
      NarrativeTitleKind.events,
      NarrativeTitleKind.facts,
    });
    expect(index.factRequests, isEmpty);
    expect(index.userRequests, isEmpty);
    expect(behaviours.rows, hasLength(2));
    expect(behaviours.factName('met'), 'Rencontre');
    expect(identical(behaviours.rows, behaviours.rows), isTrue);
  });

  test('grouping by state reads the usage index once', () async {
    await behaviours.open();
    behaviours.group(GameBehaviourGrouping.fact);
    await flush();
    await flush();

    expect(index.userRequests, [
      ['met'],
    ]);
    expect(behaviours.groups().map((group) => group.kind), [
      GameBehaviourGroupKind.fact,
      GameBehaviourGroupKind.withoutFact,
    ]);
    behaviours
      ..group(GameBehaviourGrouping.map)
      ..group(GameBehaviourGrouping.fact);
    await flush();
    expect(index.userRequests, hasLength(1));
  });

  test(
    'a behaviour deleted on disk is refused before any navigation',
    () async {
      await behaviours.open();
      final opened = <String>[];
      Future<bool> navigate(String id) async {
        opened.add(id);
        return true;
      }

      expect(await behaviours.reach(behaviourId(1), navigate), isTrue);
      index.titlesByKind[NarrativeTitleKind.events] = [
        NarrativeTitle(id: behaviourId(2), title: 'Sans carte'),
      ];

      expect(await behaviours.reach(behaviourId(1), navigate), isFalse);
      expect(opened, [behaviourId(1)]);
      expect(behaviours.refused, {behaviourId(1)});

      expect(
        await behaviours.reach(behaviourId(2), (_) async => false),
        isFalse,
      );
      expect(behaviours.refused, {behaviourId(1), behaviourId(2)});
    },
  );

  test('a saved project reloads the index; failures are stated', () async {
    await behaviours.open();
    expect(
      index.titleRequests.where((kind) => kind == NarrativeTitleKind.events),
      hasLength(1),
    );

    source.revision = Object();
    behaviours.sync();
    await flush();
    expect(
      index.titleRequests.where((kind) => kind == NarrativeTitleKind.events),
      hasLength(2),
    );

    index.titleFailure = const NarrativeIndexPreparationRequired(
      'narrativeTitles',
    );
    await behaviours.retry();
    expect(behaviours.saved.problem, GameMemoryProblem.preparationRequired);
  });
}
