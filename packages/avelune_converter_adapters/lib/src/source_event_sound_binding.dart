import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'native_project_writer.dart';
import 'source_engine_game_ini.dart';

enum SourceEventAudioKind { sound, music, musicEffect, ambience }

enum SourceEventSoundPolicy { sourceEngineGain, nativeAuthoredVolume }

final class SourceEventSoundBindingUnavailable implements Exception {
  const SourceEventSoundBindingUnavailable(this.reason);
  final String reason;
}

final class SourceEventSoundBinding {
  const SourceEventSoundBinding._(
      {required this.name,
      required this.kind,
      required this.policy,
      required this.sourceSnapshotHash,
      required this.audioFile,
      required this.mediaId,
      required this.artifact,
      required this.mutation,
      required this.evidence});
  final String name, mediaId;
  final SourceEventAudioKind kind;
  final SourceEventSoundPolicy policy;
  final Sha256Hash sourceSnapshotHash;
  final SourceFileEntry audioFile;
  final NativeArtifact artifact;
  final NativeMutation mutation;
  final Map<String, Object?> evidence;

  double gainForVolume(int volume) {
    if (volume < 0 || volume > 100) throw ArgumentError.value(volume, 'volume');
    return policy == SourceEventSoundPolicy.nativeAuthoredVolume
        ? volume / 100
        : (volume * (const {SourceEventAudioKind.music, SourceEventAudioKind.ambience}.contains(kind) ? 80 : 60) ~/ 100) *
            0.008;
  }
}

final class SourceEventSoundResolver {
  const SourceEventSoundResolver();

  Future<SourceEventSoundBinding> read({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    required String name,
    SourceEventAudioKind kind = SourceEventAudioKind.sound,
    SourceEventSoundPolicy policy = SourceEventSoundPolicy.sourceEngineGain,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    limits.validate();
    if (!SourceEventProfile.forProject(source).isQualified ||
        source.snapshot.state != SourceScanState.complete) {
      _unavailable('profile_unqualified');
    }
    if (kind == SourceEventAudioKind.ambience && policy == SourceEventSoundPolicy.sourceEngineGain) {
      _unavailable('ambience_engine_parity_unqualified');
    }
    if (kind == SourceEventAudioKind.musicEffect &&
        policy != SourceEventSoundPolicy.nativeAuthoredVolume) {
      _unavailable('music_effect_engine_parity_unqualified');
    }
    if (name.isEmpty ||
        name.trim() != name ||
        name == '.' ||
        name == '..' ||
        (RegExp(r'[\\/:<>\x00-\x1f]').hasMatch(name) &&
            !RegExp(r'^Cries/[A-Z][A-Za-z0-9_]{0,63}$').hasMatch(name))) {
      _unavailable('name_unqualified');
    }
    SourceFileEntry exact(String path) {
      final matches = source.snapshot.entries
          .where((entry) =>
              sourcePathCollisionKey(entry.relativePath) ==
              sourcePathCollisionKey(path))
          .toList();
      if (matches.length != 1 ||
          matches.single.relativePath != path ||
          matches.single.kind != SourceNodeKind.file ||
          matches.single.sha256 == null) {
        _unavailable('source_unattested');
      }
      return matches.single;
    }

    SourceFileEntry? engine, config, ini;
    if (policy == SourceEventSoundPolicy.sourceEngineGain) {
      engine = exact('Game.exe');
      config = exact('mkxp.json');
      ini = exact('Game.ini');
      if (engine.byteLength != 14732288 ||
          engine.sha256!.value !=
              '5c75e92fcbb6ec50b9f8fc61913d751a8945d6a1fc69c3017c7b8686b532bf04' ||
          config.byteLength != 6212 ||
          config.sha256!.value !=
              '90a3aee82895e48e6c767f973b637d27856cccfd575f48b78d04191cb3e7d35f' ||
          ini.byteLength < 1 || ini.byteLength > 4096) {
        _unavailable('engine_unqualified');
      }
      if (ini.byteLength > limits.maxArtifactBytes ||
          ini.byteLength > limits.maxTotalArtifactBytes) {
        _unavailable('audio_quota');
      }
      final iniBytes = await files.read(ini.fileId);
      cancellation?.check();
      if (iniBytes.length != ini.byteLength ||
          crypto.sha256.convert(iniBytes).toString() != ini.sha256!.value) {
        _unavailable('engine_configuration_changed');
      }
      if (!sourceEngineGameIniIsLocal(iniBytes)) {
        _unavailable('engine_unqualified');
      }
    }
    final directory = switch (kind) {
      SourceEventAudioKind.sound => 'SE',
      SourceEventAudioKind.music => 'BGM',
      SourceEventAudioKind.musicEffect => 'ME',
      SourceEventAudioKind.ambience => 'BGS',
    };
    final base = 'Audio/$directory/$name';
    final key = sourcePathCollisionKey(base);
    if (kind == SourceEventAudioKind.music &&
        source.snapshot.entries.any((entry) {
          final path = sourcePathCollisionKey(entry.relativePath);
          final night = '${key}_n';
          return path == night ||
              path.startsWith('$night.') &&
                  !path.substring(night.length + 1).contains('/');
        })) {
      _unavailable('night_variant_unsupported');
    }
    final matches = source.snapshot.entries.where((entry) {
      final path = sourcePathCollisionKey(entry.relativePath);
      return path == key ||
          (path.startsWith('$key.') &&
              !path.substring(key.length + 1).contains('/'));
    }).toList();
    if (matches.length != 1) {
      _unavailable(matches.isEmpty ? 'audio_missing' : 'audio_ambiguous');
    }
    final audio = matches.single;
    if (audio.relativePath.length <= base.length + 1) {
      _unavailable('audio_unsupported');
    }
    final extension = audio.relativePath.substring(base.length + 1);
    final mediaType = const {
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'mp3': 'audio/mpeg',
      'flac': 'audio/flac'
    }[extension];
    if (mediaType == null || audio.relativePath != '$base.$extension') {
      _unavailable('audio_unsupported');
    }
    exact(audio.relativePath);
    if (audio.byteLength > limits.maxArtifactBytes ||
        audio.byteLength > limits.maxTotalArtifactBytes) {
      _unavailable('audio_quota');
    }
    final bytes = await files.read(audio.fileId);
    cancellation?.check();
    if (bytes.length != audio.byteLength ||
        crypto.sha256.convert(bytes).toString() != audio.sha256!.value) {
      _unavailable('audio_changed');
    }
    final NativeArtifact artifact;
    try {
      artifact = NativeArtifact(
          bytes: bytes,
          mediaType: mediaType,
          expectedSha256: audio.sha256,
          limits: limits);
    } on NativeWriteException {
      _unavailable('audio_unsupported');
    }
    final identity = canonicalHashOf({
      'namespace': source.snapshot.logicalProjectNamespace.value,
      'fileId': audio.fileId.value,
      'sha256': audio.sha256!.value,
      'kind': switch (kind) {
        SourceEventAudioKind.sound => 'sceneSound',
        SourceEventAudioKind.music => 'sceneMusic',
        SourceEventAudioKind.musicEffect => 'sceneMusicEffect',
        SourceEventAudioKind.ambience => 'sceneAmbience',
      }
    }).value;
    final prefix = switch (kind) {
      SourceEventAudioKind.sound => 'source_se',
      SourceEventAudioKind.music => 'source_bgm',
      SourceEventAudioKind.musicEffect => 'source_me',
      SourceEventAudioKind.ambience => 'source_bgs',
    };
    final id = '${prefix}_$identity';
    final mediaId = '${prefix}_media_$identity';
    final mutation = NativeMutation(
        operationId: ConverterId(kind == SourceEventAudioKind.musicEffect
            ? 'source_me_import_$identity' : 'source_se_import_$identity'),
        actionId: 'scene.dialogue.audioMedia.import',
        sourceEntityIds: [audio.fileId],
        targetEntityIds: [ConverterId(id), ConverterId(mediaId)],
        parameters: {
          'artifactHandle': artifact.handle,
          'assetId': id,
          'mediaId': mediaId,
          'label': name,
          'logicalPath': 'assets/audio/$id.$extension',
          if (kind == SourceEventAudioKind.music || kind == SourceEventAudioKind.ambience) 'mediaKind': 'music',
          if (kind == SourceEventAudioKind.musicEffect) 'mediaKind': 'sound'
        },
        limits: limits);
    return SourceEventSoundBinding._(
        name: name,
        kind: kind,
        policy: policy,
        sourceSnapshotHash: source.snapshot.canonicalHash,
        audioFile: audio,
        mediaId: mediaId,
        artifact: artifact,
        mutation: mutation,
        evidence: _freeze({
          'sourceAudioFile': audio.toJson(),
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'sourceScriptsHash':
              source.interpretationProfile?.scriptsArchiveHash.value,
          'policy': policy.name,
          'sourceEngineGainQualified':
              policy == SourceEventSoundPolicy.sourceEngineGain,
          'fullSourceParity': false,
          if (kind == SourceEventAudioKind.musicEffect) ...{
            'playbackRole': 'musicEffect',
            'requiredRuntimeCommand': 'playMusicEffect',
            'sourceBgmVolumeRouting': true,
            'sourceMeBackendQualified': false,
            'nativePresentationAdaptation': 'aveluneMusicEffectPauseAndResume',
            'sourceInvocationCompletion': 'started',
          },
          'nativeAuthoredVolumeAdaptation':
              policy == SourceEventSoundPolicy.nativeAuthoredVolume,
          if (engine != null) 'sourceEngineFile': engine.toJson(),
          if (config != null) 'sourceConfigurationFile': config.toJson(),
          if (ini != null) 'sourceGameIniFile': ini.toJson(),
          'requiredRuntimeContext':
              policy == SourceEventSoundPolicy.nativeAuthoredVolume
                  ? 'aveluneNativeAudio'
                  : 'freshGameDefaultOptions',
          if (policy == SourceEventSoundPolicy.sourceEngineGain) ...{
            if (kind == SourceEventAudioKind.sound) 'sourceOptionSeVolume': 60,
            if (kind == SourceEventAudioKind.music)
              'sourceOptionMusicVolume': 80,
            'sourceEngineGlobalGain': 0.8,
            'sourceRubyVolumeQuantization': kind == SourceEventAudioKind.music
                ? 'floor(authoredVolume*80/100)'
                : 'floor(authoredVolume*60/100)',
          },
          if (policy == SourceEventSoundPolicy.nativeAuthoredVolume)
            'nativeGain': 'authoredVolume/100',
          if (kind != SourceEventAudioKind.ambience) 'sourceRubyOracle': kind == SourceEventAudioKind.musicEffect
              ? {'dispatch': '034:1043-1045', 'play': '093:102-118',
                 'volume': '040:155-167'}
              : kind == SourceEventAudioKind.music
              ? {'volume': '040:46-74', 'default': '307:20-30'}
              : {
                  'play': '093:202-217',
                  'volume': '040:239-245',
                  'default': '307:31'
                },
          if (kind != SourceEventAudioKind.musicEffect && kind != SourceEventAudioKind.ambience) 'sourceEngineOracle': {
            'commit': 'c9378cfaba06e0b299a1bfd4197f62da018693da',
            'gain': 'src/audio/al-util.h:239-241',
            'application': kind == SourceEventAudioKind.music
                ? 'src/audio/audiostream.cpp:249-256'
                : 'src/audio/soundemitter.cpp:116-169'
          },
          'sourceScriptsExecuted': 0,
          'usesDialogueFeedback': false,
          'sourceEngineBinaryExecuted': false,
          'upstreamBinaryByteEquivalenceQualified': false,
          'sourcePlaybackObserved': false,
          'sourceAdmission': false,
        }) as Map<String, Object?>);
  }
}

Never _unavailable(String reason) =>
    throw SourceEventSoundBindingUnavailable(reason);

Object? _freeze(Object? value) => switch (value) {
      Map<String, Object?>() => Map<String, Object?>.unmodifiable(
          value.map((key, item) => MapEntry(key, _freeze(item)))),
      List() => List<Object?>.unmodifiable(value.map(_freeze)),
      _ => value,
    };
