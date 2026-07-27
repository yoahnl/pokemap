enum RuntimeIntroPhase { idle, playing, paused, poster, completed }

enum RuntimeIntroReducedMotionBehavior { poster, skip }

/// Pure state machine for an optional intro video.
///
/// Every failure and accessibility branch terminates on either a static poster
/// with an explicit continue action or the title screen.
final class RuntimeIntroSequenceController {
  RuntimeIntroPhase _phase = RuntimeIntroPhase.idle;
  bool _hasVideo = false;
  bool _hasPoster = false;
  bool _allowReplay = false;
  String? _failureReason;

  RuntimeIntroPhase get phase => _phase;
  String? get failureReason => _failureReason;
  bool get canReplay => _allowReplay && _hasVideo;

  void start({
    required bool hasVideo,
    required bool hasPoster,
    required bool reducedMotion,
    required RuntimeIntroReducedMotionBehavior reducedMotionBehavior,
    required bool allowReplay,
  }) {
    _hasVideo = hasVideo;
    _hasPoster = hasPoster;
    _allowReplay = allowReplay;
    _failureReason = null;

    if (!hasVideo) {
      _phase = RuntimeIntroPhase.completed;
      return;
    }
    if (reducedMotion) {
      _phase =
          reducedMotionBehavior == RuntimeIntroReducedMotionBehavior.poster &&
                  hasPoster
              ? RuntimeIntroPhase.poster
              : RuntimeIntroPhase.completed;
      return;
    }
    _phase = RuntimeIntroPhase.playing;
  }

  void pauseForLifecycle() {
    if (_phase == RuntimeIntroPhase.playing) {
      _phase = RuntimeIntroPhase.paused;
    }
  }

  void resumeAfterLifecycle() {
    if (_phase == RuntimeIntroPhase.paused) {
      _phase = RuntimeIntroPhase.playing;
    }
  }

  void playbackCompleted() {
    if (_phase == RuntimeIntroPhase.playing ||
        _phase == RuntimeIntroPhase.paused) {
      _phase = RuntimeIntroPhase.completed;
    }
  }

  void playbackFailed(String reason) {
    _failureReason = reason;
    _phase =
        _hasPoster ? RuntimeIntroPhase.poster : RuntimeIntroPhase.completed;
  }

  void skip() => _phase = RuntimeIntroPhase.completed;

  void continueFromPoster() => _phase = RuntimeIntroPhase.completed;

  bool replay() {
    if (!canReplay) return false;
    _failureReason = null;
    _phase = RuntimeIntroPhase.playing;
    return true;
  }
}
