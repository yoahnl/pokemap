import 'dart:async';

import 'package:flutter/services.dart';

enum AveluneFeedbackCue { selection, align, latch, launch, details, error }

abstract interface class AveluneFeedback {
  void emit(AveluneFeedbackCue cue);
}

final class AveluneNoopFeedback implements AveluneFeedback {
  const AveluneNoopFeedback();

  @override
  void emit(AveluneFeedbackCue cue) {}
}

final class AveluneSystemFeedback implements AveluneFeedback {
  const AveluneSystemFeedback({
    required this.hapticsEnabled,
    required this.clickSoundEnabled,
  });

  final bool Function() hapticsEnabled;
  final bool Function() clickSoundEnabled;

  @override
  void emit(AveluneFeedbackCue cue) {
    if (hapticsEnabled()) {
      _ignore(
        switch (cue) {
          AveluneFeedbackCue.selection => HapticFeedback.selectionClick(),
          AveluneFeedbackCue.align => HapticFeedback.lightImpact(),
          AveluneFeedbackCue.latch ||
          AveluneFeedbackCue.details =>
            HapticFeedback.mediumImpact(),
          AveluneFeedbackCue.launch ||
          AveluneFeedbackCue.error =>
            HapticFeedback.heavyImpact(),
        },
      );
    }
    if (!clickSoundEnabled()) return;
    if (cue == AveluneFeedbackCue.latch) {
      _ignore(SystemSound.play(SystemSoundType.click));
    } else if (cue == AveluneFeedbackCue.error) {
      _ignore(SystemSound.play(SystemSoundType.alert));
    }
  }

  static void _ignore(Future<void> operation) {
    unawaited(operation.catchError((Object _) {}));
  }
}
