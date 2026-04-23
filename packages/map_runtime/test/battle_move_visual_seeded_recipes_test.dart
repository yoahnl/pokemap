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
      showdownMoveId: 'seededmove',
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
        BattleMoveVisualRecipeId.showdownTackle,
        _seededContext(BattleMoveVisualRecipeId.showdownTackle),
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
        BattleMoveVisualRecipeId.showdownScratch,
        _seededContext(BattleMoveVisualRecipeId.showdownScratch),
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
        BattleMoveVisualRecipeId.showdownQuickAttack,
        _seededContext(BattleMoveVisualRecipeId.showdownQuickAttack),
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

    test('thunderbolt uses defender lightning bursts like the Showdown recipe',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownThunderbolt,
        _seededContext(BattleMoveVisualRecipeId.showdownThunderbolt),
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
        BattleMoveVisualRecipeId.showdownShadowBall,
        _seededContext(BattleMoveVisualRecipeId.showdownShadowBall),
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
        BattleMoveVisualRecipeId.showdownAuraSphere,
        _seededContext(BattleMoveVisualRecipeId.showdownAuraSphere),
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
        BattleMoveVisualRecipeId.showdownCloseCombat,
        _seededContext(BattleMoveVisualRecipeId.showdownCloseCombat),
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
        BattleMoveVisualRecipeId.showdownStealthRock,
        _seededContext(BattleMoveVisualRecipeId.showdownStealthRock),
      );

      final plan = BattleAnimationPlan(steps: steps);
      expect(plan.requiredFxIds, containsAll(<String>['rock1', 'rock2']));
      expect(steps.whereType<SpawnFxStep>(), hasLength(4));
    });

    test('spikes places a three-caltrop volley', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownSpikes,
        _seededContext(BattleMoveVisualRecipeId.showdownSpikes),
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
        BattleMoveVisualRecipeId.showdownGrowl,
        _seededContext(BattleMoveVisualRecipeId.showdownGrowl),
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
        BattleMoveVisualRecipeId.showdownThunderWave,
        _seededContext(BattleMoveVisualRecipeId.showdownThunderWave),
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
        BattleMoveVisualRecipeId.showdownQuiverDance,
        _seededContext(BattleMoveVisualRecipeId.showdownQuiverDance),
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
        BattleMoveVisualRecipeId.showdownFocusBlast,
        _seededContext(BattleMoveVisualRecipeId.showdownFocusBlast),
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
        BattleMoveVisualRecipeId.showdownVoltSwitch,
        _seededContext(BattleMoveVisualRecipeId.showdownVoltSwitch),
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
        BattleMoveVisualRecipeId.showdownExplosion,
        _seededContext(BattleMoveVisualRecipeId.showdownExplosion),
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
        BattleMoveVisualRecipeId.showdownHurricane,
        _seededContext(BattleMoveVisualRecipeId.showdownHurricane),
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
        BattleMoveVisualRecipeId.showdownSunnyDay,
        _seededContext(BattleMoveVisualRecipeId.showdownSunnyDay),
      );
      final hail = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownHail,
        _seededContext(BattleMoveVisualRecipeId.showdownHail),
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
        BattleMoveVisualRecipeId.showdownElectricTerrain,
        _seededContext(BattleMoveVisualRecipeId.showdownElectricTerrain),
      );
      final grassy = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownGrassyTerrain,
        _seededContext(BattleMoveVisualRecipeId.showdownGrassyTerrain),
      );
      final misty = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownMistyTerrain,
        _seededContext(BattleMoveVisualRecipeId.showdownMistyTerrain),
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
        BattleMoveVisualRecipeId.showdownFollowMe,
        _seededContext(BattleMoveVisualRecipeId.showdownFollowMe),
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
        BattleMoveVisualRecipeId.showdownSolarBeam,
        _seededContext(BattleMoveVisualRecipeId.showdownSolarBeam),
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
        BattleMoveVisualRecipeId.showdownThunder,
        _seededContext(BattleMoveVisualRecipeId.showdownThunder),
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
        BattleMoveVisualRecipeId.showdownStoredPower,
        _seededContext(BattleMoveVisualRecipeId.showdownStoredPower),
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
        BattleMoveVisualRecipeId.showdownPsychoBoost,
        _seededContext(BattleMoveVisualRecipeId.showdownPsychoBoost),
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
        BattleMoveVisualRecipeId.showdownPsyshock,
        _seededContext(BattleMoveVisualRecipeId.showdownPsyshock),
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
        BattleMoveVisualRecipeId.showdownHex,
        _seededContext(BattleMoveVisualRecipeId.showdownHex),
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
        BattleMoveVisualRecipeId.showdownWillOWisp,
        _seededContext(BattleMoveVisualRecipeId.showdownWillOWisp),
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
        BattleMoveVisualRecipeId.showdownLifeDew,
        _seededContext(BattleMoveVisualRecipeId.showdownLifeDew),
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
        BattleMoveVisualRecipeId.showdownProtect,
        _seededContext(BattleMoveVisualRecipeId.showdownProtect),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
      expect(steps.whereType<BarrierPulseStep>(), isEmpty);
    });

    test('burning bulwark blooms two fire shields and a toxic ember', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownBurningBulwark,
        _seededContext(BattleMoveVisualRecipeId.showdownBurningBulwark),
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
        BattleMoveVisualRecipeId.showdownBanefulBunker,
        _seededContext(BattleMoveVisualRecipeId.showdownBanefulBunker),
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
        BattleMoveVisualRecipeId.showdownRainDance,
        _seededContext(BattleMoveVisualRecipeId.showdownRainDance),
      );
      final sand = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownSandstorm,
        _seededContext(BattleMoveVisualRecipeId.showdownSandstorm),
      );
      final trick = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownTrickRoom,
        _seededContext(BattleMoveVisualRecipeId.showdownTrickRoom),
      );

      expect(rain.whereType<CombatantShakeStep>(), isNotEmpty);
      expect(sand.whereType<CombatantShakeStep>(), isNotEmpty);
      expect(trick.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('side-condition shields use native barrier pulses instead of png fx',
        () {
      final recipeLibrary = BattleMoveVisualRecipeLibrary();
      final reflect = recipeLibrary.build(
        BattleMoveVisualRecipeId.showdownReflect,
        _seededContext(BattleMoveVisualRecipeId.showdownReflect),
      );
      final lightScreen = recipeLibrary.build(
        BattleMoveVisualRecipeId.showdownLightScreen,
        _seededContext(BattleMoveVisualRecipeId.showdownLightScreen),
      );
      final mist = recipeLibrary.build(
        BattleMoveVisualRecipeId.showdownMist,
        _seededContext(BattleMoveVisualRecipeId.showdownMist),
      );
      final auroraVeil = recipeLibrary.build(
        BattleMoveVisualRecipeId.showdownAuroraVeil,
        _seededContext(BattleMoveVisualRecipeId.showdownAuroraVeil),
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
        BattleMoveVisualRecipeId.showdownAquaJet,
        _seededContext(BattleMoveVisualRecipeId.showdownAquaJet),
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
        BattleMoveVisualRecipeId.showdownExtremeSpeed,
        _seededContext(BattleMoveVisualRecipeId.showdownExtremeSpeed),
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
        BattleMoveVisualRecipeId.showdownMachPunch,
        _seededContext(BattleMoveVisualRecipeId.showdownMachPunch),
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
        BattleMoveVisualRecipeId.showdownShadowPunch,
        _seededContext(BattleMoveVisualRecipeId.showdownShadowPunch),
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
        BattleMoveVisualRecipeId.showdownFocusPunch,
        _seededContext(BattleMoveVisualRecipeId.showdownFocusPunch),
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
        BattleMoveVisualRecipeId.showdownDrainPunch,
        _seededContext(BattleMoveVisualRecipeId.showdownDrainPunch),
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
        BattleMoveVisualRecipeId.showdownDynamicPunch,
        _seededContext(BattleMoveVisualRecipeId.showdownDynamicPunch),
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
        BattleMoveVisualRecipeId.showdownCometPunch,
        _seededContext(BattleMoveVisualRecipeId.showdownCometPunch),
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
        BattleMoveVisualRecipeId.showdownMegaPunch,
        _seededContext(BattleMoveVisualRecipeId.showdownMegaPunch),
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
        BattleMoveVisualRecipeId.showdownPowerUpPunch,
        _seededContext(BattleMoveVisualRecipeId.showdownPowerUpPunch),
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
        BattleMoveVisualRecipeId.showdownDizzyPunch,
        _seededContext(BattleMoveVisualRecipeId.showdownDizzyPunch),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
      expect(steps.whereType<CombatantShakeStep>(), hasLength(2));
    });

    test('jet punch carries one fist through a six-wisp water burst', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownJetPunch,
        _seededContext(BattleMoveVisualRecipeId.showdownJetPunch),
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
        BattleMoveVisualRecipeId.showdownFirePunch,
        _seededContext(BattleMoveVisualRecipeId.showdownFirePunch),
      );
      final icePunch = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownIcePunch,
        _seededContext(BattleMoveVisualRecipeId.showdownIcePunch),
      );
      final thunderPunch = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownThunderPunch,
        _seededContext(BattleMoveVisualRecipeId.showdownThunderPunch),
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
        BattleMoveVisualRecipeId.showdownBlazeKick,
        _seededContext(BattleMoveVisualRecipeId.showdownBlazeKick),
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
        BattleMoveVisualRecipeId.showdownThunderousKick,
        _seededContext(BattleMoveVisualRecipeId.showdownThunderousKick),
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
        BattleMoveVisualRecipeId.showdownTropKick,
        _seededContext(BattleMoveVisualRecipeId.showdownTropKick),
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
        BattleMoveVisualRecipeId.showdownDualWingBeat,
        _seededContext(BattleMoveVisualRecipeId.showdownDualWingBeat),
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
        BattleMoveVisualRecipeId.showdownBoneMerang,
        _seededContext(BattleMoveVisualRecipeId.showdownBoneMerang),
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
        BattleMoveVisualRecipeId.showdownSpark,
        _seededContext(BattleMoveVisualRecipeId.showdownSpark),
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
        BattleMoveVisualRecipeId.showdownWildCharge,
        _seededContext(BattleMoveVisualRecipeId.showdownWildCharge),
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
        BattleMoveVisualRecipeId.showdownFlareBlitz,
        _seededContext(BattleMoveVisualRecipeId.showdownFlareBlitz),
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
        BattleMoveVisualRecipeId.showdownAccelerock,
        _seededContext(BattleMoveVisualRecipeId.showdownAccelerock),
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
        BattleMoveVisualRecipeId.showdownWickedBlow,
        _seededContext(BattleMoveVisualRecipeId.showdownWickedBlow),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'fist'),
        hasLength(1),
      );
    });

    test('double hit repeats compact impact accents around the target', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownDoubleHit,
        _seededContext(BattleMoveVisualRecipeId.showdownDoubleHit),
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
        BattleMoveVisualRecipeId.showdownCrunch,
        _seededContext(BattleMoveVisualRecipeId.showdownCrunch),
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
        BattleMoveVisualRecipeId.showdownFlamethrower,
        _seededContext(BattleMoveVisualRecipeId.showdownFlamethrower),
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
        BattleMoveVisualRecipeId.showdownIceBeam,
        _seededContext(BattleMoveVisualRecipeId.showdownIceBeam),
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
        BattleMoveVisualRecipeId.showdownPsychic,
        _seededContext(BattleMoveVisualRecipeId.showdownPsychic),
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
        BattleMoveVisualRecipeId.showdownEarthquake,
        _seededContext(BattleMoveVisualRecipeId.showdownEarthquake),
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
        BattleMoveVisualRecipeId.showdownEnergyBall,
        _seededContext(BattleMoveVisualRecipeId.showdownEnergyBall),
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
        BattleMoveVisualRecipeId.showdownNightSlash,
        _seededContext(BattleMoveVisualRecipeId.showdownNightSlash),
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
        BattleMoveVisualRecipeId.showdownGigaImpact,
        _seededContext(BattleMoveVisualRecipeId.showdownGigaImpact),
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
        BattleMoveVisualRecipeId.showdownPowerWhip,
        _seededContext(BattleMoveVisualRecipeId.showdownPowerWhip),
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
        BattleMoveVisualRecipeId.showdownCrabHammer,
        _seededContext(BattleMoveVisualRecipeId.showdownCrabHammer),
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
        BattleMoveVisualRecipeId.showdownDischarge,
        _seededContext(BattleMoveVisualRecipeId.showdownDischarge),
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
        BattleMoveVisualRecipeId.showdownSmartStrike,
        _seededContext(BattleMoveVisualRecipeId.showdownSmartStrike),
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
        BattleMoveVisualRecipeId.showdownMegaHorn,
        _seededContext(BattleMoveVisualRecipeId.showdownMegaHorn),
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
        BattleMoveVisualRecipeId.showdownDragonClaw,
        _seededContext(BattleMoveVisualRecipeId.showdownDragonClaw),
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
        BattleMoveVisualRecipeId.showdownPsychoCut,
        _seededContext(BattleMoveVisualRecipeId.showdownPsychoCut),
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
        BattleMoveVisualRecipeId.showdownWaterPulse,
        _seededContext(BattleMoveVisualRecipeId.showdownWaterPulse),
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
        BattleMoveVisualRecipeId.showdownPowerGem,
        _seededContext(BattleMoveVisualRecipeId.showdownPowerGem),
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
        BattleMoveVisualRecipeId.showdownHeatWave,
        _seededContext(BattleMoveVisualRecipeId.showdownHeatWave),
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
        BattleMoveVisualRecipeId.showdownMuddyWater,
        _seededContext(BattleMoveVisualRecipeId.showdownMuddyWater),
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
        BattleMoveVisualRecipeId.showdownEarthPower,
        _seededContext(BattleMoveVisualRecipeId.showdownEarthPower),
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
        BattleMoveVisualRecipeId.showdownBugBuzz,
        _seededContext(BattleMoveVisualRecipeId.showdownBugBuzz),
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
        BattleMoveVisualRecipeId.showdownPlayRough,
        _seededContext(BattleMoveVisualRecipeId.showdownPlayRough),
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
        BattleMoveVisualRecipeId.showdownSurf,
        _seededContext(BattleMoveVisualRecipeId.showdownSurf),
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
        BattleMoveVisualRecipeId.showdownHydroPump,
        _seededContext(BattleMoveVisualRecipeId.showdownHydroPump),
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
        BattleMoveVisualRecipeId.showdownLeafBlade,
        _seededContext(BattleMoveVisualRecipeId.showdownLeafBlade),
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
        BattleMoveVisualRecipeId.showdownXScissor,
        _seededContext(BattleMoveVisualRecipeId.showdownXScissor),
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
        BattleMoveVisualRecipeId.showdownFireFang,
        _seededContext(BattleMoveVisualRecipeId.showdownFireFang),
      );
      final ice = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownIceFang,
        _seededContext(BattleMoveVisualRecipeId.showdownIceFang),
      );
      final thunder = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownThunderFang,
        _seededContext(BattleMoveVisualRecipeId.showdownThunderFang),
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
        BattleMoveVisualRecipeId.showdownAirSlash,
        _seededContext(BattleMoveVisualRecipeId.showdownAirSlash),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(4),
      );
      expect(steps.whereType<CombatantFlashStep>(), isNotEmpty);
    });

    test('draco meteor rains flareballs, rocks and a dark impact core', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownDracoMeteor,
        _seededContext(BattleMoveVisualRecipeId.showdownDracoMeteor),
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
        BattleMoveVisualRecipeId.showdownHyperVoice,
        _seededContext(BattleMoveVisualRecipeId.showdownHyperVoice),
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
        BattleMoveVisualRecipeId.showdownFlashCannon,
        _seededContext(BattleMoveVisualRecipeId.showdownFlashCannon),
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
        BattleMoveVisualRecipeId.showdownDragonPulse,
        _seededContext(BattleMoveVisualRecipeId.showdownDragonPulse),
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
        BattleMoveVisualRecipeId.showdownSludgeBomb,
        _seededContext(BattleMoveVisualRecipeId.showdownSludgeBomb),
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
        BattleMoveVisualRecipeId.showdownMagicalLeaf,
        _seededContext(BattleMoveVisualRecipeId.showdownMagicalLeaf),
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
        BattleMoveVisualRecipeId.showdownElectroweb,
        _seededContext(BattleMoveVisualRecipeId.showdownElectroweb),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'web'),
        hasLength(3),
      );
    });

    test('bullet seed uses two rapid seed-like energy shots', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownBulletSeed,
        _seededContext(BattleMoveVisualRecipeId.showdownBulletSeed),
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
        BattleMoveVisualRecipeId.showdownSlam,
        _seededContext(BattleMoveVisualRecipeId.showdownSlam),
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
        BattleMoveVisualRecipeId.showdownBodySlam,
        _seededContext(BattleMoveVisualRecipeId.showdownBodySlam),
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
        BattleMoveVisualRecipeId.showdownHighJumpKick,
        _seededContext(BattleMoveVisualRecipeId.showdownHighJumpKick),
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
        BattleMoveVisualRecipeId.showdownKarateChop,
        _seededContext(BattleMoveVisualRecipeId.showdownKarateChop),
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
        BattleMoveVisualRecipeId.showdownDrillRun,
        _seededContext(BattleMoveVisualRecipeId.showdownDrillRun),
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
        BattleMoveVisualRecipeId.showdownGunkShot,
        _seededContext(BattleMoveVisualRecipeId.showdownGunkShot),
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
        BattleMoveVisualRecipeId.showdownMudShot,
        _seededContext(BattleMoveVisualRecipeId.showdownMudShot),
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
        BattleMoveVisualRecipeId.showdownElectroBall,
        _seededContext(BattleMoveVisualRecipeId.showdownElectroBall),
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
        BattleMoveVisualRecipeId.showdownRockBlast,
        _seededContext(BattleMoveVisualRecipeId.showdownRockBlast),
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
        BattleMoveVisualRecipeId.showdownWhirlwind,
        _seededContext(BattleMoveVisualRecipeId.showdownWhirlwind),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(12),
      );
    });

    test('freeze dry throws a four-icicle volley with a cold follow-up', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownFreezeDry,
        _seededContext(BattleMoveVisualRecipeId.showdownFreezeDry),
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
        BattleMoveVisualRecipeId.showdownMagmaStorm,
        _seededContext(BattleMoveVisualRecipeId.showdownMagmaStorm),
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
        BattleMoveVisualRecipeId.showdownOriginPulse,
        _seededContext(BattleMoveVisualRecipeId.showdownOriginPulse),
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
        BattleMoveVisualRecipeId.showdownPsybeam,
        _seededContext(BattleMoveVisualRecipeId.showdownPsybeam),
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
        BattleMoveVisualRecipeId.showdownAeroblast,
        _seededContext(BattleMoveVisualRecipeId.showdownAeroblast),
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
        BattleMoveVisualRecipeId.showdownRoarOfTime,
        _seededContext(BattleMoveVisualRecipeId.showdownRoarOfTime),
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
        BattleMoveVisualRecipeId.showdownRevelationDance,
        _seededContext(BattleMoveVisualRecipeId.showdownRevelationDance),
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
        BattleMoveVisualRecipeId.showdownAromatherapy,
        _seededContext(BattleMoveVisualRecipeId.showdownAromatherapy),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
    });

    test('rest lifts two wisps behind the attacker', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownRest,
        _seededContext(BattleMoveVisualRecipeId.showdownRest),
      );

      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
    });

    test('ingrain seeds the user with layered leaves', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownIngrain,
        _seededContext(BattleMoveVisualRecipeId.showdownIngrain),
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
        BattleMoveVisualRecipeId.showdownMorningSun,
        _seededContext(BattleMoveVisualRecipeId.showdownMorningSun),
      );

      expect(steps.whereType<ScreenFlashStep>(), isNotEmpty);
      expect(
        steps.whereType<SpawnFxStep>().where((step) => step.effectId == 'wisp'),
        hasLength(2),
      );
    });

    test('shore up uses earthy healing accents around the user', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownShoreUp,
        _seededContext(BattleMoveVisualRecipeId.showdownShoreUp),
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
        BattleMoveVisualRecipeId.showdownDrain,
        _seededContext(BattleMoveVisualRecipeId.showdownDrain),
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
        BattleMoveVisualRecipeId.showdownLeechLife,
        _seededContext(BattleMoveVisualRecipeId.showdownLeechLife),
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
        BattleMoveVisualRecipeId.showdownHornLeech,
        _seededContext(BattleMoveVisualRecipeId.showdownHornLeech),
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
        BattleMoveVisualRecipeId.showdownParabolicCharge,
        _seededContext(BattleMoveVisualRecipeId.showdownParabolicCharge),
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
        BattleMoveVisualRecipeId.showdownDrainingKiss,
        _seededContext(BattleMoveVisualRecipeId.showdownDrainingKiss),
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
        BattleMoveVisualRecipeId.showdownOblivionWing,
        _seededContext(BattleMoveVisualRecipeId.showdownOblivionWing),
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
        BattleMoveVisualRecipeId.showdownLeechSeed,
        _seededContext(BattleMoveVisualRecipeId.showdownLeechSeed),
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
        BattleMoveVisualRecipeId.showdownHyperBeam,
        _seededContext(BattleMoveVisualRecipeId.showdownHyperBeam),
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
        BattleMoveVisualRecipeId.showdownSignalBeam,
        _seededContext(BattleMoveVisualRecipeId.showdownSignalBeam),
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
        BattleMoveVisualRecipeId.showdownFleurCannon,
        _seededContext(BattleMoveVisualRecipeId.showdownFleurCannon),
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
        BattleMoveVisualRecipeId.showdownArmorCannon,
        _seededContext(BattleMoveVisualRecipeId.showdownArmorCannon),
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
        BattleMoveVisualRecipeId.showdownSteelBeam,
        _seededContext(BattleMoveVisualRecipeId.showdownSteelBeam),
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
        BattleMoveVisualRecipeId.showdownBeakBlast,
        _seededContext(BattleMoveVisualRecipeId.showdownBeakBlast),
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
        BattleMoveVisualRecipeId.showdownTwinBeam,
        _seededContext(BattleMoveVisualRecipeId.showdownTwinBeam),
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
        BattleMoveVisualRecipeId.showdownSpikeCannon,
        _seededContext(BattleMoveVisualRecipeId.showdownSpikeCannon),
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
        BattleMoveVisualRecipeId.showdownHiddenPower,
        _seededContext(BattleMoveVisualRecipeId.showdownHiddenPower),
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
        BattleMoveVisualRecipeId.showdownWaterShuriken,
        _seededContext(BattleMoveVisualRecipeId.showdownWaterShuriken),
      );

      expect(_countFx(steps, 'waterwisp'), equals(3));
      expect(_countFx(steps, 'icicle'), equals(3));
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('slash keeps the showdown slashattack feel with a fast dash cut', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownSlash,
        _seededContext(BattleMoveVisualRecipeId.showdownSlash),
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
        BattleMoveVisualRecipeId.showdownTerastarStorm,
        _seededContext(BattleMoveVisualRecipeId.showdownTerastarStorm),
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
        BattleMoveVisualRecipeId.showdownMeteorMash,
        _seededContext(BattleMoveVisualRecipeId.showdownMeteorMash),
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
        BattleMoveVisualRecipeId.showdownToxic,
        _seededContext(BattleMoveVisualRecipeId.showdownToxic),
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
        BattleMoveVisualRecipeId.showdownToxicSpikes,
        _seededContext(BattleMoveVisualRecipeId.showdownToxicSpikes),
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
        BattleMoveVisualRecipeId.showdownPoisonGas,
        _seededContext(BattleMoveVisualRecipeId.showdownPoisonGas),
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
        BattleMoveVisualRecipeId.showdownSmog,
        _seededContext(BattleMoveVisualRecipeId.showdownSmog),
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
        BattleMoveVisualRecipeId.showdownClearSmog,
        _seededContext(BattleMoveVisualRecipeId.showdownClearSmog),
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
        BattleMoveVisualRecipeId.showdownPoisonFang,
        _seededContext(BattleMoveVisualRecipeId.showdownPoisonFang),
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
        BattleMoveVisualRecipeId.showdownCrossPoison,
        _seededContext(BattleMoveVisualRecipeId.showdownCrossPoison),
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
        BattleMoveVisualRecipeId.showdownDireClaw,
        _seededContext(BattleMoveVisualRecipeId.showdownDireClaw),
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
        BattleMoveVisualRecipeId.showdownSpore,
        _seededContext(BattleMoveVisualRecipeId.showdownSpore),
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
        BattleMoveVisualRecipeId.showdownPainSplit,
        _seededContext(BattleMoveVisualRecipeId.showdownPainSplit),
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
        BattleMoveVisualRecipeId.showdownSkillSwap,
        _seededContext(BattleMoveVisualRecipeId.showdownSkillSwap),
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
        BattleMoveVisualRecipeId.showdownDoomDesire,
        _seededContext(BattleMoveVisualRecipeId.showdownDoomDesire),
      );

      final flashes = steps.whereType<ScreenFlashStep>().toList();
      expect(flashes, hasLength(2));
      expect(steps.whereType<SpawnFxStep>(), isEmpty);
      expect(flashes.first.colorArgb, equals(0x33000000));
      expect(flashes.last.colorArgb, equals(0x4D000000));
    });

    test('seed flare fans repeated leaves into a bright burst', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownSeedFlare,
        _seededContext(BattleMoveVisualRecipeId.showdownSeedFlare),
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
        BattleMoveVisualRecipeId.showdownIcyWind,
        _seededContext(BattleMoveVisualRecipeId.showdownIcyWind),
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
        BattleMoveVisualRecipeId.showdownWeatherBall,
        _seededContext(BattleMoveVisualRecipeId.showdownWeatherBall),
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
        BattleMoveVisualRecipeId.showdownScald,
        _seededContext(BattleMoveVisualRecipeId.showdownScald),
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
        BattleMoveVisualRecipeId.showdownTriAttack,
        _seededContext(BattleMoveVisualRecipeId.showdownTriAttack),
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
        BattleMoveVisualRecipeId.showdownClangingScales,
        _seededContext(BattleMoveVisualRecipeId.showdownClangingScales),
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
        BattleMoveVisualRecipeId.showdownFlameBurst,
        _seededContext(BattleMoveVisualRecipeId.showdownFlameBurst),
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
        BattleMoveVisualRecipeId.showdownSteamEruption,
        _seededContext(BattleMoveVisualRecipeId.showdownSteamEruption),
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
        BattleMoveVisualRecipeId.showdownWaterSport,
        _seededContext(BattleMoveVisualRecipeId.showdownWaterSport),
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
        BattleMoveVisualRecipeId.showdownWoodHammer,
        _seededContext(BattleMoveVisualRecipeId.showdownWoodHammer),
      );
      final ivyCudgel = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownIvyCudgel,
        _seededContext(BattleMoveVisualRecipeId.showdownIvyCudgel),
      );
      final ivyCudgelWater = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownIvyCudgelWater,
        _seededContext(BattleMoveVisualRecipeId.showdownIvyCudgelWater),
      );
      final ivyCudgelFire = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownIvyCudgelFire,
        _seededContext(BattleMoveVisualRecipeId.showdownIvyCudgelFire),
      );
      final ivyCudgelRock = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownIvyCudgelRock,
        _seededContext(BattleMoveVisualRecipeId.showdownIvyCudgelRock),
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
        BattleMoveVisualRecipeId.showdownCut,
        _seededContext(BattleMoveVisualRecipeId.showdownCut),
      );
      final shadowClaw = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownShadowClaw,
        _seededContext(BattleMoveVisualRecipeId.showdownShadowClaw),
      );
      final multiAttack = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownMultiAttack,
        _seededContext(BattleMoveVisualRecipeId.showdownMultiAttack),
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
        BattleMoveVisualRecipeId.showdownBite,
        _seededContext(BattleMoveVisualRecipeId.showdownBite),
      );
      final superFang = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownSuperFang,
        _seededContext(BattleMoveVisualRecipeId.showdownSuperFang),
      );
      final bugBite = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownBugBite,
        _seededContext(BattleMoveVisualRecipeId.showdownBugBite),
      );
      final psychicFangs = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownPsychicFangs,
        _seededContext(BattleMoveVisualRecipeId.showdownPsychicFangs),
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
        BattleMoveVisualRecipeId.showdownIronHead,
        _seededContext(BattleMoveVisualRecipeId.showdownIronHead),
      );
      final headbutt = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownHeadbutt,
        _seededContext(BattleMoveVisualRecipeId.showdownHeadbutt),
      );
      final stomp = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownStomp,
        _seededContext(BattleMoveVisualRecipeId.showdownStomp),
      );
      final hammerArm = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownHammerArm,
        _seededContext(BattleMoveVisualRecipeId.showdownHammerArm),
      );
      final iceHammer = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownIceHammer,
        _seededContext(BattleMoveVisualRecipeId.showdownIceHammer),
      );
      final skyUppercut = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownSkyUppercut,
        _seededContext(BattleMoveVisualRecipeId.showdownSkyUppercut),
      );
      final needleArm = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownNeedleArm,
        _seededContext(BattleMoveVisualRecipeId.showdownNeedleArm),
      );
      final rockSmash = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownRockSmash,
        _seededContext(BattleMoveVisualRecipeId.showdownRockSmash),
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
        BattleMoveVisualRecipeId.showdownSplash,
        _seededContext(BattleMoveVisualRecipeId.showdownSplash),
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
        BattleMoveVisualRecipeId.showdownCelebrate,
        _seededContext(BattleMoveVisualRecipeId.showdownCelebrate),
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
        BattleMoveVisualRecipeId.showdownOrderUp,
        _seededContext(BattleMoveVisualRecipeId.showdownOrderUp),
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
        BattleMoveVisualRecipeId.showdownHeartStamp,
        _seededContext(BattleMoveVisualRecipeId.showdownHeartStamp),
      );

      expect(_countFx(steps, 'heart'), equals(1));
      expect(steps.whereType<CombatantMotionStep>(), isNotEmpty);
      expect(steps.whereType<CombatantFlashStep>(), isNotEmpty);
    });

    test('matcha gotcha showers energyballs before the target wisps fall', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownMatchaGotcha,
        _seededContext(BattleMoveVisualRecipeId.showdownMatchaGotcha),
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
        BattleMoveVisualRecipeId.showdownPresent,
        _seededContext(BattleMoveVisualRecipeId.showdownPresent),
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
        BattleMoveVisualRecipeId.showdownPayDay,
        _seededContext(BattleMoveVisualRecipeId.showdownPayDay),
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
        BattleMoveVisualRecipeId.showdownTaunt,
        _seededContext(BattleMoveVisualRecipeId.showdownTaunt),
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
        BattleMoveVisualRecipeId.showdownInstruct,
        _seededContext(BattleMoveVisualRecipeId.showdownInstruct),
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
        BattleMoveVisualRecipeId.showdownQuash,
        _seededContext(BattleMoveVisualRecipeId.showdownQuash),
      );

      expect(_countFx(steps, 'rightchop'), equals(1));
      expect(steps.whereType<CombatantMotionStep>(), isNotEmpty);
      expect(steps.whereType<CombatantShakeStep>(), isNotEmpty);
    });

    test('swagger keeps the attacker shake and three angry puffs on target',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownSwagger,
        _seededContext(BattleMoveVisualRecipeId.showdownSwagger),
      );

      expect(_countFx(steps, 'angry'), equals(3));
      expect(
        steps.whereType<CombatantShakeStep>().single.side,
        equals(BattleSideId.player),
      );
    });

    test('encore is now a clean self-jitter without extra particles', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownEncore,
        _seededContext(BattleMoveVisualRecipeId.showdownEncore),
      );

      expect(steps.whereType<SpawnFxStep>(), isEmpty);
      expect(
        steps.whereType<CombatantShakeStep>().single.side,
        equals(BattleSideId.player),
      );
    });

    test('baby-doll eyes now stays in a self-only dance family', () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.showdownBabyDollEyes,
        _seededContext(BattleMoveVisualRecipeId.showdownBabyDollEyes),
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
