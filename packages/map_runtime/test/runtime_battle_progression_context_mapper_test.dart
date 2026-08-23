import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  const mapper = RuntimeBattleProgressionContextMapper();

  group('RuntimeBattleProgressionContextMapper', () {
    test('maps switched lineup indexes to exact non-zero runtime party slots',
        () {
      final outcome = _switchedPsdkOutcome();
      final progressionContext = mapper.fromPsdkOutcome(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        runtimeContext: _runtimeContext(
          playerPartyIndex: 3,
          lineupToPartySlots: const <int>[3, 1, 4],
        ),
        outcome: outcome,
        partyLength: 5,
        defeatedOpponents: const <BattleProgressionDefeatedOpponent>[
          BattleProgressionDefeatedOpponent(level: 14, baseExperience: 70),
        ],
        partySlotMetadata: <BattleProgressionPartySlotMetadata>[
          _metadata(1),
          _metadata(3),
        ],
      );

      expect(
        progressionContext.ruleset,
        PokemonRulesetProfile.pokeMapBetaV1,
      );
      expect(progressionContext.playerParticipantPartySlots, <int>{1, 3});
      expect(
        progressionContext.playerParticipantPartySlots,
        isNot(contains(4)),
      );

      final state = _partyState(5);
      final result = const BattleProgressionService().apply(
        state: state,
        context: progressionContext,
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(result.state.party.members[1].experience, 195);
      expect(result.state.party.members[3].experience, 195);
      expect(result.state.party.members[0], state.party.members[0]);
      expect(result.state.party.members[2], state.party.members[2]);
      expect(result.state.party.members[4], state.party.members[4]);
      expect(
        result.appliedReward.experienceGrants.map((grant) => grant.partySlot),
        <int>[1, 3],
      );
    });

    test('maps legacy participant indexes through the same strict seam', () {
      final context = mapper.fromLegacyOutcome(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        runtimeContext: _runtimeContext(
          playerPartyIndex: 4,
          lineupToPartySlots: const <int>[4, 2, 5],
        ),
        outcome: _legacyOutcome(
          participants: const <int>{0, 1},
        ),
        partyLength: 6,
        defeatedOpponents: const <BattleProgressionDefeatedOpponent>[],
        partySlotMetadata: const <BattleProgressionPartySlotMetadata>[],
      );

      expect(context.ruleset, PokemonRulesetProfile.pokeMapBetaV1);
      expect(context.outcome, BattleProgressionOutcomeKind.victory);
      expect(context.playerParticipantPartySlots, <int>{2, 4});
      expect(context.playerParticipantPartySlots, isNot(contains(5)));
    });

    test('resolves progression participants after the party was reordered', () {
      final state = GameState(
        saveId: 'progression-identity-reorder',
        party: PlayerParty(
          members: <PlayerPokemon>[
            _partyPokemon(0).copyWith(individualId: 'pkm_reserve'),
            _partyPokemon(1).copyWith(individualId: 'pkm_active'),
          ],
        ),
      );
      final context = mapper.fromLegacyOutcome(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        runtimeContext: _runtimeContext(
          playerPartyIndex: 0,
          lineupToPartySlots: const <int>[0, 1],
          playerIndividualId: 'pkm_active',
          lineupIndividualIds: const <String>[
            'pkm_active',
            'pkm_reserve',
          ],
        ),
        outcome: _legacyOutcome(participants: const <int>{0}),
        partyLength: state.party.members.length,
        gameState: state,
        defeatedOpponents: const <BattleProgressionDefeatedOpponent>[],
        partySlotMetadata: const <BattleProgressionPartySlotMetadata>[],
      );

      expect(context.playerParticipantPartySlots, <int>{1});
    });

    test('fails closed when the lineup mapping is absent', () {
      expect(
        () => mapper.fromLegacyOutcome(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          runtimeContext: _runtimeContext(
            playerPartyIndex: 3,
            lineupToPartySlots: const <int>[],
          ),
          outcome: _legacyOutcome(),
          partyLength: 5,
          defeatedOpponents: const <BattleProgressionDefeatedOpponent>[],
          partySlotMetadata: const <BattleProgressionPartySlotMetadata>[],
        ),
        throwsStateError,
      );
    });

    test('fails closed when the mapping length cannot cover a participant', () {
      expect(
        () => mapper.fromLegacyOutcome(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          runtimeContext: _runtimeContext(
            playerPartyIndex: 3,
            lineupToPartySlots: const <int>[3],
          ),
          outcome: _legacyOutcome(participants: const <int>{0, 1}),
          partyLength: 5,
          defeatedOpponents: const <BattleProgressionDefeatedOpponent>[],
          partySlotMetadata: const <BattleProgressionPartySlotMetadata>[],
        ),
        throwsStateError,
      );
    });

    test('fails closed on an invalid mapped party index', () {
      expect(
        () => mapper.fromLegacyOutcome(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          runtimeContext: _runtimeContext(
            playerPartyIndex: 3,
            lineupToPartySlots: const <int>[3, 5],
          ),
          outcome: _legacyOutcome(participants: const <int>{0, 1}),
          partyLength: 5,
          defeatedOpponents: const <BattleProgressionDefeatedOpponent>[],
          partySlotMetadata: const <BattleProgressionPartySlotMetadata>[],
        ),
        throwsStateError,
      );
    });

    test('fails closed on duplicate mapped party slots', () {
      expect(
        () => mapper.fromLegacyOutcome(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          runtimeContext: _runtimeContext(
            playerPartyIndex: 3,
            lineupToPartySlots: const <int>[3, 3],
          ),
          outcome: _legacyOutcome(participants: const <int>{0, 1}),
          partyLength: 5,
          defeatedOpponents: const <BattleProgressionDefeatedOpponent>[],
          partySlotMetadata: const <BattleProgressionPartySlotMetadata>[],
        ),
        throwsStateError,
      );
    });
  });
}

RuntimeActiveBattleContext _runtimeContext({
  required int playerPartyIndex,
  required List<int> lineupToPartySlots,
  String playerIndividualId = '',
  List<String> lineupIndividualIds = const <String>[],
}) {
  return RuntimeActiveBattleContext.withLineupMapping(
    request: const WildBattleStartRequest(
      requestId: 'progression-mapping',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: 'route',
        playerPos: GridPos(x: 1, y: 1),
        playerFacing: Direction.south,
      ),
      mapId: 'route',
      encounterSourceId: 'grass',
      encounterSourceKind: EncounterSourceKind.gameplayZone,
      tableId: 'route-grass',
      encounterKind: EncounterKind.walk,
      speciesId: 'opponent',
      level: 14,
      minLevel: 14,
      maxLevel: 14,
      weight: 1,
      playerPos: GridPos(x: 1, y: 1),
    ),
    playerPartyIndex: playerPartyIndex,
    playerPartySlotIndicesByLineupIndex: lineupToPartySlots,
    playerIndividualId: playerIndividualId,
    playerIndividualIdsByLineupIndex: lineupIndividualIds,
  );
}

BattleOutcome _legacyOutcome({
  BattleOutcomeType type = BattleOutcomeType.victory,
  Set<int> participants = const <int>{0},
}) {
  return BattleOutcome(
    type: type,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: _legacyCombatant('player', lineupIndex: 1, currentHp: 10),
      enemy: _legacyCombatant('opponent', lineupIndex: 0, currentHp: 0),
      playerParticipantLineupIndexes: participants,
    ),
  );
}

BattleCombatant _legacyCombatant(
  String speciesId, {
  required int lineupIndex,
  required int currentHp,
}) {
  return BattleCombatant(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 5,
    currentHp: currentHp,
    maxHp: 10,
    stats: const BattleStatsSnapshot(
      attack: 10,
      defense: 10,
      specialAttack: 10,
      specialDefense: 10,
      speed: 10,
    ),
    moves: const <BattleMove>[],
  );
}

PsdkBattleOutcome _switchedPsdkOutcome() {
  final engine = BattleEngine(
    setup: BattleEngineSetup.singlesPokeMapBetaV1ForTest(
      player: _psdkCombatant(
        id: 'player_0',
        speciesId: 'lead',
        hp: 60,
      ),
      playerReserves: <PsdkBattleCombatantSetup>[
        _psdkCombatant(
          id: 'player_1',
          speciesId: 'engaged',
          hp: 80,
          attack: 120,
          moves: <PsdkBattleMoveData>[
            _psdkMove(id: 'finish', power: 200),
          ],
        ),
        _psdkCombatant(
          id: 'player_2',
          speciesId: 'unused',
          hp: 80,
        ),
      ],
      opponent: _psdkCombatant(
        id: 'opponent_0',
        speciesId: 'target',
        hp: 1,
        moves: <PsdkBattleMoveData>[
          _psdkMove(id: 'wait', power: 0),
        ],
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );

  engine.submit(const BattleDecision.switchPokemon(partyIndex: 1));
  final finished = engine.submit(const BattleDecision.fight(moveSlot: 0));
  return finished.outcome!.psdkOutcome;
}

PsdkBattleCombatantSetup _psdkCombatant({
  required String id,
  required String speciesId,
  required int hp,
  int attack = 50,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId,
    displayName: speciesId,
    level: 20,
    maxHp: hp,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: attack,
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
    category: PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

BattleProgressionPartySlotMetadata _metadata(int partySlot) {
  return BattleProgressionPartySlotMetadata(
    partySlot: partySlot,
    growthRateId: 'medium',
    oldMaxHp: 19,
    baseStats: const PokemonBaseStats(
      hp: 45,
      attack: 49,
      defense: 49,
      specialAttack: 65,
      specialDefense: 65,
      speed: 45,
    ),
  );
}

GameState _partyState(int length) {
  return GameState(
    saveId: 'mapped-progression',
    party: PlayerParty(
      members: <PlayerPokemon>[
        for (var index = 0; index < length; index++)
          PlayerPokemon(
            speciesId: 'party_$index',
            natureId: 'hardy',
            abilityId: 'ability_$index',
            level: 5,
            experience: 125,
            currentPpByMoveId: const <String, int>{},
            currentHp: 19,
          ),
      ],
    ),
  );
}

PlayerPokemon _partyPokemon(int index) => PlayerPokemon(
      speciesId: 'party_$index',
      natureId: 'hardy',
      abilityId: 'ability_$index',
      level: 5,
      experience: 125,
      currentPpByMoveId: const <String, int>{},
      currentHp: 19,
    );
