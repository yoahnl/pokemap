import 'dart:async';

import 'package:map_distribution/map_distribution.dart';

import 'battle_animation_plan.dart';
import 'battle_sfx_player.dart';
import 'battle_verified_recipe_sound_loader.dart';

enum BattleRecipeAudioStatus { ready, fallback, cancelled }

enum BattleRecipeAudioFailure {
  invalidSelection,
  preparationTimeout,
  unavailable,
}

sealed class BattleRecipeAudioSelection {
  const BattleRecipeAudioSelection();
}

final class BattleMoveClipAudio extends BattleRecipeAudioSelection {
  const BattleMoveClipAudio(this.resourceId);

  final String resourceId;
}

final class BattleSeqAudioEvent {
  const BattleSeqAudioEvent(this.sourceId, this.resourceId, this.offset);

  final String sourceId;
  final String resourceId;
  final Duration offset;
}

final class BattleSeqAudio extends BattleRecipeAudioSelection {
  BattleSeqAudio(List<BattleSeqAudioEvent> events)
    : events = List.unmodifiable(events);

  final List<BattleSeqAudioEvent> events;
}

final class BattleRecipeAudioResult {
  const BattleRecipeAudioResult._(this.status, this.program, {this.failure});

  final BattleRecipeAudioStatus status;
  final BattlePreparedRecipeAudio? program;
  final BattleRecipeAudioFailure? failure;

  List<BattleAnimationStep> stepsOrFallback(
    List<BattleAnimationStep> fallback,
  ) => switch (status) {
    BattleRecipeAudioStatus.ready => program!.steps,
    BattleRecipeAudioStatus.fallback => List.unmodifiable(fallback),
    BattleRecipeAudioStatus.cancelled => const [],
  };
}

final class BattlePreparedRecipeAudio {
  BattlePreparedRecipeAudio._(
    List<_PreparedAudioCue> cues,
    List<String> sourceSeqIds,
    this._startTimeout,
    this._cancel,
  ) : _cues = {for (final cue in cues) cue.token: cue},
      sourceSeqIds = List.unmodifiable(sourceSeqIds),
      steps = List.unmodifiable(_buildSteps(cues));

  final Map<String, _PreparedAudioCue> _cues;
  final Duration _startTimeout;
  final Future<void> Function() _cancel;
  final Completer<Object> _playbackFailure = Completer<Object>();
  bool _disabled = false;

  final List<BattleAnimationStep> steps;
  final List<String> sourceSeqIds;
  Future<Object> get playbackFailure => _playbackFailure.future;

  static List<BattleAnimationStep> _buildSteps(List<_PreparedAudioCue> cues) {
    final steps = <BattleAnimationStep>[];
    var previous = Duration.zero;
    for (final cue in cues) {
      final wait = cue.offset - previous;
      if (wait > Duration.zero) {
        steps.add(WaitStep(durationSeconds: wait.inMicroseconds / 1000000));
      }
      steps.add(PlaySeStep(seName: cue.token));
      previous = cue.offset;
    }
    return steps;
  }

  bool dispatch(PlaySeStep step) {
    final cue = _cues[step.seName];
    if (cue == null) return false;
    if (!_disabled && !cue.started) {
      cue.started = true;
      unawaited(_startCue(cue));
    }
    return true;
  }

  BattleSfxPlayer route(BattleSfxPlayer fallback) =>
      (String name, {required int volume, required int pitch}) {
        if (!dispatch(PlaySeStep(seName: name, volume: volume, pitch: pitch))) {
          fallback(name, volume: volume, pitch: pitch);
        }
      };

  Future<void> _startCue(_PreparedAudioCue cue) async {
    try {
      await cue.sound.start().timeout(_startTimeout);
    } on Object catch (error) {
      if (_disabled || cue.sound.completedNaturally) return;
      _disabled = true;
      if (!_playbackFailure.isCompleted) _playbackFailure.complete(error);
      unawaited(_cancel().then<void>((_) {}, onError: (Object _) {}));
    }
  }
}

final class _PreparedAudioCue {
  _PreparedAudioCue(this.token, this.offset, this.sound);

  final String token;
  final Duration offset;
  final BattlePreparedRecipeSound sound;
  bool started = false;
}

final class BattleRecipeAudioCoordinator {
  BattleRecipeAudioCoordinator({
    required this.player,
    required this.bundle,
    required this.preparationTimeout,
    required this.startTimeout,
  });

  final FlameAudioBattleSfxPlayer player;
  final InspectedBattleRecipeBundle bundle;
  final Duration preparationTimeout;
  final Duration startTimeout;
  static int _nextToken = 0;
  final List<BattleRecipeSoundPreparation> _pending = [];
  final Completer<void> _cancelSignal = Completer<void>();
  Future<void>? _cancelling;
  BattlePreparedRecipeAudio? _program;
  bool _requested = false;
  bool _cancelled = false;

  Future<BattleRecipeAudioResult> prepare(
    BattleRecipeAudioSelection audio,
  ) async {
    if (_requested) throw StateError('Audio preparation already requested');
    _requested = true;
    if (_cancelled) {
      return const BattleRecipeAudioResult._(
        BattleRecipeAudioStatus.cancelled,
        null,
      );
    }
    final cuesToPrepare = switch (audio) {
      BattleMoveClipAudio(:final resourceId) => [
        (resourceId: resourceId, offset: Duration.zero),
      ],
      BattleSeqAudio(:final events) => [
        for (final event in events)
          (resourceId: event.resourceId, offset: event.offset),
      ],
    };
    if (preparationTimeout <= Duration.zero ||
        preparationTimeout > const Duration(seconds: 30) ||
        startTimeout <= Duration.zero ||
        startTimeout > const Duration(seconds: 30) ||
        cuesToPrepare.isEmpty ||
        cuesToPrepare.length > 8 ||
        (audio is BattleSeqAudio &&
            audio.events.any(
              (event) => event.sourceId.isEmpty || event.sourceId.length > 160,
            ))) {
      return const BattleRecipeAudioResult._(
        BattleRecipeAudioStatus.fallback,
        null,
        failure: BattleRecipeAudioFailure.invalidSelection,
      );
    }
    var previous = Duration.zero;
    for (final cue in cuesToPrepare) {
      if (cue.resourceId.isEmpty ||
          cue.offset < previous ||
          cue.offset > const Duration(seconds: 30)) {
        return const BattleRecipeAudioResult._(
          BattleRecipeAudioStatus.fallback,
          null,
          failure: BattleRecipeAudioFailure.invalidSelection,
        );
      }
      previous = cue.offset;
    }
    final clock = Stopwatch()..start();
    final token = _nextToken++;
    final cues = <_PreparedAudioCue>[];
    try {
      for (var i = 0; i < cuesToPrepare.length; i++) {
        if (clock.elapsed >= preparationTimeout) {
          throw TimeoutException('Audio preparation timed out');
        }
        final pending = player.beginVerifiedRecipeSound(
          bundle,
          cuesToPrepare[i].resourceId,
        );
        _pending.add(pending);
        final remaining = preparationTimeout - clock.elapsed;
        if (remaining <= Duration.zero) {
          throw TimeoutException('Audio preparation timed out');
        }
        final sound = await Future.any<BattlePreparedRecipeSound>([
          pending.ready,
          _cancelSignal.future.then(
            (_) => throw StateError('Audio preparation cancelled'),
          ),
        ]).timeout(remaining);
        if (_cancelled) throw StateError('Audio preparation cancelled');
        cues.add(
          _PreparedAudioCue(
            'avelune-recipe-audio-$token-$i',
            cuesToPrepare[i].offset,
            sound,
          ),
        );
      }
      final program = BattlePreparedRecipeAudio._(
        cues,
        audio is BattleSeqAudio
            ? audio.events.map((event) => event.sourceId).toList()
            : const [],
        startTimeout,
        cancel,
      );
      _program = program;
      return BattleRecipeAudioResult._(BattleRecipeAudioStatus.ready, program);
    } on Object catch (error) {
      final status = _cancelled
          ? BattleRecipeAudioStatus.cancelled
          : BattleRecipeAudioStatus.fallback;
      unawaited(cancel().then<void>((_) {}, onError: (Object _) {}));
      return BattleRecipeAudioResult._(
        status,
        null,
        failure: status == BattleRecipeAudioStatus.cancelled
            ? null
            : error is TimeoutException
            ? BattleRecipeAudioFailure.preparationTimeout
            : BattleRecipeAudioFailure.unavailable,
      );
    }
  }

  Future<void> cancel() {
    final existing = _cancelling;
    if (existing != null) return existing;
    _cancelled = true;
    _program?._disabled = true;
    _cancelSignal.complete();
    return _cancelling = Future.wait(_pending.map((entry) => entry.cancel()))
        .then<void>((_) {});
  }
}
