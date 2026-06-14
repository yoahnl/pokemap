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

    test('renameCinematicRequiredActor updates label without changing refs',
        () {
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
            ],
            stageContext: CinematicStageContext(
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'actor_rival',
                  kind: CinematicActorBindingKind.cinematicOnly,
                ),
              ],
            ),
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'face',
                  kind: CinematicTimelineStepKind.actorFace,
                  actorId: 'actor_rival',
                ),
              ],
            ),
          ),
        ],
      );

      final result = renameCinematicRequiredActor(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_rival',
        label: 'Lysa',
      );

      expect(result.actor.actorId, 'actor_rival');
      expect(result.actor.label, 'Lysa');
      expect(result.cinematic.requiredActors.single.label, 'Lysa');
      expect(
        result.cinematic.stageContext?.actorBindings.single.actorId,
        'actor_rival',
      );
      expect(result.cinematic.timeline, project.cinematics.single.timeline);
    });

    test('renameCinematicRequiredActor refuses empty labels', () {
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
            ],
          ),
        ],
      );

      expect(
        () => renameCinematicRequiredActor(
          project,
          cinematicId: 'cinematic_intro',
          actorId: 'actor_rival',
          label: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('removeCinematicRequiredActor cleans unused stage refs only', () {
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
              CinematicActorRef(actorId: 'actor_guide', label: 'Guide'),
            ],
            stageContext: CinematicStageContext(
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'actor_rival',
                  kind: CinematicActorBindingKind.cinematicOnly,
                ),
                CinematicActorBinding(
                  actorId: 'actor_guide',
                  kind: CinematicActorBindingKind.player,
                ),
              ],
              actorAppearanceBindings: [
                CinematicActorAppearanceBinding(
                  actorId: 'actor_rival',
                  characterId: 'character_rival',
                ),
              ],
              initialPlacements: [
                CinematicActorInitialPlacement(
                  actorId: 'actor_rival',
                  kind: CinematicActorInitialPlacementKind.unset,
                ),
              ],
            ),
          ),
        ],
      );

      final result = removeCinematicRequiredActor(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_rival',
      );

      expect(result.actor.actorId, 'actor_rival');
      expect(
        result.cinematic.requiredActors.map((actor) => actor.actorId),
        ['actor_guide'],
      );
      expect(
        result.cinematic.stageContext?.actorBindings
            .map((binding) => binding.actorId),
        ['actor_guide'],
      );
      expect(result.cinematic.stageContext?.actorAppearanceBindings, isEmpty);
      expect(result.cinematic.stageContext?.initialPlacements, isEmpty);
      expect(result.cinematic.timeline, project.cinematics.single.timeline);
    });

    test('removeCinematicRequiredActor refuses actor used by timeline', () {
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
            ],
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'move',
                  kind: CinematicTimelineStepKind.actorMove,
                  actorId: 'actor_rival',
                ),
              ],
            ),
          ),
        ],
      );

      expect(
        () => removeCinematicRequiredActor(
          project,
          cinematicId: 'cinematic_intro',
          actorId: 'actor_rival',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addCinematicMovementTarget creates a stable authoring target', () {
      final project = _project(
        cinematics: [_cinematic(id: 'cinematic_intro')],
        scenarios: [
          const ScenarioAsset(
            id: 'scenario_legacy',
            name: 'Legacy',
            entryNodeId: 'start',
          ),
        ],
        scenes: [_sceneReferencingCinematic('cinematic_intro')],
      );

      final result = addCinematicMovementTarget(
        project,
        cinematicId: 'cinematic_intro',
        label: 'Point de destination',
      );

      expect(project.cinematics.single.movementTargets, isEmpty);
      expect(result.target.targetId, 'target');
      expect(result.target.label, 'Point de destination');
      expect(result.cinematic.movementTargets, [result.target]);
      expect(result.cinematic.timeline, project.cinematics.single.timeline);
      expect(result.cinematic.requiredActors,
          project.cinematics.single.requiredActors);
      expect(result.updatedProject.scenes, project.scenes);
      expect(result.updatedProject.scenarios, project.scenarios);
    });

    test('movement target operations validate labels and usage', () {
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            movementTargets: [
              CinematicMovementTargetRef(
                targetId: 'target',
                label: 'Cible',
              ),
              CinematicMovementTargetRef(
                targetId: 'target_2',
                label: 'Cible 2',
              ),
            ],
          ),
        ],
      );

      final added = addCinematicMovementTarget(
        project,
        cinematicId: 'cinematic_intro',
      );
      expect(added.target.targetId, 'target_3');
      expect(added.target.label, 'Cible');

      final updated = updateCinematicMovementTarget(
        added.updatedProject,
        cinematicId: 'cinematic_intro',
        targetId: 'target_3',
        label: '  Sortie cour  ',
        description: '  Destination authoring visible.  ',
      );
      expect(updated.target.label, 'Sortie cour');
      expect(updated.target.description, 'Destination authoring visible.');
      expect(updated.target.targetId, 'target_3');
      expect(updated.cinematic.timeline, added.cinematic.timeline);
      expect(updated.cinematic.requiredActors, added.cinematic.requiredActors);
      expect(updated.cinematic.metadata, added.cinematic.metadata);
      expect(
        added.updatedProject.cinematics.single.movementTargets.last.label,
        'Cible',
      );

      final removed = removeCinematicMovementTarget(
        updated.updatedProject,
        cinematicId: 'cinematic_intro',
        targetId: 'target_3',
      );
      expect(
        removed.cinematic.movementTargets.map((target) => target.targetId),
        ['target', 'target_2'],
      );

      expect(
        () => addCinematicMovementTarget(
          project,
          cinematicId: 'cinematic_intro',
          label: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => updateCinematicMovementTarget(
          project,
          cinematicId: 'cinematic_intro',
          targetId: 'target',
          label: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
        'renamed movement target updates actorMove lane labels only by read model',
        () {
      var project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
            ],
            movementTargets: [
              CinematicMovementTargetRef(
                targetId: 'target_center',
                label: 'Centre scène',
              ),
            ],
          ),
        ],
      );
      final added = addCinematicTimelineActorMoveStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
        targetId: 'target_center',
      );
      project = added.updatedProject;

      final renamed = updateCinematicMovementTarget(
        project,
        cinematicId: 'cinematic_intro',
        targetId: 'target_center',
        label: 'Centre du plateau',
        description: 'Point central authoring.',
      );

      final step = renamed.cinematic.timeline.steps.singleWhere(
          (step) => step.kind == CinematicTimelineStepKind.actorMove);
      expect(step.label, 'Déplacement Professor');
      expect(step.targetId, 'target_center');

      final readModel = buildCinematicTimelineLaneReadModel(renamed.cinematic);
      final laneStep =
          readModel.laneById('actor:actor_professor')!.steps.single;
      expect(laneStep.label, 'Professor → Centre du plateau');
      expect(laneStep.targetId, 'target_center');
      expect(laneStep.targetLabel, 'Centre du plateau');
      expect(laneStep.badges, contains('Cible: Centre du plateau'));
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

    test('updates cinematic stage map and backdrop without mutating timeline',
        () {
      final cinematic = _cinematicWithSteps(
        id: 'cinematic_intro',
        stepIds: ['step_wait'],
      );
      final project = _project(cinematics: [cinematic]);

      final mapResult = updateCinematicStageMap(
        project,
        cinematicId: 'cinematic_intro',
        mapId: '  map_lab  ',
      );
      final contextResult = updateCinematicStageContext(
        mapResult.updatedProject,
        cinematicId: 'cinematic_intro',
        stageContext: CinematicStageContext(
          backdropMode: CinematicStageBackdropMode.projectMap,
        ),
      );
      final cleared = updateCinematicStageMap(
        contextResult.updatedProject,
        cinematicId: 'cinematic_intro',
        mapId: '   ',
      );

      expect(project.cinematics.single.mapId, isNull);
      expect(mapResult.cinematic.mapId, 'map_lab');
      expect(
        contextResult.cinematic.stageContext?.backdropMode,
        CinematicStageBackdropMode.projectMap,
      );
      expect(cleared.cinematic.mapId, isNull);
      expect(contextResult.cinematic.timeline, cinematic.timeline);
      expect(contextResult.cinematic.timeline.steps.single.durationMs, 100);
    });

    test('upserts and removes actor bindings with validation', () {
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_player', label: 'Joueur'),
              CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
            ],
          ),
        ],
      );

      final player = upsertCinematicActorBinding(
        project,
        cinematicId: 'cinematic_intro',
        binding: CinematicActorBinding(
          actorId: 'actor_player',
          kind: CinematicActorBindingKind.player,
        ),
      );
      final professor = upsertCinematicActorBinding(
        player.updatedProject,
        cinematicId: 'cinematic_intro',
        binding: CinematicActorBinding(
          actorId: 'actor_professor',
          kind: CinematicActorBindingKind.mapEntity,
          mapEntityId: 'entity_professor',
        ),
      );
      final removed = removeCinematicActorBinding(
        professor.updatedProject,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_player',
      );

      expect(
        professor.cinematic.stageContext?.actorBindings.map(
          (binding) => binding.actorId,
        ),
        ['actor_player', 'actor_professor'],
      );
      expect(removed.cinematic.stageContext?.actorBindings.single.actorId,
          'actor_professor');
      expect(project.cinematics.single.stageContext, isNull);
      expect(
        () => upsertCinematicActorBinding(
          project,
          cinematicId: 'cinematic_intro',
          binding: CinematicActorBinding(
            actorId: 'actor_missing',
            kind: CinematicActorBindingKind.cinematicOnly,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => upsertCinematicActorBinding(
          professor.updatedProject,
          cinematicId: 'cinematic_intro',
          binding: CinematicActorBinding(
            actorId: 'actor_professor',
            kind: CinematicActorBindingKind.player,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('upserts actor appearance binding for cinematic only actor', () {
      final original = CinematicAsset(
        id: 'cinematic_intro',
        title: 'Intro cinematic',
        mapId: 'map_stage',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
        ],
        stageContext: CinematicStageContext(
          actorBindings: [
            CinematicActorBinding(
              actorId: 'actor_rival',
              kind: CinematicActorBindingKind.cinematicOnly,
            ),
          ],
        ),
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
      final project = _project(cinematics: [original]);

      final result = upsertCinematicActorAppearanceBinding(
        project,
        cinematicId: 'cinematic_intro',
        binding: CinematicActorAppearanceBinding(
          actorId: 'actor_rival',
          characterId: 'character_rival',
        ),
      );

      final context = result.cinematic.stageContext!;
      expect(project.cinematics.single.stageContext?.actorAppearanceBindings,
          isEmpty);
      expect(context.actorAppearanceBindings.single.actorId, 'actor_rival');
      expect(
        context.actorAppearanceBindings.single.characterId,
        'character_rival',
      );
      expect(context.actorBindings, original.stageContext?.actorBindings);
      expect(result.cinematic.timeline.steps, original.timeline.steps);
      expect(result.cinematic.mapId, 'map_stage');
      expect(result.updatedProject.scenes, project.scenes);
      expect(result.updatedProject.scenarios, project.scenarios);
    });

    test('replaces existing actor appearance binding for same actor', () {
      final project = _project(
        cinematics: [
          CinematicAsset(
            id: 'cinematic_intro',
            title: 'Intro cinematic',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
            ],
            stageContext: CinematicStageContext(
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'actor_rival',
                  kind: CinematicActorBindingKind.cinematicOnly,
                ),
              ],
              actorAppearanceBindings: [
                CinematicActorAppearanceBinding(
                  actorId: 'actor_rival',
                  characterId: 'character_old',
                ),
              ],
            ),
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'step_wait',
                  kind: CinematicTimelineStepKind.wait,
                  durationMs: 100,
                ),
              ],
            ),
          ),
        ],
      );

      final result = upsertCinematicActorAppearanceBinding(
        project,
        cinematicId: 'cinematic_intro',
        binding: CinematicActorAppearanceBinding(
          actorId: 'actor_rival',
          characterId: 'character_new',
        ),
      );

      expect(result.cinematic.stageContext?.actorAppearanceBindings, [
        CinematicActorAppearanceBinding(
          actorId: 'actor_rival',
          characterId: 'character_new',
        ),
      ]);
    });

    test('removes actor appearance binding', () {
      final project = _project(
        cinematics: [
          CinematicAsset(
            id: 'cinematic_intro',
            title: 'Intro cinematic',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
            ],
            stageContext: CinematicStageContext(
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'actor_rival',
                  kind: CinematicActorBindingKind.cinematicOnly,
                ),
              ],
              actorAppearanceBindings: [
                CinematicActorAppearanceBinding(
                  actorId: 'actor_rival',
                  characterId: 'character_rival',
                ),
              ],
            ),
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'step_wait',
                  kind: CinematicTimelineStepKind.wait,
                  durationMs: 100,
                ),
              ],
            ),
          ),
        ],
      );

      final result = removeCinematicActorAppearanceBinding(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_rival',
      );

      expect(result.cinematic.stageContext?.actorAppearanceBindings, isEmpty);
      expect(result.cinematic.stageContext?.actorBindings, hasLength(1));
      expect(project.cinematics.single.stageContext?.actorAppearanceBindings,
          hasLength(1));
    });

    test('rejects actor appearance binding for unknown actor', () {
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
            ],
          ),
        ],
      );

      expect(
        () => upsertCinematicActorAppearanceBinding(
          project,
          cinematicId: 'cinematic_intro',
          binding: CinematicActorAppearanceBinding(
            actorId: 'actor_missing',
            characterId: 'character_rival',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects actor appearance binding for player actor in v0', () {
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_player', label: 'Joueur'),
            ],
          ),
        ],
      );
      final withPlayer = upsertCinematicActorBinding(
        project,
        cinematicId: 'cinematic_intro',
        binding: CinematicActorBinding(
          actorId: 'actor_player',
          kind: CinematicActorBindingKind.player,
        ),
      );

      expect(
        () => upsertCinematicActorAppearanceBinding(
          withPlayer.updatedProject,
          cinematicId: 'cinematic_intro',
          binding: CinematicActorAppearanceBinding(
            actorId: 'actor_player',
            characterId: 'character_player',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects actor appearance binding for map entity actor in v0', () {
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            mapId: 'map_stage',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_npc', label: 'NPC'),
            ],
          ),
        ],
      );
      final withMapEntity = upsertCinematicActorBinding(
        project,
        cinematicId: 'cinematic_intro',
        binding: CinematicActorBinding(
          actorId: 'actor_npc',
          kind: CinematicActorBindingKind.mapEntity,
          mapEntityId: 'entity_npc',
        ),
      );

      expect(
        () => upsertCinematicActorAppearanceBinding(
          withMapEntity.updatedProject,
          cinematicId: 'cinematic_intro',
          binding: CinematicActorAppearanceBinding(
            actorId: 'actor_npc',
            characterId: 'character_npc',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects actor appearance binding for unbound actor in v0', () {
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
            ],
          ),
        ],
      );
      final withUnbound = upsertCinematicActorBinding(
        project,
        cinematicId: 'cinematic_intro',
        binding: CinematicActorBinding(
          actorId: 'actor_rival',
          kind: CinematicActorBindingKind.unbound,
        ),
      );

      expect(
        () => upsertCinematicActorAppearanceBinding(
          withUnbound.updatedProject,
          cinematicId: 'cinematic_intro',
          binding: CinematicActorAppearanceBinding(
            actorId: 'actor_rival',
            characterId: 'character_rival',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('appearance binding operations do not mutate timeline steps', () {
      final project = _project(
        cinematics: [
          _cinematicWithCharacterBinding('cinematic_intro'),
        ],
      );
      final originalSteps = project.cinematics.single.timeline.steps;

      final upserted = upsertCinematicActorAppearanceBinding(
        project,
        cinematicId: 'cinematic_intro',
        binding: CinematicActorAppearanceBinding(
          actorId: 'actor_rival',
          characterId: 'character_new',
        ),
      );
      final removed = removeCinematicActorAppearanceBinding(
        upserted.updatedProject,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_rival',
      );

      expect(upserted.cinematic.timeline.steps, originalSteps);
      expect(removed.cinematic.timeline.steps, originalSteps);
      expect(project.cinematics.single.timeline.steps, originalSteps);
    });

    test('appearance binding operations do not mutate durationMs', () {
      final project = _project(
        cinematics: [_cinematicWithCharacterBinding('cinematic_intro')],
      );

      final result = upsertCinematicActorAppearanceBinding(
        project,
        cinematicId: 'cinematic_intro',
        binding: CinematicActorAppearanceBinding(
          actorId: 'actor_rival',
          characterId: 'character_new',
        ),
      );

      expect(result.cinematic.timeline.steps.single.durationMs, 450);
      expect(project.cinematics.single.timeline.steps.single.durationMs, 450);
    });

    test(
        'appearance binding operations preserve map id and stage context map-free invariant',
        () {
      final project = _project(
        cinematics: [
          _cinematicWithCharacterBinding('cinematic_intro', mapId: 'map_stage'),
        ],
      );

      final result = upsertCinematicActorAppearanceBinding(
        project,
        cinematicId: 'cinematic_intro',
        binding: CinematicActorAppearanceBinding(
          actorId: 'actor_rival',
          characterId: 'character_new',
        ),
      );

      final stageJson = result.cinematic.stageContext!.toJson();
      expect(result.cinematic.mapId, 'map_stage');
      expect(stageJson, isNot(contains('mapId')));
      expect(
        result.cinematic.stageContext?.actorBindings.single.kind,
        CinematicActorBindingKind.cinematicOnly,
      );
    });

    test(
        'upserts placements and target bindings while preserving legacy bridge',
        () {
      final bridge = CinematicLegacyBridge(
        sourceKind: CinematicLegacyBridgeSourceKind.cutsceneStudio,
        scenarioId: 'scenario_legacy_intro',
      );
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
            ],
            movementTargets: [
              CinematicMovementTargetRef(
                targetId: 'target_center',
                label: 'Centre scene',
              ),
            ],
            legacyBridge: bridge,
          ),
        ],
      );

      final placement = upsertCinematicActorInitialPlacement(
        project,
        cinematicId: 'cinematic_intro',
        placement: CinematicActorInitialPlacement(
          actorId: 'actor_professor',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_center',
        ),
      );
      final targetBinding = upsertCinematicMovementTargetBinding(
        placement.updatedProject,
        cinematicId: 'cinematic_intro',
        binding: CinematicMovementTargetBinding(
          targetId: 'target_center',
          kind: CinematicMovementTargetBindingKind.mapEntity,
          sourceId: 'entity_center',
        ),
      );
      final removedPlacement = removeCinematicActorInitialPlacement(
        targetBinding.updatedProject,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
      );
      final removedTargetBinding = removeCinematicMovementTargetBinding(
        removedPlacement.updatedProject,
        cinematicId: 'cinematic_intro',
        targetId: 'target_center',
      );

      expect(
        targetBinding.cinematic.stageContext?.initialPlacements.single.targetId,
        'target_center',
      );
      expect(
        targetBinding
            .cinematic.stageContext?.movementTargetBindings.single.sourceId,
        'entity_center',
      );
      expect(
          removedPlacement.cinematic.stageContext?.initialPlacements, isEmpty);
      expect(
          removedTargetBinding.cinematic.stageContext?.movementTargetBindings,
          isEmpty);
      expect(targetBinding.cinematic.legacyBridge, bridge);
      expect(
          targetBinding.cinematic.timeline, project.cinematics.single.timeline);
      expect(
        () => upsertCinematicActorInitialPlacement(
          project,
          cinematicId: 'cinematic_intro',
          placement: CinematicActorInitialPlacement(
            actorId: 'actor_missing',
            kind: CinematicActorInitialPlacementKind.unset,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => upsertCinematicActorInitialPlacement(
          project,
          cinematicId: 'cinematic_intro',
          placement: CinematicActorInitialPlacement(
            actorId: 'actor_professor',
            kind: CinematicActorInitialPlacementKind.fromMovementTarget,
            targetId: 'target_missing',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => upsertCinematicMovementTargetBinding(
          project,
          cinematicId: 'cinematic_intro',
          binding: CinematicMovementTargetBinding(
            targetId: 'target_missing',
            kind: CinematicMovementTargetBindingKind.abstractPoint,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('transitions target bindings and prevents zombie sourceId values', () {
      final project = _project(
        cinematics: [
          CinematicAsset(
            id: 'cinematic_intro',
            title: 'Intro cinematic',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
            ],
            movementTargets: [
              CinematicMovementTargetRef(
                targetId: 'target_center',
                label: 'Centre scene',
              ),
            ],
            timeline: CinematicTimeline(),
          ),
        ],
      );

      // 1. Set to stagePoint target binding
      final step1 = upsertCinematicMovementTargetBinding(
        project,
        cinematicId: 'cinematic_intro',
        binding: CinematicMovementTargetBinding(
          targetId: 'target_center',
          kind: CinematicMovementTargetBindingKind.stagePoint,
          sourceId: 'point_1',
        ),
      );
      expect(
        step1.cinematic.stageContext?.movementTargetBindings.single.kind,
        CinematicMovementTargetBindingKind.stagePoint,
      );
      expect(
        step1.cinematic.stageContext?.movementTargetBindings.single.sourceId,
        'point_1',
      );

      // 2. Transition stagePoint -> abstractPoint (directly)
      final step2 = upsertCinematicMovementTargetBinding(
        step1.updatedProject,
        cinematicId: 'cinematic_intro',
        binding: CinematicMovementTargetBinding(
          targetId: 'target_center',
          kind: CinematicMovementTargetBindingKind.abstractPoint,
        ),
      );
      expect(
        step2.cinematic.stageContext?.movementTargetBindings.single.kind,
        CinematicMovementTargetBindingKind.abstractPoint,
      );
      expect(
        step2.cinematic.stageContext?.movementTargetBindings.single.sourceId,
        isNull,
      );

      // 3. Transition back to stagePoint to prepare next test
      final step3 = upsertCinematicMovementTargetBinding(
        step2.updatedProject,
        cinematicId: 'cinematic_intro',
        binding: CinematicMovementTargetBinding(
          targetId: 'target_center',
          kind: CinematicMovementTargetBindingKind.stagePoint,
          sourceId: 'point_2',
        ),
      );
      expect(
        step3.cinematic.stageContext?.movementTargetBindings.single.kind,
        CinematicMovementTargetBindingKind.stagePoint,
      );
      expect(
        step3.cinematic.stageContext?.movementTargetBindings.single.sourceId,
        'point_2',
      );

      // 4. Transition stagePoint -> mapEntity (directly)
      final step4 = upsertCinematicMovementTargetBinding(
        step3.updatedProject,
        cinematicId: 'cinematic_intro',
        binding: CinematicMovementTargetBinding(
          targetId: 'target_center',
          kind: CinematicMovementTargetBindingKind.mapEntity,
          sourceId: 'entity_pnj',
        ),
      );
      expect(
        step4.cinematic.stageContext?.movementTargetBindings.single.kind,
        CinematicMovementTargetBindingKind.mapEntity,
      );
      expect(
        step4.cinematic.stageContext?.movementTargetBindings.single.sourceId,
        'entity_pnj',
      );

      // 5. Transition back to stagePoint
      final step5 = upsertCinematicMovementTargetBinding(
        step4.updatedProject,
        cinematicId: 'cinematic_intro',
        binding: CinematicMovementTargetBinding(
          targetId: 'target_center',
          kind: CinematicMovementTargetBindingKind.stagePoint,
          sourceId: 'point_3',
        ),
      );
      expect(
        step5.cinematic.stageContext?.movementTargetBindings.single.kind,
        CinematicMovementTargetBindingKind.stagePoint,
      );
      expect(
        step5.cinematic.stageContext?.movementTargetBindings.single.sourceId,
        'point_3',
      );

      // 6. Transition stagePoint -> mapEvent (directly)
      final step6 = upsertCinematicMovementTargetBinding(
        step5.updatedProject,
        cinematicId: 'cinematic_intro',
        binding: CinematicMovementTargetBinding(
          targetId: 'target_center',
          kind: CinematicMovementTargetBindingKind.mapEvent,
          sourceId: 'event_trigger',
        ),
      );
      expect(
        step6.cinematic.stageContext?.movementTargetBindings.single.kind,
        CinematicMovementTargetBindingKind.mapEvent,
      );
      expect(
        step6.cinematic.stageContext?.movementTargetBindings.single.sourceId,
        'event_trigger',
      );

      // 7. Transition back to stagePoint
      final step7 = upsertCinematicMovementTargetBinding(
        step6.updatedProject,
        cinematicId: 'cinematic_intro',
        binding: CinematicMovementTargetBinding(
          targetId: 'target_center',
          kind: CinematicMovementTargetBindingKind.stagePoint,
          sourceId: 'point_4',
        ),
      );

      // 8. Clear/reset the stagePoint target binding (removing it)
      final step8 = removeCinematicMovementTargetBinding(
        step7.updatedProject,
        cinematicId: 'cinematic_intro',
        targetId: 'target_center',
      );
      expect(step8.cinematic.stageContext?.movementTargetBindings, isEmpty);
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

    test('V1-131 adds camera focus blocks with typed target bindings', () {
      var project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(
                actorId: 'actor_professor',
                label: 'Professor',
              ),
            ],
            stageContext: CinematicStageContext(
              stagePoints: [
                CinematicStagePoint(
                  id: 'point_gate',
                  label: 'Port',
                  x: 4,
                  y: 6,
                ),
              ],
            ),
            timeline: CinematicTimeline(),
          ),
        ],
      );

      final sceneCenter = addCinematicTimelineCameraFocusStep(
        project,
        cinematicId: 'cinematic_intro',
        target: CinematicCameraTargetBinding.sceneCenter(),
        zoomPreset: CinematicCameraZoomPreset.medium,
      );
      project = sceneCenter.updatedProject;
      final actor = addCinematicTimelineCameraFocusStep(
        project,
        cinematicId: 'cinematic_intro',
        target: CinematicCameraTargetBinding.actor(
          actorId: 'actor_professor',
          label: 'Professor',
        ),
        zoomPreset: CinematicCameraZoomPreset.close,
      );
      project = actor.updatedProject;
      final stagePoint = addCinematicTimelineCameraFocusStep(
        project,
        cinematicId: 'cinematic_intro',
        target: CinematicCameraTargetBinding.stagePoint(
          stagePointId: 'point_gate',
          label: 'Port',
        ),
        zoomPreset: CinematicCameraZoomPreset.wide,
      );

      expect(sceneCenter.step.kind, CinematicTimelineStepKind.camera);
      expect(sceneCenter.step.durationMs,
          cinematicTimelineDefaultCameraDurationMs);
      expect(cinematicTimelineCameraModeOf(sceneCenter.step),
          CinematicTimelineCameraMode.focus);
      expect(
        cinematicTimelineCameraFocusBindingOf(sceneCenter.step),
        CinematicTimelineCameraFocusBinding(
          target: CinematicCameraTargetBinding.sceneCenter(),
          zoomPreset: CinematicCameraZoomPreset.medium,
        ),
      );
      expect(
        sceneCenter.step.metadata,
        isNot(contains(cinematicTimelineCameraTargetActorIdMetadataKey)),
      );
      expect(
        sceneCenter.step.metadata,
        isNot(contains(cinematicTimelineCameraTargetStagePointIdMetadataKey)),
      );

      expect(
        cinematicTimelineCameraFocusBindingOf(actor.step),
        CinematicTimelineCameraFocusBinding(
          target: CinematicCameraTargetBinding.actor(
            actorId: 'actor_professor',
          ),
          zoomPreset: CinematicCameraZoomPreset.close,
        ),
      );
      expect(
        actor.step.metadata,
        isNot(contains(cinematicTimelineCameraTargetStagePointIdMetadataKey)),
      );

      expect(
        cinematicTimelineCameraFocusBindingOf(stagePoint.step),
        CinematicTimelineCameraFocusBinding(
          target: CinematicCameraTargetBinding.stagePoint(
            stagePointId: 'point_gate',
          ),
          zoomPreset: CinematicCameraZoomPreset.wide,
        ),
      );
      expect(
        stagePoint.step.metadata,
        isNot(contains(cinematicTimelineCameraTargetActorIdMetadataKey)),
      );
      expect(
        stagePoint.cinematic.timeline.steps.map((step) => step.id),
        ['step_camera', 'step_camera_2', 'step_camera_3'],
      );
    });

    test('V1-131 updates camera focus and cleans stale camera bindings', () {
      final actorMove = CinematicTimelineStep(
        id: 'step_actor_move',
        kind: CinematicTimelineStepKind.actorMove,
        actorId: 'actor_professor',
        targetId: 'target_center',
        durationMs: 900,
        metadata: const {
          cinematicTimelineDraftMetadataKindKey:
              cinematicTimelineBasicBlockMetadataKindValue,
          cinematicTimelineDraftMetadataSourceKey:
              cinematicTimelineDraftMetadataSourceValue,
          cinematicTimelineAuthoringBlockMetadataKey:
              cinematicTimelineActorMoveBlockMetadataValue,
          cinematicTimelineActorMovementModeMetadataKey: 'walk',
          cinematicTimelineActorPathModeMetadataKey: 'manual',
        },
      );
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(
                actorId: 'actor_professor',
                label: 'Professor',
              ),
            ],
            movementTargets: [
              CinematicMovementTargetRef(
                targetId: 'target_center',
                label: 'Centre',
              ),
            ],
            stageContext: CinematicStageContext(
              stagePoints: [
                CinematicStagePoint(
                  id: 'point_gate',
                  label: 'Port',
                  x: 4,
                  y: 6,
                ),
              ],
              manualPaths: [
                CinematicManualPath(
                  id: 'path_step_actor_move',
                  label: 'Trajet',
                  ownerActorMoveStepId: 'step_actor_move',
                  waypointStagePointIds: ['point_gate'],
                ),
              ],
            ),
            timeline: CinematicTimeline(steps: [actorMove]),
          ),
        ],
      );
      final added = addCinematicTimelineCameraFocusStep(
        project,
        cinematicId: 'cinematic_intro',
        target: CinematicCameraTargetBinding.actor(actorId: 'actor_professor'),
        zoomPreset: CinematicCameraZoomPreset.close,
      );

      final stagePointFocus = updateCinematicTimelineBasicBlockStep(
        added.updatedProject,
        cinematicId: 'cinematic_intro',
        stepId: added.step.id,
        cameraMode: CinematicTimelineCameraMode.focus,
        cameraFocusBinding: CinematicTimelineCameraFocusBinding(
          target: CinematicCameraTargetBinding.stagePoint(
            stagePointId: 'point_gate',
          ),
          zoomPreset: CinematicCameraZoomPreset.wide,
        ),
      );
      final reset = updateCinematicTimelineBasicBlockStep(
        stagePointFocus.updatedProject,
        cinematicId: 'cinematic_intro',
        stepId: added.step.id,
        cameraMode: CinematicTimelineCameraMode.reset,
      );

      expect(stagePointFocus.step.durationMs,
          cinematicTimelineDefaultCameraDurationMs);
      expect(
        stagePointFocus.step.metadata,
        containsPair(
            cinematicTimelineCameraTargetStagePointIdMetadataKey, 'point_gate'),
      );
      expect(
        stagePointFocus.step.metadata,
        isNot(contains(cinematicTimelineCameraTargetActorIdMetadataKey)),
      );
      expect(cinematicTimelineCameraFocusBindingOf(stagePointFocus.step),
          isNotNull);

      expect(cinematicTimelineCameraModeOf(reset.step),
          CinematicTimelineCameraMode.reset);
      expect(cinematicTimelineCameraFocusBindingOf(reset.step), isNull);
      expect(
        reset.step.metadata,
        isNot(contains(cinematicTimelineCameraTargetKindMetadataKey)),
      );
      expect(
        reset.step.metadata,
        isNot(contains(cinematicTimelineCameraZoomPresetMetadataKey)),
      );

      final original = project.cinematics.single;
      final updated = reset.cinematic;
      expect(updated.movementTargets, original.movementTargets);
      expect(updated.stageContext?.manualPaths,
          original.stageContext?.manualPaths);
      expect(updated.timeline.steps.first, actorMove);
    });

    test('V1-131 validates camera focus target bindings', () {
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
            ],
            stageContext: CinematicStageContext(
              stagePoints: [
                CinematicStagePoint(
                    id: 'point_gate', label: 'Port', x: 1, y: 2),
              ],
            ),
            timeline: CinematicTimeline(),
          ),
        ],
      );

      expect(
        () => addCinematicTimelineBasicBlockStep(
          project,
          cinematicId: 'cinematic_intro',
          blockKind: CinematicTimelineBasicBlockKind.camera,
          cameraMode: CinematicTimelineCameraMode.focus,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => addCinematicTimelineCameraFocusStep(
          project,
          cinematicId: 'cinematic_intro',
          target: CinematicCameraTargetBinding.actor(actorId: 'actor_missing'),
          zoomPreset: CinematicCameraZoomPreset.medium,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => addCinematicTimelineCameraFocusStep(
          project,
          cinematicId: 'cinematic_intro',
          target: CinematicCameraTargetBinding.stagePoint(
            stagePointId: 'point_missing',
          ),
          zoomPreset: CinematicCameraZoomPreset.medium,
        ),
        throwsA(isA<ArgumentError>()),
      );
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
          durationMs: 99,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => updateCinematicTimelineBasicBlockStep(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: added.step.id,
          durationMs: 30001,
        ),
        throwsA(isA<ArgumentError>()),
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

    test('validateCinematicTimelineDurationMs rejects non integer durations',
        () {
      expect(
        () => validateCinematicTimelineDurationMs(
          double.nan,
          argumentName: 'durationMs',
          minMs: cinematicTimelineMinimumDurationMs,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => validateCinematicTimelineDurationMs(
          double.infinity,
          argumentName: 'durationMs',
          minMs: cinematicTimelineMinimumDurationMs,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => validateCinematicTimelineDurationMs(
          250.5,
          argumentName: 'durationMs',
          minMs: cinematicTimelineMinimumDurationMs,
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

    test('addCinematicTimelineActorMoveStep creates a bounded actorMove block',
        () {
      final cinematic = _cinematic(
        id: 'cinematic_intro',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
        ],
        movementTargets: [
          CinematicMovementTargetRef(
            targetId: 'target_center',
            label: 'Centre scène',
          ),
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

      final result = addCinematicTimelineActorMoveStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
        targetId: 'target_center',
        durationMs: 1500,
        movementMode: CinematicTimelineActorMovementMode.run,
        afterStepId: 'step_wait',
      );

      expect(project.cinematics.single.timeline.steps, hasLength(1));
      expect(result.step.id, 'step_actor_move');
      expect(result.step.kind, CinematicTimelineStepKind.actorMove);
      expect(result.step.label, 'Déplacement Professor');
      expect(result.step.actorId, 'actor_professor');
      expect(result.step.targetId, 'target_center');
      expect(result.step.durationMs, 1500);
      expect(result.step.dialogueText, isNull);
      expect(result.step.assetRef, isNull);
      expect(
          result.step.metadata, containsPair('authoring.block', 'actorMove'));
      expect(result.step.metadata, containsPair('actor.movementMode', 'run'));
      expect(result.step.metadata, containsPair('actor.pathMode', 'direct'));
      expect(isCinematicTimelineActorMoveStep(result.step), isTrue);
      expect(isCinematicTimelineAuthoringStep(result.step), isTrue);
      expect(
        cinematicTimelineActorMovementModeOf(result.step),
        CinematicTimelineActorMovementMode.run,
      );
      expect(
        cinematicTimelineActorPathModeOf(result.step),
        CinematicTimelineActorPathMode.direct,
      );
      expect(
        result.cinematic.timeline.steps.map((step) => step.id),
        ['step_wait', 'step_actor_move'],
      );
      expect(result.updatedProject.scenes, project.scenes);
      expect(result.updatedProject.scenarios, project.scenarios);
      expect(
        () => removeCinematicMovementTarget(
          result.updatedProject,
          cinematicId: 'cinematic_intro',
          targetId: 'target_center',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addCinematicTimelineActorMoveStep validates refs and suffixes', () {
      final cinematic = CinematicAsset(
        id: 'cinematic_intro',
        title: 'Intro cinematic',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
        ],
        movementTargets: [
          CinematicMovementTargetRef(
            targetId: 'target_center',
            label: 'Centre scène',
          ),
        ],
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_actor_move',
              kind: CinematicTimelineStepKind.actorMove,
              actorId: 'actor_professor',
              targetId: 'target_center',
              durationMs: 1000,
              metadata: const {
                'authoring.source': 'cinematic-builder-v0',
                'authoring.kind': 'basicBlock',
                'authoring.block': 'actorMove',
                'actor.movementMode': 'walk',
                'actor.pathMode': 'direct',
              },
            ),
          ],
        ),
      );
      final project = _project(cinematics: [cinematic]);

      final result = addCinematicTimelineActorMoveStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
        targetId: 'target_center',
      );

      expect(result.step.id, 'step_actor_move_2');
      expect(result.step.durationMs, 1000);
      expect(result.step.metadata, containsPair('actor.movementMode', 'walk'));
      expect(
        () => addCinematicTimelineActorMoveStep(
          project,
          cinematicId: 'cinematic_intro',
          actorId: 'actor_missing',
          targetId: 'target_center',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => addCinematicTimelineActorMoveStep(
          project,
          cinematicId: 'cinematic_intro',
          actorId: 'actor_professor',
          targetId: 'target_missing',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => addCinematicTimelineActorMoveStep(
          project,
          cinematicId: 'cinematic_intro',
          actorId: 'actor_professor',
          targetId: 'target_center',
          durationMs: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('V1-126 addCinematicTimelineActorEmoteStep creates actorEmote block',
        () {
      final cinematic = _cinematic(
        id: 'cinematic_intro',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
        ],
      );
      final project = _project(cinematics: [cinematic]);

      final result = addCinematicTimelineActorEmoteStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
        emoteId: 'question',
        durationMs: 1200,
        afterStepId: 'step_wait',
      );

      expect(result.step.id, 'step_actor_emote');
      expect(result.step.kind, CinematicTimelineStepKind.actorEmote);
      expect(result.step.label, 'Professor affiche Question');
      expect(result.step.actorId, 'actor_professor');
      expect(result.step.durationMs, 1200);
      expect(result.step.targetId, isNull);
      expect(
        result.step.metadata,
        containsPair('authoring.block', 'actorEmote'),
      );
      expect(result.step.metadata, containsPair('actor.emoteId', 'question'));
      expect(cinematicTimelineActorEmoteEmoteIdOf(result.step), 'question');
      expect(isCinematicTimelineActorEmoteStep(result.step), isTrue);
      expect(isCinematicTimelineAuthoringStep(result.step), isTrue);
      expect(
        result.cinematic.timeline.steps.map((step) => step.id),
        ['step_wait', 'step_actor_emote'],
      );

      final defaultResult = addCinematicTimelineActorEmoteStep(
        result.updatedProject,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
      );
      expect(
        cinematicTimelineActorEmoteEmoteIdOf(defaultResult.step),
        cinematicDefaultActorEmoteId,
      );
      expect(defaultResult.step.durationMs,
          cinematicTimelineDefaultActorEmoteDurationMs);
      expect(defaultResult.step.id, 'step_actor_emote_2');
    });

    test(
        'V1-126 updateCinematicTimelineActorEmoteStep preserves independent ids',
        () {
      final cinematic = _cinematic(
        id: 'cinematic_intro',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
          CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
        ],
      );
      var project = _project(cinematics: [cinematic]);
      final added = addCinematicTimelineActorEmoteStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
        emoteId: 'question',
      );
      project = added.updatedProject;

      final changedActor = updateCinematicTimelineActorEmoteStep(
        project,
        cinematicId: 'cinematic_intro',
        stepId: added.step.id,
        actorId: 'actor_lysa',
      );
      expect(changedActor.step.actorId, 'actor_lysa');
      expect(
        cinematicTimelineActorEmoteEmoteIdOf(changedActor.step),
        'question',
      );

      final changedEmote = updateCinematicTimelineActorEmoteStep(
        changedActor.updatedProject,
        cinematicId: 'cinematic_intro',
        stepId: added.step.id,
        emoteId: 'heart',
      );
      expect(changedEmote.step.actorId, 'actor_lysa');
      expect(cinematicTimelineActorEmoteEmoteIdOf(changedEmote.step), 'heart');
      expect(
        changedEmote.step.durationMs,
        cinematicTimelineDefaultActorEmoteDurationMs,
      );
      expect(
        () => updateCinematicTimelineActorEmoteStep(
          changedEmote.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: added.step.id,
          emoteId: 'missing_emote',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('V1-126 actorEmote JSON roundtrip preserves actor and emote ids', () {
      final step = CinematicTimelineStep(
        id: 'step_actor_emote',
        kind: CinematicTimelineStepKind.actorEmote,
        label: 'Lysa affiche Surprise',
        actorId: 'actor_lysa',
        durationMs: 800,
        metadata: const {
          cinematicTimelineDraftMetadataSourceKey:
              cinematicTimelineDraftMetadataSourceValue,
          cinematicTimelineDraftMetadataKindKey:
              cinematicTimelineBasicBlockMetadataKindValue,
          cinematicTimelineAuthoringBlockMetadataKey:
              cinematicTimelineActorEmoteBlockMetadataValue,
          cinematicTimelineActorEmoteEmoteIdMetadataKey: 'exclamation',
        },
      );

      final roundtrip = CinematicTimelineStep.fromJson(step.toJson());

      expect(roundtrip.kind, CinematicTimelineStepKind.actorEmote);
      expect(roundtrip.actorId, 'actor_lysa');
      expect(roundtrip.durationMs, 800);
      expect(cinematicTimelineActorEmoteEmoteIdOf(roundtrip), 'exclamation');
      expect(isCinematicTimelineActorEmoteStep(roundtrip), isTrue);
    });

    test('V1-126 legacy actorEmote JSON without metadata remains readable', () {
      final decoded = CinematicTimelineStep.fromJson({
        'id': 'legacy_emote',
        'kind': 'actorEmote',
        'label': 'Ancienne émotion',
        'actorId': 'actor_legacy',
        'durationMs': 700,
      });

      expect(decoded.kind, CinematicTimelineStepKind.actorEmote);
      expect(decoded.actorId, 'actor_legacy');
      expect(decoded.durationMs, 700);
      expect(decoded.metadata, isEmpty);
      expect(isCinematicTimelineActorEmoteStep(decoded), isFalse);
      expect(cinematicTimelineActorEmoteEmoteIdOf(decoded), isNull);
    });

    test('updateCinematicTimelineActorMoveStep changes bounded parameters', () {
      var project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
            ],
            movementTargets: [
              CinematicMovementTargetRef(
                targetId: 'target_center',
                label: 'Centre scène',
              ),
              CinematicMovementTargetRef(
                targetId: 'target_exit',
                label: 'Sortie',
              ),
            ],
          ),
        ],
      );
      final added = addCinematicTimelineActorMoveStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
        targetId: 'target_center',
      );
      project = added.updatedProject;

      final result = updateCinematicTimelineActorMoveStep(
        project,
        cinematicId: 'cinematic_intro',
        stepId: added.step.id,
        actorId: 'actor_rival',
        targetId: 'target_exit',
        durationMs: 2000,
        movementMode: CinematicTimelineActorMovementMode.run,
      );

      expect(result.step.id, added.step.id);
      expect(result.step.kind, CinematicTimelineStepKind.actorMove);
      expect(result.step.label, 'Déplacement Rival');
      expect(result.step.actorId, 'actor_rival');
      expect(result.step.targetId, 'target_exit');
      expect(result.step.durationMs, 2000);
      expect(result.step.metadata, containsPair('actor.movementMode', 'run'));
      expect(result.step.metadata, containsPair('actor.pathMode', 'direct'));
      expect(project.cinematics.single.timeline.steps.last.actorId,
          'actor_professor');
    });

    test('updateCinematicTimelineActorMoveStep refuses invalid updates', () {
      final project = _project(
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
            ],
            movementTargets: [
              CinematicMovementTargetRef(
                targetId: 'target_center',
                label: 'Centre scène',
              ),
            ],
          ),
        ],
      );
      final added = addCinematicTimelineActorMoveStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
        targetId: 'target_center',
      );

      expect(
        () => updateCinematicTimelineActorMoveStep(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: added.step.id,
          actorId: 'actor_missing',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => updateCinematicTimelineActorMoveStep(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: added.step.id,
          targetId: 'target_missing',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => updateCinematicTimelineActorMoveStep(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: added.step.id,
          durationMs: 199,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => updateCinematicTimelineActorMoveStep(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: added.step.id,
          durationMs: 30001,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => updateCinematicTimelineActorMoveStep(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: added.step.id,
          durationMs: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => updateCinematicTimelineActorMoveStep(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: 'step_wait',
          movementMode: CinematicTimelineActorMovementMode.run,
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
        durationMs: 750,
      );

      expect(result.step.id, added.step.id);
      expect(result.step.kind, CinematicTimelineStepKind.actorFace);
      expect(result.step.label, 'Orientation Rival');
      expect(result.step.actorId, 'actor_rival');
      expect(result.step.durationMs, 750);
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
          durationMs: 99,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => updateCinematicTimelineActorFacingStep(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: added.step.id,
          durationMs: 30001,
        ),
        throwsA(isA<ArgumentError>()),
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

    test(
        'removeCinematicTimelineAuthoringStep removes drafts and authoring blocks',
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
      final target = addCinematicMovementTarget(
        project,
        cinematicId: 'cinematic_intro',
        label: 'Target',
      );
      project = target.updatedProject;
      final actorFace = addCinematicTimelineActorFacingStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: actor.actor.actorId,
        direction: CinematicTimelineActorFacingDirection.down,
      );
      project = actorFace.updatedProject;
      final actorMove = addCinematicTimelineActorMoveStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: actor.actor.actorId,
        targetId: target.target.targetId,
      );
      project = actorMove.updatedProject;

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
      final removedActorMove = removeCinematicTimelineAuthoringStep(
        removedActorFace.updatedProject,
        cinematicId: 'cinematic_intro',
        stepId: actorMove.step.id,
      );
      final removedDraft = removeCinematicTimelineAuthoringStep(
        removedActorMove.updatedProject,
        cinematicId: 'cinematic_intro',
        stepId: draft.step.id,
      );

      expect(removedWait.removedStep.id, wait.step.id);
      expect(removedActorFace.removedStep.id, actorFace.step.id);
      expect(removedActorMove.removedStep.id, actorMove.step.id);
      expect(removedDraft.removedStep.id, draft.step.id);
      expect(
        removedDraft.cinematic.timeline.steps.map((step) => step.id),
        ['step_wait'],
      );
      expect(project.cinematics.single.timeline.steps, hasLength(5));
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

    test('adds a stage point through pure authoring operation', () {
      final project = _project(cinematics: [_cinematic(id: 'cinematic_intro')]);
      final point = CinematicStagePoint(
        id: 'point_a',
        label: 'Point A',
        x: 10.5,
        y: 20.0,
      );

      final result = addCinematicStagePoint(
        project,
        cinematicId: 'cinematic_intro',
        point: point,
      );

      expect(project.cinematics.single.stageContext?.stagePoints, isNull);
      expect(result.cinematic.stageContext?.stagePoints, [point]);
      expect(result.updatedProject.cinematics.single.stageContext?.stagePoints,
          [point]);
    });

    test('updates a stage point through pure authoring operation', () {
      final initialPoint = CinematicStagePoint(
        id: 'point_a',
        label: 'Point A',
        x: 10.5,
        y: 20.0,
      );
      final project = _project(
        cinematics: [
          CinematicAsset(
            id: 'cinematic_intro',
            title: 'Intro',
            stageContext: CinematicStageContext(
              stagePoints: [initialPoint],
            ),
            timeline: CinematicTimeline(),
          ),
        ],
      );
      final updatedPoint = CinematicStagePoint(
        id: 'point_a',
        label: 'Updated A',
        x: 15.0,
        y: 25.5,
        description: 'New desc',
      );

      final result = updateCinematicStagePoint(
        project,
        cinematicId: 'cinematic_intro',
        point: updatedPoint,
      );

      expect(
          project.cinematics.single.stageContext?.stagePoints, [initialPoint]);
      expect(result.cinematic.stageContext?.stagePoints, [updatedPoint]);
    });

    test('removes a stage point through pure authoring operation', () {
      final pointA =
          CinematicStagePoint(id: 'point_a', label: 'Point A', x: 1, y: 1);
      final pointB =
          CinematicStagePoint(id: 'point_b', label: 'Point B', x: 2, y: 2);
      final project = _project(
        cinematics: [
          CinematicAsset(
            id: 'cinematic_intro',
            title: 'Intro',
            stageContext: CinematicStageContext(
              stagePoints: [pointA, pointB],
            ),
            timeline: CinematicTimeline(),
          ),
        ],
      );

      final result = removeCinematicStagePoint(
        project,
        cinematicId: 'cinematic_intro',
        stagePointId: 'point_a',
      );

      expect(project.cinematics.single.stageContext?.stagePoints,
          [pointA, pointB]);
      expect(result.cinematic.stageContext?.stagePoints, [pointB]);
    });

    test(
        'authoring operations reject duplicate ids, empty labels, non-finite coordinates',
        () {
      final project = _project(
        cinematics: [
          CinematicAsset(
            id: 'cinematic_intro',
            title: 'Intro',
            stageContext: CinematicStageContext(
              stagePoints: [
                CinematicStagePoint(
                    id: 'point_a', label: 'Point A', x: 1, y: 1),
              ],
            ),
            timeline: CinematicTimeline(),
          ),
        ],
      );

      expect(
        () => addCinematicStagePoint(
          project,
          cinematicId: 'cinematic_intro',
          point: CinematicStagePoint(id: 'point_a', label: 'Other', x: 2, y: 2),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => addCinematicStagePoint(
          project,
          cinematicId: 'cinematic_intro',
          point: CinematicStagePoint(id: ' ', label: 'Valid', x: 2, y: 2),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => addCinematicStagePoint(
          project,
          cinematicId: 'cinematic_intro',
          point: CinematicStagePoint(id: 'point_b', label: ' ', x: 2, y: 2),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => addCinematicStagePoint(
          project,
          cinematicId: 'cinematic_intro',
          point: CinematicStagePoint(
              id: 'point_b', label: 'Valid', x: double.nan, y: 2),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    group('manual paths', () {
      final pointA =
          CinematicStagePoint(id: 'point_a', label: 'Point A', x: 1, y: 1);
      final pointB =
          CinematicStagePoint(id: 'point_b', label: 'Point B', x: 2, y: 2);
      final waitStep = CinematicTimelineStep(
        id: 'step_wait',
        kind: CinematicTimelineStepKind.wait,
        durationMs: 100,
      );
      final actorMoveStep = CinematicTimelineStep(
        id: 'step_actor_move',
        kind: CinematicTimelineStepKind.actorMove,
        actorId: 'actor_professor',
        targetId: 'target_center',
        durationMs: 1000,
        metadata: const {
          'authoring.source': 'cinematic-builder-v0',
          'authoring.kind': 'basicBlock',
          'authoring.block': 'actorMove',
          'actor.movementMode': 'walk',
          'actor.pathMode': 'direct',
        },
      );

      CinematicAsset createTestAsset() {
        return CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro cinematic',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
          ],
          movementTargets: [
            CinematicMovementTargetRef(
              targetId: 'target_center',
              label: 'Centre scène',
            ),
          ],
          stageContext: CinematicStageContext(
            stagePoints: [pointA, pointB],
          ),
          timeline: CinematicTimeline(
            steps: [waitStep, actorMoveStep],
          ),
        );
      }

      test(
          'addCinematicManualPathForActorMove creates path and sets mode to manual',
          () {
        var project = _project(cinematics: [createTestAsset()]);
        final result = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
          label: 'Jean manual path',
          description: 'A description',
          waypointStagePointIds: ['point_a', 'point_b'],
        );

        final updatedCinematic = result.cinematic;
        final context = updatedCinematic.stageContext!;
        expect(context.manualPaths, hasLength(1));
        final path = context.manualPaths.single;
        expect(path.label, 'Jean manual path');
        expect(path.description, 'A description');
        expect(path.ownerActorMoveStepId, 'step_actor_move');
        expect(path.waypointStagePointIds, ['point_a', 'point_b']);

        final step = updatedCinematic.timeline.steps
            .firstWhere((s) => s.id == 'step_actor_move');
        expect(cinematicTimelineActorPathModeOf(step),
            CinematicTimelineActorPathMode.manual);
      });

      test(
          'addCinematicManualPathForActorMove defaults label and generates unique ID',
          () {
        var project = _project(cinematics: [createTestAsset()]);
        final result1 = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
          waypointStagePointIds: ['point_a'],
        );

        expect(result1.cinematic.stageContext!.manualPaths.single.id, 'path');
        expect(result1.cinematic.stageContext!.manualPaths.single.label,
            'Chemin de déplacement');
      });

      test('addCinematicManualPathForActorMove validations', () {
        var project = _project(cinematics: [createTestAsset()]);

        // Non-actorMove step
        expect(
          () => addCinematicManualPathForActorMove(
            project,
            cinematicId: 'cinematic_intro',
            actorMoveStepId: 'step_wait',
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Unknown step
        expect(
          () => addCinematicManualPathForActorMove(
            project,
            cinematicId: 'cinematic_intro',
            actorMoveStepId: 'step_unknown',
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Stage point does not exist
        expect(
          () => addCinematicManualPathForActorMove(
            project,
            cinematicId: 'cinematic_intro',
            actorMoveStepId: 'step_actor_move',
            waypointStagePointIds: ['missing_point'],
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Duplicate path for step
        final firstAdded = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
        );
        expect(
          () => addCinematicManualPathForActorMove(
            firstAdded.updatedProject,
            cinematicId: 'cinematic_intro',
            actorMoveStepId: 'step_actor_move',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('updateCinematicManualPath updates path properties', () {
        var project = _project(cinematics: [createTestAsset()]);
        final added = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
          waypointStagePointIds: ['point_a'],
        );

        final pathId = added.cinematic.stageContext!.manualPaths.single.id;
        final updated = updateCinematicManualPath(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          manualPathId: pathId,
          label: 'Updated Label',
          description: 'Updated Description',
          waypointStagePointIds: ['point_b', 'point_a'],
        );

        final path = updated.cinematic.stageContext!.manualPaths.single;
        expect(path.label, 'Updated Label');
        expect(path.description, 'Updated Description');
        expect(path.waypointStagePointIds, ['point_b', 'point_a']);
      });

      test('updateCinematicManualPath validations', () {
        var project = _project(cinematics: [createTestAsset()]);
        final added = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
        );
        final pathId = added.cinematic.stageContext!.manualPaths.single.id;

        // Empty label
        expect(
          () => updateCinematicManualPath(
            added.updatedProject,
            cinematicId: 'cinematic_intro',
            manualPathId: pathId,
            label: '   ',
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Missing waypoint stage point
        expect(
          () => updateCinematicManualPath(
            added.updatedProject,
            cinematicId: 'cinematic_intro',
            manualPathId: pathId,
            waypointStagePointIds: ['missing_point'],
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Unknown manual path ID
        expect(
          () => updateCinematicManualPath(
            added.updatedProject,
            cinematicId: 'cinematic_intro',
            manualPathId: 'missing_path',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('removeCinematicManualPath removes path and resets step to direct',
          () {
        var project = _project(cinematics: [createTestAsset()]);
        final added = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
        );
        final pathId = added.cinematic.stageContext!.manualPaths.single.id;

        final removed = removeCinematicManualPath(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          manualPathId: pathId,
        );

        expect(removed.cinematic.stageContext!.manualPaths, isEmpty);
        final step = removed.cinematic.timeline.steps
            .firstWhere((s) => s.id == 'step_actor_move');
        expect(cinematicTimelineActorPathModeOf(step),
            CinematicTimelineActorPathMode.direct);
      });

      test('addCinematicManualPathWaypoint adds waypoint', () {
        var project = _project(cinematics: [createTestAsset()]);
        final added = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
          waypointStagePointIds: ['point_a'],
        );
        final pathId = added.cinematic.stageContext!.manualPaths.single.id;

        final updated = addCinematicManualPathWaypoint(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          manualPathId: pathId,
          stagePointId: 'point_b',
        );

        expect(
          updated
              .cinematic.stageContext!.manualPaths.single.waypointStagePointIds,
          ['point_a', 'point_b'],
        );
      });

      test('removeCinematicManualPathWaypointAt removes waypoint at index', () {
        var project = _project(cinematics: [createTestAsset()]);
        final added = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
          waypointStagePointIds: ['point_a', 'point_b'],
        );
        final pathId = added.cinematic.stageContext!.manualPaths.single.id;

        final updated = removeCinematicManualPathWaypointAt(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          manualPathId: pathId,
          index: 0,
        );

        expect(
          updated
              .cinematic.stageContext!.manualPaths.single.waypointStagePointIds,
          ['point_b'],
        );

        // Out of bounds
        expect(
          () => removeCinematicManualPathWaypointAt(
            updated.updatedProject,
            cinematicId: 'cinematic_intro',
            manualPathId: pathId,
            index: 5,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('reorderCinematicManualPathWaypoint reorders waypoints', () {
        var project = _project(cinematics: [createTestAsset()]);
        final added = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
          waypointStagePointIds: ['point_a', 'point_b'],
        );
        final pathId = added.cinematic.stageContext!.manualPaths.single.id;

        final updated = reorderCinematicManualPathWaypoint(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          manualPathId: pathId,
          fromIndex: 0,
          toIndex: 1,
        );

        expect(
          updated
              .cinematic.stageContext!.manualPaths.single.waypointStagePointIds,
          ['point_b', 'point_a'],
        );

        // Out of bounds
        expect(
          () => reorderCinematicManualPathWaypoint(
            updated.updatedProject,
            cinematicId: 'cinematic_intro',
            manualPathId: pathId,
            fromIndex: -1,
            toIndex: 1,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('setActorMovePathMode updates mode without affecting targets', () {
        var project = _project(cinematics: [createTestAsset()]);
        final updated = setActorMovePathMode(
          project,
          cinematicId: 'cinematic_intro',
          stepId: 'step_actor_move',
          pathMode: CinematicTimelineActorPathMode.manual,
        );

        final step = updated.cinematic.timeline.steps
            .firstWhere((s) => s.id == 'step_actor_move');
        expect(cinematicTimelineActorPathModeOf(step),
            CinematicTimelineActorPathMode.manual);
        expect(step.targetId, 'target_center'); // Preserves target
      });

      test('clearActorMoveManualPath resets step and deletes path', () {
        var project = _project(cinematics: [createTestAsset()]);
        final added = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
        );

        final cleared = clearActorMoveManualPath(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: 'step_actor_move',
        );

        expect(cleared.cinematic.stageContext!.manualPaths, isEmpty);
        final step = cleared.cinematic.timeline.steps
            .firstWhere((s) => s.id == 'step_actor_move');
        expect(cinematicTimelineActorPathModeOf(step),
            CinematicTimelineActorPathMode.direct);
      });
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
  String? mapId,
  List<CinematicActorRef> requiredActors = const [],
  List<CinematicMovementTargetRef> movementTargets = const [],
  CinematicStageContext? stageContext,
  CinematicTimeline? timeline,
  CinematicLegacyBridge? legacyBridge,
}) {
  return CinematicAsset(
    id: id,
    title: title,
    description: description,
    mapId: mapId,
    requiredActors: requiredActors,
    movementTargets: movementTargets,
    stageContext: stageContext,
    timeline: timeline ??
        CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_wait',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 100,
            ),
          ],
        ),
    legacyBridge: legacyBridge,
  );
}

CinematicAsset _cinematicWithCharacterBinding(
  String id, {
  String? mapId,
}) {
  return CinematicAsset(
    id: id,
    title: 'Intro cinematic',
    mapId: mapId,
    requiredActors: [
      CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
    ],
    stageContext: CinematicStageContext(
      actorBindings: [
        CinematicActorBinding(
          actorId: 'actor_rival',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
      ],
      actorAppearanceBindings: [
        CinematicActorAppearanceBinding(
          actorId: 'actor_rival',
          characterId: 'character_rival',
        ),
      ],
    ),
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_actor_face',
          kind: CinematicTimelineStepKind.actorFace,
          durationMs: 450,
          actorId: 'actor_rival',
          metadata: const {
            'authoring.source': 'cinematic-builder-v0',
            'authoring.kind': 'basicBlock',
            'authoring.block': 'actorFace',
            'actor.direction': 'right',
          },
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
