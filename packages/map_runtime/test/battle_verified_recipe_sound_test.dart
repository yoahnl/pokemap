import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_sfx_player.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_runner.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_bundle_cache.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_audio_scope.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_turn_animation_planner.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_recipe_audio_program.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_offline_move_recipe_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_verified_recipe_sound_loader.dart';
import 'package:path/path.dart' as p;

import 'support/load_flame_component.dart';
import 'support/offline_recipe_package_fixture.dart';

Future<InspectedBattleRecipeBundle> _bundle({
  Uint8List? audio,
  String mediaType = 'audio/wav',
}) async {
  final sound =
      audio ?? await File('assets/audio/overworld/jump.wav').readAsBytes();
  final recipe = Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'schemaVersion': 1,
        'recipeId': 'fire',
        'revision': '1',
        'moveSourceId': 'flamethrower',
        'variant': 'default',
        'requiredCapabilities': ['sound'],
        'provenance': {
          'source': 'synthetic',
          'sourceRevision': '1',
          'sourcePaths': <String>[],
          'converter': 'test',
        },
        'resources': [
          {
            'id': 'cue',
            'role': 'sound',
            'mediaType': mediaType,
            'sizeBytes': sound.length,
            'sha256': sha256.convert(sound).toString(),
          },
        ],
        'program': {'kind': 'sound', 'resourceId': 'cue'},
      }),
    ),
  );
  final binding = BattleMoveRecipeBinding.fromJson({
    'schemaVersion': 1,
    'projectMoveId': 'local-fire',
    'sourceMoveId': 'flamethrower',
    'catalogReleaseId': 'fixture',
    'recipeId': 'fire',
    'variant': 'default',
    'revision': '1',
    'recipeSha256': sha256.convert(recipe).toString(),
  });
  return const BattleRecipeBundleInspector().inspect(
    binding,
    recipe,
    {'cue': sound},
    limits: const BattleRecipeBundleLimits(
      maxTextures: 0,
      maxTextureBytes: 0,
      maxBundleBytes: 8 * 1024 * 1024,
      maxDimension: 1,
      maxTexturePixels: 1,
      maxTotalPixels: 1,
    ),
    availableCapabilities: const {'sound'},
    expectedProjectMoveId: 'local-fire',
    expectedCatalogReleaseId: 'fixture',
  );
}

Future<BattleOfflineVerifiedMedia> _groupedOfflineMedia(
  Directory root,
  RuntimeResourceBudget budget, {
  String? fixtureRoot,
}) async {
  final fetched = await groupedSplRecipeFixture(fixtureRoot: fixtureRoot);
  Future<void> write(String path, List<int> bytes) async {
    final file = File(p.join(root.path, path));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  await write(
    battleRecipeBindingPath('tackle'),
    utf8.encode(jsonEncode(BattleRecipeProjectBinding(binding: fetched.binding).toJson())),
  );
  await write(
    battleRecipeBlobPath(
      fetched.binding.recipeSha256,
      'application/vnd.avelune.battle-recipe+json',
      projectMoveId: 'tackle',
    ),
    fetched.bundle.recipeBytes,
  );
  for (final resource in fetched.bundle.recipe.resources) {
    await write(
      battleRecipeBlobPath(resource.sha256Hex, resource.mediaType, projectMoveId: 'tackle'),
      fetched.bundle.media[resource.id]!,
    );
  }
  final result = await BattleOfflineMoveRecipeLoader(
    projectRootDirectory: root.path,
    resourceBudget: budget,
  ).load('tackle', retainVerifiedMedia: true);
  return result.verifiedMedia!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('audio preparation releases its verified bundle reference', () async {
    final bundle = await _bundle();
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final coordinator = BattleRecipeAudioCoordinator(
      player: player,
      bundle: bundle,
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    addTearDown(coordinator.cancel);
    expect(identical(coordinator.bundle, bundle), isTrue);
    final result = await coordinator.prepare(const BattleMoveClipAudio('cue'));
    expect(result.status, BattleRecipeAudioStatus.ready);
    expect(() => coordinator.bundle, throwsStateError);
    final cancelled = BattleRecipeAudioCoordinator(
      player: player,
      bundle: bundle,
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    await cancelled.cancel();
    expect(() => cancelled.bundle, throwsStateError);
  });

  test('runs a complete clip once without replaying SEQ sounds', () async {
    final bundle = await _bundle();
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: bundle,
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    final result = await audio.prepare(const BattleMoveClipAudio('cue'));
    expect(result.status, BattleRecipeAudioStatus.ready);
    final program = result.program!;
    expect(program.sourceSeqIds, isEmpty);
    final legacy = <String>[];
    var hpChanges = 0;
    final runner = BattleAnimationRunner(
      onPresentationChanged: () {},
      onSpawnFx: (_) {},
      onScreenFlash: (_) {},
      onCombatantMotion: (_) {},
      onCombatantFlash: (_) {},
      onCombatantShake: (_) {},
      onFaintCombatant: (_) {},
      onHudHpTween: (_) => hpChanges++,
      onBarrierPulse: (_) {},
      onSwapCombatantVisual: (_) {},
      onPlaySe: (step) {
        if (!program.dispatch(step)) legacy.add(step.seName);
      },
    );
    runner.start(
      BattleAnimationPlan(
        steps: [
          ...program.steps,
          const PlaySeStep(seName: 'impact'),
          const HudHpTweenStep(side: BattleSideId.enemy, fromHp: 40, toHp: 20),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(voice.resumes, 1);
    expect(legacy, ['impact']);
    expect(hpChanges, 1);
    expect(program.dispatch(program.steps.single as PlaySeStep), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(voice.resumes, 1);
    await audio.cancel();
  });

  test(
    'uses fallback once if preparation times out before any sound starts',
    () async {
      final bundle = await _bundle();
      final gate = Completer<void>();
      final voice = _Voice(sourceGate: gate);
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: bundle,
        preparationTimeout: const Duration(milliseconds: 50),
        startTimeout: const Duration(seconds: 1),
      );
      try {
        final result = await audio.prepare(const BattleMoveClipAudio('cue'));
        expect(result.status, BattleRecipeAudioStatus.fallback);
        expect(result.failure, BattleRecipeAudioFailure.preparationTimeout);
        await audio.cancel();
        expect(voice.resumes, 0);
        expect(voice.disposals, 1);
        final events = <String>[];
        var hpChanges = 0;
        final runner = BattleAnimationRunner(
          onPresentationChanged: () {},
          onSpawnFx: (_) {},
          onScreenFlash: (_) {},
          onCombatantMotion: (_) {},
          onCombatantFlash: (_) {},
          onCombatantShake: (_) {},
          onFaintCombatant: (_) {},
          onHudHpTween: (_) => hpChanges++,
          onBarrierPulse: (_) {},
          onSwapCombatantVisual: (_) {},
          onPlaySe: (step) => events.add(step.seName),
        );
        runner.start(
          BattleAnimationPlan(
            steps: [
              ...result.stepsOrFallback(const [PlaySeStep(seName: 'legacy')]),
              const PlaySeStep(seName: 'impact'),
              const HudHpTweenStep(
                side: BattleSideId.enemy,
                fromHp: 40,
                toHp: 20,
              ),
            ],
          ),
        );
        expect(events, ['legacy', 'impact']);
        expect(hpChanges, 1);
      } finally {
        gate.complete();
      }
    },
  );

  test('preflight fallback does not wait for a stuck native cleanup', () async {
    final bundle = await _bundle();
    final sourceGate = Completer<void>();
    final stopGate = Completer<void>();
    final voice = _Voice(sourceGate: sourceGate, stopGate: stopGate);
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: bundle,
      preparationTimeout: const Duration(milliseconds: 50),
      startTimeout: const Duration(seconds: 1),
    );
    final result = await audio
        .prepare(const BattleMoveClipAudio('cue'))
        .timeout(const Duration(milliseconds: 500));
    try {
      expect(result.status, BattleRecipeAudioStatus.fallback);
      expect(result.failure, BattleRecipeAudioFailure.preparationTimeout);
      expect(voice.resumes, 0);
      await voice.stopping.future;
      var cleaned = false;
      final cleanup = audio.cancel().then((_) => cleaned = true);
      await Future<void>.delayed(Duration.zero);
      expect(cleaned, isFalse);
      stopGate.complete();
      await cleanup;
      expect(cleaned, isTrue);
    } finally {
      sourceGate.complete();
      if (!stopGate.isCompleted) stopGate.complete();
      await audio.cancel();
    }
  });

  test('preparation deadline includes synchronous player setup', () async {
    final bundle = await _bundle();
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(
      playerFactory: () {
        sleep(const Duration(milliseconds: 70));
        return voice;
      },
    );
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: bundle,
      preparationTimeout: const Duration(milliseconds: 40),
      startTimeout: const Duration(seconds: 1),
    );
    final result = await audio.prepare(const BattleMoveClipAudio('cue'));
    expect(result.status, BattleRecipeAudioStatus.fallback);
    expect(result.failure, BattleRecipeAudioFailure.preparationTimeout);
    await audio.cancel();
    expect(voice.resumes, 0);
    expect(voice.disposals, 1);
  });

  test('a timed-out start never replays the legacy sound or damage', () async {
    final bundle = await _bundle();
    final gate = Completer<void>();
    final voice = _Voice(resumeGate: gate);
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: bundle,
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(milliseconds: 50),
    );
    try {
      final result = await audio.prepare(const BattleMoveClipAudio('cue'));
      final program = result.program!;
      final events = <String>[];
      var hpChanges = 0;
      final runner = BattleAnimationRunner(
        onPresentationChanged: () {},
        onSpawnFx: (_) {},
        onScreenFlash: (_) {},
        onCombatantMotion: (_) {},
        onCombatantFlash: (_) {},
        onCombatantShake: (_) {},
        onFaintCombatant: (_) {},
        onHudHpTween: (_) => hpChanges++,
        onBarrierPulse: (_) {},
        onSwapCombatantVisual: (_) {},
        onPlaySe: (step) {
          if (!program.dispatch(step)) events.add(step.seName);
        },
      );
      runner.start(
        BattleAnimationPlan(
          steps: [
            ...result.stepsOrFallback(const [PlaySeStep(seName: 'legacy')]),
            const PlaySeStep(seName: 'impact'),
            const HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 40,
              toHp: 20,
            ),
          ],
        ),
      );
      final failure = await program.playbackFailure.timeout(
        const Duration(seconds: 1),
      );
      expect(failure, isA<TimeoutException>());
      await audio.cancel();
      expect(voice.resumes, 1);
      expect(events, ['impact']);
      expect(hpChanges, 1);
    } finally {
      gate.completeError(StateError('late player failure'));
      await Future<void>.delayed(Duration.zero);
    }
  });

  test(
    'cancelling preparation suppresses fallback and pending playback',
    () async {
      final bundle = await _bundle();
      final gate = Completer<void>();
      final voice = _Voice(sourceGate: gate);
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: bundle,
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      final pending = audio.prepare(const BattleMoveClipAudio('cue'));
      await voice.sourceSet.future;
      try {
        final closing = audio.cancel();
        final result = await pending.timeout(const Duration(milliseconds: 500));
        expect(result.status, BattleRecipeAudioStatus.cancelled);
        expect(
          result.stepsOrFallback(const [PlaySeStep(seName: 'legacy')]),
          isEmpty,
        );
        final scope = BattleMoveAudioScope.compose(
          audio: result,
          silentVisuals: const AnimationGroupStep(
            mode: BattleAnimationGroupMode.parallel,
            steps: [WaitStep(durationSeconds: .1)],
          ),
          fallback: const [PlaySeStep(seName: 'legacy')],
        );
        expect(scope.status, BattleRecipeAudioStatus.cancelled);
        expect(scope.steps, isEmpty);
        expect(scope.audioScopes, isEmpty);
        await closing.timeout(const Duration(milliseconds: 500));
        expect(voice.resumes, 0);
        expect(voice.disposals, 1);
      } finally {
        gate.completeError(StateError('late decoder failure'));
        await Future<void>.delayed(Duration.zero);
      }
    },
  );

  test(
    'a missing SEQ resource falls back before any prepared sound starts',
    () async {
      final bundle = await _bundle();
      final voices = <_Voice>[];
      final player = FlameAudioBattleSfxPlayer(
        playerFactory: () {
          final voice = _Voice();
          voices.add(voice);
          return voice;
        },
      );
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: bundle,
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      final result = await audio.prepare(
        BattleSeqAudio([
          const BattleSeqAudioEvent('SEQ_FIRST', 'cue', Duration.zero),
          const BattleSeqAudioEvent(
            'SEQ_MISSING',
            'missing',
            Duration(milliseconds: 200),
          ),
        ]),
      );
      expect(result.status, BattleRecipeAudioStatus.fallback);
      expect(result.failure, BattleRecipeAudioFailure.unavailable);
      expect(
        result.stepsOrFallback(const [PlaySeStep(seName: 'legacy')]),
        hasLength(1),
      );
      await audio.cancel();
      expect(voices, hasLength(1));
      expect(voices.single.resumes, 0);
      expect(voices.single.disposals, 1);
    },
  );

  test(
    'rejects out-of-order SEQ offsets without preparing any voice',
    () async {
      final bundle = await _bundle();
      final voices = <_Voice>[];
      final player = FlameAudioBattleSfxPlayer(
        playerFactory: () {
          final voice = _Voice();
          voices.add(voice);
          return voice;
        },
      );
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: bundle,
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      final result = await audio.prepare(
        BattleSeqAudio([
          const BattleSeqAudioEvent('SEQ_LATE', 'cue', Duration(seconds: 1)),
          const BattleSeqAudioEvent('SEQ_EARLY', 'cue', Duration.zero),
        ]),
      );
      expect(result.status, BattleRecipeAudioStatus.fallback);
      expect(result.failure, BattleRecipeAudioFailure.invalidSelection);
      expect(voices, isEmpty);
      final oversizedTimeout = BattleRecipeAudioCoordinator(
        player: player,
        bundle: bundle,
        preparationTimeout: const Duration(seconds: 31),
        startTimeout: const Duration(seconds: 1),
      );
      final invalid = await oversizedTimeout.prepare(
        const BattleMoveClipAudio('cue'),
      );
      expect(invalid.status, BattleRecipeAudioStatus.fallback);
      expect(invalid.failure, BattleRecipeAudioFailure.invalidSelection);
      expect(voices, isEmpty);
    },
  );

  test('a failed first SEQ sound suppresses later SEQ events', () async {
    final bundle = await _bundle();
    final gate = Completer<void>();
    final voices = <_Voice>[];
    final player = FlameAudioBattleSfxPlayer(
      playerFactory: () {
        final voice = _Voice(resumeGate: voices.isEmpty ? gate : null);
        voices.add(voice);
        return voice;
      },
    );
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: bundle,
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(milliseconds: 50),
    );
    try {
      final result = await audio.prepare(
        BattleSeqAudio([
          const BattleSeqAudioEvent('SEQ_FIRST', 'cue', Duration.zero),
          const BattleSeqAudioEvent(
            'SEQ_SECOND',
            'cue',
            Duration(milliseconds: 200),
          ),
        ]),
      );
      final program = result.program!;
      final unexpected = <String>[];
      var hpChanges = 0;
      final runner = BattleAnimationRunner(
        onPresentationChanged: () {},
        onSpawnFx: (_) {},
        onScreenFlash: (_) {},
        onCombatantMotion: (_) {},
        onCombatantFlash: (_) {},
        onCombatantShake: (_) {},
        onFaintCombatant: (_) {},
        onHudHpTween: (_) => hpChanges++,
        onBarrierPulse: (_) {},
        onSwapCombatantVisual: (_) {},
        onPlaySe: (step) {
          if (!program.dispatch(step)) unexpected.add(step.seName);
        },
      );
      runner.start(
        BattleAnimationPlan(
          steps: [
            ...program.steps,
            const HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 40,
              toHp: 20,
            ),
          ],
        ),
      );
      expect(
        await program.playbackFailure.timeout(const Duration(seconds: 1)),
        isA<TimeoutException>(),
      );
      await audio.cancel();
      runner.update(.2);
      await Future<void>.delayed(Duration.zero);
      expect(voices.map((voice) => voice.resumes), [1, 0]);
      expect(unexpected, isEmpty);
      expect(hpChanges, 1);
    } finally {
      gate.completeError(StateError('late playback failure'));
      await Future<void>.delayed(Duration.zero);
    }
  });

  test('a completed short sound does not cancel later SEQ events', () async {
    final bundle = await _bundle();
    final gate = Completer<void>();
    final voices = <_Voice>[];
    final player = FlameAudioBattleSfxPlayer(
      playerFactory: () {
        final voice = _Voice(resumeGate: voices.isEmpty ? gate : null);
        voices.add(voice);
        return voice;
      },
    );
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: bundle,
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    try {
      final result = await audio.prepare(
        BattleSeqAudio([
          const BattleSeqAudioEvent('SEQ_FIRST', 'cue', Duration.zero),
          const BattleSeqAudioEvent(
            'SEQ_SECOND',
            'cue',
            Duration(milliseconds: 200),
          ),
        ]),
      );
      final program = result.program!;
      var failed = false;
      program.playbackFailure.then((_) => failed = true);
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
        onPlaySe: program.dispatch,
      );
      runner.start(BattleAnimationPlan(steps: program.steps));
      await voices[0].resuming.future;
      final source = File((voices[0].source as DeviceFileSource).path);
      voices[0].complete.add(null);
      await voices[0].disposed.future;
      for (var i = 0; i < 100 && await source.parent.exists(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(failed, isFalse);
      runner.update(.2);
      await Future<void>.delayed(Duration.zero);
      expect(voices.map((voice) => voice.resumes), [1, 1]);
    } finally {
      gate.complete();
      await audio.cancel();
    }
  });

  test(
    'schedules individually identified SEQ sounds at their own offsets',
    () async {
      final bundle = await _bundle();
      final voices = <_Voice>[];
      final player = FlameAudioBattleSfxPlayer(
        playerFactory: () {
          final voice = _Voice();
          voices.add(voice);
          return voice;
        },
      );
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: bundle,
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      final result = await audio.prepare(
        BattleSeqAudio([
          const BattleSeqAudioEvent('SEQ_FIRST', 'cue', Duration.zero),
          const BattleSeqAudioEvent(
            'SEQ_SECOND',
            'cue',
            Duration(milliseconds: 500),
          ),
        ]),
      );
      expect(result.status, BattleRecipeAudioStatus.ready);
      final program = result.program!;
      expect(program.sourceSeqIds, ['SEQ_FIRST', 'SEQ_SECOND']);
      var hpChanges = 0;
      final legacy = <String>[];
      final runner = BattleAnimationRunner(
        onPresentationChanged: () {},
        onSpawnFx: (_) {},
        onScreenFlash: (_) {},
        onCombatantMotion: (_) {},
        onCombatantFlash: (_) {},
        onCombatantShake: (_) {},
        onFaintCombatant: (_) {},
        onHudHpTween: (_) => hpChanges++,
        onBarrierPulse: (_) {},
        onSwapCombatantVisual: (_) {},
        onPlaySe: (step) {
          if (!program.dispatch(step)) legacy.add(step.seName);
        },
      );
      runner.start(
        BattleAnimationPlan(
          steps: [
            ...program.steps,
            const PlaySeStep(seName: 'impact'),
            const HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 40,
              toHp: 20,
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(voices.map((voice) => voice.resumes), [1, 0]);
      expect(legacy, isEmpty);
      expect(hpChanges, 0);
      runner.update(.5);
      await Future<void>.delayed(Duration.zero);
      expect(voices.map((voice) => voice.resumes), [1, 1]);
      expect(legacy, ['impact']);
      expect(hpChanges, 1);
      await audio.cancel();
    },
  );

  test(
    'selected move clip replaces legacy move audio but keeps impact and HP',
    () async {
      final bundle = await _bundle();
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: bundle,
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final result = await audio.prepare(const BattleMoveClipAudio('cue'));
      final scope = BattleMoveAudioScope.compose(
        audio: result,
        silentVisuals: const AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: [WaitStep(durationSeconds: .1)],
        ),
        fallback: const [
          PlaySeStep(seName: 'legacy-move'),
          WaitStep(durationSeconds: .1),
        ],
      );
      final sounds = <String>[];
      var hpTransitions = 0;
      final runner = BattleAnimationRunner(
        onPresentationChanged: () {},
        onSpawnFx: (_) {},
        onScreenFlash: (_) {},
        onCombatantMotion: (_) {},
        onCombatantFlash: (_) {},
        onCombatantShake: (_) {},
        onFaintCombatant: (_) {},
        onHudHpTween: (_) => hpTransitions++,
        onBarrierPulse: (_) {},
        onSwapCombatantVisual: (_) {},
        onPlaySe: (step) => sounds.add(step.seName),
      );
      runner.start(
        BattleAnimationPlan(
          steps: [
            ...scope.steps,
            const PlaySeStep(seName: 'impact'),
            const HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 25,
              toHp: 15,
            ),
          ],
          audioScopes: scope.audioScopes,
        ),
      );
      runner.update(.1);
      await Future<void>.delayed(Duration.zero);
      expect(voice.resumes, 1);
      expect(sounds, ['impact']);
      expect(hpTransitions, 1);
    },
  );

  test('audio tokens are intercepted only inside their move scope', () async {
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: await _bundle(),
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    addTearDown(audio.cancel);
    final result = await audio.prepare(const BattleMoveClipAudio('cue'));
    final token = result.program!.steps.whereType<PlaySeStep>().single.seName;
    final scope = BattleMoveAudioScope.compose(
      audio: result,
      silentVisuals: const AnimationGroupStep(
        mode: BattleAnimationGroupMode.parallel,
        steps: [WaitStep(durationSeconds: .1)],
      ),
      fallback: const [],
    );
    final legacy = <String>[];
    final runner = _scopeRunner(onPlaySe: (step) => legacy.add(step.seName));
    runner.start(
      BattleAnimationPlan(
        steps: [
          PlaySeStep(seName: token),
          ...scope.steps,
        ],
        audioScopes: scope.audioScopes,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(legacy, [token]);
    expect(voice.resumes, 1);
  });

  test('a scoped audio cue cannot also occur outside its scope', () async {
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: await _bundle(),
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    addTearDown(audio.cancel);
    final result = await audio.prepare(const BattleMoveClipAudio('cue'));
    final cue = result.program!.steps.whereType<PlaySeStep>().single;
    final scope = BattleMoveAudioScope.compose(
      audio: result,
      silentVisuals: const AnimationGroupStep(
        mode: BattleAnimationGroupMode.parallel,
        steps: [WaitStep(durationSeconds: .1)],
      ),
      fallback: const [],
    );
    final runner = _scopeRunner();
    expect(
      () => runner.start(
        BattleAnimationPlan(
          steps: [cue, ...scope.steps],
          audioScopes: scope.audioScopes,
        ),
      ),
      throwsStateError,
    );
    expect(voice.resumes, 0);
  });

  test(
    'a prepared scope cannot be started twice or interrupt its first run',
    () async {
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final scope = BattleMoveAudioScope.compose(
        audio: await audio.prepare(const BattleMoveClipAudio('cue')),
        silentVisuals: const AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: [WaitStep(durationSeconds: .1)],
        ),
        fallback: const [],
      );
      var hpTransitions = 0;
      final runner = _scopeRunner(onHudHpTween: (_) => hpTransitions++);
      final plan = BattleAnimationPlan(
        steps: [
          ...scope.steps,
          const HudHpTweenStep(side: BattleSideId.enemy, fromHp: 25, toHp: 15),
        ],
        audioScopes: scope.audioScopes,
      );
      runner.start(plan);
      expect(() => runner.start(plan), throwsStateError);
      runner.update(.1);
      await Future<void>.delayed(Duration.zero);
      expect(voice.resumes, 1);
      expect(hpTransitions, 1);
    },
  );

  test(
    'SEQ cues follow their offsets alongside an explicit visual sequence',
    () async {
      final voices = <_Voice>[];
      final player = FlameAudioBattleSfxPlayer(
        playerFactory: () {
          final voice = _Voice();
          voices.add(voice);
          return voice;
        },
      );
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final scope = BattleMoveAudioScope.compose(
        audio: await audio.prepare(
          BattleSeqAudio([
            const BattleSeqAudioEvent('first', 'cue', Duration.zero),
            const BattleSeqAudioEvent(
              'second',
              'cue',
              Duration(milliseconds: 200),
            ),
          ]),
        ),
        silentVisuals: const AnimationGroupStep(
          mode: BattleAnimationGroupMode.sequence,
          steps: [
            ScreenFlashStep(colorArgb: 1, durationSeconds: .1),
            ScreenFlashStep(colorArgb: 2, durationSeconds: .2),
          ],
        ),
        fallback: const [PlaySeStep(seName: 'legacy-move')],
      );
      final events = <String>[];
      var hpTransitions = 0;
      final runner = _scopeRunner(
        onPlaySe: (step) => events.add(step.seName),
        onScreenFlash: (step) => events.add('flash:${step.colorArgb}'),
        onHudHpTween: (_) => hpTransitions++,
      );
      runner.start(
        BattleAnimationPlan(
          steps: [
            ...scope.steps,
            const PlaySeStep(seName: 'impact'),
            const HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 25,
              toHp: 15,
            ),
          ],
          audioScopes: scope.audioScopes,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(voices.map((voice) => voice.resumes), [1, 0]);
      expect(events, ['flash:1']);
      runner.update(.1);
      expect(events, ['flash:1', 'flash:2']);
      runner.update(.1);
      await Future<void>.delayed(Duration.zero);
      expect(voices.map((voice) => voice.resumes), [1, 1]);
      expect(hpTransitions, 0);
      runner.update(.1);
      expect(events, ['flash:1', 'flash:2', 'impact']);
      expect(hpTransitions, 1);
    },
  );

  test(
    'RMXP visuals with implicit audio retain the complete fallback',
    () async {
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      const fallback = [
        PlaySeStep(seName: 'legacy-move'),
        WaitStep(durationSeconds: .1),
      ];
      final scope = BattleMoveAudioScope.compose(
        audio: await audio.prepare(const BattleMoveClipAudio('cue')),
        silentVisuals: const AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: [
            PlayRmxpAnimationStep(
              animationId: 1,
              subjectSide: BattleSideId.player,
              attackerSide: BattleSideId.player,
              defenderSide: BattleSideId.enemy,
              phase: RmxpPlacementPhase.user,
              placementSpec: RmxpPlacementSpec(
                policy: RmxpPlacementPolicy.sdkStage,
              ),
            ),
          ],
        ),
        fallback: fallback,
      );
      expect(scope.status, BattleRecipeAudioStatus.fallback);
      expect(scope.steps, fallback);
      expect(scope.audioScopes, isEmpty);
      final events = <String>[];
      var hpTransitions = 0;
      final runner = _scopeRunner(
        onPlaySe: (step) => events.add(step.seName),
        onHudHpTween: (_) => hpTransitions++,
      );
      runner.start(
        BattleAnimationPlan(
          steps: [
            ...scope.steps,
            const PlaySeStep(seName: 'impact'),
            const HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 25,
              toHp: 15,
            ),
          ],
        ),
      );
      runner.update(.1);
      await voice.disposed.future;
      expect(voice.resumes, 0);
      expect(events, ['legacy-move', 'impact']);
      expect(hpTransitions, 1);
    },
  );

  test('nested visual audio is rejected and does not start the clip', () async {
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: await _bundle(),
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    addTearDown(audio.cancel);
    final scope = BattleMoveAudioScope.compose(
      audio: await audio.prepare(const BattleMoveClipAudio('cue')),
      silentVisuals: const AnimationGroupStep(
        mode: BattleAnimationGroupMode.parallel,
        steps: [
          AnimationGroupStep(
            mode: BattleAnimationGroupMode.sequence,
            steps: [PlaySeStep(seName: 'hidden')],
          ),
        ],
      ),
      fallback: const [PlaySeStep(seName: 'legacy-move')],
    );
    expect(scope.status, BattleRecipeAudioStatus.fallback);
    expect(scope.steps.single, isA<PlaySeStep>());
    await voice.disposed.future;
    expect(voice.resumes, 0);
  });

  test(
    'effect recovery after audio starts does not replay legacy audio',
    () async {
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final scope = BattleMoveAudioScope.compose(
        audio: await audio.prepare(const BattleMoveClipAudio('cue')),
        silentVisuals: const AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: [WaitStep(durationSeconds: .3)],
        ),
        fallback: const [PlaySeStep(seName: 'legacy-move')],
      );
      final events = <String>[];
      var hpTransitions = 0;
      late void Function() failEffect;
      final silentFallback = <BattleAnimationStep>[
        const ScreenFlashStep(colorArgb: 1, durationSeconds: .1),
      ];
      final runner = _scopeRunner(
        onPlaySe: (step) => events.add(step.seName),
        onScreenFlash: (_) => events.add('fallback-visual'),
        onHudHpTween: (_) => hpTransitions++,
        onStartRecoverableTrackedEffect: (_, _, fail) {
          failEffect = fail;
          return () {};
        },
      );
      runner.start(
        BattleAnimationPlan(
          steps: [
            StartTrackedEffectStep(
              effectId: 'bw2',
              fallbackSteps: const [
                PlaySeStep(seName: 'legacy-move'),
                ScreenFlashStep(colorArgb: 1, durationSeconds: .1),
              ],
              fallbackAfterAudioSteps: silentFallback,
            ),
            ...scope.steps,
            const WaitTrackedEffectsStep(),
            const PlaySeStep(seName: 'impact'),
            const HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 25,
              toHp: 15,
            ),
          ],
          audioScopes: scope.audioScopes,
        ),
      );
      silentFallback.add(const PlaySeStep(seName: 'late-legacy'));
      await voice.resuming.future;
      failEffect();
      runner.update(.2);
      expect(events, ['fallback-visual', 'impact']);
      expect(voice.resumes, 1);
      expect(hpTransitions, 1);
    },
  );

  test(
    'recoverable audio rejects another sound inside its attack scope',
    () async {
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final scope = BattleMoveAudioScope.compose(
        audio: await audio.prepare(const BattleMoveClipAudio('cue')),
        silentVisuals: const AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: [WaitStep(durationSeconds: .1)],
        ),
        fallback: const [PlaySeStep(seName: 'legacy-move')],
      );
      final runner = _scopeRunner(
        onStartRecoverableTrackedEffect: (_, _, _) => () {},
      );
      expect(
        () => runner.start(
          BattleAnimationPlan(
            steps: [
              const StartTrackedEffectStep(
                effectId: 'bw2',
                fallbackSteps: [PlaySeStep(seName: 'legacy-move')],
                fallbackAfterAudioSteps: [],
              ),
              ...scope.steps,
              const PlaySeStep(seName: 'legacy-move'),
              const WaitTrackedEffectsStep(),
            ],
            audioScopes: scope.audioScopes,
          ),
        ),
        throwsStateError,
      );
      expect(voice.resumes, 0);
    },
  );

  test(
    'effect failure before audio starts uses the complete legacy fallback',
    () async {
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final scope = BattleMoveAudioScope.compose(
        audio: await audio.prepare(const BattleMoveClipAudio('cue')),
        silentVisuals: const AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: [WaitStep(durationSeconds: .3)],
        ),
        fallback: const [],
      );
      final events = <String>[];
      var hpTransitions = 0;
      final runner = _scopeRunner(
        onPlaySe: (step) => events.add(step.seName),
        onScreenFlash: (_) => events.add('fallback-visual'),
        onHudHpTween: (_) => hpTransitions++,
        onStartRecoverableTrackedEffect: (_, _, fail) {
          fail();
          return () {};
        },
      );
      runner.start(
        BattleAnimationPlan(
          steps: [
            const StartTrackedEffectStep(
              effectId: 'bw2',
              fallbackSteps: [
                PlaySeStep(seName: 'legacy-move'),
                ScreenFlashStep(colorArgb: 1, durationSeconds: .1),
              ],
              fallbackAfterAudioSteps: [
                ScreenFlashStep(colorArgb: 1, durationSeconds: .1),
              ],
            ),
            ...scope.steps,
            const WaitTrackedEffectsStep(),
            const PlaySeStep(seName: 'impact'),
            const HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 25,
              toHp: 15,
            ),
          ],
          audioScopes: scope.audioScopes,
        ),
      );
      runner.update(.1);
      await voice.disposed.future;
      expect(events, ['legacy-move', 'fallback-visual', 'impact']);
      expect(voice.resumes, 0);
      expect(hpTransitions, 1);
    },
  );

  test('post-audio fallback resources are visible during plan preparation', () {
    const fallback = SpawnFxStep(
      effectId: 'silent-fallback',
      attackerSide: BattleSideId.player,
      defenderSide: BattleSideId.enemy,
      from: BattleVisualAnchor.attackerCenter,
      to: BattleVisualAnchor.defenderCenter,
      durationSeconds: .1,
    );
    const plan = BattleAnimationPlan(
      steps: [
        StartTrackedEffectStep(
          effectId: 'bw2',
          fallbackSteps: [],
          fallbackAfterAudioSteps: [fallback],
        ),
        WaitTrackedEffectsStep(),
      ],
    );
    expect(plan.requiredFxIds, {'silent-fallback'});
    expect(plan.flattenedSteps, contains(fallback));
  });

  test(
    'recoverable audio rejects absent or sounding fallback visuals',
    () async {
      final voices = <_Voice>[];
      final player = FlameAudioBattleSfxPlayer(
        playerFactory: () {
          final voice = _Voice();
          voices.add(voice);
          return voice;
        },
      );
      addTearDown(player.dispose);
      final bundle = await _bundle();
      final afterAudioOptions = <List<BattleAnimationStep>?>[
        null,
        const [PlaySeStep(seName: 'hidden')],
        const [
          PlayRmxpAnimationStep(
            animationId: 1,
            subjectSide: BattleSideId.player,
            attackerSide: BattleSideId.player,
            defenderSide: BattleSideId.enemy,
            phase: RmxpPlacementPhase.user,
            placementSpec: RmxpPlacementSpec(
              policy: RmxpPlacementPolicy.sdkStage,
            ),
          ),
        ],
        const [HudHpTweenStep(side: BattleSideId.enemy, fromHp: 25, toHp: 15)],
      ];
      for (final afterAudio in afterAudioOptions) {
        final audio = BattleRecipeAudioCoordinator(
          player: player,
          bundle: bundle,
          preparationTimeout: const Duration(seconds: 1),
          startTimeout: const Duration(seconds: 1),
        );
        final scope = BattleMoveAudioScope.compose(
          audio: await audio.prepare(const BattleMoveClipAudio('cue')),
          silentVisuals: const AnimationGroupStep(
            mode: BattleAnimationGroupMode.parallel,
            steps: [WaitStep(durationSeconds: .1)],
          ),
          fallback: const [],
        );
        final runner = _scopeRunner(
          onStartRecoverableTrackedEffect: (_, _, _) => () {},
        );
        expect(
          () => runner.start(
            BattleAnimationPlan(
              steps: [
                StartTrackedEffectStep(
                  effectId: 'bw2',
                  fallbackSteps: const [PlaySeStep(seName: 'legacy')],
                  fallbackAfterAudioSteps: afterAudio,
                ),
                ...scope.steps,
                const WaitTrackedEffectsStep(),
              ],
              audioScopes: scope.audioScopes,
            ),
          ),
          throwsStateError,
        );
        await audio.cancel();
        expect(voices.last.resumes, 0);
      }
    },
  );

  test(
    'recovery checks the current attack rather than earlier audio',
    () async {
      final voices = <_Voice>[];
      final player = FlameAudioBattleSfxPlayer(
        playerFactory: () {
          final voice = _Voice();
          voices.add(voice);
          return voice;
        },
      );
      addTearDown(player.dispose);
      final bundle = await _bundle();
      final audios = List.generate(
        2,
        (_) => BattleRecipeAudioCoordinator(
          player: player,
          bundle: bundle,
          preparationTimeout: const Duration(seconds: 1),
          startTimeout: const Duration(seconds: 1),
        ),
      );
      addTearDown(() async {
        for (final audio in audios) {
          await audio.cancel();
        }
      });
      final scopes = <BattleMoveAudioScopeResult>[];
      for (final audio in audios) {
        scopes.add(
          BattleMoveAudioScope.compose(
            audio: await audio.prepare(const BattleMoveClipAudio('cue')),
            silentVisuals: const AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [WaitStep(durationSeconds: .1)],
            ),
            fallback: const [],
          ),
        );
      }
      final events = <String>[];
      var hpTransitions = 0;
      final runner = _scopeRunner(
        onPlaySe: (step) => events.add(step.seName),
        onHudHpTween: (_) => hpTransitions++,
        onStartRecoverableTrackedEffect: (step, done, fail) {
          if (step.effectId == 'first') {
            done();
          } else {
            fail();
          }
          return () {};
        },
      );
      runner.start(
        BattleAnimationPlan(
          steps: [
            const StartTrackedEffectStep(
              effectId: 'first',
              fallbackSteps: [PlaySeStep(seName: 'first-legacy')],
              fallbackAfterAudioSteps: [],
            ),
            ...scopes[0].steps,
            const WaitTrackedEffectsStep(),
            const StartTrackedEffectStep(
              effectId: 'second',
              fallbackSteps: [PlaySeStep(seName: 'second-legacy')],
              fallbackAfterAudioSteps: [],
            ),
            ...scopes[1].steps,
            const WaitTrackedEffectsStep(),
            const PlaySeStep(seName: 'impact'),
            const HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 25,
              toHp: 15,
            ),
          ],
          audioScopes: [for (final scope in scopes) ...scope.audioScopes],
        ),
      );
      await voices.first.resuming.future;
      runner.update(.1);
      runner.update(0);
      await voices.last.disposed.future;
      expect(voices.map((voice) => voice.resumes), [1, 0]);
      expect(events, ['second-legacy', 'impact']);
      expect(hpTransitions, 1);
    },
  );

  test('unsafe visual timing or size selects the legacy fallback', () async {
    final voices = <_Voice>[];
    final player = FlameAudioBattleSfxPlayer(
      playerFactory: () {
        final voice = _Voice();
        voices.add(voice);
        return voice;
      },
    );
    addTearDown(player.dispose);
    final bundle = await _bundle();
    final inputs = <List<BattleAnimationStep>>[
      const [WaitStep(durationSeconds: double.nan)],
      const [WaitStep(durationSeconds: double.infinity)],
      const [WaitStep(durationSeconds: 31)],
      List.generate(257, (_) => const WaitStep(durationSeconds: 0)),
    ];
    for (final steps in inputs) {
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: bundle,
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      final scope = BattleMoveAudioScope.compose(
        audio: await audio.prepare(const BattleMoveClipAudio('cue')),
        silentVisuals: AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: steps,
        ),
        fallback: const [PlaySeStep(seName: 'legacy-move')],
      );
      expect(scope.status, BattleRecipeAudioStatus.fallback);
      await audio.cancel();
      expect(voices.last.resumes, 0);
    }
  });

  test(
    'changing the source visual list cannot inject audio after admission',
    () async {
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final visualSteps = <BattleAnimationStep>[
        const WaitStep(durationSeconds: .1),
      ];
      final scope = BattleMoveAudioScope.compose(
        audio: await audio.prepare(const BattleMoveClipAudio('cue')),
        silentVisuals: AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: visualSteps,
        ),
        fallback: const [],
      );
      visualSteps.add(const PlaySeStep(seName: 'late-legacy'));
      final sounds = <String>[];
      final runner = _scopeRunner(onPlaySe: (step) => sounds.add(step.seName));
      runner.start(
        BattleAnimationPlan(steps: scope.steps, audioScopes: scope.audioScopes),
      );
      runner.update(.1);
      await Future<void>.delayed(Duration.zero);
      expect(sounds, isEmpty);
      expect(voice.resumes, 1);
    },
  );

  test(
    'preparation failure leaves the legacy audio and HP untouched',
    () async {
      final voice = _Voice(failSource: true);
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final scope = BattleMoveAudioScope.compose(
        audio: await audio.prepare(const BattleMoveClipAudio('cue')),
        silentVisuals: const AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: [WaitStep(durationSeconds: .1)],
        ),
        fallback: const [PlaySeStep(seName: 'legacy-move')],
      );
      expect(scope.status, BattleRecipeAudioStatus.fallback);
      final events = <String>[];
      var hpTransitions = 0;
      final runner = _scopeRunner(
        onPlaySe: (step) => events.add(step.seName),
        onHudHpTween: (_) => hpTransitions++,
      );
      runner.start(
        BattleAnimationPlan(
          steps: [
            ...scope.steps,
            const PlaySeStep(seName: 'impact'),
            const HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 25,
              toHp: 15,
            ),
          ],
          audioScopes: scope.audioScopes,
        ),
      );
      expect(events, ['legacy-move', 'impact']);
      expect(hpTransitions, 1);
    },
  );

  test(
    'a failed start suppresses later SEQ tokens without replaying damage',
    () async {
      final voices = <_Voice>[];
      final player = FlameAudioBattleSfxPlayer(
        playerFactory: () {
          final voice = _Voice(failResume: voices.isEmpty);
          voices.add(voice);
          return voice;
        },
      );
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final result = await audio.prepare(
        BattleSeqAudio([
          const BattleSeqAudioEvent('first', 'cue', Duration.zero),
          const BattleSeqAudioEvent(
            'second',
            'cue',
            Duration(milliseconds: 500),
          ),
        ]),
      );
      final scope = BattleMoveAudioScope.compose(
        audio: result,
        silentVisuals: const AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: [WaitStep(durationSeconds: .5)],
        ),
        fallback: const [PlaySeStep(seName: 'legacy-move')],
      );
      final sounds = <String>[];
      var hpTransitions = 0;
      final runner = _scopeRunner(
        onPlaySe: (step) => sounds.add(step.seName),
        onHudHpTween: (_) => hpTransitions++,
      );
      runner.start(
        BattleAnimationPlan(
          steps: [
            ...scope.steps,
            const PlaySeStep(seName: 'impact'),
            const HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 25,
              toHp: 15,
            ),
          ],
          audioScopes: scope.audioScopes,
        ),
      );
      await result.program!.playbackFailure;
      await Future.wait(voices.map((voice) => voice.disposed.future));
      await Future<void>.delayed(Duration.zero);
      runner.update(.5);
      expect(voices.map((voice) => voice.resumes), [1, 0]);
      expect(sounds, ['impact']);
      expect(hpTransitions, 1);
    },
  );

  test(
    'cancelling a running scope stops both started and pending SEQ cues',
    () async {
      final voices = <_Voice>[];
      final player = FlameAudioBattleSfxPlayer(
        playerFactory: () {
          final voice = _Voice();
          voices.add(voice);
          return voice;
        },
      );
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final scope = BattleMoveAudioScope.compose(
        audio: await audio.prepare(
          BattleSeqAudio([
            const BattleSeqAudioEvent('first', 'cue', Duration.zero),
            const BattleSeqAudioEvent(
              'second',
              'cue',
              Duration(milliseconds: 500),
            ),
          ]),
        ),
        silentVisuals: const AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: [WaitStep(durationSeconds: 1)],
        ),
        fallback: const [PlaySeStep(seName: 'legacy-move')],
      );
      final events = <String>[];
      var hpTransitions = 0;
      final runner = _scopeRunner(
        onPlaySe: (step) => events.add(step.seName),
        onHudHpTween: (_) => hpTransitions++,
      );
      runner.start(
        BattleAnimationPlan(
          steps: [
            ...scope.steps,
            const HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 25,
              toHp: 15,
            ),
          ],
          audioScopes: scope.audioScopes,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(voices.map((voice) => voice.resumes), [1, 0]);
      runner.cancel();
      runner.update(2);
      await Future.wait(voices.map((voice) => voice.disposed.future));
      expect(voices.map((voice) => voice.resumes), [1, 0]);
      expect(events, isEmpty);
      expect(hpTransitions, 0);
    },
  );

  test('runner cancellation does not wait for a stalled audio stop', () async {
    final gate = Completer<void>();
    final voice = _Voice(stopGate: gate);
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: await _bundle(),
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    final scope = BattleMoveAudioScope.compose(
      audio: await audio.prepare(const BattleMoveClipAudio('cue')),
      silentVisuals: const AnimationGroupStep(
        mode: BattleAnimationGroupMode.parallel,
        steps: [WaitStep(durationSeconds: 1)],
      ),
      fallback: const [],
    );
    final runner = _scopeRunner();
    runner.start(
      BattleAnimationPlan(steps: scope.steps, audioScopes: scope.audioScopes),
    );
    await voice.resuming.future;
    try {
      runner.cancel();
      await voice.stopping.future;
      expect(runner.isActive, isFalse);
      expect(voice.disposals, 0);
    } finally {
      gate.complete();
      await audio.cancel();
    }
    expect(voice.disposals, 1);
  });

  test(
    'a completed plan lets its clip finish until the runner is cancelled',
    () async {
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final scope = BattleMoveAudioScope.compose(
        audio: await audio.prepare(const BattleMoveClipAudio('cue')),
        silentVisuals: const AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: [WaitStep(durationSeconds: .1)],
        ),
        fallback: const [],
      );
      final runner = _scopeRunner();
      runner.start(
        BattleAnimationPlan(steps: scope.steps, audioScopes: scope.audioScopes),
      );
      runner.update(.1);
      await Future<void>.delayed(Duration.zero);
      expect(runner.isActive, isFalse);
      expect(voice.resumes, 1);
      expect(voice.disposals, 0);
      runner.start(
        const BattleAnimationPlan(steps: [WaitStep(durationSeconds: 1)]),
      );
      await Future<void>.delayed(Duration.zero);
      expect(voice.disposals, 0);
      runner.cancel();
      await voice.disposed.future;
      expect(voice.disposals, 1);
    },
  );

  test(
    'a naturally finished clip releases its voice without cancelling play',
    () async {
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final scope = BattleMoveAudioScope.compose(
        audio: await audio.prepare(const BattleMoveClipAudio('cue')),
        silentVisuals: const AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: [WaitStep(durationSeconds: .1)],
        ),
        fallback: const [],
      );
      final runner = _scopeRunner();
      runner.start(
        BattleAnimationPlan(steps: scope.steps, audioScopes: scope.audioScopes),
      );
      await voice.resuming.future;
      voice.complete.add(null);
      await voice.disposed.future;
      runner.update(.1);
      expect(runner.isActive, isFalse);
      expect(voice.disposals, 1);
    },
  );

  test('a real turn routes its selected attack clip once', () async {
    final sourceGate = Completer<void>();
    final voice = _Voice(sourceGate: sourceGate);
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: await _bundle(),
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    addTearDown(audio.cancel);
    addTearDown(() {
      if (!sourceGate.isCompleted) sourceGate.complete();
    });
    const stats = BattleStatsSnapshot(
      attack: 20,
      defense: 20,
      specialAttack: 20,
      specialDefense: 20,
      speed: 20,
    );
    const playerPokemon = BattleCombatantData(
      speciesId: 'one',
      level: 7,
      maxHp: 80,
      currentHp: 80,
      stats: stats,
      moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 40)],
    );
    const enemyPokemon = BattleCombatantData(
      speciesId: 'two',
      level: 7,
      maxHp: 80,
      currentHp: 80,
      stats: stats,
      moves: [
        BattleMoveData(
          id: 'wait',
          name: 'Wait',
          power: 0,
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.self,
          accuracy: BattleMoveAccuracy.alwaysHits(),
        ),
      ],
    );
    final session = createBattleSession(
      BattleSetup.pokeMapBetaV1ForTest(
        playerPokemon: playerPokemon,
        enemyPokemon: enemyPokemon,
        isTrainerBattle: false,
        trainerId: null,
      ),
    );
    final after = session.applyChoice(const PlayerBattleChoiceFight(0));
    final event = after.state.currentTurn!.timeline
        .whereType<BattleTurnExecutionEvent>()
        .singleWhere(
          (entry) => entry.execution.attackerSide == BattleSideId.player,
        );
    final sounds = <String>[];
    final hpTransitions = <int>{};
    final overlay = BattleOverlayComponent(
      session: session,
      viewportSize: Vector2(390, 844),
      onPlayerChoice: (_) {},
      playSfx: (name, {required volume, required pitch}) => sounds.add(name),
      onCommandOverlaySnapshotChanged: (snapshot) {
        final hud = snapshot?.enemyHud;
        if (hud?.targetDisplayedHp == after.state.enemy.currentHp) {
          hpTransitions.add(hud!.hpTweenRevision);
        }
      },
    );
    await loadFlameComponent(overlay);
    await overlay.waitForPendingVisualSync();
    addTearDown(overlay.onRemove);
    final preparing = overlay.prepareTurnAudioAndUpdateState(
      after,
      audioRequests: [
        BattleTurnAudioRequest(
          event: event,
          coordinator: audio,
          audio: const BattleMoveClipAudio('cue'),
          silentVisuals: const AnimationGroupStep(
            mode: BattleAnimationGroupMode.parallel,
            steps: [WaitStep(durationSeconds: .3)],
          ),
        ),
      ],
    );
    await voice.sourceSet.future;
    expect(voice.resumes, 0);
    expect(overlay.debugSession.state.currentTurn, isNull);
    sourceGate.complete();
    expect(await preparing, isTrue);
    await overlay.waitForPendingVisualSync();
    expect(voice.resumes, 0);
    for (var i = 0; i < 300; i++) {
      overlay.updateTree(1 / 60);
      await Future<void>.delayed(Duration.zero);
    }
    expect(voice.resumes, 1);
    expect(sounds.where((name) => name == 'hit'), hasLength(1));
    expect(hpTransitions, hasLength(1));
  });

  test(
    'a failed clip start in a real turn does not replay sound or damage',
    () async {
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final voice = _Voice(failResume: true);
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final sounds = <String>[];
      final hpTransitions = <int>{};
      final overlay = BattleOverlayComponent(
        session: turn.before,
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
        playSfx: (name, {required volume, required pitch}) => sounds.add(name),
        onCommandOverlaySnapshotChanged: (snapshot) {
          final hud = snapshot?.enemyHud;
          if (hud?.targetDisplayedHp == turn.after.state.enemy.currentHp) {
            hpTransitions.add(hud!.hpTweenRevision);
          }
        },
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      expect(
        await overlay.prepareTurnAudioAndUpdateState(
          turn.after,
          audioRequests: [
            BattleTurnAudioRequest(
              event: event,
              coordinator: audio,
              audio: const BattleMoveClipAudio('cue'),
              silentVisuals: const AnimationGroupStep(
                mode: BattleAnimationGroupMode.parallel,
                steps: [WaitStep(durationSeconds: .2)],
              ),
            ),
          ],
        ),
        isTrue,
      );
      await overlay.waitForPendingVisualSync();
      for (var i = 0; i < 300; i++) {
        overlay.updateTree(1 / 60);
        await Future<void>.delayed(Duration.zero);
      }
      expect(voice.resumes, 1);
      expect(sounds.where((name) => name == 'hit'), hasLength(1));
      expect(
        sounds.where((name) => name.startsWith('avelune-recipe-audio-')),
        isEmpty,
      );
      expect(hpTransitions, hasLength(1));
    },
  );

  test(
    'two executions of the same move get independent audio voices',
    () async {
      final turn = _realTurn(enemyAttacks: true);
      expect(turn.events, hasLength(2));
      expect(turn.events.map((event) => event.execution.move.id), [
        'tackle',
        'tackle',
      ]);
      final voices = <_Voice>[];
      final player = FlameAudioBattleSfxPlayer(
        playerFactory: () {
          final voice = _Voice();
          voices.add(voice);
          return voice;
        },
      );
      addTearDown(player.dispose);
      final bundle = await _bundle();
      final audios = List.generate(
        2,
        (_) => BattleRecipeAudioCoordinator(
          player: player,
          bundle: bundle,
          preparationTimeout: const Duration(seconds: 1),
          startTimeout: const Duration(seconds: 1),
        ),
      );
      addTearDown(() async {
        for (final audio in audios) {
          await audio.cancel();
        }
      });
      final selections = <BattleTurnAudioSelection>[];
      for (var i = 0; i < 2; i++) {
        selections.add(
          BattleTurnAudioSelection(
            event: turn.events[i],
            audio: await audios[i].prepare(const BattleMoveClipAudio('cue')),
            silentVisuals: const AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [WaitStep(durationSeconds: .2)],
            ),
          ),
        );
      }
      final plan = _realTurnPlan(
        turn.before,
        turn.after,
        selections: selections,
      );
      final sounds = <String>[];
      var hpTransitions = 0;
      final runner = _scopeRunner(
        onPlaySe: (step) => sounds.add(step.seName),
        onHudHpTween: (_) => hpTransitions++,
      );
      runner.start(plan);
      for (var i = 0; i < 100 && voices.first.resumes == 0; i++) {
        runner.update(.05);
        await Future<void>.delayed(Duration.zero);
      }
      expect(voices.map((voice) => voice.resumes), [1, 0]);
      for (var i = 0; i < 150 && voices.last.resumes == 0; i++) {
        runner.update(.05);
        await Future<void>.delayed(Duration.zero);
      }
      for (var i = 0; i < 150 && runner.isActive; i++) {
        runner.update(.05);
      }
      expect(voices.map((voice) => voice.resumes), [1, 1]);
      expect(sounds.where((name) => name == 'legacy-move'), isEmpty);
      expect(sounds.where((name) => name == 'hit'), hasLength(2));
      expect(hpTransitions, 2);
    },
  );

  test('a stale attack event cancels its unused prepared sound', () async {
    final turn = _realTurn();
    final event = turn.events.firstWhere(
      (entry) => entry.execution.attackerSide == BattleSideId.player,
    );
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: await _bundle(),
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    addTearDown(audio.cancel);
    final selection = BattleTurnAudioSelection(
      event: BattleTurnExecutionEvent(event.execution),
      audio: await audio.prepare(const BattleMoveClipAudio('cue')),
      silentVisuals: const AnimationGroupStep(
        mode: BattleAnimationGroupMode.parallel,
        steps: [WaitStep(durationSeconds: .1)],
      ),
    );
    expect(
      () => _realTurnPlan(turn.before, turn.after, selections: [selection]),
      throwsStateError,
    );
    await voice.disposed.future;
    expect(voice.resumes, 0);
  });

  test(
    'cancelled turn preparation releases the other unstarted clip',
    () async {
      final turn = _realTurn(enemyAttacks: true);
      final gate = Completer<void>();
      final voices = <_Voice>[];
      final player = FlameAudioBattleSfxPlayer(
        playerFactory: () {
          final voice = _Voice(sourceGate: voices.isEmpty ? gate : null);
          voices.add(voice);
          return voice;
        },
      );
      addTearDown(player.dispose);
      final bundle = await _bundle();
      final audios = List.generate(
        2,
        (_) => BattleRecipeAudioCoordinator(
          player: player,
          bundle: bundle,
          preparationTimeout: const Duration(seconds: 1),
          startTimeout: const Duration(seconds: 1),
        ),
      );
      addTearDown(() async {
        if (!gate.isCompleted) gate.complete();
        for (final audio in audios) {
          await audio.cancel();
        }
      });
      final pending = audios.first.prepare(const BattleMoveClipAudio('cue'));
      await voices.first.sourceSet.future;
      await audios.first.cancel();
      final cancelled = await pending;
      final ready = await audios.last.prepare(const BattleMoveClipAudio('cue'));
      const visual = AnimationGroupStep(
        mode: BattleAnimationGroupMode.parallel,
        steps: [WaitStep(durationSeconds: .1)],
      );
      expect(
        () => _realTurnPlan(
          turn.before,
          turn.after,
          selections: [
            BattleTurnAudioSelection(
              event: turn.events[1],
              audio: ready,
              silentVisuals: visual,
            ),
            BattleTurnAudioSelection(
              event: turn.events[0],
              audio: cancelled,
              silentVisuals: visual,
            ),
          ],
        ),
        throwsA(isA<BattleTurnAudioCancelled>()),
      );
      await voices.last.disposed.future;
      expect(voices.map((voice) => voice.resumes), [0, 0]);
      gate.complete();
    },
  );

  test(
    'a sound already reserved for another scope is never cancelled',
    () async {
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final result = await audio.prepare(const BattleMoveClipAudio('cue'));
      const visuals = AnimationGroupStep(
        mode: BattleAnimationGroupMode.parallel,
        steps: [WaitStep(durationSeconds: .1)],
      );
      final first = BattleMoveAudioScope.compose(
        audio: result,
        silentVisuals: visuals,
        fallback: const [],
      );
      expect(
        () => BattleMoveAudioScope.compose(
          audio: result,
          silentVisuals: visuals,
          fallback: const [],
        ),
        throwsStateError,
      );
      final runner = _scopeRunner();
      runner.start(
        BattleAnimationPlan(steps: first.steps, audioScopes: first.audioScopes),
      );
      await voice.resuming.future;
      expect(voice.resumes, 1);
      expect(voice.disposals, 0);
    },
  );

  test('a planner failure cancels claimed and unclaimed turn audio', () async {
    final turn = _realTurn(enemyAttacks: true);
    final voices = <_Voice>[];
    final player = FlameAudioBattleSfxPlayer(
      playerFactory: () {
        final voice = _Voice();
        voices.add(voice);
        return voice;
      },
    );
    addTearDown(player.dispose);
    final bundle = await _bundle();
    final audios = List.generate(
      2,
      (_) => BattleRecipeAudioCoordinator(
        player: player,
        bundle: bundle,
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      ),
    );
    addTearDown(() async {
      for (final audio in audios) {
        await audio.cancel();
      }
    });
    const visual = AnimationGroupStep(
      mode: BattleAnimationGroupMode.parallel,
      steps: [WaitStep(durationSeconds: .1)],
    );
    final selections = <BattleTurnAudioSelection>[];
    for (var i = 0; i < 2; i++) {
      selections.add(
        BattleTurnAudioSelection(
          event: turn.events[i],
          audio: await audios[i].prepare(const BattleMoveClipAudio('cue')),
          silentVisuals: visual,
        ),
      );
    }
    var built = 0;
    final catalog = RuntimeMoveCatalog.fromEntries(
      const <String, PokemonMove>{},
    );
    final planner = BattleTurnAnimationPlanner(
      recipeBuilder: (_, _) {
        if (++built == 2) throw StateError('visual builder failed');
        return const [WaitStep(durationSeconds: .1)];
      },
    );
    expect(
      () => planner.build(
        previousSession: turn.before,
        newSession: turn.after,
        moveCatalog: catalog,
        resolver: BattleMoveVisualResolver(catalog),
        audioSelections: selections,
      ),
      throwsStateError,
    );
    await Future.wait(voices.map((voice) => voice.disposed.future));
    expect(voices.map((voice) => voice.resumes), [0, 0]);
  });

  test('failed preflight keeps the real turn legacy plan intact', () async {
    final turn = _realTurn();
    final event = turn.events.firstWhere(
      (entry) => entry.execution.attackerSide == BattleSideId.player,
    );
    final voice = _Voice(failSource: true);
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: await _bundle(),
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    addTearDown(audio.cancel);
    final result = await audio.prepare(const BattleMoveClipAudio('cue'));
    expect(result.status, BattleRecipeAudioStatus.fallback);
    final baseline = _realTurnPlan(turn.before, turn.after);
    final plan = _realTurnPlan(
      turn.before,
      turn.after,
      selections: [
        BattleTurnAudioSelection(
          event: event,
          audio: result,
          trackedEffectId: 'grouped-spl',
          silentVisuals: const AnimationGroupStep(
            mode: BattleAnimationGroupMode.parallel,
            steps: [WaitStep(durationSeconds: .1)],
          ),
        ),
      ],
    );
    expect(plan.audioScopes, isEmpty);
    expect(plan.flattenedSteps.whereType<StartTrackedEffectStep>(), isEmpty);
    expect(
      plan.flattenedSteps.map((step) => step.runtimeType),
      baseline.flattenedSteps.map((step) => step.runtimeType),
    );
    expect(
      plan.flattenedSteps.whereType<PlaySeStep>().map((step) => step.seName),
      baseline.flattenedSteps.whereType<PlaySeStep>().map(
        (step) => step.seName,
      ),
    );
    expect(
      plan.flattenedSteps.whereType<HudHpTweenStep>().length,
      baseline.flattenedSteps.whereType<HudHpTweenStep>().length,
    );
    expect(voice.resumes, 0);
  });

  for (final failureAfterAudio in [false, true]) {
    test('tracked recipe fallback preserves one real turn when failure occurs '
        '${failureAfterAudio ? 'after' : 'before'} audio', () async {
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final coordinator = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(coordinator.cancel);
      final audio = await coordinator.prepare(const BattleMoveClipAudio('cue'));
      final baseline = _realTurnPlan(turn.before, turn.after);
      final legacyCount = baseline.flattenedSteps
          .whereType<PlaySeStep>()
          .where((step) => step.seName == 'legacy-move')
          .length;
      final plan = _realTurnPlan(
        turn.before,
        turn.after,
        recipeSteps: const [
          PlaySeStep(seName: 'legacy-move'),
          ScreenFlashStep(colorArgb: 1, durationSeconds: .1),
          WaitStep(durationSeconds: .1),
        ],
        selections: [
          BattleTurnAudioSelection(
            event: event,
            audio: audio,
            trackedEffectId: 'grouped-spl',
            silentVisuals: const AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [WaitStep(durationSeconds: 0)],
            ),
          ),
        ],
      );
      final sounds = <String>[];
      var hpTransitions = 0;
      var visualFallbacks = 0;
      void Function()? failEffect;
      final runner = _scopeRunner(
        onPlaySe: (step) => sounds.add(step.seName),
        onHudHpTween: (_) => hpTransitions++,
        onScreenFlash: (_) => visualFallbacks++,
        onStartRecoverableTrackedEffect: (step, done, fail) {
          expect(step.effectId, 'grouped-spl');
          failEffect = fail;
          if (!failureAfterAudio) fail();
          return () {};
        },
      );
      runner.start(plan);
      for (var i = 0; i < 300 && failEffect == null; i++) {
        runner.update(.05);
        await Future<void>.delayed(Duration.zero);
      }
      expect(failEffect, isNotNull);
      if (failureAfterAudio) {
        for (var i = 0; i < 300 && voice.resumes == 0; i++) {
          runner.update(.05);
          await Future<void>.delayed(Duration.zero);
        }
        expect(voice.resumes, 1);
        failEffect!();
      }
      for (var i = 0; i < 300 && runner.isActive; i++) {
        runner.update(.05);
        await Future<void>.delayed(Duration.zero);
      }
      expect(runner.isActive, isFalse);
      expect(voice.resumes, failureAfterAudio ? 1 : 0);
      expect(
        sounds.where((name) => name == 'legacy-move').length,
        legacyCount - (failureAfterAudio ? 1 : 0),
      );
      expect(sounds.where((name) => name == 'hit'), hasLength(1));
      expect(hpTransitions, 1);
      expect(visualFallbacks, 2);
    });
  }

  test(
    'turn audio preparation carries its tracked effect to the scene',
    () async {
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final coordinator = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(coordinator.cancel);
      final effects = <String>[];
      final overlay = BattleOverlayComponent(
        session: turn.before,
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
        onStartRecoverableTrackedEffect: (step, done, fail) {
          effects.add(step.effectId);
          done();
          return () {};
        },
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      expect(
        await overlay.prepareTurnAudioAndUpdateState(
          turn.after,
          audioRequests: [
            BattleTurnAudioRequest(
              event: event,
              coordinator: coordinator,
              audio: const BattleMoveClipAudio('cue'),
              trackedEffectId: 'grouped-spl',
              silentVisuals: const AnimationGroupStep(
                mode: BattleAnimationGroupMode.parallel,
                steps: [WaitStep(durationSeconds: 0)],
              ),
            ),
          ],
        ),
        isTrue,
      );
      await overlay.waitForPendingVisualSync();
      for (var i = 0; i < 300; i++) {
        overlay.updateTree(1 / 60);
        await Future<void>.delayed(Duration.zero);
      }
      expect(effects, ['grouped-spl']);
      expect(voice.resumes, 1);
    },
  );

  test('grouped SPL media plays with its clip and releases after both finish', () async {
    final root = await Directory.systemTemp.createTemp('grouped-spl-turn-');
    addTearDown(() => root.delete(recursive: true));
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final media = await _groupedOfflineMedia(
      root,
      budget,
      fixtureRoot: Platform.environment['AVELUNE_BW2_PILOT_FIXTURE'],
    );
    final turn = _realTurn();
    final event = turn.events.firstWhere(
      (entry) => entry.execution.attackerSide == BattleSideId.player,
    );
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final sounds = <String>[];
    final hpTransitions = <int>{};
    late final BattleOverlayComponent overlay;
    overlay = BattleOverlayComponent(
      session: turn.before,
      viewportSize: Vector2(390, 844),
      onPlayerChoice: (_) {},
      playSfx: (name, {required volume, required pitch}) => sounds.add(name),
      onStartRecoverableTrackedEffect: (step, done, fail) =>
          overlay.startGroupedSplEffect(step, done, fail),
      onCommandOverlaySnapshotChanged: (snapshot) {
        final hud = snapshot?.enemyHud;
        if (hud?.targetDisplayedHp == turn.after.state.enemy.currentHp) {
          hpTransitions.add(hud!.hpTweenRevision);
        }
      },
    );
    await loadFlameComponent(overlay);
    await overlay.waitForPendingVisualSync();
    addTearDown(overlay.onRemove);
    final request = await overlay.prepareGroupedSplTurn(
      event: event, media: media, player: player,
    );
    expect(request, isNotNull);
    expect(await overlay.prepareTurnAudioAndUpdateState(
      turn.after, audioRequests: [request!],
    ), isTrue);
    await overlay.waitForPendingVisualSync();
    var sawParticles = false;
    var sawPixels = false;
    bool? bothCombatantsVisibleAtStart;
    var completedAudio = false;
    for (var i = 0; i < 400; i++) {
      overlay.updateTree(1 / 60);
      overlay.findGame()!.processLifecycleEvents();
      await Future<void>.delayed(Duration.zero);
      for (final effect in overlay.children.whereType<BattleSplStaticComponent>()) {
        sawParticles = sawParticles || effect.playback.activeParticles > 0;
        if (effect.playback.activeParticles > 0 &&
            bothCombatantsVisibleAtStart == null) {
          final playerRect =
              overlay.debugPlayerCombatant?.currentEffectAttachmentSpriteRect;
          final enemyRect =
              overlay.debugEnemyCombatant?.currentEffectAttachmentSpriteRect;
          final viewport = ui.Rect.fromLTWH(0, 0, 390, 844);
          bothCombatantsVisibleAtStart =
              playerRect != null &&
              enemyRect != null &&
              viewport.contains(playerRect.center) &&
              viewport.contains(enemyRect.center);
        }
        if (!sawPixels && effect.playback.tick >= 4 && effect.playback.activeParticles > 0) {
          final recorder = ui.PictureRecorder();
          effect.render(ui.Canvas(recorder));
          final picture = recorder.endRecording();
          final image = await picture.toImage(390, 844);
          try {
            final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer.asUint8List();
            for (var j = 3; j < bytes.length; j += 4) {
              if (bytes[j] != 0) {
                sawPixels = true;
                break;
              }
            }
          } finally {
            image.dispose();
            picture.dispose();
          }
        }
      }
      if (!completedAudio && voice.resumes > 0) {
        completedAudio = true;
        voice.complete.add(null);
        expect(budget.residentBytes, greaterThan(0));
      }
    }
    expect(voice.resumes, 1);
    expect(sawParticles, isTrue);
    expect(sawPixels, isTrue);
    expect(bothCombatantsVisibleAtStart, isTrue);
    expect(sounds.where((name) => name == 'hit'), hasLength(1));
    expect(hpTransitions, hasLength(1));
    expect(budget.residentBytes, 0);
  });

  test('removing the scene releases an unstarted grouped SPL effect', () async {
    final root = await Directory.systemTemp.createTemp('grouped-spl-cancel-');
    addTearDown(() => root.delete(recursive: true));
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final media = await _groupedOfflineMedia(root, budget);
    final turn = _realTurn();
    final event = turn.events.firstWhere(
      (entry) => entry.execution.attackerSide == BattleSideId.player,
    );
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final overlay = BattleOverlayComponent(
      session: turn.before,
      viewportSize: Vector2(390, 844),
      onPlayerChoice: (_) {},
    );
    await loadFlameComponent(overlay);
    await overlay.waitForPendingVisualSync();
    addTearDown(overlay.onRemove);
    final request = await overlay.prepareGroupedSplTurn(
      event: event, media: media, player: player,
    );
    expect(request, isNotNull);
    expect(budget.residentBytes, greaterThan(0));
    overlay.onRemove();
    for (var i = 0; i < 100 && budget.residentBytes != 0; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(budget.residentBytes, 0);
    expect(voice.resumes, 0);
  });

  for (final failAudio in [true, false]) {
    test('grouped SPL releases media when ${failAudio ? 'audio preparation fails' : 'the running scene closes'}', () async {
      final root = await Directory.systemTemp.createTemp('grouped-spl-failure-');
      addTearDown(() => root.delete(recursive: true));
      final budget = RuntimeResourceBudget();
      addTearDown(budget.dispose);
      final media = await _groupedOfflineMedia(root, budget);
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final voice = _Voice(failSource: failAudio);
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      late final BattleOverlayComponent overlay;
      overlay = BattleOverlayComponent(
        session: turn.before,
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
        onStartRecoverableTrackedEffect: (step, done, fail) =>
            overlay.startGroupedSplEffect(step, done, fail),
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      final request = await overlay.prepareGroupedSplTurn(
        event: event, media: media, player: player,
      );
      expect(request, isNotNull);
      expect(await overlay.prepareTurnAudioAndUpdateState(
        turn.after, audioRequests: [request!],
      ), isTrue);
      await overlay.waitForPendingVisualSync();
      if (!failAudio) {
        for (var i = 0; i < 300 && voice.resumes == 0; i++) {
          overlay.updateTree(1 / 60);
          overlay.findGame()!.processLifecycleEvents();
          await Future<void>.delayed(Duration.zero);
        }
        expect(voice.resumes, 1);
        expect(budget.residentBytes, greaterThan(0));
        overlay.onRemove();
      }
      await voice.disposed.future.timeout(const Duration(seconds: 2));
      for (var i = 0; i < 100 && budget.residentBytes != 0; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(budget.residentBytes, 0);
      expect(voice.resumes, failAudio ? 0 : 1);
    });
  }

  test('reducing motion during grouped SPL restores the silent fallback', () async {
    final root = await Directory.systemTemp.createTemp('grouped-spl-motion-');
    addTearDown(() => root.delete(recursive: true));
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final media = await _groupedOfflineMedia(root, budget);
    final turn = _realTurn();
    final event = turn.events.firstWhere(
      (entry) => entry.execution.attackerSide == BattleSideId.player,
    );
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final sounds = <String>[];
    final hpTransitions = <int>{};
    late final BattleOverlayComponent overlay;
    overlay = BattleOverlayComponent(
      session: turn.before,
      viewportSize: Vector2(390, 844),
      onPlayerChoice: (_) {},
      playSfx: (name, {required volume, required pitch}) => sounds.add(name),
      onStartRecoverableTrackedEffect: (step, done, fail) =>
          overlay.startGroupedSplEffect(step, done, fail),
      onCommandOverlaySnapshotChanged: (snapshot) {
        final hud = snapshot?.enemyHud;
        if (hud?.targetDisplayedHp == turn.after.state.enemy.currentHp) {
          hpTransitions.add(hud!.hpTweenRevision);
        }
      },
    );
    await loadFlameComponent(overlay);
    await overlay.waitForPendingVisualSync();
    addTearDown(overlay.onRemove);
    final request = await overlay.prepareGroupedSplTurn(
      event: event, media: media, player: player,
    );
    expect(request, isNotNull);
    expect(await overlay.prepareTurnAudioAndUpdateState(
      turn.after, audioRequests: [request!],
    ), isTrue);
    await overlay.waitForPendingVisualSync();
    for (var i = 0; i < 300 && voice.resumes == 0; i++) {
      overlay.updateTree(1 / 60);
      overlay.findGame()!.processLifecycleEvents();
      await Future<void>.delayed(Duration.zero);
    }
    expect(voice.resumes, 1);
    expect(overlay.children.whereType<BattleSplStaticComponent>(), isNotEmpty);
    overlay.applyMotionPolicy(BattleMotionPolicy(reducedMotion: true, effectIntensity: 0));
    overlay.updateTree(1 / 60);
    overlay.findGame()!.processLifecycleEvents();
    expect(overlay.children.whereType<BattleSplStaticComponent>(), isEmpty);
    voice.complete.add(null);
    for (var i = 0; i < 300; i++) {
      overlay.updateTree(1 / 60);
      await Future<void>.delayed(Duration.zero);
    }
    expect(voice.resumes, 1);
    expect(sounds.where((name) => name == 'hit'), hasLength(1));
    expect(hpTransitions, hasLength(1));
    expect(budget.residentBytes, 0);
  });

  for (final closeWhileWaiting in [false, true]) {
    test('grouped SPL ${closeWhileWaiting ? 'cancels' : 'waits'} while the shared decode slot is busy', () async {
      final root = await Directory.systemTemp.createTemp('grouped-spl-budget-');
      addTearDown(() => root.delete(recursive: true));
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(maximumConcurrentDecodes: 1),
      );
      addTearDown(budget.dispose);
      final media = await _groupedOfflineMedia(root, budget);
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => _Voice());
      addTearDown(player.dispose);
      final overlay = BattleOverlayComponent(
        session: turn.before,
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      final occupied = await budget.acquire(transientBytes: 1024);
      addTearDown(occupied.release);
      var completed = false;
      final preparing = overlay.prepareGroupedSplTurn(
        event: event, media: media, player: player,
      )..then((_) => completed = true);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(completed, isFalse);
      if (closeWhileWaiting) {
        overlay.onRemove();
        expect(await preparing.timeout(const Duration(seconds: 1)), isNull);
      } else {
        occupied.release();
        final request = await preparing.timeout(const Duration(seconds: 1));
        expect(request, isNotNull);
        expect(budget.activeDecodes, 0);
        expect(budget.transientBytes, 0);
        overlay.discardGroupedSplTurn(request!);
      }
      occupied.release();
      for (var i = 0; i < 100 && budget.residentBytes != 0; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(budget.residentBytes, 0);
      expect(budget.activeDecodes, 0);
      expect(budget.transientBytes, 0);
      expect(budget.pendingDecodes, 0);
    });
  }

  test('a stale turn is not applied after audio preparation', () async {
    final turn = _realTurn();
    final event = turn.events.firstWhere(
      (entry) => entry.execution.attackerSide == BattleSideId.player,
    );
    final gate = Completer<void>();
    final voice = _Voice(sourceGate: gate);
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final coordinator = BattleRecipeAudioCoordinator(
      player: player,
      bundle: await _bundle(),
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    addTearDown(coordinator.cancel);
    final overlay = BattleOverlayComponent(
      session: turn.before,
      viewportSize: Vector2(390, 844),
      onPlayerChoice: (_) {},
    );
    await loadFlameComponent(overlay);
    await overlay.waitForPendingVisualSync();
    addTearDown(overlay.onRemove);
    var current = true;
    final pending = overlay.prepareTurnAudioAndUpdateState(
      turn.after,
      isCurrent: () => current,
      audioRequests: [
        BattleTurnAudioRequest(
          event: event,
          coordinator: coordinator,
          audio: const BattleMoveClipAudio('cue'),
          silentVisuals: const AnimationGroupStep(
            mode: BattleAnimationGroupMode.parallel,
            steps: [WaitStep(durationSeconds: 0)],
          ),
        ),
      ],
    );
    await voice.sourceSet.future.timeout(const Duration(seconds: 1));
    current = false;
    gate.complete();
    expect(await pending, isFalse);
    expect(identical(overlay.debugSession, turn.before), isTrue);
    await voice.disposed.future.timeout(const Duration(seconds: 1));
    expect(voice.resumes, 0);
  });

  test(
    'post-audio fallback does not replay sounds embedded in RMXP visuals',
    () async {
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final coordinator = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(coordinator.cancel);
      const rmxp = PlayRmxpAnimationStep(
        animationId: 84,
        subjectSide: BattleSideId.enemy,
        attackerSide: BattleSideId.player,
        defenderSide: BattleSideId.enemy,
        phase: RmxpPlacementPhase.target,
        placementSpec: RmxpPlacementSpec(
          policy: RmxpPlacementPolicy.targetImpact,
          anchor: BattleVisualAnchor.defenderImpact,
        ),
      );
      final plan = _realTurnPlan(
        turn.before,
        turn.after,
        recipeSteps: const [rmxp],
        selections: [
          BattleTurnAudioSelection(
            event: event,
            audio: await coordinator.prepare(const BattleMoveClipAudio('cue')),
            trackedEffectId: 'grouped-spl',
            silentVisuals: const AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [WaitStep(durationSeconds: 0)],
            ),
          ),
        ],
      );
      final effect = plan.flattenedSteps
          .whereType<StartTrackedEffectStep>()
          .single;
      expect(effect.fallbackSteps, contains(rmxp));
      final silent = effect.fallbackAfterAudioSteps!;
      expect(silent.whereType<PlayRmxpAnimationStep>(), isEmpty);
      expect(
        silent.whereType<WaitStep>().single.durationSeconds,
        rmxp.totalDurationSeconds,
      );
    },
  );

  test('unsupported tracked fallback cancels its prepared clip', () async {
    final turn = _realTurn();
    final event = turn.events.firstWhere(
      (entry) => entry.execution.attackerSide == BattleSideId.player,
    );
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final coordinator = BattleRecipeAudioCoordinator(
      player: player,
      bundle: await _bundle(),
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    addTearDown(coordinator.cancel);
    final plan = _realTurnPlan(
      turn.before,
      turn.after,
      recipeSteps: const [ShowMessageStep(message: 'unsupported')],
      selections: [
        BattleTurnAudioSelection(
          event: event,
          audio: await coordinator.prepare(const BattleMoveClipAudio('cue')),
          trackedEffectId: 'grouped-spl',
          silentVisuals: const AnimationGroupStep(
            mode: BattleAnimationGroupMode.parallel,
            steps: [WaitStep(durationSeconds: 0)],
          ),
        ),
      ],
    );
    expect(plan.audioScopes, isEmpty);
    expect(plan.flattenedSteps.whereType<StartTrackedEffectStep>(), isEmpty);
    await voice.disposed.future.timeout(const Duration(seconds: 1));
    expect(voice.resumes, 0);
  });

  test(
    'target damage flashes inside selected visuals fall back safely',
    () async {
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final baseline = _realTurnPlan(turn.before, turn.after);
      final plan = _realTurnPlan(
        turn.before,
        turn.after,
        selections: [
          BattleTurnAudioSelection(
            event: event,
            audio: await audio.prepare(const BattleMoveClipAudio('cue')),
            silentVisuals: const AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [
                AnimationGroupStep(
                  mode: BattleAnimationGroupMode.sequence,
                  steps: [
                    CombatantFlashStep(
                      side: BattleSideId.enemy,
                      durationSeconds: .1,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
      expect(plan.audioScopes, isEmpty);
      expect(
        plan.flattenedSteps.map((step) => step.runtimeType),
        baseline.flattenedSteps.map((step) => step.runtimeType),
      );
      await voice.disposed.future;
      expect(voice.resumes, 0);
    },
  );

  test('a selected camera follows the event attacker without losing its audio scope', () async {
    final turn = _realTurn();
    final event = turn.events.firstWhere(
      (entry) => entry.execution.attackerSide == BattleSideId.player,
    );
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: await _bundle(),
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    addTearDown(audio.cancel);
    final plan = _realTurnPlan(
      turn.before,
      turn.after,
      selections: [
        BattleTurnAudioSelection(
          event: event,
          audio: await audio.prepare(const BattleMoveClipAudio('cue')),
          silentVisuals: const AnimationGroupStep(
            mode: BattleAnimationGroupMode.parallel,
            steps: [
              CameraFocusStep(
                target: BattleCameraFocusTarget.user,
                durationSeconds: .1,
              ),
            ],
          ),
        ),
      ],
    );
    final focus = plan.flattenedSteps.whereType<CameraFocusStep>().firstWhere(
      (step) => step.target == BattleCameraFocusTarget.user,
    );
    expect(focus.side, BattleSideId.player);
    expect(focus.slotIndex, event.execution.attackerSlot.slotIndex);
    final runner = _scopeRunner();
    runner.start(plan);
    for (var i = 0; i < 100 && voice.resumes == 0; i++) {
      runner.update(.05);
      await Future<void>.delayed(Duration.zero);
    }
    expect(voice.resumes, 1);
  });

  test('a finishing turn retains its selected audio scope', () async {
    final turn = _realTurn(enemyHp: 1);
    expect(turn.after.state.isFinished, isTrue);
    final event = turn.events.firstWhere(
      (entry) => entry.execution.attackerSide == BattleSideId.player,
    );
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: await _bundle(),
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    addTearDown(audio.cancel);
    final plan = _realTurnPlan(
      turn.before,
      turn.after,
      selections: [
        BattleTurnAudioSelection(
          event: event,
          audio: await audio.prepare(const BattleMoveClipAudio('cue')),
          silentVisuals: const AnimationGroupStep(
            mode: BattleAnimationGroupMode.parallel,
            steps: [WaitStep(durationSeconds: .1)],
          ),
        ),
      ],
    );
    expect(plan.audioScopes, hasLength(1));
    final runner = _scopeRunner();
    runner.start(plan);
    for (var i = 0; i < 100 && voice.resumes == 0; i++) {
      runner.update(.05);
      await Future<void>.delayed(Duration.zero);
    }
    expect(voice.resumes, 1);
  });

  test(
    'removing the overlay cancels audio preparation before the turn starts',
    () async {
      final turn = _realTurn();
      final gate = Completer<void>();
      final voice = _Voice(sourceGate: gate);
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(() async {
        if (!gate.isCompleted) gate.complete();
        await audio.cancel();
      });
      final overlay = BattleOverlayComponent(
        session: turn.before,
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final pending = overlay.prepareTurnAudioAndUpdateState(
        turn.after,
        audioRequests: [
          BattleTurnAudioRequest(
            event: event,
            coordinator: audio,
            audio: const BattleMoveClipAudio('cue'),
            silentVisuals: const AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [WaitStep(durationSeconds: .1)],
            ),
          ),
        ],
      );
      await voice.sourceSet.future;
      expect(overlay.isTurnPresentationActive, isTrue);
      overlay.onRemove();
      expect(await pending.timeout(const Duration(milliseconds: 500)), isFalse);
      expect(overlay.debugSession.state.currentTurn, isNull);
      expect(voice.resumes, 0);
    },
  );

  test(
    'waiting for turn presentation includes pending audio preparation',
    () async {
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final gate = Completer<void>();
      final voice = _Voice(sourceGate: gate);
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(() async {
        if (!gate.isCompleted) gate.complete();
        await audio.cancel();
      });
      final overlay = BattleOverlayComponent(
        session: turn.before,
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      final preparing = overlay.prepareTurnAudioAndUpdateState(
        turn.after,
        audioRequests: [
          BattleTurnAudioRequest(
            event: event,
            coordinator: audio,
            audio: const BattleMoveClipAudio('cue'),
            silentVisuals: const AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [WaitStep(durationSeconds: .1)],
            ),
          ),
        ],
      );
      await voice.sourceSet.future;
      var completed = false;
      final waiting = overlay.waitForTurnPresentationComplete().then(
        (_) => completed = true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      gate.complete();
      expect(await preparing, isTrue);
      await overlay.waitForPendingVisualSync();
      for (var i = 0; i < 300 && !completed; i++) {
        overlay.updateTree(1 / 60);
        await Future<void>.delayed(Duration.zero);
      }
      await waiting.timeout(const Duration(seconds: 1));
      expect(completed, isTrue);
      expect(voice.resumes, 1);
    },
  );

  test(
    'cancelling a later audio preparation also releases earlier ready audio',
    () async {
      final turn = _realTurn(enemyAttacks: true);
      final gate = Completer<void>();
      final secondCreated = Completer<_Voice>();
      final voices = <_Voice>[];
      final player = FlameAudioBattleSfxPlayer(
        playerFactory: () {
          final voice = _Voice(sourceGate: voices.isEmpty ? null : gate);
          voices.add(voice);
          if (voices.length == 2) secondCreated.complete(voice);
          return voice;
        },
      );
      addTearDown(player.dispose);
      final bundle = await _bundle();
      final audios = List.generate(
        2,
        (_) => BattleRecipeAudioCoordinator(
          player: player,
          bundle: bundle,
          preparationTimeout: const Duration(seconds: 1),
          startTimeout: const Duration(seconds: 1),
        ),
      );
      addTearDown(() async {
        if (!gate.isCompleted) gate.complete();
        for (final audio in audios) {
          await audio.cancel();
        }
      });
      final overlay = BattleOverlayComponent(
        session: turn.before,
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      final pending = overlay.prepareTurnAudioAndUpdateState(
        turn.after,
        audioRequests: [
          for (var i = 0; i < 2; i++)
            BattleTurnAudioRequest(
              event: turn.events[i],
              coordinator: audios[i],
              audio: const BattleMoveClipAudio('cue'),
              silentVisuals: const AnimationGroupStep(
                mode: BattleAnimationGroupMode.parallel,
                steps: [WaitStep(durationSeconds: .1)],
              ),
            ),
        ],
      );
      final second = await secondCreated.future;
      await second.sourceSet.future;
      expect(voices.map((voice) => voice.resumes), [0, 0]);
      overlay.onRemove();
      expect(await pending.timeout(const Duration(seconds: 1)), isFalse);
      await Future.wait(voices.map((voice) => voice.disposed.future));
      expect(voices.map((voice) => voice.resumes), [0, 0]);
      gate.complete();
    },
  );

  test(
    'a turn planning timeout is not mistaken for audio preparation timeout',
    () async {
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      var thrown = false;
      var armed = false;
      late BattleOverlayComponent overlay;
      overlay = BattleOverlayComponent(
        session: turn.before,
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
        resolveMoveDisplayName: (id, fallback) {
          if (armed && !thrown && !overlay.isTurnPresentationActive) {
            thrown = true;
            throw TimeoutException('presentation failed');
          }
          return fallback;
        },
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      armed = true;
      await expectLater(
        overlay.prepareTurnAudioAndUpdateState(
          turn.after,
          audioRequests: [
            BattleTurnAudioRequest(
              event: event,
              coordinator: audio,
              audio: const BattleMoveClipAudio('cue'),
              silentVisuals: const AnimationGroupStep(
                mode: BattleAnimationGroupMode.parallel,
                steps: [WaitStep(durationSeconds: .1)],
              ),
            ),
          ],
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(thrown, isTrue);
      expect(voice.resumes, 0);
    },
  );

  test('external cancellation unlocks the turn without applying it', () async {
    final turn = _realTurn();
    final event = turn.events.firstWhere(
      (entry) => entry.execution.attackerSide == BattleSideId.player,
    );
    final gate = Completer<void>();
    final voice = _Voice(sourceGate: gate);
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: await _bundle(),
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    addTearDown(() async {
      if (!gate.isCompleted) gate.complete();
      await audio.cancel();
    });
    final overlay = BattleOverlayComponent(
      session: turn.before,
      viewportSize: Vector2(390, 844),
      onPlayerChoice: (_) {},
    );
    await loadFlameComponent(overlay);
    await overlay.waitForPendingVisualSync();
    addTearDown(overlay.onRemove);
    final pending = overlay.prepareTurnAudioAndUpdateState(
      turn.after,
      audioRequests: [
        BattleTurnAudioRequest(
          event: event,
          coordinator: audio,
          audio: const BattleMoveClipAudio('cue'),
          silentVisuals: const AnimationGroupStep(
            mode: BattleAnimationGroupMode.parallel,
            steps: [WaitStep(durationSeconds: .1)],
          ),
        ),
      ],
    );
    await voice.sourceSet.future;
    await audio.cancel();
    expect(await pending, isFalse);
    expect(overlay.isTurnPresentationActive, isFalse);
    expect(identical(overlay.debugSession, turn.before), isTrue);
    expect(voice.resumes, 0);
    gate.complete();
  });

  test(
    'a turn audio timeout plays the legacy turn without waiting for stop',
    () async {
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final sourceGate = Completer<void>();
      final stopGate = Completer<void>();
      final voice = _Voice(sourceGate: sourceGate, stopGate: stopGate);
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(() async {
        if (!sourceGate.isCompleted) sourceGate.complete();
        if (!stopGate.isCompleted) stopGate.complete();
        await audio.cancel();
      });
      final sounds = <String>[];
      final hpTransitions = <int>{};
      final overlay = BattleOverlayComponent(
        session: turn.before,
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
        playSfx: (name, {required volume, required pitch}) => sounds.add(name),
        onCommandOverlaySnapshotChanged: (snapshot) {
          final hud = snapshot?.enemyHud;
          if (hud?.targetDisplayedHp == turn.after.state.enemy.currentHp) {
            hpTransitions.add(hud!.hpTweenRevision);
          }
        },
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      final pending = overlay.prepareTurnAudioAndUpdateState(
        turn.after,
        preparationTimeout: const Duration(milliseconds: 50),
        audioRequests: [
          BattleTurnAudioRequest(
            event: event,
            coordinator: audio,
            audio: const BattleMoveClipAudio('cue'),
            silentVisuals: const AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [WaitStep(durationSeconds: .1)],
            ),
          ),
        ],
      );
      await voice.sourceSet.future;
      expect(await pending.timeout(const Duration(seconds: 1)), isTrue);
      await voice.stopping.future.timeout(const Duration(seconds: 1));
      expect(voice.disposals, 0);
      expect(voice.resumes, 0);
      await overlay.waitForPendingVisualSync();
      for (var i = 0; i < 300; i++) {
        overlay.updateTree(1 / 60);
        await Future<void>.delayed(Duration.zero);
      }
      expect(sounds.where((name) => name == 'hit'), hasLength(1));
      expect(hpTransitions, hasLength(1));
      sourceGate.complete();
      stopGate.complete();
      await audio.cancel();
    },
  );

  test(
    'replacing the turn cancels slow audio preparation before it can apply',
    () async {
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final gate = Completer<void>();
      final voice = _Voice(sourceGate: gate);
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(() async {
        if (!gate.isCompleted) gate.complete();
        await audio.cancel();
      });
      final overlay = BattleOverlayComponent(
        session: turn.before,
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      final pending = overlay.prepareTurnAudioAndUpdateState(
        turn.after,
        audioRequests: [
          BattleTurnAudioRequest(
            event: event,
            coordinator: audio,
            audio: const BattleMoveClipAudio('cue'),
            silentVisuals: const AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [WaitStep(durationSeconds: .1)],
            ),
          ),
        ],
      );
      await voice.sourceSet.future;
      overlay.updateState(turn.before);
      expect(await pending.timeout(const Duration(seconds: 1)), isFalse);
      expect(identical(overlay.debugSession, turn.before), isTrue);
      expect(voice.resumes, 0);
      gate.complete();
      await audio.cancel();
    },
  );

  test(
    'removing the overlay during visual prewarm cancels the pending clip',
    () async {
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final result = await audio.prepare(const BattleMoveClipAudio('cue'));
      final gate = Completer<ui.Image>();
      final started = Completer<void>();
      final cache = BattleFxBundleCache(
        imageLoader: (key) {
          if (key.endsWith('/anim008_elec.png')) {
            if (!started.isCompleted) started.complete();
            return gate.future;
          }
          return _tinyFxImage();
        },
      );
      addTearDown(cache.dispose);
      final overlay = BattleOverlayComponent(
        session: turn.before,
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
        fxBundleCache: cache,
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      overlay.updateState(
        turn.after,
        audioSelections: [
          BattleTurnAudioSelection(
            event: event,
            audio: result,
            silentVisuals: const AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [
                SpawnFxStep(
                  effectId: 'electroball',
                  attackerSide: BattleSideId.player,
                  defenderSide: BattleSideId.enemy,
                  from: BattleVisualAnchor.attackerCenter,
                  to: BattleVisualAnchor.defenderCenter,
                  durationSeconds: .2,
                ),
              ],
            ),
          ),
        ],
      );
      final pending = overlay.waitForPendingVisualSync();
      try {
        await started.future.timeout(const Duration(seconds: 2));
        expect(voice.resumes, 0);
        overlay.onRemove();
        await voice.disposed.future.timeout(const Duration(seconds: 2));
        expect(voice.resumes, 0);
      } finally {
        gate.complete(await _tinyFxImage());
        await pending;
      }
    },
  );

  test(
    'replacing a turn during visual prewarm releases the old clip',
    () async {
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final gate = Completer<ui.Image>();
      final started = Completer<void>();
      final cache = BattleFxBundleCache(
        imageLoader: (key) {
          if (key.endsWith('/anim008_elec.png')) {
            if (!started.isCompleted) started.complete();
            return gate.future;
          }
          return _tinyFxImage();
        },
      );
      addTearDown(cache.dispose);
      final overlay = BattleOverlayComponent(
        session: turn.before,
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
        fxBundleCache: cache,
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      overlay.updateState(
        turn.after,
        audioSelections: [
          BattleTurnAudioSelection(
            event: event,
            audio: await audio.prepare(const BattleMoveClipAudio('cue')),
            silentVisuals: const AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [
                SpawnFxStep(
                  effectId: 'electroball',
                  attackerSide: BattleSideId.player,
                  defenderSide: BattleSideId.enemy,
                  from: BattleVisualAnchor.attackerCenter,
                  to: BattleVisualAnchor.defenderCenter,
                  durationSeconds: .2,
                ),
              ],
            ),
          ),
        ],
      );
      final oldPending = overlay.waitForPendingVisualSync();
      try {
        await started.future.timeout(const Duration(seconds: 2));
        overlay.updateState(turn.after);
        await voice.disposed.future.timeout(const Duration(seconds: 2));
        await overlay.waitForPendingVisualSync();
        expect(voice.resumes, 0);
      } finally {
        gate.complete(await _tinyFxImage());
        await oldPending;
      }
      expect(voice.resumes, 0);
    },
  );

  test(
    'a current visual prewarm failure stays visible and releases its clip',
    () async {
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: await _bundle(),
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final cache = BattleFxBundleCache(
        imageLoader: (key) {
          if (key.endsWith('/anim008_elec.png')) {
            return Future<ui.Image>.error(
              const RuntimeResourceAdmissionException('cancelled_or_closed'),
            );
          }
          return _tinyFxImage();
        },
      );
      addTearDown(cache.dispose);
      final overlay = BattleOverlayComponent(
        session: turn.before,
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
        fxBundleCache: cache,
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      overlay.updateState(
        turn.after,
        audioSelections: [
          BattleTurnAudioSelection(
            event: event,
            audio: await audio.prepare(const BattleMoveClipAudio('cue')),
            silentVisuals: const AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [
                SpawnFxStep(
                  effectId: 'electroball',
                  attackerSide: BattleSideId.player,
                  defenderSide: BattleSideId.enemy,
                  from: BattleVisualAnchor.attackerCenter,
                  to: BattleVisualAnchor.defenderCenter,
                  durationSeconds: .2,
                ),
              ],
            ),
          ),
        ],
      );
      await expectLater(
        overlay.waitForPendingVisualSync(),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      await voice.disposed.future;
      expect(voice.resumes, 0);
    },
  );

  test(
    'battle overlay recovers after clip playback without repeating sound or HP',
    () async {
      final bundle = await _bundle();
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: bundle,
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      final result = await audio.prepare(const BattleMoveClipAudio('cue'));
      final scope = BattleMoveAudioScope.compose(
        audio: result,
        silentVisuals: const AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: [WaitStep(durationSeconds: 1)],
        ),
        fallback: const [PlaySeStep(seName: 'legacy-move')],
      );
      const stats = BattleStatsSnapshot(
        attack: 20,
        defense: 20,
        specialAttack: 20,
        specialDefense: 20,
        speed: 20,
      );
      const pokemon = BattleCombatantData(
        speciesId: 'synthetic',
        level: 7,
        maxHp: 25,
        currentHp: 25,
        stats: stats,
        moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 40)],
      );
      final sounds = <String>[];
      final hpTransitions = <int>[];
      var tweening = false;
      late void Function() failEffect;
      final overlay = BattleOverlayComponent(
        session: createBattleSession(
          BattleSetup.pokeMapBetaV1ForTest(
            playerPokemon: pokemon,
            enemyPokemon: pokemon,
            isTrainerBattle: false,
            trainerId: null,
          ),
        ),
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
        onCommandOverlaySnapshotChanged: (snapshot) {
          final hud = snapshot?.enemyHud;
          final current = hud?.targetDisplayedHp == 15;
          if (current && !tweening) hpTransitions.add(hud!.hpTweenRevision);
          tweening = current;
        },
        playSfx: (name, {required volume, required pitch}) =>
            sounds.add('$name:$volume:$pitch'),
        onStartRecoverableTrackedEffect: (_, _, fail) {
          failEffect = fail;
          return () {};
        },
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      overlay.presentPostBattlePlan(
        BattleAnimationPlan(
          steps: [
            const StartTrackedEffectStep(
              effectId: 'bw2',
              fallbackSteps: [PlaySeStep(seName: 'legacy-move')],
              fallbackAfterAudioSteps: [],
            ),
            ...scope.steps,
            const WaitTrackedEffectsStep(),
            const PlaySeStep(seName: 'impact', volume: 65, pitch: 90),
            const HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 25,
              toHp: 15,
            ),
          ],
          audioScopes: scope.audioScopes,
        ),
      );
      await voice.resuming.future;
      failEffect();
      overlay.updateTree(.01);
      expect(voice.resumes, 1);
      expect(sounds, ['impact:65:90']);
      expect(hpTransitions, [1]);
      overlay.onRemove();
      await voice.disposed.future;
      expect(voice.disposals, 1);
    },
  );

  test(
    'cancels one pending sound without interrupting another voice',
    () async {
      final bytes = await File('assets/audio/overworld/jump.wav').readAsBytes();
      final gate = Completer<void>();
      final voices = <_Voice>[];
      final player = FlameAudioBattleSfxPlayer(
        playerFactory: () {
          final voice = _Voice(sourceGate: voices.isEmpty ? null : gate);
          voices.add(voice);
          return voice;
        },
      );
      addTearDown(() async => player.dispose());

      final first = await player.prepareRecipeSound(bytes, 'audio/wav');
      final pending = player.beginRecipeSound(bytes, 'audio/wav');
      final rejected = expectLater(pending.ready, throwsStateError);
      await voices[1].sourceSet.future;
      try {
        await pending.cancel().timeout(const Duration(milliseconds: 500));
        await rejected.timeout(const Duration(milliseconds: 500));
        expect(player.livePlayerCount, 1);
        expect(voices[0].disposals, 0);
        await first.start();
        expect(voices[0].resumes, 1);
      } finally {
        gate.complete();
      }
    },
  );

  test(
    'cancelling an ignored preparation does not leak an asynchronous error',
    () async {
      final bytes = await File('assets/audio/overworld/jump.wav').readAsBytes();
      final gate = Completer<void>();
      final voice = _Voice(sourceGate: gate);
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);

      final pending = player.beginRecipeSound(bytes, 'audio/wav');
      await voice.sourceSet.future;
      try {
        await pending.cancel();
        await Future<void>.delayed(Duration.zero);
        expect(voice.disposals, 1);
      } finally {
        gate.completeError(StateError('late decoder error'));
        await Future<void>.delayed(Duration.zero);
      }
    },
  );

  test(
    'prepares verified audio without playing, then uses the battle mix',
    () async {
      final bundle = await _bundle();
      final voices = <_Voice>[];
      final mixer = RuntimeAudioMixer(
        mix: const RuntimeAudioMix(masterVolume: .5, effectsVolume: .4),
      );
      final player = FlameAudioBattleSfxPlayer(
        mixer: mixer,
        playerFactory: () {
          final voice = _Voice();
          voices.add(voice);
          return voice;
        },
      );
      addTearDown(() async => player.dispose());

      final sound = await player.prepareVerifiedRecipeSound(bundle, 'cue');
      expect(voices, hasLength(1));
      expect(voices.single.resumes, 0);
      final source = voices.single.source as DeviceFileSource;
      final file = File(source.path);
      expect(source.mimeType, 'audio/wav');
      expect(file.path, endsWith('.wav'));
      expect(await file.readAsBytes(), orderedEquals(bundle.media['cue']!));
      await sound.start();
      expect(voices.single.resumes, 1);
      expect(voices.single.volumes, [.2]);
      await mixer.transitionTo(const RuntimeAudioMix(masterVolume: 0));
      expect(voices.single.volumes.last, 0);
      await sound.dispose();
      expect(await file.parent.exists(), isFalse);
      expect(player.livePlayerCount, 0);
    },
  );

  test('rejects an unknown sound before creating a player', () async {
    final bundle = await _bundle();
    final voices = <_Voice>[];
    final player = FlameAudioBattleSfxPlayer(
      playerFactory: () {
        final voice = _Voice();
        voices.add(voice);
        return voice;
      },
    );
    addTearDown(player.dispose);

    await expectLater(
      player.prepareVerifiedRecipeSound(bundle, 'missing'),
      throwsFormatException,
    );
    expect(voices, isEmpty);
  });

  test('overlapping copies have independent sources and cleanup', () async {
    final bundle = await _bundle();
    final voices = <_Voice>[];
    final player = FlameAudioBattleSfxPlayer(
      maxConcurrentVoices: 2,
      playerFactory: () {
        final voice = _Voice();
        voices.add(voice);
        return voice;
      },
    );
    addTearDown(player.dispose);

    final first = await player.prepareVerifiedRecipeSound(bundle, 'cue');
    final second = await player.prepareVerifiedRecipeSound(bundle, 'cue');
    final firstFile = File((voices[0].source as DeviceFileSource).path);
    final secondFile = File((voices[1].source as DeviceFileSource).path);
    expect(firstFile.path, isNot(secondFile.path));
    await expectLater(
      player.prepareVerifiedRecipeSound(bundle, 'cue'),
      throwsStateError,
    );
    await first.start();
    await second.start();
    voices[0].complete.add(null);
    await first.dispose();
    expect(await firstFile.parent.exists(), isFalse);
    expect(await secondFile.exists(), isTrue);
    expect(player.livePlayerCount, 1);
    await second.dispose();
    expect(await secondFile.parent.exists(), isFalse);
    expect(player.livePlayerCount, 0);
  });

  test('releases the source when native preparation fails', () async {
    final bundle = await _bundle();
    final voice = _Voice(failSource: true);
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);

    await expectLater(
      player.prepareVerifiedRecipeSound(bundle, 'cue'),
      throwsStateError,
    );
    final file = File((voice.source as DeviceFileSource).path);
    expect(voice.disposals, 1);
    expect(await file.parent.exists(), isFalse);
    expect(player.livePlayerCount, 0);
  });

  test('owner disposal cancels a sound still being prepared', () async {
    final bundle = await _bundle();
    final sourceGate = Completer<void>();
    final voice = _Voice(sourceGate: sourceGate);
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);

    final preparation = player.prepareVerifiedRecipeSound(bundle, 'cue');
    final rejected = expectLater(preparation, throwsStateError);
    await voice.sourceSet.future;
    final file = File((voice.source as DeviceFileSource).path);
    final closing = player.dispose();
    sourceGate.complete();
    await rejected;
    await closing;
    expect(voice.resumes, 0);
    expect(voice.disposals, 1);
    expect(await file.parent.exists(), isFalse);
    expect(player.livePlayerCount, 0);
  });

  test('owner disposal does not wait for an unresponsive decoder', () async {
    final bundle = await _bundle();
    final sourceGate = Completer<void>();
    final voice = _Voice(sourceGate: sourceGate);
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);

    final preparation = player.prepareVerifiedRecipeSound(bundle, 'cue');
    final rejected = expectLater(preparation, throwsStateError);
    await voice.sourceSet.future;
    final file = File((voice.source as DeviceFileSource).path);
    final closing = player.dispose();
    try {
      await closing.timeout(const Duration(milliseconds: 500));
      await rejected.timeout(const Duration(milliseconds: 500));
      expect(voice.disposals, 1);
      expect(await file.parent.exists(), isFalse);
      expect(player.livePlayerCount, 0);
    } finally {
      sourceGate.complete();
      await rejected;
      await closing;
    }
  });

  test('owner disposal cancels an unresponsive playback start', () async {
    final bundle = await _bundle();
    final resumeGate = Completer<void>();
    final voice = _Voice(resumeGate: resumeGate);
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);

    final sound = await player.prepareVerifiedRecipeSound(bundle, 'cue');
    final file = File((voice.source as DeviceFileSource).path);
    final rejected = expectLater(sound.start(), throwsStateError);
    await voice.resuming.future;
    final closing = player.dispose();
    try {
      await closing.timeout(const Duration(milliseconds: 500));
      await rejected.timeout(const Duration(milliseconds: 500));
      expect(voice.disposals, 1);
      expect(await file.parent.exists(), isFalse);
      expect(player.livePlayerCount, 0);
    } finally {
      resumeGate.completeError(StateError('late player failure'));
      await rejected;
      await closing;
      await Future<void>.delayed(Duration.zero);
    }
  });

  test('copies source bytes before asynchronous preparation', () async {
    final bytes = await File('assets/audio/overworld/jump.wav').readAsBytes();
    final expected = List<int>.of(bytes);
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);

    final preparation = player.prepareRecipeSound(bytes, 'audio/wav');
    bytes[0] ^= 1;
    final sound = await preparation;
    final file = File((voice.source as DeviceFileSource).path);
    expect(await file.readAsBytes(), orderedEquals(expected));
    await sound.dispose();
  });

  test(
    'rejects empty and unsupported raw sources before creating a voice',
    () async {
      final voices = <_Voice>[];
      final player = FlameAudioBattleSfxPlayer(
        playerFactory: () {
          final voice = _Voice();
          voices.add(voice);
          return voice;
        },
      );
      addTearDown(player.dispose);

      await expectLater(
        player.prepareRecipeSound(Uint8List(0), 'audio/wav'),
        throwsFormatException,
      );
      await expectLater(
        player.prepareRecipeSound(Uint8List(1), 'audio/unknown'),
        throwsFormatException,
      );
      await expectLater(
        player.prepareRecipeSound(Uint8List(8 * 1024 * 1024 + 1), 'audio/wav'),
        throwsFormatException,
      );
      expect(voices, isEmpty);
    },
  );

  test(
    'limits prepared recipe voices when legacy voices are unlimited',
    () async {
      final bundle = await _bundle();
      final player = FlameAudioBattleSfxPlayer(playerFactory: _Voice.new);
      addTearDown(player.dispose);

      for (var i = 0; i < 8; i++) {
        await player.prepareVerifiedRecipeSound(bundle, 'cue');
      }
      await expectLater(
        player.prepareVerifiedRecipeSound(bundle, 'cue'),
        throwsStateError,
      );
      expect(player.livePlayerCount, 8);
      await player.dispose();
      expect(player.livePlayerCount, 0);
    },
  );

  test('releases the voice if native playback cannot start', () async {
    final bundle = await _bundle();
    final voice = _Voice(failResume: true);
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);

    final sound = await player.prepareVerifiedRecipeSound(bundle, 'cue');
    final file = File((voice.source as DeviceFileSource).path);
    await expectLater(sound.start(), throwsStateError);
    expect(voice.disposals, 1);
    expect(await file.parent.exists(), isFalse);
    expect(player.livePlayerCount, 0);
  });

  test('completion automatically releases the prepared voice', () async {
    final bundle = await _bundle();
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);

    final sound = await player.prepareVerifiedRecipeSound(bundle, 'cue');
    final file = File((voice.source as DeviceFileSource).path);
    await sound.start();
    voice.complete.add(null);
    await voice.disposed.future;
    await sound.dispose();
    expect(await file.parent.exists(), isFalse);
    expect(player.livePlayerCount, 0);
  });

  test('owner waits for a voice already being released', () async {
    final bundle = await _bundle();
    final stopGate = Completer<void>();
    final voice = _Voice(stopGate: stopGate);
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);

    final sound = await player.prepareVerifiedRecipeSound(bundle, 'cue');
    final releasing = sound.dispose();
    await voice.stopping.future;
    var ownerClosed = false;
    final closing = player.dispose().then((_) => ownerClosed = true);
    await Future<void>.delayed(Duration.zero);
    try {
      expect(ownerClosed, isFalse);
    } finally {
      stopGate.complete();
      await releasing;
      await closing;
    }
    expect(ownerClosed, isTrue);
  });

  final sourcePath = Platform.environment['AVELUNE_RECIPE_SOUND_FILE'];

  test(
    'exported sound is verified offline before explicit real-turn playback',
    () => HttpOverrides.runZoned(() async {
      final sound = await File(sourcePath ?? 'assets/audio/overworld/jump.wav')
          .readAsBytes();
      final mediaType = sourcePath == null ? 'audio/wav' : 'audio/mpeg';
      final original = await _bundle(audio: sound, mediaType: mediaType);
      final binding = BattleMoveRecipeBinding.fromJson({
        'schemaVersion': 1,
        'projectMoveId': 'tackle',
        'sourceMoveId': 'flamethrower',
        'catalogReleaseId': 'fixture',
        'recipeId': 'fire',
        'variant': 'default',
        'revision': '1',
        'recipeSha256': sha256.convert(original.recipeBytes).toString(),
      });
      final fixture = await offlineRecipePackageFixture(
        spatial: false,
        fetchedRecipe: (
          binding: binding,
          bundle: original,
          catalogMoveId: 'catalog',
          recipeMediaId: 'fixture-sound',
        ),
      );
      final root = fixture.bundle.projectRootDirectory;
      final offline = await BattleOfflineMoveRecipeLoader(
        projectRootDirectory: root,
        resourceBudget: fixture.bundle.resourceBudget,
      ).load('tackle');
      expect(
        offline.fallbackReason,
        BattleRecipeFallbackReason.unavailableCapabilities,
      );
      expect(offline.unavailableCapabilities, {'sound'});
      expect(offline.prepared, isNull);
      final resource = original.recipe.resources.single;
      final recipeBytes = await File(
        p.join(
          root,
          battleRecipeBlobPath(
            binding.recipeSha256,
            'application/vnd.avelune.battle-recipe+json',
            projectMoveId: 'tackle',
          ),
        ),
      ).readAsBytes();
      final soundBytes = await File(
        p.join(
          root,
          battleRecipeBlobPath(
            resource.sha256Hex,
            resource.mediaType,
            projectMoveId: 'tackle',
          ),
        ),
      ).readAsBytes();
      final inspected = const BattleRecipeBundleInspector().inspect(
        binding,
        recipeBytes,
        {'cue': soundBytes},
        limits: const BattleRecipeBundleLimits(
          maxTextures: 0,
          maxTextureBytes: 0,
          maxBundleBytes: 8 * 1024 * 1024,
          maxDimension: 1,
          maxTexturePixels: 1,
          maxTotalPixels: 1,
        ),
        availableCapabilities: const {'sound'},
        expectedProjectMoveId: 'tackle',
        expectedCatalogReleaseId: 'fixture',
      );
      expect(soundBytes, orderedEquals(sound));
      final voice = _Voice();
      final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
      addTearDown(player.dispose);
      final audio = BattleRecipeAudioCoordinator(
        player: player,
        bundle: inspected,
        preparationTimeout: const Duration(seconds: 1),
        startTimeout: const Duration(seconds: 1),
      );
      addTearDown(audio.cancel);
      final turn = _realTurn();
      final event = turn.events.firstWhere(
        (entry) => entry.execution.attackerSide == BattleSideId.player,
      );
      final sounds = <String>[];
      final overlay = BattleOverlayComponent(
        session: turn.before,
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
        playSfx: (name, {required volume, required pitch}) => sounds.add(name),
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      expect(
        await overlay.prepareTurnAudioAndUpdateState(
          turn.after,
          audioRequests: [
            BattleTurnAudioRequest(
              event: event,
              coordinator: audio,
              audio: const BattleMoveClipAudio('cue'),
              silentVisuals: const AnimationGroupStep(
                mode: BattleAnimationGroupMode.parallel,
                steps: [WaitStep(durationSeconds: .1)],
              ),
            ),
          ],
        ),
        isTrue,
      );
      await overlay.waitForPendingVisualSync();
      for (var i = 0; i < 300; i++) {
        overlay.updateTree(1 / 60);
        await Future<void>.delayed(Duration.zero);
      }
      expect(voice.resumes, 1);
      expect(sounds.where((name) => name == 'hit'), hasLength(1));
      final source = voice.source as DeviceFileSource;
      expect(await File(source.path).readAsBytes(), orderedEquals(sound));
    }, createHttpClient: (_) => throw StateError('Network disabled')),
  );

  test('accepts and prepares a locally supplied verified MP3', () async {
    final input = await File(sourcePath!).readAsBytes();
    final bundle = await _bundle(audio: input, mediaType: 'audio/mpeg');
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);

    final sound = await player.prepareVerifiedRecipeSound(bundle, 'cue');
    final source = voice.source as DeviceFileSource;
    final file = File(source.path);
    expect(source.mimeType, 'audio/mpeg');
    expect(file.path, endsWith('.mp3'));
    expect(await file.readAsBytes(), orderedEquals(input));
    await sound.start();
    expect(voice.resumes, 1);
    await sound.dispose();
    expect(await file.parent.exists(), isFalse);
  }, skip: sourcePath == null ? 'No local sound supplied' : false);

  test('routes the local MP3 as one complete move clip', () async {
    final input = await File(sourcePath!).readAsBytes();
    final bundle = await _bundle(audio: input, mediaType: 'audio/mpeg');
    final voice = _Voice();
    final player = FlameAudioBattleSfxPlayer(playerFactory: () => voice);
    addTearDown(player.dispose);
    final audio = BattleRecipeAudioCoordinator(
      player: player,
      bundle: bundle,
      preparationTimeout: const Duration(seconds: 1),
      startTimeout: const Duration(seconds: 1),
    );
    final result = await audio.prepare(const BattleMoveClipAudio('cue'));
    expect(result.status, BattleRecipeAudioStatus.ready);
    final program = result.program!;
    final scope = BattleMoveAudioScope.compose(
      audio: result,
      silentVisuals: const AnimationGroupStep(
        mode: BattleAnimationGroupMode.parallel,
        steps: [WaitStep(durationSeconds: .1)],
      ),
      fallback: const [PlaySeStep(seName: 'legacy-move')],
    );
    final events = <String>[];
    final runner = _scopeRunner(onPlaySe: (step) => events.add(step.seName));
    runner.start(
      BattleAnimationPlan(steps: scope.steps, audioScopes: scope.audioScopes),
    );
    await Future<void>.delayed(Duration.zero);
    final source = voice.source as DeviceFileSource;
    expect(await File(source.path).readAsBytes(), orderedEquals(input));
    expect(voice.resumes, 1);
    expect(program.sourceSeqIds, isEmpty);
    expect(events, isEmpty);
    await audio.cancel();
  }, skip: sourcePath == null ? 'No local sound supplied' : false);
}

({
  BattleSession before,
  BattleSession after,
  List<BattleTurnExecutionEvent> events,
})
_realTurn({bool enemyAttacks = false, int enemyHp = 80}) {
  const stats = BattleStatsSnapshot(
    attack: 20,
    defense: 20,
    specialAttack: 20,
    specialDefense: 20,
    speed: 20,
  );
  const attack = BattleMoveData(
    id: 'tackle',
    name: 'Charge',
    power: 40,
    accuracy: BattleMoveAccuracy.alwaysHits(),
  );
  const wait = BattleMoveData(
    id: 'wait',
    name: 'Wait',
    power: 0,
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.self,
    accuracy: BattleMoveAccuracy.alwaysHits(),
  );
  final before = createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: const BattleCombatantData(
        speciesId: 'one',
        level: 7,
        maxHp: 80,
        currentHp: 80,
        stats: stats,
        moves: [attack],
      ),
      enemyPokemon: BattleCombatantData(
        speciesId: 'two',
        level: 7,
        maxHp: 80,
        currentHp: enemyHp,
        stats: stats,
        moves: [enemyAttacks ? attack : wait],
      ),
      isTrainerBattle: false,
      trainerId: null,
    ),
  );
  final after = before.applyChoice(const PlayerBattleChoiceFight(0));
  return (
    before: before,
    after: after,
    events: after.state.currentTurn!.timeline
        .whereType<BattleTurnExecutionEvent>()
        .toList(),
  );
}

Future<ui.Image> _tinyFxImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1), ui.Paint());
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(1, 1);
  } finally {
    picture.dispose();
  }
}

BattleAnimationPlan _realTurnPlan(
  BattleSession before,
  BattleSession after, {
  List<BattleTurnAudioSelection> selections = const [],
  List<BattleAnimationStep>? recipeSteps,
}) {
  final catalog = RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{});
  return BattleTurnAnimationPlanner(
    recipeBuilder: (_, _) =>
        recipeSteps ??
        const [
          PlaySeStep(seName: 'legacy-move'),
          WaitStep(durationSeconds: .1),
        ],
  ).build(
    previousSession: before,
    newSession: after,
    moveCatalog: catalog,
    resolver: BattleMoveVisualResolver(catalog),
    audioSelections: selections,
  );
}

BattleAnimationRunner _scopeRunner({
  void Function(PlaySeStep)? onPlaySe,
  void Function(ScreenFlashStep)? onScreenFlash,
  void Function(HudHpTweenStep)? onHudHpTween,
  void Function() Function(
    StartTrackedEffectStep,
    void Function(),
    void Function(),
  )?
  onStartRecoverableTrackedEffect,
}) => BattleAnimationRunner(
  onPresentationChanged: () {},
  onSpawnFx: (_) {},
  onScreenFlash: onScreenFlash ?? (_) {},
  onCombatantMotion: (_) {},
  onCombatantFlash: (_) {},
  onCombatantShake: (_) {},
  onFaintCombatant: (_) {},
  onHudHpTween: onHudHpTween ?? (_) {},
  onBarrierPulse: (_) {},
  onSwapCombatantVisual: (_) {},
  onPlaySe: onPlaySe,
  onStartRecoverableTrackedEffect: onStartRecoverableTrackedEffect,
);

final class _Voice implements AudioPlayer {
  _Voice({
    this.failSource = false,
    this.failResume = false,
    this.sourceGate,
    this.stopGate,
    this.resumeGate,
  });

  final bool failSource;
  final bool failResume;
  final Completer<void>? sourceGate;
  final Completer<void>? stopGate;
  final Completer<void>? resumeGate;
  final sourceSet = Completer<void>();
  final stopping = Completer<void>();
  final resuming = Completer<void>();
  final disposed = Completer<void>();
  final complete = StreamController<void>.broadcast();
  final volumes = <double>[];
  @override
  Source? source;
  var resumes = 0;
  var disposals = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #onPlayerComplete) return complete.stream;
    if (invocation.isSetter) return null;
    if (invocation.memberName == #setSource) {
      source = invocation.positionalArguments.single as Source;
      sourceSet.complete();
      if (failSource) return Future<void>.error(StateError('decoder failed'));
      if (sourceGate != null) return sourceGate!.future;
    }
    if (invocation.memberName == #setVolume) {
      volumes.add(invocation.positionalArguments.single as double);
    }
    if (invocation.memberName == #resume) {
      resumes++;
      resuming.complete();
      if (failResume) return Future<void>.error(StateError('playback failed'));
      if (resumeGate != null) return resumeGate!.future;
    }
    if (invocation.memberName == #stop) {
      stopping.complete();
      if (stopGate != null) return stopGate!.future;
    }
    if (invocation.memberName == #dispose) {
      disposals++;
      return complete.close().then((_) => disposed.complete());
    }
    return Future<void>.value();
  }
}
