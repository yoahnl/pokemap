import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_animation_plan.dart';
import 'battle_gen5_motion_playback.dart';
import 'battle_recipe_audio_program.dart';

enum BattleRecipeAudioCompileStatus { ready, silent, legacy, unsupported }

enum BattleRecipeAudioCompileFailure {
  tooManyEvents,
  offsetTooLate,
  sourceIdTooLong,
}

typedef BattleGroupedSplParticle = ({
  String resourceId,
  String from,
  String to,
  int startTick,
});
typedef BattleGroupedSplSelection = ({
  List<BattleGroupedSplParticle> particles,
  BattleMoveClipAudio audio,
  ({String target, int durationMs})? cameraBefore,
  int? cameraAfterMs,
  List<BattleGen5MotionSpec> swings,
  String? pausedTarget,
});

final class BattleRecipeAudioCompileResult {
  const BattleRecipeAudioCompileResult._(
    this.status, {
    this.selection,
    this.failure,
  });

  final BattleRecipeAudioCompileStatus status;
  final BattleRecipeAudioSelection? selection;
  final BattleRecipeAudioCompileFailure? failure;
}

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
  static const groupedSplMaxTicks = 200;

  static const availableCapabilities = {
    'sequence',
    'parallel',
    'wait',
    'cameraFocus',
    'cameraReset',
  };

  BattleGroupedSplSelection? selectGroupedSpl(
    BattleMoveAnimationRecipe recipe,
  ) {
    final audio = recipe.audio;
    if (recipe.schemaVersion != 2 || audio is! BattleRecipeAudioClip) {
      return null;
    }
    const capabilities = {
      'sequence',
      'parallel',
      'wait',
      'startParticle',
      'waitEffects',
      'splParticleV2',
      'splParticleV3',
      'splParticleV4',
      'sound',
      'audioSelectionV2',
      'cameraFocus',
      'cameraReset',
      'gen5Swing',
      'gen5SpritePause',
    };
    if (recipe.unsupportedCapabilities(capabilities).isNotEmpty) return null;
    final source = recipe.toJson();
    final required = (source['requiredCapabilities'] as List).cast<String>();
    final program = (source['program'] as Map).cast<String, dynamic>();
    if (program['kind'] != 'sequence') return null;
    final sequence = program['steps'] as List;
    if (sequence.length != 2 && sequence.length != 4 && sequence.length != 6) return null;
    final hasCamera = sequence.length >= 4;
    final hasMotion = sequence.length == 6;
    if (required.contains('cameraFocus') != hasCamera ||
        required.contains('cameraReset') != hasCamera ||
        required.contains('gen5Swing') != hasMotion ||
        required.contains('gen5SpritePause') != hasMotion) {
      return null;
    }
    final focus = hasCamera ? (sequence.first as Map).cast<String, dynamic>() : null;
    final reset = hasCamera ? (sequence.last as Map).cast<String, dynamic>() : null;
    if (hasCamera && (focus!['kind'] != 'cameraFocus' || reset!['kind'] != 'cameraReset')) return null;
    final pause = hasMotion ? (sequence[1] as Map).cast<String, dynamic>() : null;
    final resume = hasMotion ? (sequence[4] as Map).cast<String, dynamic>() : null;
    if (hasMotion && (pause!['kind'] != 'gen5SpritePause' || pause['paused'] != true ||
        resume!['kind'] != 'gen5SpritePause' || resume['paused'] != false ||
        pause['target'] != resume['target'])) {
      return null;
    }
    final parallel = (sequence[hasMotion ? 2 : hasCamera ? 1 : 0] as Map).cast<String, dynamic>();
    final barrier = (sequence[hasMotion ? 3 : hasCamera ? 2 : 1] as Map).cast<String, dynamic>();
    if (parallel['kind'] != 'parallel' || barrier['kind'] != 'waitEffects') {
      return null;
    }
    final steps = parallel['steps'] as List;
    if (steps.isEmpty || steps.length > 32) return null;
    final resources = {
      for (final resource in recipe.resources) resource.id: resource,
    };
    final particles = <BattleGroupedSplParticle>[];
    final swings = <BattleGen5MotionSpec>[];
    final swingChannels = <(String, String)>{};
    int? definitionVersion;
    for (final value in steps) {
      var step = (value as Map).cast<String, dynamic>();
      var startTick = 0;
      if (step['kind'] == 'sequence') {
        final delayed = step['steps'] as List;
        if (delayed.length != 2) return null;
        final wait = (delayed.first as Map).cast<String, dynamic>();
        if (wait['kind'] != 'wait') return null;
        startTick = ((wait['durationMs'] as int) * 60 + 500) ~/ 1000;
        if (startTick >= groupedSplMaxTicks) return null;
        step = (delayed.last as Map).cast<String, dynamic>();
        if (step['kind'] != 'startParticle') return null;
      }
      if (step['kind'] == 'gen5Swing' && hasMotion) {
        final target = step['target'] as String;
        final channel = step['channel'] as String;
        if (!swingChannels.add((target, channel)) || swings.length >= 4) return null;
        swings.add(BattleGen5MotionSpec(
          target: target, channel: channel, x: step['x'] as int, y: step['y'] as int,
          frames: step['frames'] as int, wait: step['wait'] as int, count: step['count'] as int,
        ));
        continue;
      }
      if (step['kind'] != 'startParticle') return null;
      final id = step['resourceId'] as String;
      final resource = resources[id];
      if (resource == null || !{2, 3, 4}.contains(resource.definitionVersion)) {
        return null;
      }
      definitionVersion ??= resource.definitionVersion;
      if (resource.definitionVersion != definitionVersion) return null;
      particles.add((
        resourceId: id,
        from: step['from'] as String,
        to: step['to'] as String,
        startTick: startTick,
      ));
    }
    if (particles.isEmpty || (hasMotion &&
        (swings.isEmpty || !swings.any((swing) => swing.target == pause!['target'])))) {
      return null;
    }
    return (
      particles: List.unmodifiable(particles),
      audio: BattleMoveClipAudio(audio.resourceId),
      cameraBefore: focus == null ? null : (target: focus['target'] as String, durationMs: focus['durationMs'] as int),
      cameraAfterMs: reset == null ? null : reset['durationMs'] as int,
      swings: List.unmodifiable(swings),
      pausedTarget: pause?['target'] as String?,
    );
  }

  BattleRecipeAudioCompileResult compileAudioSelection(
    BattleMoveAnimationRecipe recipe,
  ) {
    final audio = recipe.audio;
    if (audio == null) {
      return const BattleRecipeAudioCompileResult._(
        BattleRecipeAudioCompileStatus.legacy,
      );
    }
    if (audio is BattleRecipeAudioNone) {
      return const BattleRecipeAudioCompileResult._(
        BattleRecipeAudioCompileStatus.silent,
      );
    }
    if (audio is BattleRecipeAudioClip) {
      return BattleRecipeAudioCompileResult._(
        BattleRecipeAudioCompileStatus.ready,
        selection: BattleMoveClipAudio(audio.resourceId),
      );
    }
    final events = (audio as BattleRecipeAudioSequence).events;
    if (events.length > 8) {
      return const BattleRecipeAudioCompileResult._(
        BattleRecipeAudioCompileStatus.unsupported,
        failure: BattleRecipeAudioCompileFailure.tooManyEvents,
      );
    }
    final selection = <BattleSeqAudioEvent>[];
    for (final event in events) {
      if (event.sourceId.length > 160) {
        return const BattleRecipeAudioCompileResult._(
          BattleRecipeAudioCompileStatus.unsupported,
          failure: BattleRecipeAudioCompileFailure.sourceIdTooLong,
        );
      }
      final offset = event.offset;
      if (offset.ticks > offset.ticksPerSecond * 30) {
        return const BattleRecipeAudioCompileResult._(
          BattleRecipeAudioCompileStatus.unsupported,
          failure: BattleRecipeAudioCompileFailure.offsetTooLate,
        );
      }
      final microseconds =
          (offset.ticks * 1000000 + offset.ticksPerSecond ~/ 2) ~/
          offset.ticksPerSecond;
      selection.add(
        BattleSeqAudioEvent(
          event.sourceId,
          event.resourceId,
          Duration(microseconds: microseconds),
        ),
      );
    }
    return BattleRecipeAudioCompileResult._(
      BattleRecipeAudioCompileStatus.ready,
      selection: BattleSeqAudio(selection),
    );
  }

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
