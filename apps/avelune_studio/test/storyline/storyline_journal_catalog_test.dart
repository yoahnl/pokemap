import 'package:avelune_studio/features/game_memory/data/local_narrative_index_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_gateway.dart';
import 'package:avelune_studio/features/storyline/application/storyline_journal_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/features/storyline/data/local_storyline_read_adapter.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_behaviour_source.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../game_memory/game_memory_catalog_fixture.dart';

void main() {
  test(
    'a milestone journal and clue notes save through storyline.upsert',
    () async {
      final session = await openGameMemoryCatalog();
      final adapter = LocalMapWorkspaceAdapter();
      final maps = MapWorkspaceController(session, adapter);
      addTearDown(maps.dispose);
      await maps.initialize();
      final story = MapBuilderStoryBinding(
        maps: maps,
        changed: () {},
        view: () => null,
        gateway: (draft, saved) => StoryPublicationGateway(
          draft: draft,
          facts: LocalWorldAdapter(session: session, mapAdapter: adapter),
          stories: LocalStoryAdapter(session: session, mapAdapter: adapter),
          savedDialogues: saved,
        ),
      );
      final trame = StorylineTrameController(
        port: LocalStorylineReadAdapter(session),
        index: LocalNarrativeIndexAdapter(session),
        staging: MapBuilderStoryMemory(story, editable: () => true),
        source: () => MapBuilderStoryBehaviourSource(story),
        changed: () {},
      );
      await trame.open();
      expect(
        await trame.startStoryline(StorylineType.main, 'Histoire', 'Départ'),
        isTrue,
      );
      final storylineId = trame.view!.outline.storylines.single.id;
      final chapterId =
          trame.view!.outline.storylines.single.chapters.single.id;
      expect(
        await trame.createMilestone(storylineId, chapterId, 'Ouvrir la porte'),
        isTrue,
      );
      final stepId = trame.view!.milestones.single.milestone.id;

      expect(
        await trame.setMilestoneJournal(
          storylineId,
          chapterId,
          stepId,
          journal: (title: 'La porte', text: 'Léo garde la porte du bourg.'),
        ),
        isTrue,
        reason: trame.refusal,
      );
      expect(
        await trame.addJournalClue(
          storylineId,
          text: 'Léo connaît le code.',
          factId: 'fact_met',
        ),
        isTrue,
        reason: trame.refusal,
      );
      expect(
        await trame.addJournalClue(
          storylineId,
          text: 'Trois pièces suffisent.',
          factId: 'fact_coins',
        ),
        isFalse,
      );
      expect(trame.refusal, 'journalClueFactInvalid');
      expect(trame.booleanFacts.map((fact) => fact.id), {
        'fact_met',
        'fact_door',
      });

      expect(await story.save(), isTrue, reason: story.error);

      final saved = (await LocalStorylineReadAdapter(
        session,
      ).storylines()).singleWhere((item) => item.id == storylineId);
      final journal = saved.chapters.single.steps
          .singleWhere((step) => step.id == stepId)
          .journal!;
      expect(
        (journal.title.fallback, journal.text.fallback),
        ('La porte', 'Léo garde la porte du bourg.'),
      );
      expect(
        [
          for (final clue in saved.journalClues)
            (clue.id, clue.factId, clue.text.fallback),
        ],
        [('clue_l_o_conna_t_le_code', 'fact_met', 'Léo connaît le code.')],
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
