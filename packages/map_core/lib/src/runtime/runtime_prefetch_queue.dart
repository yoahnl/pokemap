import 'dart:async';

final class RuntimePrefetchQueue {
  RuntimePrefetchQueue({this.maximumQueued = 2}) {
    if (maximumQueued < 0) throw ArgumentError.value(maximumQueued);
  }

  final int maximumQueued;
  final _pending = <_RuntimePrefetchJob>[];
  var _generation = 0;
  var _running = false;
  var _disposed = false;

  Future<void>? schedule(Future<void> Function(bool Function()) run) {
    if (_disposed || (_running && _pending.length >= maximumQueued)) {
      return null;
    }
    final job = _RuntimePrefetchJob(_generation, run);
    _pending.add(job);
    _drain();
    return job.completer.future;
  }

  void invalidate() {
    _generation++;
    for (final job in _pending) {
      job.completer.complete();
    }
    _pending.clear();
  }

  void dispose() {
    _disposed = true;
    invalidate();
  }

  void _drain() {
    if (_running || _pending.isEmpty || _disposed) return;
    _running = true;
    final job = _pending.removeAt(0);
    unawaited(() async {
      try {
        if (job.generation == _generation) {
          await job.run(() => !_disposed && job.generation == _generation);
        }
        job.completer.complete();
      } on Object catch (error, stack) {
        job.completer.completeError(error, stack);
      } finally {
        _running = false;
        _drain();
      }
    }());
  }
}

final class _RuntimePrefetchJob {
  _RuntimePrefetchJob(this.generation, this.run);
  final int generation;
  final Future<void> Function(bool Function()) run;
  final completer = Completer<void>();
}
