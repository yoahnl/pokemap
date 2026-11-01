import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_feature_capabilities_fixture.dart';

void main() {
  test('exports the bound source without changing Unicode bytes', () async {
    final root = await _fixture();
    final bundle = _bundle();
    final binding = _binding(bundle);
    final bindingBytes = binding.encode();
    final bundleBytes = bundle.encode();
    await _write(root, binding.bindingPath, bindingBytes);
    await _write(root, binding.bundlePath, bundleBytes);
    final speciesFile =
        File('${root.path}/data/pokemon/species/bronze-bird.json');
    final originalSpecies = await speciesFile.readAsBytes();

    final result = await _export(root);
    final inspection =
        const GamePackageInspector().inspect(result.packageBytes);
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    final archivedBinding = Uint8List.fromList(
      archive.findFile('project/${binding.bindingPath}')!.content as List<int>,
    );
    final archivedBundle = Uint8List.fromList(
      archive.findFile('project/${binding.bundlePath}')!.content as List<int>,
    );
    expect(archivedBinding, bindingBytes);
    expect(archivedBundle, bundleBytes);
    final bindingEntry = inspection.manifest.content.files.singleWhere(
      (entry) => entry.path == 'project/${binding.bindingPath}',
    );
    final restored = Gen5BattleSourceBinding.decode(archivedBinding,
        expectedSha256: bindingEntry.sha256,
        expectedProjectSpeciesId: 'clockbird',
        expectedProjectNationalDex: 1);
    final restoredBundle = restored.resolve(archivedBundle,
        expectedProjectSpeciesId: 'clockbird', expectedProjectNationalDex: 1);
    expect(restoredBundle.reconstruction, 'a\u0300 verifier');
    expect(await speciesFile.readAsBytes(), originalSpecies);
    expect(await File('${root.path}/${binding.bindingPath}').readAsBytes(),
        bindingBytes);
    expect(await File('${root.path}/${binding.bundlePath}').readAsBytes(),
        bundleBytes);
  });

  test('rejects a resource with a stale digest during canonical export',
      () async {
    final root = await _fixture();
    final source = _bundle();
    final original = _binding(source);
    final document =
        jsonDecode(utf8.decode(source.encode())) as Map<String, dynamic>;
    final item = (document['assets'] as Map<String, dynamic>)['front.png']
        as Map<String, dynamic>;
    item['data'] = base64.encode([0, 0]);
    final damaged = Uint8List.fromList(utf8.encode(jsonEncode(document)));
    final rawBinding =
        jsonDecode(utf8.decode(original.encode())) as Map<String, dynamic>;
    rawBinding['bundleSha256'] = sha256.convert(damaged).toString();
    final bindingBytes =
        Uint8List.fromList(utf8.encode(jsonEncode(rawBinding)));
    final binding = Gen5BattleSourceBinding.decode(bindingBytes,
        expectedSha256: sha256.convert(bindingBytes).toString(),
        expectedProjectSpeciesId: 'clockbird',
        expectedProjectNationalDex: 1);
    await _write(root, binding.bindingPath, bindingBytes);
    await _write(root, binding.bundlePath, damaged);
    await expectLater(
        _export(root),
        throwsA(isA<GamePackageExportException>().having((error) => error.code,
            'code', 'gen5_battle_source.invalid_bundle')));
    expect(await File('${root.path}/${binding.bundlePath}').readAsBytes(),
        damaged);
  });

  test('rejects a binding whose national number differs from the project',
      () async {
    final root = await _fixture();
    final source = _bundle(nationalDex: 2);
    final binding = _binding(source);
    await _write(root, binding.bindingPath, binding.encode());
    await _write(root, binding.bundlePath, source.encode());
    await expectLater(
        _export(root),
        throwsA(isA<GamePackageExportException>().having((error) => error.code,
            'code', 'gen5_battle_source.identity_mismatch')));
  });

  test('exports MCSS and a battle recipe from the same project', () async {
    final root = await _fixture();
    final source = _bundle();
    final binding = _binding(source);
    await _write(root, binding.bindingPath, binding.encode());
    await _write(root, binding.bundlePath, source.encode());
    final recipe = await _writeRecipe(root);

    final result = await _export(root);
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    expect(archive.findFile('project/${binding.bindingPath}')!.content,
        binding.encode());
    expect(archive.findFile('project/${binding.bundlePath}')!.content,
        source.encode());
    expect(archive.findFile('project/${recipe.path}')!.content, recipe.bytes);
    final recipeBinding = BattleRecipeProjectBinding.fromJson(
      jsonDecode(utf8.decode(archive
          .findFile('project/${recipe.bindingPath}')!
          .content as List<int>)) as Map<String, dynamic>,
    );
    expect(
      () => recipeBinding.binding
          .resolve(recipe.bytes, const {}, availableCapabilities: {'wait'}),
      returnsNormally,
    );
  });

  test('exports MCSS from a working catalog without publishing its head',
      () async {
    final root = await _fixture();
    final source = _bundle();
    final binding = _binding(source);
    await _write(root, binding.bindingPath, binding.encode());
    await _write(root, binding.bundlePath, source.encode());
    final projectFile = File('${root.path}/project.json');
    final project = ProjectManifest.fromJson(
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
    );
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
      store: store,
      projectId: 'mcss-export-test',
      project: project,
      expectedProjectRevision:
          await store.gateway.readResourceRevision('project.json'),
    );
    addTearDown(working.close);
    final head = await store.readHead();
    final descriptor = await projectFile.readAsBytes();

    final result = await _export(root);
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    expect(archive.findFile('project/${binding.bindingPath}')!.content,
        binding.encode());
    expect(archive.findFile('project/${binding.bundlePath}')!.content,
        source.encode());
    expect(await store.readHead(), head);
    expect(await projectFile.readAsBytes(), descriptor);
  });

  test('exports the MCSS bundle through the JSONL CLI', () async {
    final root = await _fixture();
    final source = _bundle();
    final binding = _binding(source);
    await _write(root, binding.bindingPath, binding.encode());
    await _write(root, binding.bundlePath, source.encode());
    await GamePackageExportProfileStore(projectRoot: root).save(_profile());
    final output = Directory('${root.path}/exports');
    await output.create();
    final outputPath = '${output.path}/mcss.avelunegame';
    final process = await Process.start('dart', [
      'run',
      'bin/pokemap_authoring.dart',
      '--root',
      root.path,
      '--export-root',
      output.path,
    ]);
    final standardOutput = process.stdout.transform(utf8.decoder).join();
    final standardError = process.stderr.transform(utf8.decoder).join();
    var exited = false;
    try {
      process.stdin.writeln(jsonEncode({
        'id': 'mcss-export',
        'command': 'game_export',
        'args': {
          'projectRoot': root.path,
          'outputPath': outputPath,
          'mode': 'localTest',
        },
      }));
      await process.stdin.close();
      final exitCode =
          await process.exitCode.timeout(const Duration(seconds: 60));
      exited = true;
      final response = await standardOutput;
      expect(exitCode, 0, reason: await standardError);
      final result = jsonDecode(response.trim()) as Map<String, dynamic>;
      expect(result['status'], 'success', reason: response);
      final archive = ZipDecoder()
          .decodeBytes(await File(outputPath).readAsBytes(), verify: true);
      expect(archive.findFile('project/${binding.bindingPath}')!.content,
          binding.encode());
      expect(archive.findFile('project/${binding.bundlePath}')!.content,
          source.encode());
    } finally {
      if (!exited) {
        process.kill();
        await process.exitCode;
      }
    }
  }, timeout: const Timeout(Duration(seconds: 75)));

  test('rejects a binding when its bundle is missing', () async {
    final root = await _fixture();
    final binding = _binding(_bundle());
    await _write(root, binding.bindingPath, binding.encode());
    await expectLater(
      _export(root),
      throwsA(isA<GamePackageExportException>()
          .having((error) => error.code, 'code', 'missingProjectFile')
          .having((error) => error.path, 'path', binding.bundlePath)),
    );
  });

  test('rejects duplicate project species for a bound source', () async {
    final root = await _fixture();
    final source = _bundle();
    final binding = _binding(source);
    await _write(root, binding.bindingPath, binding.encode());
    await _write(root, binding.bundlePath, source.encode());
    final species = await File(
      '${root.path}/data/pokemon/species/bronze-bird.json',
    ).readAsBytes();
    await _write(root, 'data/pokemon/species/duplicate.json', species);
    await expectLater(
      _export(root),
      throwsA(isA<GamePackageExportException>().having((error) => error.code,
          'code', 'gen5_battle_source.identity_mismatch')),
    );
  });

  test('exports separate bundles for two bound project species', () async {
    final root = await _fixture();
    final speciesFile =
        File('${root.path}/data/pokemon/species/bronze-bird.json');
    final secondSpecies =
        jsonDecode(await speciesFile.readAsString()) as Map<String, dynamic>;
    secondSpecies['id'] = 'other';
    secondSpecies['slug'] = 'other';
    secondSpecies['nationalDex'] = 2;
    (secondSpecies['forms'] as Map<String, dynamic>)['baseFormId'] = 'other';
    secondSpecies['refs'] = {
      'learnset': 'other',
      'evolution': 'other',
      'media': 'other',
    };
    await _write(root, 'data/pokemon/species/other.json',
        utf8.encode(jsonEncode(secondSpecies)));
    await _write(
        root,
        'data/pokemon/learnsets/other.json',
        utf8.encode(jsonEncode(
            const PokemonLearnsetFile(speciesId: 'other').toJson())));
    await _write(
        root,
        'data/pokemon/evolutions/other.json',
        utf8.encode(jsonEncode(
            const PokemonEvolutionFile(speciesId: 'other').toJson())));
    await _write(
        root,
        'data/pokemon/media/other.json',
        utf8.encode(jsonEncode(
          const PokemonMediaFile(
              speciesId: 'other',
              defaultFormId: 'bronze',
              variants: {
                'bronze': PokemonMediaVariant(
                    frontStatic: 'assets/hero.png',
                    backStatic: 'assets/hero.png'),
              }).toJson(),
        )));
    final first = _bundle();
    final second = _bundle(nationalDex: 2);
    final bindings = [
      _binding(first),
      Gen5BattleSourceBinding.fromBundle(
        projectSpeciesId: 'other',
        projectNationalDex: 2,
        bundle: second,
      ),
    ];
    for (final (binding, source) in [
      (bindings[0], first),
      (bindings[1], second)
    ]) {
      await _write(root, binding.bindingPath, binding.encode());
      await _write(root, binding.bundlePath, source.encode());
    }
    final result = await _export(root);
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    for (final (binding, source) in [
      (bindings[0], first),
      (bindings[1], second)
    ]) {
      expect(archive.findFile('project/${binding.bindingPath}')!.content,
          binding.encode());
      expect(archive.findFile('project/${binding.bundlePath}')!.content,
          source.encode());
    }
  });

  test('rejects an unsupported recognized binding schema', () async {
    final root = await _fixture();
    final binding = _binding(_bundle());
    final document =
        jsonDecode(utf8.decode(binding.encode())) as Map<String, dynamic>;
    document['schemaVersion'] = 2;
    await _write(root, binding.bindingPath, utf8.encode(jsonEncode(document)));
    await expectLater(
      _export(root),
      throwsA(isA<GamePackageExportException>().having(
          (error) => error.code, 'code', 'gen5_battle_source.invalid_binding')),
    );
  });

  test('keeps unrelated legacy JSON in the binding directory exportable',
      () async {
    final root = await _fixture();
    const path = 'data/pokemon/gen5_battle_sources/bindings/legacy.json';
    final legacy = utf8.encode('{"kind":"another-extension","value":1}');
    await _write(root, path, legacy);
    final result = await _export(root);
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    expect(
      jsonDecode(
          utf8.decode(archive.findFile('project/$path')!.content as List<int>)),
      jsonDecode(utf8.decode(legacy)),
    );
  });
}

Future<({String path, String bindingPath, List<int> bytes})> _writeRecipe(
    Directory root) async {
  final bytes = utf8.encode(jsonEncode({
    'schemaVersion': 1,
    'recipeId': 'synthetic',
    'revision': '1',
    'moveSourceId': 'source',
    'variant': 'default',
    'requiredCapabilities': ['wait'],
    'provenance': {
      'source': 'synthetic',
      'sourceRevision': '1',
      'sourcePaths': [],
      'converter': 'test',
    },
    'resources': [],
    'program': {'kind': 'wait', 'durationMs': 100},
  }));
  final digest = sha256.convert(bytes).toString();
  final binding = BattleMoveRecipeBinding.fromJson({
    'schemaVersion': 1,
    'projectMoveId': 'custom',
    'sourceMoveId': 'source',
    'catalogReleaseId': 'test',
    'recipeId': 'synthetic',
    'variant': 'default',
    'revision': '1',
    'recipeSha256': digest,
  });
  final path = battleRecipeBlobPath(
    digest,
    'application/vnd.avelune.battle-recipe+json',
    projectMoveId: 'custom',
  );
  final bindingPath = battleRecipeBindingPath('custom');
  await _write(root, path, bytes);
  await _write(
      root,
      bindingPath,
      utf8.encode(
          jsonEncode(BattleRecipeProjectBinding(binding: binding).toJson())));
  return (path: path, bindingPath: bindingPath, bytes: bytes);
}

Future<Directory> _fixture() async {
  final configured = Platform.environment['AVELUNE_QA_ROOT'];
  final home = Platform.environment['HOME'];
  final fallback = Platform.isMacOS && home != null
      ? '$home/Library/Caches/AveluneQA/mcss-export-verification'
      : null;
  final owner = configured == null && fallback == null
      ? Directory.systemTemp
      : Directory(configured ?? fallback!);
  await owner.create(recursive: true);
  final root = await owner.createTemp('mcss-project-');
  addTearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });
  for (final entry in spatialFeaturePayload('companion').entries) {
    await _write(root, entry.key.substring('project/'.length), entry.value);
  }
  await _write(
    root,
    'data/pokemon/catalogs/items.json',
    utf8.encode(jsonEncode(encodeProjectItemCatalog(
      const ProjectItemCatalog(schemaVersion: 1, entries: []),
    ))),
  );
  return root;
}

Future<void> _write(Directory root, String path, List<int> bytes) async {
  final file = File('${root.path}/$path');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
}

Future<GamePackageExportArtifact> _export(Directory root) =>
    const CanonicalGamePackageExportService().build(
      projectRoot: root,
      profile: _profile(),
      mode: GamePackageExportMode.localTest,
    );

GamePackageExportProfile _profile() => GamePackageExportProfile(
      gameId: 'games.example.mcss',
      gameVersion: '0.1.0',
      title: 'Synthetic',
      authorName: 'Example',
      defaultLocale: 'fr',
      supportedLocales: ['fr'],
    );

Gen5BattleSourceBundle _bundle({int nationalDex = 1}) => Gen5BattleSourceBundle(
      species: 'syntheticmon',
      nationalDex: nationalDex,
      release: 'synthetic-release',
      sourceRepository: 'fuddlesworth/pokebw2',
      sourceRevision: 'a' * 40,
      sourceDirectory: 'res/pokemon/syntheticmon',
      reconstruction: 'a\u0300 verifier',
      redistributionStatus: 'unverified',
      assets: {
        for (var i = 0; i < gen5BattleBundleAssetNames.length; i++)
          gen5BattleBundleAssetNames[i]: Uint8List.fromList([i + 1, 255 - i]),
      },
    );

Gen5BattleSourceBinding _binding(Gen5BattleSourceBundle bundle) =>
    Gen5BattleSourceBinding.fromBundle(
        projectSpeciesId: 'clockbird',
        projectNationalDex: bundle.nationalDex,
        bundle: bundle);
