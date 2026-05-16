import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';

final class SpikesEffect extends BattleEffect {
  SpikesEffect({
    required this.bank,
    this.layers = 1,
  })  : assert(layers >= 1 && layers <= 3),
        super(id: 'spikes', scope: BankBattleEffectScope(bank));

  final int bank;
  final int layers;

  SpikesEffect empower() {
    return SpikesEffect(
      bank: bank,
      layers: layers >= 3 ? 3 : layers + 1,
    );
  }

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }
}

final class ToxicSpikesEffect extends BattleEffect {
  ToxicSpikesEffect({
    required this.bank,
    this.layers = 1,
  })  : assert(layers >= 1 && layers <= 2),
        super(id: 'toxic_spikes', scope: BankBattleEffectScope(bank));

  final int bank;
  final int layers;

  ToxicSpikesEffect empower() {
    return ToxicSpikesEffect(
      bank: bank,
      layers: layers >= 2 ? 2 : layers + 1,
    );
  }

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }
}

final class StealthRockEffect extends BattleEffect {
  StealthRockEffect({
    required this.bank,
  }) : super(id: 'stealth_rock', scope: BankBattleEffectScope(bank));

  final int bank;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }
}

final class StickyWebEffect extends BattleEffect {
  StickyWebEffect({
    required this.bank,
    this.origin,
  }) : super(id: 'sticky_web', scope: BankBattleEffectScope(bank));

  final int bank;
  final PsdkBattleSlotRef? origin;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }
}
