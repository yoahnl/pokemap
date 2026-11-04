import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_runner.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_recipe_compiler.dart';
import 'package:map_runtime/src/presentation/flame/battle_recipe_audio_program.dart';

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

  Map<String, dynamic> explicitAudioSource(Map<String, dynamic> audio) {
    final bytes = utf8.encode('synthetic');
    return {
      ...source(),
      'schemaVersion': 2,
      'requiredCapabilities': [
        'sequence',
        'parallel',
        'wait',
        'cameraFocus',
        'cameraReset',
        'audioSelectionV2',
        if (audio['kind'] != 'none') 'sound',
      ],
      'resources': [
        {
          'id': 'cue',
          'role': 'sound',
          'mediaType': 'audio/ogg',
          'sizeBytes': bytes.length,
          'sha256': sha256.convert(bytes).toString(),
        },
      ],
      'audio': audio,
    };
  }

  Map<String, dynamic> seqEvent({
    String sourceId = 'SEQ_EXAMPLE',
    int ticks = 1,
    int ticksPerSecond = 60,
  }) => {
    'sourceId': sourceId,
    'resourceId': 'cue',
    'offset': {'ticks': ticks, 'ticksPerSecond': ticksPerSecond},
  };

  const user = BattleSlotRef(side: BattleSideId.player, slotIndex: 1);
  const target = BattleSlotRef(side: BattleSideId.enemy, slotIndex: 1);
  const compiler = BattleMoveRecipeCompiler();

  Map<String, dynamic> groupedSplSource() {
    final result = explicitAudioSource({'kind': 'clip', 'resourceId': 'cue'});
    final bytes = utf8.encode('particle');
    result['requiredCapabilities'] = [
      'sequence',
      'parallel',
      'startParticle',
      'waitEffects',
      'splParticleV2',
      'sound',
      'audioSelectionV2',
    ];
    result['resources'] = [
      ...(result['resources'] as List),
      for (final id in ['from', 'to'])
        {
          'id': id,
          'role': 'particleDefinition',
          'mediaType': 'application/vnd.avelune.particle+json',
          'sizeBytes': bytes.length,
          'sha256': sha256.convert(bytes).toString(),
          'definitionVersion': 2,
          'dependencies': <String>[],
        },
    ];
    result['program'] = {
      'kind': 'sequence',
      'steps': [
        {
          'kind': 'parallel',
          'steps': [
            {
              'kind': 'startParticle',
              'resourceId': 'from',
              'from': 'userMouth',
              'to': 'targetImpact',
            },
            {
              'kind': 'startParticle',
              'resourceId': 'to',
              'from': 'targetImpact',
              'to': 'targetImpact',
            },
          ],
        },
        {'kind': 'waitEffects'},
      ],
    };
    return result;
  }

  test('selects a bounded grouped SPL recipe with its explicit clip', () {
    final recipe = BattleMoveAnimationRecipe.fromJson(groupedSplSource());
    final selected = compiler.selectGroupedSpl(recipe)!;
    expect(selected.particles, [
      (resourceId: 'from', from: 'userMouth', to: 'targetImpact', startTick: 0),
      (resourceId: 'to', from: 'targetImpact', to: 'targetImpact', startTick: 0),
    ]);
    expect(selected.audio.resourceId, 'cue');
    expect(() => selected.particles.clear(), throwsUnsupportedError);
  });

  test('schedules a delayed emitter without shifting the others', () {
    final input = groupedSplSource();
    (input['requiredCapabilities'] as List).add('wait');
    final steps = (input['program'] as Map)['steps'] as List;
    final particles = List<dynamic>.from((steps.first as Map)['steps'] as List);
    (steps.first as Map)['steps'] = particles;
    particles[1] = {
      'kind': 'sequence',
      'steps': [
        {'kind': 'wait', 'durationMs': 1167},
        particles[1],
      ],
    };
    final selected = compiler.selectGroupedSpl(BattleMoveAnimationRecipe.fromJson(input))!;
    expect(selected.particles.map((particle) => particle.startTick), [0, 70]);
    ((particles[1] as Map)['steps'] as List).first['durationMs'] = 4000;
    expect(compiler.selectGroupedSpl(BattleMoveAnimationRecipe.fromJson(input)), isNull);
  });

  test('selects grouped SPL v3 but refuses mixed definition versions', () {
    final input = groupedSplSource();
    (input['requiredCapabilities'] as List).add('splParticleV3');
    final definitions = (input['resources'] as List)
        .where((item) => (item as Map)['role'] == 'particleDefinition')
        .cast<Map<String, dynamic>>()
        .toList();
    definitions.first['definitionVersion'] = 3;
    expect(
      compiler.selectGroupedSpl(BattleMoveAnimationRecipe.fromJson(input)),
      isNull,
    );
    definitions.last['definitionVersion'] = 3;
    final selected = compiler.selectGroupedSpl(
      BattleMoveAnimationRecipe.fromJson(input),
    );
    expect(selected?.particles, hasLength(2));
  });

  test('selects grouped SPL v5 while retaining the mixed-version guard', () {
    final input = groupedSplSource();
    (input['requiredCapabilities'] as List).add('splParticleV5');
    final definitions = (input['resources'] as List)
        .where((item) => (item as Map)['role'] == 'particleDefinition')
        .cast<Map<String, dynamic>>()
        .toList();
    definitions.first['definitionVersion'] = 5;
    expect(compiler.selectGroupedSpl(BattleMoveAnimationRecipe.fromJson(input)), isNull);
    definitions.last['definitionVersion'] = 5;
    expect(compiler.selectGroupedSpl(BattleMoveAnimationRecipe.fromJson(input))?.particles, hasLength(2));
  });

  test('keeps camera movements around a grouped particle effect', () {
    final input = groupedSplSource();
    (input['requiredCapabilities'] as List).addAll(<String>['cameraFocus', 'cameraReset']);
    final steps = (input['program'] as Map)['steps'] as List;
    steps.insert(0, {'kind': 'cameraFocus', 'target': 'target', 'durationMs': 267});
    steps.add({'kind': 'cameraReset', 'durationMs': 267});
    final selected = compiler.selectGroupedSpl(BattleMoveAnimationRecipe.fromJson(input));
    expect(selected, isNotNull);
    expect(selected!.cameraBefore, (target: 'target', durationMs: 267));
    expect(selected.cameraAfterMs, 267);
  });

  test('selects paired sprite pause and bounded swings around a grouped effect', () {
    final input = groupedSplSource();
    (input['requiredCapabilities'] as List).addAll(<String>[
      'cameraFocus', 'cameraReset', 'gen5Swing', 'gen5SpritePause',
    ]);
    final steps = (input['program'] as Map)['steps'] as List;
    final parallel = steps.first as Map;
    parallel['steps'] = [...parallel['steps'] as List, ...<Map<String, Object>>[
      {'kind': 'gen5Swing', 'target': 'user', 'channel': 'position', 'x': 4096, 'y': 0, 'frames': 4, 'wait': 1, 'count': 1},
      {'kind': 'gen5Swing', 'target': 'target', 'channel': 'scale', 'x': 1229, 'y': -1229, 'frames': 2, 'wait': 1, 'count': 1},
    ]];
    steps.insert(0, {'kind': 'gen5SpritePause', 'target': 'target', 'paused': true});
    steps.insert(0, {'kind': 'cameraFocus', 'target': 'target', 'durationMs': 267});
    steps.add({'kind': 'gen5SpritePause', 'target': 'target', 'paused': false});
    steps.add({'kind': 'cameraReset', 'durationMs': 267});
    final selected = compiler.selectGroupedSpl(BattleMoveAnimationRecipe.fromJson(input));
    expect(selected, isNotNull);
    expect(selected!.swings, hasLength(2));
    expect(selected.pausedTarget, 'target');
    (steps[4] as Map)['target'] = 'user';
    expect(compiler.selectGroupedSpl(BattleMoveAnimationRecipe.fromJson(input)), isNull);
  });

  test('does not partially select unsupported grouped recipes', () {
    final silent = groupedSplSource();
    silent['audio'] = {'kind': 'none'};
    (silent['requiredCapabilities'] as List).remove('sound');

    final extraCapability = groupedSplSource();
    (extraCapability['requiredCapabilities'] as List).add('cameraFocus');

    final extraStep = groupedSplSource();
    final steps = (extraStep['program'] as Map)['steps'] as List;
    steps.add({'kind': 'waitEffects'});

    final oversized = groupedSplSource();
    final sequence = (oversized['program'] as Map)['steps'] as List;
    final parallel = sequence.first as Map;
    final original = parallel['steps'] as List;
    parallel['steps'] = [
      ...original,
      ...List.generate(31, (_) => Map.of(original.first as Map)),
    ];

    final mixedVersions = groupedSplSource();
    final definitions = (mixedVersions['resources'] as List)
        .where((item) => (item as Map)['role'] == 'particleDefinition')
        .cast<Map<String, dynamic>>()
        .toList();
    definitions.first['definitionVersion'] = 1;

    for (final input in [
      silent,
      extraCapability,
      extraStep,
      oversized,
      mixedVersions,
    ]) {
      expect(
        compiler.selectGroupedSpl(BattleMoveAnimationRecipe.fromJson(input)),
        isNull,
      );
    }
  });

  test('keeps legacy and silent audio distinct from an explicit clip', () {
    final legacy = compiler.compileAudioSelection(
      BattleMoveAnimationRecipe.fromJson(source()),
    );
    expect(legacy.status, BattleRecipeAudioCompileStatus.legacy);
    expect(legacy.selection, isNull);

    final oldSound = source();
    final bytes = utf8.encode('synthetic');
    oldSound['requiredCapabilities'] = ['sound'];
    oldSound['resources'] = [
      {
        'id': 'cue',
        'role': 'sound',
        'mediaType': 'audio/ogg',
        'sizeBytes': bytes.length,
        'sha256': sha256.convert(bytes).toString(),
      },
    ];
    oldSound['program'] = {'kind': 'sound', 'resourceId': 'cue'};
    final legacySound = compiler.compileAudioSelection(
      BattleMoveAnimationRecipe.fromJson(oldSound),
    );
    expect(legacySound.status, BattleRecipeAudioCompileStatus.legacy);
    expect(legacySound.selection, isNull);

    final silent = compiler.compileAudioSelection(
      BattleMoveAnimationRecipe.fromJson(explicitAudioSource({'kind': 'none'})),
    );
    expect(silent.status, BattleRecipeAudioCompileStatus.silent);
    expect(silent.selection, isNull);

    final clip = compiler.compileAudioSelection(
      BattleMoveAnimationRecipe.fromJson(
        explicitAudioSource({'kind': 'clip', 'resourceId': 'cue'}),
      ),
    );
    expect(clip.status, BattleRecipeAudioCompileStatus.ready);
    expect((clip.selection as BattleMoveClipAudio).resourceId, 'cue');
  });

  test('converts explicit rational SEQ offsets independently', () {
    final recipe = BattleMoveAnimationRecipe.fromJson(
      explicitAudioSource({
        'kind': 'seq',
        'events': [
          seqEvent(ticks: 1, ticksPerSecond: 400000),
          seqEvent(),
          seqEvent(ticks: 2, ticksPerSecond: 120),
          seqEvent(ticks: 2),
          seqEvent(ticks: 3),
        ],
      }),
    );
    final result = compiler.compileAudioSelection(recipe);
    expect(result.status, BattleRecipeAudioCompileStatus.ready);
    final events = (result.selection as BattleSeqAudio).events;
    expect(events.map((item) => item.sourceId), List.filled(5, 'SEQ_EXAMPLE'));
    expect(events.map((item) => item.offset.inMicroseconds), [
      3,
      16667,
      16667,
      33333,
      50000,
    ]);
    expect(
      (recipe.audio as BattleRecipeAudioSequence).events[1].offset.ticks,
      1,
    );
    expect(
      (recipe.audio as BattleRecipeAudioSequence)
          .events[1]
          .offset
          .ticksPerSecond,
      60,
    );
  });

  test('reports runtime audio limits without truncating valid recipes', () {
    final boundary = BattleMoveAnimationRecipe.fromJson(
      explicitAudioSource({
        'kind': 'seq',
        'events': List.generate(
          8,
          (_) => seqEvent(ticks: 30, ticksPerSecond: 1),
        ),
      }),
    );
    final atLimit = compiler.compileAudioSelection(boundary);
    expect(atLimit.status, BattleRecipeAudioCompileStatus.ready);
    expect(
      (atLimit.selection as BattleSeqAudio).events.map((event) => event.offset),
      List.filled(8, const Duration(seconds: 30)),
    );
    final examples = [
      (
        List.generate(9, (_) => seqEvent()),
        BattleRecipeAudioCompileFailure.tooManyEvents,
      ),
      ([seqEvent(ticks: 1801)], BattleRecipeAudioCompileFailure.offsetTooLate),
      (
        [seqEvent(sourceId: 'x' * 161)],
        BattleRecipeAudioCompileFailure.sourceIdTooLong,
      ),
    ];
    for (final (events, failure) in examples) {
      final recipe = BattleMoveAnimationRecipe.fromJson(
        explicitAudioSource({'kind': 'seq', 'events': events}),
      );
      final result = compiler.compileAudioSelection(recipe);
      expect(result.status, BattleRecipeAudioCompileStatus.unsupported);
      expect(result.failure, failure);
      expect(result.selection, isNull);
      expect(
        (recipe.audio as BattleRecipeAudioSequence).events,
        hasLength(events.length),
      );
    }
  });

  test('v2 audio is unavailable to the existing Player compiler', () {
    for (final audio in [
      {'kind': 'none'},
      {'kind': 'clip', 'resourceId': 'cue'},
    ]) {
      final recipe = BattleMoveAnimationRecipe.fromJson(
        explicitAudioSource(audio),
      );
      expect(
        recipe.unsupportedCapabilities(
          BattleMoveRecipeCompiler.availableCapabilities,
        ),
        contains('audioSelectionV2'),
      );
      expect(
        () => compiler.prepare(recipe, {'cue': utf8.encode('synthetic')}),
        throwsFormatException,
      );
    }
    expect(BattleMoveRecipeCompiler.supportsCompleteMoveVisuals, isFalse);
  });

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
