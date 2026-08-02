import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_session_lifecycle.dart';
import 'package:map_editor/src/application/services/map_lifecycle_transaction_service.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/repositories/editor_persistence_codec_executor.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('profiles editor codec phases and UI-isolate heartbeat', () async {
    final enforcePerformanceGates =
        Platform.environment['POKEMAP_ENFORCE_PERFORMANCE_GATES'] == '1';
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap_editor_codec_profile_',
    );
    try {
      final rows = <Map<String, Object?>>[];
      for (final requestedBytes in const [1024, 102400, 2420033, 10485760]) {
        final project = ProjectManifest(
          name: 'Codec $requestedBytes',
          maps: const [],
          tilesets: const [],
          globalProperties: {'payload': 'x' * requestedBytes},
        );
        final local = EditorPersistenceCodecExecutor(
          offloadThresholdBytes: 1 << 30,
        );
        final thresholded = EditorPersistenceCodecExecutor();

        final localEncode = await _measure(
          () => local.encodeNewProject(project),
        );
        final workerEncode = await _measure(
          () => thresholded.encodeNewProject(project),
        );
        expect(workerEncode.value, localEncode.value);

        final projectDirectory = await Directory(
          '${sandbox.path}/project_$requestedBytes',
        ).create();
        final file = File('${projectDirectory.path}/project.json');
        final writeWatch = Stopwatch()..start();
        await file.writeAsBytes(workerEncode.value, flush: true);
        writeWatch.stop();
        final readWatch = Stopwatch()..start();
        final bytes = await file.readAsBytes();
        readWatch.stop();

        final decodeWatch = Stopwatch()..start();
        final raw = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        decodeWatch.stop();
        final modelWatch = Stopwatch()..start();
        final modeled = ProjectManifest.fromJson(raw);
        modelWatch.stop();
        final validateWatch = Stopwatch()..start();
        ProjectValidator.validate(modeled);
        validateWatch.stop();

        final localDecode = await _measure(
          () => local.decodeValidatedProject(bytes),
        );
        final workerDecode = await _measure(
          () => thresholded.decodeValidatedProject(bytes),
        );
        expect(workerDecode.value, localDecode.value);
        expect(workerDecode.value, project);
        final localSavePrepare = await _measure(
          () => local.prepareExistingProjectUpdate(
            currentBytes: bytes,
            project: project,
          ),
        );
        final workerSavePrepare = await _measure(
          () => thresholded.prepareExistingProjectUpdate(
            currentBytes: bytes,
            project: project,
          ),
        );
        expect(workerSavePrepare.value.bytes, localSavePrepare.value.bytes);
        final localFingerprint = await _measure(
          () => local.fingerprintProjectBytes(bytes),
        );
        final workerFingerprint = await _measure(
          () => thresholded.fingerprintProjectBytes(bytes),
        );
        expect(workerFingerprint.value, localFingerprint.value);
        expect(workerSavePrepare.value.bytes, bytes);
        const projectFiles = EditorProjectFileReader();
        final authoringQueries = AuthoringQueryAdapter(
          fileReader: projectFiles,
        );
        final authoringLifecycle = EditorAuthoringSessionLifecycle(
          fileReader: projectFiles,
        )..attach(authoringQueries);
        await authoringLifecycle.activate(projectDirectory.path);
        await authoringQueries.open(projectDirectory.path);
        expect(authoringQueries.diagnostics.liveSessions, 1);
        late final _HeartbeatMeasurement<void> repositorySave;
        try {
          final repository = FileProjectRepository(
            codecExecutor: EditorPersistenceCodecExecutor(),
            authoringQueries: authoringQueries,
            mapLifecycleTransactions: MapLifecycleTransactionCoordinator(
              MapLifecycleTransactionFileGateway(
                mapRepository: FileMapRepository(),
              ),
            ),
          );
          repositorySave = await _measure(
            () => repository.saveProject(project, file.path),
          );
        } finally {
          expect(authoringQueries.diagnostics.liveSessions, 0);
          await authoringLifecycle.closeAll();
        }
        expect(
          narrativeEventBytesFingerprint(await file.readAsBytes()),
          narrativeEventBytesFingerprint(bytes),
        );
        if (enforcePerformanceGates && requestedBytes == 10485760) {
          expect(
            repositorySave.elapsedUs,
            lessThanOrEqualTo(250000),
            reason: '10 MiB editor save must remain within the RM-09B gate.',
          );
          expect(
            repositorySave.maxHeartbeatGapUs,
            lessThanOrEqualTo(16667),
            reason: '10 MiB editor save must not miss a 60 Hz UI heartbeat.',
          );
        }
        rows.add({
          'requestedPayloadBytes': requestedBytes,
          'encodedBytes': bytes.length,
          'fingerprint': narrativeEventBytesFingerprint(bytes),
          'readUs': readWatch.elapsedMicroseconds,
          'decodeJsonUs': decodeWatch.elapsedMicroseconds,
          'modelUs': modelWatch.elapsedMicroseconds,
          'validateUs': validateWatch.elapsedMicroseconds,
          'writeUs': writeWatch.elapsedMicroseconds,
          'localEncode': localEncode.toJson(),
          'thresholdedEncode': workerEncode.toJson(),
          'localDecode': localDecode.toJson(),
          'thresholdedDecode': workerDecode.toJson(),
          'localSavePrepare': localSavePrepare.toJson(),
          'thresholdedSavePrepare': workerSavePrepare.toJson(),
          'localFingerprint': localFingerprint.toJson(),
          'thresholdedFingerprint': workerFingerprint.toJson(),
          'repositorySave': repositorySave.toJson(),
          'authoringSnapshotInvalidated':
              authoringQueries.diagnostics.liveSessions == 0,
          'codecDiagnostics': {
            'localOperations': thresholded.diagnostics.localOperations,
            'workerOperations': thresholded.diagnostics.workerOperations,
            'workerFailures': thresholded.diagnostics.workerFailures,
          },
        });
      }
      final receipt = <String, Object?>{
        'schemaVersion': 2,
        'generatorVersion': 1,
        'benchmark': 'editor_codec_offload',
        'executionMode': 'flutter-test-debug',
        'repositoryMode':
            'production-lifecycle-with-authoring-snapshot-invalidation',
        'thresholdBytes':
            EditorPersistenceCodecExecutor.defaultOffloadThresholdBytes,
        'performanceGates': <String, Object?>{
          'editorSave10MiBMaxUs': 250000,
          'uiHeartbeatMaxGapUs': 16667,
          'enforced': enforcePerformanceGates,
        },
        'results': rows,
      };
      await _writeReceiptIfRequested(receipt);
      // ignore: avoid_print
      print(jsonEncode(receipt));
    } finally {
      await sandbox.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Future<void> _writeReceiptIfRequested(Map<String, Object?> receipt) async {
  final requested = Platform.environment['POKEMAP_PERF_OUTPUT']?.trim() ?? '';
  if (requested.isEmpty) return;
  final packageRoot = Directory.current.resolveSymbolicLinksSync();
  if (p.isAbsolute(requested)) {
    throw const FormatException(
      'POKEMAP_PERF_OUTPUT must stay inside packages/map_editor.',
    );
  }
  final output = File(p.normalize(p.join(packageRoot, requested))).absolute;
  if (!p.isWithin(packageRoot, output.path)) {
    throw const FormatException(
      'POKEMAP_PERF_OUTPUT must stay inside packages/map_editor.',
    );
  }
  await output.parent.create(recursive: true);
  await output.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(receipt)}\n',
    flush: true,
  );
}

Future<_HeartbeatMeasurement<T>> _measure<T>(
    Future<T> Function() operation) async {
  final stopwatch = Stopwatch()..start();
  var previousTickUs = 0;
  var maxHeartbeatGapUs = 0;
  var heartbeatCount = 0;
  final timer = Timer.periodic(const Duration(milliseconds: 1), (_) {
    final now = stopwatch.elapsedMicroseconds;
    final gap = now - previousTickUs;
    if (gap > maxHeartbeatGapUs) maxHeartbeatGapUs = gap;
    previousTickUs = now;
    heartbeatCount++;
  });
  try {
    final value = await operation();
    final finalGap = stopwatch.elapsedMicroseconds - previousTickUs;
    if (finalGap > maxHeartbeatGapUs) maxHeartbeatGapUs = finalGap;
    return _HeartbeatMeasurement(
      value: value,
      elapsedUs: stopwatch.elapsedMicroseconds,
      heartbeatCount: heartbeatCount,
      maxHeartbeatGapUs: maxHeartbeatGapUs,
    );
  } finally {
    timer.cancel();
    stopwatch.stop();
  }
}

final class _HeartbeatMeasurement<T> {
  const _HeartbeatMeasurement({
    required this.value,
    required this.elapsedUs,
    required this.heartbeatCount,
    required this.maxHeartbeatGapUs,
  });

  final T value;
  final int elapsedUs;
  final int heartbeatCount;
  final int maxHeartbeatGapUs;

  Map<String, Object?> toJson() => {
        'elapsedUs': elapsedUs,
        'heartbeatCount': heartbeatCount,
        'maxHeartbeatGapUs': maxHeartbeatGapUs,
      };
}
