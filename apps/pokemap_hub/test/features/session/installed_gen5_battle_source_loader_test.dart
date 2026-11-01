import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/features/session/data/repositories/installed_gen5_battle_source_loader.dart';
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../../support/game_package_fixture.dart';
import '../../../../../packages/map_distribution/test/support/spatial_feature_capabilities_fixture.dart';

void main() {
  late Directory root;
  late Gen5BattleSourceBundle bundle;
  late Gen5BattleSourceBinding binding;
  late Uint8List bindingBytes;
  late Uint8List bundleBytes;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('installed-gen5-source-');
    bundle = Gen5BattleSourceBundle(
      species: 'syntheticmon',
      nationalDex: 25,
      release: 'synthetic-release',
      sourceRepository: 'fuddlesworth/pokebw2',
      sourceRevision: 'a' * 40,
      sourceDirectory: 'res/pokemon/syntheticmon',
      reconstruction: 'unverified',
      redistributionStatus: 'unverified',
      assets: {
        for (var i = 0; i < gen5BattleBundleAssetNames.length; i++)
          gen5BattleBundleAssetNames[i]: Uint8List.fromList([i + 1]),
      },
    );
    binding = Gen5BattleSourceBinding.fromBundle(
      projectSpeciesId: 'local-mon',
      projectNationalDex: 25,
      bundle: bundle,
    );
    bindingBytes = binding.encode();
    bundleBytes = bundle.encode();
    for (final entry in {
      binding.bindingPath: bindingBytes,
      binding.bundlePath: bundleBytes,
    }.entries) {
      final file = File(p.join(root.path, 'project', entry.key));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  GamePackageFileEntry entry(String path, Uint8List bytes) =>
      GamePackageFileEntry(
        path: 'project/$path',
        size: bytes.length,
        sha256: sha256.convert(bytes).toString(),
      );

  Future<InstalledGen5BattleSourceLoader> loader(
    List<GamePackageFileEntry> files,
  ) async {
    final manifest = _manifest(files);
    final assets = await PackageAssetResolver.create(
      versionRoot: root,
      manifest: manifest,
    );
    return InstalledGen5BattleSourceLoader(manifest: manifest, assets: assets);
  }

  test(
    'loads the inventoried binding and bundle through the resolver',
    () async {
      final source = await loader([
        entry(binding.bindingPath, bindingBytes),
        entry(binding.bundlePath, bundleBytes),
      ]);
      final loaded = await source.load(
        projectSpeciesId: 'local-mon',
        projectNationalDex: 25,
      );
      expect(loaded!.species, bundle.species);
      expect(loaded.assets['front.png'], bundle.assets['front.png']);
    },
  );

  test('ignores a binding absent from the inventory', () async {
    final source = await loader([entry(binding.bundlePath, bundleBytes)]);
    expect(
      await source.load(projectSpeciesId: 'local-mon', projectNationalDex: 25),
      isNull,
    );
  });

  test(
    'rejects a bundle absent from the inventory even when it exists',
    () async {
      final source = await loader([entry(binding.bindingPath, bindingBytes)]);
      await expectLater(
        source.load(projectSpeciesId: 'local-mon', projectNationalDex: 25),
        throwsFormatException,
      );
    },
  );

  test(
    'rejects a binding that no longer matches its inventory digest',
    () async {
      final source = await loader([
        entry(binding.bindingPath, bindingBytes),
        entry(binding.bundlePath, bundleBytes),
      ]);
      await File(p.join(root.path, 'project', binding.bindingPath))
          .writeAsBytes([...bindingBytes, 0]);
      await expectLater(
        source.load(projectSpeciesId: 'local-mon', projectNationalDex: 25),
        throwsFormatException,
      );
    },
  );

  test('rejects a linked bundle outside the installed version', () async {
    final source = await loader([
      entry(binding.bindingPath, bindingBytes),
      entry(binding.bundlePath, bundleBytes),
    ]);
    final outside = File(
      p.join(root.parent.path, '${p.basename(root.path)}-outside'),
    );
    await outside.writeAsBytes(bundleBytes);
    addTearDown(() async {
      if (await outside.exists()) await outside.delete();
    });
    final path = p.join(root.path, 'project', binding.bundlePath);
    await File(path).delete();
    await Link(path).create(outside.path);
    await expectLater(
      source.load(projectSpeciesId: 'local-mon', projectNationalDex: 25),
      throwsA(isA<PackageAssetResolutionException>()),
    );
  }, skip: Platform.isWindows);

  test(
    'loads from a verified installed package without the source files',
    () async {
      final package = await writeTestPackage(
        Directory(p.join(root.path, 'archive')),
        additionalPayloadFiles: {
          'project/${binding.bindingPath}': bindingBytes,
          'project/${binding.bundlePath}': bundleBytes,
        },
      );
      final support = Directory(p.join(root.path, 'support'));
      final installed = await GamePackageInstaller(
        supportRoot: support,
        inspector: GamePackageInspector(
          hostCompatibility: testHostCompatibility(),
        ),
        availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
        loadSmoke: (_, _) async {},
        prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
      ).install(package, source: GamePackageInstallSource.localFile);
      final launch = await InstalledGameLaunchResolver(
        supportRoot: support,
        hostCompatibility: testHostCompatibility(),
      ).resolve(installed.game);

      await package.delete();
      await Directory(p.join(root.path, 'project')).delete(recursive: true);

      final loaded = await InstalledGen5BattleSourceLoader(
        manifest: launch.manifest,
        assets: launch.assets,
      ).load(projectSpeciesId: 'local-mon', projectNationalDex: 25);
      expect(loaded!.assets['front.png'], bundle.assets['front.png']);
      expect(loaded.assets['back.png'], bundle.assets['back.png']);
    },
  );

  test(
    'imports from the API and loads the installed export without its project',
    () async {
      final project = Directory(p.join(root.path, 'authoring'));
      Future<void> writeProject(String path, List<int> bytes) async {
        final file = File(p.join(project.path, path));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
      }

      final files = spatialFeaturePayload('companion');
      final projectManifest = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(files['project/project.json']!))
            as Map<String, dynamic>,
      );
      await project.create(recursive: true);
      final storage = await CatalogStorageStore.open(projectRoot: project.path);
      final working = await WorkingProjectCatalog.create(
        store: storage,
        projectId: 'gen5-installed-source',
        project: projectManifest,
      );
      await working.close();
      for (final item in files.entries) {
        if (item.key == 'project/project.json') continue;
        await writeProject(item.key.substring('project/'.length), item.value);
      }
      await writeProject(
        'data/pokemon/catalogs/items.json',
        utf8.encode(
          jsonEncode(
            encodeProjectItemCatalog(
              const ProjectItemCatalog(schemaVersion: 1, entries: []),
            ),
          ),
        ),
      );
      final source = Gen5BattleSourceBundle(
        species: 'syntheticmon',
        nationalDex: 1,
        release: 'synthetic-release',
        sourceRepository: 'fuddlesworth/pokebw2',
        sourceRevision: 'a' * 40,
        sourceDirectory: 'res/pokemon/syntheticmon',
        reconstruction: 'unverified',
        redistributionStatus: 'unverified',
        assets: bundle.assets,
      );
      final transport = _SyntheticSourceTransport(source);
      final handles = WorkspaceHandleStore();
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [project.path],
        fileReader: reader,
      );
      final opener = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {},
      );
      final opened = await opener.openProject(project.path);
      final authoring = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
      );
      await authoring.attachProject(
        projectRootPath: project.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      try {
        final result =
            await AveluneGen5BattleSourceImport(
              source: AveluneGen5BattleSource(
                client: transport,
                release: 'synthetic-release',
              ),
              authoring: authoring,
              projectHandle: opened.projectHandle,
              workspaceHandle: opened.workspaceHandle,
            ).import(
              sourceSpecies: 'syntheticmon',
              projectSpeciesId: 'clockbird',
              nationalDex: 1,
              speciesPath: 'data/pokemon/species/bronze-bird.json',
              operationId: 'api-to-installed-game',
            );
        expect(result.status, AveluneGen5ImportStatus.imported);
        expect(authoring.artifacts.list(), isEmpty);
        expect(
          transport.requests.single.path,
          endsWith('/synthetic-release/gen5-battle/1'),
        );
      } finally {
        await authoring.detachWorkspace(opened.workspaceHandle);
        handles.closeWorkspace(opened.workspaceHandle);
      }
      final export = await const CanonicalGamePackageExportService().build(
        projectRoot: project,
        profile: GamePackageExportProfile(
          gameId: 'games.example.mcss',
          gameVersion: '0.1.0',
          title: 'Synthetic',
          authorName: 'Example',
          defaultLocale: 'fr',
          supportedLocales: ['fr'],
        ),
        mode: GamePackageExportMode.localTest,
      );
      final package = File(p.join(root.path, 'export.avelunegame'));
      await package.writeAsBytes(export.packageBytes);
      final requirements = export.inspection.manifest.compatibility;
      final compatibility = GamePackageHostCompatibility(
        hubVersion: Version.parse('1.2.0'),
        runtimeApiVersion: Version.parse('1.4.0'),
        capabilities: requirements.requiredCapabilities.toSet(),
        supportedProjectFormats: {requirements.projectFormat},
        currentProjectFormat: requirements.projectFormat,
        supportedSaveFormats: {requirements.saveFormat},
      );
      final support = Directory(p.join(root.path, 'support'));
      final installed = await GamePackageInstaller(
        supportRoot: support,
        inspector: GamePackageInspector(hostCompatibility: compatibility),
        availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
        loadSmoke: (_, _) async {},
        prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
      ).install(package, source: GamePackageInstallSource.localFile);
      final launch = await InstalledGameLaunchResolver(
        supportRoot: support,
        hostCompatibility: compatibility,
      ).resolve(installed.game);

      await project.delete(recursive: true);
      await package.delete();

      final loaded = await InstalledGen5BattleSourceLoader(
        manifest: launch.manifest,
        assets: launch.assets,
      ).load(projectSpeciesId: 'clockbird', projectNationalDex: 1);
      expect(loaded!.reconstruction, 'unverified');
      for (final name in gen5BattleBundleAssetNames) {
        expect(loaded.assets[name], source.assets[name], reason: name);
      }
    },
  );
}

GamePackageManifest _manifest(List<GamePackageFileEntry> files) =>
    GamePackageManifest(
      packageFormat: 1,
      gameId: 'org.example.adventure',
      gameVersion: Version.parse('1.0.0'),
      title: 'Adventure',
      author: const GamePackageParty(name: 'Example'),
      compatibility: GamePackageCompatibility(
        minHubVersion: Version.parse('1.0.0'),
        runtimeApiExpression: '^1.0.0',
        projectFormat: 'v2',
        saveFormat: 1,
        compatibilityId: 'story-v1',
        requiredCapabilities: const [],
      ),
      locales: GamePackageLocales(
        defaultLocale: 'fr-FR',
        supported: const ['fr-FR'],
      ),
      content: GamePackageContent(
        fileCount: files.length,
        totalBytes: files.fold(0, (total, file) => total + file.size),
        treeSha256: 'a' * 64,
        files: files,
      ),
    );

final class _SyntheticSourceTransport
    implements PokemonBoundedExternalHttpTransport {
  _SyntheticSourceTransport(this.bundle);

  final Gen5BattleSourceBundle bundle;
  final requests = <Uri>[];

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    requests.add(uri);
    final document =
        jsonDecode(utf8.decode(bundle.encode())) as Map<String, dynamic>
          ..remove('kind')
          ..remove('schemaVersion')
          ..['format'] = 'gen5-battle-source-v1';
    final body = jsonEncode(document);
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: {'x-source-revision': bundle.sourceRevision},
      body: body,
      bodyBytes: Uint8List.fromList(utf8.encode(body)),
    );
  }
}
