import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';

const _outcomeTestStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

void main() {
  test(
      'RuntimeActiveBattleContext defensively copies lineup mapping and exposes it read-only',
      () {
    final sourceMapping = <int>[2, 0];
    final context = RuntimeActiveBattleContext.withLineupMapping(
      request: _wildRequest(),
      playerPartyIndex: 2,
      playerPartySlotIndicesByLineupIndex: sourceMapping,
    );

    sourceMapping
      ..[0] = 1
      ..add(3);

    expect(context.playerPartySlotIndicesByLineupIndex, <int>[2, 0]);
    expect(
      context.playerPartySlotIndicesByLineupIndex.clear,
      throwsUnsupportedError,
    );
  });

  group('applyRuntimeBattleOutcomeToGameState', () {
    test('writes back the exact party slot used for the battle handoff', () {
      const initialState = GameState(
        saveId: 'save-slot',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'slot_zero',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 40,
              knownMoveIds: <String>['a'],
              currentHp: 91,
            ),
            PlayerPokemon(
              speciesId: 'slot_one_active',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 20,
              knownMoveIds: <String>['b'],
              currentHp: 35,
            ),
            PlayerPokemon(
              speciesId: 'slot_two_stays_alive',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 22,
              knownMoveIds: <String>['c'],
              currentHp: 18,
            ),
          ],
        ),
      );

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: initialState,
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 1,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.defeat,
          playerCurrentHp: 0,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(91));
      expect(updatedState.party.members[1].currentHp, equals(0));
      expect(updatedState.party.members[2].currentHp, equals(18));
    });

    test(
        'writes back every engaged player lineup member to its exact runtime party slot after switches',
        () {
      const initialState = GameState(
        saveId: 'save-switch-lineup',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'slot_zero_bench',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 18,
              knownMoveIds: <String>['a'],
              currentHp: 44,
            ),
            PlayerPokemon(
              speciesId: 'slot_one_initial_active',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 20,
              knownMoveIds: <String>['b'],
              currentHp: 35,
            ),
            PlayerPokemon(
              speciesId: 'slot_two_unused',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 22,
              knownMoveIds: <String>['c'],
              currentHp: 18,
            ),
          ],
        ),
      );

      final outcome = BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: BattleState(
          phase: BattlePhase.finished,
          player: const BattleCombatant(
            speciesId: 'slot_zero_bench',
            lineupIndex: 1,
            level: 18,
            currentHp: 9,
            maxHp: 44,
            stats: _outcomeTestStats,
            moves: <BattleMove>[
              BattleMove(id: 'a', name: 'a', power: 10),
            ],
          ),
          playerReserve: const <BattleCombatant>[
            BattleCombatant(
              speciesId: 'slot_one_initial_active',
              lineupIndex: 0,
              level: 20,
              currentHp: 3,
              maxHp: 35,
              stats: _outcomeTestStats,
              moves: <BattleMove>[
                BattleMove(id: 'b', name: 'b', power: 10),
              ],
            ),
          ],
          enemy: const BattleCombatant(
            speciesId: 'enemy',
            level: 20,
            currentHp: 0,
            maxHp: 30,
            stats: _outcomeTestStats,
            moves: <BattleMove>[
              BattleMove(id: 'x', name: 'x', power: 10),
            ],
          ),
          currentTurn: null,
          outcome: null,
        ),
      );

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: initialState,
        context: RuntimeActiveBattleContext.withLineupMapping(
          request: _wildRequest(),
          playerPartyIndex: 1,
          playerPartySlotIndicesByLineupIndex: const <int>[1, 0],
        ),
        outcome: outcome,
      );

      expect(updatedState.party.members[0].currentHp, equals(9));
      expect(updatedState.party.members[1].currentHp, equals(3));
      expect(updatedState.party.members[2].currentHp, equals(18));
    });

    for (final outcomeType in <BattleOutcomeType>[
      BattleOutcomeType.victory,
      BattleOutcomeType.defeat,
      BattleOutcomeType.runaway,
    ]) {
      test(
          'writes HP PP and status by lineupIndex after ${outcomeType.name} while leaving the unused slot unchanged',
          () {
        const initialState = GameState(
          saveId: 'save-full-writeback',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'same_species',
                natureId: 'hardy',
                abilityId: 'pressure',
                level: 18,
                knownMoveIds: <String>['a'],
                currentPpByMoveId: <String, int>{'a': 9},
                currentHp: 44,
              ),
              PlayerPokemon(
                speciesId: 'same_species',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 20,
                knownMoveIds: <String>['b'],
                currentPpByMoveId: <String, int>{'b': 8},
                currentHp: 35,
              ),
              PlayerPokemon(
                speciesId: 'same_species',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 22,
                knownMoveIds: <String>['c'],
                currentPpByMoveId: <String, int>{'c': 7},
                currentHp: 18,
                statusId: 'frz',
              ),
            ],
          ),
        );
        final outcome = BattleOutcome(
          type: outcomeType,
          finalState: BattleState(
            phase: BattlePhase.finished,
            player: const BattleCombatant(
              speciesId: 'same_species',
              lineupIndex: 1,
              level: 18,
              currentHp: 9,
              maxHp: 44,
              stats: _outcomeTestStats,
              majorStatus: BattleMajorStatusState.brn(),
              moves: <BattleMove>[
                BattleMove(
                  id: 'a',
                  name: 'a',
                  power: 10,
                  pp: 10,
                  currentPp: 2,
                ),
              ],
            ),
            playerReserve: const <BattleCombatant>[
              BattleCombatant(
                speciesId: 'same_species',
                lineupIndex: 0,
                level: 20,
                currentHp: 3,
                maxHp: 35,
                stats: _outcomeTestStats,
                majorStatus: BattleMajorStatusState.slp(),
                moves: <BattleMove>[
                  BattleMove(
                    id: 'b',
                    name: 'b',
                    power: 10,
                    pp: 10,
                    currentPp: 1,
                  ),
                ],
              ),
            ],
            enemy: const BattleCombatant(
              speciesId: 'enemy',
              level: 20,
              currentHp: 0,
              maxHp: 30,
              stats: _outcomeTestStats,
              moves: <BattleMove>[
                BattleMove(id: 'x', name: 'x', power: 10),
              ],
            ),
            currentTurn: null,
            outcome: null,
          ),
        );

        final updatedState = applyRuntimeBattleOutcomeToGameState(
          gameState: initialState,
          context: RuntimeActiveBattleContext.withLineupMapping(
            request: _wildRequest(),
            playerPartyIndex: 1,
            playerPartySlotIndicesByLineupIndex: const <int>[1, 0],
          ),
          outcome: outcome,
        );

        expect(updatedState.party.members[0].currentHp, 9);
        expect(updatedState.party.members[0].currentPpByMoveId, {'a': 2});
        expect(updatedState.party.members[0].statusId, 'brn');
        expect(updatedState.party.members[1].currentHp, 3);
        expect(updatedState.party.members[1].currentPpByMoveId, {'b': 1});
        expect(updatedState.party.members[1].statusId, 'slp');
        expect(updatedState.party.members[2], initialState.party.members[2]);
      });
    }

    test('does not persist temporary battle moves for an explicit move set',
        () {
      const initialState = GameState(
        saveId: 'save-explicit-moves',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'copycat',
              natureId: 'hardy',
              abilityId: 'trace',
              level: 18,
              knownMoveIds: <String>['tackle'],
              currentPpByMoveId: <String, int>{'tackle': 12},
              currentHp: 30,
            ),
          ],
        ),
      );
      final outcome = BattleOutcome(
        type: BattleOutcomeType.runaway,
        finalState: BattleState(
          phase: BattlePhase.finished,
          player: const BattleCombatant(
            speciesId: 'copycat',
            level: 18,
            currentHp: 25,
            maxHp: 30,
            stats: _outcomeTestStats,
            moves: <BattleMove>[
              BattleMove(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                pp: 35,
                currentPp: 11,
              ),
              BattleMove(
                id: 'temporary_copy',
                name: 'Temporary Copy',
                power: 60,
                pp: 5,
                currentPp: 4,
              ),
            ],
            writeBackMoves: <BattleMove>[
              BattleMove(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                pp: 35,
                currentPp: 11,
              ),
            ],
            hasTemporaryBattleMoves: true,
          ),
          enemy: const BattleCombatant(
            speciesId: 'enemy',
            level: 10,
            currentHp: 10,
            maxHp: 20,
            stats: _outcomeTestStats,
            moves: <BattleMove>[
              BattleMove(id: 'wait', name: 'Wait', power: 0),
            ],
          ),
          currentTurn: null,
          outcome: null,
        ),
      );

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: initialState,
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 0,
        ),
        outcome: outcome,
      );

      expect(
          updatedState.party.members.single.knownMoveIds, <String>['tackle']);
      expect(
        updatedState.party.members.single.currentPpByMoveId,
        <String, int>{'tackle': 11},
      );
    });

    test('preserves known moves and PP that were filtered before battle', () {
      const initialState = GameState(
        saveId: 'save-filtered-move',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'mixed-moves',
              natureId: 'hardy',
              abilityId: 'trace',
              level: 18,
              knownMoveIds: <String>['unsupported_move', 'tackle'],
              currentPpByMoveId: <String, int>{
                'unsupported_move': 7,
                'tackle': 12,
              },
              currentHp: 30,
            ),
          ],
        ),
      );
      final outcome = BattleOutcome(
        type: BattleOutcomeType.runaway,
        finalState: BattleState(
          phase: BattlePhase.finished,
          player: const BattleCombatant(
            speciesId: 'mixed-moves',
            level: 18,
            currentHp: 25,
            maxHp: 30,
            stats: _outcomeTestStats,
            moves: <BattleMove>[
              BattleMove(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                pp: 35,
                currentPp: 11,
              ),
            ],
          ),
          enemy: const BattleCombatant(
            speciesId: 'enemy',
            level: 10,
            currentHp: 10,
            maxHp: 20,
            stats: _outcomeTestStats,
            moves: <BattleMove>[
              BattleMove(id: 'wait', name: 'Wait', power: 0),
            ],
          ),
          currentTurn: null,
          outcome: null,
        ),
      );

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: initialState,
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 0,
        ),
        outcome: outcome,
      );

      expect(
        updatedState.party.members.single.knownMoveIds,
        <String>['unsupported_move', 'tackle'],
      );
      expect(
        updatedState.party.members.single.currentPpByMoveId,
        <String, int>{'unsupported_move': 7, 'tackle': 11},
      );
    });

    test(
        'rejects the legacy mono-slot fallback when the final player lineup actually contains BE10 reserves',
        () {
      const initialState = GameState(
        saveId: 'save-switch-lineup-missing-mapping',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'slot_zero_bench',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 18,
              knownMoveIds: <String>['a'],
              currentHp: 44,
            ),
            PlayerPokemon(
              speciesId: 'slot_one_initial_active',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 20,
              knownMoveIds: <String>['b'],
              currentHp: 35,
            ),
          ],
        ),
      );

      final outcome = BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: BattleState(
          phase: BattlePhase.finished,
          player: const BattleCombatant(
            speciesId: 'slot_zero_bench',
            lineupIndex: 1,
            level: 18,
            currentHp: 9,
            maxHp: 44,
            stats: _outcomeTestStats,
            moves: <BattleMove>[
              BattleMove(id: 'a', name: 'a', power: 10),
            ],
          ),
          playerReserve: const <BattleCombatant>[
            BattleCombatant(
              speciesId: 'slot_one_initial_active',
              lineupIndex: 0,
              level: 20,
              currentHp: 3,
              maxHp: 35,
              stats: _outcomeTestStats,
              moves: <BattleMove>[
                BattleMove(id: 'b', name: 'b', power: 10),
              ],
            ),
          ],
          enemy: const BattleCombatant(
            speciesId: 'enemy',
            level: 20,
            currentHp: 0,
            maxHp: 30,
            stats: _outcomeTestStats,
            moves: <BattleMove>[
              BattleMove(id: 'x', name: 'x', power: 10),
            ],
          ),
          currentTurn: null,
          outcome: null,
        ),
      );

      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: initialState,
          context: RuntimeActiveBattleContext(
            request: _wildRequest(),
            playerPartyIndex: 1,
          ),
          outcome: outcome,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            contains('playerPartySlotIndicesByLineupIndex'),
          ),
        ),
      );
    });

    test('trainer victory writes player hp and marks trainer as defeated', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.victory,
          playerCurrentHp: 14,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(14));
      expect(
        updatedState.storyFlags.activeFlags,
        contains('trainer_defeated:ace_jules'),
      );
    });

    test('trainer defeat writes player hp without marking trainer defeated',
        () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.defeat,
          playerCurrentHp: 0,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(0));
      expect(
        updatedState.storyFlags.activeFlags,
        isNot(contains('trainer_defeated:ace_jules')),
      );
    });

    test('runaway writes player hp without marking trainer defeated', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.runaway,
          playerCurrentHp: 11,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(11));
      expect(
        updatedState.storyFlags.activeFlags,
        isNot(contains('trainer_defeated:ace_jules')),
      );
    });

    test('captured wild battle appends the pokemon and syncs caught/seen', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.captured,
          playerCurrentHp: 19,
          enemySpeciesId: 'wildmon',
          enemyLevel: 12,
          enemyCurrentHp: 7,
          enemyAbilityId: 'intimidate',
          enemyMoveIds: const <String>['scratch', 'leer'],
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(19));
      expect(updatedState.party.members, hasLength(3));

      final captured = updatedState.party.members.last;
      expect(captured.speciesId, equals('wildmon'));
      expect(captured.level, equals(12));
      expect(captured.abilityId, equals('intimidate'));
      expect(captured.natureId, equals('hardy'));
      expect(captured.knownMoveIds, equals(<String>['scratch', 'leer']));
      expect(
        captured.currentPpByMoveId,
        equals(<String, int>{'scratch': 35, 'leer': 35}),
      );
      expect(captured.currentHp, equals(7));
      expect(
        updatedState.bag.entries,
        equals(
          const <BagEntry>[
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
      );
      expect(updatedState.progression.caughtSpeciesIds, contains('wildmon'));
      expect(updatedState.progression.seenSpeciesIds, contains('wildmon'));
    });

    test('captures the original wild identity and moves after a real Transform',
        () {
      var battle = createBattleSession(
        const BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'player-sproutle',
            level: 12,
            maxHp: 32,
            currentHp: 23,
            stats: _outcomeTestStats,
            abilityId: 'overgrow',
            moves: <BattleMoveData>[
              BattleMoveData(
                id: 'wait',
                name: 'Wait',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.self,
                accuracy: BattleMoveAccuracy.alwaysHits(),
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'wild-ditto',
            level: 15,
            maxHp: 40,
            currentHp: 31,
            stats: BattleStatsSnapshot(
              attack: 20,
              defense: 20,
              specialAttack: 20,
              specialDefense: 20,
              speed: 100,
            ),
            abilityId: 'limber',
            moves: <BattleMoveData>[
              BattleMoveData(
                id: 'transform',
                name: 'Transform',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.opponent,
                accuracy: BattleMoveAccuracy.alwaysHits(),
                pp: 10,
                currentPp: 10,
                copiesTargetOnHit: true,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
          allowCapture: true,
        ),
      );

      battle = battle.applyChoice(const PlayerBattleChoiceFight(0));
      expect(battle.state.enemy.speciesId, 'player-sproutle');
      expect(battle.state.enemy.abilityId, 'overgrow');
      expect(battle.state.enemy.moves.single.id, 'wait');
      expect(battle.state.enemy.writeBackSpeciesId, 'wild-ditto');
      expect(battle.state.enemy.writeBackAbilityId, 'limber');
      expect(battle.state.enemy.writeBackMoves.single.id, 'transform');
      expect(battle.state.enemy.writeBackMoves.single.currentPp, 9);

      battle = battle.applyChoice(const PlayerBattleChoiceCapture());
      expect(battle.state.outcome?.isCaptured, isTrue);

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: const GameState(
          saveId: 'capture-transformed-wild',
          bag: Bag(
            entries: <BagEntry>[
              BagEntry(
                itemId: 'poke-ball',
                categoryId: 'items',
                quantity: 1,
              ),
            ],
          ),
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'player-sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['wait'],
                currentPpByMoveId: <String, int>{'wait': 35},
                currentHp: 23,
              ),
            ],
          ),
        ),
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 0,
        ),
        outcome: battle.state.outcome!,
      );

      final captured = updatedState.party.members.last;
      expect(captured.speciesId, 'wild-ditto');
      expect(captured.abilityId, 'limber');
      expect(captured.knownMoveIds, <String>['transform']);
      expect(captured.currentPpByMoveId, <String, int>{'transform': 9});
      expect(captured.level, 15);
      expect(captured.currentHp, 31);
    });

    test('captured outcome removes the poke-ball entry when quantity reaches 0',
        () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState().copyWith(
          bag: const Bag(
            entries: <BagEntry>[
              BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
              BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
            ],
          ),
        ),
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.captured,
          playerCurrentHp: 19,
          enemySpeciesId: 'wildmon',
          enemyLevel: 12,
          enemyCurrentHp: 7,
          enemyAbilityId: 'intimidate',
          enemyMoveIds: const <String>['scratch'],
        ),
      );

      expect(
        updatedState.bag.entries,
        equals(
          const <BagEntry>[
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
      );
    });

    test('captured outcome is rejected for trainer battles', () {
      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: _baseState(),
          context: RuntimeActiveBattleContext(
            request: _trainerRequest(trainerId: 'ace_jules'),
            playerPartyIndex: 0,
          ),
          outcome: _finishedOutcome(
            type: BattleOutcomeType.captured,
            playerCurrentHp: 19,
            enemySpeciesId: 'wildmon',
            enemyLevel: 12,
            enemyCurrentHp: 7,
            enemyAbilityId: 'intimidate',
            enemyMoveIds: const <String>['scratch'],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('captured wild battle stores the pokemon when party is already full',
        () {
      final fullPartyState = _baseState().copyWith(
        party: PlayerParty(
          members: <PlayerPokemon>[
            ..._baseState().party.members,
            const PlayerPokemon(
              speciesId: 'party_2',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_3',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_4',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_5',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
          ],
        ),
      );

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: fullPartyState,
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.captured,
          playerCurrentHp: 19,
          enemySpeciesId: 'wildmon',
          enemyLevel: 12,
          enemyCurrentHp: 7,
          enemyAbilityId: 'intimidate',
          enemyMoveIds: const <String>['scratch'],
        ),
      );

      expect(updatedState.party.members, hasLength(6));
      expect(updatedState.pokemonStorage.storedPokemon, hasLength(1));
      expect(
        updatedState.pokemonStorage.storedPokemon.single.speciesId,
        'wildmon',
      );
      expect(updatedState.progression.caughtSpeciesIds, contains('wildmon'));
      expect(updatedState.progression.seenSpeciesIds, contains('wildmon'));
      expect(
        updatedState.bag.entries,
        equals(
          const <BagEntry>[
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
      );
    });

    test('captured outcome is rejected when the bag has no poke-ball', () {
      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: _baseState().copyWith(
            bag: const Bag(
              entries: <BagEntry>[
                BagEntry(
                  itemId: 'potion',
                  categoryId: 'medicine',
                  quantity: 3,
                ),
              ],
            ),
          ),
          context: RuntimeActiveBattleContext(
            request: _wildRequest(),
            playerPartyIndex: 0,
          ),
          outcome: _finishedOutcome(
            type: BattleOutcomeType.captured,
            playerCurrentHp: 19,
            enemySpeciesId: 'wildmon',
            enemyLevel: 12,
            enemyCurrentHp: 7,
            enemyAbilityId: 'intimidate',
            enemyMoveIds: const <String>['scratch'],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('applyRuntimeDefeatRecoveryToGameState', () {
    test(
        'revives the exact battle slot to 1 HP when the whole party is KO after defeat',
        () {
      const defeatedState = GameState(
        saveId: 'whiteout-lite',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'slot_zero',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 12,
              knownMoveIds: <String>['growl'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'active_slot',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 18,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'slot_two',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 17,
              knownMoveIds: <String>['water_gun'],
              currentHp: 0,
            ),
          ],
        ),
      );

      final recoveredState = applyRuntimeDefeatRecoveryToGameState(
        gameState: defeatedState,
        playerPartyIndex: 1,
      );

      expect(recoveredState.party.members[0].currentHp, equals(0));
      expect(recoveredState.party.members[1].currentHp, equals(1));
      expect(recoveredState.party.members[2].currentHp, equals(0));
    });

    test(
        'revives the switched-in active slot instead of the original handoff slot after BE10 switches',
        () {
      const defeatedState = GameState(
        saveId: 'whiteout-lite-switched-active',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'initial_active_slot',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 12,
              knownMoveIds: <String>['growl'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'switched_in_active_slot',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 18,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'unused_slot',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 17,
              knownMoveIds: <String>['water_gun'],
              currentHp: 0,
            ),
          ],
        ),
      );

      final recoveredState = applyRuntimeDefeatRecoveryToGameState(
        gameState: defeatedState,
        playerPartyIndex: 0,
        activePlayerLineupIndex: 1,
        playerPartySlotIndicesByLineupIndex: const <int>[0, 1],
      );

      expect(recoveredState.party.members[0].currentHp, equals(0));
      expect(recoveredState.party.members[1].currentHp, equals(1));
      expect(recoveredState.party.members[2].currentHp, equals(0));
    });

    test('does not heal the party when another member is already usable', () {
      const defeatedState = GameState(
        saveId: 'whiteout-lite-benched',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'active_slot',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 18,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'bench_survivor',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 22,
              knownMoveIds: <String>['water_gun'],
              currentHp: 9,
            ),
          ],
        ),
      );

      final recoveredState = applyRuntimeDefeatRecoveryToGameState(
        gameState: defeatedState,
        playerPartyIndex: 0,
      );

      expect(recoveredState.party.members[0].currentHp, equals(0));
      expect(recoveredState.party.members[1].currentHp, equals(9));
    });
  });
}

GameState _baseState() {
  return const GameState(
    saveId: 'save-1',
    bag: Bag(
      entries: <BagEntry>[
        BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
        BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
      ],
    ),
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
        PlayerPokemon(
          speciesId: 'benchmon',
          natureId: 'hardy',
          abilityId: 'pressure',
          level: 18,
          knownMoveIds: <String>['leer'],
          currentHp: 17,
        ),
      ],
    ),
  );
}

BattleOutcome _finishedOutcome({
  required BattleOutcomeType type,
  required int playerCurrentHp,
  String enemySpeciesId = 'aquafi',
  int enemyLevel = 18,
  int enemyCurrentHp = 0,
  String enemyAbilityId = 'torrent',
  List<String> enemyMoveIds = const <String>['water_gun'],
}) {
  final finalState = BattleState(
    phase: BattlePhase.finished,
    player: BattleCombatant(
      speciesId: 'sproutle',
      level: 12,
      currentHp: playerCurrentHp,
      maxHp: 32,
      stats: _outcomeTestStats,
      moves: const <BattleMove>[
        BattleMove(id: 'growl', name: 'Growl', power: 0),
      ],
    ),
    enemy: BattleCombatant(
      speciesId: enemySpeciesId,
      level: enemyLevel,
      currentHp: enemyCurrentHp,
      maxHp: 35,
      stats: _outcomeTestStats,
      abilityId: enemyAbilityId,
      moves: enemyMoveIds
          .map(
            (moveId) => BattleMove(
              id: moveId,
              name: moveId,
              power: 10,
            ),
          )
          .toList(growable: false),
    ),
    currentTurn: null,
    outcome: null,
  );

  return BattleOutcome(
    type: type,
    finalState: finalState,
  );
}

WildBattleStartRequest _wildRequest() {
  return const WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: 'wildmon',
    level: 12,
    minLevel: 12,
    maxLevel: 12,
    weight: 30,
    playerPos: GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest({required String trainerId}) {
  return TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: trainerId,
    npcEntityId: 'npc_ace',
    mapId: 'field_map',
    playerPos: const GridPos(x: 1, y: 1),
  );
}
