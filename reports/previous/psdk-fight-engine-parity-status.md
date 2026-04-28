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
| Effect classes partial | 24 |
| Effect classes missing | 458 |
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
- `s_brick_break`, `s_stomp`, `s_u_turn` ->
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
- `s_dragon_tail`, `s_ice_ball`, `s_jump_kick`, `s_revenge`,
  `s_roar`, `s_rollout`, `s_round`, `s_secret_power`, `s_synchronoise`,
  `s_trump_card`, `s_uproar` ->
  `StaticBasicMoveRegistry.partialBasic(...)` (`partial`)
- `s_snore` and `s_sucker_punch` now resolve through
  `ActionGatedMoveBehavior`, adding their local PSDK pre-PP user gates while
  preserving Basic damage resolution (`partial`)
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
- Basic fallback wave: `s_burn_up`, `s_fake_out`, `s_feint`,
  `s_fell_stinger`, `s_flame_burst`, `s_fury_cutter`, `s_fusion_bolt`,
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
  `s_aura_wheel`, `s_double_iron_bash`, `s_dragon_darts`,
  `s_electro_shot`, `s_expanding_force`, `s_fickle_beam`,
  `s_gigaton_hammer`, `s_glaive_rush`,
  `s_grassy_glide`, `s_ice_spinner`, `s_jaw_lock`, `s_last_respects`,
  `s_poltergeist`, `s_rage_fist`, `s_raging_bull`, `s_scale_shot`,
  `s_steel_roller`, `s_terrain_pulse`, `s_triple_arrows` and
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
