import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_session_lifecycle.dart';
import 'package:map_editor/src/application/services/map_lifecycle_transaction_service.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/repositories/editor_persistence_codec_executor.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart';

const _requestedOutputPath = String.fromEnvironment('POKEMAP_PERF_OUTPUT');
const _target = 'integration_test/editor_codec_offload_journey_test.dart';
const _requestedPayloadBytes = 10 * 1024 * 1024;
const _saveBudgetUs = 250000;
const _heartbeatBudgetUs = 16667;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'profiles a production-wired 10 MiB editor save on macOS',
    (tester) async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap-rm09b-profile-',
      );
      addTearDown(() async {
        if (await sandbox.exists()) await sandbox.delete(recursive: true);
      });
      final project = ProjectManifest(
        name: 'RM-09B profile project',
        maps: const [],
        tilesets: const [],
        globalProperties: <String, Object?>{
          'payload': 'x' * _requestedPayloadBytes,
        },
      );
      final codec = EditorPersistenceCodecExecutor();
      final projectFile = File('${sandbox.path}/project.json');
      final beforeBytes = await codec.encodeNewProject(project);
      await projectFile.writeAsBytes(beforeBytes, flush: true);

      const projectFiles = EditorProjectFileReader();
      final authoringQueries = AuthoringQueryAdapter(fileReader: projectFiles);
      final authoringLifecycle = EditorAuthoringSessionLifecycle(
        fileReader: projectFiles,
      )..attach(authoringQueries);
      addTearDown(authoringLifecycle.closeAll);
      await authoringLifecycle.activate(sandbox.path);
      await authoringQueries.open(sandbox.path);
      expect(authoringQueries.diagnostics.liveSessions, 1);

      final repository = FileProjectRepository(
        codecExecutor: codec,
        authoringQueries: authoringQueries,
        mapLifecycleTransactions: MapLifecycleTransactionCoordinator(
          MapLifecycleTransactionFileGateway(
            mapRepository: FileMapRepository(),
          ),
        ),
      );
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          ),
        ),
      );
      for (var index = 0; index < 3; index++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      final timings = <FrameTiming>[];
      void captureTimings(List<FrameTiming> batch) => timings.addAll(batch);
      var callbackRegistered = true;
      SchedulerBinding.instance.addTimingsCallback(captureTimings);
      addTearDown(() {
        if (!callbackRegistered) return;
        SchedulerBinding.instance.removeTimingsCallback(captureTimings);
        callbackRegistered = false;
      });

      var saveCompleted = false;
      final stopwatch = Stopwatch()..start();
      var previousHeartbeatUs = 0;
      var maxHeartbeatGapUs = 0;
      var heartbeatCount = 0;
      final heartbeat = Timer.periodic(const Duration(milliseconds: 1), (_) {
        final now = stopwatch.elapsedMicroseconds;
        final gap = now - previousHeartbeatUs;
        if (gap > maxHeartbeatGapUs) maxHeartbeatGapUs = gap;
        previousHeartbeatUs = now;
        heartbeatCount++;
      });
      addTearDown(heartbeat.cancel);
      final saving = repository
          .saveProject(project, projectFile.path)
          .whenComplete(() => saveCompleted = true);
      var heartbeatPumps = 0;
      while (!saveCompleted && heartbeatPumps < 600) {
        await tester.pump(const Duration(milliseconds: 8));
        await Future<void>.delayed(const Duration(milliseconds: 1));
        heartbeatPumps++;
      }
      await saving;
      final finalHeartbeatGapUs =
          stopwatch.elapsedMicroseconds - previousHeartbeatUs;
      if (finalHeartbeatGapUs > maxHeartbeatGapUs) {
        maxHeartbeatGapUs = finalHeartbeatGapUs;
      }
      heartbeat.cancel();
      stopwatch.stop();
      expect(saveCompleted, isTrue);
      expect(authoringQueries.diagnostics.liveSessions, 0);

      for (var index = 0; index < 3; index++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      SchedulerBinding.instance.removeTimingsCallback(captureTimings);
      callbackRegistered = false;

      final frameMetrics = _frameMetrics(timings);
      const isProfile = bool.fromEnvironment('dart.vm.profile');
      final afterBytes = await projectFile.readAsBytes();
      final beforeFingerprint = narrativeEventBytesFingerprint(beforeBytes);
      final afterFingerprint = narrativeEventBytesFingerprint(afterBytes);
      expect(afterFingerprint, beforeFingerprint);
      if (isProfile) {
        expect(stopwatch.elapsedMicroseconds, lessThanOrEqualTo(_saveBudgetUs));
        expect(maxHeartbeatGapUs, lessThanOrEqualTo(_heartbeatBudgetUs));
      }
      expect(timings, isNotEmpty);
      expect(tester.takeException(), isNull);

      binding.reportData = <String, dynamic>{
        'schemaVersion': 2,
        'generatorVersion': 1,
        'benchmark': 'editor_codec_offload_journey',
        'target': _target,
        'requestedOutputPath': _requestedOutputPath,
        'executionMode': isProfile ? 'flutter-profile' : 'flutter-debug',
        'repositoryMode':
            'production-lifecycle-with-authoring-snapshot-invalidation',
        'requestedPayloadBytes': _requestedPayloadBytes,
        'encodedBytes': afterBytes.length,
        'elapsedUs': stopwatch.elapsedMicroseconds,
        'heartbeatPumps': heartbeatPumps,
        'heartbeatMetrics': <String, Object?>{
          'timerCount': heartbeatCount,
          'maxGapUs': maxHeartbeatGapUs,
        },
        'fingerprint': afterFingerprint,
        'authoringSnapshotInvalidated':
            authoringQueries.diagnostics.liveSessions == 0,
        'codecDiagnostics': <String, Object?>{
          'localOperations': codec.diagnostics.localOperations,
          'workerOperations': codec.diagnostics.workerOperations,
          'workerFailures': codec.diagnostics.workerFailures,
        },
        'frameMetrics': frameMetrics.toJson(),
        'frameMetricsAcceptance': 'observation-only',
        'performanceGates': <String, Object?>{
          'saveMaxUs': _saveBudgetUs,
          'heartbeatMaxGapUs': _heartbeatBudgetUs,
          'requiresEveryProcess': true,
          'enforced': isProfile,
        },
      };
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

_FrameMetrics _frameMetrics(List<FrameTiming> timings) {
  final spans = timings
      .map((timing) => timing.totalSpan.inMicroseconds)
      .toList(growable: false);
  final sorted = List<int>.of(spans)..sort();
  return _FrameMetrics(
    samplesUs: spans,
    p50Us: _percentile(sorted, 0.50),
    p95Us: _percentile(sorted, 0.95),
    p99Us: _percentile(sorted, 0.99),
    maxSpanUs: sorted.isEmpty ? 0 : sorted.last,
  );
}

int _percentile(List<int> sorted, double percentile) {
  if (sorted.isEmpty) return 0;
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

final class _FrameMetrics {
  const _FrameMetrics({
    required this.samplesUs,
    required this.p50Us,
    required this.p95Us,
    required this.p99Us,
    required this.maxSpanUs,
  });

  final List<int> samplesUs;
  final int p50Us;
  final int p95Us;
  final int p99Us;
  final int maxSpanUs;

  Map<String, Object?> toJson() => <String, Object?>{
        'frameCount': samplesUs.length,
        'samplesUs': samplesUs,
        'p50Us': p50Us,
        'p95Us': p95Us,
        'p99Us': p99Us,
        'maxUs': maxSpanUs,
      };
}
