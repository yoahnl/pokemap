import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('every supported consequence reaches an atomic runtime writer', () {
    final catalog = NarrativeCommandCatalog.canonical();
    final samples = _consequenceSamples();
    final declaredIds = {
      for (final command in catalog.publishable)
        if (command.backend == NarrativeCommandBackend.sceneConsequence)
          command.id,
    };
    final writer = SceneConsequenceRuntimeWriter(
      project: _project(),
      mapsById: {'map_test': _map()},
      maxHpByPartyIndex: const {0: 20},
      maxPpByPartyIndex: const {
        0: {'tackle': 35},
      },
    );

    // Adding a supported descriptor without a real writer sample must fail.
    expect(samples.keys, unorderedEquals(declaredIds));
    for (final entry in samples.entries) {
      final result = writer.applyOne(_gameState(), entry.value());
      expect(result.success, isTrue, reason: entry.key);
      expect(result.appliedConsequences, hasLength(1), reason: entry.key);
    }
  });

  test('every supported interactive command returns a declared output port',
      () async {
    final catalog = NarrativeCommandCatalog.canonical();
    final samples = _interactiveSamples();
    final declaredIds = {
      for (final command in catalog.publishable)
        if (command.backend ==
            NarrativeCommandBackend.interactiveRuntimeCommand)
          command.id,
    };
    final calls = <SceneInteractiveCommandKind>[];
    Future<String> handler(SceneInteractiveCommand command) async {
      calls.add(command.kind);
      return 'completed';
    }

    final executor = SceneInteractiveCommandRuntimeExecutor(
      warp: handler,
      openShop: handler,
      openPc: handler,
    );

    expect(samples.keys, unorderedEquals(declaredIds));
    for (final entry in samples.entries) {
      final command = entry.value();
      final output = await executor.execute(
        SceneRuntimePlanIntent.executeInteractiveCommand(command: command),
      );
      expect(command.outputPortIds, contains(output), reason: entry.key);
    }
    expect(calls, SceneInteractiveCommandKind.values);
  });

  test('every supported dedicated node reaches a runtime host callback',
      () async {
    final catalog = NarrativeCommandCatalog.canonical();
    final samples = _dedicatedSamples();
    final declaredIds = {
      for (final command in catalog.publishable)
        if (command.backend == NarrativeCommandBackend.dedicatedSceneNode)
          command.id,
    };
    final invoked = <SceneRuntimePlanIntentKind>[];
    String complete(SceneRuntimePlanIntent intent) {
      invoked.add(intent.kind);
      return switch (intent.kind) {
        SceneRuntimePlanIntentKind.startBattle => 'victory',
        _ => 'completed',
      };
    }

    final callbacks = SceneRuntimeHostCallbacks(
      evaluateCondition: complete,
      showDialogue: complete,
      startBattle: complete,
      playCinematic: complete,
    ).toExecutionCallbacks(applyConsequence: (_) => 'completed');

    expect(samples.keys, unorderedEquals(declaredIds));
    for (final entry in samples.entries) {
      final plan = buildSceneRuntimePlan(_sceneFor(entry.key, entry.value()));
      expect(plan.canBuild, isTrue, reason: entry.key);
      final result = await SceneRuntimeExecutor(callbacks: callbacks).execute(
        plan.plan!,
      );
      expect(
        result.status,
        SceneRuntimeExecutionStatus.completed,
        reason: entry.key,
      );
    }
    expect(
      invoked,
      containsAll([
        SceneRuntimePlanIntentKind.showDialogue,
        SceneRuntimePlanIntentKind.startBattle,
        SceneRuntimePlanIntentKind.playCinematic,
      ]),
    );
  });

  test('runtime parity excludes the deferred NPC presence pseudo-command', () {
    final descriptor = NarrativeCommandCatalog.canonical().byId(
      NarrativeCommandIds.setNpcPresence,
    )!;

    expect(descriptor.isPublishable, isFalse);
    expect(
      descriptor.capabilities.runtime,
      NarrativeCommandCapabilityStatus.unsupported,
    );
  });
}

Map<String, SceneConsequence Function()> _consequenceSamples() => {
      NarrativeCommandIds.setFact: () =>
          SceneConsequence.setFact(factId: 'fact_gate', value: true),
      NarrativeCommandIds.markEventConsumed: () =>
          SceneConsequence.markEventConsumed(
            mapId: 'map_test',
            eventId: 'event_gate',
          ),
      NarrativeCommandIds.completeStoryStep: () =>
          SceneConsequence.completeStoryStep(stepId: 'step_test'),
      NarrativeCommandIds.giveItem: () =>
          SceneConsequence.giveItem(itemId: 'potion', quantity: 1),
      NarrativeCommandIds.takeItem: () =>
          SceneConsequence.takeItem(itemId: 'ticket', quantity: 1),
      NarrativeCommandIds.giveMoney: () =>
          SceneConsequence.giveMoney(amount: 200),
      NarrativeCommandIds.givePokemon: () => SceneConsequence.givePokemon(
            speciesId: 'sproutle',
            level: 5,
            currentHp: 18,
          ),
      NarrativeCommandIds.giveConfiguredStarter: () =>
          SceneConsequence.giveConfiguredStarter(
            starterOptionId: 'starter_sproutle',
          ),
      NarrativeCommandIds.healParty: SceneConsequence.healParty,
      NarrativeCommandIds.awardBadge: () =>
          SceneConsequence.awardBadge(badgeId: 'badge_tide'),
      NarrativeCommandIds.unlockFieldAbility: () =>
          SceneConsequence.unlockFieldAbility(ability: FieldAbility.surf),
    };

Map<String, SceneInteractiveCommand Function()> _interactiveSamples() => {
      NarrativeCommandIds.warp: () => SceneInteractiveCommand.warp(
            destinationMapId: 'map_test',
            warpId: 'warp_arrival',
          ),
      NarrativeCommandIds.openShop: () =>
          SceneInteractiveCommand.openShop(shopId: 'shop_port'),
      NarrativeCommandIds.openPc: SceneInteractiveCommand.openPc,
    };

Map<String, SceneNodePayload Function()> _dedicatedSamples() => {
      NarrativeCommandIds.dialogue: () => SceneYarnDialoguePayload(
            dialogueId: 'dialogue_port',
          ),
      NarrativeCommandIds.trainerBattle: () => SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_port',
            declaredOutcomes: const ['victory'],
          ),
      NarrativeCommandIds.staticEncounter: () => SceneBattlePayload(
            battleKind: 'static',
            battleTemplateId: 'sproutle',
            declaredOutcomes: const ['victory'],
          ),
      NarrativeCommandIds.cinematic: () => SceneCinematicPayload(
            cinematicId: 'cinematic_port',
          ),
    };

ProjectManifest _project() => ProjectManifest(
      name: 'Runtime parity',
      maps: const [
        ProjectMapEntry(
          id: 'map_test',
          name: 'Map Test',
          relativePath: 'maps/map_test.json',
        ),
      ],
      tilesets: const [],
      facts: [
        NarrativeFactDefinition(id: 'fact_gate', label: 'Gate'),
      ],
      storylines: [
        StorylineAsset(
          id: 'story_test',
          type: StorylineType.main,
          status: StorylineStatus.active,
          title: 'Story Test',
          chapters: [
            StorylineChapter(
              id: 'chapter_test',
              title: 'Chapter',
              order: 0,
              steps: [
                StorylineStep(id: 'step_test', title: 'Step', order: 0),
              ],
            ),
          ],
        ),
      ],
      badges: const [
        BadgeDefinition(id: 'badge_tide', label: 'Badge Marée'),
      ],
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
    );

GameState _gameState() => const GameState(
      saveId: 'runtime_parity',
      trainerProfile: TrainerProfile(name: 'Leaf', money: 100),
      bag: Bag(
        entries: [
          BagEntry(itemId: 'ticket', categoryId: 'items', quantity: 2),
        ],
      ),
      party: PlayerParty(
        members: [
          PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            currentHp: 2,
            knownMoveIds: ['tackle'],
            currentPpByMoveId: {'tackle': 1},
          ),
        ],
      ),
    );

MapData _map() => const MapData(
      id: 'map_test',
      name: 'Map Test',
      size: GridSize(width: 4, height: 4),
      events: [
        MapEventDefinition(
          id: 'event_gate',
          position: EventPosition(layerId: 'base', x: 1, y: 1),
          pages: [MapEventPage(pageNumber: 0)],
        ),
      ],
    );

SceneAsset _sceneFor(String commandId, SceneNodePayload payload) {
  final (port, edgeKind) = switch (payload) {
    SceneBattlePayload() => ('victory', SceneEdgeKind.battleVictory),
    SceneCinematicPayload() => ('completed', SceneEdgeKind.cinematicCompleted),
    _ => ('completed', SceneEdgeKind.defaultFlow),
  };
  return SceneAsset(
    id: 'scene.runtime.parity.$commandId',
    name: 'Runtime parity $commandId',
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
        SceneEdge(
          id: 'command-end',
          fromNodeId: 'command',
          fromPortId: port,
          toNodeId: 'end',
          kind: edgeKind,
        ),
      ],
    ),
  );
}
