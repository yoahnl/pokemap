import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../move/disable_effect.dart';
import 'ability_effect.dart';

final class ContactDisableAbilityEffect extends BattleAbilityEffect {
  const ContactDisableAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    this.chanceNumerator = 3,
    this.chanceDenominator = 10,
  }) : super(abilityId: abilityId, scope: scope);

  final int chanceNumerator;
  final int chanceDenominator;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ContactDisableAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      chanceNumerator: chanceNumerator,
      chanceDenominator: chanceDenominator,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted ||
        !context.move.flags.contact ||
        context.move.dbSymbol == 'struggle') {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    if (user.isFainted || user.effects.contains('disable')) {
      return null;
    }

    final roll = context.rng.generic.nextChance(
      numerator: chanceNumerator,
      denominator: chanceDenominator,
    );
    final nextRng = context.rng.copyWith(generic: roll.next);
    if (!roll.didOccur) {
      return BattleEffectPostDamageResult(
        state: context.state,
        rng: nextRng,
        applied: false,
      );
    }

    final disable = DisableEffect(
      scope: BattlerBattleEffectScope(context.user),
      disabledMoveId: context.move.id,
    );
    final installed = context.state.updateBattler(
      context.user,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(disable),
      ),
    );
    final post = installed
        .battlerAt(context.user)
        .effects
        .dispatchPostVolatileStatusChange(
          BattleEffectVolatileStatusChangeContext(
            state: installed,
            rng: nextRng,
            turn: context.turn,
            owner: context.user,
            user: context.target,
            target: context.user,
            effectId: disable.id,
            cured: false,
            moveId: 'ability:$abilityId',
            move: context.move,
          ),
        );
    return BattleEffectPostDamageResult(
      state: post.state,
      rng: post.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.added(
          turn: context.turn,
          target: context.user,
          effectId: disable.id,
          remainingTurns: disable.remainingTurns,
          reason: 'ability:$abilityId',
        ),
        ...post.events,
      ],
    );
  }
}
