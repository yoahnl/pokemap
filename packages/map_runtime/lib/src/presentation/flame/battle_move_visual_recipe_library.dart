import 'package:map_battle/map_battle.dart';

import 'battle_animation_plan.dart';
import 'battle_move_visual_catalog.dart';
import 'battle_move_visual_resolver.dart';

class BattleMoveVisualRecipeContext {
  const BattleMoveVisualRecipeContext({
    required this.resolvedMove,
    required this.battleMove,
    required this.execution,
    required this.attackerSide,
    required this.targetSide,
    required this.damage,
    required this.didHit,
    required this.didCrit,
  });

  final BattleResolvedMoveVisual resolvedMove;
  final BattleMove battleMove;
  final BattleMoveExecution? execution;
  final BattleSideId attackerSide;
  final BattleSideId? targetSide;
  final int? damage;
  final bool didHit;
  final bool didCrit;
}

final class BattleMoveVisualRecipeLibrary {
  List<BattleAnimationStep> build(
    BattleMoveVisualRecipeId recipeId,
    BattleMoveVisualRecipeContext ctx,
  ) {
    return switch (recipeId) {
      BattleMoveVisualRecipeId.genericContactLight => _contactCombo(
          ctx: ctx,
          heavy: false,
        ),
      BattleMoveVisualRecipeId.genericContactHeavy => _contactCombo(
          ctx: ctx,
          heavy: true,
        ),
      BattleMoveVisualRecipeId.genericPunch => _genericPunch(ctx),
      BattleMoveVisualRecipeId.genericBite => _genericBite(ctx),
      BattleMoveVisualRecipeId.genericSlash => _slashCombo(ctx),
      BattleMoveVisualRecipeId.genericProjectileNeutral => _projectileSimple(
          ctx: ctx,
          effectId: 'impact',
        ),
      BattleMoveVisualRecipeId.genericProjectilePulse => _projectileSimple(
          ctx: ctx,
          effectId: 'mistball',
        ),
      BattleMoveVisualRecipeId.genericProjectileFire => _projectileSimple(
          ctx: ctx,
          effectId: 'fireball',
        ),
      BattleMoveVisualRecipeId.genericProjectileWater => _projectileSimple(
          ctx: ctx,
          effectId: 'waterwisp',
        ),
      BattleMoveVisualRecipeId.genericProjectileElectric => _projectileSimple(
          ctx: ctx,
          effectId: 'electroball',
        ),
      BattleMoveVisualRecipeId.genericProjectileGhost => _projectileSimple(
          ctx: ctx,
          effectId: 'shadowball',
        ),
      BattleMoveVisualRecipeId.genericProjectileDark => _projectileSimple(
          ctx: ctx,
          effectId: 'blackwisp',
        ),
      BattleMoveVisualRecipeId.genericProjectileFairy => _projectileSimple(
          ctx: ctx,
          effectId: 'mistball',
        ),
      BattleMoveVisualRecipeId.genericProjectileIce => _projectileSimple(
          ctx: ctx,
          effectId: 'iceball',
        ),
      BattleMoveVisualRecipeId.genericBuffSelf => _buffPulse(ctx),
      BattleMoveVisualRecipeId.genericDebuffTarget => _debuffPulse(ctx),
      BattleMoveVisualRecipeId.genericStatusPulse => _statusPulse(ctx),
      BattleMoveVisualRecipeId.protectBarrier => <BattleAnimationStep>[
          BarrierPulseStep(
            side: ctx.targetSide ?? ctx.attackerSide,
            colorArgb: 0xAA95E7B9,
            durationSeconds: 0.24,
          ),
        ],
      BattleMoveVisualRecipeId.setStealthRock => _hazardSet(
          ctx: ctx,
          effectId: 'rocks',
        ),
      BattleMoveVisualRecipeId.setSpikes => _hazardSet(
          ctx: ctx,
          effectId: 'caltrop',
        ),
      BattleMoveVisualRecipeId.weatherRain => const <BattleAnimationStep>[
          ScreenFlashStep(
            colorArgb: 0x663EA8FF,
            durationSeconds: 0.24,
          ),
        ],
      BattleMoveVisualRecipeId.weatherSandstorm => const <BattleAnimationStep>[
          ScreenFlashStep(
            colorArgb: 0x66D2A55A,
            durationSeconds: 0.24,
          ),
        ],
      BattleMoveVisualRecipeId.pseudoWeatherTrickRoom =>
        const <BattleAnimationStep>[
          ScreenFlashStep(
            colorArgb: 0x669A5DFF,
            durationSeconds: 0.28,
          ),
        ],
      BattleMoveVisualRecipeId.chargeUp => <BattleAnimationStep>[
          SpawnFxStep(
            effectId: 'electroball',
            attackerSide: ctx.attackerSide,
            defenderSide: ctx.attackerSide,
            from: BattleVisualAnchor.attackerCenter,
            to: BattleVisualAnchor.attackerCenter,
            durationSeconds: 0.24,
            afterEffect: BattleFxAfterEffect.fade,
          ),
        ],
      BattleMoveVisualRecipeId.rechargePause => const <BattleAnimationStep>[
          WaitStep(durationSeconds: 0.22),
        ],
      BattleMoveVisualRecipeId.showdownTackle => _showdownTackle(ctx),
      BattleMoveVisualRecipeId.showdownScratch => _showdownScratch(ctx),
      BattleMoveVisualRecipeId.showdownQuickAttack => _showdownQuickAttack(ctx),
      BattleMoveVisualRecipeId.showdownSlash => _showdownSlash(ctx),
      BattleMoveVisualRecipeId.showdownAerialAce => _showdownAerialAce(ctx),
      BattleMoveVisualRecipeId.showdownCloseCombat => _showdownCloseCombat(ctx),
      BattleMoveVisualRecipeId.showdownBodySlam => _showdownBodySlam(ctx),
      BattleMoveVisualRecipeId.showdownHighJumpKick =>
        _showdownHighJumpKick(ctx),
      BattleMoveVisualRecipeId.showdownShadowPunch => _showdownShadowPunch(ctx),
      BattleMoveVisualRecipeId.showdownFocusPunch => _showdownFocusPunch(ctx),
      BattleMoveVisualRecipeId.showdownDrainPunch => _showdownDrainPunch(ctx),
      BattleMoveVisualRecipeId.showdownDynamicPunch =>
        _showdownDynamicPunch(ctx),
      BattleMoveVisualRecipeId.showdownCometPunch => _showdownCometPunch(ctx),
      BattleMoveVisualRecipeId.showdownMegaPunch => _showdownMegaPunch(ctx),
      BattleMoveVisualRecipeId.showdownPowerUpPunch =>
        _showdownPowerUpPunch(ctx),
      BattleMoveVisualRecipeId.showdownDizzyPunch => _showdownDizzyPunch(ctx),
      BattleMoveVisualRecipeId.showdownJetPunch => _showdownJetPunch(ctx),
      BattleMoveVisualRecipeId.showdownFirePunch => _showdownFirePunch(ctx),
      BattleMoveVisualRecipeId.showdownIcePunch => _showdownIcePunch(ctx),
      BattleMoveVisualRecipeId.showdownThunderPunch =>
        _showdownThunderPunch(ctx),
      BattleMoveVisualRecipeId.showdownBlazeKick => _showdownBlazeKick(ctx),
      BattleMoveVisualRecipeId.showdownThunderousKick =>
        _showdownThunderousKick(ctx),
      BattleMoveVisualRecipeId.showdownTropKick => _showdownTropKick(ctx),
      BattleMoveVisualRecipeId.showdownWoodHammer => _showdownWoodHammer(ctx),
      BattleMoveVisualRecipeId.showdownIvyCudgel => _showdownIvyCudgel(ctx),
      BattleMoveVisualRecipeId.showdownIvyCudgelWater =>
        _showdownIvyCudgelWater(ctx),
      BattleMoveVisualRecipeId.showdownIvyCudgelFire =>
        _showdownIvyCudgelFire(ctx),
      BattleMoveVisualRecipeId.showdownIvyCudgelRock =>
        _showdownIvyCudgelRock(ctx),
      BattleMoveVisualRecipeId.showdownCut => _showdownCut(ctx),
      BattleMoveVisualRecipeId.showdownShadowClaw => _showdownShadowClaw(ctx),
      BattleMoveVisualRecipeId.showdownMultiAttack => _showdownMultiAttack(ctx),
      BattleMoveVisualRecipeId.showdownBite => _showdownBite(ctx),
      BattleMoveVisualRecipeId.showdownSuperFang => _showdownSuperFang(ctx),
      BattleMoveVisualRecipeId.showdownBugBite => _showdownBugBite(ctx),
      BattleMoveVisualRecipeId.showdownPsychicFangs =>
        _showdownPsychicFangs(ctx),
      BattleMoveVisualRecipeId.showdownIronHead => _showdownIronHead(ctx),
      BattleMoveVisualRecipeId.showdownHeadbutt => _showdownHeadbutt(ctx),
      BattleMoveVisualRecipeId.showdownStomp => _showdownStomp(ctx),
      BattleMoveVisualRecipeId.showdownHammerArm => _showdownHammerArm(ctx),
      BattleMoveVisualRecipeId.showdownIceHammer => _showdownIceHammer(ctx),
      BattleMoveVisualRecipeId.showdownSkyUppercut => _showdownSkyUppercut(ctx),
      BattleMoveVisualRecipeId.showdownNeedleArm => _showdownNeedleArm(ctx),
      BattleMoveVisualRecipeId.showdownRockSmash => _showdownRockSmash(ctx),
      BattleMoveVisualRecipeId.showdownKarateChop => _showdownKarateChop(ctx),
      BattleMoveVisualRecipeId.showdownDrillRun => _showdownDrillRun(ctx),
      BattleMoveVisualRecipeId.showdownThunderbolt => _showdownThunderbolt(ctx),
      BattleMoveVisualRecipeId.showdownChargeBeam => _showdownChargeBeam(ctx),
      BattleMoveVisualRecipeId.showdownHiddenPower => _showdownHiddenPower(ctx),
      BattleMoveVisualRecipeId.showdownElectroBall => _showdownElectroBall(ctx),
      BattleMoveVisualRecipeId.showdownShadowBall => _showdownShadowBall(ctx),
      BattleMoveVisualRecipeId.showdownDarkPulse => _showdownDarkPulse(ctx),
      BattleMoveVisualRecipeId.showdownAuraSphere => _showdownAuraSphere(ctx),
      BattleMoveVisualRecipeId.showdownBubbleBeam => _showdownBubbleBeam(ctx),
      BattleMoveVisualRecipeId.showdownFireBlast => _showdownFireBlast(ctx),
      BattleMoveVisualRecipeId.showdownBlizzard => _showdownBlizzard(ctx),
      BattleMoveVisualRecipeId.showdownDazzlingGleam =>
        _showdownDazzlingGleam(ctx),
      BattleMoveVisualRecipeId.showdownCalmMind => _showdownCalmMind(ctx),
      BattleMoveVisualRecipeId.showdownSwordsDance => _showdownSwordsDance(ctx),
      BattleMoveVisualRecipeId.showdownAgility => _showdownAgility(ctx),
      BattleMoveVisualRecipeId.showdownBulkUp => _showdownBulkUp(ctx),
      BattleMoveVisualRecipeId.showdownCharm => _showdownCharm(ctx),
      BattleMoveVisualRecipeId.showdownConfuseRay => _showdownConfuseRay(ctx),
      BattleMoveVisualRecipeId.showdownGrowl => _showdownGrowl(ctx),
      BattleMoveVisualRecipeId.showdownTaunt => _showdownTaunt(ctx),
      BattleMoveVisualRecipeId.showdownInstruct => _showdownInstruct(ctx),
      BattleMoveVisualRecipeId.showdownQuash => _showdownQuash(ctx),
      BattleMoveVisualRecipeId.showdownSwagger => _showdownSwagger(ctx),
      BattleMoveVisualRecipeId.showdownEncore => _showdownEncore(ctx),
      BattleMoveVisualRecipeId.showdownBabyDollEyes =>
        _showdownBabyDollEyes(ctx),
      BattleMoveVisualRecipeId.showdownThunderWave => _showdownThunderWave(ctx),
      BattleMoveVisualRecipeId.showdownProtect => _showdownProtect(ctx),
      BattleMoveVisualRecipeId.showdownBurningBulwark =>
        _showdownBurningBulwark(ctx),
      BattleMoveVisualRecipeId.showdownBanefulBunker =>
        _showdownBanefulBunker(ctx),
      BattleMoveVisualRecipeId.showdownReflect => _showdownReflect(ctx),
      BattleMoveVisualRecipeId.showdownLightScreen => _showdownLightScreen(ctx),
      BattleMoveVisualRecipeId.showdownMist => _showdownMist(ctx),
      BattleMoveVisualRecipeId.showdownAuroraVeil => _showdownAuroraVeil(ctx),
      BattleMoveVisualRecipeId.showdownSafeguard => _showdownSafeguard(ctx),
      BattleMoveVisualRecipeId.showdownQuickGuard => _showdownQuickGuard(ctx),
      BattleMoveVisualRecipeId.showdownWideGuard => _showdownWideGuard(ctx),
      BattleMoveVisualRecipeId.showdownTailwind => _showdownTailwind(ctx),
      BattleMoveVisualRecipeId.showdownRainDance => _showdownRainDance(ctx),
      BattleMoveVisualRecipeId.showdownSandstorm => _showdownSandstorm(ctx),
      BattleMoveVisualRecipeId.showdownTrickRoom => _showdownTrickRoom(ctx),
      BattleMoveVisualRecipeId.showdownStealthRock => _showdownStealthRock(ctx),
      BattleMoveVisualRecipeId.showdownSpikes => _showdownSpikes(ctx),
      BattleMoveVisualRecipeId.showdownAquaJet => _showdownAquaJet(ctx),
      BattleMoveVisualRecipeId.showdownExtremeSpeed =>
        _showdownExtremeSpeed(ctx),
      BattleMoveVisualRecipeId.showdownMachPunch => _showdownMachPunch(ctx),
      BattleMoveVisualRecipeId.showdownDoubleKick => _showdownDoubleKick(ctx),
      BattleMoveVisualRecipeId.showdownDualWingBeat =>
        _showdownDualWingBeat(ctx),
      BattleMoveVisualRecipeId.showdownBoneMerang => _showdownBoneMerang(ctx),
      BattleMoveVisualRecipeId.showdownSpark => _showdownSpark(ctx),
      BattleMoveVisualRecipeId.showdownWildCharge => _showdownWildCharge(ctx),
      BattleMoveVisualRecipeId.showdownFlareBlitz => _showdownFlareBlitz(ctx),
      BattleMoveVisualRecipeId.showdownAccelerock => _showdownAccelerock(ctx),
      BattleMoveVisualRecipeId.showdownWickedBlow => _showdownWickedBlow(ctx),
      BattleMoveVisualRecipeId.showdownDoubleHit => _showdownDoubleHit(ctx),
      BattleMoveVisualRecipeId.showdownCrunch => _showdownCrunch(ctx),
      BattleMoveVisualRecipeId.showdownFlamethrower =>
        _showdownFlamethrower(ctx),
      BattleMoveVisualRecipeId.showdownIceBeam => _showdownIceBeam(ctx),
      BattleMoveVisualRecipeId.showdownPsychic => _showdownPsychic(ctx),
      BattleMoveVisualRecipeId.showdownMoonBlast => _showdownMoonBlast(ctx),
      BattleMoveVisualRecipeId.showdownPoisonJab => _showdownPoisonJab(ctx),
      BattleMoveVisualRecipeId.showdownEarthquake => _showdownEarthquake(ctx),
      BattleMoveVisualRecipeId.showdownEnergyBall => _showdownEnergyBall(ctx),
      BattleMoveVisualRecipeId.showdownRockSlide => _showdownRockSlide(ctx),
      BattleMoveVisualRecipeId.showdownNightSlash => _showdownNightSlash(ctx),
      BattleMoveVisualRecipeId.showdownGigaImpact => _showdownGigaImpact(ctx),
      BattleMoveVisualRecipeId.showdownPowerWhip => _showdownPowerWhip(ctx),
      BattleMoveVisualRecipeId.showdownCrabHammer => _showdownCrabHammer(ctx),
      BattleMoveVisualRecipeId.showdownDischarge => _showdownDischarge(ctx),
      BattleMoveVisualRecipeId.showdownSmartStrike => _showdownSmartStrike(ctx),
      BattleMoveVisualRecipeId.showdownMegaHorn => _showdownMegaHorn(ctx),
      BattleMoveVisualRecipeId.showdownDragonClaw => _showdownDragonClaw(ctx),
      BattleMoveVisualRecipeId.showdownPsychoCut => _showdownPsychoCut(ctx),
      BattleMoveVisualRecipeId.showdownWaterPulse => _showdownWaterPulse(ctx),
      BattleMoveVisualRecipeId.showdownPowerGem => _showdownPowerGem(ctx),
      BattleMoveVisualRecipeId.showdownHeatWave => _showdownHeatWave(ctx),
      BattleMoveVisualRecipeId.showdownMuddyWater => _showdownMuddyWater(ctx),
      BattleMoveVisualRecipeId.showdownEarthPower => _showdownEarthPower(ctx),
      BattleMoveVisualRecipeId.showdownBugBuzz => _showdownBugBuzz(ctx),
      BattleMoveVisualRecipeId.showdownHyperVoice => _showdownHyperVoice(ctx),
      BattleMoveVisualRecipeId.showdownFlashCannon => _showdownFlashCannon(ctx),
      BattleMoveVisualRecipeId.showdownDragonPulse => _showdownDragonPulse(ctx),
      BattleMoveVisualRecipeId.showdownSludgeBomb => _showdownSludgeBomb(ctx),
      BattleMoveVisualRecipeId.showdownDoomDesire => _showdownDoomDesire(ctx),
      BattleMoveVisualRecipeId.showdownSeedFlare => _showdownSeedFlare(ctx),
      BattleMoveVisualRecipeId.showdownIcyWind => _showdownIcyWind(ctx),
      BattleMoveVisualRecipeId.showdownWeatherBall => _showdownWeatherBall(ctx),
      BattleMoveVisualRecipeId.showdownFlameBurst => _showdownFlameBurst(ctx),
      BattleMoveVisualRecipeId.showdownWaterSport => _showdownWaterSport(ctx),
      BattleMoveVisualRecipeId.showdownScald => _showdownScald(ctx),
      BattleMoveVisualRecipeId.showdownSteamEruption =>
        _showdownSteamEruption(ctx),
      BattleMoveVisualRecipeId.showdownTriAttack => _showdownTriAttack(ctx),
      BattleMoveVisualRecipeId.showdownClangingScales =>
        _showdownClangingScales(ctx),
      BattleMoveVisualRecipeId.showdownGunkShot => _showdownGunkShot(ctx),
      BattleMoveVisualRecipeId.showdownToxic => _showdownToxic(ctx),
      BattleMoveVisualRecipeId.showdownToxicSpikes => _showdownToxicSpikes(ctx),
      BattleMoveVisualRecipeId.showdownPoisonGas => _showdownPoisonGas(ctx),
      BattleMoveVisualRecipeId.showdownSmog => _showdownSmog(ctx),
      BattleMoveVisualRecipeId.showdownClearSmog => _showdownClearSmog(ctx),
      BattleMoveVisualRecipeId.showdownPoisonFang => _showdownPoisonFang(ctx),
      BattleMoveVisualRecipeId.showdownCrossPoison => _showdownCrossPoison(ctx),
      BattleMoveVisualRecipeId.showdownDireClaw => _showdownDireClaw(ctx),
      BattleMoveVisualRecipeId.showdownMudShot => _showdownMudShot(ctx),
      BattleMoveVisualRecipeId.showdownRockBlast => _showdownRockBlast(ctx),
      BattleMoveVisualRecipeId.showdownMagicalLeaf => _showdownMagicalLeaf(ctx),
      BattleMoveVisualRecipeId.showdownElectroweb => _showdownElectroweb(ctx),
      BattleMoveVisualRecipeId.showdownBulletSeed => _showdownBulletSeed(ctx),
      BattleMoveVisualRecipeId.showdownSlam => _showdownSlam(ctx),
      BattleMoveVisualRecipeId.showdownSpore => _showdownSpore(ctx),
      BattleMoveVisualRecipeId.showdownPainSplit => _showdownPainSplit(ctx),
      BattleMoveVisualRecipeId.showdownSkillSwap => _showdownSkillSwap(ctx),
      BattleMoveVisualRecipeId.showdownPlayRough => _showdownPlayRough(ctx),
      BattleMoveVisualRecipeId.showdownSurf => _showdownSurf(ctx),
      BattleMoveVisualRecipeId.showdownHydroPump => _showdownHydroPump(ctx),
      BattleMoveVisualRecipeId.showdownLeafBlade => _showdownLeafBlade(ctx),
      BattleMoveVisualRecipeId.showdownXScissor => _showdownXScissor(ctx),
      BattleMoveVisualRecipeId.showdownFireFang => _showdownFireFang(ctx),
      BattleMoveVisualRecipeId.showdownIceFang => _showdownIceFang(ctx),
      BattleMoveVisualRecipeId.showdownThunderFang => _showdownThunderFang(ctx),
      BattleMoveVisualRecipeId.showdownAirSlash => _showdownAirSlash(ctx),
      BattleMoveVisualRecipeId.showdownDracoMeteor => _showdownDracoMeteor(ctx),
      BattleMoveVisualRecipeId.showdownQuiverDance => _showdownQuiverDance(ctx),
      BattleMoveVisualRecipeId.showdownVictoryDance =>
        _showdownVictoryDance(ctx),
      BattleMoveVisualRecipeId.showdownDragonDance => _showdownDragonDance(ctx),
      BattleMoveVisualRecipeId.showdownFeatherDance =>
        _showdownFeatherDance(ctx),
      BattleMoveVisualRecipeId.showdownFocusBlast => _showdownFocusBlast(ctx),
      BattleMoveVisualRecipeId.showdownSpinAttack => _showdownSpinAttack(ctx),
      BattleMoveVisualRecipeId.showdownVoltSwitch => _showdownVoltSwitch(ctx),
      BattleMoveVisualRecipeId.showdownShockWave => _showdownShockWave(ctx),
      BattleMoveVisualRecipeId.showdownExplosion => _showdownExplosion(ctx),
      BattleMoveVisualRecipeId.showdownPopulationBomb =>
        _showdownPopulationBomb(ctx),
      BattleMoveVisualRecipeId.showdownAirCutter => _showdownAirCutter(ctx),
      BattleMoveVisualRecipeId.showdownHurricane => _showdownHurricane(ctx),
      BattleMoveVisualRecipeId.showdownWhirlwind => _showdownWhirlwind(ctx),
      BattleMoveVisualRecipeId.showdownFreezeDry => _showdownFreezeDry(ctx),
      BattleMoveVisualRecipeId.showdownMagmaStorm => _showdownMagmaStorm(ctx),
      BattleMoveVisualRecipeId.showdownOriginPulse => _showdownOriginPulse(ctx),
      BattleMoveVisualRecipeId.showdownPsybeam => _showdownPsybeam(ctx),
      BattleMoveVisualRecipeId.showdownAeroblast => _showdownAeroblast(ctx),
      BattleMoveVisualRecipeId.showdownRoarOfTime => _showdownRoarOfTime(ctx),
      BattleMoveVisualRecipeId.showdownRevelationDance =>
        _showdownRevelationDance(ctx),
      BattleMoveVisualRecipeId.showdownSunnyDay => _showdownSunnyDay(ctx),
      BattleMoveVisualRecipeId.showdownHail => _showdownHail(ctx),
      BattleMoveVisualRecipeId.showdownElectricTerrain =>
        _showdownElectricTerrain(ctx),
      BattleMoveVisualRecipeId.showdownGrassyTerrain =>
        _showdownGrassyTerrain(ctx),
      BattleMoveVisualRecipeId.showdownMistyTerrain =>
        _showdownMistyTerrain(ctx),
      BattleMoveVisualRecipeId.showdownFollowMe => _showdownFollowMe(ctx),
      BattleMoveVisualRecipeId.showdownKinesis => _showdownKinesis(ctx),
      BattleMoveVisualRecipeId.showdownSolarBeam => _showdownSolarBeam(ctx),
      BattleMoveVisualRecipeId.showdownThunder => _showdownThunder(ctx),
      BattleMoveVisualRecipeId.showdownStoredPower => _showdownStoredPower(ctx),
      BattleMoveVisualRecipeId.showdownPsychoBoost => _showdownPsychoBoost(ctx),
      BattleMoveVisualRecipeId.showdownPsyshock => _showdownPsyshock(ctx),
      BattleMoveVisualRecipeId.showdownHex => _showdownHex(ctx),
      BattleMoveVisualRecipeId.showdownWillOWisp => _showdownWillOWisp(ctx),
      BattleMoveVisualRecipeId.showdownLifeDew => _showdownLifeDew(ctx),
      BattleMoveVisualRecipeId.showdownAromatherapy =>
        _showdownAromatherapy(ctx),
      BattleMoveVisualRecipeId.showdownRest => _showdownRest(ctx),
      BattleMoveVisualRecipeId.showdownIngrain => _showdownIngrain(ctx),
      BattleMoveVisualRecipeId.showdownMorningSun => _showdownMorningSun(ctx),
      BattleMoveVisualRecipeId.showdownShoreUp => _showdownShoreUp(ctx),
      BattleMoveVisualRecipeId.showdownDrain => _showdownDrain(ctx),
      BattleMoveVisualRecipeId.showdownLeechLife => _showdownLeechLife(ctx),
      BattleMoveVisualRecipeId.showdownHornLeech => _showdownHornLeech(ctx),
      BattleMoveVisualRecipeId.showdownParabolicCharge =>
        _showdownParabolicCharge(ctx),
      BattleMoveVisualRecipeId.showdownDrainingKiss =>
        _showdownDrainingKiss(ctx),
      BattleMoveVisualRecipeId.showdownOblivionWing =>
        _showdownOblivionWing(ctx),
      BattleMoveVisualRecipeId.showdownLeechSeed => _showdownLeechSeed(ctx),
      BattleMoveVisualRecipeId.showdownHyperBeam => _showdownHyperBeam(ctx),
      BattleMoveVisualRecipeId.showdownSignalBeam => _showdownSignalBeam(ctx),
      BattleMoveVisualRecipeId.showdownFleurCannon => _showdownFleurCannon(ctx),
      BattleMoveVisualRecipeId.showdownArmorCannon => _showdownArmorCannon(ctx),
      BattleMoveVisualRecipeId.showdownSteelBeam => _showdownSteelBeam(ctx),
      BattleMoveVisualRecipeId.showdownBeakBlast => _showdownBeakBlast(ctx),
      BattleMoveVisualRecipeId.showdownTwinBeam => _showdownTwinBeam(ctx),
      BattleMoveVisualRecipeId.showdownSpikeCannon => _showdownSpikeCannon(ctx),
      BattleMoveVisualRecipeId.showdownWaterShuriken =>
        _showdownWaterShuriken(ctx),
      BattleMoveVisualRecipeId.showdownTerastarStorm =>
        _showdownTerastarStorm(ctx),
      BattleMoveVisualRecipeId.showdownMeteorMash => _showdownMeteorMash(ctx),
      BattleMoveVisualRecipeId.showdownSplash => _showdownSplash(ctx),
      BattleMoveVisualRecipeId.showdownCelebrate => _showdownCelebrate(ctx),
      BattleMoveVisualRecipeId.showdownOrderUp => _showdownOrderUp(ctx),
      BattleMoveVisualRecipeId.showdownHeartStamp => _showdownHeartStamp(ctx),
      BattleMoveVisualRecipeId.showdownMatchaGotcha =>
        _showdownMatchaGotcha(ctx),
      BattleMoveVisualRecipeId.showdownPresent => _showdownPresent(ctx),
      BattleMoveVisualRecipeId.showdownPayDay => _showdownPayDay(ctx),
      BattleMoveVisualRecipeId.noAnimation => const <BattleAnimationStep>[
          WaitStep(durationSeconds: 0),
        ],
    };
  }

  List<BattleAnimationStep> _contactCombo({
    required BattleMoveVisualRecipeContext ctx,
    required bool heavy,
  }) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: heavy ? 0.18 : 0.14,
        distancePx: heavy ? 34 : 24,
      ),
      SpawnFxStep(
        effectId: 'impact',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: heavy ? 0.16 : 0.12,
        afterEffect: BattleFxAfterEffect.fade,
        endScale: heavy ? 1.25 : 1.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.1,
      ),
      if (heavy)
        CombatantShakeStep(
          side: targetSide,
          amplitudePx: 10,
          durationSeconds: 0.14,
        ),
    ];
  }

  List<BattleAnimationStep> _slashCombo(BattleMoveVisualRecipeContext ctx) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      SpawnFxStep(
        effectId: 'leftslash',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.14,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.1,
      ),
    ];
  }

  List<BattleAnimationStep> _genericPunch(BattleMoveVisualRecipeContext ctx) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.16,
        distancePx: 24,
      ),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.14,
        startScale: 0.9,
        endScale: 1.8,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.09,
      ),
    ];
  }

  List<BattleAnimationStep> _genericBite(BattleMoveVisualRecipeContext ctx) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.16,
        distancePx: 24,
      ),
      _targetFx(
        ctx,
        effectId: 'topbite',
        durationSeconds: 0.14,
        toOffsetY: -14,
        startScale: 1.0,
        endScale: 1.4,
        startOpacity: 0.9,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'bottombite',
        durationSeconds: 0.14,
        toOffsetY: 14,
        startScale: 1.0,
        endScale: 1.4,
        startOpacity: 0.9,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.09,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 7,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _projectileSimple({
    required BattleMoveVisualRecipeContext ctx,
    required String effectId,
  }) {
    final defenderSide = ctx.targetSide ?? ctx.attackerSide;
    final steps = <BattleAnimationStep>[
      SpawnFxStep(
        effectId: effectId,
        attackerSide: ctx.attackerSide,
        defenderSide: defenderSide,
        from: BattleVisualAnchor.attackerCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.26,
        curve: BattleFxMotionCurve.arcOver,
      ),
    ];
    if (ctx.didHit && ctx.targetSide != null) {
      steps.add(
        SpawnFxStep(
          effectId: 'impact',
          attackerSide: ctx.attackerSide,
          defenderSide: ctx.targetSide!,
          from: BattleVisualAnchor.defenderCenter,
          to: BattleVisualAnchor.defenderCenter,
          durationSeconds: 0.12,
          afterEffect: BattleFxAfterEffect.fade,
        ),
      );
      steps.add(
        CombatantFlashStep(
          side: ctx.targetSide!,
          durationSeconds: 0.1,
        ),
      );
    }
    return steps;
  }

  List<BattleAnimationStep> _buffPulse(BattleMoveVisualRecipeContext ctx) {
    return <BattleAnimationStep>[
      SpawnFxStep(
        effectId: 'shine',
        attackerSide: ctx.attackerSide,
        defenderSide: ctx.attackerSide,
        from: BattleVisualAnchor.attackerCenter,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.22,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      ScreenFlashStep(
        colorArgb: 0x44A8F0FF,
        durationSeconds: 0.18,
      ),
    ];
  }

  List<BattleAnimationStep> _debuffPulse(BattleMoveVisualRecipeContext ctx) {
    final targetSide = ctx.targetSide ?? BattleSideId.enemy;
    return <BattleAnimationStep>[
      SpawnFxStep(
        effectId: 'angry',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderHead,
        durationSeconds: 0.22,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 6,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _statusPulse(BattleMoveVisualRecipeContext ctx) {
    final targetSide = ctx.targetSide ?? BattleSideId.enemy;
    return <BattleAnimationStep>[
      SpawnFxStep(
        effectId: 'wisp',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.2,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownTackle(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.22,
        distancePx: 30,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownScratch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.22,
        distancePx: 28,
      ),
      SpawnFxStep(
        effectId: 'rightslash',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.18,
        afterEffect: BattleFxAfterEffect.fade,
        startScale: 1.0,
        endScale: 2.2,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 7,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownQuickAttack(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      SpawnFxStep(
        effectId: 'wisp',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.26,
        afterEffect: BattleFxAfterEffect.fade,
        startScale: 0.0,
        endScale: 1.9,
        startOpacity: 0.5,
        endOpacity: 0.0,
      ),
      SpawnFxStep(
        effectId: 'wisp',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.30,
        afterEffect: BattleFxAfterEffect.fade,
        startScale: 0.0,
        endScale: 1.9,
        startOpacity: 0.5,
        endOpacity: 0.0,
        fromOffsetY: -10,
        toOffsetY: -10,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.30,
        distancePx: 42,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 9,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSlash(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.40,
        distancePx: 40,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'rightslash',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.50,
        startScale: 1.0,
        endScale: 3.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 7,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownAerialAce(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.16,
        distancePx: 30,
      ),
      _targetFx(
        ctx,
        effectId: 'leftslash',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        fromOffsetX: -10,
        fromOffsetY: -10,
        durationSeconds: 0.14,
        startScale: 1.5,
        endScale: 2.0,
        startOpacity: 0.6,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.12,
        startScale: 0.1,
        endScale: 2,
        startOpacity: 0.5,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'wisp',
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.12,
        startScale: 0.1,
        endScale: 2,
        startOpacity: 0.5,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownCloseCombat(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.18,
        distancePx: 34,
      ),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.10,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 1,
      ),
      WaitStep(durationSeconds: 0.03),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.10,
        toOffsetX: -10,
        toOffsetY: 20,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 1,
      ),
      WaitStep(durationSeconds: 0.03),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.10,
        toOffsetX: 30,
        toOffsetY: -20,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 1,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.12,
        toOffsetX: -30,
        toOffsetY: -20,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 1,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.12,
        toOffsetY: -10,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 1,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.12,
        toOffsetY: 10,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 1,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.18,
        startScale: 0,
        endScale: 3,
        startOpacity: 0.4,
        endOpacity: 0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 10,
        durationSeconds: 0.18,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownBodySlam(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.22,
        distancePx: 38,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        toOffsetX: 34,
        toOffsetY: -18,
        startScale: 1.0,
        endScale: 0.8,
        startOpacity: 0.8,
        endOpacity: 0.2,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        toOffsetX: -34,
        toOffsetY: -18,
        startScale: 1.0,
        endScale: 0.8,
        startOpacity: 0.8,
        endOpacity: 0.2,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.18,
        toOffsetY: 8,
        startScale: 0.8,
        endScale: 1.8,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 10,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownHighJumpKick(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.28,
        distancePx: 54,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'foot',
        durationSeconds: 0.18,
        toOffsetX: -24,
        toOffsetY: -14,
        startScale: 0.9,
        endScale: 1.7,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.16,
        toOffsetX: -8,
        toOffsetY: 6,
        startScale: 0.8,
        endScale: 1.6,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 11,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownKarateChop(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.18,
        distancePx: 34,
      ),
      _targetFx(
        ctx,
        effectId: 'rightchop',
        durationSeconds: 0.14,
        toOffsetX: -18,
        toOffsetY: -20,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 1.0,
        endOpacity: 0.4,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.14,
        toOffsetX: 10,
        toOffsetY: 4,
        startScale: 0.7,
        endScale: 1.4,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDrillRun(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.20,
        distancePx: 38,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.14,
        startScale: 0.0,
        endScale: 2.2,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.14,
        toOffsetX: 12,
        toOffsetY: -6,
        startScale: 0.0,
        endScale: 2.4,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.16,
        startScale: 0.0,
        endScale: 1.8,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 9,
        durationSeconds: 0.15,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownThunderbolt(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33000000,
        durationSeconds: 0.16,
      ),
      _targetFx(
        ctx,
        effectId: 'lightning',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        fromOffsetY: -90,
        toOffsetY: -10,
        durationSeconds: 0.18,
        startScale: 0.9,
        endScale: 1.1,
        startOpacity: 0.9,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.06),
      _targetFx(
        ctx,
        effectId: 'lightning',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        fromOffsetX: -15,
        fromOffsetY: -90,
        toOffsetX: -15,
        toOffsetY: -10,
        durationSeconds: 0.18,
        startScale: 0.9,
        endScale: 1.1,
        startOpacity: 0.9,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.06),
      _targetFx(
        ctx,
        effectId: 'lightning',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        fromOffsetX: 15,
        fromOffsetY: -90,
        toOffsetX: 15,
        toOffsetY: -10,
        durationSeconds: 0.18,
        startScale: 0.9,
        endScale: 1.1,
        startOpacity: 0.9,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownHiddenPower(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const diagonalBursts = <({double x, double y})>[
      (x: 42, y: -24),
      (x: -42, y: -24),
      (x: 42, y: 24),
      (x: -42, y: 24),
    ];
    const axialBursts = <({double x, double y})>[
      (x: 0, y: -62),
      (x: 62, y: 0),
      (x: 0, y: 62),
      (x: -62, y: 0),
    ];
    final steps = <BattleAnimationStep>[
      for (final burst in diagonalBursts)
        _attackerChargeFx(
          ctx,
          effectId: 'electroball',
          durationSeconds: 0.80,
          curve: BattleFxMotionCurve.easeOut,
          toOffsetX: burst.x,
          toOffsetY: burst.y,
          startScale: 0.5,
          endScale: 1.0,
          startOpacity: 1.0,
          endOpacity: 0.5,
          afterEffect: BattleFxAfterEffect.fade,
        ),
      const WaitStep(durationSeconds: 0.04),
      for (final burst in axialBursts)
        _attackerChargeFx(
          ctx,
          effectId: 'electroball',
          durationSeconds: 0.80,
          curve: BattleFxMotionCurve.easeOut,
          toOffsetX: burst.x,
          toOffsetY: burst.y,
          startScale: 0.5,
          endScale: 1.0,
          startOpacity: 1.0,
          endOpacity: 0.5,
          afterEffect: BattleFxAfterEffect.fade,
        ),
    ];
    return steps;
  }

  List<BattleAnimationStep> _showdownChargeBeam(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x223A8DFF,
        durationSeconds: 0.16,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.20,
        startScale: 0.5,
        endScale: 0.9,
        startOpacity: 0.2,
        endOpacity: 0.6,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.20,
        toOffsetX: 10,
        toOffsetY: -5,
        startScale: 0.5,
        endScale: 0.9,
        startOpacity: 0.2,
        endOpacity: 0.6,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.20,
        toOffsetX: -10,
        toOffsetY: 5,
        startScale: 0.5,
        endScale: 0.9,
        startOpacity: 0.2,
        endOpacity: 0.6,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.20,
        toOffsetY: -5,
        startScale: 0.5,
        endScale: 0.9,
        startOpacity: 0.2,
        endOpacity: 0.6,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 6,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownShadowBall(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x1A000000,
        durationSeconds: 0.18,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'poisonwisp',
        fromOffsetY: 100,
        durationSeconds: 0.16,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'poisonwisp',
        fromOffsetX: -60,
        fromOffsetY: -80,
        durationSeconds: 0.16,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'poisonwisp',
        fromOffsetX: 60,
        fromOffsetY: -80,
        durationSeconds: 0.16,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'poisonwisp',
        fromOffsetX: -90,
        fromOffsetY: 40,
        durationSeconds: 0.16,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'poisonwisp',
        fromOffsetX: 90,
        fromOffsetY: 40,
        durationSeconds: 0.16,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.22,
        startScale: 0.0,
        endScale: 0.8,
        startOpacity: 0,
        endOpacity: 0.5,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.22,
        startScale: 0.0,
        endScale: 1.5,
        startOpacity: 0,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.08),
      _projectileToTarget(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.8,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 1.5,
        endScale: 2.0,
        startOpacity: 0.8,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDarkPulse(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33000000,
        durationSeconds: 0.20,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'shadowball',
        from: BattleVisualAnchor.attackerHead,
        to: BattleVisualAnchor.attackerHead,
        fromOffsetY: -50,
        toOffsetY: -50,
        durationSeconds: 0.18,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 0.8,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.10),
      _targetFx(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.16,
        startScale: 0,
        endScale: 2,
        startOpacity: 0.3,
        endOpacity: 0,
      ),
      WaitStep(durationSeconds: 0.08),
      _targetFx(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.16,
        startScale: 0,
        endScale: 2,
        startOpacity: 0.3,
        endOpacity: 0,
      ),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.18,
        fromOffsetX: -40,
        toOffsetX: 40,
        startScale: 0.2,
        endScale: 0.9,
        startOpacity: 0.4,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.18,
        fromOffsetX: 0,
        fromOffsetY: -40,
        toOffsetY: 40,
        startScale: 0.2,
        endScale: 0.9,
        startOpacity: 0.4,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 7,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownAuraSphere(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x66124763,
        durationSeconds: 0.18,
      ),
      const ScreenFlashStep(
        colorArgb: 0x44FFC001,
        durationSeconds: 0.12,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        fromOffsetY: 100,
        durationSeconds: 0.18,
        startScale: 0.5,
        endScale: 0.8,
        startOpacity: 0,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.05),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        fromOffsetX: -60,
        fromOffsetY: -80,
        durationSeconds: 0.18,
        startScale: 0.5,
        endScale: 1.5,
        startOpacity: 0,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.22,
        startScale: 0,
        endScale: 0.8,
        startOpacity: 0,
        endOpacity: 0.5,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.22,
        startScale: 0,
        endScale: 1.5,
        startOpacity: 0,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.10),
      _projectileToTarget(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.8,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 1.0,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 1.0,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownBubbleBeam(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    final steps = <BattleAnimationStep>[];
    final offsets = <({double x, double y})>[
      (x: 0, y: 0),
      (x: 20, y: -10),
      (x: -20, y: 10),
      (x: 0, y: -5),
    ];
    for (var i = 0; i < offsets.length; i++) {
      if (i > 0) {
        steps.add(const WaitStep(durationSeconds: 0.06));
      }
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: 'iceball',
          durationSeconds: 0.22,
          curve: BattleFxMotionCurve.easeOut,
          toOffsetX: offsets[i].x,
          toOffsetY: offsets[i].y,
          startScale: 0.5,
          endScale: 0.9,
          startOpacity: 0.7,
          endOpacity: 0.6,
          afterEffect: BattleFxAfterEffect.explode,
        ),
      );
    }
    steps.add(
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
    );
    return steps;
  }

  List<BattleAnimationStep> _showdownFireBlast(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x66000000,
        durationSeconds: 0.16,
      ),
      const ScreenFlashStep(
        colorArgb: 0x44390000,
        durationSeconds: 0.18,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.linear,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 0.2,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.linear,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 0.2,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.18,
        startScale: 2.0,
        endScale: 3.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        toOffsetY: 100,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.18,
        startScale: 2.0,
        endScale: 3.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        toOffsetX: -60,
        toOffsetY: -80,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.18,
        startScale: 2.0,
        endScale: 3.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        toOffsetX: 60,
        toOffsetY: -80,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 10,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownBlizzard(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    final steps = <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x66009AA4,
        durationSeconds: 0.18,
      ),
    ];
    final offsets = <({double x, double y})>[
      (x: 60, y: 40),
      (x: 40, y: -40),
      (x: -60, y: 0),
      (x: -20, y: 10),
    ];
    for (var i = 0; i < offsets.length; i++) {
      if (i > 0) {
        steps.add(const WaitStep(durationSeconds: 0.05));
      }
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: 'icicle',
          durationSeconds: 0.20,
          curve: BattleFxMotionCurve.easeOut,
          toOffsetX: offsets[i].x,
          toOffsetY: offsets[i].y,
          startScale: 0.6,
          endScale: 2.0,
          startOpacity: 0.6,
          endOpacity: 0.3,
          afterEffect: BattleFxAfterEffect.explode,
        ),
      );
    }
    steps.add(
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    );
    steps.add(
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.14,
      ),
    );
    return steps;
  }

  List<BattleAnimationStep> _showdownDazzlingGleam(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    final steps = <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x66FF99FF,
        durationSeconds: 0.18,
      ),
    ];
    final offsets = <({double x, double y})>[
      (x: 30, y: 30),
      (x: 20, y: -30),
      (x: -30, y: 0),
      (x: -10, y: 10),
      (x: 10, y: 0),
    ];
    for (var i = 0; i < offsets.length; i++) {
      if (i > 0) {
        steps.add(const WaitStep(durationSeconds: 0.05));
      }
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: 'wisp',
          durationSeconds: 0.18,
          curve: BattleFxMotionCurve.linear,
          toOffsetX: offsets[i].x,
          toOffsetY: offsets[i].y,
          startScale: 0.6,
          endScale: 1.0,
          startOpacity: 0.6,
          endOpacity: 0.3,
          afterEffect: BattleFxAfterEffect.explode,
        ),
      );
    }
    steps.add(
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    );
    return steps;
  }

  List<BattleAnimationStep> _showdownCalmMind(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x222D195B,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.18,
        startScale: 2.0,
        endScale: 0.1,
        startOpacity: 0.1,
        endOpacity: 0.5,
      ),
      WaitStep(durationSeconds: 0.08),
      _attackerChargeFx(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.18,
        startScale: 2.0,
        endScale: 0.1,
        startOpacity: 0.1,
        endOpacity: 0.5,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSwordsDance(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final steps = <BattleAnimationStep>[
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 4,
        durationSeconds: 0.12,
      ),
    ];
    final pairs = <({double fromX, double toX})>[
      (fromX: 50, toX: -50),
      (fromX: -50, toX: 50),
      (fromX: 50, toX: -50),
      (fromX: -50, toX: 50),
      (fromX: 50, toX: -50),
      (fromX: -50, toX: 50),
    ];
    for (var i = 0; i < pairs.length; i++) {
      if (i > 0) {
        steps.add(const WaitStep(durationSeconds: 0.06));
      }
      steps.add(
        _attackerChargeFx(
          ctx,
          effectId: 'sword',
          fromOffsetX: pairs[i].fromX,
          toOffsetX: pairs[i].toX,
          durationSeconds: 0.16,
          curve: i.isEven
              ? BattleFxMotionCurve.arcOver
              : BattleFxMotionCurve.arcUnder,
          startScale: 0.5,
          endScale: 1.0,
          startOpacity: 1.0,
          endOpacity: 0.4,
          afterEffect: BattleFxAfterEffect.fade,
        ),
      );
    }
    return steps;
  }

  List<BattleAnimationStep> _showdownAgility(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 10,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        fromOffsetX: 20,
        toOffsetX: -30,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 1.0,
        endScale: 1.2,
        startOpacity: 0.5,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 1.0,
        endScale: 1.2,
        startOpacity: 0.5,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        fromOffsetX: -20,
        toOffsetX: 30,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 1.0,
        endScale: 1.2,
        startOpacity: 0.5,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownBulkUp(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x224C2C16,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        fromOffsetY: 20,
        toOffsetX: -30,
        toOffsetY: 20,
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.1,
        endOpacity: 0.3,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 4,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownCharm(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? BattleSideId.enemy;
    return <BattleAnimationStep>[
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 4,
        durationSeconds: 0.12,
      ),
      _targetFx(
        ctx,
        effectId: 'heart',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderHead,
        fromOffsetX: 20,
        fromOffsetY: 20,
        durationSeconds: 0.16,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.5,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'heart',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderHead,
        fromOffsetX: -20,
        fromOffsetY: 10,
        durationSeconds: 0.16,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.5,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'heart',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderHead,
        fromOffsetY: 40,
        durationSeconds: 0.16,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.5,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownConfuseRay(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? BattleSideId.enemy;
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.20,
        toOffsetX: 40,
        toOffsetY: 15,
        startScale: 0.15,
        endScale: 0.3,
        startOpacity: 0,
        endOpacity: 0.7,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.08),
      _targetFx(
        ctx,
        effectId: 'electroball',
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.defenderCenter,
        fromOffsetX: 40,
        fromOffsetY: 15,
        toOffsetX: -40,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.3,
        endScale: 0.2,
        startOpacity: 0.7,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.06),
      _targetFx(
        ctx,
        effectId: 'electroball',
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.defenderCenter,
        fromOffsetX: -40,
        toOffsetX: 10,
        toOffsetY: -15,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.1,
        endScale: 0.5,
        startOpacity: 0,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownGrowl(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        startScale: 0,
        endScale: 5,
        startOpacity: 0.7,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.06),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        startScale: 0,
        endScale: 5,
        startOpacity: 0.7,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.06),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        startScale: 0,
        endScale: 5,
        startOpacity: 0.7,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownTaunt(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 6,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'pointer',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.easeOut,
        fromOffsetX: 50,
        fromOffsetY: 30,
        toOffsetX: 30,
        toOffsetY: 35,
        startScale: 0.4,
        endScale: 0.5,
        startOpacity: 1.0,
        endOpacity: 1.0,
      ),
      const WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'pointer',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.linear,
        fromOffsetX: 30,
        fromOffsetY: 35,
        toOffsetX: 60,
        toOffsetY: 30,
        startScale: 0.5,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'angry',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderHead,
        fromOffsetX: 20,
        fromOffsetY: 20,
        durationSeconds: 0.16,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.5,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'angry',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderHead,
        fromOffsetX: -20,
        fromOffsetY: 10,
        durationSeconds: 0.16,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.5,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'angry',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderHead,
        fromOffsetY: 40,
        durationSeconds: 0.16,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.5,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownInstruct(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 6,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'pointer',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.easeOut,
        fromOffsetX: 50,
        fromOffsetY: 30,
        toOffsetX: 30,
        toOffsetY: 35,
        startScale: 0.4,
        endScale: 0.5,
        startOpacity: 1.0,
        endOpacity: 1.0,
      ),
      const WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'pointer',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.linear,
        fromOffsetX: 30,
        fromOffsetY: 35,
        toOffsetX: 60,
        toOffsetY: 30,
        startScale: 0.5,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.06),
      SpawnFxStep(
        effectId: 'poisonwisp',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.attackerCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.30,
        curve: BattleFxMotionCurve.arcOver,
        fromOffsetX: 60,
        fromOffsetY: 50,
        startScale: 0.5,
        endScale: 0.6,
        startOpacity: 0.1,
        endOpacity: 0.3,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      SpawnFxStep(
        effectId: 'wisp',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.attackerCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.30,
        curve: BattleFxMotionCurve.arcOver,
        fromOffsetX: 60,
        fromOffsetY: 50,
        startScale: 0.5,
        endScale: 0.6,
        startOpacity: 0.3,
        endOpacity: 0.6,
        afterEffect: BattleFxAfterEffect.explode,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownQuash(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.28,
        distancePx: 44,
      ),
      const WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'rightchop',
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.defenderCenter,
        fromOffsetY: 10,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.5,
        endScale: 0.25,
        startOpacity: 0.1,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 7,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSwagger(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 6,
        durationSeconds: 0.16,
      ),
      _targetFx(
        ctx,
        effectId: 'angry',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderHead,
        fromOffsetX: 20,
        fromOffsetY: 20,
        durationSeconds: 0.16,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.5,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'angry',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderHead,
        fromOffsetX: -20,
        fromOffsetY: 10,
        durationSeconds: 0.16,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.5,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'angry',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderHead,
        fromOffsetY: 40,
        durationSeconds: 0.16,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.5,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownEncore(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 10,
        durationSeconds: 0.40,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownBabyDollEyes(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x22FFB9D8,
        durationSeconds: 0.14,
      ),
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 4,
        durationSeconds: 0.18,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownThunderWave(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _attackerChargeFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        startScale: 1,
        endScale: 8,
        startOpacity: 0.2,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.08),
      _attackerChargeFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        startScale: 1,
        endScale: 8,
        startOpacity: 0.2,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.12),
      _targetFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        startScale: 1,
        endScale: 4,
        startOpacity: 0.2,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownProtect(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        startScale: 2,
        endScale: 0,
        startOpacity: 0.2,
        endOpacity: 1,
      ),
      WaitStep(durationSeconds: 0.08),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        startScale: 2,
        endScale: 0,
        startOpacity: 0.2,
        endOpacity: 1,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownBurningBulwark(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44390000,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.26,
        fromOffsetY: -24,
        toOffsetY: -12,
        startScale: 0.5,
        endScale: 2.2,
        startOpacity: 0.5,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.24,
        fromOffsetY: -12,
        toOffsetY: -6,
        startScale: 1.4,
        endScale: 1.9,
        startOpacity: 0.5,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.24,
        fromOffsetY: -10,
        toOffsetY: -4,
        startScale: 3,
        endScale: 1.8,
        startOpacity: 1,
        endOpacity: 0.5,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownBanefulBunker(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44440044,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.26,
        fromOffsetY: -24,
        toOffsetY: -12,
        startScale: 0.5,
        endScale: 2.2,
        startOpacity: 0.5,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.24,
        fromOffsetY: -12,
        toOffsetY: -6,
        startScale: 1.4,
        endScale: 1.9,
        startOpacity: 0.5,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.24,
        fromOffsetY: -10,
        toOffsetY: -4,
        startScale: 3,
        endScale: 1.8,
        startOpacity: 1,
        endOpacity: 0.5,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownReflect(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _shieldCast(
      ctx,
      colorArgb: 0xAAA76DFF,
      style: BattleBarrierStyle.reflect,
    );
  }

  List<BattleAnimationStep> _showdownLightScreen(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _shieldCast(
      ctx,
      colorArgb: 0xAA76E8FF,
      style: BattleBarrierStyle.lightScreen,
    );
  }

  List<BattleAnimationStep> _showdownMist(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _shieldCast(
      ctx,
      colorArgb: 0xAA9FD7FF,
      style: BattleBarrierStyle.mist,
    );
  }

  List<BattleAnimationStep> _showdownAuroraVeil(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _shieldCast(
      ctx,
      colorArgb: 0xAACCF7FF,
      style: BattleBarrierStyle.auroraVeil,
    );
  }

  List<BattleAnimationStep> _showdownSafeguard(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _shieldCast(
      ctx,
      colorArgb: 0xAAF7D76E,
      style: BattleBarrierStyle.safeguard,
    );
  }

  List<BattleAnimationStep> _showdownQuickGuard(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _shieldCast(
      ctx,
      colorArgb: 0xAA79FFCF,
      style: BattleBarrierStyle.quickGuard,
    );
  }

  List<BattleAnimationStep> _showdownWideGuard(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _shieldCast(
      ctx,
      colorArgb: 0xAA5EC6FF,
      style: BattleBarrierStyle.wideGuard,
    );
  }

  List<BattleAnimationStep> _shieldCast(
    BattleMoveVisualRecipeContext ctx, {
    required int colorArgb,
    required BattleBarrierStyle style,
  }) {
    return <BattleAnimationStep>[
      ScreenFlashStep(
        colorArgb: (colorArgb & 0x00FFFFFF) | 0x33000000,
        durationSeconds: 0.14,
      ),
      BarrierPulseStep(
        side: ctx.attackerSide,
        colorArgb: colorArgb,
        durationSeconds: 0.28,
        style: style,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownTailwind(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33D9F6FF,
        durationSeconds: 0.14,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'feather',
        fromOffsetX: -20,
        fromOffsetY: 16,
        toOffsetX: 20,
        toOffsetY: -28,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.5,
        endScale: 0.9,
        startOpacity: 0.8,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'feather',
        fromOffsetX: 22,
        fromOffsetY: 10,
        toOffsetX: -24,
        toOffsetY: -34,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.5,
        endScale: 0.9,
        startOpacity: 0.8,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 5,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownRainDance(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _showdownDanceCast(
      ctx,
      accentFx: 'waterwisp',
      colorArgb: 0x223EA8FF,
    );
  }

  List<BattleAnimationStep> _showdownSandstorm(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _showdownDanceCast(
      ctx,
      accentFx: 'mudwisp',
      colorArgb: 0x22D2A55A,
    );
  }

  List<BattleAnimationStep> _showdownTrickRoom(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _showdownDanceCast(
      ctx,
      accentFx: 'mistball',
      colorArgb: 0x229A5DFF,
    );
  }

  List<BattleAnimationStep> _showdownDanceCast(
    BattleMoveVisualRecipeContext ctx, {
    required String accentFx,
    required int colorArgb,
  }) {
    return <BattleAnimationStep>[
      ScreenFlashStep(
        colorArgb: colorArgb,
        durationSeconds: 0.16,
      ),
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 6,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: accentFx,
        fromOffsetX: -20,
        fromOffsetY: -10,
        toOffsetX: 20,
        toOffsetY: 20,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.7,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.06),
      _attackerChargeFx(
        ctx,
        effectId: accentFx,
        fromOffsetX: 20,
        fromOffsetY: -15,
        toOffsetX: -20,
        toOffsetY: 30,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.7,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownAquaJet(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _attackerChargeFx(
        ctx,
        effectId: 'waterwisp',
        fromOffsetX: 20,
        fromOffsetY: 30,
        toOffsetY: -20,
        durationSeconds: 0.16,
        startScale: 0.0,
        endScale: 1.6,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      SpawnFxStep(
        effectId: 'waterwisp',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.attackerCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.1,
        endScale: 1.2,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
        fromOffsetY: 20,
        toOffsetY: -10,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'waterwisp',
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.defenderCenter,
        fromOffsetX: 10,
        fromOffsetY: 30,
        toOffsetY: -20,
        durationSeconds: 0.16,
        startScale: 0.0,
        endScale: 1.8,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.30,
        distancePx: 42,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownExtremeSpeed(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        fromOffsetY: -30,
        toOffsetX: 20,
        toOffsetY: -10,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 1.2,
        endScale: 0.8,
        startOpacity: 0.6,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        fromOffsetY: -30,
        toOffsetX: -20,
        toOffsetY: -10,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 1.2,
        endScale: 0.8,
        startOpacity: 0.6,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.34,
        distancePx: 48,
      ),
      WaitStep(durationSeconds: 0.06),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.14,
        toOffsetX: -25,
        startScale: 0.7,
        endScale: 1.2,
        startOpacity: 0.7,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.03),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.14,
        toOffsetX: 25,
        toOffsetY: -5,
        startScale: 0.7,
        endScale: 1.2,
        startOpacity: 0.7,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.03),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.14,
        toOffsetX: -25,
        toOffsetY: 10,
        startScale: 0.7,
        endScale: 1.0,
        startOpacity: 0.7,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.03),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.16,
        toOffsetX: 2,
        toOffsetY: 5,
        startScale: 1.0,
        endScale: 1.5,
        startOpacity: 0.7,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 10,
        durationSeconds: 0.18,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownMachPunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.28,
        distancePx: 38,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.16,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.14,
        startScale: 0.8,
        endScale: 1.4,
        startOpacity: 0.5,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownShadowPunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44000000,
        durationSeconds: 0.18,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.24,
        distancePx: 34,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        toOffsetX: -18,
        toOffsetY: -4,
        startScale: 0.0,
        endScale: 1.9,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        toOffsetX: 16,
        toOffsetY: 8,
        startScale: 0.0,
        endScale: 1.9,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.16,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownFocusPunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33000000,
        durationSeconds: 0.18,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.30,
        distancePx: 42,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 2.8,
        startOpacity: 0.4,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.18,
        toOffsetX: 8,
        toOffsetY: -6,
        startScale: 0.0,
        endScale: 2.8,
        startOpacity: 0.4,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.18,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 10,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDrainPunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      ..._showdownMachPunch(ctx),
      WaitStep(durationSeconds: 0.03),
      SpawnFxStep(
        effectId: 'electroball',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.6,
        endScale: 0.6,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      SpawnFxStep(
        effectId: 'electroball',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.linear,
        startScale: 0.6,
        endScale: 0.6,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      SpawnFxStep(
        effectId: 'electroball',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.26,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.6,
        endScale: 0.6,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDynamicPunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44000000,
        durationSeconds: 0.18,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.18,
        distancePx: 28,
      ),
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.16,
        toOffsetX: 40,
        startScale: 0.0,
        endScale: 2.8,
        startOpacity: 0.6,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.16,
        toOffsetX: -40,
        toOffsetY: -20,
        startScale: 0.0,
        endScale: 2.8,
        startOpacity: 0.6,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.16,
        toOffsetX: 10,
        toOffsetY: 20,
        startScale: 0.0,
        endScale: 2.8,
        startOpacity: 0.6,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.16,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownCometPunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.22,
        distancePx: 32,
      ),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.14,
        toOffsetX: -12,
        startScale: 1.0,
        endScale: 1.8,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.14,
        toOffsetX: 12,
        toOffsetY: -8,
        startScale: 1.0,
        endScale: 1.8,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownMegaPunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.18,
        distancePx: 32,
      ),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.16,
        startScale: 1.0,
        endScale: 2.1,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.14,
        startScale: 0.8,
        endScale: 1.4,
        startOpacity: 0.4,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownPowerUpPunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      ..._showdownMegaPunch(ctx),
      WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        startScale: 0.2,
        endScale: 0.9,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDizzyPunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      ..._showdownMegaPunch(ctx),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        toOffsetX: -18,
        toOffsetY: -10,
        startScale: 0.3,
        endScale: 1.1,
        startOpacity: 0.8,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        toOffsetX: 18,
        toOffsetY: 10,
        startScale: 0.3,
        endScale: 1.1,
        startOpacity: 0.8,
        endOpacity: 0.0,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 9,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownJetPunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.1,
        endScale: 1.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.1,
        endScale: 1.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.16,
        toOffsetY: 50,
        startScale: 0.3,
        endScale: 0.3,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.16,
        toOffsetX: 50,
        startScale: 0.3,
        endScale: 0.3,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.16,
        toOffsetX: -50,
        startScale: 0.3,
        endScale: 0.3,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.16,
        toOffsetX: -25,
        toOffsetY: -50,
        startScale: 0.3,
        endScale: 0.3,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.16,
        toOffsetX: 25,
        toOffsetY: -50,
        startScale: 0.3,
        endScale: 0.3,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownFirePunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 2.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.18,
        toOffsetX: -18,
        toOffsetY: 10,
        startScale: 0.0,
        endScale: 2.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      ..._showdownMegaPunch(ctx),
    ];
  }

  List<BattleAnimationStep> _showdownIcePunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'icicle',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 2.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'icicle',
        durationSeconds: 0.18,
        toOffsetX: -18,
        toOffsetY: 10,
        startScale: 0.0,
        endScale: 2.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      ..._showdownMegaPunch(ctx),
    ];
  }

  List<BattleAnimationStep> _showdownThunderPunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 2.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'lightning',
        durationSeconds: 0.18,
        toOffsetX: -18,
        toOffsetY: 10,
        startScale: 0.0,
        endScale: 2.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      ..._showdownMegaPunch(ctx),
    ];
  }

  List<BattleAnimationStep> _showdownBlazeKick(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 2.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.18,
        toOffsetX: -18,
        toOffsetY: 10,
        startScale: 0.0,
        endScale: 2.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.26,
        distancePx: 46,
      ),
      _targetFx(
        ctx,
        effectId: 'foot',
        durationSeconds: 0.18,
        toOffsetY: 8,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownThunderousKick(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      ..._showdownDoubleKick(ctx),
      const ScreenFlashStep(
        colorArgb: 0x66FFFFFF,
        durationSeconds: 0.12,
      ),
      const ScreenFlashStep(
        colorArgb: 0x44000000,
        durationSeconds: 0.20,
      ),
      _targetFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 2.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        toOffsetX: -18,
        toOffsetY: 10,
        startScale: 0.0,
        endScale: 2.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'lightning',
        durationSeconds: 0.14,
        toOffsetX: 60,
        toOffsetY: -20,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'lightning',
        durationSeconds: 0.14,
        toOffsetX: -50,
        toOffsetY: -20,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'lightning',
        durationSeconds: 0.14,
        toOffsetX: -60,
        toOffsetY: 20,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'lightning',
        durationSeconds: 0.14,
        toOffsetX: 50,
        toOffsetY: 30,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'lightning',
        durationSeconds: 0.14,
        toOffsetX: -10,
        toOffsetY: 60,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownTropKick(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      ..._showdownDoubleKick(ctx),
      const ScreenFlashStep(
        colorArgb: 0x449AB440,
        durationSeconds: 0.16,
      ),
      _targetFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 2.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.18,
        toOffsetX: -18,
        toOffsetY: 10,
        startScale: 0.0,
        endScale: 2.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'petal',
        durationSeconds: 0.14,
        toOffsetX: 60,
        toOffsetY: -20,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'petal',
        durationSeconds: 0.14,
        toOffsetX: -50,
        toOffsetY: -20,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'petal',
        durationSeconds: 0.14,
        toOffsetX: -60,
        toOffsetY: 20,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'petal',
        durationSeconds: 0.14,
        toOffsetX: 50,
        toOffsetY: 30,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'petal',
        durationSeconds: 0.14,
        toOffsetX: -10,
        toOffsetY: 60,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownWoodHammer(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _cudgelStrike(
      ctx,
      openerEffectIds: const <String>['energyball', 'energyball'],
      accentEffectIds: const <String>['leaf1', 'leaf2', 'leaf2'],
      accentEndScale: 1.8,
    );
  }

  List<BattleAnimationStep> _showdownIvyCudgel(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _cudgelStrike(
      ctx,
      openerEffectIds: const <String>['energyball', 'energyball'],
      accentEffectIds: const <String>['leaf1', 'leaf2', 'leaf2'],
      accentEndScale: 1.25,
    );
  }

  List<BattleAnimationStep> _showdownIvyCudgelWater(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _cudgelStrike(
      ctx,
      openerEffectIds: const <String>['waterwisp', 'waterwisp'],
      accentEffectIds: const <String>['iceball', 'iceball', 'iceball'],
      accentEndScale: 1.25,
    );
  }

  List<BattleAnimationStep> _showdownIvyCudgelFire(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _cudgelStrike(
      ctx,
      openerEffectIds: const <String>['flareball', 'flareball'],
      accentEffectIds: const <String>['fireball', 'fireball', 'fireball'],
      accentEndScale: 1.25,
    );
  }

  List<BattleAnimationStep> _showdownIvyCudgelRock(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _cudgelStrike(
      ctx,
      openerEffectIds: const <String>['mudwisp', 'mudwisp'],
      accentEffectIds: const <String>['rock1', 'rock2', 'rock3'],
      accentEndScale: 1.25,
    );
  }

  List<BattleAnimationStep> _showdownCut(BattleMoveVisualRecipeContext ctx) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'leftslash',
        durationSeconds: 0.16,
        startScale: 0.9,
        endScale: 1.9,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownShadowClaw(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44000000,
        durationSeconds: 0.16,
      ),
      _targetFx(
        ctx,
        effectId: 'leftclaw',
        durationSeconds: 0.16,
        startScale: 0.9,
        endScale: 1.9,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'rightclaw',
        durationSeconds: 0.16,
        toOffsetX: -10,
        toOffsetY: -8,
        startScale: 0.9,
        endScale: 1.9,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownMultiAttack(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44000000,
        durationSeconds: 0.18,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.16,
        startScale: 1.0,
        endScale: 1.8,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'leftslash',
        durationSeconds: 0.18,
        toOffsetX: 5,
        toOffsetY: 20,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'rightslash',
        durationSeconds: 0.18,
        toOffsetX: -5,
        toOffsetY: -20,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 7,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownBite(BattleMoveVisualRecipeContext ctx) {
    return _biteStrike(ctx);
  }

  List<BattleAnimationStep> _showdownSuperFang(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33000000,
        durationSeconds: 0.14,
      ),
      ..._biteStrike(ctx),
    ];
  }

  List<BattleAnimationStep> _showdownBugBite(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      ..._biteStrike(ctx),
      _targetFx(
        ctx,
        effectId: 'web',
        durationSeconds: 0.16,
        startScale: 0.7,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownPsychicFangs(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      ..._biteStrike(ctx),
      _targetFx(
        ctx,
        effectId: 'mistball',
        durationSeconds: 0.16,
        toOffsetX: 12,
        toOffsetY: -10,
        startScale: 0.4,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'pointer',
        durationSeconds: 0.14,
        toOffsetX: 10,
        toOffsetY: -8,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownIronHead(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _contactCombo(
      ctx: ctx,
      heavy: true,
    );
  }

  List<BattleAnimationStep> _showdownHeadbutt(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _contactCombo(
      ctx: ctx,
      heavy: true,
    );
  }

  List<BattleAnimationStep> _showdownStomp(BattleMoveVisualRecipeContext ctx) {
    return _contactCombo(
      ctx: ctx,
      heavy: true,
    );
  }

  List<BattleAnimationStep> _showdownHammerArm(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _hammerDropStrike(
      ctx,
      accentEffectId: 'shadowball',
      extraEffectIds: const <String>['wisp', 'wisp'],
      screenColor: null,
    );
  }

  List<BattleAnimationStep> _showdownIceHammer(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _hammerDropStrike(
      ctx,
      accentEffectId: 'iceball',
      extraEffectIds: const <String>['wisp', 'wisp', 'icicle', 'icicle'],
      screenColor: 0x33FFFFFF,
    );
  }

  List<BattleAnimationStep> _showdownSkyUppercut(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.24,
        distancePx: 34,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        startScale: 0.0,
        endScale: 2.0,
        startOpacity: 0.5,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.16,
        fromOffsetX: -20,
        fromOffsetY: 10,
        toOffsetY: 80,
        startScale: 1.2,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.easeOut,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.14,
        toOffsetY: -8,
        startScale: 0.8,
        endScale: 1.6,
        startOpacity: 0.5,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownNeedleArm(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.18,
        distancePx: 28,
      ),
      _targetFx(
        ctx,
        effectId: 'rightslash',
        durationSeconds: 0.14,
        toOffsetX: -20,
        toOffsetY: -12,
        startScale: 0.8,
        endScale: 1.3,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.14,
        startScale: 0.8,
        endScale: 1.6,
        startOpacity: 0.5,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownRockSmash(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      ..._showdownMegaPunch(ctx),
      _targetFx(
        ctx,
        effectId: 'rock3',
        durationSeconds: 0.16,
        startScale: 0.7,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
    ];
  }

  List<BattleAnimationStep> _cudgelStrike(
    BattleMoveVisualRecipeContext ctx, {
    required List<String> openerEffectIds,
    required List<String> accentEffectIds,
    required double accentEndScale,
  }) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    const openerOffsets = <({double x, double y})>[
      (x: 0, y: 0),
      (x: 0, y: 0),
    ];
    const accentOffsets =
        <({double fromX, double fromY, double toX, double toY})>[
      (fromX: 0, fromY: -40, toX: 0, toY: 10),
      (fromX: -40, fromY: -40, toX: -30, toY: 0),
      (fromX: 40, fromY: -40, toX: 40, toY: 0),
    ];
    final steps = <BattleAnimationStep>[];
    for (var i = 0; i < openerEffectIds.length; i++) {
      final offset = openerOffsets[i];
      steps.add(
        _targetFx(
          ctx,
          effectId: openerEffectIds[i],
          durationSeconds: 0.18,
          toOffsetX: offset.x,
          toOffsetY: offset.y,
          startScale: 0.0,
          endScale: 2.2,
          startOpacity: 1.0,
          endOpacity: 0.0,
          afterEffect: BattleFxAfterEffect.fade,
        ),
      );
    }
    for (var i = 0; i < accentEffectIds.length; i++) {
      final offset = accentOffsets[i];
      steps.add(
        _targetFx(
          ctx,
          effectId: accentEffectIds[i],
          durationSeconds: 0.18,
          fromOffsetX: offset.fromX,
          fromOffsetY: offset.fromY,
          toOffsetX: offset.toX,
          toOffsetY: offset.toY,
          startScale: 1.0,
          endScale: accentEndScale,
          startOpacity: 1.0,
          endOpacity: 0.0,
          curve: BattleFxMotionCurve.easeOut,
          afterEffect: BattleFxAfterEffect.fade,
        ),
      );
    }
    steps.add(
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    );
    steps.add(
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.16,
      ),
    );
    return steps;
  }

  List<BattleAnimationStep> _biteStrike(BattleMoveVisualRecipeContext ctx) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'topbite',
        durationSeconds: 0.16,
        toOffsetY: 20,
        startScale: 0.7,
        endScale: 1.1,
        startOpacity: 0.0,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'bottombite',
        durationSeconds: 0.16,
        toOffsetY: -20,
        startScale: 0.7,
        endScale: 1.1,
        startOpacity: 0.0,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 7,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _hammerDropStrike(
    BattleMoveVisualRecipeContext ctx, {
    required String accentEffectId,
    required List<String> extraEffectIds,
    required int? screenColor,
  }) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    final steps = <BattleAnimationStep>[
      if (screenColor != null)
        ScreenFlashStep(
          colorArgb: screenColor,
          durationSeconds: 0.16,
        ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.24,
        distancePx: 36,
      ),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.18,
        fromOffsetY: 80,
        toOffsetY: -10,
        startScale: 1.2,
        endScale: 1.6,
        startOpacity: 0.8,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.easeOut,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: accentEffectId,
        durationSeconds: 0.16,
        startScale: 0.0,
        endScale: 2.0,
        startOpacity: 0.5,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.14,
        startScale: 0.8,
        endScale: 1.6,
        startOpacity: 0.5,
        endOpacity: 0.0,
      ),
    ];
    const extraOffsets = <({double x, double y})>[
      (x: 35, y: -25),
      (x: -35, y: -25),
      (x: -20, y: 0),
      (x: 20, y: 0),
    ];
    for (var i = 0; i < extraEffectIds.length; i++) {
      final offset = extraOffsets[i % extraOffsets.length];
      steps.add(
        _targetFx(
          ctx,
          effectId: extraEffectIds[i],
          durationSeconds: 0.16,
          toOffsetX: offset.x,
          toOffsetY: offset.y,
          startScale: extraEffectIds[i] == 'wisp' ? 0.8 : 0.0,
          endScale: extraEffectIds[i] == 'wisp' ? 0.8 : 1.8,
          startOpacity: 0.8,
          endOpacity: 0.0,
          afterEffect: extraEffectIds[i] == 'wisp'
              ? BattleFxAfterEffect.fade
              : BattleFxAfterEffect.explode,
        ),
      );
    }
    steps.add(
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    );
    steps.add(
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 10,
        durationSeconds: 0.16,
      ),
    );
    return steps;
  }

  List<BattleAnimationStep> _showdownDoubleKick(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.14,
        distancePx: 24,
      ),
      _targetFx(
        ctx,
        effectId: 'foot',
        durationSeconds: 0.12,
        toOffsetX: -10,
        startScale: 0.9,
        endScale: 1.6,
        startOpacity: 0.9,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'foot',
        durationSeconds: 0.12,
        toOffsetX: 12,
        toOffsetY: -8,
        startScale: 0.9,
        endScale: 1.6,
        startOpacity: 0.9,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDualWingBeat(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'feather',
        durationSeconds: 0.14,
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        fromOffsetX: -24,
        fromOffsetY: -16,
        toOffsetX: 6,
        toOffsetY: 12,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.5,
        endScale: 1.4,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'leftslash',
        durationSeconds: 0.12,
        startScale: 0.9,
        endScale: 1.6,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'feather',
        durationSeconds: 0.14,
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        fromOffsetX: 24,
        fromOffsetY: -16,
        toOffsetX: -6,
        toOffsetY: 12,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.5,
        endScale: 1.4,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'rightslash',
        durationSeconds: 0.12,
        startScale: 0.9,
        endScale: 1.6,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownBoneMerang(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'bone',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        fromOffsetY: -6,
        toOffsetX: -10,
        toOffsetY: -8,
        startScale: 0.6,
        endScale: 0.9,
        startOpacity: 0.9,
        endOpacity: 0.9,
      ),
      WaitStep(durationSeconds: 0.06),
      _projectileToTarget(
        ctx,
        effectId: 'bone',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        fromOffsetY: 10,
        toOffsetX: 14,
        toOffsetY: 10,
        startScale: 0.6,
        endScale: 0.9,
        startOpacity: 0.9,
        endOpacity: 0.9,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSpark(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.20,
        startScale: 0.0,
        endScale: 2.8,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.18,
        distancePx: 28,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 7,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownWildCharge(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 3.6,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 3.6,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'lightning',
        durationSeconds: 0.24,
        toOffsetY: -16,
        startScale: 0.0,
        endScale: 2.6,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.30,
        distancePx: 44,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 9,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownFlareBlitz(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x66400000,
        durationSeconds: 0.16,
      ),
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.20,
        startScale: 0.0,
        endScale: 4.8,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.20,
        startScale: 0.0,
        endScale: 4.8,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.30,
        distancePx: 44,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 9,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownAccelerock(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.26,
        distancePx: 40,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'rock3',
        durationSeconds: 0.18,
        toOffsetX: 30,
        toOffsetY: 25,
        startScale: 0.3,
        endScale: 0.9,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'rock3',
        durationSeconds: 0.18,
        toOffsetX: -30,
        toOffsetY: -20,
        startScale: 0.3,
        endScale: 0.9,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'rock3',
        durationSeconds: 0.18,
        toOffsetX: 15,
        toOffsetY: 10,
        startScale: 0.3,
        endScale: 0.9,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.14,
        startScale: 1.0,
        endScale: 1.25,
        startOpacity: 0.3,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownWickedBlow(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x66000000,
        durationSeconds: 0.20,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.28,
        distancePx: 40,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.16,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 9,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDoubleHit(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.14,
        distancePx: 22,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.12,
        toOffsetX: -10,
        startScale: 0.8,
        endScale: 1.3,
        startOpacity: 0.5,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.12,
        toOffsetX: 12,
        toOffsetY: -6,
        startScale: 0.8,
        endScale: 1.3,
        startOpacity: 0.5,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownCrunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x4419152B,
        durationSeconds: 0.16,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.18,
        distancePx: 26,
      ),
      _targetFx(
        ctx,
        effectId: 'blackwisp',
        durationSeconds: 0.16,
        startScale: 0.7,
        endScale: 1.5,
        startOpacity: 0.85,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'topbite',
        durationSeconds: 0.14,
        toOffsetY: -14,
        startScale: 1.0,
        endScale: 1.45,
        startOpacity: 0.9,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'bottombite',
        durationSeconds: 0.14,
        toOffsetY: 14,
        startScale: 1.0,
        endScale: 1.45,
        startOpacity: 0.9,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 9,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownFlamethrower(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44FF7A3A,
        durationSeconds: 0.14,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.16,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
        startScale: 0.8,
        endScale: 1.0,
        fromOffsetY: -8,
        toOffsetY: -12,
      ),
      WaitStep(durationSeconds: 0.04),
      _projectileToTarget(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.16,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
        startScale: 0.9,
        endScale: 1.1,
        fromOffsetY: 8,
        toOffsetY: 10,
      ),
      WaitStep(durationSeconds: 0.04),
      _projectileToTarget(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.explode,
        startScale: 0.9,
        endScale: 1.25,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 7,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownIceBeam(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x448CE5FF,
        durationSeconds: 0.14,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
        startScale: 0.7,
        endScale: 1.0,
        fromOffsetY: -10,
        toOffsetY: -8,
      ),
      WaitStep(durationSeconds: 0.04),
      _projectileToTarget(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
        startScale: 0.8,
        endScale: 1.1,
        fromOffsetY: 8,
        toOffsetY: 6,
      ),
      _targetFx(
        ctx,
        effectId: 'icicle',
        durationSeconds: 0.16,
        startScale: 0.9,
        endScale: 1.5,
        startOpacity: 0.9,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownPsychic(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x559B5DFF,
        durationSeconds: 0.18,
      ),
      _targetFx(
        ctx,
        effectId: 'stare',
        durationSeconds: 0.20,
        startScale: 0.8,
        endScale: 1.3,
        startOpacity: 0.85,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'pointer',
        durationSeconds: 0.18,
        toOffsetX: -18,
        toOffsetY: -16,
        startScale: 0.7,
        endScale: 1.1,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'pointer',
        durationSeconds: 0.18,
        toOffsetX: 20,
        toOffsetY: 14,
        startScale: 0.7,
        endScale: 1.1,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 6,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownMoonBlast(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _attackerChargeFx(
        ctx,
        effectId: 'moon',
        durationSeconds: 0.20,
        afterEffect: BattleFxAfterEffect.fade,
        startScale: 0.7,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
        toOffsetY: -28,
      ),
      const ScreenFlashStep(
        colorArgb: 0x44FFD6FF,
        durationSeconds: 0.16,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'mistball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.arcOver,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'rainbow',
        durationSeconds: 0.18,
        startScale: 0.8,
        endScale: 1.5,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownPoisonJab(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.20,
        distancePx: 30,
      ),
      _targetFx(
        ctx,
        effectId: 'fist1',
        durationSeconds: 0.14,
        startScale: 0.9,
        endScale: 1.8,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.18,
        startScale: 0.7,
        endScale: 1.4,
        startOpacity: 0.85,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownEarthquake(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x446B4A2E,
        durationSeconds: 0.14,
      ),
      _targetFx(
        ctx,
        effectId: 'mudwisp',
        durationSeconds: 0.18,
        toOffsetX: -24,
        toOffsetY: 20,
        startScale: 0.7,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 10,
        durationSeconds: 0.12,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'mudwisp',
        durationSeconds: 0.18,
        toOffsetX: 22,
        toOffsetY: 22,
        startScale: 0.7,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 10,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownEnergyBall(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _attackerChargeFx(
        ctx,
        effectId: 'shine',
        durationSeconds: 0.18,
        afterEffect: BattleFxAfterEffect.fade,
        startScale: 0.7,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.18,
        afterEffect: BattleFxAfterEffect.fade,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcOver,
        afterEffect: BattleFxAfterEffect.explode,
        startScale: 0.8,
        endScale: 1.1,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownRockSlide(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'rock1',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: -24,
        toOffsetY: -4,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'rock2',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 18,
        toOffsetY: 0,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'rock3',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 0,
        toOffsetY: 12,
        startScale: 0.6,
        endScale: 1.1,
        startOpacity: 0.8,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownNightSlash(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44110D24,
        durationSeconds: 0.16,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.20,
        distancePx: 28,
      ),
      _targetFx(
        ctx,
        effectId: 'blackwisp',
        durationSeconds: 0.16,
        startScale: 0.8,
        endScale: 1.35,
        startOpacity: 0.85,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'leftslash',
        durationSeconds: 0.14,
        toOffsetX: -12,
        toOffsetY: -10,
        startScale: 0.9,
        endScale: 1.5,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'rightslash',
        durationSeconds: 0.14,
        toOffsetX: 12,
        toOffsetY: 10,
        startScale: 0.9,
        endScale: 1.5,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownGigaImpact(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44FFF2B0,
        durationSeconds: 0.18,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.30,
        distancePx: 44,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.16,
        startScale: 1.1,
        endScale: 1.8,
        startOpacity: 0.6,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.12,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 12,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownPowerWhip(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'leaf1',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcUnder,
        afterEffect: BattleFxAfterEffect.fade,
        fromOffsetX: -8,
        toOffsetX: -20,
        toOffsetY: -10,
        startScale: 0.8,
        endScale: 1.1,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'leaf2',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcUnder,
        afterEffect: BattleFxAfterEffect.fade,
        fromOffsetX: 10,
        toOffsetX: 18,
        toOffsetY: 10,
        startScale: 0.8,
        endScale: 1.1,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.16,
        distancePx: 24,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.14,
        startScale: 1.0,
        endScale: 1.4,
        startOpacity: 0.4,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownCrabHammer(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _attackerChargeFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.16,
        afterEffect: BattleFxAfterEffect.fade,
        startScale: 0.7,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.20,
        distancePx: 30,
      ),
      _targetFx(
        ctx,
        effectId: 'leftclaw',
        durationSeconds: 0.14,
        toOffsetX: -10,
        startScale: 0.9,
        endScale: 1.5,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'rightclaw',
        durationSeconds: 0.14,
        toOffsetX: 10,
        startScale: 0.9,
        endScale: 1.5,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.16,
        startScale: 0.7,
        endScale: 1.3,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDischarge(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44FFF36A,
        durationSeconds: 0.16,
      ),
      _targetFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.16,
        toOffsetX: -20,
        toOffsetY: -12,
        startScale: 0.8,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.16,
        toOffsetX: 22,
        toOffsetY: 14,
        startScale: 0.8,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'lightning',
        durationSeconds: 0.16,
        startScale: 0.8,
        endScale: 1.3,
        startOpacity: 0.8,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSmartStrike(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.18,
        distancePx: 28,
      ),
      _targetFx(
        ctx,
        effectId: 'sword',
        durationSeconds: 0.14,
        startScale: 0.9,
        endScale: 1.6,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.12,
        startScale: 0.9,
        endScale: 1.25,
        startOpacity: 0.4,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownMegaHorn(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.22,
        distancePx: 34,
      ),
      _targetFx(
        ctx,
        effectId: 'leftclaw',
        durationSeconds: 0.14,
        toOffsetX: -12,
        startScale: 0.9,
        endScale: 1.5,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'rightclaw',
        durationSeconds: 0.14,
        toOffsetX: 12,
        startScale: 0.9,
        endScale: 1.5,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.12,
        startScale: 1.0,
        endScale: 1.35,
        startOpacity: 0.4,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDragonClaw(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x444E47FF,
        durationSeconds: 0.14,
      ),
      _targetFx(
        ctx,
        effectId: 'leftclaw',
        durationSeconds: 0.14,
        toOffsetX: -10,
        toOffsetY: -10,
        startScale: 0.9,
        endScale: 1.5,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'rightclaw',
        durationSeconds: 0.14,
        toOffsetX: 10,
        toOffsetY: 10,
        startScale: 0.9,
        endScale: 1.5,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownPsychoCut(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x446B5DFF,
        durationSeconds: 0.14,
      ),
      _targetFx(
        ctx,
        effectId: 'pointer',
        durationSeconds: 0.16,
        toOffsetX: -14,
        toOffsetY: -8,
        startScale: 0.8,
        endScale: 1.15,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'rightslash',
        durationSeconds: 0.14,
        toOffsetX: 12,
        toOffsetY: 8,
        startScale: 0.9,
        endScale: 1.45,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownWaterPulse(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x4449C5FF,
        durationSeconds: 0.14,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.arcOver,
        afterEffect: BattleFxAfterEffect.fade,
        startScale: 0.8,
        endScale: 1.1,
      ),
      _targetFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.16,
        toOffsetX: -16,
        toOffsetY: -10,
        startScale: 0.8,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.16,
        toOffsetX: 16,
        toOffsetY: 10,
        startScale: 0.8,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownPowerGem(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x446FC4FF,
        durationSeconds: 0.14,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'rock1',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcOver,
        afterEffect: BattleFxAfterEffect.fade,
        fromOffsetX: -10,
        toOffsetX: -16,
        startScale: 0.7,
        endScale: 1.0,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'rock2',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcOver,
        afterEffect: BattleFxAfterEffect.fade,
        fromOffsetX: 10,
        toOffsetX: 16,
        startScale: 0.7,
        endScale: 1.0,
      ),
      _targetFx(
        ctx,
        effectId: 'rock3',
        durationSeconds: 0.16,
        startScale: 0.8,
        endScale: 1.3,
        startOpacity: 0.8,
        endOpacity: 0.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownHeatWave(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44FF8A42,
        durationSeconds: 0.16,
      ),
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.18,
        toOffsetX: -24,
        toOffsetY: -8,
        startScale: 0.8,
        endScale: 1.3,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.18,
        toOffsetX: 22,
        toOffsetY: 8,
        startScale: 0.8,
        endScale: 1.3,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.18,
        startScale: 0.8,
        endScale: 1.4,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownMuddyWater(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x445A83A6,
        durationSeconds: 0.14,
      ),
      _targetFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.18,
        toOffsetX: -20,
        toOffsetY: -8,
        startScale: 0.8,
        endScale: 1.25,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'mudwisp',
        durationSeconds: 0.18,
        toOffsetX: 18,
        toOffsetY: 10,
        startScale: 0.8,
        endScale: 1.25,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.16,
        startScale: 0.8,
        endScale: 1.15,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownEarthPower(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44553A1C,
        durationSeconds: 0.14,
      ),
      _targetFx(
        ctx,
        effectId: 'mudwisp',
        durationSeconds: 0.18,
        toOffsetX: -16,
        toOffsetY: 18,
        startScale: 0.8,
        endScale: 1.25,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'mudwisp',
        durationSeconds: 0.18,
        toOffsetX: 16,
        toOffsetY: 18,
        startScale: 0.8,
        endScale: 1.25,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 9,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownBugBuzz(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x446BCB7D,
        durationSeconds: 0.14,
      ),
      _targetFx(
        ctx,
        effectId: 'web',
        durationSeconds: 0.18,
        startScale: 0.7,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        toOffsetX: -12,
        toOffsetY: -8,
        startScale: 0.8,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        toOffsetX: 12,
        toOffsetY: 8,
        startScale: 0.8,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 6,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownHyperVoice(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _attackerChargeFx(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.16,
        startScale: 0.0,
        endScale: 7.0,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.05),
      _attackerChargeFx(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 7.0,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.05),
      _attackerChargeFx(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.20,
        startScale: 0.0,
        endScale: 7.0,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 6,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownFlashCannon(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.2,
        endOpacity: 0.6,
      ),
      WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        toOffsetX: 10,
        toOffsetY: -5,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.2,
        endOpacity: 0.6,
      ),
      WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.linear,
        toOffsetX: -10,
        toOffsetY: 5,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.2,
        endOpacity: 0.6,
      ),
      WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.linear,
        toOffsetY: -5,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.2,
        endOpacity: 0.6,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDragonPulse(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _lanePulse(
        ctx,
        effectId: 'wisp',
        fraction: 0.2,
        durationSeconds: 0.22,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _lanePulse(
        ctx,
        effectId: 'poisonwisp',
        fraction: 0.2,
        durationSeconds: 0.22,
        startScale: 0.5,
        endScale: 2.0,
        startOpacity: 0.3,
        endOpacity: 0.0,
      ),
      _lanePulse(
        ctx,
        effectId: 'wisp',
        fraction: 0.45,
        durationSeconds: 0.24,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _lanePulse(
        ctx,
        effectId: 'poisonwisp',
        fraction: 0.45,
        durationSeconds: 0.24,
        startScale: 0.5,
        endScale: 2.0,
        startOpacity: 0.3,
        endOpacity: 0.0,
      ),
      _lanePulse(
        ctx,
        effectId: 'wisp',
        fraction: 0.7,
        durationSeconds: 0.26,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
      _lanePulse(
        ctx,
        effectId: 'poisonwisp',
        fraction: 0.7,
        durationSeconds: 0.26,
        startScale: 0.5,
        endScale: 2.0,
        startOpacity: 0.3,
        endOpacity: 0.0,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.16,
        fromOffsetY: -8,
        startScale: 0.5,
        endScale: 0.6,
        startOpacity: 0.6,
        endOpacity: 0.2,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.linear,
        startScale: 0.3,
        endScale: 1.0,
        startOpacity: 0.1,
        endOpacity: 1.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _projectileToTarget(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        startScale: 0.3,
        endScale: 1.0,
        startOpacity: 0.1,
        endOpacity: 1.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _projectileToTarget(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.linear,
        startScale: 0.3,
        endScale: 1.0,
        startOpacity: 0.1,
        endOpacity: 1.0,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSludgeBomb(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.1,
        endScale: 0.7,
        startOpacity: 0.0,
        endOpacity: 1.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _projectileToTarget(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 40,
        toOffsetY: -20,
        startScale: 0.1,
        endScale: 0.7,
        startOpacity: 0.0,
        endOpacity: 1.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _projectileToTarget(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: -30,
        toOffsetY: -10,
        startScale: 0.1,
        endScale: 0.7,
        startOpacity: 0.0,
        endOpacity: 1.0,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownMagicalLeaf(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const patterns = <({String effectId, double toX, double toY})>[
      (effectId: 'leaf1', toX: 30, toY: 30),
      (effectId: 'leaf2', toX: 20, toY: -30),
      (effectId: 'leaf1', toX: -30, toY: 0),
      (effectId: 'leaf2', toX: -10, toY: 10),
      (effectId: 'leaf1', toX: 10, toY: -10),
      (effectId: 'leaf2', toX: -20, toY: 0),
    ];
    final steps = <BattleAnimationStep>[];
    for (var i = 0; i < patterns.length; i++) {
      if (i > 0) {
        steps.add(const WaitStep(durationSeconds: 0.03));
      }
      final pattern = patterns[i];
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: pattern.effectId,
          durationSeconds: 0.18,
          curve: BattleFxMotionCurve.linear,
          toOffsetX: pattern.toX,
          toOffsetY: pattern.toY,
          startScale: 1.1,
          endScale: 2.0,
          startOpacity: 1.0,
          endOpacity: 0.6,
        ),
      );
    }
    return steps;
  }

  List<BattleAnimationStep> _showdownElectroweb(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'web',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.1,
        endScale: 0.5,
        startOpacity: 0.0,
        endOpacity: 1.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _projectileToTarget(
        ctx,
        effectId: 'web',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 40,
        toOffsetY: -20,
        startScale: 0.1,
        endScale: 0.5,
        startOpacity: 0.0,
        endOpacity: 1.0,
      ),
      WaitStep(durationSeconds: 0.04),
      _projectileToTarget(
        ctx,
        effectId: 'web',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: -30,
        toOffsetY: -10,
        startScale: 0.1,
        endScale: 0.5,
        startOpacity: 0.0,
        endOpacity: 1.0,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownBulletSeed(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.linear,
        startScale: 0.4,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.6,
      ),
      WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.linear,
        startScale: 0.2,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.6,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSlam(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.18,
        distancePx: 32,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.14,
        startScale: 0.9,
        endScale: 1.5,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSpore(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.20,
        fromOffsetX: 10,
        fromOffsetY: 90,
        toOffsetY: -5,
        startScale: 0.4,
        endScale: 0.4,
        startOpacity: 0.0,
        endOpacity: 1.0,
        curve: BattleFxMotionCurve.easeOut,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.20,
        fromOffsetX: 30,
        fromOffsetY: 90,
        toOffsetY: -5,
        startScale: 0.4,
        endScale: 0.4,
        startOpacity: 0.0,
        endOpacity: 1.0,
        curve: BattleFxMotionCurve.easeOut,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.20,
        fromOffsetX: -30,
        fromOffsetY: 90,
        toOffsetY: -5,
        startScale: 0.4,
        endScale: 0.4,
        startOpacity: 0.0,
        endOpacity: 1.0,
        curve: BattleFxMotionCurve.easeOut,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownPainSplit(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.30,
        startScale: 0.0,
        endScale: 3.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        playAsAccent: true,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.30,
        startScale: 0.0,
        endScale: 3.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        playAsAccent: true,
      ),
      const WaitStep(durationSeconds: 0),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.30,
        startDelaySeconds: 0.20,
        startScale: 0.0,
        endScale: 3.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        playAsAccent: true,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.30,
        startDelaySeconds: 0.20,
        startScale: 0.0,
        endScale: 3.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        playAsAccent: true,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSkillSwap(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      SpawnFxStep(
        effectId: 'wisp',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.attackerCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.40,
        curve: BattleFxMotionCurve.arcUnder,
        fromOffsetY: -30,
        startScale: 1.0,
        endScale: 0.5,
        startOpacity: 1.0,
        endOpacity: 0.0,
        playAsAccent: true,
      ),
      SpawnFxStep(
        effectId: 'wisp',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.attackerCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.40,
        startDelaySeconds: 0.20,
        curve: BattleFxMotionCurve.arcUnder,
        fromOffsetY: -30,
        startScale: 1.0,
        endScale: 0.5,
        startOpacity: 1.0,
        endOpacity: 0.0,
        playAsAccent: true,
      ),
      SpawnFxStep(
        effectId: 'wisp',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.40,
        startDelaySeconds: 0.20,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 1.0,
        endScale: 0.5,
        startOpacity: 1.0,
        endOpacity: 0.0,
        playAsAccent: true,
      ),
      SpawnFxStep(
        effectId: 'wisp',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.40,
        startDelaySeconds: 0.40,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 1.0,
        endScale: 0.5,
        startOpacity: 1.0,
        endOpacity: 0.0,
        playAsAccent: true,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownPlayRough(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44F5A6CF,
        durationSeconds: 0.14,
      ),
      _targetFx(
        ctx,
        effectId: 'fist',
        durationSeconds: 0.18,
        toOffsetX: -15,
        toOffsetY: -10,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'mudwisp',
        durationSeconds: 0.16,
        toOffsetX: -10,
        toOffsetY: -10,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'mudwisp',
        durationSeconds: 0.16,
        toOffsetX: 20,
        toOffsetY: 20,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'mudwisp',
        durationSeconds: 0.16,
        toOffsetX: 30,
        toOffsetY: -25,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'foot',
        durationSeconds: 0.20,
        toOffsetY: 10,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'heart',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderHead,
        durationSeconds: 0.16,
        fromOffsetX: -10,
        fromOffsetY: 20,
        toOffsetX: -20,
        toOffsetY: 30,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'heart',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderHead,
        durationSeconds: 0.16,
        fromOffsetX: 15,
        fromOffsetY: 10,
        toOffsetX: 25,
        toOffsetY: 20,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSurf(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x440000DD,
        durationSeconds: 0.18,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.easeOut,
        fromOffsetY: -25,
        toOffsetY: 10,
        toOffsetX: 0,
        startScale: 0.4,
        endScale: 1.0,
        startOpacity: 0.3,
        endOpacity: 0.6,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.easeOut,
        fromOffsetX: -30,
        fromOffsetY: -25,
        toOffsetX: -60,
        startScale: 0.4,
        endScale: 1.0,
        startOpacity: 0.3,
        endOpacity: 0.6,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.easeOut,
        fromOffsetX: 30,
        fromOffsetY: -25,
        toOffsetX: 60,
        startScale: 0.4,
        endScale: 1.0,
        startOpacity: 0.3,
        endOpacity: 0.6,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownHydroPump(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x440000DD,
        durationSeconds: 0.18,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        toOffsetX: 10,
        toOffsetY: 5,
        startScale: 0.4,
        endScale: 1.0,
        startOpacity: 0.3,
        endOpacity: 0.6,
      ),
      WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        toOffsetX: -10,
        toOffsetY: -5,
        startScale: 0.4,
        endScale: 1.0,
        startOpacity: 0.3,
        endOpacity: 0.6,
      ),
      WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        toOffsetY: 5,
        startScale: 0.4,
        endScale: 1.0,
        startOpacity: 0.3,
        endOpacity: 0.6,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 10,
        durationSeconds: 0.18,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownLeafBlade(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.18,
        startScale: 0.5,
        endScale: 2.0,
        startOpacity: 0.5,
        endOpacity: 0.2,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.06),
      _targetFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.18,
        startScale: 0.5,
        endScale: 2.0,
        startOpacity: 0.5,
        endOpacity: 0.2,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'leaf1',
        durationSeconds: 0.18,
        toOffsetX: -35,
        toOffsetY: -10,
        startScale: 0.5,
        endScale: 3.0,
        startOpacity: 0.7,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'leaf2',
        durationSeconds: 0.18,
        toOffsetX: 35,
        toOffsetY: -15,
        startScale: 0.8,
        endScale: 3.5,
        startOpacity: 0.7,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'leftslash',
        durationSeconds: 0.18,
        toOffsetX: -10,
        toOffsetY: -10,
        startScale: 1.5,
        endScale: 2.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.06),
      _targetFx(
        ctx,
        effectId: 'leaf1',
        durationSeconds: 0.18,
        toOffsetX: -35,
        toOffsetY: -15,
        startScale: 0.5,
        endScale: 3.0,
        startOpacity: 0.7,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'leaf2',
        durationSeconds: 0.18,
        toOffsetX: 35,
        toOffsetY: -10,
        startScale: 0.8,
        endScale: 3.5,
        startOpacity: 0.7,
        endOpacity: 0.0,
      ),
      _targetFx(
        ctx,
        effectId: 'rightslash',
        durationSeconds: 0.18,
        toOffsetX: 10,
        toOffsetY: -6,
        startScale: 1.5,
        endScale: 2.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownXScissor(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.32,
        distancePx: 40,
      ),
      _targetFx(
        ctx,
        effectId: 'rightslash',
        durationSeconds: 0.18,
        startScale: 1.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.5,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'rightslash',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 3.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'leftslash',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 3.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 9,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownFireFang(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _showdownElementalFang(
      ctx,
      accentSteps: <BattleAnimationStep>[
        _targetFx(
          ctx,
          effectId: 'fireball',
          durationSeconds: 0.18,
          toOffsetY: -40,
          startScale: 0.0,
          endScale: 3.0,
          startOpacity: 1.0,
          endOpacity: 0.0,
          curve: BattleFxMotionCurve.linear,
        ),
        WaitStep(durationSeconds: 0.05),
        _targetFx(
          ctx,
          effectId: 'fireball',
          durationSeconds: 0.18,
          toOffsetY: -40,
          startScale: 0.0,
          endScale: 3.0,
          startOpacity: 1.0,
          endOpacity: 0.0,
          curve: BattleFxMotionCurve.linear,
        ),
      ],
    );
  }

  List<BattleAnimationStep> _showdownIceFang(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _showdownElementalFang(
      ctx,
      accentSteps: <BattleAnimationStep>[
        _targetFx(
          ctx,
          effectId: 'icicle',
          durationSeconds: 0.18,
          toOffsetY: -40,
          startScale: 0.0,
          endScale: 3.0,
          startOpacity: 1.0,
          endOpacity: 0.0,
          curve: BattleFxMotionCurve.linear,
        ),
        WaitStep(durationSeconds: 0.05),
        _targetFx(
          ctx,
          effectId: 'icicle',
          durationSeconds: 0.18,
          toOffsetY: -40,
          startScale: 0.0,
          endScale: 3.0,
          startOpacity: 1.0,
          endOpacity: 0.0,
          curve: BattleFxMotionCurve.linear,
        ),
      ],
    );
  }

  List<BattleAnimationStep> _showdownThunderFang(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _showdownElementalFang(
      ctx,
      accentSteps: <BattleAnimationStep>[
        _targetFx(
          ctx,
          effectId: 'electroball',
          durationSeconds: 0.18,
          toOffsetY: -40,
          startScale: 0.0,
          endScale: 3.0,
          startOpacity: 1.0,
          endOpacity: 0.0,
          curve: BattleFxMotionCurve.linear,
        ),
        WaitStep(durationSeconds: 0.05),
        _targetFx(
          ctx,
          effectId: 'lightning',
          durationSeconds: 0.18,
          toOffsetY: -40,
          startScale: 0.0,
          endScale: 3.0,
          startOpacity: 1.0,
          endOpacity: 0.0,
          curve: BattleFxMotionCurve.linear,
        ),
      ],
    );
  }

  List<BattleAnimationStep> _showdownElementalFang(
    BattleMoveVisualRecipeContext ctx, {
    required List<BattleAnimationStep> accentSteps,
  }) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      ...accentSteps,
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.18,
        distancePx: 28,
      ),
      _targetFx(
        ctx,
        effectId: 'topbite',
        durationSeconds: 0.16,
        fromOffsetY: 50,
        toOffsetY: 10,
        startScale: 0.5,
        endScale: 0.5,
        startOpacity: 0.0,
        endOpacity: 1.0,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'bottombite',
        durationSeconds: 0.16,
        fromOffsetY: -50,
        toOffsetY: -10,
        startScale: 0.5,
        endScale: 0.5,
        startOpacity: 0.0,
        endOpacity: 1.0,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownAirSlash(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        fromOffsetX: 60,
        fromOffsetY: 30,
        toOffsetX: -70,
        toOffsetY: -40,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.4,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.03),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        fromOffsetX: 60,
        fromOffsetY: 30,
        toOffsetX: -70,
        toOffsetY: -40,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.4,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        fromOffsetX: 80,
        fromOffsetY: 10,
        toOffsetX: -50,
        toOffsetY: -60,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.4,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.03),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        fromOffsetX: 80,
        fromOffsetY: 10,
        toOffsetX: -50,
        toOffsetY: -60,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.4,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDracoMeteor(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x55445B8C,
        durationSeconds: 0.18,
      ),
      SpawnFxStep(
        effectId: 'flareball',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.screenCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.1,
        endScale: 1.5,
        startOpacity: 0.0,
        endOpacity: 0.8,
        fromOffsetX: -200,
        fromOffsetY: 175,
        toOffsetX: 50,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      WaitStep(durationSeconds: 0.04),
      SpawnFxStep(
        effectId: 'flareball',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.screenCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.1,
        endScale: 1.5,
        startOpacity: 0.0,
        endOpacity: 0.8,
        fromOffsetX: -200,
        fromOffsetY: 195,
        toOffsetX: -30,
        toOffsetY: -5,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      WaitStep(durationSeconds: 0.04),
      SpawnFxStep(
        effectId: 'flareball',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.screenCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.1,
        endScale: 1.5,
        startOpacity: 0.0,
        endOpacity: 0.8,
        fromOffsetX: -200,
        fromOffsetY: 155,
        toOffsetX: 30,
        toOffsetY: -10,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      SpawnFxStep(
        effectId: 'rock3',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.screenCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.1,
        endScale: 1.5,
        startOpacity: 0.0,
        endOpacity: 0.4,
        fromOffsetX: -200,
        fromOffsetY: 175,
        toOffsetX: 30,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      WaitStep(durationSeconds: 0.04),
      SpawnFxStep(
        effectId: 'rock3',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.screenCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.1,
        endScale: 1.5,
        startOpacity: 0.0,
        endOpacity: 0.4,
        fromOffsetX: -200,
        fromOffsetY: 195,
        toOffsetX: -20,
        toOffsetY: -5,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      WaitStep(durationSeconds: 0.04),
      SpawnFxStep(
        effectId: 'rock3',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.screenCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.1,
        endScale: 1.5,
        startOpacity: 0.0,
        endOpacity: 0.4,
        fromOffsetX: -200,
        fromOffsetY: 155,
        toOffsetX: 20,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'shadowball',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderHead,
        durationSeconds: 0.18,
        fromOffsetX: 30,
        fromOffsetY: -50,
        startScale: 1.0,
        endScale: 3.0,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 10,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownQuiverDance(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33987058,
        durationSeconds: 0.16,
      ),
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 4,
        durationSeconds: 0.20,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        from: BattleVisualAnchor.attackerHead,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.easeOut,
        fromOffsetX: 40,
        fromOffsetY: -30,
        toOffsetX: 25,
        toOffsetY: 40,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        from: BattleVisualAnchor.attackerHead,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        fromOffsetX: -40,
        fromOffsetY: -30,
        toOffsetX: -25,
        toOffsetY: 45,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        from: BattleVisualAnchor.attackerHead,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.easeOut,
        fromOffsetY: -35,
        toOffsetY: 50,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownVictoryDance(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33D6883C,
        durationSeconds: 0.16,
      ),
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 4,
        durationSeconds: 0.20,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'flareball',
        from: BattleVisualAnchor.attackerHead,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.20,
        fromOffsetX: 40,
        fromOffsetY: -30,
        toOffsetX: 25,
        toOffsetY: 40,
        startScale: 0.2,
        endScale: 0.45,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'flareball',
        from: BattleVisualAnchor.attackerHead,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.22,
        fromOffsetX: -40,
        fromOffsetY: -30,
        toOffsetX: -25,
        toOffsetY: 45,
        startScale: 0.2,
        endScale: 0.45,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'flareball',
        from: BattleVisualAnchor.attackerHead,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.24,
        fromOffsetY: -35,
        toOffsetY: 50,
        startScale: 0.2,
        endScale: 0.45,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDragonDance(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 4,
        durationSeconds: 0.18,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcOver,
        fromOffsetX: 0,
        fromOffsetY: 0,
        toOffsetX: -45,
        toOffsetY: -45,
        startScale: 0.0,
        endScale: 1.6,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.03),
      _attackerChargeFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcOver,
        toOffsetX: 55,
        toOffsetY: -45,
        startScale: 0.0,
        endScale: 1.6,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.03),
      _attackerChargeFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcOver,
        toOffsetX: 0,
        toOffsetY: 55,
        startScale: 0.0,
        endScale: 1.6,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownFeatherDance(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'feather',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        fromOffsetY: 10,
        toOffsetX: 50,
        startScale: 0.3,
        endScale: 0.5,
        startOpacity: 1.0,
        endOpacity: 0.4,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'feather',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        fromOffsetY: 10,
        toOffsetX: -50,
        startScale: 0.3,
        endScale: 0.5,
        startOpacity: 1.0,
        endOpacity: 0.4,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'feather',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        fromOffsetY: 10,
        toOffsetX: 25,
        startScale: 0.3,
        endScale: 0.5,
        startOpacity: 1.0,
        endOpacity: 0.4,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'feather',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        fromOffsetY: 10,
        toOffsetX: -25,
        startScale: 0.3,
        endScale: 0.5,
        startOpacity: 1.0,
        endOpacity: 0.4,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'feather',
        durationSeconds: 0.18,
        toOffsetX: 5,
        toOffsetY: -20,
        startScale: 0.5,
        endScale: 0.1,
        startOpacity: 1.0,
        endOpacity: 0.4,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'feather',
        durationSeconds: 0.18,
        toOffsetX: -10,
        toOffsetY: -20,
        startScale: 0.5,
        endScale: 0.1,
        startOpacity: 1.0,
        endOpacity: 0.4,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 6,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownFocusBlast(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x55B84038,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.16,
        startScale: 3.0,
        endScale: 0.6,
        startOpacity: 0.3,
        endOpacity: 1.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        startScale: 3.0,
        endScale: 0.8,
        startOpacity: 0.3,
        endOpacity: 0.6,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.14,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.8,
      ),
      WaitStep(durationSeconds: 0.08),
      _projectileToTarget(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 1.0,
        endScale: 0.8,
        startOpacity: 0.8,
        endOpacity: 0.9,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 4.0,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        toOffsetX: 20,
        toOffsetY: -10,
        startScale: 0.0,
        endScale: 3.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 9,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSpinAttack(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.14,
        distancePx: 90,
      ),
      _targetFx(
        ctx,
        effectId: 'impact',
        durationSeconds: 0.16,
        startScale: 0.6,
        endScale: 1.5,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.14,
        fromOffsetX: -15,
        toOffsetX: 20,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 7,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownVoltSwitch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        startOpacity: 0.8,
        endOpacity: 0.9,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 4.0,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        toOffsetX: 15,
        toOffsetY: -8,
        startScale: 0.0,
        endScale: 4.0,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 7,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownShockWave(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _lanePulse(
        ctx,
        effectId: 'electroball',
        fraction: 0.2,
        durationSeconds: 0.18,
        startScale: 1.0,
        endScale: 3.0,
        startOpacity: 0.6,
        endOpacity: 0.1,
      ),
      WaitStep(durationSeconds: 0.03),
      _lanePulse(
        ctx,
        effectId: 'electroball',
        fraction: 0.8,
        durationSeconds: 0.18,
        startScale: 1.0,
        endScale: 3.0,
        startOpacity: 0.6,
        endOpacity: 0.1,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.linear,
        startScale: 0.6,
        endScale: 0.8,
        startOpacity: 0.7,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.explode,
      ),
      _targetFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 3.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownExplosion(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x66FF7B00,
        durationSeconds: 0.14,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.20,
        fromOffsetX: 40,
        startScale: 0.0,
        endScale: 6.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.20,
        fromOffsetX: -40,
        fromOffsetY: -20,
        startScale: 0.0,
        endScale: 6.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.20,
        fromOffsetX: 10,
        fromOffsetY: 20,
        startScale: 0.0,
        endScale: 6.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 10,
        durationSeconds: 0.14,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 10,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownPopulationBomb(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.12,
        distancePx: 90,
      ),
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.16,
        toOffsetX: 40,
        startScale: 0.0,
        endScale: 4.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'leftslash',
        durationSeconds: 0.16,
        toOffsetX: 40,
        startScale: 0.0,
        endScale: 4.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.16,
        toOffsetX: -40,
        toOffsetY: -20,
        startScale: 0.0,
        endScale: 4.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'rightslash',
        durationSeconds: 0.16,
        toOffsetX: -30,
        toOffsetY: 10,
        startScale: 0.0,
        endScale: 4.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownAirCutter(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        fromOffsetX: 60,
        fromOffsetY: -10,
        toOffsetX: -60,
        toOffsetY: -10,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.4,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.03),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        fromOffsetX: 60,
        fromOffsetY: 20,
        toOffsetX: -60,
        toOffsetY: 20,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.4,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.03),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        fromOffsetX: 60,
        fromOffsetY: 50,
        toOffsetX: -60,
        toOffsetY: 50,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.4,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownHurricane(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44000000,
        durationSeconds: 0.18,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        fromOffsetX: 50,
        fromOffsetY: -35,
        toOffsetX: -50,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.4,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        fromOffsetX: -50,
        fromOffsetY: 35,
        toOffsetX: 50,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.4,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        fromOffsetX: 50,
        fromOffsetY: -35,
        toOffsetX: -50,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.4,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        fromOffsetX: -50,
        fromOffsetY: 35,
        toOffsetX: 50,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.4,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        fromOffsetX: 50,
        fromOffsetY: -35,
        toOffsetX: -50,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.4,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        fromOffsetX: -50,
        fromOffsetY: 35,
        toOffsetX: 50,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.4,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 9,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownWhirlwind(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const patterns = <({double x, double y})>[
      (x: 30, y: -35),
      (x: -30, y: 35),
      (x: 30, y: 0),
      (x: -30, y: -35),
    ];
    final steps = <BattleAnimationStep>[];
    for (var cycle = 0; cycle < 3; cycle++) {
      if (cycle > 0) {
        steps.add(const WaitStep(durationSeconds: 0.05));
      }
      for (final pattern in patterns) {
        steps.add(
          _targetFx(
            ctx,
            effectId: 'wisp',
            durationSeconds: 0.16,
            toOffsetX: pattern.x,
            toOffsetY: pattern.y,
            startScale: 0.2,
            endScale: 0.4,
            startOpacity: 1.0,
            endOpacity: 0.4,
            curve: BattleFxMotionCurve.linear,
            afterEffect: BattleFxAfterEffect.fade,
          ),
        );
      }
    }
    return steps;
  }

  List<BattleAnimationStep> _showdownFreezeDry(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const patterns = <({double x, double y})>[
      (x: 0, y: 0),
      (x: 10, y: -5),
      (x: -10, y: 5),
      (x: 0, y: -5),
    ];
    final steps = <BattleAnimationStep>[];
    for (var i = 0; i < patterns.length; i++) {
      if (i > 0) {
        steps.add(const WaitStep(durationSeconds: 0.03));
      }
      final pattern = patterns[i];
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: 'icicle',
          durationSeconds: 0.20,
          curve: BattleFxMotionCurve.linear,
          toOffsetX: pattern.x,
          toOffsetY: pattern.y,
          startScale: 1.0,
          endScale: 1.0,
          startOpacity: 0.2,
          endOpacity: 0.6,
        ),
      );
    }
    steps.add(
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        startScale: 2.4,
        endScale: 1.2,
        startOpacity: 0.3,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    );
    return steps;
  }

  List<BattleAnimationStep> _showdownMagmaStorm(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    const patterns = <({double x, double y})>[
      (x: 50, y: -35),
      (x: -50, y: 35),
      (x: 40, y: 10),
      (x: -40, y: -10),
    ];
    final steps = <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33CC3300,
        durationSeconds: 0.18,
      ),
    ];
    for (var i = 0; i < patterns.length; i++) {
      if (i > 0) {
        steps.add(const WaitStep(durationSeconds: 0.03));
      }
      final pattern = patterns[i];
      steps.add(
        _targetFx(
          ctx,
          effectId: 'fireball',
          durationSeconds: 0.20,
          toOffsetX: pattern.x,
          toOffsetY: pattern.y,
          startScale: 0.5,
          endScale: 1.0,
          startOpacity: 1.0,
          endOpacity: 0.4,
          afterEffect: BattleFxAfterEffect.fade,
        ),
      );
    }
    steps.add(
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 9,
        durationSeconds: 0.24,
      ),
    );
    return steps;
  }

  List<BattleAnimationStep> _showdownOriginPulse(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const patterns = <({double x, double y})>[
      (x: 10, y: 5),
      (x: -10, y: -5),
      (x: 0, y: 5),
    ];
    final steps = <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x3300CCCC,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.20,
        startScale: 1.0,
        endScale: 6.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
    for (final pattern in patterns) {
      steps.add(const WaitStep(durationSeconds: 0.03));
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: 'waterwisp',
          durationSeconds: 0.20,
          curve: BattleFxMotionCurve.easeOut,
          toOffsetX: pattern.x,
          toOffsetY: pattern.y,
          startScale: 0.4,
          endScale: 1.0,
          startOpacity: 0.3,
          endOpacity: 0.6,
        ),
      );
    }
    return steps;
  }

  List<BattleAnimationStep> _showdownPsybeam(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const patterns = <({String effectId, double x, double y})>[
      (effectId: 'mistball', x: 0, y: 0),
      (effectId: 'poisonwisp', x: 10, y: -5),
      (effectId: 'mistball', x: -10, y: 5),
      (effectId: 'poisonwisp', x: 0, y: -5),
    ];
    final steps = <BattleAnimationStep>[];
    for (var i = 0; i < patterns.length; i++) {
      if (i > 0) {
        steps.add(const WaitStep(durationSeconds: 0.03));
      }
      final pattern = patterns[i];
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: pattern.effectId,
          durationSeconds: 0.18,
          curve: BattleFxMotionCurve.linear,
          toOffsetX: pattern.x,
          toOffsetY: pattern.y,
          startScale: 0.5,
          endScale: 0.6,
          startOpacity: 0.2,
          endOpacity: 0.6,
        ),
      );
    }
    return steps;
  }

  List<BattleAnimationStep> _showdownAeroblast(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const trailOffsets = <double>[-24, -12, 0, 12, 24];
    const impacts = <({double x, double y})>[
      (x: 30, y: 30),
      (x: 20, y: -30),
      (x: -30, y: 0),
      (x: -10, y: 18),
    ];
    final steps = <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44000000,
        durationSeconds: 0.18,
      ),
    ];
    for (final offset in trailOffsets) {
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: 'wisp',
          durationSeconds: 0.18,
          curve: BattleFxMotionCurve.linear,
          toOffsetY: offset,
          startScale: 1.0,
          endScale: 3.0,
          startOpacity: 1.0,
          endOpacity: 0.0,
          afterEffect: BattleFxAfterEffect.fade,
        ),
      );
    }
    for (final impact in impacts) {
      steps.add(const WaitStep(durationSeconds: 0.03));
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: 'iceball',
          durationSeconds: 0.20,
          curve: BattleFxMotionCurve.linear,
          toOffsetX: impact.x,
          toOffsetY: impact.y,
          startScale: 0.4,
          endScale: 0.6,
          startOpacity: 0.6,
          endOpacity: 0.2,
        ),
      );
    }
    return steps;
  }

  List<BattleAnimationStep> _showdownRoarOfTime(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x44000000,
        durationSeconds: 0.22,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.20,
        startScale: 0.0,
        endScale: 7.0,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.22,
        fromOffsetY: -4,
        toOffsetY: -4,
        startScale: 0.0,
        endScale: 7.0,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.24,
        fromOffsetY: 4,
        toOffsetY: 4,
        startScale: 0.0,
        endScale: 7.0,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.20,
        toOffsetX: 40,
        startScale: 0.0,
        endScale: 5.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.22,
        toOffsetX: -40,
        toOffsetY: -20,
        startScale: 0.0,
        endScale: 5.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.24,
        toOffsetX: 10,
        toOffsetY: 20,
        startScale: 0.0,
        endScale: 5.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownRevelationDance(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33000000,
        durationSeconds: 0.18,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.16,
        fromOffsetX: 20,
        fromOffsetY: -60,
        toOffsetX: 20,
        toOffsetY: -60,
        startScale: 1.0,
        endScale: 1.5,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.03),
      _attackerChargeFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.16,
        fromOffsetX: -20,
        fromOffsetY: -60,
        toOffsetX: -20,
        toOffsetY: -60,
        startScale: 1.0,
        endScale: 1.5,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.03),
      _attackerChargeFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.16,
        fromOffsetY: -60,
        toOffsetY: -60,
        startScale: 1.0,
        endScale: 1.5,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _projectileToTarget(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        startScale: 0.7,
        endScale: 0.7,
        startOpacity: 0.8,
        endOpacity: 1.0,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        toOffsetX: 30,
        toOffsetY: 25,
        startScale: 0.2,
        endScale: 0.6,
        startOpacity: 0.6,
        endOpacity: 0.3,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        toOffsetX: -30,
        toOffsetY: -20,
        startScale: 0.2,
        endScale: 0.6,
        startOpacity: 0.6,
        endOpacity: 0.3,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSunnyDay(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _showdownDanceCast(
      ctx,
      accentFx: 'fireball',
      colorArgb: 0x33F7A11A,
    );
  }

  List<BattleAnimationStep> _showdownHail(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _showdownDanceCast(
      ctx,
      accentFx: 'iceball',
      colorArgb: 0x33C7E7FF,
    );
  }

  List<BattleAnimationStep> _showdownElectricTerrain(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _showdownDanceCast(
      ctx,
      accentFx: 'electroball',
      colorArgb: 0x33FFFF00,
    );
  }

  List<BattleAnimationStep> _showdownGrassyTerrain(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x339AB440,
        durationSeconds: 0.16,
      ),
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 6,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'leaf1',
        fromOffsetX: -20,
        fromOffsetY: -10,
        toOffsetX: 20,
        toOffsetY: 20,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.7,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.06),
      _attackerChargeFx(
        ctx,
        effectId: 'leaf1',
        fromOffsetX: 20,
        fromOffsetY: -15,
        toOffsetX: -20,
        toOffsetY: 30,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.7,
        endOpacity: 0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownMistyTerrain(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _showdownDanceCast(
      ctx,
      accentFx: 'mistball',
      colorArgb: 0x33FF99FF,
    );
  }

  List<BattleAnimationStep> _showdownFollowMe(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 5,
        durationSeconds: 0.14,
      ),
      SpawnFxStep(
        effectId: 'pointer',
        attackerSide: ctx.attackerSide,
        defenderSide: ctx.attackerSide,
        from: BattleVisualAnchor.attackerCenter,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.4,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.0,
        fromOffsetY: 30,
        toOffsetY: 60,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownKinesis(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x55AA44BB,
        durationSeconds: 0.10,
      ),
      const ScreenFlashStep(
        colorArgb: 0x44AA44FF,
        durationSeconds: 0.12,
      ),
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 5,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'mistball',
        durationSeconds: 0.18,
        startScale: 0.5,
        endScale: 1.3,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSolarBeam(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33F7D94C,
        durationSeconds: 0.18,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.18,
        startScale: 0.8,
        endScale: 1.8,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.22,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.3,
      ),
      WaitStep(durationSeconds: 0.06),
      _projectileToTarget(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        fromOffsetX: -30,
        fromOffsetY: 80,
        toOffsetX: -30,
        startScale: 0.7,
        endScale: 0.6,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        fromOffsetX: -15,
        fromOffsetY: 40,
        toOffsetX: -15,
        startScale: 0.7,
        endScale: 0.6,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        startScale: 0.7,
        endScale: 0.6,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        fromOffsetX: 15,
        fromOffsetY: -40,
        toOffsetX: 15,
        startScale: 0.7,
        endScale: 0.6,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        fromOffsetX: 30,
        fromOffsetY: -80,
        toOffsetX: 30,
        startScale: 0.7,
        endScale: 0.6,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.18,
        startScale: 0.8,
        endScale: 2.8,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownThunder(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x66FFFFFF,
        durationSeconds: 0.08,
      ),
      const ScreenFlashStep(
        colorArgb: 0x55000000,
        durationSeconds: 0.16,
      ),
      _targetFx(
        ctx,
        effectId: 'lightning',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.18,
        fromOffsetY: 120,
        toOffsetY: 20,
        startScale: 1.0,
        endScale: 1.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'lightning',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.20,
        fromOffsetX: 10,
        fromOffsetY: 100,
        toOffsetX: -10,
        toOffsetY: 10,
        startScale: 1.0,
        endScale: 1.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 10,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownStoredPower(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const offsets = <(double, double)>[
      (36, -12),
      (-36, -12),
      (28, 24),
      (-28, 24),
      (0, -42),
      (42, 8),
      (0, 42),
      (-42, 8),
    ];
    return <BattleAnimationStep>[
      for (final offset in offsets)
        _attackerChargeFx(
          ctx,
          effectId: 'poisonwisp',
          durationSeconds: 0.22,
          curve: BattleFxMotionCurve.easeOut,
          toOffsetX: offset.$1,
          toOffsetY: offset.$2,
          startScale: 0.5,
          endScale: 1.0,
          startOpacity: 1.0,
          endOpacity: 0.5,
          afterEffect: BattleFxAfterEffect.fade,
        ),
    ];
  }

  List<BattleAnimationStep> _showdownPsychoBoost(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33000000,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'mistball',
        durationSeconds: 0.18,
        startScale: 0.6,
        endScale: 3.0,
        startOpacity: 0.5,
        endOpacity: 0.3,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.03),
      _attackerChargeFx(
        ctx,
        effectId: 'mistball',
        durationSeconds: 0.18,
        startScale: 0.8,
        endScale: 3.0,
        startOpacity: 0.6,
        endOpacity: 0.5,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'mistball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 2.0,
        endScale: 1.1,
        startOpacity: 0.8,
        endOpacity: 0.8,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.18,
        startScale: 0.8,
        endScale: 4.0,
        startOpacity: 0.6,
        endOpacity: 0.4,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 2.3,
        endScale: 1.3,
        startOpacity: 0.8,
        endOpacity: 0.8,
      ),
      _targetFx(
        ctx,
        effectId: 'mistball',
        durationSeconds: 0.16,
        toOffsetX: 30,
        toOffsetY: 25,
        startScale: 0.2,
        endScale: 0.8,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'mistball',
        durationSeconds: 0.16,
        toOffsetX: -30,
        toOffsetY: -10,
        startScale: 0.2,
        endScale: 0.8,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'mistball',
        durationSeconds: 0.16,
        toOffsetX: 10,
        toOffsetY: 20,
        startScale: 0.2,
        endScale: 0.8,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.16,
        toOffsetX: -15,
        toOffsetY: 10,
        startScale: 0.2,
        endScale: 0.8,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownPsyshock(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.16,
        toOffsetX: 40,
        startScale: 0.0,
        endScale: 3.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.16,
        toOffsetX: -40,
        toOffsetY: -20,
        startScale: 0.0,
        endScale: 3.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.16,
        toOffsetX: 10,
        toOffsetY: 20,
        startScale: 0.0,
        endScale: 3.0,
        startOpacity: 0.6,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownHex(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33000000,
        durationSeconds: 0.16,
      ),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.16,
        toOffsetX: 40,
        startScale: 0.0,
        endScale: 3.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.16,
        toOffsetX: -40,
        toOffsetY: -20,
        startScale: 0.0,
        endScale: 3.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.16,
        toOffsetX: 10,
        toOffsetY: 20,
        startScale: 0.0,
        endScale: 3.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'bluefireball',
        durationSeconds: 0.18,
        toOffsetX: 40,
        toOffsetY: 30,
        startScale: 0.8,
        endScale: 0.8,
        startOpacity: 0.5,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.easeOut,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.03),
      _targetFx(
        ctx,
        effectId: 'bluefireball',
        durationSeconds: 0.18,
        toOffsetX: -40,
        toOffsetY: 30,
        startScale: 0.8,
        endScale: 0.8,
        startOpacity: 0.5,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.easeOut,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.03),
      _targetFx(
        ctx,
        effectId: 'bluefireball',
        durationSeconds: 0.18,
        toOffsetY: 40,
        startScale: 0.8,
        endScale: 0.8,
        startOpacity: 0.5,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.easeOut,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 7,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownWillOWisp(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'bluefireball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        toOffsetX: 40,
        toOffsetY: 15,
        startScale: 0.4,
        endScale: 0.8,
        startOpacity: 0.0,
        endOpacity: 0.7,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'bluefireball',
        durationSeconds: 0.18,
        fromOffsetX: 40,
        fromOffsetY: 15,
        toOffsetX: -40,
        startScale: 0.8,
        endScale: 0.7,
        startOpacity: 0.7,
        endOpacity: 1.0,
        curve: BattleFxMotionCurve.arcOver,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'bluefireball',
        durationSeconds: 0.18,
        fromOffsetX: -40,
        toOffsetX: 10,
        toOffsetY: -15,
        startScale: 0.1,
        endScale: 0.7,
        startOpacity: 0.0,
        endOpacity: 1.0,
        curve: BattleFxMotionCurve.arcOver,
        afterEffect: BattleFxAfterEffect.explode,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownLifeDew(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.easeOut,
        toOffsetX: 0,
        startScale: 0.5,
        endScale: 0.5,
        startOpacity: 0.7,
        endOpacity: 0.6,
      ),
      WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.easeOut,
        toOffsetX: 20,
        toOffsetY: -10,
        startScale: 0.5,
        endScale: 0.5,
        startOpacity: 0.7,
        endOpacity: 0.6,
      ),
      WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.easeOut,
        toOffsetX: -20,
        toOffsetY: 10,
        startScale: 0.5,
        endScale: 0.5,
        startOpacity: 0.7,
        endOpacity: 0.6,
      ),
      WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.easeOut,
        toOffsetY: -5,
        startScale: 0.5,
        endScale: 0.5,
        startOpacity: 0.7,
        endOpacity: 0.6,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownAromatherapy(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x3348C774,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.20,
        fromOffsetX: -22,
        fromOffsetY: 10,
        toOffsetX: 18,
        toOffsetY: -36,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.5,
        endScale: 0.9,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.20,
        fromOffsetX: 24,
        fromOffsetY: 16,
        toOffsetX: -18,
        toOffsetY: -42,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.5,
        endScale: 0.9,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownRest(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.22,
        fromOffsetX: -10,
        fromOffsetY: -6,
        toOffsetX: -22,
        toOffsetY: -48,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.22,
        fromOffsetX: 10,
        fromOffsetY: -2,
        toOffsetX: 24,
        toOffsetY: -44,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.6,
        endScale: 1.0,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownIngrain(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x335A8F34,
        durationSeconds: 0.14,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'leaf1',
        durationSeconds: 0.22,
        fromOffsetX: -26,
        fromOffsetY: 28,
        toOffsetX: -6,
        toOffsetY: -16,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.5,
        endScale: 0.9,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'leaf2',
        durationSeconds: 0.22,
        fromOffsetX: 28,
        fromOffsetY: 30,
        toOffsetX: 10,
        toOffsetY: -12,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.5,
        endScale: 0.9,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownMorningSun(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33F5D04C,
        durationSeconds: 0.18,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.20,
        fromOffsetX: -16,
        fromOffsetY: -70,
        toOffsetX: -6,
        toOffsetY: -14,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.6,
        endScale: 0.9,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.20,
        fromOffsetX: 16,
        fromOffsetY: -76,
        toOffsetX: 8,
        toOffsetY: -10,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.6,
        endScale: 0.9,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownShoreUp(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33D2B48C,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'mudwisp',
        durationSeconds: 0.20,
        fromOffsetX: -30,
        fromOffsetY: 20,
        toOffsetX: -8,
        toOffsetY: -18,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.6,
        endScale: 0.9,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'mudwisp',
        durationSeconds: 0.20,
        fromOffsetX: 32,
        fromOffsetY: 24,
        toOffsetX: 10,
        toOffsetY: -14,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.6,
        endScale: 0.9,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDrain(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x339AB440,
        durationSeconds: 0.18,
      ),
      _targetToAttackerFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcOver,
        toOffsetX: -12,
        toOffsetY: -8,
        startScale: 0.6,
        endScale: 0.4,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetToAttackerFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.linear,
        toOffsetX: 8,
        toOffsetY: 0,
        startScale: 0.6,
        endScale: 0.4,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetToAttackerFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 16,
        toOffsetY: -12,
        startScale: 0.6,
        endScale: 0.4,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownLeechLife(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33987058,
        durationSeconds: 0.18,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.20,
        toOffsetX: 20,
        toOffsetY: 18,
        startScale: 0.0,
        endScale: 1.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetToAttackerFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.6,
        endScale: 0.4,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetToAttackerFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.linear,
        toOffsetX: -10,
        startScale: 0.6,
        endScale: 0.4,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetToAttackerFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 10,
        startScale: 0.6,
        endScale: 0.4,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownHornLeech(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.18,
        distancePx: 34,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        toOffsetX: 20,
        toOffsetY: 16,
        startScale: 0.0,
        endScale: 1.6,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        toOffsetX: 20,
        toOffsetY: -18,
        startScale: 0.0,
        endScale: 1.6,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetToAttackerFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.6,
        endScale: 0.4,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetToAttackerFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.linear,
        toOffsetX: -12,
        startScale: 0.6,
        endScale: 0.4,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetToAttackerFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 12,
        toOffsetY: -6,
        startScale: 0.6,
        endScale: 0.4,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownParabolicCharge(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33FFF066,
        durationSeconds: 0.16,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.22,
        startScale: 4.0,
        endScale: 0.3,
        startOpacity: 0.0,
        endOpacity: 0.5,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _attackerChargeFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.24,
        fromOffsetY: -12,
        toOffsetY: -12,
        startScale: 4.2,
        endScale: 0.3,
        startOpacity: 0.0,
        endOpacity: 0.5,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDrainingKiss(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _targetToAttackerFx(
        ctx,
        effectId: 'mistball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.6,
        endScale: 0.4,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetToAttackerFx(
        ctx,
        effectId: 'mistball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.linear,
        startScale: 0.6,
        endScale: 0.4,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetToAttackerFx(
        ctx,
        effectId: 'mistball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.6,
        endScale: 0.4,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownOblivionWing(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x55000000,
        durationSeconds: 0.20,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        fromOffsetY: -70,
        toOffsetX: 20,
        toOffsetY: 18,
        startScale: 0.9,
        endScale: 0.6,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _projectileToTarget(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        fromOffsetY: -70,
        toOffsetX: -10,
        toOffsetY: -12,
        startScale: 0.9,
        endScale: 0.6,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _projectileToTarget(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        fromOffsetY: -70,
        toOffsetX: -24,
        toOffsetY: 8,
        startScale: 0.9,
        endScale: 0.6,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'blackwisp',
        from: BattleVisualAnchor.attackerHead,
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        fromOffsetY: -80,
        toOffsetX: 30,
        toOffsetY: 20,
        startScale: 0.8,
        endScale: 1.1,
        startOpacity: 0.7,
        endOpacity: 0.2,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'blackwisp',
        from: BattleVisualAnchor.attackerHead,
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        fromOffsetY: -80,
        toOffsetX: 10,
        toOffsetY: -10,
        startScale: 0.8,
        endScale: 1.1,
        startOpacity: 0.7,
        endOpacity: 0.2,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'blackwisp',
        from: BattleVisualAnchor.attackerHead,
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        fromOffsetY: -80,
        toOffsetX: -10,
        toOffsetY: 10,
        startScale: 0.8,
        endScale: 1.1,
        startOpacity: 0.7,
        endOpacity: 0.2,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'blackwisp',
        from: BattleVisualAnchor.attackerHead,
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        fromOffsetY: -80,
        toOffsetX: -30,
        toOffsetY: 0,
        startScale: 0.8,
        endScale: 1.1,
        startOpacity: 0.7,
        endOpacity: 0.2,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownLeechSeed(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: -30,
        toOffsetY: -40,
        startScale: 0.1,
        endScale: 0.2,
        startOpacity: 0.5,
        endOpacity: 0.6,
      ),
      const WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 40,
        toOffsetY: -35,
        startScale: 0.1,
        endScale: 0.2,
        startOpacity: 0.5,
        endOpacity: 0.6,
      ),
      const WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 20,
        toOffsetY: -25,
        startScale: 0.1,
        endScale: 0.2,
        startOpacity: 0.5,
        endOpacity: 0.6,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownHyperBeam(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const patterns = <({double x, double y})>[
      (x: 30, y: 30),
      (x: 20, y: -30),
      (x: -30, y: 0),
      (x: -10, y: 10),
      (x: 10, y: -10),
      (x: -20, y: 0),
    ];
    final steps = <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33000000,
        durationSeconds: 0.18,
      ),
    ];
    for (var i = 0; i < patterns.length; i++) {
      if (i > 0) {
        steps.add(const WaitStep(durationSeconds: 0.03));
      }
      final pattern = patterns[i];
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: 'electroball',
          durationSeconds: 0.20,
          curve: BattleFxMotionCurve.linear,
          toOffsetX: pattern.x,
          toOffsetY: pattern.y,
          startScale: 0.4,
          endScale: 0.6,
          startOpacity: 0.6,
          endOpacity: 0.3,
        ),
      );
    }
    steps.addAll(<BattleAnimationStep>[
      const WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 2.2,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.20,
        fromOffsetX: 8,
        toOffsetX: 8,
        startScale: 0.0,
        endScale: 2.4,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ]);
    return steps;
  }

  List<BattleAnimationStep> _showdownSignalBeam(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const patterns = <({String effectId, double x, double y})>[
      (effectId: 'energyball', x: 0, y: 0),
      (effectId: 'electroball', x: 10, y: -5),
      (effectId: 'energyball', x: -10, y: 5),
      (effectId: 'energyball', x: 0, y: -5),
    ];
    final steps = <BattleAnimationStep>[];
    for (var i = 0; i < patterns.length; i++) {
      if (i > 0) {
        steps.add(const WaitStep(durationSeconds: 0.05));
      }
      final pattern = patterns[i];
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: pattern.effectId,
          durationSeconds: 0.22,
          curve: BattleFxMotionCurve.linear,
          toOffsetX: pattern.x,
          toOffsetY: pattern.y,
          startScale: 0.5,
          endScale: 0.6,
          startOpacity: 0.2,
          endOpacity: 0.6,
        ),
      );
    }
    return steps;
  }

  List<BattleAnimationStep> _showdownFleurCannon(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const patterns = <({double x, double y})>[
      (x: 30, y: 30),
      (x: 20, y: -30),
      (x: -30, y: 0),
      (x: -10, y: 10),
      (x: 10, y: -10),
    ];
    final steps = <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33FF99FF,
        durationSeconds: 0.18,
      ),
    ];
    for (var i = 0; i < patterns.length; i++) {
      if (i > 0) {
        steps.add(const WaitStep(durationSeconds: 0.04));
      }
      final pattern = patterns[i];
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: 'mistball',
          durationSeconds: 0.20,
          curve: BattleFxMotionCurve.linear,
          toOffsetX: pattern.x,
          toOffsetY: pattern.y,
          startScale: 0.4,
          endScale: 0.6,
          startOpacity: 0.6,
          endOpacity: 0.3,
        ),
      );
    }
    return steps;
  }

  List<BattleAnimationStep> _showdownArmorCannon(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33124763,
        durationSeconds: 0.18,
      ),
      const ScreenFlashStep(
        colorArgb: 0x33FFC001,
        durationSeconds: 0.14,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.20,
        fromOffsetY: 60,
        toOffsetY: 0,
        startScale: 0.7,
        endScale: 0.9,
        startOpacity: 0.0,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.20,
        fromOffsetX: -60,
        fromOffsetY: -40,
        startScale: 0.7,
        endScale: 1.3,
        startOpacity: 0.0,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.24,
        startScale: 0.0,
        endScale: 0.8,
        startOpacity: 0.0,
        endOpacity: 0.5,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 1.0,
        endScale: 1.2,
        startOpacity: 0.8,
        endOpacity: 0.4,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSteelBeam(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.1,
        endScale: 0.7,
        startOpacity: 0.0,
        endOpacity: 1.0,
      ),
      const WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 40,
        toOffsetY: -20,
        startScale: 0.1,
        endScale: 0.7,
        startOpacity: 0.0,
        endOpacity: 1.0,
      ),
      const WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: -30,
        toOffsetY: -10,
        startScale: 0.1,
        endScale: 0.7,
        startOpacity: 0.0,
        endOpacity: 1.0,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownBeakBlast(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x55000000,
        durationSeconds: 0.20,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.18,
        fromOffsetX: -25,
        fromOffsetY: -10,
        toOffsetX: -10,
        toOffsetY: -25,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.0,
        endScale: 1.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.18,
        fromOffsetX: 30,
        fromOffsetY: -8,
        toOffsetX: 20,
        toOffsetY: -20,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.0,
        endScale: 1.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.18,
        fromOffsetX: 5,
        fromOffsetY: -12,
        toOffsetX: 5,
        toOffsetY: -40,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.0,
        endScale: 1.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'fireball',
        durationSeconds: 0.18,
        fromOffsetX: -20,
        fromOffsetY: -10,
        toOffsetX: -20,
        toOffsetY: -20,
        curve: BattleFxMotionCurve.arcOver,
        startScale: 0.0,
        endScale: 1.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.20,
        startScale: 0.0,
        endScale: 2.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownTwinBeam(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const patterns = <({String effectId, double x, double y})>[
      (effectId: 'mistball', x: 0, y: 0),
      (effectId: 'poisonwisp', x: 10, y: -5),
      (effectId: 'mistball', x: -10, y: 5),
      (effectId: 'poisonwisp', x: 0, y: -5),
      (effectId: 'mistball', x: 10, y: -5),
      (effectId: 'poisonwisp', x: 0, y: -5),
    ];
    final steps = <BattleAnimationStep>[];
    for (var i = 0; i < patterns.length; i++) {
      if (i > 0) {
        steps.add(const WaitStep(durationSeconds: 0.04));
      }
      final pattern = patterns[i];
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: pattern.effectId,
          durationSeconds: 0.20,
          curve: BattleFxMotionCurve.linear,
          toOffsetX: pattern.x,
          toOffsetY: pattern.y,
          startScale: 0.5,
          endScale: 0.6,
          startOpacity: 0.2,
          endOpacity: 0.6,
        ),
      );
    }
    return steps;
  }

  List<BattleAnimationStep> _showdownSpikeCannon(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        startScale: 0.4,
        endScale: 0.4,
        startOpacity: 0.6,
        endOpacity: 0.6,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        startScale: 0.2,
        endScale: 0.2,
        startOpacity: 0.6,
        endOpacity: 0.6,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownWaterShuriken(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    const volleys =
        <({double bloomX, double bloomY, double impactX, double impactY})>[
      (bloomX: -18, bloomY: -14, impactX: -24, impactY: -14),
      (bloomX: 18, bloomY: -20, impactX: 22, impactY: 8),
      (bloomX: 0, bloomY: 18, impactX: 0, impactY: -24),
    ];
    final steps = <BattleAnimationStep>[];
    for (var i = 0; i < volleys.length; i++) {
      final volley = volleys[i];
      if (i > 0) {
        steps.add(const WaitStep(durationSeconds: 0.04));
      }
      steps.add(
        _attackerChargeFx(
          ctx,
          effectId: 'waterwisp',
          durationSeconds: 0.18,
          curve: BattleFxMotionCurve.easeOut,
          toOffsetX: volley.bloomX,
          toOffsetY: volley.bloomY,
          startScale: 0.0,
          endScale: 4.0,
          startOpacity: 1.0,
          endOpacity: 0.0,
          afterEffect: BattleFxAfterEffect.fade,
        ),
      );
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: 'icicle',
          durationSeconds: 0.35,
          curve: BattleFxMotionCurve.easeOut,
          toOffsetX: volley.impactX,
          toOffsetY: volley.impactY - 70,
          startScale: 0.55,
          endScale: 0.8,
          startOpacity: 0.9,
          endOpacity: 0.2,
        ),
      );
    }
    steps.addAll(<BattleAnimationStep>[
      const WaitStep(durationSeconds: 0.08),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.12,
      ),
    ]);
    return steps;
  }

  List<BattleAnimationStep> _showdownTerastarStorm(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const impacts = <({double x, double y})>[
      (x: 30, y: 30),
      (x: 20, y: -30),
      (x: -10, y: 10),
      (x: -30, y: 0),
      (x: 10, y: -10),
      (x: -20, y: 0),
    ];
    final steps = <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x55000000,
        durationSeconds: 0.20,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.20,
        fromOffsetY: -10,
        toOffsetY: -80,
        startScale: 0.75,
        endScale: 1.25,
        startOpacity: 0.6,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.easeOut,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.20,
        fromOffsetY: -10,
        toOffsetY: -80,
        startScale: 1.0,
        endScale: 1.5,
        startOpacity: 0.6,
        endOpacity: 0.0,
        curve: BattleFxMotionCurve.easeOut,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
    for (var i = 0; i < impacts.length; i++) {
      steps.add(const WaitStep(durationSeconds: 0.04));
      final impact = impacts[i];
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: 'electroball',
          from: BattleVisualAnchor.attackerHead,
          durationSeconds: 0.20,
          curve: BattleFxMotionCurve.linear,
          fromOffsetY: -80,
          toOffsetX: impact.x,
          toOffsetY: impact.y,
          startScale: 0.4,
          endScale: 0.6,
          startOpacity: 0.6,
          endOpacity: 0.3,
        ),
      );
    }
    return steps;
  }

  List<BattleAnimationStep> _showdownMeteorMash(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x55000000,
        durationSeconds: 0.18,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.20,
        distancePx: 36,
      ),
      _targetFx(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 1.8,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 9,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownStealthRock(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'rock1',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: -40,
        toOffsetY: -10,
        startScale: 0.1,
        endScale: 0.2,
        startOpacity: 0.5,
        endOpacity: 1.0,
      ),
      WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'rock2',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: -20,
        toOffsetY: -40,
        startScale: 0.1,
        endScale: 0.2,
        startOpacity: 0.5,
        endOpacity: 1.0,
      ),
      WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'rock1',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 30,
        toOffsetY: -20,
        startScale: 0.1,
        endScale: 0.2,
        startOpacity: 0.5,
        endOpacity: 1.0,
      ),
      WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'rock2',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 10,
        toOffsetY: -30,
        startScale: 0.1,
        endScale: 0.2,
        startOpacity: 0.5,
        endOpacity: 1.0,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSpikes(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'caltrop',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: -25,
        toOffsetY: -40,
        startScale: 0.1,
        endScale: 0.3,
        startOpacity: 0.5,
        endOpacity: 1.0,
      ),
      WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'caltrop',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 50,
        toOffsetY: -40,
        startScale: 0.1,
        endScale: 0.3,
        startOpacity: 0.5,
        endOpacity: 1.0,
      ),
      WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'caltrop',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 30,
        toOffsetY: -45,
        startScale: 0.1,
        endScale: 0.3,
        startOpacity: 0.5,
        endOpacity: 1.0,
      ),
    ];
  }

  SpawnFxStep _lanePulse(
    BattleMoveVisualRecipeContext ctx, {
    required String effectId,
    required double fraction,
    double durationSeconds = 0.22,
    double startScale = 1.0,
    double endScale = 2.0,
    double startOpacity = 1.0,
    double endOpacity = 0.0,
  }) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    final x = (fraction - 0.5) * 40;
    final y = (0.5 - fraction) * 20;
    return SpawnFxStep(
      effectId: effectId,
      attackerSide: ctx.attackerSide,
      defenderSide: targetSide,
      from: BattleVisualAnchor.attackerCenter,
      to: BattleVisualAnchor.attackerCenter,
      durationSeconds: durationSeconds,
      curve: BattleFxMotionCurve.linear,
      startScale: startScale,
      endScale: endScale,
      startOpacity: startOpacity,
      endOpacity: endOpacity,
      fromOffsetX: x,
      fromOffsetY: y,
      toOffsetX: x,
      toOffsetY: y,
      afterEffect: BattleFxAfterEffect.fade,
    );
  }

  List<BattleAnimationStep> _hazardSet({
    required BattleMoveVisualRecipeContext ctx,
    required String effectId,
  }) {
    return <BattleAnimationStep>[
      SpawnFxStep(
        effectId: effectId,
        attackerSide: ctx.attackerSide,
        defenderSide: ctx.targetSide ?? ctx.attackerSide,
        from: BattleVisualAnchor.attackerCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  SpawnFxStep _targetFx(
    BattleMoveVisualRecipeContext ctx, {
    required String effectId,
    BattleVisualAnchor from = BattleVisualAnchor.defenderCenter,
    BattleVisualAnchor to = BattleVisualAnchor.defenderCenter,
    double durationSeconds = 0.16,
    BattleFxMotionCurve curve = BattleFxMotionCurve.easeOut,
    BattleFxAfterEffect afterEffect = BattleFxAfterEffect.none,
    double startScale = 1.0,
    double endScale = 1.0,
    double startOpacity = 1.0,
    double endOpacity = 1.0,
    double fromOffsetX = 0,
    double fromOffsetY = 0,
    double toOffsetX = 0,
    double toOffsetY = 0,
    double startDelaySeconds = 0,
    bool playAsAccent = false,
  }) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return SpawnFxStep(
      effectId: effectId,
      attackerSide: ctx.attackerSide,
      defenderSide: targetSide,
      from: from,
      to: to,
      durationSeconds: durationSeconds,
      curve: curve,
      afterEffect: afterEffect,
      startScale: startScale,
      endScale: endScale,
      startOpacity: startOpacity,
      endOpacity: endOpacity,
      fromOffsetX: fromOffsetX,
      fromOffsetY: fromOffsetY,
      toOffsetX: toOffsetX,
      toOffsetY: toOffsetY,
      startDelaySeconds: startDelaySeconds,
      playAsAccent: playAsAccent,
    );
  }

  SpawnFxStep _attackerChargeFx(
    BattleMoveVisualRecipeContext ctx, {
    required String effectId,
    BattleVisualAnchor from = BattleVisualAnchor.attackerCenter,
    BattleVisualAnchor to = BattleVisualAnchor.attackerCenter,
    double durationSeconds = 0.16,
    BattleFxMotionCurve curve = BattleFxMotionCurve.easeOut,
    BattleFxAfterEffect afterEffect = BattleFxAfterEffect.none,
    double startScale = 1.0,
    double endScale = 1.0,
    double startOpacity = 1.0,
    double endOpacity = 1.0,
    double fromOffsetX = 0,
    double fromOffsetY = 0,
    double toOffsetX = 0,
    double toOffsetY = 0,
    double startDelaySeconds = 0,
    bool playAsAccent = false,
  }) {
    return SpawnFxStep(
      effectId: effectId,
      attackerSide: ctx.attackerSide,
      defenderSide: ctx.attackerSide,
      from: from,
      to: to,
      durationSeconds: durationSeconds,
      curve: curve,
      afterEffect: afterEffect,
      startScale: startScale,
      endScale: endScale,
      startOpacity: startOpacity,
      endOpacity: endOpacity,
      fromOffsetX: fromOffsetX,
      fromOffsetY: fromOffsetY,
      toOffsetX: toOffsetX,
      toOffsetY: toOffsetY,
      startDelaySeconds: startDelaySeconds,
      playAsAccent: playAsAccent,
    );
  }

  SpawnFxStep _targetToAttackerFx(
    BattleMoveVisualRecipeContext ctx, {
    required String effectId,
    BattleVisualAnchor from = BattleVisualAnchor.defenderCenter,
    BattleVisualAnchor to = BattleVisualAnchor.attackerCenter,
    double durationSeconds = 0.22,
    BattleFxMotionCurve curve = BattleFxMotionCurve.easeOut,
    BattleFxAfterEffect afterEffect = BattleFxAfterEffect.none,
    double startScale = 1.0,
    double endScale = 1.0,
    double startOpacity = 1.0,
    double endOpacity = 1.0,
    double fromOffsetX = 0,
    double fromOffsetY = 0,
    double toOffsetX = 0,
    double toOffsetY = 0,
    double startDelaySeconds = 0,
    bool playAsAccent = false,
  }) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return SpawnFxStep(
      effectId: effectId,
      attackerSide: ctx.attackerSide,
      defenderSide: targetSide,
      from: from,
      to: to,
      durationSeconds: durationSeconds,
      curve: curve,
      afterEffect: afterEffect,
      startScale: startScale,
      endScale: endScale,
      startOpacity: startOpacity,
      endOpacity: endOpacity,
      fromOffsetX: fromOffsetX,
      fromOffsetY: fromOffsetY,
      toOffsetX: toOffsetX,
      toOffsetY: toOffsetY,
      startDelaySeconds: startDelaySeconds,
      playAsAccent: playAsAccent,
    );
  }

  SpawnFxStep _projectileToTarget(
    BattleMoveVisualRecipeContext ctx, {
    required String effectId,
    BattleVisualAnchor from = BattleVisualAnchor.attackerCenter,
    BattleVisualAnchor to = BattleVisualAnchor.defenderCenter,
    double durationSeconds = 0.22,
    BattleFxMotionCurve curve = BattleFxMotionCurve.easeOut,
    BattleFxAfterEffect afterEffect = BattleFxAfterEffect.explode,
    double startScale = 1.0,
    double endScale = 1.0,
    double startOpacity = 1.0,
    double endOpacity = 1.0,
    double fromOffsetX = 0,
    double fromOffsetY = 0,
    double toOffsetX = 0,
    double toOffsetY = 0,
    double startDelaySeconds = 0,
    bool playAsAccent = false,
  }) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return SpawnFxStep(
      effectId: effectId,
      attackerSide: ctx.attackerSide,
      defenderSide: targetSide,
      from: from,
      to: to,
      durationSeconds: durationSeconds,
      curve: curve,
      afterEffect: afterEffect,
      startScale: startScale,
      endScale: endScale,
      startOpacity: startOpacity,
      endOpacity: endOpacity,
      fromOffsetX: fromOffsetX,
      fromOffsetY: fromOffsetY,
      toOffsetX: toOffsetX,
      toOffsetY: toOffsetY,
      startDelaySeconds: startDelaySeconds,
      playAsAccent: playAsAccent,
    );
  }

  List<BattleAnimationStep> _showdownDoomDesire(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33000000,
        durationSeconds: 0.30,
      ),
      const WaitStep(durationSeconds: 0.20),
      const ScreenFlashStep(
        colorArgb: 0x4D000000,
        durationSeconds: 0.30,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSeedFlare(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x55B8FF8A,
        durationSeconds: 0.14,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.18,
        startScale: 0.7,
        endScale: 1.6,
        startOpacity: 0.5,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        toOffsetX: 28,
        toOffsetY: 18,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.5,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        toOffsetX: -28,
        toOffsetY: -18,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.5,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        toOffsetX: 0,
        toOffsetY: 28,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.5,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.16,
        toOffsetX: 0,
        toOffsetY: -28,
        startScale: 0.2,
        endScale: 0.4,
        startOpacity: 1.0,
        endOpacity: 0.5,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.18,
        toOffsetX: 24,
        toOffsetY: 16,
        startScale: 0.8,
        endScale: 1.6,
        startOpacity: 0.5,
        endOpacity: 0.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        toOffsetX: -24,
        toOffsetY: -16,
        startScale: 0.4,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        toOffsetX: 24,
        toOffsetY: 16,
        startScale: 0.4,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownIcyWind(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.linear,
        toOffsetX: 10,
        toOffsetY: 5,
        startScale: 1.7,
        endScale: 2.5,
        startOpacity: 0.3,
        endOpacity: 0.4,
      ),
      const WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        toOffsetX: -10,
        toOffsetY: -5,
        startScale: 1.7,
        endScale: 2.5,
        startOpacity: 0.3,
        endOpacity: 0.4,
      ),
      const WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.linear,
        startScale: 1.7,
        endScale: 2.5,
        startOpacity: 0.3,
        endOpacity: 0.4,
      ),
      const WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.linear,
        startScale: 1.7,
        endScale: 2.5,
        startOpacity: 0.3,
        endOpacity: 0.4,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownWeatherBall(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _attackerChargeFx(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.16,
        toOffsetY: 24,
        startScale: 0.5,
        endScale: 0.5,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.06),
      _targetFx(
        ctx,
        effectId: 'iceball',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.24,
        fromOffsetY: 34,
        startScale: 0.5,
        endScale: 0.8,
        startOpacity: 0.0,
        endOpacity: 1.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownFlameBurst(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.easeOut,
        startScale: 0.4,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.8,
      ),
      _targetFx(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.18,
        startScale: 0.5,
        endScale: 2.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        durationSeconds: 0.18,
        toOffsetY: 18,
        startScale: 1.0,
        endScale: 2.2,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownWaterSport(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 30,
        toOffsetY: 20,
        startScale: 0.1,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.3,
      ),
      const WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 20,
        toOffsetY: -20,
        startScale: 0.1,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.3,
      ),
      const WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: -30,
        startScale: 0.1,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.3,
      ),
      const WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 10,
        toOffsetY: 30,
        startScale: 0.1,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.3,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownScald(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      ..._showdownWaterSport(ctx),
      _targetFx(
        ctx,
        effectId: 'wisp',
        fromOffsetX: 30,
        durationSeconds: 0.18,
        toOffsetY: 24,
        startScale: 1.0,
        endScale: 1.4,
        startOpacity: 1.0,
        endOpacity: 0.2,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        fromOffsetX: -30,
        durationSeconds: 0.18,
        toOffsetY: 24,
        startScale: 1.0,
        endScale: 1.4,
        startOpacity: 1.0,
        endOpacity: 0.2,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        fromOffsetX: 15,
        durationSeconds: 0.18,
        toOffsetY: 24,
        startScale: 1.0,
        endScale: 1.4,
        startOpacity: 1.0,
        endOpacity: 0.2,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        fromOffsetX: -15,
        durationSeconds: 0.18,
        toOffsetY: 24,
        startScale: 1.0,
        endScale: 1.4,
        startOpacity: 1.0,
        endOpacity: 0.2,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 7,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSteamEruption(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x330000DD,
        durationSeconds: 0.14,
      ),
      ..._showdownWaterSport(ctx),
      _targetFx(
        ctx,
        effectId: 'wisp',
        fromOffsetX: 30,
        durationSeconds: 0.18,
        toOffsetY: 24,
        startScale: 1.0,
        endScale: 1.5,
        startOpacity: 1.0,
        endOpacity: 0.2,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        fromOffsetX: -30,
        durationSeconds: 0.18,
        toOffsetY: 24,
        startScale: 1.0,
        endScale: 1.5,
        startOpacity: 1.0,
        endOpacity: 0.2,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        fromOffsetX: 15,
        durationSeconds: 0.18,
        toOffsetY: 24,
        startScale: 1.0,
        endScale: 1.5,
        startOpacity: 1.0,
        endOpacity: 0.2,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'wisp',
        fromOffsetX: -15,
        durationSeconds: 0.18,
        toOffsetY: 24,
        startScale: 1.0,
        endScale: 1.5,
        startOpacity: 1.0,
        endOpacity: 0.2,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.14,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownTriAttack(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _attackerChargeFx(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.16,
        fromOffsetY: 14,
        toOffsetY: 14,
        startScale: 0.0,
        endScale: 0.5,
        startOpacity: 0.2,
        endOpacity: 0.6,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.16,
        fromOffsetX: -18,
        fromOffsetY: -10,
        toOffsetX: -18,
        toOffsetY: -10,
        startScale: 0.0,
        endScale: 0.5,
        startOpacity: 0.2,
        endOpacity: 0.6,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.16,
        fromOffsetX: 18,
        fromOffsetY: -10,
        toOffsetX: 18,
        toOffsetY: -10,
        startScale: 0.0,
        endScale: 0.5,
        startOpacity: 0.2,
        endOpacity: 0.6,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _projectileToTarget(
        ctx,
        effectId: 'flareball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.easeOut,
        toOffsetX: -10,
        toOffsetY: 5,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.8,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.easeOut,
        toOffsetX: -10,
        toOffsetY: 5,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.8,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.26,
        curve: BattleFxMotionCurve.easeOut,
        toOffsetX: 10,
        toOffsetY: -5,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.6,
        endOpacity: 0.8,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownClangingScales(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33440044,
        durationSeconds: 0.14,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.18,
        startScale: 1.0,
        endScale: 3.0,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.linear,
        toOffsetX: 30,
        toOffsetY: 30,
        startScale: 0.4,
        endScale: 0.6,
        startOpacity: 0.6,
        endOpacity: 0.3,
      ),
      const WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.linear,
        toOffsetX: 20,
        toOffsetY: -30,
        startScale: 0.4,
        endScale: 0.6,
        startOpacity: 0.6,
        endOpacity: 0.3,
      ),
      const WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.linear,
        toOffsetX: -30,
        toOffsetY: 0,
        startScale: 0.4,
        endScale: 0.6,
        startOpacity: 0.6,
        endOpacity: 0.3,
      ),
      const WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: 'shadowball',
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.linear,
        toOffsetX: -10,
        toOffsetY: 10,
        startScale: 0.4,
        endScale: 0.6,
        startOpacity: 0.6,
        endOpacity: 0.3,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownGunkShot(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const patterns = <({double toX, double toY, double wait})>[
      (toX: 30, toY: 30, wait: 0.00),
      (toX: 20, toY: -30, wait: 0.03),
      (toX: -30, toY: 0, wait: 0.03),
      (toX: -10, toY: 18, wait: 0.03),
    ];
    final steps = <BattleAnimationStep>[];
    for (var i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      if (i > 0) {
        steps.add(WaitStep(durationSeconds: pattern.wait));
      }
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: 'poisonwisp',
          durationSeconds: 0.20,
          curve: BattleFxMotionCurve.linear,
          toOffsetX: pattern.toX,
          toOffsetY: pattern.toY,
          startScale: 1.0,
          endScale: 2.0,
          startOpacity: 0.6,
          endOpacity: 0.3,
        ),
      );
    }
    return steps;
  }

  List<BattleAnimationStep> _showdownToxic(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x443B103F,
        durationSeconds: 0.10,
      ),
      _projectileToTarget(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.24,
        curve: BattleFxMotionCurve.arcUnder,
        startScale: 0.2,
        endScale: 0.7,
        startOpacity: 0.0,
        endOpacity: 1.0,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownToxicSpikes(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'poisoncaltrop',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: -20,
        toOffsetY: -42,
        startScale: 0.1,
        endScale: 0.3,
        startOpacity: 0.5,
        endOpacity: 1.0,
      ),
      const WaitStep(durationSeconds: 0.05),
      _projectileToTarget(
        ctx,
        effectId: 'poisoncaltrop',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.arcUnder,
        toOffsetX: 34,
        toOffsetY: -44,
        startScale: 0.1,
        endScale: 0.3,
        startOpacity: 0.5,
        endOpacity: 1.0,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownPoisonGas(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.20,
        fromOffsetX: -26,
        fromOffsetY: -42,
        toOffsetX: -18,
        toOffsetY: -10,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.20,
        fromOffsetY: -50,
        toOffsetY: -8,
        startScale: 0.55,
        endScale: 1.05,
        startOpacity: 0.85,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.20,
        fromOffsetX: 26,
        fromOffsetY: -42,
        toOffsetX: 18,
        toOffsetY: -10,
        startScale: 0.5,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSmog(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _showdownSmogBase(ctx, effectId: 'poisonwisp');
  }

  List<BattleAnimationStep> _showdownClearSmog(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _showdownSmogBase(ctx, effectId: 'wisp');
  }

  List<BattleAnimationStep> _showdownPoisonFang(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _showdownElementalFang(
      ctx,
      accentSteps: <BattleAnimationStep>[
        _targetFx(
          ctx,
          effectId: 'poisonwisp',
          durationSeconds: 0.16,
          toOffsetX: -16,
          toOffsetY: -14,
          startScale: 0.6,
          endScale: 1.1,
          startOpacity: 0.9,
          endOpacity: 0.0,
          afterEffect: BattleFxAfterEffect.fade,
        ),
        const WaitStep(durationSeconds: 0.04),
        _targetFx(
          ctx,
          effectId: 'poisonwisp',
          durationSeconds: 0.16,
          toOffsetX: 18,
          toOffsetY: 10,
          startScale: 0.6,
          endScale: 1.1,
          startOpacity: 0.9,
          endOpacity: 0.0,
          afterEffect: BattleFxAfterEffect.fade,
        ),
      ],
    );
  }

  List<BattleAnimationStep> _showdownCrossPoison(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x442A0E33,
        durationSeconds: 0.10,
      ),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.18,
        distancePx: 28,
      ),
      _targetFx(
        ctx,
        effectId: 'leftslash',
        durationSeconds: 0.16,
        fromOffsetX: 42,
        fromOffsetY: 30,
        toOffsetX: -24,
        toOffsetY: -20,
        startScale: 0.9,
        endScale: 1.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'rightslash',
        durationSeconds: 0.16,
        fromOffsetX: 34,
        fromOffsetY: -28,
        toOffsetX: -20,
        toOffsetY: 18,
        startScale: 0.9,
        endScale: 1.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.18,
        startScale: 0.7,
        endScale: 1.3,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownDireClaw(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.fastDash,
        durationSeconds: 0.18,
        distancePx: 28,
      ),
      _targetFx(
        ctx,
        effectId: 'leftclaw',
        durationSeconds: 0.16,
        fromOffsetX: 40,
        fromOffsetY: 28,
        toOffsetX: -18,
        toOffsetY: -16,
        startScale: 0.9,
        endScale: 1.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _targetFx(
        ctx,
        effectId: 'rightclaw',
        durationSeconds: 0.16,
        fromOffsetX: 34,
        fromOffsetY: -26,
        toOffsetX: -16,
        toOffsetY: 16,
        startScale: 0.9,
        endScale: 1.1,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: 'poisonwisp',
        durationSeconds: 0.18,
        toOffsetY: -6,
        startScale: 0.7,
        endScale: 1.2,
        startOpacity: 0.9,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSmogBase(
    BattleMoveVisualRecipeContext ctx, {
    required String effectId,
  }) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: effectId,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.easeOut,
        toOffsetX: -24,
        toOffsetY: -18,
        startScale: 0.3,
        endScale: 0.7,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: effectId,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.easeOut,
        toOffsetY: -10,
        startScale: 0.35,
        endScale: 0.75,
        startOpacity: 0.75,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.03),
      _projectileToTarget(
        ctx,
        effectId: effectId,
        durationSeconds: 0.18,
        curve: BattleFxMotionCurve.easeOut,
        toOffsetX: 24,
        toOffsetY: -18,
        startScale: 0.3,
        endScale: 0.7,
        startOpacity: 0.7,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: effectId,
        durationSeconds: 0.18,
        toOffsetX: -28,
        toOffsetY: 10,
        startScale: 0.7,
        endScale: 1.1,
        startOpacity: 0.75,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: effectId,
        durationSeconds: 0.18,
        toOffsetY: -4,
        startScale: 0.75,
        endScale: 1.15,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      _targetFx(
        ctx,
        effectId: effectId,
        durationSeconds: 0.18,
        toOffsetX: 28,
        toOffsetY: 8,
        startScale: 0.7,
        endScale: 1.1,
        startOpacity: 0.75,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownMudShot(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const patterns = <({double toX, double toY, double wait})>[
      (toX: 10, toY: 5, wait: 0.00),
      (toX: -10, toY: -5, wait: 0.04),
      (toX: 0, toY: 5, wait: 0.04),
    ];
    final steps = <BattleAnimationStep>[];
    for (var i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      if (i > 0) {
        steps.add(WaitStep(durationSeconds: pattern.wait));
      }
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: 'mudwisp',
          durationSeconds: 0.18,
          curve: BattleFxMotionCurve.easeOut,
          toOffsetX: pattern.toX,
          toOffsetY: pattern.toY,
          startScale: 0.4,
          endScale: 1.0,
          startOpacity: 0.3,
          endOpacity: 0.6,
        ),
      );
    }
    return steps;
  }

  List<BattleAnimationStep> _showdownElectroBall(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'electroball',
        durationSeconds: 0.22,
        curve: BattleFxMotionCurve.linear,
        startScale: 1.0,
        endScale: 1.0,
        startOpacity: 0.3,
        endOpacity: 0.6,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 7,
        durationSeconds: 0.16,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownRockBlast(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'rock3',
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        startScale: 0.6,
        endScale: 0.6,
        startOpacity: 0.4,
        endOpacity: 1.0,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownSplash(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _attackerChargeFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.15,
        curve: BattleFxMotionCurve.arcUnder,
        fromOffsetX: 20,
        fromOffsetY: 20,
        toOffsetX: 40,
        toOffsetY: 60,
        startScale: 0.5,
        endScale: 0.5,
        startOpacity: 0.1,
        endOpacity: 0.3,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _attackerChargeFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.15,
        curve: BattleFxMotionCurve.arcUnder,
        fromOffsetX: -20,
        fromOffsetY: 20,
        toOffsetX: -40,
        toOffsetY: 60,
        startScale: 0.5,
        endScale: 0.5,
        startOpacity: 0.1,
        endOpacity: 0.3,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _attackerChargeFx(
        ctx,
        effectId: 'waterwisp',
        durationSeconds: 0.15,
        curve: BattleFxMotionCurve.arcUnder,
        fromOffsetX: 20,
        fromOffsetY: 40,
        toOffsetX: 0,
        toOffsetY: 70,
        startScale: 0.5,
        endScale: 0.5,
        startOpacity: 0.1,
        endOpacity: 0.3,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownCelebrate(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x33FFD95B,
        durationSeconds: 0.16,
      ),
      CombatantShakeStep(
        side: ctx.attackerSide,
        amplitudePx: 5,
        durationSeconds: 0.18,
      ),
      _attackerChargeFx(
        ctx,
        effectId: 'shine',
        from: BattleVisualAnchor.attackerHead,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.arcOver,
        fromOffsetX: -28,
        fromOffsetY: -10,
        toOffsetX: 18,
        toOffsetY: 30,
        startScale: 0.4,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'shine',
        from: BattleVisualAnchor.attackerHead,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.arcUnder,
        fromOffsetX: 28,
        fromOffsetY: -16,
        toOffsetX: -20,
        toOffsetY: 32,
        startScale: 0.4,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      _attackerChargeFx(
        ctx,
        effectId: 'shine',
        from: BattleVisualAnchor.attackerHead,
        to: BattleVisualAnchor.attackerCenter,
        durationSeconds: 0.20,
        curve: BattleFxMotionCurve.easeOut,
        fromOffsetY: -28,
        toOffsetY: 42,
        startScale: 0.4,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownOrderUp(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      SpawnFxStep(
        effectId: 'tatsugiri',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.30,
        curve: BattleFxMotionCurve.linear,
        fromOffsetY: 120,
        startScale: 2.0,
        endScale: 1.0,
        startOpacity: 1.0,
        endOpacity: 1.0,
      ),
      const WaitStep(durationSeconds: 0.03),
      SpawnFxStep(
        effectId: 'tatsugiri',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        from: BattleVisualAnchor.defenderCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: 0.60,
        curve: BattleFxMotionCurve.linear,
        startScale: 1.0,
        endScale: 1.0,
        startOpacity: 1.0,
        endOpacity: 1.0,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownHeartStamp(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'heart',
        from: BattleVisualAnchor.defenderHead,
        to: BattleVisualAnchor.defenderHead,
        durationSeconds: 0.25,
        curve: BattleFxMotionCurve.linear,
        fromOffsetX: -20,
        fromOffsetY: 15,
        toOffsetX: -20,
        toOffsetY: 15,
        startScale: 1.0,
        endScale: 4.0,
        startOpacity: 0.5,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.04),
      CombatantMotionStep(
        side: ctx.attackerSide,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: 0.18,
        distancePx: 24,
      ),
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.10,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownMatchaGotcha(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    final steps = <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x3347A85B,
        durationSeconds: 0.16,
      ),
    ];
    const openingVolley = <({double x, double y, double delay})>[
      (x: 12, y: 0, delay: 0.00),
      (x: 28, y: 10, delay: 0.03),
      (x: 40, y: 20, delay: 0.06),
      (x: 52, y: 30, delay: 0.09),
      (x: 64, y: 40, delay: 0.12),
      (x: 76, y: 50, delay: 0.15),
      (x: 88, y: 60, delay: 0.18),
      (x: 100, y: 70, delay: 0.21),
      (x: 112, y: 80, delay: 0.24),
      (x: 124, y: 90, delay: 0.27),
    ];
    for (final burst in openingVolley) {
      steps.add(
        _attackerChargeFx(
          ctx,
          effectId: 'energyball',
          durationSeconds: 0.30,
          startDelaySeconds: burst.delay,
          playAsAccent: true,
          curve: BattleFxMotionCurve.arcOver,
          toOffsetX: burst.x,
          toOffsetY: burst.y,
          startScale: 0.0,
          endScale: 1.0,
          startOpacity: 1.0,
          endOpacity: 0.0,
          afterEffect: BattleFxAfterEffect.fade,
        ),
      );
    }
    const bursts = <({double x, double y, double wait})>[
      (x: -25, y: -25, wait: 0.00),
      (x: 30, y: -20, wait: 0.05),
      (x: 5, y: -40, wait: 0.05),
      (x: -20, y: -20, wait: 0.05),
    ];
    for (var i = 0; i < bursts.length; i++) {
      final burst = bursts[i];
      if (i > 0) {
        steps.add(WaitStep(durationSeconds: burst.wait));
      }
      steps.add(
        _attackerChargeFx(
          ctx,
          effectId: 'energyball',
          durationSeconds: 0.22,
          curve: BattleFxMotionCurve.arcOver,
          toOffsetX: burst.x,
          toOffsetY: burst.y,
          startScale: 0.0,
          endScale: 2.0,
          startOpacity: 1.0,
          endOpacity: 0.0,
          afterEffect: BattleFxAfterEffect.fade,
        ),
      );
    }
    steps.addAll(<BattleAnimationStep>[
      _targetFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 5.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      const WaitStep(durationSeconds: 0.05),
      _targetFx(
        ctx,
        effectId: 'energyball',
        durationSeconds: 0.18,
        startScale: 0.0,
        endScale: 8.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
    ]);
    const wisps = <({double x, double y})>[
      (x: 30, y: 60),
      (x: -30, y: 60),
      (x: 15, y: 60),
      (x: -15, y: 60),
    ];
    for (final wisp in wisps) {
      steps.add(
        _targetFx(
          ctx,
          effectId: 'wisp',
          durationSeconds: 0.20,
          curve: BattleFxMotionCurve.linear,
          fromOffsetX: wisp.x,
          toOffsetX: wisp.x,
          toOffsetY: wisp.y,
          startScale: 1.0,
          endScale: 1.0,
          startOpacity: 1.0,
          endOpacity: 0.2,
          afterEffect: BattleFxAfterEffect.fade,
        ),
      );
    }
    steps.addAll(<BattleAnimationStep>[
      CombatantFlashStep(
        side: targetSide,
        durationSeconds: 0.08,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 8,
        durationSeconds: 0.12,
      ),
    ]);
    return steps;
  }

  List<BattleAnimationStep> _showdownPresent(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      _projectileToTarget(
        ctx,
        effectId: 'iceball',
        durationSeconds: 0.50,
        curve: BattleFxMotionCurve.linear,
        startScale: 1.0,
        endScale: 1.0,
        startOpacity: 0.8,
        endOpacity: 0.8,
        afterEffect: BattleFxAfterEffect.explode,
      ),
    ];
  }

  List<BattleAnimationStep> _showdownPayDay(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    const impacts = <({double x, double y})>[
      (x: 30, y: 30),
      (x: 20, y: -30),
      (x: -30, y: 0),
      (x: -10, y: 10),
      (x: 10, y: -10),
      (x: -20, y: 0),
    ];
    final steps = <BattleAnimationStep>[];
    for (var i = 0; i < impacts.length; i++) {
      if (i > 0) {
        steps.add(const WaitStep(durationSeconds: 0.075));
      }
      final impact = impacts[i];
      steps.add(
        _projectileToTarget(
          ctx,
          effectId: 'electroball',
          durationSeconds: 0.20,
          curve: BattleFxMotionCurve.linear,
          toOffsetX: impact.x,
          toOffsetY: impact.y,
          startScale: 0.1,
          endScale: 0.3,
          startOpacity: 0.6,
          endOpacity: 0.3,
          afterEffect: BattleFxAfterEffect.explode,
        ),
      );
    }
    steps.add(
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 6,
        durationSeconds: 0.12,
      ),
    );
    return steps;
  }
}
