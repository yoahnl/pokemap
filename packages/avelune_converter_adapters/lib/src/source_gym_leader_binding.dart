import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';

final class SourceGymLeaderBinding {
  SourceGymLeaderBinding._({required this.badge, required this.audioFile,
    required this.settingsFile, required this.metadataFile,
    required this.artifact, required this.audioMutation, required this.badgeMutation,
    required this.mediaId, required this.sourceHash, required this.profileHash,
    required this.programHash, required this.policyHash});
  final BadgeDefinition badge;
  final SourceFileEntry audioFile, settingsFile, metadataFile;
  final NativeArtifact artifact;
  final NativeMutation audioMutation, badgeMutation;
  final String mediaId;
  final Sha256Hash sourceHash, profileHash, programHash, policyHash;
  var _sourceEntryComparisonCount = 0;

  int get sourceEntryComparisonCount => _sourceEntryComparisonCount;

  bool isBoundTo(NormalizedSourceProject source, SourceEventProfile profile,
      SourceTrainerProgramNode program) => source.snapshot.canonicalHash == sourceHash &&
      profile.canonicalHash == profileHash && program.gymLeader != null &&
      canonicalHashOf(program.toJson()) == programHash &&
      canonicalHashOf(program.gymLeader!.toJson()) == policyHash &&
      [audioFile, settingsFile, metadataFile]
          .every((file) => _hasExactSourceFile(source, file));

  bool _hasExactSourceFile(NormalizedSourceProject source, SourceFileEntry file) {
    final expected = canonicalJsonOf(file.toJson());
    return source.snapshot.entries.any((entry) {
      if (entry.fileId != file.fileId) {
        return false;
      }
      _sourceEntryComparisonCount++;
      return canonicalJsonOf(entry.toJson()) == expected;
    });
  }

  DialogueLineFeedback feedback(DialogueLineFeedback line, String cueId) =>
      DialogueLineFeedback(segments: line.segments,
          revealIntervalMicros: line.revealIntervalMicros, advance: line.advance,
          audioCue: DialogueAudioCue(mediaAssetId: mediaId, cueId: cueId,
              volume: 1, role: DialogueAudioCueRole.musicEffect,
              bgmInterruption: DialogueBgmInterruption(fadeOutMs: 0, fadeInMs: 0)));

  Map<String, Object?> toJson() => {
    'kind': 'sourceGymLeaderBinding', 'sourceHash': sourceHash.value,
    'profileHash': profileHash.value, 'programHash': programHash.value,
    'policyHash': policyHash.value, 'badge': badge.toJson(),
    'sourceFiles': [settingsFile.toJson(), metadataFile.toJson(), audioFile.toJson()],
    'mediaId': mediaId, 'sourceVolume': 100, 'nativeAudioGain': 1,
    'nativeAudioRole': 'musicEffect', 'nativeBgmInterruptionMs': [0, 0],
    'presentationPolicy': 'aveluneBadgeAnnouncementWithSourceFanfare',
    'sourceOpcode249TimingParityQualified': false,
    'sourceEngineAudioGainParityQualified': false,
    'machineAttribution': 'qualifiedBagGrantRequired',
    'machineUseParityQualified': false,
  };
}

final class SourceGymLeaderBindingResolver {
  const SourceGymLeaderBindingResolver();

  Future<SourceGymLeaderBinding> read({required NormalizedSourceProject source,
    required SourceEventAnalysis analysis, required SourceEventDefinition event,
    required SourceTrainerProgramNode program, required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation}) async {
    Never refuse(String reason) => throw ContractError('events.gym.$reason',
        event.identity.value, 'Gym rewards require complete exact source bindings.');
    final policy = program.gymLeader;
    if (policy == null || program.kind != SourceTrainerProgramKind.encounter ||
        !analysis.profile.isQualified || source.snapshot.state != SourceScanState.complete ||
        !program.isBoundToSourceEvent(source: source, profile: analysis.profile,
            sourceMapId: event.sourceMapId,
            event: source.maps.singleWhere((map) => map.map.sourceMapId == event.sourceMapId)
                .map.events.singleWhere((raw) => raw.sourceEventId == event.sourceEventId))) {
      refuse('source_binding');
    }
    Future<(SourceFileEntry, List<int>)> read(String path) async {
      cancellation?.check();
      final matches = source.snapshot.entries.where((entry) =>
          sourcePathCollisionKey(entry.relativePath) == sourcePathCollisionKey(path)).toList();
      if (matches.length != 1 || matches.single.relativePath != path ||
          matches.single.kind != SourceNodeKind.file || matches.single.sha256 == null) {
        refuse('source_missing');
      }
      final file = matches.single;
      if (file.byteLength > limits.maxArtifactBytes) refuse('quota');
      final bytes = await files.read(file.fileId);
      if (bytes.length != file.byteLength || crypto.sha256.convert(bytes).toString() != file.sha256!.value) {
        refuse('source_changed');
      }
      return (file, bytes);
    }
    final scripts = await read('Data/Scripts.rxdata');
    if (scripts.$1.sha256 != source.interpretationProfile?.scriptsArchiveHash) refuse('scripts_binding');
    final section = source.interpretationProfile?.sections['events.Settings'];
    if (section == null) refuse('settings_profile');
    final encodedSection = section;
    final index = encodedSection['index'] as int;
    final document = const MarshalDecoder().decode(scripts.$2);
    final entries = document.node(document.rootId).elements;
    if (index < 0 || index >= entries.length) refuse('settings_index');
    final row = document.node(entries[index]).elements;
    if (row.length != 3 || document.node(row[2]).bytes == null) refuse('settings_shape');
    final bytes = const BoundedZlibDecoder().decode(document.node(row[2]).bytes!,
        limits: const ZlibDecodeLimits(maxInputBytes: 1048576, maxOutputBytes: 1048576, maxBlocks: 10000));
    if (crypto.sha256.convert(bytes).toString() != encodedSection['sha256']) refuse('settings_hash');
    final settings = utf8.decode(bytes);
    final count = RegExp(r'^\s*FIELD_MOVES_COUNT_BADGES\s*=\s*(false|true)\s*$', multiLine: true).allMatches(settings).toList();
    final matrix = RegExp(r'^\s*REGION_HM_ARRAY\s*=\s*(\[(?:[\s\d,\-\[\]])+\])', multiLine: true).allMatches(settings).toList();
    if (count.length != 1 || count.single.group(1) != 'false' || matrix.length != 1) refuse('settings_policy');
    final raw = jsonDecode(matrix.single.group(1)!) as List;
    if (raw.length > 64 || raw.length < 2 || raw.any((row) => row is! List || row.length > 64 || row.any((value) => value is! int))) refuse('settings_matrix');
    final metadata = await read('PBS/map_metadata.txt');
    int? current, region;
    final sections = <int>{};
    for (final text in const LineSplitter().convert(utf8.decode(metadata.$2))) {
      final line = text.split('#').first.trim();
      final header = RegExp(r'^\[([0-9]+)\]$').firstMatch(line);
      if (header != null) {
        current = int.parse(header[1]!);
        if (!sections.add(current)) refuse('metadata_duplicate');
      }
      final position = RegExp(r'^MapPosition\s*=\s*(\d+)\s*,\s*\d+\s*,\s*\d+\s*$').firstMatch(line);
      if (current == event.sourceMapId && position != null) {
        if (region != null) refuse('metadata_ambiguous');
        region = int.parse(position[1]!);
      }
    }
    if (region != 1) refuse('region');
    FieldAbility? ability;
    for (final entry in const {'CUT': FieldAbility.cut, 'FLY': FieldAbility.fly,
      'SURF': FieldAbility.surf, 'STRENGTH': FieldAbility.strength,
      'FLASH': FieldAbility.flash, 'ROCKSMASH': FieldAbility.rockSmash}.entries) {
      final matches = RegExp('^\\s*BADGE_FOR_${entry.key}\\s*=\\s*(-?\\d+)\\s*\$', multiLine: true).allMatches(settings).toList();
      if (matches.length != 1) refuse('ability_policy');
      final column = int.parse(matches.single[1]!);
      final badges = raw[1] as List;
      if (column < 0 || column >= badges.length) refuse('ability_column');
      if (badges[column] == policy.sourceBadgeIndex) {
        if (ability != null) refuse('ability_conflict');
        ability = entry.value;
      }
    }
    final namespace = canonicalHashOf({'namespace': source.snapshot.logicalProjectNamespace.value,
      'kind': 'sourceFieldObstacles'}).value.substring(0, 24);
    final badgeId = 'source_badge_r1_b${policy.sourceBadgeIndex}_$namespace';
    final badge = BadgeDefinition(id: badgeId,
        label: 'Badge source ${policy.sourceBadgeIndex} (région 1)', fieldAbilityUnlock: ability);
    final presentation = program.victoryContinuation.nodes.first as SourceGymBadgePresentationNode;
    final base = 'Audio/ME/${presentation.musicName}';
    final audioMatches = source.snapshot.entries.where((entry) {
      final path = sourcePathCollisionKey(entry.relativePath), key = sourcePathCollisionKey(base);
      return path.startsWith('$key.') && !path.substring(key.length + 1).contains('/');
    }).toList();
    if (audioMatches.length != 1) refuse('audio_missing_or_ambiguous');
    final audio = await read(audioMatches.single.relativePath);
    final extension = audio.$1.relativePath.substring(base.length + 1);
    final mediaType = const {'ogg': 'audio/ogg', 'wav': 'audio/wav',
      'mp3': 'audio/mpeg', 'flac': 'audio/flac'}[extension];
    if (mediaType == null || audio.$1.relativePath != '$base.$extension') refuse('audio_format');
    final artifact = NativeArtifact(bytes: audio.$2, mediaType: mediaType,
        expectedSha256: audio.$1.sha256, limits: limits);
    final key = canonicalHashOf({'kind': 'sourceGymBadgeMusic',
      'namespace': source.snapshot.logicalProjectNamespace.value,
      'sourceFile': audio.$1.fileId.value, 'sha256': audio.$1.sha256!.value}).value.substring(0, 24);
    final mediaId = 'source_gym_music_$key', assetId = 'source_gym_audio_$key';
    return SourceGymLeaderBinding._(badge: badge, audioFile: audio.$1,
        settingsFile: scripts.$1, metadataFile: metadata.$1, artifact: artifact,
        mediaId: mediaId, sourceHash: source.snapshot.canonicalHash,
        profileHash: analysis.profile.canonicalHash, programHash: canonicalHashOf(program.toJson()),
        policyHash: canonicalHashOf(policy.toJson()),
        audioMutation: NativeMutation(operationId: ConverterId('import_$assetId'),
            actionId: 'scene.dialogue.audioMedia.import', sourceEntityIds: [audio.$1.fileId],
            targetEntityIds: [ConverterId(assetId), ConverterId(mediaId)],
            parameters: {'artifactHandle': artifact.handle, 'assetId': assetId,
              'mediaId': mediaId, 'label': presentation.musicName,
              'logicalPath': 'assets/audio/$assetId.$extension'}, limits: limits),
        badgeMutation: NativeMutation(operationId: ConverterId('source_gym_badge_$badgeId'),
            actionId: 'campaign.badge.upsert', sourceEntityIds: [scripts.$1.fileId, metadata.$1.fileId],
            targetEntityIds: [ConverterId(badgeId)], parameters: {'value': badge.toJson()}, limits: limits));
  }
}
