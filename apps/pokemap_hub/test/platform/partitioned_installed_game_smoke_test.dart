import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/map_runtime.dart' as runtime;
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/features/installation/data/repositories/installed_project_smoke.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/preferences/data/repositories/hub_preferences_repository_impl.dart';
import 'package:pokemap_hub/features/saves/data/repositories/hub_save_repository_impl.dart';
import 'package:pokemap_hub/features/session/application/services/hub_runtime_startup_bootstrap.dart';
import 'package:pokemap_hub/features/session/data/repositories/control_profile_repository_impl.dart';
import 'package:pokemap_hub/features/session/data/repositories/package_asset_resolver.dart';
import 'package:pokemap_hub/features/session/domain/entities/installed_game_launch_context.dart';
import 'package:pokemap_hub/features/session/domain/repositories/session_launch_repository_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Hub advertises the partitioned catalog capability', () {
    expect(
      aveluneHostCompatibility().capabilities,
      contains('catalog.partitioned@2'),
    );
  });

  test(
    'built game is inspected, staged and consumed by Hub and runtime',
    () async {
      final built = _build();
      final inspected = GamePackageInspector(
        hostCompatibility: aveluneHostCompatibility(),
      ).inspect(built.packageBytes);
      expect(
        inspected.compatibility!.decision,
        GamePackageCompatibilityDecision.accept,
      );
      expect(inspected.manifest.packageFormat, 1);
      expect(
        inspected.manifest.compatibility.requiredCapabilities,
        contains('catalog.partitioned@2'),
      );
      final staged = await _stage(built);
      final file = _projectFile(staged);
      final descriptor = jsonDecode(await file.readAsString()) as Map;
      expect(descriptor.keys.toSet(), {'format', 'version', 'kind', 'root'});
      expect(descriptor['version'], 2);
      expect(
        inspected.payloadPaths,
        contains(startsWith('project/catalog/objects/')),
      );
      final loaded = await loadProjectManifestFromFile(file.path);
      expect(loaded.toJson(), _project.toJson());
      await loadInstalledProjectSmoke(staged, inspected.manifest);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: file.path,
        mapId: _map.id,
      );
      expect(bundle.manifest.toJson(), _project.toJson());
      expect(bundle.map.toJson(), _map.toJson());
    },
  );

  test('old host rejects a V2 game despite unchanged outer package format', () {
    final host = aveluneHostCompatibility();
    final oldHost = GamePackageHostCompatibility(
      hubVersion: host.hubVersion,
      runtimeApiVersion: host.runtimeApiVersion,
      capabilities: host.capabilities.difference({'catalog.partitioned@2'}),
      supportedProjectFormats: host.supportedProjectFormats,
      currentProjectFormat: host.currentProjectFormat,
      currentProjectFormats: host.currentProjectFormats,
      supportedSaveFormats: host.supportedSaveFormats,
    );
    final built = _build();
    final compatibility = const GamePackageCompatibilityEvaluator().evaluate(
      built.manifest,
      oldHost,
    );
    expect(compatibility.decision, GamePackageCompatibilityDecision.reject);
    expect(
      compatibility.missingCapabilities,
      contains('catalog.partitioned@2'),
    );
    expect(
      () =>
          GamePackageInspector(hostCompatibility: oldHost)
              .inspect(built.packageBytes),
      throwsA(
        isA<GamePackageFormatException>().having(
          (error) => error.code,
          'code',
          'capabilityUnsupported',
        ),
      ),
    );
  });

  test('Hub staged smoke reads the partitioned project descriptor', () async {
    final built = _build();
    final staged = await _stage(built);
    await loadInstalledProjectSmoke(staged, built.manifest);
  });

  test('installed smoke loads only the initial map definition closure', () async {
    final built = _build();
    final staged = await _stage(built);
    final publication = PortableCatalogPublication.encodeProject(
      _project.copyWith(
        tilesets: [
          for (var i = 0; i < 64; i++)
            ProjectTilesetEntry(
              id: 'unused-$i',
              name: 'Unused $i',
              relativePath: 'assets/unused-$i.png',
            ),
        ],
      ),
    );
    await _projectFile(staged).writeAsString(jsonEncode(publication.descriptor));
    for (final object in publication.storage.objects.entries) {
      final decoded = jsonDecode(utf8.decode(object.value)) as Map;
      if (decoded['key'] case {'id': 'unused-63'}) continue;
      final file = File(
        p.join(staged.path, 'project/catalog/objects/${object.key}.json'),
      );
      await file.writeAsBytes(object.value);
    }
    await expectLater(
      loadProjectManifestFromFile(_projectFile(staged).path),
      throwsA(isA<ProjectLoadException>()),
    );
    await loadInstalledProjectSmoke(staged, built.manifest);
  });

  test(
    'real Hub bootstrap prepares and preloads the partitioned installed game',
    () async {
      final project = _project.copyWith(
        newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'start'),
      );
      final built = _build(project: project);
      final staged = await _stage(built);
      final supportRoot = await _temporaryDirectory();
      final manifest = built.manifest;
      final version = InstalledGameVersion(
        gameVersion: manifest.gameVersion,
        treeSha256: manifest.content.treeSha256,
        installedAt: DateTime.utc(2026, 10, 18),
        receiptFileName: 'receipt.json',
        source: GamePackageInstallSource.localFile,
        signatureStatus: PackageSignatureStatus.notPresent,
      );
      final game = InstalledGame(
        gameId: manifest.gameId,
        title: manifest.title,
        authorName: manifest.author.name,
        defaultLocale: manifest.locales.defaultLocale,
        supportedLocales: manifest.locales.supported,
        current: version.pointer,
        versions: [version],
      );
      final assets = await PackageAssetResolver.create(
        versionRoot: staged,
        manifest: manifest,
      );
      final launch = InstalledGameLaunchContext(
        game: game,
        manifest: manifest,
        identity: GameIdentity(
          gameId: manifest.gameId,
          gameVersion: manifest.gameVersion.toString(),
          projectFormat: ProjectFormat.v8,
          saveFormat: 1,
          compatibilityId: manifest.compatibility.compatibilityId,
        ),
        assets: assets,
        project: assets.reference('project/project.json'),
        installedVersionHandle: 'partitioned-installed-game',
        runtimeApiVersion: '1.4.0',
        grantedCapabilities: manifest.compatibility.requiredCapabilities
            .toSet(),
      );
      final stages = <runtime.RuntimeStartupBootstrapStage>[];
      final bootstrap = HubRuntimeStartupBootstrap(
        supportRoot: supportRoot,
        saveRepositoryFactory: (root, identity) =>
            HubSaveStore(supportRoot: root, identity: identity),
        preferencesRepository: HubPreferencesStore(supportRoot: supportRoot),
        controlProfileRepository: HubControlProfileStore(
          supportRoot: supportRoot,
        ),
        launchResolver: _FixedLaunchResolver(launch),
        game: game,
        onHubRequested: () async {},
        mountGame: (_) async => fail('Bootstrap must not mount a session'),
        unmountGame: (_) async {},
        stopIntroPlayback: () async {},
        defaultProfileDisplayNameForLocale: (_) => 'Joueur',
        diagnosticLogFile: File(p.join(supportRoot.path, 'launch.log')),
      );
      final prepared = await bootstrap
          .prepare(onStageCompleted: stages.add)
          .catchError((Object error, StackTrace stack) async {
            final diagnostic = File(p.join(supportRoot.path, 'launch.log'));
            if (await diagnostic.exists()) {
              stderr.writeln(await diagnostic.readAsString());
            }
            Error.throwWithStackTrace(error, stack);
          });
      addTearDown(prepared.graph.dispose);
      expect(stages.last, runtime.RuntimeStartupBootstrapStage.runtimeGraph);
      final progress = <runtime.RuntimeInitialMapPreloadProgress>[];
      await prepared.graph.initialMapPreloadPort.preloadInitialMap(
        const runtime.RuntimeInitialMapPreloadRequest.newGame(),
        onProgress: progress.add,
      );
      expect(progress.last.stage, runtime.RuntimeInitialMapPreloadStage.ready);
      expect(progress.last.value, 1);
      final preloader =
          prepared.graph.initialMapPreloadPort
              as runtime.RuntimeInitialMapPreloader;
      final resolvedProject = await assets.resolveReference(launch.project);
      final bundle = preloader.preparedNewGameBundle(
        projectFilePath: resolvedProject.path,
      );
      expect(bundle!.manifest.toJson(), project.toJson());
      expect(bundle.map.toJson(), _map.toJson());
      const defaultProfile = RuntimeResourceProfile();
      expect(defaultProfile.maximumResidentBytes, 64 * 1024 * 1024);
      expect(defaultProfile.maximumTransientBytes, 64 * 1024 * 1024);
      expect(defaultProfile.maximumConcurrentDecodes, 2);
      final budget = bundle.resourceBudget;
      expect(budget.profile.maximumResidentBytes, 256 * 1024 * 1024);
      expect(budget.profile.maximumTransientBytes, 256 * 1024 * 1024);
      expect(budget.profile.maximumConcurrentDecodes, 1);
      expect(
        budget.profile.maximumEncodedBytes,
        defaultProfile.maximumEncodedBytes,
      );
      final reservation = await budget.acquire(
        residentBytes: 80 * 1024 * 1024,
        transientBytes: 160 * 1024 * 1024,
      );
      expect(budget.activeDecodes, 1);
      expect(budget.transientBytes, 160 * 1024 * 1024);
      reservation.commit();
      expect(budget.residentBytes, 80 * 1024 * 1024);
      expect(budget.transientBytes, 0);
      expect(budget.activeDecodes, 0);
      reservation.release();
      expect(budget.residentBytes, 0);
      await expectLater(
        budget.acquire(residentBytes: 257 * 1024 * 1024),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
    },
  );

  test(
    'builder accepts an already partitioned valid project deterministically',
    () {
      final first = _build();
      final payload = <String, List<int>>{
        for (final entry in ZipDecoder().decodeBytes(first.packageBytes))
          if (entry.isFile && entry.name != 'game-manifest.json')
            entry.name: entry.content,
      };
      final rebuilt = const GamePackageBuilder().build(
        manifest: first.manifest,
        payloadFiles: payload,
      );
      expect(rebuilt.packageBytes, first.packageBytes);
    },
  );

  test(
    'Studio native JSON stays loadable independently of publication',
    () async {
      final staged = await _temporaryDirectory();
      final file = _projectFile(staged);
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(_project.toJson()));
      final mapFile = File(p.join(file.parent.path, 'maps/start.json'));
      await mapFile.parent.create(recursive: true);
      await mapFile.writeAsString(jsonEncode(_map.toJson()));
      expect(
        (await loadProjectManifestFromFile(file.path)).toJson(),
        _project.toJson(),
      );
      expect(
        (await loadRuntimeMapBundle(
          projectFilePath: file.path,
          mapId: _map.id,
        )).map.toJson(),
        _map.toJson(),
      );
    },
  );

  for (final corruption in [
    'missing',
    'changed',
    'symlink',
    'directorySymlink',
    'duplicateDescriptor',
  ]) {
    test('installed smoke refuses $corruption catalog objects', () async {
      final built = _build();
      final staged = await _stage(built);
      final objects = Directory(p.join(staged.path, 'project/catalog/objects'));
      final object = objects.listSync().whereType<File>().first;
      if (corruption == 'duplicateDescriptor') {
        final file = _projectFile(staged);
        final text = await file.readAsString();
        await file.writeAsString(
          text.replaceFirst('{', '{"format":"ambiguous-overwritten-format",'),
        );
      } else if (corruption == 'missing') {
        await object.delete();
      } else if (corruption == 'changed') {
        final bytes = await object.readAsBytes();
        final position = bytes.indexWhere(
          (value) => value >= 97 && value <= 122,
        );
        bytes[position] -= 32;
        expect(jsonDecode(utf8.decode(bytes)), isA<Map>());
        await object.writeAsBytes(bytes);
      } else if (corruption == 'symlink') {
        final outside = File(p.join(staged.path, 'outside.json'));
        await object.copy(outside.path);
        await object.delete();
        await Link(object.path).create(outside.path);
      } else {
        final outside = p.join(staged.path, 'outside-objects');
        await objects.rename(outside);
        await Link(objects.path).create(outside);
      }
      await expectLater(
        loadProjectManifestFromFile(_projectFile(staged).path),
        throwsA(isA<ProjectLoadException>()),
      );
      await expectLater(
        loadInstalledProjectSmoke(staged, built.manifest),
        throwsA(isA<ProjectLoadException>()),
      );
    });
  }
}

const _map = MapData(
  id: 'start',
  name: 'Start map',
  size: GridSize(width: 4, height: 4),
);

const _project = ProjectManifest(
  name: 'Partitioned installed game',
  version: ProjectVersion.v8,
  tilesets: [],
  pokemon: ProjectPokemonConfig(ruleset: PokemonRulesetProfile.pokeMapBetaV1),
  maps: [
    ProjectMapEntry(
      id: 'start',
      name: 'Start map',
      relativePath: 'maps/start.json',
    ),
  ],
);

GamePackageBuildResult _build({ProjectManifest project = _project}) =>
    const GamePackageBuilder().build(
      manifest: GamePackageManifest(
        packageFormat: 1,
        gameId: 'games.example.partitioned',
        gameVersion: Version.parse('1.0.0'),
        title: 'Partitioned game',
        author: const GamePackageParty(name: 'PokeMap'),
        compatibility: GamePackageCompatibility(
          minHubVersion: Version.parse('0.1.0'),
          runtimeApiExpression: '>=1.0.0 <2.0.0',
          projectFormat: 'v8',
          saveFormat: 1,
          compatibilityId: 'partitioned',
          requiredCapabilities: const ['map@1'],
        ),
        locales: GamePackageLocales(defaultLocale: 'fr', supported: ['fr']),
        content: GamePackageContent(
          fileCount: 0,
          totalBytes: 0,
          treeSha256: '0' * 64,
          files: const [],
        ),
      ),
      payloadFiles: {
        'project/project.json': utf8.encode(jsonEncode(project.toJson())),
        'project/maps/start.json': utf8.encode(jsonEncode(_map.toJson())),
      },
    );

Future<Directory> _temporaryDirectory() async {
  final directory = await Directory.systemTemp.createTemp('l4-installed-game-');
  addTearDown(() => directory.delete(recursive: true));
  return directory;
}

Future<Directory> _stage(GamePackageBuildResult built) async {
  const GamePackageInspector().inspect(built.packageBytes);
  final directory = await _temporaryDirectory();
  for (final entry in ZipDecoder().decodeBytes(built.packageBytes)) {
    if (!entry.isFile) continue;
    final file = File(p.join(directory.path, entry.name));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.content);
  }
  return directory;
}

File _projectFile(Directory directory) =>
    File(p.join(directory.path, 'project/project.json'));

final class _FixedLaunchResolver implements SessionLaunchRepositoryInterface {
  const _FixedLaunchResolver(this.context);

  final InstalledGameLaunchContext context;

  @override
  Future<InstalledGameLaunchContext> resolve(InstalledGame game) async =>
      context;
}
