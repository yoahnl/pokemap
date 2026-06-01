import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Cinematic authoring operations', () {
    test('addCinematicAsset adds an asset without mutating project', () {
      final project = _project();
      final cinematic = _cinematic(id: 'cinematic_intro');

      final result = addCinematicAsset(project, cinematic);

      expect(project.cinematics, isEmpty);
      expect(result.updatedProject.cinematics, [cinematic]);
      expect(result.cinematic, cinematic);
      expect(result.updatedProject.scenarios, project.scenarios);
      expect(result.updatedProject.scenes, project.scenes);
    });

    test('addCinematicAsset refuses duplicate ids', () {
      final project = _project(cinematics: [_cinematic(id: 'cinematic_intro')]);

      expect(
        () => addCinematicAsset(project, _cinematic(id: 'cinematic_intro')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addCinematicRequiredActor creates a minimal required actor', () {
      final project = _project(cinematics: [
        _cinematic(id: 'cinematic_intro', requiredActors: [
          CinematicActorRef(actorId: 'actor', label: 'Acteur'),
        ]),
      ]);

      final result = addCinematicRequiredActor(
        project,
        cinematicId: 'cinematic_intro',
        label: 'Assistant',
      );

      expect(project.cinematics.single.requiredActors, hasLength(1));
      expect(result.actor.actorId, 'actor_2');
      expect(result.actor.label, 'Assistant');
      expect(result.cinematic.requiredActors.map((actor) => actor.actorId), [
        'actor',
        'actor_2',
      ]);
      expect(result.cinematic.timeline, project.cinematics.single.timeline);
      expect(result.updatedProject.scenes, project.scenes);
      expect(result.updatedProject.scenarios, project.scenarios);
    });

    test('addCinematicRequiredActor refuses empty labels', () {
      final project = _project(cinematics: [_cinematic(id: 'cinematic_intro')]);

      expect(
        () => addCinematicRequiredActor(
          project,
          cinematicId: 'cinematic_intro',
          label: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateCinematicAsset replaces an existing asset only', () {
      final existing = _cinematic(id: 'cinematic_intro');
      final other = _cinematic(id: 'cinematic_other', title: 'Other');
      final project = _project(cinematics: [existing, other]);
      final updated = _cinematic(
        id: 'cinematic_intro',
        title: 'Updated intro',
        description: 'Updated description',
      );

      final result = updateCinematicAsset(project, updated);

      expect(result.updatedProject.cinematics, [updated, other]);
      expect(result.cinematic, updated);
      expect(project.cinematics, [existing, other]);
    });

    test('removeCinematicAsset removes unused asset', () {
      final cinematic = _cinematic(id: 'cinematic_intro');
      final project = _project(cinematics: [cinematic]);

      final result = removeCinematicAsset(project, 'cinematic_intro');

      expect(result.removedCinematic, cinematic);
      expect(result.updatedProject.cinematics, isEmpty);
      expect(project.cinematics, [cinematic]);
    });

    test('removeCinematicAsset refuses a cinematic referenced by a Scene', () {
      final project = _project(
        cinematics: [_cinematic(id: 'cinematic_intro')],
        scenes: [_sceneReferencingCinematic('cinematic_intro')],
      );

      expect(
        () => removeCinematicAsset(project, 'cinematic_intro'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('replaceCinematics validates duplicate ids and preserves other data',
        () {
      final scenario = const ScenarioAsset(
        id: 'scenario_legacy',
        name: 'Legacy',
        entryNodeId: 'start',
      );
      final scene = _sceneReferencingCinematic('cinematic_intro');
      final project = _project(scenarios: [scenario], scenes: [scene]);
      final cinematic = _cinematic(id: 'cinematic_intro');

      final updated = replaceCinematics(project, [cinematic]);

      expect(updated.cinematics, [cinematic]);
      expect(updated.scenarios, [scenario]);
      expect(updated.scenes, [scene]);
      expect(
        () => replaceCinematics(project, [cinematic, cinematic]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('findCinematicById returns matching asset or null', () {
      final cinematic = _cinematic(id: 'cinematic_intro');
      final project = _project(cinematics: [cinematic]);

      expect(findCinematicById(project, 'cinematic_intro'), cinematic);
      expect(findCinematicById(project, 'missing'), isNull);
    });

    test('addCinematicTimelineDraftStep inserts a marker draft after selection',
        () {
      final cinematic = _cinematic(id: 'cinematic_intro');
      final project = _project(cinematics: [cinematic]);

      final result = addCinematicTimelineDraftStep(
        project,
        cinematicId: 'cinematic_intro',
        afterStepId: 'step_wait',
      );

      expect(project.cinematics.single.timeline.steps, hasLength(1));
      expect(result.updatedProject.cinematics, hasLength(1));
      expect(result.cinematic.id, 'cinematic_intro');
      expect(result.step.id, 'step_draft');
      expect(result.step.kind, CinematicTimelineStepKind.marker);
      expect(result.step.label, 'Bloc brouillon');
      expect(result.step.durationMs, isNull);
      expect(result.step.actorId, isNull);
      expect(result.step.targetId, isNull);
      expect(result.step.dialogueText, isNull);
      expect(result.step.assetRef, isNull);
      expect(isCinematicTimelineDraftStep(result.step), isTrue);
      expect(
        result.cinematic.timeline.steps.map((step) => step.id),
        ['step_wait', 'step_draft'],
      );
      expect(result.updatedProject.scenes, project.scenes);
      expect(result.updatedProject.scenarios, project.scenarios);
    });

    test('addCinematicTimelineDraftStep appends when no step is selected', () {
      final cinematic = _cinematicWithSteps(
        id: 'cinematic_intro',
        stepIds: ['step_camera', 'step_dialogue'],
      );
      final project = _project(cinematics: [cinematic]);

      final result = addCinematicTimelineDraftStep(
        project,
        cinematicId: 'cinematic_intro',
      );

      expect(
        result.cinematic.timeline.steps.map((step) => step.id),
        ['step_camera', 'step_dialogue', 'step_draft'],
      );
    });

    test('addCinematicTimelineDraftStep generates deterministic unique ids',
        () {
      final cinematic = _cinematicWithSteps(
        id: 'cinematic_intro',
        stepIds: ['step_draft', 'step_draft_2'],
      );
      final project = _project(cinematics: [cinematic]);

      final result = addCinematicTimelineDraftStep(
        project,
        cinematicId: 'cinematic_intro',
      );

      expect(result.step.id, 'step_draft_3');
    });

    test('removeCinematicTimelineDraftStep removes only draft markers', () {
      final draft = CinematicTimelineStep(
        id: 'step_draft',
        kind: CinematicTimelineStepKind.marker,
        label: 'Bloc brouillon',
        metadata: const {
          'authoring.kind': 'draft',
          'authoring.source': 'cinematic-builder-v0',
        },
      );
      final cinematic = CinematicAsset(
        id: 'cinematic_intro',
        title: 'Intro cinematic',
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_wait',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 100,
            ),
            draft,
          ],
        ),
      );
      final project = _project(cinematics: [cinematic]);

      final result = removeCinematicTimelineDraftStep(
        project,
        cinematicId: 'cinematic_intro',
        stepId: 'step_draft',
      );

      expect(result.removedStep, draft);
      expect(
        result.cinematic.timeline.steps.map((step) => step.id),
        ['step_wait'],
      );
      expect(project.cinematics.single.timeline.steps, hasLength(2));
    });

    test('removeCinematicTimelineDraftStep refuses unknown and non-draft steps',
        () {
      final cinematic = _cinematic(id: 'cinematic_intro');
      final project = _project(cinematics: [cinematic]);

      expect(
        () => removeCinematicTimelineDraftStep(
          project,
          cinematicId: 'cinematic_intro',
          stepId: 'step_missing',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => removeCinematicTimelineDraftStep(
          project,
          cinematicId: 'cinematic_intro',
          stepId: 'step_wait',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addCinematicTimelineBasicBlockStep adds wait to an empty timeline',
        () {
      final project = _project(
        cinematics: [
          CinematicAsset(
            id: 'cinematic_intro',
            title: 'Intro cinematic',
            timeline: CinematicTimeline(),
          ),
        ],
      );

      final result = addCinematicTimelineBasicBlockStep(
        project,
        cinematicId: 'cinematic_intro',
        blockKind: CinematicTimelineBasicBlockKind.wait,
      );

      expect(project.cinematics.single.timeline.steps, isEmpty);
      expect(result.step.id, 'step_wait');
      expect(result.step.kind, CinematicTimelineStepKind.wait);
      expect(result.step.label, 'Attente');
      expect(result.step.durationMs, 1000);
      expect(result.step.actorId, isNull);
      expect(result.step.targetId, isNull);
      expect(result.step.dialogueText, isNull);
      expect(result.step.assetRef, isNull);
      expect(isCinematicTimelineAuthoringStep(result.step), isTrue);
      expect(isCinematicTimelineBasicBlockStep(result.step), isTrue);
      expect(
        cinematicTimelineBasicBlockKindOf(result.step),
        CinematicTimelineBasicBlockKind.wait,
      );
      expect(
        result.step.metadata,
        containsPair('authoring.block', 'wait'),
      );
      expect(result.cinematic.timeline.steps, [result.step]);
    });

    test('addCinematicTimelineBasicBlockStep inserts after selection', () {
      final cinematic = _cinematicWithSteps(
        id: 'cinematic_intro',
        stepIds: ['step_camera', 'step_dialogue'],
      );
      final project = _project(cinematics: [cinematic]);

      final result = addCinematicTimelineBasicBlockStep(
        project,
        cinematicId: 'cinematic_intro',
        blockKind: CinematicTimelineBasicBlockKind.fade,
        afterStepId: 'step_camera',
        fadeMode: CinematicTimelineFadeMode.fadeOut,
        durationMs: 1500,
      );

      expect(result.step.id, 'step_fade');
      expect(result.step.kind, CinematicTimelineStepKind.fade);
      expect(result.step.label, 'Fondu sortant');
      expect(result.step.durationMs, 1500);
      expect(result.step.metadata, containsPair('authoring.block', 'fade'));
      expect(result.step.metadata, containsPair('fade.mode', 'fadeOut'));
      expect(
        result.cinematic.timeline.steps.map((step) => step.id),
        ['step_camera', 'step_fade', 'step_dialogue'],
      );
      expect(project.cinematics.single.timeline.steps, hasLength(2));
    });

    test('addCinematicTimelineBasicBlockStep adds camera with stable suffixes',
        () {
      final cinematic = _cinematicWithSteps(
        id: 'cinematic_intro',
        stepIds: ['step_camera', 'step_camera_2'],
      );
      final project = _project(cinematics: [cinematic]);

      final result = addCinematicTimelineBasicBlockStep(
        project,
        cinematicId: 'cinematic_intro',
        blockKind: CinematicTimelineBasicBlockKind.camera,
        cameraMode: CinematicTimelineCameraMode.hold,
      );

      expect(result.step.id, 'step_camera_3');
      expect(result.step.kind, CinematicTimelineStepKind.camera);
      expect(result.step.label, 'Caméra');
      expect(result.step.durationMs, 500);
      expect(result.step.targetId, isNull);
      expect(result.step.actorId, isNull);
      expect(result.step.metadata, containsPair('authoring.block', 'camera'));
      expect(result.step.metadata, containsPair('camera.mode', 'hold'));
    });

    test('updateCinematicTimelineBasicBlockStep changes only allowed params',
        () {
      var project = _project(
        cinematics: [
          CinematicAsset(
            id: 'cinematic_intro',
            title: 'Intro cinematic',
            timeline: CinematicTimeline(),
          ),
        ],
        scenarios: [
          const ScenarioAsset(
            id: 'scenario_legacy',
            name: 'Legacy',
            entryNodeId: 'start',
          ),
        ],
        scenes: [_sceneReferencingCinematic('cinematic_intro')],
      );
      final fade = addCinematicTimelineBasicBlockStep(
        project,
        cinematicId: 'cinematic_intro',
        blockKind: CinematicTimelineBasicBlockKind.fade,
      );
      project = fade.updatedProject;

      final result = updateCinematicTimelineBasicBlockStep(
        project,
        cinematicId: 'cinematic_intro',
        stepId: fade.step.id,
        durationMs: 2000,
        fadeMode: CinematicTimelineFadeMode.fadeOut,
      );

      expect(result.step.id, fade.step.id);
      expect(result.step.kind, CinematicTimelineStepKind.fade);
      expect(result.step.label, 'Fondu sortant');
      expect(result.step.durationMs, 2000);
      expect(result.step.metadata, containsPair('fade.mode', 'fadeOut'));
      expect(result.updatedProject.scenes, project.scenes);
      expect(result.updatedProject.scenarios, project.scenarios);
    });

    test('updateCinematicTimelineBasicBlockStep updates camera mode', () {
      final project = _project(cinematics: [_cinematic(id: 'cinematic_intro')]);
      final added = addCinematicTimelineBasicBlockStep(
        project,
        cinematicId: 'cinematic_intro',
        blockKind: CinematicTimelineBasicBlockKind.camera,
      );

      final result = updateCinematicTimelineBasicBlockStep(
        added.updatedProject,
        cinematicId: 'cinematic_intro',
        stepId: added.step.id,
        durationMs: 1500,
        cameraMode: CinematicTimelineCameraMode.hold,
      );

      expect(result.step.metadata, containsPair('camera.mode', 'hold'));
      expect(result.step.durationMs, 1500);
    });

    test('updateCinematicTimelineBasicBlockStep refuses invalid updates', () {
      final project = _project(cinematics: [_cinematic(id: 'cinematic_intro')]);
      final added = addCinematicTimelineBasicBlockStep(
        project,
        cinematicId: 'cinematic_intro',
        blockKind: CinematicTimelineBasicBlockKind.wait,
      );

      expect(
        () => updateCinematicTimelineBasicBlockStep(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: added.step.id,
          durationMs: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => updateCinematicTimelineBasicBlockStep(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: 'step_wait',
          durationMs: 1000,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => updateCinematicTimelineBasicBlockStep(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: 'step_missing',
          durationMs: 1000,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addCinematicTimelineActorFacingStep creates an actorFace block', () {
      final cinematic = _cinematic(
        id: 'cinematic_intro',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
        ],
      );
      final project = _project(
        cinematics: [cinematic],
        scenarios: [
          const ScenarioAsset(
            id: 'scenario_legacy',
            name: 'Legacy',
            entryNodeId: 'start',
          ),
        ],
        scenes: [_sceneReferencingCinematic('cinematic_intro')],
      );

      final result = addCinematicTimelineActorFacingStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
        direction: CinematicTimelineActorFacingDirection.left,
        afterStepId: 'step_wait',
      );

      expect(project.cinematics.single.timeline.steps, hasLength(1));
      expect(result.step.id, 'step_actor_face');
      expect(result.step.kind, CinematicTimelineStepKind.actorFace);
      expect(result.step.label, 'Orientation Professor');
      expect(result.step.actorId, 'actor_professor');
      expect(result.step.durationMs, isNull);
      expect(result.step.targetId, isNull);
      expect(result.step.dialogueText, isNull);
      expect(result.step.assetRef, isNull);
      expect(
          result.step.metadata, containsPair('authoring.block', 'actorFace'));
      expect(result.step.metadata, containsPair('actor.direction', 'left'));
      expect(isCinematicTimelineActorFacingStep(result.step), isTrue);
      expect(isCinematicTimelineAuthoringStep(result.step), isTrue);
      expect(
        cinematicTimelineActorFacingDirectionOf(result.step),
        CinematicTimelineActorFacingDirection.left,
      );
      expect(
        result.cinematic.timeline.steps.map((step) => step.id),
        ['step_wait', 'step_actor_face'],
      );
      expect(result.updatedProject.scenes, project.scenes);
      expect(result.updatedProject.scenarios, project.scenarios);
    });

    test('addCinematicTimelineActorFacingStep validates actor ids and suffixes',
        () {
      final cinematic = CinematicAsset(
        id: 'cinematic_intro',
        title: 'Intro cinematic',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
        ],
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_actor_face',
              kind: CinematicTimelineStepKind.actorFace,
              actorId: 'actor_professor',
              metadata: const {
                'authoring.source': 'cinematic-builder-v0',
                'authoring.kind': 'basicBlock',
                'authoring.block': 'actorFace',
                'actor.direction': 'down',
              },
            ),
          ],
        ),
      );
      final project = _project(cinematics: [cinematic]);

      final result = addCinematicTimelineActorFacingStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
        direction: CinematicTimelineActorFacingDirection.up,
      );

      expect(result.step.id, 'step_actor_face_2');
      expect(
        () => addCinematicTimelineActorFacingStep(
          project,
          cinematicId: 'cinematic_intro',
          actorId: 'actor_missing',
          direction: CinematicTimelineActorFacingDirection.up,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateCinematicTimelineActorFacingStep changes actor and direction',
        () {
      var project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
            ],
          ),
        ],
      );
      final added = addCinematicTimelineActorFacingStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
        direction: CinematicTimelineActorFacingDirection.down,
      );
      project = added.updatedProject;

      final result = updateCinematicTimelineActorFacingStep(
        project,
        cinematicId: 'cinematic_intro',
        stepId: added.step.id,
        actorId: 'actor_rival',
        direction: CinematicTimelineActorFacingDirection.right,
      );

      expect(result.step.id, added.step.id);
      expect(result.step.kind, CinematicTimelineStepKind.actorFace);
      expect(result.step.label, 'Orientation Rival');
      expect(result.step.actorId, 'actor_rival');
      expect(result.step.metadata, containsPair('actor.direction', 'right'));
      expect(project.cinematics.single.timeline.steps.last.actorId,
          'actor_professor');
    });

    test('updateCinematicTimelineActorFacingStep refuses invalid updates', () {
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
            ],
          ),
        ],
      );
      final added = addCinematicTimelineActorFacingStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
        direction: CinematicTimelineActorFacingDirection.down,
      );

      expect(
        () => updateCinematicTimelineActorFacingStep(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: added.step.id,
          actorId: 'actor_missing',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => updateCinematicTimelineActorFacingStep(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: 'step_wait',
          direction: CinematicTimelineActorFacingDirection.left,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => updateCinematicTimelineActorFacingStep(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: 'step_missing',
          direction: CinematicTimelineActorFacingDirection.left,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('removeCinematicTimelineAuthoringStep removes drafts and basic blocks',
        () {
      var project = _project(cinematics: [_cinematic(id: 'cinematic_intro')]);
      final draft = addCinematicTimelineDraftStep(
        project,
        cinematicId: 'cinematic_intro',
      );
      project = draft.updatedProject;
      final wait = addCinematicTimelineBasicBlockStep(
        project,
        cinematicId: 'cinematic_intro',
        blockKind: CinematicTimelineBasicBlockKind.wait,
      );
      project = wait.updatedProject;
      final actor = addCinematicRequiredActor(
        project,
        cinematicId: 'cinematic_intro',
        label: 'Actor',
      );
      project = actor.updatedProject;
      final actorFace = addCinematicTimelineActorFacingStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: actor.actor.actorId,
        direction: CinematicTimelineActorFacingDirection.down,
      );
      project = actorFace.updatedProject;

      final removedWait = removeCinematicTimelineAuthoringStep(
        project,
        cinematicId: 'cinematic_intro',
        stepId: wait.step.id,
      );
      final removedActorFace = removeCinematicTimelineAuthoringStep(
        removedWait.updatedProject,
        cinematicId: 'cinematic_intro',
        stepId: actorFace.step.id,
      );
      final removedDraft = removeCinematicTimelineAuthoringStep(
        removedActorFace.updatedProject,
        cinematicId: 'cinematic_intro',
        stepId: draft.step.id,
      );

      expect(removedWait.removedStep.id, wait.step.id);
      expect(removedActorFace.removedStep.id, actorFace.step.id);
      expect(removedDraft.removedStep.id, draft.step.id);
      expect(
        removedDraft.cinematic.timeline.steps.map((step) => step.id),
        ['step_wait'],
      );
      expect(project.cinematics.single.timeline.steps, hasLength(4));
    });

    test('removeCinematicTimelineAuthoringStep refuses non-owned steps', () {
      final project = _project(cinematics: [_cinematic(id: 'cinematic_intro')]);

      expect(
        () => removeCinematicTimelineAuthoringStep(
          project,
          cinematicId: 'cinematic_intro',
          stepId: 'step_wait',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

ProjectManifest _project({
  List<CinematicAsset> cinematics = const [],
  List<ScenarioAsset> scenarios = const [],
  List<SceneAsset> scenes = const [],
}) {
  return ProjectManifest(
    name: 'Cinematic authoring test',
    maps: const [],
    tilesets: const [],
    cinematics: cinematics,
    scenarios: scenarios,
    scenes: scenes,
  );
}

CinematicAsset _cinematic({
  required String id,
  String title = 'Intro cinematic',
  String? description,
  List<CinematicActorRef> requiredActors = const [],
}) {
  return CinematicAsset(
    id: id,
    title: title,
    description: description,
    requiredActors: requiredActors,
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          durationMs: 100,
        ),
      ],
    ),
  );
}

CinematicAsset _cinematicWithSteps({
  required String id,
  required List<String> stepIds,
}) {
  return CinematicAsset(
    id: id,
    title: 'Intro cinematic',
    timeline: CinematicTimeline(
      steps: [
        for (final stepId in stepIds)
          CinematicTimelineStep(
            id: stepId,
            kind: CinematicTimelineStepKind.wait,
            durationMs: 100,
          ),
      ],
    ),
  );
}

SceneAsset _sceneReferencingCinematic(String cinematicId) {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Intro scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_cinematic',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: cinematicId),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_cinematic',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_cinematic',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_cinematic_end',
          fromNodeId: 'node_cinematic',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.cinematicCompleted,
        ),
      ],
    ),
  );
}
