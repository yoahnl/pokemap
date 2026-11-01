import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_animation_plan.dart';

final class PreparedBattleMoveRecipe {
  const PreparedBattleMoveRecipe._(
    this._program,
    this.moveSourceId,
    this.projectMoveId,
  );

  final Map<String, dynamic> _program;
  final String moveSourceId;
  final String? projectMoveId;
}

final class BattleMoveRecipeCompiler {
  const BattleMoveRecipeCompiler();

  static bool get supportsCompleteMoveVisuals => false;

  static const _maxSupplementalSteps = 256;
  static const _maxSupplementalDurationMs = 30000;

  static const availableCapabilities = {
    'sequence',
    'parallel',
    'wait',
    'cameraFocus',
    'cameraReset',
  };

  PreparedBattleMoveRecipe prepare(
    BattleMoveAnimationRecipe recipe,
    Map<String, List<int>> resources,
  ) {
    recipe.validateBundle(
      resources,
      availableCapabilities: availableCapabilities,
    );
    return _prepareValidated(recipe);
  }

  PreparedBattleMoveRecipe prepareBound(
    BattleMoveRecipeBinding binding,
    List<int> recipeBytes,
    Map<String, List<int>> resources, {
    required String expectedProjectMoveId,
    required String expectedCatalogReleaseId,
  }) {
    if (binding.projectMoveId != expectedProjectMoveId ||
        binding.catalogReleaseId != expectedCatalogReleaseId) {
      throw const FormatException('Recipe binding does not match project');
    }
    final recipe = binding.resolve(
      recipeBytes,
      resources,
      availableCapabilities: availableCapabilities,
    );
    return _prepareValidated(recipe, projectMoveId: binding.projectMoveId);
  }

  PreparedBattleMoveRecipe _prepareValidated(
    BattleMoveAnimationRecipe recipe, {
    String? projectMoveId,
  }) {
    final json = recipe.toJson();
    return PreparedBattleMoveRecipe._(
      (json['program'] as Map).cast<String, dynamic>(),
      json['moveSourceId'] as String,
      projectMoveId,
    );
  }

  BattleAnimationPlan compile(
    PreparedBattleMoveRecipe recipe, {
    required BattleSlotRef user,
    BattleSlotRef? target,
  }) {
    BattleAnimationStep compileStep(Map<String, dynamic> step) {
      final duration = ((step['durationMs'] as int?) ?? 0) / 1000;
      return switch (step['kind']) {
        'sequence' || 'parallel' => AnimationGroupStep(
          mode: step['kind'] == 'sequence'
              ? BattleAnimationGroupMode.sequence
              : BattleAnimationGroupMode.parallel,
          steps: (step['steps'] as List)
              .map(
                (value) => compileStep((value as Map).cast<String, dynamic>()),
              )
              .toList(growable: false),
        ),
        'wait' => WaitStep(durationSeconds: duration),
        'cameraReset' => BattleCameraResetStep(durationSeconds: duration),
        'cameraFocus' => () {
          final focus = switch (step['target']) {
            'user' => BattleCameraFocusTarget.user,
            'target' => BattleCameraFocusTarget.target,
            'scene' => BattleCameraFocusTarget.scene,
            _ => throw const FormatException('Unknown camera target'),
          };
          final slot = switch (focus) {
            BattleCameraFocusTarget.user => user,
            BattleCameraFocusTarget.target =>
              target ??
                  (throw const FormatException('Target slot unavailable')),
            BattleCameraFocusTarget.scene => null,
          };
          return CameraFocusStep(
            target: focus,
            side: slot?.side,
            slotIndex: slot?.slotIndex ?? 0,
            durationSeconds: duration,
          );
        }(),
        _ => throw const FormatException('Unsupported recipe instruction'),
      };
    }

    return BattleAnimationPlan(steps: [compileStep(recipe._program)]);
  }

  BattleAnimationPlan? compileSupplemental(
    PreparedBattleMoveRecipe recipe, {
    required BattleSlotRef user,
    BattleSlotRef? target,
  }) {
    var count = 0;
    int? duration(Map<String, dynamic> step) {
      if (++count > _maxSupplementalSteps) return null;
      final kind = step['kind'];
      if (kind == 'wait' || kind == 'cameraFocus' || kind == 'cameraReset') {
        final milliseconds = step['durationMs'] as int;
        return milliseconds <= _maxSupplementalDurationMs ? milliseconds : null;
      }
      if (kind != 'sequence' && kind != 'parallel') return null;
      var total = 0;
      for (final child in step['steps'] as List) {
        final childDuration = duration((child as Map).cast<String, dynamic>());
        if (childDuration == null) return null;
        if (kind == 'sequence') {
          total += childDuration;
        } else if (childDuration > total) {
          total = childDuration;
        }
        if (total > _maxSupplementalDurationMs) return null;
      }
      return total;
    }

    if (duration(recipe._program) == null) return null;
    return compile(recipe, user: user, target: target);
  }
}
