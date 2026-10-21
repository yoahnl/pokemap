import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';
import 'support/interpretation_profile_fixture.dart';
import 'support/source_external_original_fixture.dart';
import 'support/trainer_program_fixture.dart';

void main() {
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
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: fixture.source.snapshot,
        files: _TrainerFiles(fixture.files),
        selectedMapIds: {98},
        includeEventSystem: true,
        interpretationProfile: externalOracleInterpretationProfile());
    final analysis = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze();
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
  }, skip: !enabled);
}

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
