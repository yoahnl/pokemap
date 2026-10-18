import 'dart:convert';
import 'dart:io';
import 'support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

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

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  group('original center service programs', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;

    setUpAll(() async {
      source = await _source(archive!);
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
    });

    test('all original nurse and PC pages have a closed typed source program',
        () {
      for (final eventId in [2, 3]) {
        final event = analysis.events.singleWhere((event) =>
            event.sourceMapId == 102 && event.sourceEventId == eventId);
        expect(event.isQuarantined, isFalse,
            reason: '102:$eventId must retain its exact two-page service.');
        expect(event.pages, hasLength(2));
        for (final page in event.pages) {
          expect(page.body.nodes, hasLength(1));
          final node = page.body.nodes.single as SourceCenterServiceProgramNode;
          expect(node.rawDataRef.contentHash,
              source.archive.files[node.rawDataRef.fileId]!.contentHash);
          expect(node.toJson()['nativeExecutionQualified'], isFalse);
          expect(node.toJson()['fullSourceServiceParityQualified'], isFalse);
          expect(node.toJson()['sourceScriptsExecuted'], 0);
        }
      }
    });

    test(
        'nurse choice exposes party heal, checkpoint and exact source responses',
        () {
      final node = analysis.eventAt(102, 2)!.pages.first.body.nodes.single
          as SourceCenterServiceProgramNode;
      expect(node.nativeOperation, SourceCenterNativeOperation.healParty);
      expect(node.sourceHealingOpcode, 314);
      expect(node.choiceLabels, ['Yes', 'No']);
      expect(node.cancelType, 2);
      expect(node.setsHealingCheckpoint, isTrue);
      expect(
          node.requiredGameplayBindings,
          containsAll([
            'nativeHealEntireParty',
            'nativeHealingCheckpoint',
            'healOnlyAfterYes'
          ]));
      expect(node.refusalLines, [r'\rWe hope to see you again!']);
      expect(node.completionLines,
          contains(r"\rWe've restored your Pokémon to full health."));
      expect(node.recoveryMusicName,
          'FRLG Misc - Pokemon Recovery (Pokemon Recovery)');
      expect(node.recoveryMusicVolume, 100);
      expect(node.adaptedSourceEffects,
          contains('sourcePokerusBranchAndSeenSwitch'));
    });

    test('nurse recovery and PC retain different native service contracts', () {
      final recovery = analysis.eventAt(102, 2)!.pages.last.body.nodes.single
          as SourceCenterServiceProgramNode;
      expect(recovery.clearsStartingOver, isTrue);
      expect(recovery.setsHealingCheckpoint, isFalse);
      expect(recovery.requiresAcceptance, isFalse);
      for (final page in analysis.eventAt(102, 3)!.pages) {
        final pc = page.body.nodes.single as SourceCenterServiceProgramNode;
        expect(pc.nativeOperation, SourceCenterNativeOperation.openPc);
        expect(pc.sourceHealingOpcode, isNull);
        expect(pc.recoveryMusicName, isNull);
        expect(pc.requiredGameplayBindings,
            ['nativePcService', 'collapseSourcePcSelfSwitchCycle']);
      }
    });

    test('an unqualified profile does not recognize native center programs',
        () {
      final rejected = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source,
                  scriptsArchiveHash: Sha256Hash('0' * 64),
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      for (final eventId in [2, 3]) {
        expect(rejected.eventAt(102, eventId)!.isQuarantined, isTrue);
        expect(
            rejected
                .eventAt(102, eventId)!
                .pages
                .expand((page) => page.body.nodes)
                .whereType<SourceCenterServiceProgramNode>(),
            isEmpty);
      }
    });

    test('truncated normalized partner page cannot keep a complete PC witness',
        () {
      final original = source.maps.single;
      final json =
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>;
      final pc = (json['map']['events'] as List)
          .cast<Map>()
          .singleWhere((event) => event['sourceEventId'] == 3);
      (pc['pages'] as List).cast<Map>().last['commands'] = <Object?>[];
      final changed = SourceMapIr.fromJson(json)
          .map
          .events
          .singleWhere((event) => event.sourceEventId == 3);
      final program = analysis.eventAt(102, 3)!.pages.first.body.nodes.single
          as SourceCenterServiceProgramNode;
      final profile = SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
);
      expect(
          program.isBoundToSourceEvent(
              source: source,
              profile: profile,
              sourceMapId: 102,
              event: original.map.events
                  .singleWhere((event) => event.sourceEventId == 3)),
          isTrue);
      expect(
          program.isBoundToSourceEvent(
              source: source,
              profile: profile,
              sourceMapId: 102,
              event: changed),
          isFalse);
    });

    for (final mutation in [
      ('pbPokeCenterPC', 'pbPokeCenterPC;unqualified_call()', 3),
      ('pbSetPokemonCenter', 'pbSetPokemonCenter;unqualified_call()', 2),
      (r'$stats.poke_center_count += 1', r'$stats.poke_center_count += 2', 2),
      ('get_character(4).pattern = 0', 'get_character(5).pattern = 0', 2),
      (
        'FRLG Misc - Pokemon Recovery (Pokemon Recovery)',
        'Different recovery ME',
        2
      ),
    ]) {
      test('changed source service refuses the complete event: ${mutation.$1}',
          () async {
        final changed =
            await _source(archive!, before: mutation.$1, after: mutation.$2);
        final result = SourceEventAnalyzer.forProject(changed,
                profile: SourceEventProfile.forProject(changed,
interpretationProfile: fixtureSourceInterpretationProfile,
))
            .analyze();
        final event = result.eventAt(102, mutation.$3)!;
        expect(event.isQuarantined, isTrue);
        expect(
            event.pages
                .expand((page) => page.body.nodes)
                .whereType<SourceCenterServiceProgramNode>(),
            isEmpty);
      });
    }
  }, skip: archive == null);
}
