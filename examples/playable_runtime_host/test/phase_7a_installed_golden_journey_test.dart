import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/driver/selbrume_evaluation_driver.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_scenario_runner.dart';
import 'package:pokemap_loader/src/evaluation/scenario/evaluation_scenario_parser.dart';
import 'package:pokemap_loader/src/project_tree_digest.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Phase 7A certifies all 19 MVP criteria from the installed package',
    () async {
      final repositoryRoot = _findRepositoryRoot();
      final sourceProjectRoot = Directory(
        p.join(repositoryRoot.path, 'selbrume'),
      );
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'pokemap-phase-7a-installed-golden-',
      );
      addTearDown(() => temporaryRoot.delete(recursive: true));
      final evidenceOutputPath =
          Platform.environment['POKEMAP_PHASE7A_EVIDENCE_OUTPUT'];
      final evidencePackagePath =
          Platform.environment['POKEMAP_PHASE7A_PACKAGE_OUTPUT'];
      final evidenceSupportRootPath =
          Platform.environment['POKEMAP_PHASE7A_SUPPORT_ROOT'];
      final evidenceMode = evidenceOutputPath != null ||
          evidencePackagePath != null ||
          evidenceSupportRootPath != null;
      if (evidenceMode &&
          (evidenceOutputPath == null ||
              evidencePackagePath == null ||
              evidenceSupportRootPath == null)) {
        fail(
          'All three POKEMAP_PHASE7A evidence paths must be provided.',
        );
      }
      final releaseCandidateCommit = evidenceMode
          ? await _requireCleanReleaseCandidate(repositoryRoot)
          : null;

      final packageFile = File(evidencePackagePath ??
          p.join(temporaryRoot.path, 'selbrume.pokemapgame'));
      if (evidenceMode && await packageFile.exists()) {
        fail('The evidence package output must not already exist.');
      }
      final artifact = await const GamePackageExportService().exportToFile(
        projectRoot: sourceProjectRoot,
        profile: GamePackageExportProfile(
          gameId: 'games.pokemap.selbrume',
          gameVersion: '1.0.0',
          title: 'Selbrume',
          description: 'Golden gameplay journey for the PokeMap MVP.',
          authorName: 'PokeMap',
          defaultLocale: 'fr',
          supportedLocales: const <String>['fr'],
          requiredCapabilities: const <String>[
            'dialogue.choices@1',
            'map@1',
            'overworld.menu@1',
            'world.shop@1',
          ],
        ),
        outputFile: packageFile,
      );
      final compatibility = _hostCompatibility(
        artifact.manifest.compatibility.projectFormat,
      );
      final inspector = GamePackageInspector(
        hostCompatibility: compatibility,
      );
      final supportRoot = Directory(
        evidenceSupportRootPath ?? p.join(temporaryRoot.path, 'PokeMap'),
      );
      if (evidenceMode && await supportRoot.exists()) {
        fail('The evidence support root must not already exist.');
      }
      var loadSmokePassed = false;
      final installation = await GamePackageInstaller(
        supportRoot: supportRoot,
        inspector: inspector,
        availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
        loadSmoke: (_, __) async {
          loadSmokePassed = true;
        },
        prepareSavesForUpdate: (_, __) async => const SaveUpdatePreparation(),
        now: () => DateTime.utc(2026, 7, 27, 12),
      ).install(
        packageFile,
        source: GamePackageInstallSource.localFile,
      );
      final launch = await InstalledGameLaunchResolver(
        supportRoot: supportRoot,
        hostCompatibility: compatibility,
      ).resolve(installation.game);
      final installedProjectFile = await launch.assets.resolveReference(
        launch.project,
      );
      final installedProjectRoot = installedProjectFile.parent;
      final canonicalSupportRoot = await supportRoot.resolveSymbolicLinks();

      expect(loadSmokePassed, isTrue);
      expect(artifact.certification.isCertified, isTrue);
      expect(
        installation.receipt.packageSha256,
        artifact.packageSha256,
      );
      expect(
        p.isWithin(canonicalSupportRoot, installedProjectFile.path),
        isTrue,
        reason: 'The certified run must use the Hub-installed project.',
      );
      expect(
        p.equals(installedProjectRoot.path, sourceProjectRoot.path),
        isFalse,
      );

      final scenario = const EvaluationScenarioParser().parseString(
        File(
          p.join(
            'evaluation',
            'scenarios',
            'selbrume',
            'mvp_certification.json',
          ),
        ).readAsStringSync(),
      );
      final driver = await SelbrumeEvaluationDriver.start(
        projectRoot: installedProjectRoot,
        runId: 'phase-7a-installed-golden',
      );
      addTearDown(driver.dispose);
      final result = await EvaluationScenarioRunner(
        driver: driver,
        runIdFactory: () => 'phase-7a-installed-golden',
      ).run(scenario);

      final expectedCriterionIds = <String>{
        for (var index = 1; index <= 19; index += 1)
          'MVP-${index.toString().padLeft(2, '0')}',
      };
      expect(result.status, EvaluationRunStatus.succeeded);
      expect(result.evidenceLevel, EvaluationEvidenceLevel.releaseEvidence);
      expect(result.shortcutsUsed, isEmpty);
      expect(
        scenario.criteria.map((criterion) => criterion.id).toSet(),
        expectedCriterionIds,
      );
      expect(result.productCriteria, hasLength(19));
      expect(
        result.productCriteria.map((criterion) => criterion.id).toSet(),
        expectedCriterionIds,
      );
      expect(
        result.productCriteria,
        everyElement(
          isA<EvaluationProductCriterionResult>().having(
            (criterion) => criterion.passed,
            'passed',
            isTrue,
          ),
        ),
      );

      expect(driver.gameCompletionRequests, hasLength(1));
      final completion = driver.gameCompletionRequests.single;
      expect(completion.endingId, 'ending.selbrume-sauvee');
      expect(completion.outcome, GameCompletionOutcome.victory);
      expect(completion.result.title, 'Selbrume est sauvée');
      expect(completion.credits.title, 'Crédits — Selbrume');
      expect(completion.destination, GameCompletionDestination.hub);
      expect(completion.allowPostGameContinue, isFalse);

      if (evidenceMode) {
        final sourceProjectTreeHash =
            await const ProjectTreeDigest().compute(sourceProjectRoot);
        final installedProjectTreeHash =
            await const ProjectTreeDigest().compute(installedProjectRoot);
        final installedProjectEntrySha256 =
            await sha256.bind(installedProjectFile.openRead()).first;
        final scenarioFile = File(
          p.join(
            'evaluation',
            'scenarios',
            'selbrume',
            'mvp_certification.json',
          ),
        );
        final scenarioSha256 = await sha256.bind(scenarioFile.openRead()).first;
        final evidence = <String, Object?>{
          'schemaVersion': 1,
          'capturedAtUtc': DateTime.now().toUtc().toIso8601String(),
          'releaseCandidateCommit': releaseCandidateCommit,
          'workingTreeClean': true,
          'dirtyPaths': const <String>[],
          'sourceProject': <String, Object?>{
            'relativePath': 'selbrume',
            'treeHashSha256': sourceProjectTreeHash,
          },
          'scenario': <String, Object?>{
            'relativePath':
                'examples/playable_runtime_host/evaluation/scenarios/'
                    'selbrume/mvp_certification.json',
            'sha256': scenarioSha256.toString(),
            'policy': scenario.policy.name,
          },
          'package': <String, Object?>{
            'relativePath': p
                .relative(packageFile.path, from: repositoryRoot.path)
                .replaceAll(r'\', '/'),
            'sha256': artifact.packageSha256,
            'bytes': await packageFile.length(),
            'certified': artifact.certification.isCertified,
          },
          'inspection': artifact.inspection.receipt.toJson(),
          'installation': <String, Object?>{
            ...installation.receipt.toJson(),
            'alreadyInstalled': installation.alreadyInstalled,
            'loadSmokePassed': loadSmokePassed,
            'supportRootRelativePath': p
                .relative(supportRoot.path, from: repositoryRoot.path)
                .replaceAll(r'\', '/'),
          },
          'installedProject': <String, Object?>{
            'entryRelativePath': p
                .relative(installedProjectFile.path, from: supportRoot.path)
                .replaceAll(r'\', '/'),
            'entrySha256': installedProjectEntrySha256.toString(),
            'treeHashSha256': installedProjectTreeHash,
            'launchHandle': launch.installedVersionHandle,
          },
          'evaluation': <String, Object?>{
            'status': result.status.name,
            'evidenceLevel': result.evidenceLevel.name,
            'shortcutsUsed': result.shortcutsUsed,
            'criteria': <Map<String, Object?>>[
              for (final criterion in result.productCriteria)
                <String, Object?>{
                  'id': criterion.id,
                  'passed': criterion.passed,
                  'summary': criterion.summary,
                },
            ],
          },
          'completion': <String, Object?>{
            'endingId': completion.endingId,
            'outcome': completion.outcome.name,
            'resultTitle': completion.result.title,
            'creditsTitle': completion.credits.title,
            'destination': completion.destination.name,
            'allowPostGameContinue': completion.allowPostGameContinue,
          },
          'checks': <String, Object?>{
            'hashesAgree': artifact.packageSha256 ==
                    artifact.inspection.receipt.packageSha256 &&
                artifact.inspection.receipt.packageSha256 ==
                    installation.receipt.packageSha256 &&
                artifact.inspection.receipt.treeSha256 ==
                    installation.receipt.treeSha256,
            'installedLaunchResolved': true,
            'loadSmokePassed': loadSmokePassed,
            'all19CriteriaPassed': result.productCriteria.length == 19 &&
                result.productCriteria.every(
                  (criterion) => criterion.passed,
                ),
          },
          'status': 'passed',
        };
        final evidenceFile = File(evidenceOutputPath!);
        await evidenceFile.parent.create(recursive: true);
        await evidenceFile.writeAsString(
          '${const JsonEncoder.withIndent('  ').convert(evidence)}\n',
          flush: true,
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

GamePackageHostCompatibility _hostCompatibility(String projectFormat) =>
    GamePackageHostCompatibility(
      hubVersion: Version.parse('1.2.0'),
      runtimeApiVersion: Version.parse('1.4.0'),
      capabilities: const <String>{
        'dialogue.choices@1',
        'map@1',
        'overworld.menu@1',
        'world.shop@1',
      },
      supportedProjectFormats: <String>{projectFormat},
      currentProjectFormat: projectFormat,
      supportedSaveFormats: const <int>{1},
    );

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        Directory(p.join(current.path, 'selbrume')).existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate the PokeMap repository root.');
    }
    current = parent;
  }
}

Future<String> _requireCleanReleaseCandidate(
  Directory repositoryRoot,
) async {
  final status = await Process.run(
    'git',
    const <String>['status', '--porcelain', '--untracked-files=all'],
    workingDirectory: repositoryRoot.path,
  );
  if (status.exitCode != 0 || (status.stdout as String).trim().isNotEmpty) {
    throw StateError(
      'Release evidence requires a clean candidate worktree.',
    );
  }
  final head = await Process.run(
    'git',
    const <String>['rev-parse', 'HEAD'],
    workingDirectory: repositoryRoot.path,
  );
  if (head.exitCode != 0) {
    throw StateError('Unable to resolve the release candidate commit.');
  }
  return (head.stdout as String).trim();
}
