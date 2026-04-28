# PSDK Fight Parity Execution Lots

Date: 2026-04-28

Goal: promote remaining `partial` move families from broad fallbacks to focused
PSDK-inspired Dart behaviors, while keeping each slice testable in isolation.

## Lot A - Action/User Gated Attacks

Status: completed.

Files:

- Create `packages/map_battle/lib/src/domain/move/behaviors/action_gated_move_behavior.dart`
- Create `packages/map_battle/test/psdk_move_families/action_gated_moves_test.dart`
- Update `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- Update `packages/map_battle/tool/extract_psdk_move_registry.dart`
- Regenerate `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Update `reports/previous/psdk-move-porting-matrix.md`
- Update `reports/previous/psdk-attack-coverage.md`
- Update `reports/previous/psdk-fight-engine-parity-status.md`
- Update `reports/previous/psdk-fight-parity-next-lots.md`

Logic:

- `s_snore`: fail before PP unless the user is asleep or has `comatose`.
- `s_sucker_punch`: fail before PP if the target already attempted a move this
  turn, or if the target's pending local singles move is status-only.
- Keep both methods `partial`: doubles targeting, action queue introspection and
  full Me First-specific parity are still not complete.

Verification:

- Focused action-gated test file: passed.
- Registry manifest test: passed.
- Full `packages/map_battle` analyzer/tests: passed.

## Lot B - Weather-Driven Accuracy And Charge

Status: completed.

Files:

- Add/extend weather-aware move behavior files.
- Update registry/extractor/manifest/reports.
- Added weather tests for `s_thunder`, `s_hurricane`, `s_solar_beam`.

Logic:

- Thunder/Hurricane weather accuracy overrides.
- Solar Beam immediate release under harsh sun and weakened release under rain,
  sand, hail/snow where supported by local weather state.
- Keep `partial` for full weather ability/item exceptions.

## Lot C - Consecutive/Combo Power Counters

Status: completed.

Files:

- Added consecutive-power behavior and tests.
- Update registry/extractor/manifest/reports.

Logic:

- `s_echo`, `s_fury_cutter`, `s_rollout`, `s_ice_ball`, `s_trump_card`.
- Uses existing move history and current PP as the local source of truth.
- Keep `partial` for lock-in, Defense Curl coupling and full party/PP edge
  cases.

## Lot D - Counter/Delayed Damage

Status: completed.

Files:

- Added counter-style/direct retaliation behavior and tests for `s_counter`,
  `s_mirror_coat`, `s_metal_burst` and `s_bide`.
- Added same-bank KO history power behavior and tests for `s_retaliate`.
- Update registry/extractor/manifest/reports.

Logic:

- `s_counter`, `s_mirror_coat`, `s_metal_burst`, `s_bide`, `s_retaliate`.
- Read current-turn damage history, category metadata where available, then
  apply direct damage or fail before PP.
- `s_retaliate` scans same-bank combatants for a previous-turn damage history
  entry ending at 0 HP, then doubles base power like the local PSDK slice.

## Lot E - Item-Dependent Moves

Status: completed.

Files:

- Added `ItemDependentMoveBehavior` and tests.
- Updated registry/extractor/manifest/reports.

Logic:

- `s_techno_blast`, `s_natural_gift`, `s_fling`, `s_pluck`, `s_thief`,
  `s_knock_off`, `s_bestow`, `s_recycle`, `s_belch`.
- Ports the local singles slice for Genesect gating, Drive type selection,
  Berry Natural Gift power/type, Fling power/consumption, Pluck/Thief/Knock Off
  item removal or transfer, Bestow item transfer, Recycle restoration and Belch
  consumed-berry gating.
- Keep `partial` until the full PSDK item catalog, `can_lose_item?` /
  `can_give_item?`, Berry effects, Fling riders and trainer/wild persistence
  rules are promoted.

## Lot F - Forced Action And Lock-In

Status: completed for the current local singles slice.

Files:

- Extended `ForceNextMoveBaseEffect` so it can represent both recharge
  prevention and PSDK-style repeated-move lock-in.
- Added/extended `ForcedActionMoveBehavior` for `s_gigaton_hammer`,
  `s_thrash`, `s_outrage` and `s_uproar`.
- Added targeted tests in
  `packages/map_battle/test/psdk_move_families/forced_action_moves_test.dart`.
- Updated registry/extractor/manifest/reports.

Logic:

- `s_outrage`, `s_thrash`, `s_uproar`, `s_gigaton_hammer`, `s_reload`.
- `s_gigaton_hammer` now fails before PP when it was the user's previous
  move, matching the local PSDK disable rule.
- `s_thrash` and `s_outrage` now install a `force_next_move_base` lock after a
  successful hit, block selecting another move while locked, then release into
  `confusion` at the end of the local randomized duration.
- `s_uproar` now installs a timed local `uproar` marker after a successful hit.
- Remaining gaps: automatic action replacement, doubles/random adjacent target
  retargeting while locked, Uproar's field-wide sleep-prevention terrain and
  full PSDK failure cleanup hooks.

## Lot G - Field/Location Specific Attacks

Status: completed for the current local singles slice.

Files:

- Added `packages/map_battle/lib/src/domain/move/behaviors/field_location_move_behavior.dart`.
- Added `packages/map_battle/test/psdk_move_families/field_location_moves_test.dart`.
- Updated registry/extractor/manifest/reports.

Logic:

- `s_secret_power`, `s_nature_power`, `s_camouflage`, `s_synchronoise`,
  `s_pledge`.
- `s_camouflage` now changes the user/target type from active terrain, falling
  back to Normal when no terrain is represented by the battle field.
- `s_nature_power` now becomes a terrain/default damaging move in the local
  slice: default `tri_attack`, Electric Terrain `thunderbolt`, Grassy Terrain
  `energy_ball`, Misty Terrain `moonblast`, Psychic Terrain `psychic`.
- `s_secret_power` now deals damage and applies its PSDK terrain/default
  secondary on the existing 30% proc seam.
- `s_synchronoise` now fails before damage unless the target shares one of the
  user's current battle types.
- `s_pledge` now has a dedicated local Basic damage behavior instead of the
  broad fallback; doubles pledge-combo ordering remains explicit future work.
- Remaining gaps: map biome/background location fidelity, multi-target
  Synchronoise, full Pledge ally-order combo effects and exact animation move
  substitution.

## Lot H - Multi-Target And Doubles Semantics

Status: pending.

Files:

- Extend targeting/action-order seams and add focused doubles tests.
- Update registry/extractor/manifest/reports.

Logic:

- `s_round`, `s_dragon_darts`, `s_expanding_force`, Pledge ordering and spread
  modifiers.
- Requires queue-aware action metadata before claiming more than local partial
  singles parity.

## Lot I - Special Secondary Random Effects

Status: completed for the current local singles slice.

Files:

- Added `packages/map_battle/lib/src/domain/move/behaviors/special_secondary_move_behavior.dart`.
- Added `packages/map_battle/test/psdk_move_families/special_secondary_moves_test.dart`.
- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated `packages/map_battle/tool/extract_psdk_move_registry.dart`.
- Updated registry manifest, matrix and coverage reports.

Logic:

- `s_tri_attack`, `s_psychic_noise`, `s_throat_chop`, `s_burn_up`,
  `s_incinerate`, `s_relic_song`, `s_alluring_voice`,
  `s_burning_jealousy`, `s_salt_cure`, `s_syrup_bomb`, `s_tar_shot`.
- `s_tri_attack` now keeps its Basic hit and applies one random major status
  among paralysis, burn and freeze through the existing 20% secondary proc
  seam.
- `s_psychic_noise` now keeps its Basic hit and applies a three-turn
  `HealBlockEffect`, unless the target's local ability is `aroma_veil`.
- `s_throat_chop` now keeps its Basic hit and installs a timed local
  `ThroatChopEffect` after a successful hit; the effect prevents sound-flagged
  moves while active.
- `s_burn_up` now fails before PP if the user does not currently have the
  move type, then removes that type from the user's local battle typing after
  a successful hit.
- `s_incinerate` now keeps its Basic hit and removes target-held berry/gem ids
  after a successful hit.
- `s_relic_song` now resolves through a dedicated Basic damage path so its PSDK
  method is no longer hidden inside the broad fallback.
- `s_alluring_voice` and `s_burning_jealousy` now check same-turn positive
  target stat history before applying confusion or burn.
- `s_salt_cure` now installs an object-backed `SaltCureEffect` with end-turn
  residual damage and the Water/Steel divisor branch.
- `s_syrup_bomb` now installs an object-backed `SyrupBombEffect` that applies
  timed end-turn Speed drops.
- `s_tar_shot` now installs an object-backed `TarShotEffect` marker for the
  Fire-weakness rule.
- Remaining gaps: Throat Chop disabled-move UI/messages, ally-side Aroma Veil
  protection, full PSDK item database and `can_lose_item?` checks for
  Incinerate, Burn Up restoration/cleanup semantics, exact Syrup Bomb
  lifecycle/messages, and Meloetta form calibration for Relic Song.

## Lot J - Object-Backed Effect Promotion

Status: pending.

Files:

- Promote high-impact markers to first-class `BattleEffect` objects.
- Update effect matrix and move reports.

Logic:

- Prioritize Yawn, Wish, Future Sight, Tailwind, Trick Room, Safeguard,
  Destiny Bond, Powder, Embargo, Grudge, Magnet Rise and hazard/screen gaps.

## Lot K - Grounding And Type-Immunity Corrections

Status: completed for the current local singles slice.

Files:

- Added `packages/map_battle/lib/src/domain/move/behaviors/grounding_move_behavior.dart`.
- Added `packages/map_battle/lib/src/domain/effect/move/smack_down_effect.dart`.
- Added `packages/map_battle/test/psdk_move_families/grounding_moves_test.dart`.
- Updated type effectiveness/immunity seams and registry/extractor/reports.

Logic:

- `s_smack_down` now keeps its Basic Rock hit and installs
  `SmackDownEffect` on airborne targets.
- `BattleGroundingResolver` already treats `smack_down` as force-grounded; the
  local type-effectiveness path now also treats Flying as neutral for later
  Ground moves when the target carries this effect.
- Remaining gaps: PSDK cleanup of Magnet Rise, Telekinesis and compatible
  out-of-reach effects, Substitute/Authenic checks and Sky Drop exceptions.

## Lot L - Fake Out And Flinch

Status: completed for the current local singles slice.

Files:

- Added `packages/map_battle/lib/src/domain/effect/move/flinch_effect.dart`.
- Updated `packages/map_battle/lib/src/domain/move/behaviors/action_gated_move_behavior.dart`.
- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated `packages/map_battle/test/psdk_move_families/action_gated_moves_test.dart`.
- Updated registry manifest, effect matrix and coverage reports.

Logic:

- `s_fake_out` now uses `ActionGatedMoveBehavior.fakeOut` instead of the broad
  Basic fallback.
- The move fails before PP when the user has been active for more than one
  battle turn or carries the local `instruct` effect marker.
- On a successful hit, it applies object-backed `FlinchEffect` to the target.
- `FlinchEffect` prevents its scoped battler from executing its next same-turn
  move and is cleared by the existing end-turn turn-scoped effect cleanup.
- Remaining gaps: battle message parity, Steadfast-style side effects and
  deeper doubles/action-queue edge cases.

## Lot M - Feint Protect Breaking

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/domain/move/battle_move_immunity_resolver.dart`.
- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated `packages/map_battle/test/psdk_protect_effect_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_feint` now uses a dedicated static resolver instead of the broad Basic
  fallback.
- The resolver preserves type-immunity checks but ignores target Protect
  prevention for Feint's hit window.
- After a successful hit, it removes local `protect` and `crafty_shield`
  markers from the target effect stack.
- If the target successfully used Protect or Crafty Shield earlier in the same
  turn, Feint calculates damage with PSDK's local increased power of 50.
- Remaining gaps: exact battle messages, broader Protect-variant effect names
  and doubles/action-queue edge cases.

## Lot N - Fell Stinger KO Boost

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated `packages/map_battle/test/psdk_move_families/basic_damage_specialization_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_fell_stinger` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- The resolver first runs the shared Basic damage path so accuracy, immunity,
  Protect and secondary handling stay consistent with the rest of the engine.
- If a successful damage event from Fell Stinger leaves a target fainted, the
  user receives a +3 Attack stage change through `BattleStatChangeHandler`.
- Remaining gaps: Moxie post-damage-death chaining and richer multi-target
  ordering semantics.

## Lot O - Stomp And Minimize

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated `packages/map_battle/test/psdk_move_families/basic_damage_specialization_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_stomp` now uses a dedicated static resolver instead of the broad Basic
  fallback.
- If the target carries the local `minimize` marker, Stomp bypasses accuracy.
- If the target carries the local `minimize` marker, Stomp calculates damage
  with doubled base power.
- Remaining gaps: fully object-backed Minimize effect parity and broader
  multi-target accuracy semantics.

## Lot P - U-turn Pivot Switch

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated `packages/map_battle/test/psdk_move_families/switch_effect_moves_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_u_turn` now uses a dedicated static resolver instead of the broad Basic
  fallback.
- On a successful damage hit, U-turn marks the user as `switching`.
- On a miss or prevented hit, U-turn does not mark the user as `switching`.
- Remaining gaps: full reserve/switch-handler integration and exact item or
  ability ordering for Red Card, Eject Button and Emergency Exit.

## Lot Q - High Jump Kick Crash

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated `packages/map_battle/test/psdk_move_families/basic_damage_specialization_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_jump_kick` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- On a normal hit, High Jump Kick keeps the regular Basic damage path.
- On accuracy failure, target immunity or Protect-style failure, High Jump
  Kick applies crash damage equal to half the user's max HP.
- PP and pre-user-gate failures still do not crash the user.
- Remaining gaps: exact PSDK message parity and broader faint-process ordering.

## Lot R - Ice Spinner And Steel Roller Terrain Clear

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated `packages/map_battle/test/psdk_move_families/terrain_power_move_behavior_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_ice_spinner` and `s_steel_roller` now use dedicated static resolvers
  instead of the broad Basic fallback.
- Ice Spinner keeps its Basic hit and clears active terrain after a successful
  hit.
- Steel Roller fails before damage if no terrain is active.
- Steel Roller keeps its Basic hit and clears active terrain after a
  successful hit.
- Remaining gaps: exact PSDK message parity and richer terrain-effect hook
  ordering.

## Lot S - Jaw Lock And Poltergeist Gates

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated `packages/map_battle/test/psdk_move_families/basic_damage_specialization_test.dart`.
- Updated `packages/map_battle/test/psdk_move_families/trapping_moves_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_jaw_lock` now uses a dedicated static resolver instead of the broad Basic
  fallback.
- On a successful damaging hit, Jaw Lock installs `CantSwitchEffect` on both
  the user and target, with the user recorded as the origin.
- If either side is already under `cant_switch`, Jaw Lock keeps its damage but
  does not install duplicate trapping effects.
- `s_poltergeist` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- Poltergeist fails before damage when the target has no held item.
- Poltergeist keeps its Basic damage path when the target has a held item.
- Remaining gaps: exact PSDK reveal-item message parity, multi-target
  Poltergeist display ordering and richer switch-prevention cleanup semantics.

## Lot T - Sappy Seed Leech Seed Hit

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated `packages/map_battle/test/psdk_move_families/persistent_effect_moves_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_sappy_seed` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- Sappy Seed keeps its Basic damage path.
- After a successful damage hit, Sappy Seed installs `LeechSeedEffect` on the
  target when the target is alive, non-Grass, not already seeded and not under
  Substitute.
- Grass targets still take damage but do not receive Leech Seed.
- Remaining gaps: exact PSDK message parity, position-effect vs battler-effect
  modelling and richer Substitute/ability interactions.

## Lot U - Baddy Bad And Glitzy Glow Screens

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated `packages/map_battle/test/psdk_move_families/screen_moves_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_baddy_bad` and `s_glitzy_glow` now use dedicated static resolvers instead
  of the broad Basic fallback.
- Both moves keep their Basic damage path.
- After a successful damage hit, Baddy Bad installs `reflect` on the user's
  bank.
- After a successful damage hit, Glitzy Glow installs `light_screen` on the
  user's bank.
- Light Clay extends the screen duration through the existing screen duration
  convention.
- Remaining gaps: exact PSDK messages, bank-effect modelling beyond singles
  and richer screen replacement/order hooks.

## Lot V - Freezy Frost Stat Reset

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/basic_damage_specialization_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_freezy_frost` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- Freezy Frost keeps its Basic damage path.
- After a successful damage hit, every alive battler has its stat stages reset
  to neutral, matching the PSDK `deal_effect` sweep over alive battlers.
- Remaining gaps: exact PSDK messages and richer multi-battler event ordering.

## Lot W - Scale Shot Multi-Hit Self Stats

Status: completed for the current local singles slice.

Files:

- Updated
  `packages/map_battle/lib/src/domain/move/behaviors/multi_hit_move_behavior.dart`.
- Updated `packages/map_battle/lib/src/domain/effect/ability/skill_link_effect.dart`.
- Updated `packages/map_battle/lib/src/domain/effect/item/loaded_dice_effect.dart`.
- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/fixed_damage_and_multi_hit_test.dart`.
- Updated `packages/map_battle/test/psdk_ability_effects_test.dart`.
- Updated `packages/map_battle/test/psdk_item_effects_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_scale_shot` now uses `MultiHitMoveBehavior.scaleShot` instead of the
  broad Basic fallback.
- Scale Shot reuses the PSDK 2-5 hit distribution already used by base
  `MultiHit`.
- Skill Link forces Scale Shot to five hits.
- Loaded Dice raises low Scale Shot rolls to at least four hits.
- After successful damage, Scale Shot applies its stage mods to the user rather
  than the target, matching PSDK's `deal_stats(user, [user])` override.
- Remaining gaps: exact PSDK messages and richer multi-target ordering.

## Lot X - Double Iron Bash Two-Hit Minimize Branch

Status: completed for the current local singles slice.

Files:

- Updated
  `packages/map_battle/lib/src/domain/move/behaviors/multi_hit_move_behavior.dart`.
- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/fixed_damage_and_multi_hit_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_double_iron_bash` now uses `MultiHitMoveBehavior.doubleIronBash` instead
  of the broad Basic fallback.
- Double Iron Bash executes exactly two successful hits through the PSDK
  multi-hit lane.
- Against a target with `minimize`, Double Iron Bash bypasses accuracy and
  doubles base power before damage calculation.
- Remaining gaps: exact PSDK messages, flinch timing parity and richer
  multi-target ordering.

## Lot Y - Grav Apple Gravity Power

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/basic_damage_specialization_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_grav_apple` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- Grav Apple keeps Basic damage and imported secondary stat drops.
- When Gravity is active in the local effect stack, Grav Apple raises base
  power by 1.5x before damage calculation, matching PSDK's `real_base_power`
  branch.
- Remaining gaps: exact PSDK messages and the full Gravity field-effect
  lifecycle.

## Lot Z - Rage User Marker

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_rage` now uses a dedicated static resolver instead of the broad Basic
  fallback.
- Rage keeps the successful Basic damage path.
- After a successful damage event, Rage installs a battler-scoped `rage`
  marker on the user, matching PSDK's `Effects::Rage` installation slice.
- Existing active `rage` markers are preserved instead of being replaced.
- Remaining gaps: exact PSDK messages and the full Rage attack-raise lifecycle
  when the user is hit later.

## Lot AA - Raging Bull Brick Break Inheritance

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/hazard_cleanup_moves_test.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_raging_bull` now uses the Brick Break static resolver instead of the
  broad Basic fallback.
- Raging Bull keeps its successful damage path.
- After a successful damage event, it clears opposing `reflect`,
  `light_screen` and `aurora_veil` bank-scoped screen markers, matching the
  PSDK inheritance from `BrickBreak`.
- Remaining gaps: Tauros form-based type changes and exact PSDK screen-break
  messages.

## Lot AB - Spectral Thief Positive Stat Theft

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_spectral_thief` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- Spectral Thief keeps its successful damage path.
- After a successful damage event, it copies every positive target stat stage
  to the user and clears those positive stages from the target.
- Negative target stages are preserved.
- Remaining gaps: exact PSDK messages and richer multi-target ordering.

## Lot AC - Make It Rain SelfStat Drop

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_make_it_rain` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- Make It Rain keeps its successful damage path.
- After a successful damage event, it applies imported stat-stage drops to the
  user, matching PSDK's `SelfStat` inheritance slice.
- Remaining gaps: battle-info money rewards and exact PSDK messages.

## Lot AD - Magnitude Random Power Table

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated registry manifest, move matrix and attack coverage report.

Logic:

- `s_magnitude` now uses a dedicated static resolver instead of the broad Basic
  fallback.
- Magnitude samples the PSDK probability table from the generic RNG stream.
- The selected table power overrides imported Studio power for damage
  calculation.
- The local deterministic seed `generic: 0` selects Magnitude 4 / base power
  10, matching PSDK's first table bucket.
- Remaining gaps: exact PSDK messages and the Dig/out-of-reach doubled damage
  branch.

## Lot AE - Glaive Rush Marker And Incoming Damage

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated `packages/map_battle/tool/extract_psdk_move_registry.dart`.
- Regenerated the move registry manifest and move porting matrix.

Logic:

- `s_glaive_rush` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- Glaive Rush keeps its successful Basic hit.
- After a successful damage event, it installs a battler-scoped
  `glaive_rush` marker on the user.
- While the marker is active, incoming damage against that battler is doubled
  in the local damage calculator, matching the PSDK documented behavior for
  the singles slice.
- Remaining gaps: exact PSDK messages and the action-order cleanup semantics
  from `Effects::GlaiveRush#on_post_action_event`.

## Lot AF - Fickle Beam Empowered Power Roll

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated `packages/map_battle/tool/extract_psdk_move_registry.dart`.
- Regenerated the move registry manifest and move porting matrix.

Logic:

- `s_fickle_beam` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- After the regular prechecks/accuracy path, it consumes the generic RNG stream
  and applies PSDK's `bchance?(0.3)` empowerment roll.
- On a successful empowerment roll, it doubles the base power through a scoped
  damage override for that hit.
- Remaining gaps: exact PSDK empowerment message text/timing.

## Lot AG - Super Duper Effective Damage Boost

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated `packages/map_battle/tool/extract_psdk_move_registry.dart`.
- Regenerated the move registry manifest, move porting matrix and attack
  coverage report.

Logic:

- `s_super_duper_effective` now uses a dedicated static resolver instead of the
  broad Basic fallback.
- It keeps the regular Basic hit path.
- When raw type effectiveness is super effective, it applies PSDK's
  `5461 / 4096` final damage multiplier after the local screen adjustment.
- Remaining gaps: exact PSDK message/event timing and richer interactions with
  later full damage-modifier hooks.

## Lot AH - Genies Storm Rain Accuracy

Status: completed for the current local singles slice.

Files:

- Updated
  `packages/map_battle/lib/src/domain/move/behaviors/weather_power_move_behavior.dart`.
- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated `packages/map_battle/tool/extract_psdk_move_registry.dart`.
- Regenerated the move registry manifest, move porting matrix and attack
  coverage report.

Logic:

- `s_genies_storm` now resolves through `WeatherPowerMoveBehavior.geniesStorm`
  instead of the broad Basic fallback.
- Under rain or hard rain, it copies the move with `accuracy: 0`, matching the
  existing clean-lane convention for guaranteed accuracy.
- Weather suppression via Air Lock / Cloud Nine keeps the regular imported
  accuracy because it flows through the existing `weatherEffectsSuppressed`
  field semantics.
- Remaining gaps: exact PSDK messages and broader weather/ability/item
  exceptions outside the local singles slice.

## Lot AI - Eerie Spell PP Drain

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated `packages/map_battle/tool/extract_psdk_move_registry.dart`.
- Regenerated the move registry manifest, move porting matrix and attack
  coverage report.

Logic:

- `s_eerie_spell` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- After a successful damage event, it finds the target's last attempted move in
  the local move history and removes up to 3 PP from that move.
- It preserves the existing clean-lane action order: if the target already
  acted earlier in the turn, its normal PP spend is visible before Eerie Spell's
  PP drain.
- Remaining gaps: exact PSDK message text/timing and richer multi-target
  behavior.

## Lot AJ - Last Respects Local KO Scaling

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated `packages/map_battle/tool/extract_psdk_move_registry.dart`.
- Regenerated the move registry manifest, move porting matrix and attack
  coverage report.

Logic:

- `s_last_respects` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- It scales base power by `(user.koCount + 1).clamp(1, 101)`, matching the PSDK
  formula shape with the local singles snapshot data currently available.
- Remaining gaps: full party-side KO aggregation across reserves and exact PSDK
  logging/messages.

## Lot AK - Shell Side Arm Damage Category Selection

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated `packages/map_battle/tool/extract_psdk_move_registry.dart`.
- Regenerated the move registry manifest, move porting matrix and attack
  coverage report.

Logic:

- `s_shell_side_arm` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- It evaluates the same move as physical and special against the current target,
  including local screen adjustment for the chosen category.
- It selects the physical lane only when physical damage is strictly higher;
  ties stay special, matching the PSDK `physical_hp > special_hp` branch.
- Remaining gaps: the local event model does not yet expose Shell Side Arm's
  PSDK `direct?` contact override when the physical lane wins.

## Lot AL - Electro Shot Charge and Rain Shortcut

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated `packages/map_battle/tool/extract_psdk_move_registry.dart`.
- Regenerated the move registry manifest, move porting matrix and attack
  coverage report.

Logic:

- `s_electro_shot` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- On the first non-rain turn, it performs the shared precheck, raises the user's
  Special Attack by one stage and installs the local two-turn charge marker
  without dealing damage.
- On the release turn, it removes the charge marker and resolves the normal
  Basic hit.
- Under active rain or hard rain, it still raises Special Attack and fires on
  the same turn, matching PSDK's `shortcut?` branch.
- Remaining gaps: exact PSDK charge messages/animations, forced-next-move
  metadata and non-100-accuracy shortcut edge cases are still broader two-turn
  parity work.

## Lot AM - Present Random Damage or Heal

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated `packages/map_battle/tool/extract_psdk_move_registry.dart`.
- Regenerated the move registry manifest, move porting matrix and attack
  coverage report.

Logic:

- `s_present` now uses a dedicated static resolver instead of being unsupported
  or broad Basic fallback behavior.
- It samples the PSDK generic RNG table: 40 power on rolls 1-40, 80 power on
  41-70, 120 power on 71-80 and healing on 81-100.
- Damage branches reuse the normal local damage calculator with the sampled
  power override.
- The healing branch heals the target by one quarter of max HP, and skips the
  heal if the target is already full or locally Heal Blocked.
- Remaining gaps: exact PSDK messages and richer heal-block display semantics
  are still not represented in the local event stream.

## Lot AN - Triple Arrows User Crit Marker

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated `packages/map_battle/test/psdk_registry_manifest_test.dart`.
- Updated `packages/map_battle/tool/extract_psdk_move_registry.dart`.
- Regenerated the move registry manifest, move porting matrix and attack
  coverage report.

Logic:

- `s_triple_arrows` now uses a dedicated static resolver instead of the broad
  Basic fallback.
- It preserves the normal Basic hit, then installs a user-scoped
  `triple_arrows` marker for four turns after successful damage.
- It follows PSDK's unstackable-effect guard: the marker is skipped when the
  user already has `dragon_cheer`, `focus_energy` or `triple_arrows`.
- Remaining gaps: the local critical-hit calculator does not yet consume the
  `triple_arrows` marker as a crit-stage modifier, and exact PSDK messages are
  still not represented.

## Lot AO - Critical Marker Damage Hooks

Status: completed for the current local singles slice.

Files:

- Updated
  `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`.
- Updated
  `packages/map_battle/lib/src/domain/move/battle_move_critical_resolver.dart`.
- Updated `packages/map_battle/test/psdk_type_damage_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- The local damage calculator now feeds an effective critical count into the
  critical resolver instead of relying only on the imported move critical rate.
- `focus_energy` and `triple_arrows` add +2 to the user's effective critical
  count, matching PSDK `calc_critical_count`.
- `dragon_cheer` adds +1 for non-Dragon users and +2 for Dragon users.
- `laser_focus` maps to a guaranteed critical branch without advancing the
  critical RNG stream, matching PSDK's early return before the random roll.
- Remaining gaps: Lucky Chant, critical-blocking abilities, Super Luck,
  critical-rate items and exact PSDK critical messages remain separate battle
  effect or ability/item parity lots.

## Lot AP - Advanced Critical Ability And Item Hooks

Status: completed for the current local singles slice.

Files:

- Updated
  `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`.
- Updated `packages/map_battle/test/psdk_type_damage_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- Lucky Chant now blocks critical hits before guaranteed-critical branches.
- Merciless now guarantees a critical hit against poisoned or toxic targets
  without advancing the critical RNG stream.
- Battle Armor and Shell Armor now force the effective critical count to zero.
- Super Luck, Lansat Berry and critical-rate items add +1 to the effective
  critical count. The item slice covers PSDK's unconditional `razor_claw` and
  `scope_lens`, plus Farfetch'd-only `leek` and Chansey-only `lucky_punch`.
- Remaining gaps: Mold Breaker-like ability cancellation and exact PSDK
  critical messages remain broader ability/message parity work.

## Lot AQ - Charge Electric Base-Power Hook

Status: completed for the current local singles slice.

Files:

- Updated
  `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`.
- Updated `packages/map_battle/test/psdk_type_damage_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- A user-scoped `charge` marker now doubles base power for Electric moves only.
- Non-Electric moves are deliberately unchanged while Charge is active.
- Remaining gaps: exact Charge messages and effect-consumption semantics remain
  broader marker lifecycle work.

## Lot AR - Defog Fog Weather Cleanup

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/hazard_cleanup_moves_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- `s_defog` now clears active fog weather after its existing stat, hazard and
  screen cleanup path.
- Non-fog weather, including rain, is preserved.
- Remaining gaps: exact PSDK weather-clear messages/events remain future event
  parity work.

## Lot AS - Gastro Acid Active Ability Suppression

Status: completed for the current local singles slice.

Files:

- Updated
  `packages/map_battle/lib/src/domain/effect/ability/ability_effect.dart`.
- Updated
  `packages/map_battle/lib/src/domain/battler/battle_grounding_resolver.dart`.
- Updated `packages/map_battle/test/psdk_type_damage_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- Battlers carrying `ability_suppressed` no longer expose active
  `BattleAbilityEffect` hooks.
- The direct Levitate grounding shortcut also respects `ability_suppressed`, so
  a Ground move can hit a Levitate target after Gastro Acid has marked it.
- Remaining gaps: Gastro Acid's full PSDK ability-change guard list, protected
  ability/species checks and exact messages remain future ability-change work.

## Lot AT - Autotomize Weight Mutation

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- `s_autotomize` now lowers the user's current battle weight by 100 kg, clamped
  to 0.1 kg, when its Speed stage increase actually changes the target stages.
- If Speed is already capped and no stat stage changes, Autotomize preserves the
  current weight, matching PSDK's stat-success gate for the effect.
- Remaining gaps: exact marker removal/on-delete weight restoration and PSDK
  messages remain lifecycle work.

## Lot AU - Mud Sport And Water Sport Power Hooks

Status: completed for the current local singles slice.

Files:

- Updated
  `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`.
- Updated `packages/map_battle/test/psdk_type_damage_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- A local `mud_sport` marker now halves Electric move base power during damage
  calculation.
- A local `water_sport` marker now halves Fire move base power during damage
  calculation.
- Non-matching move types are deliberately unchanged.
- Remaining gaps: exact global/field marker lifecycle and PSDK messages remain
  future effect-lifecycle work.

## Lot AV - Foresight And Miracle Eye Type-Immunity Hooks

Status: completed for the current local singles slice.

Files:

- Updated
  `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`.
- Updated
  `packages/map_battle/lib/src/domain/move/battle_move_immunity_resolver.dart`.
- Updated
  `packages/map_battle/lib/src/domain/move/battle_move_type_processor.dart`.
- Updated `packages/map_battle/test/psdk_type_damage_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- Target-side `foresight` now overwrites the Ghost single-type immunity for
  Normal and Fighting moves.
- Target-side `miracle_eye` now overwrites the Dark single-type immunity for
  Psychic moves.
- The overwrite is applied in both the pre-damage immunity filter and the damage
  type multiplier path so animation/damage decisions stay aligned.
- Remaining gaps: exact unstackable-effect failure messages and broader effect
  cleanup remain future parity work.

## Lot AW - PSDK Third-Type Damage Propagation

Status: completed for the current local singles slice.

Files:

- Updated
  `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`.
- Updated
  `packages/map_battle/lib/src/domain/move/battle_move_immunity_resolver.dart`.
- Updated
  `packages/map_battle/lib/src/domain/move/battle_move_type_processor.dart`.
- Updated `packages/map_battle/test/psdk_type_damage_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- A user's `type3` now participates in STAB resolution.
- A target's `type3` now participates in type effectiveness and type-immunity
  prechecks.
- The same extra-type seam also carries temporary types already present on the
  combatant snapshot.
- Remaining gaps: exact PSDK type-change cleanup, richer temporary-type
  lifecycle and move-specific third-type edge cases remain future work.

## Lot AX - Mist Stat-Drop Prevention

Status: completed for the current local singles slice.

Files:

- Updated
  `packages/map_battle/lib/src/domain/handler/battle_stat_change_handler.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/generic_status_stat_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- A bank-scoped local `mist` marker now prevents opposing negative stat-stage
  changes from applying to protected battlers.
- Same-bank/self stat changes are deliberately not blocked, matching PSDK's
  launcher-bank guard.
- The tests cover both direct marker injection and the real `s_mist` move path
  before a slower opposing stat drop.
- Remaining gaps: exact PSDK prevention messages and a generic
  `stat_decrease_prevention` hook registry remain future effect-hook work.

## Lot AY - Telekinesis Grounding Hook

Status: completed for the current local singles slice.

Files:

- Updated
  `packages/map_battle/lib/src/domain/battler/battle_grounding_resolver.dart`.
- Updated `packages/map_battle/test/psdk_type_damage_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- A target carrying local `telekinesis` is now treated as airborne by the
  grounding resolver after forced-grounding effects such as Gravity,
  Smack Down and Ingrain have had priority.
- Ground moves against an otherwise grounded Telekinesis target now fail through
  the same immunity precheck path as Flying/Levitate.
- Remaining gaps: PSDK's Telekinesis move definition is skeletal in the local
  source snapshot, so richer target guards/out-of-reach interactions remain a
  documented local mechanics choice for a later lot.

## Lot AZ - Electrify And Ion Deluge Type Rewrite

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`.
- Updated
  `packages/map_battle/lib/src/domain/move/battle_move_immunity_resolver.dart`.
- Updated `packages/map_battle/test/psdk_type_damage_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- Local `electrify` now rewrites the user's effective move type to Electric for
  damage, STAB, effectiveness and immunity prechecks.
- Local `ion_deluge` now rewrites Normal moves to Electric for the same damage
  and precheck paths.
- `s_electrify` uses a distinct local `electrify` marker so it does not collide
  with the durable `change_type` marker used by moves such as Soak.
- Remaining gaps: exact PSDK once-turn cleanup, duplicate-effect failure
  messages and a shared definitive-type hook for every specialized move
  behavior remain future work.

## Lot BA - Magnet Rise Grounding Hook

Status: completed for the current local singles slice.

Files:

- Updated
  `packages/map_battle/lib/src/domain/battler/battle_grounding_resolver.dart`.
- Updated `packages/map_battle/test/psdk_type_damage_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- Local `magnet_rise` now shares the forced-flying grounding path with
  `telekinesis`, matching PSDK's ForceFlying effect family.
- Forced-grounding effects still have priority because Gravity, Smack Down and
  Ingrain are checked before Magnet Rise.
- Ground moves against a grounded target with `magnet_rise` now fail through
  the same immunity precheck path as Flying/Levitate/Air Balloon targets.
- Remaining gaps: exact `s_magnet_rise` usage failure messages and Iron Ball
  move-usage gating remain future move-definition work.

## Lot BB - Embargo Held-Item Grounding Suppression

Status: completed for the current local singles slice.

Files:

- Updated
  `packages/map_battle/lib/src/domain/battler/battle_grounding_resolver.dart`.
- Updated `packages/map_battle/test/psdk_type_damage_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- A target carrying local `embargo` now ignores held-item grounding overrides in
  the grounding resolver.
- The verified slice covers Air Balloon: a Normal target holding Air Balloon is
  immune to Ground moves normally, then becomes grounded when Embargo is active.
- The patch deliberately does not claim full Embargo parity yet: bag-item
  prevention, move item-use guards, Baton Pass transfer and the older Iron
  Ball/Flying type-chart interaction remain separate lots.

## Lot BC - Toxic Thread Double-Fail Guard

Status: completed for the current local singles slice.

Files:

- Updated `packages/map_battle/lib/src/data/static_basic_move_registry.dart`.
- Updated
  `packages/map_battle/lib/src/domain/handler/battle_stat_change_handler.dart`.
- Updated
  `packages/map_battle/test/psdk_move_families/generic_status_stat_test.dart`.
- Updated this parity execution report plus the parity status and next-lots
  notes.

Logic:

- Stat-stage changes that are already clamped at their target limit now return
  `applied: false` instead of emitting a misleading `stat_stage_change` event.
- `s_toxic_thread` now emits `move_failed` only when its secondary resolver
  applies no status and no stat-stage change.
- Tests cover the exact PSDK gate: already-poisoned + Speed at `-6` fails,
  already-poisoned with Speed still droppable succeeds through the Speed drop,
  and Speed at `-6` with poison still applicable succeeds through poison.
- Remaining gaps: exact PSDK failure message text and broader secondary-effect
  reason propagation remain future polish.
