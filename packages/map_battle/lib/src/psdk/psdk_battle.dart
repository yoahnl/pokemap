/// Public barrel for the parallel Pokemon SDK battle foundation.
///
/// This barrel is exported from `map_battle.dart` so tests, tools, and future
/// adapters can exercise the PSDK lane without importing legacy `BattleSession`
/// internals. The implementation stays split by responsibility below to avoid
/// recreating another monolithic battle file.
library psdk_battle;

export '../domain/move/battle_move_prevention.dart'
    show
        BattleMoveAccuracyHook,
        BattleMoveAccuracyHookContext,
        BattleMoveFailureContext,
        BattleMoveFailureHook,
        BattleMoveFailureReason,
        BattleMoveFailureReasonJson,
        BattleMoveProcedureHooks,
        BattleMoveUserPreventionContext,
        BattleMoveUserPreventionHook,
        BattleMoveUserPreventionResult;
export '../domain/battler/battle_combatant_history.dart';
export '../domain/battler/battle_grounding_resolver.dart';
export '../domain/battler/battle_transform_state.dart';
export '../domain/effect/battle_effect.dart';
export '../domain/effect/battle_effect_hooks.dart';
export '../domain/effect/battle_effect_scope.dart';
export '../domain/effect/ability/ability_effect.dart';
export '../domain/effect/ability/ability_effect_registry.dart';
export '../domain/effect/ability/air_lock_effect.dart';
export '../domain/effect/ability/cloud_nine_effect.dart';
export '../domain/effect/ability/damp_effect.dart';
export '../domain/effect/ability/levitate_effect.dart';
export '../domain/effect/ability/no_guard_effect.dart';
export '../domain/effect/ability/reckless_effect.dart';
export '../domain/effect/ability/rock_head_effect.dart';
export '../domain/effect/ability/skill_link_effect.dart';
export '../domain/effect/ability/status_immunity_effect.dart';
export '../domain/effect/field/terrain_effect.dart';
export '../domain/effect/field/weather_effect.dart';
export '../domain/effect/item/air_balloon_effect.dart';
export '../domain/effect/item/iron_ball_effect.dart';
export '../domain/effect/item/item_effect.dart';
export '../domain/effect/item/item_effect_registry.dart';
export '../domain/effect/item/loaded_dice_effect.dart';
export '../domain/effect/item/terrain_extender_effect.dart';
export '../domain/effect/item/weather_rock_effect.dart';
export '../domain/effect/move/aqua_ring_effect.dart';
export '../domain/effect/move/baton_pass_effect.dart';
export '../domain/effect/move/confusion_effect.dart';
export '../domain/effect/move/curse_effect.dart';
export '../domain/effect/move/ingrain_effect.dart';
export '../domain/effect/move/leech_seed_effect.dart';
export '../domain/effect/move/protect_effect.dart';
export '../domain/effect/status/burn_effect.dart';
export '../domain/effect/status/freeze_effect.dart';
export '../domain/effect/status/paralysis_effect.dart';
export '../domain/effect/status/poison_effect.dart';
export '../domain/effect/status/sleep_effect.dart';
export '../domain/effect/status/status_effect_registry.dart';
export '../domain/effect/status/toxic_effect.dart';
export 'application/psdk_battle_engine.dart';
export 'application/psdk_battle_move_behavior.dart';
export 'domain/psdk_battle_combatant.dart';
export 'domain/psdk_battle_field.dart';
export 'domain/psdk_battle_move.dart';
export 'domain/psdk_battle_outcome.dart';
export 'domain/psdk_battle_rng.dart';
export 'domain/psdk_battle_setup.dart';
export 'domain/psdk_battle_slots.dart';
export 'domain/psdk_battle_state.dart';
export 'domain/psdk_battle_timeline.dart';
