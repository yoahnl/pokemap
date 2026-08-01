import 'dart:async';
import 'dart:isolate';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../models/narrative_event_authoring_session.dart';
import '../../infrastructure/repositories/narrative_runtime_smoke_receipt_repository.dart';
import 'narrative_studio_validation_coordinator.dart';

const _narrativeValidatorIsolateName = 'pokemap-narrative-validator';

enum NarrativeValidatorWorkKind { projectReport, multidimensionalReport }

/// Immutable input copied to the dedicated Narrative Validator isolate.
final class NarrativeValidatorWork {
  NarrativeValidatorWork({
    required this.validationId,
    required String projectRootPath,
    required this.project,
    required Set<String>? knownSpeciesIds,
    required Set<String>? knownMoveIds,
    required this.requirePokemonCatalogs,
    this.activeMap,
  })  : projectRootPath = p.normalize(projectRootPath),
        kind = NarrativeValidatorWorkKind.projectReport,
        projectValidationId = validationId,
        projectReport = null,
        knownSpeciesIds = knownSpeciesIds == null
            ? null
            : Set<String>.unmodifiable(knownSpeciesIds),
        knownMoveIds = knownMoveIds == null
            ? null
            : Set<String>.unmodifiable(knownMoveIds);

  NarrativeValidatorWork.multidimensional({
    required this.validationId,
    required this.projectValidationId,
    required String projectRootPath,
    required this.project,
    required this.projectReport,
    this.activeMap,
  })  : projectRootPath = p.normalize(projectRootPath),
        kind = NarrativeValidatorWorkKind.multidimensionalReport,
        knownSpeciesIds = null,
        knownMoveIds = null,
        requirePokemonCatalogs = false;

  final String validationId;
  final String projectValidationId;
  final String projectRootPath;
  final NarrativeValidatorWorkKind kind;
  final ProjectManifest project;
  final MapData? activeMap;
  final NarrativeProjectValidationReport? projectReport;
  final Set<String>? knownSpeciesIds;
  final Set<String>? knownMoveIds;
  final bool requirePokemonCatalogs;
}

final class NarrativeValidatorExecutionResult {
  const NarrativeValidatorExecutionResult({
    required this.validationId,
    this.report,
    this.multidimensionalReport,
    required this.workerIsolateDebugName,
    required this.workerControlPort,
  }) : assert(
          (report == null) != (multidimensionalReport == null),
          'Exactly one validation report phase must be present.',
        );

  final String validationId;
  final NarrativeProjectValidationReport? report;
  final NarrativeMultidimensionalValidationReport? multidimensionalReport;
  final String? workerIsolateDebugName;
  final SendPort? workerControlPort;
}

enum NarrativeValidatorCancellationReason {
  superseded,
  providerDisposed,
  executorDisposed,
}

final class NarrativeValidatorCancelledException implements Exception {
  const NarrativeValidatorCancelledException({
    required this.validationId,
    required this.reason,
  });

  final String validationId;
  final NarrativeValidatorCancellationReason reason;

  @override
  String toString() =>
      'Narrative validation $validationId cancelled (${reason.name}).';
}

final class NarrativeValidatorWorkerException implements Exception {
  const NarrativeValidatorWorkerException({
    required this.message,
    required this.workerStackTrace,
  });

  final String message;
  final String workerStackTrace;

  @override
  String toString() => 'Narrative validator worker failed: $message';
}

abstract interface class NarrativeValidatorExecutor {
  Future<NarrativeValidatorExecutionResult> execute(
    NarrativeValidatorWork work,
  );

  void cancel(
    String validationId, {
    NarrativeValidatorCancellationReason reason,
  });

  void dispose();
}

/// Runs at most one validation per project root and gives the most recent
/// snapshot of that project priority. Superseded isolates are killed instead
/// of continuing to consume a core after Riverpod has moved to newer data.
final class IsolateNarrativeValidatorExecutor
    implements NarrativeValidatorExecutor {
  IsolateNarrativeValidatorExecutor({
    this.debounceDuration = const Duration(milliseconds: 120),
    this.onWorkerSpawned,
    this.onWorkerExited,
  });

  final Duration debounceDuration;
  final void Function(String validationId)? onWorkerSpawned;
  final void Function(String validationId)? onWorkerExited;

  final Map<String, _NarrativeValidatorIsolateTask> _activeTasks = {};
  final Map<String, String> _currentProjectValidationIds = {};
  bool _disposed = false;

  @override
  Future<NarrativeValidatorExecutionResult> execute(
    NarrativeValidatorWork work,
  ) {
    if (_disposed) {
      return Future<NarrativeValidatorExecutionResult>.error(
        StateError('The Narrative Validator executor is disposed.'),
      );
    }

    final scope = work.projectRootPath;
    switch (work.kind) {
      case NarrativeValidatorWorkKind.projectReport:
        _currentProjectValidationIds[scope] = work.projectValidationId;
      case NarrativeValidatorWorkKind.multidimensionalReport:
        if (_currentProjectValidationIds[scope] != work.projectValidationId) {
          return Future<NarrativeValidatorExecutionResult>.error(
            NarrativeValidatorCancelledException(
              validationId: work.validationId,
              reason: NarrativeValidatorCancellationReason.superseded,
            ),
            StackTrace.current,
          );
        }
    }
    final previousTask = _activeTasks[scope];
    final previousExit = previousTask?.exited;
    previousTask?.cancel(NarrativeValidatorCancellationReason.superseded);
    late final _NarrativeValidatorIsolateTask task;
    task = _NarrativeValidatorIsolateTask(
      work: work,
      debounceDuration: debounceDuration,
      onWorkerSpawned: onWorkerSpawned,
      onWorkerExited: onWorkerExited,
      onFinished: () {
        if (identical(_activeTasks[scope], task)) {
          _activeTasks.remove(scope);
        }
      },
    );
    _activeTasks[scope] = task;
    task.start(after: previousExit);
    return task.future;
  }

  @override
  void cancel(
    String validationId, {
    NarrativeValidatorCancellationReason reason =
        NarrativeValidatorCancellationReason.providerDisposed,
  }) {
    for (final task in _activeTasks.values) {
      if (task.validationId == validationId) {
        task.cancel(reason);
        return;
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final task in _activeTasks.values.toList(growable: false)) {
      task.cancel(NarrativeValidatorCancellationReason.executorDisposed);
    }
    _activeTasks.clear();
    _currentProjectValidationIds.clear();
  }
}

final class _NarrativeValidatorIsolateTask {
  _NarrativeValidatorIsolateTask({
    required this.work,
    required this.debounceDuration,
    required this.onWorkerSpawned,
    required this.onWorkerExited,
    required this.onFinished,
  });

  final NarrativeValidatorWork work;
  final Duration debounceDuration;
  final void Function(String validationId)? onWorkerSpawned;
  final void Function(String validationId)? onWorkerExited;
  final void Function() onFinished;
  final Completer<NarrativeValidatorExecutionResult> _completer =
      Completer<NarrativeValidatorExecutionResult>();
  final Completer<void> _exitCompleter = Completer<void>();

  Timer? _debounceTimer;
  ReceivePort? _receivePort;
  StreamSubscription<Object?>? _receiveSubscription;
  Isolate? _isolate;
  Future<void>? _predecessorExit;
  bool _spawnStarted = false;
  bool _workerSpawned = false;
  bool _killRequested = false;

  String get validationId => work.validationId;
  Future<NarrativeValidatorExecutionResult> get future => _completer.future;
  Future<void> get exited => _exitCompleter.future;

  void start({Future<void>? after}) {
    _predecessorExit = after;
    if (after == null) {
      _armDebounce();
      return;
    }
    unawaited(_startAfter(after));
  }

  Future<void> _startAfter(Future<void> predecessorExit) async {
    await predecessorExit;
    _predecessorExit = null;
    if (_killRequested) {
      _finishExited();
      return;
    }
    _armDebounce();
  }

  void _armDebounce() {
    if (_exitCompleter.isCompleted || _killRequested) {
      return;
    }
    _debounceTimer = Timer(
      debounceDuration,
      () => unawaited(_spawn()),
    );
  }

  Future<void> _spawn() async {
    if (_killRequested || _exitCompleter.isCompleted) {
      return;
    }
    _spawnStarted = true;

    final receivePort = ReceivePort();
    _receivePort = receivePort;
    _receiveSubscription = receivePort.listen(_handleWorkerMessage);
    try {
      final isolate = await Isolate.spawn<_NarrativeValidatorIsolateCommand>(
        _runNarrativeValidation,
        _NarrativeValidatorIsolateCommand(
          resultPort: receivePort.sendPort,
          work: work,
        ),
        debugName: _narrativeValidatorIsolateName,
        errorsAreFatal: true,
        onError: receivePort.sendPort,
        onExit: receivePort.sendPort,
      );
      if (_exitCompleter.isCompleted) {
        isolate.kill(priority: Isolate.immediate);
        return;
      }
      _isolate = isolate;
      _workerSpawned = true;
      if (_killRequested) {
        isolate.kill(priority: Isolate.immediate);
      } else {
        try {
          onWorkerSpawned?.call(validationId);
        } on Object catch (error, stackTrace) {
          _killRequested = true;
          _completeError(error, stackTrace);
          isolate.kill(priority: Isolate.immediate);
        }
      }
    } on Object catch (error, stackTrace) {
      _completeError(error, stackTrace);
      _finishExited();
    }
  }

  void _handleWorkerMessage(Object? message) {
    if (message == null) {
      if (!_completer.isCompleted) {
        _completeError(
          const NarrativeValidatorWorkerException(
            message: 'The worker exited without returning a report.',
            workerStackTrace: '',
          ),
          StackTrace.current,
        );
      }
      _finishExited();
      return;
    }
    if (_completer.isCompleted) {
      return;
    }
    if (message is! List || message.isEmpty) {
      _completeProtocolError('Unexpected worker response: $message');
      return;
    }

    switch (message.first) {
      case _workerSuccess:
        if (message.length != 6 ||
            message[1] is! String ||
            (message[2] != null &&
                message[2] is! NarrativeProjectValidationReport) ||
            (message[3] != null &&
                message[3] is! NarrativeMultidimensionalValidationReport) ||
            ((message[2] == null) == (message[3] == null)) ||
            message[4] is! String? ||
            message[5] is! SendPort) {
          _completeProtocolError('Malformed worker success response.');
          return;
        }
        _complete(
          NarrativeValidatorExecutionResult(
            validationId: message[1] as String,
            report: message[2] as NarrativeProjectValidationReport?,
            multidimensionalReport:
                message[3] as NarrativeMultidimensionalValidationReport?,
            workerIsolateDebugName: message[4] as String?,
            workerControlPort: message[5] as SendPort,
          ),
        );
      case _workerFailure:
        if (message.length != 3 ||
            message[1] is! String ||
            message[2] is! String) {
          _completeProtocolError('Malformed worker failure response.');
          return;
        }
        _completeError(
          NarrativeValidatorWorkerException(
            message: message[1] as String,
            workerStackTrace: message[2] as String,
          ),
          StackTrace.fromString(message[2] as String),
        );
      default:
        // Uncaught isolate errors arrive as [error, stackTrace].
        _completeError(
          NarrativeValidatorWorkerException(
            message: '${message.first}',
            workerStackTrace: message.length > 1 ? '${message[1]}' : '',
          ),
          message.length > 1
              ? StackTrace.fromString('${message[1]}')
              : StackTrace.current,
        );
    }
  }

  void _completeProtocolError(String message) {
    _killRequested = true;
    _completeError(
      NarrativeValidatorWorkerException(
        message: message,
        workerStackTrace: '',
      ),
      StackTrace.current,
    );
    _isolate?.kill(priority: Isolate.immediate);
  }

  void cancel(NarrativeValidatorCancellationReason reason) {
    if (_exitCompleter.isCompleted) {
      return;
    }
    _killRequested = true;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _isolate?.kill(priority: Isolate.immediate);
    if (!_completer.isCompleted) {
      _completeError(
        NarrativeValidatorCancelledException(
          validationId: validationId,
          reason: reason,
        ),
        StackTrace.current,
      );
    }
    if (!_spawnStarted && _predecessorExit == null) {
      _finishExited();
    }
  }

  void _complete(NarrativeValidatorExecutionResult result) {
    if (_completer.isCompleted) {
      return;
    }
    _completer.complete(result);
  }

  void _completeError(Object error, StackTrace stackTrace) {
    if (_completer.isCompleted) {
      return;
    }
    _completer.completeError(error, stackTrace);
  }

  void _finishExited() {
    if (_exitCompleter.isCompleted) {
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = null;
    final subscription = _receiveSubscription;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    _receiveSubscription = null;
    _receivePort?.close();
    _receivePort = null;
    _isolate = null;
    _exitCompleter.complete();
    if (_workerSpawned) {
      onWorkerExited?.call(validationId);
    }
    onFinished();
  }
}

const _workerSuccess = 'success';
const _workerFailure = 'failure';

final class _NarrativeValidatorIsolateCommand {
  const _NarrativeValidatorIsolateCommand({
    required this.resultPort,
    required this.work,
  });

  final SendPort resultPort;
  final NarrativeValidatorWork work;
}

@pragma('vm:entry-point')
Future<void> _runNarrativeValidation(
  _NarrativeValidatorIsolateCommand command,
) async {
  try {
    final work = command.work;
    final maps = await _loadValidationMaps(work);
    switch (work.kind) {
      case NarrativeValidatorWorkKind.projectReport:
        final report = validateNarrativeProject(
          work.project,
          maps: maps,
          knownSpeciesIds: work.knownSpeciesIds,
          knownMoveIds: work.knownMoveIds,
          requirePokemonCatalogs: work.requirePokemonCatalogs,
        );
        Isolate.exit(command.resultPort, <Object?>[
          _workerSuccess,
          work.validationId,
          report,
          null,
          Isolate.current.debugName,
          Isolate.current.controlPort,
        ]);
      case NarrativeValidatorWorkKind.multidimensionalReport:
        const receipts = NarrativeRuntimeSmokeReceiptRepository();
        final projectFingerprint =
            await receipts.computeProjectFingerprint(work.projectRootPath);
        final runtimeReceipt = await receipts.read(
          projectRoot: work.projectRootPath,
          expectedFingerprint: projectFingerprint,
          profile: selbrumeReleaseV1Profile,
        );
        final multidimensionalReport =
            const NarrativeStudioValidationCoordinator().coordinate(
          project: work.project,
          maps: maps,
          projectReport: work.projectReport!,
          projectFingerprint: projectFingerprint,
          profile: selbrumeReleaseV1Profile,
          runtimeReceipt: runtimeReceipt,
        );
        Isolate.exit(command.resultPort, <Object?>[
          _workerSuccess,
          work.validationId,
          null,
          multidimensionalReport,
          Isolate.current.debugName,
          Isolate.current.controlPort,
        ]);
    }
  } on Object catch (error, stackTrace) {
    Isolate.exit(command.resultPort, <Object?>[
      _workerFailure,
      error.toString(),
      stackTrace.toString(),
    ]);
  }
}

Future<List<MapData>> _loadValidationMaps(NarrativeValidatorWork work) async {
  final session = await NarrativeEventAuthoringSession.prepare(
    p.join(work.projectRootPath, 'project.json'),
  );
  final maps = session.maps.toList(growable: true);
  final activeMap = work.activeMap;
  if (activeMap != null) {
    final index = maps.indexWhere((map) => map.id == activeMap.id);
    if (index < 0) {
      maps.add(activeMap);
    } else {
      maps[index] = activeMap;
    }
  }
  return maps;
}
