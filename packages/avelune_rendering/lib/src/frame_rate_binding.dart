import 'package:flutter/widgets.dart';

import 'frame_pacer.dart';
import 'frame_rate.dart';

mixin AveluneFrameRateBinding on WidgetsBinding {
  AveluneFramePacer? _framePacer;
  Duration? _vsyncEpoch;
  Duration? _lastVsync;
  bool _skipDraw = false;
  bool _awaitingFrame = false;
  bool _forceFrame = false;

  @override
  void initInstances() {
    super.initInstances();
    _framePacer = AveluneFramePacer(limit: AveluneFrameRate.limit);
    AveluneFrameRate.changes.addListener(_frameRateChanged);
  }

  void _frameRateChanged() {
    _framePacer?.setLimit(AveluneFrameRate.limit);
  }

  @override
  void scheduleForcedFrame() {
    _forceFrame = true;
    super.scheduleForcedFrame();
  }

  @override
  void handleBeginFrame(Duration? rawTimeStamp) {
    if (rawTimeStamp != null) {
      final previous = _lastVsync;
      if (previous != null && rawTimeStamp < previous) {
        resetEpoch();
        _framePacer?.reset();
        _vsyncEpoch = rawTimeStamp;
      }
      _lastVsync = rawTimeStamp;
    }
    final pacingTime = rawTimeStamp == null ? null : _pacingTime(rawTimeStamp);
    final forced = _forceFrame;
    _forceFrame = false;
    if (rawTimeStamp != null &&
        framesEnabled &&
        !forced &&
        (_framePacer?.delay(pacingTime!) ?? Duration.zero) > Duration.zero) {
      _skipDraw = true;
      _awaitingFrame = true;
      return;
    }
    _skipDraw = false;
    _awaitingFrame = false;
    if (rawTimeStamp != null && framesEnabled) {
      _framePacer?.frameStarted(pacingTime!);
    }
    super.handleBeginFrame(rawTimeStamp);
  }

  @override
  void handleDrawFrame() {
    if (!_skipDraw) {
      super.handleDrawFrame();
      return;
    }
    _skipDraw = false;
    platformDispatcher.scheduleFrame();
  }

  @override
  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    final previouslyEnabled = framesEnabled;
    super.handleAppLifecycleStateChanged(state);
    if (!framesEnabled) {
      _framePacer?.reset();
      _lastVsync = null;
      _vsyncEpoch = null;
    } else if (!previouslyEnabled && _awaitingFrame && hasScheduledFrame) {
      platformDispatcher.scheduleFrame();
    }
  }

  Duration _pacingTime(Duration timestamp) =>
      timestamp - (_vsyncEpoch ??= timestamp);
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
