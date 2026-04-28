# PSDK Fight Parity Next Lots

Date: 2026-04-28

## Baseline

Sources:

- `reports/previous/psdk-fight-engine-parity-status.md`
- `reports/previous/psdk-move-porting-matrix.md`
- `reports/previous/psdk-effect-porting-matrix.md`
- `reports/previous/psdk-attack-coverage.md`
- `pokemonsdk-development/scripts/5 Battle`

Current measured state:

| Axis | Current |
| --- | ---: |
| PSDK move methods | 330 |
| Move methods ported | 25 |
| Move methods partial | 305 |
| Move methods missing | 0 |
| PSDK effect classes | 482 |
| Effect classes ported | 0 |
| Effect classes partial | 25 |
| Effect classes missing | 457 |
| Studio attacks in local source | 728 |
| Studio attacks fait | 33 |
| Studio attacks partiel | 695 |
| Studio attacks pas_fait | 0 |

Latest completed wave:

- `s_a_fang`, `s_ohko`, `s_sacred_sword`, `s_heal_bell`,
  `s_take_heart`, `s_sparkly_swirl` are now wired in the Dart registry and
  marked `partial`.
- Basic-descendant method `s_brick_break` is now wired as a partial Basic hit;
  its PSDK-specific effects remain explicit dependencies.
- `s_bind` is now wired as a dedicated partial Bind resolver with timed
  trapping and residual end-turn damage.
- `s_cantflee` is now wired as a dedicated partial CantSwitch resolver instead
  of a generic Basic fallback.
- `ShadowTag`, `ArenaTrap` and `MagnetPull` are now wired as object-backed
  switch-prevention ability effects.
- `s_dragon_tail` and `s_roar` are now wired as dedicated force-switch marker
  resolvers instead of generic Basic fallbacks.
- Additional Basic-descendant methods `s_outrage`, `s_pledge`,
  `s_psychic_noise`, `s_thrash`, `s_throat_chop`, `s_tri_attack` are now wired
  as partial Basic hits. Singles fallback targeting now handles `randomFoe`
  and `allAdjacentFoes`.
- Additional partial Basic fallback wave: `s_dragon_tail`, `s_ice_ball`,
  `s_revenge`, `s_roar`, `s_rollout`,
  `s_round`, `s_secret_power`, `s_synchronoise`, `s_trump_card`, `s_uproar`.
- Recharge/screen/attention wave: `s_reload` now has a minimal
  `force_next_move_base` recharge effect, `s_reflect` now carries timed local
  markers for Reflect/Light Screen/Aurora Veil, refuses duplicate screens,
  requires snow/hail for Aurora Veil, honors Light Clay duration, applies local
  screen damage reduction for Basic physical/special hits and lets Infiltrator
  bypass that reduction; `s_follow_me` now executes as a turn-scoped attention
  marker. All three remain `partial`.
- Two-turn wave: `s_2turns` now charges first and releases its Basic hit on
  the next submission. It remains `partial`.
- State-marker/item/Z wave: `s_foresight` installs a target marker and now
  feeds Normal/Fighting-vs-Ghost immunity overwrites, `s_add_type` writes the
  target `type3` and that third type now participates in STAB/effectiveness,
  `s_thing_sport` installs timed sport markers and those markers now dampen
  matching Electric/Fire base power, `s_trick` swaps held items, and
  Studio-only offensive `s_z_move` entries now execute through the Basic damage
  path. They remain `partial`.
- Marker wave: `s_yawn`, `s_taunt`, `s_torment`, `s_future_sight`,
  `s_wish`, `s_tailwind`, `s_safe_guard`, `s_spike`, `s_stealth_rock`,
  `s_sticky_web`, `s_toxic_spike`, `s_trick_room` and `s_wonder_room` now
  install local PSDK effect markers. They remain `partial`.
- Ability/type wave: `s_simple_beam`, `s_worry_seed`, `s_role_play`,
  `s_skill_swap` and `s_reflect_type` now mutate local ability/type state.
  They remain `partial`.
- Marker/secondary wave: `s_minimize`, `s_miracle_eye`, `s_mist`,
  `s_perish_song`, `s_telekinesis`, `s_toxic_thread` and `s_plasma_fists`
  now execute through local PSDK marker, secondary-status/stat or Basic+Ion
  Deluge paths. `miracle_eye` now also feeds Psychic-vs-Dark immunity
  overwrites. They remain `partial`.
- Turn-marker wave: `s_destiny_bond`, `s_disable`, `s_electrify`,
  `s_embargo`, `s_encore`, `s_grudge`, `s_heal_block`, `s_ion_deluge`,
  `s_lucky_chant`, `s_magnet_rise`, `s_powder` and `s_snatch` now execute
  through local PSDK marker paths. They remain `partial`.
- Basic fallback wave: `s_burn_up`,
  `s_flame_burst`, `s_fury_cutter`, `s_fusion_bolt`,
  `s_fusion_flare`, `s_hidden_power`, `s_incinerate`,
  `s_last_resort`, `s_payday`,
  `s_photon_geyser`, `s_pollen_puff`, `s_pursuit`, `s_rage`,
  `s_rapid_spin`, `s_relic_song` and `s_spectral_thief` now execute their
  local Basic damage path. They remain `partial`.
- Marker/secondary status wave: `s_focus_energy`, `s_laser_focus`,
  `s_charge`, `s_autotomize`, `s_gastro_acid` and `s_defog` now execute
  through local marker or secondary-only state paths. They remain `partial`.
- Mixed fallback wave: `s_beak_blast`, `s_core_enforcer`,
  `s_flying_press`, `s_focus_punch`
  and `s_shell_trap` now execute their local Basic damage path; `s_sky_drop`
  uses the local two-turn path; `s_substitute` spends user HP and installs a
  local substitute marker; `s_attract`, `s_imprison`, `s_nightmare`,
  `s_quash`, `s_gravity`, `s_happy_hour` and `s_magic_room` now install local
  marker paths. They remain `partial`.
- Type/order/status wave: `s_change_type` now replaces the target visible
  types and adds a local change-type marker; `s_stockpile` now marks the user
  and raises Defense/Special Defense; `s_after_you`, `s_ally_switch`,
  `s_magic_coat` and `s_crafty_shield` now execute as turn-scoped marker
  slices; `s_captivate` and `s_parting_shot` now execute through the
  secondary-only stat path. They remain `partial`.
- Focus/history wave: `s_struggle` now uses the local recoil path with recoil
  from user max HP; `s_lock_on` and `s_mind_reader` install a local Lock-On
  marker on the user; `s_entrainment` copies the user's ability to the target;
  `s_memento` applies imported offensive drops and knocks out the user. They
  remain `partial`.
- Move-prevention effect wave: `Taunt` is now object-backed as `TauntEffect`
  and prevents status moves through the user-prevention hook; `Torment` is
  now object-backed as `TormentEffect` and prevents repeating the last
  successful non-Struggle move; `Disable` is now object-backed as
  `DisableEffect` and blocks the target's last successful non-Struggle move;
  `Encore` is now object-backed as `EncoreEffect` and blocks choosing a
  different move than the encored last successful move; `HealBlock` is now
  object-backed as `HealBlockEffect` and blocks local healing methods;
  `Attract` is now object-backed as `AttractEffect` and performs its 50%
  user-prevention roll; `Imprison` is now object-backed as `ImprisonEffect`
  and blocks shared foe move ids. They remain `partial`.
- Hazard cleanup wave: `s_rapid_spin` now resolves through a dedicated Rapid
  Spin path that keeps its Basic hit and clears user-local rapid-spin-affected
  effects plus own-bank hazards; `s_defog` now resolves through a dedicated
  Defog path that keeps imported secondary drops and clears rapid-spin hazards
  plus opposing screen markers; `s_brick_break` now keeps its Basic hit and
  clears opposing screen markers after a successful hit; Spikes, Toxic Spikes,
  Stealth Rock and Sticky Web are now object-backed bank hazard effects;
  Spikes and Toxic Spikes persist PSDK layer counts; Heavy-Duty Boots prevents
  all local entry-hazard effects and Magic Guard prevents Spikes/Stealth Rock
  entry damage; `s_stone_axe` and `s_ceaseless_edge` now keep their Basic hit
  and install or empower their matching entry hazard after a successful hit.
  They remain `partial`.
- Broad missing-method fallback wave: all 47 Studio attack rows that were
  previously `pas_fait` now resolve to explicit `partial` behaviors. This
  includes broad Basic fallbacks (`s_beat_up`, `s_echo`, `s_frustration`,
  `s_magnitude`, `s_present`, `s_return`, `s_split_up`),
  target markers (`s_assist`, `s_bide`, `s_camouflage`,
  `s_conversion`, `s_conversion2`, `s_counter`, `s_healing_wish`,
  `s_instruct`, `s_lunar_dance`, `s_me_first`, `s_metal_burst`,
  `s_metronome`, `s_mimic`, `s_mirror_coat`, `s_mirror_move`,
  `s_nature_power`, `s_sketch`, `s_sleep_talk`, `s_spite`,
  `s_swallow`, `s_teleport`), user-bank markers (`s_flower_shield`,
  `s_gear_up`, `s_helping_hand`, `s_magnetic_flux`, `s_rototiller`),
  secondary-only markers (`s_self_stat_z_move`, `s_venom_drench`) and
  Studio-only offensive methods (`s_genesis_supernova`,
  `s_guardian_of_alola`, `s_hyperspace_hole`,
  `s_light_that_burns_the_sky`, `s_malicious_moonsault`,
  `s_splintered_stormshards`, `s_z_move`). They remain intentionally
  `partial`: the goal of this wave is runtime executability and coverage
  accounting, not full method parity.
- Ruby-only missing-method fallback wave: the remaining 56 PSDK Ruby move
  registrations now resolve to explicit `partial` behaviors in Dart, so the
  move-method matrix has no `missing` rows left. Offensive methods are wired
  through Basic fallbacks where they can at least execute their imported
  damage data; non-damaging or rule-heavy methods are wired as local
  target/user/field markers. This wave covers `s_alluring_voice`,
  `s_aura_wheel`, `s_burning_jealousy`,
  `s_chilly_reception`, `s_corrosive_gas`, `s_court_change`, `s_doodle`,
  `s_dragon_cheer`, `s_dragon_darts`,
  `s_eerie_spell`, `s_electro_shot`, `s_expanding_force`, `s_fairy_lock`,
  `s_fickle_beam`, `s_genies_storm`,
  `s_geomancy`, `s_gigaton_hammer`, `s_glaive_rush`,
  `s_grassy_glide`, `s_ice_spinner`,
  `s_last_respects`, `s_magic_powder`,
  `s_make_it_rain`, `s_no_retreat`, `s_octolock`, `s_order_up`,
  `s_pre_attack_base`, `s_rage_fist`, `s_raging_bull`,
  `s_revival_blessing`, `s_rising_voltage`, `s_salt_cure`,
  `s_shed_tail`, `s_shell_side_arm`,
  `s_steel_roller`, `s_stuff_cheeks`, `s_super_duper_effective`,
  `s_syrup_bomb`, `s_tar_shot`, `s_teatime`, `s_terrain_pulse`,
  `s_tidy_up`, `s_triple_arrows` and `s_upper_hand`.
- Terrain damage promotion wave: `s_expanding_force`, `s_grassy_glide`,
  `s_rising_voltage` and `s_terrain_pulse` now use
  `TerrainPowerMoveBehavior` instead of generic Basic fallbacks. This ports
  the local singles slice for terrain-driven power changes, Terrain Pulse type
  changes and Grassy Glide priority under Grassy Terrain while keeping the
  methods `partial` for the remaining targeting/action-order edge cases.
- Freezy Frost promotion wave: `s_freezy_frost` now uses a dedicated static
  resolver instead of the generic Basic fallback. It keeps Basic damage and
  resets every alive battler's stat stages to neutral after a successful hit.
  It remains `partial` for exact PSDK messages and richer multi-battler event
  ordering.
- Scale Shot promotion wave: `s_scale_shot` now uses
  `MultiHitMoveBehavior.scaleShot` instead of the generic Basic fallback. It
  reuses PSDK 2-5 multi-hit selection, Skill Link and Loaded Dice hooks, then
  redirects stage mods to the user after successful damage. It remains
  `partial` for exact PSDK messages and richer multi-target ordering.
- Double Iron Bash promotion wave: `s_double_iron_bash` now uses
  `MultiHitMoveBehavior.doubleIronBash` instead of the generic Basic fallback.
  It executes two hits and ports the Minimize branch that bypasses accuracy and
  doubles base power. It remains `partial` for exact PSDK messages, flinch
  timing parity and richer multi-target ordering.
- Grav Apple promotion wave: `s_grav_apple` now uses a dedicated static
  resolver instead of the generic Basic fallback. It keeps Basic damage and
  imported secondary stat drops, then raises base power by 1.5x while Gravity
  is active. It remains `partial` for exact PSDK messages and the full Gravity
  field-effect lifecycle.
- Rage promotion wave: `s_rage` now uses a dedicated static resolver instead
  of the generic Basic fallback. It keeps the successful Basic hit and installs
  a battler-scoped `rage` marker on the user after a successful damage event.
  It remains `partial` until the full Rage attack-raise lifecycle and exact
  PSDK messages are represented.
- Raging Bull promotion wave: `s_raging_bull` now reuses the Brick Break static
  cleanup path instead of the generic Basic fallback. It keeps the successful
  hit and clears opposing `reflect`, `light_screen` and `aurora_veil` markers.
  It remains `partial` until Tauros form-based type changes and exact PSDK
  messages are represented.
- Spectral Thief promotion wave: `s_spectral_thief` now uses a dedicated
  static resolver instead of the generic Basic fallback. It keeps the
  successful hit, copies positive target stat stages to the user and clears
  those positive stages from the target. It remains `partial` until exact PSDK
  messages and multi-target ordering are represented.
- Make It Rain promotion wave: `s_make_it_rain` now uses a dedicated static
  resolver instead of the generic Basic fallback. It keeps the successful hit
  and applies imported stat-stage drops to the user, matching the PSDK
  `SelfStat` inheritance slice. It remains `partial` until battle-info money
  rewards and exact PSDK messages are represented.
- Magnitude promotion wave: `s_magnitude` now uses a dedicated static resolver
  instead of the generic Basic fallback. It samples the PSDK magnitude table
  from the generic RNG stream and uses the selected base power for damage. It
  remains `partial` until exact PSDK messages and the Dig/out-of-reach doubled
  damage branch are represented.
- Glaive Rush promotion wave: `s_glaive_rush` now uses a dedicated static
  resolver instead of the generic Basic fallback. It keeps the successful Basic
  hit, installs a battler-scoped `glaive_rush` marker and doubles incoming
  damage while the marker is active. It remains `partial` until exact PSDK
  messages and the full action-order cleanup semantics are represented.
- Fickle Beam promotion wave: `s_fickle_beam` now uses a dedicated static
  resolver instead of the generic Basic fallback. It consumes the generic RNG
  after prechecks/accuracy and doubles base power on PSDK's `bchance?(0.3)`
  empowerment roll. It remains `partial` until exact PSDK empowerment messages
  are represented.
- Super Duper Effective promotion wave: `s_super_duper_effective` now uses a
  dedicated static resolver instead of the generic Basic fallback. It keeps the
  regular Basic hit and applies PSDK's `5461 / 4096` damage boost when the raw
  type effectiveness is super effective. It remains `partial` until exact PSDK
  message/event timing and fuller damage-modifier hook ordering are represented.
- Genies Storm promotion wave: `s_genies_storm` now resolves through
  `WeatherPowerMoveBehavior.geniesStorm` instead of the generic Basic fallback.
  It bypasses accuracy under rain/hard rain while preserving weather
  suppression semantics. It remains `partial` until exact PSDK messages and
  richer weather/ability/item exceptions are represented.
- Eerie Spell promotion wave: `s_eerie_spell` now uses a dedicated static
  resolver instead of the generic Basic fallback. After a successful hit, it
  removes up to 3 PP from the target's last attempted move. It remains
  `partial` until exact PSDK messages and richer multi-target behavior are
  represented.
- Last Respects promotion wave: `s_last_respects` now uses a dedicated static
  resolver instead of the generic Basic fallback. It scales base power from the
  local clean-lane `koCount` snapshot with PSDK's `(ko_count + 1).clamp(1, 101)`
  formula shape. It remains `partial` until full party-side KO aggregation and
  exact PSDK messages are represented.
- Shell Side Arm promotion wave: `s_shell_side_arm` now uses a dedicated static
  resolver instead of the generic Basic fallback. It evaluates the physical and
  special damage lanes against the current target, applies local screen
  adjustment per lane and keeps physical only when it is strictly stronger,
  matching PSDK's tie-to-special branch. It remains `partial` until the physical
  lane's `direct?`/contact override is represented.
- Electro Shot promotion wave: `s_electro_shot` now uses a dedicated static
  resolver instead of the generic Basic fallback. It raises Special Attack on
  the charge turn, stores the local two-turn marker, releases on the next
  submission and shortcuts to same-turn damage under rain/hard rain. It remains
  `partial` until exact charge messages, forced-next-move metadata and fuller
  accuracy shortcut semantics are represented.
- Present promotion wave: `s_present` now uses a dedicated static resolver. It
  samples the PSDK 40/80/120/heal RNG table, routes damage branches through the
  normal calculator and heals the target by one quarter of max HP on the heal
  branch when the target is not full or locally Heal Blocked. It remains
  `partial` until exact messages and richer heal-block display semantics are
  represented.
- Triple Arrows promotion wave: `s_triple_arrows` now uses a dedicated static
  resolver instead of the generic Basic fallback. It keeps the Basic hit and
  installs a four-turn user-scoped `triple_arrows` marker after successful
  damage, skipping it when `dragon_cheer`, `focus_energy` or `triple_arrows`
  already exists on the user. The critical-hit calculator now consumes
  `triple_arrows`, `focus_energy`, `dragon_cheer` and `laser_focus` markers
  with PSDK's critical-count rules. It remains `partial` until exact messages
  are represented.
- History power promotion wave: `s_assurance`, `s_avalanche`,
  `s_fishious_rend`, `s_lash_out`, `s_payback`, `s_rage_fist`,
  `s_retaliate`, `s_revenge` and `s_stomping_tantrum` now use
  `HistoryPowerMoveBehavior` instead of
  generic Basic fallbacks. The local singles slice ports their PSDK
  damage/stat/move-history, same-bank previous-turn KO and action-order power
  rules while keeping the methods `partial` for richer source metadata,
  full party/reserve KO state and multi-battler edge-case parity.
- Type-based damage promotion wave: `s_ivy_cudgel`, `s_judgment`,
  `s_multi_attack` and `s_revelation_dance` now use `TypeBasedMoveBehavior`
  instead of generic Basic fallbacks. The local singles slice ports effective
  type selection from masks, plates, memories and the user's primary type.
  They remain `partial` for full item validation, suppression/ability hooks
  and Revelation Dance secondary-effect parity.
- Action-gated move promotion wave: `s_snore` and `s_sucker_punch` now use
  `ActionGatedMoveBehavior` instead of generic Basic fallbacks. The local
  singles slice ports Snore sleep/Comatose gating and Sucker Punch
  pending-action checks. They remain `partial` for full PSDK action-queue,
  doubles and Me First edge-case parity.
- Fake Out/flinch promotion wave: `s_fake_out` now uses
  `ActionGatedMoveBehavior.fakeOut` instead of a generic Basic fallback. The
  local singles slice ports the first-active-turn/Instruct gate and applies an
  object-backed `FlinchEffect` after a successful hit so a slower target is
  prevented before moving. It remains `partial` for message parity and
  secondary ability/item side effects such as Steadfast-style hooks.
- Feint/Protect-breaking promotion wave: `s_feint` now uses a dedicated static
  Feint path instead of a generic Basic fallback. The local singles slice keeps
  type-immunity checks while bypassing local Protect prevention, lifts
  `protect`/`crafty_shield` target markers after a successful hit, and uses
  the PSDK 50-power branch when the target successfully used Protect or Crafty
  Shield earlier in the same turn. It remains `partial` for message parity and
  richer Protect-variant coverage.
- Fell Stinger KO-boost promotion wave: `s_fell_stinger` now uses a dedicated
  static Fell Stinger path instead of a generic Basic fallback. The local
  singles slice keeps the normal Basic hit and raises the user's Attack by
  three stages when that hit leaves a target fainted. It remains `partial` for
  richer multi-target ordering and Moxie post-damage-death chaining.
- Stomp/Minimize promotion wave: `s_stomp` now uses a dedicated static Stomp
  path instead of a generic Basic fallback. The local singles slice doubles
  Stomp power and bypasses accuracy when the target carries the local
  `minimize` effect marker. It remains `partial` for fully object-backed
  Minimize effect parity and wider multi-target accuracy semantics.
- U-turn pivot promotion wave: `s_u_turn` now uses a dedicated static U-turn
  path instead of a generic Basic fallback. The local singles slice keeps the
  normal Basic hit and marks the user as switching after a successful damage
  hit. It remains `partial` for full reserve/switch-handler integration and
  Red Card, Eject Button and Emergency Exit ordering.
- High Jump Kick crash promotion wave: `s_jump_kick` now uses a dedicated
  static High Jump Kick path instead of a generic Basic fallback. The local
  singles slice keeps the normal Basic hit and applies half-max-HP crash
  damage to the user on accuracy, immunity or Protect-style failure. It
  remains `partial` for exact message and broader faint-process ordering.
- Terrain-clearing hit promotion wave: `s_ice_spinner` and `s_steel_roller`
  now use dedicated static terrain-clearing paths instead of generic Basic
  fallbacks. The local singles slice clears active terrain after a successful
  hit; `s_steel_roller` also fails before damage when no terrain is active.
  They remain `partial` for exact PSDK messages and richer terrain-effect
  hook ordering.
- Trap/item-gated Basic promotion wave: `s_jaw_lock` and `s_poltergeist` now
  use dedicated static paths instead of generic Basic fallbacks. The local
  singles slice installs mutual `CantSwitchEffect` for Jaw Lock after a
  successful hit and makes Poltergeist fail before damage when its target has
  no held item. They remain `partial` for exact PSDK reveal-item messages,
  multi-target display ordering and full switch-prevention cleanup semantics.
- Persistent-hit promotion wave: `s_sappy_seed` now uses a dedicated static
  path instead of a generic Basic fallback. The local singles slice keeps the
  Basic damage hit and applies `LeechSeedEffect` when the target can be seeded.
  It remains `partial` for exact PSDK messages, position-effect modelling and
  richer Substitute/ability interactions.
- Screen-setting hit promotion wave: `s_baddy_bad` and `s_glitzy_glow` now use
  dedicated static paths instead of generic Basic fallbacks. The local singles
  slice keeps their Basic damage hits and applies user-bank `reflect` or
  `light_screen` after successful damage, reusing the existing Light Clay
  duration convention. They remain `partial` for exact PSDK messages,
  richer bank-effect modelling and full screen ordering hooks.
- Weather-conditional move promotion wave: `s_thunder`, `s_hurricane` and
  `s_solar_beam` now use `WeatherPowerMoveBehavior` instead of generic Basic
  fallbacks. The local singles slice ports rain/sun accuracy overrides, Solar
  Beam charging outside sun, sunny shortcut and bad-weather power reduction.
  They remain `partial` for full weather suppression, ability and item edge
  cases.
- Consecutive-power promotion wave: `s_echo`, `s_fury_cutter`, `s_rollout`,
  `s_ice_ball` and `s_trump_card` now use `ConsecutivePowerMoveBehavior`
  instead of generic Basic fallbacks. The local singles slice ports repeated
  successful-move power scaling and Trump Card remaining-PP power. They remain
  `partial` for full field Echoed Voice effects, Rollout/Ice Ball lock-in,
  Defense Curl coupling and interruption hooks.
- Counter-damage promotion wave: `s_counter`, `s_mirror_coat`,
  `s_metal_burst` and `s_bide` now use `CounterDamageMoveBehavior` instead of
  marker fallbacks. The local singles slice ports direct retaliation from
  current-turn or stored damage history. They remain `partial` for damage
  category filters, Bide forced-turn timing and exact retaliation target parity.
- Item-dependent promotion wave: `s_belch`, `s_bestow`, `s_fling`,
  `s_knock_off`, `s_natural_gift`, `s_pluck`, `s_recycle`,
  `s_techno_blast` and `s_thief` now use `ItemDependentMoveBehavior` instead
  of generic Basic/marker fallbacks. The local singles slice ports the
  immediately testable PSDK behavior for held/consumed item gating, item
  transfer/removal, Fling/Natural Gift item power and Techno Blast Drive type.
  They remain `partial` for full item catalog coverage, Berry/Fling effects,
  PSDK item-loss restrictions and trainer/wild persistence.
- Forced-action lock-in wave: `s_gigaton_hammer`, `s_thrash`, `s_outrage` and
  `s_uproar` now use `ForcedActionMoveBehavior` instead of generic Basic
  fallbacks. The local slice ports Gigaton Hammer's previous-move selection
  gate, Thrash/Outrage lock-in with confusion on release, and Uproar's local
  timed marker. They remain `partial` for automatic forced-action selection,
  doubles retargeting, Uproar sleep prevention and exact failure cleanup.
- Field/location wave: `s_camouflage`, `s_nature_power`, `s_pledge`,
  `s_secret_power` and `s_synchronoise` now use
  `FieldLocationMoveBehavior`. The local singles slice ports active-terrain
  defaults for Camouflage/Nature Power/Secret Power, Synchronoise shared-type
  gating and a dedicated Pledge damage path. They remain `partial` for
  map-biome locations, multi-target Synchronoise and Pledge combo
  ordering/effects.
- Special-secondary wave: `s_alluring_voice`, `s_burning_jealousy`,
  `s_burn_up`, `s_incinerate`, `s_psychic_noise`, `s_relic_song`,
  `s_salt_cure`, `s_syrup_bomb`, `s_tar_shot`, `s_throat_chop` and
  `s_tri_attack` now use `SpecialSecondaryMoveBehavior` instead of generic
  Basic/marker fallbacks. The local singles slice ports Tri Attack random
  major status, stat-history-gated Alluring Voice/Burning Jealousy, Psychic
  Noise Heal Block, Throat Chop's sound-move prevention, Burn Up type
  gating/removal, Incinerate berry/gem removal, Salt Cure residual damage,
  Syrup Bomb timed Speed drops and Tar Shot's fire-weakness multiplier. They
  remain `partial` for disabled-move UI/messages, ally-side Aroma Veil, exact
  PSDK item-loss checks, Burn Up cleanup semantics, exact Syrup Bomb
  lifecycle/messages and Relic Song Meloetta form calibration.
- Grounding wave: `s_smack_down` now uses `GroundingMoveBehavior` instead of
  a generic Basic fallback. The local singles slice keeps its Rock hit,
  installs object-backed `SmackDownEffect` on airborne targets and lets later
  Ground moves hit Flying targets through the local type-effectiveness
  override. It remains `partial` for full flying-effect cleanup,
  Substitute/Authenic checks and Sky Drop/out-of-reach exceptions.
- Added targeted behavior tests in
  `packages/map_battle/test/psdk_move_families/high_leverage_missing_moves_test.dart`.
- Regenerated `reports/previous/psdk-move-porting-matrix.md` and
  `reports/previous/psdk-attack-coverage.md`.
- Remaining limitations in this wave: Fang flinch choice, OHKO level accuracy
  and Sheer Cold Ice immunity, Heal Bell party reserves/Soundproof, and full
  multi-target process hooks. The Basic-descendant wave still needs Bind/Cant
  Switch effects and Brick Break wall removal.
  The latest Basic wave still needs Pledge combo fields,
  Thunder/Hurricane weather accuracy and Thrash/Outrage lock-in/confusion.
  The newest fallback wave still needs force-switch requests,
  Round ordering/power combo,
  Secret Power location effects, Synchronoise shared-type filtering and Uproar
  lock-in.
  The recharge/screen/attention wave still needs full PSDK forced-action
  history, screen reduction in every non-Basic damage behavior, doubles 2/3
  screen multiplier, full Aurora Veil weather edge cases, double-battle target
  redirection and competing Follow Me/Rage Powder rules.
  The two-turn wave still needs Power Herb, weather shortcuts, out-of-reach
  targeting/immunity, first-turn stat boosts, forced second-turn action, and
  spread targeting for moves such as Razor Wind.
  The state-marker/item/Z wave still needs item-change handler restrictions,
  full Z-Crystal/once-per-battle validation, exact Sport marker lifecycle and
  richer type-change cleanup.
  The marker wave still needs actual end-turn/switch-in/action-order hooks:
  Yawn sleep application, Future Sight delayed damage, Wish healing, Tailwind
  and Trick Room speed-order changes, Safeguard status prevention, hazard
  switch-in effects, and Wonder Room stat swapping.
  The ability/type wave still needs full PSDK AbilityChangeHandler guards,
  forbidden abilities/species, ability-change events and Reflect Type failure
  checks.
  The newest marker/secondary wave still needs the full effect hooks:
  Perish Song end-turn fainting and Baton Pass transfer, richer Telekinesis
  out-of-reach/target guards, and exact Mist/Telekinesis/Toxic Thread/Ion
  Deluge cleanup messages. Toxic Thread target blocking when both status and
  stat drop fail is now covered.
  The turn-marker wave still needs method-specific hooks: Destiny Bond KO
  retaliation, Disable/Encore move-history selection and move prevention,
  broader Embargo item prevention and Baton Pass transfer, Grudge PP depletion
  on user death, Heal Block move prevention, Powder fire-move
  interruption/damage, and Snatch status-move interception. Magnet Rise
  force-flying and the first Embargo held-item grounding slice are now covered.
  The newest Basic fallback wave still needs method-specific hooks such as
  Flame Burst adjacent damage, Fury Cutter/Rage counters, Fusion combo power,
  Hidden Power/Judgment type resolution, Knock Off item mutation,
  Last Resort move-history gating, Photon Geyser stat source selection,
  Pollen Puff ally healing, Pursuit switch interception, Rapid Spin speed
  boost, Relic Song form hooks and Spectral Thief stat
  stealing.
  The marker/secondary status wave still needs Autotomize weight restoration
  on effect removal and Gastro Acid ability-change guards.
  The mixed fallback wave still needs Assurance/Core Enforcer action-history
  checks, Belch berry-consumption validation, Beak Blast/Focus Punch/Shell
  Trap pre-attack interruption hooks, Flying Press dual-type damage,
  Multi-Attack held-memory typing, Sky Drop out-of-reach target effects,
  Substitute damage interception/Baton Pass transfer, Attract gender/Destiny
  Knot rules, Nightmare sleep-only end-turn damage, Quash action-order
  rewrites, Gravity grounding/accuracy hooks, Happy Hour payout integration
  and Magic Room item suppression.
  The type/order/status wave still needs ChangeType ability/substitute failure
  checks and effect cleanup, Stockpile's three-stack counter with Swallow/Spit
  Up coupling, After You/Ally Switch doubles action-order logic, Magic Coat
  reflection hooks, Crafty Shield status protection, Captivate gender/Oblivious
  checks and Parting Shot's switch request.
  The focus/history wave still needs Lock-On/Mind Reader accuracy bypass with
  target identity, Entrainment ability-change guards, Memento's failure branch
  when target stat drops cannot apply, Struggle typeless damage and no-PP
  forced-action integration.
  The move-prevention effect wave still needs move-disabled UI checks,
  deletion messages and equivalent object-backed effects for Torment, Disable,
  Encore, Heal Block, Imprison and Attract.
  The broad missing-method fallback wave still needs method-specific PSDK
  behavior, especially random move selection/copying (`Assist`, `Metronome`,
  `Mirror Move`, `Sleep Talk`, `Nature Power`), item transfer/consumption
  (`Bestow`, `Fling`, `Recycle`, `Natural Gift`), type conversion
  (`Conversion`, `Conversion2`, `Camouflage`), team-member/party inspection
  (`Beat Up`, `Healing Wish`, `Lunar Dance`), friendship/random-power
  formulas (`Return`, `Frustration`, `Magnitude`, `Present`), reactive damage
  history (`Bide`, `Counter`, `Metal Burst`, `Mirror Coat`), PP/move mutation
  (`Mimic`, `Sketch`, `Spite`, `Instruct`) and battle-context markers such as
  `Flower Shield`, `Gear Up`, `Helping Hand`, `Magnetic Flux`, `Rototiller`,
  `Swallow`, `Venom Drench` and the Studio-only Z/Special attack methods.
  The Ruby-only missing-method fallback wave still needs many method-specific
  hooks before it can be promoted beyond `partial`: move-history power or
  restrictions (`Fishious Rend`, `Gigaton Hammer`, `Glaive Rush`, `Lash Out`,
  `Last Respects`, `Upper Hand`), multi-hit or multi-target
  rules (`Dragon Darts`), item/berry
  interactions (`Poltergeist`, `Corrosive Gas`, `Stuff Cheeks`, `Teatime`),
  side/field swaps or cleanup (`Court Change`, `Fairy Lock`, `Tidy Up`),
  weather/two-turn/switch behavior (`Chilly Reception`, `Electro Shot`,
  `Geomancy`, `Shed Tail`), ability/type/stat mutation (`Doodle`,
  `Dragon Cheer`, `Magic Powder`, `No Retreat`, `Octolock`) and
  modern signature-move effects (`Sappy Seed`, `Raging Bull`,
  `Glitzy Glow`, `Baddy Bad`, `Ivy Cudgel`, `Shell Side Arm`, `Order Up`,
  `Make It Rain`, `Revival Blessing`).
  The terrain damage promotion wave still needs Expanding Force doubles spread
  targeting, full PSDK `grounded?` effect parity and broader action-order
  interactions around priority blockers.
  The history power promotion wave still needs damage-source category metadata
  and exact PSDK history filtering; current Dart history is sufficient for the
  local singles power slice but not for every residual, ability, item or
  multi-target damage path.

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
- Added `PsdkBattleVolatileStatus.confusion` and a `PsdkBattleMoveStatus`
  volatile constructor so PSDK move data can apply `CONFUSED` directly through
  `s_status`. The CLI `confusion` scenario now goes through a `confuse_ray`
  move status before the slower target self-hits.

Still remaining in this lot:

- Add explicit deletion/switch-out lifecycle hooks for effects that need PSDK
  cleanup behavior beyond Baton Pass transfer.
- Port `Substitute` and any remaining PSDK edge case tied to copied/deleted
  volatile effects. `Confusion` is intentionally not treated as Baton Pass
  transferable here because the inspected PSDK `Confusion.rb` file does not
  expose a Baton Pass transfer override.
- Finish the outer Studio/runtime catalog bridge for `CONFUSED`
  (`Confuse Ray`, `Supersonic`, etc.) if the source enters the engine through
  `map_core`/runtime models instead of direct `PsdkBattleMoveData`.
- Complete immunity/cure interactions such as Own Tempo/Persim-style behavior.
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

Status: in progress in `valuer-pokmon-sdk-combat`.

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

Current slice:

- `s_spikes`, `s_stealth_rock`, `s_toxic_spikes` and `s_sticky_web` install
  object-backed bank-scoped hazard effects.
- Spikes and Toxic Spikes persist PSDK layer counts and fail when their layer
  cap is already reached.
- `s_stone_axe` and `s_ceaseless_edge` keep their Basic hit and install or
  empower Stealth Rock/Spikes after a successful hit.
- `s_rapid_spin` clears user-local rapid-spin-affected effects and own-bank
  hazard markers after a successful Basic hit.
- `s_defog` clears rapid-spin hazard markers across banks and opposing screen
  markers while preserving its imported secondary stat drop path.
- `s_brick_break` clears opposing Reflect/Light Screen/Aurora Veil markers
  after a successful Basic hit.
- `BattleSwitchHandler.applyEntryHazards` applies one-layer bank hazard
  effects on entry: layered Spikes damage grounded entrants, Stealth Rock deals
  Rock-type effectiveness-scaled damage, layered Toxic Spikes poisons or badly
  poisons grounded entrants and is absorbed by grounded Poison types, and
  Sticky Web drops grounded entrant Speed.
- Heavy-Duty Boots prevents all entry-hazard effects for the entrant.
- Magic Guard prevents Spikes and Stealth Rock entry damage while leaving Toxic
  Spikes status and Sticky Web stat changes active.

Remaining limitations:

- The hook is available on `BattleSwitchHandler`, but the clean PSDK setup still
  needs richer reserve/switch integration before forced/pivot switch flows can
  call it automatically.

## Lot PSDK-PARITY-05 - Move Prevention Effects

Status: in progress in `valuer-pokmon-sdk-combat`.

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

Done so far:

- Added object-backed `TauntEffect`.
- `TauntEffect` blocks status moves through the existing
  `onUserMovePrevention` hook and allows damaging moves.
- `s_taunt` still installs through the existing target-marker path, but now
  receives an active effect object instead of a passive generic marker.
- Added object-backed `TormentEffect`.
- `TormentEffect` blocks repeating the last successful non-Struggle move and
  allows different moves or Struggle.
- `s_torment` still installs through the existing target-marker path, but now
  receives an active effect object instead of a passive generic marker.
- Added object-backed `DisableEffect`.
- `DisableEffect` blocks the affected battler's last successful non-Struggle
  move through the existing `onUserMovePrevention` hook.
- `s_disable` now installs a history-bound active effect object instead of a
  passive generic marker.
- Added object-backed `EncoreEffect`.
- `EncoreEffect` blocks choosing a different move than the encored last
  successful move and allows Struggle as an escape path.
- `s_encore` now installs a history-bound active effect object instead of a
  passive generic marker.
- Added object-backed `HealBlockEffect`.
- `HealBlockEffect` blocks the local healing methods currently modeled in the
  Dart registry through the existing `onUserMovePrevention` hook.
- `s_heal_block` now installs an active timed effect object instead of a
  passive generic marker.
- Added object-backed `AttractEffect`.
- `AttractEffect` performs the PSDK 50% user-prevention roll against the
  attracting battler.
- `s_attract` now installs an active effect object bound to the move user.
- Added object-backed `ImprisonEffect`.
- `ImprisonEffect` blocks shared foe move ids through the existing
  `onUserMovePrevention` hook.
- `s_imprison` now installs an active effect object carrying the user's move
  ids.
- Updated the generated effect matrix: `Taunt`, `Torment`, `Disable`,
  `Encore`, `HealBlock`, `Attract` and `Imprison` are now
  `partial`.

Still remaining in this lot:

- Move-disabled UI checks/deletion messages and richer PSDK failure branches.
- Full PP forcing, UI selection forcing and deletion messages for
  Disable/Encore/Torment.
- Full Attract gender immunity, Oblivious/Aroma Veil, Destiny Knot mirroring
  and delete messages.
- Global PSDK effect dispatch for Imprison so the effect can live on the user
  instead of the current target-local bridge.
- Studio heal flags, messages and item/ability exceptions for HealBlock.

## Lot PSDK-PARITY-06 - Trapping And Switch Prevention

Purpose: implement effects that prevent voluntary switch and force switches.

Progress:

- `s_cantflee` now has a dedicated resolver instead of the generic Basic
  fallback.
- `s_bind` now has a dedicated resolver instead of the generic Basic fallback.
- `CantSwitchEffect` is object-backed, blocks regular switch attempts through
  `BattleSwitchHandler`, transfers through Baton Pass and stops blocking when
  its origin fainted.
- `BindEffect` is object-backed, blocks regular switch attempts, applies
  residual end-turn damage, honors Magic Guard, Grip Claw and Binding Band, and
  stops blocking when its origin fainted.
- `ShadowTag`, `ArenaTrap` and `MagnetPull` now prevent valid opposing switch
  attempts through active ability-effect dispatch.
- `s_dragon_tail` and `s_roar` now mark the target as switching after a
  successful move resolution. Full bench replacement is still blocked by the
  current `PsdkBattleSetup.singles` shape, which has no reserve list.

Still open:

- Rapid Spin cleanup and delete-message parity for `BindEffect`.
- Full bench replacement for forced-switch moves once PSDK setup carries
  reserves.
- `s_whirlwind` if/when a Studio move maps to the same force-switch method.
- Pivot switch behavior for `s_parting_shot`, `s_flip_turn` and `s_uturn`.
- Force-switch move exceptions and message parity for Shadow Tag/Arena
  Trap/Magnet Pull.

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

- Port `s_counter`, `s_mirror_coat`, `s_metal_burst` and `s_bide`.
- Extend damage history with source move category, KO/faint-party metadata and
  full multi-battler turn timing. `s_assurance`, `s_avalanche`,
  `s_fishious_rend`, `s_lash_out`, `s_payback`, `s_rage_fist`,
  `s_retaliate`, `s_revenge` and `s_stomping_tantrum` already have local
  singles power slices, but still depend on richer history metadata for
  complete PSDK parity.

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
- `packages/map_battle/lib/src/domain/move/behaviors/item_dependent_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/item_dependent_moves_test.dart`

Logic:

- Already locally sliced: `s_knock_off`, `s_bestow`, `s_fling`,
  `s_recycle`, `s_belch`, `s_pluck`, `s_thief`, `s_natural_gift` and
  `s_techno_blast`.
- Remaining parity work: `s_switcheroo`, `s_embargo`, `s_magic_room`,
  `s_corrosive_gas`, full item catalog metadata, item-loss restrictions,
  Berry/Fling rider effects and trainer/wild item persistence.

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
