import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:map_distribution/map_distribution.dart';

import '../contracts/job_contracts.dart';
import '../contracts/json_contract_support.dart';

final class ResourcePackTransferException implements Exception {
  const ResourcePackTransferException(
    this.code,
    this.message, {
    this.details = const {},
  });
  final String code;
  final String message;
  final Map<String, Object?> details;
  @override
  String toString() => '$code: $message';
}

final class ResourcePackJobContext {
  ResourcePackJobContext._(this._job, this._checkOwner);
  final _Job _job;
  final void Function() _checkOwner;
  Future<void> Function()? _discardResult;

  void onResultRejected(Future<void> Function() discard) {
    if (_discardResult != null) {
      throw StateError('A result owner is already registered for this job.');
    }
    _discardResult = discard;
  }

  void checkCancelled() {
    if (!_job.cancelAllowed) return;
    _checkOwner();
    if (_job.cancelRequested) throw const _Cancelled();
  }

  void progress(String phase, {Map<String, int> counters = const {}}) {
    checkCancelled();
    _job.emit(phase, counters: counters);
  }

  void enterFinalization() {
    checkCancelled();
    _job.cancelAllowed = false;
    _job.emit('finalizing');
  }
}

typedef ResourcePackJobWork = Future<Map<String, Object?>> Function(
  ResourcePackJobContext context,
);

final class ResourcePackJobService implements AuthoringJobPort {
  ResourcePackJobService({
    required void Function() requireActive,
    DateTime Function()? clock,
    String Function()? tokenFactory,
  }) : _requireActive = requireActive,
       _clock = clock ?? DateTime.now,
       _tokenFactory = tokenFactory ?? _token;

  final void Function() _requireActive;
  final DateTime Function() _clock;
  final String Function() _tokenFactory;
  final Map<String, _Job> _jobs = {};
  bool _closed = false;
  Future<List<AuthoringJobSnapshot>>? _closing;

  Future<AuthoringJobSnapshot> startWork(
    AuthoringJobRequest request,
    ResourcePackJobWork work, {
    Future<void> Function()? onSettled,
  }) {
    _checkOpen();
    if (!const {
      'resource_pack.stage',
      'resource_pack.license.stage',
      'resource_pack.inspect',
      'resource_pack.diagnose',
      'resource_pack.prepare',
      'resource_pack.import',
      'resource_pack.export',
      'resource_pack.undo',
      'resource_pack.redo',
      'resource_pack.revert',
      'resource_pack.recover',
    }.contains(request.kind)) {
      throw const ResourcePackTransferException(
        'resource_pack.job_kind_invalid',
        'Unsupported pack job kind.',
      );
    }
    if (_jobs.length >= 512 ||
        utf8.encode(jsonEncode(request.toJson())).length > 4096) {
      throw const ResourcePackTransferException(
        'resource_pack.job_limit',
        'The bounded job session is full.',
      );
    }
    final id = _tokenFactory();
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id) ||
        _jobs.containsKey(id)) {
      throw StateError('The job token factory reused an identity.');
    }
    final job = _Job(id, request, _clock);
    _jobs[id] = job;
    final initial = job.snapshot;
    job.completion = Future<void>(() async {
      final context = ResourcePackJobContext._(job, _checkOpen);
      try {
        _checkOpen();
        if (job.cancelRequested) throw const _Cancelled();
        job.state = AuthoringJobState.running;
        job.emit('running');
        final result = await work(context);
        if (job.cancelAllowed) _checkOpen();
        if (job.cancelAllowed && job.cancelRequested) throw const _Cancelled();
        if (utf8.encode(jsonEncode(result)).length > 240 * 1024) {
          throw const ResourcePackTransferException(
            'resource_pack.result_too_large',
            'Use bounded result references.',
          );
        }
        job.result = freezeContractJsonObject(result, field: 'resourcePackJob.result');
        job.state = AuthoringJobState.succeeded;
        job.emit('completed');
      } on _Cancelled {
        if (job.cancelAllowed) {
          job.state = AuthoringJobState.cancelled;
          job.emit('cancelled');
        } else {
          job.state = AuthoringJobState.failed;
          job.errorCode = 'resource_pack.recovery_required';
          job.errorMessage = 'Finalization requires canonical recovery.';
          job.emit('recoveryRequired');
        }
      } on Object catch (error) {
        if (job.cancelAllowed && job.cancelRequested) {
          job.state = AuthoringJobState.cancelled;
          job.emit('cancelled');
          return;
        }
        job.state = AuthoringJobState.failed;
        job.errorCode = _code(error);
        if (job.cancelAllowed && error is CatalogBudgetExceededException) {
          final result = {'budgetReport': error.report.toBoundedJson()};
          if (utf8.encode(jsonEncode(result)).length <= 240 * 1024) {
            job.result = freezeContractJsonObject(result,
                field: 'resourcePackJob.budget');
          }
          job.errorCode = error.code;
          job.errorMessage = error.message;
          job.emit('failed');
          return;
        }
        if (job.cancelAllowed && error is GamePackageFormatException) {
          final report = error.details?['budgetReport'];
          if (report is Map<String, Object?>) {
            final result = {'budgetReport': report};
            if (utf8.encode(jsonEncode(result)).length <= 240 * 1024) {
              job.result = freezeContractJsonObject(result,
                  field: 'resourcePackJob.budget');
              job.errorCode = error.code;
              job.errorMessage =
                  'Le pack dépasse les limites indiquées dans le rapport de volumes.';
              job.emit('failed');
              return;
            }
          }
        }
        job.errorMessage = job.cancelAllowed
            ? 'The pack operation failed before finalization.'
            : 'Finalization requires the canonical receipt or transaction recovery.';
        job.emit(job.cancelAllowed ? 'failed' : 'recoveryRequired');
      } finally {
        try {
          try {
            if (job.state != AuthoringJobState.succeeded) {
              await context._discardResult?.call();
            }
          } finally {
            await onSettled?.call();
          }
        } on Object {
          job.result = {
            ...?job.result,
            'cleanupDiagnostic': {'code': 'resource_pack.cleanup_required'},
          };
        }
      }
    });
    return Future.value(initial);
  }

  @override
  Future<AuthoringJobSnapshot> start(AuthoringJobRequest request) =>
      throw const ResourcePackTransferException(
        'resource_pack.start_requires_transfer',
        'Start jobs through the scoped pack transfer API.',
      );

  @override
  Future<AuthoringJobSnapshot> get(String jobId) async =>
      _require(jobId).snapshot;

  Map<String, Object?> result(String jobId) {
    final job = _require(jobId);
    return freezeContractJsonObject({
      'snapshot': job.snapshot.toJson(),
      'phase': job.phase,
      'cancelAllowed': job.cancelAllowed && !job.state.isTerminal,
      if (job.result != null) 'result': job.result,
    }, field: 'resourcePackJob');
  }

  @override
  Future<List<AuthoringJobEvent>> events(
    String jobId, {
    int afterSequence = 0,
  }) async {
    if (afterSequence < 0) throw ArgumentError.value(afterSequence);
    final job = _require(jobId);
    final rows = <AuthoringJobEvent>[];
    var bytes = 4096;
    for (final event in job.events.where((e) => e.sequence > afterSequence)) {
      final length = utf8.encode(jsonEncode(event.toJson())).length;
      if (rows.length == 200 || bytes + length > 240 * 1024) break;
      rows.add(event);
      bytes += length;
    }
    return rows;
  }

  @override
  Future<AuthoringJobCancellation> cancel(
    String jobId, {
    required Duration timeout,
  }) async {
    final job = _require(jobId);
    if (!job.cancelAllowed ||
        (job.state.isTerminal && job.state != AuthoringJobState.cancelled)) {
      throw ResourcePackTransferException(
        'resource_pack.cancel_not_allowed',
        'The job has entered finalization or already finished.',
        details: {'jobId': jobId, 'phase': job.phase, 'cancelAllowed': false},
      );
    }
    job.cancelRequested = true;
    if (job.state != AuthoringJobState.cancelled) {
      job.state = AuthoringJobState.cancelling;
      job.emit('cancelling');
    }
    return AuthoringJobCancellation(
      jobId: jobId,
      state: job.state,
      bounded: false,
      timeoutMilliseconds: max(1, timeout.inMilliseconds),
    );
  }

  @override
  Future<AuthoringJobSnapshot> retry(String jobId) =>
      throw const ResourcePackTransferException(
        'resource_pack.retry_requires_transfer',
        'Retry with a fresh scoped transfer request and the same canonical operation identity.',
      );

  Future<List<AuthoringJobSnapshot>> close() => _closing ??= _finishClose();

  Future<List<AuthoringJobSnapshot>> _finishClose() async {
    _closed = true;
    for (final job in _jobs.values) {
      if (job.cancelAllowed && !job.state.isTerminal) {
        job.cancelRequested = true;
      }
    }
    await Future.wait(_jobs.values.map((job) => job.completion));
    return [for (final job in _jobs.values) job.snapshot];
  }

  void _checkOpen() {
    if (_closed) throw const _Cancelled();
    _requireActive();
  }

  _Job _require(String id) {
    _checkOpen();
    final job = _jobs[id];
    if (job == null) {
      throw const ResourcePackTransferException(
        'resource_pack.job_unknown',
        'The job is unknown in this session.',
      );
    }
    return job;
  }
}

final class _Job {
  _Job(this.id, this.request, this.clock)
    : created = clock().toUtc().toIso8601String() {
    emit('queued');
  }
  final String id;
  final AuthoringJobRequest request;
  final DateTime Function() clock;
  final String created;
  final List<AuthoringJobEvent> events = [];
  AuthoringJobState state = AuthoringJobState.queued;
  String phase = 'queued';
  String? errorCode;
  String? errorMessage;
  bool cancelRequested = false;
  bool cancelAllowed = true;
  Map<String, Object?>? result;
  Future<void> completion = Future.value();
  void emit(String value, {Map<String, int> counters = const {}}) {
    phase = value;
    events.add(
      AuthoringJobEvent(
        jobId: id,
        sequence: events.length + 1,
        type: 'resource_pack.progress',
        state: state,
        occurredAtUtc: clock().toUtc().toIso8601String(),
        payload: {
          'phase': phase,
          'cancelAllowed': cancelAllowed && !state.isTerminal,
          'progress': counters.isEmpty ? 'indeterminate' : 'measured',
          if (counters.isNotEmpty) 'counters': counters,
        },
      ),
    );
  }

  AuthoringJobSnapshot get snapshot => AuthoringJobSnapshot(
    jobId: id,
    request: request,
    attempt: 1,
    state: state,
    createdAtUtc: created,
    updatedAtUtc: events.last.occurredAtUtc,
    lastEventSequence: events.length,
    errorCode: errorCode,
    errorMessage: errorMessage,
  );
}

final class _Cancelled implements Exception {
  const _Cancelled();
}

String _code(Object error) {
  if (error is ResourcePackTransferException) return error.code;
  try {
    final code = (error as dynamic).code;
    if (code is String && RegExp(r'^[a-zA-Z0-9_.]{1,128}$').hasMatch(code)) {
      return code;
    }
  } on Object {
    return 'resource_pack.operation_failed';
  }
  return 'resource_pack.operation_failed';
}

String _token() {
  final random = Random.secure();
  return 'job_${List.generate(24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}
