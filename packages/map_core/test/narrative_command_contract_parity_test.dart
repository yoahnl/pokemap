import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('every publishable command owns a serializable diagnostic-safe plan', () {
    final catalog = NarrativeCommandCatalog.canonical();
    final samples = _canonicalSamples();
    final project = _project();
    final mapsById = {'map_port': _map()};
    final publishableIds = {
      for (final command in catalog.publishable) command.id,
    };

    // This equality is the fail-closed part of the gate: adding a supported
    // descriptor requires proving its canonical wire in this test.
    expect(samples.keys, unorderedEquals(publishableIds));

    for (final command in catalog.publishable) {
      final spatial = command.id == NarrativeCommandIds.playModelAnimation;
      final contextProject = spatial
          ? project.copyWith(
              settings: project.settings.copyWith(
                dimension: ProjectDimension.threeD,
              ),
              models3d: [_doorModel()],
            )
          : project;
      final contextMaps = spatial
          ? {
              'map_port': _map().copyWith(
                spatialScene: MapSpatialScene(
                  width: 4,
                  depth: 4,
                  instances: [
                    SpatialModelInstance(
                      id: 'door',
                      modelId: 'door_model',
                      position: Model3dVector3(x: 1, y: 0, z: 1),
                    ),
                  ],
                ),
              ),
            }
          : mapsById;
      final payload = samples[command.id]!();
      final roundTrip = SceneNodePayload.fromJson(payload.toJson());
      final scene = _sceneFor(command.id, roundTrip);
      final diagnostics = diagnoseSceneAgainstProject(
        scene,
        contextProject,
        mapsById: contextMaps,
      );
      final plan = buildSceneRuntimePlan(scene);

      expect(roundTrip, payload, reason: command.id);
      expect(
        diagnostics.hasErrors,
        isFalse,
        reason:
            '${command.id}: '
            '${diagnostics.diagnostics.map((item) => item.code.name).join(', ')}',
      );
      expect(plan.canBuild, isTrue, reason: command.id);
      if (payload case SceneActionPayload(:final interactiveCommand?)) {
        expect(
          diagnoseInteractiveCommand(
            command: interactiveCommand,
            project: contextProject,
          ),
          isEmpty,
          reason: command.id,
        );
      }
      expect(
        plan.plan!.nodes[1].intent.kind,
        _expectedIntent(payload),
        reason: command.id,
      );
    }
  });

  test('NPC state commands are published through typed guided contracts', () {
    final catalog = NarrativeCommandCatalog.canonical();

    for (final commandId in [
      NarrativeCommandIds.setNpcPresence,
      NarrativeCommandIds.moveNpc,
    ]) {
      final descriptor = catalog.byId(commandId)!;
      expect(descriptor.isPublishable, isTrue, reason: commandId);
      expect(
        descriptor.parameters.first.kind,
        NarrativeCommandParameterKind.npc,
        reason: commandId,
      );
    }
  });

  test('static encounter diagnostics require one tagged trainer contract', () {
    final valid = _sceneFor(
      'static.valid',
      SceneBattlePayload(
        battleKind: 'static',
        trainerId: 'trainer_static',
        battleTemplateId: 'static:trainer_static',
        declaredOutcomes: const ['victory'],
      ),
    );
    final legacySpeciesOnly = _sceneFor(
      'static.missing',
      SceneBattlePayload(
        battleKind: 'static',
        battleTemplateId: 'sproutle',
        declaredOutcomes: const ['victory'],
      ),
    );
    final wrongKind = _sceneFor(
      'static.trainer',
      SceneBattlePayload(
        battleKind: 'static',
        trainerId: 'trainer_port',
        battleTemplateId: 'static:trainer_port',
        declaredOutcomes: const ['victory'],
      ),
    );

    expect(
      diagnoseSceneAgainstProject(
        valid,
        _project(),
        mapsById: {'map_port': _map()},
      ).hasErrors,
      isFalse,
    );
    expect(
      diagnoseSceneAgainstProject(
        legacySpeciesOnly,
        _project(),
        mapsById: {'map_port': _map()},
      ).byCode(SceneDiagnosticCode.battleTrainerRefUnknown),
      hasLength(1),
    );
    expect(
      diagnoseSceneAgainstProject(
        wrongKind,
        _project(),
        mapsById: {'map_port': _map()},
      ).byCode(SceneDiagnosticCode.battleTrainerRefUnknown),
      hasLength(1),
    );
  });
}

Map<String, SceneNodePayload Function()> _canonicalSamples() => {
  NarrativeCommandIds.whiteOut: () =>
      SceneActionPayload.interactive(SceneInteractiveCommand.whiteOut()),
  NarrativeCommandIds.setFact: () => SceneActionPayload.consequence(
    SceneConsequence.setFact(factId: 'fact_gate', value: true),
  ),
  NarrativeCommandIds.markEventConsumed: () => SceneActionPayload.consequence(
    SceneConsequence.markEventConsumed(
      mapId: 'map_port',
      eventId: 'event_gate',
    ),
  ),
  NarrativeCommandIds.completeStoryStep: () => SceneActionPayload.consequence(
    SceneConsequence.completeStoryStep(stepId: 'step_port'),
  ),
  NarrativeCommandIds.giveItem: () => SceneActionPayload.consequence(
    SceneConsequence.giveItem(itemId: 'potion', quantity: 1),
  ),
  NarrativeCommandIds.giveItemGift: () => SceneActionPayload.interactive(
    SceneInteractiveCommand.giveItem(itemId: 'potion', quantity: 1),
  ),
  NarrativeCommandIds.takeItem: () => SceneActionPayload.consequence(
    SceneConsequence.takeItem(itemId: 'ticket', quantity: 1),
  ),
  NarrativeCommandIds.giveMoney: () =>
      SceneActionPayload.consequence(SceneConsequence.giveMoney(amount: 200)),
  NarrativeCommandIds.givePokemonFromCatalog: () => SceneActionPayload.consequence(
    SceneConsequence.givePokemonFromCatalog(speciesId: 'fixture', formId: 'base', level: 5),
  ),
  NarrativeCommandIds.givePokemon: () => SceneActionPayload.consequence(
    SceneConsequence.givePokemon(
      speciesId: 'sproutle',
      formId: 'base',
      level: 5,
      currentHp: 18,
    ),
  ),
  NarrativeCommandIds.giveConfiguredStarter: () =>
      SceneActionPayload.consequence(
        SceneConsequence.giveConfiguredStarter(
          starterOptionId: 'starter_sproutle',
        ),
      ),
  NarrativeCommandIds.healParty: () =>
      SceneActionPayload.consequence(SceneConsequence.healParty()),
  NarrativeCommandIds.awardBadge: () => SceneActionPayload.consequence(
    SceneConsequence.awardBadge(badgeId: 'badge_tide'),
  ),
  NarrativeCommandIds.unlockFieldAbility: () => SceneActionPayload.consequence(
    SceneConsequence.unlockFieldAbility(ability: FieldAbility.surf),
  ),
  NarrativeCommandIds.finishGame: () => SceneActionPayload.consequence(
    SceneConsequence.finishGame(
      endingId: 'ending.parity',
      outcome: SceneGameCompletionOutcome.completed,
      result: SceneFinishGameResult(
        title: SceneLocalizedText(fallback: 'Fin'),
        summary: SceneLocalizedText(fallback: 'Test terminé.'),
      ),
      postGamePolicy: ScenePostGamePolicy.returnToTitle,
    ),
  ),
  NarrativeCommandIds.setNpcPresence: () => SceneActionPayload.consequence(
    SceneConsequence.setNpcPresence(
      mapId: 'map_port',
      entityId: 'npc_sailor',
      present: false,
    ),
  ),
  NarrativeCommandIds.setPauseMenuEntryVisibility: () =>
      SceneActionPayload.consequence(
        SceneConsequence.setPauseMenuEntryVisibility(
          actionId: ProjectPauseActionId.pokedex,
          visible: false,
        ),
      ),
  NarrativeCommandIds.warp: () => SceneActionPayload.interactive(
    SceneInteractiveCommand.warp(
      destinationMapId: 'map_port',
      warpId: 'warp_arrival',
    ),
  ),
  NarrativeCommandIds.openShop: () => SceneActionPayload.interactive(
    SceneInteractiveCommand.openShop(shopId: 'shop_port'),
  ),
  NarrativeCommandIds.waitForActorRoutes: () => SceneActionPayload.interactive(
    SceneInteractiveCommand.waitForActorRoutes(mapId: 'map_port'),
  ),
  NarrativeCommandIds.wait: () => SceneActionPayload.interactive(
    SceneInteractiveCommand.wait(durationMs: 400),
  ),
  NarrativeCommandIds.worldTone: () => SceneActionPayload.interactive(
    SceneInteractiveCommand.worldTone(
      red: -255, green: -254.5, blue: 0, gray: 10, durationMs: 300,
    ),
  ),
  NarrativeCommandIds.playMusicEffect: () => SceneActionPayload.interactive(
    SceneInteractiveCommand.playMusicEffect(mediaAssetId: 'door-sound', volume: .8,
      bgmInterruption: DialogueBgmInterruption(fadeOutMs: 0, fadeInMs: 200)),
  ),
  NarrativeCommandIds.playSoundEffect: () => SceneActionPayload.interactive(
    SceneInteractiveCommand.playSoundEffect(mediaAssetId: 'door-sound', volume: .8),
  ),
  NarrativeCommandIds.actorRoute: () => SceneActionPayload.interactive(
    SceneInteractiveCommand.actorRoute(target: SceneActorTarget.player(mapId: 'map_port'),
      steps: [SceneActorRouteStep.face(direction: EntityFacing.north, yieldAfter: true)]),
  ),
  NarrativeCommandIds.actorVisibility: () => SceneActionPayload.interactive(
    SceneInteractiveCommand.actorVisibility(target: SceneActorTarget.player(mapId: 'map_port'),
      visible: false),
  ),
  NarrativeCommandIds.openHeal: () =>
      SceneActionPayload.interactive(SceneInteractiveCommand.openHeal()),
  NarrativeCommandIds.openPc: () =>
      SceneActionPayload.interactive(SceneInteractiveCommand.openPc()),
  NarrativeCommandIds.movePlatform: () => SceneActionPayload.interactive(
    SceneInteractiveCommand.movePlatform(
      mapId: 'map_port',
      platformId: 'ferry',
      motion: MovingPlatformMotion.forward,
    ),
  ),
  NarrativeCommandIds.moveNpc: () => SceneActionPayload.interactive(
    SceneInteractiveCommand.moveNpc(
      mapId: 'map_port',
      entityId: 'npc_sailor',
      warpId: 'warp_arrival',
    ),
  ),
  NarrativeCommandIds.playCharacterAnimation: () =>
      SceneActionPayload.interactive(
        SceneInteractiveCommand.playCharacterAnimation(
          runtimeCommand: CharacterCustomAnimationRuntimeCommand(
            actorId: 'npc_sailor',
            definitionId: 'saluer',
            direction: EntityFacing.south,
          ),
        ),
      ),
  NarrativeCommandIds.playModelAnimation: () => SceneActionPayload.interactive(
    SceneInteractiveCommand.playModelAnimation(
      mapId: 'map_port',
      instanceId: 'door',
      animationIndex: 0,
      blocksMovementAfter: false,
    ),
  ),
  NarrativeCommandIds.railJourney: () => SceneActionPayload.interactive(
    SceneInteractiveCommand.railJourney(
      commandId: 'scene.parity.rail.begin',
      journeyId: 'T1',
      operation: SceneRailJourneyOperation.begin,
      direction: RailJourneyDirection.outbound,
      doorSide: RailJourneyDoorSide.west,
    ),
  ),
  NarrativeCommandIds.dialogue: () =>
      SceneYarnDialoguePayload(dialogueId: 'dialogue_port'),
  NarrativeCommandIds.trainerBattle: () => SceneBattlePayload(
    battleKind: 'trainer',
    trainerId: 'trainer_port',
    declaredOutcomes: const ['victory'],
  ),
  NarrativeCommandIds.staticEncounter: () => SceneBattlePayload(
    battleKind: 'static',
    trainerId: 'trainer_static',
    battleTemplateId: 'static:trainer_static',
    declaredOutcomes: const ['victory'],
  ),
  NarrativeCommandIds.cinematic: () =>
      SceneCinematicPayload(cinematicId: 'cinematic_port'),
};

SceneRuntimePlanIntentKind _expectedIntent(SceneNodePayload payload) =>
    switch (payload) {
      SceneActionPayload(:final consequence) when consequence != null =>
        SceneRuntimePlanIntentKind.applyConsequence,
      SceneActionPayload(:final interactiveCommand)
          when interactiveCommand != null =>
        SceneRuntimePlanIntentKind.executeInteractiveCommand,
      SceneYarnDialoguePayload() => SceneRuntimePlanIntentKind.showDialogue,
      SceneBattlePayload() => SceneRuntimePlanIntentKind.startBattle,
      SceneCinematicPayload() => SceneRuntimePlanIntentKind.playCinematic,
      _ => throw StateError('Unsupported parity sample ${payload.kind.name}'),
    };

SceneAsset _sceneFor(String commandId, SceneNodePayload payload) {
  final (port, edgeKind) = switch (payload) {
    SceneBattlePayload() => ('victory', SceneEdgeKind.battleVictory),
    SceneCinematicPayload() => ('completed', SceneEdgeKind.cinematicCompleted),
    SceneActionPayload(:final interactiveCommand?) => (
      interactiveCommand.outputPortIds.first,
      SceneEdgeKind.actionCompleted,
    ),
    SceneActionPayload() => ('completed', SceneEdgeKind.actionCompleted),
    _ => ('completed', SceneEdgeKind.defaultFlow),
  };
  return SceneAsset(
    id: 'scene.parity.$commandId',
    name: 'Parity $commandId',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'command', kind: payload.kind, payload: payload),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start-command',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'command',
          kind: SceneEdgeKind.defaultFlow,
        ),
        for (final outputPort in switch (payload) {
          SceneActionPayload(:final interactiveCommand?) =>
            interactiveCommand.outputPortIds,
          _ => [port],
        })
          SceneEdge(
            id: 'command-end-$outputPort',
            fromNodeId: 'command',
            fromPortId: outputPort,
            toNodeId: 'end',
            kind: edgeKind,
          ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'start', x: 0, y: 0),
        SceneNodeLayout(nodeId: 'command', x: 240, y: 0),
        SceneNodeLayout(nodeId: 'end', x: 480, y: 0),
      ],
    ),
  );
}

ProjectManifest _project() => ProjectManifest(
  name: 'Core parity',
  maps: const [
    ProjectMapEntry(
      id: 'map_port',
      name: 'Port',
      relativePath: 'maps/port.json',
    ),
  ],
  tilesets: const [],
  cinematicMediaAssets: [
    CinematicMediaAsset(id: 'door-sound', label: 'Door',
      kind: CinematicMediaAssetKind.sound, relativePath: 'assets/door.wav'),
  ],
  facts: [NarrativeFactDefinition(id: 'fact_gate', label: 'Gate')],
  dialogues: const [
    ProjectDialogueEntry(
      id: 'dialogue_port',
      name: 'Dialogue Port',
      relativePath: 'dialogues/port.yarn',
    ),
  ],
  trainers: const [
    ProjectTrainerEntry(
      id: 'trainer_port',
      name: 'Dresseur du port',
      trainerClass: 'Marin',
      team: [ProjectTrainerPokemonEntry(speciesId: 'sproutle', level: 5)],
    ),
    ProjectTrainerEntry(
      id: 'trainer_static',
      name: 'Gardien immobile',
      trainerClass: 'Rencontre',
      tags: ['static-encounter'],
      team: [ProjectTrainerPokemonEntry(speciesId: 'sproutle', level: 7)],
    ),
  ],
  cinematics: [
    CinematicAsset(
      id: 'cinematic_port',
      title: 'Port',
      mapId: 'map_port',
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'wait',
            kind: CinematicTimelineStepKind.wait,
            durationMs: 100,
          ),
        ],
      ),
    ),
  ],
  storylines: [
    StorylineAsset(
      id: 'story_port',
      type: StorylineType.main,
      status: StorylineStatus.active,
      title: 'Port',
      chapters: [
        StorylineChapter(
          id: 'chapter_port',
          title: 'Port',
          order: 0,
          steps: [StorylineStep(id: 'step_port', title: 'Port', order: 0)],
        ),
      ],
    ),
  ],
  shops: const [ShopDefinition(id: 'shop_port', label: 'Boutique du port')],
  badges: const [BadgeDefinition(id: 'badge_tide', label: 'Badge Marée')],
  newGame: const ProjectNewGameConfig(
    starterOptions: [
      ProjectStarterOption(
        id: 'starter_sproutle',
        label: 'Sproutle',
        pokemon: PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'hardy',
          abilityId: 'overgrow',
          currentHp: 20,
        ),
      ),
    ],
  ),
  railJourneyCatalog: const RailJourneyCatalog(
    journeys: <RailJourneyDefinition>[_parityJourney],
  ),
);

MapData _map() => MapData(
  id: 'map_port',
  name: 'Port',
  size: const GridSize(width: 4, height: 4),
  movingPlatforms: [
    MovingPlatformDefinition(
      id: 'ferry',
      placedElementId: 'ferry_visual',
      initialPose: MovingPlatformPose(leftPx: 0, topPx: 0, quarterTurns: 0),
      translationDistanceCells: 1,
      lattice: MovingPlatformLattice(
        widthPx: 32,
        heightPx: 32,
        originLeftPx: 0,
        originTopPx: 0,
        cellOffsetLeftPx: 0,
        cellOffsetTopPx: 0,
      ),
      variants: [
        for (var quarterTurns = 0; quarterTurns < 4; quarterTurns++)
          MovingPlatformVariant(
            elementId: 'ferry_$quarterTurns',
            anchorOffsetPx: const GridPos(x: 0, y: 0),
            supportCells: const [GridPos(x: 0, y: 0)],
            clearanceCells: const [GridPos(x: 0, y: 0)],
            rotationClearanceCells: const [GridPos(x: 0, y: 0)],
            forwardClearanceCells: const [GridPos(x: 0, y: 0)],
            backwardClearanceCells: const [GridPos(x: 0, y: 0)],
          ),
      ],
      terrainLayerIds: {'base'},
      travelCells: const [GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
    ),
  ],
  events: [
    MapEventDefinition(
      id: 'event_gate',
      position: const EventPosition(layerId: 'base', x: 1, y: 1),
      pages: const [MapEventPage(pageNumber: 0)],
    ),
  ],
  warps: const [
    MapWarp(
      id: 'warp_arrival',
      pos: GridPos(x: 1, y: 1),
      targetMapId: 'map_port',
      targetPos: GridPos(x: 2, y: 2),
    ),
  ],
  entities: const [
    MapEntity(
      id: 'npc_sailor',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 2, y: 1),
      size: GridSize(width: 1, height: 1),
      npc: MapEntityNpcData(),
    ),
  ],
);

ProjectModel3dEntry _doorModel() => ProjectModel3dEntry(
  id: 'door_model',
  name: 'Porte',
  sourceAssetId: 'door_source',
  relativePath: 'assets/models3d/door_model.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 1, y: 2, z: .2),
    ),
    meshCount: 1,
    triangleCount: 4,
    animations: [
      Model3dAnimation(index: 0, name: 'Ouvrir', durationSeconds: .2),
    ],
  ),
);

const _parityJourney = RailJourneyDefinition(
  id: 'T1',
  label: 'Parity Journey',
  origin: RailJourneyEndpoint(
    stationMapId: 'map_port',
    boardingArea: MapRect(
      pos: GridPos(x: 0, y: 0),
      size: GridSize(width: 1, height: 1),
    ),
    trainEntryPos: GridPos(x: 0, y: 0),
    stationArrivalPos: GridPos(x: 0, y: 0),
    doors: <RailJourneyEndpointDoor>[],
  ),
  destination: RailJourneyEndpoint(
    stationMapId: 'map_port',
    boardingArea: MapRect(
      pos: GridPos(x: 0, y: 0),
      size: GridSize(width: 1, height: 1),
    ),
    trainEntryPos: GridPos(x: 0, y: 0),
    stationArrivalPos: GridPos(x: 0, y: 0),
    doors: <RailJourneyEndpointDoor>[],
  ),
  vehicleMapId: 'map_port',
  vehicleVariant: RailJourneyVehicleVariant.regular,
  shellState: 'day',
  fare: RailJourneyFare(policy: RailJourneyFarePolicy.storyFree),
);
