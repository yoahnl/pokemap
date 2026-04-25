import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK battle battler state', () {
    test('clamps hp and exposes alive ko helpers', () {
      final battler = _battler(hp: 99, maxHp: 40);

      expect(battler.hp, 40);
      expect(battler.isAlive, isTrue);
      expect(battler.isKo, isFalse);

      battler.applyDamage(55);

      expect(battler.hp, 0);
      expect(battler.isAlive, isFalse);
      expect(battler.isKo, isTrue);
    });

    test('keeps move and effect collections owned by the battler', () {
      final moves = <BattleMoveInstance>[
        BattleMoveInstance(
          id: 'tackle',
          dbSymbol: 'tackle',
          pp: 35,
          maxPp: 35,
        ),
      ];
      final battler = _battler(moves: moves);
      moves.clear();

      expect(battler.moves, hasLength(1));
      expect(
        () => battler.moves.clear(),
        throwsUnsupportedError,
      );

      battler.effects.add('flinch');
      battler.history.markMoveUsed('tackle');

      expect(battler.effects.contains('flinch'), isTrue);
      expect(battler.history.lastMoveId, 'tackle');
    });

    test('stat stages are bounded to the Pokemon stage range', () {
      final stages = BattleStatStageSet.neutral()
        ..raise(BattleStat.attack, 9)
        ..lower(BattleStat.speed, 20);

      expect(stages.valueOf(BattleStat.attack), 6);
      expect(stages.valueOf(BattleStat.speed), -6);
      expect(
        () => stages.raise(BattleStat.defense, -1),
        throwsRangeError,
      );
      expect(
        () => stages.lower(BattleStat.defense, -1),
        throwsRangeError,
      );
    });

    test('move pp cannot become negative or exceed max pp', () {
      final move = BattleMoveInstance(
        id: 'tackle',
        dbSymbol: 'tackle',
        pp: 1,
        maxPp: 35,
      );

      expect(move.spendPp(), isTrue);
      expect(move.pp, 0);
      expect(move.spendPp(), isFalse);

      move.restorePp(99);

      expect(move.pp, 35);
    });

    test('rejects invalid battler and move invariants', () {
      expect(() => _battler(instanceId: ' '), throwsArgumentError);
      expect(() => _battler(speciesId: ' '), throwsArgumentError);
      expect(() => _battler(displayName: ' '), throwsArgumentError);
      expect(() => _battler(bank: -1), throwsRangeError);
      expect(() => _battler(position: -2), throwsRangeError);
      expect(() => _battler(partyIndex: -1), throwsRangeError);
      expect(() => _battler(level: 0), throwsRangeError);
      expect(() => _battler(maxHp: 0), throwsRangeError);
      expect(
        () => BattleMoveInstance(
          id: ' ',
          dbSymbol: 'tackle',
          pp: 1,
          maxPp: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => BattleMoveInstance(
          id: 'tackle',
          dbSymbol: ' ',
          pp: 1,
          maxPp: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => BattleMoveInstance(
          id: 'tackle',
          dbSymbol: 'tackle',
          pp: 2,
          maxPp: 1,
        ),
        throwsRangeError,
      );
    });
  });

  group('PSDK clean combatant state', () {
    test('copyWith can explicitly clear a carried major status', () {
      final battler = PsdkBattleCombatant.fromSetup(
        _psdkCombatant(
          majorStatus: PsdkBattleMajorStatus.burn,
        ),
      );

      expect(battler.majorStatus, PsdkBattleMajorStatus.burn);
      expect(battler.copyWith(clearMajorStatus: true).majorStatus, isNull);
      expect(
        () => battler.copyWith(
          majorStatus: PsdkBattleMajorStatus.poison,
          clearMajorStatus: true,
        ),
        throwsArgumentError,
      );
    });
  });
}

BattleBattler _battler({
  String instanceId = 'player-bulbasaur',
  String speciesId = 'bulbasaur',
  String displayName = 'Bulbasaur',
  int bank = 0,
  int position = 0,
  int partyIndex = 0,
  int level = 10,
  int hp = 40,
  int maxHp = 40,
  List<BattleMoveInstance>? moves,
}) {
  return BattleBattler(
    instanceId: instanceId,
    speciesId: speciesId,
    displayName: displayName,
    bank: bank,
    position: position,
    partyId: 0,
    partyIndex: partyIndex,
    level: level,
    types: const BattleTypes(primary: 'grass', secondary: 'poison'),
    stats: const BattleComputedStats(
      attack: 49,
      defense: 49,
      specialAttack: 65,
      specialDefense: 65,
      speed: 45,
    ),
    hp: hp,
    maxHp: maxHp,
    moves: moves ??
        <BattleMoveInstance>[
          BattleMoveInstance(
            id: 'tackle',
            dbSymbol: 'tackle',
            pp: 35,
            maxPp: 35,
          ),
        ],
  );
}

PsdkBattleCombatantSetup _psdkCombatant({
  PsdkBattleMajorStatus? majorStatus,
}) {
  return PsdkBattleCombatantSetup(
    id: 'psdk-player',
    speciesId: 'bulbasaur',
    displayName: 'Bulbasaur',
    level: 10,
    maxHp: 40,
    currentHp: 40,
    types: const PsdkBattleTypes(primary: 'grass', secondary: 'poison'),
    stats: const PsdkBattleStats(
      attack: 49,
      defense: 49,
      specialAttack: 65,
      specialDefense: 65,
      speed: 45,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: 'tackle',
        dbSymbol: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: 40,
        accuracy: 100,
        pp: 35,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
    majorStatus: majorStatus,
  );
}
