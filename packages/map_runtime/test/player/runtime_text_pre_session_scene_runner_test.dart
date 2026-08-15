import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('executes a text-only preSession Scene through structured requests',
      () async {
    final directory = await Directory.systemTemp.createTemp(
      'pokemap-pre-session-runner-',
    );
    addTearDown(() => directory.delete(recursive: true));
    await File('${directory.path}/intro.yarn').writeAsString('''
title: Start
---
Bienvenue à Avelune.
===
''');
    final project = ProjectManifest(
      name: 'Text preSession',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      dialogues: const <ProjectDialogueEntry>[
        ProjectDialogueEntry(
          id: 'intro',
          name: 'Intro',
          relativePath: 'intro.yarn',
          defaultStartNode: 'Start',
        ),
      ],
      scenes: <SceneAsset>[_scene()],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'start_map',
        preSessionSceneId: 'scene_intro',
      ),
    );
    final draft = NewGameDraft.start(
      draftId: 'draft-1',
      projectRevision: 'sha256:test',
      slotId: 'slot_1',
      config: project.newGame,
    );
    final interactions = HeadlessSceneInteractionPort();
    addTearDown(interactions.close);
    final requests = <SceneInteractionRequest>[];
    final subscription = interactions.requests.listen((request) {
      requests.add(request);
      interactions.resolve(
        SceneInteractionResult.acknowledged(
          requestId: request.requestId,
          revision: request.revision,
        ),
      );
    });
    addTearDown(subscription.cancel);

    final result = await RuntimeTextPreSessionSceneRunner(
      project: project,
      projectRootDirectory: directory.path,
      sceneId: 'scene_intro',
    ).run(
      runId: 'run-1',
      draft: draft,
      interactions: interactions,
    );

    expect(result, same(draft));
    expect(requests, hasLength(1));
    expect(requests.single.kind, SceneInteractionRequestKind.message);
    expect(requests.single.prompt.fallbackText, 'Bienvenue à Avelune.');
  });
}

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Intro',
    executionProfile: SceneExecutionProfile.preSession,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(
            dialogueId: 'intro',
            yarnNodeName: 'Start',
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_dialogue',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'dialogue',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'dialogue_end',
          fromNodeId: 'dialogue',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}
