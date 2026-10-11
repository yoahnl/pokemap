import 'package:avelune_converter_core/avelune_converter_core.dart';

void main() {
  final namespace = ConverterId('probe-project');
  final hash = canonicalHashOf({
    'z': 1,
    'a': [true, null]
  });
  if (hash !=
      canonicalHashOf({
        'a': [true, null],
        'z': 1.0
      })) {
    throw StateError('Canonical public API is inconsistent');
  }
  final identity = SourceIdentity(namespace, ConverterId('map'), 1).stableId;
  final session = ConversionSession(
    sessionId: ConverterId('probe-session'),
    revision: 1,
    logicalProjectNamespace: namespace,
    sourceSnapshotHash: hash,
  );
  final queued = ConversionJob(
    jobId: ConverterId('probe-job'),
    session: session,
    progress: JobProgress(done: 0, total: 1, unit: JobUnit.maps),
  );
  final running = queued.applyUpdate(
    jobId: queued.jobId,
    sessionRevision: session.revision,
    state: JobState.running,
    progress: queued.progress,
  );
  final succeeded = running.applyUpdate(
    jobId: queued.jobId,
    sessionRevision: session.revision,
    state: JobState.succeeded,
    progress: JobProgress(done: 1, total: 1, unit: JobUnit.maps),
  );
  if (identity.value.length != 67 || succeeded.state != JobState.succeeded) {
    throw StateError('Identity or job public API is inconsistent');
  }
}
