import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_recipe_library.dart';

BattleMoveVisualRecipeContext _context(BattleMoveVisualRecipeId recipeId) {
  final move = BattleMove(
    id: 'test_move',
    name: 'Test Move',
    power: 80,
    type: 'normal',
    category: BattleMoveCategory.special,
    target: BattleMoveTarget.opponent,
  );
  return BattleMoveVisualRecipeContext(
    resolvedMove: BattleResolvedMoveVisual(
      localMoveId: 'test_move',
      showdownMoveId: 'testmove',
      recipeId: recipeId,
      usesFallback: false,
      canonicalMove: null,
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
        for (final step in steps.whereType<SpawnFxStep>()) {
          expect(
            BattleFxCatalog.contains(step.effectId),
            isTrue,
            reason: '${recipeId.name} -> ${step.effectId}',
          );
        }
      }
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
