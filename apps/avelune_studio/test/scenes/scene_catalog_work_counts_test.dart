import 'package:avelune_studio/features/game_memory/data/local_narrative_index_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_catalog_controller.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/features/storyline/data/local_storyline_read_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../pokemon/pokemon_scoped_save_counting_reader.dart';
import 'scene_catalog_support.dart';
import 'scene_focus_catalog_fixture.dart';

void main() {
  test(
    'a saved revision invalidates only the document requested again',
    () async {
      final h = CatalogHarness();
      addTearDown(h.controller.dispose);
      await h.controller.open();
      await h.controller.readDocument('scene_0');
      await h.controller.readDocument('scene_1');
      h.draft.load(
        StoryDraftKind.scene,
        'scene_0',
        h.index.documents['scene_0']!.scene,
      );
      h.source.revision = Object();
      h.index.documents['scene_0'] = catalogDocument(
        catalogScene('scene_0', 'Nouvelle version enregistrée'),
      );
      expect(
        (await h.controller.readDocument('scene_0')).scene.name,
        'Nouvelle version enregistrée',
      );
      expect(h.index.documentRequests, ['scene_0', 'scene_1', 'scene_0']);
    },
  );
  test(
    '443 titles load no scene and only the requested preview is read',
    () async {
      final h = CatalogHarness(count: 443);
      addTearDown(h.controller.dispose);
      await h.controller.open();
      expect(h.controller.rows, hasLength(443));
      expect(h.index.documentRequests, isEmpty);
      expect(h.stories.storylineReads, 1);
      h.controller.select('scene_0');
      await h.controller.loadSelected();
      await h.controller.readDocument('scene_0');
      expect(h.index.documentRequests, ['scene_0']);
      expect(h.index.directoryRequests, isEmpty);
    },
  );

  test('renaming one scene invalidates only its preview and leaves the other cache intact', () async {
    final h = CatalogHarness(count: 443);
    addTearDown(h.controller.dispose);
    await h.controller.open();
    await h.controller.readDocument('scene_0');
    await h.controller.readDocument('scene_1');
    final scene = h.index.documents['scene_0']!.scene;
    h.draft.load(StoryDraftKind.scene, scene.id, scene);
    h.draft.put(StoryDraftKind.scene, catalogScene(scene.id, 'Renommée'));
    h.controller.sync();
    expect((await h.controller.readDocument(scene.id)).scene.name, 'Renommée');
    await h.controller.readDocument('scene_1');
    expect(h.index.documentRequests, ['scene_0', 'scene_1', 'scene_0']);
    expect(h.index.titleRequests, hasLength(1));
    expect(h.stories.storylineReads, 1);
  });

  test('the real catalogue list reads metadata only and a selected orphan reads one definition', () async {
    final session = await openSceneFocusCatalog(unrelated: 30);
    final reader = CountingReader();
    final controller = SceneCatalogController(
      port: LocalNarrativeIndexAdapter(session, reader: reader),
      storylines: LocalStorylineReadAdapter(session, reader: reader),
      draft: StoryDraft(),
      source: () => FakeBehaviourSource(),
      changed: () {},
    );
    addTearDown(controller.dispose);
    await controller.open();
    expect(controller.rows, hasLength(31));
    expect(reader.definitions, isEmpty);
    expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
    reader.clear();
    controller.select('unused_scene_3');
    await controller.loadSelected();
    expect(controller.preview.value!.scene.id, 'unused_scene_3');
    expect(reader.definitions, ['unused_scene_3']);
    expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
    expect(
      reader.unitKeys.where((key) => key.contains('unused_scene_4')),
      isEmpty,
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
