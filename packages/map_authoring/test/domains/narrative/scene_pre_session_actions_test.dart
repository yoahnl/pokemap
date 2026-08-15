import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene preSession semantic actions', () {
    test('publishes the complete headless action catalog', () {
      expect(
        SceneActions.descriptors.map((descriptor) => descriptor.id),
        containsAll(const {
          'scene.preSession.create',
          'scene.preSession.interaction.insert',
          'scene.preSession.presentation.insert',
          'scene.preSession.condition.insert',
          'scene.preSession.end.configure',
        }),
      );
    });

    test('creates a valid identity template and links the entrypoint', () {
      final project = _project();

      final projected = const SceneActions().createPreSessionScene(
        project,
        maps: const <MapData>[],
        sceneId: 'new_game_intro',
        name: 'Nouvelle partie',
        templateId: 'identitySetup',
        setAsEntrypoint: true,
      );

      final scene = projected.scenes.single;
      expect(scene.executionProfile, SceneExecutionProfile.preSession);
      expect(projected.newGame.preSessionSceneId, scene.id);
      expect(buildSceneRuntimePlan(scene).canBuild, isTrue);
      expect(
        scene.graph.nodes
            .where((node) => node.kind == SceneNodeKind.action)
            .map((node) =>
                (node.payload as SceneActionPayload).preSessionInteraction)
            .whereType<ScenePreSessionInteractionSpec>()
            .map((interaction) => interaction.resultBinding?.field),
        const [
          ScenePreSessionDraftField.playerName,
          ScenePreSessionDraftField.avatarCharacterId,
          ScenePreSessionDraftField.starterOptionId,
        ],
      );
    });

    test('inserts typed nodes without requiring a whole Scene payload', () {
      final actions = const SceneActions();
      var project = actions.createPreSessionScene(
        _project(),
        maps: const <MapData>[],
        sceneId: 'new_game_intro',
        name: 'Nouvelle partie',
        templateId: 'minimal',
        setAsEntrypoint: true,
      );
      project = actions.insertPreSessionInteraction(
        project,
        maps: const <MapData>[],
        sceneId: 'new_game_intro',
        nodeId: 'ask_name',
        targetNodeId: 'end',
        interaction: ScenePreSessionInteractionSpec.text(
          prompt: SceneInteractionPrompt(
            localizationKey: 'newGame.playerName.prompt',
          ),
          resultBinding: const ScenePreSessionResultBinding(
            field: ScenePreSessionDraftField.playerName,
          ),
        ),
      );
      project = actions.insertPreSessionPresentation(
        project,
        maps: const <MapData>[],
        sceneId: 'new_game_intro',
        nodeId: 'opening',
        targetNodeId: 'end',
        presentationCinematicId: 'presentation_opening',
      );
      project = actions.insertPreSessionCondition(
        project,
        maps: const <MapData>[],
        sceneId: 'new_game_intro',
        nodeId: 'has_name',
        targetNodeId: 'end',
        falseEndNodeId: 'end_missing_name',
        draftField: ScenePreSessionDraftField.playerName,
        operator: SceneConditionOperator.isTrue,
      );
      project = actions.configurePreSessionEnd(
        project,
        maps: const <MapData>[],
        sceneId: 'new_game_intro',
        nodeId: 'end',
        outcomeId: 'ready',
        outcomeLabel: 'Prêt',
        outcomePolicy: SceneOutcomePolicy.progression,
      );

      final scene = project.scenes.single;
      expect(buildSceneRuntimePlan(scene).canBuild, isTrue);
      expect(
        scene.graph.nodes.map((node) => node.id),
        containsAll(const {
          'ask_name',
          'opening',
          'has_name',
          'end_missing_name',
        }),
      );
      expect(
        scene.declaredOutcomes.map((outcome) => outcome.id),
        containsAll(const {'ready', 'outcome_end_missing_name'}),
      );
    });

    test('rejects an unknown Presentation relation with a stable code', () {
      final actions = const SceneActions();
      final project = actions.createPreSessionScene(
        _project(),
        maps: const <MapData>[],
        sceneId: 'new_game_intro',
        name: 'Nouvelle partie',
        templateId: 'minimal',
        setAsEntrypoint: true,
      );

      expect(
        () => actions.insertPreSessionPresentation(
          project,
          maps: const <MapData>[],
          sceneId: 'new_game_intro',
          nodeId: 'opening',
          targetNodeId: 'end',
          presentationCinematicId: 'missing',
        ),
        throwsA(
          isA<NarrativeAuthoringException>().having(
            (error) => error.code,
            'code',
            'scene.preSession.presentation.unknown',
          ),
        ),
      );
    });

    test('rejects semantic preSession edits against a world Scene', () {
      final project = _project().copyWith(
        scenes: [
          SceneAsset(
            id: 'world_scene',
            name: 'Monde',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(id: 'end', kind: SceneNodeKind.end),
              ],
              edges: [
                SceneEdge(
                  id: 'start_end',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'end',
                  kind: SceneEdgeKind.defaultFlow,
                ),
              ],
            ),
          ),
        ],
      );

      expect(
        () => const SceneActions().insertPreSessionInteraction(
          project,
          maps: const <MapData>[],
          sceneId: 'world_scene',
          nodeId: 'message',
          targetNodeId: 'end',
          interaction: ScenePreSessionInteractionSpec.message(
            prompt: SceneInteractionPrompt(
              localizationKey: 'world.invalid.prompt',
            ),
          ),
        ),
        throwsA(
          isA<NarrativeAuthoringException>().having(
            (error) => error.code,
            'code',
            'scene.preSession.profile_required',
          ),
        ),
      );
    });

    test('rejects draft-bound options outside New Game config', () {
      final actions = const SceneActions();
      final project = actions.createPreSessionScene(
        _project(),
        maps: const <MapData>[],
        sceneId: 'new_game_intro',
        name: 'Nouvelle partie',
        templateId: 'minimal',
        setAsEntrypoint: true,
      );

      expect(
        () => actions.insertPreSessionInteraction(
          project,
          maps: const <MapData>[],
          sceneId: 'new_game_intro',
          nodeId: 'choose_starter',
          targetNodeId: 'end',
          interaction: ScenePreSessionInteractionSpec.choice(
            prompt: SceneInteractionPrompt(
              localizationKey: 'newGame.starter.prompt',
            ),
            options: [
              SceneInteractionOption(
                id: 'starter_unknown',
                label: SceneInteractionPrompt(
                  localizationKey: 'newGame.starter.unknown',
                ),
              ),
            ],
            resultBinding: const ScenePreSessionResultBinding(
              field: ScenePreSessionDraftField.starterOptionId,
            ),
          ),
        ),
        throwsA(
          isA<NarrativeAuthoringException>().having(
            (error) => error.code,
            'code',
            'scene.preSession.binding.option_unknown',
          ),
        ),
      );
    });
  });
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Pre-session authoring fixture',
    version: ProjectVersion.v7,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    presentationCinematics: [
      PresentationCinematicAsset(
        id: 'presentation_opening',
        title: 'Ouverture',
        durationUs: 1000000,
      ),
    ],
    newGame: ProjectNewGameConfig(
      enabled: true,
      startMapId: 'map_start',
      playerAvatarCharacterIds: const ['avatar_a'],
      starterOptions: [
        ProjectStarterOption(
          id: 'starter_leaf',
          label: 'Feuille',
          pokemon: PlayerPokemon(
            speciesId: 'leaf',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 5,
          ),
        ),
      ],
    ),
  );
}
