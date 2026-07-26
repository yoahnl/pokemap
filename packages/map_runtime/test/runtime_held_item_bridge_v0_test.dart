import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';

void main() {
  group('runtime held item bridge v0', () {
    test('a runtime seed hydrates and executes its held-item effect', () {
      final playerSeed = RuntimePsdkBattleCombatantSeed(
        speciesId: 'player',
        level: 20,
        maxHp: 80,
        catchRate: 45,
        stats: _stats,
        typing: const BattleTypingSnapshot(primaryType: 'normal'),
        abilityId: 'pressure',
        heldItemId: 'leftovers',
        moves: <PsdkBattleMoveData>[_move('player-wait')],
        currentHp: 40,
      );
      final session = BattleSessionFacade.fromPsdkSetup(
        setup: PsdkBattleSetup.singles(
          player: playerSeed.toPsdkBattleCombatantSetup(
            lineupIndex: 0,
            idPrefix: 'player',
          ),
          opponent: _combatant(id: 'opponent_0'),
          rngSeeds: _rngSeeds,
        ),
      );

      final player = session.state.psdkState.battlerAt(psdkPlayerSlot);
      expect(player.heldItemId, 'leftovers');
      expect(
        player.effects.effects.map((effect) => effect.id),
        contains('item:leftovers'),
      );

      session.submit(const BattleDecision.noAction());

      expect(
        session.state.psdkState.battlerAt(psdkPlayerSlot).currentHp,
        45,
      );
    });

    test('writes unchanged, consumed, removed and received items explicitly',
        () {
      final psdkState = PsdkBattleState.fromSetup(
        PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player_0',
            heldItemId: 'oran_berry',
          ),
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'player_1',
              consumedItemId: 'sitrus_berry',
              itemConsumed: true,
            ),
            _combatant(id: 'player_2'),
            _combatant(
              id: 'player_3',
              heldItemId: 'leftovers',
            ),
          ],
          opponent: _combatant(id: 'opponent_0'),
          rngSeeds: _rngSeeds,
        ),
      );
      const gameState = GameState(
        saveId: 'held-item-write-back',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              heldItemId: 'oran-berry',
            ),
            PlayerPokemon(
              speciesId: 'bench-one',
              natureId: 'hardy',
              abilityId: 'pressure',
              heldItemId: 'sitrus-berry',
            ),
            PlayerPokemon(
              speciesId: 'bench-two',
              natureId: 'hardy',
              abilityId: 'pressure',
              heldItemId: 'air-balloon',
            ),
            PlayerPokemon(
              speciesId: 'bench-three',
              natureId: 'hardy',
              abilityId: 'pressure',
              heldItemId: 'oran-berry',
            ),
          ],
        ),
      );

      final result = writePlayerPsdkHeldItemsBackToPartySlots(
        gameState: gameState,
        context: _context(),
        psdkState: psdkState,
      );

      expect(
        result.party.members.map((pokemon) => pokemon.heldItemId),
        <String>['oran-berry', '', '', 'leftovers'],
      );
    });
  });
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  String? heldItemId,
  String? consumedItemId,
  bool itemConsumed = false,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 80,
    currentHp: 80,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    heldItemId: heldItemId,
    consumedItemId: consumedItemId,
    itemConsumed: itemConsumed,
    moves: <PsdkBattleMoveData>[_move('$id-move')],
  );
}

const _stats = BattleStatsSnapshot(
  attack: 50,
  defense: 50,
  specialAttack: 50,
  specialDefense: 50,
  speed: 50,
);

PsdkBattleMoveData _move(String id) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: 'Wait',
    type: 'normal',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.user,
  );
}

const _rngSeeds = PsdkBattleRngSeeds(
  moveDamage: 1,
  moveCritical: 2,
  moveAccuracy: 3,
  generic: 4,
);

RuntimeActiveBattleContext _context() {
  return RuntimeActiveBattleContext.withLineupMapping(
    request: const TrainerBattleStartRequest(
      requestId: 'held-item-battle',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: 'field',
        playerPos: GridPos(x: 1, y: 1),
        playerFacing: Direction.south,
      ),
      trainerId: 'trainer',
      npcEntityId: 'npc',
      mapId: 'field',
      playerPos: GridPos(x: 1, y: 1),
    ),
    playerPartyIndex: 0,
    playerPartySlotIndicesByLineupIndex: const <int>[0, 1, 2, 3],
  );
}
