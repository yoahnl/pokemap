import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart'
    show
        ProjectItemIconPack,
        ProjectItemIconProvisioningCancelled,
        ProjectItemIconProvisioningPartialFailure,
        provisionProjectItemIcons;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late Directory source;
  late List<int> potion;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('project-item-provisioning-');
    root = Directory(await root.resolveSymbolicLinks());
    source = await Directory(p.join(root.path, 'source')).create();
    potion = image.encodePng(image.Image(width: 2, height: 2));
    await _writePack(source, {'potion': potion, 'poke-ball': potion});
  });

  tearDown(() => root.delete(recursive: true));

  test('imports only project catalog items through canonical assets', () async {
    final manifestFile = File(p.join(source.path, 'manifest.json'));
    final manifest = jsonDecode(await manifestFile.readAsString()) as Map;
    manifest['items']['potion']['provenance'] = {
      'generator': 'Fixture generator',
      'sourceArtifact': 'original.png',
    };
    manifest['items']['potion']['sourcePath'] = '/tmp/original.png';
    await manifestFile.writeAsString(jsonEncode(manifest));
    final project = await _project(root, 'first', ['potion']);
    final result = await _run(project, source);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    final receipt = jsonDecode(result.stdout as String) as Map;
    expect(receipt['importedItems'], ['potion']);
    expect(
      await File(p.join(project.path, 'data/pokemon/assets/items/potion.png'))
          .readAsBytes(),
      potion,
    );
    expect(
      await File(
              p.join(project.path, 'data/pokemon/assets/items/poke-ball.png'))
          .exists(),
      isFalse,
    );
    final assets = await _assets(project);
    final icon =
        assets.findByLogicalPath('data/pokemon/assets/items/potion.png');
    expect(icon, isNotNull);
    expect(
      await File(p.join(project.path, assetBlobStorageKey(icon!.artifact)))
          .readAsBytes(),
      potion,
    );
    final provenance = assets.records
        .where((entry) => entry.tags.contains('item-icon-provenance'))
        .single;
    expect(provenance.logicalPath, endsWith('.json'));
    final projection = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: project,
      profile: GamePackageExportProfile(
          gameId: 'games.test.item-icons',
          gameVersion: '0.1.0',
          title: 'Item icons',
          authorName: 'Tester',
          defaultLocale: 'en',
          supportedLocales: const ['en']),
    );
    final metadata = jsonDecode(utf8.decode(
        projection.payloadFiles['project/${provenance.logicalPath}']!)) as Map;
    final iconMetadata = (metadata['icons'] as List).single as Map;
    expect(iconMetadata['projectItemId'], 'potion');
    expect(iconMetadata['generation']['generator'], 'Fixture generator');
    expect(iconMetadata.containsKey('sourcePath'), isFalse);
    expect(metadata['licenseText'], 'Fixture license');
    final inventory =
        const GamePackageInventoryBuilder().build(projection.payloadFiles);
    const validator = GamePackageContentValidator(GamePackageSecurityPolicy());
    for (final entry in inventory.files) {
      validator.validate(
          entry, Uint8List.fromList(projection.payloadFiles[entry.path]!));
    }
  });

  test('keeps custom files isolated from the same item in another project',
      () async {
    final customized = await _project(root, 'customized', ['potion']);
    final regular = await _project(root, 'regular', ['potion']);
    final customFile =
        File(p.join(customized.path, 'data/pokemon/assets/items/potion.png'));
    await customFile.parent.create(recursive: true);
    await customFile.writeAsBytes([7, 8, 9]);

    final preserved = await _run(customized, source);
    final imported = await _run(regular, source);

    expect(preserved.exitCode, 0, reason: preserved.stderr.toString());
    expect(imported.exitCode, 0, reason: imported.stderr.toString());
    expect(
        jsonDecode(preserved.stdout as String)['preservedItems'], ['potion']);
    expect(await customFile.readAsBytes(), [7, 8, 9]);
    expect(
        await File(p.join(regular.path, 'data/pokemon/assets/items/potion.png'))
            .readAsBytes(),
        potion);
    expect(await File(p.join(customized.path, assetCatalogStorageKey)).exists(),
        isFalse);
  });

  test('provisions more than 200 assets through separate canonical batches',
      () async {
    final ids = [for (var index = 0; index < 201; index++) 'item-$index'];
    await _writePack(source, {for (final id in ids) id: potion});
    final project = await _project(root, 'multiple-batches', ids);

    final result = await _run(project, source);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    final output = jsonDecode(result.stdout as String) as Map;
    expect(output['importedItems'], unorderedEquals(ids));
    expect(output['receipts'], hasLength(2));
    final assets = await _assets(project);
    expect(assets.records, hasLength(202));
    for (final id in ids) {
      expect(
          await File(p.join(project.path, 'data/pokemon/assets/items/$id.png'))
              .readAsBytes(),
          potion);
    }
  });

  test('does not load a source pack when every project icon already exists',
      () async {
    final project = await _project(root, 'complete', ['potion']);
    final file =
        File(p.join(project.path, 'data/pokemon/assets/items/potion.png'));
    await file.parent.create(recursive: true);
    await file.writeAsBytes([7, 8, 9]);

    final result = await _run(project, Directory(p.join(root.path, 'absent')));

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(jsonDecode(result.stdout as String)['preservedItems'], ['potion']);
    expect(await file.readAsBytes(), [7, 8, 9]);
    expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
        isFalse);
  });

  test('keeps managed icons without their materialized logical file', () async {
    final project = await _project(root, 'managed', ['potion']);
    final first = await _run(project, source);
    expect(first.exitCode, 0, reason: first.stderr.toString());
    final catalogFile = File(p.join(project.path, assetCatalogStorageKey));
    final before = await catalogFile.readAsBytes();
    await File(p.join(project.path, 'data/pokemon/assets/items/potion.png'))
        .delete();

    final repeated = await _run(project, source);

    expect(repeated.exitCode, 0, reason: repeated.stderr.toString());
    expect(jsonDecode(repeated.stdout as String)['importedItems'], isEmpty);
    expect(jsonDecode(repeated.stdout as String)['preservedItems'], ['potion']);
    expect(jsonDecode(repeated.stdout as String)['receipts'], isEmpty);
    expect(await catalogFile.readAsBytes(), before);
  });

  test('materializes source aliases under the selected project item ID',
      () async {
    await _writePack(source, {'kings-rock': potion, 'potion': potion},
        aliases: {'king-s-rock': 'kings-rock'});
    final project = await _project(root, 'aliases', [
      'king_s_rock',
      'potion'
    ], aliases: {
      'king_s_rock': ['royal-rock']
    });

    final result = await _runCli(project, source, ['--item', 'royal-rock']);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(
        jsonDecode(result.stdout as String)['importedItems'], ['king_s_rock']);
    expect(
        await File(p.join(
                project.path, 'data/pokemon/assets/items/king_s_rock.png'))
            .readAsBytes(),
        potion);
    expect(
        await File(p.join(project.path, 'data/pokemon/assets/items/potion.png'))
            .exists(),
        isFalse);
  });

  test('rejects an asset identity assigned to another authored file', () async {
    final project = await _project(root, 'identity-conflict', ['potion']);
    final artifact =
        ContentArtifactRef.fromBytes(potion, mediaType: 'image/png');
    final record = AssetRecord(
        id: 'item-icon-potion',
        logicalPath: 'graphics/custom-potion.png',
        artifact: artifact);
    final catalog = File(p.join(project.path, assetCatalogStorageKey));
    await catalog.parent.create(recursive: true);
    await catalog
        .writeAsString(jsonEncode(AssetCatalog(records: [record]).toJson()));
    final blob = File(p.join(project.path, assetBlobStorageKey(artifact)));
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(potion);
    final custom = File(p.join(project.path, record.logicalPath));
    await custom.parent.create(recursive: true);
    await custom.writeAsBytes(potion);
    final before = await catalog.readAsBytes();

    final result = await _run(project, source);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('Asset identity already exists'));
    expect(await catalog.readAsBytes(), before);
    expect(await custom.readAsBytes(), potion);
    expect(
        await File(p.join(project.path, 'data/pokemon/assets/items/potion.png'))
            .exists(),
        isFalse);
  });

  test('does not inject a pack into a project with Pokemon disabled', () async {
    final project = await _project(root, 'neutral', ['potion']);
    final file = File(p.join(project.path, 'project.json'));
    final manifest = ProjectManifest.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    await file.writeAsString(jsonEncode(manifest
        .copyWith(pokemon: manifest.pokemon.copyWith(enabled: false))
        .toJson()));
    final before = await file.readAsBytes();

    final result = await _run(project, Directory(p.join(root.path, 'absent')));

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(jsonDecode(result.stdout as String)['skippedReason'],
        'pokemon-disabled');
    expect(await file.readAsBytes(), before);
    expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
        isFalse);
    expect(
        await Directory(p.join(project.path, 'data/pokemon/assets')).exists(),
        isFalse);
  });

  test('rejects unsafe or unknown explicit item IDs before mutation', () async {
    final project = await _project(root, 'unsafe-id', ['potion']);
    for (final id in ['../potion', 'poke-ball']) {
      final result = await _run(project, source, ['--item', id]);
      expect(result.exitCode, 1);
      expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
          isFalse);
    }
  });

  test('skips projects without an item catalog configuration without loading',
      () async {
    final project = await _project(root, 'no-item-catalog', ['potion']);
    final file = File(p.join(project.path, 'project.json'));
    final manifest = ProjectManifest.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    await file.writeAsString(jsonEncode(manifest
        .copyWith(pokemon: manifest.pokemon.copyWith(catalogFiles: const {}))
        .toJson()));
    final before = await file.readAsBytes();
    var loads = 0;

    final receipt = await provisionProjectItemIcons(
      projectPath: project.path,
      loadPack: () async {
        loads++;
        throw StateError('The pack must not load.');
      },
    );

    expect(receipt['skippedReason'], 'item-catalog-not-configured');
    expect(loads, 0);
    expect(await file.readAsBytes(), before);
    expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
        isFalse);
  });

  test('skips empty item catalogs without loading the pack', () async {
    final project = await _project(root, 'empty-item-catalog', []);
    var loads = 0;

    final receipt = await provisionProjectItemIcons(
      projectPath: project.path,
      loadPack: () async {
        loads++;
        throw StateError('The pack must not load.');
      },
    );

    expect(receipt['importedItems'], isEmpty);
    expect(receipt['receipts'], isEmpty);
    expect(loads, 0);
    expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
        isFalse);
  });

  test('skips missing configured item catalogs only for automatic requests',
      () async {
    final project = await _project(root, 'missing-catalog', ['potion']);
    await File(p.join(project.path, 'data/pokemon/catalogs/items.json'))
        .delete();
    var loads = 0;
    Future<ProjectItemIconPack> loadPack() async {
      loads++;
      throw StateError('The pack must not load.');
    }

    final receipt = await provisionProjectItemIcons(
      projectPath: project.path,
      loadPack: loadPack,
    );

    expect(receipt['skippedReason'], 'item-catalog-missing');
    await expectLater(
      provisionProjectItemIcons(
        projectPath: project.path,
        loadPack: loadPack,
        itemIds: ['potion'],
      ),
      throwsFormatException,
    );
    expect(loads, 0);
    expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
        isFalse);
  });

  test('rejects malformed configured item catalogs before loading', () async {
    final project = await _project(root, 'invalid-catalog', ['potion']);
    await File(p.join(project.path, 'data/pokemon/catalogs/items.json'))
        .writeAsString('{}');
    var loads = 0;

    await expectLater(
      provisionProjectItemIcons(
        projectPath: project.path,
        loadPack: () async {
          loads++;
          throw StateError('The pack must not load.');
        },
      ),
      throwsFormatException,
    );

    expect(loads, 0);
    expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
        isFalse);
  });

  test('cancels a superseded request after pack loading without mutations',
      () async {
    final project = await _project(root, 'cancelled', ['potion']);
    var current = true;

    await expectLater(
      provisionProjectItemIcons(
        projectPath: project.path,
        shouldContinue: () => current,
        loadPack: () async {
          final pack = await _loadPack(source);
          current = false;
          return pack;
        },
      ),
      throwsA(isA<ProjectItemIconProvisioningCancelled>()),
    );

    expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
        isFalse);
    expect(
        await File(p.join(project.path, 'data/pokemon/assets/items/potion.png'))
            .exists(),
        isFalse);
  });

  test('cancels between batches and reports the applied batch accurately',
      () async {
    final ids = [for (var index = 0; index < 201; index++) 'item-$index']
      ..sort();
    await _writePack(source, {for (final id in ids) id: potion});
    final project = await _project(root, 'cancelled-batch', ids);
    final first = File(
        p.join(project.path, 'data/pokemon/assets/items/${ids.first}.png'));

    await expectLater(
      provisionProjectItemIcons(
        projectPath: project.path,
        loadPack: () => _loadPack(source),
        shouldContinue: () => !first.existsSync(),
      ),
      throwsA(isA<ProjectItemIconProvisioningPartialFailure>()
          .having(
              (error) => error.importedItems, 'importedItems', hasLength(200))
          .having((error) => error.receipts, 'receipts', hasLength(1))),
    );

    expect(await first.exists(), isTrue);
    expect(
        await File(p.join(
                project.path, 'data/pokemon/assets/items/${ids.last}.png'))
            .exists(),
        isFalse);
    expect((await _assets(project)).records, hasLength(200));
  });

  test('verifies every image hash before importing any requested icon',
      () async {
    final project = await _project(root, 'bad-pack', ['potion']);
    final file = File(p.join(source.path, 'manifest.json'));
    final manifest = jsonDecode(await file.readAsString()) as Map;
    manifest['items']['poke-ball']['sha256'] = 'wrong';
    await file.writeAsString(jsonEncode(manifest));

    final result = await _run(project, source);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('differs from its manifest'));
    expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
        isFalse);
  });

  test('rejects symbolic links in import destinations and source roots',
      () async {
    final project = await _project(root, 'linked', ['potion']);
    final outside = await Directory(p.join(root.path, 'outside')).create();
    await Link(p.join(project.path, 'data/pokemon/assets'))
        .create(outside.path);

    final targetResult = await _run(project, source);

    expect(targetResult.exitCode, 1);
    expect(await outside.list().toList(), isEmpty);
    expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
        isFalse);

    final clean = await _project(root, 'clean', ['potion']);
    final linkedSource = p.join(root.path, 'linked-source');
    await Link(linkedSource).create(source.path);
    final sourceResult = await _runCli(clean, Directory(linkedSource));
    expect(sourceResult.exitCode, 1);
    expect(await File(p.join(clean.path, assetCatalogStorageKey)).exists(),
        isFalse);
  });
}

Future<ProcessResult> _run(Directory project, Directory source,
    [List<String> arguments = const []]) async {
  try {
    final receipt = await provisionProjectItemIcons(
      projectPath: project.path,
      loadPack: () => _loadPack(source),
      itemIds: arguments.isEmpty
          ? null
          : [
              for (var index = 1; index < arguments.length; index += 2)
                arguments[index],
            ],
    );
    return ProcessResult(0, 0, jsonEncode(receipt), '');
  } on ProjectItemIconProvisioningPartialFailure catch (error) {
    return ProcessResult(0, 1, '', jsonEncode(error.toJson()));
  } on Object catch (error) {
    return ProcessResult(0, 1, '', 'Item icon provisioning failed: $error');
  }
}

Future<ProjectItemIconPack> _loadPack(Directory source) async =>
    ProjectItemIconPack(
      manifestBytes:
          await File(p.join(source.path, 'manifest.json')).readAsBytes(),
      archiveBytes: await File(p.join(source.path, 'icons.zip')).readAsBytes(),
    );

Future<ProcessResult> _runCli(Directory project, Directory source,
        [List<String> arguments = const []]) =>
    Process.run(Platform.resolvedExecutable, [
      'run',
      'tool/import_project_item_icons.dart',
      '--project',
      project.path,
      '--source',
      source.path,
      ...arguments,
    ]);

Future<Directory> _project(Directory root, String name, List<String> ids,
    {Map<String, List<String>> aliases = const {}}) async {
  final project = await Directory(p.join(root.path, name)).create();
  await File(p.join(project.path, 'project.json')).writeAsString(jsonEncode(
    ProjectManifest(
            name: name,
            maps: const [],
            tilesets: const [],
            pokemon: const ProjectPokemonConfig(
                enabled: true, ruleset: PokemonRulesetProfile.pokeMapBetaV1))
        .toJson(),
  ));
  final catalog =
      File(p.join(project.path, 'data/pokemon/catalogs/items.json'));
  await catalog.parent.create(recursive: true);
  await catalog.writeAsString(jsonEncode(encodeProjectItemCatalog(
    ProjectItemCatalog(schemaVersion: 1, entries: [
      for (final id in ids)
        ProjectItemDefinition(
            id: id,
            displayName: id,
            aliases: aliases[id] ?? const [],
            pocketId: 'medicine'),
    ]),
  )));
  return project;
}

Future<AssetCatalog> _assets(Directory project) async => AssetCatalog.fromJson(
      jsonDecode(await File(p.join(project.path, assetCatalogStorageKey))
          .readAsString()) as Map<String, dynamic>,
    );

Future<void> _writePack(Directory source, Map<String, List<int>> icons,
    {Map<String, String> aliases = const {}}) async {
  final license = utf8.encode('Fixture license');
  final archive = Archive();
  for (final entry in icons.entries) {
    archive.addFile(
        ArchiveFile('${entry.key}.png', entry.value.length, entry.value));
  }
  archive.addFile(ArchiveFile('LICENCE.txt', license.length, license));
  final zip = ZipEncoder().encode(archive);
  await File(p.join(source.path, 'icons.zip')).writeAsBytes(zip);
  await File(p.join(source.path, 'manifest.json')).writeAsString(jsonEncode({
    'schemaVersion': 1,
    'repository': 'https://example.invalid/fixture',
    'revision': 'fixture-revision',
    'aliases': aliases,
    'licensePath': 'LICENCE.txt',
    'licenseSha256': sha256.convert(license).toString(),
    'archiveSha256': sha256.convert(zip).toString(),
    'items': {
      for (final entry in icons.entries)
        entry.key: {
          'sha256': sha256.convert(entry.value).toString(),
          'bytes': entry.value.length,
          'width': image.decodePng(Uint8List.fromList(entry.value))!.width,
          'height': image.decodePng(Uint8List.fromList(entry.value))!.height,
        },
    },
  }));
}
