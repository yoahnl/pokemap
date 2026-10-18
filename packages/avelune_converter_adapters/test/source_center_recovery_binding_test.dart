import 'dart:convert';
import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_converter_adapters/src/source_center_recovery_binding.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';

final class _Files implements SourceFilePort {
  _Files(this.bytes);
  final Map<ConverterId, List<int>> bytes;

  @override
  Future<List<int>> read(ConverterId id) async => List.of(bytes[id]!);
}

List<int> _replaceLiteral(List<int> bytes, String before, String after) {
  final old = utf8.encode(before), next = utf8.encode(after);
  final pattern = [0x22, old.length + 5, ...old];
  for (var index = 0; index <= bytes.length - pattern.length; index++) {
    if (List.generate(pattern.length, (slot) => bytes[index + slot])
        .indexed
        .every((entry) => entry.$2 == pattern[entry.$1])) {
      return [
        ...bytes.take(index),
        0x22,
        next.length + 5,
        ...next,
        ...bytes.skip(index + pattern.length)
      ];
    }
  }
  throw StateError('Source literal not found: $before');
}

Future<NormalizedSourceProject> _source(String folder,
    {String? before, String? after}) async {
  final input = jsonDecode(await File('$folder/snapshot.json').readAsString())
      as Map<String, dynamic>;
  final frozen =
      jsonDecode(await File('$folder/normalized.json').readAsString())
          as Map<String, dynamic>;
  final bytes = <ConverterId, List<int>>{
    for (final dynamic row in frozen['archive']['files'])
      ConverterId(row['entry']['fileId'] as String):
          base64Decode(row['rawBytes'] as String)
  };
  final map = (input['entries'] as List)
      .cast<Map>()
      .singleWhere((row) => row['relativePath'] == 'Data/Map102.rxdata');
  final mapId = ConverterId(map['fileId'] as String);
  if (before != null) {
    bytes[mapId] = _replaceLiteral(bytes[mapId]!, before, after!);
  }
  final snapshot = SourceSnapshot(
      logicalProjectNamespace:
          ConverterId(input['logicalProjectNamespace'] as String),
      policyHash: Sha256Hash(input['policyHash'] as String),
      entries: [
        for (final dynamic row in input['entries'])
          SourceFileEntry(
              fileId: ConverterId(row['fileId'] as String),
              relativePath: row['relativePath'] as String,
              kind: SourceNodeKind.values.byName(row['kind'] as String),
              byteLength: row['fileId'] == mapId.value && before != null
                  ? bytes[mapId]!.length
                  : row['byteLength'] as int,
              sha256: row['sha256'] == null
                  ? null
                  : Sha256Hash(row['fileId'] == mapId.value && before != null
                      ? crypto.sha256.convert(bytes[mapId]!).toString()
                      : row['sha256'] as String),
              format: row['format'] as String,
              family: row['family'] as String)
      ],
      diagnostics: [],
      excludedPaths: (input['excludedPaths'] as List).cast<String>(),
      profileEvidence: [
        for (final dynamic row in input['profileEvidence'])
          SourceProfileEvidence(
              relativePath: row['relativePath'] as String,
              fileHash: Sha256Hash(row['fileHash'] as String),
              version: row['version'] as String,
              line: row['line'] as int,
              excerpt: row['excerpt'] as String)
      ],
      state: SourceScanState.values.byName(input['state'] as String));
  return const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: _Files(bytes),
      selectedMapIds: {102},
      includeEventSystem: true);
}

final class _AudioFiles implements SourceFilePort {
  _AudioFiles(this.source, this.root, {this.changed = false});
  final NormalizedSourceProject source;
  final String root;
  final bool changed;
  final reads = <String>[];
  @override
  Future<List<int>> read(ConverterId id) async {
    final entry =
        source.snapshot.entries.singleWhere((entry) => entry.fileId == id);
    reads.add(entry.relativePath);
    final bytes = await File('$root/${entry.relativePath}').readAsBytes();
    if (changed) bytes[bytes.length - 1] ^= 1;
    return bytes;
  }
}

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final sourceRoot = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('source Center recovery music binding', () {
    late NormalizedSourceProject source;
    setUpAll(() async {
      source = await _source(archive!);
    });

    test('attested source recovery ME becomes a native music-effect cue',
        () async {
      final files = _AudioFiles(source, sourceRoot!);
      final binding = await const SourceCenterRecoveryResolver()
          .read(source: source, files: files);
      expect(files.reads,
          ['Audio/ME/FRLG Misc - Pokemon Recovery (Pokemon Recovery).ogg']);
      expect(binding.artifact.rawSha256, binding.audioFile.sha256);
      expect(binding.mutation.actionId, 'scene.dialogue.audioMedia.import');
      expect(
          binding.isBoundTo(source, SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
)),
          isTrue);
      final feedback = binding.recoveryFeedback(
          cueId: 'recovery',
          line: DialogueLineFeedback(
              segments: [DialogueTextSegment('Thank you for waiting.')]));
      expect(feedback.plainText, 'Thank you for waiting.');
      expect(feedback.advance.delayMicros, 2900000);
      expect(feedback.audioCue!.role, DialogueAudioCueRole.musicEffect);
      expect(feedback.audioCue!.mediaAssetId, binding.mediaId);
      expect(feedback.audioCue!.bgmInterruption, isNotNull);
      expect(binding.evidence['fullSourceServiceParityQualified'], isFalse);
      expect(binding.evidence['sourceAudioGainParityQualified'], isFalse);
    });

    test('recovery audio quota is checked before reading bytes', () async {
      final files = _AudioFiles(source, sourceRoot!);
      await expectLater(
          const SourceCenterRecoveryResolver().read(
              source: source,
              files: files,
              limits: const NativeWriteLimits(maxArtifactBytes: 1)),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'events.center_recovery.quota')));
      expect(files.reads, isEmpty);
    });

    test('changed recovery audio refuses the source inventory hash', () async {
      final files = _AudioFiles(source, sourceRoot!, changed: true);
      await expectLater(
          const SourceCenterRecoveryResolver()
              .read(source: source, files: files),
          throwsA(isA<ContractError>().having((error) => error.code, 'code',
              'source.center_recovery.audio_changed')));
    });

    test('binding refuses an unqualified or stale event profile', () async {
      final binding = await const SourceCenterRecoveryResolver()
          .read(source: source, files: _AudioFiles(source, sourceRoot!));
      expect(
          binding.isBoundTo(
              source,
              SourceEventProfile.forProject(source,
                  scriptsArchiveHash: Sha256Hash('0' * 64),
interpretationProfile: fixtureSourceInterpretationProfile,
)),
          isFalse);
    });

    test('changed nurse checkpoint program cannot bind recovery music',
        () async {
      final changed = await _source(archive!,
          before: 'pbSetPokemonCenter',
          after: 'pbSetPokemonCenter;unqualified_call()');
      final files = _AudioFiles(changed, sourceRoot!);
      await expectLater(
          const SourceCenterRecoveryResolver()
              .read(source: changed, files: files),
          throwsA(isA<SourceCenterRecoveryBindingUnavailable>().having(
              (error) => error.reason,
              'reason',
              'source_program_unqualified')));
      expect(files.reads, isEmpty);
    });
  }, skip: archive == null || sourceRoot == null);
}
