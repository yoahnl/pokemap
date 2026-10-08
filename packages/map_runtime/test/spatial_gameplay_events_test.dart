import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/map_activation.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/application/narrative_spatial_production_dispatch_bridge.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_runtime_host_callbacks.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_consequence_runtime_writer.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/spatial/spatial_gameplay_events.dart';

void main() {
  test('empty connected activation preserves movement without taking the gameplay gate', () async {
    final map = _map();
    final host = await _Host.create(_project(map), map);
    final activation = _activation('connected', MapActivationReason.connection);
    final pending = host.events.activateMap(activation);
    expect(host.events.isBusy, isFalse);
    expect(host.gate.activity, NarrativeRuntimeActivity.idle);
    expect(host.state.narrativeEventProgress.activeNarrativeMapId, map.id);
    expect(host.state.narrativeEventProgress.visitedNarrativeMapIds, contains(map.id));
    host.moveTo(3.25, 2.5);
    await pending;
    expect(host.state.playerSpatialPosition, PlayerSpatialPosition(x: 3.25, z: 2.5));
  });

  test('map enter executes once per activation and persists one-shot reuse',
      () async {
    final map = _map();
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.mapEnter(map.id), 'reward')
    ], scenes: [
      _scene('reward', [SceneConsequence.giveMoney(amount: 25)])
    ]);
    final host = await _Host.create(project, map);
    final activation = _activation('first');
    await host.events.activateMap(activation);
    await host.events.activateMap(activation);
    await host.events.activateMap(_activation('second'));
    expect(host.state.trainerProfile.money, 25);
    expect(host.state.narrativeEventProgress.consumedNarrativeEventIds,
        {_id('evt', 1)});
    expect(host.gate.activity, NarrativeRuntimeActivity.idle);
  });

  test('connected activation drains a pending outcome instead of bypassing it', () async {
    final map = _map();
    final outcome = NarrativeOutcomeRef(producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: 'producer', outcomeId: 'completed');
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.outcomeReceived(outcome), 'reward')
    ], scenes: [
      _scene('producer', [], outcome: 'completed'),
      _scene('reward', [SceneConsequence.giveMoney(amount: 25)]),
    ]);
    final host = await _Host.create(project, map, state: GameState(
      saveId: 'save', currentMapId: map.id,
      playerPosition: const GridPos(x: 2, y: 2),
      narrativeEventProgress: NarrativeEventProgress(pendingNarrativeOutcomeDeliveries: [
        NarrativeOutcomeDelivery(deliveryId: _id('outd', 2), outcome: outcome,
          rootCorrelationId: _id('corr', 3), depth: 0, attemptCount: 0),
      ]),
    ));
    final pending = host.events.activateMap(_activation('connected', MapActivationReason.connection));
    expect(host.events.isBusy, isTrue);
    await pending;
    expect(host.state.trainerProfile.money, 25);
    expect(host.state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries, isEmpty);
  });

  test('empty connected activation still resets one-shot interactions on reentry', () async {
    final map = _map(entities: const [MapEntity(id: 'pickup',
      kind: MapEntityKind.item, pos: GridPos(x: 2, y: 3))]);
    final event = NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(id: _id('evt', 1), name: 'Pickup',
        source: NarrativeEventSourceRef.entityInteract(map.id, 'pickup'),
        conditions: [], sceneId: 'reward', reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0, order: 0, resetPolicy: const NarrativeEventResetPolicy.onMapReentry()),
      enabled: true);
    final host = await _Host.create(_project(map, records: [event],
      scenes: [_scene('reward', [SceneConsequence.giveMoney(amount: 7)])]), map,
      state: GameState(saveId: 'save', currentMapId: map.id,
        playerPosition: const GridPos(x: 2, y: 2),
        playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 2.5),
        narrativeEventProgress: NarrativeEventProgress(
          consumedNarrativeEventIds: {_id('evt', 1)},
          activeNarrativeMapId: 'previous', visitedNarrativeMapIds: {'previous', map.id})));
    final pending = host.events.activateMap(_activation('reentry', MapActivationReason.connection));
    expect(host.events.isBusy, isFalse);
    await pending;
    expect(host.state.narrativeEventProgress.consumedNarrativeEventIds, isEmpty);
    await host.events.interact();
    expect(host.state.trainerProfile.money, 7);
  });

  test('pickup commits once and world rule removes its interaction presence',
      () async {
    final map = _map(entities: const [
      MapEntity(
          id: 'pickup',
          kind: MapEntityKind.item,
          pos: GridPos(x: 2, y: 3),
          item: MapEntityItemData(gameItemId: 'item_potion', quantity: 2)),
    ]);
    final project = _project(map, records: [
      _event(
          1, NarrativeEventSourceRef.entityInteract(map.id, 'pickup'), 'pickup')
    ], scenes: [
      _scene('pickup', [
        SceneConsequence.giveItem(itemId: 'item_potion', quantity: 2),
        SceneConsequence.setFact(factId: 'picked', value: true),
      ])
    ], worldRules: [
      WorldRuleDefinition(
        id: 'hide_pickup',
        label: 'Hide collected pickup',
        source: WorldRuleSource(
            kind: WorldRuleSourceKind.fact,
            sourceId: 'picked',
            predicate: WorldRuleSourcePredicate.isTrue),
        target: const WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEntity,
            mapId: 'map',
            entityId: 'pickup'),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
      )
    ]).copyWith(
        facts: [NarrativeFactDefinition(id: 'picked', label: 'Picked')]);
    final host = await _Host.create(project, map);
    await host.events.activateMap(_activation('pickup', MapActivationReason.connection));
    expect(host.events.interactionTarget?.id, 'pickup');
    expect(await host.events.interact(),
        isA<NarrativeSpatialProductionDispatchV2Handled>());
    expect(host.state.bag.entries.single.itemId, 'item_potion');
    expect(host.state.bag.entries.single.quantity, 2);
    expect(host.events.entityIsPresent(map.id, map.entities.single), isFalse);
    expect(host.events.interactionTarget, isNull);
    final reloaded =
        gameStateFromStrictSaveJson(strictGameStateSaveJson(host.state));
    final resumed = await _Host.create(project, map, state: reloaded);
    await resumed.events
        .activateMap(_activation('resume', MapActivationReason.saveRestore));
    expect(resumed.events.interactionTarget, isNull);
    expect(resumed.state.bag.entries.single.quantity, 2);
  });

  test('failed scene does not leak an earlier item consequence', () async {
    final map = _map(entities: const [
      MapEntity(
          id: 'pickup', kind: MapEntityKind.item, pos: GridPos(x: 2, y: 3)),
    ]);
    final project = _project(map, records: [
      _event(
          1, NarrativeEventSourceRef.entityInteract(map.id, 'pickup'), 'failed')
    ], scenes: [
      _scene('failed', [
        SceneConsequence.giveItem(itemId: 'item_potion', quantity: 2),
        SceneConsequence.takeItem(itemId: 'missing_item', quantity: 1),
      ])
    ]);
    final host = await _Host.create(project, map);
    await host.events.activateMap(_activation('failed'));
    final before = host.state;
    await expectLater(host.events.interact(), throwsStateError);
    expect(host.state, before);
    expect(host.state.bag.entries, isEmpty);
  });

  test('dialogue suspends checkpoint and disposal cancels the final commit',
      () async {
    final map = _map(entities: const [
      MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 3),
          npc: MapEntityNpcData()),
    ]);
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.entityInteract(map.id, 'npc'), 'talk')
    ], scenes: [
      _scene('talk', [SceneConsequence.giveMoney(amount: 50)], dialogue: true)
    ]);
    final dialogue = Completer<String>();
    final opened = Completer<void>();
    final host = await _Host.create(project, map, dialogue: () {
      opened.complete();
      return dialogue.future;
    });
    await host.events.activateMap(_activation('talk'));
    final before = host.state;
    final interaction = host.events.interact();
    await opened.future;
    expect(host.events.isBusy, isTrue);
    await expectLater(
        host.gate.runCheckpoint(
            NarrativeRuntimeCheckpointOperation.save, () async {}),
        throwsA(isA<NarrativeRuntimeCheckpointBlockedException>()));
    expect(host.state.trainerProfile.money, 0);
    host.events.dispose();
    dialogue.complete('completed');
    await interaction;
    expect(host.state, before);
    expect(host.events.isBusy, isFalse);
  });

  test('encounters use actual cell entries, never facing or blocked inputs',
      () async {
    final map = _map(zones: const [
      MapGameplayZone(
        id: 'grass',
        name: 'Grass',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
            pos: GridPos(x: 1, y: 1), size: GridSize(width: 4, height: 4)),
        encounter: EncounterZonePayload(
            encounterTableId: 'grass_table', encounterKind: EncounterKind.walk),
      ),
    ]);
    final project = _project(map).copyWith(encounterTables: const [
      ProjectEncounterTable(
          id: 'grass_table',
          name: 'Grass',
          encounterKind: EncounterKind.walk,
          chancePerStep: 1,
          entries: [
            ProjectEncounterEntry(speciesId: 'zubat', minLevel: 5, maxLevel: 5),
          ]),
    ]);
    final host = await _Host.create(project, map);
    await host.events.activateMap(_activation('grass'));
    expect(host.battles, isEmpty);
    const start = GridPos(x: 2, y: 2);
    expect(
        await host.events
            .playerEnteredCell(previousPosition: start, currentPosition: start),
        isNull);
    host.canInput = false;
    expect(
        await host.events
            .playerEnteredCell(previousPosition: start, currentPosition: start),
        isNull);
    host.canInput = true;
    host.moveTo(3.125, 2.5625);
    const next = GridPos(x: 3, y: 2);
    final result = await host.events
        .playerEnteredCell(previousPosition: start, currentPosition: next);
    expect(result?.status, GameplayEncounterCheckStatus.triggered);
    expect(host.battles, hasLength(1));
    expect(host.battles.single.returnContext.playerPos, next);
    expect(
        await host.events
            .playerEnteredCell(previousPosition: start, currentPosition: next),
        isNull);
    expect(host.battles, hasLength(1));
  });

  test('event trigger fires on entry, then waits for a real reentry', () async {
    final map = _map(triggers: const [
      MapTrigger(
          id: 'entry',
          type: TriggerType.event,
          area: MapRect(
              pos: GridPos(x: 3, y: 2), size: GridSize(width: 1, height: 1))),
    ]);
    final project = _project(map, records: [
      _event(
          1, NarrativeEventSourceRef.triggerEnter(map.id, 'entry'), 'trigger',
          oneShot: false),
    ], scenes: [
      _scene('trigger', [SceneConsequence.giveMoney(amount: 10)])
    ]);
    final host = await _Host.create(project, map);
    await host.events.activateMap(_activation('trigger'));
    host.moveTo(3.5, 2.5);
    await host.events.playerEnteredCell(
        previousPosition: const GridPos(x: 2, y: 2),
        currentPosition: const GridPos(x: 3, y: 2));
    expect(host.state.trainerProfile.money, 10);
    await host.events.playerEnteredCell(
        previousPosition: const GridPos(x: 3, y: 2),
        currentPosition: const GridPos(x: 3, y: 2));
    expect(host.state.trainerProfile.money, 10);
    host.moveTo(2.5, 2.5);
    await host.events.playerEnteredCell(
        previousPosition: const GridPos(x: 3, y: 2),
        currentPosition: const GridPos(x: 2, y: 2));
    host.moveTo(3.5, 2.5);
    await host.events.playerEnteredCell(
        previousPosition: const GridPos(x: 2, y: 2),
        currentPosition: const GridPos(x: 3, y: 2));
    expect(host.state.trainerProfile.money, 20);
  });

  test('world projection uses manifest pixels and the canonical feet cell',
      () async {
    final map = _map();
    final host = await _Host.create(_project(map), map);
    host.moveTo(3.3125, 2.0);
    final world = host.events.projectWorld();
    expect(world.player.pos, const GridPos(x: 3, y: 2));
    expect(world.player.playerCollisionRectPx.bottomCenterPx.xPx, 106);
    expect(world.player.playerCollisionRectPx.bottomCenterPx.yPx, 48);
    expect(
        PlayerCollisionConventionsV1.projectFeetAnchorToCell(
          playerCollisionRectPx: world.player.playerCollisionRectPx,
          tileWidthPx: 32,
          tileHeightPx: 24,
          mapWidthCells: 6,
          mapHeightCells: 6,
        ),
        world.player.pos);
  });
  test('fact conditions claim an interaction without executing until eligible',
      () async {
    final map = _map(entities: const [
      MapEntity(id: 'sign', kind: MapEntityKind.sign, pos: GridPos(x: 2, y: 3))
    ]);
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.entityInteract(map.id, 'sign'),
          'conditional',
          conditions: [NarrativeEventCondition.fact('ready', true)])
    ], scenes: [
      _scene('conditional', [SceneConsequence.giveMoney(amount: 30)])
    ]).copyWith(facts: [
      NarrativeFactDefinition(
          id: 'ready', label: 'Ready', legacyFlagName: 'ready')
    ]);
    final host = await _Host.create(project, map);
    await host.events.activateMap(_activation('conditional'));
    expect(await host.events.interact(),
        isA<NarrativeSpatialProductionDispatchNoFallback>());
    expect(host.state.trainerProfile.money, 0);
    host.state = const GameStateMutations().setFlag(host.state, 'ready');
    expect(await host.events.interact(),
        isA<NarrativeSpatialProductionDispatchV2Handled>());
    expect(host.state.trainerProfile.money, 30);
  });

  test('restored outbox is delivered before map enter and child outcomes drain',
      () async {
    final map = _map();
    final producer = _scene('producer', [], outcome: 'finished');
    final pending = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'producer',
        outcomeId: 'finished');
    final child = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'outcome_reward',
        outcomeId: 'rewarded');
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.outcomeReceived(pending),
          'outcome_reward'),
      _event(2, NarrativeEventSourceRef.outcomeReceived(child), 'child_reward'),
      _event(3, NarrativeEventSourceRef.mapEnter(map.id), 'map_reward'),
    ], scenes: [
      producer,
      _scene('outcome_reward', [SceneConsequence.giveMoney(amount: 10)],
          outcome: 'rewarded'),
      _scene('child_reward', [SceneConsequence.giveMoney(amount: 1)]),
      _scene('map_reward', [SceneConsequence.giveMoney(amount: 100)]),
    ]);
    final deliveryId = _id('outd', 5);
    final host = await _Host.create(project, map,
        state: GameState(
          saveId: 'save',
          currentMapId: map.id,
          playerPosition: const GridPos(x: 2, y: 2),
          playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 2.5),
          narrativeEventProgress:
              NarrativeEventProgress(pendingNarrativeOutcomeDeliveries: [
            NarrativeOutcomeDelivery(
                deliveryId: deliveryId,
                outcome: pending,
                rootCorrelationId: _id('corr', 6),
                depth: 0,
                attemptCount: 0),
          ]),
        ));
    await host.events
        .activateMap(_activation('restore', MapActivationReason.saveRestore));
    expect(host.state.trainerProfile.money, 111);
    expect(host.state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty);
    expect(
        host.state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        contains(deliveryId));
    expect(host.state.narrativeEventProgress.consumedNarrativeEventIds,
        {_id('evt', 1), _id('evt', 2), _id('evt', 3)});
  });

  test('postcommit warp can await the destination activation without deadlock',
      () async {
    final first = _map();
    final second = _map().copyWith(id: 'second');
    final project = _project(first, records: [
      _event(1, NarrativeEventSourceRef.mapEnter(first.id), 'first_reward'),
      _event(2, NarrativeEventSourceRef.mapEnter(second.id), 'second_reward'),
    ], scenes: [
      _scene('first_reward', [SceneConsequence.giveMoney(amount: 10)]),
      _scene('second_reward', [SceneConsequence.giveMoney(amount: 20)]),
    ]).copyWith(maps: [
      const ProjectMapEntry(
          id: 'map', name: 'First', relativePath: 'maps/map.json'),
      const ProjectMapEntry(
          id: 'second', name: 'Second', relativePath: 'maps/second.json'),
    ]);
    late _Host host;
    var warped = false;
    host = await _Host.create(project, first,
        maps: {first.id: first, second.id: second},
        afterStateCommitted: (state) async {
      if (state.currentMapId == 'map' && !warped) {
        warped = true;
        host.state = state.copyWith(currentMapId: 'second');
        await host.events.activateMap(MapActivation(
            activationId: 'warp',
            mapId: 'second',
            reason: MapActivationReason.warp));
      }
    });
    await host.events
        .activateMap(_activation('initial'))
        .timeout(const Duration(seconds: 3));
    expect(host.state.currentMapId, 'second');
    expect(host.state.trainerProfile.money, 30);
    expect(host.events.isBusy, isFalse);
    expect(host.gate.activity, NarrativeRuntimeActivity.idle);
  });
  test('scene host writes remain private until the entire scene commits',
      () async {
    final map = _map(entities: const [
      MapEntity(id: 'sign', kind: MapEntityKind.sign, pos: GridPos(x: 2, y: 3))
    ]);
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.entityInteract(map.id, 'sign'),
          'host_write')
    ], scenes: [
      _scene('host_write', [SceneConsequence.giveMoney(amount: 30)],
          dialogue: true)
    ]);
    final finish = Completer<String>();
    final opened = Completer<void>();
    final host = await _Host.create(project, map,
        createSceneCallbacks: (read, commit) => SceneRuntimeHostCallbacks(
              evaluateCondition: (_) => 'true',
              showDialogue: (_) async {
                final state = read();
                commit(state.copyWith(
                    trainerProfile: state.trainerProfile.copyWith(money: 70)));
                opened.complete();
                return finish.future;
              },
              startBattle: (_) => 'victory',
              playCinematic: (_) => 'completed',
            ));
    await host.events.activateMap(_activation('host_write'));
    final interaction = host.events.interact();
    await opened.future;
    expect(host.state.trainerProfile.money, 0);
    expect(await host.events.interact(), isNull);
    finish.complete('completed');
    await interaction;
    expect(host.state.trainerProfile.money, 100);
  });

  test('conditional NPC visibility also filters the query world collision',
      () async {
    final map = _map(entities: const [
      MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
        blocksMovement: true,
        npc: MapEntityNpcData(
            visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.storyFlagSet,
              refId: 'visible'),
        )),
      )
    ]);
    final host = await _Host.create(_project(map), map);
    await host.events.activateMap(_activation('visible'));
    expect(host.events.entityIsPresent(map.id, map.entities.single), isFalse);
    expect(host.events.projectWorld().entityAt(2, 3), isNull);
    host.state = const GameStateMutations().setFlag(host.state, 'visible');
    expect(host.events.entityIsPresent(map.id, map.entities.single), isTrue);
    expect(host.events.interactionTarget?.id, 'npc');
    expect(host.events.projectWorld().entityAt(2, 3)?.id, 'npc');
  });
  test('postcommit host changes survive the following outcome transaction',
      () async {
    final map = _map();
    final parent = _scene('parent', [SceneConsequence.giveMoney(amount: 10)],
        outcome: 'finished');
    final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'parent',
        outcomeId: 'finished');
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.mapEnter(map.id), 'parent'),
      _event(2, NarrativeEventSourceRef.outcomeReceived(outcome), 'child'),
    ], scenes: [
      parent,
      _scene('child', [SceneConsequence.giveMoney(amount: 20)])
    ]);
    late _Host host;
    var prepared = false;
    host = await _Host.create(project, map, afterStateCommitted: (state) async {
      if (!prepared) {
        prepared = true;
        host.state = state.copyWith(
            trainerProfile: state.trainerProfile
                .copyWith(money: state.trainerProfile.money + 5));
      }
    });
    await host.events.activateMap(_activation('host_change'));
    expect(host.state.trainerProfile.money, 35);
  });
  test('scene healing uses host recovery caps through the canonical writer',
      () async {
    final map = _map(entities: const [
      MapEntity(
          id: 'healer',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 3),
          npc: MapEntityNpcData())
    ]);
    final project = _project(map, records: [
      _event(
          1, NarrativeEventSourceRef.entityInteract(map.id, 'healer'), 'heal')
    ], scenes: [
      _scene('heal', [SceneConsequence.healParty()])
    ]);
    final state = GameState(
        saveId: 'save',
        currentMapId: map.id,
        playerPosition: const GridPos(x: 2, y: 2),
        playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 2.5),
        party: const PlayerParty(members: [
          PlayerPokemon(
              speciesId: 'zubat',
              level: 5,
              currentHp: 3,
              abilityId: 'inner_focus',
              natureId: 'hardy')
        ]));
    final host = await _Host.create(project, map,
        state: state,
        buildSceneConsequenceWriter: (working, sceneId) async =>
            SceneConsequenceRuntimeWriter(
              project: project,
              mapsById: {map.id: map},
              maxHpByPartyIndex: const {0: 30},
            ));
    await host.events.activateMap(_activation('heal'));
    await host.events.interact();
    expect(host.state.party.members.single.currentHp, 30);
  });
  test('battle public outcome is collected once and committed with its scene',
      () async {
    final map = _map(entities: const [
      MapEntity(
          id: 'trainer',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 3),
          npc: MapEntityNpcData(trainerId: 'coach'))
    ]);
    final battleOutcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.battle,
        producerId: 'trainer:coach',
        outcomeId: 'victory');
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.entityInteract(map.id, 'trainer'),
          'battle'),
      _event(2, NarrativeEventSourceRef.outcomeReceived(battleOutcome),
          'after_battle'),
    ], scenes: [
      _battleScene(),
      _scene('after_battle', [SceneConsequence.giveMoney(amount: 5)])
    ]).copyWith(trainers: const [
      ProjectTrainerEntry(id: 'coach', name: 'Coach', trainerClass: 'youngster')
    ]);
    late _Host host;
    final request = _trainerRequest('attempt');
    host = await _Host.create(project, map,
        createSceneCallbacks: (read, commit) => SceneRuntimeHostCallbacks(
              evaluateCondition: (_) => 'true',
              showDialogue: (_) => 'completed',
              startBattle: (_) async {
                commit(read().copyWith(
                    trainerProfile: read().trainerProfile.copyWith(money: 7)));
                expect(
                    await host.events.publishBattleOutcome(
                        request: request, outcomeId: 'victory'),
                    isTrue);
                expect(
                    await host.events.publishBattleOutcome(
                        request: request, outcomeId: 'victory'),
                    isFalse);
                expect(host.state.trainerProfile.money, 0);
                expect(
                    host.state.narrativeEventProgress
                        .pendingNarrativeOutcomeDeliveries,
                    isEmpty);
                return 'victory';
              },
              playCinematic: (_) => 'completed',
            ));
    await host.events.activateMap(_activation('battle'));
    await host.events.interact();
    expect(host.state.trainerProfile.money, 12);
    expect(host.state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty);
    expect(
        await host.events
            .publishBattleOutcome(request: request, outcomeId: 'victory'),
        isFalse);
  });

  test('battle output does not escape a scene that fails after battle',
      () async {
    final map = _map(entities: const [
      MapEntity(
          id: 'trainer',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 3),
          npc: MapEntityNpcData(trainerId: 'coach'))
    ]);
    final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.battle,
        producerId: 'trainer:coach',
        outcomeId: 'victory');
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.entityInteract(map.id, 'trainer'),
          'battle'),
      _event(
          2, NarrativeEventSourceRef.outcomeReceived(outcome), 'after_battle'),
    ], scenes: [
      _battleScene(failAfterBattle: true),
      _scene('after_battle', [SceneConsequence.giveMoney(amount: 5)])
    ]).copyWith(trainers: const [
      ProjectTrainerEntry(id: 'coach', name: 'Coach', trainerClass: 'youngster')
    ]);
    late _Host host;
    host = await _Host.create(project, map,
        createSceneCallbacks: (read, commit) => SceneRuntimeHostCallbacks(
              evaluateCondition: (_) => 'true',
              showDialogue: (_) => 'completed',
              startBattle: (_) async {
                commit(read().copyWith(
                    trainerProfile: read().trainerProfile.copyWith(money: 7)));
                await host.events.publishBattleOutcome(
                    request: _trainerRequest('failed_attempt'),
                    outcomeId: 'victory');
                return 'victory';
              },
              playCinematic: (_) => 'completed',
            ));
    await host.events.activateMap(_activation('failed_battle'));
    final before = host.state;
    await expectLater(host.events.interact(), throwsStateError);
    expect(host.state, before);
  });
  test(
      'standalone battle publication is idempotent and checks the public contract',
      () async {
    final map = _map();
    final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.battle,
        producerId: 'trainer:coach',
        outcomeId: 'victory');
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.outcomeReceived(outcome), 'reward')
    ], scenes: [
      _scene('reward', [SceneConsequence.giveMoney(amount: 5)])
    ]).copyWith(trainers: const [
      ProjectTrainerEntry(id: 'coach', name: 'Coach', trainerClass: 'youngster')
    ]);
    final host = await _Host.create(project, map);
    await host.events.activateMap(_activation('standalone'));
    final request = _trainerRequest('standalone_attempt');
    expect(
        await host.events
            .publishBattleOutcome(request: request, outcomeId: 'captured'),
        isFalse);
    expect(
        await host.events
            .publishBattleOutcome(request: request, outcomeId: 'victory'),
        isTrue);
    expect(
        await host.events
            .publishBattleOutcome(request: request, outcomeId: 'victory'),
        isFalse);
    expect(host.state.trainerProfile.money, 5);
    expect(host.state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty);
  });

  test(
      'wild returns cannot invent a battle producer outside the authoring catalog',
      () async {
    final map = _map();
    final host = await _Host.create(_project(map), map);
    await host.events.activateMap(_activation('wild'));
    final before = host.state;
    final request = WildBattleStartRequest(
        requestId: 'wild_attempt',
        createdAtEpochMs: 42,
        returnContext: const OverworldReturnContext(
            mapId: 'map',
            playerPos: GridPos(x: 2, y: 2),
            playerFacing: Direction.south),
        mapId: 'map',
        encounterSourceId: 'grass',
        encounterSourceKind: EncounterSourceKind.gameplayZone,
        tableId: 'grass_table',
        encounterKind: EncounterKind.walk,
        speciesId: 'zubat',
        level: 5,
        minLevel: 5,
        maxLevel: 5,
        weight: 1,
        playerPos: const GridPos(x: 2, y: 2));
    for (final outcome in ['victory', 'captured', 'runaway']) {
      expect(
          await host.events
              .publishBattleOutcome(request: request, outcomeId: outcome),
          isFalse);
    }
    expect(host.state, before);
  });
}

TrainerBattleStartRequest _trainerRequest(String attempt) =>
    TrainerBattleStartRequest(
      requestId: attempt,
      createdAtEpochMs: 42,
      returnContext: const OverworldReturnContext(
          mapId: 'map',
          playerPos: GridPos(x: 2, y: 2),
          playerFacing: Direction.south),
      trainerId: 'coach',
      npcEntityId: 'trainer',
      mapId: 'map',
      playerPos: const GridPos(x: 2, y: 2),
    );

SceneAsset _battleScene({bool failAfterBattle = false}) => SceneAsset(
    id: 'battle',
    name: 'Battle',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
              battleKind: 'trainer',
              trainerId: 'coach',
              declaredOutcomes: const ['victory', 'defeat'])),
      if (failAfterBattle)
        SceneNode(
            id: 'failed',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(SceneConsequence.takeItem(
                itemId: 'missing_item', quantity: 1))),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(
          id: 'start_battle',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow),
      SceneEdge(
          id: 'victory',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: failAfterBattle ? 'failed' : 'end',
          kind: SceneEdgeKind.battleVictory),
      SceneEdge(
          id: 'defeat',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'end',
          kind: SceneEdgeKind.battleDefeat),
      if (failAfterBattle)
        SceneEdge(
            id: 'failed_end',
            fromNodeId: 'failed',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted),
    ]));

final class _Host {
  _Host(this.state);
  GameState state;
  late SpatialGameplayEvents events;
  final gate = NarrativeRuntimeActivityGate();
  final battles = <WildBattleStartRequest>[];
  bool canInput = true;
  int serial = 10;

  static Future<_Host> create(ProjectManifest project, MapData map,
      {GameState? state,
      Future<String> Function()? dialogue,
      Map<String, MapData>? maps,
      SpatialSceneCallbackFactory? createSceneCallbacks,
      SpatialSceneConsequenceWriterFactory? buildSceneConsequenceWriter,
      Future<void> Function(GameState)? afterStateCommitted}) async {
    final host = _Host(state ??
        GameState(
          saveId: 'save',
          currentMapId: map.id,
          playerPosition: const GridPos(x: 2, y: 2),
          playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 2.5),
        ));
    host.events = await SpatialGameplayEvents.create(
      project: project,
      mapsById: maps ?? {map.id: map},
      readGameState: () => host.state,
      commitGameState: (state) => host.state = state,
      createSceneCallbacks: createSceneCallbacks ??
          (read, commit) => SceneRuntimeHostCallbacks(
                evaluateCondition: (_) => 'true',
                showDialogue: (_) async =>
                    dialogue == null ? 'completed' : await dialogue(),
                startBattle: (_) => 'victory',
                playCinematic: (_) => 'completed',
              ),
      showEntityDialogue: (_, __) async {},
      startWildBattle: (request) async => host.battles.add(request),
      activityGate: host.gate,
      isActive: () => true,
      canProcessInput: () => host.canInput,
      runtimeIdFactory: (prefix) => _id(prefix, host.serial++),
      afterStateCommitted: afterStateCommitted,
      buildSceneConsequenceWriter: buildSceneConsequenceWriter,
      random: Random(41),
      now: () => DateTime.fromMillisecondsSinceEpoch(42),
    );
    return host;
  }

  void moveTo(double x, double z) {
    state = state.copyWith(
        playerPosition: GridPos(x: x.floor(), y: z.floor()),
        playerSpatialPosition: PlayerSpatialPosition(x: x, z: z));
  }
}

String _id(String prefix, int value) =>
    '${prefix}_019abcde-0000-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';
MapActivation _activation(String id,
        [MapActivationReason reason = MapActivationReason.initialBoot]) =>
    MapActivation(activationId: id, mapId: 'map', reason: reason);

MapData _map(
        {List<MapEntity> entities = const [],
        List<MapTrigger> triggers = const [],
        List<MapGameplayZone> zones = const []}) =>
    MapData(
      id: 'map',
      name: 'Spatial village',
      size: const GridSize(width: 6, height: 6),
      entities: entities,
      triggers: triggers,
      gameplayZones: zones,
      spatialScene: MapSpatialScene(
          width: 6,
          depth: 6,
          navigation:
              SpatialNavigationProfile(spawn: SpatialSpawn(x: 2.5, z: 2.5))),
    );

ProjectManifest _project(MapData map,
        {List<NarrativeEventRecord> records = const [],
        List<SceneAsset> scenes = const [],
        List<WorldRuleDefinition> worldRules = const []}) =>
    ProjectManifest(
      name: 'Spatial events',
      tilesets: const [],
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
          tileWidth: 32,
          tileHeight: 24),
      maps: [
        ProjectMapEntry(
            id: map.id, name: map.name, relativePath: 'maps/map.json')
      ],
      dialogues: const [
        ProjectDialogueEntry(
            id: 'talk', name: 'Talk', relativePath: 'dialogues/talk.yarn')
      ],
      eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: records,
          legacyClaims: const []),
      scenes: scenes,
      worldRules: worldRules,
    );

NarrativeEventRecord _event(
        int id, NarrativeEventSourceRef source, String sceneId,
        {bool oneShot = true,
        List<NarrativeEventCondition> conditions = const []}) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: _id('evt', id),
          name: sceneId,
          source: source,
          conditions: conditions,
          sceneId: sceneId,
          reusePolicy: oneShot
              ? NarrativeEventReusePolicy.oneShot
              : NarrativeEventReusePolicy.reusable,
          priority: 0,
          order: id,
          resetPolicy: const NarrativeEventResetPolicy.never(),
        ),
        enabled: true);

SceneAsset _scene(String id, List<SceneConsequence> consequences,
    {bool dialogue = false, String? outcome}) {
  final nodes = <SceneNode>[
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    for (var index = 0; index < consequences.length; index++)
      SceneNode(
          id: 'action_$index',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(consequences[index])),
    if (dialogue)
      SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'talk')),
    SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload:
            outcome == null ? null : SceneEndPayload(sceneOutcomeId: outcome)),
  ];
  return SceneAsset(
      id: id,
      name: id,
      declaredOutcomes: [
        if (outcome != null) SceneOutcome(id: outcome, label: outcome)
      ],
      graph: SceneGraph(startNodeId: 'start', nodes: nodes, edges: [
        for (var index = 0; index < nodes.length - 1; index++)
          SceneEdge(
            id: 'edge_$index',
            fromNodeId: nodes[index].id,
            fromPortId: 'completed',
            toNodeId: nodes[index + 1].id,
            kind: nodes[index].kind == SceneNodeKind.action
                ? SceneEdgeKind.actionCompleted
                : nodes[index].kind == SceneNodeKind.yarnDialogue
                    ? SceneEdgeKind.defaultFlow
                    : SceneEdgeKind.defaultFlow,
          )
      ]));
}
