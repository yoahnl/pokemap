import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_recipe_library.dart';

BattleMoveVisualRecipeContext _seededContext(
  BattleMoveVisualRecipeId recipeId,
) {
  const move = BattleMove(
    id: 'seeded_move',
    name: 'Seeded Move',
    power: 90,
    type: 'normal',
    category: BattleMoveCategory.special,
    target: BattleMoveTarget.opponent,
  );
  return BattleMoveVisualRecipeContext(
    resolvedMove: BattleResolvedMoveVisual(
      localMoveId: 'seeded_move',
      sdkMoveId: 'seededmove',
      recipeId: recipeId,
      usesFallback: false,
      canonicalMove: null,
    ),
    battleMove: move,
    execution: null,
    attackerSide: BattleSideId.player,
    targetSide: BattleSideId.enemy,
    damage: 24,
    didHit: true,
    didCrit: false,
  );
}

int _countFx(List<BattleAnimationStep> steps, String effectId) {
  return steps
      .whereType<SpawnFxStep>()
      .where((step) => step.effectId == effectId)
      .length;
}

void main() {
  group('BattleMoveVisual seeded recipes', () {
    test('tackle follows a pure contact pattern without projectile fx', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkTackle,
        _seededContext(BattleMoveVisualRecipeId.sdkTackle),
      );

      final plan = BattleAnimationPlan(steps: steps);
      expect(plan.requiredFxIds, isEmpty);
      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.lunge),
      );
      expect(steps.whereType<CombatantFlashStep>(), isNotEmpty);
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('scratch uses a slash overlay after a contact approach', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkScratch,
        _seededContext(BattleMoveVisualRecipeId.sdkScratch),
      );

      final slashes = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'rightslash')
          .toList();
      expect(slashes, hasLength(1));
      expect(steps.whereType<CombatantMotionStep>(), isNotEmpty);
      expect(steps.whereType<CombatantFlashStep>(), isNotEmpty);
    });

    test('quick attack uses a fast dash plus two wisp bursts on the target',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkQuickAttack,
        _seededContext(BattleMoveVisualRecipeId.sdkQuickAttack),
      );

      final wisps = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'wisp')
          .toList();
      expect(wisps, hasLength(2));
      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.fastDash),
      );
      expect(steps.whereType<CombatantFlashStep>(), isNotEmpty);
    });

    test('thunderbolt uses defender lightning bursts like the SDK recipe', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkThunderbolt,
        _seededContext(BattleMoveVisualRecipeId.sdkThunderbolt),
      );

      final plan = BattleAnimationPlan(steps: steps);
      expect(plan.requiredFxIds, contains('lightning'));
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'lightning'),
        hasLength(3),
      );
      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('shadow ball charges before launching the orb', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkShadowBall,
        _seededContext(BattleMoveVisualRecipeId.sdkShadowBall),
      );

      final plan = BattleAnimationPlan(steps: steps);
      expect(plan.requiredFxIds,
          containsAll(<String>['poisonwisp', 'shadowball']));
      expect(steps.whereType<WaitStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'shadowball')
            .length,
        greaterThanOrEqualTo(2),
      );
    });

    test('aura sphere builds a charge phase and an impact phase', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkAuraSphere,
        _seededContext(BattleMoveVisualRecipeId.sdkAuraSphere),
      );

      final plan = BattleAnimationPlan(steps: steps);
      expect(plan.requiredFxIds, containsAll(<String>['wisp', 'iceball']));
      expect(
        steps.whereType<ScreenFlashStep>().length,
        greaterThanOrEqualTo(2),
      );
      expect(steps.whereType<WaitStep>(), isNotEmpty);
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('close combat layers fists and impact accents around the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkCloseCombat,
        _seededContext(BattleMoveVisualRecipeId.sdkCloseCombat),
      );

      final plan = BattleAnimationPlan(steps: steps);
      expect(plan.requiredFxIds, containsAll(<String>['fist', 'impact']));
      expect(steps.whereType<CombatantMotionStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'fist')
            .length,
        greaterThanOrEqualTo(4),
      );
    });

    test('stealth rock throws multiple rock projectiles into the hazard line',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkStealthRock,
        _seededContext(BattleMoveVisualRecipeId.sdkStealthRock),
      );

      final plan = BattleAnimationPlan(steps: steps);
      expect(plan.requiredFxIds, containsAll(<String>['rock1', 'rock2']));
      expect(steps.whereType<SpawnFxStep>(), hasLength(4));
    });

    test('spikes places a three-caltrop volley', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSpikes,
        _seededContext(BattleMoveVisualRecipeId.sdkSpikes),
      );

      final plan = BattleAnimationPlan(steps: steps);
      expect(plan.requiredFxIds, contains('caltrop'));
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'caltrop'),
        hasLength(3),
      );
    });

    test('growl uses repeated sound wisps centered on the attacker', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkGrowl,
        _seededContext(BattleMoveVisualRecipeId.sdkGrowl),
      );

      final soundBursts = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'wisp')
          .toList();
      expect(soundBursts, hasLength(3));
      expect(
        soundBursts.every(
          (step) =>
              step.attackerSide == BattleSideId.player &&
              step.defenderSide == BattleSideId.player &&
              step.from == BattleVisualAnchor.attackerCenter &&
              step.to == BattleVisualAnchor.attackerCenter,
        ),
        isTrue,
      );
    });

    test('thunder wave pulses around the attacker then tags the defender', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkThunderWave,
        _seededContext(BattleMoveVisualRecipeId.sdkThunderWave),
      );

      final electricBursts = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'electroball')
          .toList();
      expect(electricBursts, hasLength(3));
      expect(
        electricBursts.take(2).every(
              (step) => step.defenderSide == BattleSideId.player,
            ),
        isTrue,
      );
      expect(electricBursts.last.defenderSide, equals(BattleSideId.enemy));
    });

    test('quiver dance swirls three wisps around the user', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkQuiverDance,
        _seededContext(BattleMoveVisualRecipeId.sdkQuiverDance),
      );

      final wisps = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'wisp')
          .toList();
      expect(wisps, hasLength(3));
      expect(
        wisps.every((step) => step.defenderSide == BattleSideId.player),
        isTrue,
      );
    });

    test('focus blast builds a charge orb then detonates on the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkFocusBlast,
        _seededContext(BattleMoveVisualRecipeId.sdkFocusBlast),
      );

      final electroballs = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'electroball')
          .toList();
      expect(electroballs.length, greaterThanOrEqualTo(4));
      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('volt switch sends an electroball into the defender then blooms', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkVoltSwitch,
        _seededContext(BattleMoveVisualRecipeId.sdkVoltSwitch),
      );

      final electroballs = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'electroball')
          .toList();
      expect(electroballs.length, greaterThanOrEqualTo(3));
      expect(steps.whereType<CombatantFlashStep>(), isNotEmpty);
    });

    test('explosion bursts from the attacker with multiple fireballs', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkExplosion,
        _seededContext(BattleMoveVisualRecipeId.sdkExplosion),
      );

      final fireballs = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'fireball')
          .toList();
      expect(fireballs.length, greaterThanOrEqualTo(3));
      expect(
        fireballs.every((step) => step.defenderSide == BattleSideId.player),
        isTrue,
      );
    });

    test('hurricane surrounds the target with repeated wind wisps', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkHurricane,
        _seededContext(BattleMoveVisualRecipeId.sdkHurricane),
      );

      final wisps = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'wisp')
          .toList();
      expect(wisps.length, greaterThanOrEqualTo(6));
      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('sunny day and hail use distinct weather accents around the user', () {
      final sunny = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSunnyDay,
        _seededContext(BattleMoveVisualRecipeId.sdkSunnyDay),
      );
      final hail = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkHail,
        _seededContext(BattleMoveVisualRecipeId.sdkHail),
      );

      expect(
        sunny
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'fireball'),
        hasLength(2),
      );
      expect(
        hail
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'iceball'),
        hasLength(2),
      );
    });

    test('terrain casts keep dance-like motion with colored accent effects',
        () {
      final electric = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkElectricTerrain,
        _seededContext(BattleMoveVisualRecipeId.sdkElectricTerrain),
      );
      final grassy = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkGrassyTerrain,
        _seededContext(BattleMoveVisualRecipeId.sdkGrassyTerrain),
      );
      final misty = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkMistyTerrain,
        _seededContext(BattleMoveVisualRecipeId.sdkMistyTerrain),
      );

      expect(
        electric
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(2),
      );
      expect(
        grassy
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'leaf1'),
        hasLength(2),
      );
      expect(
        misty
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'mistball'),
        hasLength(2),
      );
    });

    test('follow me keeps the pointer centered on the attacker', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkFollowMe,
        _seededContext(BattleMoveVisualRecipeId.sdkFollowMe),
      );

      final pointers = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'pointer')
          .toList();
      expect(pointers, hasLength(1));
      expect(
        pointers.single.defenderSide,
        equals(BattleSideId.player),
      );
    });

    test('solar beam charges and then projects multiple energy orbs forward',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSolarBeam,
        _seededContext(BattleMoveVisualRecipeId.sdkSolarBeam),
      );

      final energy = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'energyball')
          .toList();
      expect(energy.length, greaterThanOrEqualTo(4));
      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
    });

    test('thunder crashes repeated lightning down onto the defender', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkThunder,
        _seededContext(BattleMoveVisualRecipeId.sdkThunder),
      );

      final lightning = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'lightning')
          .toList();
      expect(lightning.length, greaterThanOrEqualTo(2));
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('stored power swirls multiple poison wisps around the attacker', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkStoredPower,
        _seededContext(BattleMoveVisualRecipeId.sdkStoredPower),
      );

      final wisps = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'poisonwisp')
          .toList();
      expect(wisps, hasLength(8));
      expect(
        wisps.every((step) => step.defenderSide == BattleSideId.player),
        isTrue,
      );
    });

    test('psychoboost charges mistball and poisonwisp before detonating', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPsychoBoost,
        _seededContext(BattleMoveVisualRecipeId.sdkPsychoBoost),
      );

      final mistballs = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'mistball')
          .toList();
      final wisps = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'poisonwisp')
          .toList();
      expect(mistballs.length, greaterThanOrEqualTo(4));
      expect(wisps.length, greaterThanOrEqualTo(3));
      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
    });

    test('psyshock bursts psychic energy directly on the defender', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPsyshock,
        _seededContext(BattleMoveVisualRecipeId.sdkPsyshock),
      );

      final poisonWisps = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'poisonwisp')
          .toList();
      final waterWisps = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'waterwisp')
          .toList();
      expect(poisonWisps, hasLength(2));
      expect(waterWisps, hasLength(1));
      expect(
        poisonWisps.every((step) => step.defenderSide == BattleSideId.enemy),
        isTrue,
      );
    });

    test('hex stacks poison wisps with blue ghost fire over the defender', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkHex,
        _seededContext(BattleMoveVisualRecipeId.sdkHex),
      );

      final poisonWisps = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'poisonwisp')
          .toList();
      final blueFire = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'bluefireball')
          .toList();
      expect(poisonWisps, hasLength(3));
      expect(blueFire, hasLength(3));
      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
    });

    test('will-o-wisp sends blue ghost fire to the target in three beats', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkWillOWisp,
        _seededContext(BattleMoveVisualRecipeId.sdkWillOWisp),
      );

      final blueFire = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'bluefireball')
          .toList();
      expect(blueFire, hasLength(3));
      expect(
        blueFire.first.from,
        equals(BattleVisualAnchor.attackerCenter),
      );
      expect(
        blueFire.last.to,
        equals(BattleVisualAnchor.defenderCenter),
      );
    });

    test('life dew throws repeated healing iceballs from the user', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkLifeDew,
        _seededContext(BattleMoveVisualRecipeId.sdkLifeDew),
      );

      final iceballs = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'iceball')
          .toList();
      expect(iceballs, hasLength(4));
      expect(
        iceballs.every((step) => step.defenderSide == BattleSideId.enemy),
        isTrue,
      );
    });

    test(
        'protect uses self-status wisps and leaves the barrier overlay to field events',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkProtect,
        _seededContext(BattleMoveVisualRecipeId.sdkProtect),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
      expect(steps.whereType<BarrierPulseStep>(), isEmpty);
    });

    test('burning bulwark blooms two fire shields and a toxic ember', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkBurningBulwark,
        _seededContext(BattleMoveVisualRecipeId.sdkBurningBulwark),
      );

      expect(
        steps.whereType<ScreenFlashStep>(),
        isNotEmpty,
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'flareball'),
        hasLength(2),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        hasLength(1),
      );
      expect(steps.whereType<BarrierPulseStep>(), isEmpty);
    });

    test('baneful bunker blooms shadow shields and a toxic core', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkBanefulBunker,
        _seededContext(BattleMoveVisualRecipeId.sdkBanefulBunker),
      );

      expect(
        steps.whereType<ScreenFlashStep>(),
        isNotEmpty,
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'shadowball'),
        hasLength(2),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        hasLength(1),
      );
      expect(steps.whereType<BarrierPulseStep>(), isEmpty);
    });

    test(
        'rain dance, sandstorm and trick room each animate the user before field effects',
        () {
      final rain = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkRainDance,
        _seededContext(BattleMoveVisualRecipeId.sdkRainDance),
      );
      final sand = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSandstorm,
        _seededContext(BattleMoveVisualRecipeId.sdkSandstorm),
      );
      final trick = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkTrickRoom,
        _seededContext(BattleMoveVisualRecipeId.sdkTrickRoom),
      );

      expect(rain.whereType<CombatantShakeStep>(), isNotEmpty);
      expect(sand.whereType<CombatantShakeStep>(), isNotEmpty);
      expect(trick.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('side-condition shields use native barrier pulses instead of png fx',
        () {
      final recipeLibrary = BattleMoveVisualRecipeLibrary();
      final reflect = recipeLibrary.build(
        BattleMoveVisualRecipeId.sdkReflect,
        _seededContext(BattleMoveVisualRecipeId.sdkReflect),
      );
      final lightScreen = recipeLibrary.build(
        BattleMoveVisualRecipeId.sdkLightScreen,
        _seededContext(BattleMoveVisualRecipeId.sdkLightScreen),
      );
      final mist = recipeLibrary.build(
        BattleMoveVisualRecipeId.sdkMist,
        _seededContext(BattleMoveVisualRecipeId.sdkMist),
      );
      final auroraVeil = recipeLibrary.build(
        BattleMoveVisualRecipeId.sdkAuroraVeil,
        _seededContext(BattleMoveVisualRecipeId.sdkAuroraVeil),
      );

      expect(
        reflect.whereType<BarrierPulseStep>().single.style,
        equals(BattleBarrierStyle.reflect),
      );
      expect(
        lightScreen.whereType<BarrierPulseStep>().single.style,
        equals(BattleBarrierStyle.lightScreen),
      );
      expect(
        mist.whereType<BarrierPulseStep>().single.style,
        equals(BattleBarrierStyle.mist),
      );
      expect(
        auroraVeil.whereType<BarrierPulseStep>().single.style,
        equals(BattleBarrierStyle.auroraVeil),
      );
      expect(BattleAnimationPlan(steps: reflect).requiredFxIds, isEmpty);
      expect(BattleAnimationPlan(steps: lightScreen).requiredFxIds, isEmpty);
      expect(BattleAnimationPlan(steps: mist).requiredFxIds, isEmpty);
      expect(BattleAnimationPlan(steps: auroraVeil).requiredFxIds, isEmpty);
    });

    test('aqua jet adds water wisps to a fast dash contact pattern', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkAquaJet,
        _seededContext(BattleMoveVisualRecipeId.sdkAquaJet),
      );

      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.fastDash),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'waterwisp'),
        hasLength(greaterThanOrEqualTo(3)),
      );
    });

    test('extreme speed stacks several impacts around a fast dash strike', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkExtremeSpeed,
        _seededContext(BattleMoveVisualRecipeId.sdkExtremeSpeed),
      );

      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.fastDash),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'impact'),
        hasLength(greaterThanOrEqualTo(3)),
      );
    });

    test('mach punch keeps the fast-attack body line and adds a fist accent',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkMachPunch,
        _seededContext(BattleMoveVisualRecipeId.sdkMachPunch),
      );

      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.fastDash),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'fist'),
        hasLength(1),
      );
    });

    test('generic punch keeps the contact lunge simple and stable', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.genericPunch,
        _seededContext(BattleMoveVisualRecipeId.genericPunch),
      );

      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.lunge),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'fist'),
        hasLength(1),
      );
      expect(steps.whereType<CombatantFlashStep>(), isNotEmpty);
    });

    test('shadow punch adds a dark flash with two wisps and a fist impact', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkShadowPunch,
        _seededContext(BattleMoveVisualRecipeId.sdkShadowPunch),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'fist'),
        hasLength(1),
      );
    });

    test('focus punch layers two impacts before the fist lands', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkFocusPunch,
        _seededContext(BattleMoveVisualRecipeId.sdkFocusPunch),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'impact'),
        hasLength(2),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'fist'),
        hasLength(1),
      );
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('drain punch keeps the punch finish and returns three drain orbs', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkDrainPunch,
        _seededContext(BattleMoveVisualRecipeId.sdkDrainPunch),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(3),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'fist'),
        hasLength(1),
      );
    });

    test('dynamic punch detonates with three fireballs around the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkDynamicPunch,
        _seededContext(BattleMoveVisualRecipeId.sdkDynamicPunch),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'fireball'),
        hasLength(3),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'fist'),
        hasLength(1),
      );
    });

    test('comet punch repeats two quick fist accents', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkCometPunch,
        _seededContext(BattleMoveVisualRecipeId.sdkCometPunch),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'fist'),
        hasLength(2),
      );
      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.fastDash),
      );
    });

    test('mega punch keeps one heavy fist and one impact ring', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkMegaPunch,
        _seededContext(BattleMoveVisualRecipeId.sdkMegaPunch),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'fist'),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'impact'),
        hasLength(1),
      );
    });

    test('power-up punch adds a self charge orb after the hit', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPowerUpPunch,
        _seededContext(BattleMoveVisualRecipeId.sdkPowerUpPunch),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(1),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'fist'),
        hasLength(1),
      );
    });

    test('dizzy punch trails two wisps after the heavy hit', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkDizzyPunch,
        _seededContext(BattleMoveVisualRecipeId.sdkDizzyPunch),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
      expect(steps.whereType<CombatantShakeStep>(), hasLength(2));
    });

    test('jet punch carries one fist through a six-wisp water burst', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkJetPunch,
        _seededContext(BattleMoveVisualRecipeId.sdkJetPunch),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'waterwisp'),
        hasLength(6),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'fist'),
        hasLength(1),
      );
    });

    test('elemental punches keep their elemental burst signatures', () {
      final firePunch = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkFirePunch,
        _seededContext(BattleMoveVisualRecipeId.sdkFirePunch),
      );
      final icePunch = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkIcePunch,
        _seededContext(BattleMoveVisualRecipeId.sdkIcePunch),
      );
      final thunderPunch = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkThunderPunch,
        _seededContext(BattleMoveVisualRecipeId.sdkThunderPunch),
      );

      expect(
        firePunch
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'fireball'),
        hasLength(2),
      );
      expect(
        icePunch
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'icicle'),
        hasLength(2),
      );
      expect(
        thunderPunch
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(1),
      );
      expect(
        thunderPunch
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'lightning'),
        hasLength(1),
      );
    });

    test('blaze kick keeps the two fireball setup before the foot strike', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkBlazeKick,
        _seededContext(BattleMoveVisualRecipeId.sdkBlazeKick),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'fireball'),
        hasLength(2),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'foot'),
        hasLength(1),
      );
    });

    test('thunderous kick blooms into a five-lightning electric burst', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkThunderousKick,
        _seededContext(BattleMoveVisualRecipeId.sdkThunderousKick),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(2),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'lightning'),
        hasLength(5),
      );
    });

    test('trop kick blooms into a five-petal burst with two seed orbs', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkTropKick,
        _seededContext(BattleMoveVisualRecipeId.sdkTropKick),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'energyball'),
        hasLength(2),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'petal'),
        hasLength(5),
      );
    });

    test('dual wingbeat hits twice with feather accents', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkDualWingBeat,
        _seededContext(BattleMoveVisualRecipeId.sdkDualWingBeat),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'feather'),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(steps.whereType<CombatantFlashStep>().length,
          greaterThanOrEqualTo(1));
    });

    test('bonemerang throws two bone projectiles across the lane', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkBoneMerang,
        _seededContext(BattleMoveVisualRecipeId.sdkBoneMerang),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'bone'),
        hasLength(2),
      );
      expect(
        steps.whereType<SpawnFxStep>().every(
              (step) => step.curve == BattleFxMotionCurve.arcUnder,
            ),
        isTrue,
      );
    });

    test('spark mixes a short electric burst into a contact finish', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSpark,
        _seededContext(BattleMoveVisualRecipeId.sdkSpark),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(greaterThanOrEqualTo(1)),
      );
      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.lunge),
      );
    });

    test('wild charge layers electric bursts around a fast dash impact', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkWildCharge,
        _seededContext(BattleMoveVisualRecipeId.sdkWildCharge),
      );

      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.fastDash),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'lightning'),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(greaterThanOrEqualTo(2)),
      );
    });

    test('flare blitz uses repeated fire bursts around a fast dash impact', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkFlareBlitz,
        _seededContext(BattleMoveVisualRecipeId.sdkFlareBlitz),
      );

      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.fastDash),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'fireball'),
        hasLength(greaterThanOrEqualTo(2)),
      );
    });

    test('accelerock adds a rock burst on top of a fast attack impact', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkAccelerock,
        _seededContext(BattleMoveVisualRecipeId.sdkAccelerock),
      );

      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.fastDash),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'rock3'),
        hasLength(greaterThanOrEqualTo(3)),
      );
    });

    test('wicked blow darkens the screen around a fist-led fast strike', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkWickedBlow,
        _seededContext(BattleMoveVisualRecipeId.sdkWickedBlow),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'fist'),
        hasLength(1),
      );
    });

    test('double hit repeats compact impact accents around the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkDoubleHit,
        _seededContext(BattleMoveVisualRecipeId.sdkDoubleHit),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'impact'),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(steps.whereType<WaitStep>(), isNotEmpty);
    });

    test('crunch layers bite jaws with a dark accent around the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkCrunch,
        _seededContext(BattleMoveVisualRecipeId.sdkCrunch),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'topbite'),
        hasLength(1),
      );
      expect(
        steps.whereType<SpawnFxStep>().where(
              (step) => step.effectId == 'bottombite',
            ),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'blackwisp'),
        isNotEmpty,
      );
    });

    test('flamethrower chains repeated fireballs through the lane', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkFlamethrower,
        _seededContext(BattleMoveVisualRecipeId.sdkFlamethrower),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'fireball'),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'flareball'),
        hasLength(1),
      );
      expect(steps.whereType<WaitStep>(), isNotEmpty);
    });

    test('ice beam mixes iceball travel and icicle accents on impact', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkIceBeam,
        _seededContext(BattleMoveVisualRecipeId.sdkIceBeam),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'iceball'),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'icicle'),
        isNotEmpty,
      );
    });

    test('psychic uses mind pressure accents rather than a plain projectile',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPsychic,
        _seededContext(BattleMoveVisualRecipeId.sdkPsychic),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'stare'),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'pointer'),
        hasLength(greaterThanOrEqualTo(2)),
      );
    });

    test('earthquake drives repeated ground bursts and target shake', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkEarthquake,
        _seededContext(BattleMoveVisualRecipeId.sdkEarthquake),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'mudwisp'),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
      expect(steps.whereType<WaitStep>(), isNotEmpty);
    });

    test('energy ball charges then launches the green orb forward', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkEnergyBall,
        _seededContext(BattleMoveVisualRecipeId.sdkEnergyBall),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'energyball'),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'shine'),
        isNotEmpty,
      );
    });

    test('night slash mixes a dark flash with multiple slash accents', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkNightSlash,
        _seededContext(BattleMoveVisualRecipeId.sdkNightSlash),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'blackwisp'),
        isNotEmpty,
      );
      expect(
        steps.whereType<SpawnFxStep>().where(
              (step) =>
                  step.effectId == 'leftslash' || step.effectId == 'rightslash',
            ),
        hasLength(greaterThanOrEqualTo(2)),
      );
    });

    test('giga impact commits to a heavy fast dash and oversized impact', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkGigaImpact,
        _seededContext(BattleMoveVisualRecipeId.sdkGigaImpact),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.fastDash),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'impact'),
        hasLength(greaterThanOrEqualTo(1)),
      );
    });

    test('power whip drives leaf accents into a contact finish', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPowerWhip,
        _seededContext(BattleMoveVisualRecipeId.sdkPowerWhip),
      );

      expect(
        steps.whereType<SpawnFxStep>().where(
              (step) => step.effectId == 'leaf1' || step.effectId == 'leaf2',
            ),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(steps.whereType<CombatantMotionStep>(), isNotEmpty);
    });

    test('crabhammer mixes water bursts and claw accents', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkCrabHammer,
        _seededContext(BattleMoveVisualRecipeId.sdkCrabHammer),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'waterwisp'),
        isNotEmpty,
      );
      expect(
        steps.whereType<SpawnFxStep>().where(
              (step) =>
                  step.effectId == 'leftclaw' || step.effectId == 'rightclaw',
            ),
        hasLength(greaterThanOrEqualTo(1)),
      );
    });

    test('discharge blooms repeated electric bursts over the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkDischarge,
        _seededContext(BattleMoveVisualRecipeId.sdkDischarge),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'lightning'),
        isNotEmpty,
      );
    });

    test('smart strike keeps a sharp sword-led contact line', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSmartStrike,
        _seededContext(BattleMoveVisualRecipeId.sdkSmartStrike),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'sword'),
        hasLength(greaterThanOrEqualTo(1)),
      );
      expect(steps.whereType<CombatantMotionStep>(), isNotEmpty);
    });

    test('megahorn keeps a heavy rushing line with claw-like impact accents',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkMegaHorn,
        _seededContext(BattleMoveVisualRecipeId.sdkMegaHorn),
      );

      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.fastDash),
      );
      expect(
        steps.whereType<SpawnFxStep>().where(
              (step) =>
                  step.effectId == 'leftclaw' || step.effectId == 'rightclaw',
            ),
        hasLength(greaterThanOrEqualTo(1)),
      );
    });

    test('dragon claw layers paired claw cuts on the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkDragonClaw,
        _seededContext(BattleMoveVisualRecipeId.sdkDragonClaw),
      );

      expect(
        steps.whereType<SpawnFxStep>().where(
              (step) =>
                  step.effectId == 'leftclaw' || step.effectId == 'rightclaw',
            ),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
    });

    test('psycho cut mixes a psychic flash with a sharp slash accent', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPsychoCut,
        _seededContext(BattleMoveVisualRecipeId.sdkPsychoCut),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'pointer'),
        isNotEmpty,
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'rightslash'),
        hasLength(1),
      );
    });

    test('water pulse launches a water orb then ripples over the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkWaterPulse,
        _seededContext(BattleMoveVisualRecipeId.sdkWaterPulse),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'waterwisp'),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
    });

    test('power gem launches a jewel-like rock burst into the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPowerGem,
        _seededContext(BattleMoveVisualRecipeId.sdkPowerGem),
      );

      expect(
        steps.whereType<SpawnFxStep>().where(
              (step) =>
                  step.effectId == 'rock1' ||
                  step.effectId == 'rock2' ||
                  step.effectId == 'rock3',
            ),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
    });

    test('heat wave spreads repeated fire bursts across the target lane', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkHeatWave,
        _seededContext(BattleMoveVisualRecipeId.sdkHeatWave),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'fireball'),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
    });

    test('muddy water mixes water and mud wisps around the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkMuddyWater,
        _seededContext(BattleMoveVisualRecipeId.sdkMuddyWater),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'waterwisp'),
        isNotEmpty,
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'mudwisp'),
        isNotEmpty,
      );
    });

    test('earth power erupts the ground under the defender', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkEarthPower,
        _seededContext(BattleMoveVisualRecipeId.sdkEarthPower),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'mudwisp'),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('bug buzz uses web-like and buzzing pulses on the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkBugBuzz,
        _seededContext(BattleMoveVisualRecipeId.sdkBugBuzz),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'web'),
        isNotEmpty,
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        isNotEmpty,
      );
    });

    test('play rough mixes fist, foot, mud wisps and hearts on the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPlayRough,
        _seededContext(BattleMoveVisualRecipeId.sdkPlayRough),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'fist'),
        hasLength(1),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'foot'),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'mudwisp'),
        hasLength(greaterThanOrEqualTo(3)),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'heart'),
        hasLength(greaterThanOrEqualTo(2)),
      );
    });

    test('surf throws a three-lane water swell and shakes the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSurf,
        _seededContext(BattleMoveVisualRecipeId.sdkSurf),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'waterwisp'),
        hasLength(3),
      );
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('hydro pump uses a focused hydroshot lane and a strong target shake',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkHydroPump,
        _seededContext(BattleMoveVisualRecipeId.sdkHydroPump),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'waterwisp'),
        hasLength(3),
      );
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('leaf blade layers leaves, green energy, and paired slash cuts', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkLeafBlade,
        _seededContext(BattleMoveVisualRecipeId.sdkLeafBlade),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'energyball'),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(
        steps.whereType<SpawnFxStep>().where(
              (step) => step.effectId == 'leaf1' || step.effectId == 'leaf2',
            ),
        hasLength(greaterThanOrEqualTo(4)),
      );
      expect(
        steps.whereType<SpawnFxStep>().where(
              (step) =>
                  step.effectId == 'leftslash' || step.effectId == 'rightslash',
            ),
        hasLength(2),
      );
    });

    test('x-scissor draws a crossing pair of slash impacts', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkXScissor,
        _seededContext(BattleMoveVisualRecipeId.sdkXScissor),
      );

      expect(
        steps.whereType<SpawnFxStep>().where(
              (step) =>
                  step.effectId == 'leftslash' || step.effectId == 'rightslash',
            ),
        hasLength(greaterThanOrEqualTo(3)),
      );
      expect(steps.whereType<CombatantMotionStep>(), isNotEmpty);
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('elemental fang recipes keep bite jaws plus their elemental accent',
        () {
      final fire = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkFireFang,
        _seededContext(BattleMoveVisualRecipeId.sdkFireFang),
      );
      final ice = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkIceFang,
        _seededContext(BattleMoveVisualRecipeId.sdkIceFang),
      );
      final thunder = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkThunderFang,
        _seededContext(BattleMoveVisualRecipeId.sdkThunderFang),
      );

      for (final steps in <List<BattleAnimationStep>>[fire, ice, thunder]) {
        expect(
          steps.whereType<SpawnFxStep>().where(
                (step) => step.effectId == 'topbite',
              ),
          hasLength(1),
        );
        expect(
          steps.whereType<SpawnFxStep>().where(
                (step) => step.effectId == 'bottombite',
              ),
          hasLength(1),
        );
      }

      expect(
        fire
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'fireball'),
        hasLength(2),
      );
      expect(
        ice.whereType<SpawnFxStep>().where((step) => step.effectId == 'icicle'),
        hasLength(2),
      );
      expect(
        thunder.whereType<SpawnFxStep>().where(
              (step) =>
                  step.effectId == 'electroball' ||
                  step.effectId == 'lightning',
            ),
        hasLength(greaterThanOrEqualTo(2)),
      );
    });

    test('air slash sweeps repeated wisps diagonally across the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkAirSlash,
        _seededContext(BattleMoveVisualRecipeId.sdkAirSlash),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(4),
      );
      expect(steps.whereType<CombatantFlashStep>(), isNotEmpty);
    });

    test('draco meteor rains flareballs, rocks and a dark impact core', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkDracoMeteor,
        _seededContext(BattleMoveVisualRecipeId.sdkDracoMeteor),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'flareball'),
        hasLength(3),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'rock3'),
        hasLength(3),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'shadowball'),
        isNotEmpty,
      );
    });

    test('hyper voice expands repeated sound rings around the attacker', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkHyperVoice,
        _seededContext(BattleMoveVisualRecipeId.sdkHyperVoice),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'iceball'),
        hasLength(3),
      );
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('flash cannon mixes bright wisps and water wisps into a beam lane',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkFlashCannon,
        _seededContext(BattleMoveVisualRecipeId.sdkFlashCannon),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'waterwisp'),
        hasLength(2),
      );
    });

    test('dragon pulse builds a pulse lane then launches repeated shadow orbs',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkDragonPulse,
        _seededContext(BattleMoveVisualRecipeId.sdkDragonPulse),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(greaterThanOrEqualTo(3)),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        hasLength(greaterThanOrEqualTo(3)),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'shadowball'),
        hasLength(greaterThanOrEqualTo(3)),
      );
    });

    test('sludge bomb hurls three poison bursts with ballistic spread', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSludgeBomb,
        _seededContext(BattleMoveVisualRecipeId.sdkSludgeBomb),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        hasLength(3),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .every((step) => step.curve == BattleFxMotionCurve.arcUnder),
        isTrue,
      );
    });

    test('magical leaf fans repeated leaves into the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkMagicalLeaf,
        _seededContext(BattleMoveVisualRecipeId.sdkMagicalLeaf),
      );

      expect(
        steps.whereType<SpawnFxStep>().where(
              (step) => step.effectId == 'leaf1' || step.effectId == 'leaf2',
            ),
        hasLength(6),
      );
    });

    test('electroweb throws repeated web projectiles into the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkElectroweb,
        _seededContext(BattleMoveVisualRecipeId.sdkElectroweb),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'web'),
        hasLength(3),
      );
    });

    test('bullet seed uses two rapid seed-like energy shots', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkBulletSeed,
        _seededContext(BattleMoveVisualRecipeId.sdkBulletSeed),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'energyball'),
        hasLength(2),
      );
      expect(steps.whereType<WaitStep>(), isNotEmpty);
    });

    test('slam keeps a heavy body-check line with impact confirmation', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSlam,
        _seededContext(BattleMoveVisualRecipeId.sdkSlam),
      );

      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.lunge),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'impact'),
        isNotEmpty,
      );
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('body slam throws twin wisps into a heavy body-check impact', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkBodySlam,
        _seededContext(BattleMoveVisualRecipeId.sdkBodySlam),
      );

      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.lunge),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'impact'),
        hasLength(1),
      );
    });

    test('high jump kick keeps a fast kick line with a foot accent', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkHighJumpKick,
        _seededContext(BattleMoveVisualRecipeId.sdkHighJumpKick),
      );

      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.fastDash),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'foot'),
        hasLength(1),
      );
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('karate chop layers a chop arc over a contact strike', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkKarateChop,
        _seededContext(BattleMoveVisualRecipeId.sdkKarateChop),
      );

      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.lunge),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'rightchop'),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'impact'),
        hasLength(1),
      );
    });

    test('drill run tunnels into the target with twin wisps and an impact', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkDrillRun,
        _seededContext(BattleMoveVisualRecipeId.sdkDrillRun),
      );

      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.lunge),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'impact'),
        hasLength(1),
      );
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('gunk shot hurls repeated poison bursts onto the target lane', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkGunkShot,
        _seededContext(BattleMoveVisualRecipeId.sdkGunkShot),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        hasLength(4),
      );
    });

    test('mud shot throws a muddy triple burst across the target lane', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkMudShot,
        _seededContext(BattleMoveVisualRecipeId.sdkMudShot),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'mudwisp'),
        hasLength(3),
      );
    });

    test('electro ball launches a single orb and rocks the defender', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkElectroBall,
        _seededContext(BattleMoveVisualRecipeId.sdkElectroBall),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(1),
      );
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('rock blast slings a single exploding rock into the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkRockBlast,
        _seededContext(BattleMoveVisualRecipeId.sdkRockBlast),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'rock3'),
        hasLength(1),
      );
    });

    test('whirlwind surrounds the target with repeated wind wisps', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkWhirlwind,
        _seededContext(BattleMoveVisualRecipeId.sdkWhirlwind),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(12),
      );
    });

    test('freeze dry throws a four-icicle volley with a cold follow-up', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkFreezeDry,
        _seededContext(BattleMoveVisualRecipeId.sdkFreezeDry),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'icicle'),
        hasLength(4),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        isNotEmpty,
      );
    });

    test('magma storm rings the target with repeated fireballs', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkMagmaStorm,
        _seededContext(BattleMoveVisualRecipeId.sdkMagmaStorm),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'fireball'),
        hasLength(greaterThanOrEqualTo(4)),
      );
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('origin pulse charges then throws a triple water burst', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkOriginPulse,
        _seededContext(BattleMoveVisualRecipeId.sdkOriginPulse),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'iceball'),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'waterwisp'),
        hasLength(3),
      );
    });

    test('psybeam alternates mistball and poisonwisp down the lane', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPsybeam,
        _seededContext(BattleMoveVisualRecipeId.sdkPsybeam),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'mistball'),
        hasLength(2),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        hasLength(2),
      );
    });

    test('aeroblast builds a wind trail before ice impacts land', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkAeroblast,
        _seededContext(BattleMoveVisualRecipeId.sdkAeroblast),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(greaterThanOrEqualTo(5)),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'iceball'),
        hasLength(greaterThanOrEqualTo(4)),
      );
    });

    test('roar of time charges with giant iceballs then detonates on target',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkRoarOfTime,
        _seededContext(BattleMoveVisualRecipeId.sdkRoarOfTime),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'iceball'),
        hasLength(3),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) {
          return step.effectId == 'poisonwisp' || step.effectId == 'waterwisp';
        }),
        hasLength(greaterThanOrEqualTo(3)),
      );
    });

    test('revelation dance builds four electro notes before the impact bloom',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkRevelationDance,
        _seededContext(BattleMoveVisualRecipeId.sdkRevelationDance),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(4),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(greaterThanOrEqualTo(2)),
      );
    });

    test('aromatherapy wraps the user in soothing wisps', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkAromatherapy,
        _seededContext(BattleMoveVisualRecipeId.sdkAromatherapy),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
    });

    test('rest lifts two wisps behind the attacker', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkRest,
        _seededContext(BattleMoveVisualRecipeId.sdkRest),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
    });

    test('ingrain seeds the user with layered leaves', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkIngrain,
        _seededContext(BattleMoveVisualRecipeId.sdkIngrain),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'leaf1'),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'leaf2'),
        hasLength(1),
      );
    });

    test('morning sun combines a warm flash with falling wisps', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkMorningSun,
        _seededContext(BattleMoveVisualRecipeId.sdkMorningSun),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
    });

    test('shore up uses earthy healing accents around the user', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkShoreUp,
        _seededContext(BattleMoveVisualRecipeId.sdkShoreUp),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'mudwisp'),
        hasLength(2),
      );
    });

    test('drain throws green siphon bursts back toward the attacker', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkDrain,
        _seededContext(BattleMoveVisualRecipeId.sdkDrain),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'energyball'),
        hasLength(3),
      );
    });

    test('leech life bursts a wisp before draining electroballs home', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkLeechLife,
        _seededContext(BattleMoveVisualRecipeId.sdkLeechLife),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(3),
      );
    });

    test('horn leech lunges in, blooms wisps, then draws energy back', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkHornLeech,
        _seededContext(BattleMoveVisualRecipeId.sdkHornLeech),
      );

      expect(steps.whereType<CombatantMotionStep>(), isNotEmpty);
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'energyball'),
        hasLength(3),
      );
    });

    test('parabolic charge collapses two electro rings around the user', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkParabolicCharge,
        _seededContext(BattleMoveVisualRecipeId.sdkParabolicCharge),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(2),
      );
    });

    test('draining kiss sends three mistballs back to the user', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkDrainingKiss,
        _seededContext(BattleMoveVisualRecipeId.sdkDrainingKiss),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'mistball'),
        hasLength(3),
      );
    });

    test('oblivion wing layers a dark screen with flare and black wisps', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkOblivionWing,
        _seededContext(BattleMoveVisualRecipeId.sdkOblivionWing),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'flareball'),
        hasLength(3),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'blackwisp'),
        hasLength(4),
      );
    });

    test('leech seed peppers the target with three seeded energyballs', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkLeechSeed,
        _seededContext(BattleMoveVisualRecipeId.sdkLeechSeed),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'energyball'),
        hasLength(3),
      );
    });

    test('hyper beam chains six electro shots into twin shadowball blooms', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkHyperBeam,
        _seededContext(BattleMoveVisualRecipeId.sdkHyperBeam),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(6),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'shadowball'),
        hasLength(2),
      );
    });

    test('signal beam alternates energy and electric pulses down the lane', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSignalBeam,
        _seededContext(BattleMoveVisualRecipeId.sdkSignalBeam),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'energyball'),
        hasLength(3),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(1),
      );
    });

    test('fleur cannon peppers the target with a pink mistball volley', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkFleurCannon,
        _seededContext(BattleMoveVisualRecipeId.sdkFleurCannon),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'mistball'),
        hasLength(5),
      );
    });

    test('armor cannon charges flare cores before the main blast', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkArmorCannon,
        _seededContext(BattleMoveVisualRecipeId.sdkArmorCannon),
      );

      expect(steps.whereType<ScreenFlashStep>(),
          hasLength(greaterThanOrEqualTo(2)));
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'flareball'),
        hasLength(greaterThanOrEqualTo(3)),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        isNotEmpty,
      );
    });

    test('steel beam launches a triple steel-like ice volley', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSteelBeam,
        _seededContext(BattleMoveVisualRecipeId.sdkSteelBeam),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'iceball'),
        hasLength(3),
      );
    });

    test('beak blast stores four fireballs before the detonation bloom', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkBeakBlast,
        _seededContext(BattleMoveVisualRecipeId.sdkBeakBlast),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'fireball'),
        hasLength(4),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'flareball'),
        hasLength(1),
      );
    });

    test('twin beam alternates psychic and toxic pulses six times', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkTwinBeam,
        _seededContext(BattleMoveVisualRecipeId.sdkTwinBeam),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'mistball'),
        hasLength(3),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        hasLength(3),
      );
    });

    test('spike cannon fires a tight double electro burst', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSpikeCannon,
        _seededContext(BattleMoveVisualRecipeId.sdkSpikeCannon),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(2),
      );
    });

    test('hidden power radiates eight electro orbs around the attacker', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkHiddenPower,
        _seededContext(BattleMoveVisualRecipeId.sdkHiddenPower),
      );

      final orbs = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'electroball')
          .toList();
      expect(orbs, hasLength(8));
      expect(
        orbs.every((step) => step.defenderSide == BattleSideId.player),
        isTrue,
      );
      expect(steps.whereType<CombatantFlashStep>(), isEmpty);
    });

    test('watershuriken mixes three water blooms with three icicle strikes',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkWaterShuriken,
        _seededContext(BattleMoveVisualRecipeId.sdkWaterShuriken),
      );

      expect(_countFx(steps, 'waterwisp'), equals(3));
      expect(_countFx(steps, 'icicle'), equals(3));
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('slash keeps the sdk slashattack feel with a fast dash cut', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSlash,
        _seededContext(BattleMoveVisualRecipeId.sdkSlash),
      );

      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.fastDash),
      );
      expect(_countFx(steps, 'rightslash'), equals(1));
      expect(steps.whereType<CombatantFlashStep>(), isNotEmpty);
    });

    test('terastar storm lifts a star core before six rainbow impacts', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkTerastarStorm,
        _seededContext(BattleMoveVisualRecipeId.sdkTerastarStorm),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(6),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'iceball'),
        hasLength(1),
      );
    });

    test('meteor mash rushes in under a space flash before shadow impact', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkMeteorMash,
        _seededContext(BattleMoveVisualRecipeId.sdkMeteorMash),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps.whereType<CombatantMotionStep>().single.motionKind,
        equals(BattleCombatantMotionKind.fastDash),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'shadowball'),
        hasLength(1),
      );
    });

    test('toxic throws a single ballistic poison wisp onto the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkToxic,
        _seededContext(BattleMoveVisualRecipeId.sdkToxic),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        hasLength(1),
      );
    });

    test('toxic spikes plants two poison caltrops on the defender side', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkToxicSpikes,
        _seededContext(BattleMoveVisualRecipeId.sdkToxicSpikes),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisoncaltrop'),
        hasLength(2),
      );
    });

    test('poison gas drops three poison wisps over the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPoisonGas,
        _seededContext(BattleMoveVisualRecipeId.sdkPoisonGas),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        hasLength(3),
      );
    });

    test('smog layers three inbound and three lingering poison wisps', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSmog,
        _seededContext(BattleMoveVisualRecipeId.sdkSmog),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        hasLength(6),
      );
    });

    test('clear smog mirrors smog with neutral wisps instead of poison', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkClearSmog,
        _seededContext(BattleMoveVisualRecipeId.sdkClearSmog),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(6),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        isEmpty,
      );
    });

    test('poison fang stacks bite jaws with two toxic blooms', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPoisonFang,
        _seededContext(BattleMoveVisualRecipeId.sdkPoisonFang),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'topbite'),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'bottombite'),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        hasLength(2),
      );
    });

    test('cross poison crosses slash accents with a toxic burst', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkCrossPoison,
        _seededContext(BattleMoveVisualRecipeId.sdkCrossPoison),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'leftslash'),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'rightslash'),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        hasLength(1),
      );
    });

    test('dire claw adds a toxic bloom to a paired claw strike', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkDireClaw,
        _seededContext(BattleMoveVisualRecipeId.sdkDireClaw),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'leftclaw'),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'rightclaw'),
        hasLength(1),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        hasLength(1),
      );
    });

    test('spore rains poison wisps down onto the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSpore,
        _seededContext(BattleMoveVisualRecipeId.sdkSpore),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'poisonwisp'),
        hasLength(3),
      );
      expect(
        steps.whereType<SpawnFxStep>().every(
              (step) => step.from == BattleVisualAnchor.defenderHead,
            ),
        isTrue,
      );
    });

    test('pain split mirrors repeated wisps on both battlers', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPainSplit,
        _seededContext(BattleMoveVisualRecipeId.sdkPainSplit),
      );

      final wisps = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'wisp')
          .toList();
      expect(wisps, hasLength(4));
      expect(steps.whereType<WaitStep>(), hasLength(1));
      expect(wisps[0].defenderSide, equals(BattleSideId.player));
      expect(wisps[1].defenderSide, equals(BattleSideId.enemy));
      expect(wisps[0].durationSeconds, closeTo(0.30, 0.001));
      expect(wisps[1].durationSeconds, closeTo(0.30, 0.001));
      expect(wisps[2].startDelaySeconds, closeTo(0.20, 0.001));
      expect(wisps[3].startDelaySeconds, closeTo(0.20, 0.001));
    });

    test('skill swap trades repeated wisps between attacker and defender', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSkillSwap,
        _seededContext(BattleMoveVisualRecipeId.sdkSkillSwap),
      );

      final wisps = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'wisp')
          .toList();
      expect(wisps, hasLength(4));
      expect(wisps.every((step) => step.playAsAccent), isTrue);
      expect(
        wisps.map((step) => step.startDelaySeconds),
        orderedEquals(<double>[0.0, 0.2, 0.2, 0.4]),
      );
      expect(
        wisps.take(2).every(
              (step) => step.curve == BattleFxMotionCurve.arcUnder,
            ),
        isTrue,
      );
      expect(
        wisps.skip(2).every(
              (step) => step.curve == BattleFxMotionCurve.arcOver,
            ),
        isTrue,
      );
      expect(wisps.take(2).every((step) => step.fromOffsetY == -30), isTrue);
    });

    test('doom desire charges a psychic core before the delayed hit lands', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkDoomDesire,
        _seededContext(BattleMoveVisualRecipeId.sdkDoomDesire),
      );

      final flashes = steps.whereType<ScreenFlashStep>().toList();
      expect(flashes, hasLength(2));
      expect(steps.whereType<SpawnFxStep>(), isEmpty);
      expect(flashes.first.colorArgb, equals(0x33000000));
      expect(flashes.last.colorArgb, equals(0x4D000000));
    });

    test('seed flare fans repeated leaves into a bright burst', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSeedFlare,
        _seededContext(BattleMoveVisualRecipeId.sdkSeedFlare),
      );

      final plan = BattleAnimationPlan(steps: steps);
      expect(plan.requiredFxIds, containsAll(<String>['energyball', 'wisp']));
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'energyball'),
        hasLength(2),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(6),
      );
    });

    test('icy wind throws a short iceball volley with a cold shake', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkIcyWind,
        _seededContext(BattleMoveVisualRecipeId.sdkIcyWind),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(4),
      );
      expect(
        steps.whereType<WaitStep>(),
        hasLength(3),
      );
    });

    test('weather ball keeps a compact projectile lane', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkWeatherBall,
        _seededContext(BattleMoveVisualRecipeId.sdkWeatherBall),
      );

      final plan = BattleAnimationPlan(steps: steps);
      expect(plan.requiredFxIds, contains('iceball'));
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'iceball'),
        hasLength(2),
      );
      expect(steps.whereType<CombatantFlashStep>(), isNotEmpty);
    });

    test('scald pushes repeated water wisps through the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkScald,
        _seededContext(BattleMoveVisualRecipeId.sdkScald),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'waterwisp'),
        hasLength(4),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(4),
      );
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('tri attack splits into elemental shots across the lane', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkTriAttack,
        _seededContext(BattleMoveVisualRecipeId.sdkTriAttack),
      );

      final plan = BattleAnimationPlan(steps: steps);
      expect(
        plan.requiredFxIds,
        containsAll(<String>['flareball', 'iceball', 'electroball']),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'flareball'),
        hasLength(2),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'iceball'),
        hasLength(2),
      );
      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'electroball'),
        hasLength(2),
      );
    });

    test('clanging scales rings the user with repeated impact beats', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkClangingScales,
        _seededContext(BattleMoveVisualRecipeId.sdkClangingScales),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'shadowball'),
        hasLength(5),
      );
      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('flame burst blooms a short fireball burst with a flare finish', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkFlameBurst,
        _seededContext(BattleMoveVisualRecipeId.sdkFlameBurst),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'flareball'),
        hasLength(2),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(1),
      );
      expect(steps.whereType<CombatantFlashStep>(), isNotEmpty);
    });

    test('steam eruption drives a heavier water burst into the defender', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSteamEruption,
        _seededContext(BattleMoveVisualRecipeId.sdkSteamEruption),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'waterwisp'),
        hasLength(4),
      );
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(4),
      );
      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('water sport keeps the user wrapped in a small water aura', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkWaterSport,
        _seededContext(BattleMoveVisualRecipeId.sdkWaterSport),
      );

      expect(
        steps
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'waterwisp'),
        hasLength(4),
      );
      expect(steps.whereType<WaitStep>(), hasLength(3));
    });

    test('wood hammer and ivy cudgel keep the leaf-hammer signature', () {
      final woodHammer = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkWoodHammer,
        _seededContext(BattleMoveVisualRecipeId.sdkWoodHammer),
      );
      final ivyCudgel = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkIvyCudgel,
        _seededContext(BattleMoveVisualRecipeId.sdkIvyCudgel),
      );
      final ivyCudgelWater = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkIvyCudgelWater,
        _seededContext(BattleMoveVisualRecipeId.sdkIvyCudgelWater),
      );
      final ivyCudgelFire = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkIvyCudgelFire,
        _seededContext(BattleMoveVisualRecipeId.sdkIvyCudgelFire),
      );
      final ivyCudgelRock = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkIvyCudgelRock,
        _seededContext(BattleMoveVisualRecipeId.sdkIvyCudgelRock),
      );

      for (final steps in <List<BattleAnimationStep>>[
        woodHammer,
        ivyCudgel,
      ]) {
        expect(_countFx(steps, 'energyball'), 2);
        expect(
          _countFx(steps, 'leaf1') + _countFx(steps, 'leaf2'),
          3,
        );
      }

      expect(_countFx(ivyCudgelWater, 'waterwisp'), 2);
      expect(_countFx(ivyCudgelWater, 'iceball'), 3);
      expect(_countFx(ivyCudgelFire, 'flareball'), 2);
      expect(_countFx(ivyCudgelFire, 'fireball'), 3);
      expect(_countFx(ivyCudgelRock, 'mudwisp'), 2);
      expect(
        _countFx(ivyCudgelRock, 'rock1') +
            _countFx(ivyCudgelRock, 'rock2') +
            _countFx(ivyCudgelRock, 'rock3'),
        3,
      );
    });

    test('slash and claw routes keep their dark impact accents', () {
      final cut = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkCut,
        _seededContext(BattleMoveVisualRecipeId.sdkCut),
      );
      final shadowClaw = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkShadowClaw,
        _seededContext(BattleMoveVisualRecipeId.sdkShadowClaw),
      );
      final multiAttack = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkMultiAttack,
        _seededContext(BattleMoveVisualRecipeId.sdkMultiAttack),
      );

      expect(
        cut
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'leftslash'),
        hasLength(1),
      );
      expect(
        shadowClaw
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'leftclaw'),
        hasLength(1),
      );
      expect(
        shadowClaw
            .whereType<SpawnFxStep>()
            .where((step) => step.effectId == 'rightclaw'),
        hasLength(1),
      );
      expect(shadowClaw.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(_countFx(multiAttack, 'flareball'), 1);
      expect(_countFx(multiAttack, 'leftslash'), 1);
      expect(_countFx(multiAttack, 'rightslash'), 1);
    });

    test('bite and fang routes keep the jaw family with a psychic accent', () {
      final bite = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkBite,
        _seededContext(BattleMoveVisualRecipeId.sdkBite),
      );
      final superFang = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSuperFang,
        _seededContext(BattleMoveVisualRecipeId.sdkSuperFang),
      );
      final bugBite = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkBugBite,
        _seededContext(BattleMoveVisualRecipeId.sdkBugBite),
      );
      final psychicFangs = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPsychicFangs,
        _seededContext(BattleMoveVisualRecipeId.sdkPsychicFangs),
      );

      for (final steps in <List<BattleAnimationStep>>[
        bite,
        superFang,
        bugBite
      ]) {
        expect(_countFx(steps, 'topbite'), 1);
        expect(_countFx(steps, 'bottombite'), 1);
      }
      expect(_countFx(psychicFangs, 'topbite'), 1);
      expect(_countFx(psychicFangs, 'bottombite'), 1);
      expect(_countFx(psychicFangs, 'pointer'), greaterThanOrEqualTo(1));
    });

    test('head impact and heavy fist routes stay grounded in contact beats',
        () {
      final ironHead = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkIronHead,
        _seededContext(BattleMoveVisualRecipeId.sdkIronHead),
      );
      final headbutt = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkHeadbutt,
        _seededContext(BattleMoveVisualRecipeId.sdkHeadbutt),
      );
      final stomp = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkStomp,
        _seededContext(BattleMoveVisualRecipeId.sdkStomp),
      );
      final hammerArm = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkHammerArm,
        _seededContext(BattleMoveVisualRecipeId.sdkHammerArm),
      );
      final iceHammer = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkIceHammer,
        _seededContext(BattleMoveVisualRecipeId.sdkIceHammer),
      );
      final skyUppercut = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSkyUppercut,
        _seededContext(BattleMoveVisualRecipeId.sdkSkyUppercut),
      );
      final needleArm = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkNeedleArm,
        _seededContext(BattleMoveVisualRecipeId.sdkNeedleArm),
      );
      final rockSmash = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkRockSmash,
        _seededContext(BattleMoveVisualRecipeId.sdkRockSmash),
      );

      for (final steps in <List<BattleAnimationStep>>[
        ironHead,
        headbutt,
        stomp
      ]) {
        expect(
          steps.whereType<CombatantMotionStep>().single.motionKind,
          equals(BattleCombatantMotionKind.lunge),
        );
        expect(_countFx(steps, 'impact'), 1);
      }

      for (final steps in <List<BattleAnimationStep>>[
        hammerArm,
        iceHammer,
        skyUppercut,
      ]) {
        expect(_countFx(steps, 'fist'), 1);
        expect(_countFx(steps, 'impact'), 1);
      }

      expect(_countFx(iceHammer, 'iceball'), 1);
      expect(_countFx(needleArm, 'rightslash'), 1);
      expect(_countFx(needleArm, 'impact'), 1);
      expect(_countFx(rockSmash, 'rock3'), 1);
      expect(_countFx(rockSmash, 'impact'), 1);
    });

    test('splash throws three water wisps around the attacker only', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSplash,
        _seededContext(BattleMoveVisualRecipeId.sdkSplash),
      );

      final splashes = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'waterwisp')
          .toList();
      expect(splashes, hasLength(3));
      expect(
        splashes.every((step) => step.defenderSide == BattleSideId.player),
        isTrue,
      );
    });

    test('celebrate builds a self-only festive shine dance', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkCelebrate,
        _seededContext(BattleMoveVisualRecipeId.sdkCelebrate),
      );

      expect(_countFx(steps, 'shine'), equals(3));
      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps.whereType<CombatantShakeStep>().single.side,
        equals(BattleSideId.player),
      );
    });

    test(
        'order up lifts a Tatsugiri sprite under the defender and lets it linger',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkOrderUp,
        _seededContext(BattleMoveVisualRecipeId.sdkOrderUp),
      );

      final tatsugiri = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'tatsugiri')
          .toList();
      expect(tatsugiri, hasLength(2));
      expect(_countFx(steps, 'shell'), equals(0));
      expect(tatsugiri.first.defenderSide, equals(BattleSideId.enemy));
      expect(tatsugiri.first.fromOffsetY, greaterThanOrEqualTo(120));
      expect(tatsugiri.first.durationSeconds, equals(0.30));
      expect(tatsugiri.first.startScale, equals(2.0));
      expect(tatsugiri.first.endScale, equals(1.0));
      expect(tatsugiri.last.durationSeconds, equals(0.60));
      expect(tatsugiri.last.fromOffsetY, equals(0));
      expect(tatsugiri.last.toOffsetY, equals(0));
      expect(steps.whereType<CombatantShakeStep>(), isEmpty);
      expect(steps.whereType<CombatantFlashStep>(), isEmpty);
    });

    test('heart stamp expands a heart before the contact hit lands', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkHeartStamp,
        _seededContext(BattleMoveVisualRecipeId.sdkHeartStamp),
      );

      expect(_countFx(steps, 'heart'), equals(1));
      expect(steps.whereType<CombatantMotionStep>(), isNotEmpty);
      expect(steps.whereType<CombatantFlashStep>(), isNotEmpty);
    });

    test('matcha gotcha showers energyballs before the target wisps fall', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkMatchaGotcha,
        _seededContext(BattleMoveVisualRecipeId.sdkMatchaGotcha),
      );

      final energyBalls = steps
          .whereType<SpawnFxStep>()
          .where((step) => step.effectId == 'energyball')
          .toList();
      expect(energyBalls.length, greaterThanOrEqualTo(16));
      expect(energyBalls.take(10).every((step) => step.playAsAccent), isTrue);
      expect(
        energyBalls.take(10).map((step) => step.startDelaySeconds).toSet(),
        containsAll(<double>{0.0, 0.03, 0.06, 0.09}),
      );
      expect(_countFx(steps, 'wisp'), equals(4));
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('present keeps the single exploding iceball projectile shape', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPresent,
        _seededContext(BattleMoveVisualRecipeId.sdkPresent),
      );

      final projectile = steps.whereType<SpawnFxStep>().single;
      expect(projectile.effectId, equals('iceball'));
      expect(projectile.curve, equals(BattleFxMotionCurve.linear));
      expect(projectile.durationSeconds, closeTo(0.5, 0.001));
      expect(projectile.afterEffect, equals(BattleFxAfterEffect.explode));
      expect(steps.whereType<CombatantFlashStep>(), isEmpty);
    });

    test('pay day fans out a six-hit electroball volley', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkPayDay,
        _seededContext(BattleMoveVisualRecipeId.sdkPayDay),
      );

      expect(_countFx(steps, 'electroball'), equals(6));
      expect(
        steps.whereType<WaitStep>().map((step) => step.durationSeconds),
        everyElement(closeTo(0.075, 0.001)),
      );
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('taunt now uses pointer harassment plus three angry bursts', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkTaunt,
        _seededContext(BattleMoveVisualRecipeId.sdkTaunt),
      );

      expect(_countFx(steps, 'pointer'), equals(2));
      expect(_countFx(steps, 'angry'), equals(3));
      expect(
        steps.whereType<CombatantShakeStep>().single.side,
        equals(BattleSideId.player),
      );
    });

    test('instruct points first, then sends poison and white wisps forward',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkInstruct,
        _seededContext(BattleMoveVisualRecipeId.sdkInstruct),
      );

      expect(_countFx(steps, 'pointer'), equals(2));
      expect(_countFx(steps, 'poisonwisp'), equals(1));
      expect(_countFx(steps, 'wisp'), equals(1));
      expect(
        steps.whereType<CombatantShakeStep>().single.side,
        equals(BattleSideId.player),
      );
    });

    test('quash uses a rush-in strike instead of generic growl particles', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkQuash,
        _seededContext(BattleMoveVisualRecipeId.sdkQuash),
      );

      expect(_countFx(steps, 'rightchop'), equals(1));
      expect(steps.whereType<CombatantMotionStep>(), isNotEmpty);
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('swagger keeps the attacker shake and three angry puffs on target',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkSwagger,
        _seededContext(BattleMoveVisualRecipeId.sdkSwagger),
      );

      expect(_countFx(steps, 'angry'), equals(3));
      expect(
        steps.whereType<CombatantShakeStep>().single.side,
        equals(BattleSideId.player),
      );
    });

    test('encore is now a clean self-jitter without extra particles', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkEncore,
        _seededContext(BattleMoveVisualRecipeId.sdkEncore),
      );

      expect(steps.whereType<SpawnFxStep>(), isEmpty);
      expect(
        steps.whereType<CombatantShakeStep>().single.side,
        equals(BattleSideId.player),
      );
    });

    test('baby-doll eyes now stays in a self-only dance family', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkBabyDollEyes,
        _seededContext(BattleMoveVisualRecipeId.sdkBabyDollEyes),
      );

      expect(_countFx(steps, 'heart'), equals(0));
      expect(steps.whereType<SpawnFxStep>(), isEmpty);
      expect(
        steps.whereType<CombatantShakeStep>().single.side,
        equals(BattleSideId.player),
      );
    });
  });
}
