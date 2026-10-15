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
  group('original self-trade source program', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    setUpAll(() async {
      source = await _source(archive!);
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
    });
    test('the complete guard page becomes one typed inert native trade program',
        () {
      final event = analysis.eventAt(102, 7)!;
      expect(event.isQuarantined, false);
      expect(event.pages.single.body.nodes, hasLength(1));
      expect(event.pages.single.body.nodes.single.runtimeType.toString(),
          'SourcePartyTradeProgramNode');
    });
    test(
        'the typed program retains source text and explicit native adaptations',
        () {
      final node = analysis.eventAt(102, 7)!.pages.single.body.nodes.single
          as SourcePartyTradeProgramNode;
      expect(node.greetingLines.map((line) => line.text), [
        r"\rI'm sorry, but the Pokémon Center 2F is closed.",
        r"\rIf you're looking to trade Pokémon, I can assist you.",
      ]);
      expect(node.refusalLine.text, r'\rWe hope you have a wonderful day!');
      expect(node.sourceFacingDirection, 4);
      expect(node.choiceLabels, ['YES', 'NO']);
      expect(node.cancelType, 2);
      expect(node.span.firstCommandIndex, 0);
      expect(node.span.lastCommandIndex, 29);
      expect(node.toJson()['sourceScriptsExecuted'], 0);
      expect(node.toJson()['nativeExecutionQualified'], false);
      expect(node.toJson()['adaptedSourceEffects'],
          containsPair('partyNegativeIndexOnCancel', 'cancelWithoutMutation'));
    });
    test('raw event identity and complete normalized page are both mandatory',
        () {
      final ir = source.maps.single;
      final original =
          ir.map.events.singleWhere((event) => event.sourceEventId == 7);
      final node = analysis.eventAt(102, 7)!.pages.single.body.nodes.single
          as SourcePartyTradeProgramNode;
      bool bound(SourceEvent event) => node.isBoundToSourceEvent(
          source: source,
          profile: analysis.profile,
          sourceMapId: 102,
          event: event);
      expect(bound(original), true);
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (event) => event['x'] = 4,
        (event) => event['y'] = 9,
        (event) => event['name'] = 'different guard',
        (event) => (event['pages'] as List).single['rawDataRef'] = null,
        (event) => (event['pages'] as List).single['conditionsDataRef'] = null,
        (event) => (event['pages'] as List).single['triggerCode'] = 3,
        (event) =>
            ((event['pages'] as List).single['commands'] as List).removeLast(),
        (event) => ((event['pages'] as List).single['commands'] as List)[0]
            ['parameters'] = [6, -1, 2],
        (event) => ((event['pages'] as List).single['commands'] as List)[0]
            ['indent'] = 1,
        (event) => ((event['pages'] as List).single['commands'] as List)[0]
            ['code'] = 355,
      ]) {
        final json =
            jsonDecode(jsonEncode(ir.toJson())) as Map<String, dynamic>;
        final event = (json['map']['events'] as List)
            .cast<Map<String, dynamic>>()
            .singleWhere((event) => event['sourceEventId'] == 7);
        mutate(event);
        final forged = SourceMapIr.fromJson(json)
            .map
            .events
            .singleWhere((event) => event.sourceEventId == 7);
        expect(bound(forged), false);
      }
    });
    test('an unqualified source profile refuses the entire guard', () {
      final result = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source,
                  scriptsArchiveHash: Sha256Hash('0' * 64)))
          .analyze();
      expect(result.eventAt(102, 7)!.isQuarantined, true);
    });
    for (final mutation in [
      (
        'pbStartTradeYourself(pkmn1,pkmn2)',
        'pbStartTradeYourself(pkmn1,pkmn2); unknown_call'
      ),
      ('pbChoosePokemon(2,3)', 'pbChoosePokemon(2,4)'),
      (
        'pbStartTradeYourself(pkmn1,pkmn1)',
        'pbStartTradeYourself(pkmn2,pkmn1)'
      ),
    ]) {
      test(
          'unknown or changed source trade refuses the whole guard: ${mutation.$1}',
          () async {
        final changed =
            await _source(archive!, before: mutation.$1, after: mutation.$2);
        final result = SourceEventAnalyzer.forProject(changed,
                profile: SourceEventProfile.kantoForProject(changed))
            .analyze();
        expect(result.eventAt(102, 7)!.isQuarantined, true);
      });
    }
  }, skip: archive == null ? 'Original source archive required.' : false);
}
