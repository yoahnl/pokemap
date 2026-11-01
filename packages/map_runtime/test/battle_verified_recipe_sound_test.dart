import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
import 'package:map_runtime/src/presentation/flame/battle_recipe_audio_program.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_verified_recipe_sound_loader.dart';

import 'support/load_flame_component.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    'battle overlay dispatches the complete clip and HP transition once',
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
      final program = result.program!;
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
      final route = program.route(
        (String name, {required int volume, required int pitch}) =>
            sounds.add('$name:$volume:$pitch'),
      );
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
        playSfx: route,
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      overlay.presentPostBattlePlan(
        BattleAnimationPlan(
          steps: [
            ...program.steps,
            const PlaySeStep(seName: 'impact', volume: 65, pitch: 90),
            const HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 25,
              toHp: 15,
            ),
          ],
        ),
      );
      overlay.updateTree(.01);
      await Future<void>.delayed(Duration.zero);
      expect(voice.resumes, 1);
      expect(sounds, ['impact:65:90']);
      expect(hpTransitions, [1]);
      await audio.cancel();
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
    final events = <String>[];
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
      onPlaySe: (step) {
        if (!program.dispatch(step)) events.add(step.seName);
      },
    );
    runner.start(BattleAnimationPlan(steps: program.steps));
    await Future<void>.delayed(Duration.zero);
    final source = voice.source as DeviceFileSource;
    expect(await File(source.path).readAsBytes(), orderedEquals(input));
    expect(voice.resumes, 1);
    expect(program.sourceSeqIds, isEmpty);
    expect(events, isEmpty);
    await audio.cancel();
  }, skip: sourcePath == null ? 'No local sound supplied' : false);
}

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
