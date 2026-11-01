import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_runner.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_recipe_compiler.dart';

void main() {
  Map<String, dynamic> source() => {
    'schemaVersion': 1,
    'recipeId': 'synthetic',
    'revision': '1',
    'moveSourceId': 'flamethrower',
    'variant': 'default',
    'requiredCapabilities': [
      'sequence',
      'parallel',
      'wait',
      'cameraFocus',
      'cameraReset',
    ],
    'provenance': {
      'source': 'synthetic',
      'sourceRevision': '1',
      'sourcePaths': <String>[],
      'converter': 'test/1',
    },
    'resources': <Object>[],
    'program': {
      'kind': 'sequence',
      'steps': [
        {
          'kind': 'parallel',
          'steps': [
            {'kind': 'cameraFocus', 'target': 'target', 'durationMs': 300},
            {
              'kind': 'sequence',
              'steps': [
                {'kind': 'wait', 'durationMs': 100},
                {'kind': 'cameraFocus', 'target': 'user', 'durationMs': 200},
              ],
            },
          ],
        },
        {'kind': 'cameraReset', 'durationMs': 250},
      ],
    },
  };

  const user = BattleSlotRef(side: BattleSideId.player, slotIndex: 1);
  const target = BattleSlotRef(side: BattleSideId.enemy, slotIndex: 1);
  const compiler = BattleMoveRecipeCompiler();

  test('compiles nested groups, milliseconds and exact combatant slots', () {
    final plan = compiler.compile(
      compiler.prepare(BattleMoveAnimationRecipe.fromJson(source()), const {}),
      user: user,
      target: target,
    );
    final parallel = plan.steps.single as AnimationGroupStep;
    expect(parallel.mode, BattleAnimationGroupMode.sequence);
    final group = parallel.steps.first as AnimationGroupStep;
    final focus = group.steps.first as CameraFocusStep;
    expect(
      (focus.side, focus.slotIndex, focus.durationSeconds),
      (target.side, target.slotIndex, .3),
    );
    final nested = group.steps.last as AnimationGroupStep;
    expect((nested.steps.first as WaitStep).durationSeconds, .1);
    final userFocus = nested.steps.last as CameraFocusStep;
    expect((userFocus.side, userFocus.slotIndex), (user.side, user.slotIndex));
    expect((parallel.steps.last as BattleCameraResetStep).durationSeconds, .25);
  });

  test('refuses an unavailable target and unsupported media', () {
    final recipe = BattleMoveAnimationRecipe.fromJson(source());
    expect(
      () => compiler.compile(compiler.prepare(recipe, const {}), user: user),
      throwsFormatException,
    );
    final bytes = utf8.encode('synthetic');
    final data = source();
    data['requiredCapabilities'] = ['sound'];
    data['resources'] = [
      {
        'id': 'cue',
        'role': 'sound',
        'mediaType': 'audio/ogg',
        'sizeBytes': bytes.length,
        'sha256': sha256.convert(bytes).toString(),
      },
    ];
    data['program'] = {'kind': 'sound', 'resourceId': 'cue'};
    final soundRecipe = BattleMoveAnimationRecipe.fromJson(data);
    expect(
      () => compiler.prepare(soundRecipe, {'cue': bytes}),
      throwsFormatException,
    );
  });

  test('checks resources when preparing, not on every attack compilation', () {
    final bytes = utf8.encode('synthetic');
    final data = source();
    data['resources'] = [
      {
        'id': 'unused',
        'role': 'sound',
        'mediaType': 'audio/ogg',
        'sizeBytes': bytes.length,
        'sha256': sha256.convert(bytes).toString(),
      },
    ];
    final recipe = BattleMoveAnimationRecipe.fromJson(data);
    expect(
      () => compiler.prepare(recipe, {
        'unused': [1],
      }),
      throwsFormatException,
    );
    final prepared = compiler.prepare(recipe, {'unused': bytes});
    bytes[0] ^= 1;
    expect(prepared.moveSourceId, 'flamethrower');
    expect(
      () => compiler.compile(prepared, user: user, target: target),
      returnsNormally,
    );
  });

  test('prepares only the bound local move and catalog release', () {
    final bytes = utf8.encode(jsonEncode(source()));
    final binding = BattleMoveRecipeBinding.fromJson({
      'schemaVersion': 1,
      'projectMoveId': 'local-fire',
      'sourceMoveId': 'flamethrower',
      'catalogReleaseId': 'synthetic-release',
      'recipeId': 'synthetic',
      'variant': 'default',
      'revision': '1',
      'recipeSha256': sha256.convert(bytes).toString(),
    });
    final prepared = compiler.prepareBound(
      binding,
      bytes,
      const {},
      expectedProjectMoveId: 'local-fire',
      expectedCatalogReleaseId: 'synthetic-release',
    );
    expect(
      () => compiler.compile(prepared, user: user, target: target),
      returnsNormally,
    );
    expect(
      () => compiler.prepareBound(
        binding,
        bytes,
        const {},
        expectedProjectMoveId: 'other',
        expectedCatalogReleaseId: 'synthetic-release',
      ),
      throwsFormatException,
    );
    expect(
      () => compiler.prepareBound(
        binding,
        bytes,
        const {},
        expectedProjectMoveId: 'local-fire',
        expectedCatalogReleaseId: 'other',
      ),
      throwsFormatException,
    );
    expect(
      () => compiler.prepareBound(
        binding,
        [...bytes, 32],
        const {},
        expectedProjectMoveId: 'local-fire',
        expectedCatalogReleaseId: 'synthetic-release',
      ),
      throwsFormatException,
    );
  });

  test('the existing runner preserves the compiled parallel timing', () {
    final events = <BattleCameraFocusTarget>[];
    final runner = BattleAnimationRunner(
      onPresentationChanged: () {},
      onSpawnFx: (_) {},
      onScreenFlash: (_) {},
      onCombatantMotion: (_) {},
      onCombatantFlash: (_) {},
      onCombatantShake: (_) {},
      onFaintCombatant: (_) {},
      onHudHpTween: (_) {},
      onBarrierPulse: (_) {},
      onSwapCombatantVisual: (_) {},
      onCameraFocus: (step) => events.add(step.target),
    );
    runner.start(
      compiler.compile(
        compiler.prepare(
          BattleMoveAnimationRecipe.fromJson(source()),
          const {},
        ),
        user: user,
        target: target,
      ),
    );
    expect(events, [BattleCameraFocusTarget.target]);
    runner.update(.09);
    expect(events, [BattleCameraFocusTarget.target]);
    runner.update(.01);
    expect(events, [
      BattleCameraFocusTarget.target,
      BattleCameraFocusTarget.user,
    ]);
    runner.update(.2);
    expect(runner.isActive, isTrue);
    runner.update(.25);
    expect(runner.isActive, isFalse);
  });
}
