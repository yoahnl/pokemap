import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_interactive_integer.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_interactive_text_input.dart';

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
      ..._transactionalSamples().keys,
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

  test('RailJourney runtime evidence names the transactional consumer', () {
    final attestation = buildMapRuntimeNarrativeCommandConsumerAttestation();

    expect(
      attestation.referenceFor(NarrativeCommandIds.railJourney),
      endsWith(
        'rail_journey_runtime_transaction.dart#RailJourneyRuntimeTransaction',
      ),
    );
  });

  test('transactional inputs attest their actual runtime consumers', () {
    final attestation = buildMapRuntimeNarrativeCommandConsumerAttestation();
    for (final entry in {
      NarrativeCommandIds.inputIntegerToFact:
          'scene_interactive_integer.dart#inputSceneIntegerToFact',
      NarrativeCommandIds.tryPayMoney:
          'scene_interactive_integer.dart#tryScenePayMoney',
      NarrativeCommandIds.inputTextToFact:
          'scene_interactive_text_input.dart#inputSceneTextToFact',
    }.entries) {
      expect(
        attestation.referenceFor(entry.key),
        endsWith(entry.value),
        reason: entry.key,
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
      mapInstanceScopes: {'map_test': MapInstanceRef(mapId: 'map_test', instanceId: 'parity')},
      maxHpByPartyIndex: const {0: 20},
      pokemonCatalog: _pokemonCatalog(),
      maxPpByPartyIndex: const {
        0: {'tackle': 35},
      },
    );

    expect(samples.keys, unorderedEquals(declaredIds));
    for (final entry in samples.entries) {
      final consequence = entry.value();
      final result = writer.applyOne(
        _gameState(),
        consequence,
        pokemonGrantOperationId: consequence.kind ==
                    SceneConsequenceKind.givePokemon ||
                consequence.kind == SceneConsequenceKind.giveConfiguredStarter
                || consequence.kind == SceneConsequenceKind.givePokemonFromCatalog
            ? 'scene:parity:execution:${entry.key}'
            : null,
      );
      expect(result.success, isTrue, reason: entry.key);
      expect(result.appliedConsequences, hasLength(1), reason: entry.key);
    }
  });

  test('every supported interactive command returns a declared output port',
      () async {
    final catalog = NarrativeCommandCatalog.canonical();
    final samples = _interactiveSamples();
    final transactionalSamples = _transactionalSamples();
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
      wait: handler,
      waitForActorRoutes: handler,
      worldTone: handler,
      worldPresentation: handler,
      stopSoundEffects: handler,
      sceneMusic: handler,
      playSoundEffect: handler,
      playMusicEffect: handler,
      actorRoute: handler,
      actorVisibility: handler,
      giveItem: (command) async {
        calls.add(command.kind);
        return 'received';
      },
      movePlatform: (command) async {
        calls.add(command.kind);
        return 'moved';
      },
      playModelAnimation: handler,
      moveNpc: handler,
      openShop: handler,
      openHeal: handler,
      openPc: handler,
      whiteOut: handler,
      setPropState: (command) async {
        calls.add(command.kind);
        return 'moved';
      },
      openWorldService: (request) async {
        calls.add(switch (request) {
          OpenShopService() => SceneInteractiveCommandKind.openShop,
          OpenHealService() => SceneInteractiveCommandKind.openHeal,
          OpenPcService() => SceneInteractiveCommandKind.openPc,
          OpenRegionalMapService() =>
            SceneInteractiveCommandKind.openRegionalMap,
          OpenPartyTradeService() =>
            SceneInteractiveCommandKind.openPartyTrade,
          _ => throw StateError('Unexpected service ${request.kind}'),
        });
        return 'completed';
      },
      playCharacterAnimation: handler,
      railJourney: handler,
    );

    expect({
        ...samples.keys,
        ...transactionalSamples.keys,
      }, unorderedEquals(declaredIds));
    for (final entry in samples.entries) {
      final command = entry.value();
      final output = await executor.execute(
        SceneRuntimePlanIntent.executeInteractiveCommand(command: command),
      );
      expect(command.outputPortIds, contains(output), reason: entry.key);
    }
    expect(
      calls,
      samples.values.map((sample) => sample().kind),
    );
  });

  test(
    'transactional interactive commands use their real state consumers',
    () async {
      final samples = _transactionalSamples();
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(),
        pokemonCatalog: _pokemonCatalog(),
      );
      for (final entry in samples.entries) {
        final before = _gameState();
        final command = entry.value();
        final String output;
        final GameState after;
        if (command is SceneReceivePokemonFromCatalogInteractiveCommand) {
          final result = await receiveScenePokemonFromCatalog(
            command: command,
            operationId: 'parity:${entry.key}',
            project: _project(),
            readProjectedState: () => before,
            catalog: _pokemonCatalog(),
            present: (request) async => SceneInteractionResult.acknowledged(
              requestId: request.interaction.requestId,
              revision: request.interaction.revision,
            ),
          );
          output = result.outputPortId;
          after = result.prepared!.commit(
            before,
            catalog: _pokemonCatalog(),
            project: _project(),
          );
          expect(
            after.party.members,
            hasLength(before.party.members.length + 1),
          );
          expect(
            after.appliedPokemonGrantOperationIds,
            contains('parity:${entry.key}'),
    );
  } else {
          Future<SceneInteractionResult> present(
            OpenSceneTextInteractionService request,
          ) async {
            final interaction = request.interaction;
            return switch (interaction) {
              SceneIntegerInteractionRequest() =>
                SceneIntegerSubmittedInteractionResult(
                  requestId: interaction.requestId,
                  revision: interaction.revision,
                  value: 7,
                ),
              SceneTextInteractionRequest() =>
                SceneInteractionResult.textSubmitted(
                  requestId: interaction.requestId,
                  revision: interaction.revision,
                  value: 'Blue',
                ),
              SceneConfirmationInteractionRequest() =>
                SceneInteractionResult.confirmed(
                  requestId: interaction.requestId,
                  revision: interaction.revision,
                  value: true,
                ),
              _ => throw StateError('Unexpected interaction'),
            };
          }

          final ({String outputPortId, SceneConsequence? consequence}) result =
              switch (command) {
                SceneInputIntegerToFactInteractiveCommand() =>
                  await inputSceneIntegerToFact(
                    command: command,
                    operationId: 'parity:${entry.key}',
                    project: _project(),
                    readProjectedState: () => before,
                    present: present,
                  ),
                SceneTryPayMoneyInteractiveCommand() => await tryScenePayMoney(
                  command: command,
                  operationId: 'parity:${entry.key}',
                  project: _project(),
                  readProjectedState: () => before,
                  present: present,
                ),
                SceneInputTextToFactInteractiveCommand() =>
                  await inputSceneTextToFact(
                    command: command,
                    operationId: 'parity:${entry.key}',
                    project: _project(),
                    readProjectedState: () => before,
                    present: present,
                  ),
                _ => throw StateError('Unexpected transaction ${entry.key}'),
              };
          output = result.outputPortId;
          final applied = writer.applyOne(before, result.consequence!);
          expect(applied.success, isTrue, reason: entry.key);
          after = applied.gameState;
          if (command is SceneInputIntegerToFactInteractiveCommand) {
            expect(
              after.narrativeFactRuntimeState.valueFor('fact_counter'),
              NarrativeValue.integer(7),
            );
          } else if (command is SceneInputTextToFactInteractiveCommand) {
            expect(
              after.narrativeFactRuntimeState.valueFor('fact_name'),
              NarrativeValue.string('Blue'),
            );
          } else {
            expect(after.trainerProfile.money, 90);
          }
        }
        expect(command.outputPortIds, contains(output), reason: entry.key);
        expect(after, isNot(before), reason: entry.key);
        expect(before, _gameState(), reason: entry.key);
      }
    },
  );

  test('RailJourney execution fails closed when its handler is missing',
      () async {
    final executor = SceneInteractiveCommandRuntimeExecutor(
      warp: (_) async => 'completed',
    );

    await expectLater(
      executor.execute(
        SceneRuntimePlanIntent.executeInteractiveCommand(
          command: _interactiveSamples()[NarrativeCommandIds.railJourney]!(),
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('railJourney'),
        ),
      ),
    );
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
            '${_positiveProofName(command)}',
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

String _positiveProofName(NarrativeCommandDescriptor command) {
  if (_transactionalSamples().containsKey(command.id)) {
    return 'transactional interactive commands use their real state consumers';
  }
  return switch (command.backend) {
      NarrativeCommandBackend.sceneConsequence =>
        'every supported consequence reaches an atomic runtime writer',
      NarrativeCommandBackend.interactiveRuntimeCommand =>
        'every supported interactive command returns a declared output port',
      NarrativeCommandBackend.dedicatedSceneNode =>
        'every supported dedicated node reaches a runtime host callback',
    };
}

Map<String, SceneConsequence Function()> _consequenceSamples() => {
      NarrativeCommandIds.calculateIntegerFacts: () =>
          SceneConsequence.calculateIntegerFacts(
            factIds: ['fact_counter'], operation: SceneIntegerOperation.add,
            operand: SceneIntegerOperand.literal(2), minimum: 0, maximum: 100,
          ),
      NarrativeCommandIds.adjustIntegerFact: () =>
          SceneConsequence.adjustIntegerFact(
            factId: 'fact_counter', delta: 1, minimum: 0, maximum: 100,
          ),
      NarrativeCommandIds.adjustMoney: () => SceneConsequence.adjustMoney(
            operation: SceneMoneyOperation.subtract,
            amount: SceneIntegerOperand.literal(10), minimum: 0, maximum: 1000,
          ),
      NarrativeCommandIds.setMapEventInstanceBoolean: () =>
          SceneConsequence.setMapEventInstanceBoolean(
            mapId: 'map_test', eventId: 'npc_guide', key: 'A', value: true,
          ),
      NarrativeCommandIds.markPokemonSeen: () =>
          SceneConsequence.markPokemonSeen(speciesId: 'sproutle'),
      NarrativeCommandIds.setNpcPose: () => SceneConsequence.setNpcPose(
            mapId: 'map_test', entityId: 'npc_guide', facing: EntityFacing.east,
          ),
      NarrativeCommandIds.setPlayerAvatar: () =>
          SceneConsequence.setPlayerAvatar(characterId: 'hero'),
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
            formId: 'base',
            level: 5,
            currentHp: 18,
          ),
      NarrativeCommandIds.givePokemonFromCatalog: () => SceneConsequence.givePokemonFromCatalog(
        speciesId: 'sproutle', formId: 'base', level: 5,
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
      NarrativeCommandIds.setPauseMenuEntryVisibility: () =>
          SceneConsequence.setPauseMenuEntryVisibility(
            actionId: ProjectPauseActionId.pokedex,
            visible: false,
          ),
    };

Map<String, SceneInteractiveCommand Function()> _interactiveSamples() => {
      NarrativeCommandIds.worldPresentation: () =>
          SceneInteractiveCommand.worldPresentation(
            operation: SceneWorldPresentationOperation.flash,
            red: 255, green: 255, blue: 255, alpha: 128, durationMs: 100,
          ),
      NarrativeCommandIds.stopSoundEffects:
          SceneInteractiveCommand.stopSoundEffects,
      NarrativeCommandIds.sceneMusic: () => SceneInteractiveCommand.sceneMusic(
            operation: SceneMusicOperation.restore,
          ),
      NarrativeCommandIds.whiteOut: SceneInteractiveCommand.whiteOut,
      NarrativeCommandIds.openRegionalMap: SceneInteractiveCommand.openRegionalMap,
      NarrativeCommandIds.openPartyTrade: SceneInteractiveCommand.openPartyTrade,
      NarrativeCommandIds.setPropState: () => SceneInteractiveCommand.setPropState(
            mapId: 'map_test', propIds: ['gate'], state: MovingPropState.open,
          ),
      NarrativeCommandIds.giveItemGift: () =>
          SceneInteractiveCommand.giveItem(itemId: 'item_potion', quantity: 1),
      NarrativeCommandIds.warp: () => SceneInteractiveCommand.warp(
            destinationMapId: 'map_test',
            warpId: 'warp_arrival',
          ),
      NarrativeCommandIds.wait: () => SceneInteractiveCommand.wait(durationMs: 400),
      NarrativeCommandIds.waitForActorRoutes: () => SceneInteractiveCommand.waitForActorRoutes(mapId: 'map_test'),
      NarrativeCommandIds.worldTone: () => SceneInteractiveCommand.worldTone(
            red: -255, green: -254.5, blue: 0, gray: 10, durationMs: 300,
          ),
      NarrativeCommandIds.playMusicEffect: () =>
          SceneInteractiveCommand.playMusicEffect(mediaAssetId: 'door-sound', volume: .8,
            bgmInterruption: DialogueBgmInterruption(fadeOutMs: 0, fadeInMs: 200)),
      NarrativeCommandIds.playSoundEffect: () =>
          SceneInteractiveCommand.playSoundEffect(mediaAssetId: 'door-sound', volume: .8),
      NarrativeCommandIds.actorRoute: () => SceneInteractiveCommand.actorRoute(
            target: SceneActorTarget.player(mapId: 'map_test'),
            steps: [SceneActorRouteStep.wait(durationMs: 0)],
          ),
      NarrativeCommandIds.actorVisibility: () =>
          SceneInteractiveCommand.actorVisibility(
            target: SceneActorTarget.player(mapId: 'map_test'),
            visible: false,
          ),
      NarrativeCommandIds.movePlatform: () => SceneInteractiveCommand.movePlatform(
            mapId: 'map_test', platformId: 'ferry', motion: MovingPlatformMotion.forward,
          ),
      NarrativeCommandIds.playModelAnimation: () => SceneInteractiveCommand.playModelAnimation(
            mapId: 'map_test', instanceId: 'door', animationIndex: 0,
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
      NarrativeCommandIds.railJourney: () =>
          SceneInteractiveCommand.railJourney(
            commandId: 'scene.runtime.rail.begin',
            journeyId: 'T1',
            operation: SceneRailJourneyOperation.begin,
            direction: RailJourneyDirection.outbound,
            doorSide: RailJourneyDoorSide.west,
          ),
    };

Map<String, SceneInteractiveCommand Function()> _transactionalSamples() => {
  NarrativeCommandIds.inputIntegerToFact: () =>
      SceneInteractiveCommand.inputIntegerToFact(
        factId: 'fact_counter',
        prompt: SceneInteractionPrompt(localizationKey: 'counter'),
        digits: 2,
        minimum: 0,
        maximum: 99,
      ),
  NarrativeCommandIds.tryPayMoney: () => SceneInteractiveCommand.tryPayMoney(
    amount: SceneIntegerOperand.literal(10),
  ),
  NarrativeCommandIds.inputTextToFact: () =>
      SceneInteractiveCommand.inputTextToFact(
        factId: 'fact_name',
        prompt: SceneInteractionPrompt(localizationKey: 'name'),
        confirmationPrompt: SceneInteractionPrompt(localizationKey: 'confirm'),
        constraints: SceneTextInputConstraints(
          minGraphemes: 1,
          maxGraphemes: 10,
        ),
      ),
  NarrativeCommandIds.receivePokemonFromCatalog: () =>
      SceneInteractiveCommand.receivePokemonFromCatalog(
        speciesId: 'sproutle',
        formId: 'base',
        level: 5,
        nicknamePolicy: ScenePokemonGiftNicknamePolicy.disabled,
        nicknameMaxGraphemes: 10,
        pokedexPresentationPolicy:
            ScenePokemonGiftPokedexPresentationPolicy.never,
      ),
};

RuntimeScenePokemonCatalog _pokemonCatalog() => RuntimeScenePokemonCatalog(
  entries: {
    'sproutle': RuntimeScenePokemonCatalogEntry(
      species: const WildPokemonGenerationSpecies(
        id: 'sproutle',
        formId: 'base',
        baseStats: PokemonBaseStats(
          hp: 45,
          attack: 49,
          defense: 49,
          specialAttack: 65,
          specialDefense: 65,
          speed: 45,
        ),
        primaryAbilityId: 'overgrow',
        standardAbilityIds: ['overgrow'],
        allowedAbilityIds: ['overgrow'],
        genderRatio: {'male': 1},
        growthRateId: 'medium_fast',
        baseFriendship: 70,
      ),
      learnset: const WildPokemonGenerationLearnset(startingMoves: ['tackle']),
      maxPpByMoveId: {'tackle': 35},
    ),
  },
);

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
      characters: [
        ProjectCharacterEntry(
          id: 'hero', name: 'Hero', tilesetId: 'actors',
          animations: [
            for (final direction in EntityFacing.values)
              CharacterAnimation(
                state: CharacterAnimationState.walk, direction: direction,
                sourceAssetId: 'hero', frames: const [
                  CharacterAnimationFrame(source: TilesetSourceRect(
                    x: 0, y: 0, width: 32, height: 32,
                  )),
                ],
              ),
          ],
        ),
      ],
      facts: [
        NarrativeFactDefinition(id: 'fact_gate', label: 'Gate'),
        NarrativeFactDefinition(id: 'fact_counter', label: 'Counter',
            initialValue: NarrativeValue.integer(0)),
        NarrativeFactDefinition(id: 'fact_name', label: 'Name',
            initialValue: NarrativeValue.string('Old')),
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

GameState _gameState() => GameState(
      saveId: 'runtime_parity',
      currentMapId: 'map_test',
      mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
        'map_test': MapInstanceRuntimeState(instanceId: 'parity'),
      }),
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

MapData _map() => MapData(
      id: 'map_test',
      name: 'Map Test',
      size: const GridSize(width: 4, height: 4),
      events: const [
        MapEventDefinition(
          id: 'event_gate',
          position: EventPosition(layerId: 'base', x: 1, y: 1),
          pages: [MapEventPage(pageNumber: 0)],
        ),
      ],
      warps: const [
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
          pos: const GridPos(x: 1, y: 2),
          npc: const MapEntityNpcData(),
          presentation: MapEntityPresentation(variants: [
            MapEntityPresentationVariant(id: 'visible',
                condition: NarrativeEventConditionExpression.all([]),
                characterId: 'hero', blocksMovement: true),
          ]),
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
