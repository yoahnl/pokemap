# PSDK Move Porting Matrix

Source: `../../pokemonsdk-development/scripts/5 Battle`

Total registered methods: 330

| Status | Count |
| --- | ---: |
| `ported` | 25 |
| `partial` | 65 |
| `missing` | 240 |

| Method | Ruby class | Ruby path | Dart behavior | Status | Dependencies |
| --- | --- | --- | --- | --- | --- |
| `s_2hits` | `TwoHit` | `10 Move/1 Mechanics/103 TwoHit MultiHit.rb` | `MultiHitMoveBehavior.fixed(2)` | `ported` | `-` |
| `s_2turns` | `TwoTurnBase` | `10 Move/1 Mechanics/110 TwoTurnBase.rb` | `TODO` | `missing` | `-` |
| `s_3hits` | `ThreeHit` | `10 Move/1 Mechanics/103 TwoHit MultiHit.rb` | `MultiHitMoveBehavior.fixed(3)` | `ported` | `-` |
| `s_a_fang` | `Fangs` | `10 Move/2 Definitions/300 Fangs.rb` | `TODO` | `missing` | `-` |
| `s_absorb` | `Absorb` | `10 Move/2 Definitions/300 Absorb.rb` | `DrainMoveBehavior.absorb` | `partial` | `handler_damage`, `effects`, `item`, `ability` |
| `s_acrobatics` | `Acrobatics` | `10 Move/2 Definitions/300 Acrobatics.rb` | `SpecialPowerMoveBehavior.acrobatics` | `partial` | `item` |
| `s_acupressure` | `Acupressure` | `10 Move/2 Definitions/300 Acupressure.rb` | `AdvancedStatMoveBehavior.acupressure` | `partial` | `handler_stat`, `effects`, `ability` |
| `s_add_type` | `AddThirdType` | `10 Move/2 Definitions/300 AddThirdType.rb` | `TODO` | `missing` | `-` |
| `s_after_you` | `AfterYou` | `10 Move/2 Definitions/300 After you.rb` | `TODO` | `missing` | `-` |
| `s_alluring_voice` | `AlluringVoice` | `10 Move/2 Definitions/300 AlluringVoice.rb` | `TODO` | `missing` | `-` |
| `s_ally_switch` | `AllySwitch` | `10 Move/2 Definitions/300 AllySwitch.rb` | `TODO` | `missing` | `-` |
| `s_aqua_ring` | `AquaRing` | `10 Move/2 Definitions/300 AquaRing.rb` | `PersistentEffectMoveBehavior.aquaRing` | `partial` | `handler_damage`, `effects`, `end_turn`, `item` |
| `s_assist` | `Assist` | `10 Move/2 Definitions/300 Assist.rb` | `TODO` | `missing` | `-` |
| `s_assurance` | `Assurance` | `10 Move/2 Definitions/300 Assurance.rb` | `TODO` | `missing` | `-` |
| `s_attract` | `Attract` | `10 Move/2 Definitions/300 Attract.rb` | `TODO` | `missing` | `-` |
| `s_aura_wheel` | `AuraWheel` | `10 Move/2 Definitions/300 AuraWheel.rb` | `TODO` | `missing` | `-` |
| `s_autotomize` | `Autotomize` | `10 Move/2 Definitions/300 Autotomize.rb` | `TODO` | `missing` | `-` |
| `s_avalanche` | `Avalanche` | `10 Move/2 Definitions/300 Avalanche.rb` | `TODO` | `missing` | `-` |
| `s_baddy_bad` | `BaddyBad` | `10 Move/2 Definitions/300 GlitzyGlow.rb` | `TODO` | `missing` | `-` |
| `s_basic` | `Basic` | `10 Move/1 Mechanics/100 Basic.rb` | `StaticBasicMoveRegistry.s_basic` | `partial` | `-` |
| `s_baton_pass` | `BatonPass` | `10 Move/2 Definitions/300 BatonPass.rb` | `SwitchEffectMoveBehavior.batonPass` | `partial` | `handler_switch`, `effects` |
| `s_beak_blast` | `BeakBlast` | `10 Move/2 Definitions/300 PreAttackMoves.rb` | `TODO` | `missing` | `-` |
| `s_beat_up` | `BeatUp` | `10 Move/2 Definitions/300 BeatUp.rb` | `TODO` | `missing` | `-` |
| `s_belch` | `Belch` | `10 Move/2 Definitions/300 Belch.rb` | `TODO` | `missing` | `-` |
| `s_bellydrum` | `BellyDrum` | `10 Move/2 Definitions/300 BellyDrum.rb` | `RecoveryStatMoveBehavior.bellyDrum` | `partial` | `handler_damage`, `handler_stat`, `ability`, `effects` |
| `s_bestow` | `Bestow` | `10 Move/2 Definitions/300 Bestow.rb` | `TODO` | `missing` | `-` |
| `s_bide` | `Bide` | `10 Move/2 Definitions/300 Bide.rb` | `TODO` | `missing` | `-` |
| `s_bind` | `Bind` | `10 Move/2 Definitions/300 Bind.rb` | `TODO` | `missing` | `-` |
| `s_bitter_malice` | `InfernalParade` | `10 Move/2 Definitions/300 StatusBoostedMove.rb` | `VariablePowerMoveBehavior.bitterMalice` | `ported` | `-` |
| `s_body_press` | `BodyPress` | `10 Move/2 Definitions/300 BodyPress.rb` | `CustomStatSourceMoveBehavior.bodyPress` | `partial` | `handler_damage`, `ability`, `item` |
| `s_brick_break` | `BrickBreak` | `10 Move/2 Definitions/300 BrickBreak.rb` | `TODO` | `missing` | `-` |
| `s_brine` | `Brine` | `10 Move/2 Definitions/300 Brine.rb` | `VariablePowerMoveBehavior.brine` | `ported` | `-` |
| `s_burn_up` | `BurnUp` | `10 Move/2 Definitions/300 BurnUp.rb` | `TODO` | `missing` | `-` |
| `s_burning_jealousy` | `BurningJealousy` | `10 Move/2 Definitions/300 AlluringVoice.rb` | `TODO` | `missing` | `-` |
| `s_camouflage` | `Camouflage` | `10 Move/2 Definitions/300 Camouflage.rb` | `TODO` | `missing` | `-` |
| `s_cantflee` | `CantSwitch` | `10 Move/2 Definitions/300 CantSwitch.rb` | `TODO` | `missing` | `-` |
| `s_captivate` | `Captivate` | `10 Move/2 Definitions/300 Captivate.rb` | `TODO` | `missing` | `-` |
| `s_ceaseless_edge` | `CeaselessEdge` | `10 Move/2 Definitions/300 HazardsSetting.rb` | `TODO` | `missing` | `-` |
| `s_change_type` | `ChangeType` | `10 Move/2 Definitions/300 ChangeType.rb` | `TODO` | `missing` | `-` |
| `s_charge` | `Charge` | `10 Move/2 Definitions/300 Charge.rb` | `TODO` | `missing` | `-` |
| `s_chilly_reception` | `ChillyReception` | `10 Move/2 Definitions/300 ChillyReception.rb` | `TODO` | `missing` | `-` |
| `s_chloroblast` | `MindBlown` | `10 Move/2 Definitions/300 MindBlown.rb` | `MindBlownMoveBehavior.chloroblast` | `partial` | `ability`, `faint_process` |
| `s_clangorous_soul` | `ClangorousSoul` | `10 Move/2 Definitions/300 ClangorousSoul.rb` | `AdvancedStatMoveBehavior.clangorousSoul` | `partial` | `handler_damage`, `handler_stat`, `effects`, `ability` |
| `s_conversion` | `Conversion` | `10 Move/2 Definitions/300 Conversion.rb` | `TODO` | `missing` | `-` |
| `s_conversion2` | `Conversion2` | `10 Move/2 Definitions/300 Conversion.rb` | `TODO` | `missing` | `-` |
| `s_core_enforcer` | `CoreEnforcer` | `10 Move/2 Definitions/300 CoreEnforcer.rb` | `TODO` | `missing` | `-` |
| `s_corrosive_gas` | `CorrosiveGas` | `10 Move/2 Definitions/300 CorrosiveGas.rb` | `TODO` | `missing` | `-` |
| `s_counter` | `Counter` | `10 Move/2 Definitions/300 Counter moves.rb` | `TODO` | `missing` | `-` |
| `s_court_change` | `CourtChange` | `10 Move/2 Definitions/300 CourtChange.rb` | `TODO` | `missing` | `-` |
| `s_crafty_shield` | `CraftyShield` | `10 Move/2 Definitions/300 CraftyShield.rb` | `TODO` | `missing` | `-` |
| `s_curse` | `Curse` | `10 Move/2 Definitions/300 Curse.rb` | `AdvancedStatMoveBehavior.curse` | `partial` | `handler_damage`, `handler_stat`, `effects`, `end_turn` |
| `s_custom_stats_based` | `CustomStatsBased` | `10 Move/2 Definitions/300 CustomStatsBased.rb` | `CustomStatSourceMoveBehavior.customStatsBased` | `partial` | `handler_damage`, `ability`, `item` |
| `s_defog` | `Defog` | `10 Move/2 Definitions/300 Defog.rb` | `TODO` | `missing` | `-` |
| `s_destiny_bond` | `DestinyBond` | `10 Move/2 Definitions/300 DestinyBond.rb` | `TODO` | `missing` | `-` |
| `s_disable` | `Disable` | `10 Move/2 Definitions/300 Disable.rb` | `TODO` | `missing` | `-` |
| `s_do_nothing` | `DoNothing` | `10 Move/2 Definitions/300 Splash.rb` | `NoEffectMoveBehavior.doNothing` | `ported` | `-` |
| `s_doodle` | `Doodle` | `10 Move/2 Definitions/300 AbilityChanging.rb` | `TODO` | `missing` | `-` |
| `s_double_iron_bash` | `DoubleIronBash` | `10 Move/2 Definitions/300 DoubleIronBash.rb` | `TODO` | `missing` | `-` |
| `s_dragon_cheer` | `DragonCheer` | `10 Move/2 Definitions/300 DragonCheer.rb` | `TODO` | `missing` | `-` |
| `s_dragon_darts` | `DragonDarts` | `10 Move/2 Definitions/300 DragonDarts.rb` | `TODO` | `missing` | `-` |
| `s_dragon_tail` | `ForceSwitch` | `10 Move/2 Definitions/300 ForceSwitch.rb` | `TODO` | `missing` | `-` |
| `s_dream_eater` | `Absorb` | `10 Move/2 Definitions/300 Absorb.rb` | `DrainMoveBehavior.dreamEater` | `partial` | `handler_damage`, `handler_status`, `effects`, `item`, `ability` |
| `s_echo` | `EchoedVoice` | `10 Move/2 Definitions/300 EchoedVoice.rb` | `TODO` | `missing` | `-` |
| `s_eerie_spell` | `EerieSpell` | `10 Move/2 Definitions/300 EerieSpell.rb` | `TODO` | `missing` | `-` |
| `s_electrify` | `Electrify` | `10 Move/2 Definitions/300 Electrify.rb` | `TODO` | `missing` | `-` |
| `s_electro_ball` | `ElectroBall` | `10 Move/2 Definitions/300 ElectroBall.rb` | `VariablePowerMoveBehavior.electroBall` | `ported` | `-` |
| `s_electro_shot` | `ElectroShot` | `10 Move/2 Definitions/300 ElectroShot.rb` | `TODO` | `missing` | `-` |
| `s_embargo` | `Embargo` | `10 Move/2 Definitions/300 Embargo.rb` | `TODO` | `missing` | `-` |
| `s_encore` | `Encore` | `10 Move/2 Definitions/300 Encore.rb` | `TODO` | `missing` | `-` |
| `s_endeavor` | `Endeavor` | `10 Move/2 Definitions/300 Endeavor.rb` | `DirectHpMoveBehavior.endeavor` | `ported` | `-` |
| `s_entrainment` | `Entrainment` | `10 Move/2 Definitions/300 AbilityChanging.rb` | `TODO` | `missing` | `-` |
| `s_eruption` | `Eruption` | `10 Move/2 Definitions/300 Eruption.rb` | `VariablePowerMoveBehavior.eruption` | `ported` | `-` |
| `s_expanding_force` | `ExpandingForce` | `10 Move/2 Definitions/300 TerrainDamageMoves.rb` | `TODO` | `missing` | `terrain`, `grounded`, `targeting_multi` |
| `s_explosion` | `SelfDestruct` | `10 Move/2 Definitions/300 SelfDestruct.rb` | `SelfDestructMoveBehavior.explosion` | `partial` | `ability`, `faint_process` |
| `s_facade` | `Facade` | `10 Move/2 Definitions/300 StatusBoostedMove.rb` | `VariablePowerMoveBehavior.facade` | `ported` | `-` |
| `s_fairy_lock` | `FairyLock` | `10 Move/2 Definitions/300 FairyLock.rb` | `TODO` | `missing` | `-` |
| `s_fake_out` | `FakeOut` | `10 Move/2 Definitions/300 FakeOut.rb` | `TODO` | `missing` | `-` |
| `s_false_swipe` | `FalseSwipe` | `10 Move/2 Definitions/300 FalseSwipe.rb` | `BasicDamageSpecializationMoveBehavior.falseSwipe` | `partial` | `effects` |
| `s_feint` | `Feint` | `10 Move/2 Definitions/300 Feint.rb` | `TODO` | `missing` | `-` |
| `s_fell_stinger` | `FellStinger` | `10 Move/2 Definitions/300 FellStinger.rb` | `TODO` | `missing` | `-` |
| `s_fickle_beam` | `FickleBeam` | `10 Move/2 Definitions/300 FickleBeam.rb` | `TODO` | `missing` | `-` |
| `s_fillet_away` | `FilletAway` | `10 Move/2 Definitions/300 BellyDrum.rb` | `RecoveryStatMoveBehavior.filletAway` | `partial` | `handler_damage`, `handler_stat`, `ability`, `effects` |
| `s_final_gambit` | `FinalGambit` | `10 Move/2 Definitions/300 FinalGambit.rb` | `DirectHpMoveBehavior.finalGambit` | `partial` | `faint_process`, `history` |
| `s_fishious_rend` | `FishiousRend` | `10 Move/2 Definitions/300 FishiousRend.rb` | `TODO` | `missing` | `-` |
| `s_fixed_damage` | `FixedDamages` | `10 Move/2 Definitions/300 FixedDamages.rb` | `FixedDamageMoveBehavior.psdkFixedDamage` | `ported` | `-` |
| `s_flail` | `Flail` | `10 Move/2 Definitions/300 Flail.rb` | `VariablePowerMoveBehavior.flail` | `ported` | `-` |
| `s_flame_burst` | `FlameBurst` | `10 Move/2 Definitions/300 FlameBurst.rb` | `TODO` | `missing` | `-` |
| `s_fling` | `Fling` | `10 Move/2 Definitions/300 Fling.rb` | `TODO` | `missing` | `-` |
| `s_floral_healing` | `FloralHealing` | `10 Move/2 Definitions/300 FloralHealing.rb` | `HealMoveBehavior.floralHealing` | `partial` | `handler_damage`, `terrain`, `effects`, `ability` |
| `s_flower_shield` | `FlowerShield` | `10 Move/2 Definitions/300 FlowerShield.rb` | `TODO` | `missing` | `-` |
| `s_flying_press` | `FlyingPress` | `10 Move/2 Definitions/300 FlyingPress.rb` | `TODO` | `missing` | `-` |
| `s_focus_energy` | `FocusEnergy` | `10 Move/2 Definitions/300 FocusEnergy.rb` | `TODO` | `missing` | `-` |
| `s_focus_punch` | `FocusPunch` | `10 Move/2 Definitions/300 PreAttackMoves.rb` | `TODO` | `missing` | `-` |
| `s_follow_me` | `FollowMe` | `10 Move/2 Definitions/300 FollowMe.rb` | `TODO` | `missing` | `-` |
| `s_foresight` | `Foresight` | `10 Move/2 Definitions/300 Foresight.rb` | `TODO` | `missing` | `-` |
| `s_foul_play` | `FoulPlay` | `10 Move/2 Definitions/300 FoulPlay.rb` | `CustomStatSourceMoveBehavior.foulPlay` | `partial` | `handler_damage`, `ability`, `item` |
| `s_freezy_frost` | `FreezyFrost` | `10 Move/2 Definitions/300 FreezyFrost.rb` | `TODO` | `missing` | `-` |
| `s_frustration` | `Frustration` | `10 Move/2 Definitions/300 Frustration.rb` | `TODO` | `missing` | `-` |
| `s_full_crit` | `FullCrit` | `10 Move/2 Definitions/300 FullCrit.rb` | `BasicDamageSpecializationMoveBehavior.fullCrit` | `ported` | `-` |
| `s_fury_cutter` | `FuryCutter` | `10 Move/2 Definitions/300 FuryCutter.rb` | `TODO` | `missing` | `-` |
| `s_fusion_bolt` | `FusionBolt` | `10 Move/2 Definitions/300 FusionFlareBolt.rb` | `TODO` | `missing` | `-` |
| `s_fusion_flare` | `FusionFlare` | `10 Move/2 Definitions/300 FusionFlareBolt.rb` | `TODO` | `missing` | `-` |
| `s_future_sight` | `FutureSight` | `10 Move/2 Definitions/300 FutureSight.rb` | `TODO` | `missing` | `-` |
| `s_gastro_acid` | `GastroAcid` | `10 Move/2 Definitions/300 GastroAcid.rb` | `TODO` | `missing` | `-` |
| `s_gear_up` | `GearUp` | `10 Move/2 Definitions/300 GearUp.rb` | `TODO` | `missing` | `-` |
| `s_genies_storm` | `GeniesStorm` | `10 Move/2 Definitions/300 GeniesStorm.rb` | `TODO` | `missing` | `-` |
| `s_geomancy` | `Geomancy` | `10 Move/2 Definitions/300 Geomancy.rb` | `TODO` | `missing` | `-` |
| `s_gigaton_hammer` | `GigatonHammer` | `10 Move/2 Definitions/300 GigatonHammer.rb` | `TODO` | `missing` | `-` |
| `s_glaive_rush` | `GlaiveRush` | `10 Move/2 Definitions/300 GlaiveRush.rb` | `TODO` | `missing` | `-` |
| `s_glitzy_glow` | `GlitzyGlow` | `10 Move/2 Definitions/300 GlitzyGlow.rb` | `TODO` | `missing` | `-` |
| `s_grassy_glide` | `GrassyGlide` | `10 Move/2 Definitions/300 TerrainDamageMoves.rb` | `TODO` | `missing` | `terrain`, `grounded`, `action_order` |
| `s_grav_apple` | `GravApple` | `10 Move/2 Definitions/300 GravApple.rb` | `TODO` | `missing` | `-` |
| `s_gravity` | `Gravity` | `10 Move/2 Definitions/300 Gravity.rb` | `TODO` | `missing` | `-` |
| `s_growth` | `Growth` | `10 Move/2 Definitions/300 Growth.rb` | `AdvancedStatMoveBehavior.growth` | `partial` | `handler_stat`, `weather`, `effects`, `ability` |
| `s_grudge` | `Grudge` | `10 Move/2 Definitions/300 Grudge.rb` | `TODO` | `missing` | `-` |
| `s_guard_split` | `GuardSplit` | `10 Move/2 Definitions/300 Stages split moves.rb` | `StatSplitMoveBehavior.guard` | `ported` | `-` |
| `s_guard_swap` | `GuardSwap` | `10 Move/2 Definitions/300 Stages swap moves.rb` | `AdvancedStatMoveBehavior.guardSwap` | `partial` | `handler_stat`, `effects`, `ability` |
| `s_gyro_ball` | `GyroBall` | `10 Move/2 Definitions/300 GyroBall.rb` | `VariablePowerMoveBehavior.gyroBall` | `partial` | `-` |
| `s_happy_hour` | `HappyHour` | `10 Move/2 Definitions/300 HappyHour.rb` | `TODO` | `missing` | `-` |
| `s_hard_press` | `HardPress` | `10 Move/2 Definitions/300 WringOut.rb` | `VariablePowerMoveBehavior.hardPress` | `ported` | `-` |
| `s_haze` | `Haze` | `10 Move/2 Definitions/300 Haze.rb` | `AdvancedStatMoveBehavior.haze` | `partial` | `handler_stat`, `effects`, `ability`, `targeting_multi` |
| `s_heal` | `HealMove` | `10 Move/1 Mechanics/105 Heal.rb` | `HealMoveBehavior` | `partial` | `handler_damage`, `effects`, `ability` |
| `s_heal_bell` | `HealBell` | `10 Move/2 Definitions/300 HealBell.rb` | `TODO` | `missing` | `-` |
| `s_heal_block` | `HealBlock` | `10 Move/2 Definitions/300 HealBlock.rb` | `TODO` | `missing` | `-` |
| `s_heal_weather` | `HealWeather` | `10 Move/2 Definitions/300 HealWeather.rb` | `HealMoveBehavior.weather` | `partial` | `handler_damage`, `weather`, `effects`, `ability` |
| `s_healing_wish` | `HealingWish` | `10 Move/2 Definitions/300 HealingSacrifice.rb` | `TODO` | `missing` | `-` |
| `s_heart_swap` | `HeartSwap` | `10 Move/2 Definitions/300 Stages swap moves.rb` | `AdvancedStatMoveBehavior.heartSwap` | `partial` | `handler_stat`, `effects`, `ability` |
| `s_heavy_slam` | `HeavySlam` | `10 Move/2 Definitions/300 HeavySlam.rb` | `WeightPowerMoveBehavior.heavySlam` | `partial` | `effects`, `ability` |
| `s_helping_hand` | `HelpingHand` | `10 Move/2 Definitions/300 HelpingHand.rb` | `TODO` | `missing` | `-` |
| `s_hex` | `Hex` | `10 Move/2 Definitions/300 Hex.rb` | `VariablePowerMoveBehavior.hex` | `partial` | `ability`, `handler_status` |
| `s_hidden_power` | `HiddenPower` | `10 Move/2 Definitions/300 HiddenPower.rb` | `TODO` | `missing` | `-` |
| `s_hp_eq_level` | `HPEqLevel` | `10 Move/2 Definitions/300 HPEqLevel.rb` | `FixedDamageMoveBehavior.userLevel` | `ported` | `-` |
| `s_hurricane` | `Thunder` | `10 Move/2 Definitions/300 Thunder.rb` | `TODO` | `missing` | `-` |
| `s_ice_ball` | `Rollout` | `10 Move/2 Definitions/300 Rollout.rb` | `TODO` | `missing` | `-` |
| `s_ice_spinner` | `IceSpinner` | `10 Move/2 Definitions/300 IceSpinner SteelRoller.rb` | `TODO` | `missing` | `-` |
| `s_imprison` | `Imprison` | `10 Move/2 Definitions/300 Imprison.rb` | `TODO` | `missing` | `-` |
| `s_incinerate` | `Incinerate` | `10 Move/2 Definitions/300 Incinerate.rb` | `TODO` | `missing` | `-` |
| `s_infernal_parade` | `InfernalParade` | `10 Move/2 Definitions/300 StatusBoostedMove.rb` | `VariablePowerMoveBehavior.infernalParade` | `ported` | `-` |
| `s_ingrain` | `Ingrain` | `10 Move/2 Definitions/300 Ingrain.rb` | `PersistentEffectMoveBehavior.ingrain` | `partial` | `handler_damage`, `handler_switch`, `effects`, `end_turn`, `item` |
| `s_instruct` | `Instruct` | `10 Move/2 Definitions/300 Instruct.rb` | `TODO` | `missing` | `-` |
| `s_ion_deluge` | `IonDeluge` | `10 Move/2 Definitions/300 Ion Deluge.rb` | `TODO` | `missing` | `-` |
| `s_ivy_cudgel` | `IvyCudgel` | `10 Move/2 Definitions/300 IvyCudgel.rb` | `TODO` | `missing` | `-` |
| `s_jaw_lock` | `JawLock` | `10 Move/2 Definitions/300 JawLock.rb` | `TODO` | `missing` | `-` |
| `s_judgment` | `Judgment` | `10 Move/2 Definitions/300 Judgment.rb` | `TODO` | `missing` | `-` |
| `s_jump_kick` | `HighJumpKick` | `10 Move/2 Definitions/300 HighJumpKick.rb` | `TODO` | `missing` | `-` |
| `s_jungle_healing` | `JungleHealing` | `10 Move/2 Definitions/300 LifeDew.rb` | `HealMoveBehavior.jungleHealing` | `partial` | `handler_damage`, `handler_status`, `effects`, `targeting_multi` |
| `s_knock_off` | `KnockOff` | `10 Move/2 Definitions/300 KnockOff.rb` | `TODO` | `missing` | `-` |
| `s_laser_focus` | `LaserFocus` | `10 Move/2 Definitions/300 LaserFocus.rb` | `TODO` | `missing` | `-` |
| `s_lash_out` | `LashOut` | `10 Move/2 Definitions/300 LashOut.rb` | `TODO` | `missing` | `-` |
| `s_last_resort` | `LastResort` | `10 Move/2 Definitions/300 LastResort.rb` | `TODO` | `missing` | `-` |
| `s_last_respects` | `LastRespects` | `10 Move/2 Definitions/300 LastRespects.rb` | `TODO` | `missing` | `-` |
| `s_leech_seed` | `LeechSeed` | `10 Move/2 Definitions/300 LeechSeed.rb` | `PersistentEffectMoveBehavior.leechSeed` | `partial` | `handler_damage`, `effects`, `end_turn`, `ability` |
| `s_life_dew` | `LifeDew` | `10 Move/2 Definitions/300 LifeDew.rb` | `HealMoveBehavior.lifeDew` | `partial` | `handler_damage`, `effects`, `targeting_multi` |
| `s_lock_on` | `LockOn` | `10 Move/2 Definitions/300 LockOn.rb` | `TODO` | `missing` | `-` |
| `s_low_kick` | `LowKick` | `10 Move/2 Definitions/300 LowKick.rb` | `WeightPowerMoveBehavior.lowKick` | `partial` | `effects`, `ability`, `grounded` |
| `s_lucky_chant` | `LuckyChant` | `10 Move/2 Definitions/300 LuckyChant.rb` | `TODO` | `missing` | `-` |
| `s_lunar_dance` | `LunarDance` | `10 Move/2 Definitions/300 HealingSacrifice.rb` | `TODO` | `missing` | `-` |
| `s_magic_coat` | `MagicCoat` | `10 Move/2 Definitions/300 MagicCoat.rb` | `TODO` | `missing` | `-` |
| `s_magic_powder` | `MagicPowder` | `10 Move/2 Definitions/300 MagicPowder.rb` | `TODO` | `missing` | `-` |
| `s_magic_room` | `MagicRoom` | `10 Move/2 Definitions/300 MagicRoom.rb` | `TODO` | `missing` | `-` |
| `s_magnet_rise` | `MagnetRise` | `10 Move/2 Definitions/300 MagnetRise.rb` | `TODO` | `missing` | `-` |
| `s_magnetic_flux` | `MagneticFlux` | `10 Move/2 Definitions/300 MagneticFlux.rb` | `TODO` | `missing` | `-` |
| `s_magnitude` | `Magnitude` | `10 Move/2 Definitions/300 Magnitude.rb` | `TODO` | `missing` | `-` |
| `s_make_it_rain` | `MakeItRain` | `10 Move/2 Definitions/300 MakeItRain.rb` | `TODO` | `missing` | `-` |
| `s_me_first` | `MeFirst` | `10 Move/2 Definitions/300 Me First.rb` | `TODO` | `missing` | `-` |
| `s_memento` | `Memento` | `10 Move/2 Definitions/300 Memento.rb` | `TODO` | `missing` | `-` |
| `s_metal_burst` | `MetalBurst` | `10 Move/2 Definitions/300 Counter moves.rb` | `TODO` | `missing` | `-` |
| `s_metronome` | `Metronome` | `10 Move/2 Definitions/300 Metronome.rb` | `TODO` | `missing` | `-` |
| `s_mimic` | `Mimic` | `10 Move/2 Definitions/300 Mimic.rb` | `TODO` | `missing` | `-` |
| `s_mind_blown` | `MindBlown` | `10 Move/2 Definitions/300 MindBlown.rb` | `MindBlownMoveBehavior.mindBlown` | `partial` | `ability`, `faint_process` |
| `s_mind_reader` | `LockOn` | `10 Move/2 Definitions/300 LockOn.rb` | `TODO` | `missing` | `-` |
| `s_minimize` | `Minimize` | `10 Move/2 Definitions/300 Minimize.rb` | `TODO` | `missing` | `-` |
| `s_miracle_eye` | `MiracleEye` | `10 Move/2 Definitions/300 MiracleEye.rb` | `TODO` | `missing` | `-` |
| `s_mirror_coat` | `MirrorCoat` | `10 Move/2 Definitions/300 Counter moves.rb` | `TODO` | `missing` | `-` |
| `s_mirror_move` | `MirrorMove` | `10 Move/2 Definitions/300 MirrorMove.rb` | `TODO` | `missing` | `-` |
| `s_mist` | `Mist` | `10 Move/2 Definitions/300 Mist.rb` | `TODO` | `missing` | `-` |
| `s_misty_explosion` | `MistyExplosion` | `10 Move/2 Definitions/300 TerrainDamageMoves.rb` | `SelfDestructMoveBehavior.mistyExplosion` | `partial` | `ability`, `faint_process`, `terrain`, `grounded` |
| `s_multi_attack` | `MultiAttack` | `10 Move/2 Definitions/300 MultiAttack.rb` | `TODO` | `missing` | `-` |
| `s_multi_hit` | `MultiHit` | `10 Move/1 Mechanics/103 TwoHit MultiHit.rb` | `MultiHitMoveBehavior.psdkRandom` | `partial` | `ability`, `item` |
| `s_natural_gift` | `NaturalGift` | `10 Move/2 Definitions/300 NaturalGift.rb` | `TODO` | `missing` | `-` |
| `s_nature_power` | `NaturePower` | `10 Move/2 Definitions/300 NaturePower.rb` | `TODO` | `missing` | `-` |
| `s_nightmare` | `Nightmare` | `10 Move/2 Definitions/300 Nightmare.rb` | `TODO` | `missing` | `-` |
| `s_no_retreat` | `NoRetreat` | `10 Move/2 Definitions/300 NoRetreat.rb` | `TODO` | `missing` | `-` |
| `s_octolock` | `Octolock` | `10 Move/2 Definitions/300 Octolock.rb` | `TODO` | `missing` | `-` |
| `s_ohko` | `OHKO` | `10 Move/2 Definitions/300 OHKO.rb` | `TODO` | `missing` | `-` |
| `s_order_up` | `OrderUp` | `10 Move/2 Definitions/300 OrderUp.rb` | `TODO` | `missing` | `-` |
| `s_outrage` | `Thrash` | `10 Move/2 Definitions/300 Thrash.rb` | `TODO` | `missing` | `-` |
| `s_pain_split` | `PainSplit` | `10 Move/2 Definitions/300 PainSplit.rb` | `DirectHpMoveBehavior.painSplit` | `partial` | `handler_damage`, `effects` |
| `s_parting_shot` | `PartingShot` | `10 Move/2 Definitions/300 PartingShot.rb` | `TODO` | `missing` | `-` |
| `s_payback` | `PayBack` | `10 Move/2 Definitions/300 PayBack.rb` | `TODO` | `missing` | `-` |
| `s_payday` | `PayDay` | `10 Move/2 Definitions/300 Payday.rb` | `TODO` | `missing` | `-` |
| `s_perish_song` | `PerishSong` | `10 Move/2 Definitions/300 PerishSong.rb` | `TODO` | `missing` | `-` |
| `s_photon_geyser` | `PhotonGeyser` | `10 Move/2 Definitions/300 PhotonGeyser.rb` | `TODO` | `missing` | `-` |
| `s_plasma_fists` | `PlasmaFists` | `10 Move/2 Definitions/300 PlasmaFists.rb` | `TODO` | `missing` | `-` |
| `s_pledge` | `Pledge` | `10 Move/1 Mechanics/130 Pledge.rb` | `TODO` | `missing` | `-` |
| `s_pluck` | `Pluck` | `10 Move/2 Definitions/300 Pluck.rb` | `TODO` | `missing` | `-` |
| `s_pollen_puff` | `PollenPuff` | `10 Move/2 Definitions/300 PollenPuff.rb` | `TODO` | `missing` | `-` |
| `s_poltergeist` | `Poltergeist` | `10 Move/2 Definitions/300 Poltergeist.rb` | `TODO` | `missing` | `-` |
| `s_population_bomb` | `PopulationBomb` | `10 Move/1 Mechanics/103 TwoHit MultiHit.rb` | `MultiHitMoveBehavior.populationBomb` | `partial` | `ability`, `item` |
| `s_powder` | `Powder` | `10 Move/2 Definitions/300 Powder.rb` | `TODO` | `missing` | `-` |
| `s_power_split` | `PowerSplit` | `10 Move/2 Definitions/300 Stages split moves.rb` | `StatSplitMoveBehavior.power` | `ported` | `-` |
| `s_power_swap` | `PowerSwap` | `10 Move/2 Definitions/300 Stages swap moves.rb` | `AdvancedStatMoveBehavior.powerSwap` | `partial` | `handler_stat`, `effects`, `ability` |
| `s_power_trick` | `PowerTrick` | `10 Move/2 Definitions/300 PowerTrick.rb` | `PowerTrickMoveBehavior` | `ported` | `-` |
| `s_pre_attack_base` | `PreAttackBase` | `10 Move/2 Definitions/300 PreAttackMoves.rb` | `TODO` | `missing` | `-` |
| `s_present` | `Present` | `10 Move/2 Definitions/300 Present.rb` | `TODO` | `missing` | `-` |
| `s_protect` | `Protect` | `10 Move/2 Definitions/300 Protect.rb` | `StaticBasicMoveRegistry.s_protect` | `partial` | `-` |
| `s_psych_up` | `PsychUp` | `10 Move/2 Definitions/300 PsychUp.rb` | `AdvancedStatMoveBehavior.psychUp` | `partial` | `handler_stat`, `effects`, `ability` |
| `s_psychic_noise` | `PsychicNoise` | `10 Move/2 Definitions/300 PsychicNoise.rb` | `TODO` | `missing` | `-` |
| `s_psycho_shift` | `PsychoShift` | `10 Move/2 Definitions/300 PsychoShift.rb` | `PsychoShiftMoveBehavior` | `partial` | `handler_status`, `effects`, `ability`, `targeting_multi` |
| `s_psyshock` | `CustomStatsBased` | `10 Move/2 Definitions/300 CustomStatsBased.rb` | `CustomStatSourceMoveBehavior.psyshock` | `partial` | `handler_damage`, `ability`, `item` |
| `s_psywave` | `Psywave` | `10 Move/2 Definitions/300 HPEqLevel.rb` | `FixedDamageMoveBehavior.psywave` | `ported` | `-` |
| `s_purify` | `Purify` | `10 Move/2 Definitions/300 Purify.rb` | `PurifyMoveBehavior` | `partial` | `handler_damage`, `handler_status`, `effects`, `targeting_multi` |
| `s_pursuit` | `Pursuit` | `10 Move/2 Definitions/300 Pursuit.rb` | `TODO` | `missing` | `-` |
| `s_quash` | `Quash` | `10 Move/2 Definitions/300 Quash.rb` | `TODO` | `missing` | `-` |
| `s_rage` | `Rage` | `10 Move/2 Definitions/300 Rage.rb` | `TODO` | `missing` | `-` |
| `s_rage_fist` | `RageFist` | `10 Move/2 Definitions/300 RageFist.rb` | `TODO` | `missing` | `-` |
| `s_raging_bull` | `RagingBull` | `10 Move/2 Definitions/300 BrickBreak.rb` | `TODO` | `missing` | `-` |
| `s_rapid_spin` | `RapidSpin` | `10 Move/2 Definitions/300 RapidSpin.rb` | `TODO` | `missing` | `-` |
| `s_recoil` | `RecoilMove` | `10 Move/2 Definitions/300 RecoilMove.rb` | `RecoilMoveBehavior.psdkRecoil` | `partial` | `handler_damage`, `ability`, `item`, `history` |
| `s_recycle` | `Recycle` | `10 Move/2 Definitions/300 Recycle.rb` | `TODO` | `missing` | `-` |
| `s_reflect` | `Reflect` | `10 Move/2 Definitions/300 LightScreen Reflect.rb` | `TODO` | `missing` | `-` |
| `s_reflect_type` | `ReflectType` | `10 Move/2 Definitions/300 ReflectType.rb` | `TODO` | `missing` | `-` |
| `s_relic_song` | `RelicSong` | `10 Move/2 Definitions/300 RelicSong.rb` | `TODO` | `missing` | `-` |
| `s_reload` | `Reload` | `10 Move/2 Definitions/300 Reload.rb` | `TODO` | `missing` | `-` |
| `s_rest` | `Rest` | `10 Move/2 Definitions/300 Rest.rb` | `RecoveryStatMoveBehavior.rest` | `partial` | `handler_status`, `handler_damage`, `effects`, `ability`, `terrain`, `item` |
| `s_retaliate` | `Retaliate` | `10 Move/2 Definitions/300 Retaliate.rb` | `TODO` | `missing` | `-` |
| `s_return` | `Return` | `10 Move/2 Definitions/300 Return.rb` | `TODO` | `missing` | `-` |
| `s_revelation_dance` | `RevelationDance` | `10 Move/2 Definitions/300 RevelationDance.rb` | `TODO` | `missing` | `-` |
| `s_revenge` | `Revenge` | `10 Move/2 Definitions/300 Revenge.rb` | `TODO` | `missing` | `-` |
| `s_revival_blessing` | `RevivalBlessing` | `10 Move/2 Definitions/300 RevivalBlessing.rb` | `TODO` | `missing` | `-` |
| `s_rising_voltage` | `RisingVoltage` | `10 Move/2 Definitions/300 TerrainDamageMoves.rb` | `TODO` | `missing` | `terrain`, `grounded` |
| `s_roar` | `ForceSwitch` | `10 Move/2 Definitions/300 ForceSwitch.rb` | `TODO` | `missing` | `-` |
| `s_role_play` | `RolePlay` | `10 Move/2 Definitions/300 AbilityChanging.rb` | `TODO` | `missing` | `-` |
| `s_rollout` | `Rollout` | `10 Move/2 Definitions/300 Rollout.rb` | `TODO` | `missing` | `-` |
| `s_roost` | `Roost` | `10 Move/2 Definitions/300 Roost.rb` | `HealMoveBehavior.roost` | `partial` | `handler_damage`, `effects` |
| `s_rototiller` | `Rototiller` | `10 Move/2 Definitions/300 Rototiller.rb` | `TODO` | `missing` | `-` |
| `s_round` | `Round` | `10 Move/2 Definitions/300 Round.rb` | `TODO` | `missing` | `-` |
| `s_sacred_sword` | `SacredSword` | `10 Move/2 Definitions/300 SacredSword.rb` | `TODO` | `missing` | `-` |
| `s_safe_guard` | `Safeguard` | `10 Move/2 Definitions/300 Safeguard.rb` | `TODO` | `missing` | `-` |
| `s_salt_cure` | `SaltCure` | `10 Move/2 Definitions/300 SaltCure.rb` | `TODO` | `missing` | `-` |
| `s_sappy_seed` | `SappySeed` | `10 Move/2 Definitions/300 SappySeed.rb` | `TODO` | `missing` | `-` |
| `s_scale_shot` | `ScaleShot` | `10 Move/2 Definitions/300 ScaleShot.rb` | `TODO` | `missing` | `-` |
| `s_secret_power` | `SecretPower` | `10 Move/2 Definitions/300 SecretPower.rb` | `TODO` | `missing` | `-` |
| `s_self_stat` | `SelfStat` | `10 Move/1 Mechanics/101 Self.rb` | `StatusStatMoveBehavior.selfStat` | `partial` | `handler_damage`, `handler_stat`, `effects`, `ability` |
| `s_self_status` | `SelfStatus` | `10 Move/1 Mechanics/101 Self.rb` | `StatusStatMoveBehavior.selfStatus` | `partial` | `handler_damage`, `handler_status`, `effects`, `ability` |
| `s_shed_tail` | `ShedTail` | `10 Move/2 Definitions/300 Substitute.rb` | `TODO` | `missing` | `-` |
| `s_shell_side_arm` | `ShellSideArm` | `10 Move/2 Definitions/300 ShellSideArm.rb` | `TODO` | `missing` | `-` |
| `s_shell_trap` | `ShellTrap` | `10 Move/2 Definitions/300 PreAttackMoves.rb` | `TODO` | `missing` | `-` |
| `s_shore_up` | `ShoreUp` | `10 Move/2 Definitions/300 Shore Up.rb` | `HealMoveBehavior.shoreUp` | `partial` | `weather`, `handler_damage`, `effects` |
| `s_simple_beam` | `SimpleBeam` | `10 Move/2 Definitions/300 AbilityChanging.rb` | `TODO` | `missing` | `-` |
| `s_sketch` | `Sketch` | `10 Move/2 Definitions/300 Sketch.rb` | `TODO` | `missing` | `-` |
| `s_skill_swap` | `SkillSwap` | `10 Move/2 Definitions/300 AbilityChanging.rb` | `TODO` | `missing` | `-` |
| `s_sky_drop` | `SkyDrop` | `10 Move/2 Definitions/300 SkyDrop.rb` | `TODO` | `missing` | `-` |
| `s_sleep_talk` | `SleepTalk` | `10 Move/2 Definitions/300 SleepTalk.rb` | `TODO` | `missing` | `-` |
| `s_smack_down` | `SmackDown` | `10 Move/2 Definitions/300 SmackDown.rb` | `TODO` | `missing` | `-` |
| `s_smelling_salt` | `SmellingSalts` | `10 Move/2 Definitions/300 HitThenCureStatus.rb` | `HitThenCureStatusMoveBehavior.smellingSalt` | `partial` | `handler_damage`, `handler_status`, `effects` |
| `s_snatch` | `Snatch` | `10 Move/2 Definitions/300 Snatch.rb` | `TODO` | `missing` | `-` |
| `s_snore` | `Snore` | `10 Move/2 Definitions/300 Snore.rb` | `TODO` | `missing` | `-` |
| `s_solar_beam` | `SolarBeam` | `10 Move/2 Definitions/300 SolarBeam.rb` | `TODO` | `missing` | `weather`, `effects` |
| `s_sparkling_aria` | `SparklingAria` | `10 Move/2 Definitions/300 SparklingAria.rb` | `HitThenCureStatusMoveBehavior.sparklingAria` | `partial` | `handler_damage`, `handler_status`, `effects` |
| `s_sparkly_swirl` | `SparklySwirl` | `10 Move/2 Definitions/300 SparklySwirl.rb` | `TODO` | `missing` | `-` |
| `s_spectral_thief` | `SpectralThief` | `10 Move/2 Definitions/300 SpectralThief.rb` | `TODO` | `missing` | `-` |
| `s_speed_swap` | `SpeedSwap` | `10 Move/2 Definitions/300 Stages swap moves.rb` | `SpeedSwapMoveBehavior` | `ported` | `-` |
| `s_spike` | `Spikes` | `10 Move/2 Definitions/300 Spikes.rb` | `TODO` | `missing` | `-` |
| `s_spite` | `Spite` | `10 Move/2 Definitions/300 Spite.rb` | `TODO` | `missing` | `-` |
| `s_splash` | `Splash` | `10 Move/2 Definitions/300 Splash.rb` | `NoEffectMoveBehavior.splash` | `partial` | `-` |
| `s_split_up` | `SpitUp` | `10 Move/2 Definitions/300 SpitUp.rb` | `TODO` | `missing` | `-` |
| `s_stat` | `StatusStat` | `10 Move/1 Mechanics/102 Status Stat.rb` | `StatusStatMoveBehavior.stat` | `partial` | `handler_status`, `handler_stat`, `effects`, `ability` |
| `s_status` | `StatusStat` | `10 Move/1 Mechanics/102 Status Stat.rb` | `StatusStatMoveBehavior.status` | `partial` | `handler_status`, `handler_stat`, `effects`, `ability` |
| `s_stealth_rock` | `StealthRock` | `10 Move/2 Definitions/300 StealthRock.rb` | `TODO` | `missing` | `-` |
| `s_steel_beam` | `MindBlown` | `10 Move/2 Definitions/300 MindBlown.rb` | `MindBlownMoveBehavior.steelBeam` | `partial` | `ability`, `faint_process` |
| `s_steel_roller` | `SteelRoller` | `10 Move/2 Definitions/300 IceSpinner SteelRoller.rb` | `TODO` | `missing` | `-` |
| `s_sticky_web` | `StickyWeb` | `10 Move/2 Definitions/300 StickyWeb.rb` | `TODO` | `missing` | `-` |
| `s_stockpile` | `Stockpile` | `10 Move/2 Definitions/300 Stockpile.rb` | `TODO` | `missing` | `-` |
| `s_stomp` | `Stomp` | `10 Move/2 Definitions/300 Stomp.rb` | `TODO` | `missing` | `-` |
| `s_stomping_tantrum` | `StompingTantrum` | `10 Move/2 Definitions/300 StompingTantrum.rb` | `TODO` | `missing` | `-` |
| `s_stone_axe` | `StoneAxe` | `10 Move/2 Definitions/300 HazardsSetting.rb` | `TODO` | `missing` | `-` |
| `s_stored_power` | `StoredPower` | `10 Move/2 Definitions/300 StoredPower.rb` | `SpecialPowerMoveBehavior.storedPower` | `ported` | `-` |
| `s_strength_sap` | `StrengthSap` | `10 Move/2 Definitions/300 StrengthSap.rb` | `RecoveryStatMoveBehavior.strengthSap` | `partial` | `handler_damage`, `handler_stat`, `ability`, `item`, `effects` |
| `s_struggle` | `Struggle` | `10 Move/2 Definitions/300 RecoilMove.rb` | `TODO` | `missing` | `-` |
| `s_stuff_cheeks` | `StuffCheeks` | `10 Move/2 Definitions/300 StuffCheeks.rb` | `TODO` | `missing` | `-` |
| `s_substitute` | `Substitute` | `10 Move/2 Definitions/300 Substitute.rb` | `TODO` | `missing` | `-` |
| `s_sucker_punch` | `SuckerPunch` | `10 Move/2 Definitions/300 SuckerPunch.rb` | `TODO` | `missing` | `-` |
| `s_super_duper_effective` | `SuperDuperEffective` | `10 Move/2 Definitions/300 SuperDuperEffective.rb` | `TODO` | `missing` | `-` |
| `s_super_fang` | `SuperFang` | `10 Move/2 Definitions/300 SuperFang.rb` | `FixedDamageMoveBehavior.halfCurrentTargetHp` | `ported` | `-` |
| `s_swallow` | `Swallow` | `10 Move/2 Definitions/300 Swallow.rb` | `TODO` | `missing` | `-` |
| `s_synchronoise` | `Synchronoise` | `10 Move/2 Definitions/300 Synchronoise.rb` | `TODO` | `missing` | `-` |
| `s_syrup_bomb` | `SyrupBomb` | `10 Move/2 Definitions/300 SyrupBomb.rb` | `TODO` | `missing` | `-` |
| `s_tailwind` | `Tailwind` | `10 Move/2 Definitions/300 Tailwind.rb` | `TODO` | `missing` | `-` |
| `s_take_heart` | `TakeHeart` | `10 Move/2 Definitions/300 TakeHeart.rb` | `TODO` | `missing` | `-` |
| `s_tar_shot` | `TarShot` | `10 Move/2 Definitions/300 TarShot.rb` | `TODO` | `missing` | `-` |
| `s_taunt` | `Taunt` | `10 Move/2 Definitions/300 Taunt.rb` | `TODO` | `missing` | `-` |
| `s_teatime` | `Teatime` | `10 Move/2 Definitions/300 TeaTime.rb` | `TODO` | `missing` | `-` |
| `s_techno_blast` | `TechnoBlast` | `10 Move/2 Definitions/300 TechnoBlast.rb` | `TODO` | `missing` | `-` |
| `s_telekinesis` | `Telekinesis` | `10 Move/2 Definitions/300 Telekinesis.rb` | `TODO` | `missing` | `-` |
| `s_teleport` | `Teleport` | `10 Move/2 Definitions/300 Teleport.rb` | `TODO` | `missing` | `-` |
| `s_terrain` | `TerrainMove` | `10 Move/2 Definitions/300 TerrainMove.rb` | `TerrainMoveBehavior` | `partial` | `handler_terrain`, `terrain`, `effects`, `item` |
| `s_terrain_boosting` | `TerrainBoosting` | `10 Move/2 Definitions/300 TerrainBoosting.rb` | `TerrainPowerMoveBehavior.terrainBoosting` | `ported` | `-` |
| `s_terrain_pulse` | `TerrainPulse` | `10 Move/2 Definitions/300 TerrainPulse.rb` | `TODO` | `missing` | `terrain`, `grounded` |
| `s_thief` | `Thief` | `10 Move/2 Definitions/300 Thief.rb` | `TODO` | `missing` | `-` |
| `s_thing_sport` | `MudSport` | `10 Move/2 Definitions/300 MudSport.rb` | `TODO` | `missing` | `-` |
| `s_thrash` | `Thrash` | `10 Move/2 Definitions/300 Thrash.rb` | `TODO` | `missing` | `-` |
| `s_throat_chop` | `ThroatChop` | `10 Move/2 Definitions/300 ThroatChop.rb` | `TODO` | `missing` | `-` |
| `s_thunder` | `Thunder` | `10 Move/2 Definitions/300 Thunder.rb` | `TODO` | `missing` | `weather` |
| `s_tidy_up` | `TidyUp` | `10 Move/2 Definitions/300 TidyUp.rb` | `TODO` | `missing` | `-` |
| `s_topsy_turvy` | `TopsyTurvy` | `10 Move/2 Definitions/300 TopsyTurvy.rb` | `AdvancedStatMoveBehavior.topsyTurvy` | `partial` | `handler_stat`, `effects`, `ability` |
| `s_torment` | `Torment` | `10 Move/2 Definitions/300 Torment.rb` | `TODO` | `missing` | `-` |
| `s_toxic_spike` | `ToxicSpikes` | `10 Move/2 Definitions/300 Toxic_Spikes.rb` | `TODO` | `missing` | `-` |
| `s_toxic_thread` | `ToxicThread` | `10 Move/2 Definitions/300 ToxicThread.rb` | `TODO` | `missing` | `-` |
| `s_transform` | `Transform` | `10 Move/2 Definitions/300 Transform.rb` | `TransformMoveBehavior` | `partial` | `handler_switch`, `effects`, `ability` |
| `s_tri_attack` | `TriAttack` | `10 Move/2 Definitions/300 TriAttack.rb` | `TODO` | `missing` | `-` |
| `s_trick` | `Switcheroo` | `10 Move/2 Definitions/300 Switcheroo.rb` | `TODO` | `missing` | `-` |
| `s_trick_room` | `TrickRoom` | `10 Move/2 Definitions/300 TrickRoom.rb` | `TODO` | `missing` | `-` |
| `s_triple_arrows` | `TripleArrows` | `10 Move/2 Definitions/300 TripleArrows.rb` | `TODO` | `missing` | `-` |
| `s_triple_kick` | `TripleKick` | `10 Move/1 Mechanics/103 TwoHit MultiHit.rb` | `MultiHitMoveBehavior.tripleKick` | `partial` | `ability`, `item`, `history` |
| `s_trump_card` | `TrumpCard` | `10 Move/2 Definitions/300 TrumpCard.rb` | `TODO` | `missing` | `-` |
| `s_u_turn` | `UTurn` | `10 Move/2 Definitions/300 UTurn.rb` | `TODO` | `missing` | `-` |
| `s_upper_hand` | `UpperHand` | `10 Move/2 Definitions/300 UpperHand.rb` | `TODO` | `missing` | `-` |
| `s_uproar` | `UpRoar` | `10 Move/2 Definitions/300 UpRoar.rb` | `TODO` | `missing` | `-` |
| `s_venom_drench` | `VenomDrench` | `10 Move/2 Definitions/300 VenomDrench.rb` | `TODO` | `missing` | `-` |
| `s_venoshock` | `Venoshock` | `10 Move/2 Definitions/300 Venoshock.rb` | `VariablePowerMoveBehavior.venoshock` | `ported` | `-` |
| `s_wakeup_slap` | `WakeUpSlap` | `10 Move/2 Definitions/300 HitThenCureStatus.rb` | `HitThenCureStatusMoveBehavior.wakeUpSlap` | `partial` | `handler_damage`, `handler_status`, `effects`, `ability` |
| `s_water_shuriken` | `WaterShuriken` | `10 Move/1 Mechanics/103 TwoHit MultiHit.rb` | `MultiHitMoveBehavior.waterShuriken` | `partial` | `ability`, `item` |
| `s_weather` | `WeatherMove` | `10 Move/2 Definitions/300 WeatherMove.rb` | `WeatherMoveBehavior` | `partial` | `handler_weather`, `weather`, `effects`, `item` |
| `s_weather_ball` | `WeatherBall` | `10 Move/2 Definitions/300 WeatherBall.rb` | `WeatherPowerMoveBehavior.weatherBall` | `partial` | `weather`, `ability` |
| `s_wish` | `Wish` | `10 Move/2 Definitions/300 Wish.rb` | `TODO` | `missing` | `-` |
| `s_wonder_room` | `WonderRoom` | `10 Move/2 Definitions/300 WonderRoom.rb` | `TODO` | `missing` | `-` |
| `s_worry_seed` | `WorrySeed` | `10 Move/2 Definitions/300 AbilityChanging.rb` | `TODO` | `missing` | `-` |
| `s_wring_out` | `WringOut` | `10 Move/2 Definitions/300 WringOut.rb` | `VariablePowerMoveBehavior.wringOut` | `ported` | `-` |
| `s_yawn` | `Yawn` | `10 Move/2 Definitions/300 Yawn.rb` | `TODO` | `missing` | `-` |
