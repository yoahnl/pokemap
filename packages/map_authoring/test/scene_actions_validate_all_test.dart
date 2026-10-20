import 'dart:async';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('validateInOrder is lazy and preserves the exact refusal at its scene', () {
    final first = _scene('first', 'known');
    final invalid = _scene('invalid', 'unknown');
    final project = _project([first, invalid]);
    var builds = 0;
    final scenes = const SceneActions().validateInOrder(project,
        maps: const [], onContextBuilt: (_) => builds++);
    expect(builds, 0);
    final iterator = scenes.iterator;
    expect(builds, 0);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.current, same(first));
    expect(builds, 1);
    final expected = _failure(() => const SceneActions()
        .upsert(project, maps: const [], scene: invalid));
    final actual = _failure(() => iterator.moveNext());
    expect(actual.code, expected.code);
    expect(actual.message, expected.message);
    expect(actual.details, expected.details);
    expect(builds, 1);
  });

  test('a cooperative consumer cancels after 32 scenes before the next validation', () async {
    final project = _project([
      ...List.generate(32, (index) => _scene('scene_$index', 'known')),
      _scene('never_validated', 'unknown'),
    ]);
    var builds = 0;
    var completed = 0;
    var cancelled = false;
    for (final scene in const SceneActions().validateInOrder(project,
        maps: const [], onContextBuilt: (_) => builds++)) {
      expect(scene.id, 'scene_$completed');
      completed++;
      if (completed == 32) Timer.run(() => cancelled = true);
      await Future<void>.delayed(Duration.zero);
      if (cancelled) break;
    }
    expect(cancelled, isTrue);
    expect(completed, 32);
    expect(builds, 1);
  });

  test('validateAll preserves unloaded and empty item catalog semantics', () {
    final scene = SceneAsset(
      id: 'item',
      name: 'Item',
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
            id: 'give',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
                SceneConsequence.giveItem(itemId: 'potion', quantity: 1))),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(
            id: 'first',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'give',
            kind: SceneEdgeKind.defaultFlow),
        SceneEdge(
            id: 'last',
            fromNodeId: 'give',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted),
      ]),
    );
    final project = _project([scene]);
    const actions = SceneActions();
    actions.upsert(project, maps: const [], scene: scene);
    actions.validateAll(project, maps: const []);
    const empty = ProjectItemCatalog(schemaVersion: 1, entries: []);
    final expected = _failure(() => actions.upsert(project,
        maps: const [], scene: scene, itemCatalog: empty));
    final actual = _failure(
        () => actions.validateAll(project, maps: const [], itemCatalog: empty));
    expect(actual.code, expected.code);
    expect(actual.details, expected.details);
    final known = ProjectItemCatalog.fromJson({
      'schemaVersion': 1,
      'entries': [
        {'id': 'potion', 'displayName': 'Potion', 'pocketId': 'medicine'}
      ]
    });
    actions.upsert(project, maps: const [], scene: scene, itemCatalog: known);
    actions.validateAll(project, maps: const [], itemCatalog: known);
  });

  test('validateAll builds one context for an immutable complete scene set',
      () {
    final scenes =
        List.generate(24, (index) => _scene('scene_$index', 'known'));
    final project = _project(scenes);
    var builds = 0;
    const SceneActions()
        .validateAll(project, maps: const [], onContextBuilt: (_) => builds++);
    expect(builds, 1);
    expect(project.scenes, scenes);
    for (final scene in scenes) {
      expect(buildSceneRuntimePlan(scene).canBuild, isTrue);
      expect(
          const SceneActions()
              .upsert(project, maps: const [], scene: scene)
              .toJson(),
          project.toJson());
    }
  });

  test('validateAll preserves the exact single-scene refusal details', () {
    final invalid = _scene('invalid', 'unknown');
    final project = _project([_scene('valid', 'known'), invalid]);
    final expected = _failure(() =>
        const SceneActions().upsert(project, maps: const [], scene: invalid));
    var builds = 0;
    final actual = _failure(() => const SceneActions()
        .validateAll(project, maps: const [], onContextBuilt: (_) => builds++));
    expect(builds, 1);
    expect(actual.code, expected.code);
    expect(actual.message, expected.message);
    expect(actual.details, expected.details);
  });
}

NarrativeAuthoringException _failure(void Function() action) {
  try {
    action();
  } on NarrativeAuthoringException catch (error) {
    return error;
  }
  throw StateError('Expected canonical scene refusal');
}

ProjectManifest _project(List<SceneAsset> scenes) => ProjectManifest(
      name: 'Batch scene qualification',
      maps: const [],
      tilesets: const [],
      scenes: scenes,
      dialogues: const [
        ProjectDialogueEntry(
            id: 'known', name: 'Known', relativePath: 'dialogues/known.yarn')
      ],
    );

SceneAsset _scene(String id, String dialogue) => SceneAsset(
      id: id,
      name: id,
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(dialogueId: dialogue)),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(
            id: 'first',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'dialogue',
            kind: SceneEdgeKind.defaultFlow),
        SceneEdge(
            id: 'last',
            fromNodeId: 'dialogue',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow),
      ]),
    );
