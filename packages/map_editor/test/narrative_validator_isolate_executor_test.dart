import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_studio_validation_coordinator.dart';
import 'package:map_editor/src/application/services/narrative_validator_isolate_executor.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_runtime_smoke_receipt_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  group('IsolateNarrativeValidatorExecutor', () {
    late Directory projectRoot;

    setUp(() async {
      projectRoot = await Directory.systemTemp.createTemp(
        'narrative_validator_isolate_',
      );
      await _writeProject(projectRoot, _project);
    });

    tearDown(() async {
      await projectRoot.delete(recursive: true);
    });

    test('runs validation on a dedicated isolate without changing the report',
        () async {
      final executor = IsolateNarrativeValidatorExecutor(
        debounceDuration: Duration.zero,
      );
      addTearDown(executor.dispose);
      final expected = validateNarrativeProject(
        _project,
        maps: const [],
        knownSpeciesIds: const <String>{},
        knownMoveIds: const <String>{},
      );

      final projectResult = await executor.execute(
        _work(projectRoot, validationId: 'validation-current'),
      );
      final result = await executor.execute(
        _multidimensionalWork(
          projectRoot,
          validationId: 'validation-current-multidimensional',
          projectReport: projectResult.report!,
        ),
      );
      const receipts = NarrativeRuntimeSmokeReceiptRepository();
      final projectFingerprint =
          await receipts.computeProjectFingerprint(projectRoot.path);
      final runtimeReceipt = await receipts.read(
        projectRoot: projectRoot.path,
        expectedFingerprint: projectFingerprint,
        profile: selbrumeReleaseV1Profile,
      );
      final expectedMultidimensional =
          const NarrativeStudioValidationCoordinator().coordinate(
        project: _project,
        maps: const [],
        projectReport: expected,
        projectFingerprint: projectFingerprint,
        profile: selbrumeReleaseV1Profile,
        runtimeReceipt: runtimeReceipt,
        generatedAt: result.multidimensionalReport!.generatedAt,
      );

      expect(projectResult.validationId, 'validation-current');
      expect(result.validationId, 'validation-current-multidimensional');
      expect(
          projectResult.workerIsolateDebugName, 'pokemap-narrative-validator');
      expect(projectResult.workerIsolateDebugName,
          isNot(Isolate.current.debugName));
      expect(
          projectResult.workerControlPort, isNot(Isolate.current.controlPort));
      expect(
        result.multidimensionalReport!.projectFingerprint,
        startsWith('sha256:'),
      );
      expect(
        _projectReportProjection(projectResult.report!),
        _projectReportProjection(expected),
      );
      expect(
        encodeNarrativeValidationReport(result.multidimensionalReport!),
        encodeNarrativeValidationReport(expectedMultidimensional),
      );
    });

    test('kills a started obsolete validation before spawning the newer one',
        () async {
      final obsoleteSpawned = Completer<void>();
      late IsolateNarrativeValidatorExecutor executor;
      late Future<NarrativeValidatorExecutionResult> current;
      executor = IsolateNarrativeValidatorExecutor(
        debounceDuration: Duration.zero,
        onWorkerSpawned: (validationId) {
          if (validationId == 'validation-obsolete' &&
              !obsoleteSpawned.isCompleted) {
            current = executor.execute(
              _work(projectRoot, validationId: 'validation-current'),
            );
            obsoleteSpawned.complete();
          }
        },
      );
      addTearDown(executor.dispose);

      final obsolete = executor.execute(
        _work(projectRoot, validationId: 'validation-obsolete'),
      );
      final obsoleteExpectation = expectLater(
        obsolete,
        throwsA(
          isA<NarrativeValidatorCancelledException>().having(
            (error) => error.reason,
            'reason',
            NarrativeValidatorCancellationReason.superseded,
          ),
        ),
      );
      await obsoleteSpawned.future;
      await obsoleteExpectation;
      expect((await current).validationId, 'validation-current');
    });

    test('serializes a three-request burst across the original worker exit',
        () async {
      final lifecycle = <String>[];
      final originalSpawned = Completer<void>();
      late IsolateNarrativeValidatorExecutor executor;
      Future<NarrativeValidatorExecutionResult>? skipped;
      Future<void>? skippedExpectation;
      Future<NarrativeValidatorExecutionResult>? current;
      executor = IsolateNarrativeValidatorExecutor(
        debounceDuration: Duration.zero,
        onWorkerSpawned: (validationId) {
          lifecycle.add('spawn:$validationId');
          if (validationId == 'validation-original' &&
              !originalSpawned.isCompleted) {
            skipped = executor.execute(
              _work(projectRoot, validationId: 'validation-skipped'),
            );
            skippedExpectation = expectLater(
              skipped!,
              throwsA(isA<NarrativeValidatorCancelledException>()),
            );
            current = executor.execute(
              _work(projectRoot, validationId: 'validation-current'),
            );
            originalSpawned.complete();
          }
        },
        onWorkerExited: (validationId) {
          lifecycle.add('exit:$validationId');
        },
      );
      addTearDown(executor.dispose);

      final original = executor.execute(
        _work(projectRoot, validationId: 'validation-original'),
      );
      final originalExpectation = expectLater(
        original,
        throwsA(isA<NarrativeValidatorCancelledException>()),
      );
      await originalSpawned.future;

      await originalExpectation;
      await skippedExpectation!;
      expect((await current!).validationId, 'validation-current');
      expect(
        lifecycle.indexOf('exit:validation-original'),
        lessThan(lifecycle.indexOf('spawn:validation-current')),
      );
      expect(lifecycle, isNot(contains('spawn:validation-skipped')));
    });

    test('does not supersede a validation from another project root', () async {
      final otherProjectRoot = await Directory.systemTemp.createTemp(
        'narrative_validator_other_project_',
      );
      addTearDown(() => otherProjectRoot.delete(recursive: true));
      await _writeProject(otherProjectRoot, _project);
      final firstSpawned = Completer<void>();
      Future<NarrativeValidatorExecutionResult>? second;
      late IsolateNarrativeValidatorExecutor executor;
      executor = IsolateNarrativeValidatorExecutor(
        debounceDuration: Duration.zero,
        onWorkerSpawned: (validationId) {
          if (validationId == 'validation-first' && !firstSpawned.isCompleted) {
            second = executor.execute(
              _work(
                otherProjectRoot,
                validationId: 'validation-second',
              ),
            );
            firstSpawned.complete();
          }
        },
      );
      addTearDown(executor.dispose);

      final first = executor.execute(
        _work(projectRoot, validationId: 'validation-first'),
      );
      final firstExpectation = expectLater(first, completes);
      await firstSpawned.future;

      await firstExpectation;
      expect((await first).validationId, 'validation-first');
      expect((await second!).validationId, 'validation-second');
    });

    test('rejects a stale phase two without cancelling the newer phase one',
        () async {
      Future<void>? staleExpectation;
      final newerSpawned = Completer<void>();
      late IsolateNarrativeValidatorExecutor executor;
      NarrativeProjectValidationReport? olderReport;
      executor = IsolateNarrativeValidatorExecutor(
        debounceDuration: Duration.zero,
        onWorkerSpawned: (validationId) {
          if (validationId == 'validation-newer' && !newerSpawned.isCompleted) {
            final stale = executor.execute(
              NarrativeValidatorWork.multidimensional(
                validationId: 'validation-older-multidimensional',
                projectValidationId: 'validation-older',
                projectRootPath: projectRoot.path,
                project: _project,
                projectReport: olderReport!,
              ),
            );
            staleExpectation = expectLater(
              stale,
              throwsA(
                isA<NarrativeValidatorCancelledException>().having(
                  (error) => error.reason,
                  'reason',
                  NarrativeValidatorCancellationReason.superseded,
                ),
              ),
            );
            newerSpawned.complete();
          }
        },
      );
      addTearDown(executor.dispose);
      final older = await executor.execute(
        _work(projectRoot, validationId: 'validation-older'),
      );
      olderReport = older.report;

      final newer = executor.execute(
        _work(projectRoot, validationId: 'validation-newer'),
      );
      final newerExpectation = expectLater(newer, completes);
      await newerSpawned.future;

      await staleExpectation!;
      await newerExpectation;
      expect((await newer).validationId, 'validation-newer');
    });

    test('wraps a worker-side project loading failure', () async {
      final executor = IsolateNarrativeValidatorExecutor(
        debounceDuration: Duration.zero,
      );
      addTearDown(executor.dispose);
      final missingRoot = Directory(p.join(projectRoot.path, 'missing'));

      await expectLater(
        executor.execute(
          _work(missingRoot, validationId: 'validation-missing-project'),
        ),
        throwsA(
          isA<NarrativeValidatorWorkerException>()
              .having((error) => error.message, 'message', isNotEmpty)
              .having(
                (error) => error.workerStackTrace,
                'workerStackTrace',
                isNotEmpty,
              ),
        ),
      );
    });
  });
}

const _project = ProjectManifest(
  name: 'Narrative isolate fixture',
  maps: [],
  tilesets: [],
);

NarrativeValidatorWork _work(
  Directory projectRoot, {
  required String validationId,
}) {
  return NarrativeValidatorWork(
    validationId: validationId,
    projectRootPath: projectRoot.path,
    project: _project,
    knownSpeciesIds: const <String>{},
    knownMoveIds: const <String>{},
    requirePokemonCatalogs: false,
  );
}

NarrativeValidatorWork _multidimensionalWork(
  Directory projectRoot, {
  required String validationId,
  required NarrativeProjectValidationReport projectReport,
}) {
  return NarrativeValidatorWork.multidimensional(
    validationId: validationId,
    projectValidationId: 'validation-current',
    projectRootPath: projectRoot.path,
    project: _project,
    projectReport: projectReport,
  );
}

Future<void> _writeProject(
  Directory projectRoot,
  ProjectManifest project,
) {
  return File(p.join(projectRoot.path, 'project.json')).writeAsString(
    const JsonEncoder.withIndent('  ').convert(project.toJson()),
  );
}

Map<String, Object?> _projectReportProjection(
  NarrativeProjectValidationReport report,
) {
  return {
    'diagnostics': [
      for (final item in report.diagnostics)
        {
          'code': item.code,
          'severity': item.severity.name,
          'domain': item.domain.name,
          'message': item.message,
          'path': item.path,
          'destination': item.destination.name,
          'suggestedFixLabel': item.suggestedFixLabel,
          'mapId': item.mapId,
          'eventId': item.eventId,
          'sceneId': item.sceneId,
          'dialogueId': item.dialogueId,
          'cinematicId': item.cinematicId,
          'storylineId': item.storylineId,
          'chapterId': item.chapterId,
          'stepId': item.stepId,
          'factId': item.factId,
          'worldRuleId': item.worldRuleId,
        },
    ],
    'mapEventViews': [
      for (final view in report.mapEventViews)
        {
          'groupKind': view.groupKind.name,
          'mapId': view.mapId,
          'label': view.label,
          'events': [
            for (final event in view.events)
              {
                'eventId': event.eventId,
                'label': event.label,
                'enabled': event.enabled,
                'sourceKind': event.sourceKind?.name,
                'mapId': event.mapId,
                'sourceOwnerId': event.sourceOwnerId,
                'sourceOwnerLabel': event.sourceOwnerLabel,
                'sourceEntityKind': event.sourceEntityKind?.name,
                'sourceConnected': event.sourceConnected,
                'sceneId': event.sceneId,
                'sceneLabel': event.sceneLabel,
                'sceneConnected': event.sceneConnected,
                'conditionCount': event.conditionCount,
                'diagnosticCount': event.diagnosticCount,
                'warningCount': event.warningCount,
              },
          ],
        },
    ],
    'symbolicReachability': _symbolicProjection(report.symbolicReachability),
  };
}

Object? _symbolicProjection(NarrativeSymbolicReachabilityReport? report) {
  if (report == null) return null;
  final reachableSceneIds = report.reachableSceneIds.toList()..sort();
  return {
    'verdict': report.verdict.name,
    'terminalStates': report.terminalStates.map(_stateProjection).toList(),
    'exploredStates': report.exploredStates.map(_stateProjection).toList(),
    'evidenceStates': report.evidenceStates.map(_stateProjection).toList(),
    'issues': [
      for (final issue in report.issues)
        {
          'code': issue.code.name,
          'verdict': issue.verdict.name,
          'message': issue.message,
          'sceneId': issue.sceneId,
          'nodeId': issue.nodeId,
          'eventId': issue.eventId,
          'optional': issue.optional,
          'provenance': issue.provenance.map(_provenanceProjection).toList(),
        },
    ],
    'reachableSceneIds': reachableSceneIds,
    'exploredStateCount': report.exploredStateCount,
    'independentFactComponents': [
      for (final component in report.independentFactComponents)
        {
          'factIds': component.factIds.toList()..sort(),
          'states': component.states.map(_stateProjection).toList(),
          'compatibleMainStateKeysByStateKey': {
            for (final key
                in (component.compatibleMainStateKeysByStateKey.keys.toList()
                  ..sort()))
              key: component.compatibleMainStateKeysByStateKey[key]!.toList()
                ..sort(),
          },
        },
    ],
  };
}

Map<String, Object?> _stateProjection(NarrativeSymbolicState state) {
  final factKeys = state.factValues.keys.toList()..sort();
  final completedStepIds = state.completedStepIds.toList()..sort();
  final consumedEventIds = state.consumedEventIds.toList()..sort();
  final badgeIds = state.badgeIds.toList()..sort();
  final fieldAbilities =
      state.unlockedFieldAbilities.map((item) => item.moveId).toList()..sort();
  final emittedOutcomeKeys = state.emittedOutcomeKeys.toList()..sort();
  final executedEventIds = state.executedEventIds.toList()..sort();
  return {
    'factValues': {
      for (final key in factKeys) key: state.factValues[key]!.toJson(),
    },
    'completedStepIds': completedStepIds,
    'consumedEventIds': consumedEventIds,
    'badgeIds': badgeIds,
    'unlockedFieldAbilities': fieldAbilities,
    'emittedOutcomeKeys': emittedOutcomeKeys,
    'executedEventIds': executedEventIds,
    'provenance': state.provenance.map(_provenanceProjection).toList(),
    'indeterminate': state.indeterminate,
  };
}

Map<String, Object?> _provenanceProjection(
  NarrativeSymbolicProvenance provenance,
) {
  return {
    'sceneId': provenance.sceneId,
    'nodeId': provenance.nodeId,
    'eventId': provenance.eventId,
    'description': provenance.description,
  };
}
