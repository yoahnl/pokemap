import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK generic stat/status hooks', () {
    test('target effects can prevent a major status through the hook stack',
        () {
      final context = _context(
        state: PsdkBattleState.fromSetup(
          _setup(
            opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
              _StatusPreventionFixtureEffect(),
            ),
          ),
        ),
      );

      final result = const BattleStatusChangeHandler().applyMajorStatus(
        context: context,
        target: psdkOpponentSlot,
        moveId: 'thunder_wave',
        status: PsdkBattleMajorStatus.paralysis,
      );

      expect(result.applied, isFalse);
      expect(result.reason, 'fixture_status_prevented');
      expect(result.events, isEmpty);
      expect(result.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
    });

    test('stat hooks can rewrite stages before applying the change', () {
      final context = _context(
        state: PsdkBattleState.fromSetup(
          _setup(
            opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
              _StatRewriteFixtureEffect(),
            ),
          ),
        ),
      );

      final result = const BattleStatChangeHandler().applyStatChange(
        context: context,
        target: psdkOpponentSlot,
        stat: 'defense',
        stages: -1,
      );

      final target = result.state.battlerAt(psdkOpponentSlot);
      expect(result.applied, isTrue);
      expect(result.amount, -2);
      expect(target.statStages.valueOf('defense'), -2);
      expect(result.events.whereType<PsdkBattleStatStageEvent>().single.amount,
          -2);
    });

    test('stat post hooks are dispatched after the stage change event', () {
      final context = _context(
        state: PsdkBattleState.fromSetup(
          _setup(
            opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
              _StatPostFixtureEffect(),
            ),
          ),
        ),
      );

      final result = const BattleStatChangeHandler().applyStatChange(
        context: context,
        target: psdkOpponentSlot,
        stat: 'attack',
        stages: 1,
      );

      expect(result.applied, isTrue);
      expect(result.events.first, isA<PsdkBattleStatStageEvent>());
      expect(
        result.events.whereType<PsdkBattleEffectEvent>().single.reason,
        'fixture_post_stat_change',
      );
    });

    test('status cure dispatches the post status hook after clearing status',
        () {
      final poisoned = PsdkBattleState.fromSetup(
        _setup(
          opponentStatus: PsdkBattleMajorStatus.poison,
          opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
            _StatusPostFixtureEffect(),
          ),
        ),
      );

      final result = const BattleStatusChangeHandler().cureMajorStatus(
        context: _context(state: poisoned),
        target: psdkOpponentSlot,
        moveId: 'refresh',
      );

      expect(result.applied, isTrue);
      expect(result.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(
        result.events.whereType<PsdkBattleEffectEvent>().single.reason,
        'fixture_post_status_cure',
      );
    });

    test('Substitute effect prevents opposing non-authentic stat hooks', () {
      final state = PsdkBattleState.fromSetup(_setup());
      const effect = SubstituteEffect(
        scope: BattlerBattleEffectScope(psdkOpponentSlot),
        remainingHp: 25,
      );
      final move = _moveDefinition(id: 'tail_whip');

      final decrease = effect.onStatDecreasePrevention(
        BattleEffectStatChangePreventionContext(
          state: state,
          rng: _rng(),
          turn: 3,
          owner: psdkOpponentSlot,
          user: psdkPlayerSlot,
          target: psdkOpponentSlot,
          stat: 'defense',
          stages: -1,
          move: move,
        ),
      );
      final increase = effect.onStatIncreasePrevention(
        BattleEffectStatChangePreventionContext(
          state: state,
          rng: _rng(),
          turn: 3,
          owner: psdkOpponentSlot,
          user: psdkPlayerSlot,
          target: psdkOpponentSlot,
          stat: 'attack',
          stages: 1,
          move: move,
        ),
      );

      expect(decrease, 'substitute');
      expect(increase, 'substitute');
    });

    test('Substitute effect prevents opposing non-authentic status hooks', () {
      final state = PsdkBattleState.fromSetup(_setup());
      const effect = SubstituteEffect(
        scope: BattlerBattleEffectScope(psdkOpponentSlot),
        remainingHp: 25,
      );

      final reason = effect.onStatusPrevention(
        BattleEffectStatusPreventionContext(
          state: state,
          rng: _rng(),
          turn: 3,
          owner: psdkOpponentSlot,
          user: psdkPlayerSlot,
          target: psdkOpponentSlot,
          status: PsdkBattleMajorStatus.paralysis,
          move: _moveDefinition(id: 'thunder_wave'),
        ),
      );

      expect(reason, 'substitute');
    });
  });
}

final class _StatPostFixtureEffect extends BattleEffect {
  const _StatPostFixtureEffect()
      : super(
          id: 'fixture_post_stat',
          scope: const BattlerBattleEffectScope(psdkOpponentSlot),
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) => this;

  @override
  BattleEffectStatChangePostResult? onStatChangePost(
    BattleEffectStatChangeContext context,
  ) {
    return BattleEffectStatChangePostResult(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.ticked(
          turn: context.turn,
          target: context.target,
          effectId: id,
          reason: 'fixture_post_stat_change',
        ),
      ],
    );
  }
}

final class _StatusPreventionFixtureEffect extends BattleEffect {
  const _StatusPreventionFixtureEffect()
      : super(
          id: 'fixture_status_prevention',
          scope: const BattlerBattleEffectScope(psdkOpponentSlot),
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) => this;

  @override
  String? onStatusPrevention(BattleEffectStatusPreventionContext context) {
    return context.status == PsdkBattleMajorStatus.paralysis
        ? 'fixture_status_prevented'
        : null;
  }
}

final class _StatRewriteFixtureEffect extends BattleEffect {
  const _StatRewriteFixtureEffect()
      : super(
          id: 'fixture_stat_rewrite',
          scope: const BattlerBattleEffectScope(psdkOpponentSlot),
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) => this;

  @override
  int? onStatChange(BattleEffectStatChangeContext context) {
    return context.stat == 'defense' && context.stages == -1 ? -2 : null;
  }
}

final class _StatusPostFixtureEffect extends BattleEffect {
  const _StatusPostFixtureEffect()
      : super(
          id: 'fixture_post_status',
          scope: const BattlerBattleEffectScope(psdkOpponentSlot),
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) => this;

  @override
  BattleEffectStatusChangeResult? onPostStatusChange(
    BattleEffectStatusChangeContext context,
  ) {
    if (!context.cured) {
      return null;
    }
    return BattleEffectStatusChangeResult(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.ticked(
          turn: context.turn,
          target: context.target,
          effectId: id,
          reason: 'fixture_post_status_cure',
        ),
      ],
    );
  }
}

BattleHandlerContext _context({
  PsdkBattleState? state,
  PsdkBattleSlotRef user = psdkPlayerSlot,
}) {
  return BattleHandlerContext(
    state: state ?? PsdkBattleState.fromSetup(_setup()),
    rng: _rng(),
    turn: 3,
    user: user,
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 1,
    moveAccuracySeed: 1,
    genericSeed: 1,
  );
}

BattleMoveDefinition _moveDefinition({
  required String id,
  bool sound = false,
}) {
  return BattleMoveDefinition.fromPsdk(
    PsdkBattleMoveData(
      id: id,
      dbSymbol: id,
      name: id,
      type: 'normal',
      category: PsdkBattleMoveCategory.status,
      power: 0,
      accuracy: 100,
      pp: 20,
      priority: 0,
      criticalRate: 1,
      sound: sound,
      battleEngineMethod: 's_status',
      target: PsdkBattleMoveTarget.adjacentFoe,
    ),
  );
}

PsdkBattleSetup _setup({
  PsdkBattleEffectStack? playerEffects,
  PsdkBattleEffectStack? opponentEffects,
  PsdkBattleMajorStatus? opponentStatus,
}) {
  return PsdkBattleSetup.singles(
    player: _combatant('player', effects: playerEffects),
    opponent: _combatant(
      'opponent',
      effects: opponentEffects,
      majorStatus: opponentStatus,
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 1,
      moveAccuracy: 1,
      generic: 1,
    ),
  );
}

PsdkBattleCombatantSetup _combatant(
  String id, {
  PsdkBattleEffectStack? effects,
  PsdkBattleMajorStatus? majorStatus,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 10,
    maxHp: 40,
    currentHp: 40,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 20,
      defense: 20,
      specialAttack: 20,
      specialDefense: 20,
      speed: 20,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: 'scratch',
        dbSymbol: 'scratch',
        name: 'Scratch',
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
    effects: effects,
    majorStatus: majorStatus,
  );
}
