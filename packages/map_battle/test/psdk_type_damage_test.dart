import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK clean type-aware damage', () {
    test('STAB and type effectiveness increase damage over a neutral hit', () {
      final neutral = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _damagingMove(
          id: 'swift',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );
      final superEffectiveStab = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _damagingMove(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );

      expect(neutral.damageToOpponent, 8);
      expect(superEffectiveStab.damageToOpponent, 24);
      expect(superEffectiveStab.timelineKinds, contains('damage'));
    });

    test('type immunity stops before animation and damage RNG', () {
      const seeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 2,
        moveAccuracy: 3,
        generic: 4,
      );
      final result = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'electric'),
        opponentTypes: const PsdkBattleTypes(primary: 'ground'),
        playerMove: _damagingMove(
          id: 'thunder_shock',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
        seeds: seeds,
      );

      expect(result.damageToOpponent, 0);
      expect(result.rngSeeds.moveDamage, seeds.moveDamage);
      expect(result.timelineKinds, contains('move_immune'));
      expect(
        result.timelineEvents.where(
          (event) =>
              event.kind == 'animation_cue' &&
              event.toJson()['moveId'] == 'thunder_shock',
        ),
        isEmpty,
      );
      expect(
        result.timelineEvents.where(
          (event) =>
              event.kind == 'damage' &&
              event.toJson()['moveId'] == 'thunder_shock',
        ),
        isEmpty,
      );
    });

    test('critical rate can force a critical hit through PSDK move data', () {
      const noCriticalSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      );
      const criticalSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 2,
        moveAccuracy: 3,
        generic: 4,
      );
      final baseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerMove: _damagingMove(
          id: 'tackle',
          type: 'normal',
          power: 40,
          criticalRate: 1,
        ),
        seeds: noCriticalSeeds,
      );
      final critical = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerMove: _damagingMove(
          id: 'karate_chop',
          type: 'normal',
          power: 40,
          criticalRate: 4,
        ),
        seeds: criticalSeeds,
      );

      expect(critical.damageToOpponent, greaterThan(baseline.damageToOpponent));
      expect(critical.rngSeeds.moveCritical, criticalSeeds.moveCritical);
      expect(critical.rngSeeds.moveDamage, isNot(criticalSeeds.moveDamage));
    });

    test('Tar Shot marker doubles fire-type effectiveness locally', () {
      final baseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _damagingMove(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );
      final tarred = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
          TarShotEffect(scope: BattlerBattleEffectScope(psdkOpponentSlot)),
        ),
        playerMove: _damagingMove(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );

      expect(baseline.damageToOpponent, 12);
      expect(tarred.damageToOpponent, 24);
    });
  });
}

_RunResult _runSinglePlayerMove({
  required PsdkBattleTypes playerTypes,
  required PsdkBattleTypes opponentTypes,
  required PsdkBattleMoveData playerMove,
  PsdkBattleEffectStack opponentEffects = const PsdkBattleEffectStack.empty(),
  BattleRngSeeds seeds = const BattleRngSeeds(
    moveDamage: 1,
    moveCritical: 99999,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  final setup = BattleEngineSetup.singles(
    player: _combatant(
      id: 'player',
      types: playerTypes,
      speed: 100,
      moves: <PsdkBattleMoveData>[playerMove],
    ),
    opponent: _combatant(
      id: 'opponent',
      types: opponentTypes,
      speed: 1,
      effects: opponentEffects,
      moves: <PsdkBattleMoveData>[
        _damagingMove(id: 'splash_hit', type: 'normal', power: 0),
      ],
    ),
    rngSeeds: seeds.psdkSeeds,
  );
  final engine = BattleEngine(setup: setup);
  final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
  final opponentHp = result.state.battlerAt(psdkOpponentSlot).currentHp;
  return _RunResult(
    damageToOpponent: 100 - opponentHp,
    timelineEvents: result.timeline.events,
    rngSeeds: result.state.rngSeeds,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleTypes types,
  required int speed,
  required List<PsdkBattleMoveData> moves,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: types,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: moves,
    effects: effects,
  );
}

PsdkBattleMoveData _damagingMove({
  required String id,
  required String type,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int criticalRate = 1,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: criticalRate,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

final class _RunResult {
  const _RunResult({
    required this.damageToOpponent,
    required this.timelineEvents,
    required this.rngSeeds,
  });

  final int damageToOpponent;
  final List<BattleTimelineEvent> timelineEvents;
  final BattleRngSeeds rngSeeds;

  List<String> get timelineKinds {
    return timelineEvents.map((event) => event.kind).toList(growable: false);
  }
}
