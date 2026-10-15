import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';

final class SourceCenterRecoveryBindingUnavailable implements Exception {
  const SourceCenterRecoveryBindingUnavailable(this.reason);
  final String reason;
}

final class SourceCenterRecoveryBinding {
  const SourceCenterRecoveryBinding._({
    required this.sourceSnapshotHash,
    required this.normalizationHash,
    required this.profileHash,
    required this.audioFile,
    required this.mediaId,
    required this.artifact,
    required this.mutation,
    required this.evidence,
  });

  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;
  final SourceFileEntry audioFile;
  final String mediaId;
  final NativeArtifact artifact;
  final NativeMutation mutation;
  final Map<String, Object?> evidence;

  bool isBoundTo(NormalizedSourceProject source, SourceEventProfile profile) =>
      sourceSnapshotHash == source.snapshot.canonicalHash &&
      normalizationHash == source.canonicalHash &&
      profileHash == profile.canonicalHash &&
      source.snapshot.entries.any((entry) =>
          entry.fileId == audioFile.fileId &&
          entry.relativePath == audioFile.relativePath &&
          entry.sha256 == audioFile.sha256 &&
          entry.byteLength == audioFile.byteLength &&
          entry.kind == SourceNodeKind.file);

  DialogueLineFeedback recoveryFeedback(
          {required String cueId, required DialogueLineFeedback line}) =>
      DialogueLineFeedback(
        segments: line.segments,
        revealIntervalMicros: line.revealIntervalMicros,
        advance: DialogueLineAdvancePolicy.autoAfterReveal(2900000),
        audioCue: DialogueAudioCue(
            mediaAssetId: mediaId,
            cueId: cueId,
            volume: 0.8,
            role: DialogueAudioCueRole.musicEffect,
            bgmInterruption:
                DialogueBgmInterruption(fadeOutMs: 0, fadeInMs: 0)),
      );
}

final class SourceCenterRecoveryResolver {
  const SourceCenterRecoveryResolver();

  Future<SourceCenterRecoveryBinding> read({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    limits.validate();
    final profile = SourceEventProfile.kantoForProject(source);
    if (!profile.isQualified ||
        source.snapshot.state != SourceScanState.complete) {
      throw const SourceCenterRecoveryBindingUnavailable('source_unqualified');
    }
    final nurse = SourceEventAnalyzer.forProject(source, profile: profile)
        .analyze()
        .eventAt(102, 2);
    if (nurse == null ||
        nurse.isQuarantined ||
        nurse.pages.length != 2 ||
        nurse.pages.any((page) =>
            page.body.nodes.length != 1 ||
            page.body.nodes.single is! SourceCenterServiceProgramNode ||
            (page.body.nodes.single as SourceCenterServiceProgramNode).isPc)) {
      throw const SourceCenterRecoveryBindingUnavailable(
          'source_program_unqualified');
    }
    const name = 'FRLG Misc - Pokemon Recovery (Pokemon Recovery)';
    const base = 'Audio/ME/$name';
    final matches = source.snapshot.entries.where((entry) {
      final key = sourcePathCollisionKey(entry.relativePath);
      final expected = sourcePathCollisionKey(base);
      return key == expected ||
          (key.startsWith('$expected.') &&
              !key.substring(expected.length + 1).contains('/'));
    }).toList();
    if (matches.length != 1) {
      throw SourceCenterRecoveryBindingUnavailable(
          matches.isEmpty ? 'audio_missing' : 'audio_ambiguous');
    }
    final audio = matches.single;
    final extension = audio.relativePath.length > base.length + 1
        ? audio.relativePath.substring(base.length + 1)
        : '';
    final mediaType = const {
      'ogg': 'audio/ogg',
      'wav': 'audio/wav',
      'mp3': 'audio/mpeg',
      'flac': 'audio/flac'
    }[extension];
    if (audio.kind != SourceNodeKind.file ||
        audio.sha256 == null ||
        mediaType == null ||
        audio.relativePath != '$base.$extension') {
      throw const SourceCenterRecoveryBindingUnavailable('audio_unattested');
    }
    if (audio.byteLength > limits.maxArtifactBytes ||
        audio.byteLength > limits.maxTotalArtifactBytes) {
      throw const NativeWriteException('events.center_recovery.quota',
          'The recovery music exceeds the native artifact budget.');
    }
    final bytes = await files.read(audio.fileId);
    cancellation?.check();
    if (bytes.length != audio.byteLength ||
        crypto.sha256.convert(bytes).toString() != audio.sha256!.value) {
      throw ContractError(
          'source.center_recovery.audio_changed',
          audio.relativePath,
          'Recovery audio no longer matches its source inventory.');
    }
    final artifact = NativeArtifact(
        bytes: bytes,
        mediaType: mediaType,
        expectedSha256: audio.sha256,
        limits: limits);
    final identity = canonicalHashOf({
      'kind': 'centerRecoveryMusic',
      'namespace': source.snapshot.logicalProjectNamespace.value,
      'sourceFileId': audio.fileId.value,
      'sourceSha256': audio.sha256!.value
    }).value.substring(0, 24);
    final mediaId = 'source_center_recovery_$identity';
    final assetId = 'source_center_recovery_audio_$identity';
    final mutation = NativeMutation(
        operationId: ConverterId('import_$assetId'),
        actionId: 'scene.dialogue.audioMedia.import',
        sourceEntityIds: [audio.fileId],
        targetEntityIds: [ConverterId(assetId), ConverterId(mediaId)],
        parameters: {
          'artifactHandle': artifact.handle,
          'assetId': assetId,
          'mediaId': mediaId,
          'label': name,
          'logicalPath': 'assets/audio/$assetId.$extension',
        },
        limits: limits);
    return SourceCenterRecoveryBinding._(
        sourceSnapshotHash: source.snapshot.canonicalHash,
        normalizationHash: source.canonicalHash,
        profileHash: profile.canonicalHash,
        audioFile: audio,
        mediaId: mediaId,
        artifact: artifact,
        mutation: mutation,
        evidence: Map.unmodifiable({
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'normalizationHash': source.canonicalHash.value,
          'sourceProfileHash': profile.canonicalHash.value,
          'sourceMusicName': name,
          'sourceAudioFile': audio.toJson(),
          'sourcePrograms': [
            for (final page in nurse.pages)
              (page.body.nodes.single as SourceCenterServiceProgramNode)
                  .toJson()
          ],
          'sourceOpcode': 249,
          'sourceVolume': 100,
          'sourcePitch': 100,
          'sourceWaitTicks': 58,
          'sourceTicksPerSecond': 20,
          'nativeFeedbackAdvanceDelayMicros': 2900000,
          'nativeRecoveryCueWithFirstCompletionLine': true,
          'sourceSilentWaitBeforeCompletionParityQualified': false,
          'nativeAudioRole': 'musicEffect',
          'nativeAudioGain': 0.8,
          'sourceAudioGainParityQualified': false,
          'sourceNurseAndBallAnimationParityQualified': false,
          'sourceScriptsExecuted': 0,
          'sourcePlaybackObserved': false,
          'fullSourceServiceParityQualified': false,
        }));
  }
}
