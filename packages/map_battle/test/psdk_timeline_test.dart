import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _player = BattlePositionRef(bank: 0, position: 0);
const _opponent = BattlePositionRef(bank: 1, position: 0);

void main() {
  group('PSDK clean timeline', () {
    test('stores clean events and adapts back to the PSDK smoke timeline', () {
      final events = <BattleTimelineEvent>[
        const BattleTurnStartedTimelineEvent(turn: 1),
        BattleMoveDeclaredTimelineEvent(
          user: _player,
          targets: const <BattlePositionRef>[_opponent],
          moveId: 'scratch',
          moveName: 'Scratch',
          moveDbSymbol: 'scratch',
        ),
        const BattleDamageTimelineEvent(
          user: _player,
          target: _opponent,
          moveId: 'scratch',
          damage: 18,
          remainingHp: 0,
          maxHp: 18,
          critical: false,
        ),
        const BattleEndedTimelineEvent(
          outcome: PsdkBattleOutcome(kind: PsdkBattleOutcomeKind.victory),
        ),
      ];
      final timeline = BattleTimeline(events: events);

      expect(timeline.events, hasLength(4));
      expect(timeline.toJson().map((event) => event['kind']), <String>[
        'turn_started',
        'move_declared',
        'damage',
        'battle_ended',
      ]);
      expect(() => timeline.events.clear(), throwsUnsupportedError);
      expect(timeline.psdkTimeline.events.whereType<PsdkBattleDamageEvent>(),
          hasLength(1));
      expect(timeline.psdkTimeline.toJson().map((event) => event['kind']),
          <String>['turn_started', 'move_declared', 'damage', 'battle_ended']);
    });

    test('BattleEngine emits clean timeline while PsdkBattleEngine stays PSDK',
        () {
      final setup = _setup();

      final clean = BattleEngine(setup: BattleEngineSetup.fromPsdk(setup))
          .submit(const BattleDecision.fight(moveSlot: 0));
      final psdk = PsdkBattleEngine(setup: setup)
          .submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(
        clean.timeline.events.whereType<BattleDamageTimelineEvent>(),
        hasLength(1),
      );
      expect(
        clean.timeline.events.whereType<PsdkBattleDamageEvent>(),
        isEmpty,
      );
      expect(psdk.timeline.events.whereType<PsdkBattleDamageEvent>(),
          hasLength(1));
      expect(
        clean.timeline.toJson().map((event) => event['kind']),
        containsAllInOrder(<String>[
          'turn_started',
          'move_declared',
          'animation_cue',
          'damage',
        ]),
      );
      expect(
        psdk.timeline.toJson().map((event) => event['kind']),
        containsAllInOrder(<String>[
          'turn_started',
          'move_declared',
          'animation_cue',
          'damage',
        ]),
      );
    });
  });
}

PsdkBattleSetup _setup() {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player-charmander',
      speciesId: 'charmander',
      speed: 65,
      hp: 44,
      moves: <PsdkBattleMoveData>[_move(power: 180)],
    ),
    opponent: _combatant(
      id: 'opponent-bulbasaur',
      speciesId: 'bulbasaur',
      speed: 45,
      hp: 18,
      moves: <PsdkBattleMoveData>[_move(power: 20)],
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 2,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required String speciesId,
  required int speed,
  required int hp,
  required List<PsdkBattleMoveData> moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId,
    displayName: speciesId,
    level: 10,
    maxHp: hp,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 64,
      defense: 49,
      specialAttack: 60,
      specialDefense: 50,
      speed: speed,
    ),
    moves: moves,
  );
}

PsdkBattleMoveData _move({required int power}) {
  return PsdkBattleMoveData(
    id: 'scratch',
    dbSymbol: 'scratch',
    name: 'Scratch',
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
