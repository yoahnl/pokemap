import 'dart:async';

import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/scenes/domain/scene_document.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_source.dart';
import 'package:avelune_studio/features/scenes/application/scene_catalog_controller.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../storyline/storyline_fakes.dart';

import 'package:avelune_studio/features/scenes/application/scene_catalog_rows.dart';

import 'scene_catalog_support.dart';

void main() {
  test('removing the filtered story resets obsolete filters', () async {
    final h = CatalogHarness();
    addTearDown(h.controller.dispose);
    final story = mainStoryline();
    h.stories.stories = [story];
    await h.controller.open();
    h.controller.filter(
      story: 'story:${story.id}',
      chapter: sceneCatalogChapterKey(story.id, story.chapters.first.id),
    );
    h.draft.load(StoryDraftKind.story, story.id, story);
    h.draft.remove(StoryDraftKind.story, story.id);
    h.controller.sync();
    expect(
      (h.controller.storyFilter, h.controller.chapterFilter),
      ('all', 'all'),
    );
  });
  test('a partial manifest is never the source of scene existence', () async {
    final h = CatalogHarness();
    final GameBehaviourSource source = FakeBehaviourSource(
      scenes: [catalogScene('phantom')],
    );
    final controller = SceneCatalogController(
      port: h.index,
      storylines: h.stories,
      draft: h.draft,
      source: () => source,
      changed: () {},
    );
    addTearDown(controller.dispose);
    await controller.open();
    expect(controller.rows.map((row) => row.id).toSet(), {
      'scene_0',
      'scene_1',
    });
    expect(h.index.documentRequests, isEmpty);
  });

  test(
    'editing a scene while its preview loads rejects the obsolete result',
    () async {
      final h = CatalogHarness();
      addTearDown(h.controller.dispose);
      final loading = Completer<SceneDocument>();
      h.index.documentLoader = (_) => loading.future;
      await h.controller.open();
      h.controller.select('scene_0');
      final pending = h.controller.loadSelected();
      h.draft.load(
        StoryDraftKind.scene,
        'scene_0',
        h.index.documents['scene_0']!.scene,
      );
      h.draft.put(
        StoryDraftKind.scene,
        catalogScene('scene_0', 'Après modification'),
      );
      h.controller.sync();
      loading.complete(h.index.documents['scene_0']);
      await pending;
      expect(h.controller.preview.value, isNull);
      h.index.documentLoader = null;
      await h.controller.loadSelected();
      expect(h.controller.preview.value!.scene.name, 'Après modification');
    },
  );
  test('saved titles and draft deltas include creations, renames and explicit deletions', () async {
    final h = CatalogHarness();
    addTearDown(h.controller.dispose);
    await h.controller.open();
    final original = h.index.documents['scene_0']!.scene;
    h.draft.load(StoryDraftKind.scene, original.id, original);
    h.draft.put(StoryDraftKind.scene, catalogScene(original.id, 'Nouveau nom'));
    h.draft.load(StoryDraftKind.scene, 'created', null);
    h.draft.put(StoryDraftKind.scene, catalogScene('created', 'Sans porteur'));
    h.draft.load(
      StoryDraftKind.scene,
      'scene_1',
      h.index.documents['scene_1']!.scene,
    );
    h.draft.remove(StoryDraftKind.scene, 'scene_1');
    h.controller.sync();
    expect(
      h.controller.rows.singleWhere((row) => row.id == 'scene_0').title,
      'Nouveau nom',
    );
    expect(
      h.controller.rows.singleWhere((row) => row.id == 'created').openable,
      isTrue,
    );
    final deleted = h.controller.rows.singleWhere((row) => row.id == 'scene_1');
    expect((deleted.deleted, deleted.openable), (true, false));
    h.draft.undo();
    h.controller.sync();
    expect(
      h.controller.rows.singleWhere((row) => row.id == 'scene_1').deleted,
      isFalse,
    );
    expect(h.index.documentRequests, isEmpty);
  });

  test('a removed selection and a filtered selection cannot keep a stale inspector', () async {
    final h = CatalogHarness();
    addTearDown(h.controller.dispose);
    await h.controller.open();
    h.controller.select('scene_0');
    h.controller.filter(query: 'Scène 1');
    expect(h.controller.selectedId, isNull);
    h.controller.filter(query: '');
    h.controller.select('scene_0');
    h.index.titlesByKind[NarrativeTitleKind.scenes] = const [];
    await h.controller.open(force: true);
    expect(h.controller.selectedId, isNull);
    expect(h.controller.preview.value, isNull);
  });

  test('a slow older document cannot replace the newer selection', () async {
    final h = CatalogHarness();
    addTearDown(h.controller.dispose);
    final first = Completer<SceneDocument>();
    final second = Completer<SceneDocument>();
    h.index.documentLoader = (id) =>
        id == 'scene_0' ? first.future : second.future;
    await h.controller.open();
    h.controller.select('scene_0');
    final a = h.controller.loadSelected();
    h.controller.select('scene_1');
    final b = h.controller.loadSelected();
    first.complete(h.index.documents['scene_0']);
    await a;
    expect(h.controller.preview.value, isNull);
    second.complete(h.index.documents['scene_1']);
    await b;
    expect(h.controller.preview.value!.scene.id, 'scene_1');
  });

  test('failed metadata can be retried without loading any scene', () async {
    final h = CatalogHarness();
    addTearDown(h.controller.dispose);
    h.index.titleFailure = StateError('temporary');
    await h.controller.open();
    expect(h.controller.titles.problem, isNotNull);
    h.index.titleFailure = null;
    await h.controller.open(force: true);
    expect(h.controller.titles.ready, isTrue);
    expect(h.controller.rows, hasLength(2));
    expect(h.index.documentRequests, isEmpty);
  });
}
