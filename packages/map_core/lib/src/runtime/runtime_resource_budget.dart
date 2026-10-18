import 'dart:async';

int runtimeImageRgbaByteLength(
  int width,
  int height, {
  required int maximumBytes,
}) {
  if (width <= 0 ||
      height <= 0 ||
      maximumBytes < 4 ||
      width > maximumBytes ~/ 4 ||
      height > (maximumBytes ~/ 4) ~/ width) {
    throw const RuntimeResourceAdmissionException('image_dimensions');
  }
  return width * height * 4;
}

final class RuntimeResourceProfile {
  const RuntimeResourceProfile({
    this.maximumResidentBytes = 64 * 1024 * 1024,
    this.maximumTransientBytes = 64 * 1024 * 1024,
    this.maximumConcurrentDecodes = 2,
    this.maximumEncodedBytes = 32 * 1024 * 1024,
  });
  final int maximumResidentBytes;
  final int maximumTransientBytes;
  final int maximumConcurrentDecodes;
  final int maximumEncodedBytes;
}

final class RuntimeResourceAdmissionException implements Exception {
  const RuntimeResourceAdmissionException(this.reason);
  final String reason;
  @override
  String toString() => 'Runtime resource admission failed: $reason';
}

final class RuntimeResourceBudget {
  RuntimeResourceBudget({this.profile = const RuntimeResourceProfile()}) {
    if (profile.maximumResidentBytes <= 0 ||
        profile.maximumTransientBytes <= 0 ||
        profile.maximumConcurrentDecodes <= 0 ||
        profile.maximumEncodedBytes <= 0) {
      throw ArgumentError('Runtime resource limits must be positive.');
    }
  }
  final RuntimeResourceProfile profile;
  final _pending = <_RuntimeResourceRequest>[];
  final _reservations = <RuntimeResourceReservation>{};
  var _residentBytes = 0;
  var _transientBytes = 0;
  var _activeDecodes = 0;
  var _peakBytes = 0;
  var _peakConcurrentDecodes = 0;
  var _disposed = false;
  int get residentBytes => _residentBytes;
  int get transientBytes => _transientBytes;
  int get activeDecodes => _activeDecodes;
  int get pendingDecodes => _pending.length;
  int get peakBytes => _peakBytes;
  int get peakConcurrentDecodes => _peakConcurrentDecodes;
  bool get isDisposed => _disposed;

  Future<RuntimeResourceReservation> acquire({
    int residentBytes = 0,
    int transientBytes = 0,
    bool prefetch = false,
    bool Function()? isCurrent,
  }) {
    final request = _RuntimeResourceRequest(
      residentBytes,
      transientBytes,
      prefetch,
      isCurrent,
    );
    if (_disposed) {
      request.completer.completeError(
        const RuntimeResourceAdmissionException('session_closed'),
      );
    } else {
      _pending.add(request);
      _drain();
    }
    return request.completer.future;
  }

  void _drain() {
    if (_disposed) return;
    _pending.removeWhere((request) {
      if (request.isCurrent?.call() ?? true) return false;
      request.completer.completeError(
        const RuntimeResourceAdmissionException('cancelled'),
      );
      return true;
    });
    while (_activeDecodes < profile.maximumConcurrentDecodes &&
        _pending.isNotEmpty) {
      var index = _pending.indexWhere((request) => !request.prefetch);
      if (index < 0) index = 0;
      final request = _pending.removeAt(index);
      try {
        _check(request.residentBytes, request.transientBytes);
        final lease = RuntimeResourceReservation._(
          this,
          request.residentBytes,
          request.transientBytes,
          request.isCurrent,
        );
        _reservations.add(lease);
        _residentBytes += request.residentBytes;
        _transientBytes += request.transientBytes;
        _activeDecodes++;
        _recordPeak();
        request.completer.complete(lease);
      } catch (error, stack) {
        if (error is RuntimeResourceAdmissionException &&
            error.reason == 'transient_bytes' &&
            request.transientBytes <= profile.maximumTransientBytes &&
            _activeDecodes > 0) {
          _pending.insert(index, request);
          return;
        }
        request.completer.completeError(error, stack);
      }
    }
  }

  void _check(int resident, int transient) {
    if (resident < 0 || transient < 0) {
      throw ArgumentError('Negative resource reservation.');
    }
    if (resident > profile.maximumResidentBytes - _residentBytes) {
      throw const RuntimeResourceAdmissionException('resident_bytes');
    }
    if (transient > profile.maximumTransientBytes - _transientBytes) {
      throw const RuntimeResourceAdmissionException('transient_bytes');
    }
  }

  void _recordPeak() {
    final total = _residentBytes > 0x7fffffffffffffff - _transientBytes
        ? 0x7fffffffffffffff
        : _residentBytes + _transientBytes;
    if (total > _peakBytes) _peakBytes = total;
    if (_activeDecodes > _peakConcurrentDecodes) {
      _peakConcurrentDecodes = _activeDecodes;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final request in _pending) {
      request.completer.completeError(
        const RuntimeResourceAdmissionException('session_closed'),
      );
    }
    _pending.clear();
    for (final reservation in _reservations.toList()) {
      reservation.release();
    }
  }
}

final class RuntimeResourceReservation {
  RuntimeResourceReservation._(
    this._budget,
    this._resident,
    this._transient,
    this._isCurrent,
  );
  final RuntimeResourceBudget _budget;
  final bool Function()? _isCurrent;
  int _resident, _transient;
  bool _released = false;
  bool _committed = false;
  RuntimeResourceProfile get profile => _budget.profile;

  void ensureCurrent() {
    if (_released || _budget._disposed || !(_isCurrent?.call() ?? true)) {
      throw const RuntimeResourceAdmissionException('cancelled_or_closed');
    }
  }

  void resize({required int residentBytes, required int transientBytes}) {
    ensureCurrent();
    if (_committed) throw StateError('A committed resource cannot be resized.');
    _budget._residentBytes -= _resident;
    _budget._transientBytes -= _transient;
    try {
      _budget._check(residentBytes, transientBytes);
    } catch (_) {
      _budget._residentBytes += _resident;
      _budget._transientBytes += _transient;
      rethrow;
    }
    _resident = residentBytes;
    _transient = transientBytes;
    _budget._residentBytes += _resident;
    _budget._transientBytes += _transient;
    _budget._recordPeak();
  }

  void commit() {
    ensureCurrent();
    if (_committed) return;
    _committed = true;
    _budget._transientBytes -= _transient;
    _transient = 0;
    _budget._activeDecodes--;
    _budget._drain();
  }

  void release() {
    if (_released) return;
    _released = true;
    _budget._residentBytes -= _resident;
    _budget._transientBytes -= _transient;
    if (!_committed) _budget._activeDecodes--;
    _resident = 0;
    _transient = 0;
    _budget._reservations.remove(this);
    _budget._drain();
  }
}

final class _RuntimeResourceRequest {
  _RuntimeResourceRequest(
    this.residentBytes,
    this.transientBytes,
    this.prefetch,
    this.isCurrent,
  );
  final int residentBytes, transientBytes;
  final bool prefetch;
  final bool Function()? isCurrent;
  final completer = Completer<RuntimeResourceReservation>();
}
