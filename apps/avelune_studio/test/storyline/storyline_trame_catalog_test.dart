import 'package:avelune_studio/features/game_memory/data/local_narrative_index_adapter.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_gateway.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_condition_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_journal_edits.dart';
import 'package:avelune_studio/features/storyline/data/local_storyline_read_adapter.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_behaviour_source.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart'
    show CatalogGenerationRetention, CatalogStorageStore;
import 'package:map_core/map_core.dart';

import '../game_memory/game_memory_catalog_fixture.dart';
import '../pokemon/pokemon_scoped_save_counting_reader.dart';

Future<
  ({
    ProjectSession session,
    MapBuilderStoryBinding story,
    StorylineTrameController trame,
    CountingReader reader,
  })
>
_openTrame() async {
  final session = await openGameMemoryCatalog(unrelated: 50);
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
  final reader = CountingReader();
  final trame = StorylineTrameController(
    port: LocalStorylineReadAdapter(session, reader: reader),
    index: LocalNarrativeIndexAdapter(session, reader: reader),
    staging: MapBuilderStoryMemory(story, editable: () => true),
    source: () => MapBuilderStoryBehaviourSource(story),
    changed: () {},
  );
  return (session: session, story: story, trame: trame, reader: reader);
}

void main() {
  test('loading storyline documents reads each definition once', () async {
    final session = await openGameMemoryCatalog(
      unrelated: 2,
      prepared: false,
      storylines: true,
      unrelatedDialogues: true,
    );
    final store = await CatalogStorageStore.open(
      projectRoot: session.directoryPath,
    );
    final catalog = await CatalogGenerationRetention(
      store: store,
    ).openSnapshot();
    try {
      expect(
        await catalog.snapshot.lookup(
          CatalogDefinitionKey(
            CatalogDefinitionKind.workspaceState,
            'narrativeEventDocuments',
          ),
        ),
        isNotNull,
      );
    } finally {
      await catalog.close();
    }
    final reader = CountingReader();

    final storylines = await LocalStorylineReadAdapter(
      session,
      reader: reader,
    ).storylines();

    expect(storylines, hasLength(3));
    expect(
      storylines.singleWhere((storyline) => storyline.id == 'main'),
      memoryUsageStory(),
    );
    expect(
      reader.definitions,
      unorderedEquals(['main', 'unrelated_story_0', 'unrelated_story_1']),
    );
    expect(
      reader.unitKeys.where(
        (key) =>
            key == 'workspaceState:narrativeEventDocuments' ||
            key.contains('"eventRegistry"'),
      ),
      isEmpty,
    );
  });

  test('chapter and journal metadata stay targeted and conditions reopen from the catalog', () async {
    final (session: session, story: story, trame: initial, reader: reader) =
        await _openTrame();
    await initial.open();
    expect(
      await initial.startStoryline(
        StorylineType.sideQuest,
        'La lettre',
        'Livraison',
      ),
      isTrue,
    );
    final storylineId = initial.view!.outline.storylines.single.id;
    final chapterId =
        initial.view!.outline.storylines.single.chapters.single.id;
    expect(
      await initial.createMilestone(storylineId, chapterId, 'Porter la lettre'),
      isTrue,
    );
    final stepId = initial.view!.milestones.single.milestone.id;
    expect(await story.save(), isTrue, reason: story.error);
    final trame = StorylineTrameController(
      port: LocalStorylineReadAdapter(session, reader: reader),
      index: LocalNarrativeIndexAdapter(session, reader: reader),
      staging: MapBuilderStoryMemory(story, editable: () => true),
      source: () => MapBuilderStoryBehaviourSource(story),
      changed: () {},
    );
    await trame.open();
    expect(await trame.prepare(), isTrue);
    reader.clear();
    expect(
      await trame.renameChapter(storylineId, chapterId, 'Une livraison'),
      isTrue,
    );
    expect(
      await trame.setMilestoneJournal(
        storylineId,
        chapterId,
        stepId,
        journal: (title: 'La lettre', text: 'Retrouver le destinataire.'),
      ),
      isTrue,
    );
    expect(
      await trame.setSimpleCondition(
        storylineId,
        chapterId,
        stepId,
        entry: true,
        factId: 'fact_met',
      ),
      isTrue,
    );
    expect(
      await trame.addJournalClue(
        storylineId,
        text: 'Le guide connaît le chemin.',
        factId: 'fact_met',
      ),
      isTrue,
    );
    expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
    expect(reader.unitKeys.where((key) => key.startsWith('map')), isEmpty);
    expect(reader.definitions, isEmpty);
    expect(await story.save(), isTrue, reason: story.error);
    final fresh = CountingReader();
    final saved = (await LocalStorylineReadAdapter(
      session,
      reader: fresh,
    ).storylines()).single;
    expect(saved.type, StorylineType.sideQuest);
    expect(saved.chapters.single.title, 'Une livraison');
    expect(
      saved.chapters.single.steps.single.entryCondition,
      ScriptConditionFactory.factEquals(
        'fact_met',
        const NarrativeValue.boolean(true),
      ),
    );
    expect(
      saved.chapters.single.steps.single.journal!.text.fallback,
      'Retrouver le destinataire.',
    );
    expect(
      saved.journalClues.single.text.fallback,
      'Le guide connaît le chemin.',
    );
    expect(fresh.paths.where((path) => path.startsWith('maps/')), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test(
    'the Trame opens from the outline and saves through the story draft',
    () async {
      final (:session, :story, :trame, :reader) = await _openTrame();

      await trame.open();
      expect(trame.view!.outline.storylines, isEmpty);
      expect(reader.definitions, isEmpty);
      expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);

      expect(
        await trame.startStoryline(StorylineType.main, 'Histoire', 'Départ'),
        isTrue,
      );
      final chapterId =
          trame.view!.outline.storylines.single.chapters.single.id;
      final storylineId = trame.view!.outline.storylines.single.id;
      expect(
        await trame.createMilestone(storylineId, chapterId, 'Ouvrir la porte'),
        isTrue,
      );
      final milestone = trame.view!.milestones.single.milestone;
      expect(
        await trame.attachScene(storylineId, chapterId, milestone.id, 'gate'),
        isTrue,
        reason: trame.refusal,
      );
      expect(story.dirty, isTrue);

      expect(await story.save(), isTrue, reason: story.error);
      expect(story.dirty, isFalse);

      final fresh = CountingReader();
      final outline = await LocalStorylineReadAdapter(
        session,
        reader: fresh,
      ).outline();
      final saved = outline.storylines.single;
      expect(saved.title, 'Histoire');
      final step = saved.chapters.single.milestones.single;
      expect(step.title, 'Ouvrir la porte');
      expect(step.sceneIds, ['gate']);
      expect(step.completionFactId, milestone.completionFactId);
      expect(
        step.issues,
        isNot(contains(StorylineMilestoneIssue.noCompletionFact)),
      );
      expect(
        outline.scenesOutsideStorylines.map((scene) => scene.id),
        isNot(contains('gate')),
      );
      expect(fresh.paths.where((path) => path.startsWith('maps/')), isEmpty);
      expect(fresh.definitions.toSet(), {
        storylineId,
        milestone.completionFactId,
      });
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  for (final (title, factId) in const [
    ('Jalon A', 'fact_jalon_a'),
    ('Départ', 'fact_d_part'),
    ('Met', 'fact_met_2'),
  ]) {
    test(
      'a milestone renamed "$title" before its first save is saved as $factId',
      () async {
        final (:session, :story, :trame, reader: _) = await _openTrame();
        await trame.open();
        expect(
          await trame.startStoryline(StorylineType.main, 'Histoire', 'Début'),
          isTrue,
        );
        final storylineId = trame.view!.outline.storylines.single.id;
        final chapterId =
            trame.view!.outline.storylines.single.chapters.single.id;
        expect(
          await trame.createMilestone(storylineId, chapterId, 'Nouveau jalon'),
          isTrue,
        );
        final created = trame.view!.milestones.single.milestone;
        expect(created.completionFactId, 'fact_nouveau_jalon');
        expect(
          await trame.renameMilestone(
            storylineId,
            chapterId,
            created.id,
            title,
            completionFactId: created.completionFactId,
          ),
          isTrue,
          reason: trame.refusal,
        );
        expect(
          trame.view!.milestones.single.milestone.completionFactId,
          factId,
        );

        expect(await story.save(), isTrue, reason: story.error);
        expect(story.dirty, isFalse);

        final outline = await LocalStorylineReadAdapter(
          session,
          reader: CountingReader(),
        ).outline();
        final step =
            outline.storylines.single.chapters.single.milestones.single;
        expect((step.title, step.completionFactId), (title, factId));
        expect(
          step.issues,
          isNot(contains(StorylineMilestoneIssue.noCompletionFact)),
        );
        final index = LocalNarrativeIndexAdapter(session);
        final facts = await index.facts([factId]);
        expect((facts.single.id, facts.single.label), (factId, title));
        final titles = await index.titles(NarrativeTitleKind.facts);
        expect(
          titles.map((title) => title.id),
          isNot(contains('fact_nouveau_jalon')),
        );
        expect(
          titles.singleWhere((title) => title.id == 'fact_met').title,
          'Rencontre',
        );
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }
}
