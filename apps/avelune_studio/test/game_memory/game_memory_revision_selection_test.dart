import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_memory_fakes.dart';

void main() {
  test('a revision refresh reloads the selected fact without reading unrelated facts', () async {
    final index = FakeNarrativeIndex()
      ..addFacts([memoryFact('met', 'Avant'), memoryFact('other', 'Autre')]);
    final staging = FakeMemoryStaging();
    final memory = GameMemoryController(
      port: index,
      staging: staging,
      changed: () {},
    );
    addTearDown(memory.dispose);
    await memory.open();
    memory.select('met');
    await Future<void>.delayed(Duration.zero);
    expect(memory.current('met')!.label, 'Avant');
    index.definitions['met'] = memoryFact('met', 'Après sauvegarde');
    staging.revision = Object();
    memory.sync();
    await Future<void>.delayed(Duration.zero);
    expect(memory.current('met')?.label, 'Après sauvegarde');
    expect(index.factRequests, [
      ['met'],
      ['met'],
    ]);
  });

  test('a refresh with no selection keeps fact definitions unloaded', () async {
    final index = FakeNarrativeIndex()
      ..addFacts([memoryFact('met', 'Rencontre')]);
    final staging = FakeMemoryStaging();
    final memory = GameMemoryController(
      port: index,
      staging: staging,
      changed: () {},
    );
    addTearDown(memory.dispose);
    await memory.open();
    staging.revision = Object();
    memory.sync();
    await Future<void>.delayed(Duration.zero);
    expect(index.factRequests, isEmpty);
  });

  test(
    'refreshing the selected saved fact preserves its unpublished draft',
    () async {
      final index = FakeNarrativeIndex()
        ..addFacts([memoryFact('met', 'Enregistré')]);
      final staging = FakeMemoryStaging();
      final memory = GameMemoryController(
        port: index,
        staging: staging,
        changed: () {},
      );
      addTearDown(memory.dispose);
      await memory.open();
      memory.select('met');
      await Future<void>.delayed(Duration.zero);
      expect(memory.renameFact('met', 'Brouillon'), isTrue);
      staging.revision = Object();
      memory.sync();
      await Future<void>.delayed(Duration.zero);
      expect(memory.current(memory.selectedFact!)!.label, 'Brouillon');
    },
  );
}
