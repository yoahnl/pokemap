import 'frame_rate.dart';

class AveluneFramePacer {
  AveluneFramePacer({int limit = AveluneFrameRate.defaultLimit})
    : _limit = AveluneFrameRate.validate(limit);

  int _limit;
  int? _lastFrameUs;
  double? _nextDeadlineUs;

  int get limit => _limit;
  double get _periodUs => Duration.microsecondsPerSecond / _limit;

  void setLimit(int limit) {
    AveluneFrameRate.validate(limit);
    if (limit == _limit) return;
    _limit = limit;
    final lastFrameUs = _lastFrameUs;
    _nextDeadlineUs = lastFrameUs == null ? null : lastFrameUs + _periodUs;
  }

  static const _deadlineToleranceUs = 1000.0;

  Duration delay(Duration now) {
    final deadline = _nextDeadlineUs;
    if (deadline == null) return Duration.zero;
    final remaining = deadline - now.inMicroseconds;
    return remaining <= _deadlineToleranceUs
        ? Duration.zero
        : Duration(microseconds: remaining.round());
  }

  void frameStarted(Duration now) {
    final elapsedUs = now.inMicroseconds;
    _lastFrameUs = elapsedUs;
    final deadline = _nextDeadlineUs;
    if (deadline == null) {
      _nextDeadlineUs = elapsedUs + _periodUs;
    } else if (deadline <= elapsedUs + _deadlineToleranceUs) {
      final missed =
          ((elapsedUs - deadline + _deadlineToleranceUs) / _periodUs).floor();
      _nextDeadlineUs = deadline + (missed + 1) * _periodUs;
    }
  }

  void reset() {
    _lastFrameUs = null;
    _nextDeadlineUs = null;
  }
}
