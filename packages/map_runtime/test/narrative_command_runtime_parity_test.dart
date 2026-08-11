import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('capability truth promotes exactly the runtime parity samples', () {
    final catalog = NarrativeCommandCatalog.canonical();
    final report = ProjectCapabilityTruthReport.evaluate(
      _truthMatrix(catalog),
      requiredCapabilityIds: requiredNarrativeCommandCapabilityIds(
        catalog: catalog,
      ),
    );
    final sampledIds = <String>{
      ..._consequenceSamples().keys,
      ..._interactiveSamples().keys,
      ..._dedicatedSamples().keys,
    };

    expect(report.isPassing, isTrue, reason: report.agentMarkdown);
    expect(
      report.capabilities
          .where(
            (capability) =>
                capability.status == ProjectCapabilityTruthStatus.promoted,
          )
          .map((capability) => capability.capabilityId),
      unorderedEquals(
        sampledIds.map((id) => 'narrative.command.$id'),
      ),
    );
  });

  test('missing backend attestation fails every published command', () {
    final catalog = NarrativeCommandCatalog.canonical();
    final completeRuntime =
        buildMapRuntimeNarrativeCommandConsumerAttestation(catalog: catalog);
    for (final command in catalog.publishable) {
      final incompleteRuntime = ProjectCapabilityTruthAttestation(
        referencesByCapabilityId: {
          ...completeRuntime.referencesByCapabilityId,
        }..remove(command.id),
      );
      final report = ProjectCapabilityTruthReport.evaluate(
        _truthMatrix(
          catalog,
          runtime: incompleteRuntime,
        ),
        requiredCapabilityIds: requiredNarrativeCommandCapabilityIds(
          catalog: catalog,
        ),
      );

      expect(report.isPassing, isFalse, reason: command.id);
      expect(
        report.issues.any(
          (issue) =>
              issue.capabilityId == narrativeCommandCapabilityId(command.id) &&
              issue.code ==
                  ProjectCapabilityTruthIssueCode.missingRuntimeConsumer,
        ),
        isTrue,
        reason: command.id,
      );
    }
  });

  test('player-surface attestation resolves to the playable game host', () {
    final catalog = NarrativeCommandCatalog.canonical();
    final consumers =
        buildMapRuntimeNarrativeCommandConsumerAttestation(catalog: catalog);
    final surfaces = buildMapRuntimeNarrativeCommandPlayerSurfaceAttestation(
      catalog: catalog,
    );

    expect(
      surfaces.referencesByCapabilityId.keys,
      unorderedEquals(catalog.publishable.map((command) => command.id)),
    );
    expect(
      surfaces.referencesByCapabilityId.values,
      everyElement(endsWith('playable_map_game.dart#PlayableMapGame')),
    );
    for (final command in catalog.publishable) {
      expect(
        surfaces.referenceFor(command.id),
        isNot(consumers.referenceFor(command.id)),
        reason: command.id,
      );
    }
  });

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
      moveNpc: handler,
      openShop: handler,
      openHeal: handler,
      openPc: handler,
      playCharacterAnimation: handler,
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
    final launchedBattles = <SceneBattleRuntimeBattleRequest>[];
    String complete(SceneRuntimePlanIntent intent) {
      invoked.add(intent.kind);
      return 'completed';
    }

    final battleAdapter = SceneBattleRuntimeOutcomeAdapter(
      runtimeSourceId: 'runtime-parity',
      defaultNpcEntityId: 'npc_runtime_parity',
      createdAtEpochMs: () => 1234,
      launcher: _ParityBattleLauncher((request) async {
        launchedBattles.add(request);
        return const SceneBattleRuntimeOutcomeResult.completed(
          port: SceneBattleRuntimeOutcomePort.victory,
        );
      }),
    );

    final callbacks = SceneRuntimeHostCallbacks(
      evaluateCondition: complete,
      showDialogue: complete,
      startBattle: (intent) async {
        invoked.add(intent.kind);
        final result = await battleAdapter.startBattle(intent);
        return result.scenePortId ?? 'failed';
      },
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
    expect(launchedBattles, hasLength(2));
    final staticRequest = launchedBattles.singleWhere(
      (request) => request.battleKind == 'static',
    );
    expect(staticRequest.trainerId, 'trainer_static');
    expect(staticRequest.battleTemplateId, 'battle_lighthouse_pokemon');
  });

  test('runtime parity covers both canonical NPC state commands', () {
    final catalog = NarrativeCommandCatalog.canonical();

    expect(catalog.byId(NarrativeCommandIds.setNpcPresence)!.isPublishable,
        isTrue);
    expect(catalog.byId(NarrativeCommandIds.moveNpc)!.isPublishable, isTrue);
    expect(_consequenceSamples(), contains(NarrativeCommandIds.setNpcPresence));
    expect(_interactiveSamples(), contains(NarrativeCommandIds.moveNpc));
  });
}

List<ProjectCapabilityTruthRecord> _truthMatrix(
  NarrativeCommandCatalog catalog, {
  ProjectCapabilityTruthAttestation? runtime,
}) {
  final authoring = ProjectCapabilityTruthAttestation(
    referencesByCapabilityId: {
      for (final command in catalog.publishable)
        command.id: 'packages/map_editor/lib/src/ui/canvas/scenes/'
            'scene_action_builder.dart#SceneActionBuilder',
    },
  );
  final positiveTests = ProjectCapabilityTruthAttestation(
    referencesByCapabilityId: {
      for (final command in catalog.publishable)
        command.id: 'packages/map_runtime/test/'
            'narrative_command_runtime_parity_test.dart#'
            '${_positiveProofName(command.backend)}',
    },
  );
  final negativeTests = ProjectCapabilityTruthAttestation(
    referencesByCapabilityId: {
      for (final command in catalog.publishable)
        command.id: 'packages/map_runtime/test/'
            'narrative_command_runtime_parity_test.dart#'
            'missing backend attestation fails every published command',
    },
  );
  return buildNarrativeCommandCapabilityTruthMatrix(
    catalog: catalog,
    authoring: authoring,
    runtime: runtime ??
        buildMapRuntimeNarrativeCommandConsumerAttestation(catalog: catalog),
    playerSurface: buildMapRuntimeNarrativeCommandPlayerSurfaceAttestation(
      catalog: catalog,
    ),
    positiveTests: positiveTests,
    negativeTests: negativeTests,
  );
}

String _positiveProofName(NarrativeCommandBackend backend) => switch (backend) {
      NarrativeCommandBackend.sceneConsequence =>
        'every supported consequence reaches an atomic runtime writer',
      NarrativeCommandBackend.interactiveRuntimeCommand =>
        'every supported interactive command returns a declared output port',
      NarrativeCommandBackend.dedicatedSceneNode =>
        'every supported dedicated node reaches a runtime host callback',
    };

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
      NarrativeCommandIds.finishGame: () => SceneConsequence.finishGame(
            endingId: 'ending.parity',
            outcome: SceneGameCompletionOutcome.completed,
            result: SceneFinishGameResult(
              title: SceneLocalizedText(fallback: 'Fin'),
              summary: SceneLocalizedText(fallback: 'Test terminé.'),
            ),
            postGamePolicy: ScenePostGamePolicy.returnToTitle,
          ),
      NarrativeCommandIds.setNpcPresence: () => SceneConsequence.setNpcPresence(
            mapId: 'map_test',
            entityId: 'npc_guide',
            present: false,
          ),
    };

Map<String, SceneInteractiveCommand Function()> _interactiveSamples() => {
      NarrativeCommandIds.warp: () => SceneInteractiveCommand.warp(
            destinationMapId: 'map_test',
            warpId: 'warp_arrival',
          ),
      NarrativeCommandIds.moveNpc: () => SceneInteractiveCommand.moveNpc(
            mapId: 'map_test',
            entityId: 'npc_guide',
            warpId: 'warp_arrival',
          ),
      NarrativeCommandIds.openShop: () =>
          SceneInteractiveCommand.openShop(shopId: 'shop_port'),
      NarrativeCommandIds.openHeal: SceneInteractiveCommand.openHeal,
      NarrativeCommandIds.openPc: SceneInteractiveCommand.openPc,
      NarrativeCommandIds.playCharacterAnimation: () =>
          SceneInteractiveCommand.playCharacterAnimation(
            runtimeCommand: CharacterCustomAnimationRuntimeCommand(
              actorId: 'npc_guide',
              definitionId: 'saluer',
              direction: EntityFacing.south,
            ),
          ),
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
            trainerId: 'trainer_static',
            battleTemplateId: 'battle_lighthouse_pokemon',
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
          BagEntry(itemId: 'ticket', quantity: 2),
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
      warps: [
        MapWarp(
          id: 'warp_arrival',
          pos: GridPos(x: 2, y: 2),
          targetMapId: 'map_test',
          targetPos: GridPos(x: 2, y: 2),
        ),
      ],
      entities: [
        MapEntity(
          id: 'npc_guide',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 2),
          npc: MapEntityNpcData(),
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

final class _ParityBattleLauncher implements SceneBattleRuntimeLauncher {
  const _ParityBattleLauncher(this._launch);

  final Future<SceneBattleRuntimeOutcomeResult> Function(
    SceneBattleRuntimeBattleRequest request,
  ) _launch;

  @override
  Future<SceneBattleRuntimeOutcomeResult> startTrainerBattle(
    SceneBattleRuntimeBattleRequest request,
  ) async {
    return _launch(request);
  }
}
