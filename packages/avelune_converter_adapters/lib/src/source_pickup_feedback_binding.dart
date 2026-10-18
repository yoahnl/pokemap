import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'source_event_item_bindings.dart';
import 'source_map_music_binding.dart';

final class SourcePickupBindingUnavailable implements Exception {
  const SourcePickupBindingUnavailable(this.reason);
  final String reason;
  @override
  String toString() => 'SourcePickupBindingUnavailable($reason)';
}

final class SourcePickupFeedbackBinding {
  SourcePickupFeedbackBinding._({
    required this.item,
    required this.helper,
    required this.sourceMapId,
    required this.sourceSnapshotHash,
    required this.iconTilesetId,
    required this.mediaId,
    required this.metadataFile,
    required this.iconFile,
    required this.windowskinFile,
    required this.audioFile,
    required this.metadataReference,
    required this.metadataArchive,
    required this.bagFeedback,
    required this.bagFullFoundFeedback,
    required this.bagFullFeedback,
    required this.music,
    required this.omittedSourceBgmPath,
    required List<DialogueLineSegment> foundSegments,
    required List<NativeArtifact> artifacts,
    required List<NativeMutation> mutations,
    required Map<String, Object?> evidence,
  })  : _foundSegments = List.unmodifiable(foundSegments),
        artifacts = List.unmodifiable(artifacts),
        mutations = List.unmodifiable(mutations),
        evidence = _freeze(evidence) as Map<String, Object?>;

  final SourceEventItemBinding item;
  final SourceItemGrantHelper helper;
  final int sourceMapId;
  final Sha256Hash sourceSnapshotHash;
  final String iconTilesetId;
  final String mediaId;
  final SourceFileEntry metadataFile;
  final SourceFileEntry iconFile;
  final SourceFileEntry windowskinFile;
  final SourceFileEntry audioFile;
  final SourcePreservedData metadataReference;
  final SourceArchive metadataArchive;
  final DialogueLineFeedback bagFeedback;
  final DialogueLineFeedback bagFullFoundFeedback;
  final DialogueLineFeedback bagFullFeedback;
  final SourceMapMusicBinding? music;
  final String? omittedSourceBgmPath;
  final List<DialogueLineSegment> _foundSegments;
  final List<NativeArtifact> artifacts;
  final List<NativeMutation> mutations;
  final Map<String, Object?> evidence;

  double get nativeAudioGain => omittedSourceBgmPath != null ||
          music?.policy == SourceMapMusicPolicy.nativeAuthoredVolume
      ? 1
      : music?.nativeVolume ?? 0.8;

  DialogueLineFeedback foundFeedback({required String cueId}) =>
      DialogueLineFeedback(
        segments: _foundSegments,
        revealIntervalMicros: 25000,
        advance: DialogueLineAdvancePolicy.autoAfterReveal(
            item.isMachine ? 3500000 : 2000000),
        audioCue: DialogueAudioCue(
          mediaAssetId: mediaId,
          cueId: cueId,
          volume: nativeAudioGain,
          role: music == null
              ? DialogueAudioCueRole.effect
              : DialogueAudioCueRole.musicEffect,
          bgmInterruption: music == null
              ? null
              : DialogueBgmInterruption(fadeOutMs: 200, fadeInMs: 1000),
        ),
      );
}

final class SourcePickupFeedbackResolver {
  const SourcePickupFeedbackResolver();

  Future<SourcePickupFeedbackBinding> read({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    required SourceEventItemBinding item,
    required int sourceMapId,
    SourceItemGrantHelper helper = SourceItemGrantHelper.itemBall,
    SourceMapMusicBinding? music,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    final cancel = cancellation ?? ScanCancellation();
    cancel.check();
    limits.validate();
    final snapshot = source.snapshot;
    if (snapshot.state != SourceScanState.complete ||
        item.sourceSnapshotHash != snapshot.canonicalHash) {
      throw ContractError('source.pickup_feedback.item_binding', r'$',
          'Pickup feedback requires an item from the exact complete source snapshot.');
    }
    final profile = SourceEventProfile.forProject(source);
    if (!profile.isQualified) _unavailable('profile_unqualified');
    if (!item.pickupQualified ||
        (item.isKeyItem &&
            (helper != SourceItemGrantHelper.receiveItem ||
                item.sourcePocketIndex != 8)) ||
        (item.isMachine && item.sourcePocketIndex != 4) ||
        item.sourceSymbol == 'DNASPLICERS') {
      _unavailable('item_unsupported');
    }
    if (RegExp(r'[\\<>\x00-\x1f]').hasMatch(item.portionName)) {
      _unavailable('item_name_controls');
    }
    final machineMove = item.sourceMachineMove;
    if (item.isMachine &&
        (machineMove == null ||
            machineMove.sourceSymbol != item.moveSymbol ||
            machineMove.sourceSnapshotHash != snapshot.canonicalHash ||
            !snapshot.entries.any((entry) =>
                entry.fileId == machineMove.file.fileId &&
                entry.relativePath == machineMove.file.relativePath &&
                entry.sha256 == machineMove.file.sha256 &&
                entry.byteLength == machineMove.file.byteLength))) {
      _unavailable('machine_move_unqualified');
    }
    if (limits.maxArtifacts < 2 || limits.maxMutations < 2) _quota();
    final maps =
        source.maps.where((map) => map.map.sourceMapId == sourceMapId).toList();
    if (maps.length != 1) _unavailable('map_missing');
    final map = maps.single;
    final mapFile = source.archive.files[map.map.sourceFileId];
    if (mapFile == null ||
        mapFile.contentHash != mapFile.entry.sha256 ||
        !snapshot.entries.any((entry) =>
            entry.fileId == mapFile.entry.fileId &&
            entry.sha256 == mapFile.contentHash)) {
      throw ContractError('source.pickup_feedback.map_binding', r'$',
          'The source map must retain its attested original graph.');
    }
    final mapFields = _fields(mapFile.document, mapFile.document.rootId,
        'RPG::Map', 'bgm_unqualified');
    final autoplayId = mapFields['@autoplay_bgm'];
    if (autoplayId == null) _unavailable('bgm_unqualified');
    final autoplay = mapFile.document.node(autoplayId);
    if (autoplay.kind != MarshalKind.boolean) _unavailable('bgm_unqualified');
    String? omittedSourceBgmPath;
    if (autoplay.booleanValue == true && music == null) {
      if (helper != SourceItemGrantHelper.receiveItem) {
        _unavailable('bgm_active');
      }
      omittedSourceBgmPath =
          _absentSourceBgmPath(source, mapFile.document, mapFields['@bgm']);
      if (omittedSourceBgmPath == null) _unavailable('bgm_active');
    }
    if (music != null &&
        (autoplay.booleanValue != true ||
            music.sourceMapId != sourceMapId ||
            music.sourceSnapshotHash != snapshot.canonicalHash ||
            music.normalizedSourceHash != source.canonicalHash ||
            music.mapFile.fileId != mapFile.entry.fileId ||
            music.mapFile.sha256 != mapFile.contentHash)) {
      throw ContractError('source.pickup_feedback.music_binding', r'$',
          'Pickup music must bind the exact normalized source map and snapshot.');
    }

    SourceFileEntry entry(String path, String family) {
      final matches = snapshot.entries
          .where((value) =>
              sourcePathCollisionKey(value.relativePath) ==
              sourcePathCollisionKey(path))
          .toList();
      if (matches.length != 1 || matches.single.relativePath != path) {
        _unavailable('${family}_missing');
      }
      final result = matches.single;
      if (result.kind != SourceNodeKind.file || result.sha256 == null) {
        _unavailable('${family}_unattested');
      }
      return result;
    }

    var readBytes = 0;
    Future<Uint8List> read(SourceFileEntry entry, int maximum) async {
      cancel.check();
      if (entry.byteLength > maximum ||
          entry.byteLength > limits.maxArtifactBytes ||
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
            'source.pickup_feedback.source_changed',
            entry.relativePath,
            'Pickup source bytes differ from the attested snapshot.');
      }
      return Uint8List.fromList(bytes).asUnmodifiableView();
    }

    final metadataFile = entry('Data/map_metadata.dat', 'metadata');
    final metadataBytes = await read(metadataFile, 4194304);
    final metadataArchive = SourceArchive(
        limits: const SourceArchiveLimits(
            maxFiles: 1,
            maxFileBytes: 4194304,
            maxTotalBytes: 4194304,
            maxTotalNodes: 100000,
            maxTotalEntries: 400000,
            maxReferences: 1));
    late SourceArchivedFile archived;
    try {
      archived = metadataArchive.add(metadataFile, metadataBytes);
    } on BinaryDecodeError catch (error) {
      if (error.code.startsWith('marshal.quota.')) _quota();
      _unavailable('metadata_invalid');
    }
    final document = archived.document;
    final root = document.node(document.rootId);
    if (root.kind != MarshalKind.hash) {
      _unavailable('metadata_invalid');
    }
    if (root.pairs.length > 4096) _quota();
    final matches = root.pairs
        .where((pair) =>
            document.node(pair.key).kind == MarshalKind.integer &&
            document.node(pair.key).integerValue == BigInt.from(sourceMapId))
        .toList();
    if (matches.length != 1) _unavailable('metadata_missing');
    final metadataNodeId = matches.single.value;
    final fields = _fields(
        document, metadataNodeId, 'GameData::MapMetadata', 'metadata_invalid');
    if (_integer(document, fields['@id']) != sourceMapId) {
      _unavailable('metadata_invalid');
    }
    final positionId = fields['@town_map_position'];
    if (positionId == null) _unavailable('metadata_invalid');
    final position = document.node(positionId);
    if (position.kind != MarshalKind.array ||
        position.elements.length != 3 ||
        position.elements.any((id) => _integer(document, id) == null)) {
      _unavailable('metadata_invalid');
    }
    final region = _integer(document, position.elements.first)!;
    if (region != 1) _unavailable('region_unsupported');
    final metadataReference = metadataArchive.reference(
        fileId: metadataFile.fileId, nodeId: metadataNodeId);
    metadataArchive.seal();

    final iconFile =
        entry('Graphics/Icons/bagPocket${item.sourcePocketIndex}.png', 'icon');
    final skinFile = entry('Graphics/Windowskins/speech hgss 1.png', 'skin');
    final audioBase = item.isKeyItem
        ? 'Audio/ME/FRLG Fanfare - Item Key (Fanfare! Key Item)'
        : item.isMachine
            ? 'Audio/ME/FRLG Fanfare - Item Machine (Fanfare! Item Obtained (Version 2))'
            : 'Audio/ME/FRLG Fanfare - Item (Fanfare Item Get 1)';
    const mediaTypes = {
      'ogg': 'audio/ogg',
      'wav': 'audio/wav',
      'mp3': 'audio/mpeg',
      'flac': 'audio/flac'
    };
    final audioMatches = <(SourceFileEntry, String, String)>[];
    for (final ext in mediaTypes.entries) {
      final path = '$audioBase.${ext.key}';
      final candidates = snapshot.entries
          .where((value) =>
              sourcePathCollisionKey(value.relativePath) ==
              sourcePathCollisionKey(path))
          .toList();
      if (candidates.length > 1 ||
          (candidates.isNotEmpty && candidates.single.relativePath != path)) {
        _unavailable('audio_ambiguous');
      }
      if (candidates.isNotEmpty) {
        audioMatches.add((entry(path, 'audio'), ext.key, ext.value));
      }
    }
    if (audioMatches.isEmpty) _unavailable('audio_missing');
    if (audioMatches.length != 1) _unavailable('audio_ambiguous');
    final (audioFile, audioExtension, audioMediaType) = audioMatches.single;
    final iconBytes = await read(iconFile, 1048576);
    final skinBytes = await read(skinFile, 1048576);
    final audioBytes = await read(audioFile, 16777216);
    final icon = _png(iconBytes, limits, 'icon');
    final skin = _png(skinBytes, limits, 'skin');
    if (icon.width > 256 || icon.height > 256) _unavailable('icon_unsupported');
    if (skin.width != 96 || skin.height != 48) _unavailable('skin_unsupported');
    final isDark = _isDarkSkin(skin);
    final standard = DialogueSegmentStyle(
        colorArgb: isDark ? 0xfff8f8f8 : 0xff505058,
        shadowColorArgb: isDark ? 0xff485058 : 0xffa0a0a8);
    final highlighted = DialogueSegmentStyle(
        colorArgb: isDark ? 0xff78b8e8 : 0xff0070f8,
        shadowColorArgb: isDark ? 0xff0070f8 : 0xff78b8e8);
    final iconArtifact = NativeArtifact(
        bytes: iconBytes, expectedSha256: iconFile.sha256, limits: limits);
    late NativeArtifact audioArtifact;
    try {
      audioArtifact = NativeArtifact(
          bytes: audioBytes,
          mediaType: audioMediaType,
          expectedSha256: audioFile.sha256,
          limits: limits);
    } on NativeWriteException catch (error) {
      if (error.code == 'native.artifact.audio') _unavailable('audio_invalid');
      rethrow;
    }
    if (iconArtifact.bytes.length + audioArtifact.bytes.length >
        limits.maxTotalArtifactBytes) {
      _quota();
    }
    String key(String kind, SourceFileEntry file) => canonicalHashOf({
          'kind': kind,
          'namespace': snapshot.logicalProjectNamespace.value,
          'sourceFileId': file.fileId.value,
          'sourcePath': file.relativePath,
          'sourceHash': file.sha256!.value,
        }).value.substring(0, 24);
    final iconKey = key('pickupIcon', iconFile),
        audioKey = key('pickupAudio', audioFile);
    final iconTilesetId = 'source_pickup_icon_$iconKey';
    final iconAssetId = 'image_$iconTilesetId';
    final mediaId = 'source-pickup-me-$audioKey';
    final audioAssetId = 'source-pickup-audio-$audioKey';
    final logicalAudioPath =
        'assets/dialogue_audio/source_pickup_$audioKey.$audioExtension';
    final mutations = [
      NativeMutation(
          operationId: ConverterId('source-pickup-icon-$iconKey'),
          actionId: 'tileset.import_image',
          sourceEntityIds: [iconFile.fileId],
          targetEntityIds: [
            ConverterId(iconTilesetId),
            ConverterId(iconAssetId)
          ],
          parameters: {
            'artifactHandle': iconArtifact.handle,
            'tilesetId': iconTilesetId,
            'name': 'Source bag pocket ${item.sourcePocketIndex}',
            'tileWidth': 1,
            'tileHeight': 1
          },
          limits: limits),
      NativeMutation(
          operationId: ConverterId('source-pickup-audio-$audioKey'),
          actionId: 'scene.dialogue.audioMedia.import',
          sourceEntityIds: [audioFile.fileId],
          targetEntityIds: [ConverterId(audioAssetId), ConverterId(mediaId)],
          parameters: {
            'artifactHandle': audioArtifact.handle,
            'assetId': audioAssetId,
            'mediaId': mediaId,
            'label': item.isKeyItem
                ? 'FRLG key item obtained'
                : item.isMachine
                    ? 'FRLG machine found'
                    : 'FRLG item found',
            'logicalPath': logicalAudioPath
          },
          limits: limits),
    ];
    final name = item.portionName;
    final article = const {'a', 'e', 'i', 'o', 'u'}
            .contains(name.substring(0, 1).toLowerCase())
        ? 'an'
        : 'a';
    final verb =
        helper == SourceItemGrantHelper.receiveItem ? 'obtained' : 'found';
    final foundSegments = [
      DialogueTextSegment(item.isMachine ? 'You $verb ' : 'You $verb $article ',
          style: standard),
      DialogueTextSegment(item.isMachine ? '$name ${machineMove!.name}' : name,
          style: highlighted),
      DialogueTextSegment('!', style: standard)
    ];
    final bag = DialogueLineFeedback(segments: [
      DialogueTextSegment("You put the $name in\nyour Bag's ", style: standard),
      DialogueIconSegment(
          assetId: iconTilesetId, widthPx: icon.width, heightPx: icon.height),
      DialogueTextSegment(_pocketNames[item.sourcePocketIndex - 1],
          style: highlighted),
      DialogueTextSegment(' pocket.', style: standard),
    ], revealIntervalMicros: 25000);
    final bagFullFound = DialogueLineFeedback(
        segments: foundSegments, revealIntervalMicros: 25000);
    final bagFull = DialogueLineFeedback(segments: [
      DialogueTextSegment('But your Bag is full...', style: standard)
    ], revealIntervalMicros: 25000);
    return SourcePickupFeedbackBinding._(
        item: item,
        helper: helper,
        sourceMapId: sourceMapId,
        sourceSnapshotHash: snapshot.canonicalHash,
        iconTilesetId: iconTilesetId,
        mediaId: mediaId,
        metadataFile: metadataFile,
        iconFile: iconFile,
        windowskinFile: skinFile,
        audioFile: audioFile,
        metadataReference: metadataReference,
        metadataArchive: metadataArchive,
        bagFeedback: bag,
        bagFullFoundFeedback: bagFullFound,
        bagFullFeedback: bagFull,
        music: music,
        omittedSourceBgmPath: omittedSourceBgmPath,
        foundSegments: foundSegments,
        artifacts: [iconArtifact, audioArtifact],
        mutations: mutations,
        evidence: {
          'kind': 'sourcePickupFeedbackBinding',
          'version': 1,
          'sourceSnapshotHash': snapshot.canonicalHash.value,
          'normalizationHash': source.canonicalHash.value,
          'eventProfile': profile.toJson(),
          'sourceMapId': sourceMapId,
          'sourceSymbol': item.sourceSymbol,
          'sourceHelper': helper.name,
          'sourceReturnValueUsed': helper == SourceItemGrantHelper.itemBall,
          'sourceGrantOrder': helper == SourceItemGrantHelper.receiveItem
              ? ['obtainedFeedback', 'bagAdd', 'bagFeedbackOnSuccess']
              : ['bagAdd', 'foundFeedbackOnSuccess', 'bagFeedbackOnSuccess'],
          'sourceFailureFeedback': helper == SourceItemGrantHelper.receiveItem
              ? 'noneAfterObtainedFeedback'
              : 'foundThenBagFull',
          'itemReference': item.itemReference.toJson(),
          if (item.isMachine) 'sourceMachineMove': machineMove!.toJson(),
          if (item.isMachine) 'nativeProjectMoveMachine': null,
          if (item.isMachine) 'fullMachineUseParityQualified': false,
          'metadataFile': metadataFile.toJson(),
          'metadataReference': metadataReference.toJson(),
          'metadataArchiveHash': metadataArchive.canonicalHash.value,
          'sourceMapFile': mapFile.entry.toJson(),
          'iconFile': iconFile.toJson(),
          'windowskinFile': skinFile.toJson(),
          'audioFile': audioFile.toJson(),
          'sourceRegion': region,
          'sourceQuantity': 1,
          'requiredRuntimeContext': omittedSourceBgmPath != null
              ? 'aveluneNativeWithoutMissingSourceMapBgm'
              : music == null
                  ? 'freshGameDefaultOptionsAndNoActiveBgm'
                  : 'freshGameDefaultOptionsAndQualifiedMapBgm',
          'sourceBgmAutoplay': autoplay.booleanValue,
          'nativeMapBgmImported': music != null,
          if (omittedSourceBgmPath != null) ...{
            'sourceBgmOmission': {
              'sourcePathBase': omittedSourceBgmPath,
              'reason': 'physicallyAbsentFromCompleteSourceSnapshot',
              'nativePolicy': 'omitMapBgmAndPlayExistingItemFeedbackOnly',
              'resumeAbsentTrack': false,
              'fullSourceParity': false,
            },
            'diagnostics': [
              {
                'code': 'source.item_giver.missing_bgm_omitted',
                'message':
                    'Map $sourceMapId omits missing source background music $omittedSourceBgmPath; item gifts use native Avelune feedback.',
                'locator': {
                  'file': mapFile.entry.relativePath,
                  'mapId': sourceMapId
                },
                'blocksPlanning': false,
              }
            ],
          },
          if (music != null) 'mapMusicBinding': music.evidence,
          'sourceSessionBgmInheritanceQualified': false,
          'sourceOptions': {
            'textSpeed': 1,
            'textSkin': 0,
            'language': 0,
            'bgmVolume': 80
          },
          'activeTranslations': 'none_LANGUAGES_empty',
          'sourceSkin': {
            'width': skin.width,
            'height': skin.height,
            'isDark': isDark,
            'sampleRectangle': {'x': 32, 'y': 16, 'width': 16, 'height': 16},
            'policy': 'nontransparentSampleAverageLumaBelow160'
          },
          'defaultStyle': standard.toJson(),
          'highlightStyle': highlighted.toJson(),
          'foundText': foundSegments.map((segment) => segment.plainText).join(),
          'bagFeedback': bag.toJson(),
          'bagFullFoundFeedback': bagFullFound.toJson(),
          'bagFullFeedback': bagFull.toJson(),
          'revealIntervalMicros': 25000,
          'foundAutoAfterRevealMicros': item.isMachine ? 3500000 : 2000000,
          'sourceAudioGain': 0.8,
          'nativeAudioGain': omittedSourceBgmPath != null ||
                  music?.policy == SourceMapMusicPolicy.nativeAuthoredVolume
              ? 1.0
              : music?.nativeVolume ?? 0.8,
          'nativeAudioRole': music == null ? 'effect' : 'musicEffect',
          if (music != null)
            'nativeBgmInterruption': {'fadeOutMs': 200, 'fadeInMs': 1000},
          'sourceEngineAudioGainQualified': music != null &&
              music.policy == SourceMapMusicPolicy.sourceEngineGain,
          'sourceIconSize': {'width': icon.width, 'height': icon.height},
          'sourcePixelsResampled': false,
          'iconTilesetId': iconTilesetId,
          'mediaId': mediaId,
          'sourceAudioPauseResumeQualified': false,
          'sourceFramebufferParityQualified': false,
          'sourceScriptsExecuted': 0,
          'aiCalls': 0,
          'sourceOracleWitnessRequired': true,
          'operationIds':
              mutations.map((mutation) => mutation.operationId.value).toList(),
          'artifacts': [
            for (final artifact in [iconArtifact, audioArtifact])
              {
                'handle': artifact.handle,
                'rawSha256': artifact.rawSha256.value,
                'byteLength': artifact.bytes.length,
                'mediaType': artifact.reference.mediaType
              }
          ],
          'oracle': {
            'archiveHash': source.interpretationProfile?.scriptsArchiveHash.value,
            'receiveItem': {
              'section': 241,
              'lines': [725, 762]
            },
            'keyItemMusic': {
              'section': 0,
              'lines': [117, 129]
            },
            'itemBall': {
              'section': 241,
              'lines': [668, 719]
            },
            'skin': {
              'section': 79,
              'lines': [283, 374]
            },
            'freshOptions': {
              'section': 307,
              'lines': [20, 30]
            },
            'advance': {
              'section': 88,
              'lines': [612, 629]
            },
            'icon': {
              'section': 87,
              'lines': [519, 565]
            }
          },
        });
  }
}

String? _absentSourceBgmPath(
    NormalizedSourceProject source, MarshalDocument document, int? audioId) {
  if (source.snapshot.state != SourceScanState.complete || audioId == null) {
    return null;
  }
  final fields =
      _fields(document, audioId, 'RPG::AudioFile', 'bgm_unqualified');
  if (fields.length != 3 ||
      !fields.keys.toSet().containsAll({'@name', '@volume', '@pitch'})) {
    return null;
  }
  final nameNode = document.node(fields['@name']!);
  final name =
      nameNode.kind == MarshalKind.string ? nameNode.text().text : null;
  if (name == null ||
      name.isEmpty ||
      name.length > 512 ||
      name.trim() != name ||
      name == '.' ||
      name == '..' ||
      RegExp(r'[\\/:<>]').hasMatch(name) ||
      name.codeUnits.any((value) => value < 32) ||
      _integer(document, fields['@volume']) != 100 ||
      _integer(document, fields['@pitch']) != 100) {
    return null;
  }
  final base = 'Audio/BGM/$name';
  bool matches(String value, String candidate) =>
      value == candidate ||
      (value.startsWith('$candidate.') &&
          !value.substring(candidate.length + 1).contains('/'));
  final key = sourcePathCollisionKey(base);
  if (source.snapshot.excludedPaths.any((excluded) {
    final path = sourcePathCollisionKey(excluded);
    return key.startsWith('$path/') ||
        matches(path, key) ||
        matches(path, '${key}_n');
  })) {
    return null;
  }
  if (source.snapshot.entries.any((entry) {
    final path = sourcePathCollisionKey(entry.relativePath);
    return matches(path, key) || matches(path, '${key}_n');
  })) {
    return null;
  }
  return base;
}

Never _unavailable(String reason) =>
    throw SourcePickupBindingUnavailable('pickup.feedback.$reason');
Never _quota() => throw ContractError('source.pickup_feedback.quota', r'$',
    'Pickup feedback exceeds its bounded source or output quota.');

Map<String, int> _fields(
    MarshalDocument document, int nodeId, String className, String failure) {
  final node = document.node(nodeId);
  if (node.kind != MarshalKind.object || node.className != className) {
    _unavailable(failure);
  }
  if (node.instanceVariables.length > 128) _quota();
  final result = <String, int>{};
  for (final field in node.instanceVariables) {
    final name = document.node(field.key).name;
    if (document.node(field.key).kind != MarshalKind.symbol ||
        name == null ||
        result.containsKey(name)) {
      _unavailable(failure);
    }
    result[name] = field.value;
  }
  return result;
}

int? _integer(MarshalDocument document, int? id) {
  if (id == null) return null;
  final node = document.node(id), value = document.node(id).integerValue;
  return node.kind == MarshalKind.integer &&
          value != null &&
          value >= BigInt.zero &&
          value <= BigInt.from(2147483647)
      ? value.toInt()
      : null;
}

image.Image _png(Uint8List bytes, NativeWriteLimits limits, String family) {
  if (bytes.length < 24 ||
      bytes.take(8).join(',') != '137,80,78,71,13,10,26,10') {
    _unavailable('${family}_invalid');
  }
  final header = ByteData.sublistView(bytes),
      width = header.getUint32(16),
      height = header.getUint32(20);
  if (width == 0 || height == 0) _unavailable('${family}_invalid');
  if (width > limits.maxImagePixels ||
      height > limits.maxImagePixels ||
      width * height > limits.maxImagePixels) {
    _quota();
  }
  if ((family == 'icon' && (width > 256 || height > 256)) ||
      (family == 'skin' && (width != 96 || height != 48))) {
    _unavailable('${family}_unsupported');
  }
  try {
    final raster = image.decodePng(bytes);
    if (raster == null ||
        raster.width != width ||
        raster.height != height ||
        raster.numFrames != 1) {
      _unavailable('${family}_invalid');
    }
    return raster;
  } on SourcePickupBindingUnavailable {
    rethrow;
  } on Object {
    _unavailable('${family}_invalid');
  }
}

bool _isDarkSkin(image.Image skin) {
  double red = 0, green = 0, blue = 0;
  var count = 0;
  for (var y = 16; y < 32; y++) {
    for (var x = 32; x < 48; x++) {
      final pixel = skin.getPixel(x, y);
      if (pixel.a != 0) {
        red += pixel.r;
        green += pixel.g;
        blue += pixel.b;
        count++;
      }
    }
  }
  return count == 0 ||
      (red / count * 0.299 + green / count * 0.587 + blue / count * 0.114) <
          160;
}

Object? _freeze(Object? value) {
  if (value is Map<String, Object?>) {
    return Map<String, Object?>.unmodifiable(
        value.map((key, entry) => MapEntry(key, _freeze(entry))));
  }
  if (value is List) return List<Object?>.unmodifiable(value.map(_freeze));
  return value;
}

const _pocketNames = [
  'Items',
  'Medicine',
  'PokéBalls',
  'TMs & HMs',
  'Berries',
  'Mail',
  'Battle Items',
  'Key Items'
];
