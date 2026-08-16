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

  test('awaits a Presentation cinematic before continuing the Scene', () async {
    final project = ProjectManifest(
      name: 'Presentation preSession',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      presentationCinematics: <PresentationCinematicAsset>[
        PresentationCinematicAsset(
          id: 'opening',
          title: 'Opening',
          durationUs: 1000000,
        ),
      ],
      scenes: <SceneAsset>[_presentationScene()],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'start_map',
        preSessionSceneId: 'scene_intro',
      ),
    );
    final player = _CompletingPresentationPlayer();
    final adapter = ScenePresentationCinematicRuntimeAwaitableAdapter(
      runtimeSourceId: 'installed-game',
      projectRevision:
          'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      assets: project.presentationCinematics,
      player: player,
      createdAtEpochMs: () => 42,
    );
    final interactions = HeadlessSceneInteractionPort();
    addTearDown(interactions.close);

    final result = await RuntimeTextPreSessionSceneRunner(
      project: project,
      projectRootDirectory: Directory.systemTemp.path,
      sceneId: 'scene_intro',
      presentationCinematic: adapter,
    ).run(
      runId: 'run-1',
      draft: NewGameDraft.start(
        draftId: 'draft-1',
        projectRevision: adapter.projectRevision,
        slotId: 'slot_1',
        config: project.newGame,
      ),
      interactions: interactions,
    );

    expect(result.draftId, 'draft-1');
    expect(player.requests.single.presentationCinematicId, 'opening');
  });

  test('applies structured interaction bindings to the New Game draft',
      () async {
    final project = ProjectManifest(
      name: 'Structured preSession',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      scenes: <SceneAsset>[_structuredInteractionScene()],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'start_map',
        preSessionSceneId: 'scene_intro',
        playerAvatarCharacterIds: <String>['hero_a'],
        starterOptions: <ProjectStarterOption>[
          ProjectStarterOption(
            id: 'starter_leaf',
            label: 'Leaf',
            pokemon: PlayerPokemon(
              speciesId: 'leafmon',
              natureId: 'hardy',
              abilityId: 'overgrow',
              currentHp: 20,
            ),
          ),
        ],
      ),
    );
    final interactions = HeadlessSceneInteractionPort();
    addTearDown(interactions.close);
    final subscription = interactions.requests.listen((request) {
      final result = switch (request.kind) {
        SceneInteractionRequestKind.text =>
          SceneInteractionResult.textSubmitted(
            requestId: request.requestId,
            revision: request.revision,
            value: 'Yoahn',
          ),
        SceneInteractionRequestKind.choice =>
          SceneInteractionResult.choiceSelected(
            requestId: request.requestId,
            revision: request.revision,
            selectedOptionId: 'hero_a',
          ),
        SceneInteractionRequestKind.selection =>
          SceneInteractionResult.selectionSubmitted(
            requestId: request.requestId,
            revision: request.revision,
            selectedOptionIds: const <String>['starter_leaf'],
          ),
        _ => throw StateError('Unexpected request ${request.kind.name}.'),
      };
      interactions.resolve(result);
    });
    addTearDown(subscription.cancel);

    final result = await RuntimeTextPreSessionSceneRunner(
      project: project,
      projectRootDirectory: Directory.systemTemp.path,
      sceneId: 'scene_intro',
    ).run(
      runId: 'run-structured',
      draft: NewGameDraft.start(
        draftId: 'draft-structured',
        projectRevision: 'sha256:test',
        slotId: 'slot_1',
        config: project.newGame,
      ),
      interactions: interactions,
    );

    expect(result.playerName, 'Yoahn');
    expect(result.avatarCharacterId, 'hero_a');
    expect(result.starterOptionId, 'starter_leaf');
    expect(result.revision, 3);
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

SceneAsset _presentationScene() => SceneAsset(
      id: 'scene_intro',
      name: 'Intro',
      executionProfile: SceneExecutionProfile.preSession,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'presentation',
            kind: SceneNodeKind.presentationCinematic,
            payload: ScenePresentationCinematicPayload(
              presentationCinematicId: 'opening',
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_presentation',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'presentation',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'presentation_end',
            fromNodeId: 'presentation',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.presentationCompleted,
          ),
        ],
      ),
    );

SceneAsset _structuredInteractionScene() => SceneAsset(
      id: 'scene_intro',
      name: 'Structured intro',
      executionProfile: SceneExecutionProfile.preSession,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'name',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.preSessionInteraction(
              ScenePreSessionInteractionSpec.text(
                prompt: SceneInteractionPrompt(
                  localizationKey: 'new_game.name',
                  fallbackText: 'Votre nom ?',
                ),
                resultBinding: ScenePreSessionResultBinding(
                  field: ScenePreSessionDraftField.playerName,
                ),
              ),
            ),
          ),
          SceneNode(
            id: 'avatar',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.preSessionInteraction(
              ScenePreSessionInteractionSpec.choice(
                prompt: SceneInteractionPrompt(
                  localizationKey: 'new_game.avatar',
                  fallbackText: 'Votre avatar ?',
                ),
                options: <SceneInteractionOption>[
                  SceneInteractionOption(
                    id: 'hero_a',
                    label: SceneInteractionPrompt(
                      localizationKey: 'new_game.avatar.hero_a',
                      fallbackText: 'Hero A',
                    ),
                  ),
                ],
                resultBinding: ScenePreSessionResultBinding(
                  field: ScenePreSessionDraftField.avatarCharacterId,
                ),
              ),
            ),
          ),
          SceneNode(
            id: 'starter',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.preSessionInteraction(
              ScenePreSessionInteractionSpec.selection(
                prompt: SceneInteractionPrompt(
                  localizationKey: 'new_game.starter',
                  fallbackText: 'Votre starter ?',
                ),
                options: <SceneInteractionOption>[
                  SceneInteractionOption(
                    id: 'starter_leaf',
                    label: SceneInteractionPrompt(
                      localizationKey: 'new_game.starter.leaf',
                      fallbackText: 'Leaf',
                    ),
                  ),
                ],
                resultBinding: ScenePreSessionResultBinding(
                  field: ScenePreSessionDraftField.starterOptionId,
                ),
              ),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_name',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'name',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'name_avatar',
            fromNodeId: 'name',
            fromPortId: 'completed',
            toNodeId: 'avatar',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'avatar_starter',
            fromNodeId: 'avatar',
            fromPortId: 'completed',
            toNodeId: 'starter',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'starter_end',
            fromNodeId: 'starter',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );

final class _CompletingPresentationPlayer
    implements ScenePresentationCinematicRuntimePlayer {
  final requests = <ScenePresentationCinematicRuntimeRequest>[];

  @override
  Future<RuntimePresentationExecutionTerminal> playPresentationCinematic(
    ScenePresentationCinematicRuntimeRequest request,
  ) async {
    requests.add(request);
    return const RuntimePresentationExecutionTerminal(
      runToken: RuntimePresentationRunToken(1),
      result: RuntimePresentationExecutionResult.completed,
    );
  }
}
