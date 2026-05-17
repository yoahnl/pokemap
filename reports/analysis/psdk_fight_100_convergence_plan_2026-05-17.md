# PSDK Fight 100 Percent Convergence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the Dart battle engine to measurable 100% Pokemon SDK fight parity: `728 / 728` Studio attacks strict, `330 / 330` PSDK move methods ported, `482 / 482` PSDK effect classes ported, and runtime bridge parity measured.

**Architecture:** Keep the existing clean architecture: PSDK source extraction and manifests live in `packages/map_battle/lib/src/data`, battle semantics live in domain handlers/effects/move behaviors, playable runtime filtering lives in `packages/map_runtime`, and golden fixtures live under `packages/map_battle/test/fixtures/psdk_golden`. Every promotion from `partial` to `ported` must be source-backed by Pokemon SDK Ruby behavior, regression-tested, and visible in the audit CLI.

**Tech Stack:** Dart packages, `package:test`, generated manifests, local Pokemon SDK Ruby source under `pokemonsdk-development/scripts/5 Battle`, Studio move data under `pokémon_sdk_test_project/Data/Studio/moves`, runtime bridge diagnostics in `packages/map_runtime`, playable example in `examples/playable_runtime_host`.

---

## Current Baseline

Generated on 2026-05-17 with:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
dart run tool/psdk_fight_parity_audit.dart \
  --json /tmp/psdk-fight-audit-current.json \
  --markdown /tmp/psdk-fight-audit-current.md
```

| Axis | Current | Required | Gap |
| --- | ---: | ---: | ---: |
| Studio attacks strict `fait` | 267 | 728 | 461 |
| PSDK methods `ported` | 65 | 330 | 265 |
| PSDK effects `ported` | 0 | 482 | 482 |
| Runtime bridge | `not_measured` | measured | 1 |
| Golden fixtures | 1+ | representative family suite | broad gap |

Important: `partiel` means executable or partially modeled. It is not PSDK parity.

## Non-Negotiable Promotion Rule

A move method or effect can be marked `ported` only when all of these are true:

- The exact PSDK Ruby source path is named in the manifest or test.
- Success path, failure path, immunity/prevention path, and ordering path are tested when the PSDK class has those branches.
- RNG consumption uses `BattleRngStreams` and is deterministic in tests.
- PP, history, original move, target slot, and action order semantics match PSDK for that family.
- Interactions with ability, item, status, field, side, slot, and substitute effects are either covered or explicitly proven irrelevant.
- The audit CLI count increases for the intended axis.
- The final gate is not weakened except for user-approved, documented out-of-scope entries.

## Verification Commands

Run the focused command for each lot, then the shared checks:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
dart test test/<focused_test_file>.dart
dart test test/psdk_parity_gate_test.dart test/psdk_final_parity_gate_test.dart
dart run tool/psdk_fight_parity_audit.dart --gate
dart run tool/psdk_fight_parity_audit.dart \
  --json ../../reports/analysis/psdk_fight_parity_audit_latest.json \
  --markdown ../../reports/analysis/psdk_fight_parity_audit_latest.md
```

For lots touching runtime bridge:

```bash
cd /Users/karim/Project/pokemonProject
dart test packages/map_runtime/test/runtime_battle_move_bridge_test.dart
dart test packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
dart test examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart
```

Final convergence command:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
dart run tool/psdk_fight_parity_audit.dart \
  --final-gate \
  --goldens test/fixtures/psdk_golden
```

---

## Phase A - Measurement Must Become Complete

### Lot 66 - Materialized Gap Lists

**Purpose:** Stop working from aggregate counts only. The audit must emit exact missing/partial attacks, methods, and effects, grouped by PSDK family and dependency.

**Files:**
- Modify: `packages/map_battle/lib/src/data/psdk_fight_parity_audit.dart`
- Modify: `packages/map_battle/tool/psdk_fight_parity_audit.dart`
- Modify: `packages/map_battle/test/tool/psdk_fight_parity_audit_test.dart`
- Create: `reports/analysis/psdk_fight_gap_inventory.md`

**Logic:**
- Add JSON arrays:
  - `attacks.entries[]`: `moveId`, `battleEngineMethod`, `coverage`, `psdkStatus`, `reason`.
  - `methods.entries[]`: `battleEngineMethod`, `rubyClass`, `rubyPath`, `dartBehavior`, `status`, `dependencies`.
  - `effects.entries[]`: `family`, `rubyClass`, `rubyPath`, `status`, `dartEffect`.
- Add markdown sections for:
  - `Partial attacks by method`.
  - `Partial methods by dependency`.
  - `Missing effects by family`.
- Keep current summary fields stable so existing tests keep passing.

**Acceptance:**
- Audit still prints `267/728`, `65/330`, `0/482` before any behavior changes.
- `reports/analysis/psdk_fight_gap_inventory.md` can be regenerated and used as the source of truth for later lots.

### Lot 67 - Manifest Status Integrity Gate

**Purpose:** Prevent accidental `ported` inflation.

**Files:**
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_ability_effect_manifest.dart`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_item_effect_manifest.dart`
- Modify: `packages/map_battle/test/psdk_registry_manifest_test.dart`
- Modify: `packages/map_battle/test/psdk_effect_matrix_test.dart`

**Logic:**
- Add validation that every `ported` move method has:
  - non-empty `rubyPath`,
  - non-empty `dartBehavior`,
  - at least one matching focused test file or golden fixture tag.
- Add equivalent validation for ability/item/move/status/field/mechanics effects.
- For generated item manifest, introduce `PsdkItemPortStatus.ported` instead of only `partial`/`missing`.

**Acceptance:**
- Existing `ported` methods pass validation.
- Any manual status promotion without test evidence fails.

### Lot 68 - Runtime Bridge Measurement In Audit

**Purpose:** Replace final-gate `runtime_bridge status is not measured` with real diagnostics.

**Files:**
- Modify: `packages/map_battle/lib/src/data/psdk_fight_parity_audit.dart`
- Modify: `packages/map_battle/tool/psdk_fight_parity_audit.dart`
- Modify: `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- Modify: `packages/map_runtime/lib/src/application/runtime_battle_move_bridge_diagnostics.dart`
- Modify: `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- Modify: `packages/map_battle/test/psdk_final_parity_gate_test.dart`

**Logic:**
- Expose a runtime bridge report that counts:
  - bridgeable Studio moves,
  - non-bridgeable Studio moves,
  - non-bridgeable moves with explicit diagnostic reason,
  - PSDK status for each move.
- Add an optional audit CLI input or package-level bridge collector so final gate can read it.
- Final gate accepts `runtimeBridge.status == explained` while convergence is incomplete, then `complete` when no supported move is filtered.

**Acceptance:**
- Final gate no longer fails with `not_measured`.
- If any runtime-filtered move lacks a reason, final gate fails with that move id.

### Lot 69 - Golden Fixture Expansion Harness

**Purpose:** Make PSDK comparison meaningful beyond one basic fixture.

**Files:**
- Modify: `packages/map_battle/lib/src/data/psdk_golden_fixture.dart`
- Modify: `packages/map_battle/test/psdk_golden_fixture_test.dart`
- Modify: `packages/map_battle/test/fixtures/psdk_golden/schema.md`
- Create: `packages/map_battle/test/fixtures/psdk_golden/_index.md`

**Logic:**
- Add fixture tags: `move_method`, `effect_family`, `ability`, `item`, `status`, `field`, `doubles`, `runtime_bridge`.
- Add optional expected audit deltas per fixture.
- Add loader validation that every fixture declares:
  - PSDK source path,
  - deterministic seed,
  - setup,
  - action sequence,
  - expected timeline,
  - expected final state.

**Acceptance:**
- Existing fixture migrates to the new schema.
- Future lots can add fixtures without changing the loader.

### Lot 70 - Convergence Dashboard

**Purpose:** Keep progress visible without manually recalculating percentages.

**Files:**
- Create: `packages/map_battle/tool/update_psdk_fight_convergence_dashboard.dart`
- Create: `reports/analysis/psdk_fight_convergence_dashboard.md`
- Modify: `packages/map_battle/test/tool/psdk_fight_parity_audit_test.dart`

**Logic:**
- Read audit JSON.
- Emit a dashboard table:
  - total attack/method/effect counts,
  - remaining by family,
  - lots completed,
  - next recommended lot from highest-impact gap.
- Never overwrite historical audit reports.

**Acceptance:**
- Dashboard regenerates deterministically.
- Dashboard shows the current baseline before behavior work continues.

---

## Phase B - Close Existing In-Progress Lots 30-34

### Lot 71 - Copy/Call Action Semantics

**Purpose:** Finish Lot 30. Promote copy/call methods only when their PSDK action semantics are exact.

**PSDK Sources:**
- `10 Move/2 Definitions/300 SleepTalk.rb`
- `10 Move/2 Definitions/300 Metronome.rb`
- `10 Move/2 Definitions/300 Mimic.rb`
- `10 Move/2 Definitions/300 Sketch.rb`
- `10 Move/2 Definitions/300 MirrorMove.rb`
- `10 Move/2 Definitions/300 Assist.rb`
- `10 Move/2 Definitions/300 Instruct.rb`
- `10 Move/2 Definitions/300 Me First.rb`

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/copy_call_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/battler/battle_combatant_history.dart`
- Modify: `packages/map_battle/lib/src/domain/action/battle_action_queue.dart`
- Modify: `packages/map_battle/lib/src/domain/action/battle_action_ordering.dart`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Modify: `packages/map_battle/test/psdk_move_families/copy_call_move_behavior_test.dart`
- Add golden fixtures under `packages/map_battle/test/fixtures/psdk_golden/copy_call/`

**Logic:**
- Store PSDK-equivalent `originalMoveId`, `calledMoveId`, `lastMoveSuccessful`, `lastMoveAttempted`, `lastMoveTargets`.
- Model copied moves as child actions, not direct ad-hoc behavior calls.
- Use PSDK exclusion lists for every copy/call move.
- Add exact `Me First` damage multiplier as a damage modifier, not a local power approximation.
- Preserve PP rules:
  - caller PP is consumed,
  - called move PP is not consumed except `Instruct` repeating target action,
  - Sketch/Mimic slot replacement rules are exact.

**Acceptance:**
- Methods promoted from `partial` to `ported`: `s_sleep_talk`, `s_metronome`, `s_mimic`, `s_sketch`, `s_mirror_move`, `s_assist`, `s_instruct`, `s_me_first`.
- Golden fixtures cover at least one success and one failure per method.

### Lot 72 - Force Switch, Pivot, and Baton Pass

**Purpose:** Finish Lot 31.

**PSDK Sources:**
- `10 Move/2 Definitions/300 ForceSwitch.rb`
- `10 Move/2 Definitions/300 PartingShot.rb`
- `10 Move/2 Definitions/300 BatonPass.rb`
- `06 Effects/02 Move Effects/001 BatonPass.rb`

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/switch_effect_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/baton_pass_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_switch_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/battle/battle_party.dart`
- Modify: `packages/map_battle/test/psdk_move_families/switch_effect_moves_test.dart`
- Modify: `packages/map_battle/test/psdk_switch_action_test.dart`

**Logic:**
- Model force-switch as a resolved switch action with reserve selection.
- Damage-before-switch for Dragon Tail / Circle Throw.
- Self-pivot for U-turn / Volt Switch / Flip Turn / Parting Shot.
- Baton Pass transfers only PSDK-transferable stages/effects.
- Respect trapping, Suction Cups-like prevention, Ingrain, Shed Shell, fainted target, no reserve, and wild battle exceptions.

**Acceptance:**
- Promote `s_baton_pass`, `s_dragon_tail`, force-switch aliases, and pivot methods when all branches pass.
- Runtime bridge can mark self/force switch moves bridgeable.

### Lot 73 - Substitute Full Interaction Matrix

**Purpose:** Finish Lot 32.

**PSDK Sources:**
- `06 Effects/02 Move Effects/001 Substitute.rb`
- `10 Move/2 Definitions/300 Substitute.rb`
- `10 Move/2 Definitions/300 PreAttackMoves.rb`

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/move/substitute_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_damage_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_status_change_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_stat_change_handler.dart`
- Modify: `packages/map_battle/test/psdk_move_families/substitute_focus_punch_test.dart`

**Logic:**
- Block status/stat/volatile changes through Substitute according to PSDK.
- Implement sound, authentic, infiltrator, and bypass exceptions.
- Ensure multi-hit damage interacts with Substitute per hit.
- Focus Punch uses a preparation effect and fails from the exact PSDK disturbance causes.

**Acceptance:**
- `s_substitute` and `s_focus_punch` promoted only after matrix tests pass.
- Substitute effect counted as `ported` in effect matrix.

### Lot 74 - Delayed Move and Healing Sacrifice Effects

**Purpose:** Finish Lot 33.

**PSDK Sources:**
- `10 Move/2 Definitions/300 FutureSight.rb`
- `10 Move/2 Definitions/300 HealingSacrifice.rb`
- `06 Effects/02 Move Effects/001 FutureSight.rb`
- `06 Effects/02 Move Effects/001 Wish.rb`
- `06 Effects/02 Move Effects/001 HealingWish.rb`
- `06 Effects/02 Move Effects/001 LunarDance.rb`

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/field/delayed_move_effect.dart`
- Create: `packages/map_battle/lib/src/domain/effect/field/wish_effect.dart`
- Create: `packages/map_battle/lib/src/domain/effect/field/healing_wish_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_end_turn_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_switch_handler.dart`
- Modify: `packages/map_battle/test/psdk_move_families/delayed_attacks_test.dart`

**Logic:**
- Future Sight / Doom Desire target slots, not just current battlers.
- Wish heals the occupant of the slot after the correct delay.
- Healing Wish / Lunar Dance store pending switch-in healing and consume on eligible switch-in.
- Exact failure when a same-slot delayed effect already exists.

**Acceptance:**
- Promote delayed attack and healing sacrifice methods/effects.
- Golden fixtures cover switch replacement before delayed resolution.

### Lot 75 - Round, Echoed Voice, Pledge, and Combo Ordering

**Purpose:** Finish Lot 34.

**PSDK Sources:**
- `10 Move/1 Mechanics/130 Pledge.rb`
- `10 Move/2 Definitions/300 Round.rb`
- `10 Move/2 Definitions/300 EchoedVoice.rb`
- `06 Effects/02 Move Effects/001 EchoedVoice.rb`
- `06 Effects/02 Move Effects/001 Pledge Effects/001 Rainbow.rb`
- `06 Effects/02 Move Effects/001 Pledge Effects/001 SeaOfFire.rb`
- `06 Effects/02 Move Effects/001 Pledge Effects/001 Swamp.rb`

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/consecutive_power_move_behavior.dart`
- Create: `packages/map_battle/lib/src/domain/move/behaviors/pledge_combo_move_behavior.dart`
- Create: `packages/map_battle/lib/src/domain/effect/field/pledge_field_effects.dart`
- Modify: `packages/map_battle/lib/src/domain/action/battle_action_ordering.dart`
- Modify: `packages/map_battle/test/psdk_move_families/consecutive_power_moves_test.dart`
- Create: `packages/map_battle/test/psdk_move_families/pledge_combo_move_behavior_test.dart`

**Logic:**
- Round changes action order when ally has queued Round.
- Echoed Voice tracks successive successful uses.
- Pledge combines queued ally actions, changes power, and installs the correct field effect.
- Doubles target ordering and ally insertion must be queue-based.

**Acceptance:**
- Promote `s_round`, `s_echo`, `s_pledge` when queue and field effects match PSDK.

---

## Phase C - Move Method Convergence

### Lot 76 - Action Order and Priority Control Moves

**Purpose:** Port methods that primarily manipulate turn order.

**Move Methods:**
- `s_after_you`, `s_quash`, `s_trick_room`, `s_tailwind`, `s_electrify`, `s_ion_deluge`, `s_sucker_punch`, `s_fake_out`, `s_feint`, `s_helping_hand`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/action/battle_action_ordering.dart`
- Modify: `packages/map_battle/lib/src/domain/action/battle_action_queue.dart`
- Create: `packages/map_battle/lib/src/domain/effect/field/trick_room_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/flinch_effect.dart`
- Create: `packages/map_battle/test/psdk_move_families/action_order_control_moves_test.dart`

**Logic:**
- Queue mutations must happen before action execution where PSDK does.
- Trick Room reverses priority/speed tie resolution at the correct layer.
- Fake Out and Feint respect first-turn/protect-breaking branches.

**Acceptance:**
- All listed methods either ported or moved to a named follow-up only if PSDK source proves dependence on a later lot.

### Lot 77 - Variable Power Completion

**Purpose:** Finish variable-power methods still marked partial.

**Move Methods:**
- `s_acrobatics`, `s_assurance`, `s_avalanche`, `s_bide`, `s_counter`, `s_echo`, `s_expanding_force`, `s_fishious_rend`, `s_fury_cutter`, `s_genies_storm`, `s_gyro_ball`, `s_heavy_slam`, `s_hex`, `s_ice_ball`, `s_lash_out`, `s_low_kick`, `s_metal_burst`, `s_mirror_coat`, `s_payback`, `s_rage_fist`, `s_retaliate`, `s_revenge`, `s_rollout`, `s_solar_beam`, `s_stomping_tantrum`, `s_trump_card`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/variable_power_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/history_power_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/counter_damage_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/battler/battle_combatant_history.dart`
- Modify: `packages/map_battle/test/psdk_move_families/variable_power_test.dart`
- Modify: `packages/map_battle/test/psdk_move_families/history_power_moves_test.dart`
- Modify: `packages/map_battle/test/psdk_move_families/counter_damage_moves_test.dart`

**Logic:**
- Exact PSDK integer rounding and modifier layer.
- Track required previous-turn and current-turn history.
- Respect itemlessness, speed, weight, HP ratio, status, terrain, weather, and target-moved-before-user branches.

**Acceptance:**
- Variable-power group has zero partials except species/form data dependencies explicitly approved.

### Lot 78 - Direct HP, Sacrifice, Faint, and Fixed Damage Moves

**Purpose:** Finish methods that bypass normal damage or trigger self-faint.

**Move Methods:**
- `s_final_gambit`, `s_explosion`, `s_memento`, `s_mind_blown`, `s_misty_explosion`, `s_chloroblast`, `s_super_fang`, `s_endeavor`, `s_pain_split`, `s_ohko`, `s_fixed_damage`, `s_hp_eq_level`, `s_present`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/handler/battle_damage_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_battle_end_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/self_destruct_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/no_effect_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/direct_hp_move_behavior.dart`
- Modify: `packages/map_battle/test/psdk_move_families/no_effect_and_direct_hp_test.dart`
- Modify: `packages/map_battle/test/psdk_move_families/self_destruct_move_behavior_test.dart`

**Logic:**
- Faint processing happens through the shared faint pipeline.
- Damp-like prevention, Substitute interactions, Sturdy-like branches, immunities, and fail conditions match PSDK.
- Present consumes RNG from the correct stream.

**Acceptance:**
- Faint/direct-HP methods promote only after faint queue ordering tests pass.

### Lot 79 - Item-Dependent Move Completion

**Purpose:** Finish moves whose behavior depends on held item state.

**Move Methods:**
- `s_belch`, `s_bestow`, `s_fling`, `s_knock_off`, `s_natural_gift`, `s_pluck`, `s_recycle`, `s_techno_blast`, `s_thief`, `s_switcheroo`, `s_trick`, `s_corrosive_gas`, `s_stuff_cheeks`, `s_poltergeist`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/item_dependent_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_item_change_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/item/item_effect_registry.dart`
- Modify: `packages/map_battle/test/psdk_move_families/item_dependent_moves_test.dart`
- Modify: `packages/map_battle/test/psdk_item_effects_test.dart`

**Logic:**
- Model consumed berry memory, recyclable item, stolen item, burnt item, knocked-off item, Fling item table, Natural Gift type/power table.
- Respect item blockers, mail-like restrictions if present in data, mega/primal/gimmick item locks, Substitute branches, and Unburden-like downstream hooks.

**Acceptance:**
- Item-dependent moves become bridgeable in runtime when all effects are supported.

### Lot 80 - Type, Form, and Ability-Changing Moves

**Purpose:** Finish methods that mutate type, ability, or form-related battle state.

**Move Methods:**
- `s_add_type`, `s_change_type`, `s_conversion`, `s_conversion2`, `s_reflect_type`, `s_magic_powder`, `s_soak`, `s_burn_up`, `s_roost`, `s_simple_beam`, `s_skill_swap`, `s_entrainment`, `s_worry_seed`, `s_gastro_acid`, `s_doodle`, `s_core_enforcer`, `s_multi_attack`, `s_judgment`, `s_ivy_cudgel`, `s_revelation_dance`, `s_aura_wheel`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/battler/battle_transform_state.dart`
- Create: `packages/map_battle/lib/src/domain/battler/battle_type_mutation_state.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_ability_change_handler.dart`
- Create: `packages/map_battle/lib/src/domain/move/behaviors/type_ability_change_move_behavior.dart`
- Create: `packages/map_battle/test/psdk_move_families/type_ability_change_moves_test.dart`

**Logic:**
- Distinguish base type, added type, replaced type, temporary lost type, and form-derived type.
- Ability suppression/change/copy must be reversible where PSDK makes it reversible.
- Species/form-specific moves use explicit data adapters, not hard-coded UI assumptions.

**Acceptance:**
- Type/ability changing move methods and matching move effects promote together.

### Lot 81 - Volatile Status Control Moves

**Purpose:** Finish volatile move effects and their prevention/cure semantics.

**Move Methods:**
- `s_attract`, `s_confuse`, `s_disable`, `s_encore`, `s_embargo`, `s_heal_block`, `s_imprison`, `s_taunt`, `s_torment`, `s_nightmare`, `s_perish_song`, `s_grudge`, `s_destiny_bond`, `s_fairy_lock`, `s_no_retreat`, `s_octolock`, `s_powder`, `s_laser_focus`, `s_focus_energy`, `s_lock_on`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/move/*.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/battle_effect_hooks.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_status_change_handler.dart`
- Create: `packages/map_battle/test/psdk_move_families/volatile_status_control_moves_test.dart`

**Logic:**
- Every volatile effect has duration, owner, target, turn decrement phase, cure phase, and Baton Pass transfer flag.
- Move selection prevention routes through effect hooks.
- Mental Herb / Aroma Veil / Oblivious-like interactions are handled by item/ability hooks when their lots land.

**Acceptance:**
- Volatile effects no longer live as passive markers when PSDK has active behavior.

### Lot 82 - Field, Room, Sport, and Screen Move Completion

**Purpose:** Finish field and side-condition methods.

**Move Methods:**
- `s_magic_room`, `s_wonder_room`, `s_gravity`, `s_mud_sport`, `s_water_sport`, `s_lucky_chant`, `s_mist`, `s_safeguard`, `s_crafty_shield`, `s_mat_block`, `s_quick_guard`, `s_wide_guard`, `s_spikes`, `s_toxic_spikes`, `s_stealth_rock`, `s_sticky_web`, `s_defog`, `s_rapid_spin`, `s_court_change`, `s_freezy_frost`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/field/*.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/side/*.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_end_turn_handler.dart`
- Modify: `packages/map_battle/test/psdk_side_slot_condition_test.dart`
- Modify: `packages/map_battle/test/psdk_move_families/hazard_cleanup_moves_test.dart`
- Create: `packages/map_battle/test/psdk_move_families/field_room_sport_moves_test.dart`

**Logic:**
- Field effects apply globally; side effects apply per bank; slot effects follow slot occupant rules.
- Court Change swaps only PSDK-approved side conditions.
- Defog / Rapid Spin remove hazards and apply stat changes exactly.

**Acceptance:**
- Field/side/slot methods promote and runtime bridge allows those effect kinds.

### Lot 83 - Multi-Target and Doubles Utility Moves

**Purpose:** Finish moves whose PSDK correctness depends on doubles topology.

**Move Methods:**
- `s_follow_me`, `s_rage_powder`, `s_ally_switch`, `s_life_dew`, `s_floral_healing`, `s_flower_shield`, `s_magnetic_flux`, `s_gear_up`, `s_rototiller`, `s_coaching`, `s_decorate`, `s_aromatic_mist`, `s_pollen_puff`, `s_dragon_darts`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/battle/battle_topology.dart`
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_execution.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/side/doubles_guard_effects.dart`
- Modify: `packages/map_battle/test/psdk_target_resolver_doubles_test.dart`
- Modify: `packages/map_battle/test/psdk_multi_target_test.dart`
- Create: `packages/map_battle/test/psdk_move_families/doubles_utility_moves_test.dart`

**Logic:**
- Target resolution must distinguish ally, adjacent foe, all foes, all adjacent, user side, opposing side, slot, and field.
- Redirection, guard effects, and target retargeting must happen at PSDK timing.
- Pollen Puff and Dragon Darts branch on ally/foe/fainted availability.

**Acceptance:**
- Doubles utility methods are promoted and covered by at least five doubles golden fixtures.

### Lot 84 - Stat and Status Composite Move Completion

**Purpose:** Finish the largest partial group currently mixed under status/stat behavior.

**Move Methods:** All remaining partials implemented by `StatusStatMoveBehavior`, `AdvancedStatMoveBehavior`, `RecoveryStatMoveBehavior`, and `StaticBasicMoveRegistry.partialTargetMarker`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/status_stat_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/recovery_stat_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_stat_change_handler.dart`
- Modify: `packages/map_battle/test/psdk_move_families/generic_status_stat_test.dart`
- Modify: `packages/map_battle/test/psdk_move_families/advanced_stat_moves_test.dart`

**Logic:**
- Composite moves must execute in PSDK order: damage, status, stat, volatile, secondary, messages.
- Accuracy/evasion stages, custom stat sources, target-all stat edits, self-damage costs, and ability-prevention branches must be supported.
- Move-specific exceptions must be split into focused behavior classes when the generic behavior becomes misleading.

**Acceptance:**
- No method remains partial only because of generic stat/status handling.

### Lot 85 - Secondary Effect and Chance Branch Completion

**Purpose:** Finish secondary effects that currently execute partially or only as damage.

**Move Methods:**
- `s_a_fang`, `s_alluring_voice`, `s_burning_jealousy`, `s_false_swipe`, `s_incinerate`, `s_psychic_noise`, `s_relic_song`, `s_salt_cure`, `s_syrup_bomb`, `s_tar_shot`, `s_throat_chop`, `s_tri_attack`, plus Studio moves with `probabilistic_modify_stats`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/special_secondary_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_procedure.dart`
- Modify: `packages/map_battle/lib/src/domain/rng/battle_rng_streams.dart`
- Modify: `packages/map_battle/test/psdk_secondary_effects_test.dart`
- Modify: `packages/map_battle/test/psdk_move_families/special_secondary_moves_test.dart`

**Logic:**
- Secondary effect probability consumes the correct RNG stream.
- Sheer Force / Shield Dust / Serene Grace-like interactions are hookable.
- Tri Attack status choice is deterministic and PSDK-ordered.

**Acceptance:**
- Runtime bridge removes `unsupported_mechanic:probabilistic_modify_stats` for supported moves.

### Lot 86 - Move Prevention and Failure Conditions

**Purpose:** Close PSDK `move_prevention` branches that are not owned by a single effect.

**Move Methods:**
- `s_belch`, `s_last_resort`, `s_sucker_punch`, `s_snore`, `s_dream_eater`, `s_rest`, `s_splash`, `s_poltergeist`, `s_gigaton_hammer`, `s_fake_out`, `s_focus_punch`, `s_shell_trap`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_procedure.dart`
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_execution.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/action_gated_move_behavior.dart`
- Modify: `packages/map_battle/test/psdk_move_families/move_prevention_test.dart`
- Modify: `packages/map_battle/test/psdk_move_families/action_gated_moves_test.dart`

**Logic:**
- Preconditions run before PP when PSDK says so, after PP when PSDK says so.
- Failure events produce timeline messages and no side effects.
- Sleep, target HP/status, previous move, item, and turn counters are centralized.

**Acceptance:**
- No move remains partial because of simple precondition order.

### Lot 87 - Two-Turn, Out-of-Reach, and Charge Edge Cases

**Purpose:** Finish charge/release moves already marked ported only for the local slice.

**Move Methods:**
- `s_2turns`, `s_solar_beam`, `s_electro_shot`, `s_geomancy`, `s_sky_drop`, `s_dig`, `s_dive`, `s_fly`, `s_phantom_force`, `s_shadow_force`, `s_bounce`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/move/two_turn_charge_effect.dart`
- Create: `packages/map_battle/lib/src/domain/effect/move/out_of_reach_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/weather_power_move_behavior.dart`
- Create: `packages/map_battle/test/psdk_move_families/two_turn_out_of_reach_moves_test.dart`

**Logic:**
- Charge skips due to weather/item.
- Out-of-reach grants exact hit exceptions.
- Sky Drop target carry and failure branches match PSDK.
- Power Herb-like item integration is hookable.

**Acceptance:**
- Two-turn methods stay `ported` under stricter tests.

### Lot 88 - Transform, Imposter, and Battle State Copying

**Purpose:** Finish Transform-like battle state copying beyond the current local fix.

**PSDK Sources:**
- `10 Move/2 Definitions/300 Transform.rb`
- `06 Effects/02 Move Effects/001 Transform.rb`
- `06 Effects/04 Ability Effects/100 Imposter.rb`

**Files:**
- Modify: `packages/map_battle/lib/src/domain/battler/battle_transform_state.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/transform_move_behavior.dart`
- Create: `packages/map_battle/lib/src/domain/effect/ability/imposter_effect.dart`
- Modify: `packages/map_battle/test/battle_transform_test.dart`
- Modify: `packages/map_battle/test/psdk_move_families/transform_move_behavior_test.dart`

**Logic:**
- Copy species, form, stats, stat stages, moves with PP rules, type, ability display, and visual identity according to PSDK.
- Prevent transforming into transformed/invalid targets.
- Imposter triggers at switch-in timing.

**Acceptance:**
- Ditto/Transform and Imposter are strict and runtime bridge keeps Transform bridgeable.

### Lot 89 - Move Manifest Final Sweep

**Purpose:** Eliminate all remaining `partial` move methods after focused family lots.

**Files:**
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Modify: `packages/map_battle/lib/src/data/psdk_attack_coverage_report.dart`
- Modify: `packages/map_battle/test/psdk_registry_manifest_test.dart`
- Modify: `packages/map_battle/test/psdk_attack_coverage_report_test.dart`
- Modify: focused test files for any remaining method listed by Lot 66 inventory.

**Logic:**
- Run the materialized gap list.
- For every remaining partial method:
  - either create a tiny focused lot patch,
  - or document an approved out-of-scope with user approval.
- No silent broad promotion.

**Acceptance:**
- `methods complete: 330 / 330`.
- `attacks complete: 728 / 728` unless a documented effect dependency still blocks attack strictness; if blocked, proceed to Phase D and rerun.

---

## Phase D - Effect Matrix Convergence

### Lot 90 - Effect Manifest Ported Status Model

**Purpose:** The effect matrix currently reports `0 / 482 ported` partly because effect manifests do not express full ported status.

**Files:**
- Modify: `packages/map_battle/tool/extract_psdk_effect_matrix.dart`
- Modify: `packages/map_battle/lib/src/data/psdk_fight_parity_audit.dart`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_ability_effect_manifest.dart`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_item_effect_manifest.dart`
- Modify: `packages/map_battle/test/psdk_effect_matrix_test.dart`

**Logic:**
- Add `ported` to ability and item effect status enums.
- Support move/status/field/mechanics effect statuses through a generated or explicit manifest.
- Require test evidence for `ported`.

**Acceptance:**
- Already complete status effects can be promoted only if tests satisfy PSDK lifecycle requirements.

### Lot 91 - Status Effect Exact Lifecycle

**Purpose:** Promote PSDK status effects from modeled to strictly ported.

**PSDK Sources:**
- `06 Effects/03 Status Effects/101 Poison.rb`
- `06 Effects/03 Status Effects/102 Paralysis.rb`
- `06 Effects/03 Status Effects/103 Burn.rb`
- `06 Effects/03 Status Effects/104 Asleep.rb`
- `06 Effects/03 Status Effects/105 Frozen.rb`
- `06 Effects/03 Status Effects/108 Toxic.rb`

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/status/*.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/status/status_effect_registry.dart`
- Modify: `packages/map_battle/test/psdk_status_effects_test.dart`
- Modify: `packages/map_battle/test/psdk_status_lifecycle_test.dart`

**Logic:**
- Exact residual phase, cure phase, skip-action phase, stat modifier phase, and message phase.
- Toxic counter, sleep counter, freeze thaw, paralysis action prevention, burn attack reduction, poison damage.

**Acceptance:**
- Status family effects report `ported`.

### Lot 92 - Move Volatile Effects Batch 1: Selection Locks

**Purpose:** Port selection-preventing move effects.

**Effects:**
- `Disable`, `Encore`, `Taunt`, `Torment`, `HealBlock`, `Imprison`, `ThroatChop`, `Embargo`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/move/disable_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/encore_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/taunt_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/torment_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/heal_block_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/imprison_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/throat_chop_effect.dart`
- Create: `packages/map_battle/test/psdk_effects/move_selection_lock_effects_test.dart`

**Logic:**
- Implement duration, move filtering, switch cleanup, Mental Herb-style cure hook, and message order.

**Acceptance:**
- Listed move effects report `ported`.

### Lot 93 - Move Volatile Effects Batch 2: Residual and End-Turn

**Purpose:** Port end-turn move effects.

**Effects:**
- `AquaRing`, `Bind`, `Curse`, `Ingrain`, `LeechSeed`, `Nightmare`, `PerishSong`, `SaltCure`, `SyrupBomb`, `Wish`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/move/aqua_ring_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/bind_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/curse_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/ingrain_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/leech_seed_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/salt_cure_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/syrup_bomb_effect.dart`
- Create: `packages/map_battle/test/psdk_effects/move_residual_effects_test.dart`

**Logic:**
- End-turn ordering must match PSDK effect handler order.
- Big Root, Binding Band, Grip Claw, type exceptions, and target/user ownership must be hookable.

**Acceptance:**
- Residual move effects report `ported`.

### Lot 94 - Move Volatile Effects Batch 3: Protection, Redirection, and Guard

**Purpose:** Port protection and redirection effects.

**Effects:**
- `Protect`, `CraftyShield`, `MatBlock`, `QuickGuard`, `WideGuard`, `CenterOfAttention`, `MagicCoat`, `Snatch`, `Powder`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/move/protect_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/side/doubles_guard_effects.dart`
- Create: `packages/map_battle/lib/src/domain/effect/move/magic_coat_effect.dart`
- Create: `packages/map_battle/lib/src/domain/effect/move/snatch_effect.dart`
- Create: `packages/map_battle/test/psdk_effects/protection_redirection_effects_test.dart`

**Logic:**
- Stalling counter, target redirection priority, reflected move behavior, snatchable move filter, guard scopes.

**Acceptance:**
- Protection/redirection effects report `ported` and move methods depending on them remain strict.

### Lot 95 - Move Field and Side Effects Batch

**Purpose:** Port field, side, and room effects.

**Effects:**
- `Gravity`, `LightScreen`, `Reflect`, `AuroraVeil`, `LuckyChant`, `MagicRoom`, `Mist`, `MudSport`, `Safeguard`, `Tailwind`, `TrickRoom`, `WaterSport`, `WonderRoom`, hazards.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/field/*.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/side/*.dart`
- Create: `packages/map_battle/test/psdk_effects/field_side_effects_test.dart`

**Logic:**
- Duration, ownership, switch persistence, side swapping, item duration extension, and cleanup.

**Acceptance:**
- Field and side effects report `ported`.

### Lot 96 - Move State Marker Effects Batch

**Purpose:** Port marker effects not covered by previous batches.

**Effects:**
- `Attract`, `Autotomize`, `BeakBlast`, `Bestow`, `BurnUp`, `ChangeType`, `Charge`, `DestinyBond`, `DragonCheer`, `Drowsiness`, `Electrify`, `FairyLock`, `Flinch`, `FocusEnergy`, `Foresight`, `GlaiveRush`, `Grudge`, `HelpingHand`, `LaserFocus`, `LockOn`, `MagnetRise`, `Minimize`, `MiracleEye`, `NoRetreat`, `Octolock`, `Rage`, `Roost`, `SmackDown`, `Stockpile`, `TarShot`, `Telekinesis`, `Transform`, `UpRoar`.

**Files:**
- Modify or create focused files under `packages/map_battle/lib/src/domain/effect/move/`
- Create: `packages/map_battle/test/psdk_effects/move_marker_effects_test.dart`

**Logic:**
- Each marker must define:
  - owner/target,
  - duration,
  - Baton Pass transfer,
  - switch cleanup,
  - hook interfaces it implements,
  - exact PSDK message timing where observable.

**Acceptance:**
- Marker effects report `ported` and no marker is passive unless PSDK is passive.

### Lot 97 - Ability Effect Status and Registry Foundation

**Purpose:** Prepare 276 ability entries for real `ported` status.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/ability/ability_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/ability/ability_effect_registry.dart`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_ability_effect_manifest.dart`
- Modify: `packages/map_battle/test/psdk_ability_registry_manifest_test.dart`
- Modify: `packages/map_battle/test/psdk_ability_effects_test.dart`

**Logic:**
- Normalize ability hook interfaces:
  - switch-in,
  - pre-damage,
  - post-damage,
  - stat prevention,
  - status prevention,
  - move selection,
  - accuracy,
  - speed/stat modifiers,
  - faint triggers,
  - weather/terrain setters.

**Acceptance:**
- Manifest can represent `ported` abilities with evidence.

### Lot 98 - Ability Effects Batch 1: Damage, Type, and Accuracy

**Purpose:** Port high-impact damage/type/accuracy abilities.

**Families:**
- Type boosters, type changers, immunities, damage reducers, weather/terrain power modifiers, accuracy/evasion modifiers, contact punishers.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/ability/type_boosting_ability_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/ability/type_immunity_ability_effect.dart`
- Create focused ability effect files as needed under `packages/map_battle/lib/src/domain/effect/ability/`
- Create: `packages/map_battle/test/psdk_effects/ability_damage_type_accuracy_effects_test.dart`

**Logic:**
- Include Mold Breaker-style bypass, ability suppression, Neutralizing Gas, and source/target ownership.

**Acceptance:**
- All abilities in this batch report `ported`.

### Lot 99 - Ability Effects Batch 2: Status, Stat, and Selection

**Purpose:** Port ability effects that prevent or mutate statuses/stats/actions.

**Families:**
- Status immunities, stat drop prevention, Contrary/Simple-like stat mutation, Prankster/Priority blockers, Aroma Veil/Mental immunity, sound/powder/bullet protections.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/ability/status_immunity_effect.dart`
- Create focused ability effect files under `packages/map_battle/lib/src/domain/effect/ability/`
- Create: `packages/map_battle/test/psdk_effects/ability_status_stat_selection_effects_test.dart`

**Logic:**
- Hook into status/stat handlers and move selection prevention.
- Respect target side, ally protection, bypass rules, and ability suppression.

**Acceptance:**
- All abilities in this batch report `ported`.

### Lot 100 - Ability Effects Batch 3: Switch, Faint, Residual, and Form

**Purpose:** Port abilities triggered by switch, faint, end-turn, or form changes.

**Families:**
- Intimidate-like, Download-like, Drizzle/Drought-like, terrain setters, Natural Cure, Regenerator, Moxie/Beast Boost-like, Emergency Exit, Disguise/Ice Face, Forecast, Hunger Switch, Power Construct, Imposter.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/ability/switch_trigger_ability_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/ability/residual_ability_effect.dart`
- Create focused ability effect files under `packages/map_battle/lib/src/domain/effect/ability/`
- Create: `packages/map_battle/test/psdk_effects/ability_switch_faint_form_effects_test.dart`

**Logic:**
- Use shared switch/faint/end-turn handlers.
- Form changes mutate battle state through one state object.

**Acceptance:**
- Remaining ability effects report `ported` or are explicitly user-approved out of battle scope.

### Lot 101 - Item Effect Status and Registry Foundation

**Purpose:** Prepare item entries for real `ported` status and exact item hooks.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/item/item_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/item/item_effect_registry.dart`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_item_effect_manifest.dart`
- Modify: `packages/map_battle/test/psdk_item_registry_manifest_test.dart`

**Logic:**
- Item effects need hooks equivalent to abilities, plus consume/remove/swap lifecycle.
- Distinguish held item, consumed item, removed item, knocked-off item, recyclable item.

**Acceptance:**
- Item manifest can mark individual items `ported`.

### Lot 102 - Item Effects Batch 1: Damage, Type, Stat, and Accuracy Modifiers

**Purpose:** Port passive item modifiers.

**Families:**
- Plates/incenses/type boosters, Gems, Choice items, Eviolite, Assault Vest, species stat items, Life Orb, Expert Belt, Muscle Band, Wise Glasses, accuracy/evasion items.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/item/held_item_modifier_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/item/move_modifier_item_effect.dart`
- Create focused item effect files as needed.
- Modify: `packages/map_battle/test/psdk_item_damage_modifiers_test.dart`

**Logic:**
- Correct modifier layer, consumption timing, item removal effects, and category/type/species conditions.

**Acceptance:**
- Batch items report `ported`.

### Lot 103 - Item Effects Batch 2: Berries, Focus, Eject, Orb, Weather, Terrain

**Purpose:** Port active item triggers.

**Families:**
- Status berries, HP berries with nature confusion, pinch stat berries, type-resist berries, Focus Sash/Band, Eject Button/Pack, Red Card, Flame/Toxic Orb, weather rocks, Terrain Extender, Air Balloon.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/item/berry_item_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/item/weather_rock_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/item/terrain_extender_effect.dart`
- Create focused item effect files as needed.
- Modify: `packages/map_battle/test/psdk_item_berries_test.dart`
- Create: `packages/map_battle/test/psdk_effects/item_active_trigger_effects_test.dart`

**Logic:**
- Trigger timing must match PSDK: after damage, before faint, end-turn, switch-in, status receive.
- Berries consume and interact with Unnerve/Magic Room-like effects.

**Acceptance:**
- Batch items report `ported`.

### Lot 104 - Mechanics and Generic Effect Classes

**Purpose:** Port PSDK generic mechanics effects currently missing from the matrix.

**PSDK Sources:**
- `06 Effects/01 Mechanics/100 ForceFlying.rb`
- `06 Effects/01 Mechanics/100 ForceNextMove.rb`
- `06 Effects/01 Mechanics/100 Mark.rb`
- `06 Effects/01 Mechanics/100 NeutralizeType.rb`
- `06 Effects/01 Mechanics/100 OutOfReach.rb`
- `06 Effects/01 Mechanics/100 SuccessiveSuccessfulUses.rb`
- `06 Effects/01 Mechanics/100 WithTargets.rb`
- `06 Effects/01 Mechanics/200 WithMarkedTargets.rb`

**Files:**
- Create focused files under `packages/map_battle/lib/src/domain/effect/mechanics/`
- Modify: `packages/map_battle/lib/src/domain/effect/battle_effect_registry.dart`
- Create: `packages/map_battle/test/psdk_effects/mechanics_effects_test.dart`

**Logic:**
- These are shared primitives; move effects should reuse them instead of duplicating behavior.

**Acceptance:**
- Mechanics family reports `ported`.

### Lot 105 - Effect Matrix Final Sweep

**Purpose:** Close the remaining effect gap after batch lots.

**Files:**
- Modify: `packages/map_battle/lib/src/data/generated/*manifest*.dart`
- Modify: `packages/map_battle/test/psdk_effect_matrix_test.dart`
- Modify/create focused effect tests for any remaining gap.

**Logic:**
- Run Lot 66 inventory and close every remaining `missing` or `partial` effect.
- Keep approved out-of-scope at zero unless user explicitly approves exclusions.

**Acceptance:**
- `effects complete: 482 / 482`.

---

## Phase E - Runtime, Goldens, and Final Gate

### Lot 106 - Damage Formula and Modifier Stack Audit

**Purpose:** Verify that the now-ported abilities/items/effects compose through the exact PSDK damage formula.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_type_processor.dart`
- Modify: `packages/map_battle/test/psdk_type_damage_test.dart`
- Create: `packages/map_battle/test/psdk_damage_formula_parity_test.dart`

**Logic:**
- Confirm integer rounding at every stage.
- Confirm modifier ordering for weather, terrain, screens, burn, critical, abilities, items, type, random, STAB.

**Acceptance:**
- Golden fixtures cover representative modifier stacking.

### Lot 107 - Full Faint, Switch, and End-Turn Ordering

**Purpose:** Ensure global battle order matches PSDK once all effects exist.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/handler/battle_end_turn_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_switch_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_battle_end_handler.dart`
- Modify: `packages/map_battle/lib/src/application/battle_turn_runner.dart`
- Create: `packages/map_battle/test/psdk_global_ordering_test.dart`

**Logic:**
- Faint replacement, switch-in triggers, residual effects, weather/terrain expiry, queued delayed effects, and battle end checks run in PSDK order.

**Acceptance:**
- No final-gate failures are due to ordering gaps.

### Lot 108 - Golden Fixture Suite Per Family

**Purpose:** Add enough PSDK goldens to prevent false confidence.

**Files:**
- Add fixtures under `packages/map_battle/test/fixtures/psdk_golden/`
- Modify: `packages/map_battle/test/psdk_golden_fixture_test.dart`
- Modify: `packages/map_battle/lib/src/data/psdk_parity_gate.dart`

**Logic:**
- Minimum fixture groups:
  - 10 direct damage/modifier fixtures,
  - 10 status/stat fixtures,
  - 10 volatile effect fixtures,
  - 10 ability fixtures,
  - 10 item fixtures,
  - 10 doubles/targeting fixtures,
  - 10 switch/faint/end-turn fixtures,
  - 10 copy/call/edge fixtures.
- Raise `minimumGoldenFixtures` from `1` to the agreed suite size.

**Acceptance:**
- Final gate requires the meaningful fixture count.

### Lot 109 - Runtime Bridge Full Unlock

**Purpose:** Remove runtime filtering for moves that are now supported by map_battle.

**Files:**
- Modify: `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- Modify: `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- Modify: `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- Modify: `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- Modify: `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`

**Logic:**
- Bridge should trust PSDK audit status and only reject truly unsupported data defects.
- Each previously rejected effect kind is opened only when the battle package has tests.

**Acceptance:**
- Explicit four-move teams keep all four moves when the battle engine supports them.
- Bridge report status becomes `complete` or `explained` with zero unsupported supported moves.

### Lot 110 - Playable Runtime Regression Pack

**Purpose:** Ensure the game example can exercise the completed engine.

**Files:**
- Modify: `examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart`
- Modify: `examples/playable_runtime_host/lib/src/runtime_party_builder.dart`
- Modify: `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`
- Modify: `examples/playable_runtime_host/test/runtime_party_builder_test.dart`

**Logic:**
- Add curated test teams:
  - Ditto/Transform/Imposter.
  - Mew copy/call moves.
  - switch/pivot/Baton Pass team.
  - hazards/screens/weather/terrain team.
  - item/ability interaction team.
  - doubles-targeting team if runtime topology exposes it.

**Acceptance:**
- Manual QA can select complex Pokemon/moves without bridge filtering surprises.

### Lot 111 - Final Audit Gate Green

**Purpose:** Make the final gate pass without weakening acceptance.

**Files:**
- Modify: `reports/analysis/psdk_fight_100_percent_acceptance.md`
- Modify: `reports/analysis/psdk_fight_convergence_dashboard.md`
- Modify: `packages/map_battle/test/psdk_final_parity_gate_test.dart` only if raising fixture thresholds.

**Logic:**
- Run final gate.
- If it fails, use Lot 66 inventory to create a micro-lot for each remaining named gap.
- Do not mark this lot complete until final gate passes.

**Acceptance:**
- Command passes:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
dart run tool/psdk_fight_parity_audit.dart \
  --final-gate \
  --goldens test/fixtures/psdk_golden
```

- Expected final audit:
  - attacks complete: `728 / 728`,
  - methods complete: `330 / 330`,
  - effects complete: `482 / 482`,
  - runtime bridge measured and accepted,
  - golden fixture threshold met.

---

## Recommended Execution Strategy

Run these in order:

1. Lots 66-70 first. They improve measurement and prevent false progress.
2. Lots 71-75 next. They close known in-progress work.
3. Lots 76-89 by independent move-family subagents. These can partly run in parallel once Lot 66 exists.
4. Lots 90-105 by effect-family subagents. Ability, item, move-effect, and status batches can run in parallel after Lot 90.
5. Lots 106-111 last. These verify composition, runtime bridge, playable QA, and final gate.

Parallel-safe groups:

- Lots 77, 79, 81, 82, 85 can run in parallel if they do not edit the same behavior files at the same time.
- Lots 98, 99, 100 can run in parallel after Lot 97.
- Lots 102 and 103 can run in parallel after Lot 101.
- Lots 106 and 107 should not run until most effects are complete because they validate composition.

Commit convention:

```bash
git commit -m "Lot 66: materialize PSDK fight gap lists"
git commit -m "Lot 67: add PSDK manifest integrity gate"
```

Every lot must update the dashboard or audit output so the next agent sees the latest truth.
