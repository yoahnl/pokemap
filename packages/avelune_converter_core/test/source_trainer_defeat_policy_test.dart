import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';
import 'support/interpretation_profile_fixture.dart';
import 'support/source_external_original_fixture.dart';
import 'support/trainer_program_fixture.dart';

void main() {
  for (final variable in [
    'AVELUNE_BUILTIN_JOHTO_SCRIPTS',
    'AVELUNE_BUILTIN_HOENN_SCRIPTS'
  ]) {
    final scriptsPath = Platform.environment[variable];
    group('trainer defeat engine witnesses $variable', () {
      late List<int> scripts;
      late SourceInterpretationProfile profile;
      setUpAll(() async {
        scripts = await File(scriptsPath!).readAsBytes();
        profile = _engineProfile(scripts);
      });
      test('attests the same loss policy for an independently bound archive',
          () async {
        final source = await trainerSource(
            scriptsBytes: scripts, interpretationProfile: profile);
        final analysis = SourceEventAnalyzer.forProject(source,
                profile: SourceEventProfile.forProject(source))
            .analyze();
        final event = analysis.eventAt(417, 23)!;
        expect(event.isQuarantined, isFalse);
        for (final program in event.pages
            .expand((page) => page.body.nodes)
            .whereType<SourceTrainerProgramNode>()) {
          expect(program.defeatPolicy, isNotNull);
          expect(program.defeatPolicy!.canLose, isFalse);
          expect(program.defeatPolicy!.scriptsArchiveHash,
              profile.scriptsArchiveHash);
          expect(program.defeatPolicy!.toJson()['oracleSections'],
              [for (final section in profile.sections.values) section]);
        }
      });
      for (final role in [
        'events.Battle',
        'events.Overworld_BattleStarting'
      ]) {
        test('does not infer defeat semantics without $role', () async {
          final sections = {...profile.sections}..remove(role);
          final incomplete = SourceInterpretationProfile.fromJson({
            ...profile.toJson(),
            'sections': sections,
          });
          final source = await trainerSource(
              scriptsBytes: scripts, interpretationProfile: incomplete);
          final event = SourceEventAnalyzer.forProject(source,
                  profile: SourceEventProfile.forProject(source))
              .analyze()
              .eventAt(417, 23)!;
          final programs = event.pages
              .expand((page) => page.body.nodes)
              .whereType<SourceTrainerProgramNode>();
          expect(programs, isNotEmpty);
          expect(programs.map((program) => program.defeatPolicy),
              everyElement(isNull));
        });
        test('normalization rejects altered bytes declared for $role',
            () async {
          final altered = SourceInterpretationProfile.fromJson({
            ...profile.toJson(),
            'sections': {
              ...profile.sections,
              role: {...profile.sections[role]!, 'sha256': '0' * 64},
            },
          });
          await expectLater(
              trainerSource(
                  scriptsBytes: scripts, interpretationProfile: altered),
              throwsA(isA<ContractError>().having((error) => error.code,
                  'code', 'interpretation_profile.section_mismatch')));
        });
      }
      test('rejects a forged profile or a different source archive', () async {
        final source = await trainerSource(
            scriptsBytes: scripts, interpretationProfile: profile);
        final forged = SourceInterpretationProfile.fromJson({
          ...profile.toJson(),
          'profileId': 'forged-loss-policy-profile',
        });
        final forgedEvent = SourceEventAnalyzer.forProject(source,
                profile: SourceEventProfile.forProject(source,
                    interpretationProfile: forged))
            .analyze()
            .eventAt(417, 23)!;
        final programs = forgedEvent.pages
            .expand((page) => page.body.nodes)
            .whereType<SourceTrainerProgramNode>();
        expect(programs, isNotEmpty);
        expect(programs.map((program) => program.defeatPolicy),
            everyElement(isNull));
        final mismatched = SourceEventAnalyzer.forProject(source,
                profile: SourceEventProfile.forProject(source,
                    scriptsArchiveHash: Sha256Hash('0' * 64)))
            .analyze()
            .eventAt(417, 23)!;
        expect(mismatched.isQuarantined, isTrue);
        expect(
            mismatched.pages
                .expand((page) => page.body.nodes)
                .whereType<SourceTrainerProgramNode>(),
            isEmpty);
      });
    }, skip: scriptsPath == null ? '$variable is required' : false);
  }

  test(
      'an otherwise recognized trainer does not invent a loss policy for an unattested engine',
      () async {
    final source = await trainerSource();
    final event = analyzeTrainerSource(source).eventAt(417, 23)!;
    expect(event.isQuarantined, isFalse);
    for (final page in event.pages) {
      final program = page.body.nodes.single as SourceTrainerProgramNode;
      expect(program.defeatPolicy, isNull);
      expect(program.toJson().containsKey('defeatPolicy'), isFalse);
    }
  });
  for (final rule in [
    'setBattleRule("canLose")',
    'setBattleRule(variable_rule)',
    'unknown_battle_setup()'
  ]) {
    test('custom or explicit loss setup stays quarantined: $rule', () async {
      final source = await trainerSource(mutate: (pages) {
        (pages.first.fields['@list'] as List)
            .insert(0, trainerCommand(355, [rule]));
      });
      final event = analyzeTrainerSource(source).eventAt(417, 23)!;
      expect(event.isQuarantined, isTrue);
      expect(
          event.pages
              .expand((page) => page.body.nodes)
              .whereType<SourceTrainerProgramNode>(),
          isEmpty);
    });
  }
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final enabled = root != null &&
      snapshot != null &&
      Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'] != null;
  test(
      'original trainer archive attests loss recovery independently of native battle rules',
      () async {
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {98});
    final declared = externalOracleInterpretationProfile();
    final verifiedProfile = SourceInterpretationProfile.fromJson({
      ...declared.toJson(),
      'sections': {...declared.sections, ..._engineSections},
    });
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: fixture.source.snapshot,
        files: _TrainerFiles(fixture.files),
        selectedMapIds: {98},
        includeEventSystem: true,
        interpretationProfile: verifiedProfile);
    final profile = SourceEventProfile.forProject(source);
    final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
    final analysis = analyzer.analyze();
    Sha256Hash programHash(SourceEventAnalysis value) => canonicalHashOf([
      value.profile.toJson(),
      for (final event in value.events)
        [event.identity.value,
          for (final page in event.pages)
            for (final node in page.body.nodes.whereType<SourceTrainerProgramNode>())
              node.toJson()],
    ]);
    final program = analysis.eventAt(98, 1)!.pages.first.body.nodes.single
        as SourceTrainerProgramNode;
    expect(program.defeatPolicy, isNotNull);
    expect(program.defeatPolicy!.canLose, isFalse);
    final json = program.defeatPolicy!.toJson();
    expect(json['scriptsArchiveHash'],
        '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d');
    expect(json['nativeDefeatRecovery'], 'returnToRecoveryPoint');
    expect(json['sourceScriptsExecuted'], 0);
    expect(
        program.isBoundToSourceEvent(
            source: source,
            profile: analysis.profile,
            sourceMapId: 98,
            event: source.maps.single.map.events
                .singleWhere((event) => event.sourceEventId == 1)),
        isTrue);
    final policies = analysis.eventAt(98, 1)!.pages
        .expand((page) => page.body.nodes)
        .whereType<SourceTrainerProgramNode>()
        .map((node) => node.defeatPolicy)
        .toList();
    expect(policies.length, greaterThanOrEqualTo(2));
    expect(policies, everyElement(same(program.defeatPolicy)));
    final repeated = analyzer.analyze();
    expect(programHash(repeated), programHash(analysis));
    expect(repeated.eventAt(98, 1)!.pages.first.body.nodes
        .whereType<SourceTrainerProgramNode>().single.defeatPolicy,
        same(program.defeatPolicy));
    final otherAnalyzer = SourceEventAnalyzer.forProject(source, profile: profile);
    final separatelyOwned = otherAnalyzer.analyze();
    expect(programHash(separatelyOwned), programHash(analysis));
    expect(separatelyOwned.eventAt(98, 1)!.pages.first.body.nodes
        .whereType<SourceTrainerProgramNode>().single.defeatPolicy,
        same(program.defeatPolicy));
    for (final (index, rejected) in [
      SourceEventProfile(
          sourceSnapshotHash: Sha256Hash('0' * 64),
          normalizationHash: profile.normalizationHash,
          scriptsArchiveHash: profile.scriptsArchiveHash,
          interpretationProfile: profile.interpretationProfile),
      SourceEventProfile(
          sourceSnapshotHash: profile.sourceSnapshotHash,
          normalizationHash: Sha256Hash('0' * 64),
          scriptsArchiveHash: profile.scriptsArchiveHash,
          interpretationProfile: profile.interpretationProfile),
      SourceEventProfile(
          sourceSnapshotHash: profile.sourceSnapshotHash,
          normalizationHash: profile.normalizationHash,
          scriptsArchiveHash: Sha256Hash('0' * 64),
          interpretationProfile: profile.interpretationProfile),
      SourceEventProfile.forProject(source,
          interpretationProfile: SourceInterpretationProfile.fromJson({
            ...source.interpretationProfile!.toJson(),
            'profileId': 'altered-trainer-policy-profile',
          })),
    ].indexed) {
      final rejectedAnalyzer = SourceEventAnalyzer.forProject(source,
          profile: rejected);
      for (var repeat = 0; repeat < 2; repeat++) {
        final rejectedAnalysis = rejectedAnalyzer.analyze();
        final rejectedEvent = rejectedAnalysis.eventAt(98, 1)!;
        final rejectedNodes = rejectedEvent.pages
            .expand((page) => page.body.nodes)
            .whereType<SourceTrainerProgramNode>()
            .toList();
        if (index < 3) {
          expect(rejectedEvent.isQuarantined, isTrue);
          expect(rejectedNodes, isEmpty);
        } else {
          expect(rejectedEvent.isQuarantined, isFalse);
          expect(rejectedNodes, hasLength(policies.length));
          expect(rejectedNodes.map((node) => node.defeatPolicy),
              everyElement(isNull));
        }
      }
    }
  }, skip: !enabled);
}

SourceInterpretationProfile _engineProfile(List<int> scripts) =>
    SourceInterpretationProfile.fromJson({
      'kind': 'sourceInterpretationProfile',
      'schemaVersion': 2,
      'profileId': 'attested-trainer-defeat-engine',
      'semanticsId': 'rmxp-essentials-static-v1',
      'scriptsArchive': {
        'relativePath': 'Data/Scripts.rxdata',
        'sha256': crypto.sha256.convert(scripts).toString(),
      },
      'capabilities': ['events'],
      'sections': _engineSections,
    });

const _engineSections = {
  'events.Battle': {
    'index': 147,
    'name': 'Battle',
    'sha256':
        'd61fd2ce22cc27e9d9682c14ced068dca544f39921af9b1acaa18c9022325c5b',
    'lines': [131, 134],
  },
  'events.Overworld_BattleStarting': {
    'index': 256,
    'name': 'Overworld_BattleStarting',
    'sha256':
        '7a0e305aad2f7939254b9e322bb86ee592e2da338b114cdec2a74e4cb1ff4b04',
    'lines': [492, 527],
  },
};

final class _TrainerFiles implements SourceFilePort {
  const _TrainerFiles(this.primary);
  final ExternalOriginalFiles primary;
  @override
  Future<List<int>> read(ConverterId id) async {
    if (primary.overrideBytes.containsKey(primary.snapshot.entries
        .singleWhere((e) => e.fileId == id)
        .relativePath)) {
      return primary.read(id);
    }
    final entry = primary.snapshot.entries.singleWhere((e) => e.fileId == id);
    for (final root in [
      primary.root,
      ...(Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ?? '')
          .split('|')
          .where((v) => v.isNotEmpty)
    ]) {
      final file = File('$root/${entry.relativePath}');
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      if (bytes.length == entry.byteLength &&
          crypto.sha256.convert(bytes).toString() == entry.sha256?.value) {
        return bytes;
      }
    }
    return primary.read(id);
  }
}
