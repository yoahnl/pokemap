import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_gameplay/map_gameplay.dart';

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
  final generic = args.isNotEmpty && args.first == '--catalog-requests';
  final paths = generic ? args.sublist(1) : args;
  if (paths.length != 4) {
    throw ArgumentError('Expected [--catalog-requests] PSDK root, '
        'request JSON or source trainers PBS, JSON output, Dart output.');
  }
  final root = await Directory(paths[0]).resolveSymbolicLinks();
  final input = File(paths[1]);
  if (await input.length() > (generic ? 262144 : 16777216)) {
    throw StateError('Native catalog recipe input exceeds its limit.');
  }
  final inputBytes = await input.readAsBytes();
  SourceFileEntry? trainerFile;
  final trainers = <SourcePbsEntry>[];
  final requests = <NativePsdkCatalogRequest>[];
  if (generic) {
    final raw = jsonDecode(utf8.decode(inputBytes));
    if (raw is! Map<String, dynamic> ||
        raw['kind'] != 'nativePsdkCatalogRequests' ||
        raw['version'] != 1 ||
        raw.keys.any(
            (key) => !const {'kind', 'version', 'requests'}.contains(key)) ||
        raw['requests'] is! List ||
        (raw['requests'] as List).isEmpty ||
        (raw['requests'] as List).length > 256) {
      throw StateError(
          'An exact bounded native catalog request recipe is required.');
    }
    for (final request in raw['requests'] as List) {
      if (request is! Map<String, dynamic>) {
        throw StateError('A native catalog request must be an object.');
      }
      requests.add(NativePsdkCatalogRequest.fromJson(request));
    }
  } else {
    trainerFile = SourceFileEntry(
        fileId: ConverterId('source-native-trainer-recipe'),
        relativePath: 'PBS/trainers.txt',
        kind: SourceNodeKind.file,
        byteLength: inputBytes.length,
        sha256: Sha256Hash(crypto.sha256.convert(inputBytes).toString()),
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
        files: _SourceFiles(inputBytes),
        families: const {SourcePbsFamily.trainers});
    trainers.addAll(pbs.entries.where((entry) =>
        _trainerKeys.contains(
            '${entry.identity?.trainerType},${entry.identity?.trainerName}') &&
        entry.identity?.version == 0));
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
    requests.addAll([
      for (final entry in levels.entries)
        for (final level in entry.value)
          NativePsdkCatalogRequest(baseId: entry.key, form: 0, level: level)
    ]);
  }
  if (requests.map((r) => r.baseId).toSet().length > 64) {
    throw StateError('Native requested species exceed their limit.');
  }
  final sourceFiles = <String, NativePsdkTrainerSourceFile>{};
  var totalBytes = 0;
  Future<List<int>> readBytes(String path) async {
    if (!RegExp(
            r'^(Data/Studio/[a-z_]+/[a-z0-9_]+\.json|graphics/pokedex/poke(front|back)/[a-z0-9_]+\.png)$')
        .hasMatch(path)) {
      throw StateError('Invalid native source path.');
    }
    final previous = sourceFiles[path];
    if (previous != null) return previous.bytes;
    if (sourceFiles.length >= 2048) {
      throw StateError('Native source count exceeds its limit.');
    }
    final file = File('$root/$path');
    final resolved = await file.resolveSymbolicLinks();
    if (!resolved.startsWith('$root/')) {
      throw StateError('Reference escaped its root.');
    }
    final length = await file.length();
    if (length > 1048576 || totalBytes + length > 16777216) {
      throw StateError('Native source bytes exceed their limit.');
    }
    final bytes = await file.readAsBytes();
    totalBytes += bytes.length;
    sourceFiles[path] = NativePsdkTrainerSourceFile(
        relativePath: path,
        sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
        bytes: bytes);
    return bytes;
  }

  Future<Map<String, dynamic>> read(String path) async =>
      (jsonDecode(utf8.decode(await readBytes(path))) as Map)
          .cast<String, dynamic>();

  final moves = {
    ...nativeQualifiedFieldMoveSourceHashes.keys,
    for (final request in requests) ...?request.explicitMoveIds
  };
  final abilities = <String>{};
  final species = requests.map((r) => r.baseId).toSet();
  final queue = species.toList()..sort();
  var formCount = 0;
  for (var cursor = 0; cursor < queue.length; cursor++) {
    if (queue.length > 64) {
      throw StateError('Native species closure exceeds its limit.');
    }
    final id = queue[cursor];
    final raw = await read('Data/Studio/pokemon/$id.json');
    final forms = (raw['forms'] as List).cast<Map>();
    formCount += forms.length;
    if (formCount > 128) {
      throw StateError('Native form count exceeds its limit.');
    }
    for (final form in forms) {
      abilities.addAll((form['abilities'] as List).cast<String>());
      moves.addAll((form['moveSet'] as List)
          .cast<Map>()
          .map((move) => move['move'] as String));
      for (final rule in (form['evolutions'] as List).cast<Map>()) {
        for (final condition in (rule['conditions'] as List).cast<Map>()) {
          if (condition['type'] == 'skill1') {
            moves.add(condition['value'] as String);
          }
        }
      }
      if (moves.length > 512) {
        throw StateError('Native move count exceeds its limit.');
      }
      final targets = <String>[
        for (final evolution in (form['evolutions'] as List).cast<Map>())
          (evolution['dbSymbol'] ?? id) as String,
        if (form['babyDbSymbol'] case final String baby) baby,
      ];
      for (final target in targets) {
        if (target != 'none' && target != '__undef__' && species.add(target)) {
          if (species.length > 64) {
            throw StateError('Native species closure exceeds its limit.');
          }
          queue.add(target);
        }
      }
      if (form['form'] != 0) {
        for (final side in ['front', 'back']) {
          final path =
              "graphics/pokedex/poke$side/${(form['resources'] as Map)[side]}.png";
          await readBytes(path);
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
  for (final id in canonicalPokemonNatureIds.toList()..sort()) {
    await read('Data/Studio/natures/$id.json');
  }
  final bundle = const NativePsdkTrainerBundleBuilder()
      .build(files: sourceFiles.values.toList(), requests: requests);
  final json = bundle.toJson();
  if (trainerFile != null) {
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
  }
  final contents = '${const JsonEncoder.withIndent('  ').convert(json)}\n';
  if (contents.contains("'''")) {
    throw StateError('Invalid embedded JSON literal.');
  }
  for (final path in [paths[2], paths[3]]) {
    await File(path).parent.create(recursive: true);
  }
  await File(paths[2]).writeAsString(contents);
  await File(paths[3])
      .writeAsString("const nativePsdkTrainerBundleJson = r'''$contents''';\n");
  stdout.writeln(jsonEncode({
    'trainers': trainers.length,
    'members':
        trainers.fold<int>(0, (sum, trainer) => sum + trainer.party.length),
    'species': bundle.speciesById.length,
    'moves': bundle.movesById.length,
    'types': bundle.catalogs['types']!.entries.length,
    'abilities': bundle.catalogs['abilities']!.entries.length,
    'natures': bundle.catalogs['natures']!.entries.length,
    'sources': sourceFiles.length,
    'bundleHash': canonicalHashOf(json).value,
    'sourceScriptsExecuted': 0,
  }));
}
