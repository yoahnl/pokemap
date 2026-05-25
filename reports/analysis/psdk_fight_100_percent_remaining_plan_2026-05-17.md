# PSDK Fight 100 Percent Remaining Convergence Plan

Generated: 2026-05-17

## Goal

Reach strict Pokemon SDK fight parity on every final-gate axis:

| Axis | Current | Target | Remaining |
| --- | ---: | ---: | ---: |
| Attacks strict | 343 / 728 | 728 / 728 | 385 |
| Methods ported | 149 / 330 | 330 / 330 | 181 |
| Effects ported | 159 / 482 | 482 / 482 | 323 |
| Runtime bridge | explained | complete | complete once supported moves are no longer filtered |
| Golden fixtures | 2 | broad representative suite | many family fixtures |

Global strict parity is currently `651 / 1540`, so `42.3%`.

## Important Correction

The existing Phase C lots can be considered executed as planned work, but the
attack axis is not complete yet. The remaining attack gaps are mostly residual
convergence work caused by still-missing methods, effects, interactions, and
audit promotions.

This plan does not introduce a new Phase F. It keeps the existing convergence
frame:

- Phase C residuals: methods and attack strict promotions still missing.
- Phase D residuals: effect matrix completion.
- Phase E finalization: goldens, runtime completion, final audit gate.

## Execution Strategy

Do not try to close attacks first. The highest-impact path is:

1. Finish effect families first, especially abilities.
2. Re-run audit and promote methods whose dependencies are now complete.
3. Re-run audit and promote attacks whose method/effect dependencies are now strict.
4. Expand goldens enough to make the final gate meaningful.
5. Unlock runtime only for fully supported battle behavior.
6. Run final gate without weakening thresholds.

Every lot must:

- add or update focused tests before promotion,
- cite the Pokemon SDK Ruby source path in tests or manifest evidence,
- regenerate `reports/analysis/psdk_fight_parity_audit_latest.json`,
- regenerate `reports/analysis/psdk_fight_convergence_dashboard.md`,
- commit with the lot number.

## Remaining Lots

### Lot 112 - Ability Inventory Split

**Purpose:** Split the `216` remaining ability effects into executable batches.

**Files:**
- Modify: `packages/map_battle/tool/extract_psdk_effect_matrix.dart`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_ability_effect_manifest.dart`
- Modify: `packages/map_battle/test/psdk_effect_matrix_test.dart`
- Modify: `reports/analysis/psdk_fight_convergence_dashboard.md`

**Logic:**
- Group missing abilities by hook:
  - damage modifiers,
  - damage prevention,
  - status immunity/cure,
  - stat stage hooks,
  - weather/terrain hooks,
  - switch-in hooks,
  - switch-out hooks,
  - faint hooks,
  - move selection hooks,
  - form/type changes.
- Add counts per group to the dashboard.

**Acceptance:**
- Dashboard names the next ability batch precisely instead of only saying
  `ability (216 remaining effects)`.

### Lot 113 - Abilities Batch A: Damage Modifiers

**Purpose:** Port ability effects that modify outgoing/incoming damage.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/ability/`
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_ability_effect_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_effect_families/ability_damage_effects_test.dart`

**Logic:**
- Implement PSDK hooks equivalent to damage increase/reduction.
- Keep modifiers in the PSDK damage stack, not as power approximations.
- Cover success and bypass paths.

**Acceptance:**
- Relevant ability effects move from `missing` or `partial` to `ported`.
- Audit effect count increases.

### Lot 114 - Abilities Batch B: Immunity and Prevention

**Purpose:** Port ability effects that block moves, types, statuses, or damage.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/ability/`
- Modify: `packages/map_battle/lib/src/domain/handler/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_ability_effect_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_effect_families/ability_immunity_effects_test.dart`

**Logic:**
- Implement type immunity, status immunity, move prevention, and damage
  prevention hooks.
- Preserve PSDK event ordering and battle messages.

**Acceptance:**
- Immunity/prevention ability effects are ported with positive and negative tests.

### Lot 115 - Abilities Batch C: Status and Stat Hooks

**Purpose:** Port abilities that cure, reflect, prevent, or modify status/stat changes.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/ability/`
- Modify: `packages/map_battle/lib/src/domain/status/`
- Modify: `packages/map_battle/lib/src/domain/stat/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_ability_effect_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_effect_families/ability_status_stat_effects_test.dart`

**Logic:**
- Implement status cure/prevention.
- Implement stat drop prevention, stat boost on trigger, and stat reflection.

**Acceptance:**
- Ability status/stat effects are ported and deterministic.

### Lot 116 - Abilities Batch D: Switch, Faint, and Residual Hooks

**Purpose:** Port abilities that trigger on switch-in, switch-out, faint, and end-turn.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/ability/`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_switch_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_end_turn_handler.dart`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_ability_effect_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_effect_families/ability_switch_faint_effects_test.dart`

**Logic:**
- Implement switch-in weather/terrain/stat effects.
- Implement faint-triggered effects.
- Implement residual ability effects at the correct end-turn position.

**Acceptance:**
- No final-gate failure remains for switch/faint/residual ability hooks.

### Lot 117 - Abilities Batch E: Form, Type, Move Selection, and Edge Hooks

**Purpose:** Close remaining ability hooks that do not fit Lots 113-116.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/ability/`
- Modify: `packages/map_battle/lib/src/domain/battler/`
- Modify: `packages/map_battle/lib/src/domain/action/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_ability_effect_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_effect_families/ability_edge_effects_test.dart`

**Logic:**
- Implement form/type-changing ability behavior.
- Implement move selection restrictions and priority/order edge hooks.
- Add explicit out-of-scope evidence only if Pokemon SDK source proves the
  effect is unreachable in the current battle topology.

**Acceptance:**
- Ability family reaches `254 / 254` ported or explicitly approved by final gate.

### Lot 118 - Item Inventory Split

**Purpose:** Split the `60` remaining item effects into concrete batches.

**Files:**
- Modify: `packages/map_battle/lib/src/data/generated/psdk_item_effect_manifest.dart`
- Modify: `packages/map_battle/test/psdk_effect_matrix_test.dart`
- Modify: `reports/analysis/psdk_fight_convergence_dashboard.md`

**Logic:**
- Group missing item effects by:
  - damage/type/stat modifiers,
  - berries,
  - focus/eject/choice/orb,
  - weather/terrain/field,
  - held-item lifecycle and consumption.

**Acceptance:**
- Dashboard shows item subgroups instead of only `item (60 remaining effects)`.

### Lot 119 - Items Batch A: Damage, Type, Accuracy, and Stat Modifiers

**Purpose:** Port item effects that participate in damage and stat calculations.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/item/`
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_item_effect_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_effect_families/item_modifier_effects_test.dart`

**Acceptance:**
- Modifier item effects are ported with damage-stack tests.

### Lot 120 - Items Batch B: Berries and Consumption

**Purpose:** Port berry consumption, HP thresholds, status berries, and stat berries.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/item/`
- Modify: `packages/map_battle/lib/src/domain/item/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_item_effect_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_effect_families/item_berry_effects_test.dart`

**Acceptance:**
- Berry effects consume held items once and only at the PSDK trigger point.

### Lot 121 - Items Batch C: Focus, Eject, Choice, Orb, Weather, Terrain

**Purpose:** Port complex held-item lifecycle effects.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/item/`
- Modify: `packages/map_battle/lib/src/domain/action/`
- Modify: `packages/map_battle/lib/src/domain/handler/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_item_effect_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_effect_families/item_lifecycle_effects_test.dart`

**Acceptance:**
- Item family reaches `87 / 87` ported or explicitly approved by final gate.

### Lot 122 - Move Effects Batch A: Remaining Volatiles

**Purpose:** Close the remaining move-effect volatile classes.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/move/`
- Modify: `packages/map_battle/lib/src/domain/volatile/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_effect_families/move_volatile_effects_test.dart`

**Acceptance:**
- Selection-lock, residual, guard, protection, and marker volatiles are strict.

### Lot 123 - Move Effects Batch B: Remaining Side, Slot, and Field Effects

**Purpose:** Close remaining move-side/slot/field effect classes.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/move/`
- Modify: `packages/map_battle/lib/src/domain/field/`
- Modify: `packages/map_battle/lib/src/domain/side/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_effect_families/move_side_field_effects_test.dart`

**Acceptance:**
- Move effect family drops below 20 remaining.

### Lot 124 - Move Effects Batch C: Remaining Edge Effects

**Purpose:** Close all remaining move effect classes after Lots 122-123.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/move/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_effect_families/move_edge_effects_test.dart`

**Acceptance:**
- Move effect family reaches `115 / 115` ported or explicitly approved.

### Lot 125 - Status Final Effect

**Purpose:** Close the last remaining status effect.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/status/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_status_effect_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_effect_families/status_effects_test.dart`

**Acceptance:**
- Status effect family reaches `7 / 7`.

### Lot 126 - Effect Matrix Final Sweep

**Purpose:** Make the effect axis pass before method/attack promotion.

**Files:**
- Modify: all generated effect manifests as needed.
- Modify: `packages/map_battle/test/psdk_effect_matrix_test.dart`
- Modify: `reports/analysis/psdk_fight_convergence_dashboard.md`

**Logic:**
- Run effect matrix audit.
- For every remaining non-ported effect, either port it or create an explicit,
  source-backed approved-out-of-scope entry.

**Acceptance:**
- Effects axis reaches `482 / 482` complete for final gate purposes.

### Lot 127 - Method Residual Inventory

**Purpose:** Recompute the `181` remaining methods after effects are complete.

**Files:**
- Modify: `packages/map_battle/tool/psdk_fight_parity_audit.dart`
- Modify: `reports/analysis/psdk_fight_gap_inventory.md`
- Modify: `reports/analysis/psdk_fight_convergence_dashboard.md`

**Logic:**
- Group remaining methods by missing dependency:
  - action queue,
  - target resolution,
  - damage formula,
  - effect hook,
  - doubles topology,
  - audit manifest evidence only.

**Acceptance:**
- Dashboard names exact method batches instead of one aggregate count.

### Lot 128 - Methods Batch A: Action Queue and Copy/Call Residuals

**Purpose:** Port remaining methods that create, repeat, copy, or reorder actions.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/action/`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_move_families/action_queue_methods_test.dart`

**Acceptance:**
- No remaining method is blocked by copy/call/action queue semantics.

### Lot 129 - Methods Batch B: Damage Formula and Variable Power Residuals

**Purpose:** Port methods still blocked by exact damage or power semantics.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_move_families/variable_power_methods_test.dart`

**Acceptance:**
- Variable power and formula-dependent methods are ported.

### Lot 130 - Methods Batch C: Targeting and Doubles Residuals

**Purpose:** Port remaining methods blocked by target shape, bank, side, or doubles logic.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/target/`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_move_families/targeting_doubles_methods_test.dart`

**Acceptance:**
- No remaining method is blocked only by target topology.

### Lot 131 - Methods Batch D: Prevention, Failure, and Immunity Residuals

**Purpose:** Port remaining methods blocked by failure/prevention paths.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/handler/`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_move_families/failure_prevention_methods_test.dart`

**Acceptance:**
- Failure branch parity is explicit for all remaining methods.

### Lot 132 - Methods Batch E: Two-Turn, Out-of-Reach, and Delayed Residuals

**Purpose:** Port remaining methods requiring multi-turn state.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/move/`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_end_turn_handler.dart`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_move_families/multiturn_methods_test.dart`

**Acceptance:**
- No remaining method is blocked by delayed or two-turn semantics.

### Lot 133 - Methods Batch F: Method Manifest Final Sweep

**Purpose:** Close the method axis.

**Files:**
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Modify: `packages/map_battle/test/psdk_registry_manifest_test.dart`
- Modify: `reports/analysis/psdk_fight_convergence_dashboard.md`

**Acceptance:**
- Methods axis reaches `330 / 330` complete for final gate purposes.

### Lot 134 - Attack Strict Inventory Rebuild

**Purpose:** Recompute the `385` remaining attacks after effects and methods are complete.

**Files:**
- Modify: `packages/map_battle/tool/psdk_fight_parity_audit.dart`
- Modify: `reports/analysis/psdk_fight_gap_inventory.md`
- Modify: `reports/analysis/psdk_fight_convergence_dashboard.md`

**Logic:**
- Group remaining attacks by exact reason:
  - method still partial,
  - effect still partial,
  - data mismatch,
  - runtime target mismatch,
  - manifest evidence missing,
  - fixture missing.

**Acceptance:**
- Every remaining attack has one actionable reason.

### Lot 135 - Attacks Batch A: Data and Manifest Promotions

**Purpose:** Promote attacks that are already behaviorally supported but lack evidence.

**Files:**
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Modify: `packages/map_battle/test/psdk_registry_manifest_test.dart`
- Add fixtures as needed under `packages/map_battle/test/fixtures/psdk_golden/`

**Acceptance:**
- Attack strict count increases without changing battle behavior.

### Lot 136 - Attacks Batch B: Remaining Damage Attacks

**Purpose:** Close all remaining direct-damage attack strict gaps.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_attack_strict/damage_attacks_test.dart`

**Acceptance:**
- Damage attack strict gaps are closed.

### Lot 137 - Attacks Batch C: Remaining Status and Stat Attacks

**Purpose:** Close all remaining status/stat attack strict gaps.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/status/`
- Modify: `packages/map_battle/lib/src/domain/stat/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_attack_strict/status_stat_attacks_test.dart`

**Acceptance:**
- Status/stat attack strict gaps are closed.

### Lot 138 - Attacks Batch D: Remaining Field, Side, Switch, and Item Attacks

**Purpose:** Close attacks whose observable behavior is field, side, switch, or item mutation.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/field/`
- Modify: `packages/map_battle/lib/src/domain/side/`
- Modify: `packages/map_battle/lib/src/domain/item/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_attack_strict/field_side_item_attacks_test.dart`

**Acceptance:**
- Field/side/switch/item attack strict gaps are closed.

### Lot 139 - Attacks Batch E: Remaining Copy, Transform, Form, and Edge Attacks

**Purpose:** Close attacks with unusual state transitions.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/battler/`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Create/modify: `packages/map_battle/test/psdk_attack_strict/edge_attacks_test.dart`

**Acceptance:**
- Edge attack strict gaps are closed.

### Lot 140 - Attack Strict Final Sweep

**Purpose:** Close the attack axis.

**Files:**
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Modify: `packages/map_battle/test/psdk_registry_manifest_test.dart`
- Modify: `reports/analysis/psdk_fight_convergence_dashboard.md`

**Acceptance:**
- Attacks axis reaches `728 / 728` complete for final gate purposes.

### Lot 141 - Golden Fixture Suite Expansion

**Purpose:** Make final parity resistant to regressions.

**Files:**
- Create fixtures under `packages/map_battle/test/fixtures/psdk_golden/`
- Modify: `packages/map_battle/test/fixtures/psdk_golden/_index.md`
- Modify: `packages/map_battle/lib/src/data/psdk_parity_gate.dart`
- Modify: `packages/map_battle/test/psdk_golden_fixture_test.dart`

**Logic:**
- Add at least:
  - 10 damage/modifier fixtures,
  - 10 status/stat fixtures,
  - 10 volatile fixtures,
  - 10 ability fixtures,
  - 10 item fixtures,
  - 10 field/side fixtures,
  - 10 switch/faint/end-turn fixtures,
  - 10 copy/call/edge fixtures.

**Acceptance:**
- `minimumGoldenFixtures` reflects the real suite size.
- Fixture replay test runs every fixture.

### Lot 142 - Runtime Bridge Complete Mode

**Purpose:** Move runtime bridge from `explained` to `complete`.

**Files:**
- Modify: `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- Modify: `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- Modify: `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- Modify: `reports/analysis/psdk_runtime_bridge_diagnostics_latest.json`

**Logic:**
- A move may be filtered only for data defects or intentionally unsupported
  topology.
- Any PSDK-ported move supported by battle must pass through.

**Acceptance:**
- Runtime bridge diagnostics report `complete` or zero rejected supported moves.

### Lot 143 - Playable Runtime Full Regression Pack

**Purpose:** Make the example app exercise the completed engine.

**Files:**
- Modify: `examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart`
- Modify: `examples/playable_runtime_host/lib/src/runtime_party_builder.dart`
- Modify: `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`
- Modify: `examples/playable_runtime_host/test/runtime_party_builder_test.dart`

**Logic:**
- Add curated selectable QA teams:
  - Ditto/Transform/Imposter,
  - Mew copy/call,
  - weather/terrain,
  - hazards/screens,
  - item/ability interactions,
  - switch/pivot/Baton Pass,
  - status and stat stacking.

**Acceptance:**
- Manual QA can select complex teams without unexpected filtering.

### Lot 144 - Final Audit Gate Dry Run

**Purpose:** Run final gate before the final commit and generate exact residuals.

**Files:**
- Modify: `reports/analysis/psdk_fight_gap_inventory.md`
- Modify: `reports/analysis/psdk_fight_convergence_dashboard.md`

**Acceptance:**
- Either final gate passes, or the dashboard contains a zero-ambiguity list of
  the last named failures.

### Lot 145 - Final Gate Green

**Purpose:** Finish strict 100% convergence.

**Files:**
- Modify: `reports/analysis/psdk_fight_100_percent_acceptance.md`
- Modify: `reports/analysis/psdk_fight_convergence_dashboard.md`
- Modify tests/manifests only for failures discovered by Lot 144.

**Acceptance:**
- This command passes:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
dart run tool/psdk_fight_parity_audit.dart \
  --final-gate \
  --goldens test/fixtures/psdk_golden
```

- Final expected state:
  - attacks: `728 / 728`,
  - methods: `330 / 330`,
  - effects: `482 / 482`,
  - runtime bridge: complete or no unsupported supported moves,
  - golden fixture threshold met.

## Lot Count

This plan adds `34` remaining lots: Lots `112` through `145`.

The highest-risk lots are:

| Risk | Lots |
| --- | --- |
| Ability explosion | 113-117 |
| Item lifecycle interactions | 119-121 |
| Doubles/targeting assumptions | 130 |
| Multi-turn ordering | 132 |
| Final attack promotions | 134-140 |
| Golden suite volume | 141 |

## Recommended Order

1. Lots 112-126: finish effects first.
2. Lots 127-133: finish methods after effects are available.
3. Lots 134-140: finish attack strict promotions.
4. Lots 141-143: expand goldens and runtime completion.
5. Lots 144-145: final gate dry run and final green.

Do not skip directly to attack batches unless the dashboard proves their
dependencies are already complete.
