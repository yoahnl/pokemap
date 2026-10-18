import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'native_project_writer.dart';

enum SourceMapMusicPolicy { sourceEngineGain, nativeAuthoredVolume }

final class SourceMapMusicBindingUnavailable implements Exception {
  const SourceMapMusicBindingUnavailable(this.reason);
  final String reason;

  @override
  String toString() => 'SourceMapMusicBindingUnavailable($reason)';
}

final class SourceMapMusicBinding {
  SourceMapMusicBinding._({
    required this.sourceMapId,
    required this.policy,
    required this.sourceSnapshotHash,
    required this.normalizedSourceHash,
    required this.nativeVolume,
    required this.mapFile,
    required this.mapMusicPath,
    required this.audioFile,
    required List<NativeArtifact> artifacts,
    required List<NativeMutation> importMutations,
    required Map<String, Object?> evidence,
    required ConverterId namespace,
    required ConverterId sourceMapIdentity,
    required NativeWriteLimits limits,
  })  : artifacts = List.unmodifiable(artifacts),
        importMutations = List.unmodifiable(importMutations),
        evidence = _freeze(evidence) as Map<String, Object?>,
        _namespace = namespace,
        _sourceMapIdentity = sourceMapIdentity,
        _limits = limits;

  final int sourceMapId;
  final SourceMapMusicPolicy policy;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash normalizedSourceHash;
  final double nativeVolume;
  final SourceFileEntry mapFile;
  final SourceFileEntry audioFile;
  final String mapMusicPath;
  final List<NativeArtifact> artifacts;
  final List<NativeMutation> importMutations;
  final Map<String, Object?> evidence;
  final ConverterId _namespace;
  final ConverterId _sourceMapIdentity;
  final NativeWriteLimits _limits;

  NativeMutation mapMutation({required String nativeMapId}) {
    final target = ConverterId(nativeMapId);
    final identity = canonicalHashOf({
      'namespace': _namespace.value,
      'sourceMapId': sourceMapId,
      'sourceMapHash': mapFile.sha256!.value,
      'nativeMapId': nativeMapId,
      'musicPath': mapMusicPath,
      'musicVolume': nativeVolume,
    }, limits: _limits.jsonLimits);
    return NativeMutation(
      operationId: ConverterId('source_map_music_assign_${identity.value}'),
      actionId: 'map.audio.update',
      sourceEntityIds: [_sourceMapIdentity, mapFile.fileId, audioFile.fileId],
      targetEntityIds: [target],
      parameters: {
        'mapId': nativeMapId,
        'musicPath': mapMusicPath,
        'musicVolume': nativeVolume,
      },
      limits: _limits,
    );
  }
}

final class SourceMapMusicResolver {
  const SourceMapMusicResolver();

  Future<SourceMapMusicBinding?> read({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    required int sourceMapId,
    SourceMapMusicPolicy policy = SourceMapMusicPolicy.sourceEngineGain,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    final cancel = cancellation ?? ScanCancellation();
    cancel.check();
    limits.validate();
    final snapshot = source.snapshot;
    if (snapshot.state != SourceScanState.complete) {
      _unavailable('snapshot_incomplete');
    }
    final maps =
        source.maps.where((map) => map.map.sourceMapId == sourceMapId).toList();
    if (maps.length != 1) _unavailable('map_missing');
    final archived = source.archive.files[maps.single.map.sourceFileId];
    if (archived == null ||
        !snapshot.entries.any((entry) =>
            entry.fileId == archived.fileId &&
            entry.relativePath == archived.entry.relativePath &&
            entry.byteLength == archived.entry.byteLength &&
            entry.sha256 == archived.contentHash &&
            entry.kind == SourceNodeKind.file)) {
      _unavailable('map_unattested');
    }
    var readBytes = 0;
    Future<Uint8List> read(SourceFileEntry entry) async {
      cancel.check();
      if (entry.byteLength > limits.maxArtifactBytes ||
          entry.byteLength > limits.maxTotalArtifactBytes - readBytes) {
        _quota();
      }
      readBytes += entry.byteLength;
      final bytes = await files.read(entry.fileId);
      cancel.check();
      if (bytes.length != entry.byteLength ||
          bytes.any((value) => value < 0 || value > 255) ||
          crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
        throw ContractError(
            'source.map_music.source_changed',
            entry.relativePath,
            'Music source bytes differ from the exact admitted snapshot.');
      }
      return Uint8List.fromList(bytes).asUnmodifiableView();
    }

    SourceFileEntry entry(String path, String reason) {
      final matches = snapshot.entries
          .where((candidate) =>
              sourcePathCollisionKey(candidate.relativePath) ==
              sourcePathCollisionKey(path))
          .toList();
      if (matches.length != 1 ||
          matches.single.relativePath != path ||
          matches.single.kind != SourceNodeKind.file ||
          matches.single.sha256 == null) {
        _unavailable(reason);
      }
      return matches.single;
    }

    final mapFile = entry(archived.entry.relativePath, 'map_unattested');
    await read(mapFile);
    final document = archived.document;
    final fields =
        _fields(document, document.rootId, 'RPG::Map', 'map_unqualified');
    final autoplayId = fields['@autoplay_bgm'];
    if (autoplayId == null ||
        document.node(autoplayId).kind != MarshalKind.boolean) {
      _unavailable('autoplay_unqualified');
    }
    if (document.node(autoplayId).booleanValue == false) return null;
    if (limits.maxArtifacts < 1 || limits.maxMutations < 2) _quota();
    final scripts = entry('Data/Scripts.rxdata', 'profile_unqualified');
    if (scripts.sha256!.value != source.interpretationProfile?.scriptsArchiveHash.value ||
        !SourceEventProfile.forProject(source).isQualified) {
      _unavailable('profile_unqualified');
    }
    await read(scripts);
    SourceFileEntry? engine, configuration, gameIni;
    if (policy == SourceMapMusicPolicy.sourceEngineGain) {
      engine = entry('Game.exe', 'engine_unqualified');
      if (engine.byteLength != 14732288 ||
          engine.sha256!.value != _engineHash) {
        _unavailable('engine_unqualified');
      }
      configuration = entry('mkxp.json', 'configuration_unqualified');
      gameIni = entry('Game.ini', 'configuration_unqualified');
      if (configuration.byteLength != 6212 ||
          configuration.sha256!.value != _configurationHash ||
          gameIni.byteLength != 121 ||
          gameIni.sha256!.value != _gameIniHash) {
        _unavailable('configuration_unqualified');
      }
      await read(configuration);
      await read(gameIni);
    }

    final musicId = fields['@bgm'];
    if (musicId == null) _unavailable('music_unqualified');
    final music =
        _fields(document, musicId, 'RPG::AudioFile', 'music_unqualified');
    if (music.length != 3 ||
        !music.keys.toSet().containsAll({'@name', '@volume', '@pitch'})) {
      _unavailable('music_unqualified');
    }
    final nameId = music['@name']!;
    final nameNode = document.node(nameId);
    final name =
        nameNode.kind == MarshalKind.string ? nameNode.text().text : null;
    if (name == null ||
        name.isEmpty ||
        name.length > 512 ||
        name.trim() != name ||
        name == '.' ||
        name == '..' ||
        RegExp(r'[\\/:<>\x00-\x1f]').hasMatch(name)) {
      _unavailable('name_unqualified');
    }
    final volume = _integer(document, music['@volume']);
    final pitch = _integer(document, music['@pitch']);
    if (volume == null) _unavailable('volume_unqualified');
    if (pitch == null) _unavailable('pitch_unqualified');
    if (volume > 100 ||
        (policy == SourceMapMusicPolicy.sourceEngineGain && volume != 100)) {
      _unavailable('volume_unsupported');
    }
    if (pitch != 100) _unavailable('pitch_unsupported');
    final base = 'Audio/BGM/$name';
    final baseKey = sourcePathCollisionKey(base);
    bool matches(String path, String key) {
      final candidate = sourcePathCollisionKey(path);
      if (candidate == key) return true;
      if (!candidate.startsWith('$key.')) return false;
      return !candidate.substring(key.length + 1).contains('/');
    }

    if (snapshot.entries
        .any((value) => matches(value.relativePath, '${baseKey}_n'))) {
      _unavailable('night_variant_unsupported');
    }
    final audioMatches = snapshot.entries
        .where((value) => matches(value.relativePath, baseKey))
        .toList();
    if (audioMatches.isEmpty) _unavailable('audio_missing');
    if (audioMatches.length != 1) _unavailable('audio_ambiguous');
    final audio = audioMatches.single;
    if (audio.relativePath.length <= base.length + 1) {
      _unavailable('audio_unsupported');
    }
    final extension = audio.relativePath.substring(base.length + 1);
    final mediaType = _audioTypes[extension];
    if (mediaType == null || audio.relativePath != '$base.$extension') {
      _unavailable('audio_unsupported');
    }
    final audioFile = entry(audio.relativePath, 'audio_unattested');
    final bytes = await read(audioFile);
    late NativeArtifact artifact;
    try {
      artifact = NativeArtifact(
          bytes: bytes,
          mediaType: mediaType,
          expectedSha256: audioFile.sha256,
          limits: limits);
    } on NativeWriteException catch (error) {
      if (error.code == 'native.artifact.audio') {
        _unavailable('audio_unsupported');
      }
      rethrow;
    }
    cancel.check();
    final identity = canonicalHashOf({
      'namespace': snapshot.logicalProjectNamespace.value,
      'domain': 'source-map-music',
      'sourceFileId': audioFile.fileId.value,
      'sourceFileHash': audioFile.sha256!.value,
    }, limits: limits.jsonLimits);
    final assetId = 'source_music_${identity.value}';
    final logicalPath = 'assets/audio/$assetId.$extension';
    final import = NativeMutation(
      operationId: ConverterId('source_map_music_import_${identity.value}'),
      actionId: 'asset.import',
      sourceEntityIds: [audioFile.fileId],
      targetEntityIds: [ConverterId(assetId)],
      parameters: {
        'artifactHandle': artifact.handle,
        'assetId': assetId,
        'logicalPath': logicalPath,
        'tags': ['source-map-music'],
        'usages': ['mapMusic'],
      },
      limits: limits,
    );
    return SourceMapMusicBinding._(
      sourceMapId: sourceMapId,
      policy: policy,
      sourceSnapshotHash: snapshot.canonicalHash,
      normalizedSourceHash: source.canonicalHash,
      nativeVolume: policy == SourceMapMusicPolicy.nativeAuthoredVolume
          ? volume / 100
          : 0.64,
      mapFile: mapFile,
      audioFile: audioFile,
      mapMusicPath: logicalPath,
      artifacts: [artifact],
      importMutations: [import],
      namespace: snapshot.logicalProjectNamespace,
      sourceMapIdentity: source.mapIdentity(sourceMapId),
      limits: limits,
      evidence: {
        'kind': 'sourceMapMusicBinding',
        'version': 1,
        'profile': policy == SourceMapMusicPolicy.nativeAuthoredVolume
            ? 'source-native-authored-audio-v1'
            : 'source-mkxp-z-2.4.2-c9378cf-static-audio-v1',
        'policy': policy.name,
        'sourceEngineGainQualified':
            policy == SourceMapMusicPolicy.sourceEngineGain,
        'fullSourceParity': false,
        'sourceSnapshotHash': snapshot.canonicalHash.value,
        'normalizedSourceHash': source.canonicalHash.value,
        'sourceMapId': sourceMapId,
        'sourceMapFile': mapFile.toJson(),
        'sourceAudioFile': audioFile.toJson(),
        if (engine != null) 'sourceEngineFile': engine.toJson(),
        if (configuration != null)
          'sourceConfigurationFile': configuration.toJson(),
        if (gameIni != null) 'sourceGameIniFile': gameIni.toJson(),
        'sourceScriptsFile': scripts.toJson(),
        'sourceAutoplayBgm': true,
        'sourceName': name,
        'sourceVolume': volume,
        'sourcePitch': pitch,
        if (policy == SourceMapMusicPolicy.sourceEngineGain) ...{
          'sourceFreshOptionsMusicVolume': 80,
          'sourceRubyAudioGain': 0.8,
          'sourceEngineGlobalGain': 0.8,
        },
        'nativeAudioGain': policy == SourceMapMusicPolicy.nativeAuthoredVolume
            ? volume / 100
            : 0.64,
        if (policy == SourceMapMusicPolicy.nativeAuthoredVolume)
          'nativeGain': 'authoredVolume/100',
        'requiredRuntimeContext':
            policy == SourceMapMusicPolicy.nativeAuthoredVolume
                ? 'aveluneNativeAudio'
                : 'freshGameDefaultOptions',
        'sourceSessionBgmInheritanceQualified': false,
        'sourceNightVariant': 'absentInCompleteSnapshot',
        'sourceEngineIdentityAttestation':
            policy == SourceMapMusicPolicy.nativeAuthoredVolume
                ? 'notRequiredForNativeAudioAdaptation'
                : 'sealedSnapshotSha256AndByteLength',
        'sourceEngineBinaryBytesReinspected': false,
        'sourceEngineBinaryRetained': false,
        'sourceEngineBinaryExecuted': false,
        'upstreamBinaryByteEquivalenceQualified': false,
        'sourceAudioPlaybackObserved': false,
        'sourceAudioPauseResumeQualified': false,
        'nativeMusicPlaybackQualified': false,
        'sourceLoopPlaybackParityQualified': false,
        'battleAuthority': 'aveluneNative',
        'sourceBattleScriptsExecuted': false,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'sourceAudioBytesChanged': false,
        'importBeforeMaps': true,
        'mapMutationAfterMapSave': true,
        'sourceOracle': {
          'scriptsArchiveHash': source.interpretationProfile?.scriptsArchiveHash.value,
          'settings': {
            'section': 0,
            'sha256':
                'cc412c0b86e5ebbc121a91ca5efc2d7d6c7b398469cb0c7cd5be1b770531b06f',
            'lines': [869, 871]
          },
          'freshOptions': {
            'section': 307,
            'sha256':
                '3368adf8185258005fc0ee11bf97aeb4e54597b96404365bac5ef79a500dcfb3',
            'lines': [20, 30]
          },
          'gameSystem': {
            'section': 40,
            'sha256':
                '38574a92d37fad43446237e6f429863507a46b9c7c4e7806a7251ee71a307bdb',
            'lines': [46, 74]
          },
          'gameMap': {
            'section': 42,
            'sha256':
                '2e31060a4dc0ac036fecc510735f8a70f8cb8c7f33291b572e489e89c4f5b7f9',
            'lines': [113, 131]
          },
          'upstreamCommit': 'c9378cfaba06e0b299a1bfd4197f62da018693da',
          'engineGain': {
            'path': 'src/audio/al-util.h',
            'sha256':
                '12797ca38dbb7552a6f15b04f268f78e9cab1368b30536488338e3f7a7f3cba8',
            'lines': [239, 241]
          },
          'engineGainApplication': {
            'path': 'src/audio/audiostream.cpp',
            'sha256':
                '483d66023a5f30618d6655c8338ecdca79af29c3d99ec51d66400e4920a80848',
            'lines': [249, 256]
          },
        },
        'artifact': {
          'handle': artifact.handle,
          'rawSha256': artifact.rawSha256.value,
          'byteLength': artifact.bytes.length,
          'mediaType': artifact.reference.mediaType,
        },
        'importOperationIds': [import.operationId.value],
      },
    );
  }
}

const _engineHash =
    '5c75e92fcbb6ec50b9f8fc61913d751a8945d6a1fc69c3017c7b8686b532bf04';
const _configurationHash =
    '90a3aee82895e48e6c767f973b637d27856cccfd575f48b78d04191cb3e7d35f';
const _gameIniHash =
    '5ca2b3b37b92767097a5db5a126c6c50cc6fc2602d3fa9776f06883838aba5f6';
const _audioTypes = {
  'wav': 'audio/wav',
  'ogg': 'audio/ogg',
  'mp3': 'audio/mpeg',
  'flac': 'audio/flac'
};

Never _unavailable(String reason) =>
    throw SourceMapMusicBindingUnavailable('map.music.$reason');
Never _quota() => throw ContractError('source.map_music.quota', r'$',
    'Music source reads and native output exceed the caller byte or operation budget.');

Map<String, int> _fields(
    MarshalDocument document, int id, String className, String reason) {
  final node = document.node(id);
  if (node.kind != MarshalKind.object || node.className != className) {
    _unavailable(reason);
  }
  if (node.instanceVariables.length > 128) _quota();
  final result = <String, int>{};
  for (final pair in node.instanceVariables) {
    final key = document.node(pair.key);
    if (key.kind != MarshalKind.symbol ||
        key.name == null ||
        result.containsKey(key.name)) {
      _unavailable(reason);
    }
    result[key.name!] = pair.value;
  }
  return result;
}

int? _integer(MarshalDocument document, int? id) {
  if (id == null) return null;
  final node = document.node(id), value = document.node(id).integerValue;
  if (node.kind != MarshalKind.integer ||
      value == null ||
      value < BigInt.zero ||
      value > BigInt.from(2147483647)) {
    return null;
  }
  return value.toInt();
}

Object? _freeze(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable(
        value.map((key, entry) => MapEntry(key as String, _freeze(entry))));
  }
  if (value is List) return List<Object?>.unmodifiable(value.map(_freeze));
  return value;
}
