import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_recipe_library.dart';

BattleMoveVisualRecipeContext _context(
  BattleMoveVisualRecipeId recipeId, {
  String moveId = 'test_move',
  String? sdkMoveId = 'testmove',
  int? sdkNumericMoveId,
  int? rmxpUserAnimationId,
  int? rmxpTargetAnimationId,
  BattleMoveVisualSource visualSource = BattleMoveVisualSource.sdkFamily,
}) {
  final move = BattleMove(
    id: moveId,
    name: 'Test Move',
    power: 80,
    type: 'normal',
    category: BattleMoveCategory.special,
    target: BattleMoveTarget.opponent,
  );
  return BattleMoveVisualRecipeContext(
    resolvedMove: BattleResolvedMoveVisual(
      localMoveId: moveId,
      sdkMoveId: sdkMoveId,
      sdkNumericMoveId: sdkNumericMoveId,
      rmxpUserAnimationId: rmxpUserAnimationId,
      rmxpTargetAnimationId: rmxpTargetAnimationId,
      recipeId: recipeId,
      usesFallback: false,
      canonicalMove: null,
      visualSource: visualSource,
    ),
    battleMove: move,
    execution: null,
    attackerSide: BattleSideId.player,
    targetSide: BattleSideId.enemy,
    damage: 18,
    didHit: true,
    didCrit: false,
  );
}

Iterable<BattleAnimationStep> _flattenSteps(
  Iterable<BattleAnimationStep> steps,
) sync* {
  for (final step in steps) {
    yield step;
    if (step case AnimationGroupStep(:final steps)) {
      yield* _flattenSteps(steps);
    }
  }
}

void main() {
  group('BattleMoveVisualRecipeLibrary', () {
    test('each recipe returns at least one step or an explicit no-op', () {
      final library = BattleMoveVisualRecipeLibrary();

      for (final recipeId in BattleMoveVisualRecipeId.values) {
        final steps = library.build(recipeId, _context(recipeId));
        expect(steps, isNotEmpty, reason: recipeId.name);
      }
    });

    test('each recipe references the expected requiredFxIds', () {
      final library = BattleMoveVisualRecipeLibrary();

      final fireSteps = library.build(
        BattleMoveVisualRecipeId.genericProjectileFire,
        _context(BattleMoveVisualRecipeId.genericProjectileFire),
      );
      final firePlan = BattleAnimationPlan(steps: fireSteps);
      expect(firePlan.requiredFxIds, contains('fireball'));
      expect(firePlan.requiredFxIds, contains('impact'));

      final slashSteps = library.build(
        BattleMoveVisualRecipeId.genericSlash,
        _context(BattleMoveVisualRecipeId.genericSlash),
      );
      final slashPlan = BattleAnimationPlan(steps: slashSteps);
      expect(slashPlan.requiredFxIds, contains('leftslash'));
    });

    test('no recipe in v1 depends on an effect id absent from BattleFxCatalog',
        () {
      final library = BattleMoveVisualRecipeLibrary();

      for (final recipeId in BattleMoveVisualRecipeId.values) {
        final steps = library.build(recipeId, _context(recipeId));
        final plan = BattleAnimationPlan(steps: steps);
        for (final effectId in plan.requiredFxIds) {
          expect(
            BattleFxCatalog.contains(effectId),
            isTrue,
            reason: '${recipeId.name} -> $effectId',
          );
        }
      }
    });

    test('exact SDK sprite-sheet recipes use the imported sheet metadata', () {
      final library = BattleMoveVisualRecipeLibrary();

      final acidArmorSteps = library.build(
        BattleMoveVisualRecipeId.sdkExactAcidArmor,
        _context(BattleMoveVisualRecipeId.sdkExactAcidArmor),
      );
      final acidArmorSheet =
          acidArmorSteps.whereType<PlaySpriteSheetFxStep>().single;
      expect(
        acidArmorSheet.frameSequence,
        equals(<int>[0, 1, 2, 3, 0, 1, 2, 3]),
      );
      expect(
        acidArmorSteps.whereType<CombatantFlashStep>(),
        isEmpty,
        reason: 'Exact SDK sheets must not invent hit flash.',
      );
      expect(
        acidArmorSteps.whereType<CombatantShakeStep>(),
        isEmpty,
        reason: 'Exact SDK sheets must not invent shake.',
      );

      final aerialAceSteps = library.build(
        BattleMoveVisualRecipeId.sdkExactAerialAce,
        _context(BattleMoveVisualRecipeId.sdkExactAerialAce),
      );
      final aerialAceSheet =
          aerialAceSteps.whereType<PlaySpriteSheetFxStep>().single;
      expect(aerialAceSheet.assetId, equals('aerial_ace'));
      expect(aerialAceSheet.frameWidth, equals(208));
      expect(aerialAceSheet.frameHeight, equals(192));
      expect(aerialAceSheet.frameCount, equals(13));
      expect(aerialAceSteps.whereType<CombatantFlashStep>(), isEmpty);
      expect(aerialAceSteps.whereType<CombatantShakeStep>(), isEmpty);

      final aquaTailSteps = library.build(
        BattleMoveVisualRecipeId.sdkExactAquaTail,
        _context(BattleMoveVisualRecipeId.sdkExactAquaTail),
      );
      final aquaTailSheet =
          aquaTailSteps.whereType<PlaySpriteSheetFxStep>().single;
      expect(
        aquaTailSheet.frameDurationsSeconds,
        equals(<double>[0.065, 0.065, 0.065, 0.075, 0.075, 0.075, 0.075]),
      );

      final thunderWaveSteps = library.build(
        BattleMoveVisualRecipeId.sdkExactThunderWave,
        _context(BattleMoveVisualRecipeId.sdkExactThunderWave),
      );
      final thunderWaveSheet =
          thunderWaveSteps.whereType<PlaySpriteSheetFxStep>().single;
      expect(thunderWaveSheet.assetId, equals('thunder_02'));
      expect(thunderWaveSheet.frameWidth, equals(192));
      expect(thunderWaveSheet.frameHeight, equals(192));
      expect(thunderWaveSheet.frameCount, equals(10));
      expect(
        thunderWaveSheet.frameSequence,
        equals(<int>[1, 0, 1, 0, 1, 0, 1, 0, 1, 0]),
      );
    });

    test('RMXP move recipes preserve SDK reverse for enemy attackers', () {
      final library = BattleMoveVisualRecipeLibrary();
      const move = BattleMove(
        id: 'watergun',
        name: 'Water Gun',
        power: 40,
        type: 'water',
        category: BattleMoveCategory.special,
        target: BattleMoveTarget.opponent,
      );
      final steps = library.build(
        BattleMoveVisualRecipeId.sdkRmxpMoveAnimation,
        const BattleMoveVisualRecipeContext(
          resolvedMove: BattleResolvedMoveVisual(
            localMoveId: 'watergun',
            sdkMoveId: 'watergun',
            sdkNumericMoveId: 55,
            rmxpTargetAnimationId: 55,
            recipeId: BattleMoveVisualRecipeId.sdkRmxpMoveAnimation,
            usesFallback: false,
            canonicalMove: null,
            visualSource: BattleMoveVisualSource.exactRmxp,
          ),
          battleMove: move,
          execution: null,
          attackerSide: BattleSideId.enemy,
          targetSide: BattleSideId.player,
          damage: 12,
          didHit: true,
          didCrit: false,
        ),
      );

      final step = steps.whereType<PlayRmxpAnimationStep>().single;
      expect(step.animationId, equals(55));
      expect(step.subjectSide, equals(BattleSideId.player));
      expect(step.attackerSide, equals(BattleSideId.enemy));
      expect(step.defenderSide, equals(BattleSideId.player));
      expect(step.phase, equals(RmxpPlacementPhase.target));
      expect(step.placementSpec.policy,
          equals(RmxpPlacementPolicy.projectileLine));
      expect(step.placementSpec.sourceAnchor,
          equals(BattleVisualAnchor.attackerMouth));
      expect(step.placementSpec.targetAnchor,
          equals(BattleVisualAnchor.defenderImpact));
      expect(step.reverse, isTrue);
    });

    test('critical RMXP recipes carry explicit anchoring intent', () {
      const samples =
          <({String moveId, int animationId, RmxpPlacementPolicy policy})>[
        (
          moveId: 'megapunch',
          animationId: 5,
          policy: RmxpPlacementPolicy.targetImpact
        ),
        (
          moveId: 'swift',
          animationId: 129,
          policy: RmxpPlacementPolicy.projectileLine
        ),
        (
          moveId: 'dragonbreath',
          animationId: 225,
          policy: RmxpPlacementPolicy.projectileLine
        ),
      ];

      for (final sample in samples) {
        final steps = BattleMoveVisualRecipeLibrary().build(
          BattleMoveVisualRecipeId.sdkRmxpMoveAnimation,
          _context(
            BattleMoveVisualRecipeId.sdkRmxpMoveAnimation,
            moveId: sample.moveId,
            sdkMoveId: sample.moveId,
            rmxpTargetAnimationId: sample.animationId,
            visualSource: BattleMoveVisualSource.exactRmxp,
          ),
        );

        final step = steps.whereType<PlayRmxpAnimationStep>().single;
        expect(step.placementSpec.policy, sample.policy, reason: sample.moveId);
        expect(step.placementSpec.isImplicit, isFalse, reason: sample.moveId);
      }
    });

    test('tail whip uses the SDK user ellipse instead of stat-down overlay',
        () {
      final steps = BattleMoveVisualRecipeLibrary().build(
        BattleMoveVisualRecipeId.sdkExactTailWhip,
        _context(BattleMoveVisualRecipeId.sdkExactTailWhip),
      );

      expect(steps.whereType<CombatantEllipseStep>(), hasLength(1));
      expect(steps.whereType<SpriteSheetOnCombatantStep>(), isEmpty);
    });

    test('exact SDK powder and leech-seed recipes use SDK primitive particles',
        () {
      final library = BattleMoveVisualRecipeLibrary();

      final powderSteps = library.build(
        BattleMoveVisualRecipeId.sdkExactSleepPowder,
        _context(BattleMoveVisualRecipeId.sdkExactSleepPowder),
      );
      final flattenedPowderSteps = _flattenSteps(powderSteps).toList();
      expect(
        flattenedPowderSteps.whereType<ParticleBurstStep>(),
        isEmpty,
        reason: 'Exact Ruby powders need per-particle falling paths.',
      );
      final powderParticles =
          flattenedPowderSteps.whereType<SdkFallingParticlesStep>().single;
      expect(powderParticles.assetId, equals('circle_blurry_m_2'));
      expect(
        powderParticles.colorArgb,
        isNotNull,
      );

      final leechSeedSteps = library.build(
        BattleMoveVisualRecipeId.sdkExactLeechSeed,
        _context(BattleMoveVisualRecipeId.sdkExactLeechSeed),
      );
      final flattenedLeechSeedSteps = _flattenSteps(leechSeedSteps).toList();
      expect(
        leechSeedSteps.whereType<WaitStep>(),
        isEmpty,
        reason: 'Leech Seed jets and growth must overlap like the SDK script.',
      );
      expect(
        leechSeedSteps
            .whereType<AnimationGroupStep>()
            .any((step) => step.mode == BattleAnimationGroupMode.parallel),
        isTrue,
      );
      expect(
        flattenedLeechSeedSteps.whereType<SdkScalarParticleStep>(),
        isNotEmpty,
        reason:
            'Seed jets should be scalar SDK particles with individual paths.',
      );
      expect(
        flattenedLeechSeedSteps.whereType<SdkParticleZoomStep>(),
        isNotEmpty,
        reason: 'Seed growth should use the SDK zoom primitive.',
      );
      final leechSeedPlan = BattleAnimationPlan(steps: leechSeedSteps);
      expect(leechSeedPlan.requiredFxIds, contains('seed'));
      expect(leechSeedPlan.requiredFxIds, contains('seed_growth'));
    });

    test('recover and karate chop use SDK primitives, not generic bursts', () {
      final library = BattleMoveVisualRecipeLibrary();

      final recoverSteps = library.build(
        BattleMoveVisualRecipeId.sdkExactRecover,
        _context(BattleMoveVisualRecipeId.sdkExactRecover),
      );
      final flattenedRecoverSteps = _flattenSteps(recoverSteps).toList();
      expect(flattenedRecoverSteps.whereType<ParticleBurstStep>(), isEmpty);
      final recoverParticleIds = <String>{
        ...flattenedRecoverSteps
            .whereType<SdkRadiusParticleStep>()
            .map((step) => step.assetId),
        ...flattenedRecoverSteps
            .whereType<SdkParticleZoomStep>()
            .map((step) => step.assetId),
      };
      expect(
        recoverParticleIds,
        containsAll(<String>{'circle_blurry_m_2', 'star_4_ring_l'}),
      );

      final karateSteps = library.build(
        BattleMoveVisualRecipeId.sdkExactKarateChop,
        _context(BattleMoveVisualRecipeId.sdkExactKarateChop),
      );
      final flattenedKarateSteps = _flattenSteps(karateSteps).toList();
      expect(flattenedKarateSteps.whereType<ParticleBurstStep>(), isEmpty);
      expect(
        flattenedKarateSteps.whereType<SdkScalarParticleStep>(),
        isNotEmpty,
      );
      expect(
        flattenedKarateSteps.whereType<SdkFallingParticlesStep>(),
        isNotEmpty,
      );
      expect(
        flattenedKarateSteps.whereType<CombatantCompressStep>(),
        isNotEmpty,
      );
    });

    test('visible generic bugfixes use dedicated SDK families', () {
      final library = BattleMoveVisualRecipeLibrary();

      final swiftSteps = library.build(
        BattleMoveVisualRecipeId.sdkStarVolley,
        _context(BattleMoveVisualRecipeId.sdkStarVolley),
      );
      final swiftPlan = BattleAnimationPlan(steps: swiftSteps);
      expect(swiftPlan.requiredFxIds, containsAll(<String>['star', 'star_1']));
      expect(swiftPlan.requiredFxIds, isNot(contains('leaf1')));

      final shockSteps = library.build(
        BattleMoveVisualRecipeId.sdkElectricShock,
        _context(BattleMoveVisualRecipeId.sdkElectricShock),
      );
      final shockPlan = BattleAnimationPlan(steps: shockSteps);
      expect(
        shockPlan.requiredFxIds,
        containsAll(<String>['thunder_02', 'shock_1']),
      );
      expect(shockPlan.requiredFxIds, isNot(contains('electroball')));
    });

    test('protect barrier does not require a png effect', () {
      final library = BattleMoveVisualRecipeLibrary();
      final steps = library.build(
        BattleMoveVisualRecipeId.protectBarrier,
        _context(BattleMoveVisualRecipeId.protectBarrier),
      );

      expect(steps.whereType<BarrierPulseStep>(), isNotEmpty);
      expect(steps.whereType<SpawnFxStep>(), isEmpty);
    });
  });
}
