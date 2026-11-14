import 'package:avelune_studio/features/game_memory/data/local_narrative_index_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_gateway.dart';
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
import '../pokemon/pokemon_scoped_save_counting_reader.dart';

void main() {
  test(
    'the Trame opens from the outline and saves through the story draft',
    () async {
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
        index: LocalNarrativeIndexAdapter(session),
        staging: MapBuilderStoryMemory(story, editable: () => true),
        source: () => MapBuilderStoryBehaviourSource(story),
        changed: () {},
      );

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
}
