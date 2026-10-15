import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

const _trainerKeys = {
  'FRLG_BUGCATCHER,Brent',
  'FRLG_BUGCATCHER,Conner',
  'FRLG_HIKER,Jeremy',
  'FRLG_HIKER,Alan',
  'FRLG_HIKER,Brice',
  'FRLG_PICNICKER,Alicia',
  'FRLG_PICNICKER,Caitlin',
  'FRLG_CAMPER,Chris',
  'FRLG_CAMPER,Drew',
  'FRLG_PICNICKER,Heidi',
  'FRLG_POKEMANIAC,Mark',
};

final class _SourceFiles implements SourceFilePort {
  const _SourceFiles(this.bytes);
  final List<int> bytes;
  @override
  Future<List<int>> read(ConverterId id) async => bytes;
}

Future<void> main(List<String> args) async {
  if (args.length != 4) {
    throw ArgumentError(
        'Expected PSDK root, source trainers PBS, JSON output, Dart output.');
  }
  final root = await Directory(args[0]).resolveSymbolicLinks();
  final trainersBytes = await File(args[1]).readAsBytes();
  final trainerFile = SourceFileEntry(
      fileId: ConverterId('source-native-trainer-recipe'),
      relativePath: 'PBS/trainers.txt',
      kind: SourceNodeKind.file,
      byteLength: trainersBytes.length,
      sha256: Sha256Hash(crypto.sha256.convert(trainersBytes).toString()),
      format: 'pbs',
      family: 'pbs');
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: ConverterId('kanto-native-trainer-recipe'),
      policyHash: SourceScanPolicy().canonicalHash,
      entries: [trainerFile],
      diagnostics: [],
      excludedPaths: [],
      profileEvidence: [],
      state: SourceScanState.complete);
  final pbs = await const SourcePbsParser().read(
      snapshot: snapshot,
      files: _SourceFiles(trainersBytes),
      families: const {SourcePbsFamily.trainers});
  final trainers = pbs.entries
      .where((entry) =>
          _trainerKeys.contains(
              '${entry.identity?.trainerType},${entry.identity?.trainerName}') &&
          entry.identity?.version == 0)
      .toList();
  if (trainers.length != _trainerKeys.length ||
      trainers.any((entry) => entry.isBlocked)) {
    throw StateError('The exact eleven source trainers are required.');
  }
  final levels = <String, Set<int>>{};
  for (final trainer in trainers) {
    for (final member in trainer.party) {
      if (member.fields.isNotEmpty || member.headerField.values.length != 2) {
        throw StateError('Unexpected source party overrides.');
      }
      final tokens = member.headerField.values;
      levels
          .putIfAbsent(tokens.first.toLowerCase(), () => {})
          .add(int.parse(tokens.last));
    }
  }
  final sourceFiles = <String, NativePsdkTrainerSourceFile>{};
  Future<Map<String, dynamic>> read(String path) async {
    final file = File('$root/$path');
    final resolved = await file.resolveSymbolicLinks();
    if (!resolved.startsWith('$root/')) {
      throw StateError('Reference escaped its root.');
    }
    final bytes = await file.readAsBytes();
    sourceFiles[path] = NativePsdkTrainerSourceFile(
        relativePath: path,
        sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
        bytes: bytes);
    return (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>();
  }

  final moves = <String>{};
  final abilities = <String>{};
  final species = levels.keys.toSet();
  final queue = levels.keys.toList()..sort();
  for (var cursor = 0; cursor < queue.length; cursor++) {
    if (queue.length > 64) {
      throw StateError('Native species closure exceeds its limit.');
    }
    final id = queue[cursor];
    final raw = await read('Data/Studio/pokemon/$id.json');
    for (final form in (raw['forms'] as List).cast<Map>()) {
      abilities.addAll((form['abilities'] as List).cast<String>());
      moves.addAll((form['moveSet'] as List)
          .cast<Map>()
          .map((move) => move['move'] as String));
      final targets = <String>[
        for (final evolution in (form['evolutions'] as List).cast<Map>())
          (evolution['dbSymbol'] ?? id) as String,
        if (form['babyDbSymbol'] case final String baby) baby,
      ];
      for (final target in targets) {
        if (target != 'none' && target != '__undef__' && species.add(target)) {
          queue.add(target);
        }
      }
      if (form['form'] != 0) {
        for (final side in ['front', 'back']) {
          final path =
              "graphics/pokedex/poke$side/${(form['resources'] as Map)[side]}.png";
          final file = File('$root/$path');
          if (!(await file.resolveSymbolicLinks()).startsWith('$root/')) {
            throw StateError('Reference escaped its root.');
          }
          final bytes = await file.readAsBytes();
          sourceFiles[path] = NativePsdkTrainerSourceFile(
              relativePath: path,
              sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
              bytes: bytes);
        }
      }
    }
  }
  for (final id in moves.toList()..sort()) {
    await read('Data/Studio/moves/$id.json');
  }
  for (final id in nativeTrainerTypeIds.toList()..sort()) {
    await read('Data/Studio/types/$id.json');
  }
  for (final id in abilities.toList()..sort()) {
    await read('Data/Studio/abilities/$id.json');
  }
  await read('Data/Studio/natures/hardy.json');
  final bundle = const NativePsdkTrainerBundleBuilder()
      .build(files: sourceFiles.values.toList(), requestedLevels: levels);
  final json = bundle.toJson();
  json['evidence'] = {
    ...bundle.evidence,
    'sourceRosterFile': trainerFile.toJson(),
    'sourceTrainerKeys': _trainerKeys.toList()..sort(),
    'sourceTrainerRosters': {
      for (final trainer in trainers)
        '${trainer.identity!.trainerType},${trainer.identity!.trainerName}': [
          for (final member in trainer.party)
            {
              'sourceSpeciesSymbol': member.headerField.values.first,
              'level': int.parse(member.headerField.values.last)
            }
        ]
    },
    'sourceRosterLocators': [
      for (final trainer in trainers) trainer.headerLocator.toJson()
    ],
  };
  final contents = '${const JsonEncoder.withIndent('  ').convert(json)}\n';
  if (contents.contains("'''")) {
    throw StateError('Invalid embedded JSON literal.');
  }
  for (final path in [args[2], args[3]]) {
    await File(path).parent.create(recursive: true);
  }
  await File(args[2]).writeAsString(contents);
  await File(args[3])
      .writeAsString("const nativePsdkTrainerBundleJson = r'''$contents''';\n");
  stdout.writeln(jsonEncode({
    'trainers': trainers.length,
    'members':
        trainers.fold<int>(0, (sum, trainer) => sum + trainer.party.length),
    'species': bundle.speciesById.length,
    'moves': bundle.movesById.length,
    'types': bundle.catalogs['types']!.entries.length,
    'abilities': bundle.catalogs['abilities']!.entries.length,
    'sources': sourceFiles.length,
    'bundleHash': canonicalHashOf(json).value,
    'sourceScriptsExecuted': 0,
  }));
}
