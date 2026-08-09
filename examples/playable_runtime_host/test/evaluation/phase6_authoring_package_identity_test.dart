import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pokemap_loader/src/evaluation/authoring/evaluation_distribution_package_service.dart';
import 'package:pokemap_loader/src/project_tree_digest.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'public authoring creates the slice and installed bytes boot in production runtime',
    () async {
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'pmcp072_authoring_package_',
      );
      addTearDown(() async {
        if (await temporaryRoot.exists()) {
          await temporaryRoot.delete(recursive: true);
        }
      });
      final projectRoot = Directory(p.join(temporaryRoot.path, 'project'));
      await projectRoot.create();
      await File(
        p.join('phase6_authoring_golden_slice', 'project.json'),
      ).copy(p.join(projectRoot.path, 'project.json'));

      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: <String>[projectRoot.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore(
        tokenFactory: (prefix) => '${prefix}pmcp072',
      );
      final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ).openProject(projectRoot.path);
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final mutations = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
      );
      await mutations.attachProject(
        projectRootPath: projectRoot.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      addTearDown(() => mutations.detachWorkspace(opened.workspaceHandle));
      final before = await snapshots.load(opened.projectHandle);
      expect(before.manifest.maps, isEmpty);

      final planned = await mutations.plan(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'request-create-golden-map',
          actionId: 'map.create',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: const <String, Object?>{
            'mapId': 'golden_api_map',
            'name': 'Golden API Map',
            'width': 6,
            'height': 4,
          },
          expectedRevision: before.revision,
          idempotencyKey: 'idem-create-golden-map',
        ),
      );
      final applied = await mutations.apply(
        opened.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation-create-golden-map',
      );
      expect(
        (applied['receipt']! as Map<String, Object?>)['status'],
        'applied',
      );
      final authored = await snapshots.load(opened.projectHandle);
      expect(authored.manifest.maps.single.id, 'golden_api_map');
      final sourceRevision =
          'sha256:${await const ProjectTreeDigest().compute(projectRoot)}';

      final hostCompatibility = GamePackageHostCompatibility(
        hubVersion: Version.parse('1.2.0'),
        runtimeApiVersion: Version.parse('1.4.0'),
        capabilities: const <String>{'map@1'},
        supportedProjectFormats: const <String>{'v2'},
        currentProjectFormat: 'v2',
        supportedSaveFormats: const <int>{1},
      );
      final inspector = GamePackageInspector(
        hostCompatibility: hostCompatibility,
      );
      final supportRoot = Directory(p.join(temporaryRoot.path, 'support'));
      String? runtimeLoadedMapId;
      final packageService = EvaluationDistributionPackageService(
        inspector: inspector,
        inputLoader: (request) async {
          expect(request.sourceRevision, sourceRevision);
          return EvaluationDistributionPackageInput(
            manifest: _packageManifest(),
            payloadFiles: <String, List<int>>{
              'project/project.json':
                  await File(p.join(projectRoot.path, 'project.json'))
                      .readAsBytes(),
              'project/maps/golden_api_map.json': await File(
                p.join(projectRoot.path, 'maps', 'golden_api_map.json'),
              ).readAsBytes(),
            },
          );
        },
        installer: ({
          required artifact,
          required packageBytes,
          required inspection,
        }) async {
          final exportedFile = File(
            p.join(temporaryRoot.path, 'golden-api.avelunegame'),
          );
          await exportedFile.writeAsBytes(packageBytes, flush: true);
          final installation = await GamePackageInstaller(
            supportRoot: supportRoot,
            inspector: inspector,
            availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
            loadSmoke: (stagedVersion, manifest) async {
              final bundle = await loadRuntimeMapBundle(
                projectFilePath: p.join(
                  stagedVersion.path,
                  'project',
                  'project.json',
                ),
                mapId: 'golden_api_map',
              );
              final game = RuntimeMapGame(bundle: bundle);
              game.onGameResize(Vector2(320, 240));
              await game.onLoad();
              runtimeLoadedMapId = bundle.map.id;
            },
            prepareSavesForUpdate: (_, __) async =>
                const SaveUpdatePreparation(),
            now: () => DateTime.utc(2026, 7, 31, 18),
          ).install(
            exportedFile,
            source: GamePackageInstallSource.localExport,
          );
          final launch = await InstalledGameLaunchResolver(
            supportRoot: supportRoot,
            hostCompatibility: hostCompatibility,
          ).resolve(installation.game);
          final installedProjectFile =
              await launch.assets.resolveReference(launch.project);
          final installedBundle = await loadRuntimeMapBundle(
            projectFilePath: installedProjectFile.path,
            mapId: 'golden_api_map',
          );
          final installedGame = RuntimeMapGame(bundle: installedBundle);
          installedGame.onGameResize(Vector2(320, 240));
          await installedGame.onLoad();
          runtimeLoadedMapId = installedBundle.map.id;
          expect(
            inspection.receipt.packageSha256,
            installation.receipt.packageSha256,
          );
          return EvaluationInstalledPackageEvidence(
            packageSha256: installation.receipt.packageSha256,
            passed: true,
            evidenceRef: 'hub-install://${installation.receipt.gameId}/'
                '${installation.receipt.packageSha256}',
          );
        },
      );

      final receipt =
          await DistributionPackageActions(port: packageService).release(
        request: PackageBuildRequest(
          requestId: 'request-release-golden',
          packageId: 'golden-api',
          projectId: 'phase6-golden-project',
          sourceRevision: sourceRevision,
          releaseVersion: '1.0.0',
        ),
        regressionGates: <PackageReleaseGateEvidence>[
          PackageReleaseGateEvidence(
            id: 'authoring.public-api',
            passed: true,
            summary: 'map.create plan/apply created the fixture map.',
            evidenceRef: 'authoring-receipt://operation-create-golden-map',
          ),
          PackageReleaseGateEvidence(
            id: 'runtime.golden-slice',
            passed: true,
            summary: 'The installed map booted through RuntimeMapGame.',
            evidenceRef: 'test://pmcp072/production-runtime-smoke',
          ),
          PackageReleaseGateEvidence(
            id: 'regression.matrix',
            passed: true,
            summary: 'The PMCP-072 scoped regression matrix passed.',
            evidenceRef: 'test://pmcp072/regression-matrix',
          ),
        ],
        gameplayLots: <GameplayLotReleaseMapping>[
          for (var id = 180; id <= 184; id += 1)
            GameplayLotReleaseMapping(lotId: 'FG-$id', status: 'DONE'),
          GameplayLotReleaseMapping(lotId: 'FG-185', status: 'PARTIAL'),
        ],
      );

      expect(runtimeLoadedMapId, 'golden_api_map');
      expect(receipt.isReady, isTrue);
      expect(receipt.packageDigest, receipt.installedDigest);
      expect(
        receipt.gates,
        everyElement(
          isA<PackageReleaseGateEvidence>()
              .having((gate) => gate.passed, 'passed', isTrue)
              .having((gate) => gate.evidenceRef, 'evidenceRef', isNotEmpty),
        ),
      );
      expect(
        receipt.gameplayLots,
        everyElement(
          isA<GameplayLotReleaseMapping>().having(
            (mapping) => mapping.updateApplied,
            'updateApplied',
            isFalse,
          ),
        ),
      );
      final installedManifest = ProjectManifest.fromJson(
        (jsonDecode(
          await File(
            p.join(
              supportRoot.path,
              'games',
              'games.example.pmcp072-golden',
              'versions',
              '1.0.0',
              'project',
              'project.json',
            ),
          ).readAsString(),
        ) as Map)
            .cast<String, dynamic>(),
      );
      expect(installedManifest.maps.single.id, 'golden_api_map');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

GamePackageManifest _packageManifest() => GamePackageManifest(
      packageFormat: 1,
      gameId: 'games.example.pmcp072-golden',
      gameVersion: Version.parse('1.0.0'),
      title: 'PMCP-072 Golden API',
      author: const GamePackageParty(name: 'PokeMap'),
      compatibility: GamePackageCompatibility(
        minHubVersion: Version.parse('0.1.0'),
        runtimeApiExpression: '>=1.0.0 <2.0.0',
        projectFormat: 'v2',
        saveFormat: 1,
        compatibilityId: 'main',
        requiredCapabilities: const <String>['map@1'],
      ),
      locales: GamePackageLocales(
        defaultLocale: 'fr',
        supported: const <String>['fr'],
      ),
      presentation: const GamePackagePresentation(),
      content: GamePackageContent(
        fileCount: 0,
        totalBytes: 0,
        treeSha256: '0' * 64,
        files: const <GamePackageFileEntry>[],
      ),
    );
