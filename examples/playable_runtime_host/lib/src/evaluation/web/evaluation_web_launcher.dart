import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../contracts/evaluation_event.dart';
import '../contracts/evaluation_policy.dart';
import '../contracts/evaluation_receipt.dart';
import '../contracts/evaluation_scenario.dart';
import '../runner/evaluation_run_control.dart';
import '../scenario/evaluation_scenario_parser.dart';
import '../worker/evaluation_worker_protocol.dart';
import 'evaluation_run_store.dart';
import 'evaluation_web_server.dart';
import 'evaluation_worker_pool.dart';

abstract interface class EvaluationProcessRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    required bool runInShell,
  });
}

final class IoEvaluationProcessRunner implements EvaluationProcessRunner {
  const IoEvaluationProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    required bool runInShell,
  }) {
    return Process.run(
      executable,
      arguments,
      runInShell: runInShell,
    );
  }
}

final class EvaluationWebLauncher {
  EvaluationWebLauncher({
    EvaluationProcessRunner? processRunner,
    String? operatingSystem,
  })  : _processRunner = processRunner ?? const IoEvaluationProcessRunner(),
        _operatingSystem = operatingSystem ?? Platform.operatingSystem;

  final EvaluationProcessRunner _processRunner;
  final String _operatingSystem;

  Future<bool> open(Uri uri) async {
    final executable = switch (_operatingSystem) {
      'macos' => 'open',
      'linux' => 'xdg-open',
      _ => null,
    };
    if (executable == null) return false;
    final result = await _processRunner.run(
      executable,
      <String>[uri.toString()],
      runInShell: false,
    );
    return result.exitCode == 0;
  }
}

Directory evaluationWebAssetsForScript(Uri script) {
  if (script.scheme != 'file') {
    throw ArgumentError.value(
      script,
      'script',
      'The evaluation command must be loaded from a local file.',
    );
  }
  return Directory(
    p.join(
      p.dirname(script.toFilePath()),
      'assets',
      'pokemap_eval_web',
    ),
  ).absolute;
}

final class EvaluationWebApplication {
  EvaluationWebApplication._(this.server);

  final EvaluationWebServer server;

  Uri get uri => server.uri;

  static Future<EvaluationWebApplication> start({
    required Directory repositoryRoot,
    required Directory assetsRoot,
    required int port,
    String? projectId,
    EvaluationWorkerFactory? workerFactory,
    String Function()? runIdFactory,
    DateTime Function()? clock,
    void Function(String chunk)? stderrSink,
  }) async {
    final root = repositoryRoot.absolute;
    final orchestrator = LocalEvaluationWebOrchestrator(
      repositoryRoot: root,
      selectedProjectId: projectId,
      workerPool: EvaluationWorkerPool(
        factory: workerFactory ??
            PersistentEvaluationWorkerFactory(
              hostRoot: root,
              stderrSink: stderrSink,
            ),
      ),
      runStore: EvaluationRunStore(
        historyRoot: Directory(p.join(root.path, 'build', 'pokemap-eval')),
      ),
      runIdFactory: runIdFactory,
      clock: clock,
    );
    try {
      final server = await EvaluationWebServer.start(
        port: port,
        assetsRoot: assetsRoot,
        orchestrator: orchestrator,
      );
      return EvaluationWebApplication._(server);
    } on Object {
      await orchestrator.close();
      rethrow;
    }
  }

  Future<void> close() => server.close();
}

final class LocalEvaluationWebOrchestrator extends EvaluationWebOrchestrator {
  LocalEvaluationWebOrchestrator({
    required Directory repositoryRoot,
    required this.workerPool,
    required this.runStore,
    this.selectedProjectId,
    String Function()? runIdFactory,
    DateTime Function()? clock,
  })  : repositoryRoot = repositoryRoot.absolute,
        _runIdFactory = runIdFactory ?? _defaultRunId,
        _clock = clock ?? DateTime.now;

  final Directory repositoryRoot;
  final EvaluationWorkerPool workerPool;
  final EvaluationRunStore runStore;
  final String? selectedProjectId;
  final String Function() _runIdFactory;
  final DateTime Function() _clock;
  final Map<String, String> _projectByRunId = <String, String>{};
  final Map<String, File> _artifactFiles = <String, File>{};
  bool _closed = false;

  @override
  Future<List<EvaluationWebProjectDescriptor>> listProjects() async {
    final entries = await _discoverScenarios();
    final projectIds = entries.map((entry) => entry.scenario.projectId).toSet();
    final descriptors = projectIds
        .map(
          (id) => EvaluationWebProjectDescriptor(
            id: id,
            label: _readableProjectLabel(id),
          ),
        )
        .toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return descriptors;
  }

  @override
  Future<List<EvaluationWebScenarioDescriptor>> listScenarios({
    String? projectId,
  }) async {
    final filter = projectId ?? selectedProjectId;
    final entries = await _discoverScenarios();
    return entries
        .where(
          (entry) => filter == null || entry.scenario.projectId == filter,
        )
        .map(_descriptorFor)
        .toList(growable: false);
  }

  @override
  Future<List<EvaluationRunRecord>> listActiveRuns() async {
    final historyIds =
        (await runStore.loadHistory()).map((record) => record.runId).toSet();
    return runStore.activeRuns
        .where((record) => !historyIds.contains(record.runId))
        .toList(growable: false);
  }

  @override
  Future<List<EvaluationRunHistoryRecord>> loadHistory() {
    return runStore.loadHistory();
  }

  @override
  Future<EvaluationRunRecord> startRun({
    required EvaluationWebScenarioDescriptor scenario,
    required EvaluationTarget target,
  }) async {
    if (_closed) throw StateError('Evaluation web orchestrator is closed.');
    if (target != EvaluationTarget.headless) {
      throw StateError('Only headless evaluation is available in V1.');
    }
    final matches = (await _discoverScenarios())
        .where((entry) => entry.scenario.id == scenario.id)
        .where((entry) => entry.scenario.projectId == scenario.projectId)
        .toList(growable: false);
    if (matches.length != 1) {
      throw StateError(
        matches.isEmpty
            ? 'Unknown evaluation scenario ${scenario.id}.'
            : 'Evaluation scenario ${scenario.id} is duplicated.',
      );
    }

    final entry = matches.single;
    final runId = _runIdFactory();
    final record = runStore.create(
      EvaluationRunDescriptor(
        runId: runId,
        projectId: entry.scenario.projectId,
        scenarioId: entry.scenario.id,
        policy: entry.scenario.policy,
        target: target,
        createdAt: _clock(),
      ),
    );
    _projectByRunId[runId] = entry.scenario.projectId;
    unawaited(_execute(entry, runId));
    return record;
  }

  @override
  Future<EvaluationWebArtifact?> readArtifact(String artifactId) async {
    final file = _artifactFiles[artifactId];
    if (file == null || !await file.exists()) return null;
    return EvaluationWebArtifact(
      id: artifactId,
      contentType: ContentType.json,
      bytes: await file.readAsBytes(),
    );
  }

  @override
  EvaluationRunRecord? activeRun(String runId) {
    try {
      return runStore.requireRun(runId);
    } on StateError {
      return null;
    }
  }

  @override
  Stream<EvaluationEvent>? eventsFor(String runId) {
    if (!_projectByRunId.containsKey(runId)) return null;
    return runStore.eventsFor(runId);
  }

  @override
  Future<EvaluationControlState> controlRun(
    String runId,
    EvaluationWorkerControlAction action,
  ) async {
    final projectId = _projectByRunId[runId];
    if (projectId == null) {
      throw StateError('Unknown evaluation run $runId.');
    }
    if (runStore.requireRun(runId).events.lastOrNull?.type == 'run.finished') {
      throw StateError('Evaluation run $runId has already finished.');
    }
    await workerPool.control(
      projectId: projectId,
      runId: runId,
      action: action,
    );
    return switch (action) {
      EvaluationWorkerControlAction.pause => EvaluationControlState.paused,
      EvaluationWorkerControlAction.step => EvaluationControlState.paused,
      EvaluationWorkerControlAction.resume => EvaluationControlState.running,
      EvaluationWorkerControlAction.cancel => EvaluationControlState.cancelled,
    };
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await workerPool.close();
    await runStore.close();
  }

  Future<void> _execute(_DiscoveredWebScenario entry, String runId) async {
    try {
      final outputDirectory = p.posix.join(
        'build',
        'pokemap-eval',
        'runs',
        runId,
      );
      final result = await workerPool.run(
        projectId: entry.scenario.projectId,
        request: EvaluationWorkerRequest.run(
          runId: runId,
          projectRoot: entry.scenario.projectId,
          scenarioPath: _portableRelativePath(entry.file),
          outputDirectory: outputDirectory,
        ),
        eventSink: runStore.append,
        releaseEvidenceCandidate:
            entry.scenario.policy == EvaluationPolicy.certify,
      );
      if (result.receiptPath case final receiptPath?) {
        final receipt = File(p.join(repositoryRoot.path, receiptPath));
        if (_isWithinRepository(receipt)) {
          _artifactFiles['$runId-receipt'] = receipt;
        }
      }
      _appendTerminalIfMissing(
        runId,
        status: result.status,
        message: result.message,
      );
    } on Object catch (error) {
      _appendTerminalIfMissing(
        runId,
        status: EvaluationRunStatus.infrastructureFailure,
        message: '$error',
      );
    }
  }

  void _appendTerminalIfMissing(
    String runId, {
    required EvaluationRunStatus status,
    String? message,
  }) {
    var run = runStore.requireRun(runId);
    if (run.events.lastOrNull?.type == 'run.finished') return;
    if (status == EvaluationRunStatus.infrastructureFailure) {
      runStore.append(
        EvaluationEvent(
          runId: runId,
          sequence: run.lastSequence + 1,
          type: 'worker.failed',
          payload: <String, Object?>{
            'message': message ?? 'Evaluation worker failed.',
          },
        ),
      );
      run = runStore.requireRun(runId);
    }
    runStore.append(
      EvaluationEvent(
        runId: runId,
        sequence: run.lastSequence + 1,
        type: 'run.finished',
        payload: <String, Object?>{
          'status': status.name,
          'evidenceLevel': EvaluationEvidenceLevel.diagnosticOnly.name,
          if (message != null) 'error': message,
        },
      ),
    );
  }

  Future<List<_DiscoveredWebScenario>> _discoverScenarios() async {
    final root = Directory(
      p.join(
        repositoryRoot.path,
        'examples',
        'playable_runtime_host',
        'evaluation',
        'scenarios',
      ),
    );
    if (!await root.exists()) return const <_DiscoveredWebScenario>[];
    final entries = <_DiscoveredWebScenario>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File || p.extension(entity.path) != '.json') continue;
      final scenario = const EvaluationScenarioParser().parseString(
        await entity.readAsString(),
      );
      if (selectedProjectId == null ||
          scenario.projectId == selectedProjectId) {
        entries.add(_DiscoveredWebScenario(entity, scenario));
      }
    }
    entries.sort(
      (left, right) => left.scenario.id.compareTo(right.scenario.id),
    );
    return entries;
  }

  EvaluationWebScenarioDescriptor _descriptorFor(
    _DiscoveredWebScenario entry,
  ) {
    return EvaluationWebScenarioDescriptor(
      id: entry.scenario.id,
      title: entry.scenario.title,
      projectId: entry.scenario.projectId,
      policy: entry.scenario.policy,
      stepCount: entry.scenario.steps.length,
      criterionIds: entry.scenario.criteria
          .map((criterion) => criterion.id)
          .toList(growable: false),
    );
  }

  String _portableRelativePath(File file) {
    return p
        .relative(file.absolute.path, from: repositoryRoot.path)
        .replaceAll(r'\', '/');
  }

  bool _isWithinRepository(File file) {
    final relative = p.relative(file.absolute.path, from: repositoryRoot.path);
    return relative != '..' &&
        !relative.startsWith('..${p.separator}') &&
        !p.isAbsolute(relative);
  }
}

final class _DiscoveredWebScenario {
  const _DiscoveredWebScenario(this.file, this.scenario);

  final File file;
  final EvaluationScenario scenario;
}

String _readableProjectLabel(String id) {
  if (id.isEmpty) return id;
  return '${id[0].toUpperCase()}${id.substring(1)}';
}

String _defaultRunId() {
  return 'run-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
