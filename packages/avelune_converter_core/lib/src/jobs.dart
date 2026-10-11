part of '../avelune_converter_core.dart';

enum JobState { queued, running, succeeded, failed, cancelled }

enum JobUnit { files, maps, assets, operations }

final class JobProgress {
  JobProgress({required this.done, required this.total, required this.unit}) {
    _require(
        done >= 0 &&
            done <= 2147483647 &&
            (total == null || (total! >= done && total! <= 2147483647)),
        'job.progress',
        r'$',
        'Invalid job progress');
  }
  final int done;
  final int? total;
  final JobUnit unit;
}

final class ConversionSession {
  ConversionSession({
    required this.sessionId,
    required this.revision,
    required this.logicalProjectNamespace,
    required this.sourceSnapshotHash,
  }) {
    _require(revision >= 1 && revision <= 2147483647, 'session.revision', r'$',
        'Session revisions must be positive');
  }
  final ConverterId sessionId;
  final int revision;
  final ConverterId logicalProjectNamespace;
  final Sha256Hash sourceSnapshotHash;
}

final class ConversionJob {
  ConversionJob(
      {required this.jobId, required this.session, required this.progress})
      : state = JobState.queued {
    _require(progress.done == 0, 'job.initialProgress', r'$',
        'Queued job cannot have completed work');
  }
  ConversionJob._(this.jobId, this.session, this.progress, this.state);
  final ConverterId jobId;
  final ConversionSession session;
  final JobProgress progress;
  final JobState state;

  ConversionJob applyUpdate({
    required ConverterId jobId,
    required int sessionRevision,
    required JobState state,
    required JobProgress progress,
  }) {
    _require(
        jobId == this.jobId && sessionRevision == session.revision,
        'job.staleUpdate',
        r'$',
        'Update belongs to another job or session revision');
    final permitted = switch (this.state) {
      JobState.queued =>
        state == JobState.running || state == JobState.cancelled,
      JobState.running => state != JobState.queued,
      JobState.succeeded || JobState.failed || JobState.cancelled => false,
    };
    _require(permitted, 'job.transition', r'$',
        'Invalid or terminal job transition');
    _require(
        progress.unit == this.progress.unit &&
            progress.done >= this.progress.done &&
            (this.progress.total == null ||
                progress.total == this.progress.total),
        'job.progressUpdate',
        r'$',
        'Progress unit, completed work or total changed inconsistently');
    _require(
        state != JobState.succeeded ||
            progress.total == null ||
            progress.done == progress.total,
        'job.incomplete',
        r'$',
        'Success requires completion of known total');
    return ConversionJob._(this.jobId, session, progress, state);
  }
}
