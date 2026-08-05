import 'dart:async';

import 'package:flutter/foundation.dart';

import '../design_system/foundation/avelune_motion_tokens.dart';
import 'avelune_feedback.dart';
import 'avelune_interaction_state.dart';

final class AveluneInsertionController extends ChangeNotifier {
  AveluneInsertionController({
    required this.motion,
    required AveluneFeedback feedback,
    AveluneDelay delay = _defaultDelay,
  })  : _feedback = feedback,
        _delay = delay;

  final AveluneMotionTokens motion;
  final AveluneFeedback _feedback;
  final AveluneDelay _delay;

  AveluneInteractionState _state = AveluneInteractionState.idle;
  Future<bool>? _activeFuture;
  Object? _lastError;
  bool _disposed = false;
  int _generation = 0;

  AveluneInteractionState get state => _state;
  Object? get lastError => _lastError;
  bool get isInserting => switch (_state) {
        AveluneInteractionState.aligning ||
        AveluneInteractionState.descending ||
        AveluneInteractionState.latched ||
        AveluneInteractionState.launching =>
          true,
        _ => false,
      };

  Future<bool> insert({required FutureOr<void> Function() onLaunch}) {
    if (_disposed || _state == AveluneInteractionState.error) {
      return Future<bool>.value(false);
    }
    final activeFuture = _activeFuture;
    if (activeFuture != null) return activeFuture;

    _lastError = null;
    final generation = ++_generation;
    late final Future<bool> future;
    future = _run(onLaunch, generation).whenComplete(() {
      if (identical(_activeFuture, future)) _activeFuture = null;
    });
    _activeFuture = future;
    return future;
  }

  Future<bool> _run(
    FutureOr<void> Function() onLaunch,
    int generation,
  ) async {
    try {
      _transition(AveluneInteractionState.aligning);
      await _delay(motion.insertionAlign);
      if (!_isCurrent(generation)) return false;

      _transition(AveluneInteractionState.descending);
      await _delay(motion.insertionDescend);
      if (!_isCurrent(generation)) return false;

      _transition(AveluneInteractionState.latched);
      await _delay(motion.insertionLatch);
      if (!_isCurrent(generation)) return false;

      _transition(AveluneInteractionState.launching);
      await _delay(motion.insertionLaunchDelay);
      if (!_isCurrent(generation)) return false;

      await Future<void>.sync(onLaunch);
      if (!_isCurrent(generation)) return false;
      _transition(AveluneInteractionState.idle);
      return true;
    } catch (error, stackTrace) {
      if (_isCurrent(generation)) {
        _lastError = error;
        if (_state != AveluneInteractionState.error) {
          _transition(AveluneInteractionState.error);
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  bool cancel() {
    if (_disposed || _state == AveluneInteractionState.idle) return false;
    _generation++;
    _activeFuture = null;
    if (_state != AveluneInteractionState.recovering) {
      _transition(AveluneInteractionState.recovering);
    }
    _transition(AveluneInteractionState.idle);
    return true;
  }

  bool recover() {
    if (_disposed || _state != AveluneInteractionState.error) return false;
    _lastError = null;
    return cancel();
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _transition(AveluneInteractionState next) {
    AveluneInteractionTransitions.ensureAllowed(_state, next);
    _state = next;
    final cue = switch (next) {
      AveluneInteractionState.aligning => AveluneFeedbackCue.align,
      AveluneInteractionState.latched => AveluneFeedbackCue.latch,
      AveluneInteractionState.launching => AveluneFeedbackCue.launch,
      AveluneInteractionState.error => AveluneFeedbackCue.error,
      _ => null,
    };
    if (cue != null) _feedback.emit(cue);
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _activeFuture = null;
    super.dispose();
  }
}

Future<void> _defaultDelay(Duration duration) => Future<void>.delayed(duration);
