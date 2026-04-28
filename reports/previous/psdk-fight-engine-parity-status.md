# PSDK Fight Engine Parity Status

Date: 2026-04-28

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
| Studio attacks unknown_methods | 0 |

This status file is intentionally small. The source of truth for detailed rows
is still:

- `reports/previous/psdk-move-porting-matrix.md`
- `reports/previous/psdk-effect-porting-matrix.md`
- `reports/previous/psdk-attack-coverage.md`

Latest completed move wave:

- `s_a_fang` -> `BasicDamageSpecializationMoveBehavior.fangs` (`partial`)
- `s_ohko` -> `OhkoMoveBehavior` (`partial`)
- `s_sacred_sword` -> `CustomStatSourceMoveBehavior.sacredSword` (`partial`)
- `s_heal_bell` -> `StatusCureMoveBehavior.healBell` (`partial`)
- `s_take_heart` -> `StatusCureMoveBehavior.takeHeart` (`partial`)
- `s_sparkly_swirl` -> `StatusCureMoveBehavior.sparklySwirl` (`partial`)
- `s_brick_break` ->
  `StaticBasicMoveRegistry.partialBasic(...)`
  (`partial`)
- `s_bind` now resolves through a dedicated Bind path that installs timed
  trapping, blocks switch-out and applies residual end-turn damage (`partial`)
- `s_cantflee` now resolves through a dedicated CantSwitch path that installs
  object-backed switch prevention on the target (`partial`)
- Ability trapping wave: `ShadowTag`, `ArenaTrap` and `MagnetPull` are now
  object-backed switch-prevention effects (`partial`)
- `s_dragon_tail` and `s_roar` now resolve through a dedicated force-switch
  marker path that marks the target as switching after a successful move
  resolution (`partial`)
- `s_outrage`, `s_pledge`, `s_psychic_noise`,
  `s_thrash`, `s_throat_chop`, `s_tri_attack` ->
  `StaticBasicMoveRegistry.partialBasic(...)` (`partial`)
- `s_dragon_tail`, `s_ice_ball`, `s_revenge`,
  `s_roar`, `s_rollout`, `s_round`, `s_secret_power`, `s_synchronoise`,
  `s_trump_card`, `s_uproar` ->
  `StaticBasicMoveRegistry.partialBasic(...)` (`partial`)
- `s_snore` and `s_sucker_punch` now resolve through
  `ActionGatedMoveBehavior`, adding their local PSDK pre-PP user gates while
  preserving Basic damage resolution (`partial`)
- `s_fake_out` now resolves through `ActionGatedMoveBehavior.fakeOut`, fails
  before PP after the user's first active turn or under local Instruct, keeps
  its Basic hit and installs object-backed `FlinchEffect` on a successful hit
  so a slower target loses its same-turn action (`partial`)
- `s_feint` now resolves through a dedicated static Feint path, keeps type
  immunity checks, bypasses/lifts local Protect/Crafty Shield markers and uses
  its increased 50-power slice after same-turn Protect or Crafty Shield
  success (`partial`)
- `s_fell_stinger` now resolves through a dedicated static Fell Stinger path:
  it keeps its Basic hit and raises the user's Attack by three stages when
  that hit leaves at least one target fainted (`partial`)
- `s_stomp` now resolves through a dedicated static Stomp path: it doubles
  local power and bypasses accuracy when the target carries the `minimize`
  effect marker (`partial`)
- `s_u_turn` now resolves through a dedicated static U-turn path: it keeps
  its Basic hit and marks the user as switching after a successful damage hit
  (`partial`)
- `s_jump_kick` now resolves through a dedicated static High Jump Kick path:
  it keeps the Basic hit and applies half-max-HP crash damage to the user on
  accuracy, immunity or Protect-style failure (`partial`)
- `s_ice_spinner` and `s_steel_roller` now resolve through dedicated static
  terrain-clearing hit paths: both clear active terrain after a successful hit,
  and Steel Roller fails before damage if no terrain is active (`partial`)
- `s_reload` now deals damage and installs a one-turn
  `force_next_move_base` recharge prevention effect (`partial`)
- `s_reflect` now installs timed local screen markers for Reflect,
  Light Screen and Aurora Veil, refuses duplicate screens, requires snow/hail
  for Aurora Veil, honors Light Clay duration, applies local screen damage
  reduction for Basic physical/special hits and lets Infiltrator bypass that
  reduction (`partial`)
- `s_follow_me` now executes as a turn-scoped center-of-attention marker
  (`partial`)
- `s_2turns` now charges on the first turn and releases its Basic hit on the
  next submission (`partial`)
- `s_foresight`, `s_add_type`, `s_thing_sport` and `s_trick` now execute their
  local state mutation paths (`partial`)
- Studio-only offensive `s_z_move` entries now execute through the Basic damage
  path and are tracked as partial in the attack coverage report
- Marker wave: `s_yawn`, `s_taunt`, `s_torment`, `s_future_sight`,
  `s_wish`, `s_tailwind`, `s_safe_guard`, `s_spike`, `s_stealth_rock`,
  `s_sticky_web`, `s_toxic_spike`, `s_trick_room` and `s_wonder_room`
  now install local PSDK effect markers (`partial`)
- Ability/type wave: `s_simple_beam`, `s_worry_seed`, `s_role_play`,
  `s_skill_swap` and `s_reflect_type` now mutate local ability/type state
  (`partial`)
- Marker/secondary wave: `s_minimize`, `s_miracle_eye`, `s_mist`,
  `s_perish_song`, `s_telekinesis`, `s_toxic_thread` and `s_plasma_fists`
  now execute their local marker, secondary-status/stat or Basic+Ion Deluge
  paths (`partial`)
- Turn-marker wave: `s_destiny_bond`, `s_disable`, `s_electrify`,
  `s_embargo`, `s_encore`, `s_grudge`, `s_heal_block`, `s_ion_deluge`,
  `s_lucky_chant`, `s_magnet_rise`, `s_powder` and `s_snatch` now execute
  through local PSDK marker paths (`partial`)
- Basic fallback wave: `s_burn_up`,
  `s_flame_burst`, `s_fury_cutter`, `s_fusion_bolt`,
  `s_fusion_flare`, `s_hidden_power`, `s_incinerate`,
  `s_last_resort`, `s_payday`,
  `s_photon_geyser`, `s_pollen_puff`, `s_pursuit`, `s_rage`,
  `s_rapid_spin`, `s_relic_song` and `s_spectral_thief` now execute their
  local Basic damage path (`partial`)
- Marker/secondary status wave: `s_focus_energy`, `s_laser_focus`,
  `s_charge`, `s_autotomize`, `s_gastro_acid` and `s_defog` now execute
  through local marker or secondary-only state paths (`partial`)
- Mixed fallback wave: `s_beak_blast`, `s_core_enforcer`,
  `s_flying_press`, `s_focus_punch`
  and `s_shell_trap` now execute their local Basic damage path; `s_sky_drop`
  uses the local two-turn path; `s_substitute` spends user HP and installs a
  local substitute marker; `s_attract`, `s_imprison`, `s_nightmare`,
  `s_quash`, `s_gravity`, `s_happy_hour` and `s_magic_room` now install local
  marker paths (`partial`)
- Type/order/status wave: `s_change_type` now replaces the target visible
  types and adds a local change-type marker; `s_stockpile` now marks the user
  and raises Defense/Special Defense; `s_after_you`, `s_ally_switch`,
  `s_magic_coat` and `s_crafty_shield` now execute as turn-scoped marker
  slices; `s_captivate` and `s_parting_shot` now execute through the
  secondary-only stat path (`partial`)
- Focus/history wave: `s_struggle` now uses the local recoil path with recoil
  from user max HP; `s_lock_on` and `s_mind_reader` install a local Lock-On
  marker on the user; `s_entrainment` copies the user's ability to the target;
  `s_memento` applies imported offensive drops and knocks out the user
  (`partial`)
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
  and blocks shared foe move ids (`partial`)
- Hazard cleanup wave: `s_rapid_spin` now resolves through a dedicated
  Rapid Spin path that keeps its Basic hit and clears user-local
  rapid-spin-affected effects plus own-bank hazards; `s_defog` now resolves
  through a dedicated Defog path that keeps imported secondary drops and clears
  rapid-spin hazards plus opposing screen markers; `s_brick_break` now keeps
  its Basic hit and clears opposing screen markers after a successful hit;
  Spikes, Toxic Spikes, Stealth Rock and Sticky Web are now object-backed bank
  hazard effects; Spikes and Toxic Spikes persist PSDK layer counts;
  `BattleSwitchHandler.applyEntryHazards` now applies layered Spikes damage,
  layered Toxic Spikes poison/bad poison plus grounded Poison absorption,
  Stealth Rock Rock-effectiveness damage and Sticky Web Speed drops on entry;
  Heavy-Duty Boots prevents all local entry-hazard effects and Magic Guard
  prevents Spikes/Stealth Rock entry damage;
  `s_stone_axe` and `s_ceaseless_edge` now keep their Basic hit and install or
  empower their matching entry hazard after a successful hit (`partial`)
- Broad missing-method fallback wave: the remaining Studio-facing
  `pas_fait` methods now execute through explicit partial fallbacks instead of
  failing at runtime. Basic-style methods include `s_beat_up`, `s_echo`,
  `s_frustration`, `s_magnitude`, `s_present`, `s_return`,
  `s_split_up` and Studio-only Z/Special methods such as
  `s_genesis_supernova`, `s_guardian_of_alola`, `s_hyperspace_hole`,
  `s_light_that_burns_the_sky`, `s_malicious_moonsault` and
  `s_splintered_stormshards`. Marker/secondary methods include `s_assist`,
  `s_bide`, `s_camouflage`, `s_conversion`, `s_conversion2`,
  `s_counter`, `s_healing_wish`, `s_instruct`, `s_lunar_dance`,
  `s_me_first`, `s_metal_burst`, `s_metronome`, `s_mimic`,
  `s_mirror_coat`, `s_mirror_move`, `s_nature_power`,
  `s_sketch`, `s_sleep_talk`, `s_spite`, `s_swallow`, `s_teleport`,
  `s_venom_drench` and user-bank marker methods `s_flower_shield`,
  `s_gear_up`, `s_helping_hand`, `s_magnetic_flux`, `s_rototiller`.
  This moves the Studio attack coverage to `pas_fait = 0` while preserving
  `partial` status until method-specific PSDK behavior is implemented.
- Ruby-only missing-method fallback wave: the 56 remaining registered PSDK
  Ruby methods that are not required by the current Studio attack coverage now
  resolve to explicit `partial` behaviors instead of `TODO` in the move
  matrix. This includes offensive Basic fallbacks such as `s_alluring_voice`,
  `s_aura_wheel`, `s_dragon_darts`,
  `s_electro_shot`, `s_expanding_force`, `s_fickle_beam`,
  `s_gigaton_hammer`, `s_glaive_rush`,
  `s_grassy_glide`, `s_last_respects`,
  `s_rage_fist`, `s_raging_bull`,
  `s_terrain_pulse`, `s_triple_arrows` and
  `s_upper_hand`, plus marker fallbacks such as `s_chilly_reception`,
  `s_court_change`, `s_doodle`, `s_dragon_cheer`, `s_fairy_lock`,
  `s_geomancy`, `s_magic_powder`, `s_no_retreat`, `s_octolock`,
  `s_revival_blessing`, `s_shed_tail`, `s_stuff_cheeks`, `s_tar_shot`,
  `s_teatime` and `s_tidy_up`. The move-method matrix is now
  `missing = 0`; this is runtime/extraction coverage, not full battle-rule
  parity.
- Terrain damage promotion wave: `s_expanding_force`, `s_grassy_glide`,
  `s_rising_voltage` and `s_terrain_pulse` now resolve through
  `TerrainPowerMoveBehavior` instead of generic Basic fallbacks. The local
  singles slice covers PSDK terrain power changes, Terrain Pulse type changes
  and Grassy Glide priority when the user is grounded on Grassy Terrain. These
  methods remain `partial` until Expanding Force spread targeting and the full
  PSDK action/grounding edge cases are ported.
- Freezy Frost promotion wave: `s_freezy_frost` now resolves through a
  dedicated static path instead of the generic Basic fallback. The local
  singles slice covers the PSDK hit-then-reset behavior by resetting stat
  stages to neutral for every alive battler after a successful damage hit.
  The method remains `partial` until exact PSDK messages and multi-battler
  event ordering are ported.
- Scale Shot promotion wave: `s_scale_shot` now resolves through
  `MultiHitMoveBehavior.scaleShot` instead of the generic Basic fallback. The
  local singles slice covers PSDK 2-5 hit selection, Skill Link forced five
  hits, Loaded Dice minimum hit count, and redirecting the move's stage mods to
  the user so Defense drops and Speed rises after successful damage.
  The method remains `partial` until exact PSDK messages and richer
  multi-target ordering are ported.
- Double Iron Bash promotion wave: `s_double_iron_bash` now resolves through
  `MultiHitMoveBehavior.doubleIronBash` instead of the generic Basic fallback.
  The local singles slice covers its PSDK `TwoHit` inheritance plus the
  Minimize branch that bypasses accuracy and doubles base power. The method
  remains `partial` until exact PSDK messages, flinch timing parity and richer
  multi-target ordering are ported.
- Grav Apple promotion wave: `s_grav_apple` now resolves through a dedicated
  static path instead of the generic Basic fallback. The local singles slice
  covers the PSDK Gravity power branch while preserving imported secondary
  Defense drops. The method remains `partial` until exact PSDK messages and
  the full Gravity field-effect lifecycle are ported.
- Rage promotion wave: `s_rage` now resolves through a dedicated static path
  instead of the generic Basic fallback. The local singles slice covers the
  successful Basic hit and battler-scoped `rage` marker installation on the
  user. The method remains `partial` until the full Rage attack-raise lifecycle
  and exact PSDK messages are ported.
- Raging Bull promotion wave: `s_raging_bull` now resolves through the Brick
  Break static cleanup path instead of the generic Basic fallback. The local
  singles slice covers the successful hit and opposing screen cleanup inherited
  from PSDK `BrickBreak`. The method remains `partial` until Tauros form-based
  type changes and exact PSDK messages are ported.
- Spectral Thief promotion wave: `s_spectral_thief` now resolves through a
  dedicated static path instead of the generic Basic fallback. The local
  singles slice covers successful-hit damage plus positive target stat-stage
  theft. The method remains `partial` until exact PSDK messages and
  multi-target ordering are ported.
- Make It Rain promotion wave: `s_make_it_rain` now resolves through a
  dedicated static path instead of the generic Basic fallback. The local
  singles slice covers successful-hit damage plus imported self stat drops from
  PSDK `SelfStat`. The method remains `partial` until battle-info money rewards
  and exact PSDK messages are ported.
- Magnitude promotion wave: `s_magnitude` now resolves through a dedicated
  static path instead of the generic Basic fallback. The local singles slice
  covers generic-RNG selection of the PSDK magnitude table and uses the selected
  base power for damage. The method remains `partial` until exact PSDK messages
  and the Dig/out-of-reach doubled damage branch are ported.
- History power promotion wave: `s_assurance`, `s_avalanche`,
  `s_fishious_rend`, `s_lash_out`, `s_payback`, `s_rage_fist`,
  `s_retaliate`, `s_revenge` and `s_stomping_tantrum` now resolve through
  `HistoryPowerMoveBehavior` instead of generic Basic fallbacks. The local
  singles slice reads PSDK damage, stat and move histories plus current-turn
  action order to apply their conditional power rules. Retaliate additionally
  scans same-bank combatants for a previous-turn KO in local damage history.
  These methods remain `partial` until the history records can distinguish
  every PSDK damage source/category, full party/reserve KO state and all
  multi-battler action-order edge cases are ported.
- Type-based damage promotion wave: `s_ivy_cudgel`, `s_judgment`,
  `s_multi_attack` and `s_revelation_dance` now resolve through
  `TypeBasedMoveBehavior` instead of generic Basic fallbacks. The local slice
  ports PSDK effective move type selection from held masks/plates/memories or
  from the user's primary type. These methods remain `partial` until item
  validation, suppression/ability hooks and Revelation Dance secondary effect
  parity are complete.
- Action-gated move promotion wave: `s_snore` now fails before PP unless the
  user is asleep or has `comatose`; `s_sucker_punch` now fails before PP
  against status-only pending target moves or targets that already attempted an
  action this turn. These methods remain `partial` until the clean move context
  exposes full PSDK action-queue metadata for doubles and Me First edge cases.
- Weather-conditional move promotion wave: `s_thunder`, `s_hurricane` and
  `s_solar_beam` now resolve through `WeatherPowerMoveBehavior` instead of
  generic Basic fallbacks. The local slice ports rain/sun accuracy overrides,
  Solar Beam sunny shortcut, two-turn charging outside sun and reduced release
  power under rain, sandstorm, hail or snow. These methods remain `partial`
  until full PSDK weather/ability/item exceptions are ported.
- Consecutive-power promotion wave: `s_echo`, `s_fury_cutter`, `s_rollout`,
  `s_ice_ball` and `s_trump_card` now resolve through
  `ConsecutivePowerMoveBehavior` instead of generic Basic fallbacks. The local
  slice ports move-history power scaling and Trump Card PP-based power. These
  methods remain `partial` until full field Echoed Voice effects, Rollout/Ice
  Ball lock-in, Defense Curl coupling and interruption hooks are ported.
- Counter-damage promotion wave: `s_counter`, `s_mirror_coat`,
  `s_metal_burst` and `s_bide` now resolve through
  `CounterDamageMoveBehavior` instead of marker fallbacks. The local slice
  ports current-turn/stored direct damage retaliation. These methods remain
  `partial` until incoming damage category, exact selected retaliation target,
  Bide lock-in/release timing and failure hooks are fully represented.
- Item-dependent promotion wave: `s_belch`, `s_bestow`, `s_fling`,
  `s_knock_off`, `s_natural_gift`, `s_pluck`, `s_recycle`,
  `s_techno_blast` and `s_thief` now resolve through
  `ItemDependentMoveBehavior` instead of generic Basic/marker fallbacks. The
  local singles slice ports held/consumed item gating, item transfer/removal,
  Fling/Natural Gift power tables and Techno Blast Drive typing. These methods
  remain `partial` until the full PSDK item catalog, Berry/Fling item effects,
  item-loss restrictions and trainer/wild persistence rules are ported.
- Forced-action lock-in wave: `s_gigaton_hammer`, `s_thrash`, `s_outrage` and
  `s_uproar` now resolve through `ForcedActionMoveBehavior` instead of generic
  Basic fallbacks. The local slice ports Gigaton Hammer's previous-move gate,
  Thrash/Outrage repeated-move lock-in with confusion on release, and Uproar's
  local timed marker. They remain `partial` until automatic forced-action
  selection, doubles retargeting, Uproar sleep prevention and exact failure
  cleanup are ported.
- Field/location wave: `s_camouflage`, `s_nature_power`, `s_pledge`,
  `s_secret_power` and `s_synchronoise` now resolve through
  `FieldLocationMoveBehavior` instead of target-marker/basic fallbacks. The
  local singles slice ports active-terrain/default behavior for Camouflage,
  Nature Power and Secret Power, Synchronoise shared-type gating and a
  dedicated Pledge damage path. They remain `partial` until map-biome
  locations, multi-target Synchronoise and Pledge combo ordering/effects are
  represented.
- Special-secondary wave: `s_alluring_voice`, `s_burning_jealousy`,
  `s_burn_up`, `s_incinerate`, `s_psychic_noise`, `s_relic_song`,
  `s_salt_cure`, `s_syrup_bomb`, `s_tar_shot`, `s_throat_chop` and
  `s_tri_attack` now resolve through `SpecialSecondaryMoveBehavior` instead of
  generic Basic/marker fallbacks. The local singles slice ports Tri Attack
  random major status, stat-history-gated Alluring Voice/Burning Jealousy,
  Psychic Noise Heal Block, Throat Chop's sound-move prevention, Burn Up type
  gating/removal, Incinerate berry/gem removal, Salt Cure residual damage,
  Syrup Bomb timed Speed drops and Tar Shot's fire-weakness multiplier. They
  remain `partial` until disabled-move UI/messages, ally-side Aroma Veil, exact
  PSDK item-loss checks, Burn Up cleanup semantics, exact Syrup Bomb
  lifecycle/messages and Relic Song Meloetta form calibration are represented.
- Grounding wave: `s_smack_down` now resolves through
  `GroundingMoveBehavior` instead of a generic Basic fallback. The local slice
  keeps its Rock hit, installs an object-backed `SmackDownEffect` on airborne
  targets and lets later Ground moves hit Flying targets by overriding the
  local Flying immunity branch. It remains `partial` until full flying-effect
  cleanup, Substitute/Authenic checks and Sky Drop/out-of-reach exceptions are
  represented.
- Trap/item-gated Basic promotion wave: `s_jaw_lock` and `s_poltergeist` now
  resolve through dedicated static paths instead of generic Basic fallbacks.
  The local singles slice ports Jaw Lock's mutual `cant_switch` installation
  after a successful hit and Poltergeist's no-held-item failure gate before
  damage. They remain `partial` until exact reveal-item messages, multi-target
  display ordering and full switch-prevention cleanup semantics are ported.
- Persistent-hit promotion wave: `s_sappy_seed` now resolves through a
  dedicated static path instead of a generic Basic fallback. The local singles
  slice keeps its Basic hit and installs `LeechSeedEffect` after a successful
  hit when the target is alive, non-Grass, not already seeded and not under
  Substitute. It remains `partial` until exact PSDK messages, position-effect
  modelling and richer Substitute/ability interactions are ported.
- Screen-setting hit promotion wave: `s_baddy_bad` and `s_glitzy_glow` now
  resolve through dedicated static paths instead of generic Basic fallbacks.
  The local singles slice keeps their Basic hits and installs user-bank
  `reflect` or `light_screen` after successful damage, including the existing
  Light Clay duration convention. They remain `partial` until exact PSDK
  messages, richer bank-effect modelling and full screen ordering hooks are
  ported.
- Glaive Rush promotion wave: `s_glaive_rush` now resolves through a dedicated
  static path instead of a generic Basic fallback. The local singles slice keeps
  the successful Dragon hit, installs a battler-scoped `glaive_rush` marker and
  doubles incoming damage while that marker is active. It remains `partial`
  until exact PSDK messages and action-order cleanup semantics are ported.
- Fickle Beam promotion wave: `s_fickle_beam` now resolves through a dedicated
  static path instead of a generic Basic fallback. The local singles slice
  consumes the generic RNG after prechecks/accuracy and doubles base power when
  PSDK's `bchance?(0.3)` empowerment roll succeeds. It remains `partial` until
  exact empowerment messages are ported.
- Super Duper Effective promotion wave: `s_super_duper_effective` now resolves
  through a dedicated static path instead of a generic Basic fallback. The local
  singles slice keeps the Basic hit and applies PSDK's `5461 / 4096` final
  damage multiplier when raw type effectiveness is super effective. It remains
  `partial` until exact message/event timing and fuller damage-modifier hook
  ordering are ported.
- Genies Storm promotion wave: `s_genies_storm` now resolves through
  `WeatherPowerMoveBehavior.geniesStorm` instead of a generic Basic fallback.
  The local singles slice ports rain/hard-rain accuracy bypass while preserving
  Air Lock / Cloud Nine suppression through existing field semantics. It remains
  `partial` until exact messages and richer weather/ability/item exceptions are
  ported.
- Eerie Spell promotion wave: `s_eerie_spell` now resolves through a dedicated
  static path instead of a generic Basic fallback. The local singles slice keeps
  the Basic hit and removes up to 3 PP from the target's last attempted move
  after successful damage. It remains `partial` until exact messages and richer
  multi-target behavior are ported.
- Last Respects promotion wave: `s_last_respects` now resolves through a
  dedicated static path instead of a generic Basic fallback. The local singles
  slice scales base power from the clean-lane `koCount` snapshot with PSDK's
  `(ko_count + 1).clamp(1, 101)` formula shape. It remains `partial` until full
  party-side KO aggregation and exact messages are ported.
- Shell Side Arm promotion wave: `s_shell_side_arm` now resolves through a
  dedicated static path instead of a generic Basic fallback. The local singles
  slice evaluates physical and special damage lanes, applies local screen
  adjustment per lane, then keeps physical only when it is strictly stronger,
  matching PSDK's tie-to-special branch. It remains `partial` until the physical
  lane's `direct?`/contact override is represented in the local event model.
- Electro Shot promotion wave: `s_electro_shot` now resolves through a
  dedicated static path instead of a generic Basic fallback. The local singles
  slice raises the user's Special Attack during the charge turn, stores the
  local two-turn marker, releases the Basic hit on the next submission and
  shortcuts to same-turn damage under rain/hard rain. It remains `partial` until
  exact PSDK charge messages, forced-next-move metadata and richer accuracy
  shortcut edge cases are represented.
- Present promotion wave: `s_present` now resolves through a dedicated static
  path. The local singles slice samples PSDK's 40/80/120/heal RNG table, applies
  sampled damage power through the normal calculator and heals the target for a
  quarter of max HP on the heal branch when not full or locally Heal Blocked. It
  remains `partial` until exact PSDK messages and richer heal-block display
  semantics are represented.
- Triple Arrows promotion wave: `s_triple_arrows` now resolves through a
  dedicated static path instead of a generic Basic fallback. The local singles
  slice preserves the Basic hit and installs a four-turn user-scoped
  `triple_arrows` marker after successful damage, while respecting PSDK's
  unstackable guard against `dragon_cheer`, `focus_energy` and an existing
  `triple_arrows` marker. The local critical-hit calculator now consumes
  `triple_arrows`, `focus_energy`, `dragon_cheer` and `laser_focus` markers
  using PSDK's critical-count rules. It remains `partial` until exact PSDK
  messages are represented.
- Critical parity wave: the local damage calculator now also ports PSDK's
  Lucky Chant critical prevention, Battle Armor/Shell Armor critical blocking,
  Merciless guaranteed critical hits against poisoned/toxic targets, Super Luck,
  Lansat Berry and critical-rate item count boosts (`razor_claw`, `scope_lens`,
  Farfetch'd `leek`, Chansey `lucky_punch`). Remaining gaps are Mold
  Breaker-like ability cancellation and exact PSDK critical messages.
- Marker/secondary cleanup wave: `charge` now doubles Electric move base power
  while active, `s_defog` clears fog weather without clearing non-fog weather,
  and `ability_suppressed` disables active ability-effect hooks and direct
  Levitate grounding immunity. Remaining Gastro Acid gaps are ability-change
  guards and exact messages.
- Marker/type multiplier wave: `s_autotomize` now applies PSDK's weight-loss
  gate when the Speed raise succeeds; `mud_sport` and `water_sport` now apply
  their matching base-power dampening; `foresight` and `miracle_eye` now
  overwrite their matching single-type immunities; and PSDK `type3` now feeds
  STAB, effectiveness and immunity prechecks. Remaining gaps are Autotomize
  on-delete restoration, exact effect-lifecycle messages and richer type-change
  cleanup.
- Marker hook wave: `mist` now prevents opposing stat drops through the stat
  change handler, `telekinesis` now feeds the grounding resolver so Ground moves
  fail against lifted targets, `magnet_rise` now feeds the same forced-flying
  resolver path, `embargo` now suppresses Air Balloon-style held-item grounding
  effects, `s_toxic_thread` now fails only when both poison and the Speed drop
  cannot apply, and `electrify`/`ion_deluge` now rewrite the effective move type
  before immunity and damage. Remaining gaps are exact prevention/type-change
  messages, one-turn cleanup, broader Embargo item-use prevention and fuller
  shared hook coverage for specialized move behaviors.
