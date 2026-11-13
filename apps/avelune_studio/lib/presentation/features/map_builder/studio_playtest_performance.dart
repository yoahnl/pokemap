import 'dart:collection';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class StudioPlaytestPerformanceSample {
  const StudioPlaytestPerformanceSample({
    required this.fps,
    required this.buildMs,
    required this.rasterMs,
  });

  final double fps;
  final double buildMs;
  final double rasterMs;
}

class StudioPlaytestPerformanceMonitor extends ChangeNotifier {
  StudioPlaytestPerformanceMonitor({bool active = true}) : _active = active {
    SchedulerBinding.instance.addTimingsCallback(_observe);
  }

  final _frames = Queue<FrameTiming>();
  int? _lastPublication;
  StudioPlaytestPerformanceSample? _sample;
  bool _active;
  bool _disposed = false;

  StudioPlaytestPerformanceSample? get sample => _sample;

  void setActive(bool active) {
    if (_disposed || _active == active) return;
    _active = active;
    _frames.clear();
    _lastPublication = null;
    _sample = null;
    notifyListeners();
  }

  void _observe(List<FrameTiming> timings) {
    if (_disposed || !_active) return;
    for (final timing in timings) {
      final timestamp = timing.timestampInMicroseconds(FramePhase.rasterFinish);
      if (_frames.isNotEmpty &&
          timestamp <=
              _frames.last.timestampInMicroseconds(FramePhase.rasterFinish)) {
        continue;
      }
      _frames.add(timing);
      while (_frames.length > 2 &&
          _frames.first.timestampInMicroseconds(FramePhase.rasterFinish) <
              timestamp - 2000000) {
        _frames.removeFirst();
      }
    }
    if (_frames.length < 2) return;
    final last = _frames.last.timestampInMicroseconds(FramePhase.rasterFinish);
    if (_lastPublication != null && last - _lastPublication! < 500000) return;
    _lastPublication = last;
    final first = _frames.first.timestampInMicroseconds(
      FramePhase.rasterFinish,
    );
    final fps = (_frames.length - 1) * 1000000 / (last - first);
    final build =
        _frames.fold<int>(
          0,
          (total, frame) => total + frame.buildDuration.inMicroseconds,
        ) /
        _frames.length /
        1000;
    final raster =
        _frames.fold<int>(
          0,
          (total, frame) => total + frame.rasterDuration.inMicroseconds,
        ) /
        _frames.length /
        1000;
    _sample = StudioPlaytestPerformanceSample(
      fps: fps,
      buildMs: build,
      rasterMs: raster,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    SchedulerBinding.instance.removeTimingsCallback(_observe);
    super.dispose();
  }
}
