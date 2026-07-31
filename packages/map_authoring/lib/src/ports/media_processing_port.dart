import 'dart:async';

import '../contracts/artifact_ref.dart';
import '../contracts/json_contract_support.dart';
import '../support/authoring_fingerprint.dart';

enum MediaProcessingKind {
  transcodeVideo('transcode_video'),
  extractPoster('extract_poster'),
  normalizeAudio('normalize_audio'),
  subsetFont('subset_font');

  const MediaProcessingKind(this.wireName);

  final String wireName;
}

enum MediaProcessingStatus { queued, running, succeeded, failed }

final class MediaProcessingException implements Exception {
  MediaProcessingException(
    this.code,
    this.message, {
    Map<String, Object?> details = const {},
  }) : details = freezeContractJsonObject(details, field: 'details');

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'MediaProcessingException($code): $message';
}

/// Path-free request for one potentially long-running media transformation.
final class MediaProcessingRequest {
  MediaProcessingRequest({
    required String idempotencyKey,
    required this.kind,
    required this.source,
    required String expectedProjectRevision,
    required String targetMediaType,
    Map<String, Object?> options = const {},
  })  : idempotencyKey = _stableKey(idempotencyKey, 'idempotencyKey'),
        expectedProjectRevision =
            _revision(expectedProjectRevision, 'expectedProjectRevision'),
        targetMediaType = _mediaType(targetMediaType),
        options = freezeContractJsonObject(options, field: 'options');

  final String idempotencyKey;
  final MediaProcessingKind kind;
  final ContentArtifactRef source;
  final String expectedProjectRevision;
  final String targetMediaType;
  final Map<String, Object?> options;

  Map<String, Object?> toJson() => {
        'idempotencyKey': idempotencyKey,
        'kind': kind.wireName,
        'source': source.toJson(),
        'expectedProjectRevision': expectedProjectRevision,
        'targetMediaType': targetMediaType,
        'options': options,
      };
}

final class MediaProcessingResult {
  MediaProcessingResult({
    required this.output,
    Map<String, Object?> metadata = const {},
  }) : metadata = freezeContractJsonObject(metadata, field: 'metadata');

  final ContentArtifactRef output;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() => {
        'output': output.toJson(),
        'metadata': metadata,
      };
}

final class MediaProcessingJob {
  const MediaProcessingJob({
    required this.jobId,
    required this.request,
    required this.status,
    required this.createdAtUtc,
    this.result,
    this.failureCode,
  });

  final String jobId;
  final MediaProcessingRequest request;
  final MediaProcessingStatus status;
  final DateTime createdAtUtc;
  final MediaProcessingResult? result;
  final String? failureCode;

  bool get isTerminal =>
      status == MediaProcessingStatus.succeeded ||
      status == MediaProcessingStatus.failed;

  Map<String, Object?> toJson() => {
        'jobId': jobId,
        'request': request.toJson(),
        'status': status.name,
        'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
        if (result != null) 'result': result!.toJson(),
        if (failureCode != null) 'failureCode': failureCode,
      };
}

abstract interface class MediaProcessingPort {
  Future<MediaProcessingJob> submit(MediaProcessingRequest request);

  Future<MediaProcessingJob> status(String jobId);

  Future<MediaProcessingJob> wait(String jobId);
}

typedef MediaProcessor = Future<MediaProcessingResult> Function(
  MediaProcessingRequest request,
);

/// Deterministic in-process adapter used by hosts and contract tests.
///
/// A production host can implement [MediaProcessingPort] with an isolated
/// worker or service without giving the authoring API process or filesystem
/// authority. Submission is idempotent and always returns before processing
/// completion.
final class InMemoryMediaProcessingPort implements MediaProcessingPort {
  InMemoryMediaProcessingPort({
    required MediaProcessor processor,
    DateTime Function()? clock,
  })  : _processor = processor,
        _clock = clock ?? (() => DateTime.now().toUtc());

  final MediaProcessor _processor;
  final DateTime Function() _clock;
  final Map<String, MediaProcessingJob> _jobs = {};
  final Map<String, Completer<MediaProcessingJob>> _completions = {};

  @override
  Future<MediaProcessingJob> submit(MediaProcessingRequest request) async {
    final jobId = 'media-job:${request.idempotencyKey}';
    final existing = _jobs[jobId];
    if (existing != null) {
      if (!_sameRequest(existing.request, request)) {
        throw MediaProcessingException(
          'media.idempotency_conflict',
          'The idempotency key is already bound to another media request.',
          details: {'idempotencyKey': request.idempotencyKey},
        );
      }
      return existing;
    }
    final queued = MediaProcessingJob(
      jobId: jobId,
      request: request,
      status: MediaProcessingStatus.queued,
      createdAtUtc: _clock().toUtc(),
    );
    _jobs[jobId] = queued;
    _completions[jobId] = Completer<MediaProcessingJob>();
    scheduleMicrotask(() => _run(jobId));
    return queued;
  }

  @override
  Future<MediaProcessingJob> status(String jobId) async => _require(jobId);

  @override
  Future<MediaProcessingJob> wait(String jobId) {
    final job = _require(jobId);
    if (job.isTerminal) return Future.value(job);
    return _completions[jobId]!.future;
  }

  Future<void> _run(String jobId) async {
    final queued = _require(jobId);
    _jobs[jobId] = MediaProcessingJob(
      jobId: jobId,
      request: queued.request,
      status: MediaProcessingStatus.running,
      createdAtUtc: queued.createdAtUtc,
    );
    late final MediaProcessingJob terminal;
    try {
      final result = await _processor(queued.request);
      if (result.output.mediaType != queued.request.targetMediaType) {
        throw MediaProcessingException(
          'media.output_type_mismatch',
          'The processor output does not match the requested media type.',
          details: {
            'expected': queued.request.targetMediaType,
            'actual': result.output.mediaType,
          },
        );
      }
      terminal = MediaProcessingJob(
        jobId: jobId,
        request: queued.request,
        status: MediaProcessingStatus.succeeded,
        createdAtUtc: queued.createdAtUtc,
        result: result,
      );
    } on Object catch (error) {
      terminal = MediaProcessingJob(
        jobId: jobId,
        request: queued.request,
        status: MediaProcessingStatus.failed,
        createdAtUtc: queued.createdAtUtc,
        failureCode: error is MediaProcessingException
            ? error.code
            : 'media.processor_failed',
      );
    }
    _jobs[jobId] = terminal;
    _completions.remove(jobId)!.complete(terminal);
  }

  MediaProcessingJob _require(String jobId) {
    final normalized = _stableKey(jobId, 'jobId');
    final job = _jobs[normalized];
    if (job == null) {
      throw MediaProcessingException(
        'media.job_unknown',
        'The media processing job does not exist.',
        details: {'jobId': normalized},
      );
    }
    return job;
  }
}

bool _sameRequest(MediaProcessingRequest left, MediaProcessingRequest right) =>
    canonicalAuthoringJson(left.toJson()) ==
    canonicalAuthoringJson(right.toJson());

String _stableKey(String value, String field) {
  final normalized = value.trim();
  if (normalized != value ||
      !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.:-]*$').hasMatch(normalized)) {
    throw ArgumentError.value(value, field, 'must be a stable key');
  }
  return normalized;
}

String _revision(String value, String field) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a SHA-256 revision');
  }
  return value;
}

String _mediaType(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized != value ||
      !RegExp(r'^[a-z0-9][a-z0-9!#$&^_.+-]*/[a-z0-9][a-z0-9!#$&^_.+-]*$')
          .hasMatch(normalized)) {
    throw ArgumentError.value(value, 'targetMediaType', 'must be a MIME type');
  }
  return normalized;
}
