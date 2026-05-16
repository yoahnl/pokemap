# PSDK Move Porting Matrix

Source: `../../pokemonsdk-development/scripts/5 Battle`

Total registered methods: 330

| Status | Count |
| --- | ---: |
| `ported` | 63 |
| `partial` | 267 |
| `missing` | 0 |

| Method | Ruby class | Ruby path | Dart behavior | Status | Dependencies |
| --- | --- | --- | --- | --- | --- |
| `s_2hits` | `TwoHit` | `10 Move/1 Mechanics/103 TwoHit MultiHit.rb` | `MultiHitMoveBehavior.fixed(2)` | `ported` | `-` |
| `s_2turns` | `TwoTurnBase` | `10 Move/1 Mechanics/110 TwoTurnBase.rb` | `StaticBasicMoveRegistry.s_2turns` | `ported` | `effects`, `action_order`, `weather`, `item`, `targeting_multi` |
| `s_3hits` | `ThreeHit` | `10 Move/1 Mechanics/103 TwoHit MultiHit.rb` | `MultiHitMoveBehavior.fixed(3)` | `ported` | `-` |
| `s_a_fang` | `Fangs` | `10 Move/2 Definitions/300 Fangs.rb` | `BasicDamageSpecializationMoveBehavior.fangs` | `partial` | `handler_status`, `effects`, `ability` |
| `s_absorb` | `Absorb` | `10 Move/2 Definitions/300 Absorb.rb` | `DrainMoveBehavior.absorb` | `ported` | `handler_damage`, `effects`, `item`, `ability` |
| `s_acrobatics` | `Acrobatics` | `10 Move/2 Definitions/300 Acrobatics.rb` | `SpecialPowerMoveBehavior.acrobatics` | `partial` | `item` |
| `s_acupressure` | `Acupressure` | `10 Move/2 Definitions/300 Acupressure.rb` | `AdvancedStatMoveBehavior.acupressure` | `partial` | `handler_stat`, `effects`, `ability` |
| `s_add_type` | `AddThirdType` | `10 Move/2 Definitions/300 AddThirdType.rb` | `StaticBasicMoveRegistry.s_add_type` | `partial` | `effects`, `ability` |
| `s_after_you` | `AfterYou` | `10 Move/2 Definitions/300 After you.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_after_you)` | `partial` | `-` |
| `s_alluring_voice` | `AlluringVoice` | `10 Move/2 Definitions/300 AlluringVoice.rb` | `SpecialSecondaryMoveBehavior.alluringVoice` | `partial` | `-` |
| `s_ally_switch` | `AllySwitch` | `10 Move/2 Definitions/300 AllySwitch.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_ally_switch)` | `partial` | `-` |
| `s_aqua_ring` | `AquaRing` | `10 Move/2 Definitions/300 AquaRing.rb` | `PersistentEffectMoveBehavior.aquaRing` | `partial` | `handler_damage`, `effects`, `end_turn`, `item` |
| `s_assist` | `Assist` | `10 Move/2 Definitions/300 Assist.rb` | `CopyCallMoveBehavior.assist` | `partial` | `-` |
| `s_assurance` | `Assurance` | `10 Move/2 Definitions/300 Assurance.rb` | `HistoryPowerMoveBehavior.assurance` | `partial` | `-` |
| `s_attract` | `Attract` | `10 Move/2 Definitions/300 Attract.rb` | `StaticBasicMoveRegistry.attract` | `partial` | `-` |
| `s_aura_wheel` | `AuraWheel` | `10 Move/2 Definitions/300 AuraWheel.rb` | `StaticBasicMoveRegistry.partialBasic(s_aura_wheel)` | `partial` | `-` |
| `s_autotomize` | `Autotomize` | `10 Move/2 Definitions/300 Autotomize.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_autotomize)` | `partial` | `-` |
| `s_avalanche` | `Avalanche` | `10 Move/2 Definitions/300 Avalanche.rb` | `HistoryPowerMoveBehavior.avalanche` | `partial` | `-` |
| `s_baddy_bad` | `BaddyBad` | `10 Move/2 Definitions/300 GlitzyGlow.rb` | `StaticBasicMoveRegistry.s_baddy_bad` | `partial` | `-` |
| `s_basic` | `Basic` | `10 Move/1 Mechanics/100 Basic.rb` | `StaticBasicMoveRegistry.s_basic` | `ported` | `-` |
| `s_baton_pass` | `BatonPass` | `10 Move/2 Definitions/300 BatonPass.rb` | `SwitchEffectMoveBehavior.batonPass` | `partial` | `handler_switch`, `effects` |
| `s_beak_blast` | `BeakBlast` | `10 Move/2 Definitions/300 PreAttackMoves.rb` | `StaticBasicMoveRegistry.partialBasic(s_beak_blast)` | `partial` | `-` |
| `s_beat_up` | `BeatUp` | `10 Move/2 Definitions/300 BeatUp.rb` | `StaticBasicMoveRegistry.partialBasic(s_beat_up)` | `partial` | `-` |
| `s_belch` | `Belch` | `10 Move/2 Definitions/300 Belch.rb` | `ItemDependentMoveBehavior.belch` | `partial` | `-` |
| `s_bellydrum` | `BellyDrum` | `10 Move/2 Definitions/300 BellyDrum.rb` | `RecoveryStatMoveBehavior.bellyDrum` | `partial` | `handler_damage`, `handler_stat`, `ability`, `effects` |
| `s_bestow` | `Bestow` | `10 Move/2 Definitions/300 Bestow.rb` | `ItemDependentMoveBehavior.bestow` | `partial` | `-` |
| `s_bide` | `Bide` | `10 Move/2 Definitions/300 Bide.rb` | `CounterDamageMoveBehavior.bide` | `partial` | `-` |
| `s_bind` | `Bind` | `10 Move/2 Definitions/300 Bind.rb` | `StaticBasicMoveRegistry.s_bind` | `ported` | `-` |
| `s_bitter_malice` | `InfernalParade` | `10 Move/2 Definitions/300 StatusBoostedMove.rb` | `VariablePowerMoveBehavior.bitterMalice` | `ported` | `-` |
| `s_body_press` | `BodyPress` | `10 Move/2 Definitions/300 BodyPress.rb` | `CustomStatSourceMoveBehavior.bodyPress` | `partial` | `handler_damage`, `ability`, `item` |
| `s_brick_break` | `BrickBreak` | `10 Move/2 Definitions/300 BrickBreak.rb` | `StaticBasicMoveRegistry.s_brick_break` | `partial` | `effects` |
| `s_brine` | `Brine` | `10 Move/2 Definitions/300 Brine.rb` | `VariablePowerMoveBehavior.brine` | `ported` | `-` |
| `s_burn_up` | `BurnUp` | `10 Move/2 Definitions/300 BurnUp.rb` | `SpecialSecondaryMoveBehavior.burnUp` | `partial` | `-` |
| `s_burning_jealousy` | `BurningJealousy` | `10 Move/2 Definitions/300 AlluringVoice.rb` | `SpecialSecondaryMoveBehavior.burningJealousy` | `partial` | `-` |
| `s_camouflage` | `Camouflage` | `10 Move/2 Definitions/300 Camouflage.rb` | `FieldLocationMoveBehavior.camouflage` | `partial` | `-` |
| `s_cantflee` | `CantSwitch` | `10 Move/2 Definitions/300 CantSwitch.rb` | `StaticBasicMoveRegistry.s_cantflee` | `ported` | `-` |
| `s_captivate` | `Captivate` | `10 Move/2 Definitions/300 Captivate.rb` | `StaticBasicMoveRegistry.secondaryOnly(s_captivate)` | `partial` | `-` |
| `s_ceaseless_edge` | `CeaselessEdge` | `10 Move/2 Definitions/300 HazardsSetting.rb` | `StaticBasicMoveRegistry.s_ceaseless_edge` | `ported` | `-` |
| `s_change_type` | `ChangeType` | `10 Move/2 Definitions/300 ChangeType.rb` | `StaticBasicMoveRegistry.s_change_type` | `partial` | `-` |
| `s_charge` | `Charge` | `10 Move/2 Definitions/300 Charge.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_charge)` | `partial` | `-` |
| `s_chilly_reception` | `ChillyReception` | `10 Move/2 Definitions/300 ChillyReception.rb` | `StaticBasicMoveRegistry.partialFieldMarker(s_chilly_reception)` | `partial` | `-` |
| `s_chloroblast` | `MindBlown` | `10 Move/2 Definitions/300 MindBlown.rb` | `MindBlownMoveBehavior.chloroblast` | `partial` | `ability`, `faint_process` |
| `s_clangorous_soul` | `ClangorousSoul` | `10 Move/2 Definitions/300 ClangorousSoul.rb` | `AdvancedStatMoveBehavior.clangorousSoul` | `partial` | `handler_damage`, `handler_stat`, `effects`, `ability` |
| `s_conversion` | `Conversion` | `10 Move/2 Definitions/300 Conversion.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_conversion)` | `partial` | `-` |
| `s_conversion2` | `Conversion2` | `10 Move/2 Definitions/300 Conversion.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_conversion2)` | `partial` | `-` |
| `s_core_enforcer` | `CoreEnforcer` | `10 Move/2 Definitions/300 CoreEnforcer.rb` | `StaticBasicMoveRegistry.partialBasic(s_core_enforcer)` | `partial` | `-` |
| `s_corrosive_gas` | `CorrosiveGas` | `10 Move/2 Definitions/300 CorrosiveGas.rb` | `StaticBasicMoveRegistry.s_corrosive_gas` | `partial` | `-` |
| `s_counter` | `Counter` | `10 Move/2 Definitions/300 Counter moves.rb` | `CounterDamageMoveBehavior.counter` | `partial` | `-` |
| `s_court_change` | `CourtChange` | `10 Move/2 Definitions/300 CourtChange.rb` | `StaticBasicMoveRegistry.partialFieldMarker(s_court_change)` | `partial` | `-` |
| `s_crafty_shield` | `CraftyShield` | `10 Move/2 Definitions/300 CraftyShield.rb` | `StaticBasicMoveRegistry.partialUserBankMarker(s_crafty_shield)` | `partial` | `-` |
| `s_curse` | `Curse` | `10 Move/2 Definitions/300 Curse.rb` | `AdvancedStatMoveBehavior.curse` | `partial` | `handler_damage`, `handler_stat`, `effects`, `end_turn` |
| `s_custom_stats_based` | `CustomStatsBased` | `10 Move/2 Definitions/300 CustomStatsBased.rb` | `CustomStatSourceMoveBehavior.customStatsBased` | `partial` | `handler_damage`, `ability`, `item` |
| `s_defog` | `Defog` | `10 Move/2 Definitions/300 Defog.rb` | `StaticBasicMoveRegistry.s_defog` | `ported` | `-` |
| `s_destiny_bond` | `DestinyBond` | `10 Move/2 Definitions/300 DestinyBond.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_destiny_bond)` | `partial` | `-` |
| `s_disable` | `Disable` | `10 Move/2 Definitions/300 Disable.rb` | `StaticBasicMoveRegistry.disable` | `partial` | `-` |
| `s_do_nothing` | `DoNothing` | `10 Move/2 Definitions/300 Splash.rb` | `NoEffectMoveBehavior.doNothing` | `ported` | `-` |
| `s_doodle` | `Doodle` | `10 Move/2 Definitions/300 AbilityChanging.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_doodle)` | `partial` | `-` |
| `s_double_iron_bash` | `DoubleIronBash` | `10 Move/2 Definitions/300 DoubleIronBash.rb` | `MultiHitMoveBehavior.doubleIronBash` | `partial` | `-` |
| `s_dragon_cheer` | `DragonCheer` | `10 Move/2 Definitions/300 DragonCheer.rb` | `StaticBasicMoveRegistry.partialUserBankMarker(s_dragon_cheer)` | `partial` | `-` |
| `s_dragon_darts` | `DragonDarts` | `10 Move/2 Definitions/300 DragonDarts.rb` | `StaticBasicMoveRegistry.partialBasic(s_dragon_darts)` | `partial` | `-` |
| `s_dragon_tail` | `ForceSwitch` | `10 Move/2 Definitions/300 ForceSwitch.rb` | `StaticBasicMoveRegistry.forceSwitch(s_dragon_tail)` | `partial` | `handler_switch`, `effects`, `ability` |
| `s_dream_eater` | `Absorb` | `10 Move/2 Definitions/300 Absorb.rb` | `DrainMoveBehavior.dreamEater` | `partial` | `handler_damage`, `handler_status`, `effects`, `item`, `ability` |
| `s_echo` | `EchoedVoice` | `10 Move/2 Definitions/300 EchoedVoice.rb` | `ConsecutivePowerMoveBehavior.echoedVoice` | `partial` | `-` |
| `s_eerie_spell` | `EerieSpell` | `10 Move/2 Definitions/300 EerieSpell.rb` | `StaticBasicMoveRegistry.s_eerie_spell` | `partial` | `-` |
| `s_electrify` | `Electrify` | `10 Move/2 Definitions/300 Electrify.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_electrify)` | `partial` | `-` |
| `s_electro_ball` | `ElectroBall` | `10 Move/2 Definitions/300 ElectroBall.rb` | `VariablePowerMoveBehavior.electroBall` | `ported` | `-` |
| `s_electro_shot` | `ElectroShot` | `10 Move/2 Definitions/300 ElectroShot.rb` | `StaticBasicMoveRegistry.s_electro_shot` | `partial` | `-` |
| `s_embargo` | `Embargo` | `10 Move/2 Definitions/300 Embargo.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_embargo)` | `partial` | `-` |
| `s_encore` | `Encore` | `10 Move/2 Definitions/300 Encore.rb` | `StaticBasicMoveRegistry.encore` | `partial` | `-` |
| `s_endeavor` | `Endeavor` | `10 Move/2 Definitions/300 Endeavor.rb` | `DirectHpMoveBehavior.endeavor` | `ported` | `-` |
| `s_entrainment` | `Entrainment` | `10 Move/2 Definitions/300 AbilityChanging.rb` | `StaticBasicMoveRegistry.partialAbilityChanging(s_entrainment)` | `partial` | `-` |
| `s_eruption` | `Eruption` | `10 Move/2 Definitions/300 Eruption.rb` | `VariablePowerMoveBehavior.eruption` | `ported` | `-` |
| `s_expanding_force` | `ExpandingForce` | `10 Move/2 Definitions/300 TerrainDamageMoves.rb` | `TerrainPowerMoveBehavior.expandingForce` | `partial` | `terrain`, `grounded`, `targeting_multi` |
| `s_explosion` | `SelfDestruct` | `10 Move/2 Definitions/300 SelfDestruct.rb` | `SelfDestructMoveBehavior.explosion` | `partial` | `ability`, `faint_process` |
| `s_facade` | `Facade` | `10 Move/2 Definitions/300 StatusBoostedMove.rb` | `VariablePowerMoveBehavior.facade` | `ported` | `-` |
| `s_fairy_lock` | `FairyLock` | `10 Move/2 Definitions/300 FairyLock.rb` | `StaticBasicMoveRegistry.partialFieldMarker(s_fairy_lock)` | `partial` | `-` |
| `s_fake_out` | `FakeOut` | `10 Move/2 Definitions/300 FakeOut.rb` | `ActionGatedMoveBehavior.fakeOut` | `partial` | `-` |
| `s_false_swipe` | `FalseSwipe` | `10 Move/2 Definitions/300 FalseSwipe.rb` | `BasicDamageSpecializationMoveBehavior.falseSwipe` | `partial` | `effects` |
| `s_feint` | `Feint` | `10 Move/2 Definitions/300 Feint.rb` | `StaticBasicMoveRegistry.s_feint` | `partial` | `-` |
| `s_fell_stinger` | `FellStinger` | `10 Move/2 Definitions/300 FellStinger.rb` | `StaticBasicMoveRegistry.s_fell_stinger` | `partial` | `-` |
| `s_fickle_beam` | `FickleBeam` | `10 Move/2 Definitions/300 FickleBeam.rb` | `StaticBasicMoveRegistry.s_fickle_beam` | `partial` | `-` |
| `s_fillet_away` | `FilletAway` | `10 Move/2 Definitions/300 BellyDrum.rb` | `RecoveryStatMoveBehavior.filletAway` | `partial` | `handler_damage`, `handler_stat`, `ability`, `effects` |
| `s_final_gambit` | `FinalGambit` | `10 Move/2 Definitions/300 FinalGambit.rb` | `DirectHpMoveBehavior.finalGambit` | `partial` | `faint_process`, `history` |
| `s_fishious_rend` | `FishiousRend` | `10 Move/2 Definitions/300 FishiousRend.rb` | `HistoryPowerMoveBehavior.fishiousRend` | `partial` | `-` |
| `s_fixed_damage` | `FixedDamages` | `10 Move/2 Definitions/300 FixedDamages.rb` | `FixedDamageMoveBehavior.psdkFixedDamage` | `ported` | `-` |
| `s_flail` | `Flail` | `10 Move/2 Definitions/300 Flail.rb` | `VariablePowerMoveBehavior.flail` | `ported` | `-` |
| `s_flame_burst` | `FlameBurst` | `10 Move/2 Definitions/300 FlameBurst.rb` | `StaticBasicMoveRegistry.s_flame_burst` | `partial` | `-` |
| `s_fling` | `Fling` | `10 Move/2 Definitions/300 Fling.rb` | `ItemDependentMoveBehavior.fling` | `partial` | `-` |
| `s_floral_healing` | `FloralHealing` | `10 Move/2 Definitions/300 FloralHealing.rb` | `HealMoveBehavior.floralHealing` | `partial` | `handler_damage`, `terrain`, `effects`, `ability` |
| `s_flower_shield` | `FlowerShield` | `10 Move/2 Definitions/300 FlowerShield.rb` | `StaticBasicMoveRegistry.partialUserBankMarker(s_flower_shield)` | `partial` | `-` |
| `s_flying_press` | `FlyingPress` | `10 Move/2 Definitions/300 FlyingPress.rb` | `StaticBasicMoveRegistry.partialBasic(s_flying_press)` | `partial` | `-` |
| `s_focus_energy` | `FocusEnergy` | `10 Move/2 Definitions/300 FocusEnergy.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_focus_energy)` | `partial` | `-` |
| `s_focus_punch` | `FocusPunch` | `10 Move/2 Definitions/300 PreAttackMoves.rb` | `StaticBasicMoveRegistry.partialBasic(s_focus_punch)` | `partial` | `-` |
| `s_follow_me` | `FollowMe` | `10 Move/2 Definitions/300 FollowMe.rb` | `StaticBasicMoveRegistry.s_follow_me` | `partial` | `effects`, `action_order`, `targeting_multi` |
| `s_foresight` | `Foresight` | `10 Move/2 Definitions/300 Foresight.rb` | `StaticBasicMoveRegistry.s_foresight` | `partial` | `effects` |
| `s_foul_play` | `FoulPlay` | `10 Move/2 Definitions/300 FoulPlay.rb` | `CustomStatSourceMoveBehavior.foulPlay` | `partial` | `handler_damage`, `ability`, `item` |
| `s_freezy_frost` | `FreezyFrost` | `10 Move/2 Definitions/300 FreezyFrost.rb` | `StaticBasicMoveRegistry.s_freezy_frost` | `partial` | `-` |
| `s_frustration` | `Frustration` | `10 Move/2 Definitions/300 Frustration.rb` | `StaticBasicMoveRegistry.partialBasic(s_frustration)` | `partial` | `-` |
| `s_full_crit` | `FullCrit` | `10 Move/2 Definitions/300 FullCrit.rb` | `BasicDamageSpecializationMoveBehavior.fullCrit` | `ported` | `-` |
| `s_fury_cutter` | `FuryCutter` | `10 Move/2 Definitions/300 FuryCutter.rb` | `ConsecutivePowerMoveBehavior.furyCutter` | `partial` | `-` |
| `s_fusion_bolt` | `FusionBolt` | `10 Move/2 Definitions/300 FusionFlareBolt.rb` | `StaticBasicMoveRegistry.s_fusion_bolt` | `partial` | `-` |
| `s_fusion_flare` | `FusionFlare` | `10 Move/2 Definitions/300 FusionFlareBolt.rb` | `StaticBasicMoveRegistry.s_fusion_flare` | `partial` | `-` |
| `s_future_sight` | `FutureSight` | `10 Move/2 Definitions/300 FutureSight.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_future_sight)` | `partial` | `effects`, `end_turn`, `handler_damage`, `handler_switch` |
| `s_gastro_acid` | `GastroAcid` | `10 Move/2 Definitions/300 GastroAcid.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_gastro_acid)` | `partial` | `-` |
| `s_gear_up` | `GearUp` | `10 Move/2 Definitions/300 GearUp.rb` | `StaticBasicMoveRegistry.partialUserBankMarker(s_gear_up)` | `partial` | `-` |
| `s_genies_storm` | `GeniesStorm` | `10 Move/2 Definitions/300 GeniesStorm.rb` | `WeatherPowerMoveBehavior.geniesStorm` | `partial` | `-` |
| `s_geomancy` | `Geomancy` | `10 Move/2 Definitions/300 Geomancy.rb` | `StaticBasicMoveRegistry.partialUserBankMarker(s_geomancy)` | `partial` | `-` |
| `s_gigaton_hammer` | `GigatonHammer` | `10 Move/2 Definitions/300 GigatonHammer.rb` | `ForcedActionMoveBehavior.gigatonHammer` | `partial` | `-` |
| `s_glaive_rush` | `GlaiveRush` | `10 Move/2 Definitions/300 GlaiveRush.rb` | `StaticBasicMoveRegistry.s_glaive_rush` | `partial` | `-` |
| `s_glitzy_glow` | `GlitzyGlow` | `10 Move/2 Definitions/300 GlitzyGlow.rb` | `StaticBasicMoveRegistry.s_glitzy_glow` | `partial` | `-` |
| `s_grassy_glide` | `GrassyGlide` | `10 Move/2 Definitions/300 TerrainDamageMoves.rb` | `TerrainPowerMoveBehavior.grassyGlide` | `ported` | `terrain`, `grounded`, `action_order` |
| `s_grav_apple` | `GravApple` | `10 Move/2 Definitions/300 GravApple.rb` | `StaticBasicMoveRegistry.s_grav_apple` | `partial` | `-` |
| `s_gravity` | `Gravity` | `10 Move/2 Definitions/300 Gravity.rb` | `StaticBasicMoveRegistry.partialFieldMarker(s_gravity)` | `partial` | `-` |
| `s_growth` | `Growth` | `10 Move/2 Definitions/300 Growth.rb` | `AdvancedStatMoveBehavior.growth` | `partial` | `handler_stat`, `weather`, `effects`, `ability` |
| `s_grudge` | `Grudge` | `10 Move/2 Definitions/300 Grudge.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_grudge)` | `partial` | `-` |
| `s_guard_split` | `GuardSplit` | `10 Move/2 Definitions/300 Stages split moves.rb` | `StatSplitMoveBehavior.guard` | `ported` | `-` |
| `s_guard_swap` | `GuardSwap` | `10 Move/2 Definitions/300 Stages swap moves.rb` | `AdvancedStatMoveBehavior.guardSwap` | `partial` | `handler_stat`, `effects`, `ability` |
| `s_gyro_ball` | `GyroBall` | `10 Move/2 Definitions/300 GyroBall.rb` | `VariablePowerMoveBehavior.gyroBall` | `partial` | `-` |
| `s_happy_hour` | `HappyHour` | `10 Move/2 Definitions/300 HappyHour.rb` | `StaticBasicMoveRegistry.partialFieldMarker(s_happy_hour)` | `partial` | `-` |
| `s_hard_press` | `HardPress` | `10 Move/2 Definitions/300 WringOut.rb` | `VariablePowerMoveBehavior.hardPress` | `ported` | `-` |
| `s_haze` | `Haze` | `10 Move/2 Definitions/300 Haze.rb` | `AdvancedStatMoveBehavior.haze` | `partial` | `handler_stat`, `effects`, `ability`, `targeting_multi` |
| `s_heal` | `HealMove` | `10 Move/1 Mechanics/105 Heal.rb` | `HealMoveBehavior` | `ported` | `handler_damage`, `effects`, `ability` |
| `s_heal_bell` | `HealBell` | `10 Move/2 Definitions/300 HealBell.rb` | `StatusCureMoveBehavior.healBell` | `partial` | `handler_status`, `effects`, `ability`, `targeting_multi` |
| `s_heal_block` | `HealBlock` | `10 Move/2 Definitions/300 HealBlock.rb` | `StaticBasicMoveRegistry.healBlock` | `partial` | `-` |
| `s_heal_weather` | `HealWeather` | `10 Move/2 Definitions/300 HealWeather.rb` | `HealMoveBehavior.weather` | `ported` | `handler_damage`, `weather`, `effects`, `ability` |
| `s_healing_wish` | `HealingWish` | `10 Move/2 Definitions/300 HealingSacrifice.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_healing_wish)` | `partial` | `-` |
| `s_heart_swap` | `HeartSwap` | `10 Move/2 Definitions/300 Stages swap moves.rb` | `AdvancedStatMoveBehavior.heartSwap` | `partial` | `handler_stat`, `effects`, `ability` |
| `s_heavy_slam` | `HeavySlam` | `10 Move/2 Definitions/300 HeavySlam.rb` | `WeightPowerMoveBehavior.heavySlam` | `partial` | `effects`, `ability` |
| `s_helping_hand` | `HelpingHand` | `10 Move/2 Definitions/300 HelpingHand.rb` | `StaticBasicMoveRegistry.partialUserBankMarker(s_helping_hand)` | `partial` | `-` |
| `s_hex` | `Hex` | `10 Move/2 Definitions/300 Hex.rb` | `VariablePowerMoveBehavior.hex` | `partial` | `ability`, `handler_status` |
| `s_hidden_power` | `HiddenPower` | `10 Move/2 Definitions/300 HiddenPower.rb` | `StaticBasicMoveRegistry.partialBasic(s_hidden_power)` | `partial` | `-` |
| `s_hp_eq_level` | `HPEqLevel` | `10 Move/2 Definitions/300 HPEqLevel.rb` | `FixedDamageMoveBehavior.userLevel` | `ported` | `-` |
| `s_hurricane` | `Thunder` | `10 Move/2 Definitions/300 Thunder.rb` | `WeatherPowerMoveBehavior.hurricane` | `ported` | `weather`, `accuracy`, `handler_status` |
| `s_ice_ball` | `Rollout` | `10 Move/2 Definitions/300 Rollout.rb` | `ConsecutivePowerMoveBehavior.iceBall` | `partial` | `effects`, `history`, `accuracy` |
| `s_ice_spinner` | `IceSpinner` | `10 Move/2 Definitions/300 IceSpinner SteelRoller.rb` | `StaticBasicMoveRegistry.s_ice_spinner` | `partial` | `-` |
| `s_imprison` | `Imprison` | `10 Move/2 Definitions/300 Imprison.rb` | `StaticBasicMoveRegistry.imprison` | `partial` | `-` |
| `s_incinerate` | `Incinerate` | `10 Move/2 Definitions/300 Incinerate.rb` | `SpecialSecondaryMoveBehavior.incinerate` | `partial` | `-` |
| `s_infernal_parade` | `InfernalParade` | `10 Move/2 Definitions/300 StatusBoostedMove.rb` | `VariablePowerMoveBehavior.infernalParade` | `ported` | `-` |
| `s_ingrain` | `Ingrain` | `10 Move/2 Definitions/300 Ingrain.rb` | `PersistentEffectMoveBehavior.ingrain` | `partial` | `handler_damage`, `handler_switch`, `effects`, `end_turn`, `item` |
| `s_instruct` | `Instruct` | `10 Move/2 Definitions/300 Instruct.rb` | `CopyCallMoveBehavior.instruct` | `partial` | `-` |
| `s_ion_deluge` | `IonDeluge` | `10 Move/2 Definitions/300 Ion Deluge.rb` | `StaticBasicMoveRegistry.partialFieldMarker(s_ion_deluge)` | `partial` | `-` |
| `s_ivy_cudgel` | `IvyCudgel` | `10 Move/2 Definitions/300 IvyCudgel.rb` | `TypeBasedMoveBehavior.ivyCudgel` | `partial` | `-` |
| `s_jaw_lock` | `JawLock` | `10 Move/2 Definitions/300 JawLock.rb` | `StaticBasicMoveRegistry.s_jaw_lock` | `partial` | `-` |
| `s_judgment` | `Judgment` | `10 Move/2 Definitions/300 Judgment.rb` | `TypeBasedMoveBehavior.judgment` | `partial` | `-` |
| `s_jump_kick` | `HighJumpKick` | `10 Move/2 Definitions/300 HighJumpKick.rb` | `StaticBasicMoveRegistry.s_jump_kick` | `partial` | `-` |
| `s_jungle_healing` | `JungleHealing` | `10 Move/2 Definitions/300 LifeDew.rb` | `HealMoveBehavior.jungleHealing` | `partial` | `handler_damage`, `handler_status`, `effects`, `targeting_multi` |
| `s_knock_off` | `KnockOff` | `10 Move/2 Definitions/300 KnockOff.rb` | `ItemDependentMoveBehavior.knockOff` | `partial` | `-` |
| `s_laser_focus` | `LaserFocus` | `10 Move/2 Definitions/300 LaserFocus.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_laser_focus)` | `partial` | `-` |
| `s_lash_out` | `LashOut` | `10 Move/2 Definitions/300 LashOut.rb` | `HistoryPowerMoveBehavior.lashOut` | `partial` | `-` |
| `s_last_resort` | `LastResort` | `10 Move/2 Definitions/300 LastResort.rb` | `StaticBasicMoveRegistry.s_last_resort` | `partial` | `-` |
| `s_last_respects` | `LastRespects` | `10 Move/2 Definitions/300 LastRespects.rb` | `StaticBasicMoveRegistry.s_last_respects` | `partial` | `-` |
| `s_leech_seed` | `LeechSeed` | `10 Move/2 Definitions/300 LeechSeed.rb` | `PersistentEffectMoveBehavior.leechSeed` | `partial` | `handler_damage`, `effects`, `end_turn`, `ability` |
| `s_life_dew` | `LifeDew` | `10 Move/2 Definitions/300 LifeDew.rb` | `HealMoveBehavior.lifeDew` | `partial` | `handler_damage`, `effects`, `targeting_multi` |
| `s_lock_on` | `LockOn` | `10 Move/2 Definitions/300 LockOn.rb` | `StaticBasicMoveRegistry.s_lock_on` | `partial` | `-` |
| `s_low_kick` | `LowKick` | `10 Move/2 Definitions/300 LowKick.rb` | `WeightPowerMoveBehavior.lowKick` | `partial` | `effects`, `ability`, `grounded` |
| `s_lucky_chant` | `LuckyChant` | `10 Move/2 Definitions/300 LuckyChant.rb` | `StaticBasicMoveRegistry.s_lucky_chant` | `ported` | `-` |
| `s_lunar_dance` | `LunarDance` | `10 Move/2 Definitions/300 HealingSacrifice.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_lunar_dance)` | `partial` | `-` |
| `s_magic_coat` | `MagicCoat` | `10 Move/2 Definitions/300 MagicCoat.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_magic_coat)` | `partial` | `-` |
| `s_magic_powder` | `MagicPowder` | `10 Move/2 Definitions/300 MagicPowder.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_magic_powder)` | `partial` | `-` |
| `s_magic_room` | `MagicRoom` | `10 Move/2 Definitions/300 MagicRoom.rb` | `StaticBasicMoveRegistry.partialFieldMarker(s_magic_room)` | `partial` | `-` |
| `s_magnet_rise` | `MagnetRise` | `10 Move/2 Definitions/300 MagnetRise.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_magnet_rise)` | `partial` | `-` |
| `s_magnetic_flux` | `MagneticFlux` | `10 Move/2 Definitions/300 MagneticFlux.rb` | `StaticBasicMoveRegistry.partialUserBankMarker(s_magnetic_flux)` | `partial` | `-` |
| `s_magnitude` | `Magnitude` | `10 Move/2 Definitions/300 Magnitude.rb` | `StaticBasicMoveRegistry.s_magnitude` | `partial` | `-` |
| `s_make_it_rain` | `MakeItRain` | `10 Move/2 Definitions/300 MakeItRain.rb` | `StaticBasicMoveRegistry.s_make_it_rain` | `partial` | `-` |
| `s_me_first` | `MeFirst` | `10 Move/2 Definitions/300 Me First.rb` | `CopyCallMoveBehavior.meFirst` | `partial` | `-` |
| `s_memento` | `Memento` | `10 Move/2 Definitions/300 Memento.rb` | `StaticBasicMoveRegistry.s_memento` | `partial` | `-` |
| `s_metal_burst` | `MetalBurst` | `10 Move/2 Definitions/300 Counter moves.rb` | `CounterDamageMoveBehavior.metalBurst` | `partial` | `-` |
| `s_metronome` | `Metronome` | `10 Move/2 Definitions/300 Metronome.rb` | `CopyCallMoveBehavior.metronome` | `partial` | `-` |
| `s_mimic` | `Mimic` | `10 Move/2 Definitions/300 Mimic.rb` | `CopyCallMoveBehavior.mimic` | `partial` | `-` |
| `s_mind_blown` | `MindBlown` | `10 Move/2 Definitions/300 MindBlown.rb` | `MindBlownMoveBehavior.mindBlown` | `partial` | `ability`, `faint_process` |
| `s_mind_reader` | `LockOn` | `10 Move/2 Definitions/300 LockOn.rb` | `StaticBasicMoveRegistry.s_mind_reader` | `partial` | `-` |
| `s_minimize` | `Minimize` | `10 Move/2 Definitions/300 Minimize.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_minimize)` | `partial` | `-` |
| `s_miracle_eye` | `MiracleEye` | `10 Move/2 Definitions/300 MiracleEye.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_miracle_eye)` | `partial` | `-` |
| `s_mirror_coat` | `MirrorCoat` | `10 Move/2 Definitions/300 Counter moves.rb` | `CounterDamageMoveBehavior.mirrorCoat` | `partial` | `-` |
| `s_mirror_move` | `MirrorMove` | `10 Move/2 Definitions/300 MirrorMove.rb` | `CopyCallMoveBehavior.mirrorMove` | `partial` | `-` |
| `s_mist` | `Mist` | `10 Move/2 Definitions/300 Mist.rb` | `StaticBasicMoveRegistry.s_mist` | `ported` | `-` |
| `s_misty_explosion` | `MistyExplosion` | `10 Move/2 Definitions/300 TerrainDamageMoves.rb` | `SelfDestructMoveBehavior.mistyExplosion` | `partial` | `ability`, `faint_process`, `terrain`, `grounded` |
| `s_multi_attack` | `MultiAttack` | `10 Move/2 Definitions/300 MultiAttack.rb` | `TypeBasedMoveBehavior.multiAttack` | `partial` | `-` |
| `s_multi_hit` | `MultiHit` | `10 Move/1 Mechanics/103 TwoHit MultiHit.rb` | `MultiHitMoveBehavior.psdkRandom` | `ported` | `-` |
| `s_natural_gift` | `NaturalGift` | `10 Move/2 Definitions/300 NaturalGift.rb` | `ItemDependentMoveBehavior.naturalGift` | `partial` | `-` |
| `s_nature_power` | `NaturePower` | `10 Move/2 Definitions/300 NaturePower.rb` | `FieldLocationMoveBehavior.naturePower` | `partial` | `-` |
| `s_nightmare` | `Nightmare` | `10 Move/2 Definitions/300 Nightmare.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_nightmare)` | `partial` | `-` |
| `s_no_retreat` | `NoRetreat` | `10 Move/2 Definitions/300 NoRetreat.rb` | `StaticBasicMoveRegistry.partialUserBankMarker(s_no_retreat)` | `partial` | `-` |
| `s_octolock` | `Octolock` | `10 Move/2 Definitions/300 Octolock.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_octolock)` | `partial` | `-` |
| `s_ohko` | `OHKO` | `10 Move/2 Definitions/300 OHKO.rb` | `OhkoMoveBehavior` | `partial` | `handler_damage`, `ability`, `effects` |
| `s_order_up` | `OrderUp` | `10 Move/2 Definitions/300 OrderUp.rb` | `StaticBasicMoveRegistry.partialBasic(s_order_up)` | `partial` | `-` |
| `s_outrage` | `Thrash` | `10 Move/2 Definitions/300 Thrash.rb` | `ForcedActionMoveBehavior.outrage` | `partial` | `effects`, `handler_status`, `history` |
| `s_pain_split` | `PainSplit` | `10 Move/2 Definitions/300 PainSplit.rb` | `DirectHpMoveBehavior.painSplit` | `partial` | `handler_damage`, `effects` |
| `s_parting_shot` | `PartingShot` | `10 Move/2 Definitions/300 PartingShot.rb` | `StaticBasicMoveRegistry.secondaryOnly(s_parting_shot)` | `partial` | `-` |
| `s_payback` | `PayBack` | `10 Move/2 Definitions/300 PayBack.rb` | `HistoryPowerMoveBehavior.payback` | `partial` | `-` |
| `s_payday` | `PayDay` | `10 Move/2 Definitions/300 Payday.rb` | `StaticBasicMoveRegistry.partialBasic(s_payday)` | `partial` | `-` |
| `s_perish_song` | `PerishSong` | `10 Move/2 Definitions/300 PerishSong.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_perish_song)` | `partial` | `-` |
| `s_photon_geyser` | `PhotonGeyser` | `10 Move/2 Definitions/300 PhotonGeyser.rb` | `StaticBasicMoveRegistry.s_photon_geyser` | `partial` | `-` |
| `s_plasma_fists` | `PlasmaFists` | `10 Move/2 Definitions/300 PlasmaFists.rb` | `StaticBasicMoveRegistry.s_plasma_fists` | `partial` | `-` |
| `s_pledge` | `Pledge` | `10 Move/1 Mechanics/130 Pledge.rb` | `FieldLocationMoveBehavior.pledge` | `partial` | `effects`, `field`, `targeting_multi`, `action_order` |
| `s_pluck` | `Pluck` | `10 Move/2 Definitions/300 Pluck.rb` | `ItemDependentMoveBehavior.pluck` | `partial` | `item`, `ability` |
| `s_pollen_puff` | `PollenPuff` | `10 Move/2 Definitions/300 PollenPuff.rb` | `StaticBasicMoveRegistry.s_pollen_puff` | `partial` | `-` |
| `s_poltergeist` | `Poltergeist` | `10 Move/2 Definitions/300 Poltergeist.rb` | `StaticBasicMoveRegistry.s_poltergeist` | `partial` | `-` |
| `s_population_bomb` | `PopulationBomb` | `10 Move/1 Mechanics/103 TwoHit MultiHit.rb` | `MultiHitMoveBehavior.populationBomb` | `partial` | `ability`, `item` |
| `s_powder` | `Powder` | `10 Move/2 Definitions/300 Powder.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_powder)` | `partial` | `-` |
| `s_power_split` | `PowerSplit` | `10 Move/2 Definitions/300 Stages split moves.rb` | `StatSplitMoveBehavior.power` | `ported` | `-` |
| `s_power_swap` | `PowerSwap` | `10 Move/2 Definitions/300 Stages swap moves.rb` | `AdvancedStatMoveBehavior.powerSwap` | `partial` | `handler_stat`, `effects`, `ability` |
| `s_power_trick` | `PowerTrick` | `10 Move/2 Definitions/300 PowerTrick.rb` | `PowerTrickMoveBehavior` | `ported` | `-` |
| `s_pre_attack_base` | `PreAttackBase` | `10 Move/2 Definitions/300 PreAttackMoves.rb` | `StaticBasicMoveRegistry.partialBasic(s_pre_attack_base)` | `partial` | `-` |
| `s_present` | `Present` | `10 Move/2 Definitions/300 Present.rb` | `StaticBasicMoveRegistry.s_present` | `partial` | `-` |
| `s_protect` | `Protect` | `10 Move/2 Definitions/300 Protect.rb` | `StaticBasicMoveRegistry.s_protect` | `ported` | `-` |
| `s_psych_up` | `PsychUp` | `10 Move/2 Definitions/300 PsychUp.rb` | `AdvancedStatMoveBehavior.psychUp` | `partial` | `handler_stat`, `effects`, `ability` |
| `s_psychic_noise` | `PsychicNoise` | `10 Move/2 Definitions/300 PsychicNoise.rb` | `SpecialSecondaryMoveBehavior.psychicNoise` | `partial` | `effects`, `ability` |
| `s_psycho_shift` | `PsychoShift` | `10 Move/2 Definitions/300 PsychoShift.rb` | `PsychoShiftMoveBehavior` | `partial` | `handler_status`, `effects`, `ability`, `targeting_multi` |
| `s_psyshock` | `CustomStatsBased` | `10 Move/2 Definitions/300 CustomStatsBased.rb` | `CustomStatSourceMoveBehavior.psyshock` | `partial` | `handler_damage`, `ability`, `item` |
| `s_psywave` | `Psywave` | `10 Move/2 Definitions/300 HPEqLevel.rb` | `FixedDamageMoveBehavior.psywave` | `ported` | `-` |
| `s_purify` | `Purify` | `10 Move/2 Definitions/300 Purify.rb` | `PurifyMoveBehavior` | `partial` | `handler_damage`, `handler_status`, `effects`, `targeting_multi` |
| `s_pursuit` | `Pursuit` | `10 Move/2 Definitions/300 Pursuit.rb` | `StaticBasicMoveRegistry.s_pursuit` | `partial` | `-` |
| `s_quash` | `Quash` | `10 Move/2 Definitions/300 Quash.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_quash)` | `partial` | `-` |
| `s_rage` | `Rage` | `10 Move/2 Definitions/300 Rage.rb` | `StaticBasicMoveRegistry.s_rage` | `partial` | `-` |
| `s_rage_fist` | `RageFist` | `10 Move/2 Definitions/300 RageFist.rb` | `HistoryPowerMoveBehavior.rageFist` | `partial` | `-` |
| `s_raging_bull` | `RagingBull` | `10 Move/2 Definitions/300 BrickBreak.rb` | `StaticBasicMoveRegistry.s_raging_bull` | `partial` | `-` |
| `s_rapid_spin` | `RapidSpin` | `10 Move/2 Definitions/300 RapidSpin.rb` | `StaticBasicMoveRegistry.s_rapid_spin` | `ported` | `-` |
| `s_recoil` | `RecoilMove` | `10 Move/2 Definitions/300 RecoilMove.rb` | `RecoilMoveBehavior.psdkRecoil` | `ported` | `handler_damage`, `ability`, `item`, `history` |
| `s_recycle` | `Recycle` | `10 Move/2 Definitions/300 Recycle.rb` | `ItemDependentMoveBehavior.recycle` | `partial` | `-` |
| `s_reflect` | `Reflect` | `10 Move/2 Definitions/300 LightScreen Reflect.rb` | `StaticBasicMoveRegistry.s_reflect` | `ported` | `-` |
| `s_reflect_type` | `ReflectType` | `10 Move/2 Definitions/300 ReflectType.rb` | `StaticBasicMoveRegistry.s_reflect_type` | `partial` | `effects`, `ability` |
| `s_relic_song` | `RelicSong` | `10 Move/2 Definitions/300 RelicSong.rb` | `SpecialSecondaryMoveBehavior.relicSong` | `partial` | `-` |
| `s_reload` | `Reload` | `10 Move/2 Definitions/300 Reload.rb` | `StaticBasicMoveRegistry.s_reload` | `ported` | `effects`, `history`, `action_order` |
| `s_rest` | `Rest` | `10 Move/2 Definitions/300 Rest.rb` | `RecoveryStatMoveBehavior.rest` | `ported` | `handler_status`, `handler_damage`, `effects`, `ability`, `terrain`, `item` |
| `s_retaliate` | `Retaliate` | `10 Move/2 Definitions/300 Retaliate.rb` | `HistoryPowerMoveBehavior.retaliate` | `partial` | `history`, `faint_process` |
| `s_return` | `Return` | `10 Move/2 Definitions/300 Return.rb` | `StaticBasicMoveRegistry.partialBasic(s_return)` | `partial` | `-` |
| `s_revelation_dance` | `RevelationDance` | `10 Move/2 Definitions/300 RevelationDance.rb` | `TypeBasedMoveBehavior.revelationDance` | `partial` | `effects` |
| `s_revenge` | `Revenge` | `10 Move/2 Definitions/300 Revenge.rb` | `HistoryPowerMoveBehavior.revenge` | `partial` | `history` |
| `s_revival_blessing` | `RevivalBlessing` | `10 Move/2 Definitions/300 RevivalBlessing.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_revival_blessing)` | `partial` | `-` |
| `s_rising_voltage` | `RisingVoltage` | `10 Move/2 Definitions/300 TerrainDamageMoves.rb` | `TerrainPowerMoveBehavior.risingVoltage` | `ported` | `terrain`, `grounded` |
| `s_roar` | `ForceSwitch` | `10 Move/2 Definitions/300 ForceSwitch.rb` | `StaticBasicMoveRegistry.forceSwitch(s_roar)` | `partial` | `handler_switch`, `effects`, `ability` |
| `s_role_play` | `RolePlay` | `10 Move/2 Definitions/300 AbilityChanging.rb` | `StaticBasicMoveRegistry.partialAbilityChanging(s_role_play)` | `partial` | `ability`, `effects` |
| `s_rollout` | `Rollout` | `10 Move/2 Definitions/300 Rollout.rb` | `ConsecutivePowerMoveBehavior.rollout` | `partial` | `effects`, `history`, `accuracy` |
| `s_roost` | `Roost` | `10 Move/2 Definitions/300 Roost.rb` | `HealMoveBehavior.roost` | `partial` | `handler_damage`, `effects` |
| `s_rototiller` | `Rototiller` | `10 Move/2 Definitions/300 Rototiller.rb` | `StaticBasicMoveRegistry.partialUserBankMarker(s_rototiller)` | `partial` | `-` |
| `s_round` | `Round` | `10 Move/2 Definitions/300 Round.rb` | `StaticBasicMoveRegistry.partialBasic(s_round)` | `partial` | `action_order`, `history`, `targeting_multi` |
| `s_sacred_sword` | `SacredSword` | `10 Move/2 Definitions/300 SacredSword.rb` | `CustomStatSourceMoveBehavior.sacredSword` | `partial` | `handler_damage`, `effects` |
| `s_safe_guard` | `Safeguard` | `10 Move/2 Definitions/300 Safeguard.rb` | `StaticBasicMoveRegistry.s_safe_guard` | `ported` | `-` |
| `s_salt_cure` | `SaltCure` | `10 Move/2 Definitions/300 SaltCure.rb` | `SpecialSecondaryMoveBehavior.saltCure` | `partial` | `-` |
| `s_sappy_seed` | `SappySeed` | `10 Move/2 Definitions/300 SappySeed.rb` | `StaticBasicMoveRegistry.s_sappy_seed` | `partial` | `-` |
| `s_scale_shot` | `ScaleShot` | `10 Move/2 Definitions/300 ScaleShot.rb` | `MultiHitMoveBehavior.scaleShot` | `partial` | `-` |
| `s_secret_power` | `SecretPower` | `10 Move/2 Definitions/300 SecretPower.rb` | `FieldLocationMoveBehavior.secretPower` | `partial` | `field`, `handler_status`, `handler_stat` |
| `s_self_stat` | `SelfStat` | `10 Move/1 Mechanics/101 Self.rb` | `StatusStatMoveBehavior.selfStat` | `ported` | `-` |
| `s_self_status` | `SelfStatus` | `10 Move/1 Mechanics/101 Self.rb` | `StatusStatMoveBehavior.selfStatus` | `ported` | `-` |
| `s_shed_tail` | `ShedTail` | `10 Move/2 Definitions/300 Substitute.rb` | `StaticBasicMoveRegistry.partialUserBankMarker(s_shed_tail)` | `partial` | `-` |
| `s_shell_side_arm` | `ShellSideArm` | `10 Move/2 Definitions/300 ShellSideArm.rb` | `StaticBasicMoveRegistry.s_shell_side_arm` | `partial` | `-` |
| `s_shell_trap` | `ShellTrap` | `10 Move/2 Definitions/300 PreAttackMoves.rb` | `StaticBasicMoveRegistry.partialBasic(s_shell_trap)` | `partial` | `-` |
| `s_shore_up` | `ShoreUp` | `10 Move/2 Definitions/300 Shore Up.rb` | `HealMoveBehavior.shoreUp` | `ported` | `weather`, `handler_damage`, `effects` |
| `s_simple_beam` | `SimpleBeam` | `10 Move/2 Definitions/300 AbilityChanging.rb` | `StaticBasicMoveRegistry.partialAbilityChanging(s_simple_beam)` | `partial` | `ability`, `effects` |
| `s_sketch` | `Sketch` | `10 Move/2 Definitions/300 Sketch.rb` | `CopyCallMoveBehavior.sketch` | `partial` | `-` |
| `s_skill_swap` | `SkillSwap` | `10 Move/2 Definitions/300 AbilityChanging.rb` | `StaticBasicMoveRegistry.partialAbilityChanging(s_skill_swap)` | `partial` | `ability`, `effects` |
| `s_sky_drop` | `SkyDrop` | `10 Move/2 Definitions/300 SkyDrop.rb` | `StaticBasicMoveRegistry.s_sky_drop` | `partial` | `-` |
| `s_sleep_talk` | `SleepTalk` | `10 Move/2 Definitions/300 SleepTalk.rb` | `CopyCallMoveBehavior.sleepTalk` | `partial` | `-` |
| `s_smack_down` | `SmackDown` | `10 Move/2 Definitions/300 SmackDown.rb` | `GroundingMoveBehavior.smackDown` | `partial` | `effects`, `grounded`, `targeting_multi` |
| `s_smelling_salt` | `SmellingSalts` | `10 Move/2 Definitions/300 HitThenCureStatus.rb` | `HitThenCureStatusMoveBehavior.smellingSalt` | `partial` | `handler_damage`, `handler_status`, `effects` |
| `s_snatch` | `Snatch` | `10 Move/2 Definitions/300 Snatch.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_snatch)` | `partial` | `-` |
| `s_snore` | `Snore` | `10 Move/2 Definitions/300 Snore.rb` | `ActionGatedMoveBehavior.snore` | `partial` | `handler_status`, `ability` |
| `s_solar_beam` | `SolarBeam` | `10 Move/2 Definitions/300 SolarBeam.rb` | `WeatherPowerMoveBehavior.solarBeam` | `partial` | `weather`, `effects` |
| `s_sparkling_aria` | `SparklingAria` | `10 Move/2 Definitions/300 SparklingAria.rb` | `HitThenCureStatusMoveBehavior.sparklingAria` | `partial` | `handler_damage`, `handler_status`, `effects` |
| `s_sparkly_swirl` | `SparklySwirl` | `10 Move/2 Definitions/300 SparklySwirl.rb` | `StatusCureMoveBehavior.sparklySwirl` | `partial` | `handler_damage`, `handler_status`, `effects`, `targeting_multi` |
| `s_spectral_thief` | `SpectralThief` | `10 Move/2 Definitions/300 SpectralThief.rb` | `StaticBasicMoveRegistry.s_spectral_thief` | `partial` | `-` |
| `s_speed_swap` | `SpeedSwap` | `10 Move/2 Definitions/300 Stages swap moves.rb` | `SpeedSwapMoveBehavior` | `ported` | `-` |
| `s_spike` | `Spikes` | `10 Move/2 Definitions/300 Spikes.rb` | `StaticBasicMoveRegistry.s_spike` | `ported` | `effects`, `handler_switch`, `grounded` |
| `s_spite` | `Spite` | `10 Move/2 Definitions/300 Spite.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_spite)` | `partial` | `-` |
| `s_splash` | `Splash` | `10 Move/2 Definitions/300 Splash.rb` | `NoEffectMoveBehavior.splash` | `partial` | `-` |
| `s_split_up` | `SpitUp` | `10 Move/2 Definitions/300 SpitUp.rb` | `StaticBasicMoveRegistry.partialBasic(s_split_up)` | `partial` | `-` |
| `s_stat` | `StatusStat` | `10 Move/1 Mechanics/102 Status Stat.rb` | `StatusStatMoveBehavior.stat` | `ported` | `-` |
| `s_status` | `StatusStat` | `10 Move/1 Mechanics/102 Status Stat.rb` | `StatusStatMoveBehavior.status` | `ported` | `-` |
| `s_stealth_rock` | `StealthRock` | `10 Move/2 Definitions/300 StealthRock.rb` | `StaticBasicMoveRegistry.s_stealth_rock` | `ported` | `effects`, `handler_switch` |
| `s_steel_beam` | `MindBlown` | `10 Move/2 Definitions/300 MindBlown.rb` | `MindBlownMoveBehavior.steelBeam` | `partial` | `ability`, `faint_process` |
| `s_steel_roller` | `SteelRoller` | `10 Move/2 Definitions/300 IceSpinner SteelRoller.rb` | `StaticBasicMoveRegistry.s_steel_roller` | `partial` | `-` |
| `s_sticky_web` | `StickyWeb` | `10 Move/2 Definitions/300 StickyWeb.rb` | `StaticBasicMoveRegistry.s_sticky_web` | `ported` | `effects`, `handler_switch`, `grounded` |
| `s_stockpile` | `Stockpile` | `10 Move/2 Definitions/300 Stockpile.rb` | `StaticBasicMoveRegistry.s_stockpile` | `partial` | `-` |
| `s_stomp` | `Stomp` | `10 Move/2 Definitions/300 Stomp.rb` | `StaticBasicMoveRegistry.s_stomp` | `partial` | `-` |
| `s_stomping_tantrum` | `StompingTantrum` | `10 Move/2 Definitions/300 StompingTantrum.rb` | `HistoryPowerMoveBehavior.stompingTantrum` | `partial` | `history` |
| `s_stone_axe` | `StoneAxe` | `10 Move/2 Definitions/300 HazardsSetting.rb` | `StaticBasicMoveRegistry.s_stone_axe` | `ported` | `-` |
| `s_stored_power` | `StoredPower` | `10 Move/2 Definitions/300 StoredPower.rb` | `SpecialPowerMoveBehavior.storedPower` | `ported` | `-` |
| `s_strength_sap` | `StrengthSap` | `10 Move/2 Definitions/300 StrengthSap.rb` | `RecoveryStatMoveBehavior.strengthSap` | `partial` | `handler_damage`, `handler_stat`, `ability`, `item`, `effects` |
| `s_struggle` | `Struggle` | `10 Move/2 Definitions/300 RecoilMove.rb` | `RecoilMoveBehavior.struggle` | `partial` | `-` |
| `s_stuff_cheeks` | `StuffCheeks` | `10 Move/2 Definitions/300 StuffCheeks.rb` | `StaticBasicMoveRegistry.partialUserBankMarker(s_stuff_cheeks)` | `partial` | `-` |
| `s_substitute` | `Substitute` | `10 Move/2 Definitions/300 Substitute.rb` | `StaticBasicMoveRegistry.s_substitute` | `partial` | `-` |
| `s_sucker_punch` | `SuckerPunch` | `10 Move/2 Definitions/300 SuckerPunch.rb` | `ActionGatedMoveBehavior.suckerPunch` | `partial` | `action_order` |
| `s_super_duper_effective` | `SuperDuperEffective` | `10 Move/2 Definitions/300 SuperDuperEffective.rb` | `StaticBasicMoveRegistry.s_super_duper_effective` | `partial` | `-` |
| `s_super_fang` | `SuperFang` | `10 Move/2 Definitions/300 SuperFang.rb` | `FixedDamageMoveBehavior.halfCurrentTargetHp` | `ported` | `-` |
| `s_swallow` | `Swallow` | `10 Move/2 Definitions/300 Swallow.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_swallow)` | `partial` | `-` |
| `s_synchronoise` | `Synchronoise` | `10 Move/2 Definitions/300 Synchronoise.rb` | `FieldLocationMoveBehavior.synchronoise` | `partial` | `targeting_multi` |
| `s_syrup_bomb` | `SyrupBomb` | `10 Move/2 Definitions/300 SyrupBomb.rb` | `SpecialSecondaryMoveBehavior.syrupBomb` | `partial` | `-` |
| `s_tailwind` | `Tailwind` | `10 Move/2 Definitions/300 Tailwind.rb` | `StaticBasicMoveRegistry.partialUserBankMarker(s_tailwind)` | `partial` | `effects`, `action_order` |
| `s_take_heart` | `TakeHeart` | `10 Move/2 Definitions/300 TakeHeart.rb` | `StatusCureMoveBehavior.takeHeart` | `partial` | `handler_status`, `effects`, `targeting_multi` |
| `s_tar_shot` | `TarShot` | `10 Move/2 Definitions/300 TarShot.rb` | `SpecialSecondaryMoveBehavior.tarShot` | `partial` | `-` |
| `s_taunt` | `Taunt` | `10 Move/2 Definitions/300 Taunt.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_taunt)` | `partial` | `effects`, `action_order` |
| `s_teatime` | `Teatime` | `10 Move/2 Definitions/300 TeaTime.rb` | `StaticBasicMoveRegistry.partialFieldMarker(s_teatime)` | `partial` | `-` |
| `s_techno_blast` | `TechnoBlast` | `10 Move/2 Definitions/300 TechnoBlast.rb` | `ItemDependentMoveBehavior.technoBlast` | `partial` | `item`, `ability` |
| `s_telekinesis` | `Telekinesis` | `10 Move/2 Definitions/300 Telekinesis.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_telekinesis)` | `partial` | `-` |
| `s_teleport` | `Teleport` | `10 Move/2 Definitions/300 Teleport.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_teleport)` | `partial` | `-` |
| `s_terrain` | `TerrainMove` | `10 Move/2 Definitions/300 TerrainMove.rb` | `TerrainMoveBehavior` | `ported` | `handler_terrain`, `terrain`, `effects`, `item` |
| `s_terrain_boosting` | `TerrainBoosting` | `10 Move/2 Definitions/300 TerrainBoosting.rb` | `TerrainPowerMoveBehavior.terrainBoosting` | `ported` | `-` |
| `s_terrain_pulse` | `TerrainPulse` | `10 Move/2 Definitions/300 TerrainPulse.rb` | `TerrainPowerMoveBehavior.terrainPulse` | `ported` | `terrain`, `grounded` |
| `s_thief` | `Thief` | `10 Move/2 Definitions/300 Thief.rb` | `ItemDependentMoveBehavior.thief` | `partial` | `item`, `ability`, `effects` |
| `s_thing_sport` | `MudSport` | `10 Move/2 Definitions/300 MudSport.rb` | `StaticBasicMoveRegistry.s_thing_sport` | `partial` | `effects`, `field` |
| `s_thrash` | `Thrash` | `10 Move/2 Definitions/300 Thrash.rb` | `ForcedActionMoveBehavior.thrash` | `partial` | `effects`, `handler_status`, `history` |
| `s_throat_chop` | `ThroatChop` | `10 Move/2 Definitions/300 ThroatChop.rb` | `SpecialSecondaryMoveBehavior.throatChop` | `partial` | `effects` |
| `s_thunder` | `Thunder` | `10 Move/2 Definitions/300 Thunder.rb` | `WeatherPowerMoveBehavior.thunder` | `ported` | `weather`, `accuracy` |
| `s_tidy_up` | `TidyUp` | `10 Move/2 Definitions/300 TidyUp.rb` | `StaticBasicMoveRegistry.s_tidy_up` | `ported` | `-` |
| `s_topsy_turvy` | `TopsyTurvy` | `10 Move/2 Definitions/300 TopsyTurvy.rb` | `AdvancedStatMoveBehavior.topsyTurvy` | `partial` | `handler_stat`, `effects`, `ability` |
| `s_torment` | `Torment` | `10 Move/2 Definitions/300 Torment.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_torment)` | `partial` | `effects`, `history` |
| `s_toxic_spike` | `ToxicSpikes` | `10 Move/2 Definitions/300 Toxic_Spikes.rb` | `StaticBasicMoveRegistry.s_toxic_spike` | `ported` | `effects`, `handler_switch`, `grounded` |
| `s_toxic_thread` | `ToxicThread` | `10 Move/2 Definitions/300 ToxicThread.rb` | `StaticBasicMoveRegistry.secondaryOnly(s_toxic_thread)` | `partial` | `-` |
| `s_transform` | `Transform` | `10 Move/2 Definitions/300 Transform.rb` | `TransformMoveBehavior` | `partial` | `handler_switch`, `effects`, `ability` |
| `s_tri_attack` | `TriAttack` | `10 Move/2 Definitions/300 TriAttack.rb` | `SpecialSecondaryMoveBehavior.triAttack` | `partial` | `handler_status` |
| `s_trick` | `Switcheroo` | `10 Move/2 Definitions/300 Switcheroo.rb` | `StaticBasicMoveRegistry.s_trick` | `partial` | `handler_item`, `item`, `ability` |
| `s_trick_room` | `TrickRoom` | `10 Move/2 Definitions/300 TrickRoom.rb` | `StaticBasicMoveRegistry.partialFieldMarker(s_trick_room)` | `partial` | `effects`, `action_order`, `field` |
| `s_triple_arrows` | `TripleArrows` | `10 Move/2 Definitions/300 TripleArrows.rb` | `StaticBasicMoveRegistry.s_triple_arrows` | `partial` | `-` |
| `s_triple_kick` | `TripleKick` | `10 Move/1 Mechanics/103 TwoHit MultiHit.rb` | `MultiHitMoveBehavior.tripleKick` | `partial` | `ability`, `item`, `history` |
| `s_trump_card` | `TrumpCard` | `10 Move/2 Definitions/300 TrumpCard.rb` | `ConsecutivePowerMoveBehavior.trumpCard` | `partial` | `history`, `accuracy`, `effects` |
| `s_u_turn` | `UTurn` | `10 Move/2 Definitions/300 UTurn.rb` | `StaticBasicMoveRegistry.s_u_turn` | `partial` | `handler_switch`, `item`, `ability` |
| `s_upper_hand` | `UpperHand` | `10 Move/2 Definitions/300 UpperHand.rb` | `StaticBasicMoveRegistry.partialBasic(s_upper_hand)` | `partial` | `-` |
| `s_uproar` | `UpRoar` | `10 Move/2 Definitions/300 UpRoar.rb` | `ForcedActionMoveBehavior.uproar` | `partial` | `effects`, `handler_status`, `history`, `targeting_multi` |
| `s_venom_drench` | `VenomDrench` | `10 Move/2 Definitions/300 VenomDrench.rb` | `StaticBasicMoveRegistry.secondaryOnly(s_venom_drench)` | `partial` | `-` |
| `s_venoshock` | `Venoshock` | `10 Move/2 Definitions/300 Venoshock.rb` | `VariablePowerMoveBehavior.venoshock` | `ported` | `-` |
| `s_wakeup_slap` | `WakeUpSlap` | `10 Move/2 Definitions/300 HitThenCureStatus.rb` | `HitThenCureStatusMoveBehavior.wakeUpSlap` | `partial` | `handler_damage`, `handler_status`, `effects`, `ability` |
| `s_water_shuriken` | `WaterShuriken` | `10 Move/1 Mechanics/103 TwoHit MultiHit.rb` | `MultiHitMoveBehavior.waterShuriken` | `partial` | `ability`, `item` |
| `s_weather` | `WeatherMove` | `10 Move/2 Definitions/300 WeatherMove.rb` | `WeatherMoveBehavior` | `ported` | `handler_weather`, `weather`, `effects`, `item` |
| `s_weather_ball` | `WeatherBall` | `10 Move/2 Definitions/300 WeatherBall.rb` | `WeatherPowerMoveBehavior.weatherBall` | `ported` | `weather`, `ability` |
| `s_wish` | `Wish` | `10 Move/2 Definitions/300 Wish.rb` | `StaticBasicMoveRegistry.partialUserBankMarker(s_wish)` | `partial` | `effects`, `end_turn`, `handler_switch` |
| `s_wonder_room` | `WonderRoom` | `10 Move/2 Definitions/300 WonderRoom.rb` | `StaticBasicMoveRegistry.partialFieldMarker(s_wonder_room)` | `partial` | `effects`, `handler_stat`, `field` |
| `s_worry_seed` | `WorrySeed` | `10 Move/2 Definitions/300 AbilityChanging.rb` | `StaticBasicMoveRegistry.partialAbilityChanging(s_worry_seed)` | `partial` | `ability`, `effects` |
| `s_wring_out` | `WringOut` | `10 Move/2 Definitions/300 WringOut.rb` | `VariablePowerMoveBehavior.wringOut` | `ported` | `-` |
| `s_yawn` | `Yawn` | `10 Move/2 Definitions/300 Yawn.rb` | `StaticBasicMoveRegistry.partialTargetMarker(s_yawn)` | `partial` | `effects`, `handler_status`, `ability`, `terrain` |
