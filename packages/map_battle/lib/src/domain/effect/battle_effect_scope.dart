import '../../psdk/domain/psdk_battle_slots.dart';

/// Scope owned by a PSDK battle effect.
///
/// Pokemon SDK can attach effects to battlers, positions, banks and the field.
/// FIGHT-03 only needs battler-local Protect, but the scope value is explicit so
/// later lots can add bank/field effects without changing the effect API again.
sealed class BattleEffectScope {
  const BattleEffectScope();
}

/// Scope used by compatibility stacks that are already owned by one battler.
final class LocalBattleEffectScope extends BattleEffectScope {
  const LocalBattleEffectScope();
}

final class BattlerBattleEffectScope extends BattleEffectScope {
  const BattlerBattleEffectScope(this.slot);

  final PsdkBattleSlotRef slot;
}

final class BankBattleEffectScope extends BattleEffectScope {
  const BankBattleEffectScope(this.bank);

  final int bank;
}

final class FieldBattleEffectScope extends BattleEffectScope {
  const FieldBattleEffectScope();
}
