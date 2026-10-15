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
  group('original Town Map source program', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    setUpAll(() async {
      source = await _source(archive!);
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
    });
    test('complete wall map page becomes one typed inert program', () {
      final event = analysis.eventAt(102, 6)!;
      expect(event.isQuarantined, false);
      expect(event.pages.single.body.nodes, hasLength(1));
      expect(event.pages.single.body.nodes.single.runtimeType.toString(),
          'SourceTownMapProgramNode');
    });
    test(
        'typed wall-map program preserves raw page, text and deferred native qualification',
        () {
      final event = analysis.eventAt(102, 6)!;
      final node =
          event.pages.single.body.nodes.single as SourceTownMapProgramNode;
      expect(node.text.text, 'A Town Map.');
      expect(node.span.firstCommandIndex, 0);
      expect(node.span.lastCommandIndex, 2);
      expect(node.toJson()['nativeExecutionQualified'], false);
      expect(node.toJson()['sourceScriptsExecuted'], 0);
      expect(node.rawDataRef.locator!.pageIndex, 0);
      final original = source.maps
          .singleWhere((map) => map.map.sourceMapId == 102)
          .map
          .events
          .singleWhere((event) => event.sourceEventId == 6);
      expect(
          node.isBoundToSourceEvent(
              source: source,
              profile: analysis.profile,
              sourceMapId: 102,
              event: original),
          true);
    });
    test('unknown script suffix refuses the entire original wall map',
        () async {
      final changed = await _source(archive!,
          before: 'pbShowMap', after: 'pbShowMap; unknown_call');
      final result = SourceEventAnalyzer.forProject(changed,
              profile: SourceEventProfile.kantoForProject(changed))
          .analyze();
      expect(result.eventAt(102, 6)!.isQuarantined, true);
    });
  }, skip: archive == null ? 'Original source archive required.' : false);
}
