import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_bag_hp_heal_item_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

final _itemCatalog = ItemCatalogSnapshot.fromCatalog(
  ProjectItemCatalog(
    schemaVersion: 1,
    entries: <ProjectItemDefinition>[
      ...mvpItemCatalog.entries,
      const ProjectItemDefinition(
        id: 'battle-tonic',
        displayName: 'Battle Tonic',
        pocketId: 'expedition-supplies',
        uses: <ProjectItemUseDefinition>[
          ProjectItemUseDefinition(
            contexts: <ProjectItemUseContext>{ProjectItemUseContext.battle},
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.healHp(
              mode: ProjectItemAmountMode.flat,
              amount: 13,
            ),
          ),
        ],
      ),
      const ProjectItemDefinition(
        id: 'toxin-sponge',
        displayName: 'Toxin Sponge',
        pocketId: 'field-tools',
        uses: <ProjectItemUseDefinition>[
          ProjectItemUseDefinition(
            contexts: <ProjectItemUseContext>{ProjectItemUseContext.battle},
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.cureStatus(
              mode: ProjectItemStatusCureMode.listed,
              statusIds: <String>{'poison'},
            ),
          ),
        ],
      ),
      const ProjectItemDefinition(
        id: 'dawn-feather',
        displayName: 'Dawn Feather',
        pocketId: 'relics',
        uses: <ProjectItemUseDefinition>[
          ProjectItemUseDefinition(
            contexts: <ProjectItemUseContext>{ProjectItemUseContext.battle},
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.revive(
              rateNumerator: 1,
              rateDenominator: 2,
            ),
          ),
        ],
      ),
      const ProjectItemDefinition(
        id: 'reusable-tonic',
        displayName: 'Reusable Tonic',
        pocketId: 'field-tools',
        uses: <ProjectItemUseDefinition>[
          ProjectItemUseDefinition(
            contexts: <ProjectItemUseContext>{ProjectItemUseContext.battle},
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.never,
            effect: ProjectItemEffectDefinition.healHp(
              mode: ProjectItemAmountMode.flat,
              amount: 13,
            ),
          ),
        ],
      ),
    ],
  ),
);

void main() {
  group('runtime generic battle items v0', () {
    test('a custom healing item applies once and returns one receipt', () {
      final psdkSession = _session(
        player: _combatant(
          id: 'player_0',
          speciesId: 'sproutle',
          currentHp: 60,
        ),
      );
      final displaySession = psdkSession.createLegacyDisplaySession(
        isTrainerBattle: true,
        trainerId: 'trainer',
      );

      final result = tryApplyRuntimePsdkBattleItemUse(
        psdkSession: psdkSession,
        displaySession: displaySession,
        gameState: _gameState(
          itemId: 'battle-tonic',
          members: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 60),
          ],
        ),
        context: _context(const <int>[0]),
        itemId: 'battle-tonic',
        targetLineupIndex: 0,
        isTrainerBattle: true,
        trainerId: 'trainer',
        itemCatalog: _itemCatalog,
      );

      expect(result, isNotNull);
      expect(result!.effectKind, RuntimeBattleItemEffectKind.healHp);
      expect(result.appliedAmount, 13);
      expect(result.updatedGameState.party.members.single.currentHp, 73);
      expect(result.updatedGameState.bag.entries, isEmpty);
      expect(result.consumptionReceipt!.itemId, 'battle-tonic');
      expect(result.consumptionReceipt!.quantity, 1);
    });

    test('a custom cure clears a compatible status and returns one receipt',
        () {
      final psdkSession = _session(
        player: _combatant(
          id: 'player_0',
          speciesId: 'sproutle',
          currentHp: 60,
          majorStatus: PsdkBattleMajorStatus.poison,
        ),
      );
      final displaySession = psdkSession.createLegacyDisplaySession(
        isTrainerBattle: true,
        trainerId: 'trainer',
      );

      final result = tryApplyRuntimePsdkBattleItemUse(
        psdkSession: psdkSession,
        displaySession: displaySession,
        gameState: _gameState(
          itemId: 'toxin-sponge',
          members: <PlayerPokemon>[
            _partyMember(
              speciesId: 'sproutle',
              currentHp: 60,
              statusId: 'poison',
            ),
          ],
        ),
        context: _context(const <int>[0]),
        itemId: 'toxin-sponge',
        targetLineupIndex: 0,
        isTrainerBattle: true,
        trainerId: 'trainer',
        itemCatalog: _itemCatalog,
      );

      expect(result, isNotNull);
      expect(result!.effectKind.name, 'cureStatus');
      expect(result.updatedDisplaySession.state.player.majorStatus, isNull);
      expect(result.updatedGameState.party.members.single.statusId, isEmpty);
      expect(result.updatedGameState.bag.entries, isEmpty);
      expect(result.consumptionReceipt!.itemId, 'toxin-sponge');
      expect(
        psdkSession.state.psdkState.battlerAt(psdkPlayerSlot).majorStatus,
        isNull,
      );
    });

    test('revive restores a fainted reserve and writes it back', () {
      final psdkSession = _session(
        player: _combatant(
          id: 'player_0',
          speciesId: 'sproutle',
          currentHp: 60,
        ),
        playerReserves: <PsdkBattleCombatantSetup>[
          _combatant(
            id: 'player_1',
            speciesId: 'benchmon',
            currentHp: 0,
          ),
        ],
      );
      final displaySession = psdkSession.createLegacyDisplaySession(
        isTrainerBattle: true,
        trainerId: 'trainer',
      );

      final result = tryApplyRuntimePsdkBattleItemUse(
        psdkSession: psdkSession,
        displaySession: displaySession,
        gameState: _gameState(
          itemId: 'dawn-feather',
          members: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 60),
            _partyMember(speciesId: 'benchmon', currentHp: 0),
          ],
        ),
        context: _context(const <int>[0, 1]),
        itemId: 'dawn-feather',
        targetLineupIndex: 1,
        isTrainerBattle: true,
        trainerId: 'trainer',
        itemCatalog: _itemCatalog,
      );

      expect(result, isNotNull);
      expect(result!.effectKind.name, 'revive');
      expect(result.appliedAmount, 40);
      expect(
        result.updatedDisplaySession.state.playerReserve.single.currentHp,
        40,
      );
      expect(result.updatedGameState.party.members[1].currentHp, 40);
      expect(result.updatedGameState.bag.entries, isEmpty);
      expect(result.consumptionReceipt!.itemId, 'dawn-feather');
      expect(
        psdkSession.state.psdkState
            .partyForBank(psdkPlayerSlot.bank)[1]
            .currentHp,
        40,
      );
    });

    test('a no-effect item leaves engine, party and bag unchanged', () {
      final psdkSession = _session(
        player: _combatant(
          id: 'player_0',
          speciesId: 'sproutle',
          currentHp: 80,
        ),
      );
      final displaySession = psdkSession.createLegacyDisplaySession(
        isTrainerBattle: true,
        trainerId: 'trainer',
      );
      final gameState = _gameState(
        itemId: 'antidote',
        members: <PlayerPokemon>[
          _partyMember(speciesId: 'sproutle', currentHp: 80),
        ],
      );

      final result = tryApplyRuntimePsdkBattleItemUse(
        psdkSession: psdkSession,
        displaySession: displaySession,
        gameState: gameState,
        context: _context(const <int>[0]),
        itemId: 'antidote',
        targetLineupIndex: 0,
        isTrainerBattle: true,
        trainerId: 'trainer',
        itemCatalog: _itemCatalog,
      );

      expect(result, isNull);
      expect(psdkSession.state.turnNumber, 0);
      expect(gameState.party.members.single.currentHp, 80);
      expect(gameState.bag.entries.single.quantity, 1);
    });

    test('a reusable healing item works through both battle engines', () {
      final legacyBridge = _session(
        player: _combatant(
          id: 'player_0',
          speciesId: 'sproutle',
          currentHp: 60,
        ),
      );
      final legacyResult = tryApplyRuntimeBattleItemUse(
        session: legacyBridge.createLegacyDisplaySession(
          isTrainerBattle: true,
          trainerId: 'trainer',
        ),
        gameState: _gameState(
          itemId: 'reusable-tonic',
          members: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 60),
          ],
        ),
        context: _context(const <int>[0]),
        itemId: 'reusable-tonic',
        targetLineupIndex: 0,
        itemCatalog: _itemCatalog,
      );

      expect(legacyResult, isNotNull);
      expect(legacyResult!.appliedAmount, 13);
      expect(legacyResult.updatedGameState.bag.entries.single.quantity, 1);
      expect(legacyResult.consumptionReceipt, isNull);

      final psdkSession = _session(
        player: _combatant(
          id: 'player_0',
          speciesId: 'sproutle',
          currentHp: 60,
        ),
      );
      final psdkResult = tryApplyRuntimePsdkBattleItemUse(
        psdkSession: psdkSession,
        displaySession: psdkSession.createLegacyDisplaySession(
          isTrainerBattle: true,
          trainerId: 'trainer',
        ),
        gameState: _gameState(
          itemId: 'reusable-tonic',
          members: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 60),
          ],
        ),
        context: _context(const <int>[0]),
        itemId: 'reusable-tonic',
        targetLineupIndex: 0,
        isTrainerBattle: true,
        trainerId: 'trainer',
        itemCatalog: _itemCatalog,
      );

      expect(psdkResult, isNotNull);
      expect(psdkResult!.appliedAmount, 13);
      expect(psdkResult.updatedGameState.bag.entries.single.quantity, 1);
      expect(psdkResult.consumptionReceipt, isNull);
    });
  });
}

RuntimePsdkBattleSessionAdapter _session({
  required PsdkBattleCombatantSetup player,
  List<PsdkBattleCombatantSetup> playerReserves =
      const <PsdkBattleCombatantSetup>[],
}) {
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup.singles(
      player: player,
      playerReserves: playerReserves,
      opponent: _combatant(
        id: 'opponent_0',
        speciesId: 'sparkitten',
        currentHp: 80,
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

PsdkBattleCombatantSetup _combatant({
  required String id,
  required String speciesId,
  required int currentHp,
  PsdkBattleMajorStatus? majorStatus,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId,
    displayName: speciesId,
    level: 20,
    maxHp: 80,
    currentHp: currentHp,
    majorStatus: majorStatus,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: '$id-wait',
        dbSymbol: '$id-wait',
        name: 'Wait',
        type: 'normal',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 100,
        pp: 35,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.user,
      ),
    ],
  );
}

GameState _gameState({
  required String itemId,
  required List<PlayerPokemon> members,
}) {
  return GameState(
    saveId: 'generic-battle-items-v0',
    bag: Bag(
      entries: <BagEntry>[
        BagEntry(itemId: itemId, quantity: 1),
      ],
    ),
    party: PlayerParty(members: members),
  );
}

PlayerPokemon _partyMember({
  required String speciesId,
  required int currentHp,
  String statusId = '',
}) {
  return PlayerPokemon(
    speciesId: speciesId,
    natureId: 'hardy',
    abilityId: 'pressure',
    level: 20,
    knownMoveIds: const <String>['wait'],
    currentHp: currentHp,
    statusId: statusId,
  );
}

RuntimeActiveBattleContext _context(List<int> lineupPartyIndices) {
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
    playerPartyIndex: lineupPartyIndices.first,
    playerPartySlotIndicesByLineupIndex: lineupPartyIndices,
  );
}
