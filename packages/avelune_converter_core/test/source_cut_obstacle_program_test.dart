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
    for (final row in frozen['archive']['files'])
      ConverterId(row['entry']['fileId'] as String):
          base64Decode(row['rawBytes'] as String)
  };
  final map = (input['entries'] as List)
      .cast<Map>()
      .singleWhere((row) => row['relativePath'] == 'Data/Map098.rxdata');
  final mapId = ConverterId(map['fileId'] as String);
  if (before != null) {
    bytes[mapId] = _replaceLiteral(bytes[mapId]!, before, after!);
  }
  final changed = before != null;
  final snapshot = SourceSnapshot(
      logicalProjectNamespace:
          ConverterId(input['logicalProjectNamespace'] as String),
      policyHash: Sha256Hash(input['policyHash'] as String),
      entries: [
        for (final row in input['entries'])
          SourceFileEntry(
              fileId: ConverterId(row['fileId'] as String),
              relativePath: row['relativePath'] as String,
              kind: SourceNodeKind.values.byName(row['kind'] as String),
              byteLength: row['fileId'] == mapId.value && changed
                  ? bytes[mapId]!.length
                  : row['byteLength'] as int,
              sha256: row['sha256'] == null
                  ? null
                  : Sha256Hash(row['fileId'] == mapId.value && changed
                      ? crypto.sha256.convert(bytes[mapId]!).toString()
                      : row['sha256'] as String),
              format: row['format'] as String,
              family: row['family'] as String)
      ],
      diagnostics: [],
      excludedPaths: (input['excludedPaths'] as List).cast<String>(),
      profileEvidence: [
        for (final row in input['profileEvidence'])
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
      selectedMapIds: {98, 100},
      includeEventSystem: true);
}

const _trees = [(98, 3), (100, 2), (100, 3), (100, 4), (100, 5)];

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  group('closed original Cut obstacle programmes', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    setUpAll(() async {
      source = await _source(archive!);
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
    });
    test('all five exact source trees become typed closed programmes', () {
      for (final key in _trees) {
        final event = analysis.eventAt(key.$1, key.$2)!;
        expect(event.isQuarantined, isFalse);
        final node = event.pages.single.body.nodes.single
            as SourceFieldObstacleProgramNode;
        expect(node.sourceMove, 'CUT');
        expect(node.span.firstCommandIndex, 0);
        expect(node.span.lastCommandIndex, 6);
        expect(node.toJson()['sourceScriptsExecuted'], 0);
        expect(node.toJson()['nativeExecutionQualified'], isFalse);
        expect(node.toJson()['fullSourceFieldObstacleParityQualified'], isFalse);
        final original = source.maps
            .singleWhere((m) => m.map.sourceMapId == key.$1)
            .map
            .events
            .singleWhere((e) => e.sourceEventId == key.$2);
        expect(
            node.isBoundToSourceEvent(
                source: source,
                profile: analysis.profile,
                sourceMapId: key.$1,
                event: original),
            isTrue);
      }
    });
    test('an unqualified script profile cannot recognize Cut programmes', () {
      final rejected = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source,
                  scriptsArchiveHash: Sha256Hash('0' * 64)))
          .analyze();
      for (final key in _trees) {
        expect(rejected.eventAt(key.$1, key.$2)!.isQuarantined, isTrue);
        expect(
            rejected
                .eventAt(key.$1, key.$2)!
                .pages
                .single
                .body
                .nodes
                .whereType<SourceFieldObstacleProgramNode>(),
            isEmpty);
      }
    });
    for (final mode in [
      'truncate',
      'code',
      'indent',
      'script',
      'trigger',
      'conditionRef',
      'position',
      'name'
    ]) {
      test('raw IR binding refuses changed $mode', () {
        final original =
            source.maps.singleWhere((m) => m.map.sourceMapId == 98);
        final json =
            jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>;
        final event = (json['map']['events'] as List)
            .cast<Map>()
            .singleWhere((e) => e['sourceEventId'] == 3);
        final page = (event['pages'] as List).single as Map;
        final commands = page['commands'] as List;
        switch (mode) {
          case 'truncate':
            commands.removeLast();
          case 'code':
            (commands[3] as Map)['code'] = 101;
          case 'indent':
            (commands[3] as Map)['indent'] = 0;
          case 'script':
            (commands[3] as Map)['parameters'] = ['pbSmashThisEvent;extra'];
          case 'trigger':
            page['triggerCode'] = 1;
          case 'conditionRef':
            page['conditionsDataRef'] = page['rawDataRef'];
          case 'position':
            event['x'] = 3;
          case 'name':
            event['name'] = 'CutTree extra';
        }
        final changed = SourceMapIr.fromJson(json)
            .map
            .events
            .singleWhere((e) => e.sourceEventId == 3);
        final node = analysis.eventAt(98, 3)!.pages.single.body.nodes.single
            as SourceFieldObstacleProgramNode;
        expect(
            node.isBoundToSourceEvent(
                source: source,
                profile: analysis.profile,
                sourceMapId: 98,
                event: changed),
            isFalse);
      });
    }
    for (final mutation in [
      ('pbCut', 'pbCut;evil'),
      ('pbSmashThisEvent', 'pbSmashThisEvent;evil')
    ]) {
      test('changed raw source suffix ${mutation.$1} is never accepted',
          () async {
        final changed =
            await _source(archive!, before: mutation.$1, after: mutation.$2);
        final result = SourceEventAnalyzer.forProject(changed,
                profile: SourceEventProfile.kantoForProject(changed))
            .analyze();
        expect(result.eventAt(98, 3)!.isQuarantined, isTrue);
        expect(
            result
                .eventAt(98, 3)!
                .pages
                .single
                .body
                .nodes
                .whereType<SourceFieldObstacleProgramNode>(),
            isEmpty);
      });
    }
  }, skip: archive == null);
}
