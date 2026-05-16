import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK post-damage effects', () {
    test('defender contact effect can damage the attacker after damage', () {
      final state = _state(
        playerEffects: const PsdkBattleEffectStack.empty(),
        opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
          _RoughSkinFixtureEffect(
              scope: BattlerBattleEffectScope(psdkOpponentSlot)),
        ),
      );

      final result = const BattleDamageHandler().applyDamage(
        context: _context(state: state),
        target: psdkOpponentSlot,
        moveId: 'scratch',
        rawDamage: 20,
        move: _moveDefinition(id: 'scratch', contact: true),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final opponent = result.state.battlerAt(psdkOpponentSlot);
      final damages = result.events.whereType<PsdkBattleDamageEvent>().toList();

      expect(opponent.currentHp, 80);
      expect(player.currentHp, 88);
      expect(damages.map((event) => event.moveId), <String>[
        'scratch',
        'effect:rough_skin_fixture',
      ]);
    });

    test(
        'attacker post-damage effect can damage its owner after target effects',
        () {
      final state = _state(
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          _LifeOrbFixtureEffect(
              scope: BattlerBattleEffectScope(psdkPlayerSlot)),
        ),
        opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
          _RoughSkinFixtureEffect(
              scope: BattlerBattleEffectScope(psdkOpponentSlot)),
        ),
      );

      final result = const BattleDamageHandler().applyDamage(
        context: _context(state: state),
        target: psdkOpponentSlot,
        moveId: 'scratch',
        rawDamage: 20,
        move: _moveDefinition(id: 'scratch', contact: true),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final damages = result.events.whereType<PsdkBattleDamageEvent>().toList();

      expect(player.currentHp, 78);
      expect(damages.map((event) => event.moveId), <String>[
        'scratch',
        'effect:rough_skin_fixture',
        'effect:life_orb_fixture',
      ]);
    });

    test('post-damage context marks fatal target damage deterministically', () {
      final state = _state(
        playerEffects: const PsdkBattleEffectStack.empty(),
        opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
          _DeathMarkerFixtureEffect(
            scope: BattlerBattleEffectScope(psdkOpponentSlot),
          ),
        ),
      );

      final result = const BattleDamageHandler().applyDamage(
        context: _context(state: state),
        target: psdkOpponentSlot,
        moveId: 'scratch',
        rawDamage: 100,
        move: _moveDefinition(id: 'scratch', contact: true),
      );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 0);
      expect(
        result.events.whereType<PsdkBattleEffectEvent>().single.toJson(),
        containsPair('reason', 'fatal'),
      );
    });
  });
}

final class _RoughSkinFixtureEffect extends BattleEffect {
  const _RoughSkinFixtureEffect({required BattleEffectScope scope})
      : super(id: 'rough_skin_fixture', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) => this;

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (!_appliesTo(context.owner) ||
        context.owner != context.target ||
        !context.move.flags.contact ||
        context.user.bank == context.target.bank ||
        context.damage <= 0) {
      return null;
    }

    return _applyFixtureDamage(
      context: context,
      target: context.user,
      moveId: 'effect:rough_skin_fixture',
      damage: 12,
    );
  }

  bool _appliesTo(PsdkBattleSlotRef owner) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == owner;
  }
}

final class _LifeOrbFixtureEffect extends BattleEffect {
  const _LifeOrbFixtureEffect({required BattleEffectScope scope})
      : super(id: 'life_orb_fixture', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) => this;

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (!_appliesTo(context.owner) ||
        context.owner != context.user ||
        context.user.bank == context.target.bank ||
        context.damage <= 0) {
      return null;
    }

    return _applyFixtureDamage(
      context: context,
      target: context.user,
      moveId: 'effect:life_orb_fixture',
      damage: 10,
    );
  }

  bool _appliesTo(PsdkBattleSlotRef owner) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == owner;
  }
}

final class _DeathMarkerFixtureEffect extends BattleEffect {
  const _DeathMarkerFixtureEffect({required BattleEffectScope scope})
      : super(id: 'death_marker_fixture', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) => this;

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (!context.targetFainted || context.owner != context.target) {
      return null;
    }

    return BattleEffectPostDamageResult(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.removed(
          turn: context.turn,
          target: context.target,
          effectId: id,
          reason: 'fatal',
        ),
      ],
    );
  }
}

BattleEffectPostDamageResult _applyFixtureDamage({
  required BattleEffectPostDamageContext context,
  required PsdkBattleSlotRef target,
  required String moveId,
  required int damage,
}) {
  final targetBattler = context.state.battlerAt(target);
  final nextHp = (targetBattler.currentHp - damage)
      .clamp(0, targetBattler.currentHp)
      .toInt();
  final nextState = context.state.replaceBattler(
    target,
    targetBattler.copyWith(currentHp: nextHp),
  );
  return BattleEffectPostDamageResult(
    state: nextState,
    rng: context.rng,
    events: <PsdkBattleEvent>[
      PsdkBattleDamageEvent(
        user: context.owner,
        target: target,
        moveId: moveId,
        damage: targetBattler.currentHp - nextHp,
        remainingHp: nextHp,
      ),
    ],
  );
}

BattleHandlerContext _context({required PsdkBattleState state}) {
  return BattleHandlerContext(
    state: state,
    rng: BattleRngStreams.fromSeeds(
      moveDamageSeed: 1,
      moveCriticalSeed: 2,
      moveAccuracySeed: 3,
      genericSeed: 4,
    ),
    turn: 3,
    user: psdkPlayerSlot,
  );
}

PsdkBattleState _state({
  required PsdkBattleEffectStack playerEffects,
  required PsdkBattleEffectStack opponentEffects,
}) {
  return PsdkBattleState.fromSetup(
    PsdkBattleSetup.singles(
      player: _combatant(id: 'player', effects: playerEffects),
      opponent: _combatant(id: 'opponent', effects: opponentEffects),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 2,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleEffectStack effects,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    effects: effects,
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: 'scratch',
        dbSymbol: 'scratch',
        name: 'scratch',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: 40,
        accuracy: 100,
        pp: 35,
        priority: 0,
        criticalRate: 1,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
  );
}

BattleMoveDefinition _moveDefinition({
  required String id,
  required bool contact,
}) {
  return BattleMoveDefinition(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
    flags: BattleMoveFlags(contact: contact),
  );
}
