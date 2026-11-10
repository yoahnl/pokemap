import 'dart:io';

import 'package:avelune_studio/features/stories/application/story_coherence.dart';
import 'package:avelune_studio/features/stories/application/story_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/story_backend_fixture.dart';

void main() {
  test('a healthy story has no coherence entries', () {
    expect(storyCoherence(_project([_story()]), 'main'), isEmpty);
  });

  test('an unknown story keeps its diagnostic without fabricating navigation targets', () {
    final entries = storyCoherence(_project([_story()]), 'missing');
    final entry = entries.single;
    expect(
      entry.progression!.code,
      StorylineProgressionDiagnosticCode.storylineNotFound,
    );
    expect(entry.progression!.nodeId, 'storyline:missing');
    expect(entry.sceneLink, isNull);
    expect(entry.node, isNull);
    expect(entry.edge, isNull);
    expect(entry.graphTargetId, isNull);
    expect(entry.sceneTarget, isNull);
    expect(() => entries.clear(), throwsUnsupportedError);
  });

  test('a missing fact keeps its original diagnostic and exact edge and node targets', () {
    final project = _project([
      _story(condition: ScriptConditionFactory.flagIsSet('absent')),
    ]);
    final before = project.toJson();
    final entry = storyCoherence(project, 'main').single;
    expect(
      entry.progression!.code,
      StorylineProgressionDiagnosticCode.missingDestination,
    );
    expect(entry.message, 'La condition cible un Fact introuvable: absent.');
    expect(entry.sceneLink, isNull);
    expect(entry.node!.id, 'fact:absent');
    expect(entry.node!.isMissing, isTrue);
    expect(entry.edge!.id, 'condition:main:chapter:step:entry');
    expect(entry.edge!.fromNodeId, entry.node!.id);
    expect(entry.edge!.toNodeId, 'step:step');
    expect(entry.progression!.nodeId, entry.node!.id);
    expect(entry.progression!.edgeId, entry.edge!.id);
    expect(entry.graphTargetId, entry.edge!.id);
    expect(entry.sceneTarget, isNull);
    expect(project.toJson(), before);
  });

  test('scene link diagnostics stay scoped and distinguish exact scene IDs from names and missing references', () {
    final first = _scene('first');
    final second = _scene('second');
    final project = _project(
      [
        _story(sceneIds: ['first', 'missing', 'second']),
        _story(id: 'other', sceneIds: ['unrelated']),
      ],
      scenes: [first, second],
    );
    final entries = storyCoherence(project, 'main');
    expect(entries, isNotEmpty);
    expect(entries.every((entry) => entry.progression == null), isTrue);
    expect(
      entries.every((entry) => entry.sceneLink!.storylineId == 'main'),
      isTrue,
    );
    for (final id in ['first', 'second']) {
      final targets = entries.where((entry) => entry.sceneLink!.sceneId == id);
      expect(targets, isNotEmpty);
      for (final entry in targets) {
        expect(entry.sceneTarget, (id: id, name: 'Rencontre'));
        expect(entry.sceneLink!.chapterId, 'chapter');
        expect(entry.sceneLink!.stepId, 'step');
        expect(entry.node!.id, 'step:step');
        expect(entry.graphTargetId, 'step:step');
        expect(entry.edge, isNull);
      }
    }
    final missing = entries.singleWhere(
      (entry) => entry.sceneLink!.sceneId == 'missing',
    );
    expect(
      missing.sceneLink!.code,
      StorylineSceneLinkDiagnosticCode.storylineStepUnknownSceneLink,
    );
    expect(missing.sceneTarget, isNull);
    expect(missing.node!.id, 'step:step');
    expect(
      entries.any((entry) => entry.sceneLink!.sceneId == 'unrelated'),
      isFalse,
    );
    expect(project.scenes, [first, second]);
    expect(first.name, second.name);
  });

  test(
    'a structured scenario diagnostic never opens a same-ID scene implicitly',
    () {
      final scene = _scene('shared');
      final story = _story().copyWith(
        sceneLinks: [
          StorylineSceneLink(
            id: 'scenario-link',
            chapterId: 'chapter',
            stepId: 'step',
            label: 'Scénario absent',
            state: StorylineSceneLinkState.linkedScenario,
            role: StorylineSceneLinkRole.primary,
            order: 0,
            sceneRef: StorylineSceneRef(
              kind: StorylineSceneRefKind.scenario,
              targetId: scene.id,
            ),
          ),
        ],
      );
      final entries = storyCoherence(
        _project([story], scenes: [scene]),
        story.id,
      );
      final entry = entries.singleWhere(
        (entry) =>
            entry.sceneLink?.code ==
            StorylineSceneLinkDiagnosticCode
                .storylineStructuredOutcomeUnknownScenario,
      );
      expect(entry.sceneLink!.sceneId, scene.id);
      expect(entry.sceneLink!.sceneLinkId, 'scenario-link');
      expect(entry.node!.id, 'step:step');
      expect(entry.sceneTarget, isNull);
      expect(entry.progression, isNull);
    },
  );

  test('coherence reads current story and scene drafts without publishing or changing history', () async {
    final parent = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
    );
    await parent.create(recursive: true);
    final fixture = await IOOverrides.runZoned(
      () => StoryBackendFixture.create(stories: [_story()]),
      getSystemTempDirectory: () => parent,
    );
    addTearDown(fixture.dispose);
    final draftScene = _scene('draft-scene');
    final controller = StoryWorkspaceController(
      fixture.narrative,
      fixture.port,
      changed: () {},
      sceneDrafts: () => [draftScene],
    );
    addTearDown(controller.dispose);
    expect(controller.open('main'), isTrue);
    final original = controller.active!;
    final step = original.chapters.single.steps.single;
    expect(
      controller.apply(
        updateStorylineStep(
          controller.project,
          storylineId: original.id,
          chapterId: original.chapters.single.id,
          stepId: step.id,
          step: step.copyWith(
            sceneLinkIds: [draftScene.id],
            entryCondition: ScriptConditionFactory.flagIsSet('absent'),
          ),
        ),
      ),
      isTrue,
    );
    final draft = controller.active;
    final before = await File('${fixture.directory.path}/project.json')
        .readAsBytes();
    final entries = storyCoherence(controller.project, original.id);
    expect(
      entries.first.progression!.code,
      StorylineProgressionDiagnosticCode.missingDestination,
    );
    expect(entries.first.graphTargetId, 'condition:main:chapter:step:entry');
    expect(
      entries.where((entry) => entry.sceneTarget?.id == draftScene.id),
      isNotEmpty,
    );
    expect(controller.active, same(draft));
    expect(controller.dirty, isTrue);
    expect(controller.canUndo, isTrue);
    expect(controller.canRedo, isFalse);
    expect(
      await File('${fixture.directory.path}/project.json').readAsBytes(),
      before,
    );
    controller.restore(redo: false);
    expect(controller.active, original);
    expect(controller.dirty, isFalse);
    controller.restore(redo: true);
    expect(controller.active, draft);
    expect(
      await File('${fixture.directory.path}/project.json').readAsBytes(),
      before,
    );
  });
}

ProjectManifest _project(
  List<StorylineAsset> stories, {
  List<SceneAsset> scenes = const [],
}) => ProjectManifest(
  name: 'Cohérence',
  maps: const [],
  tilesets: const [],
  storylines: stories,
  scenes: scenes,
);

StorylineAsset _story({
  String id = 'main',
  List<String> sceneIds = const [],
  ScriptCondition? condition,
}) => StorylineAsset(
  id: id,
  title: 'Histoire $id',
  type: StorylineType.main,
  chapters: [
    StorylineChapter(
      id: 'chapter',
      order: 0,
      title: 'Chapitre',
      steps: [
        StorylineStep(
          id: 'step',
          title: 'Étape',
          order: 0,
          sceneLinkIds: sceneIds,
          entryCondition: condition,
        ),
      ],
    ),
  ],
);

SceneAsset _scene(String id) => SceneAsset(
  id: id,
  name: 'Rencontre',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
  ),
);
