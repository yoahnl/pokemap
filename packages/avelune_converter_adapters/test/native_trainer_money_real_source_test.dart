import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_trainer_money_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

void main() {
  final sourceRoot = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final profile = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  final project = Platform.environment['AVELUNE_TRAINER_MONEY_PROJECT'];
  final export = Platform.environment['AVELUNE_TRAINER_MONEY_EXPORT'];
  test(
      'existing Kanto trainers retain their teams and acquire source prize money',
      () async {
    final fixture = await readExternalOriginalSource(sourceRoot!, snapshot!,
        selectedMapIds: const {62},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((value) => value.isNotEmpty)
                .toList());
    final pbs = await const SourcePbsParser().read(
        snapshot: fixture.source.snapshot,
        files: fixture.files,
        families: const {
          SourcePbsFamily.trainers,
          SourcePbsFamily.trainerTypes
        });
    final witness = await NativeTrainerMoneyWitness.read(
        snapshot: fixture.source.snapshot, files: fixture.files);
    final manifest = ProjectManifest.fromJson(
        jsonDecode(await File('$project/project.json').readAsString()));
    final sourceTrainers = {
      for (final entry in pbs.entries.where((entry) =>
          entry.family == SourcePbsFamily.trainers && entry.identity != null))
        entry.identity!.sourceId.value: entry,
    };
    final rows = <Map<String, Object?>>[];
    final updates = <Map<String, Object?>>[];
    for (final trainer in manifest.trainers) {
      final roster = sourceTrainers[trainer.id];
      if (roster == null) continue;
      final binding = NativeTrainerMoneyBinding.fromPbs(
          source: pbs,
          roster: roster,
          team: trainer.team,
          compiledWitness: witness);
      final updated = trainer.copyWith(moneyReward: binding.amount);
      expect(updated.copyWith(moneyReward: trainer.moneyReward), trainer);
      rows.add({
        'trainerId': trainer.id,
        'trainerName': trainer.name,
        'beforeMoneyReward': trainer.moneyReward,
        'afterMoneyReward': binding.amount,
        'proof': binding.evidence,
      });
      if (updated != trainer) {
        updates.add({
          'beforeHash': canonicalHashOf(trainer.toJson()).value,
          'value': updated.toJson(),
        });
      }
    }
    expect(rows, isNotEmpty);
    expect(
        rows.singleWhere(
            (row) => row['trainerName'] == 'Brock')['afterMoneyReward'],
        1400);
    expect(
        rows.singleWhere(
            (row) => row['trainerName'] == 'Blaine')['afterMoneyReward'],
        4700);
    if (export != null) {
      expect(File(export).isAbsolute, isTrue);
      await File(export).writeAsString(jsonEncode({
        'kind': 'sourceTrainerPrizeTargetedUpdates',
        'sourceSnapshotHash': fixture.source.snapshot.canonicalHash.value,
        'projectPath': project,
        'nativeTrainerCount': manifest.trainers.length,
        'sourceTrainerCount': rows.length,
        'updates': updates,
        'rows': rows,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'battleRulesModified': false,
        'mapsModified': 0,
      }));
    }
    stdout.writeln(jsonEncode({
      'qualifiedTrainers': rows.length,
      'prizeUpdates': updates.length,
      'exportPath': export,
    }));
  },
      timeout: const Timeout(Duration(minutes: 4)),
      skip: sourceRoot == null ||
              snapshot == null ||
              profile == null ||
              project == null
          ? 'Requires exact external Kanto source, profile, snapshot and project.'
          : false);
}
