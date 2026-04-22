import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_potion_apply.dart';

BattleStatsSnapshot _stats() {
  return const BattleStatsSnapshot(
    attack: 60,
    defense: 60,
    specialAttack: 60,
    specialDefense: 60,
    speed: 60,
  );
}

BattleMoveData _move({
  required String id,
  required String name,
  int power = 40,
}) {
  return BattleMoveData(
    id: id,
    name: name,
    power: power,
    type: 'normal',
    category:
        power <= 0 ? BattleMoveCategory.status : BattleMoveCategory.physical,
    target: power <= 0 ? BattleMoveTarget.self : BattleMoveTarget.opponent,
    accuracy: power <= 0
        ? const BattleMoveAccuracy.alwaysHits()
        : const BattleMoveAccuracy.percent(value: 100),
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int level = 30,
  int maxHp = 40,
  int? currentHp,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: level,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: _stats(),
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      isTrainerBattle: true,
      trainerId: 'trainer',
    ),
  );
}

PlayerPokemon _partyMember({
  required String speciesId,
  int level = 10,
  int currentHp = 20,
}) {
  return PlayerPokemon(
    speciesId: speciesId,
    natureId: 'hardy',
    abilityId: 'pressure',
    level: level,
    knownMoveIds: const <String>['tackle'],
    currentHp: currentHp,
  );
}

GameState _gameState({
  required Bag bag,
  required List<PlayerPokemon> partyMembers,
}) {
  return GameState(
    saveId: 'battle-potion-runtime',
    bag: bag,
    party: PlayerParty(members: partyMembers),
  );
}

RuntimeActiveBattleContext _context({
  required int playerPartyIndex,
  required List<int> lineupPartyIndices,
}) {
  return RuntimeActiveBattleContext(
    request: const TrainerBattleStartRequest(
      requestId: 'trainer-request',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: 'field_map',
        playerPos: GridPos(x: 1, y: 1),
        playerFacing: Direction.north,
      ),
      trainerId: 'trainer',
      npcEntityId: 'npc_trainer',
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
    ),
    playerPartyIndex: playerPartyIndex,
    playerPartySlotIndicesByLineupIndex: lineupPartyIndices,
  );
}

void main() {
  group('tryApplyRuntimeBattlePotionUse', () {
    test('potion heals a damaged active target by 20 and consumes one item',
        () {
      final result = tryApplyRuntimeBattlePotionUse(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 12,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          enemy: _combatant(
            speciesId: 'enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
          ),
        ),
        gameState: _gameState(
          bag: const Bag(
            entries: <BagEntry>[
              BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 12),
          ],
        ),
        context: _context(
          playerPartyIndex: 0,
          lineupPartyIndices: const <int>[0],
        ),
        targetLineupIndex: 0,
      );

      expect(result, isNotNull);
      expect(result!.healedAmount, equals(20));
      expect(result.updatedSession.state.currentTurn, isNotNull);
      expect(
        result.updatedSession.state.currentTurn!.playerAction,
        isA<BattleActionPotionUse>(),
      );
      expect(result.updatedSession.state.player.currentHp, equals(32));
      expect(result.updatedGameState.party.members.first.currentHp, equals(32));
      expect(
        result.updatedGameState.bag.entries,
        const <BagEntry>[
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
        ],
      );
    });

    test('potion heal is capped at max hp', () {
      final result = tryApplyRuntimeBattlePotionUse(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 35,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          enemy: _combatant(
            speciesId: 'enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
          ),
        ),
        gameState: _gameState(
          bag: const Bag(
            entries: <BagEntry>[
              BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 35),
          ],
        ),
        context: _context(
          playerPartyIndex: 0,
          lineupPartyIndices: const <int>[0],
        ),
        targetLineupIndex: 0,
      );

      expect(result, isNotNull);
      expect(result!.healedAmount, equals(5));
      expect(result.updatedSession.state.currentTurn, isNotNull);
      expect(result.updatedSession.state.player.currentHp, equals(40));
      expect(result.updatedGameState.party.members.first.currentHp, equals(40));
    });

    test(
        'potion use removes the bag entry when quantity reaches zero and targets the intended reserve by lineup identity',
        () {
      final result = tryApplyRuntimeBattlePotionUse(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 1,
            currentHp: 22,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'sproutle',
              lineupIndex: 0,
              currentHp: 35,
              maxHp: 40,
              moves: <BattleMoveData>[
                _move(id: 'wait', name: 'Wait', power: 0)
              ],
            ),
          ],
          enemy: _combatant(
            speciesId: 'enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
          ),
        ),
        gameState: _gameState(
          bag: const Bag(
            entries: <BagEntry>[
              BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 22),
            _partyMember(speciesId: 'sproutle', currentHp: 35),
          ],
        ),
        context: _context(
          playerPartyIndex: 0,
          lineupPartyIndices: const <int>[1, 0],
        ),
        targetLineupIndex: 0,
      );

      expect(result, isNotNull);
      expect(result!.healedAmount, equals(5));
      expect(result.updatedSession.state.currentTurn, isNotNull);
      expect(result.updatedSession.state.player.currentHp, equals(22));
      expect(
        result.updatedSession.state.playerReserve.single.currentHp,
        equals(40),
      );
      expect(result.updatedGameState.party.members[0].currentHp, equals(22));
      expect(result.updatedGameState.party.members[1].currentHp, equals(40));
      expect(result.updatedGameState.bag.entries, isEmpty);
    });

    test('potion use does not affect a full hp or fainted target', () {
      final fullHpState = _gameState(
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
          ],
        ),
        partyMembers: <PlayerPokemon>[
          _partyMember(speciesId: 'sproutle', currentHp: 40),
        ],
      );
      final fullHpSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 40,
          maxHp: 40,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
        ),
      );

      expect(
        tryApplyRuntimeBattlePotionUse(
          session: fullHpSession,
          gameState: fullHpState,
          context: _context(
            playerPartyIndex: 0,
            lineupPartyIndices: const <int>[0],
          ),
          targetLineupIndex: 0,
        ),
        isNull,
      );
      expect(fullHpSession.state.player.currentHp, equals(40));
      expect(fullHpState.party.members.first.currentHp, equals(40));
      expect(fullHpState.bag.entries.single.quantity, equals(1));

      final faintedState = _gameState(
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
          ],
        ),
        partyMembers: <PlayerPokemon>[
          _partyMember(speciesId: 'sproutle', currentHp: 0),
        ],
      );
      final faintedSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 0,
          maxHp: 40,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
        ),
      );

      expect(
        tryApplyRuntimeBattlePotionUse(
          session: faintedSession,
          gameState: faintedState,
          context: _context(
            playerPartyIndex: 0,
            lineupPartyIndices: const <int>[0],
          ),
          targetLineupIndex: 0,
        ),
        isNull,
      );
      expect(faintedSession.state.player.currentHp, equals(0));
      expect(faintedState.party.members.first.currentHp, equals(0));
      expect(faintedState.bag.entries.single.quantity, equals(1));
    });
  });
}
