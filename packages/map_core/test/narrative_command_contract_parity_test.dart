import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {

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
  tilesets: const [ProjectTilesetEntry(id: 'sprites', name: 'Sprites', relativePath: 'assets/sprites.png')],
  characters: [_avatarCharacter()],
  cinematicMediaAssets: [
    CinematicMediaAsset(id: 'music', label: 'Music', kind: CinematicMediaAssetKind.music, relativePath: 'audio/music.ogg'),
    CinematicMediaAsset(id: 'door-sound', label: 'Door',
      kind: CinematicMediaAssetKind.sound, relativePath: 'assets/door.wav'),
  ],
  facts: [
    NarrativeFactDefinition(id: 'fact_gate', label: 'Gate'),
    NarrativeFactDefinition(id: 'fact_counter', label: 'Counter', initialValue: NarrativeValue.integer(0)),
    NarrativeFactDefinition(id: 'fact_name', label: 'Name', initialValue: NarrativeValue.string('')),
  ],
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
  movingProps: [MovingPropDefinition(
    id: 'gate', placedElementId: 'gate_visual',
    closedPositionPx: const PixelOffset(x: 0, y: 0),
    openPositionPx: const PixelOffset(x: 32, y: 0),
    collisionRect: const PixelRect(leftPx: 0, topPx: 0, widthPx: 16, heightPx: 16),
  )],
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
  entities: [
    MapEntity(id: 'npc_variant', kind: MapEntityKind.custom,
      pos: const GridPos(x: 1, y: 1),
      presentation: MapEntityPresentation(variants: [
        MapEntityPresentationVariant(id: 'base', characterId: 'hero', blocksMovement: true, size: const GridSize(width: 1, height: 1),
          condition: NarrativeEventConditionExpression.leaf(NarrativeEventCondition.fact('fact_gate', false))),
      ])),
    MapEntity(
      id: 'npc_sailor',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 2, y: 1),
      size: GridSize(width: 1, height: 1),
      npc: MapEntityNpcData(),
    ),
  ],
);

ProjectCharacterEntry _avatarCharacter() => ProjectCharacterEntry(
  id: 'hero', name: 'Hero', tilesetId: 'sprites',
  animations: [for (final direction in EntityFacing.values) CharacterAnimation(
    state: CharacterAnimationState.walk, direction: direction,
    frames: [const CharacterAnimationFrame(source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))],
  )],
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
