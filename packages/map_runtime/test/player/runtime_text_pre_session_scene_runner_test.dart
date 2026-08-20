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

  test('routes a declined confirmation through its typed output', () async {
    final project = ProjectManifest(
      name: 'Confirmation preSession',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      scenes: <SceneAsset>[_confirmationScene()],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'start_map',
        preSessionSceneId: 'scene_intro',
      ),
    );
    final interactions = HeadlessSceneInteractionPort();
    addTearDown(interactions.close);
    final requests = <SceneInteractionRequest>[];
    final subscription = interactions.requests.listen((request) {
      requests.add(request);
      interactions.resolve(
        SceneInteractionResult.confirmed(
          requestId: request.requestId,
          revision: request.revision,
          value: false,
        ),
      );
    });
    addTearDown(subscription.cancel);

    await RuntimeTextPreSessionSceneRunner(
      project: project,
      projectRootDirectory: Directory.systemTemp.path,
      sceneId: 'scene_intro',
    ).run(
      runId: 'run-confirmation',
      draft: NewGameDraft.start(
        draftId: 'draft-confirmation',
        projectRevision: 'sha256:test',
        slotId: 'slot_1',
        config: project.newGame,
      ),
      interactions: interactions,
    );

    expect(requests, hasLength(1));
    expect(requests.single.kind, SceneInteractionRequestKind.confirmation);
  });

  test('resolves a linked interaction during Presentation exactly once',
      () async {
    final project = ProjectManifest(
      name: 'Presentation interaction',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      presentationCinematics: <PresentationCinematicAsset>[
        PresentationCinematicAsset(
          id: 'opening',
          title: 'Opening',
          durationUs: 1000000,
          tracks: [
            PresentationTrack(
              id: 'markers',
              label: 'Repères',
              kind: PresentationTrackKind.marker,
              clips: [
                PresentationMarkerClip(
                  id: 'ask_avatar',
                  startUs: 500000,
                  label: 'Choisir l’avatar',
                  markerKind: PresentationMarkerKind.interactionCue,
                ),
              ],
            ),
          ],
        ),
      ],
      scenes: <SceneAsset>[_presentationInteractionScene()],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'start_map',
        preSessionSceneId: 'scene_intro',
        playerAvatarCharacterIds: <String>['hero_a'],
      ),
    );
    final player = _CompletingPresentationPlayer(
      triggerMarkerId: 'ask_avatar',
    );
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
    var requestCount = 0;
    final subscription = interactions.requests.listen((request) {
      requestCount++;
      interactions.resolve(
        SceneInteractionResult.choiceSelected(
          requestId: request.requestId,
          revision: request.revision,
          selectedOptionId: 'hero_a',
        ),
      );
    });
    addTearDown(subscription.cancel);

    final result = await RuntimeTextPreSessionSceneRunner(
      project: project,
      projectRootDirectory: Directory.systemTemp.path,
      sceneId: 'scene_intro',
      presentationCinematic: adapter,
    ).run(
      runId: 'run-cue',
      draft: NewGameDraft.start(
        draftId: 'draft-cue',
        projectRevision: adapter.projectRevision,
        slotId: 'slot_1',
        config: project.newGame,
      ),
      interactions: interactions,
    );

    expect(result.avatarCharacterId, 'hero_a');
    expect(requestCount, 1);
    expect(player.requests.single.interactionCueMarkerIds, {'ask_avatar'});
  });
  test('interpolates the draft into texts after each validated response',
      () async {
    final directory = await Directory.systemTemp.createTemp(
      'pokemap-pre-session-interpolation-',
    );
    addTearDown(() => directory.delete(recursive: true));
    await File('${directory.path}/intro.yarn').writeAsString('''
title: Before
---
Bonjour {{draft.playerName}}, ton avatar {{draft.avatarName}} t'attend !
===
title: After
---
Enchanté {{draft.playerName}} !
===
''');
    final project = ProjectManifest(
      name: 'Interpolated preSession',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      dialogues: const <ProjectDialogueEntry>[
        ProjectDialogueEntry(
          id: 'intro',
          name: 'Intro',
          relativePath: 'intro.yarn',
          defaultStartNode: 'Before',
        ),
      ],
      scenes: <SceneAsset>[_interpolationScene()],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'start_map',
        preSessionSceneId: 'scene_intro',
      ),
    );
    final interactions = HeadlessSceneInteractionPort();
    addTearDown(interactions.close);
    final requests = <SceneInteractionRequest>[];
    final subscription = interactions.requests.listen((request) {
      requests.add(request);
      interactions.resolve(
        request.kind == SceneInteractionRequestKind.text
            ? SceneInteractionResult.textSubmitted(
                requestId: request.requestId,
                revision: request.revision,
                value: 'Yoahn 🐉',
              )
            : SceneInteractionResult.acknowledged(
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
      runId: 'run-interpolation',
      draft: NewGameDraft.start(
        draftId: 'draft-interpolation',
        projectRevision: 'sha256:test',
        slotId: 'slot_1',
        config: project.newGame,
      ),
      interactions: interactions,
    );

    expect(result.playerName, 'Yoahn 🐉');
    expect(requests, hasLength(3));
    expect(
      requests[0].prompt.fallbackText,
      "Bonjour Player, ton avatar {{draft.avatarName}} t'attend !",
      reason: 'the line renders the CURRENT draft: the config-provided '
          'default name resolves, and the unanswered avatar keeps its '
          'placeholder visible instead of going silently blank',
    );
    expect(requests[0].revision, 0);
    expect(requests[1].kind, SceneInteractionRequestKind.text);
    expect(requests[1].revision, 0);
    expect(
      requests[2].prompt.fallbackText,
      'Enchanté Yoahn 🐉 !',
      reason: 'texts re-evaluate the draft AFTER the validated response',
    );
    expect(
      requests[2].revision,
      1,
      reason: 'the request carries the draft revision so stale renderings '
          'are identifiable',
    );
  });

  test('a Presentation cue runs a Yarn dialogue during the hold, once',
      () async {
    final directory = await Directory.systemTemp.createTemp(
      'pokemap-pre-session-yarn-cue-',
    );
    addTearDown(() => directory.delete(recursive: true));
    await File('${directory.path}/cue_talk.yarn').writeAsString('''
title: CueTalk
---
Le professeur entre en scène.
Il ajuste ses lunettes.
===
''');
    final project = ProjectManifest(
      name: 'Yarn cue preSession',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      dialogues: const <ProjectDialogueEntry>[
        ProjectDialogueEntry(
          id: 'cue_talk',
          name: 'Cue talk',
          relativePath: 'cue_talk.yarn',
          defaultStartNode: 'CueTalk',
        ),
      ],
      presentationCinematics: <PresentationCinematicAsset>[
        PresentationCinematicAsset(
          id: 'opening',
          title: 'Opening',
          durationUs: 1000000,
        ),
      ],
      scenes: <SceneAsset>[_yarnCueScene()],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'start_map',
        preSessionSceneId: 'scene_intro',
      ),
    );
    final player = _CompletingPresentationPlayer(triggerMarkerId: 'cue_talk');
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

    await RuntimeTextPreSessionSceneRunner(
      project: project,
      projectRootDirectory: directory.path,
      sceneId: 'scene_intro',
      presentationCinematic: adapter,
    ).run(
      runId: 'run-yarn-cue',
      draft: NewGameDraft.start(
        draftId: 'draft-yarn-cue',
        projectRevision: adapter.projectRevision,
        slotId: 'slot_1',
        config: project.newGame,
      ),
      interactions: interactions,
    );

    expect(
      requests.map((request) => request.prompt.fallbackText),
      [
        'Le professeur entre en scène.',
        'Il ajuste ses lunettes.',
      ],
      reason: 'the Yarn pages ran DURING the cue hold through the existing '
          'dialogue runner, and the graph node afterwards replayed nothing — '
          'exactly once, no parallel interpreter',
    );
  });

  test('Non routes back to the name entry, Oui hands off to the graph',
      () async {
    final project = ProjectManifest(
      name: 'Confirmation branch preSession',
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
      scenes: <SceneAsset>[_confirmationBranchScene()],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'start_map',
        preSessionSceneId: 'scene_intro',
      ),
    );
    final player = _RoutingPresentationPlayer(
      orderedMarkerIds: const ['cue_name', 'cue_confirm'],
    );
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
    final names = ['Yoahn', 'Yoahn Le Vrai'];
    final confirmations = [false, true];
    var nameIndex = 0;
    var confirmationIndex = 0;
    final requests = <SceneInteractionRequest>[];
    final subscription = interactions.requests.listen((request) {
      requests.add(request);
      interactions.resolve(switch (request.kind) {
        SceneInteractionRequestKind.text => SceneInteractionResult.textSubmitted(
            requestId: request.requestId,
            revision: request.revision,
            value: names[nameIndex++],
          ),
        SceneInteractionRequestKind.confirmation =>
          SceneInteractionResult.confirmed(
            requestId: request.requestId,
            revision: request.revision,
            value: confirmations[confirmationIndex++],
          ),
        _ => throw StateError('Unexpected request ${request.kind.name}.'),
      });
    });
    addTearDown(subscription.cancel);

    final result = await RuntimeTextPreSessionSceneRunner(
      project: project,
      projectRootDirectory: Directory.systemTemp.path,
      sceneId: 'scene_intro',
      presentationCinematic: adapter,
    ).run(
      runId: 'run-branch',
      draft: NewGameDraft.start(
        draftId: 'draft-branch',
        projectRevision: adapter.projectRevision,
        slotId: 'slot_1',
        config: project.newGame,
      ),
      interactions: interactions,
    );

    expect(
      result.playerName,
      'Yoahn Le Vrai',
      reason: 'Non replayed the name entry: the second validated answer is '
          'the one that survives — no partial draft mutation',
    );
    expect(
      requests.map((request) => request.kind.name),
      ['text', 'confirmation', 'text', 'confirmation'],
      reason: 'Non → back to the entry → new name → Oui, deterministically',
    );
    expect(
      requests.map((request) => request.revision),
      [0, 1, 1, 2],
      reason: 'every request carries the draft revision current at its '
          'evaluation',
    );
  });

  test('an authored infinite loop fails closed without partial draft writes',
      () async {
    final project = ProjectManifest(
      name: 'Loop preSession',
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
      scenes: <SceneAsset>[_loopingScene()],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'start_map',
        preSessionSceneId: 'scene_intro',
      ),
    );
    final adapter = ScenePresentationCinematicRuntimeAwaitableAdapter(
      runtimeSourceId: 'installed-game',
      projectRevision:
          'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      assets: project.presentationCinematics,
      player: _RoutingPresentationPlayer(orderedMarkerIds: const ['cue_name']),
      createdAtEpochMs: () => 42,
    );
    final interactions = HeadlessSceneInteractionPort();
    addTearDown(interactions.close);
    var serial = 0;
    final subscription = interactions.requests.listen((request) {
      serial += 1;
      interactions.resolve(
        SceneInteractionResult.textSubmitted(
          requestId: request.requestId,
          revision: request.revision,
          value: 'Essai $serial',
        ),
      );
    });
    addTearDown(subscription.cancel);

    await expectLater(
      RuntimeTextPreSessionSceneRunner(
        project: project,
        projectRootDirectory: Directory.systemTemp.path,
        sceneId: 'scene_intro',
        presentationCinematic: adapter,
      ).run(
        runId: 'run-loop',
        draft: NewGameDraft.start(
          draftId: 'draft-loop',
          projectRevision: adapter.projectRevision,
          slotId: 'slot_1',
          config: project.newGame,
        ),
        interactions: interactions,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains(PresentationCueOutcomeCodes.transitionBudgetExhausted),
        ),
      ),
    );
    expect(
      serial,
      defaultPresentationTransitionBudgetPerExecution + 1,
      reason: 'each loop turn completed one whole validated answer before '
          'the budget cut it — the failure never interrupts a half-applied '
          'draft command',
    );
  });

}

SceneAsset _loopingScene() => SceneAsset(
      id: 'scene_intro',
      name: 'Looping intro',
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
              interactionCueBindings: [
                ScenePresentationInteractionCueBinding(
                  markerId: 'cue_name',
                  awaitableNodeId: 'ask_name',
                  outcomeRoutes: [
                    ScenePresentationCueOutcomeRoute(
                      outputPortId: 'completed',
                      outcome: PresentationInteractionOutcome.repeatFromMarker(
                        markerId: 'cue_name',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SceneNode(
            id: 'ask_name',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.preSessionInteraction(
              ScenePreSessionInteractionSpec.text(
                prompt: SceneInteractionPrompt(
                  localizationKey: 'new_game.name',
                  fallbackText: 'Votre nom ?',
                ),
                resultBinding: const ScenePreSessionResultBinding(
                  field: ScenePreSessionDraftField.playerName,
                ),
              ),
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

SceneAsset _confirmationBranchScene() => SceneAsset(
      id: 'scene_intro',
      name: 'Confirmation branch intro',
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
              interactionCueBindings: [
                ScenePresentationInteractionCueBinding(
                  markerId: 'cue_name',
                  awaitableNodeId: 'ask_name',
                ),
                ScenePresentationInteractionCueBinding(
                  markerId: 'cue_confirm',
                  awaitableNodeId: 'confirm_name',
                  outcomeRoutes: [
                    ScenePresentationCueOutcomeRoute(
                      outputPortId: 'declined',
                      outcome: PresentationInteractionOutcome.repeatFromMarker(
                        markerId: 'cue_name',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SceneNode(
            id: 'ask_name',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.preSessionInteraction(
              ScenePreSessionInteractionSpec.text(
                prompt: SceneInteractionPrompt(
                  localizationKey: 'new_game.name',
                  fallbackText: 'Votre nom ?',
                ),
                resultBinding: const ScenePreSessionResultBinding(
                  field: ScenePreSessionDraftField.playerName,
                ),
              ),
            ),
          ),
          SceneNode(
            id: 'confirm_name',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.preSessionInteraction(
              ScenePreSessionInteractionSpec.confirmation(
                prompt: SceneInteractionPrompt(
                  localizationKey: 'new_game.confirm',
                  fallbackText: 'On garde {{draft.playerName}} ?',
                ),
              ),
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

final class _RoutingPresentationPlayer
    implements ScenePresentationCinematicRuntimePlayer {
  _RoutingPresentationPlayer({required this.orderedMarkerIds});

  final List<String> orderedMarkerIds;
  var _cueSequence = 0;

  @override
  Future<RuntimePresentationExecutionTerminal> playPresentationCinematic(
    ScenePresentationCinematicRuntimeRequest request,
  ) async {
    var index = 0;
    var transitions = 0;
    while (index < orderedMarkerIds.length) {
      final markerId = orderedMarkerIds[index];
      if (!request.interactionCueMarkerIds.contains(markerId)) {
        index += 1;
        continue;
      }
      final outcome = await request.onInteractionCue!(
        ScenePresentationInteractionCue(
          markerId: markerId,
          cueExecutionId:
              '${request.requestId}:cue:$markerId#${++_cueSequence}',
        ),
      );
      switch (outcome) {
        case PresentationContinueTimelineOutcome():
          index += 1;
        case PresentationSeekMarkerOutcome(markerId: final destination) ||
              PresentationRepeatFromMarkerOutcome(
                markerId: final destination,
              ):
          transitions += 1;
          if (transitions > defaultPresentationTransitionBudgetPerExecution) {
            return const RuntimePresentationExecutionTerminal(
              runToken: RuntimePresentationRunToken(1),
              result: RuntimePresentationExecutionResult.failed,
              diagnosticCode:
                  PresentationCueOutcomeCodes.transitionBudgetExhausted,
            );
          }
          final target = orderedMarkerIds.indexOf(destination);
          if (target < 0) {
            return const RuntimePresentationExecutionTerminal(
              runToken: RuntimePresentationRunToken(1),
              result: RuntimePresentationExecutionResult.failed,
              diagnosticCode:
                  PresentationCueOutcomeCodes.unknownSeekDestination,
            );
          }
          index = target;
        case PresentationStopOutcome():
          return const RuntimePresentationExecutionTerminal(
            runToken: RuntimePresentationRunToken(1),
            result: RuntimePresentationExecutionResult.completed,
          );
        case PresentationCancelledOutcome():
          return const RuntimePresentationExecutionTerminal(
            runToken: RuntimePresentationRunToken(1),
            result: RuntimePresentationExecutionResult.skipped,
          );
        case PresentationFailedOutcome(:final diagnosticCode):
          return RuntimePresentationExecutionTerminal(
            runToken: const RuntimePresentationRunToken(1),
            result: RuntimePresentationExecutionResult.failed,
            diagnosticCode: diagnosticCode,
          );
      }
    }
    return const RuntimePresentationExecutionTerminal(
      runToken: RuntimePresentationRunToken(1),
      result: RuntimePresentationExecutionResult.completed,
    );
  }
}

SceneAsset _yarnCueScene() => SceneAsset(
      id: 'scene_intro',
      name: 'Yarn cue intro',
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
              interactionCueBindings: [
                ScenePresentationInteractionCueBinding(
                  markerId: 'cue_talk',
                  awaitableNodeId: 'talk',
                ),
              ],
            ),
          ),
          SceneNode(
            id: 'talk',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(
              dialogueId: 'cue_talk',
              yarnNodeName: 'CueTalk',
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
            id: 'presentation_talk',
            fromNodeId: 'presentation',
            fromPortId: 'completed',
            toNodeId: 'talk',
            kind: SceneEdgeKind.presentationCompleted,
          ),
          SceneEdge(
            id: 'talk_end',
            fromNodeId: 'talk',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );

SceneAsset _interpolationScene() => SceneAsset(
      id: 'scene_intro',
      name: 'Interpolated intro',
      executionProfile: SceneExecutionProfile.preSession,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'before',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(
              dialogueId: 'intro',
              yarnNodeName: 'Before',
            ),
          ),
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
            id: 'after',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(
              dialogueId: 'intro',
              yarnNodeName: 'After',
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_before',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'before',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'before_name',
            fromNodeId: 'before',
            fromPortId: 'completed',
            toNodeId: 'name',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'name_after',
            fromNodeId: 'name',
            fromPortId: 'completed',
            toNodeId: 'after',
            kind: SceneEdgeKind.actionCompleted,
          ),
          SceneEdge(
            id: 'after_end',
            fromNodeId: 'after',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );

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

SceneAsset _confirmationScene() => SceneAsset(
      id: 'scene_intro',
      name: 'Confirmation',
      executionProfile: SceneExecutionProfile.preSession,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'confirm',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.preSessionInteraction(
              ScenePreSessionInteractionSpec.confirmation(
                prompt: SceneInteractionPrompt(
                  localizationKey: 'new_game.confirm',
                  fallbackText: 'Continuer ?',
                ),
              ),
            ),
          ),
          SceneNode(
            id: 'confirmed_message',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.preSessionInteraction(
              ScenePreSessionInteractionSpec.message(
                prompt: SceneInteractionPrompt(
                  localizationKey: 'new_game.confirmed',
                  fallbackText: 'Confirmation reçue.',
                ),
              ),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_confirm',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'confirm',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'confirm_yes',
            fromNodeId: 'confirm',
            fromPortId: 'confirmed',
            toNodeId: 'confirmed_message',
            kind: SceneEdgeKind.actionCompleted,
          ),
          SceneEdge(
            id: 'confirm_no',
            fromNodeId: 'confirm',
            fromPortId: 'declined',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
          SceneEdge(
            id: 'message_end',
            fromNodeId: 'confirmed_message',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
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
            fromPortId: 'hero_a',
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

SceneAsset _presentationInteractionScene() => SceneAsset(
      id: 'scene_intro',
      name: 'Presentation interaction',
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
              interactionCueBindings: [
                ScenePresentationInteractionCueBinding(
                  markerId: 'ask_avatar',
                  awaitableNodeId: 'avatar',
                ),
              ],
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
                resultBinding: const ScenePreSessionResultBinding(
                  field: ScenePreSessionDraftField.avatarCharacterId,
                ),
              ),
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
            id: 'presentation_avatar',
            fromNodeId: 'presentation',
            fromPortId: 'completed',
            toNodeId: 'avatar',
            kind: SceneEdgeKind.presentationCompleted,
          ),
          SceneEdge(
            id: 'avatar_end',
            fromNodeId: 'avatar',
            fromPortId: 'hero_a',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );

final class _CompletingPresentationPlayer
    implements ScenePresentationCinematicRuntimePlayer {
  _CompletingPresentationPlayer({this.triggerMarkerId});

  final String? triggerMarkerId;
  final requests = <ScenePresentationCinematicRuntimeRequest>[];

  @override
  Future<RuntimePresentationExecutionTerminal> playPresentationCinematic(
    ScenePresentationCinematicRuntimeRequest request,
  ) async {
    requests.add(request);
    final markerId = triggerMarkerId;
    if (markerId != null) {
      final outcome = await request.onInteractionCue?.call(
        ScenePresentationInteractionCue(
          markerId: markerId,
          cueExecutionId: '${request.requestId}:cue:$markerId#1',
        ),
      );
      if (outcome != null) {
        expect(outcome, const PresentationInteractionOutcome.continueTimeline());
      }
    }
    return const RuntimePresentationExecutionTerminal(
      runToken: RuntimePresentationRunToken(1),
      result: RuntimePresentationExecutionResult.completed,
    );
  }
}
