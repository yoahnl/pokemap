import 'dart:io';

import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/stories/application/story_document_commands.dart';
import 'package:avelune_studio/features/stories/application/story_progression_sources.dart';
import 'package:avelune_studio/features/stories/application/story_workspace_controller.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/ui06_scene_fixture.dart';
import '../support/ui07_story_fixture.dart';
import '../support/ui09_runtime_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('story scene navigation preserves exact owners and unrelated drafts through independent publication', () async {
    final source = await Ui07StoryFixture.create();
    addTearDown(source.dispose);
    final maps = MapWorkspaceController(source.session, source.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final scenes = SceneWorkspaceController(
      maps,
      LocalSceneAdapter(session: source.session, mapAdapter: source.maps),
      narrative: narrative,
      changed: () {},
    );
    addTearDown(scenes.dispose);
    final stories = StoryWorkspaceController(
      narrative,
      source.port,
      changed: () {},
      sceneDrafts: () => scenes.scenes,
    );
    addTearDown(stories.dispose);
    final navigation = WorkspaceNavigationSession(
      controller: maps,
      isActive: () => true,
      changed: () {},
      stories: () => stories,
      scenes: () => scenes,
    );
    expect(
      navigation.openProgressionStep(
        Ui07StoryFixture.mainId,
        Ui07StoryFixture.talkId,
      ),
      isTrue,
    );
    final selectedNode = navigation.progressionNodes[Ui07StoryFixture.mainId]!;
    final original = stories.active!;
    final map = maps.active!;
    map.commit(map.current.copyWith(name: 'Carte gardée en mémoire'));
    final mapDraft = map.current;
    final mapFile = File(
      '${source.directory.path}/${maps.project!.maps.first.relativePath}',
    );
    final mapBytes = await mapFile.readAsBytes();
    final relation = buildStorylineProgressionProjection(
      project: stories.project,
      storylineId: original.id,
    ).edgesOfKind(StorylineProgressionEdgeKind.requires).single;
    expect(stories.disconnect(relation.id), isTrue);
    expect(stories.narrative.pendingStories.keys, [Ui07StoryFixture.sideId]);
    expect(stories.active, same(original));
    stories.restore(redo: false);
    expect(stories.dirty, isFalse);
    StoryDocumentCommands(stories).metadata(
      original.id,
      Ui07StoryFixture.arrivalId,
      Ui07StoryFixture.talkId,
      'title',
      'Parler au chef de gare — avant le départ',
    );
    expect(await navigation.openScene(Ui06SceneFixture.sceneId), isNull);
    expect(navigation.sceneOrigin.space, WorkspaceSpace.progression);
    final scene = scenes.active!;
    expect(scene.rename('Accueillir le voyageur avant le départ'), isTrue);
    expect(await scenes.save(), isTrue, reason: scenes.error);
    final savedScene = scene.current;
    expect(stories.dirty, isTrue);
    final otherScene = scenes.create('Autre scène conservée')!;
    final otherSceneDraft = otherScene.current;
    scenes.open(savedScene.id);
    expect(scene.move('start', 45, 30), isTrue);
    final sceneDraft = scene.current;
    navigation.show(navigation.sceneOrigin.space);
    expect(navigation.space, WorkspaceSpace.progression);
    expect(navigation.progressionNodes[original.id], same(selectedNode));
    expect(stories.activeId, original.id);
    final sources = StoryProgressionSources(
      stories.project,
      original.id,
      revealedFacts: const [Ui07StoryFixture.factId],
    );
    expect(
      stories.connect(
        StoryDocumentCommands.connectionRequest(
          source: sources.nodes['fact:${Ui07StoryFixture.factId}']!,
          target: sources.nodes['step:${Ui07StoryFixture.waitId}']!,
          choice: 2,
          relationshipId: () => throw StateError('Unexpected relationship'),
        ),
      ),
      isTrue,
    );
    expect(await stories.save(), isTrue, reason: stories.error);
    expect(scene.current, same(sceneDraft));
    expect(scene.dirty, isTrue);
    expect(otherScene.current, same(otherSceneDraft));
    expect(otherScene.dirty, isTrue);
    expect(map.current, same(mapDraft));
    expect(map.dirty, isTrue);
    final reopened = await source.readFresh();
    expect(
      reopened.storylines.singleWhere((story) => story.id == original.id),
      stories.active,
    );
    expect(
      reopened.scenes.singleWhere((value) => value.id == savedScene.id),
      savedScene,
    );
    expect(
      reopened.scenes.any((value) => value.id == otherSceneDraft.id),
      isFalse,
    );
    expect(await mapFile.readAsBytes(), mapBytes);
  });

  test('nested story scene dialogue navigation returns to the exact step without publication', () async {
    final source = await createUi09RuntimeFixture();
    addTearDown(source.dispose);
    final projectFile = File('${source.directory.path}/project.json');
    final before = await projectFile.readAsBytes();
    final maps = MapWorkspaceController(source.session, source.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final scenes = SceneWorkspaceController(
      maps,
      LocalSceneAdapter(session: source.session, mapAdapter: source.maps),
      narrative: narrative,
      changed: () {},
    );
    addTearDown(scenes.dispose);
    final stories = StoryWorkspaceController(
      narrative,
      LocalStoryAdapter(session: source.session, mapAdapter: source.maps),
      changed: () {},
    );
    addTearDown(stories.dispose);
    final dialogues = DialogueWorkspaceController(
      narrative,
      LocalDialogueAdapter(session: source.session, mapAdapter: source.maps),
      changed: () {},
      sceneDrafts: () => scenes.scenes,
    );
    addTearDown(dialogues.dispose);
    final story = stories.create('Préparer le départ')!;
    final commands = StoryDocumentCommands(stories);
    commands.addChapter(story.id, 'La gare');
    final chapter = stories.active!.chapters.single;
    commands.addStep(story.id, chapter.id, 'Parler au chef de gare');
    final step = stories.active!.chapters.single.steps.single;
    commands.associateScene(
      storyId: story.id,
      chapterId: chapter.id,
      stepId: step.id,
      sceneId: Ui06SceneFixture.sceneId,
      linked: true,
    );
    final navigation = WorkspaceNavigationSession(
      controller: maps,
      isActive: () => true,
      changed: () {},
      stories: () => stories,
      scenes: () => scenes,
      dialogues: () => dialogues,
    );
    expect(navigation.openProgressionStep(story.id, step.id), isTrue);
    final selected = navigation.progressionNodes[story.id];
    expect(
      await navigation.openScene(
        Ui06SceneFixture.sceneId,
        nodeId: 'conversation',
      ),
      isNull,
    );
    final scene = scenes.active!;
    scene.rename('Brouillon scène conservé');
    final sceneDraft = scene.current;
    expect(
      await navigation.openDialogue(
        ui09DialogueId,
        WorkspaceSpace.scene,
        startNode: 'Accueil',
      ),
      isNull,
    );
    expect(dialogues.activeId, ui09DialogueId);
    expect(dialogues.active!.startNode, 'Accueil');
    navigation.returnFromDialogue();
    expect(navigation.space, WorkspaceSpace.scene);
    expect(scene.current, same(sceneDraft));
    expect(scene.dirty, isTrue);
    navigation.show(navigation.sceneOrigin.space);
    expect(navigation.space, WorkspaceSpace.progression);
    expect(stories.activeId, story.id);
    expect(navigation.progressionNodes[story.id], same(selected));
    expect(selected!.stepId, step.id);
    expect(stories.dirty, isTrue);
    expect(await projectFile.readAsBytes(), before);
  });
}
