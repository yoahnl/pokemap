import 'package:map_battle/map_battle.dart';

import 'battle_animation_plan.dart';
import 'battle_fx_catalog.dart';
import 'battle_move_visual_catalog.dart';
import 'battle_move_visual_resolver.dart';
import 'battle_rmxp_move_placement_catalog.dart';
import 'battle_sdk_rmxp_animation_catalog.dart';

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
      BattleMoveVisualRecipeId.sdkExactAcidArmor => _sdkExactSpriteOnUser(
          ctx,
          'acid_armor',
          frameSeconds: 0.12,
          frameSequence: const <int>[0, 1, 2, 3, 0, 1, 2, 3],
        ),
      BattleMoveVisualRecipeId.sdkExactAcrobatics => _sdkExactSpriteOnTarget(
          ctx,
          'acrobatics',
          frameSeconds: 0.10,
          initialWaitSeconds: 0.20,
        ),
      BattleMoveVisualRecipeId.sdkExactAerialAce =>
        _sdkExactSpriteOnTarget(ctx, 'aerial_ace', frameSeconds: 0.055),
      BattleMoveVisualRecipeId.sdkExactAirSlash =>
        _sdkExactSpriteOnTarget(ctx, 'air_slash', frameSeconds: 0.055),
      BattleMoveVisualRecipeId.sdkExactAquaRing => _sdkExactSpriteOnUser(
          ctx,
          'aqua_ring',
          frameSeconds: 0.15,
          frameSequence: const <int>[0, 1, 2, 0, 1, 2, 0, 1, 2],
        ),
      BattleMoveVisualRecipeId.sdkExactAquaTail => _sdkExactSpriteOnTarget(
          ctx,
          'aqua_tail',
          frameSeconds: 0.07,
          frameDurationsSeconds: const <double>[
            0.065,
            0.065,
            0.065,
            0.075,
            0.075,
            0.075,
            0.075,
          ],
        ),
      BattleMoveVisualRecipeId.sdkExactAssurance =>
        _sdkExactSpriteOnTarget(ctx, 'assurance', frameSeconds: 0.15),
      BattleMoveVisualRecipeId.sdkExactAstonish => _sdkExactSpriteOnTarget(
          ctx,
          'astonish',
          frameSeconds: 0.09,
          frameDurationsSeconds: const <double>[
            0.085,
            0.15,
            0.085,
            0.085,
            0.085,
          ],
        ),
      BattleMoveVisualRecipeId.sdkExactAvalanche =>
        _sdkExactSpriteOnTarget(ctx, 'avalanche', frameSeconds: 0.10),
      BattleMoveVisualRecipeId.sdkExactKarateChop => _sdkExactKarateChop(ctx),
      BattleMoveVisualRecipeId.sdkExactLeechSeed => _sdkExactLeechSeed(ctx),
      BattleMoveVisualRecipeId.sdkExactPoisonPowder => _sdkExactPowder(
          ctx,
          colorArgb: 0xCCB942F4,
        ),
      BattleMoveVisualRecipeId.sdkExactRecover => _sdkExactRecover(ctx),
      BattleMoveVisualRecipeId.sdkExactSleepPowder => _sdkExactPowder(
          ctx,
          colorArgb: 0xCCC4D8FF,
        ),
      BattleMoveVisualRecipeId.sdkExactStunSpore => _sdkExactPowder(
          ctx,
          colorArgb: 0xCCEDE452,
        ),
      BattleMoveVisualRecipeId.sdkExactTailWhip => _sdkExactTailWhip(ctx),
      BattleMoveVisualRecipeId.sdkExactThunderWave => _sdkExactThunderWave(ctx),
      BattleMoveVisualRecipeId.sdkExactVineWhip => _sdkExactSpriteOnTarget(
          ctx,
          'vine_whip',
          frameSeconds: 0.015,
          initialWaitSeconds: 0.05,
        ),
      BattleMoveVisualRecipeId.sdkRmxpMoveAnimation =>
        _sdkRmxpMoveAnimation(ctx),
      BattleMoveVisualRecipeId.sdkTackle => _sdkTackle(ctx),
      BattleMoveVisualRecipeId.sdkScratch => _sdkScratch(ctx),
      BattleMoveVisualRecipeId.sdkQuickAttack => _sdkQuickAttack(ctx),
      BattleMoveVisualRecipeId.sdkSlash => _sdkSlash(ctx),
      BattleMoveVisualRecipeId.sdkAerialAce => _sdkAerialAce(ctx),
      BattleMoveVisualRecipeId.sdkCloseCombat => _sdkCloseCombat(ctx),
      BattleMoveVisualRecipeId.sdkBodySlam => _sdkBodySlam(ctx),
      BattleMoveVisualRecipeId.sdkHighJumpKick => _sdkHighJumpKick(ctx),
      BattleMoveVisualRecipeId.sdkShadowPunch => _sdkShadowPunch(ctx),
      BattleMoveVisualRecipeId.sdkFocusPunch => _sdkFocusPunch(ctx),
      BattleMoveVisualRecipeId.sdkDrainPunch => _sdkDrainPunch(ctx),
      BattleMoveVisualRecipeId.sdkDynamicPunch => _sdkDynamicPunch(ctx),
      BattleMoveVisualRecipeId.sdkCometPunch => _sdkCometPunch(ctx),
      BattleMoveVisualRecipeId.sdkMegaPunch => _sdkMegaPunch(ctx),
      BattleMoveVisualRecipeId.sdkPowerUpPunch => _sdkPowerUpPunch(ctx),
      BattleMoveVisualRecipeId.sdkDizzyPunch => _sdkDizzyPunch(ctx),
      BattleMoveVisualRecipeId.sdkJetPunch => _sdkJetPunch(ctx),
      BattleMoveVisualRecipeId.sdkFirePunch => _sdkFirePunch(ctx),
      BattleMoveVisualRecipeId.sdkIcePunch => _sdkIcePunch(ctx),
      BattleMoveVisualRecipeId.sdkThunderPunch => _sdkThunderPunch(ctx),
      BattleMoveVisualRecipeId.sdkBlazeKick => _sdkBlazeKick(ctx),
      BattleMoveVisualRecipeId.sdkThunderousKick => _sdkThunderousKick(ctx),
      BattleMoveVisualRecipeId.sdkTropKick => _sdkTropKick(ctx),
      BattleMoveVisualRecipeId.sdkWoodHammer => _sdkWoodHammer(ctx),
      BattleMoveVisualRecipeId.sdkIvyCudgel => _sdkIvyCudgel(ctx),
      BattleMoveVisualRecipeId.sdkIvyCudgelWater => _sdkIvyCudgelWater(ctx),
      BattleMoveVisualRecipeId.sdkIvyCudgelFire => _sdkIvyCudgelFire(ctx),
      BattleMoveVisualRecipeId.sdkIvyCudgelRock => _sdkIvyCudgelRock(ctx),
      BattleMoveVisualRecipeId.sdkCut => _sdkCut(ctx),
      BattleMoveVisualRecipeId.sdkShadowClaw => _sdkShadowClaw(ctx),
      BattleMoveVisualRecipeId.sdkMultiAttack => _sdkMultiAttack(ctx),
      BattleMoveVisualRecipeId.sdkBite => _sdkBite(ctx),
      BattleMoveVisualRecipeId.sdkSuperFang => _sdkSuperFang(ctx),
      BattleMoveVisualRecipeId.sdkBugBite => _sdkBugBite(ctx),
      BattleMoveVisualRecipeId.sdkPsychicFangs => _sdkPsychicFangs(ctx),
      BattleMoveVisualRecipeId.sdkIronHead => _sdkIronHead(ctx),
      BattleMoveVisualRecipeId.sdkHeadbutt => _sdkHeadbutt(ctx),
      BattleMoveVisualRecipeId.sdkStomp => _sdkStomp(ctx),
      BattleMoveVisualRecipeId.sdkHammerArm => _sdkHammerArm(ctx),
      BattleMoveVisualRecipeId.sdkIceHammer => _sdkIceHammer(ctx),
      BattleMoveVisualRecipeId.sdkSkyUppercut => _sdkSkyUppercut(ctx),
      BattleMoveVisualRecipeId.sdkNeedleArm => _sdkNeedleArm(ctx),
      BattleMoveVisualRecipeId.sdkRockSmash => _sdkRockSmash(ctx),
      BattleMoveVisualRecipeId.sdkKarateChop => _sdkKarateChop(ctx),
      BattleMoveVisualRecipeId.sdkDrillRun => _sdkDrillRun(ctx),
      BattleMoveVisualRecipeId.sdkThunderbolt => _sdkThunderbolt(ctx),
      BattleMoveVisualRecipeId.sdkChargeBeam => _sdkChargeBeam(ctx),
      BattleMoveVisualRecipeId.sdkHiddenPower => _sdkHiddenPower(ctx),
      BattleMoveVisualRecipeId.sdkElectroBall => _sdkElectroBall(ctx),
      BattleMoveVisualRecipeId.sdkElectricShock => _sdkElectricShock(ctx),
      BattleMoveVisualRecipeId.sdkShadowBall => _sdkShadowBall(ctx),
      BattleMoveVisualRecipeId.sdkDarkPulse => _sdkDarkPulse(ctx),
      BattleMoveVisualRecipeId.sdkAuraSphere => _sdkAuraSphere(ctx),
      BattleMoveVisualRecipeId.sdkBubbleBeam => _sdkBubbleBeam(ctx),
      BattleMoveVisualRecipeId.sdkFireBlast => _sdkFireBlast(ctx),
      BattleMoveVisualRecipeId.sdkBlizzard => _sdkBlizzard(ctx),
      BattleMoveVisualRecipeId.sdkDazzlingGleam => _sdkDazzlingGleam(ctx),
      BattleMoveVisualRecipeId.sdkCalmMind => _sdkCalmMind(ctx),
      BattleMoveVisualRecipeId.sdkSwordsDance => _sdkSwordsDance(ctx),
      BattleMoveVisualRecipeId.sdkAgility => _sdkAgility(ctx),
      BattleMoveVisualRecipeId.sdkBulkUp => _sdkBulkUp(ctx),
      BattleMoveVisualRecipeId.sdkCharm => _sdkCharm(ctx),
      BattleMoveVisualRecipeId.sdkConfuseRay => _sdkConfuseRay(ctx),
      BattleMoveVisualRecipeId.sdkGrowl => _sdkGrowl(ctx),
      BattleMoveVisualRecipeId.sdkTaunt => _sdkTaunt(ctx),
      BattleMoveVisualRecipeId.sdkInstruct => _sdkInstruct(ctx),
      BattleMoveVisualRecipeId.sdkQuash => _sdkQuash(ctx),
      BattleMoveVisualRecipeId.sdkSwagger => _sdkSwagger(ctx),
      BattleMoveVisualRecipeId.sdkEncore => _sdkEncore(ctx),
      BattleMoveVisualRecipeId.sdkBabyDollEyes => _sdkBabyDollEyes(ctx),
      BattleMoveVisualRecipeId.sdkThunderWave => _sdkThunderWave(ctx),
      BattleMoveVisualRecipeId.sdkProtect => _sdkProtect(ctx),
      BattleMoveVisualRecipeId.sdkBurningBulwark => _sdkBurningBulwark(ctx),
      BattleMoveVisualRecipeId.sdkBanefulBunker => _sdkBanefulBunker(ctx),
      BattleMoveVisualRecipeId.sdkReflect => _sdkReflect(ctx),
      BattleMoveVisualRecipeId.sdkLightScreen => _sdkLightScreen(ctx),
      BattleMoveVisualRecipeId.sdkMist => _sdkMist(ctx),
      BattleMoveVisualRecipeId.sdkAuroraVeil => _sdkAuroraVeil(ctx),
      BattleMoveVisualRecipeId.sdkSafeguard => _sdkSafeguard(ctx),
      BattleMoveVisualRecipeId.sdkQuickGuard => _sdkQuickGuard(ctx),
      BattleMoveVisualRecipeId.sdkWideGuard => _sdkWideGuard(ctx),
      BattleMoveVisualRecipeId.sdkTailwind => _sdkTailwind(ctx),
      BattleMoveVisualRecipeId.sdkRainDance => _sdkRainDance(ctx),
      BattleMoveVisualRecipeId.sdkSandstorm => _sdkSandstorm(ctx),
      BattleMoveVisualRecipeId.sdkTrickRoom => _sdkTrickRoom(ctx),
      BattleMoveVisualRecipeId.sdkStealthRock => _sdkStealthRock(ctx),
      BattleMoveVisualRecipeId.sdkSpikes => _sdkSpikes(ctx),
      BattleMoveVisualRecipeId.sdkAquaJet => _sdkAquaJet(ctx),
      BattleMoveVisualRecipeId.sdkExtremeSpeed => _sdkExtremeSpeed(ctx),
      BattleMoveVisualRecipeId.sdkMachPunch => _sdkMachPunch(ctx),
      BattleMoveVisualRecipeId.sdkDoubleKick => _sdkDoubleKick(ctx),
      BattleMoveVisualRecipeId.sdkDualWingBeat => _sdkDualWingBeat(ctx),
      BattleMoveVisualRecipeId.sdkBoneMerang => _sdkBoneMerang(ctx),
      BattleMoveVisualRecipeId.sdkSpark => _sdkSpark(ctx),
      BattleMoveVisualRecipeId.sdkWildCharge => _sdkWildCharge(ctx),
      BattleMoveVisualRecipeId.sdkFlareBlitz => _sdkFlareBlitz(ctx),
      BattleMoveVisualRecipeId.sdkAccelerock => _sdkAccelerock(ctx),
      BattleMoveVisualRecipeId.sdkWickedBlow => _sdkWickedBlow(ctx),
      BattleMoveVisualRecipeId.sdkDoubleHit => _sdkDoubleHit(ctx),
      BattleMoveVisualRecipeId.sdkCrunch => _sdkCrunch(ctx),
      BattleMoveVisualRecipeId.sdkFlamethrower => _sdkFlamethrower(ctx),
      BattleMoveVisualRecipeId.sdkIceBeam => _sdkIceBeam(ctx),
      BattleMoveVisualRecipeId.sdkPsychic => _sdkPsychic(ctx),
      BattleMoveVisualRecipeId.sdkMoonBlast => _sdkMoonBlast(ctx),
      BattleMoveVisualRecipeId.sdkPoisonJab => _sdkPoisonJab(ctx),
      BattleMoveVisualRecipeId.sdkEarthquake => _sdkEarthquake(ctx),
      BattleMoveVisualRecipeId.sdkEnergyBall => _sdkEnergyBall(ctx),
      BattleMoveVisualRecipeId.sdkRockSlide => _sdkRockSlide(ctx),
      BattleMoveVisualRecipeId.sdkNightSlash => _sdkNightSlash(ctx),
      BattleMoveVisualRecipeId.sdkGigaImpact => _sdkGigaImpact(ctx),
      BattleMoveVisualRecipeId.sdkPowerWhip => _sdkPowerWhip(ctx),
      BattleMoveVisualRecipeId.sdkCrabHammer => _sdkCrabHammer(ctx),
      BattleMoveVisualRecipeId.sdkDischarge => _sdkDischarge(ctx),
      BattleMoveVisualRecipeId.sdkSmartStrike => _sdkSmartStrike(ctx),
      BattleMoveVisualRecipeId.sdkMegaHorn => _sdkMegaHorn(ctx),
      BattleMoveVisualRecipeId.sdkDragonClaw => _sdkDragonClaw(ctx),
      BattleMoveVisualRecipeId.sdkPsychoCut => _sdkPsychoCut(ctx),
      BattleMoveVisualRecipeId.sdkWaterPulse => _sdkWaterPulse(ctx),
      BattleMoveVisualRecipeId.sdkPowerGem => _sdkPowerGem(ctx),
      BattleMoveVisualRecipeId.sdkHeatWave => _sdkHeatWave(ctx),
      BattleMoveVisualRecipeId.sdkMuddyWater => _sdkMuddyWater(ctx),
      BattleMoveVisualRecipeId.sdkEarthPower => _sdkEarthPower(ctx),
      BattleMoveVisualRecipeId.sdkBugBuzz => _sdkBugBuzz(ctx),
      BattleMoveVisualRecipeId.sdkHyperVoice => _sdkHyperVoice(ctx),
      BattleMoveVisualRecipeId.sdkFlashCannon => _sdkFlashCannon(ctx),
      BattleMoveVisualRecipeId.sdkDragonPulse => _sdkDragonPulse(ctx),
      BattleMoveVisualRecipeId.sdkSludgeBomb => _sdkSludgeBomb(ctx),
      BattleMoveVisualRecipeId.sdkDoomDesire => _sdkDoomDesire(ctx),
      BattleMoveVisualRecipeId.sdkSeedFlare => _sdkSeedFlare(ctx),
      BattleMoveVisualRecipeId.sdkIcyWind => _sdkIcyWind(ctx),
      BattleMoveVisualRecipeId.sdkWeatherBall => _sdkWeatherBall(ctx),
      BattleMoveVisualRecipeId.sdkFlameBurst => _sdkFlameBurst(ctx),
      BattleMoveVisualRecipeId.sdkWaterSport => _sdkWaterSport(ctx),
      BattleMoveVisualRecipeId.sdkScald => _sdkScald(ctx),
      BattleMoveVisualRecipeId.sdkSteamEruption => _sdkSteamEruption(ctx),
      BattleMoveVisualRecipeId.sdkTriAttack => _sdkTriAttack(ctx),
      BattleMoveVisualRecipeId.sdkClangingScales => _sdkClangingScales(ctx),
      BattleMoveVisualRecipeId.sdkGunkShot => _sdkGunkShot(ctx),
      BattleMoveVisualRecipeId.sdkToxic => _sdkToxic(ctx),
      BattleMoveVisualRecipeId.sdkToxicSpikes => _sdkToxicSpikes(ctx),
      BattleMoveVisualRecipeId.sdkPoisonGas => _sdkPoisonGas(ctx),
      BattleMoveVisualRecipeId.sdkSmog => _sdkSmog(ctx),
      BattleMoveVisualRecipeId.sdkClearSmog => _sdkClearSmog(ctx),
      BattleMoveVisualRecipeId.sdkPoisonFang => _sdkPoisonFang(ctx),
      BattleMoveVisualRecipeId.sdkCrossPoison => _sdkCrossPoison(ctx),
      BattleMoveVisualRecipeId.sdkDireClaw => _sdkDireClaw(ctx),
      BattleMoveVisualRecipeId.sdkMudShot => _sdkMudShot(ctx),
      BattleMoveVisualRecipeId.sdkRockBlast => _sdkRockBlast(ctx),
      BattleMoveVisualRecipeId.sdkMagicalLeaf => _sdkMagicalLeaf(ctx),
      BattleMoveVisualRecipeId.sdkStarVolley => _sdkStarVolley(ctx),
      BattleMoveVisualRecipeId.sdkElectroweb => _sdkElectroweb(ctx),
      BattleMoveVisualRecipeId.sdkBulletSeed => _sdkBulletSeed(ctx),
      BattleMoveVisualRecipeId.sdkSlam => _sdkSlam(ctx),
      BattleMoveVisualRecipeId.sdkSpore => _sdkSpore(ctx),
      BattleMoveVisualRecipeId.sdkPainSplit => _sdkPainSplit(ctx),
      BattleMoveVisualRecipeId.sdkSkillSwap => _sdkSkillSwap(ctx),
      BattleMoveVisualRecipeId.sdkPlayRough => _sdkPlayRough(ctx),
      BattleMoveVisualRecipeId.sdkSurf => _sdkSurf(ctx),
      BattleMoveVisualRecipeId.sdkHydroPump => _sdkHydroPump(ctx),
      BattleMoveVisualRecipeId.sdkLeafBlade => _sdkLeafBlade(ctx),
      BattleMoveVisualRecipeId.sdkXScissor => _sdkXScissor(ctx),
      BattleMoveVisualRecipeId.sdkFireFang => _sdkFireFang(ctx),
      BattleMoveVisualRecipeId.sdkIceFang => _sdkIceFang(ctx),
      BattleMoveVisualRecipeId.sdkThunderFang => _sdkThunderFang(ctx),
      BattleMoveVisualRecipeId.sdkAirSlash => _sdkAirSlash(ctx),
      BattleMoveVisualRecipeId.sdkDracoMeteor => _sdkDracoMeteor(ctx),
      BattleMoveVisualRecipeId.sdkQuiverDance => _sdkQuiverDance(ctx),
      BattleMoveVisualRecipeId.sdkVictoryDance => _sdkVictoryDance(ctx),
      BattleMoveVisualRecipeId.sdkDragonDance => _sdkDragonDance(ctx),
      BattleMoveVisualRecipeId.sdkFeatherDance => _sdkFeatherDance(ctx),
      BattleMoveVisualRecipeId.sdkFocusBlast => _sdkFocusBlast(ctx),
      BattleMoveVisualRecipeId.sdkSpinAttack => _sdkSpinAttack(ctx),
      BattleMoveVisualRecipeId.sdkVoltSwitch => _sdkVoltSwitch(ctx),
      BattleMoveVisualRecipeId.sdkShockWave => _sdkShockWave(ctx),
      BattleMoveVisualRecipeId.sdkExplosion => _sdkExplosion(ctx),
      BattleMoveVisualRecipeId.sdkPopulationBomb => _sdkPopulationBomb(ctx),
      BattleMoveVisualRecipeId.sdkAirCutter => _sdkAirCutter(ctx),
      BattleMoveVisualRecipeId.sdkHurricane => _sdkHurricane(ctx),
      BattleMoveVisualRecipeId.sdkWhirlwind => _sdkWhirlwind(ctx),
      BattleMoveVisualRecipeId.sdkFreezeDry => _sdkFreezeDry(ctx),
      BattleMoveVisualRecipeId.sdkMagmaStorm => _sdkMagmaStorm(ctx),
      BattleMoveVisualRecipeId.sdkOriginPulse => _sdkOriginPulse(ctx),
      BattleMoveVisualRecipeId.sdkPsybeam => _sdkPsybeam(ctx),
      BattleMoveVisualRecipeId.sdkAeroblast => _sdkAeroblast(ctx),
      BattleMoveVisualRecipeId.sdkRoarOfTime => _sdkRoarOfTime(ctx),
      BattleMoveVisualRecipeId.sdkRevelationDance => _sdkRevelationDance(ctx),
      BattleMoveVisualRecipeId.sdkSunnyDay => _sdkSunnyDay(ctx),
      BattleMoveVisualRecipeId.sdkHail => _sdkHail(ctx),
      BattleMoveVisualRecipeId.sdkElectricTerrain => _sdkElectricTerrain(ctx),
      BattleMoveVisualRecipeId.sdkGrassyTerrain => _sdkGrassyTerrain(ctx),
      BattleMoveVisualRecipeId.sdkMistyTerrain => _sdkMistyTerrain(ctx),
      BattleMoveVisualRecipeId.sdkFollowMe => _sdkFollowMe(ctx),
      BattleMoveVisualRecipeId.sdkKinesis => _sdkKinesis(ctx),
      BattleMoveVisualRecipeId.sdkSolarBeam => _sdkSolarBeam(ctx),
      BattleMoveVisualRecipeId.sdkThunder => _sdkThunder(ctx),
      BattleMoveVisualRecipeId.sdkStoredPower => _sdkStoredPower(ctx),
      BattleMoveVisualRecipeId.sdkPsychoBoost => _sdkPsychoBoost(ctx),
      BattleMoveVisualRecipeId.sdkPsyshock => _sdkPsyshock(ctx),
      BattleMoveVisualRecipeId.sdkHex => _sdkHex(ctx),
      BattleMoveVisualRecipeId.sdkWillOWisp => _sdkWillOWisp(ctx),
      BattleMoveVisualRecipeId.sdkLifeDew => _sdkLifeDew(ctx),
      BattleMoveVisualRecipeId.sdkAromatherapy => _sdkAromatherapy(ctx),
      BattleMoveVisualRecipeId.sdkRest => _sdkRest(ctx),
      BattleMoveVisualRecipeId.sdkIngrain => _sdkIngrain(ctx),
      BattleMoveVisualRecipeId.sdkMorningSun => _sdkMorningSun(ctx),
      BattleMoveVisualRecipeId.sdkShoreUp => _sdkShoreUp(ctx),
      BattleMoveVisualRecipeId.sdkDrain => _sdkDrain(ctx),
      BattleMoveVisualRecipeId.sdkLeechLife => _sdkLeechLife(ctx),
      BattleMoveVisualRecipeId.sdkHornLeech => _sdkHornLeech(ctx),
      BattleMoveVisualRecipeId.sdkParabolicCharge => _sdkParabolicCharge(ctx),
      BattleMoveVisualRecipeId.sdkDrainingKiss => _sdkDrainingKiss(ctx),
      BattleMoveVisualRecipeId.sdkOblivionWing => _sdkOblivionWing(ctx),
      BattleMoveVisualRecipeId.sdkLeechSeed => _sdkLeechSeed(ctx),
      BattleMoveVisualRecipeId.sdkHyperBeam => _sdkHyperBeam(ctx),
      BattleMoveVisualRecipeId.sdkSignalBeam => _sdkSignalBeam(ctx),
      BattleMoveVisualRecipeId.sdkFleurCannon => _sdkFleurCannon(ctx),
      BattleMoveVisualRecipeId.sdkArmorCannon => _sdkArmorCannon(ctx),
      BattleMoveVisualRecipeId.sdkSteelBeam => _sdkSteelBeam(ctx),
      BattleMoveVisualRecipeId.sdkBeakBlast => _sdkBeakBlast(ctx),
      BattleMoveVisualRecipeId.sdkTwinBeam => _sdkTwinBeam(ctx),
      BattleMoveVisualRecipeId.sdkSpikeCannon => _sdkSpikeCannon(ctx),
      BattleMoveVisualRecipeId.sdkWaterShuriken => _sdkWaterShuriken(ctx),
      BattleMoveVisualRecipeId.sdkTerastarStorm => _sdkTerastarStorm(ctx),
      BattleMoveVisualRecipeId.sdkMeteorMash => _sdkMeteorMash(ctx),
      BattleMoveVisualRecipeId.sdkSplash => _sdkSplash(ctx),
      BattleMoveVisualRecipeId.sdkCelebrate => _sdkCelebrate(ctx),
      BattleMoveVisualRecipeId.sdkOrderUp => _sdkOrderUp(ctx),
      BattleMoveVisualRecipeId.sdkHeartStamp => _sdkHeartStamp(ctx),
      BattleMoveVisualRecipeId.sdkMatchaGotcha => _sdkMatchaGotcha(ctx),
      BattleMoveVisualRecipeId.sdkPresent => _sdkPresent(ctx),
      BattleMoveVisualRecipeId.sdkPayDay => _sdkPayDay(ctx),
      BattleMoveVisualRecipeId.noAnimation => const <BattleAnimationStep>[
          WaitStep(durationSeconds: 0),
        ],
    };
  }

  List<BattleAnimationStep> _sdkRmxpMoveAnimation(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final defenderSide = ctx.targetSide ?? ctx.attackerSide;
    final reverse = ctx.attackerSide == BattleSideId.enemy;
    final steps = <BattleAnimationStep>[];
    final userAnimationId = ctx.resolvedMove.rmxpUserAnimationId;
    if (userAnimationId != null) {
      final animation = BattleSdkRmxpAnimationCatalog.require(userAnimationId);
      steps.add(
        PlayRmxpAnimationStep(
          animationId: userAnimationId,
          sdkMoveId: ctx.resolvedMove.sdkMoveId,
          subjectSide: ctx.attackerSide,
          attackerSide: ctx.attackerSide,
          defenderSide: defenderSide,
          phase: RmxpPlacementPhase.user,
          placementSpec: RmxpMovePlacementCatalog.resolve(
            sdkMoveId: ctx.resolvedMove.sdkMoveId,
            animationId: userAnimationId,
            phase: RmxpPlacementPhase.user,
            animation: animation,
          ),
          reverse: reverse,
        ),
      );
    }
    final targetAnimationId = ctx.resolvedMove.rmxpTargetAnimationId;
    if (targetAnimationId != null) {
      final animation =
          BattleSdkRmxpAnimationCatalog.require(targetAnimationId);
      steps.add(
        PlayRmxpAnimationStep(
          animationId: targetAnimationId,
          sdkMoveId: ctx.resolvedMove.sdkMoveId,
          subjectSide: defenderSide,
          attackerSide: ctx.attackerSide,
          defenderSide: defenderSide,
          phase: RmxpPlacementPhase.target,
          placementSpec: RmxpMovePlacementCatalog.resolve(
            sdkMoveId: ctx.resolvedMove.sdkMoveId,
            animationId: targetAnimationId,
            phase: RmxpPlacementPhase.target,
            animation: animation,
          ),
          reverse: reverse,
        ),
      );
    }
    return steps.isEmpty
        ? const <BattleAnimationStep>[WaitStep(durationSeconds: 0)]
        : steps;
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

  // Source: Pokemon SDK 5 Battle/20 MoveAnimation/100 AerialAce.rb and
  // sibling exact sprite-sheet scripts.
  List<BattleAnimationStep> _sdkExactSpriteOnTarget(
    BattleMoveVisualRecipeContext ctx,
    String assetId, {
    required double frameSeconds,
    double initialWaitSeconds = 0.10,
    List<int>? frameSequence,
    List<double>? frameDurationsSeconds,
  }) {
    final spec = BattleFxCatalog.require(assetId);
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      WaitStep(durationSeconds: initialWaitSeconds),
      PlaySpriteSheetFxStep(
        assetId: assetId,
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        anchor: BattleVisualAnchor.defenderCenter,
        frameWidth: spec.frameWidth,
        frameHeight: spec.frameHeight,
        frameCount: spec.frameCount,
        frameDurationSeconds: frameSeconds,
        columns: spec.columns,
        originX: spec.originX,
        originY: spec.originY,
        frameSequence: frameSequence,
        frameDurationsSeconds: frameDurationsSeconds,
      ),
    ];
  }

  // Source: Pokemon SDK 5 Battle/20 MoveAnimation/100 AquaRing.rb and
  // 100 AcidArmor.rb; both are anchored on the user sprite.
  List<BattleAnimationStep> _sdkExactSpriteOnUser(
    BattleMoveVisualRecipeContext ctx,
    String assetId, {
    required double frameSeconds,
    List<int>? frameSequence,
    List<double>? frameDurationsSeconds,
  }) {
    final spec = BattleFxCatalog.require(assetId);
    return <BattleAnimationStep>[
      const WaitStep(durationSeconds: 0.10),
      PlaySpriteSheetFxStep(
        assetId: assetId,
        attackerSide: ctx.attackerSide,
        defenderSide: ctx.targetSide ?? ctx.attackerSide,
        anchor: BattleVisualAnchor.attackerCenter,
        frameWidth: spec.frameWidth,
        frameHeight: spec.frameHeight,
        frameCount: spec.frameCount,
        frameDurationSeconds: frameSeconds,
        columns: spec.columns,
        originX: spec.originX,
        originY: spec.originY,
        frameSequence: frameSequence,
        frameDurationsSeconds: frameDurationsSeconds,
      ),
    ];
  }

  // Source: Pokemon SDK 5 Battle/20 MoveAnimation/100 KarateChop.rb.
  List<BattleAnimationStep> _sdkExactKarateChop(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const CameraFocusStep(
        target: BattleCameraFocusTarget.target,
        durationSeconds: 1.10,
      ),
      SdkScalarParticleStep(
        assetId: ctx.attackerSide == BattleSideId.player
            ? 'hand_front_left'
            : 'hand_front_right',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        anchor: BattleVisualAnchor.defenderHead,
        offsetX: ctx.attackerSide == BattleSideId.player ? -16 : 16,
        offsetY: -48,
        endOffsetX: 0,
        endOffsetY: 16,
        startScaleX: 1.0,
        startScaleY: 0.36,
        endScaleX: 0.46,
        endScaleY: 1.12,
        startOpacity: 0.9,
        endOpacity: 0,
        durationSeconds: 0.58,
        rotationTurns: ctx.attackerSide == BattleSideId.player ? 0.08 : -0.08,
      ),
      CombatantCompressStep(
        side: targetSide,
        scaleX: 0.2,
        scaleY: -0.6,
        durationSeconds: 0.30,
      ),
      SdkFallingParticlesStep(
        assetId: 'circle_particle',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        anchor: BattleVisualAnchor.defenderCenter,
        particleCount: 18,
        durationSeconds: 0.34,
        startAreaWidth: 84,
        startOffsetY: -30,
        fallDistanceY: 42,
        driftX: 24,
        startScaleX: 1.0,
        startScaleY: 0.8,
        endScaleX: 0.15,
        endScaleY: 0.15,
        intervalSeconds: 0.012,
        colorArgb: 0xFFFFA638,
      ),
    ];
  }

  // Source: Pokemon SDK 5 Battle/20 MoveAnimation/100 LeechSeed.rb.
  List<BattleAnimationStep> _sdkExactLeechSeed(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      AnimationGroupStep(
        mode: BattleAnimationGroupMode.parallel,
        steps: <BattleAnimationStep>[
          for (var i = 0; i < 6; i++)
            SdkScalarParticleStep(
              assetId: 'seed',
              attackerSide: ctx.attackerSide,
              defenderSide: targetSide,
              anchor: BattleVisualAnchor.attackerHead,
              offsetX: -12 + ((i % 3) * 12),
              offsetY: -10 + ((i % 2) * 8),
              endOffsetX: -32 + ((i % 3) * 32),
              endOffsetY: 10 + ((i % 2) * 18),
              startScaleX: 0.12,
              startScaleY: 0.12,
              endScaleX: 0.85,
              endScaleY: 0.65,
              startOpacity: 1,
              endOpacity: 0,
              delaySeconds: i * 0.08,
              durationSeconds: 0.62,
              rotationTurns: i.isEven ? 0.5 : -0.45,
            ),
          for (final entry in const <({double delay, double offset})>[
            (delay: 0.32, offset: -22),
            (delay: 0.42, offset: 0),
            (delay: 0.52, offset: 22),
          ])
            SdkParticleZoomStep(
              assetId: 'seed_growth',
              attackerSide: ctx.attackerSide,
              defenderSide: targetSide,
              anchor: BattleVisualAnchor.defenderCenter,
              offsetX: entry.offset,
              offsetY: 16,
              startScale: 0.12,
              endScale: 1.05,
              startOpacity: 0,
              endOpacity: 0.95,
              delaySeconds: entry.delay,
              durationSeconds: 0.42,
            ),
        ],
      ),
    ];
  }

  // Source: Pokemon SDK powder scripts share Circle-blurry-M-2 particles.
  List<BattleAnimationStep> _sdkExactPowder(
    BattleMoveVisualRecipeContext ctx, {
    required int colorArgb,
  }) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const CameraFocusStep(
        target: BattleCameraFocusTarget.target,
        durationSeconds: 1.20,
      ),
      SdkFallingParticlesStep(
        assetId: 'circle_blurry_m_2',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        anchor: BattleVisualAnchor.defenderHead,
        particleCount: 24,
        durationSeconds: 0.82,
        startAreaWidth: 144,
        startOffsetY: -92,
        fallDistanceY: 120,
        driftX: 28,
        startScaleX: 0.05,
        startScaleY: 0.08,
        endScaleX: 0.72,
        endScaleY: 0.78,
        intervalSeconds: 0.045,
        colorArgb: colorArgb,
      ),
      CombatantToneStep(
        side: targetSide,
        colorArgb: colorArgb,
        durationSeconds: 1.00,
      ),
      CombatantCompressStep(
        side: targetSide,
        scaleX: -0.2,
        scaleY: 0.2,
        durationSeconds: 0.75,
        iteration: 5,
      ),
    ];
  }

  // Source: Pokemon SDK 5 Battle/20 MoveAnimation/100 Recover.rb.
  List<BattleAnimationStep> _sdkExactRecover(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      const CameraFocusStep(
        target: BattleCameraFocusTarget.user,
        durationSeconds: 1.20,
      ),
      CombatantCompressStep(
        side: ctx.attackerSide,
        scaleX: 0.15,
        scaleY: -0.4,
        durationSeconds: 0.30,
      ),
      AnimationGroupStep(
        mode: BattleAnimationGroupMode.parallel,
        steps: <BattleAnimationStep>[
          SdkRadiusParticleStep(
            assetId: 'circle_blurry_m_2',
            attackerSide: ctx.attackerSide,
            defenderSide: ctx.targetSide ?? ctx.attackerSide,
            anchor: BattleVisualAnchor.attackerCenter,
            particleCount: 18,
            startRadiusPx: 18,
            endRadiusPx: 72,
            durationSeconds: 0.72,
            startScale: 0.05,
            endScale: 0.7,
            intervalSeconds: 0.025,
            colorArgb: 0xFFFFD56B,
          ),
          SdkRadiusParticleStep(
            assetId: 'star_4_ring_l',
            attackerSide: ctx.attackerSide,
            defenderSide: ctx.targetSide ?? ctx.attackerSide,
            anchor: BattleVisualAnchor.attackerHead,
            particleCount: 10,
            startRadiusPx: 14,
            endRadiusPx: 54,
            durationSeconds: 0.58,
            startScale: 0.2,
            endScale: 1.0,
            startAngleTurns: 0.08,
            intervalSeconds: 0.035,
          ),
          SdkParticleZoomStep(
            assetId: 'star_4_ring_l',
            attackerSide: ctx.attackerSide,
            defenderSide: ctx.targetSide ?? ctx.attackerSide,
            anchor: BattleVisualAnchor.attackerHead,
            offsetY: -12,
            startScale: 0.25,
            endScale: 1.15,
            delaySeconds: 0.16,
            durationSeconds: 0.74,
            rotationTurns: 0.33,
          ),
        ],
      ),
    ];
  }

  // Source: Pokemon SDK 5 Battle/20 MoveAnimation/100 Tail_Whip.rb.
  List<BattleAnimationStep> _sdkExactTailWhip(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      CombatantEllipseStep(
        side: ctx.attackerSide,
        radiusX: ctx.attackerSide == BattleSideId.player ? 18 : 11,
        radiusY: ctx.attackerSide == BattleSideId.player ? 9 : -5,
        turns: 2,
        durationSeconds: 1.5,
      ),
    ];
  }

  // Source: Pokemon SDK 5 Battle/20 MoveAnimation/100 Thunder_wave.rb.
  List<BattleAnimationStep> _sdkExactThunderWave(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    final thunder = BattleFxCatalog.require('thunder_02');
    return <BattleAnimationStep>[
      PlaySpriteSheetFxStep(
        assetId: 'thunder_02',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        anchor: BattleVisualAnchor.defenderCenter,
        frameWidth: thunder.frameWidth,
        frameHeight: thunder.frameHeight,
        frameCount: thunder.frameCount,
        frameDurationSeconds: 0.05,
        columns: thunder.columns,
        originX: thunder.originX,
        originY: thunder.originY,
        frameSequence: const <int>[1, 0, 1, 0, 1, 0, 1, 0, 1, 0],
        frameDurationsSeconds: const <double>[
          0.05,
          0.05,
          0.05,
          0.05,
          0.05,
          0.05,
          0.05,
          0.05,
          0.05,
          0.05,
        ],
      ),
    ];
  }

  List<BattleAnimationStep> _sdkTackle(
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

  List<BattleAnimationStep> _sdkScratch(
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

  List<BattleAnimationStep> _sdkQuickAttack(
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

  List<BattleAnimationStep> _sdkSlash(
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

  List<BattleAnimationStep> _sdkAerialAce(
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

  List<BattleAnimationStep> _sdkCloseCombat(
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

  List<BattleAnimationStep> _sdkBodySlam(
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

  List<BattleAnimationStep> _sdkHighJumpKick(
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

  List<BattleAnimationStep> _sdkKarateChop(
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

  List<BattleAnimationStep> _sdkDrillRun(
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

  List<BattleAnimationStep> _sdkThunderbolt(
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

  List<BattleAnimationStep> _sdkHiddenPower(
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

  List<BattleAnimationStep> _sdkChargeBeam(
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

  List<BattleAnimationStep> _sdkShadowBall(
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

  List<BattleAnimationStep> _sdkDarkPulse(
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

  List<BattleAnimationStep> _sdkAuraSphere(
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

  List<BattleAnimationStep> _sdkBubbleBeam(
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

  List<BattleAnimationStep> _sdkFireBlast(
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

  List<BattleAnimationStep> _sdkBlizzard(
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

  List<BattleAnimationStep> _sdkDazzlingGleam(
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

  List<BattleAnimationStep> _sdkCalmMind(
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

  List<BattleAnimationStep> _sdkSwordsDance(
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

  List<BattleAnimationStep> _sdkAgility(
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

  List<BattleAnimationStep> _sdkBulkUp(
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

  List<BattleAnimationStep> _sdkCharm(
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

  List<BattleAnimationStep> _sdkConfuseRay(
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

  List<BattleAnimationStep> _sdkGrowl(
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

  List<BattleAnimationStep> _sdkTaunt(
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

  List<BattleAnimationStep> _sdkInstruct(
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

  List<BattleAnimationStep> _sdkQuash(
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

  List<BattleAnimationStep> _sdkSwagger(
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

  List<BattleAnimationStep> _sdkEncore(
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

  List<BattleAnimationStep> _sdkBabyDollEyes(
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

  List<BattleAnimationStep> _sdkThunderWave(
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

  List<BattleAnimationStep> _sdkProtect(
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

  List<BattleAnimationStep> _sdkBurningBulwark(
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

  List<BattleAnimationStep> _sdkBanefulBunker(
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

  List<BattleAnimationStep> _sdkReflect(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _shieldCast(
      ctx,
      colorArgb: 0xAAA76DFF,
      style: BattleBarrierStyle.reflect,
    );
  }

  List<BattleAnimationStep> _sdkLightScreen(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _shieldCast(
      ctx,
      colorArgb: 0xAA76E8FF,
      style: BattleBarrierStyle.lightScreen,
    );
  }

  List<BattleAnimationStep> _sdkMist(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _shieldCast(
      ctx,
      colorArgb: 0xAA9FD7FF,
      style: BattleBarrierStyle.mist,
    );
  }

  List<BattleAnimationStep> _sdkAuroraVeil(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _shieldCast(
      ctx,
      colorArgb: 0xAACCF7FF,
      style: BattleBarrierStyle.auroraVeil,
    );
  }

  List<BattleAnimationStep> _sdkSafeguard(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _shieldCast(
      ctx,
      colorArgb: 0xAAF7D76E,
      style: BattleBarrierStyle.safeguard,
    );
  }

  List<BattleAnimationStep> _sdkQuickGuard(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _shieldCast(
      ctx,
      colorArgb: 0xAA79FFCF,
      style: BattleBarrierStyle.quickGuard,
    );
  }

  List<BattleAnimationStep> _sdkWideGuard(
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

  List<BattleAnimationStep> _sdkTailwind(
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

  List<BattleAnimationStep> _sdkRainDance(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _sdkDanceCast(
      ctx,
      accentFx: 'waterwisp',
      colorArgb: 0x223EA8FF,
    );
  }

  List<BattleAnimationStep> _sdkSandstorm(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _sdkDanceCast(
      ctx,
      accentFx: 'mudwisp',
      colorArgb: 0x22D2A55A,
    );
  }

  List<BattleAnimationStep> _sdkTrickRoom(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _sdkDanceCast(
      ctx,
      accentFx: 'mistball',
      colorArgb: 0x229A5DFF,
    );
  }

  List<BattleAnimationStep> _sdkDanceCast(
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

  List<BattleAnimationStep> _sdkAquaJet(
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

  List<BattleAnimationStep> _sdkExtremeSpeed(
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

  List<BattleAnimationStep> _sdkMachPunch(
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

  List<BattleAnimationStep> _sdkShadowPunch(
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

  List<BattleAnimationStep> _sdkFocusPunch(
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

  List<BattleAnimationStep> _sdkDrainPunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      ..._sdkMachPunch(ctx),
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

  List<BattleAnimationStep> _sdkDynamicPunch(
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

  List<BattleAnimationStep> _sdkCometPunch(
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

  List<BattleAnimationStep> _sdkMegaPunch(
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

  List<BattleAnimationStep> _sdkPowerUpPunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      ..._sdkMegaPunch(ctx),
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

  List<BattleAnimationStep> _sdkDizzyPunch(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      ..._sdkMegaPunch(ctx),
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

  List<BattleAnimationStep> _sdkJetPunch(
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

  List<BattleAnimationStep> _sdkFirePunch(
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
      ..._sdkMegaPunch(ctx),
    ];
  }

  List<BattleAnimationStep> _sdkIcePunch(
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
      ..._sdkMegaPunch(ctx),
    ];
  }

  List<BattleAnimationStep> _sdkThunderPunch(
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
      ..._sdkMegaPunch(ctx),
    ];
  }

  List<BattleAnimationStep> _sdkBlazeKick(
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

  List<BattleAnimationStep> _sdkThunderousKick(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      ..._sdkDoubleKick(ctx),
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

  List<BattleAnimationStep> _sdkTropKick(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      ..._sdkDoubleKick(ctx),
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

  List<BattleAnimationStep> _sdkWoodHammer(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _cudgelStrike(
      ctx,
      openerEffectIds: const <String>['energyball', 'energyball'],
      accentEffectIds: const <String>['leaf1', 'leaf2', 'leaf2'],
      accentEndScale: 1.8,
    );
  }

  List<BattleAnimationStep> _sdkIvyCudgel(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _cudgelStrike(
      ctx,
      openerEffectIds: const <String>['energyball', 'energyball'],
      accentEffectIds: const <String>['leaf1', 'leaf2', 'leaf2'],
      accentEndScale: 1.25,
    );
  }

  List<BattleAnimationStep> _sdkIvyCudgelWater(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _cudgelStrike(
      ctx,
      openerEffectIds: const <String>['waterwisp', 'waterwisp'],
      accentEffectIds: const <String>['iceball', 'iceball', 'iceball'],
      accentEndScale: 1.25,
    );
  }

  List<BattleAnimationStep> _sdkIvyCudgelFire(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _cudgelStrike(
      ctx,
      openerEffectIds: const <String>['flareball', 'flareball'],
      accentEffectIds: const <String>['fireball', 'fireball', 'fireball'],
      accentEndScale: 1.25,
    );
  }

  List<BattleAnimationStep> _sdkIvyCudgelRock(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _cudgelStrike(
      ctx,
      openerEffectIds: const <String>['mudwisp', 'mudwisp'],
      accentEffectIds: const <String>['rock1', 'rock2', 'rock3'],
      accentEndScale: 1.25,
    );
  }

  List<BattleAnimationStep> _sdkCut(BattleMoveVisualRecipeContext ctx) {
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

  List<BattleAnimationStep> _sdkShadowClaw(
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

  List<BattleAnimationStep> _sdkMultiAttack(
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

  List<BattleAnimationStep> _sdkBite(BattleMoveVisualRecipeContext ctx) {
    return _biteStrike(ctx);
  }

  List<BattleAnimationStep> _sdkSuperFang(
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

  List<BattleAnimationStep> _sdkBugBite(
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

  List<BattleAnimationStep> _sdkPsychicFangs(
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

  List<BattleAnimationStep> _sdkIronHead(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _contactCombo(
      ctx: ctx,
      heavy: true,
    );
  }

  List<BattleAnimationStep> _sdkHeadbutt(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _contactCombo(
      ctx: ctx,
      heavy: true,
    );
  }

  List<BattleAnimationStep> _sdkStomp(BattleMoveVisualRecipeContext ctx) {
    return _contactCombo(
      ctx: ctx,
      heavy: true,
    );
  }

  List<BattleAnimationStep> _sdkHammerArm(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _hammerDropStrike(
      ctx,
      accentEffectId: 'shadowball',
      extraEffectIds: const <String>['wisp', 'wisp'],
      screenColor: null,
    );
  }

  List<BattleAnimationStep> _sdkIceHammer(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _hammerDropStrike(
      ctx,
      accentEffectId: 'iceball',
      extraEffectIds: const <String>['wisp', 'wisp', 'icicle', 'icicle'],
      screenColor: 0x33FFFFFF,
    );
  }

  List<BattleAnimationStep> _sdkSkyUppercut(
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

  List<BattleAnimationStep> _sdkNeedleArm(
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

  List<BattleAnimationStep> _sdkRockSmash(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return <BattleAnimationStep>[
      ..._sdkMegaPunch(ctx),
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

  List<BattleAnimationStep> _sdkDoubleKick(
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

  List<BattleAnimationStep> _sdkDualWingBeat(
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

  List<BattleAnimationStep> _sdkBoneMerang(
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

  List<BattleAnimationStep> _sdkSpark(
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

  List<BattleAnimationStep> _sdkWildCharge(
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

  List<BattleAnimationStep> _sdkFlareBlitz(
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

  List<BattleAnimationStep> _sdkAccelerock(
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

  List<BattleAnimationStep> _sdkWickedBlow(
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

  List<BattleAnimationStep> _sdkDoubleHit(
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

  List<BattleAnimationStep> _sdkCrunch(
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

  List<BattleAnimationStep> _sdkFlamethrower(
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

  List<BattleAnimationStep> _sdkIceBeam(
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

  List<BattleAnimationStep> _sdkPsychic(
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

  List<BattleAnimationStep> _sdkMoonBlast(
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

  List<BattleAnimationStep> _sdkPoisonJab(
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

  List<BattleAnimationStep> _sdkEarthquake(
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

  List<BattleAnimationStep> _sdkEnergyBall(
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

  List<BattleAnimationStep> _sdkRockSlide(
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

  List<BattleAnimationStep> _sdkNightSlash(
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

  List<BattleAnimationStep> _sdkGigaImpact(
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

  List<BattleAnimationStep> _sdkPowerWhip(
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

  List<BattleAnimationStep> _sdkCrabHammer(
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

  List<BattleAnimationStep> _sdkDischarge(
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

  List<BattleAnimationStep> _sdkSmartStrike(
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

  List<BattleAnimationStep> _sdkMegaHorn(
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

  List<BattleAnimationStep> _sdkDragonClaw(
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

  List<BattleAnimationStep> _sdkPsychoCut(
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

  List<BattleAnimationStep> _sdkWaterPulse(
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

  List<BattleAnimationStep> _sdkPowerGem(
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

  List<BattleAnimationStep> _sdkHeatWave(
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

  List<BattleAnimationStep> _sdkMuddyWater(
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

  List<BattleAnimationStep> _sdkEarthPower(
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

  List<BattleAnimationStep> _sdkBugBuzz(
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

  List<BattleAnimationStep> _sdkHyperVoice(
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

  List<BattleAnimationStep> _sdkFlashCannon(
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

  List<BattleAnimationStep> _sdkDragonPulse(
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

  List<BattleAnimationStep> _sdkSludgeBomb(
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

  List<BattleAnimationStep> _sdkMagicalLeaf(
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

  List<BattleAnimationStep> _sdkStarVolley(
    BattleMoveVisualRecipeContext ctx,
  ) {
    const patterns =
        <({String effectId, double toX, double toY, double delay})>[
      (effectId: 'star', toX: -28, toY: -20, delay: 0.00),
      (effectId: 'star_1', toX: 20, toY: -36, delay: 0.04),
      (effectId: 'star', toX: 34, toY: 2, delay: 0.08),
      (effectId: 'star_1', toX: -14, toY: 22, delay: 0.12),
      (effectId: 'star', toX: 10, toY: -10, delay: 0.16),
    ];
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x18FFF3A6,
        durationSeconds: 0.10,
      ),
      for (final pattern in patterns)
        _projectileToTarget(
          ctx,
          effectId: pattern.effectId,
          durationSeconds: 0.30,
          startDelaySeconds: pattern.delay,
          curve: BattleFxMotionCurve.arcOver,
          toOffsetX: pattern.toX,
          toOffsetY: pattern.toY,
          startScale: 0.25,
          endScale: 0.95,
          startOpacity: 0.95,
          endOpacity: 1.0,
          afterEffect: BattleFxAfterEffect.fade,
          playAsAccent: true,
        ),
      CombatantFlashStep(
        side: ctx.targetSide ?? ctx.attackerSide,
        durationSeconds: 0.08,
      ),
    ];
  }

  List<BattleAnimationStep> _sdkElectroweb(
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

  List<BattleAnimationStep> _sdkBulletSeed(
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

  List<BattleAnimationStep> _sdkSlam(
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

  List<BattleAnimationStep> _sdkSpore(
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

  List<BattleAnimationStep> _sdkPainSplit(
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

  List<BattleAnimationStep> _sdkSkillSwap(
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

  List<BattleAnimationStep> _sdkPlayRough(
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

  List<BattleAnimationStep> _sdkSurf(
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

  List<BattleAnimationStep> _sdkHydroPump(
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

  List<BattleAnimationStep> _sdkLeafBlade(
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

  List<BattleAnimationStep> _sdkXScissor(
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

  List<BattleAnimationStep> _sdkFireFang(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _sdkElementalFang(
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

  List<BattleAnimationStep> _sdkIceFang(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _sdkElementalFang(
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

  List<BattleAnimationStep> _sdkThunderFang(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _sdkElementalFang(
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

  List<BattleAnimationStep> _sdkElementalFang(
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

  List<BattleAnimationStep> _sdkAirSlash(
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

  List<BattleAnimationStep> _sdkDracoMeteor(
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

  List<BattleAnimationStep> _sdkQuiverDance(
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

  List<BattleAnimationStep> _sdkVictoryDance(
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

  List<BattleAnimationStep> _sdkDragonDance(
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

  List<BattleAnimationStep> _sdkFeatherDance(
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

  List<BattleAnimationStep> _sdkFocusBlast(
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

  List<BattleAnimationStep> _sdkSpinAttack(
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

  List<BattleAnimationStep> _sdkVoltSwitch(
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

  List<BattleAnimationStep> _sdkShockWave(
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

  List<BattleAnimationStep> _sdkExplosion(
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

  List<BattleAnimationStep> _sdkPopulationBomb(
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

  List<BattleAnimationStep> _sdkAirCutter(
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

  List<BattleAnimationStep> _sdkHurricane(
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

  List<BattleAnimationStep> _sdkWhirlwind(
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

  List<BattleAnimationStep> _sdkFreezeDry(
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

  List<BattleAnimationStep> _sdkMagmaStorm(
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

  List<BattleAnimationStep> _sdkOriginPulse(
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

  List<BattleAnimationStep> _sdkPsybeam(
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

  List<BattleAnimationStep> _sdkAeroblast(
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

  List<BattleAnimationStep> _sdkRoarOfTime(
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

  List<BattleAnimationStep> _sdkRevelationDance(
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

  List<BattleAnimationStep> _sdkSunnyDay(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _sdkDanceCast(
      ctx,
      accentFx: 'fireball',
      colorArgb: 0x33F7A11A,
    );
  }

  List<BattleAnimationStep> _sdkHail(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _sdkDanceCast(
      ctx,
      accentFx: 'iceball',
      colorArgb: 0x33C7E7FF,
    );
  }

  List<BattleAnimationStep> _sdkElectricTerrain(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _sdkDanceCast(
      ctx,
      accentFx: 'electroball',
      colorArgb: 0x33FFFF00,
    );
  }

  List<BattleAnimationStep> _sdkGrassyTerrain(
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

  List<BattleAnimationStep> _sdkMistyTerrain(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _sdkDanceCast(
      ctx,
      accentFx: 'mistball',
      colorArgb: 0x33FF99FF,
    );
  }

  List<BattleAnimationStep> _sdkFollowMe(
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

  List<BattleAnimationStep> _sdkKinesis(
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

  List<BattleAnimationStep> _sdkSolarBeam(
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

  List<BattleAnimationStep> _sdkThunder(
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

  List<BattleAnimationStep> _sdkStoredPower(
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

  List<BattleAnimationStep> _sdkPsychoBoost(
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

  List<BattleAnimationStep> _sdkPsyshock(
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

  List<BattleAnimationStep> _sdkHex(
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

  List<BattleAnimationStep> _sdkWillOWisp(
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

  List<BattleAnimationStep> _sdkLifeDew(
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

  List<BattleAnimationStep> _sdkAromatherapy(
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

  List<BattleAnimationStep> _sdkRest(
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

  List<BattleAnimationStep> _sdkIngrain(
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

  List<BattleAnimationStep> _sdkMorningSun(
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

  List<BattleAnimationStep> _sdkShoreUp(
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

  List<BattleAnimationStep> _sdkDrain(
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

  List<BattleAnimationStep> _sdkLeechLife(
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

  List<BattleAnimationStep> _sdkHornLeech(
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

  List<BattleAnimationStep> _sdkParabolicCharge(
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

  List<BattleAnimationStep> _sdkDrainingKiss(
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

  List<BattleAnimationStep> _sdkOblivionWing(
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

  List<BattleAnimationStep> _sdkLeechSeed(
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

  List<BattleAnimationStep> _sdkHyperBeam(
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

  List<BattleAnimationStep> _sdkSignalBeam(
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

  List<BattleAnimationStep> _sdkFleurCannon(
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

  List<BattleAnimationStep> _sdkArmorCannon(
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

  List<BattleAnimationStep> _sdkSteelBeam(
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

  List<BattleAnimationStep> _sdkBeakBlast(
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

  List<BattleAnimationStep> _sdkTwinBeam(
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

  List<BattleAnimationStep> _sdkSpikeCannon(
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

  List<BattleAnimationStep> _sdkWaterShuriken(
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

  List<BattleAnimationStep> _sdkTerastarStorm(
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

  List<BattleAnimationStep> _sdkMeteorMash(
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

  List<BattleAnimationStep> _sdkStealthRock(
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

  List<BattleAnimationStep> _sdkSpikes(
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

  List<BattleAnimationStep> _sdkDoomDesire(
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

  List<BattleAnimationStep> _sdkSeedFlare(
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

  List<BattleAnimationStep> _sdkIcyWind(
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

  List<BattleAnimationStep> _sdkWeatherBall(
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

  List<BattleAnimationStep> _sdkFlameBurst(
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

  List<BattleAnimationStep> _sdkWaterSport(
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

  List<BattleAnimationStep> _sdkScald(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      ..._sdkWaterSport(ctx),
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

  List<BattleAnimationStep> _sdkSteamEruption(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x330000DD,
        durationSeconds: 0.14,
      ),
      ..._sdkWaterSport(ctx),
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

  List<BattleAnimationStep> _sdkTriAttack(
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

  List<BattleAnimationStep> _sdkClangingScales(
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

  List<BattleAnimationStep> _sdkGunkShot(
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

  List<BattleAnimationStep> _sdkToxic(
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

  List<BattleAnimationStep> _sdkToxicSpikes(
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

  List<BattleAnimationStep> _sdkPoisonGas(
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

  List<BattleAnimationStep> _sdkSmog(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _sdkSmogBase(ctx, effectId: 'poisonwisp');
  }

  List<BattleAnimationStep> _sdkClearSmog(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _sdkSmogBase(ctx, effectId: 'wisp');
  }

  List<BattleAnimationStep> _sdkPoisonFang(
    BattleMoveVisualRecipeContext ctx,
  ) {
    return _sdkElementalFang(
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

  List<BattleAnimationStep> _sdkCrossPoison(
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

  List<BattleAnimationStep> _sdkDireClaw(
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

  List<BattleAnimationStep> _sdkSmogBase(
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

  List<BattleAnimationStep> _sdkMudShot(
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

  List<BattleAnimationStep> _sdkElectroBall(
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

  List<BattleAnimationStep> _sdkElectricShock(
    BattleMoveVisualRecipeContext ctx,
  ) {
    final targetSide = ctx.targetSide ?? ctx.attackerSide;
    final thunder = BattleFxCatalog.require('thunder_02');
    return <BattleAnimationStep>[
      const ScreenFlashStep(
        colorArgb: 0x22FFF06A,
        durationSeconds: 0.08,
      ),
      PlaySpriteSheetFxStep(
        assetId: 'thunder_02',
        attackerSide: ctx.attackerSide,
        defenderSide: targetSide,
        anchor: BattleVisualAnchor.defenderCenter,
        frameWidth: thunder.frameWidth,
        frameHeight: thunder.frameHeight,
        frameCount: thunder.frameCount,
        frameDurationSeconds: 0.04,
        columns: thunder.columns,
        originX: thunder.originX,
        originY: thunder.originY,
        frameSequence: const <int>[1, 0, 1, 0, 1, 0],
        frameDurationsSeconds: const <double>[
          0.04,
          0.04,
          0.04,
          0.04,
          0.04,
          0.04,
        ],
      ),
      _targetFx(
        ctx,
        effectId: 'shock_1',
        durationSeconds: 0.18,
        startScale: 0.35,
        endScale: 0.55,
        startOpacity: 0.75,
        endOpacity: 0.0,
        afterEffect: BattleFxAfterEffect.fade,
      ),
      CombatantToneStep(
        side: targetSide,
        colorArgb: 0xCCFFF06A,
        durationSeconds: 0.18,
      ),
      CombatantShakeStep(
        side: targetSide,
        amplitudePx: 4,
        durationSeconds: 0.12,
      ),
    ];
  }

  List<BattleAnimationStep> _sdkRockBlast(
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

  List<BattleAnimationStep> _sdkSplash(
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

  List<BattleAnimationStep> _sdkCelebrate(
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

  List<BattleAnimationStep> _sdkOrderUp(
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

  List<BattleAnimationStep> _sdkHeartStamp(
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

  List<BattleAnimationStep> _sdkMatchaGotcha(
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

  List<BattleAnimationStep> _sdkPresent(
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

  List<BattleAnimationStep> _sdkPayDay(
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
