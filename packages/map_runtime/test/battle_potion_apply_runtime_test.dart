import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_bag_hp_heal_item_apply.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

final _itemCatalog = ItemCatalogSnapshot.fromCatalog(mvpItemCatalog);

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
  return RuntimeActiveBattleContext.withLineupMapping(
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
  group('tryApplyRuntimeBattleItemUse', () {
    test('potion heals a damaged active target by 20 and consumes one item',
        () {
      final result = tryApplyRuntimeBattleItemUse(
        itemId: 'potion',
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
              BagEntry(itemId: 'potion', quantity: 2),
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
        itemCatalog: _itemCatalog,
      );

      expect(result, isNotNull);
      expect(result!.appliedAmount, equals(20));
      expect(result.updatedSession.state.currentTurn, isNotNull);
      expect(
        result.updatedSession.state.currentTurn!.playerAction,
        isA<BattleActionBagHpHealItemUse>().having(
          (action) => action.itemId,
          'itemKind',
          equals('potion'),
        ),
      );
      expect(result.updatedSession.state.player.currentHp, equals(32));
      expect(result.updatedGameState.party.members.first.currentHp, equals(32));
      expect(
        result.updatedGameState.bag.entries,
        const <BagEntry>[
          BagEntry(itemId: 'potion', quantity: 1),
        ],
      );
    });

    test('potion heal is capped at max hp', () {
      final result = tryApplyRuntimeBattleItemUse(
        itemId: 'potion',
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
              BagEntry(itemId: 'potion', quantity: 2),
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
        itemCatalog: _itemCatalog,
      );

      expect(result, isNotNull);
      expect(result!.appliedAmount, equals(5));
      expect(result.updatedSession.state.currentTurn, isNotNull);
      expect(result.updatedSession.state.player.currentHp, equals(40));
      expect(result.updatedGameState.party.members.first.currentHp, equals(40));
    });

    test(
        'super potion heals a damaged active target by 50 and consumes only super potion',
        () {
      final result = tryApplyRuntimeBattleItemUse(
        itemId: 'super-potion',
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
              BagEntry(itemId: 'potion', quantity: 2),
              BagEntry(
                itemId: 'super-potion',
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
        itemCatalog: _itemCatalog,
      );

      expect(result, isNotNull);
      expect(result!.appliedAmount, equals(50));
      expect(
        result.updatedSession.state.currentTurn!.playerAction,
        isA<BattleActionBagHpHealItemUse>().having(
          (action) => action.itemId,
          'itemKind',
          equals('super-potion'),
        ),
      );
      expect(result.updatedSession.state.player.currentHp, equals(62));
      expect(result.updatedGameState.party.members.first.currentHp, equals(62));
      expect(
        result.updatedGameState.bag.entries,
        const <BagEntry>[
          BagEntry(itemId: 'potion', quantity: 2),
          BagEntry(
            itemId: 'super-potion',
            quantity: 1,
          ),
        ],
      );
    });

    test('super potion heal is capped at max hp', () {
      final result = tryApplyRuntimeBattleItemUse(
        itemId: 'super-potion',
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
        itemCatalog: _itemCatalog,
      );

      expect(result, isNotNull);
      expect(result!.appliedAmount, equals(20));
      expect(result.updatedSession.state.player.currentHp, equals(80));
      expect(result.updatedGameState.party.members.first.currentHp, equals(80));
      expect(result.updatedGameState.bag.entries, isEmpty);
    });

    test(
        'hyper potion heals a damaged active target by 120 and consumes only hyper potion',
        () {
      final result = tryApplyRuntimeBattleItemUse(
        itemId: 'hyper-potion',
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
              BagEntry(itemId: 'potion', quantity: 2),
              BagEntry(
                itemId: 'super-potion',
                quantity: 2,
              ),
              BagEntry(
                itemId: 'hyper-potion',
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
        itemCatalog: _itemCatalog,
      );

      expect(result, isNotNull);
      expect(result!.appliedAmount, equals(120));
      expect(
        result.updatedSession.state.currentTurn!.playerAction,
        isA<BattleActionBagHpHealItemUse>().having(
          (action) => action.itemId,
          'itemKind',
          equals('hyper-potion'),
        ),
      );
      expect(result.updatedSession.state.player.currentHp, equals(132));
      expect(
          result.updatedGameState.party.members.first.currentHp, equals(132));
      expect(
        result.updatedGameState.bag.entries,
        const Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'potion', quantity: 2),
            BagEntry(
              itemId: 'super-potion',
              quantity: 2,
            ),
            BagEntry(
              itemId: 'hyper-potion',
              quantity: 1,
            ),
          ],
        ).normalized().entries,
      );
    });

    test('hyper potion heal is capped at max hp', () {
      final result = tryApplyRuntimeBattleItemUse(
        itemId: 'hyper-potion',
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
        itemCatalog: _itemCatalog,
      );

      expect(result, isNotNull);
      expect(result!.appliedAmount, equals(70));
      expect(result.updatedSession.state.player.currentHp, equals(260));
      expect(
          result.updatedGameState.party.members.first.currentHp, equals(260));
      expect(result.updatedGameState.bag.entries, isEmpty);
    });

    test(
        'max potion heals a damaged active target to max hp and consumes only max potion',
        () {
      final result = tryApplyRuntimeBattleItemUse(
        itemId: 'max-potion',
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
              BagEntry(itemId: 'potion', quantity: 2),
              BagEntry(
                itemId: 'super-potion',
                quantity: 2,
              ),
              BagEntry(
                itemId: 'hyper-potion',
                quantity: 2,
              ),
              BagEntry(
                itemId: 'max-potion',
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
        itemCatalog: _itemCatalog,
      );

      expect(result, isNotNull);
      expect(result!.appliedAmount, equals(248));
      expect(
        result.updatedSession.state.currentTurn!.playerAction,
        isA<BattleActionBagHpHealItemUse>()
            .having(
              (action) => action.itemId,
              'itemKind',
              equals('max-potion'),
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
            BagEntry(itemId: 'potion', quantity: 2),
            BagEntry(
              itemId: 'super-potion',
              quantity: 2,
            ),
            BagEntry(
              itemId: 'hyper-potion',
              quantity: 2,
            ),
            BagEntry(
              itemId: 'max-potion',
              quantity: 1,
            ),
          ],
        ).normalized().entries,
      );
    });

    test('max potion removes the bag entry when quantity reaches zero', () {
      final result = tryApplyRuntimeBattleItemUse(
        itemId: 'max-potion',
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
        itemCatalog: _itemCatalog,
      );

      expect(result, isNotNull);
      expect(result!.appliedAmount, equals(70));
      expect(result.updatedSession.state.player.currentHp, equals(260));
      expect(
          result.updatedGameState.party.members.first.currentHp, equals(260));
      expect(result.updatedGameState.bag.entries, isEmpty);
    });

    test(
        'potion use removes the bag entry when quantity reaches zero and targets the intended reserve by lineup identity',
        () {
      final result = tryApplyRuntimeBattleItemUse(
        itemId: 'potion',
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
              BagEntry(itemId: 'potion', quantity: 1),
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
        itemCatalog: _itemCatalog,
      );

      expect(result, isNotNull);
      expect(result!.appliedAmount, equals(5));
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
            BagEntry(itemId: 'potion', quantity: 1),
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
        tryApplyRuntimeBattleItemUse(
          itemId: 'potion',
          session: fullHpSession,
          gameState: fullHpState,
          context: _context(
            playerPartyIndex: 0,
            lineupPartyIndices: const <int>[0],
          ),
          targetLineupIndex: 0,
          itemCatalog: _itemCatalog,
        ),
        isNull,
      );
      expect(fullHpSession.state.player.currentHp, equals(40));
      expect(fullHpState.party.members.first.currentHp, equals(40));
      expect(fullHpState.bag.entries.single.quantity, equals(1));

      final faintedState = _gameState(
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'potion', quantity: 1),
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
        tryApplyRuntimeBattleItemUse(
          itemId: 'potion',
          session: faintedSession,
          gameState: faintedState,
          context: _context(
            playerPartyIndex: 0,
            lineupPartyIndices: const <int>[0],
          ),
          targetLineupIndex: 0,
          itemCatalog: _itemCatalog,
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
            BagEntry(itemId: 'max-potion', quantity: 1),
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
        tryApplyRuntimeBattleItemUse(
          itemId: 'max-potion',
          session: fullHpSession,
          gameState: fullHpState,
          context: _context(
            playerPartyIndex: 0,
            lineupPartyIndices: const <int>[0],
          ),
          targetLineupIndex: 0,
          itemCatalog: _itemCatalog,
        ),
        isNull,
      );
      expect(fullHpSession.state.player.currentHp, equals(40));
      expect(fullHpState.party.members.first.currentHp, equals(40));
      expect(fullHpState.bag.entries.single.quantity, equals(1));

      final faintedState = _gameState(
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'max-potion', quantity: 1),
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
        tryApplyRuntimeBattleItemUse(
          itemId: 'max-potion',
          session: faintedSession,
          gameState: faintedState,
          context: _context(
            playerPartyIndex: 0,
            lineupPartyIndices: const <int>[0],
          ),
          targetLineupIndex: 0,
          itemCatalog: _itemCatalog,
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
        String kind,
        int currentHp,
        int maxHp,
        int expectedHp,
      })>[
        (
          itemId: 'potion',
          kind: 'potion',
          currentHp: 30,
          maxHp: 100,
          expectedHp: 50,
        ),
        (
          itemId: 'super-potion',
          kind: 'super-potion',
          currentHp: 30,
          maxHp: 100,
          expectedHp: 80,
        ),
        (
          itemId: 'hyper-potion',
          kind: 'hyper-potion',
          currentHp: 30,
          maxHp: 100,
          expectedHp: 100,
        ),
        (
          itemId: 'max-potion',
          kind: 'max-potion',
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
        final result = tryApplyRuntimePsdkBattleItemUse(
          psdkSession: psdkSession,
          displaySession: displaySession,
          gameState: _gameState(
            bag: Bag(
              entries: <BagEntry>[
                BagEntry(
                  itemId: itemCase.itemId,
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
          itemCatalog: _itemCatalog,
          isTrainerBattle: true,
          trainerId: 'trainer',
        );

        expect(result, isNotNull, reason: itemCase.itemId);
        expect(result!.itemId, itemCase.kind);
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

    test('canonical HP values match overworld, legacy, PSDK and narration', () {
      const cases = <(String, int)>[
        ('potion', 20),
        ('super-potion', 50),
        ('hyper-potion', 120),
        ('max-potion', 220),
      ];

      for (final (itemId, expectedDelta) in cases) {
        final bag = Bag(
          entries: <BagEntry>[BagEntry(itemId: itemId, quantity: 1)],
        );
        final state = _gameState(
          bag: bag,
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 30),
          ],
        );
        final overworldResult =
            PlayerItemUseService(snapshot: _itemCatalog).use(
          PlayerItemUseRequest(
            state: state,
            itemId: itemId,
            context: ProjectItemUseContext.overworld,
            partyIndex: 0,
            maxHp: 250,
          ),
        );
        final legacySession = _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 30,
            maxHp: 250,
            moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
          ),
        );
        final legacyResult = switch (itemId) {
          'potion' => tryApplyRuntimeBattleItemUse(
              itemId: 'potion',
              session: legacySession,
              gameState: state,
              context: _context(
                playerPartyIndex: 0,
                lineupPartyIndices: const <int>[0],
              ),
              targetLineupIndex: 0,
              itemCatalog: _itemCatalog,
            ),
          'super-potion' => tryApplyRuntimeBattleItemUse(
              itemId: 'super-potion',
              session: legacySession,
              gameState: state,
              context: _context(
                playerPartyIndex: 0,
                lineupPartyIndices: const <int>[0],
              ),
              targetLineupIndex: 0,
              itemCatalog: _itemCatalog,
            ),
          'hyper-potion' => tryApplyRuntimeBattleItemUse(
              itemId: 'hyper-potion',
              session: legacySession,
              gameState: state,
              context: _context(
                playerPartyIndex: 0,
                lineupPartyIndices: const <int>[0],
              ),
              targetLineupIndex: 0,
              itemCatalog: _itemCatalog,
            ),
          'max-potion' => tryApplyRuntimeBattleItemUse(
              itemId: 'max-potion',
              session: legacySession,
              gameState: state,
              context: _context(
                playerPartyIndex: 0,
                lineupPartyIndices: const <int>[0],
              ),
              targetLineupIndex: 0,
              itemCatalog: _itemCatalog,
            ),
          _ => null,
        };
        final psdkSession = _psdkSession(currentHp: 30, maxHp: 250);
        final psdkResult = tryApplyRuntimePsdkBattleItemUse(
          psdkSession: psdkSession,
          displaySession: psdkSession.createLegacyDisplaySession(
            isTrainerBattle: true,
            trainerId: 'trainer',
          ),
          gameState: state,
          context: _context(
            playerPartyIndex: 0,
            lineupPartyIndices: const <int>[0],
          ),
          itemId: itemId,
          targetLineupIndex: 0,
          isTrainerBattle: true,
          trainerId: 'trainer',
          itemCatalog: _itemCatalog,
        );

        expect(overworldResult.isSuccess, isTrue, reason: itemId);
        expect(
          overworldResult.state.party.members.first.currentHp - 30,
          expectedDelta,
          reason: itemId,
        );
        expect(legacyResult!.appliedAmount, expectedDelta, reason: itemId);
        expect(psdkResult!.appliedAmount, expectedDelta, reason: itemId);
        expect(
          buildBattleTurnLinesForOverlay(
            legacyResult.updatedSession.state.currentTurn!,
          ),
          contains('sproutle récupère $expectedDelta PV'),
          reason: itemId,
        );
      }
    });

    test('PSDK HP medicines can target a reserve battler atomically', () {
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
            BagEntry(itemId: 'potion', quantity: 1),
          ],
        ),
        partyMembers: <PlayerPokemon>[
          _partyMember(speciesId: 'sproutle', currentHp: 30),
          _partyMember(speciesId: 'sproutle', currentHp: 40),
        ],
      );

      final result = tryApplyRuntimePsdkBattleItemUse(
        psdkSession: psdkSession,
        displaySession: displaySession,
        gameState: gameState,
        context: _context(
          playerPartyIndex: 0,
          lineupPartyIndices: const <int>[0, 1],
        ),
        itemId: 'potion',
        targetLineupIndex: 1,
        itemCatalog: _itemCatalog,
        isTrainerBattle: true,
        trainerId: 'trainer',
      );

      expect(result, isNotNull);
      expect(result!.targetLineupIndex, 1);
      final displayItemAction = result.updatedDisplaySession.state.currentTurn!
          .playerAction as BattleActionBagHpHealItemUse;
      expect(displayItemAction.targetLineupIndex, 1);
      expect(result.updatedDisplaySession.state.playerReserve.single.currentHp,
          equals(60));
      expect(result.updatedGameState.party.members[1].currentHp, equals(60));
      expect(result.updatedGameState.bag.entries, isEmpty);
      expect(psdkSession.state.psdkState.battlerAt(psdkPlayerSlot).currentHp,
          equals(30));
      expect(
        psdkSession.state.psdkState
            .partyForBank(psdkPlayerSlot.bank)[1]
            .currentHp,
        equals(60),
      );
    });
  });
}
