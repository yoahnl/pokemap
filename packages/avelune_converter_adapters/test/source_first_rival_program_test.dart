import 'dart:io';
import 'dart:convert';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_first_rival_binding.dart';
import 'package:test/test.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'support/source_external_original_fixture.dart';
import 'support/literal_tile_fixture.dart';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

Object? _literal(Object? value) => switch (value) {
      Map() => LiteralFixtureObject(value['__class__'] as String, {
          for (final e in value.entries)
            if (e.key != '__class__') '@${e.key}': _literal(e.value)
        }),
      List() => value.map(_literal).toList(),
      _ => value,
    };

Future<LiteralTileFixture> _mutant(NormalizedSourceProject source,
    ExternalOriginalFiles files, Map raw, void Function(Map) mutate) async {
  final changed = jsonDecode(jsonEncode(raw)) as Map;
  mutate(changed);
  final scripts = source.snapshot.entries
      .singleWhere((e) => e.relativePath == 'Data/Scripts.rxdata');
  final pages = <LiteralFixtureEventPage>[];
  for (final p in changed['pages'] as List) {
    final commands = <LiteralFixtureEventCommand>[];
    final list = p['list'] as List;
    for (final c in list) {
      commands.add(LiteralFixtureEventCommand(
          c['code'] as int, (c['parameters'] as List).map(_literal).toList(),
          indent: c['indent'] as int));
    }
    pages.add(LiteralFixtureEventPage(
        globalSwitch: p['condition']['switch1_valid'] == true
            ? p['condition']['switch1_id'] as int
            : null,
        selfSwitch: p['condition']['self_switch_valid'] == true
            ? p['condition']['self_switch_ch'] as String
            : null,
        variableId: p['condition']['variable_valid'] == true
            ? p['condition']['variable_id'] as int
            : null,
        variableThreshold: p['condition']['variable_value'] as int,
        trigger: p['trigger'] as int,
        through: p['through'] as bool,
        commands: commands));
  }
  final event = LiteralFixtureEvent(
      id: changed['id'] as int,
      x: changed['x'] as int,
      y: changed['y'] as int,
      name: changed['name'] as String,
      pages: pages);
  return LiteralTileFixture.create(
      interpretationProfile: externalOracleInterpretationProfile(),
      scriptsBytes: await files.read(scripts.fileId),
      includeEventSystem: true,
      switchNames: [
        null,
        for (var i = 1; i <= 75; i++) 'Switch $i'
      ],
      variableNames: [
        null,
        for (var i = 1; i <= 29; i++) 'Variable $i'
      ],
      maps: [
        LiteralFixtureMap(id: 9, width: 20, height: 20, layers: [
          List.filled(400, 384),
          List.filled(400, 0),
          List.filled(400, 0)
        ], events: [
          event
        ])
      ]);
}

final class _PbsOverlayFiles implements SourceFilePort {
  const _PbsOverlayFiles(this.original, this.fileId, this.bytes);
  final SourceFilePort original;
  final ConverterId fileId;
  final List<int> bytes;

  @override
  Future<List<int>> read(ConverterId id) =>
      id == fileId ? Future.value(bytes) : original.read(id);
}

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  test(
      'closed first rival preserves all nine source roster branches and lane-specific loss exits',
      () async {
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {9},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((v) => v.isNotEmpty)
                .toList());
    final source = fixture.source;
    final profile = SourceEventProfile.forProject(source);
    final map = source.maps.single.map;
    final analysis =
        SourceEventAnalyzer.forProject(source, profile: profile).analyze();
    final native = await const SourceFirstRivalBindingResolver()
        .read(source: source, analysis: analysis, files: fixture.files);
    expect(native.refusals, isEmpty,
        reason:
            '${native.qualification?.refusals.map((r) => r.toJson()).toList()}');
    expect(native.byEventIdentity, hasLength(3));

    for (final id in [2, 3, 9]) {
      final original = map.events.singleWhere((e) => e.sourceEventId == id);
      final program = SourceFirstRivalProgram.read(
          source: source, profile: profile, sourceMapId: 9, event: original);
      expect(program, isNotNull,
          reason: 'source9/$id ${original.pages.map((p) => p.commands.where((c) => !const {
                101,
                401,
                509
              }.contains(c.code)).map((c) => "${c.code}:${c.indent}").join(","))}');
      expect(program!.choiceVariableId, 29);
      final ownedPrograms = analysis.eventAt(9, id)!.pages
          .expand((page) => page.body.nodes)
          .whereType<SourceFirstRivalProgramNode>()
          .map((node) => node.program)
          .toList();
      expect(ownedPrograms, hasLength(2));
      for (final owned in ownedPrograms) {
        expect(owned.programHash, program.programHash);
        expect(canonicalHashOf(owned.toJson()), canonicalHashOf(program.toJson()));
      }
      expect(SourceFirstRivalProgram.read(source: source,
          profile: SourceEventProfile(
              scriptsArchiveHash: profile.scriptsArchiveHash,
              sourceSnapshotHash: Sha256Hash('0' * 64),
              normalizationHash: profile.normalizationHash,
              interpretationProfile: profile.interpretationProfile),
          sourceMapId: 9, event: original), isNull);
      expect(program.offerSwitchId, 75);
      expect(
          program.battles.map((b) => b.starterValue), orderedEquals([1, 2, 3]));
      expect(program.battles.map((b) => b.trainerVersion),
          orderedEquals(id == 9 ? [1, 2, 0] : [0, 1, 2]));
      expect(
          program.battles.every((b) => b.lossExitsEvent == (id == 3)), isTrue);
      expect(
          program.isBoundTo(source: source, profile: profile, event: original),
          isTrue);
      expect(program.toJson()['sourceScriptsExecuted'], 0);
      expect(program.toJson()['sourceTemporalAudioParity'], isFalse);
      final malformed = [
        (Map e) {
          e['pages'][1]['list'][17]
              ['parameters'] = ['setBattleRule("cannotLose")'];
        },
        (Map e) {
          final c = (e['pages'][1]['list'] as List)
              .firstWhere((c) => c['code'] == 111 && c['indent'] == 1);
          c['parameters'] = [
            12,
            'TrainerBattle.start(:FRLG_RIVAL1, "Blue", 7)'
          ];
        },
        (Map e) {
          e['pages'][1]['condition']['variable_value'] = 2;
        },
        (Map e) {
          e['pages'][1]['list'].insert(18, {
            '__class__': 'RPG::EventCommand',
            'code': 314,
            'indent': 0,
            'parameters': [0]
          });
        },
        (Map e) {
          final c = (e['pages'][1]['list'] as List).firstWhere((c) =>
              c['code'] == 355 &&
              c['parameters'][0].startsWith('pbSetSelfSwitch'));
          c['parameters'] = ['pbSetSelfSwitch(1,"A",false)'];
        },
      ];
      final control = await _mutant(source, fixture.files, program.raw, (_) {});
      expect(
          SourceFirstRivalProgram.read(
              source: control.source,
              profile: SourceEventProfile.forProject(control.source),
              sourceMapId: 9,
              event: control.source.maps.single.map.events.single),
          isNotNull,
          reason: 'Positive control for the exact same inert mutation fixture');
      for (final mutate in malformed) {
        final f = await _mutant(source, fixture.files, program.raw, mutate);
        expect(
            SourceFirstRivalProgram.read(
                source: f.source,
                profile: SourceEventProfile.forProject(f.source),
                sourceMapId: 9,
                event: f.source.maps.single.map.events.single),
            isNull);
      }
    }
    expect(
        SourceFirstRivalProgram.read(
            source: source,
            profile: profile,
            sourceMapId: 9,
            event: map.events.singleWhere((e) => e.sourceEventId == 1)),
        isNull);
  },
      skip: root == null || snapshot == null
          ? 'Requires explicit original source root and snapshot'
          : false);
  test('missing source rival LoseText refuses every dependent controller',
      () async {
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {9},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((v) => v.isNotEmpty)
                .toList());
    final original = fixture.source.snapshot;
    final entry = original.entries
        .singleWhere((entry) => entry.relativePath == 'PBS/trainers.txt');
    final text = utf8.decode(await fixture.files.read(entry.fileId));
    final section = RegExp(r'\[FRLG_RIVAL1,Blue\]\r?\nLoseText[^\r\n]*\r?\n');
    expect(section.allMatches(text), hasLength(1));
    final bytes = utf8.encode(
        text.replaceFirstMapped(section, (match) => '[FRLG_RIVAL1,Blue]\r\n'));
    final changed = SourceSnapshot(
        logicalProjectNamespace: original.logicalProjectNamespace,
        policyHash: original.policyHash,
        entries: [
          for (final row in original.entries)
            if (row.fileId != entry.fileId)
              row
            else
              SourceFileEntry(
                  fileId: row.fileId,
                  relativePath: row.relativePath,
                  kind: row.kind,
                  byteLength: bytes.length,
                  sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
                  format: row.format,
                  family: row.family)
        ],
        diagnostics: original.diagnostics,
        excludedPaths: original.excludedPaths,
        profileEvidence: original.profileEvidence,
        state: original.state);
    final files = _PbsOverlayFiles(fixture.files, entry.fileId, bytes);
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: changed,
        files: files,
        interpretationProfile: externalOracleInterpretationProfile(),
        selectedMapIds: {9},
        includeEventSystem: true,
        includeConnections: true);
    final analysis = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze();
    final bindings = await const SourceFirstRivalBindingResolver()
        .read(source: source, analysis: analysis, files: files);
    expect(bindings.byEventIdentity, isEmpty);
    expect(bindings.refusals, hasLength(3));
    expect(bindings.refusals.values, everyElement('events.first_rival.speech'));
  },
      skip: root == null || snapshot == null
          ? 'Requires explicit original source root and snapshot'
          : false);
  test('source rival binding and speech remain identical to frozen Lab export',
      () async {
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {9},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((v) => v.isNotEmpty)
                .toList());
    final analysis = SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source))
        .analyze();
    final bindings = await const SourceFirstRivalBindingResolver()
        .read(source: fixture.source, analysis: analysis, files: fixture.files);
    expect(bindings.refusals, isEmpty);
    expect(bindings.byEventIdentity, hasLength(3));
    final frozen = jsonDecode(
        await File(Platform.environment['AVELUNE_FIRST_RIVAL_FROZEN_BUNDLE']!)
            .readAsString()) as Map;
    expect(frozen['sourceSnapshotHash'],
        fixture.source.snapshot.canonicalHash.value);
    final rows = (frozen['projection']['events'] as List).cast<Map>();
    for (final binding in bindings.byEventIdentity.values) {
      final row = rows.singleWhere((row) =>
          row['locator']['mapId'] == 9 &&
          row['locator']['eventId'] == binding.program.sourceEventId);
      expect(binding.toJson(), equals(row['nativeFirstRival']));
      expect(
          binding.loseTexts,
          equals({
            for (final version in [0, 1, 2])
              version: 'WHAT? Unbelievable! I picked the wrong Pokémon!'
          }));
      for (final speech in binding.loseTexts.values) {
        expect(jsonEncode(frozen['dialogueSources']), contains(speech));
      }
    }
  },
      skip: root == null ||
              snapshot == null ||
              Platform.environment['AVELUNE_FIRST_RIVAL_FROZEN_BUNDLE'] == null
          ? 'Requires explicit original source and frozen Lab export'
          : false);
  test('closed rival native write closure retains every possible source switch',
      () async {
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {9},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((v) => v.isNotEmpty)
                .toList());
    final source = fixture.source;
    final profile = SourceEventProfile.forProject(source);
    final dormancy =
        auditSourceParallelDormancy(source: source, profile: profile);
    final nativeWrites =
        (dormancy.toJson()['nativeWriteSet'] as List).cast<Map>();
    expect(
        dormancy.refusals.where((r) => const {
              'sourceDormancyWriterUnqualified:9:2',
              'sourceDormancyWriterUnqualified:9:3',
              'sourceDormancyWriterUnqualified:9:9'
            }.contains(r)),
        isEmpty);
    for (final id in [2, 3, 9]) {
      final written = nativeWrites
          .where((w) => w['sourceMapId'] == 9 && w['sourceEventId'] == id);
      final writerIds = written.map((w) => w['factId']).toSet();
      expect(
          writerIds,
          equals({
            for (final target in [1, 2, 3, 9, 17, 18, 19])
              SourceEventAnalyzer.forProject(source, profile: profile)
                  .selfFactId(9, target, 'A')
          }));
      expect(written.every((w) => w['value'] == true), isTrue);
      expect(
          writerIds,
          contains(SourceEventAnalyzer.forProject(source, profile: profile)
              .selfFactId(9, id, 'A')));
    }
  },
      skip: root == null || snapshot == null
          ? 'Requires explicit original source root and snapshot'
          : false);
}
