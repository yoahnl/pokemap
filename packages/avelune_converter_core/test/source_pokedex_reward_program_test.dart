import 'dart:convert';
import 'dart:io';

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
  group('original Everstone reward program', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    setUpAll(() async {
      source = await _source(archive!);
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
    });
    test('complete two-page source reward has one typed program per page', () {
      final event = analysis.eventAt(102, 10)!;
      expect(event.isQuarantined, isFalse);
      for (final page in event.pages) {
        expect(page.body.nodes, hasLength(1));
        expect(page.body.nodes.single.runtimeType.toString(),
            'SourcePokedexRewardProgramNode');
      }
    });

    test(
        'offer retains exact source count, controls, choices and item operation',
        () {
      final node = analysis.eventAt(102, 10)!.pages.first.body.nodes.single
          as SourcePokedexRewardProgramNode;
      expect(node.kind, SourcePokedexRewardProgramKind.offer);
      expect(node.sourceDexIndex, 1);
      expect(node.minimumCount, 20);
      expect(node.sourceSeenVariableId, 1);
      expect(node.sourceOwnedVariableId, 2);
      expect(node.choiceLabels, ['YES', 'NO']);
      expect(node.cancelType, 2);
      expect(node.texts(SourcePokedexRewardTextGroup.greeting), hasLength(6));
      expect(node.texts(SourcePokedexRewardTextGroup.greeting).first.text,
          contains(r'\PN'));
      expect(node.texts(SourcePokedexRewardTextGroup.eligible).first.text,
          contains(r'\v[2]'));
      expect(node.pickup!.sourceSymbol, 'EVERSTONE');
      expect(node.pickup!.quantity, 1);
      expect(node.pickup!.span.firstCommandIndex, 18);
      expect(node.rewardFactId, endsWith(':map:102:event:10:self:A'));
    });
    test(
        'post-reward page contains only the source explanation and facing contract',
        () {
      final node = analysis.eventAt(102, 10)!.pages.last.body.nodes.single
          as SourcePokedexRewardProgramNode;
      expect(node.kind, SourcePokedexRewardProgramKind.afterReward);
      expect(
          node.texts(SourcePokedexRewardTextGroup.explanation), hasLength(4));
      expect(node.texts(SourcePokedexRewardTextGroup.greeting), isEmpty);
      expect(node.pickup, isNull);
      expect(node.choiceLabels, isEmpty);
      expect(node.cancelType, isNull);
    });
    test('program binds both raw pages without qualifying native execution',
        () {
      final original = source.maps.single.map.events
          .singleWhere((event) => event.sourceEventId == 10);
      for (final page in analysis.eventAt(102, 10)!.pages) {
        final node = page.body.nodes.single as SourcePokedexRewardProgramNode;
        expect(
            node.isBoundToSourceEvent(
                source: source,
                profile: analysis.profile,
                sourceMapId: 102,
                event: original),
            isTrue);
        expect(node.sourcePageRefs, hasLength(2));
        expect(node.toJson()['sourceScriptsExecuted'], 0);
        expect(node.toJson()['nativeExecutionQualified'], isFalse);
        expect(node.toJson()['fullSourceRewardParityQualified'], isFalse);
        expect(() => node.textGroups.clear(), throwsUnsupportedError);
      }
    });
    for (final suffix in ['2))', '1)); unknown_call']) {
      test(
          'changed dex expression or unknown suffix $suffix refuses both pages',
          () async {
        final changed = await _source(archive!,
            before: r'pbSet(2,$player.pokedex.owned_count(1))',
            after: r'pbSet(2,$player.pokedex.owned_count(' + suffix);
        final rejected = SourceEventAnalyzer.forProject(changed,
                profile: SourceEventProfile.kantoForProject(changed))
            .analyze()
            .eventAt(102, 10)!;
        expect(rejected.isQuarantined, isTrue);
        expect(
            rejected.pages
                .expand((page) => page.body.nodes)
                .whereType<SourcePokedexRewardProgramNode>(),
            isEmpty);
      });
    }
    test('wrong script archive cannot admit the reward program', () {
      final rejected = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source,
                  scriptsArchiveHash: Sha256Hash('0' * 64)))
          .analyze()
          .eventAt(102, 10)!;
      expect(rejected.isQuarantined, isTrue);
      expect(
          rejected.pages
              .expand((page) => page.body.nodes)
              .whereType<SourcePokedexRewardProgramNode>(),
          isEmpty);
    });
  }, skip: archive == null);
}
