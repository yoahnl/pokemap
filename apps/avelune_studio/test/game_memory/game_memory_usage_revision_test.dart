import 'dart:async';

import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_fact_rows.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_memory_fakes.dart';

void main() {
  test('two revisions while titles are loading retain only the latest titles and usages', () async {
    final index = FakeNarrativeIndex()
      ..addFacts([memoryFact('met', 'Rencontre')]);
    final staging = FakeMemoryStaging()..revision = Object();
    final memory = GameMemoryController(
      port: index,
      staging: staging,
      changed: () {},
    );
    addTearDown(memory.dispose);
    await memory.open();
    memory.toggle(GameMemoryFactFilter.neverRead);
    await Future<void>.delayed(Duration.zero);
    final second = Completer<List<NarrativeTitle>>();
    final third = Completer<List<NarrativeTitle>>();
    index.titleLoader = (_) => second.future;
    staging.revision = Object();
    memory.sync();
    index.titleLoader = (_) => third.future;
    staging.revision = Object();
    memory.sync();
    third.complete(const [NarrativeTitle(id: 'latest', title: 'Révision 3')]);
    await Future<void>.delayed(Duration.zero);
    second.complete(const [
      NarrativeTitle(id: 'obsolete', title: 'Révision 2'),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(memory.rows.map((row) => row.id), ['latest']);
    expect(index.userRequests.last, ['latest']);
  });

  test('a revision loads filter usages for newly indexed facts after their titles arrive', () async {
    final index = FakeNarrativeIndex()
      ..addFacts([memoryFact('met', 'Rencontre')]);
    final staging = FakeMemoryStaging()..revision = Object();
    final memory = GameMemoryController(
      port: index,
      staging: staging,
      changed: () {},
    );
    addTearDown(memory.dispose);
    await memory.open();
    memory.toggle(GameMemoryFactFilter.neverRead);
    await Future<void>.delayed(Duration.zero);
    final titles = Completer<List<NarrativeTitle>>();
    index.titleLoader = (_) => titles.future;
    staging.revision = Object();
    memory.sync();
    await Future<void>.delayed(Duration.zero);
    titles.complete(const [
      NarrativeTitle(id: 'met', title: 'Rencontre'),
      NarrativeTitle(id: 'new', title: 'Nouveau'),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(index.userRequests.last, ['met', 'new']);
    expect(memory.rows.map((row) => row.id), ['met', 'new']);
    expect(memory.usagesFilter.ready, isTrue);
  });

  test(
    'a filter in flight restarts its saved usages after a revision change',
    () async {
      final old = Completer<Map<String, NarrativeUsages>>();
      final index = FakeNarrativeIndex()
        ..addFacts([
          memoryFact('met', 'Rencontre'),
          memoryFact('door', 'Porte'),
        ]);
      index.userLoader = (_) => old.future;
      final staging = FakeMemoryStaging()..revision = Object();
      final memory = GameMemoryController(
        port: index,
        staging: staging,
        changed: () {},
      );
      addTearDown(memory.dispose);
      await memory.open();
      memory.toggle(GameMemoryFactFilter.neverRead);
      await Future<void>.delayed(Duration.zero);
      index.userLoader = (_) async => {
        'met': NarrativeUsages(
          owners: const [
            NarrativeOwner(
              kind: NarrativeOwnerKind.scene,
              id: 'new',
              role: NarrativeFactRole.read,
            ),
          ],
          notCovered: const [],
        ),
        'door': NarrativeUsages(owners: const [], notCovered: const []),
      };
      staging.revision = Object();
      memory.sync();
      await Future<void>.delayed(Duration.zero);
      old.complete({
        for (final id in ['met', 'door'])
          id: NarrativeUsages(owners: const [], notCovered: const []),
      });
      await Future<void>.delayed(Duration.zero);
      expect(index.userRequests, hasLength(2));
      expect(memory.usagesFilter.ready, isTrue);
      expect(memory.rows.map((row) => row.id), ['door']);
    },
  );

  test(
    'a late saved usage result cannot replace a newer project revision',
    () async {
      final old = Completer<Map<String, NarrativeUsages>>();
      final index = FakeNarrativeIndex()
        ..addFacts([memoryFact('met', 'Rencontre')]);
      final staging = FakeMemoryStaging()..revision = Object();
      index.userLoader = (_) => old.future;
      final memory = GameMemoryController(
        port: index,
        staging: staging,
        changed: () {},
      );
      addTearDown(memory.dispose);
      await memory.open();
      memory.select('met');
      await Future<void>.delayed(Duration.zero);
      final latest = NarrativeUsages(
        owners: const [
          NarrativeOwner(
            kind: NarrativeOwnerKind.scene,
            id: 'current',
            role: NarrativeFactRole.read,
          ),
        ],
        notCovered: const [],
      );
      index.userLoader = (_) async => {'met': latest};
      staging.revision = Object();
      memory.sync();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      old.complete({
        'met': NarrativeUsages(
          owners: const [
            NarrativeOwner(
              kind: NarrativeOwnerKind.scene,
              id: 'obsolete',
              role: NarrativeFactRole.read,
            ),
          ],
          notCovered: const [],
        ),
      });
      await Future<void>.delayed(Duration.zero);
      expect(index.userRequests, hasLength(2));
      expect(memory.usages['met']!.owners, latest.owners);
    },
  );
}
