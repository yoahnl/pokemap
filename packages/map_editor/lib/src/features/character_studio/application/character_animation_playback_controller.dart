import 'package:map_core/map_core.dart';

final class CharacterAnimationPlaybackController {
  CharacterAnimationPlaybackController({
    required List<CharacterAnimationFrame> frames,
    required this.loop,
  }) : _frames = List<CharacterAnimationFrame>.unmodifiable(frames);

  List<CharacterAnimationFrame> _frames;
  bool loop;
  bool _isPlaying = false;
  bool _completed = false;
  int _currentFrameIndex = 0;
  double _elapsedInFrameMs = 0;
  double _speed = 1;

  List<CharacterAnimationFrame> get frames => _frames;
  bool get isPlaying => _isPlaying;
  int get currentFrameIndex => _currentFrameIndex;

  double get speed => _speed;

  set speed(double value) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(value, 'speed', 'must be positive and finite');
    }
    _speed = value;
  }

  void play() {
    if (_completed) reset();
    if (_frames.isNotEmpty) _isPlaying = true;
  }

  void pause() => _isPlaying = false;

  void reset({bool pause = true}) {
    _currentFrameIndex = 0;
    _elapsedInFrameMs = 0;
    _completed = false;
    if (pause) _isPlaying = false;
  }

  void replaceFrames(List<CharacterAnimationFrame> frames) {
    _frames = List<CharacterAnimationFrame>.unmodifiable(frames);
    reset();
  }

  void stepNext() {
    if (_frames.isEmpty) return;
    _isPlaying = false;
    _completed = false;
    _elapsedInFrameMs = 0;
    _currentFrameIndex = (_currentFrameIndex + 1) % _frames.length;
  }

  void stepPrevious() {
    if (_frames.isEmpty) return;
    _isPlaying = false;
    _completed = false;
    _elapsedInFrameMs = 0;
    _currentFrameIndex =
        (_currentFrameIndex - 1 + _frames.length) % _frames.length;
  }

  void advance(Duration elapsed) {
    if (!_isPlaying || _frames.isEmpty || elapsed <= Duration.zero) return;
    var remainingMs = elapsed.inMicroseconds / 1000 * _speed;
    while (remainingMs > 0 && _isPlaying) {
      final durationMs = _frames[_currentFrameIndex].durationMs;
      if (durationMs <= 0) {
        _isPlaying = false;
        return;
      }
      final untilBoundary = durationMs - _elapsedInFrameMs;
      if (remainingMs < untilBoundary) {
        _elapsedInFrameMs += remainingMs;
        return;
      }
      remainingMs -= untilBoundary;
      _elapsedInFrameMs = 0;
      if (_currentFrameIndex < _frames.length - 1) {
        _currentFrameIndex++;
      } else if (loop) {
        _currentFrameIndex = 0;
      } else {
        _isPlaying = false;
        _completed = true;
      }
    }
  }
}
