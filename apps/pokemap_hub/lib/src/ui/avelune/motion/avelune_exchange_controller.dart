import 'package:flutter/foundation.dart';

import '../design_system/foundation/avelune_motion_tokens.dart';
import 'avelune_feedback.dart';
import 'avelune_interaction_state.dart';

enum AveluneExchangeStage { idle, departing, settling }

final class AveluneExchangeController extends ChangeNotifier {
  AveluneExchangeController({
    required String initialGameId,
    required this.motion,
    required AveluneFeedback feedback,
    AveluneDelay delay = _defaultDelay,
    bool Function() isSelectionBlocked = _selectionNeverBlocked,
  })  : _currentGameId = initialGameId,
        _feedback = feedback,
        _delay = delay,
        _isSelectionBlocked = isSelectionBlocked,
        assert(initialGameId.isNotEmpty, 'An initial game id is required.');

  final AveluneMotionTokens motion;
  final AveluneFeedback _feedback;
  final AveluneDelay _delay;
  final bool Function() _isSelectionBlocked;

  AveluneInteractionState _state = AveluneInteractionState.idle;
  AveluneExchangeStage _stage = AveluneExchangeStage.idle;
  String _currentGameId;
  String? _sourceGameId;
  String? _targetGameId;
  _ExchangeRequest? _queued;
  Future<void>? _activeFuture;
  Object? _lastError;
  bool _disposed = false;
  int _generation = 0;

  AveluneInteractionState get state => _state;
  AveluneExchangeStage get stage => _stage;
  String get currentGameId => _currentGameId;
  String? get sourceGameId => _sourceGameId;
  String? get targetGameId => _targetGameId;
  String? get queuedGameId => _queued?.gameId;
  Object? get lastError => _lastError;
  bool get isExchanging => _state == AveluneInteractionState.exchanging;

  Future<void> select(
    String gameId, {
    required ValueChanged<String> onCommitted,
  }) {
    assert(gameId.isNotEmpty, 'A game id is required.');
    if (_disposed ||
        _state == AveluneInteractionState.error ||
        _isSelectionBlocked() ||
        gameId == _currentGameId && _activeFuture == null) {
      return Future<void>.value();
    }

    final request = _ExchangeRequest(gameId, onCommitted);
    final activeFuture = _activeFuture;
    if (activeFuture != null) {
      _queued = request;
      if (_stage == AveluneExchangeStage.departing) {
        _targetGameId = gameId;
        if (!_disposed) notifyListeners();
      }
      return activeFuture;
    }

    final generation = ++_generation;
    _lastError = null;
    late final Future<void> future;
    future = _run(request, generation).whenComplete(() {
      if (identical(_activeFuture, future)) _activeFuture = null;
    });
    _activeFuture = future;
    return future;
  }

  Future<void> _run(_ExchangeRequest initial, int generation) async {
    var request = initial;
    try {
      while (_isCurrent(generation)) {
        if (request.gameId != _currentGameId) {
          _sourceGameId = _currentGameId;
          _targetGameId = request.gameId;
          _stage = AveluneExchangeStage.departing;
          _transition(AveluneInteractionState.exchanging);
          await _delay(_half(motion.exchange));
          if (!_isCurrent(generation)) return;

          final latestBeforeMidpoint = _queued;
          if (latestBeforeMidpoint != null) {
            request = latestBeforeMidpoint;
            _queued = null;
            _targetGameId = request.gameId;
          }

          if (request.gameId != _currentGameId) {
            _currentGameId = request.gameId;
            request.onCommitted(request.gameId);
            _feedback.emit(AveluneFeedbackCue.selection);
          }
          if (!_isCurrent(generation)) return;
          _stage = AveluneExchangeStage.settling;
          if (!_disposed) notifyListeners();

          await _delay(_remainingHalf(motion.exchange));
          if (!_isCurrent(generation)) return;
          _transition(AveluneInteractionState.idle);
          _stage = AveluneExchangeStage.idle;
          _sourceGameId = null;
          _targetGameId = null;
          if (!_disposed) notifyListeners();
        }

        final queued = _queued;
        _queued = null;
        if (queued == null) return;
        request = queued;
      }
    } catch (error) {
      if (_isCurrent(generation) && _state != AveluneInteractionState.error) {
        _lastError = error;
        _queued = null;
        _transition(AveluneInteractionState.error);
      }
      rethrow;
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  bool recover() {
    if (_disposed || _state != AveluneInteractionState.error) return false;
    _lastError = null;
    _transition(AveluneInteractionState.recovering);
    _transition(AveluneInteractionState.idle);
    return true;
  }

  void _transition(AveluneInteractionState next) {
    AveluneInteractionTransitions.ensureAllowed(_state, next);
    _state = next;
    if (next == AveluneInteractionState.error) {
      _feedback.emit(AveluneFeedbackCue.error);
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _queued = null;
    _activeFuture = null;
    _stage = AveluneExchangeStage.idle;
    _sourceGameId = null;
    _targetGameId = null;
    super.dispose();
  }
}

final class _ExchangeRequest {
  const _ExchangeRequest(this.gameId, this.onCommitted);

  final String gameId;
  final ValueChanged<String> onCommitted;
}

Future<void> _defaultDelay(Duration duration) => Future<void>.delayed(duration);

bool _selectionNeverBlocked() => false;

Duration _half(Duration duration) => Duration(
      microseconds: duration.inMicroseconds ~/ 2,
    );

Duration _remainingHalf(Duration duration) => Duration(
      microseconds: duration.inMicroseconds - _half(duration).inMicroseconds,
    );
