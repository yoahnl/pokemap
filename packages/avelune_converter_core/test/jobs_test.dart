import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

ConversionSession session() => ConversionSession(
      sessionId: ConverterId('session-1'),
      revision: 1,
      logicalProjectNamespace: ConverterId('project-1'),
      sourceSnapshotHash: Sha256Hash('a' * 64),
    );
JobProgress progress(int done, {int? total = 2, JobUnit unit = JobUnit.maps}) =>
    JobProgress(done: done, total: total, unit: unit);
ConversionJob queued() => ConversionJob(
    jobId: ConverterId('job-1'), session: session(), progress: progress(0));
ConversionJob update(ConversionJob job, JobState state, int done) =>
    job.applyUpdate(
        jobId: job.jobId,
        sessionRevision: 1,
        state: state,
        progress: progress(done));

void main() {
  test('job snapshots transition immutably from queued to success', () {
    final q = queued();
    final running = update(q, JobState.running, 1);
    final done = update(running, JobState.succeeded, 2);
    expect(q.state, JobState.queued);
    expect(running.state, JobState.running);
    expect(done.state, JobState.succeeded);
    expect(done.progress.done, 2);
  });
  test('cancelled jobs reject late worker updates', () {
    final cancelled = update(queued(), JobState.cancelled, 0);
    expect(() => update(cancelled, JobState.running, 1), throwsFormatException);
  });
  test('terminal success cannot be reopened', () {
    final done =
        update(update(queued(), JobState.running, 1), JobState.succeeded, 2);
    expect(() => update(done, JobState.running, 2), throwsFormatException);
  });
  test('queued jobs cannot skip execution', () {
    expect(
        () => update(queued(), JobState.succeeded, 2), throwsFormatException);
  });
  test('old session revisions are rejected', () {
    final job = queued();
    expect(
        () => job.applyUpdate(
            jobId: job.jobId,
            sessionRevision: 0,
            state: JobState.running,
            progress: progress(1)),
        throwsFormatException);
  });
  test('another job ID is rejected', () {
    final job = queued();
    expect(
        () => job.applyUpdate(
            jobId: ConverterId('another'),
            sessionRevision: 1,
            state: JobState.running,
            progress: progress(1)),
        throwsFormatException);
  });
  test('progress cannot move backwards or change units', () {
    final job = update(queued(), JobState.running, 1);
    expect(() => update(job, JobState.running, 0), throwsFormatException);
    expect(
        () => job.applyUpdate(
            jobId: job.jobId,
            sessionRevision: 1,
            state: JobState.running,
            progress: progress(1, unit: JobUnit.files)),
        throwsFormatException);
  });
  test('known totals are stable across updates', () {
    final job = queued();
    expect(
        () => job.applyUpdate(
            jobId: job.jobId,
            sessionRevision: 1,
            state: JobState.running,
            progress: progress(1, total: 3)),
        throwsFormatException);
  });
  test('an unknown total can become known', () {
    final job = ConversionJob(
        jobId: ConverterId('job-1'),
        session: session(),
        progress: progress(0, total: null));
    expect(update(job, JobState.running, 1).progress.total, 2);
  });
  test('progress cannot exceed total', () {
    expect(() => progress(3), throwsFormatException);
    expect(() => progress(-1), throwsFormatException);
  });
  test('success requires completion of a known total', () {
    final job = update(queued(), JobState.running, 1);
    expect(() => update(job, JobState.succeeded, 1), throwsFormatException);
  });
  test('session revisions are positive', () {
    expect(
        () => ConversionSession(
            sessionId: ConverterId('s'),
            revision: 0,
            logicalProjectNamespace: ConverterId('p'),
            sourceSnapshotHash: Sha256Hash('a' * 64)),
        throwsFormatException);
  });
}
