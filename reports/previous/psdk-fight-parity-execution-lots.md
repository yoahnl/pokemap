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
