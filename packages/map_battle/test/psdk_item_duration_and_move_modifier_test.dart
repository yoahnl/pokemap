import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK duration and move modifier items', () {
    test('Big Root boosts drain moves only while item effects are active', () {
      final baseline = _runMove(
        playerCurrentHp: 10,
        playerMove: _move(
          id: 'absorb',
          battleEngineMethod: 's_absorb',
          power: 80,
          type: 'grass',
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final boosted = _runMove(
        playerCurrentHp: 10,
        playerHeldItemId: 'big_root',
        playerMove: _move(
          id: 'absorb',
          battleEngineMethod: 's_absorb',
          power: 80,
          type: 'grass',
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final suppressed = _runMove(
        playerCurrentHp: 10,
        playerHeldItemId: 'big_root',
        playerEffects: PsdkBattleEffectStack(
          values: const <String>['magic_room'],
        ),
        playerMove: _move(
          id: 'absorb',
          battleEngineMethod: 's_absorb',
          power: 80,
          type: 'grass',
          category: PsdkBattleMoveCategory.special,
        ),
      );

      expect(
        _heal(boosted, moveId: 'absorb'),
        greaterThan(_heal(baseline, moveId: 'absorb')),
      );
      expect(
        _heal(suppressed, moveId: 'absorb'),
        _heal(baseline, moveId: 'absorb'),
      );
    });

    test('Big Root boosts Leech Seed healing only while active', () {
      final baseline = _tickLeechSeed(sourceHeldItemId: null);
      final boosted = _tickLeechSeed(sourceHeldItemId: 'big_root');
      final suppressed = _tickLeechSeed(
        sourceHeldItemId: 'big_root',
        sourceEffects: PsdkBattleEffectStack(
          values: const <String>['magic_room'],
        ),
      );

      expect(
        _healFromEvents(boosted.events, moveId: 'effect:leech_seed'),
        greaterThan(
          _healFromEvents(baseline.events, moveId: 'effect:leech_seed'),
        ),
      );
      expect(
        _healFromEvents(suppressed.events, moveId: 'effect:leech_seed'),
        _healFromEvents(baseline.events, moveId: 'effect:leech_seed'),
      );
    });

    test('Binding Band residual damage is suppressed by Magic Room', () {
      final baseline = _runBind();
      final boosted = _runBind(playerHeldItemId: 'binding_band');
      final suppressed = _runBind(
        playerHeldItemId: 'binding_band',
        playerEffects: PsdkBattleEffectStack(
          values: const <String>['magic_room'],
        ),
      );

      expect(_damage(boosted, moveId: 'effect:bind'),
          greaterThan(_damage(baseline, moveId: 'effect:bind')));
      expect(
        _damage(suppressed, moveId: 'effect:bind'),
        _damage(baseline, moveId: 'effect:bind'),
      );
    });

    test('Grip Claw bind duration is suppressed by Magic Room', () {
      final boosted = _runBind(playerHeldItemId: 'grip_claw');
      final suppressed = _runBind(
        playerHeldItemId: 'grip_claw',
        playerEffects: PsdkBattleEffectStack(
          values: const <String>['magic_room'],
        ),
      );

      expect(_bindRemainingTurns(boosted), 6);
      expect(_bindRemainingTurns(suppressed), inInclusiveRange(3, 4));
    });

    test('registry hydrates branch-enabling Lot 56 held items', () {
      final registry = ItemEffectRegistry();

      for (final itemId in const <String>[
        'big_root',
        'binding_band',
        'grip_claw',
      ]) {
        expect(
          registry.create(itemId, owner: psdkPlayerSlot),
          isNotNull,
          reason: itemId,
        );
      }
    });
  });
}

const _seeds = BattleRngSeeds(
  moveDamage: 1,
  moveCritical: 99999,
  moveAccuracy: 3,
  generic: 4,
);

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  String? playerHeldItemId,
  int playerCurrentHp = 200,
  PsdkBattleEffectStack playerEffects = const PsdkBattleEffectStack.empty(),
}) {
  final engine = PsdkBattleEngine(
    setup: BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        heldItemId: playerHeldItemId,
        currentHp: playerCurrentHp,
        effects: playerEffects,
        moves: <PsdkBattleMoveData>[playerMove],
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: 200,
        speed: 1,
        moves: <PsdkBattleMoveData>[
          _move(
            id: 'opponent_wait',
            power: 0,
            category: PsdkBattleMoveCategory.status,
            battleEngineMethod: 's_splash',
          ),
        ],
      ),
      rngSeeds: _seeds.psdkSeeds,
    ).psdkSetup,
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleTurnResult _runBind({
  String? playerHeldItemId,
  PsdkBattleEffectStack playerEffects = const PsdkBattleEffectStack.empty(),
}) {
  return _runMove(
    playerHeldItemId: playerHeldItemId,
    playerEffects: playerEffects,
    playerMove: _move(
      id: 'bind',
      battleEngineMethod: 's_bind',
      power: 15,
    ),
  );
}

BattleHandlerResult _tickLeechSeed({
  required String? sourceHeldItemId,
  PsdkBattleEffectStack sourceEffects = const PsdkBattleEffectStack.empty(),
}) {
  final state = PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'source',
          currentHp: 40,
          heldItemId: sourceHeldItemId,
          effects: sourceEffects,
          moves: <PsdkBattleMoveData>[
            _move(id: 'tackle', power: 40),
          ],
        ),
      ),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'seeded',
          moves: <PsdkBattleMoveData>[
            _move(id: 'tackle', power: 40),
          ],
          effects: const PsdkBattleEffectStack.empty().addEffect(
            LeechSeedEffect(
              scope: BattlerBattleEffectScope(psdkOpponentSlot),
              source: psdkPlayerSlot,
            ),
          ),
        ),
      ),
    },
  );
  return const BattleEndTurnHandler().tickEndTurnEffects(
    BattleHandlerContext(
      state: state,
      rng: BattleRngStreams.fromSeedSnapshot(_seeds),
      turn: 2,
      user: psdkPlayerSlot,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required List<PsdkBattleMoveData> moves,
  String? heldItemId,
  int currentHp = 200,
  int speed = 100,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 200,
    currentHp: currentHp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    heldItemId: heldItemId,
    effects: effects,
    moves: moves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  required int power,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  String battleEngineMethod = 's_basic',
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
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

int _heal(PsdkBattleTurnResult result, {required String moveId}) {
  return _healFromEvents(result.timeline.events, moveId: moveId);
}

int _healFromEvents(Iterable<PsdkBattleEvent> events,
    {required String moveId}) {
  return events
      .whereType<PsdkBattleHealEvent>()
      .where((event) => event.moveId == moveId)
      .fold<int>(0, (sum, event) => sum + event.amount);
}

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .fold<int>(0, (sum, event) => sum + event.damage);
}

int? _bindRemainingTurns(PsdkBattleTurnResult result) {
  final effect = result.state
      .battlerAt(psdkOpponentSlot)
      .effects
      .effects
      .singleWhere((effect) => effect.id == PsdkBattleEffectIds.bind);
  return effect.remainingTurns;
}
