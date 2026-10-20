import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart' as runtime;
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/core/ports/game_installation_ports.dart';
import 'package:pokemap_hub/features/installation/data/repositories/game_package_installer.dart';
import 'package:pokemap_hub/features/installation/data/repositories/installed_project_smoke.dart';
import 'package:pokemap_hub/features/installation/data/sources/file_package_source.dart';
import 'package:pokemap_hub/features/preferences/data/repositories/hub_preferences_repository_impl.dart';
import 'package:pokemap_hub/features/saves/data/repositories/hub_save_repository_impl.dart';
import 'package:pokemap_hub/features/session/application/services/hub_runtime_startup_bootstrap.dart';
import 'package:pokemap_hub/features/session/data/repositories/control_profile_repository_impl.dart';
import 'package:pokemap_hub/features/session/data/repositories/installed_game_launch_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final packagePath =
      Platform.environment['POKEMAP_SYNTHETIC_CATALOG_PACKAGE'] ?? '';
  final expectedHash =
      Platform.environment['POKEMAP_SYNTHETIC_CATALOG_PACKAGE_SHA256'] ?? '';
  final receiptPath =
      Platform.environment['POKEMAP_SYNTHETIC_CATALOG_JOURNEY_RECEIPT'] ?? '';
  final installRootPath =
      Platform.environment['POKEMAP_SYNTHETIC_CATALOG_INSTALL_ROOT'] ?? '';

  test(
    'same synthetic archive installs and boots through the real Hub catalog',
    () async {
      final elapsed = Stopwatch()..start();
      expect(
        RegExp(r'^[0-9a-f]{64}$').hasMatch(expectedHash),
        isTrue,
        reason: 'The opt-in journey requires the frozen package SHA-256.',
      );
      final package = File(packagePath);
      expect(
        (await sha256.bind(package.openRead()).first).toString(),
        expectedHash,
      );
      final inspector = GamePackageInspector(
        hostCompatibility: aveluneHostCompatibility(),
      );
      final source = await FilePackageSource.open(package);
      late GamePackageInspectionResult inspection;
      try {
        inspection = inspector.inspectSourceSync(source);
      } finally {
        await source.close();
      }
      expect(inspection.receipt.packageSha256, expectedHash);
      expect(
        inspection.compatibility!.decision,
        GamePackageCompatibilityDecision.accept,
      );
      final supportRoot = installRootPath.isEmpty
          ? await Directory.systemTemp.createTemp('synthetic-hub-')
          : Directory(installRootPath);
      if (installRootPath.isEmpty) {
        addTearDown(() => supportRoot.delete(recursive: true));
      } else {
        expect(await supportRoot.exists(), isFalse);
        await supportRoot.create(recursive: true);
      }
      final installer = GamePackageInstaller(
        supportRoot: supportRoot,
        inspector: inspector,
        availableDiskBytes: (_) async => 1024 * 1024 * 1024,
        loadSmoke: loadInstalledProjectSmoke,
        prepareSavesForUpdate: (_, __) async => const SaveUpdatePreparation(),
      );
      final installed = await installer.install(
        package,
        source: GamePackageInstallSource.localFile,
      );
      expect(installed.receipt.packageSha256, expectedHash);
      expect(installed.alreadyInstalled, isFalse);
      final resolver = InstalledGameLaunchResolver(
        supportRoot: supportRoot,
        hostCompatibility: aveluneHostCompatibility(),
      );
      final launch = await resolver.resolve(installed.game);
      final projectFile = await launch.assets.resolveReference(launch.project);
      final descriptor =
          jsonDecode(await File(projectFile.path).readAsString()) as Map;
      expect(descriptor.keys.toSet(), {'format', 'version', 'kind', 'root'});
      expect(descriptor['format'], 'avelune.portable-catalog');
      expect(descriptor['version'], 2);
      expect(await File(projectFile.path).length(), lessThan(4096));
      final stages = <runtime.RuntimeStartupBootstrapStage>[];
      final bootstrap = HubRuntimeStartupBootstrap(
        supportRoot: supportRoot,
        saveRepositoryFactory: (root, identity) =>
            HubSaveStore(supportRoot: root, identity: identity),
        preferencesRepository: HubPreferencesStore(supportRoot: supportRoot),
        controlProfileRepository: HubControlProfileStore(
          supportRoot: supportRoot,
        ),
        launchResolver: resolver,
        game: installed.game,
        onHubRequested: () async {},
        mountGame: (_) async => fail('Preparation must not mount a Player.'),
        unmountGame: (_) async {},
        stopIntroPlayback: () async {},
        defaultProfileDisplayNameForLocale: (_) => 'Synthetic player',
        diagnosticLogFile: File(p.join(supportRoot.path, 'startup.log')),
      );
      final prepared = await bootstrap.prepare(onStageCompleted: stages.add);
      addTearDown(prepared.graph.dispose);
      final progress = <runtime.RuntimeInitialMapPreloadProgress>[];
      await prepared.graph.initialMapPreloadPort.preloadInitialMap(
        const runtime.RuntimeInitialMapPreloadRequest.newGame(),
        onProgress: progress.add,
      );
      expect(progress.last.stage, runtime.RuntimeInitialMapPreloadStage.ready);
      final preloader =
          prepared.graph.initialMapPreloadPort
              as runtime.RuntimeInitialMapPreloader;
      final bundle = preloader.preparedNewGameBundle(
        projectFilePath: projectFile.path,
      )!;
      final catalog = bundle.projectCatalog!;
      expect(catalog.projectMetadata.elements, isEmpty);
      expect(catalog.projectMetadata.tilesets, isEmpty);
      expect(bundle.map.id, 'synthetic-map-0000');
      expect(bundle.manifest.characters.single.id, 'synthetic-player');
      expect(bundle.runtimeImageAbsolutePathsById, isNotEmpty);
      final config =
          catalog.projectMetadata.globalProperties['syntheticQualification']
              as Map;
      expect(config['version'], 1);
      expect(catalog.projectMetadata.maps.length, config['mapCount']);
      expect(
        bundle.manifest.elements.length,
        lessThan(config['definitionCount'] as int),
      );
      final publication = await PortableProjectCatalog.open(
        Map<String, Object?>.from(descriptor),
        readObject: (reference) => File(
          p.join(
            p.dirname(projectFile.path),
            PortableCatalogPublication.objectPath(reference),
          ),
        ).readAsBytes(),
      );
      var definitionCount = 0;
      String? cursor;
      do {
        final page = await publication.snapshot.page(
          kind: CatalogDefinitionKind.element,
          limit: 128,
          cursor: cursor,
        );
        definitionCount += page.items.length;
        cursor = page.nextCursor;
      } while (cursor != null);
      expect(definitionCount, config['definitionCount']);
      final last = await loadRuntimeMapBundle(
        projectFilePath: projectFile.path,
        projectCatalog: catalog,
        mapId: catalog.projectMetadata.maps.last.id,
      );
      expect(last.projectCatalog, same(catalog));
      expect(last.map.id, catalog.projectMetadata.maps.last.id);
      expect(
        last.manifest.elements.length,
        lessThan(config['definitionCount'] as int),
      );
      expect(
        (await sha256.bind(package.openRead()).first).toString(),
        expectedHash,
      );
      if (receiptPath.isNotEmpty) {
        final receipt = File(receiptPath);
        expect(await receipt.exists(), isFalse);
        await receipt.parent.create(recursive: true);
        final evidence = {
          'receiptVersion': 1,
          'kind': 'syntheticCatalogPackageJourney',
          'packageSha256': expectedHash,
          'inspection': inspection.receipt.toJson(),
          'fixtureParameters': config,
          'archivedDefinitionCount': definitionCount,
          'descriptorBytes': await File(projectFile.path).length(),
          'startupStages': stages.map((stage) => stage.name).toList(),
          'initialMapId': bundle.map.id,
          'initialScopedDefinitions': bundle.manifest.elements.length,
          'initialImageIds': bundle.runtimeImageAbsolutePathsById.keys.toList(),
          'lastMapId': last.map.id,
          'lastScopedDefinitions': last.manifest.elements.length,
          'sharedCatalog': identical(last.projectCatalog, catalog),
          'sourceWorkspaceRequired': false,
          'installedProjectRoot': p.dirname(projectFile.path),
          'supportRoot': supportRoot.path,
          'elapsedMicroseconds': elapsed.elapsedMicroseconds,
          'maxRssBytes': ProcessInfo.maxRss,
          'rssScope': 'testProcessLifetime',
        };
        await receipt.writeAsString('${jsonEncode(evidence)}\n', flush: true);
      }
    },
    skip: packagePath.isEmpty
        ? 'Opt-in: frozen synthetic package required.'
        : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
