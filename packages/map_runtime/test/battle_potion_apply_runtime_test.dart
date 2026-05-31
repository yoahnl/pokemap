import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_bag_hp_heal_item_apply.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

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

RuntimePsdkBattleSessionAdapter _psdkSession({
  int currentHp = 30,
  int maxHp = 100,
  List<PsdkBattleCombatantSetup> playerReserves =
      const <PsdkBattleCombatantSetup>[],
}) {
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup.singles(
      player: _psdkCombatant(
        id: 'player_0',
        speciesId: 'sproutle',
        currentHp: currentHp,
        maxHp: maxHp,
      ),
      playerReserves: playerReserves,
      opponent: _psdkCombatant(
        id: 'opponent_0',
        speciesId: 'sparkitten',
        currentHp: 80,
        maxHp: 80,
        moves: <PsdkBattleMoveData>[_psdkMove(id: 'wait', power: 0)],
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 17,
        moveCritical: 23,
        moveAccuracy: 31,
        generic: 47,
      ),
    ),
  );
}

PsdkBattleCombatantSetup _psdkCombatant({
  required String id,
  required String speciesId,
  required int currentHp,
  required int maxHp,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId,
    displayName: speciesId,
    level: 20,
    maxHp: maxHp,
    currentHp: currentHp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: moves ?? <PsdkBattleMoveData>[_psdkMove(id: 'tackle', power: 40)],
  );
}

PsdkBattleMoveData _psdkMove({
  required String id,
  required int power,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: power <= 0
        ? PsdkBattleMoveCategory.status
        : PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: power <= 0
        ? PsdkBattleMoveTarget.user
        : PsdkBattleMoveTarget.adjacentFoe,
  );
}

void main() {
  group('tryApplyRuntimeBattleBagHpHealItemUse', () {
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
        isA<BattleActionBagHpHealItemUse>().having(
          (action) => action.itemKind,
          'itemKind',
          equals(BattleBagHpHealItemKind.potion),
        ),
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
        'super potion heals a damaged active target by 50 and consumes only super potion',
        () {
      final result = tryApplyRuntimeBattleSuperPotionUse(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 12,
            maxHp: 80,
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
              BagEntry(
                itemId: 'super-potion',
                categoryId: 'medicine',
                quantity: 2,
              ),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 12, level: 10),
          ],
        ),
        context: _context(
          playerPartyIndex: 0,
          lineupPartyIndices: const <int>[0],
        ),
        targetLineupIndex: 0,
      );

      expect(result, isNotNull);
      expect(result!.healedAmount, equals(50));
      expect(
        result.updatedSession.state.currentTurn!.playerAction,
        isA<BattleActionBagHpHealItemUse>().having(
          (action) => action.itemKind,
          'itemKind',
          equals(BattleBagHpHealItemKind.superPotion),
        ),
      );
      expect(result.updatedSession.state.player.currentHp, equals(62));
      expect(result.updatedGameState.party.members.first.currentHp, equals(62));
      expect(
        result.updatedGameState.bag.entries,
        const <BagEntry>[
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
          BagEntry(
            itemId: 'super-potion',
            categoryId: 'medicine',
            quantity: 1,
          ),
        ],
      );
    });

    test('super potion heal is capped at max hp', () {
      final result = tryApplyRuntimeBattleSuperPotionUse(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 60,
            maxHp: 80,
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
              BagEntry(
                itemId: 'super-potion',
                categoryId: 'medicine',
                quantity: 1,
              ),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 60),
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
      expect(result.updatedSession.state.player.currentHp, equals(80));
      expect(result.updatedGameState.party.members.first.currentHp, equals(80));
      expect(result.updatedGameState.bag.entries, isEmpty);
    });

    test(
        'hyper potion heals a damaged active target by 200 and consumes only hyper potion',
        () {
      final result = tryApplyRuntimeBattleHyperPotionUse(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 12,
            maxHp: 260,
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
              BagEntry(
                itemId: 'super-potion',
                categoryId: 'medicine',
                quantity: 2,
              ),
              BagEntry(
                itemId: 'hyper-potion',
                categoryId: 'medicine',
                quantity: 2,
              ),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 12, level: 10),
          ],
        ),
        context: _context(
          playerPartyIndex: 0,
          lineupPartyIndices: const <int>[0],
        ),
        targetLineupIndex: 0,
      );

      expect(result, isNotNull);
      expect(result!.healedAmount, equals(200));
      expect(
        result.updatedSession.state.currentTurn!.playerAction,
        isA<BattleActionBagHpHealItemUse>().having(
          (action) => action.itemKind,
          'itemKind',
          equals(BattleBagHpHealItemKind.hyperPotion),
        ),
      );
      expect(result.updatedSession.state.player.currentHp, equals(212));
      expect(
          result.updatedGameState.party.members.first.currentHp, equals(212));
      expect(
        result.updatedGameState.bag.entries,
        const Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
            BagEntry(
              itemId: 'super-potion',
              categoryId: 'medicine',
              quantity: 2,
            ),
            BagEntry(
              itemId: 'hyper-potion',
              categoryId: 'medicine',
              quantity: 1,
            ),
          ],
        ).normalized().entries,
      );
    });

    test('hyper potion heal is capped at max hp', () {
      final result = tryApplyRuntimeBattleHyperPotionUse(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 190,
            maxHp: 260,
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
              BagEntry(
                itemId: 'hyper-potion',
                categoryId: 'medicine',
                quantity: 1,
              ),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 190),
          ],
        ),
        context: _context(
          playerPartyIndex: 0,
          lineupPartyIndices: const <int>[0],
        ),
        targetLineupIndex: 0,
      );

      expect(result, isNotNull);
      expect(result!.healedAmount, equals(70));
      expect(result.updatedSession.state.player.currentHp, equals(260));
      expect(
          result.updatedGameState.party.members.first.currentHp, equals(260));
      expect(result.updatedGameState.bag.entries, isEmpty);
    });

    test(
        'max potion heals a damaged active target to max hp and consumes only max potion',
        () {
      final result = tryApplyRuntimeBattleMaxPotionUse(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 12,
            maxHp: 260,
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
              BagEntry(
                itemId: 'super-potion',
                categoryId: 'medicine',
                quantity: 2,
              ),
              BagEntry(
                itemId: 'hyper-potion',
                categoryId: 'medicine',
                quantity: 2,
              ),
              BagEntry(
                itemId: 'max-potion',
                categoryId: 'medicine',
                quantity: 2,
              ),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 12, level: 10),
          ],
        ),
        context: _context(
          playerPartyIndex: 0,
          lineupPartyIndices: const <int>[0],
        ),
        targetLineupIndex: 0,
      );

      expect(result, isNotNull);
      expect(result!.healedAmount, equals(248));
      expect(
        result.updatedSession.state.currentTurn!.playerAction,
        isA<BattleActionBagHpHealItemUse>()
            .having(
              (action) => action.itemKind,
              'itemKind',
              equals(BattleBagHpHealItemKind.maxPotion),
            )
            .having(
              (action) => action.effect,
              'effect',
              isA<BattleBagRestoreToFullHpHealEffect>(),
            ),
      );
      expect(result.updatedSession.state.player.currentHp, equals(260));
      expect(
          result.updatedGameState.party.members.first.currentHp, equals(260));
      expect(
        result.updatedGameState.bag.entries,
        const Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
            BagEntry(
              itemId: 'super-potion',
              categoryId: 'medicine',
              quantity: 2,
            ),
            BagEntry(
              itemId: 'hyper-potion',
              categoryId: 'medicine',
              quantity: 2,
            ),
            BagEntry(
              itemId: 'max-potion',
              categoryId: 'medicine',
              quantity: 1,
            ),
          ],
        ).normalized().entries,
      );
    });

    test('max potion removes the bag entry when quantity reaches zero', () {
      final result = tryApplyRuntimeBattleMaxPotionUse(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 190,
            maxHp: 260,
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
              BagEntry(
                itemId: 'max-potion',
                categoryId: 'medicine',
                quantity: 1,
              ),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 190),
          ],
        ),
        context: _context(
          playerPartyIndex: 0,
          lineupPartyIndices: const <int>[0],
        ),
        targetLineupIndex: 0,
      );

      expect(result, isNotNull);
      expect(result!.healedAmount, equals(70));
      expect(result.updatedSession.state.player.currentHp, equals(260));
      expect(
          result.updatedGameState.party.members.first.currentHp, equals(260));
      expect(result.updatedGameState.bag.entries, isEmpty);
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

    test('max potion use does not affect a full hp or fainted target', () {
      final fullHpState = _gameState(
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'max-potion', categoryId: 'medicine', quantity: 1),
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
        tryApplyRuntimeBattleMaxPotionUse(
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
            BagEntry(itemId: 'max-potion', categoryId: 'medicine', quantity: 1),
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
        tryApplyRuntimeBattleMaxPotionUse(
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

    test('PSDK HP medicines update battle state and runtime bag', () {
      const cases = <({
        String itemId,
        BattleBagHpHealItemKind kind,
        int currentHp,
        int maxHp,
        int expectedHp,
      })>[
        (
          itemId: 'potion',
          kind: BattleBagHpHealItemKind.potion,
          currentHp: 30,
          maxHp: 100,
          expectedHp: 50,
        ),
        (
          itemId: 'super-potion',
          kind: BattleBagHpHealItemKind.superPotion,
          currentHp: 30,
          maxHp: 100,
          expectedHp: 80,
        ),
        (
          itemId: 'hyper-potion',
          kind: BattleBagHpHealItemKind.hyperPotion,
          currentHp: 30,
          maxHp: 100,
          expectedHp: 100,
        ),
        (
          itemId: 'max-potion',
          kind: BattleBagHpHealItemKind.maxPotion,
          currentHp: 30,
          maxHp: 100,
          expectedHp: 100,
        ),
      ];

      for (final itemCase in cases) {
        final psdkSession = _psdkSession(
          currentHp: itemCase.currentHp,
          maxHp: itemCase.maxHp,
        );
        final displaySession = psdkSession.createLegacyDisplaySession(
          isTrainerBattle: true,
          trainerId: 'trainer',
        );
        final result = tryApplyRuntimePsdkBattleBagHpHealItemUse(
          psdkSession: psdkSession,
          displaySession: displaySession,
          gameState: _gameState(
            bag: Bag(
              entries: <BagEntry>[
                BagEntry(
                  itemId: itemCase.itemId,
                  categoryId: 'medicine',
                  quantity: 1,
                ),
              ],
            ),
            partyMembers: <PlayerPokemon>[
              _partyMember(
                speciesId: 'sproutle',
                currentHp: itemCase.currentHp,
              ),
            ],
          ),
          context: _context(
            playerPartyIndex: 0,
            lineupPartyIndices: const <int>[0],
          ),
          itemId: itemCase.itemId,
          targetLineupIndex: 0,
          isTrainerBattle: true,
          trainerId: 'trainer',
        );

        expect(result, isNotNull, reason: itemCase.itemId);
        expect(result!.itemKind, itemCase.kind);
        expect(result.updatedDisplaySession.state.player.currentHp,
            itemCase.expectedHp);
        expect(result.updatedGameState.party.members.first.currentHp,
            itemCase.expectedHp);
        expect(result.updatedGameState.bag.entries, isEmpty);
        expect(
          psdkSession.state.psdkState.battlerAt(psdkPlayerSlot).currentHp,
          itemCase.expectedHp,
        );
      }
    });

    test('PSDK HP medicines stay limited to the active battler', () {
      final psdkSession = _psdkSession(
        currentHp: 30,
        maxHp: 100,
        playerReserves: <PsdkBattleCombatantSetup>[
          _psdkCombatant(
            id: 'player_1',
            speciesId: 'sproutle',
            currentHp: 40,
            maxHp: 100,
          ),
        ],
      );
      final displaySession = psdkSession.createLegacyDisplaySession(
        isTrainerBattle: true,
        trainerId: 'trainer',
      );
      final gameState = _gameState(
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
          ],
        ),
        partyMembers: <PlayerPokemon>[
          _partyMember(speciesId: 'sproutle', currentHp: 30),
          _partyMember(speciesId: 'sproutle', currentHp: 40),
        ],
      );

      final result = tryApplyRuntimePsdkBattleBagHpHealItemUse(
        psdkSession: psdkSession,
        displaySession: displaySession,
        gameState: gameState,
        context: _context(
          playerPartyIndex: 0,
          lineupPartyIndices: const <int>[0, 1],
        ),
        itemId: 'potion',
        targetLineupIndex: 1,
        isTrainerBattle: true,
        trainerId: 'trainer',
      );

      expect(result, isNull);
      expect(gameState.bag.entries.single.quantity, equals(1));
      expect(psdkSession.state.psdkState.battlerAt(psdkPlayerSlot).currentHp,
          equals(30));
    });
  });
}
