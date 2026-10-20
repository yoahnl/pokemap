import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'native_project_writer.dart';

final class SourceCardKeyGateMissingAudioProof {
  SourceCardKeyGateMissingAudioProof._(this.sourceHash, this.normalizationHash,
      this.profileHash, List<SourceFileEntry> witnesses)
      : witnesses = List.unmodifiable(witnesses);
  final Sha256Hash sourceHash, normalizationHash, profileHash;
  final List<SourceFileEntry> witnesses;

  bool isBoundTo(NormalizedSourceProject source, SourceEventProfile profile) =>
      source.snapshot.canonicalHash == sourceHash &&
      source.canonicalHash == normalizationHash &&
      profile.isQualified &&
      profile.canonicalHash == profileHash;

  Map<String, Object?> toJson() => {
        'kind': 'sourceMissingGateSoundNoOp',
        'name': 'frlg_gateopen',
        'diagnostic': 'sourceAudioMissing',
        'sourceSnapshotHash': sourceHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'files': [for (final file in witnesses) file.toJson()],
        'sourceOracle': {
          'Interpreter_Commands': '034:1051-1053',
          'Audio_Play': '093:202-208',
          'Game_System': '040:239-246',
          'FileTests': '019:184-192,216-241,264-267'
        },
        'sourceRtpRoots': ['./'],
        'sourceAudioFilePresent': false,
        'nativeSoundSubstituted': false,
        'sourceDiagnosticRetained': true,
        'sourceScriptsExecuted': 0,
        'sourcePlaybackObserved': false,
      };
}

final class SourceCardKeyGateMissingAudioResolver {
  const SourceCardKeyGateMissingAudioResolver();

  Future<SourceCardKeyGateMissingAudioProof> read(
      {required NormalizedSourceProject source,
      required SourceFilePort files,
      NativeWriteLimits limits = const NativeWriteLimits(),
      ScanCancellation? cancellation}) async {
    Never refuse(String reason) => throw NativeWriteException(
        'events.card_key_gate.$reason',
        'The missing gate sound requires its exact source engine, empty RTP and absence proof.');
    cancellation?.check();
    limits.validate();
    final profile = SourceEventProfile.forProject(source);
    if (!profile.isQualified ||
        source.snapshot.state != SourceScanState.complete ||
        !const {
          '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d',
          '8b03301e71b12ba8cc84efb128534d0a7f17d02cf56c770e40c16be37b730940',
        }.contains(profile.scriptsArchiveHash?.value)) {
      refuse('audio_oracle_unqualified');
    }
    final entries = source.snapshot.entries;
    const base = 'audio/se/frlg_gateopen';
    if (source.snapshot.excludedPaths.any((path) {
      final key = sourcePathCollisionKey(path);
      return key == 'audio' ||
          key == 'audio/se' ||
          key.startsWith('audio/se/') ||
          key == 'plugins' ||
          key.startsWith('plugins/') ||
          key.endsWith('.rb') ||
          RegExp(r'\.(rgssad|rgss2a|rgss3a)$').hasMatch(key);
    })) {
      refuse('audio_absence_unqualified');
    }
    if (entries.any((entry) {
      final key = sourcePathCollisionKey(entry.relativePath);
      return key == base ||
          key.startsWith('$base.') ||
          RegExp(r'\.(rgssad|rgss2a|rgss3a)$').hasMatch(key);
    })) {
      refuse('audio_absence_unqualified');
    }
    SourceFileEntry exact(String name, String hash, int? length) {
      final matches = entries
          .where((entry) =>
              sourcePathCollisionKey(entry.relativePath) ==
              sourcePathCollisionKey(name))
          .toList();
      if (matches.length != 1 ||
          matches.single.relativePath != name ||
          matches.single.kind != SourceNodeKind.file ||
          matches.single.sha256?.value != hash ||
          length != null && matches.single.byteLength != length) {
        refuse('audio_resolution_unqualified');
      }
      return matches.single;
    }

    final witnesses = <SourceFileEntry>[
      exact('Data/Scripts.rxdata', profile.scriptsArchiveHash!.value, null),
      exact(
          'Game.ini',
          '5ca2b3b37b92767097a5db5a126c6c50cc6fc2602d3fa9776f06883838aba5f6',
          121),
      exact(
          'mkxp.json',
          '90a3aee82895e48e6c767f973b637d27856cccfd575f48b78d04191cb3e7d35f',
          6212),
      exact(
          'Data/PluginScripts.rxdata',
          'f390bd7fb8c034267c8341500f257b8ab1aaaef204c4c88477c81b39806ce9bb',
          477498),
    ];
    final ruby = entries
        .where((entry) => entry.relativePath.toLowerCase().endsWith('.rb'))
        .toList()
      ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
    if (canonicalHashOf([
          for (final file in ruby)
            {
              'path': file.relativePath,
              'size': file.byteLength,
              'sha256': file.sha256?.value
            }
        ]).value !=
        '6394899d20b1f9d3a5a8125e8927e370baa1412770adc14a8dd623a5c67911cd') {
      refuse('audio_overrides_unqualified');
    }
    witnesses.addAll(ruby);
    var reserved = 0;
    for (final file in witnesses) {
      cancellation?.check();
      if (file.byteLength > limits.maxArtifactBytes ||
          reserved + file.byteLength > limits.maxTotalArtifactBytes) {
        refuse('audio_proof_quota');
      }
      reserved += file.byteLength;
      final bytes = await files.read(file.fileId);
      if (bytes.length != file.byteLength ||
          crypto.sha256.convert(bytes).toString() != file.sha256!.value) {
        refuse('audio_proof_changed');
      }
    }
    cancellation?.check();
    return SourceCardKeyGateMissingAudioProof._(source.snapshot.canonicalHash,
        source.canonicalHash, profile.canonicalHash, witnesses);
  }
}
