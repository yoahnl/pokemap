enum PresentationPlaybackStatus {
  loading,
  ready,
  playing,
  paused,
  interactionHold,
  completed,
  error,
  disposed,
}

enum PresentationMediaClockPolicy { paused, synchronized, continueAmbient }

final class PresentationPlaybackClock {
  PresentationPlaybackClock({
    required int durationUs,
    int initialPlayheadUs = 0,
    int frameStepUs = 33_333,
    bool loop = false,
    PresentationPlaybackStatus initialStatus = PresentationPlaybackStatus.ready,
  }) : _durationUs = _nonnegative(durationUs, 'durationUs'),
       _playheadUs = _nonnegative(initialPlayheadUs, 'initialPlayheadUs'),
       _frameStepUs = _positive(frameStepUs, 'frameStepUs'),
       _loop = loop,
       _status = initialStatus {
    if (initialStatus == PresentationPlaybackStatus.disposed) {
      throw ArgumentError.value(
        initialStatus,
        'initialStatus',
        'cannot start disposed',
      );
    }
    _playheadUs = _playheadUs.clamp(0, _durationUs);
  }

  int _durationUs;
  int _playheadUs;
  final int _frameStepUs;
  bool _loop;
  PresentationPlaybackStatus _status;
  int _token = 0;

  int get durationUs => _durationUs;
  int get playheadUs => _playheadUs;
  int get frameStepUs => _frameStepUs;
  bool get loop => _loop;
  PresentationPlaybackStatus get status => _status;
  int get token => _token;

  bool get narrativeClockRunning =>
      _status == PresentationPlaybackStatus.playing;

  PresentationMediaClockPolicy get mediaClockPolicy => switch (_status) {
    PresentationPlaybackStatus.playing =>
      PresentationMediaClockPolicy.synchronized,
    PresentationPlaybackStatus.interactionHold =>
      PresentationMediaClockPolicy.continueAmbient,
    _ => PresentationMediaClockPolicy.paused,
  };

  int? play() {
    if (!_acceptsTransportCommands || _durationUs == 0) return null;
    if (_status == PresentationPlaybackStatus.playing) return _token;
    if (_status == PresentationPlaybackStatus.completed ||
        _playheadUs >= _durationUs) {
      _playheadUs = 0;
    }
    _status = PresentationPlaybackStatus.playing;
    return _invalidateCallbacks();
  }

  int? resume() {
    if (_status != PresentationPlaybackStatus.paused &&
        _status != PresentationPlaybackStatus.interactionHold) {
      return _status == PresentationPlaybackStatus.playing ? _token : null;
    }
    if (_durationUs == 0) return null;
    if (_playheadUs >= _durationUs) _playheadUs = 0;
    _status = PresentationPlaybackStatus.playing;
    return _invalidateCallbacks();
  }

  void pause() {
    if (_status != PresentationPlaybackStatus.playing &&
        _status != PresentationPlaybackStatus.interactionHold) {
      return;
    }
    _status = PresentationPlaybackStatus.paused;
    _invalidateCallbacks();
  }

  void holdForInteraction() {
    if (_status != PresentationPlaybackStatus.playing) return;
    _status = PresentationPlaybackStatus.interactionHold;
    _invalidateCallbacks();
  }

  void stop() {
    if (_status == PresentationPlaybackStatus.disposed) return;
    _playheadUs = 0;
    if (_status != PresentationPlaybackStatus.loading &&
        _status != PresentationPlaybackStatus.error) {
      _status = PresentationPlaybackStatus.ready;
    }
    _invalidateCallbacks();
  }

  bool advanceBy(int deltaUs, {required int token}) {
    if (deltaUs < 0) {
      throw ArgumentError.value(deltaUs, 'deltaUs', 'must be nonnegative');
    }
    if (token != _token ||
        _status != PresentationPlaybackStatus.playing ||
        deltaUs == 0 ||
        _durationUs == 0) {
      return false;
    }
    final next = _playheadUs + deltaUs;
    if (next < _durationUs) {
      _playheadUs = next;
      return true;
    }
    if (_loop) {
      _playheadUs = next % _durationUs;
      return true;
    }
    _playheadUs = _durationUs;
    _status = PresentationPlaybackStatus.completed;
    _invalidateCallbacks();
    return true;
  }

  void seekTo(int timeUs) {
    if (!_acceptsTransportCommands) return;
    final resolved = _nonnegative(timeUs, 'timeUs').clamp(0, _durationUs);
    _playheadUs = resolved;
    if (_status == PresentationPlaybackStatus.completed &&
        resolved < _durationUs) {
      _status = PresentationPlaybackStatus.paused;
    }
  }

  void stepForward() => _stepBy(_frameStepUs);

  void stepBackward() => _stepBy(-_frameStepUs);

  void setLoop(bool value) {
    if (_status == PresentationPlaybackStatus.disposed) return;
    _loop = value;
  }

  void configureDuration(int value) {
    if (_status == PresentationPlaybackStatus.disposed) return;
    _durationUs = _nonnegative(value, 'value');
    _playheadUs = _playheadUs.clamp(0, _durationUs);
    if (_status != PresentationPlaybackStatus.loading &&
        _status != PresentationPlaybackStatus.error &&
        _playheadUs >= _durationUs &&
        _durationUs > 0) {
      _status = PresentationPlaybackStatus.completed;
      _invalidateCallbacks();
    }
  }

  void setLoading() {
    if (_status == PresentationPlaybackStatus.disposed) return;
    _status = PresentationPlaybackStatus.loading;
    _invalidateCallbacks();
  }

  void setError() {
    if (_status == PresentationPlaybackStatus.disposed) return;
    _status = PresentationPlaybackStatus.error;
    _invalidateCallbacks();
  }

  void setReady() {
    if (_status == PresentationPlaybackStatus.disposed) return;
    _status = _playheadUs >= _durationUs && _durationUs > 0
        ? PresentationPlaybackStatus.completed
        : PresentationPlaybackStatus.ready;
    _invalidateCallbacks();
  }

  void dispose() {
    if (_status == PresentationPlaybackStatus.disposed) return;
    _status = PresentationPlaybackStatus.disposed;
    _invalidateCallbacks();
  }

  bool get _acceptsTransportCommands =>
      _status != PresentationPlaybackStatus.loading &&
      _status != PresentationPlaybackStatus.error &&
      _status != PresentationPlaybackStatus.disposed;

  void _stepBy(int deltaUs) {
    if (!_acceptsTransportCommands) return;
    _playheadUs = (_playheadUs + deltaUs).clamp(0, _durationUs);
    _status = PresentationPlaybackStatus.paused;
    _invalidateCallbacks();
  }

  int _invalidateCallbacks() => ++_token;
}

int _nonnegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, 'must be nonnegative');
  }
  return value;
}

int _positive(int value, String name) {
  if (value <= 0) {
    throw ArgumentError.value(value, name, 'must be positive');
  }
  return value;
}
