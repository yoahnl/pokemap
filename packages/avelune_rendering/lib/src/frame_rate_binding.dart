import 'dart:async';

import 'package:flutter/widgets.dart';

import 'frame_pacer.dart';
import 'frame_rate.dart';

mixin AveluneFrameRateBinding on WidgetsBinding {
  final _framePacingStopwatch = Stopwatch()..start();
  AveluneFramePacer? _framePacer;
  Timer? _pendingFrameTimer;

  @protected
  Duration get framePacingElapsed => _framePacingStopwatch.elapsed;

  @override
  void initInstances() {
    super.initInstances();
    _framePacer = AveluneFramePacer(limit: AveluneFrameRate.limit);
    AveluneFrameRate.changes.addListener(_frameRateChanged);
  }

  void _frameRateChanged() {
    _framePacer?.setLimit(AveluneFrameRate.limit);
    if (_pendingFrameTimer == null) return;
    _pendingFrameTimer!.cancel();
    _pendingFrameTimer = null;
    scheduleFrame();
  }

  @override
  void scheduleFrame() {
    if (hasScheduledFrame || !framesEnabled || _pendingFrameTimer != null) {
      return;
    }
    final wait = _framePacer?.delay(framePacingElapsed) ?? Duration.zero;
    if (wait == Duration.zero) {
      super.scheduleFrame();
    } else {
      _pendingFrameTimer = Timer(wait, () {
        _pendingFrameTimer = null;
        scheduleFrame();
      });
    }
  }

  @override
  void handleBeginFrame(Duration? rawTimeStamp) {
    _pendingFrameTimer?.cancel();
    _pendingFrameTimer = null;
    if (rawTimeStamp != null) _framePacer?.frameStarted(framePacingElapsed);
    super.handleBeginFrame(rawTimeStamp);
  }

  @override
  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pendingFrameTimer?.cancel();
      _pendingFrameTimer = null;
      _framePacer?.reset();
    }
    super.handleAppLifecycleStateChanged(state);
  }
}

class AveluneWidgetsFlutterBinding extends WidgetsFlutterBinding
    with AveluneFrameRateBinding {
  static WidgetsBinding ensureInitialized() {
    WidgetsBinding? binding;
    try {
      binding = WidgetsBinding.instance;
    } on FlutterError {
      binding = null;
    } on TypeError {
      binding = null;
    }
    return binding ?? AveluneWidgetsFlutterBinding();
  }
}
