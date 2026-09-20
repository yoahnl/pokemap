import 'dart:async';
import 'package:map_core/map_core_domain.dart';
import 'cinematic_preview_media_session.dart';

class CinematicPreviewTransport {
  final Set<void Function()> _listeners = {};
  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);
  void notifyListeners() {
    if (_disposed) return;
    for (final listener in _listeners.toList()) {
      if (_listeners.contains(listener)) listener();
    }
  }

  CinematicPreviewPlaybackPlan? plan;
  CinematicPreviewPlaybackFrame? frame;
  Timer? _timer;
  final _clock = Stopwatch();
  CinematicPreviewMediaSession? _media;
  Future<void> _retiredMedia = Future.value();
  String? mediaError;
  bool _disposed = false;
  bool previewActive = false;
  Future<void> get mediaSettled async {
    await _retiredMedia;
    await _media?.settled;
  }

  void configureMedia(CinematicMediaPlaybackPort port) {
    if (_disposed) return;
    final previous = _media;
    previous?.dispose();
    if (previous != null) {
      _retiredMedia = Future.wait([
        _retiredMedia,
        previous.settled,
      ]).then((_) {});
    }
    _media = CinematicPreviewMediaSession(port, (error) {
      if (_disposed) return;
      mediaError = 'Lecture des médias interrompue : $error';
      pause();
    });
    mediaError = null;
  }

  int timeMs = 0, frameEvaluations = 0, _origin = 0;
  bool get playing => _timer != null;
  int get durationMs => plan?.totalDurationMs ?? 0;
  void install(CinematicPreviewPlaybackPlan value) {
    if (_disposed) return;
    pause();
    plan = value;
    stop();
  }

  void clear() {
    pause();
    plan = null;
    frame = null;
    timeMs = 0;
    previewActive = false;
    notifyListeners();
  }

  void seek(int value) {
    if (_disposed) return;
    if (playing) pause();
    _media?.cancel();
    final bounded = value.clamp(0, durationMs);
    previewActive = plan != null;
    timeMs = bounded;
    frame = plan?.frameAt(bounded);
    if (plan != null) frameEvaluations++;
    if (playing) {
      _origin = bounded;
      _clock.reset();
    }
    notifyListeners();
  }

  void play() {
    if (_disposed || playing || plan == null || durationMs <= 0) return;
    if (timeMs >= durationMs) seek(0);
    mediaError = null;
    previewActive = true;
    _media?.start(plan!, timeMs);
    _origin = timeMs;
    _clock
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final next = _origin + _clock.elapsedMilliseconds;
      advance(next - timeMs);
    });
    notifyListeners();
  }

  void advance(int milliseconds) {
    if (_disposed || milliseconds < 0 || plan == null) return;
    final next = (timeMs + milliseconds).clamp(0, durationMs);
    timeMs = next;
    frame = plan!.frameAt(next);
    frameEvaluations++;
    if (playing) _media?.advance(next);
    if (next >= durationMs && playing) {
      stop();
      return;
    }
    notifyListeners();
  }

  void pause() {
    _media?.cancel();
    _timer?.cancel();
    _timer = null;
    _clock.stop();
    notifyListeners();
  }

  void stop() {
    pause();
    seek(0);
    previewActive = false;
    notifyListeners();
  }

  void dispose() {
    _disposed = true;
    _media?.dispose();
    _timer?.cancel();
    _clock.stop();
    _timer = null;
    _listeners.clear();
  }
}
