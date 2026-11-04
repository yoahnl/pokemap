import 'dart:async';

final class WorkshopReferencePlayback {
  WorkshopReferencePlayback({
    required Future<void> Function(String? url, int requestId) display,
    this.timeout = const Duration(seconds: 5),
  }) : _display = display;

  final Future<void> Function(String? url, int requestId) _display;
  final Duration timeout;
  Completer<bool>? _pending;
  int _version = 0;
  bool _closed = false;

  bool isCurrent(int requestId) => !_closed && requestId == _version;

  Future<bool> show(String? url) {
    if (_closed) return Future.value(false);
    final previous = _pending;
    if (previous != null && !previous.isCompleted) previous.complete(false);
    _pending = null;
    final requestId = ++_version;
    if (url == null) {
      _send(null, requestId);
      return Future.value(false);
    }
    final pending = Completer<bool>();
    _pending = pending;
    _send(url, requestId);
    return pending.future.timeout(timeout, onTimeout: () {
      if (isCurrent(requestId)) {
        _send(null, ++_version);
      }
      return false;
    }).whenComplete(() {
      if (identical(_pending, pending)) _pending = null;
    });
  }

  void report(int requestId, {required bool loaded}) {
    final pending = _pending;
    if (isCurrent(requestId) && pending != null && !pending.isCompleted) {
      pending.complete(loaded);
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _version++;
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(false);
  }

  void _send(String? url, int requestId) {
    unawaited(Future<void>.sync(() => _display(url, requestId)).then(
      (_) {},
      onError: (Object _, StackTrace __) => report(requestId, loaded: false),
    ));
  }
}
