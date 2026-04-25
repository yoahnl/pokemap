# PSDK Fight Parity Next Lots

Date: 2026-04-25

## Baseline

Sources:

- `reports/psdk-fight-engine-parity-status.md`
- `reports/psdk-move-porting-matrix.md`
- `reports/psdk-effect-porting-matrix.md`
- `reports/psdk-attack-coverage.md`
- `pokemonsdk-development/scripts/5 Battle`

Current measured state:

| Axis | Current |
| --- | ---: |
| PSDK move methods | 330 |
| Move methods ported | 21 |
| Move methods partial | 61 |
| Move methods missing | 248 |
| PSDK effect classes | 482 |
| Effect classes ported | 0 |
| Effect classes partial | 7 |
| Effect classes missing | 475 |
| Studio attacks in local source | 728 |
| Studio attacks fait | 29 |
| Studio attacks partiel | 429 |
| Studio attacks pas_fait | 270 |

Goal: move from isolated move-family behavior to real Pokemon SDK parity by
porting the shared PSDK effect/handler/action surfaces first, then using those
surfaces to finish move families.

Rules for every lot:

- `packages/map_battle` stays pure Dart.
- Start with a failing targeted test.
- Keep reports generated from tools, not hand-edited counts.
- Prefer one commit per lot, or one commit per tightly coupled batch.
- Run at least `cd packages/map_battle && dart analyze && dart test`.

## Lot PSDK-PARITY-01 - End-Turn Effect Kernel

Status: completed in `codex/psdk-fight-next-move-wave`.

Purpose: make PSDK move effects executable at end of turn instead of passive ids.

Files to modify:

- `packages/map_battle/lib/src/domain/effect/battle_effect.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_hooks.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_registry.dart`
- `packages/map_battle/lib/src/domain/handler/battle_end_turn_handler.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/advanced_stat_move_behavior.dart`
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/tool/extract_psdk_move_registry.dart`
- `packages/map_battle/test/psdk_effect_kernel_test.dart`
- `packages/map_battle/test/psdk_move_families/advanced_stat_moves_test.dart`
- `packages/map_battle/test/psdk_registry_manifest_test.dart`

Files to create:

- `packages/map_battle/lib/src/domain/effect/move/curse_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/aqua_ring_effect.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/persistent_effect_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/persistent_effect_moves_test.dart`

Logic:

- Add a generic `onEndTurn` hook to `BattleEffect`.
- Let `BattleEndTurnHandler` iterate alive battlers and execute their effect
  hooks before field/weather expiration.
- Port `Effects::Curse`: each end turn, cursed target loses `maxHp / 4`,
  clamped to at least 1 and current HP.
- Port `Effects::AquaRing`: each end turn, target heals `maxHp / 16`,
  clamped by missing HP.
- Port `s_aqua_ring`: fails if all targets already have Aqua Ring; otherwise
  adds `AquaRingEffect`.
- Upgrade ghost `s_curse` from generic `curse` id to `CurseEffect`.

Verification:

- `dart test test/psdk_effect_kernel_test.dart test/psdk_move_families/advanced_stat_moves_test.dart test/psdk_move_families/persistent_effect_moves_test.dart`
- `dart run tool/extract_psdk_move_registry.dart`
- `dart run tool/generate_psdk_attack_coverage_report.dart`
- `dart analyze`
- `dart test`

Expected parity movement:

- `s_aqua_ring`: `missing` -> `partial`.
- `s_curse`: closer to `ported`, but remains `partial` until Magic Guard,
  duplicate-target messaging and Baton Pass transfer are modeled.
- Effect matrix should mark `AquaRing` and `Curse` at least `partial`.

## Lot PSDK-PARITY-02 - Effect Lifecycle And Transfer

Status: in progress in `codex/psdk-fight-next-move-wave`.

Purpose: model PSDK effect deletion, turn counters and Baton Pass transfer.

Files to modify/create:

- `packages/map_battle/lib/src/domain/effect/battle_effect.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_stack.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_scope.dart`
- `packages/map_battle/lib/src/domain/handler/battle_switch_handler.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/switch_effect_move_behavior.dart`
- `packages/map_battle/test/psdk_effect_lifecycle_test.dart`
- `packages/map_battle/test/psdk_move_families/switch_effect_moves_test.dart`

Logic:

- Add lifecycle hooks: `onDelete`, `onSwitchOut`, `onBatonPassTransfer`.
- Port transferable move effects used by PSDK: `Curse`, `AquaRing`,
  `Substitute`, `Confusion`, `LeechSeed`, `Ingrain` where applicable.
- Implement `s_baton_pass` enough to transfer stat stages and transferable
  effects to the incoming combatant.

Done so far:

- Added `BattleEffectBatonPassContext` and the object-effect
  `onBatonPassTransfer` hook.
- Added object-stack helpers to collect transferable effects and remove them
  from the source combatant.
- Added `BatonPassEffect` plus registry/export wiring.
- Made `AquaRingEffect` and `CurseEffect` transfer to the incoming combatant
  with the new target scope.
- Added `BattleSwitchHandler.batonPassTransfer` to move stat stages and
  transferable effects from source to replacement, then clear source stat
  stages and the one-shot `baton_pass` marker.
- Added `SwitchEffectMoveBehavior.batonPass` and registered `s_baton_pass`.
- Updated generated move/effect/attack parity reports:
  `s_baton_pass` is now `partial`, `BatonPass` is now `partial`, and the
  Studio attack coverage moved one attack from `pas_fait` to `partiel`.
- Added `IngrainEffect` and `LeechSeedEffect` object hooks:
  `s_ingrain` and `s_leech_seed` are now `partial`, `Ingrain` and
  `LeechSeed` are now `partial`, and the Studio attack coverage moved two more
  attacks from `pas_fait` to `partiel`.
- Added switch-prevention plumbing for object effects, currently exercised by
  `IngrainEffect`.
- Added CLI smoke scenarios for `ingrain` and `leech_seed` so the new
  persistent-effect behavior can be checked from `psdk_battle_cli.dart`.
- Added the object-effect user-prevention hook and `ConfusionEffect`:
  the PSDK countdown, final cleanup, 50% self-hit roll and typeless 40-power
  self damage now execute before PP is spent. `Confusion` is now `partial` in
  the generated effect matrix.
- Added a CLI smoke scenario `--scenario confusion` that emits the self-hit
  damage and `move_failed` JSON events for behavior checks.

Still remaining in this lot:

- Add explicit deletion/switch-out lifecycle hooks for effects that need PSDK
  cleanup behavior beyond Baton Pass transfer.
- Port `Substitute` and any remaining PSDK edge case tied to copied/deleted
  volatile effects. `Confusion` is intentionally not treated as Baton Pass
  transferable here because the inspected PSDK `Confusion.rb` file does not
  expose a Baton Pass transfer override.
- Wire Studio `CONFUSED` move statuses (`Confuse Ray`, `Supersonic`, etc.) to
  `ConfusionEffect`, including randomized PSDK duration and immunity/cure
  interactions such as Own Tempo/Persim-style behavior.
- Complete the PSDK edge cases for `Ingrain` and `LeechSeed`: Ghost/Teleport
  switch exceptions, forced-switch handling, Liquid Ooze, explicit
  `LeechSeed::Mark` modeling and full origin cleanup.
- Wire Baton Pass into a full party switch action, including replacement
  selection, invalid-switch handling and battle events/messages.
- Promote `s_baton_pass` from `partial` only after the full switch action
  matches PSDK behavior.

## Lot PSDK-PARITY-03 - Screens, Barriers And Protection Variants

Purpose: port the side effects that gate large families of common moves.

Files to modify/create:

- `packages/map_battle/lib/src/domain/effect/move/light_screen_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/reflect_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/aurora_veil_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/protect_effect.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/screen_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/screen_moves_test.dart`
- `packages/map_battle/test/psdk_move_families/protect_variants_test.dart`

Logic:

- Port `s_reflect`, `s_protect`, `s_crafty_shield`, `s_quick_guard`,
  `s_wide_guard`, `s_mat_block`, `s_endure`.
- Add side-scoped effects and duration handling.
- Add Protect success-rate decay based on recent protect attempts.

## Lot PSDK-PARITY-04 - Hazards And Side Field Effects

Purpose: support entry hazards and side cleanup.

Files to modify/create:

- `packages/map_battle/lib/src/domain/effect/side/spikes_effect.dart`
- `packages/map_battle/lib/src/domain/effect/side/stealth_rock_effect.dart`
- `packages/map_battle/lib/src/domain/effect/side/toxic_spikes_effect.dart`
- `packages/map_battle/lib/src/domain/effect/side/sticky_web_effect.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/hazard_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/hazard_clear_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/hazard_moves_test.dart`

Logic:

- Port `s_spikes`, `s_stealth_rock`, `s_toxic_spikes`, `s_sticky_web`,
  `s_rapid_spin`, `s_defog`, `s_mortal_spin`, `s_ceaseless_edge`,
  `s_stone_axe`.
- Trigger hazards on switch-in through `BattleSwitchHandler`.

## Lot PSDK-PARITY-05 - Move Prevention Effects

Purpose: port effects that prevent, redirect or restrict move usage.

Files to modify/create:

- `packages/map_battle/lib/src/domain/effect/move/disable_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/encore_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/taunt_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/attract_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/confusion_effect.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/move_lock_behavior.dart`
- `packages/map_battle/test/psdk_move_families/move_prevention_test.dart`

Logic:

- Add user-prevention hooks for `Disable`, `Encore`, `Taunt`, `Torment`,
  `HealBlock`, `Imprison`, `Attract`, `Confusion`.
- Track disabled move ids and forced-next-move state in combatant history.

## Lot PSDK-PARITY-06 - Trapping And Switch Prevention

Purpose: implement effects that prevent voluntary switch and force switches.

Files to modify/create:

- `packages/map_battle/lib/src/domain/effect/move/bind_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/cant_switch_effect.dart`
- `packages/map_battle/lib/src/domain/effect/ability/shadow_tag_effect.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/trapping_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/force_switch_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/trapping_moves_test.dart`

Logic:

- Port `s_bind`, `s_cantflee`, `s_mean_look`, `s_dragon_tail`, `s_roar`,
  `s_whirlwind`, `s_parting_shot`, `s_flip_turn`, `s_uturn`.
- Add switch-prevention hooks and switch action validation.

## Lot PSDK-PARITY-07 - Two-Turn, Charge And Recharge Moves

Purpose: model multi-turn move state instead of resolving everything in one
action.

Files to modify/create:

- `packages/map_battle/lib/src/domain/effect/move/two_turn_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/recharge_effect.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/two_turn_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/two_turn_moves_test.dart`

Logic:

- Port `s_2turns`, `s_solar_beam`, `s_skull_bash`, `s_geomancy`,
  `s_electro_shot`, `s_hyper_beam`, `s_gigaton_hammer`.
- Track semi-invulnerable states and charge skipping under weather/items.

## Lot PSDK-PARITY-08 - Counter, Revenge And History Moves

Purpose: use damage/move history to resolve delayed or reactive damage.

Files to modify/create:

- `packages/map_battle/lib/src/domain/move/behaviors/counter_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/history_power_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/history_moves_test.dart`

Logic:

- Port `s_counter`, `s_mirror_coat`, `s_metal_burst`, `s_bide`,
  `s_avalanche`, `s_revenge`, `s_assurance`, `s_stomping_tantrum`,
  `s_payback`.
- Extend damage history with source move category and turn timing.

## Lot PSDK-PARITY-09 - Type And Ability Changing Moves

Purpose: support the moves that mutate typing or abilities.

Files to modify/create:

- `packages/map_battle/lib/src/domain/effect/move/change_type_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/ability_suppressed_effect.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/type_change_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/ability_change_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/type_ability_change_test.dart`

Logic:

- Port `s_change_type`, `s_add_type`, `s_conversion`, `s_conversion2`,
  `s_soak`, `s_burn_up`, `s_gastro_acid`, `s_worry_seed`, `s_simple_beam`,
  `s_entrainment`, `s_skill_swap`, `s_doodle`, `s_core_enforcer`.

## Lot PSDK-PARITY-10 - Item Changing And Consumption Moves

Purpose: implement item mutation hooks for move parity.

Files to modify/create:

- `packages/map_battle/lib/src/domain/effect/item/item_effect.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/item_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/item_moves_test.dart`

Logic:

- Port `s_knock_off`, `s_trick`, `s_switcheroo`, `s_bestow`, `s_fling`,
  `s_recycle`, `s_embargo`, `s_magic_room`, `s_corrosive_gas`, `s_belch`.
- Track held, consumed and restored items in PSDK combatant state.

## Lot PSDK-PARITY-11 - Ability And Item Effect Waves

Purpose: turn ability/item dependencies from partial to real hooks.

Files to modify/create:

- `packages/map_battle/lib/src/domain/effect/ability/*_effect.dart`
- `packages/map_battle/lib/src/domain/effect/item/*_effect.dart`
- `packages/map_battle/lib/src/domain/effect/ability/ability_effect_registry.dart`
- `packages/map_battle/lib/src/domain/effect/item/item_effect_registry.dart`
- `packages/map_battle/test/psdk_ability_effects_test.dart`
- `packages/map_battle/test/psdk_item_effects_test.dart`

Logic:

- Port high-impact abilities first: `magic_guard`, `sturdy`, `mold_breaker`,
  `unaware`, `guts`, `sheer_force`, `technician`, `prankster`, `serene_grace`,
  `intimidate`, `flash_fire`, type absorb abilities.
- Port high-impact items first: berries, choice items, focus sash, leftovers,
  life orb, eviolite, assault vest, protective pads, big root.

## Lot PSDK-PARITY-12 - Z-Moves And Unknown Studio Methods

Purpose: eliminate the `unknown_methods` bucket in attack coverage.

Files to modify/create:

- `packages/map_battle/tool/extract_psdk_move_registry.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/z_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/z_moves_test.dart`

Logic:

- Add manifest entries for Studio-only methods: `s_z_move`,
  `s_self_stat_z_move`, `s_genesis_supernova`, `s_guardian_of_alola`,
  `s_hyperspace_hole`, `s_light_that_burns_the_sky`,
  `s_malicious_moonsault`, `s_splintered_stormshards`.
- Treat each as explicit partial until their exclusive effects are complete.

## Lot PSDK-PARITY-13 - Full Move Method Waves

Purpose: finish the remaining missing move methods once shared effects exist.

Files to modify/create:

- `packages/map_battle/lib/src/domain/move/behaviors/*.dart`
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/test/psdk_move_families/*_test.dart`
- `packages/map_battle/tool/extract_psdk_move_registry.dart`

Logic:

- Work alphabetically or by dependency-free clusters.
- Each method gets at least one direct behavior test and one registry test.
- A method becomes `ported` only when all listed PSDK dependencies are satisfied
  or explicitly irrelevant in this engine.

## Lot PSDK-PARITY-14 - Parity Gates

Purpose: prevent regressions and make progress visible.

Files to modify/create:

- `packages/map_battle/test/psdk_attack_coverage_report_test.dart`
- `packages/map_battle/test/psdk_registry_manifest_test.dart`
- `packages/map_battle/tool/generate_psdk_attack_coverage_report.dart`
- `scripts/generate_psdk_fight_parity.sh`

Logic:

- Add optional thresholds for `ported`, `partial` and `missing` counts.
- Keep thresholds monotonic: a PR may improve counts, but not silently regress.
- Generate all PSDK reports through one command.
