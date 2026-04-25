import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

enum _NoEffectMoveKind {
  splash,
  doNothing,
}

/// Ports PSDK moves whose Ruby `deal_effect` intentionally does not mutate
/// battle state.
///
/// The shared move procedure still emits declaration and animation events, and
/// still owns target resolution, accuracy, Protect and immunity. Splash remains
/// marked partial in the matrix because PSDK also displays a localized
/// "nothing happened" message, while this pure battle lane has no text event
/// contract yet.
final class NoEffectMoveBehavior implements BattleMoveBehavior {
  const NoEffectMoveBehavior.splash()
      : battleEngineMethod = 's_splash',
        _kind = _NoEffectMoveKind.splash;

  const NoEffectMoveBehavior.doNothing()
      : battleEngineMethod = 's_do_nothing',
        _kind = _NoEffectMoveKind.doNothing;

  @override
  final String battleEngineMethod;
  final _NoEffectMoveKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    // Both PSDK classes are deliberately state-neutral. The switch keeps the
    // family explicit so future message/event support can specialize Splash
    // without changing the registry contract.
    return switch (_kind) {
      _NoEffectMoveKind.splash ||
      _NoEffectMoveKind.doNothing =>
        prepared.toResolution(successful: true),
    };
  }
}
