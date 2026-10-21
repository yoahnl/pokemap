import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';
import 'package:avelune_converter_adapters/src/native_psdk_catalog.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

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
  if (args.isNotEmpty && args.first == '--refresh-targets') {
    await _refreshTargets(args.sublist(1));
    return;
  }
  if (args.isNotEmpty && args.first == '--embed-catalog') {
    await _embedCatalog(args.sublist(1));
    return;
  }
  final sharded = args.isNotEmpty && args.first == '--catalog-shards';
  final generic =
      sharded || (args.isNotEmpty && args.first == '--catalog-requests');
  final paths = generic ? args.sublist(1) : args;
  if (paths.length != 4) {
    throw ArgumentError(
        'Expected [--catalog-requests|--catalog-shards] PSDK root, '
        'recipe, JSON output, Dart output (or shard directory for --catalog-shards).');
  }
  final root = await Directory(paths[0]).resolveSymbolicLinks();
  final input = File(paths[1]);
  if (await input.length() >
      (sharded
          ? 1048576
          : generic
              ? 262144
              : 16777216)) {
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
        (raw['requests'] as List).length > (sharded ? 8192 : 256)) {
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

  if (sharded) {
    final catalog = await const NativePsdkCatalogBuilder().build(
      requests: requests,
      buildShard: (batch) => buildNativePsdkTrainerShard(root, batch),
    );
    for (final entry in catalog.shards.entries) {
      final file = File('${paths[3]}/${entry.key}.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(
          '${canonicalJsonOf(entry.value.toJson(), limits: nativePsdkCatalogShardJsonLimits)}\n');
    }
    final manifest = File(paths[2]);
    await manifest.parent.create(recursive: true);
    await manifest.writeAsString('${canonicalJsonOf(catalog.toJson())}\n');
    stdout.writeln(jsonEncode({
      'shards': catalog.shards.length,
      'requests': requests.length,
      'species': catalog.speciesById.length,
      'moves': catalog.movesById.length,
      'sources': (catalog.evidence['sources'] as List).length,
      'manifestHash': canonicalHashOf(catalog.toJson()).value,
      'runtimeBattleBuilderQualified': false,
      'sourceScriptsExecuted': 0,
      'aiCalls': 0,
    }));
    return;
  }
  final bundle = await buildNativePsdkTrainerShard(root, requests);
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
    'sources': (bundle.evidence['sources'] as List).length,
    'bundleHash': canonicalHashOf(json).value,
    'sourceScriptsExecuted': 0,
  }));
}

NativePsdkTrainerBundle refreshNativePsdkTrainerTargets({
  required NativePsdkTrainerBundle bundle,
  required List<NativePsdkTrainerSourceFile> sources,
}) {
  final witnesses = <String, NativePsdkTrainerSourceFile>{};
  for (final source in sources) {
    if (witnesses.containsKey(source.relativePath)) {
      throw StateError('Duplicate native move witness.');
    }
    witnesses[source.relativePath] = source;
  }
  final provenance = <String, Map>{};
  for (final raw in bundle.evidence['sources'] as List) {
    final row = raw as Map;
    final relative = row['relativePath'] as String;
    if (provenance.containsKey(relative)) {
      throw StateError('Duplicate native source provenance.');
    }
    provenance[relative] = row;
  }
  final document =
      jsonDecode(jsonEncode(bundle.toJson())) as Map<String, dynamic>;
  final catalogs = (document['catalogs'] as List).cast<Map>();
  final catalog = catalogs.singleWhere((row) => row['catalog'] == 'moves');
  final entries = catalog['entries'] as List;
  for (var i = 0; i < entries.length; i++) {
    final raw = Map<String, dynamic>.from(entries[i] as Map);
    final move = PokemonMove.fromJson(raw);
    final relative = 'Data/Studio/moves/${move.id}.json';
    final witness = witnesses.remove(relative);
    final origin = provenance[relative];
    if (witness == null ||
        origin == null ||
        origin['sha256'] != witness.sha256.value ||
        origin['byteLength'] != witness.bytes.length) {
      throw StateError(
          'Native move source does not match pinned provenance: $relative.');
    }
    final original =
        jsonDecode(utf8.decode(witness.bytes)) as Map<String, dynamic>;
    if (original['dbSymbol'] != move.id ||
        (raw['sourceRefs'] as Map?)?['psdkDbSymbol'] != move.id) {
      throw StateError('Native move identity changed: $relative.');
    }
    final projected = const PokemonSdkMoveCatalogConverter().convert({
      for (final key in const [
        'dbSymbol',
        'type',
        'category',
        'power',
        'accuracy',
        'pp',
        'battleEngineMethod'
      ])
        key: original[key],
      'battleEngineAimedTarget': switch (original['battleEngineAimedTarget']) {
        'any_other_pokemon' => 'anyFoe',
        'all_ally' => 'allAllies',
        final value => value,
      },
    });
    if (projected.id != move.id) {
      throw StateError('Projected native move identity changed.');
    }
    entries[i] = {
      ...raw,
      'target': move.copyWith(target: projected.target).target.name
    };
  }
  if (witnesses.isNotEmpty) {
    throw StateError('Unexpected native move source witness.');
  }
  final refreshed = NativePsdkTrainerBundle.fromJson(document);
  Map<String, dynamic> withoutTargets(NativePsdkTrainerBundle value) {
    final stripped =
        jsonDecode(jsonEncode(value.toJson())) as Map<String, dynamic>;
    final moveCatalog = (stripped['catalogs'] as List)
        .cast<Map>()
        .singleWhere((catalog) => catalog['catalog'] == 'moves');
    for (final move in moveCatalog['entries'] as List) {
      (move as Map).remove('target');
    }
    return stripped;
  }

  if (canonicalHashOf(withoutTargets(bundle),
          limits: nativePsdkCatalogShardJsonLimits) !=
      canonicalHashOf(withoutTargets(refreshed),
          limits: nativePsdkCatalogShardJsonLimits)) {
    throw StateError('Target refresh changed unrelated native bundle content.');
  }
  return refreshed;
}

Future<void> _refreshTargets(List<String> paths) async {
  if (paths.length != 4) {
    throw ArgumentError(
        'Expected --refresh-targets PSDK root, pinned bundle, JSON output, Dart output.');
  }
  final root = await Directory(paths[0]).resolveSymbolicLinks();
  final input = File(paths[1]);
  if (await input.length() > 16777216) {
    throw StateError('Pinned native bundle exceeds its input limit.');
  }
  final bundle = NativePsdkTrainerBundle.fromJson(
      jsonDecode(await input.readAsString()) as Map<String, dynamic>);
  final sources = <NativePsdkTrainerSourceFile>[];
  for (final move in bundle.movesById.values) {
    final relative = 'Data/Studio/moves/${move.id}.json';
    if (!RegExp(r'^Data/Studio/moves/[a-z0-9_]+\.json$').hasMatch(relative)) {
      throw StateError('Native source path is invalid.');
    }
    final file = File('$root/$relative');
    final resolved = await file.resolveSymbolicLinks();
    if (!resolved.startsWith('$root/') || await file.length() > 1048576) {
      throw StateError('Native move exceeds its admitted root or input limit.');
    }
    final bytes = await file.readAsBytes();
    sources.add(NativePsdkTrainerSourceFile(
        relativePath: relative,
        sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
        bytes: bytes));
  }
  final refreshed =
      refreshNativePsdkTrainerTargets(bundle: bundle, sources: sources);
  final contents =
      '${const JsonEncoder.withIndent('  ').convert(refreshed.toJson())}\n';
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
    'mode': 'pinnedMoveTargetRefresh',
    'moves': refreshed.movesById.length,
    'changedTargets': [
      for (final move in refreshed.movesById.values)
        if (move.target != bundle.movesById[move.id]!.target) move.id
    ],
    'sourceScriptsExecuted': 0,
    'aiCalls': 0,
  }));
}

Future<void> _embedCatalog(List<String> paths) async {
  if (paths.length != 3) {
    throw ArgumentError(
        'Expected --embed-catalog manifest, shard directory, Dart output.');
  }
  final manifest = File(paths[0]);
  if (await manifest.length() > 65536) {
    throw StateError('Native manifest exceeds its input limit.');
  }
  final raw = jsonDecode(await manifest.readAsString());
  if (raw is! Map<String, dynamic> ||
      raw['shards'] is! List ||
      (raw['shards'] as List).isEmpty ||
      (raw['shards'] as List).length > 128) {
    throw StateError('An exact bounded native catalog manifest is required.');
  }
  final shards = <String, Map<String, Object?>>{};
  var totalBytes = 0;
  final root = await Directory(paths[1]).resolveSymbolicLinks();
  for (final hash in raw['shards'] as List) {
    if (hash is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
      throw StateError('Native shard identity is invalid.');
    }
    final file = File('$root/$hash.json');
    final resolved = await file.resolveSymbolicLinks();
    final size = await file.length();
    totalBytes += size;
    if (!resolved.startsWith('$root/') ||
        size > 33554432 ||
        totalBytes > 134217728) {
      throw StateError(
          'Native catalog exceeds its admitted root or input limit.');
    }
    final shard = jsonDecode(await file.readAsString());
    if (shard is! Map<String, dynamic>) {
      throw StateError('Native shard must be an object.');
    }
    shards[hash] = shard;
  }
  final catalog = NativePsdkCatalogManifest.fromJson(raw, shards: shards);
  String literal(Object? document,
          {ContractLimits limits = const ContractLimits()}) =>
      canonicalJsonOf(document, limits: limits).replaceAll("'", r'\u0027');
  final output = StringBuffer()
    ..writeln(
        "const nativePsdkCatalogManifestHash = '${canonicalHashOf(catalog.toJson()).value}';")
    ..writeln(
        "const nativePsdkCatalogManifestJson = r'''${literal(catalog.toJson())}''';")
    ..writeln('const nativePsdkCatalogShardJson = <String, String>{');
  for (final entry in catalog.shards.entries) {
    output.writeln(
        "'${entry.key}': r'''${literal(entry.value.toJson(), limits: nativePsdkCatalogShardJsonLimits)}''',");
  }
  output.writeln('};');
  final target = File(paths[2]);
  await target.parent.create(recursive: true);
  await target.writeAsString(output.toString());
  stdout.writeln(jsonEncode({
    'manifestHash': canonicalHashOf(catalog.toJson()).value,
    'shards': catalog.shards.length,
    'species': catalog.speciesById.length,
    'moves': catalog.movesById.length,
    'sourceScriptsExecuted': 0,
  }));
}

Future<NativePsdkTrainerBundle> buildNativePsdkTrainerShard(
    String root, List<NativePsdkCatalogRequest> requests) async {
  root = await Directory(root).resolveSymbolicLinks();
  if (requests.map((r) => r.baseId).toSet().length > 64) {
    throw ContractError('native_trainer.requested_base_quota', r'$',
        'Native requested species exceed their limit.');
  }
  final sourceFiles = <String, NativePsdkTrainerSourceFile>{};
  var totalBytes = 0;
  Future<List<int>> readBytes(String path) async {
    if (!RegExp(
            r'^(Data/Studio/[a-z_]+/[a-z0-9_]+\.json|Data/Text/Dialogs/(100000|100067)\.csv|graphics/pokedex/poke(front|back)/[a-z0-9_]+\.png)$')
        .hasMatch(path)) {
      throw StateError('Invalid native source path.');
    }
    final previous = sourceFiles[path];
    if (previous != null) return previous.bytes;
    if (sourceFiles.length >= 2048) {
      throw ContractError('native_trainer.source_file_quota', path,
          'Native source count exceeds its limit.');
    }
    final file = File('$root/$path');
    final resolved = await file.resolveSymbolicLinks();
    if (!resolved.startsWith('$root/')) {
      throw StateError('Reference escaped its root.');
    }
    final length = await file.length();
    if (length > 1048576) {
      throw ContractError('native_trainer.source_witness', path,
          'Native source file exceeds its limit.');
    }
    if (totalBytes + length > 16777216) {
      throw ContractError('native_trainer.source_bytes_quota', path,
          'Native source bytes exceed their limit.');
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

  await readBytes('Data/Text/Dialogs/100000.csv');
  await readBytes('Data/Text/Dialogs/100067.csv');
  final moves = {
    ...nativeQualifiedFieldMoveSourceHashes.keys,
    for (final request in requests) ...?request.explicitMoveIds
  };
  final abilities = <String>{};
  final species = requests.map((r) => r.baseId).toSet();
  final queue = species.toList()..sort();
  var formCount = 0;
  for (var cursor = 0; cursor < queue.length; cursor++) {
    if (queue.length > 128) {
      throw ContractError('native_trainer.species_closure_quota', r'$',
          'Native species closure exceeds its limit.');
    }
    final id = queue[cursor];
    final raw = await read('Data/Studio/pokemon/$id.json');
    final forms = (raw['forms'] as List).cast<Map>();
    formCount += forms.length;
    if (formCount > 128) {
      throw ContractError('native_trainer.form_quota', r'$',
          'Native form count exceeds its limit.');
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
        throw ContractError('native_trainer.move_quota', r'$',
            'Native move count exceeds its limit.');
      }
      final targets = <String>[
        for (final evolution in (form['evolutions'] as List).cast<Map>())
          (evolution['dbSymbol'] ?? id) as String,
        if (form['babyDbSymbol'] case final String baby) baby,
      ];
      for (final target in targets) {
        if (target != 'none' && target != '__undef__' && species.add(target)) {
          if (species.length > 128) {
            throw ContractError('native_trainer.species_closure_quota', r'$',
                'Native species closure exceeds its limit.');
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
  return const NativePsdkTrainerBundleBuilder()
      .build(files: sourceFiles.values.toList(), requests: requests);
}
