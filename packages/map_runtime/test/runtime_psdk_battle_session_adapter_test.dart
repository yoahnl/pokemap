import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

void main() {
  group('RuntimePsdkBattleSessionAdapter', () {
    test('opponent status cures produce an item narration event', () {
      final wait = _move(
        id: 'wait',
        category: PsdkBattleMoveCategory.status,
        power: 0,
      );
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
          player: _combatant(id: 'player_0', hp: 100, moves: [wait]),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
          opponent: _combatant(
            id: 'opponent_0',
            hp: 100,
            majorStatus: PsdkBattleMajorStatus.poison,
            moves: [wait],
          ),
        ),
        opponentAi: const PsdkBattleAi(
          canUseItem: true,
          itemOptions: [
            PsdkBattleAiItemOption(
              itemId: 'antidote',
              effect: PsdkBattleStatusCureItemEffect.any(),
            ),
          ],
        ),
        itemDisplayNames: const {'antidote': 'Antidote du projet'},
      );

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final turn = session
          .createLegacyDisplaySession(isTrainerBattle: true)
          .state
          .currentTurn!;

      expect(session.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(
        buildBattleTurnLinesForOverlay(turn).join('\n'),
        contains('Antidote du projet'),
      );
    });

    test('opponent healing keeps its target when the player heals a reserve', () {
      final session = _trainerMedicineSession();

      session.submitBattleItem(
        itemId: 'potion',
        displayName: 'Potion',
        targetPartyIndex: 1,
        effect: const PsdkBattleHpHealItemEffect.flat(20),
        consumeItem: true,
      );
      final turn = session
          .createLegacyDisplaySession(isTrainerBattle: true)
          .state
          .currentTurn!;
      final opponentHeal = turn.bagHpHealItemEvents
          .singleWhere((event) => event.side == BattleSideId.enemy);
      final playerHeal = turn.bagHpHealItemEvents
          .singleWhere((event) => event.side == BattleSideId.player);

      expect(opponentHeal.targetSpeciesId, 'opponent_0');
      expect(opponentHeal.displayName, 'Potion du projet');
      expect(opponentHeal.targetLineupIndex, 0);
      expect(playerHeal.targetSpeciesId, 'player_1');
      expect(playerHeal.targetLineupIndex, 1);
    });

    test('L14 translates weather set and residuals without extra move uses', () {
      final session = _sandstormSession(setWeather: true);

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final turn = session
          .createLegacyDisplaySession(isTrainerBattle: false)
          .state
          .currentTurn!;
      final fields = turn.timeline.whereType<BattleTurnFieldEvent>().toList();

      expect(fields.map((event) => event.event.kind), <BattleFieldEventKind>[
        BattleFieldEventKind.weatherSet,
        BattleFieldEventKind.weatherResidualDamage,
        BattleFieldEventKind.weatherResidualDamage,
      ]);
      expect(fields.first.event.weather, BattleWeatherId.sandstorm);
      final residuals = fields.skip(1).map((event) => event.event).toList();
      expect(residuals.map((event) => event.targetSide).toSet(),
          <BattleSideId>{BattleSideId.player, BattleSideId.enemy});
      expect(residuals.map((event) => event.damage), everyElement(10));
      expect(turn.executions.where((event) => event.move.id == 'sandstorm'),
          hasLength(1));
      expect(turn.executions.every((event) => event.damage == 0), isTrue);
      expect(turn.fieldEvents, fields.map((event) => event.event).toList());
      expect(
        turn.timeline.indexOf(fields[1]),
        greaterThan(turn.timeline.lastIndexWhere(
            (event) => event is BattleTurnExecutionEvent)),
      );
    });

    test('L14 expires the previous sandstorm without residuals on its last tick',
        () {
      final session = _sandstormSession(remainingTurns: 1);

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final display =
          session.createLegacyDisplaySession(isTrainerBattle: false);
      final fields = display.state.currentTurn!.timeline
          .whereType<BattleTurnFieldEvent>()
          .map((event) => event.event)
          .toList();

      expect(fields, hasLength(1));
      expect(fields.single.kind, BattleFieldEventKind.weatherExpired);
      expect(fields.single.weather, BattleWeatherId.sandstorm);
      expect(display.state.player.currentHp, 160);
      expect(display.state.enemy.currentHp, 160);
      expect(display.state.field.weather, isNull);
    });

    test('L14 residual knockout retains the canonical replacement request', () {
      final session = _sandstormSession(playerHp: 5, withReserve: true);

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final display =
          session.createLegacyDisplaySession(isTrainerBattle: true);
      final residual = display.state.currentTurn!.timeline
          .whereType<BattleTurnFieldEvent>()
          .map((event) => event.event)
          .singleWhere((event) => event.targetSide == BattleSideId.player);

      expect(residual.damage, 5);
      expect(display.state.player.currentHp, 0);
      expect(display.decisionRequest, isA<BattleForcedReplacementRequest>());
      expect(session.decisionRequest.kind,
          BattleEngineDecisionRequestKind.forcedReplacement);
      expect(session.createLegacyWriteBackState().player.currentHp, 0);
    });

    test('legacy display session preserves an explicit no-flee policy', () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(_setup());
      final displaySession = session.createLegacyDisplaySession(
        isTrainerBattle: false,
        allowFlee: false,
      );

      expect(displaySession.setup.allowFlee, isFalse);
      expect(
        displaySession.decisionRequest.allowedChoices
            .whereType<PlayerBattleChoiceRun>(),
        isEmpty,
      );
      expect(
        () => displaySession.applyChoice(const PlayerBattleChoiceRun()),
        throwsA(isA<StateError>()),
      );
    });

    test(
        'BETA-BAT-036 : un remplacement d’adversaire produit un événement de '
        'changement pour la présentation', () {
      // Le moteur émettait déjà `switch_out` / `switch_in`, mais RIEN ne les
      // traduisait : le planner n'atteignait jamais sa séquence de Ball, et
      // surtout le gel du sprite restait vide — le remplaçant apparaissait
      // avant que le K.O. qui le provoque ait été joué.
      final session =
          RuntimePsdkBattleSessionAdapter.fromSetup(_setupWithOpponentReserve());

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final display = session.createLegacyDisplaySession(
        isTrainerBattle: true,
      );
      final turn = display.state.currentTurn;

      final switches = turn!.timeline.whereType<BattleTurnSwitchEvent>().toList();
      expect(
        switches,
        hasLength(1),
        reason: 'le K.O. du premier adversaire déclenche son remplacement',
      );
      final event = switches.single.event;
      expect(event.side, BattleSideId.enemy);
      expect(event.kind, BattleSwitchEventKind.switched);
      expect(
        event.fromSpeciesId,
        'lead_foe',
        reason: 'l’espèce sortante est lue AVANT l’application de l’état',
      );
      expect(
        event.toSpeciesId,
        'reserve_foe',
        reason: 'et l’entrante APRÈS — les déduire de l’état final serait '
            'faux dès qu’un tour enchaîne deux remplacements',
      );
      expect(event.wasForced, isTrue);
    });

    test('uses PSDK AI by default so opponents can choose a damaging move', () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(_setup());

      final result =
          session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final displaySession = session.createLegacyDisplaySession(
        isTrainerBattle: false,
      );

      expect(
        result.timeline.events
            .whereType<BattleMoveDeclaredTimelineEvent>()
            .where((event) =>
                event.user.bank == psdkOpponentSlot.bank &&
                event.user.position == psdkOpponentSlot.position)
            .map((event) => event.moveId),
        contains('tackle'),
      );
      expect(
        result.state.psdkState.battlerAt(psdkPlayerSlot).currentHp,
        lessThan(120),
      );
      expect(displaySession.state.player.currentHp, lessThan(120));
      expect(
        displaySession.state.currentTurn!.executions.where(
          (execution) => execution.attackerSide == BattleSideId.enemy,
        ),
        isNotEmpty,
      );
      expect(displaySession.state.currentTurn!.enemyAction,
          isA<BattleActionFight>());
      expect(
        (displaySession.state.currentTurn!.enemyAction as BattleActionFight)
            .move
            .id,
        equals('tackle'),
      );
    });

    test('accepts native capture and projects a failed attempt plus enemy turn',
        () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
          player: _combatant(
            id: 'player',
            hp: 120,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'wait',
                category: PsdkBattleMoveCategory.status,
                power: 0,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'wild',
            hp: 120,
            catchRate: 1,
            moves: <PsdkBattleMoveData>[
              _move(id: 'tackle', power: 40),
            ],
          ),
          canCapture: true,
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 47,
          ),
        ),
      );

      final result =
          session.submitPlayerChoice(const PlayerBattleChoiceCapture());
      final displaySession = session.createLegacyDisplaySession(
        isTrainerBattle: false,
        allowCapture: true,
      );

      expect(result.outcome, isNull);
      expect(
        result.timeline.events
            .whereType<BattleCaptureAttemptTimelineEvent>()
            .single
            .caught,
        isFalse,
      );
      expect(session.state.psdkState.battlerAt(psdkPlayerSlot).currentHp,
          lessThan(120));
      expect(
        displaySession.state.currentTurn!.captureAttemptEvents.single.caught,
        isFalse,
      );
      expect(displaySession.state.currentTurn!.enemyAction,
          isA<BattleActionFight>());
    });

    test('the legacy projection transmits the formula shakes on failure', () {
      // ENC-005 : le seed 5 fait tirer 33849 sur 120/91800 -> échec à deux
      // secousses. La projection legacy doit porter CE nombre ; une projection
      // qui redériverait `caught ? 4 : 0` rendrait zéro et casserait ici.
      final expected = const BattleCaptureFormula().attempt(
        targetCurrentHp: 120,
        targetMaxHp: 120,
        catchRate: 1,
        ballId: canonicalPokeBallItemId,
        ballRateNumerator: 1,
        ballRateDenominator: 1,
        status: BattleCaptureStatus.none,
        rng: const BattleSeededRng(state: 5),
      );
      expect(expected.caught, isFalse);
      expect(expected.shakes, 2,
          reason: 'the chosen seed must discriminate 0, 3 and 4');

      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
          player: _combatant(
            id: 'player',
            hp: 120,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'wait',
                category: PsdkBattleMoveCategory.status,
                power: 0,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'wild',
            hp: 120,
            catchRate: 1,
            moves: <PsdkBattleMoveData>[
              _move(id: 'tackle', power: 40),
            ],
          ),
          canCapture: true,
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 5,
          ),
        ),
      );

      final result =
          session.submitPlayerChoice(const PlayerBattleChoiceCapture());
      final displaySession = session.createLegacyDisplaySession(
        isTrainerBattle: false,
        allowCapture: true,
      );

      final nativeAttempt = result.timeline.events
          .whereType<BattleCaptureAttemptTimelineEvent>()
          .single;
      expect(nativeAttempt.caught, isFalse);
      expect(nativeAttempt.shakes, expected.shakes);
      final legacyEvent =
          displaySession.state.currentTurn!.captureAttemptEvents.single;
      expect(legacyEvent.caught, isFalse);
      expect(legacyEvent.shakes, expected.shakes);
    });

    test('projects native capture success and canonical item into legacy', () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
          player: _combatant(
            id: 'player',
            hp: 120,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'wait',
                category: PsdkBattleMoveCategory.status,
                power: 0,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'wild',
            hp: 120,
            currentHp: 1,
            catchRate: 255,
            majorStatus: PsdkBattleMajorStatus.sleep,
            moves: <PsdkBattleMoveData>[
              _move(id: 'tackle', power: 40),
            ],
          ),
          canCapture: true,
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 47,
          ),
        ),
      );

      session.submitPlayerChoice(const PlayerBattleChoiceCapture());
      final outcome = session.createLegacyOutcome(isTrainerBattle: false);

      expect(session.state.outcome?.kind, BattleEngineOutcomeKind.captured);
      expect(outcome.type, BattleOutcomeType.captured);
      expect(outcome.captureItemId, canonicalPokeBallItemId);
      expect(outcome.finalState.enemy.currentHp, 1);
      expect(outcome.finalState.enemy.majorStatus?.id, BattleMajorStatusId.slp);
    });

    test('writes back original Transform PP after a real PSDK transformation',
        () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
          player: _combatant(
            id: 'player_0',
            hp: 999,
            abilityId: 'limber',
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'transform',
                category: PsdkBattleMoveCategory.status,
                power: 0,
                battleEngineMethod: 's_transform',
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent_0',
            hp: 1,
            moves: <PsdkBattleMoveData>[
              _move(id: 'tackle', power: 200),
            ],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      expect(
        session.state.psdkState.battlerAt(psdkPlayerSlot).moves.single.id,
        'tackle',
      );
      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isTrue);

      final outcome = session.createLegacyOutcome(isTrainerBattle: false);
      expect(outcome.finalState.player.writeBackSpeciesId, 'player_0');
      expect(outcome.finalState.player.writeBackAbilityId, 'limber');

      final writtenBack = applyRuntimeBattleOutcomeToGameState(
        gameState: const GameState(
          saveId: 'psdk-transform-writeback',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'player_0',
                natureId: 'hardy',
                abilityId: 'limber',
                level: 50,
                knownMoveIds: <String>['transform'],
                currentPpByMoveId: <String, int>{'transform': 15},
                currentHp: 999,
              ),
            ],
          ),
        ),
        context: const RuntimeActiveBattleContext(
          request: WildBattleStartRequest(
            requestId: 'psdk-transform',
            createdAtEpochMs: 1,
            returnContext: OverworldReturnContext(
              mapId: 'field',
              playerPos: GridPos(x: 1, y: 1),
              playerFacing: Direction.south,
            ),
            mapId: 'field',
            encounterSourceId: 'grass',
            encounterSourceKind: EncounterSourceKind.gameplayZone,
            tableId: 'field-grass',
            encounterKind: EncounterKind.walk,
            speciesId: 'opponent_0',
            level: 50,
            minLevel: 50,
            maxLevel: 50,
            weight: 1,
            playerPos: GridPos(x: 1, y: 1),
          ),
          playerPartyIndex: 0,
        ),
        outcome: outcome,
      );

      expect(
        writtenBack.party.members.single.knownMoveIds,
        <String>['transform'],
      );
      expect(
        writtenBack.party.members.single.currentPpByMoveId,
        <String, int>{'transform': 14},
      );
    });

    test('persists the move learned by Sketch through a real PSDK outcome', () {
      final session = _copyMoveSession(
        moveId: 'sketch',
        battleEngineMethod: 's_sketch',
      );

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      session.submitPlayerChoice(const PlayerBattleChoiceFight(1));
      final player = session.state.psdkState.battlerAt(psdkPlayerSlot);
      expect(player.moves[1].id, 'target_move');
      expect(player.writeBackMoves[1].id, 'target_move');

      session.submitPlayerChoice(const PlayerBattleChoiceFight(1));
      expect(session.state.isFinished, isTrue);
      final writtenBack = _applySinglePlayerOutcome(
        session: session,
        saveId: 'psdk-sketch-writeback',
        moveIds: const <String>['wait', 'sketch'],
        currentPpByMoveId: const <String, int>{'wait': 15, 'sketch': 15},
      );

      expect(
        writtenBack.party.members.single.knownMoveIds,
        <String>['wait', 'target_move'],
      );
      expect(
        writtenBack.party.members.single.currentPpByMoveId,
        <String, int>{'wait': 14, 'target_move': 14},
      );
    });

    test('keeps Mimic battle-only through a real PSDK outcome', () {
      final session = _copyMoveSession(
        moveId: 'mimic',
        battleEngineMethod: 's_mimic',
      );

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      session.submitPlayerChoice(const PlayerBattleChoiceFight(1));
      final player = session.state.psdkState.battlerAt(psdkPlayerSlot);
      expect(player.moves[1].id, 'target_move');
      expect(player.writeBackMoves[1].id, 'mimic');

      session.submitPlayerChoice(const PlayerBattleChoiceFight(1));
      expect(session.state.isFinished, isTrue);
      final writtenBack = _applySinglePlayerOutcome(
        session: session,
        saveId: 'psdk-mimic-writeback',
        moveIds: const <String>['wait', 'mimic'],
        currentPpByMoveId: const <String, int>{'wait': 15, 'mimic': 15},
      );

      expect(
        writtenBack.party.members.single.knownMoveIds,
        <String>['wait', 'mimic'],
      );
      expect(
        writtenBack.party.members.single.currentPpByMoveId,
        <String, int>{'wait': 14, 'mimic': 14},
      );
    });

    test('writes back Lunar Dance PP restoration through the PSDK adapter', () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
          player: _combatant(
            id: 'player_0',
            hp: 999,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'lunar_dance',
                category: PsdkBattleMoveCategory.status,
                power: 0,
                battleEngineMethod: 's_lunar_dance',
                target: PsdkBattleMoveTarget.user,
              ),
            ],
          ),
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'player_1',
              hp: 999,
              currentHp: 20,
              majorStatus: PsdkBattleMajorStatus.burn,
              moves: <PsdkBattleMoveData>[
                _move(
                  id: 'reserve_strike',
                  power: 200,
                  pp: 20,
                  currentPp: 3,
                ),
              ],
            ),
          ],
          opponent: _combatant(
            id: 'opponent_0',
            hp: 1,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'opponent_wait',
                category: PsdkBattleMoveCategory.status,
                power: 0,
              ),
            ],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      session.submitPlayerChoice(const PlayerBattleChoiceSwitch(0));
      final replacement = session.state.psdkState.battlerAt(psdkPlayerSlot);
      expect(replacement.id, 'player_1');
      expect(replacement.currentHp, replacement.maxHp);
      expect(replacement.majorStatus, isNull);
      expect(replacement.writeBackMoves.single.currentPp, 20);

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isTrue);

      final writtenBack = applyRuntimeBattleOutcomeToGameState(
        gameState: const GameState(
          saveId: 'psdk-lunar-dance-writeback',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'player_0',
                natureId: 'hardy',
                abilityId: 'unknown',
                level: 50,
                knownMoveIds: <String>['lunar_dance'],
                currentPpByMoveId: <String, int>{'lunar_dance': 15},
                currentHp: 999,
              ),
              PlayerPokemon(
                speciesId: 'player_1',
                natureId: 'hardy',
                abilityId: 'unknown',
                level: 50,
                knownMoveIds: <String>['reserve_strike'],
                currentPpByMoveId: <String, int>{'reserve_strike': 3},
                currentHp: 20,
                statusId: 'burn',
              ),
            ],
          ),
        ),
        context: RuntimeActiveBattleContext.withLineupMapping(
          request: const WildBattleStartRequest(
            requestId: 'psdk-lunar-dance',
            createdAtEpochMs: 1,
            returnContext: OverworldReturnContext(
              mapId: 'field',
              playerPos: GridPos(x: 1, y: 1),
              playerFacing: Direction.south,
            ),
            mapId: 'field',
            encounterSourceId: 'grass',
            encounterSourceKind: EncounterSourceKind.gameplayZone,
            tableId: 'field-grass',
            encounterKind: EncounterKind.walk,
            speciesId: 'opponent_0',
            level: 50,
            minLevel: 50,
            maxLevel: 50,
            weight: 1,
            playerPos: GridPos(x: 1, y: 1),
          ),
          playerPartyIndex: 0,
          playerPartySlotIndicesByLineupIndex: <int>[0, 1],
        ),
        outcome: session.createLegacyOutcome(isTrainerBattle: false),
      );

      final restored = writtenBack.party.members[1];
      expect(restored.currentHp, 999);
      expect(restored.statusId, isEmpty);
      expect(
        restored.currentPpByMoveId,
        <String, int>{'reserve_strike': 19},
      );
    });

    test('projects exact switched participants into the legacy outcome', () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
          player: _combatant(
            id: 'player_0',
            hp: 100,
            moves: <PsdkBattleMoveData>[
              _move(id: 'active_wait', power: 0),
            ],
          ),
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'player_1',
              hp: 100,
              moves: <PsdkBattleMoveData>[
                _move(id: 'winning_move', power: 200),
              ],
            ),
            _combatant(
              id: 'player_2',
              hp: 100,
              moves: <PsdkBattleMoveData>[
                _move(id: 'unused_move', power: 200),
              ],
            ),
          ],
          opponent: _combatant(
            id: 'opponent_0',
            hp: 1,
            moves: <PsdkBattleMoveData>[
              _move(id: 'opponent_wait', power: 0),
            ],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );

      session.submitPlayerChoice(const PlayerBattleChoiceSwitch(0));
      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));

      final outcome = session.createLegacyOutcome(isTrainerBattle: false);
      expect(outcome.playerParticipantLineupIndexes, <int>{0, 1});
      expect(outcome.playerParticipantLineupIndexes, isNot(contains(2)));
      expect(
        () => outcome.playerParticipantLineupIndexes.add(2),
        throwsUnsupportedError,
      );
    });
  });
}

RuntimePsdkBattleSessionAdapter _sandstormSession({
  bool setWeather = false,
  int remainingTurns = 2,
  int playerHp = 160,
  bool withReserve = false,
}) {
  final wait = _move(
    id: 'splash',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    battleEngineMethod: 's_splash',
  );
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
      player: _combatant(
        id: 'player_0',
        hp: 160,
        currentHp: playerHp,
        moves: <PsdkBattleMoveData>[
          if (setWeather)
            _move(
              id: 'sandstorm',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              battleEngineMethod: 's_weather',
              target: PsdkBattleMoveTarget.allBattlers,
            )
          else
            wait,
        ],
      ),
      playerReserves: <PsdkBattleCombatantSetup>[
        if (withReserve)
          _combatant(id: 'player_1', hp: 160, moves: <PsdkBattleMoveData>[wait]),
      ],
      opponent: _combatant(
        id: 'opponent_0',
        hp: 160,
        moves: <PsdkBattleMoveData>[wait],
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 1,
        generic: 1,
      ),
      field: PsdkBattleFieldState(
        weather: setWeather
            ? null
            : PsdkBattleWeatherState(
                id: PsdkBattleWeatherId.sandstorm,
                remainingTurns: remainingTurns,
              ),
      ),
    ),
  );
}

RuntimePsdkBattleSessionAdapter _copyMoveSession({
  required String moveId,
  required String battleEngineMethod,
}) {
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
      player: _combatant(
        id: 'player_0',
        hp: 999,
        moves: <PsdkBattleMoveData>[
          _move(
            id: 'wait',
            category: PsdkBattleMoveCategory.status,
            power: 0,
          ),
          _move(
            id: moveId,
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: battleEngineMethod,
          ),
        ],
      ),
      opponent: _combatant(
        id: 'opponent_0',
        hp: 100,
        moves: <PsdkBattleMoveData>[
          _move(id: 'target_move', power: 200),
        ],
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 1,
        generic: 1,
      ),
    ),
  );
}

GameState _applySinglePlayerOutcome({
  required RuntimePsdkBattleSessionAdapter session,
  required String saveId,
  required List<String> moveIds,
  required Map<String, int> currentPpByMoveId,
}) {
  return applyRuntimeBattleOutcomeToGameState(
    gameState: GameState(
      saveId: saveId,
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'player_0',
            natureId: 'hardy',
            abilityId: 'unknown',
            level: 50,
            knownMoveIds: moveIds,
            currentPpByMoveId: currentPpByMoveId,
            currentHp: 999,
          ),
        ],
      ),
    ),
    context: const RuntimeActiveBattleContext(
      request: WildBattleStartRequest(
        requestId: 'psdk-copy-move',
        createdAtEpochMs: 1,
        returnContext: OverworldReturnContext(
          mapId: 'field',
          playerPos: GridPos(x: 1, y: 1),
          playerFacing: Direction.south,
        ),
        mapId: 'field',
        encounterSourceId: 'grass',
        encounterSourceKind: EncounterSourceKind.gameplayZone,
        tableId: 'field-grass',
        encounterKind: EncounterKind.walk,
        speciesId: 'opponent_0',
        level: 50,
        minLevel: 50,
        maxLevel: 50,
        weight: 1,
        playerPos: GridPos(x: 1, y: 1),
      ),
      playerPartyIndex: 0,
    ),
    outcome: session.createLegacyOutcome(isTrainerBattle: false),
  );
}

PsdkBattleSetup _setupWithOpponentReserve() {
  return PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant(
      id: 'player',
      hp: 200,
      moves: <PsdkBattleMoveData>[_move(id: 'tackle', power: 250)],
    ),
    opponent: _combatant(
      id: 'lead_foe',
      hp: 1,
      moves: <PsdkBattleMoveData>[_move(id: 'tackle', power: 1)],
    ),
    opponentReserves: <PsdkBattleCombatantSetup>[
      _combatant(
        id: 'reserve_foe',
        hp: 120,
        moves: <PsdkBattleMoveData>[_move(id: 'tackle', power: 1)],
      ),
    ],
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 1,
      generic: 1,
    ),
  );
}

PsdkBattleSetup _setup() {
  return PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant(
      id: 'player',
      hp: 120,
      moves: <PsdkBattleMoveData>[
        _move(
          id: 'wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
      ],
    ),
    opponent: _combatant(
      id: 'opponent',
      hp: 120,
      moves: <PsdkBattleMoveData>[
        _move(
          id: 'growl',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(stat: 'attack', stages: -1),
          ],
        ),
        _move(id: 'tackle', power: 40),
      ],
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 1,
      generic: 1,
    ),
  );
}

RuntimePsdkBattleSessionAdapter _trainerMedicineSession() {
  final wait = _move(
    id: 'trainer_wait',
    category: PsdkBattleMoveCategory.status,
    power: 0,
  );
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
      player: _combatant(id: 'player_0', hp: 100, moves: [wait]),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
      playerReserves: [
        _combatant(id: 'player_1', hp: 100, currentHp: 20, moves: [wait]),
      ],
      opponent: _combatant(
        id: 'opponent_0',
        hp: 100,
        currentHp: 20,
        moves: [wait],
      ),
    ),
    opponentAi: const PsdkBattleAi(
      canUseItem: true,
      itemOptions: [
        PsdkBattleAiItemOption.hpHeal(itemId: 'potion', amount: 20),
      ],
    ),
    itemDisplayNames: const {'potion': 'Potion du projet'},
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int hp,
  required List<PsdkBattleMoveData> moves,
  String? abilityId,
  int? currentHp,
  int? catchRate,
  PsdkBattleMajorStatus? majorStatus,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: hp,
    currentHp: currentHp ?? hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: 100,
    ),
    abilityId: abilityId,
    catchRate: catchRate,
    majorStatus: majorStatus,
    moves: moves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
  String? battleEngineMethod,
  int pp = 15,
  int? currentPp,
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: category,
    power: power,
    accuracy: 100,
    pp: pp,
    currentPp: currentPp ?? pp,
    priority: 0,
    battleEngineMethod: battleEngineMethod ??
        (category == PsdkBattleMoveCategory.status ? 's_status' : 's_basic'),
    target: target,
    stageMods: stageMods,
  );
}
