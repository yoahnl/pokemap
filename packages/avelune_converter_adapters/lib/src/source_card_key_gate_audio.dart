import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'native_project_writer.dart';

const _missingOptionalSoundSections = [
  (34, 'Interpreter_Commands',
      'ec927a007bee1889223dbc8b3de115f062a5308ab4410f87dab965eef3032561'),
  (93, 'Audio_Play',
      'e21c2f9b086f99777b7421c850e4b04cb8e5db574876b3fbb9c0fd9932e1d1fb'),
  (40, 'Game_System',
      '38574a92d37fad43446237e6f429863507a46b9c7c4e7806a7251ee71a307bdb'),
  (19, 'FileTests',
      'ec5be8b9ee266b6d6b0f5dc5b8ffd2d51436a6e43902f57aefa6e77546cfe429'),
];

final class SourceMissingOptionalSoundProof {
  SourceMissingOptionalSoundProof._(this.name, this.sourceHash,
      this.normalizationHash, this.profileHash, List<SourceFileEntry> witnesses)
      : witnesses = List.unmodifiable(witnesses);
  final String name;
  final Sha256Hash sourceHash, normalizationHash, profileHash;
  final List<SourceFileEntry> witnesses;

  bool isBoundTo(NormalizedSourceProject source, SourceEventProfile profile,
          {required String name}) =>
      this.name == name &&
      source.snapshot.canonicalHash == sourceHash &&
      source.canonicalHash == normalizationHash &&
      profile.isQualified &&
      profile.canonicalHash == profileHash;

  Map<String, Object?> toJson() => {
        'kind': 'sourceMissingOptionalSoundNoOp',
        'policy': 'attested-missing-optional-se-noop-v1',
        'name': name,
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
        'sourceSections': [
          for (final section in _missingOptionalSoundSections)
            {'index': section.$1, 'name': section.$2, 'sha256': section.$3}
        ],
        'sourceRtpRoots': ['./'],
        'sourceGameIniPolicy': 'bounded-local-scripts-and-empty-rtp-v1',
        'sourcePluginArchivePolicy':
            'attested-se-resolution-equivalent-distributions-v1',
        'sourceAudioFilePresent': false,
        'nativeSoundSubstituted': false,
        'sourceDiagnosticRetained': true,
        'sourceScriptsExecuted': 0,
        'sourcePlaybackObserved': false,
      };
}

final class SourceMissingOptionalSoundResolver {
  const SourceMissingOptionalSoundResolver();

  Future<SourceMissingOptionalSoundProof> read(
      {required NormalizedSourceProject source,
      required SourceFilePort files,
      required String name,
      NativeWriteLimits limits = const NativeWriteLimits(),
      ScanCancellation? cancellation}) async {
    Never refuse(String reason) => throw NativeWriteException(
        'events.optional_sound.$reason',
        'A missing optional sound requires its exact source engine, local RTP and complete absence proof.');
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
    if (name.isEmpty || name.length > 256 || name.trim() != name ||
        name == '.' || name == '..' ||
        RegExp(r'[\\/:<>\x00-\x1f]').hasMatch(name)) {
      refuse('audio_name_unqualified');
    }
    final entries = source.snapshot.entries;
    final base = sourcePathCollisionKey('Audio/SE/$name');
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
    SourceFileEntry exact(String name, String? hash, int? length) {
      final matches = entries
          .where((entry) =>
              sourcePathCollisionKey(entry.relativePath) ==
              sourcePathCollisionKey(name))
          .toList();
      if (matches.length != 1 ||
          matches.single.relativePath != name ||
          matches.single.kind != SourceNodeKind.file ||
          matches.single.sha256 == null ||
          hash != null && matches.single.sha256!.value != hash ||
          length != null && matches.single.byteLength != length) {
        refuse('audio_resolution_unqualified');
      }
      return matches.single;
    }

    final witnesses = <SourceFileEntry>[
      exact('Data/Scripts.rxdata', profile.scriptsArchiveHash!.value, null),
      exact('Game.ini', null, null),
      exact(
          'mkxp.json',
          '90a3aee82895e48e6c767f973b637d27856cccfd575f48b78d04191cb3e7d35f',
          6212),
      exact('Data/PluginScripts.rxdata', null, null),
    ];
    final pluginArchive = witnesses.last;
    if (!const {
      (477498,
          'f390bd7fb8c034267c8341500f257b8ab1aaaef204c4c88477c81b39806ce9bb'),
      (477493,
          '8de00f654e8912ba1f8ef04b9a22994b0456c2ccbca6b8c64e09d654e1b1868b'),
      (477498,
          '9a12df5c3a8af5d8c6aa337ff1801ce017108950824e07c20d45446d9630a695'),
    }.contains((pluginArchive.byteLength, pluginArchive.sha256!.value))) {
      refuse('audio_overrides_unqualified');
    }
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
    List<int>? scriptsBytes;
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
      if (file.relativePath == 'Game.ini' &&
          !_sourceMissingOptionalSoundIniIsLocal(bytes)) {
        refuse('audio_resolution_unqualified');
      }
      if (file.relativePath == 'Data/Scripts.rxdata') scriptsBytes = bytes;
    }
    final document = const MarshalDecoder().decode(scriptsBytes!,
        sourcePath: 'Data/Scripts.rxdata',
        limits: const MarshalDecodeLimits(
            maxInputBytes: 8388608, maxNodes: 100000,
            maxObjects: 100000, maxSymbols: 4096,
            maxContainerEntries: 65536, maxTotalEntries: 100000,
            maxStringBytes: 8388608, maxTotalStringBytes: 8388608));
    final root = document.node(document.rootId);
    if (root.kind != MarshalKind.array) refuse('audio_oracle_unqualified');
    for (final section in _missingOptionalSoundSections) {
      cancellation?.check();
      if (section.$1 >= root.elements.length) refuse('audio_oracle_unqualified');
      final row = document.node(root.elements[section.$1]);
      if (row.kind != MarshalKind.array || row.elements.length != 3) {
        refuse('audio_oracle_unqualified');
      }
      final title = document.node(row.elements[1]);
      final compressed = document.node(row.elements[2]);
      if (title.kind != MarshalKind.string || title.text().text != section.$2 ||
          compressed.kind != MarshalKind.string || compressed.bytes == null) {
        refuse('audio_oracle_unqualified');
      }
      final expanded = const BoundedZlibDecoder().decode(compressed.bytes!,
          sourcePath: 'Data/Scripts.rxdata',
          limits: const ZlibDecodeLimits(
              maxInputBytes: 8388608, maxOutputBytes: 4194304));
      if (crypto.sha256.convert(expanded).toString() != section.$3) {
        refuse('audio_oracle_unqualified');
      }
    }
    cancellation?.check();
    return SourceMissingOptionalSoundProof._(name, source.snapshot.canonicalHash,
        source.canonicalHash, profile.canonicalHash, witnesses);
  }
}

bool _sourceMissingOptionalSoundIniIsLocal(List<int> bytes) {
  if (bytes.isEmpty || bytes.length > 4096 || bytes.contains(0)) return false;
  final lines = const LineSplitter().convert(latin1.decode(bytes));
  final values = <String, String>{};
  var gameSection = false;
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line == '[Game]') {
      if (gameSection || values.isNotEmpty) return false;
      gameSection = true;
      continue;
    }
    final equals = line.indexOf('=');
    if (!gameSection || equals < 1) return false;
    final key = line.substring(0, equals).trim();
    final value = line.substring(equals + 1).trim();
    if (!const {'Library', 'Scripts', 'Title', 'RTP1', 'RTP2', 'RTP3'}
            .contains(key) ||
        values.containsKey(key)) {
      return false;
    }
    values[key] = value;
  }
  final title = values['Title'];
  return values.length == 6 && values['Library'] == 'RGSS104E.dll' &&
      values['Scripts']?.replaceAll(r'\', '/') == 'Data/Scripts.rxdata' &&
      title != null && title.isNotEmpty && title.length <= 256 &&
      !title.codeUnits.any((unit) => unit < 32 || unit == 127) &&
      const ['RTP1', 'RTP2', 'RTP3'].every((key) => values[key] == '');
}
