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
  group('closed original healing display program', () {
    late NormalizedSourceProject source;
    late SourceEventProfile profile;
    late SourceEvent event;
    setUpAll(() async {
      source = await _source(archive!);
      profile = SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
);
      event = source.maps
          .singleWhere((map) => map.map.sourceMapId == 102)
          .map
          .events
          .singleWhere((event) => event.sourceEventId == 4);
    });
    test('seven exact source pages resolve one closed visual program', () {
      final program = resolveSourceHealingDisplayProgram(
          source: source, profile: profile, sourceMapId: 102, event: event);
      expect(program, isNotNull);
      expect(program!.pages, hasLength(7));
      expect(program.sourceVariableId, 6);
      expect(program.nativeExecutionQualified, isFalse);
      expect(
          program.isBoundToSourceEvent(
              source: source, profile: profile, sourceMapId: 102, event: event),
          isTrue);
      expect(() => program.pages.clear(), throwsUnsupportedError);
    });
    for (final mode in [
      'truncatePages',
      'duplicatePage',
      'pageIndex',
      'trigger',
      'truncateCommands',
      'suffix',
      'code',
      'indent',
      'parameters',
      'conditionRef',
      'position',
      'name'
    ]) {
      test('closed display rejects changed IR $mode', () {
        final ir = source.maps.singleWhere((map) => map.map.sourceMapId == 102);
        final json =
            jsonDecode(jsonEncode(ir.toJson())) as Map<String, dynamic>;
        final row = (json['map']['events'] as List)
            .cast<Map>()
            .singleWhere((row) => row['sourceEventId'] == 4);
        final pages = row['pages'] as List;
        final page = pages[1] as Map;
        final commands = page['commands'] as List;
        switch (mode) {
          case 'truncatePages':
            pages.removeLast();
          case 'duplicatePage':
            pages[6] = jsonDecode(jsonEncode(pages[5]));
            (pages[6] as Map)['originalPageIndex'] = 6;
            for (final command in (pages[6] as Map)['commands'] as List) {
              ((command as Map)['sourceLocator'] as Map)['pageIndex'] = 6;
            }
          case 'pageIndex':
            page['originalPageIndex'] = 99;
            for (final command in commands) {
              ((command as Map)['sourceLocator'] as Map)['pageIndex'] = 99;
            }
          case 'trigger':
            page['triggerCode'] = 1;
          case 'truncateCommands':
            commands.clear();
          case 'suffix':
            final extra = jsonDecode(jsonEncode(commands.single)) as Map;
            extra['originalIndex'] = 1;
            (extra['sourceLocator'] as Map)['commandIndex'] = 1;
            commands.add(extra);
          case 'code':
            (commands.single as Map)['code'] = 355;
          case 'indent':
            (commands.single as Map)['indent'] = 1;
          case 'parameters':
            (commands.single as Map)['parameters'] = ['evil'];
          case 'conditionRef':
            page['conditionsDataRef'] = page['rawDataRef'];
          case 'position':
            row['x'] = 8;
          case 'name':
            row['name'] = 'Healing balls extra';
        }
        final changed = SourceMapIr.fromJson(json)
            .map
            .events
            .singleWhere((e) => e.sourceEventId == 4);
        expect(
            resolveSourceHealingDisplayProgram(
                source: source,
                profile: profile,
                sourceMapId: 102,
                event: changed),
            isNull);
      });
    }
    test('an unqualified script profile never authorizes a visual program', () {
      final unqualified = SourceEventProfile.forProject(source,
          scriptsArchiveHash: Sha256Hash('0' * 64),
interpretationProfile: fixtureSourceInterpretationProfile,
);
      expect(
          resolveSourceHealingDisplayProgram(
              source: source,
              profile: unqualified,
              sourceMapId: 102,
              event: event),
          isNull);
      expect(
          resolveSourceHealingDisplayProgram(
              source: source, profile: profile, sourceMapId: 100, event: event),
          isNull);
    });
    for (final mutation in [
      ('OBJ_FRLG_Healing1', 'OBJ_FRLG_HealingX'),
      ('get_character(4).pattern = 0', 'get_character(4).pattern = 1')
    ]) {
      test('freshly reattested raw source rejects changed ${mutation.$1}',
          () async {
        final changed =
            await _source(archive!, before: mutation.$1, after: mutation.$2);
        final changedEvent = changed.maps
            .singleWhere((map) => map.map.sourceMapId == 102)
            .map
            .events
            .singleWhere((event) => event.sourceEventId == 4);
        expect(
            resolveSourceHealingDisplayProgram(
                source: changed,
                profile: SourceEventProfile.forProject(changed,
interpretationProfile: fixtureSourceInterpretationProfile,
),
                sourceMapId: 102,
                event: changedEvent),
            isNull);
      });
    }
  }, skip: archive == null);
}
