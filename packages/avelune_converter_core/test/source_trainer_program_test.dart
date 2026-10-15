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
    {String? before,
    String? after,
    int? branchParameter,
    int? parameterValue}) async {
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
  if (branchParameter != null) {
    final document = const MarshalDecoder().decode(bytes[mapId]!);
    int field(int node, String key) => document
        .node(node)
        .instanceVariables
        .singleWhere((pair) => document.node(pair.key).name == key)
        .value;
    final commands = document.node(field(687, '@list')).elements;
    final parameter = document
        .node(field(commands[6], '@parameters'))
        .elements[branchParameter];
    final offset = document.node(parameter).location.byteOffset;
    if (bytes[mapId]![offset] != 0x69 ||
        parameterValue == null ||
        parameterValue < 0 ||
        parameterValue >= 123) {
      throw StateError('Fixture requires a small Marshal integer');
    }
    bytes[mapId] = [...bytes[mapId]!];
    bytes[mapId]![offset + 1] = parameterValue == 0 ? 0 : parameterValue + 5;
  }
  final changed = before != null || branchParameter != null;
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

const _trainerIds = [
  (98, 1),
  (98, 2),
  (98, 6),
  (98, 7),
  (98, 8),
  (98, 9),
  (98, 10),
  (98, 11),
  (98, 12),
  (100, 11),
  (100, 12),
];

SourceTrainerProgramNode _program(SourceEventPageAnalysis page) {
  expect(page.body.nodes, hasLength(1));
  final node = page.body.nodes.single;
  expect(node, isA<SourceTrainerProgramNode>());
  return node as SourceTrainerProgramNode;
}

void _expectRejected(SourceEventAnalysis analysis, int mapId, int eventId) {
  final event = analysis.eventAt(mapId, eventId)!;
  expect(event.isQuarantined, isTrue);
  expect(
      event.pages.expand((page) => page.body.nodes).where(
          (node) => node.runtimeType.toString() == 'SourceTrainerProgramNode'),
      isEmpty);
}

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  group('original trainer programs', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    setUpAll(() async {
      source = await _source(archive!);
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
    });

    for (final id in _trainerIds) {
      test('recognizes complete source program ${id.$1}:${id.$2}', () {
        final event = analysis.eventAt(id.$1, id.$2)!;
        expect(event.isQuarantined, isFalse);
        expect(event.pages, hasLength(2));
        for (final page in event.pages) {
          final node = _program(page);
          expect(node.trainerVersion, 0);
          expect(
              node.isBoundToSourceEvent(
                  source: source,
                  profile: analysis.profile,
                  sourceMapId: id.$1,
                  event: source.maps
                      .singleWhere((map) => map.map.sourceMapId == id.$1)
                      .map
                      .events
                      .singleWhere(
                          (candidate) => candidate.sourceEventId == id.$2)),
              isTrue);
          expect(node.defeatedFactId,
              'source:source-semantic-study:map:${id.$1}:event:${id.$2}:self:A');
          expect(node.rawDataRef.contentHash,
              source.archive.files[node.rawDataRef.fileId]!.contentHash);
          final evidence = node.toJson() as Map;
          expect(evidence['sourceProgramRecognized'], isTrue);
          expect(evidence['nativeExecutionQualified'], isFalse);
          expect(evidence['sourceScriptsExecuted'], 0);
          expect(evidence['sourceEndSpeechCommentRuntimeDialogue'], isFalse);
          expect(evidence['sourceDefeatedCondition'], 'battleOutcomeEquals1');
        }
      });
    }

    test('retains source message boundaries and post-win facing order', () {
      final brent = analysis.eventAt(98, 1)!;
      final encounter = _program(brent.pages.first);
      final after = _program(brent.pages.last);
      expect(encounter.kind.name, 'encounter');
      expect(encounter.trainerType, 'FRLG_BUGCATCHER');
      expect(encounter.trainerName, 'Brent');
      expect(encounter.detectionDistance, 2);
      expect(encounter.challengeLines,
          [r'\bI got up early every day to raise\nmy Pokémon from cocoons!']);
      expect(encounter.endSpeechComment,
          r'EndSpeech: WHAT?\nWhat a total waste of time!');
      expect(after.kind.name, 'afterWin');
      expect(after.afterWinLines,
          [r'\bI have to collect more than bugs\nto get stronger...']);
      expect(after.facesPlayerAfterDialogue, isTrue);
      final heidi = _program(analysis.eventAt(100, 11)!.pages.first);
      expect(heidi.challengeLines, [
        r"\rI've been out at a Pokémon Gym\na few times.",
        r'\r...But I always lose.',
      ]);
      final postHeidi = _program(analysis.eventAt(100, 11)!.pages.last);
      expect(postHeidi.afterWinLines, [
        r'\rI noticed some Pokémaniacs\nprowling around.',
        r'\rCan you imagine? Them?\nUp here in the mountains?',
      ]);
      expect(() => encounter.challengeLines.clear(), throwsUnsupportedError);
    });

    test('typed program binding rejects forged normalized pages', () {
      final node = _program(analysis.eventAt(98, 1)!.pages.first);
      final map = source.maps.singleWhere((map) => map.map.sourceMapId == 98);
      for (final variant in [
        'emptyCommands',
        'script',
        'selfSwitch',
        'trigger',
        'rawReference',
        'conditionReference',
        'reorderedPages'
      ]) {
        final json =
            jsonDecode(jsonEncode(map.toJson())) as Map<String, dynamic>;
        final event = (json['map']['events'] as List)
            .cast<Map>()
            .singleWhere((event) => event['sourceEventId'] == 1);
        final pages = event['pages'] as List;
        final commands = pages[0]['commands'] as List;
        switch (variant) {
          case 'emptyCommands':
            pages[0]['commands'] = <Object?>[];
          case 'script':
            commands[0]['parameters'] = ['pbTrainerIntro(:UNKNOWN)'];
          case 'selfSwitch':
            commands[6]['parameters'] = ['A', 1];
          case 'trigger':
            pages[0]['triggerCode'] = 0;
          case 'rawReference':
            pages[0]['rawDataRef'] = pages[1]['rawDataRef'];
          case 'conditionReference':
            pages[0]['conditionsDataRef'] = null;
          case 'reorderedPages':
            event['pages'] = pages.reversed.toList();
        }
        final forged = SourceMapIr.fromJson(json)
            .map
            .events
            .singleWhere((event) => event.sourceEventId == 1);
        expect(
            node.isBoundToSourceEvent(
                source: source,
                profile: analysis.profile,
                sourceMapId: 98,
                event: forged),
            isFalse,
            reason: variant);
      }
    });

    test('recognition does not qualify source sight approach or patrol', () {
      final brice = _program(analysis.eventAt(98, 8)!.pages.first);
      expect(brice.sourceTriggerCode, 2);
      expect(
          brice.requiredGameplayBindings,
          containsAll([
            'nativeTrainerBattleOutcome',
            'sourceTrainerSightAndApproach',
            'sourceTrainerLockAndUnlock',
            'sourceAutonomousMovement',
          ]));
      final brent = _program(analysis.eventAt(98, 1)!.pages.first);
      expect(brent.requiredGameplayBindings,
          isNot(contains('sourceAutonomousMovement')));
    });

    test('unqualified and mismatched profiles cannot recognize trainers', () {
      for (final profile in [
        SourceEventProfile.kantoForProject(source,
            scriptsArchiveHash: Sha256Hash('0' * 64)),
        SourceEventProfile.kanto(
            scriptsArchiveHash:
                Sha256Hash(SourceEventProfile.kantoScriptsArchiveSha256),
            sourceSnapshotHash: Sha256Hash('0' * 64),
            normalizationHash: source.canonicalHash),
      ]) {
        final result =
            SourceEventAnalyzer.forProject(source, profile: profile).analyze();
        for (final id in _trainerIds) {
          _expectRejected(result, id.$1, id.$2);
        }
      }
    });

    for (final mutation in [
      (
        'pbTrainerIntro(:FRLG_BUGCATCHER)',
        'pbTrainerIntro(:FRLG_BUGCATCHER);unknown()'
      ),
      ('pbNoticePlayer(get_self)', 'pbNoticePlayer(get_self);unknown()'),
      (
        'TrainerBattle.start(:FRLG_BUGCATCHER, "Brent")',
        'TrainerBattle.start(:FRLG_BUGCATCHER, "Brent");unknown()'
      ),
      ('pbTrainerEnd', 'pbTrainerEnd;unknown()'),
      (r'EndSpeech: WHAT?\nWhat a total waste of time!', 'EndSpeech: changed'),
      (
        r'\bI have to collect more than bugs\nto get stronger...',
        'Changed post-battle text'
      ),
    ]) {
      test('changed trainer program is refused: ${mutation.$1}', () async {
        final changed =
            await _source(archive!, before: mutation.$1, after: mutation.$2);
        final result = SourceEventAnalyzer.forProject(changed,
                profile: SourceEventProfile.kantoForProject(changed))
            .analyze();
        final rejected = _trainerIds
            .where((id) => result.eventAt(id.$1, id.$2)!.isQuarantined);
        expect(rejected, isNotEmpty);
        for (final id in rejected) {
          _expectRejected(result, id.$1, id.$2);
        }
      });
    }

    test('self A off cannot masquerade as the proved win-only assignment',
        () async {
      final changed =
          await _source(archive!, branchParameter: 1, parameterValue: 1);
      final result = SourceEventAnalyzer.forProject(changed,
              profile: SourceEventProfile.kantoForProject(changed))
          .analyze();
      _expectRejected(result, 98, 1);
    });
  }, skip: archive == null);
}
