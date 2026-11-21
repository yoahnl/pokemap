import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import '../contracts/evaluation_event.dart';
import '../contracts/evaluation_receipt.dart';
import '../web/evaluation_worker_pool.dart';
import '../worker/evaluation_worker_protocol.dart';

typedef EvaluationJobArtifactCollector = Future<List<AuthoringJobArtifact>>
    Function(
  AuthoringJobSnapshot snapshot,
  EvaluationWorkerResult result,
);
typedef EvaluationWorkerRequestFactory = EvaluationWorkerRequest Function(
  AuthoringJobSnapshot snapshot,
);

/// Converts the worker's private files into path-free, content-addressed API
/// artifacts. Receipt-declared files are resolved below the receipt directory
/// and symlinks are checked against the configured repository boundary.
final class EvaluationFileArtifactCollector {
  EvaluationFileArtifactCollector({required Directory repositoryRoot})
      : repositoryRoot = repositoryRoot.absolute;

  final Directory repositoryRoot;

  Future<List<AuthoringJobArtifact>> collect(
    AuthoringJobSnapshot snapshot,
    EvaluationWorkerResult result,
  ) async {
    final receiptPath = result.receiptPath;
    if (receiptPath == null) return const <AuthoringJobArtifact>[];
    final rootPath = await repositoryRoot.resolveSymbolicLinks();
    final receipt = await _boundedFile(
      File(p.join(repositoryRoot.path, receiptPath)),
      rootPath,
    );
    final decoded = jsonDecode(await receipt.readAsString());
    if (decoded is! Map || decoded['artifacts'] is! List) {
      throw const FormatException(
        'Evaluation receipt must declare an artifacts list.',
      );
    }
    final files = <(ArtifactKind, File)>[(ArtifactKind.receipt, receipt)];
    for (final rawPath in decoded['artifacts']! as List) {
      if (rawPath is! String ||
          rawPath.trim().isEmpty ||
          p.isAbsolute(rawPath) ||
          p.split(rawPath).contains('..')) {
        throw const FormatException(
          'Evaluation receipt artifact paths must remain relative.',
        );
      }
      final file = await _boundedFile(
        File(p.join(receipt.parent.path, rawPath)),
        rootPath,
      );
      files.add((_kindFor(file.path), file));
    }

    final artifacts = <AuthoringJobArtifact>[];
    for (var index = 0; index < files.length; index += 1) {
      final (kind, file) = files[index];
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes).toString();
      final sequence = index + 1;
      artifacts.add(
        AuthoringJobArtifact(
          jobId: snapshot.jobId,
          sequence: sequence,
          kind: kind,
          createdAtUtc: (await file.lastModified()).toUtc().toIso8601String(),
          reference: AuthoringArtifactRef(
            id: '${kind.wireName}-$sequence',
            mediaType: _mediaTypeFor(file.path, kind),
            uri: 'artifact://sha256/$digest',
            byteLength: bytes.length,
            sha256: digest,
          ),
        ),
      );
    }
    return List<AuthoringJobArtifact>.unmodifiable(artifacts);
  }

  Future<File> _boundedFile(File candidate, String rootPath) async {
    if (!await candidate.exists()) {
      throw StateError('Declared evaluation artifact does not exist.');
    }
    final resolved = await candidate.resolveSymbolicLinks();
    if (resolved != rootPath && !p.isWithin(rootPath, resolved)) {
      throw StateError('Evaluation artifact escaped the repository boundary.');
    }
    return File(resolved);
  }
}

ArtifactKind _kindFor(String path) {
  return switch (p.extension(path).toLowerCase()) {
    '.png' || '.jpg' || '.jpeg' || '.webp' => ArtifactKind.image,
    _ => ArtifactKind.log,
  };
}

String _mediaTypeFor(String path, ArtifactKind kind) {
  if (kind == ArtifactKind.receipt) return 'application/json';
  return switch (p.extension(path).toLowerCase()) {
    '.png' => 'image/png',
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.webp' => 'image/webp',
    '.json' => 'application/json',
    '.jsonl' || '.ndjson' => 'application/x-ndjson',
    _ => 'text/plain',
  };
}

abstract interface class EvaluationAuthoringJobExecutor {
  Future<EvaluationWorkerResult> run(
    AuthoringJobSnapshot snapshot,
    void Function(EvaluationEvent event) eventSink,
  );

  Future<bool> cancel(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  });

  Future<bool> forceStop(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  });
}

/// Production adapter from transport-neutral Authoring jobs to PokeMap Eval's
/// persistent, project-serialized worker pool.
final class EvaluationWorkerPoolJobExecutor
    implements EvaluationAuthoringJobExecutor {
  EvaluationWorkerPoolJobExecutor({
    required this.workerPool,
    required this.requestFactory,
    this.releaseEvidenceCandidate = false,
  });

  final EvaluationWorkerPool workerPool;
  final EvaluationWorkerRequestFactory requestFactory;
  final bool releaseEvidenceCandidate;

  @override
  Future<EvaluationWorkerResult> run(
    AuthoringJobSnapshot snapshot,
    void Function(EvaluationEvent event) eventSink,
  ) {
    return workerPool.run(
      projectId: snapshot.request.projectId,
      request: requestFactory(snapshot),
      eventSink: eventSink,
      releaseEvidenceCandidate: releaseEvidenceCandidate,
    );
  }

  @override
  Future<bool> cancel(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  }) async {
    try {
      await workerPool
          .control(
            projectId: snapshot.request.projectId,
            runId: snapshot.jobId,
            action: EvaluationWorkerControlAction.cancel,
          )
          .timeout(timeout);
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> forceStop(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  }) {
    return workerPool.forceStopProject(
      snapshot.request.projectId,
      timeout: timeout,
    );
  }
}

/// In-memory orchestration for `jobs.start/get/events/cancel/retry`.
///
/// Each lifecycle or worker event receives a fresh service-owned sequence, so
/// polling and streaming transports observe the same stable order even if a
/// worker uses a different sequence domain.
final class EvaluationAuthoringJobService implements AuthoringJobPort {
  EvaluationAuthoringJobService({
    required this.executor,
    DateTime Function()? clock,
    String Function()? jobIdFactory,
    EvaluationJobArtifactCollector? artifactCollector,
  })  : _clock = clock ?? DateTime.now,
        _jobIdFactory = jobIdFactory ?? _defaultJobId,
        _artifactCollector = artifactCollector ?? _noArtifacts;

  final EvaluationAuthoringJobExecutor executor;
  final DateTime Function() _clock;
  final String Function() _jobIdFactory;
  final EvaluationJobArtifactCollector _artifactCollector;
  final Map<String, _JobRecord> _jobs = <String, _JobRecord>{};
  var _closed = false;

  @override
  Future<AuthoringJobSnapshot> start(AuthoringJobRequest request) async {
    _ensureOpen();
    final jobId = _uniqueJobId();
    final record = _JobRecord(
      jobId: jobId,
      request: request,
      attempt: 1,
      createdAt: _clock().toUtc(),
    );
    _jobs[jobId] = record;
    _emit(record, 'job.queued', AuthoringJobState.queued);
    scheduleMicrotask(() => _execute(record));
    return record.snapshot();
  }

  @override
  Future<AuthoringJobSnapshot> get(String jobId) async {
    return _require(jobId).snapshot();
  }

  @override
  Future<List<AuthoringJobEvent>> events(
    String jobId, {
    int afterSequence = 0,
  }) async {
    if (afterSequence < 0) {
      throw ArgumentError.value(
        afterSequence,
        'afterSequence',
        'must not be negative',
      );
    }
    return List<AuthoringJobEvent>.unmodifiable(
      _require(jobId).events.where((event) => event.sequence > afterSequence),
    );
  }

  @override
  Future<AuthoringJobCancellation> cancel(
    String jobId, {
    required Duration timeout,
  }) async {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
    final record = _require(jobId);
    if (record.state == AuthoringJobState.cancelled) {
      return AuthoringJobCancellation(
        jobId: jobId,
        state: AuthoringJobState.cancelled,
        bounded: true,
        timeoutMilliseconds: timeout.inMilliseconds,
      );
    }
    if (record.state.isTerminal) {
      throw StateError('Job $jobId is already ${record.state.name}.');
    }
    record.cancelRequested = true;
    if (record.state != AuthoringJobState.cancelling) {
      _emit(record, 'job.cancelling', AuthoringJobState.cancelling);
    }

    final stopwatch = Stopwatch()..start();
    final acknowledged = await _withinRemaining(
      () => executor.cancel(
        record.snapshot(),
        timeout: _remaining(timeout, stopwatch),
      ),
      timeout,
      stopwatch,
      fallback: false,
    );
    if (!acknowledged && !record.terminal.isCompleted) {
      final stopped = await _withinRemaining(
        () => executor.forceStop(
          record.snapshot(),
          timeout: _remaining(timeout, stopwatch),
        ),
        timeout,
        stopwatch,
        fallback: false,
      );
      if (stopped && !record.terminal.isCompleted) {
        _finishCancelled(record, forced: true);
      }
    }
    if (!record.terminal.isCompleted) {
      await _withinRemaining<void>(
        () => record.terminal.future,
        timeout,
        stopwatch,
        fallback: null,
      );
    }
    stopwatch.stop();
    final bounded = record.state == AuthoringJobState.cancelled;
    return AuthoringJobCancellation(
      jobId: jobId,
      state:
          bounded ? AuthoringJobState.cancelled : AuthoringJobState.cancelling,
      bounded: bounded,
      timeoutMilliseconds: timeout.inMilliseconds,
    );
  }

  @override
  Future<AuthoringJobSnapshot> retry(String jobId) async {
    _ensureOpen();
    final source = _require(jobId);
    if (source.state != AuthoringJobState.failed &&
        source.state != AuthoringJobState.cancelled) {
      throw StateError(
        'Only failed or cancelled jobs can be retried; '
        '$jobId is ${source.state.name}.',
      );
    }
    final retryId = _uniqueJobId();
    final record = _JobRecord(
      jobId: retryId,
      request: source.request,
      attempt: source.attempt + 1,
      createdAt: _clock().toUtc(),
      retryOfJobId: source.jobId,
    );
    _jobs[retryId] = record;
    _emit(
      record,
      'job.queued',
      AuthoringJobState.queued,
      <String, Object?>{'retryOfJobId': source.jobId},
    );
    scheduleMicrotask(() => _execute(record));
    return record.snapshot();
  }

  Future<AuthoringJobSnapshot> waitForTerminal(String jobId) async {
    final record = _require(jobId);
    if (!record.state.isTerminal) await record.terminal.future;
    return record.snapshot();
  }

  Future<AuthoringArtifactManifest> artifacts(String jobId) async {
    final record = _require(jobId);
    return AuthoringArtifactManifest(
      jobId: jobId,
      artifacts: record.artifacts,
    );
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final active = _jobs.values.where((record) => !record.state.isTerminal);
    await Future.wait<void>(
      active.map((record) async {
        record.cancelRequested = true;
        if (!record.terminal.isCompleted) {
          await executor.forceStop(
            record.snapshot(),
            timeout: const Duration(seconds: 1),
          );
        }
      }),
    );
  }

  Future<void> _execute(_JobRecord record) async {
    if (record.cancelRequested) {
      _finishCancelled(record);
      return;
    }
    _emit(record, 'job.running', AuthoringJobState.running);
    try {
      final result = await executor.run(
        record.snapshot(),
        (workerEvent) {
          if (record.state.isTerminal) return;
          _emit(
            record,
            'worker.${workerEvent.type}',
            record.state,
            <String, Object?>{
              'workerSequence': workerEvent.sequence,
              ...workerEvent.payload,
            },
          );
        },
      );
      if (record.state.isTerminal) return;
      record.artifacts = await _artifactCollector(record.snapshot(), result);
      if (record.cancelRequested ||
          result.status == EvaluationRunStatus.cancelled) {
        _finishCancelled(record);
      } else if (result.status == EvaluationRunStatus.succeeded) {
        _finish(record, AuthoringJobState.succeeded, 'job.succeeded');
      } else {
        _finishFailed(
          record,
          'evaluation.${result.status.name}',
          result.message ?? 'Evaluation worker returned ${result.status.name}.',
        );
      }
    } on Object catch (error) {
      if (record.state.isTerminal) return;
      if (record.cancelRequested) {
        _finishCancelled(record, forced: true);
      } else {
        _finishFailed(record, 'evaluation.workerFailure', '$error');
      }
    }
  }

  void _finishCancelled(_JobRecord record, {bool forced = false}) {
    if (record.state.isTerminal) return;
    _finish(
      record,
      AuthoringJobState.cancelled,
      'job.cancelled',
      <String, Object?>{'forced': forced},
    );
  }

  void _finishFailed(_JobRecord record, String code, String message) {
    record
      ..errorCode = code
      ..errorMessage = message;
    _finish(
      record,
      AuthoringJobState.failed,
      'job.failed',
      <String, Object?>{'errorCode': code, 'message': message},
    );
  }

  void _finish(
    _JobRecord record,
    AuthoringJobState state,
    String type, [
    Map<String, Object?> payload = const <String, Object?>{},
  ]) {
    _emit(record, type, state, payload);
    if (!record.terminal.isCompleted) record.terminal.complete();
  }

  void _emit(
    _JobRecord record,
    String type,
    AuthoringJobState state, [
    Map<String, Object?> payload = const <String, Object?>{},
  ]) {
    if (!record.state.canTransitionTo(state)) {
      throw StateError(
        'Invalid job transition ${record.state.name} -> ${state.name}.',
      );
    }
    record
      ..state = state
      ..updatedAt = _clock().toUtc();
    record.events.add(
      AuthoringJobEvent(
        jobId: record.jobId,
        sequence: record.events.length + 1,
        type: type,
        state: state,
        occurredAtUtc: record.updatedAt.toIso8601String(),
        payload: payload,
      ),
    );
  }

  _JobRecord _require(String jobId) {
    final record = _jobs[jobId];
    if (record == null) throw StateError('Unknown authoring job $jobId.');
    return record;
  }

  String _uniqueJobId() {
    final id = _jobIdFactory().trim();
    if (id.isEmpty || _jobs.containsKey(id)) {
      throw StateError('Job id factory returned an invalid or duplicate id.');
    }
    return id;
  }

  void _ensureOpen() {
    if (_closed) throw StateError('Authoring job service is closed.');
  }
}

final class _JobRecord {
  _JobRecord({
    required this.jobId,
    required this.request,
    required this.attempt,
    required this.createdAt,
    this.retryOfJobId,
  }) : updatedAt = createdAt;

  final String jobId;
  final AuthoringJobRequest request;
  final int attempt;
  final DateTime createdAt;
  final String? retryOfJobId;
  DateTime updatedAt;
  AuthoringJobState state = AuthoringJobState.queued;
  final List<AuthoringJobEvent> events = <AuthoringJobEvent>[];
  final Completer<void> terminal = Completer<void>();
  List<AuthoringJobArtifact> artifacts = <AuthoringJobArtifact>[];
  String? errorCode;
  String? errorMessage;
  bool cancelRequested = false;

  AuthoringJobSnapshot snapshot() => AuthoringJobSnapshot(
        jobId: jobId,
        request: request,
        attempt: attempt,
        state: state,
        createdAtUtc: createdAt.toIso8601String(),
        updatedAtUtc: updatedAt.toIso8601String(),
        lastEventSequence: events.length,
        retryOfJobId: retryOfJobId,
        errorCode: errorCode,
        errorMessage: errorMessage,
      );
}

Future<T> _withinRemaining<T>(
  Future<T> Function() operation,
  Duration total,
  Stopwatch stopwatch, {
  required T fallback,
}) async {
  final remaining = _remaining(total, stopwatch);
  if (remaining <= Duration.zero) return fallback;
  try {
    return await operation().timeout(remaining);
  } on Object {
    return fallback;
  }
}

Duration _remaining(Duration total, Stopwatch stopwatch) {
  final remaining = total - stopwatch.elapsed;
  return remaining.isNegative ? Duration.zero : remaining;
}

String _defaultJobId() =>
    'job-${DateTime.now().toUtc().microsecondsSinceEpoch}';

Future<List<AuthoringJobArtifact>> _noArtifacts(
  AuthoringJobSnapshot snapshot,
  EvaluationWorkerResult result,
) async =>
    const <AuthoringJobArtifact>[];
