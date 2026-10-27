import 'dart:async';

const int runtimeTilesetChunkHeight = 4096;

({int residentBytes, int transientBytes}) runtimeTilesetImageAllocation({
  required int encodedLength,
  required int width,
  required int height,
  bool transformRgba = false,
  int sourceBitDepth = 8,
  RuntimeResourceProfile profile = const RuntimeResourceProfile(),
}) {
  if (encodedLength <= 0 || encodedLength > profile.maximumEncodedBytes) {
    throw const RuntimeResourceAdmissionException('encoded_bytes');
  }
  final chunked = height > runtimeTilesetChunkHeight;
  final encodedCopyCount = chunked ? 6 : 2;
  if (encodedLength > profile.maximumTransientBytes ~/ encodedCopyCount) {
    throw const RuntimeResourceAdmissionException('image_dimensions');
  }
  final encodedCopies = encodedLength * encodedCopyCount;
  final chunkScratch = chunked
      ? runtimeImageRgbaByteLength(
          width,
          runtimeTilesetChunkHeight,
          maximumBytes: profile.maximumTransientBytes,
        )
      : 0;
  final fullImageScratchCopies = chunked
      ? (sourceBitDepth > 8 ? 4 : 2)
      : (transformRgba ? 4 : 2);
  if (chunked && height > profile.maximumTransientBytes ~/ 7) {
    throw const RuntimeResourceAdmissionException('image_dimensions');
  }
  final scanlineScratch = chunked ? height * 7 : 0;
  final availablePixels =
      (profile.maximumTransientBytes -
          encodedCopies -
          chunkScratch -
          scanlineScratch) ~/
      fullImageScratchCopies;
  final pixels = runtimeImageRgbaByteLength(
    width,
    height,
    maximumBytes: profile.maximumResidentBytes < availablePixels
        ? profile.maximumResidentBytes
        : availablePixels,
  );
  return (
    residentBytes: pixels,
    transientBytes:
        encodedCopies +
        pixels * fullImageScratchCopies +
        chunkScratch +
        scanlineScratch,
  );
}

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
  final _optionalReservations = <RuntimeResourceReservation>{};
  var _draining = false;
  var _checking = 0;
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
    if (_disposed || _draining || _checking > 0) return;
    _draining = true;
    try {
      _drainPending();
    } finally {
      _draining = false;
    }
  }

  void _drainPending() {
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
        if (!(request.isCurrent?.call() ?? true)) {
          throw const RuntimeResourceAdmissionException('cancelled');
        }
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

  void _check(
    int resident,
    int transient, {
    RuntimeResourceReservation? replacing,
  }) {
    if (resident < 0 || transient < 0) {
      throw ArgumentError('Negative resource reservation.');
    }
    if (resident > profile.maximumResidentBytes) {
      throw const RuntimeResourceAdmissionException('resident_bytes');
    }
    if (transient > profile.maximumTransientBytes) {
      throw const RuntimeResourceAdmissionException('transient_bytes');
    }
    int availableResident() =>
        profile.maximumResidentBytes -
        (_residentBytes - (replacing?._resident ?? 0));
    if (resident > availableResident()) {
      _checking++;
      try {
        for (final lease in _optionalReservations.toList()) {
          if (resident <= availableResident()) break;
          lease._evict();
        }
      } finally {
        _checking--;
      }
    }
    if (_disposed) {
      throw const RuntimeResourceAdmissionException('session_closed');
    }
    if (resident > availableResident()) {
      throw const RuntimeResourceAdmissionException('resident_bytes');
    }
    if (transient >
        profile.maximumTransientBytes -
            (_transientBytes - (replacing?._transient ?? 0))) {
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
  void Function()? _onEvicted;
  int get residentBytes => _resident;

  void retainOptionally(void Function() onEvicted) {
    if (_released || _budget._disposed) {
      throw const RuntimeResourceAdmissionException('cancelled_or_closed');
    }
    if (!_committed) {
      throw StateError('Only committed resources may be optional.');
    }
    _onEvicted = onEvicted;
    _budget._optionalReservations.add(this);
  }

  void retainRequired() {
    _onEvicted = null;
    _budget._optionalReservations.remove(this);
  }

  void _evict() {
    final callback = _onEvicted;
    if (callback == null) return;
    retainRequired();
    try {
      callback();
    } catch (_) {
      return;
    }
    release();
  }

  RuntimeResourceProfile get profile => _budget.profile;

  void ensureCurrent() {
    if (_released || _budget._disposed || !(_isCurrent?.call() ?? true)) {
      throw const RuntimeResourceAdmissionException('cancelled_or_closed');
    }
  }

  void resize({required int residentBytes, required int transientBytes}) {
    ensureCurrent();
    if (_committed) throw StateError('A committed resource cannot be resized.');
    if (_budget._checking > 0) {
      throw StateError('Resources cannot be resized during optional eviction.');
    }
    try {
      _budget._check(residentBytes, transientBytes, replacing: this);
      ensureCurrent();
    } catch (_) {
      _budget._drain();
      rethrow;
    }
    _budget._residentBytes += residentBytes - _resident;
    _budget._transientBytes += transientBytes - _transient;
    _resident = residentBytes;
    _transient = transientBytes;
    _budget._recordPeak();
    _budget._drain();
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
    retainRequired();
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
