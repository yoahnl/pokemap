import 'package:map_core/map_core_domain.dart';

class CinematicPreviewMediaSession {
  CinematicPreviewMediaSession(CinematicMediaPlaybackPort port, this.onError)
    : _controller = CinematicMediaPreviewController(port: port);

  final CinematicMediaPreviewController _controller;
  final void Function(Object) onError;
  Future<void> _pending = Future.value();
  int _generation = 0, _requestedTime = 0;
  bool _closed = false, _advanceQueued = false;
  Future<void> get settled => _pending;

  void start(CinematicPreviewPlaybackPlan plan, int timeMs) {
    if (_closed) return;
    final ticket = ++_generation;
    _queue(() async {
      if (_closed || ticket != _generation) return;
      await _controller.prepare(plan);
      if (_closed || ticket != _generation) {
        await _controller.cancel();
        return;
      }
      if (timeMs > 0) {
        await _controller.seek(timeMs);
      } else {
        await _controller.advanceTo(0);
      }
    });
  }

  void advance(int timeMs) {
    if (_closed) return;
    _requestedTime = timeMs;
    if (_advanceQueued) return;
    _advanceQueued = true;
    final ticket = _generation;
    _queue(() async {
      try {
        while (!_closed && ticket == _generation && _controller.isPrepared) {
          final time = _requestedTime;
          await _controller.advanceTo(time);
          if (time == _requestedTime) break;
        }
      } finally {
        _advanceQueued = false;
      }
    });
  }

  void cancel() {
    _generation++;
    _queue(_controller.cancel);
  }

  void _queue(Future<void> Function() operation) {
    _pending = _pending.then((_) => operation()).catchError((
      Object error,
    ) async {
      try {
        await _controller.cancel();
      } catch (_) {}
      if (!_closed) onError(error);
    });
  }

  void dispose() {
    _closed = true;
    cancel();
  }
}
