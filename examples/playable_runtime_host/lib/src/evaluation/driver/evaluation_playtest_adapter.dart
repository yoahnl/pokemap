import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import '../../project_tree_digest.dart';
import '../runner/evaluation_command_dispatcher.dart';
import 'evaluation_driver.dart';

typedef EvaluationPlaytestDriverFactory = Future<EvaluationDriver> Function({
  required String runId,
  required int seed,
});
typedef EvaluationSurfaceCapture = Future<List<int>> Function();

/// PokeMap Eval adapter for one Authoring API playtest session.
///
/// The production project is read-only. Saves remain inside the evaluator's
/// in-memory repository, while transient captures live in a dedicated sandbox
/// that is recursively removed by [dispose].
final class EvaluationPlaytestDriver implements RuntimePlaytestDriver {
  EvaluationPlaytestDriver._({
    required this.request,
    required this.projectRoot,
    required this.sandboxRoot,
    required this.driver,
    required this.captureSurface,
  });

  static Future<EvaluationPlaytestDriver> start({
    required PlaytestStartRequest request,
    required Directory projectRoot,
    required EvaluationPlaytestDriverFactory driverFactory,
    EvaluationSurfaceCapture? captureSurface,
    void Function(Directory sandbox)? onSandboxCreated,
  }) async {
    final actualRevision = await computeEvaluationProjectRevision(projectRoot);
    if (actualRevision != request.projectRevision) {
      throw StateError(
        'Evaluation project revision mismatch: expected '
        '${request.projectRevision}, got $actualRevision.',
      );
    }

    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap_playtest_${_safeSegment(request.sessionId)}_',
    );
    onSandboxCreated?.call(sandbox);
    EvaluationDriver? evaluationDriver;
    try {
      evaluationDriver = await driverFactory(
        runId: request.sessionId,
        seed: request.seed,
      );
      if (request.checkpointId case final checkpointId?) {
        await evaluationDriver.probeLoadCheckpoint(checkpointId);
      }
      return EvaluationPlaytestDriver._(
        request: request,
        projectRoot: projectRoot,
        sandboxRoot: sandbox,
        driver: evaluationDriver,
        captureSurface: captureSurface,
      );
    } catch (_) {
      if (evaluationDriver != null) await evaluationDriver.dispose();
      if (await sandbox.exists()) await sandbox.delete(recursive: true);
      rethrow;
    }
  }

  final PlaytestStartRequest request;
  final Directory projectRoot;
  final Directory sandboxRoot;
  final EvaluationDriver driver;
  final EvaluationSurfaceCapture? captureSurface;
  var _disposed = false;

  @override
  Future<String> readProjectRevision() {
    return computeEvaluationProjectRevision(projectRoot);
  }

  @override
  Map<String, Object?> snapshot() => driver.snapshot().toJson();

  @override
  Future<void> execute(PlaytestCommand command) {
    _ensureOpen();
    return const EvaluationCommandDispatcher().execute(
      driver: driver,
      commandId: command.commandId,
      operation: command.operation,
      arguments: command.arguments,
      evidenceCapture: ({required stepId, name}) async {
        await captureScreenshot(name ?? stepId);
      },
    );
  }

  @override
  Future<AuthoringArtifactRef> captureScreenshot(String name) async {
    _ensureOpen();
    final capture = captureSurface;
    if (capture == null) {
      throw StateError('Visible evaluation surface capture is unavailable.');
    }
    final bytes = await capture();
    if (bytes.isEmpty || bytes.any((byte) => byte < 0 || byte > 255)) {
      throw StateError('Evaluation surface returned invalid image bytes.');
    }
    final digest = sha256.convert(bytes).toString();
    final artifactId = 'screenshot-${_safeSegment(name)}';
    // The temporary file is intentionally not exposed through the public URI.
    // PMCP-071 installs the durable artifact job boundary; this lot only needs
    // content identity and deterministic cleanup.
    final file = File(p.join(sandboxRoot.path, '$artifactId.png'));
    await file.writeAsBytes(bytes, flush: true);
    return AuthoringArtifactRef(
      id: artifactId,
      mediaType: 'image/png',
      uri: 'artifact://sha256/$digest',
      byteLength: bytes.length,
      sha256: digest,
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await driver.dispose();
    } finally {
      if (await sandboxRoot.exists()) {
        await sandboxRoot.delete(recursive: true);
      }
    }
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('Evaluation playtest driver is disposed.');
  }
}

Future<String> computeEvaluationProjectRevision(Directory projectRoot) async {
  final digest = await const ProjectTreeDigest().compute(projectRoot);
  return 'sha256:$digest';
}

String _safeSegment(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9._-]+'),
        '-',
      );
  final bounded =
      normalized.length <= 64 ? normalized : normalized.substring(0, 64);
  return bounded.isEmpty ? 'capture' : bounded;
}
