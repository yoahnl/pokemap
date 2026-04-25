import 'battle_effect.dart';
import 'battle_effect_scope.dart';
import 'move/aqua_ring_effect.dart';
import 'move/curse_effect.dart';
import 'move/protect_effect.dart';

/// Small id-to-effect factory used by compatibility constructors.
///
/// FIGHT-03 only registers Protect because it is the only active migrated
/// effect. Unknown ids intentionally become passive generic effects instead of
/// failing: existing tests and setup fixtures can still carry dependency ids
/// such as `gravity` before their behavior lots are implemented.
final class BattleEffectRegistry {
  const BattleEffectRegistry();

  BattleEffect fromId(String id) {
    return switch (id) {
      'aqua_ring' => const AquaRingEffect(scope: LocalBattleEffectScope()),
      'curse' => const CurseEffect(scope: LocalBattleEffectScope()),
      'protect' => const ProtectEffect(scope: LocalBattleEffectScope()),
      final value => GenericBattleEffect(id: value),
    };
  }
}
