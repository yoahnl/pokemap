import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_sfx_player.dart';
import 'package:map_runtime/src/presentation/flame/battle_verified_recipe_sound_loader.dart';

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
