import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/data/local_narrative_index_adapter.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../pokemon/pokemon_scoped_save_counting_reader.dart';
import 'game_memory_catalog_fixture.dart';
import 'game_memory_fakes.dart';

void main() {
  test(
    'a usage target reads only its storyline among unrelated documents',
    () async {
      final session = await openGameMemoryCatalog(
        unrelated: 30,
        storylines: true,
      );
      final reader = CountingReader();
      final index = LocalNarrativeIndexAdapter(session, reader: reader);
      final memory = GameMemoryController(
        port: index,
        staging: FakeMemoryStaging(),
        changed: () {},
      );
      addTearDown(memory.dispose);
      const owner = NarrativeOwner(
        kind: NarrativeOwnerKind.storyline,
        id: 'main',
        role: NarrativeFactRole.read,
      );

      expect(await memory.storyUsageTargets(owner, 'fact_met'), [
        (stepId: 'second', title: 'Deuxième jalon'),
      ]);
      expect(reader.definitions, ['main']);
      expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
      expect(reader.unitKeys.where((key) => key.startsWith('map')), isEmpty);
      reader.clear();
      expect(await memory.storyUsageTargets(owner, 'fact_met'), [
        (stepId: 'second', title: 'Deuxième jalon'),
      ]);
      expect(reader.paths, isEmpty);

      expect(await index.usageStoryline('missing'), isNull);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('a touched storyline keeps unexecuted citations separate and locates their exact milestone', () async {
    final index = FakeNarrativeIndex()
      ..addFacts([
        memoryFact('fact_met', 'Rencontre'),
        memoryFact('door', 'Porte'),
      ]);
    final staging = FakeMemoryStaging();
    final memory = GameMemoryController(
      port: index,
      staging: staging,
      changed: () {},
    );
    addTearDown(memory.dispose);
    await memory.open();
    memory.select('door');
    await Future<void>.delayed(Duration.zero);
    final base = memoryUsageStory();
    final next = base.copyWith(
      sceneLinks: [
        StorylineSceneLink(
          id: 'link',
          chapterId: 'chapter',
          stepId: 'second',
          label: 'Sortie',
          state: StorylineSceneLinkState.placeholder,
          role: StorylineSceneLinkRole.primary,
          order: 0,
          outcomeLinks: [
            StorylineSceneOutcomeLink(
              id: 'outcome',
              outcomeId: 'done',
              effects: [
                StorylineEffect.emitFactValue(
                  factId: 'door',
                  value: const NarrativeValue.boolean(true),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    staging.draft
      ..load(StoryDraftKind.story, base.id, base)
      ..put(StoryDraftKind.story, next);
    final usage = memory.usages['door']!;
    expect(usage.owners, const [
      NarrativeOwner(kind: NarrativeOwnerKind.storyline, id: 'main'),
    ]);
    expect(usage.withRole(NarrativeFactRole.write), isEmpty);
    expect(await memory.storyUsageTargets(usage.owners.single, 'door'), [
      (stepId: 'second', title: 'Deuxième jalon'),
    ]);
    expect(index.usageStoryRequests, isEmpty);
    staging.draft.undo();
    expect(memory.usages['door']!.owners, isEmpty);
  });
}
