import 'dart:convert';
import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';
import 'package:avelune_converter_adapters/src/source_pokedex_reward_binding.dart';

final class _Files implements SourceFilePort {
  _Files(this.bytes, this.paths, this.sourceRoot);
  final Map<ConverterId, List<int>> bytes;
  final Map<ConverterId, String> paths;
  final String sourceRoot;

  @override
  Future<List<int>> read(ConverterId id) async => bytes.containsKey(id)
      ? List.of(bytes[id]!)
      : File('$sourceRoot/${paths[id]}').readAsBytes();
}

Future<(NormalizedSourceProject, SourceFilePort)> _source(
    String folder, String sourceRoot,
    {bool changedDex = false,
    bool unrelatedDex = false,
    String? omitPath}) async {
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
  final paths = <ConverterId, String>{
    for (final dynamic row in input['entries'])
      ConverterId(row['fileId'] as String): row['relativePath'] as String,
  };
  final dexId = paths.entries
      .singleWhere((entry) => entry.value == 'Data/regional_dexes.dat')
      .key;
  if (changedDex || unrelatedDex) {
    final raw = await File('$sourceRoot/Data/regional_dexes.dat').readAsBytes();
    final before = utf8.encode(changedDex ? 'BULBASAUR' : 'MISSINGNO');
    final after = utf8.encode(changedDex ? 'NOTASAUUR' : 'OTHERDEXX');
    var found = false;
    for (var i = 0; i <= raw.length - before.length; i++) {
      if (before.indexed.every((pair) => raw[i + pair.$1] == pair.$2)) {
        raw.setRange(i, i + after.length, after);
        found = true;
        break;
      }
    }
    if (!found) throw StateError('Missing source dex symbol');
    bytes[dexId] = raw;
  }
  final changed = bytes.containsKey(dexId);
  final files = _Files(bytes, paths, sourceRoot);
  final snapshot = SourceSnapshot(
      logicalProjectNamespace:
          ConverterId(input['logicalProjectNamespace'] as String),
      policyHash: Sha256Hash(input['policyHash'] as String),
      entries: [
        for (final dynamic row in input['entries'])
          if (row['relativePath'] != omitPath)
            SourceFileEntry(
                fileId: ConverterId(row['fileId'] as String),
                relativePath: row['relativePath'] as String,
                kind: SourceNodeKind.values.byName(row['kind'] as String),
                byteLength: row['fileId'] == dexId.value && changed
                    ? bytes[dexId]!.length
                    : row['byteLength'] as int,
                sha256: row['sha256'] == null
                    ? null
                    : Sha256Hash(row['fileId'] == dexId.value && changed
                        ? crypto.sha256.convert(bytes[dexId]!).toString()
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
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: files,
      selectedMapIds: {102},
      includeEventSystem: true);
  return (source, files);
}

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('source regional Pokedex reward binding', () {
    late NormalizedSourceProject source;
    late SourceFilePort files;
    late SourceEventAnalysis analysis;
    SourceEventAnalysis analyze(NormalizedSourceProject value) =>
        SourceEventAnalyzer.forProject(value,
                profile: SourceEventProfile.forProject(value,
interpretationProfile: fixtureSourceInterpretationProfile,
))
            .analyze();
    setUpAll(() async {
      final fixture = await _source(archive!, root!);
      source = fixture.$1;
      files = fixture.$2;
      analysis = analyze(source);
    });
    test('attests exact 151-species regional scope and ordinary source item',
        () async {
      final binding = await const SourcePokedexRewardBindingResolver()
          .read(source: source, analysis: analysis, files: files);
      expect(binding, isNotNull);
      expect(binding!.range.firstNationalDex, 1);
      expect(binding.range.lastNationalDex, 151);
      expect(binding.item.sourceSymbol, 'EVERSTONE');
      expect(binding.item.pickupQualified, isTrue);
      expect(
          binding.isBoundToEvent(
              source: source,
              analysis: analysis,
              event: analysis.eventAt(102, 10)!),
          isTrue);
      expect(binding.toJson()['sourceScriptsExecuted'], 0);
      expect(binding.toJson()['fullSourceRewardParityQualified'], isFalse);
      expect(binding.toJson()['regionalSpecies'], hasLength(151));
      expect(binding.archive.files, hasLength(1));
      expect(binding.itemArchive.files, hasLength(1));
    });
    test('unknown regional species refuses the entire binding', () async {
      final fixture = await _source(archive!, root!, changedDex: true);
      expect(
          await const SourcePokedexRewardBindingResolver().read(
              source: fixture.$1,
              analysis: analyze(fixture.$1),
              files: fixture.$2),
          isNull);
    });
    test('unrelated attested regional dex change preserves exact slot one',
        () async {
      final fixture = await _source(archive!, root!, unrelatedDex: true);
      final binding = await const SourcePokedexRewardBindingResolver().read(
          source: fixture.$1, analysis: analyze(fixture.$1), files: fixture.$2);
      expect(binding, isNotNull);
      expect(binding!.toJson()['sourceFileMatchesReference'], isFalse);
    });
    for (final path in ['Data/regional_dexes.dat', 'Data/items.dat']) {
      test('missing $path preserves whole-event quarantine via absent binding',
          () async {
        final fixture = await _source(archive!, root!, omitPath: path);
        expect(
            await const SourcePokedexRewardBindingResolver().read(
                source: fixture.$1,
                analysis: analyze(fixture.$1),
                files: fixture.$2),
            isNull);
      });
    }
    test('unattested regional bytes fail before projection', () async {
      final entry = source.snapshot.entries.singleWhere(
          (entry) => entry.relativePath == 'Data/regional_dexes.dat');
      final altered = _Files({
        entry.fileId: [...await files.read(entry.fileId), 0]
      }, {
        for (final entry in source.snapshot.entries)
          entry.fileId: entry.relativePath
      }, root!);
      await expectLater(
          const SourcePokedexRewardBindingResolver()
              .read(source: source, analysis: analysis, files: altered),
          throwsA(isA<ContractError>().having(
              (e) => e.code, 'code', 'events.pokedex_reward.source_changed')));
    });
    test('another event and changed profile cannot reuse the reward binding',
        () async {
      final binding = (await const SourcePokedexRewardBindingResolver()
          .read(source: source, analysis: analysis, files: files))!;
      expect(
          binding.isBoundToEvent(
              source: source,
              analysis: analysis,
              event: analysis.eventAt(102, 6)!),
          isFalse);
      final badAnalysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source,
                  scriptsArchiveHash: Sha256Hash('0' * 64),
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      expect(
          binding.isBoundToEvent(
              source: source,
              analysis: badAnalysis,
              event: analysis.eventAt(102, 10)!),
          isFalse);
    });
  },
      skip: archive == null || root == null
          ? 'Original source archive and root required.'
          : false);
}
