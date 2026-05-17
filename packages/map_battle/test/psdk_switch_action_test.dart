import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK voluntary switch actions', () {
    test('decision request exposes legal reserve switches', () {
      final engine = BattleEngine(setup: _setup());

      final request = engine.currentRequest;

      expect(request.switchChoices.map((choice) => choice.partyIndex), <int>[
        1,
      ]);
      expect(
        request.allowedDecisions
            .whereType<BattleSwitchDecision>()
            .map((decision) => decision.partyIndex),
        contains(1),
      );
      expect(
        request.allows(const BattleDecision.switchPokemon(partyIndex: 1)),
        isTrue,
      );
    });

    test('switches before the opposing regular move targets the new active',
        () {
      final engine = BattleEngine(setup: _setup());

      final result = engine.submit(
        const BattleDecision.switchPokemon(partyIndex: 1),
      );

      final active = result.state.battlerAt(psdkPlayerSlot);
      expect(active.speciesId, 'ivysaur');
      expect(active.currentHp, lessThan(active.maxHp));
      expect(active.currentHp, greaterThan(0));
      expect(
        result.timeline.events
            .whereType<BattleMovePpSpentTimelineEvent>()
            .map((event) => event.user),
        <BattlePositionRef>[const BattlePositionRef(bank: 1, position: 0)],
      );
    });

    test('rejects illegal switch decisions before mutating the turn', () {
      final engine = BattleEngine(setup: _setup());

      expect(
        () => engine.submit(const BattleDecision.switchPokemon(partyIndex: 4)),
        throwsRangeError,
      );
      expect(engine.snapshot().turnNumber, 0);
      expect(
          engine.snapshot().battlerAt(psdkPlayerSlot).speciesId, 'bulbasaur');
    });

    test('switch-in hazards and ability hooks run for the replacement', () {
      final engine = BattleEngine(
        setup: _setup(
          playerReserve: _combatant(
            id: 'player-ivysaur',
            speciesId: 'ivysaur',
            hp: 80,
            abilityId: 'intimidate',
          ),
          opponent: _combatant(
            id: 'opponent-rattata',
            speciesId: 'rattata',
            hp: 70,
            attack: 60,
            moves: <PsdkBattleMoveData>[
              _move(id: 'wait', power: 0),
            ],
            effects: PsdkBattleEffectStack(
              effects: <BattleEffect>[
                SpikesEffect(bank: 0, layers: 1),
              ],
            ),
          ),
        ),
      );

      final result = engine.submit(
        const BattleDecision.switchPokemon(partyIndex: 1),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).speciesId, 'ivysaur');
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 70);
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
        -1,
      );
      expect(
        result.timeline.events
            .whereType<BattleDamageTimelineEvent>()
            .map((event) => event.moveId),
        contains('effect:spikes'),
      );
      expect(
        result.timeline.events
            .whereType<BattleStatStageChangeTimelineEvent>()
            .map((event) => event.stat),
        contains('attack'),
      );
    });
  });
}

BattleEngineSetup _setup({
  PsdkBattleCombatantSetup? player,
  PsdkBattleCombatantSetup? playerReserve,
  PsdkBattleCombatantSetup? opponent,
  List<PsdkBattleMoveData>? opponentMoves,
}) {
  return BattleEngineSetup.singles(
    player: player ??
        _combatant(
          id: 'player-bulbasaur',
          speciesId: 'bulbasaur',
          hp: 60,
        ),
    playerReserves: <PsdkBattleCombatantSetup>[
      playerReserve ??
          _combatant(
            id: 'player-ivysaur',
            speciesId: 'ivysaur',
            hp: 80,
          ),
    ],
    opponent: opponent ??
        _combatant(
          id: 'opponent-rattata',
          speciesId: 'rattata',
          hp: 70,
          moves: opponentMoves,
        ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required String speciesId,
  required int hp,
  int attack = 50,
  String? abilityId,
  List<PsdkBattleMoveData>? moves,
  PsdkBattleEffectStack? effects,
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
    abilityId: abilityId,
    moves: moves ?? <PsdkBattleMoveData>[_move(id: 'tackle', power: 40)],
    effects: effects,
  );
}

PsdkBattleMoveData _move({
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
