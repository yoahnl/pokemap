import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter/converter_app.dart';
import 'package:avelune_converter/desktop_services.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import '../../../packages/avelune_converter_adapters/test/support/literal_tile_fixture.dart';
import '../../../packages/avelune_converter_adapters/test/support/native_reproducibility.dart';

void main() {
  final executable = Platform.environment['AVELUNE_AC16_CLI_EXECUTABLE'];
  final evidencePath = Platform.environment['AVELUNE_AC16_EVIDENCE_PATH'];
  final skip = !Platform.isMacOS || executable == null || executable.isEmpty;

  testWidgets(
    'an extracted CLI plan publishes identical native output through desktop review',
    (tester) async {
      final workflows = <ConverterWorkflow>[];
      final invocations = <Map<String, Object?>>[];
      Directory? ownedRoot;
      ConverterWorkflow? desktopWorkflow;
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      try {
        final setup = (await tester.runAsync(() async {
          final cli = executable!;
          expect(path.isAbsolute(cli), isTrue);
          expect(
            await FileSystemEntity.type(cli, followLinks: false),
            FileSystemEntityType.file,
          );
          final cliStat = await File(cli).stat();
          expect(
            cliStat.mode & 0x49,
            isNot(0),
            reason: 'The explicitly selected CLI must be executable.',
          );
          final cliBytes = await File(cli).readAsBytes();
          expect(cliBytes.length, greaterThan(4));
          final magic = cliBytes
              .take(4)
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();
          expect(
            magic,
            isIn({
              'cffaedfe',
              'feedfacf',
              'cafebabe',
              'bebafeca',
              'cafebabf',
              'bfbafeca',
            }),
            reason: 'Use the actual extracted Mach-O AOT executable.',
          );
          final cliHash = literalFixtureHash(cliBytes).value;
          final temporary = await Directory.systemTemp.createTemp(
            'ac16-cli-desktop-plan-parity-',
          );
          ownedRoot = Directory(await temporary.resolveSymbolicLinks());
          final root = ownedRoot!;
          final output = await Directory(path.join(root.path, 'output'))
              .create();
          final fixture = await LiteralTileFixture.create(
            namespace: 'original-ac16-cli-desktop-parity',
            sourceRootPath: path.join(root.path, 'source'),
            maps: [LiteralFixtureMap(id: 1), LiteralFixtureMap(id: 8)],
          );
          final sourcePath = fixture.sourceRootPath!;
          final sourceBefore = await readNativeStudyTree(sourcePath);
          expect(sourceBefore.keys, isNot(contains('Data/Scripts.rxdata')));
          expect(
            sourceBefore.keys.any((name) => name.endsWith('.rb')),
            isFalse,
          );
          final planPath = path.join(root.path, 'original-plan.json');
          final destination = path.join(output.path, 'native-study');
          final preserved = path.join(
            output.path,
            'native-study.cli-preserved',
          );
          final planned = await _invokeCli(cli, [
            'plan',
            '--source',
            sourcePath,
            '--namespace',
            'original-ac16-cli-desktop-parity',
            '--destination',
            destination,
            '--maps',
            '1,8',
            '--name',
            'Original CLI desktop parity fixture',
            '--plan',
            planPath,
            '--ack-profile',
            '--offline',
            '--json',
          ], invocations);
          final recipe = await const LocalStudyPlanStore().read(planPath);
          expect(planned, recipe.toJson());
          expect(recipe.settings.selectedSourceMapIds, [1, 8]);
          expect(await Directory(destination).exists(), isFalse);
          final recipeBytes = await File(planPath).readAsBytes();
          final recipeBytesHash = literalFixtureHash(recipeBytes).value;
          final captureWorkflow = ConverterWorkflow();
          workflows.add(captureWorkflow);
          final prepared = await captureWorkflow.restoreStudyPlanRecipe(recipe);
          expect(prepared.canApprove, isTrue);
          expect(prepared.nativeDraft, isNotNull);
          expect(captureWorkflow.state.approval, isNull);
          expect(captureWorkflow.state.result, isNull);
          expect(prepared.nativeDraft!.canonicalHash, recipe.nativeDraftHash);
          expect(prepared.preparationHash, recipe.preparationHash);
          expect(
            captureWorkflow.exportStudyPlanRecipe().canonicalHash,
            recipe.canonicalHash,
          );
          final operations = List<String>.unmodifiable(
            prepared.nativeDraft!.mutations.map(
              (mutation) => mutation.operationId.value,
            ),
          );
          expect(operations, isNotEmpty);
          expect(operations.length, lessThanOrEqualTo(2048));
          expect(operations.toSet(), hasLength(operations.length));
          final expectations = <String, Object?>{
            'kind': 'nativeReproducibilityExpectations',
            'version': 1,
            'recipeHash': recipe.canonicalHash.value,
            'nativeDraftHash': recipe.nativeDraftHash.value,
            'approvedPlanHash': recipe.approvedPlanHash.value,
            'operationIds': operations,
          };
          final expectationsBytes = utf8.encode(jsonEncode(expectations));
          final expectationsPath = path.join(root.path, 'expectations.json');
          await File(expectationsPath)
              .writeAsBytes(expectationsBytes, flush: true);
          final expectationsHash = literalFixtureHash(expectationsBytes).value;
          expect(await readNativeStudyTree(sourcePath), sourceBefore);
          expect(await Directory(destination).exists(), isFalse);
          expect(await output.list().toList(), isEmpty);
          final wrongHash =
              '${recipe.approvedPlanHash.value[0] == '0' ? '1' : '0'}'
              '${recipe.approvedPlanHash.value.substring(1)}';
          final rejected = await _invokeCli(
            cli,
            [
              'convert',
              '--plan',
              planPath,
              '--approve-plan',
              wrongHash,
              '--offline',
              '--json',
            ],
            invocations,
            expectedExit: 7,
          );
          expect(rejected.keys.toSet(), {
            'code',
            'message',
            'promotionMayHaveOccurred',
          });
          expect(rejected['code'], 'workflow.stale_approval');
          expect(rejected['message'], isA<String>());
          expect(rejected['promotionMayHaveOccurred'], isFalse);
          expect(await Directory(destination).exists(), isFalse);
          expect(await output.list().toList(), isEmpty);
          expect(await File(planPath).readAsBytes(), recipeBytes);
          expect(await readNativeStudyTree(sourcePath), sourceBefore);
          expect(captureWorkflow.state.approval, isNull);
          final converted = await _invokeCli(cli, [
            'convert',
            '--plan',
            planPath,
            '--approve-plan',
            recipe.approvedPlanHash.value,
            '--offline',
            '--json',
          ], invocations);
          expect(converted.keys.toSet(), {
            'kind',
            'version',
            'projectPath',
            'published',
            'verified',
            'playableCertified',
            'sourceUnchanged',
            'nativeRevision',
            'approvedPlanHash',
            'preparationHash',
            'sourceSnapshotHash',
            'journalPath',
            'stagingPath',
          });
          expect(converted['kind'], 'converterStudyResult');
          expect(converted['version'], 1);
          expect(converted['projectPath'], destination);
          expect(converted['published'], isTrue);
          expect(converted['verified'], isTrue);
          expect(converted['sourceUnchanged'], isTrue);
          expect(converted['playableCertified'], isFalse);
          expect(converted['approvedPlanHash'], recipe.approvedPlanHash.value);
          expect(converted['preparationHash'], recipe.preparationHash.value);
          expect(
            converted['sourceSnapshotHash'],
            recipe.sourceSnapshotHash.value,
          );
          final verified = await _invokeCli(cli, [
            'verify',
            '--project',
            destination,
            '--offline',
            '--json',
          ], invocations);
          expect(verified.keys.toSet(), {
            'kind',
            'version',
            'projectPath',
            'nativeRevision',
            'mapCount',
            'assetCount',
            'verified',
            'playableCertified',
          });
          expect(verified['kind'], 'nativeStudyVerification');
          expect(verified['version'], 1);
          expect(verified['projectPath'], destination);
          expect(verified['verified'], isTrue);
          expect(verified['playableCertified'], isFalse);
          expect(verified['mapCount'], 2);
          expect(verified['assetCount'], greaterThan(0));
          expect(verified['nativeRevision'], converted['nativeRevision']);
          final firstOutput = await readNativeStudyTree(destination);
          final firstOutputModes = await _fileModes(destination);
          expect(path.dirname(preserved), path.dirname(destination));
          expect(
            await FileSystemEntity.type(preserved, followLinks: false),
            FileSystemEntityType.notFound,
          );
          expect(
            await FileSystemEntity.type(destination, followLinks: false),
            FileSystemEntityType.directory,
          );
          await Directory(destination).rename(preserved);
          expect(await Directory(destination).exists(), isFalse);
          expect(await readNativeStudyTree(preserved), firstOutput);
          expect(await _fileModes(preserved), firstOutputModes);
          expect(await File(planPath).readAsBytes(), recipeBytes);
          expect(await readNativeStudyTree(sourcePath), sourceBefore);
          await captureWorkflow.dispose();
          workflows.remove(captureWorkflow);
          return (
            cli: cli,
            cliHash: cliHash,
            root: root,
            output: output,
            sourcePath: sourcePath,
            sourceBefore: sourceBefore,
            planPath: planPath,
            recipe: recipe,
            recipeBytes: recipeBytes,
            recipeBytesHash: recipeBytesHash,
            expectations: expectations,
            expectationsPath: expectationsPath,
            expectationsBytes: expectationsBytes,
            expectationsHash: expectationsHash,
            operations: operations,
            destination: destination,
            preserved: preserved,
            firstOutput: firstOutput,
            firstOutputModes: firstOutputModes,
            cliResult: converted,
            cliVerification: verified,
          );
        }))!;
        final pickedKinds = <ConverterPathKind>[];
        await tester.pumpWidget(
          ConverterApp(
            workflowFactory: () {
              final workflow = ConverterWorkflow();
              workflows.add(workflow);
              desktopWorkflow = workflow;
              return workflow;
            },
            pathPicker: (kind) async {
              pickedKinds.add(kind);
              return kind == ConverterPathKind.planFile ? setup.planPath : null;
            },
            sessionStore: LocalReviewSessionStore(
              rootPath: path.join(setup.root.path, 'sessions'),
            ),
          ),
        );
        await _tap(tester, find.byKey(const ValueKey('load-conversion-plan')));
        await _waitFor(
          tester,
          () =>
              desktopWorkflow?.state.failure != null ||
              desktopWorkflow?.state.prepared != null &&
                  !desktopWorkflow!.state.isBusy &&
                  find
                      .textContaining('Une nouvelle approbation')
                      .evaluate()
                      .isNotEmpty,
          'fresh desktop plan recomposition',
        );
        final desktop = desktopWorkflow!;
        expect(desktop.state.failure, isNull);
        expect(pickedKinds, [ConverterPathKind.planFile]);
        expect(desktop.state.prepared, isNotNull);
        expect(desktop.state.prepared!.canApprove, isTrue);
        expect(
          desktop.exportStudyPlanRecipe().canonicalHash,
          setup.recipe.canonicalHash,
        );
        expect(
          desktop.state.prepared!.nativeDraft!.canonicalHash,
          setup.recipe.nativeDraftHash,
        );
        expect(
          desktop.state.prepared!.nativeDraft!.mutations
              .map((mutation) => mutation.operationId.value)
              .toList(),
          setup.operations,
        );
        expect(desktop.state.approval, isNull);
        expect(desktop.state.result, isNull);
        await tester.runAsync(() async {
          expect(await Directory(setup.destination).exists(), isFalse);
          expect(await File(setup.planPath).readAsBytes(), setup.recipeBytes);
          expect(
            await readNativeStudyTree(setup.sourcePath),
            setup.sourceBefore,
          );
          expect(await readNativeStudyTree(setup.preserved), setup.firstOutput);
        });
        await _openApproval(tester);
        expect(
          tester
              .widget<StudioButton>(
                find.byKey(const ValueKey('confirm-reviewed-plan')),
              )
              .onPressed,
          isNull,
        );
        await _tap(
          tester,
          find.descendant(
            of: find.byType(StudioReviewDialog),
            matching: find.widgetWithText(StudioButton, 'Annuler'),
          ),
        );
        await _waitFor(
          tester,
          () => find.byType(StudioReviewDialog).evaluate().isEmpty,
          'cancelled approval dialog',
        );
        expect(desktop.state.approval, isNull);
        expect(desktop.state.result, isNull);
        expect(
          desktop.exportStudyPlanRecipe().canonicalHash,
          setup.recipe.canonicalHash,
        );
        await tester.runAsync(() async {
          expect(await Directory(setup.destination).exists(), isFalse);
          expect(await readNativeStudyTree(setup.preserved), setup.firstOutput);
        });
        await _openApproval(tester);
        await _tap(tester, find.byKey(const ValueKey('approve-plan')));
        await _waitFor(
          tester,
          () =>
              tester
                  .widget<StudioButton>(
                    find.byKey(const ValueKey('confirm-reviewed-plan')),
                  )
                  .onPressed !=
              null,
          'explicit checked approval',
        );
        await _tap(tester, find.byKey(const ValueKey('confirm-reviewed-plan')));
        await _waitFor(
          tester,
          () => desktop.state.result != null || desktop.state.failure != null,
          'desktop native publication',
        );
        expect(desktop.state.failure, isNull);
        expect(desktop.state.isBusy, isFalse);
        expect(desktop.state.result, isNotNull);
        final result = desktop.state.result!;
        expect(result.projectPath, setup.destination);
        expect(result.published, isTrue);
        expect(result.receipt.verified, isTrue);
        expect(result.sourceUnchanged, isTrue);
        expect(result.playableCertified, isFalse);
        expect(result.approvedPlanHash, setup.recipe.approvedPlanHash);
        expect(result.preparationHash, setup.recipe.preparationHash);
        expect(result.sourceSnapshotHash, setup.recipe.sourceSnapshotHash);
        expect(
          result.receipt.nativeRevision,
          setup.cliResult['nativeRevision'],
        );
        expect(desktop.state.approval, isNull);
        expect(find.text('Projet d’étude publié et vérifié.'), findsOneWidget);
        expect(find.textContaining('Une nouvelle approbation'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final desktopBefore = await readNativeStudyTree(setup.destination);
          final desktopModes = await _fileModes(setup.destination);
          final comparison = await compareNativeStudyDirectories(
            leftProjectPath: setup.preserved,
            rightProjectPath: setup.destination,
            allowedParentPath: setup.output.path,
            expectedOperationIds: setup.operations,
          );
          expect(comparison.toJson()['equal'], isTrue);
          expect(comparison.fileCount, setup.firstOutput.length);
          expect(comparison.fileCount, desktopBefore.length);
          expect(comparison.left.verified, isTrue);
          expect(comparison.right.verified, isTrue);
          expect(comparison.left.mapCount, 2);
          expect(comparison.right.mapCount, 2);
          expect(
            comparison.left.nativeRevision,
            setup.cliResult['nativeRevision'],
          );
          expect(
            comparison.right.nativeRevision,
            result.receipt.nativeRevision,
          );
          final cliAfter = await readNativeStudyTree(setup.preserved);
          final desktopAfter = await readNativeStudyTree(setup.destination);
          expect(cliAfter, setup.firstOutput);
          expect(desktopAfter, desktopBefore);
          expect(await _fileModes(setup.preserved), setup.firstOutputModes);
          expect(await _fileModes(setup.destination), desktopModes);
          expect(
            _treeFingerprint(cliAfter),
            _treeFingerprint(setup.firstOutput),
          );
          expect(
            _treeFingerprint(desktopAfter),
            _treeFingerprint(desktopBefore),
          );
          expect(
            await readNativeStudyTree(setup.sourcePath),
            setup.sourceBefore,
          );
          expect(await File(setup.planPath).readAsBytes(), setup.recipeBytes);
          expect(
            (await const LocalStudyPlanStore().read(setup.planPath))
                .canonicalHash,
            setup.recipe.canonicalHash,
          );
          expect(
            await File(setup.expectationsPath).readAsBytes(),
            setup.expectationsBytes,
          );
          expect(
            literalFixtureHash(await File(setup.cli).readAsBytes()).value,
            setup.cliHash,
          );
          expect(
            desktop.exportStudyPlanRecipe().canonicalHash,
            setup.recipe.canonicalHash,
          );
          if (evidencePath != null && evidencePath.isNotEmpty) {
            final target = path.normalize(evidencePath);
            final repository = path.normalize(
              path.join(Directory.current.path, '..', '..'),
            );
            expect(path.isAbsolute(target), isTrue);
            expect(
              path.isWithin(repository, target) ||
                  path.equals(repository, target),
              isFalse,
            );
            expect(path.isWithin(setup.root.path, target), isFalse);
            expect(
              await FileSystemEntity.type(target, followLinks: false),
              FileSystemEntityType.notFound,
            );
            expect(await Directory(path.dirname(target)).exists(), isTrue);
            await File(target).writeAsString(
              jsonEncode({
                'kind': 'cliDesktopPlanParityEvidence',
                'version': 1,
                'proofScope': 'headlessRealCliAndConverterAppPlanParity',
                'equal': true,
                'cliExecutable': setup.cli,
                'cliSha256': setup.cliHash,
                'recipeHash': setup.recipe.canonicalHash.value,
                'recipeFileSha256': setup.recipeBytesHash,
                'nativeDraftHash': setup.recipe.nativeDraftHash.value,
                'approvedPlanHash': setup.recipe.approvedPlanHash.value,
                'preparationHash': setup.recipe.preparationHash.value,
                'expectations': setup.expectations,
                'expectationsFileSha256': setup.expectationsHash,
                'cli': setup.cliResult,
                'cliVerification': setup.cliVerification,
                'desktop': {
                  'published': result.published,
                  'verified': result.receipt.verified,
                  'sourceUnchanged': result.sourceUnchanged,
                  'nativeRevision': result.receipt.nativeRevision,
                },
                'comparison': comparison.toJson(),
                'cliRawInventory': _treeInventory(cliAfter),
                'cliFileModesBeforeAndAfterRename': setup.firstOutputModes,
                'cliRawFingerprint': _treeFingerprint(cliAfter),
                'desktopRawInventory': _treeInventory(desktopAfter),
                'desktopFileModesBeforeAndAfterVerification': desktopModes,
                'desktopRawFingerprint': _treeFingerprint(desktopAfter),
                'sourceInventory': _treeInventory(setup.sourceBefore),
                'sourceFingerprint': _treeFingerprint(setup.sourceBefore),
                'firstOutputPreservedBySiblingRename': true,
                'recipeUnchanged': true,
                'firstOutputUnchanged': true,
                'sourceUnchanged': true,
                'wrongCliApprovalRejected': true,
                'cancelledDesktopApprovalDidNotPublish': true,
                'operationIdsCapturedBeforeAnyConvert': true,
                'fixtureMapIds': [1, 8],
                'sourceScriptsPresent': false,
                'cliInvocations': invocations,
                'nativeGuiQualified': false,
                'nativePickerQualified': false,
                'audiblePlaybackQualified': false,
                'fullGameQualified': false,
                'cleanupPolicy': 'Owned temporary root removed in finally; no temporary output retention is requested.',
              }),
              flush: true,
            );
          }
        });
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          for (final workflow in workflows.reversed) {
            await workflow.dispose();
          }
          final root = ownedRoot;
          if (root != null && await root.exists()) {
            await root.delete(recursive: true);
          }
        });
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<Map<String, dynamic>> _invokeCli(
  String executable,
  List<String> arguments,
  List<Map<String, Object?>> invocations, {
  int expectedExit = 0,
}) async {
  final result = await Process.run(
    executable,
    arguments,
    environment: const {'PATH': '/usr/bin:/bin:/usr/sbin:/sbin'},
    runInShell: false,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  invocations.add({
    'arguments': List<String>.unmodifiable(arguments),
    'exitCode': result.exitCode,
    'stdout': result.stdout,
    'stderr': result.stderr,
  });
  expect(
    result.exitCode,
    expectedExit,
    reason:
        'CLI arguments $arguments\nstdout=${result.stdout}\nstderr=${result.stderr}',
  );
  if (expectedExit == 0) expect(result.stderr, isEmpty);
  final decoded = jsonDecode(
    (expectedExit == 0 ? result.stdout : result.stderr) as String,
  );
  expect(decoded, isA<Map<String, dynamic>>());
  return Map<String, dynamic>.from(decoded as Map);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 16));
}

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() done,
  String stage,
) async {
  for (var attempt = 0; attempt < 3000 && !done(); attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final error = tester.takeException();
    if (error != null) throw error;
  }
  if (!done()) {
    throw TimeoutException('CLI desktop parity did not finish $stage.');
  }
  await tester.pump();
}

Future<void> _openApproval(WidgetTester tester) async {
  await _tap(tester, find.byKey(const ValueKey('create-study-project')));
  await _waitFor(
    tester,
    () => find.byType(StudioReviewDialog).evaluate().isNotEmpty,
    'publication approval dialog',
  );
  expect(find.byKey(const ValueKey('approve-plan')), findsOneWidget);
}

Map<String, Object?> _treeInventory(Map<String, List<int>> files) {
  final keys = files.keys.toList()..sort();
  return {
    for (final key in keys)
      key: {
        'byteLength': files[key]!.length,
        'sha256': literalFixtureHash(files[key]!).value,
      },
  };
}

String _treeFingerprint(Map<String, List<int>> files) =>
    canonicalHashOf(_treeInventory(files)).value;

Future<Map<String, int>> _fileModes(String root) async {
  final modes = <String, int>{};
  await for (final entry in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    expect(entry, isNot(isA<Link>()));
    if (entry is File) {
      final stat = await entry.stat();
      expect(stat.type, FileSystemEntityType.file);
      modes[entry.path.substring(root.length + 1)] = stat.mode;
    }
  }
  return modes;
}
