import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../contracts/evaluation_event.dart';
import '../contracts/evaluation_policy.dart';
import '../contracts/evaluation_receipt.dart';

enum EvaluationRunLifecycle {
  queued,
  running,
  paused,
  succeeded,
  failed,
  cancelled,
}

final class EvaluationRunDescriptor {
  EvaluationRunDescriptor({
    required String runId,
    required String projectId,
    required String scenarioId,
    required this.policy,
    required this.target,
    required DateTime createdAt,
  })  : runId = _identifier(runId, 'runId'),
        projectId = _identifier(projectId, 'projectId'),
        scenarioId = _identifier(scenarioId, 'scenarioId'),
        createdAt = createdAt.toUtc();

  final String runId;
  final String projectId;
  final String scenarioId;
  final EvaluationPolicy policy;
  final EvaluationTarget target;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runId': runId,
      'projectId': projectId,
      'scenarioId': scenarioId,
      'policy': policy.name,
      'target': target.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

final class EvaluationRunRecord {
  EvaluationRunRecord._({
    required this.descriptor,
    required List<EvaluationEvent> events,
  }) : events = List<EvaluationEvent>.unmodifiable(events);

  final EvaluationRunDescriptor descriptor;
  final List<EvaluationEvent> events;

  String get runId => descriptor.runId;
  int get lastSequence => events.isEmpty ? 0 : events.last.sequence;
  EvaluationRunLifecycle get lifecycle => _lifecycleFor(events);

  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...descriptor.toJson(),
      'lifecycle': lifecycle.name,
      'lastSequence': lastSequence,
      'events': events.map((event) => event.toJson()).toList(growable: false),
    };
  }
}

final class EvaluationRunHistoryRecord {
  const EvaluationRunHistoryRecord({
    required this.receipt,
    required this.receiptPath,
  });

  final EvaluationReceipt receipt;
  final String receiptPath;

  String get runId => receipt.runId;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runId': receipt.runId,
      'projectId': receipt.projectId,
      'scenarioId': receipt.scenarioId,
      'policy': receipt.policy.name,
      'target': receipt.target.name,
      'evidenceLevel': receipt.evidenceLevel.name,
      'status': receipt.status.name,
      'startedAt': receipt.startedAt.toIso8601String(),
      'finishedAt': receipt.finishedAt.toIso8601String(),
      'durationMilliseconds': receipt.duration.inMilliseconds,
      'receiptPath': receiptPath,
    };
  }
}

final class EvaluationRunStore {
  EvaluationRunStore({required Directory historyRoot})
      : historyRoot = historyRoot.absolute;

  final Directory historyRoot;
  final Map<String, _MutableEvaluationRunRecord> _runs =
      <String, _MutableEvaluationRunRecord>{};
  final Map<String, StreamController<EvaluationEvent>> _events =
      <String, StreamController<EvaluationEvent>>{};

  bool _closed = false;
  int _invalidHistoryEntryCount = 0;

  int get invalidHistoryEntryCount => _invalidHistoryEntryCount;

  List<EvaluationRunRecord> get activeRuns {
    final records = _runs.values.map((run) => run.snapshot()).toList()
      ..sort(
        (left, right) =>
            right.descriptor.createdAt.compareTo(left.descriptor.createdAt),
      );
    return List<EvaluationRunRecord>.unmodifiable(records);
  }

  Stream<EvaluationEvent> eventsFor(String runId) {
    _ensureOpen();
    final validRunId = _identifier(runId, 'runId');
    return (_events[validRunId] ??=
            StreamController<EvaluationEvent>.broadcast())
        .stream;
  }

  EvaluationRunRecord create(EvaluationRunDescriptor descriptor) {
    _ensureOpen();
    if (_runs.containsKey(descriptor.runId)) {
      throw StateError('Evaluation run ${descriptor.runId} already exists.');
    }
    final run = _MutableEvaluationRunRecord(descriptor);
    _runs[descriptor.runId] = run;
    return run.snapshot();
  }

  EvaluationRunRecord requireRun(String runId) {
    final validRunId = _identifier(runId, 'runId');
    final run = _runs[validRunId];
    if (run == null) {
      throw StateError('Unknown evaluation run $validRunId.');
    }
    return run.snapshot();
  }

  void append(EvaluationEvent event) {
    _ensureOpen();
    final run = _runs[event.runId];
    if (run == null) {
      throw StateError('Unknown evaluation run ${event.runId}.');
    }
    if (event.sequence != run.lastSequence + 1) {
      throw StateError(
        'Non-contiguous event sequence for ${event.runId}: expected '
        '${run.lastSequence + 1}, got ${event.sequence}.',
      );
    }
    run.events.add(event);
    _events[event.runId]?.add(event);
  }

  Future<List<EvaluationRunHistoryRecord>> loadHistory() async {
    _ensureOpen();
    _invalidHistoryEntryCount = 0;
    final runsRoot = Directory(p.join(historyRoot.path, 'runs'));
    if (!await runsRoot.exists()) {
      return const <EvaluationRunHistoryRecord>[];
    }

    final records = <EvaluationRunHistoryRecord>[];
    await for (final entity
        in runsRoot.list(recursive: false, followLinks: false)) {
      if (entity is! Directory) continue;
      final directoryRunId = p.basename(entity.path);
      if (!_isIdentifier(directoryRunId)) {
        _invalidHistoryEntryCount += 1;
        continue;
      }
      final receiptFile = File(p.join(entity.path, 'receipt.json'));
      if (!await receiptFile.exists()) continue;
      try {
        final decoded = jsonDecode(await receiptFile.readAsString());
        if (decoded is! Map) {
          throw const FormatException('Receipt root must be an object.');
        }
        final receipt = EvaluationReceipt.fromJson(
          Map<String, Object?>.from(decoded),
        );
        if (receipt.runId != directoryRunId) {
          throw const FormatException(
            'Receipt run id must match its directory.',
          );
        }
        records.add(
          EvaluationRunHistoryRecord(
            receipt: receipt,
            receiptPath: p.posix.join(
              'runs',
              directoryRunId,
              'receipt.json',
            ),
          ),
        );
      } on Object {
        _invalidHistoryEntryCount += 1;
      }
    }
    records.sort((left, right) {
      final byFinishedAt =
          right.receipt.finishedAt.compareTo(left.receipt.finishedAt);
      return byFinishedAt != 0
          ? byFinishedAt
          : left.runId.compareTo(right.runId);
    });
    return List<EvaluationRunHistoryRecord>.unmodifiable(records);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await Future.wait<void>(
      _events.values.map((controller) => controller.close()),
    );
    _events.clear();
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('Evaluation run store is closed.');
    }
  }
}

final class _MutableEvaluationRunRecord {
  _MutableEvaluationRunRecord(this.descriptor);

  final EvaluationRunDescriptor descriptor;
  final List<EvaluationEvent> events = <EvaluationEvent>[];

  int get lastSequence => events.isEmpty ? 0 : events.last.sequence;

  EvaluationRunRecord snapshot() {
    return EvaluationRunRecord._(
      descriptor: descriptor,
      events: events,
    );
  }
}

EvaluationRunLifecycle _lifecycleFor(List<EvaluationEvent> events) {
  if (events.isEmpty) return EvaluationRunLifecycle.queued;
  return switch (events.last.type) {
    'run.paused' => EvaluationRunLifecycle.paused,
    'run.succeeded' || 'run.completed' => EvaluationRunLifecycle.succeeded,
    'run.failed' => EvaluationRunLifecycle.failed,
    'run.cancelled' => EvaluationRunLifecycle.cancelled,
    _ => EvaluationRunLifecycle.running,
  };
}

String _identifier(String value, String name) {
  if (!_isIdentifier(value)) {
    throw ArgumentError.value(
      value,
      name,
      'Expected 1-128 ASCII letters, digits, dots, underscores, or hyphens.',
    );
  }
  return value;
}

bool _isIdentifier(String value) {
  return RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$').hasMatch(value);
}
