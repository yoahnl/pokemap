import '../read_models/cinematic_preview_playback_plan.dart';
import '../models/cinematic_asset.dart';
import 'cinematic_media_playback_contract.dart';

abstract interface class CinematicPreviewClock {
  int get nowMs;
  void seekTo(int timeMs);
}

final class MutableCinematicPreviewClock implements CinematicPreviewClock {
  MutableCinematicPreviewClock([this._nowMs = 0]);

  int _nowMs;

  @override
  int get nowMs => _nowMs;

  @override
  void seekTo(int timeMs) => _nowMs = timeMs;
}

final class CinematicMediaPreviewState {
  const CinematicMediaPreviewState({
    required this.timeMs,
    required this.activeCues,
  });

  final int timeMs;
  final List<CinematicPlaybackCue> activeCues;

  CinematicPlaybackCue? get dialogue =>
      _first(CinematicPlaybackCueKind.dialogue);
  CinematicPlaybackCue? get shake => _first(CinematicPlaybackCueKind.shake);
  CinematicPlaybackCue? get fx => _first(CinematicPlaybackCueKind.fx);

  CinematicPlaybackCue? _first(CinematicPlaybackCueKind kind) {
    for (final cue in activeCues) {
      if (cue.kind == kind) return cue;
    }
    return null;
  }
}

final class CinematicMediaPreviewException implements Exception {
  const CinematicMediaPreviewException(this.message, this.cause);

  final String message;
  final Object cause;

  @override
  String toString() => '$message: $cause';
}

final class CinematicMediaPreviewController {
  CinematicMediaPreviewController({
    required this.port,
    CinematicPreviewClock? clock,
  }) : clock = clock ?? MutableCinematicPreviewClock();

  final CinematicMediaPlaybackPort port;
  final CinematicPreviewClock clock;

  CinematicPreviewPlaybackPlan? _plan;
  CinematicMediaPlaybackCheckpoint? _checkpoint;
  final Set<String> _executedCueIds = {};
  CinematicMediaPreviewState _state = const CinematicMediaPreviewState(
    timeMs: 0,
    activeCues: [],
  );

  CinematicMediaPreviewState get state => _state;
  bool get isPrepared => _checkpoint != null && _plan != null;

  Future<CinematicMediaPreviewState> prepare(
    CinematicPreviewPlaybackPlan plan,
  ) async {
    final unsupported = plan.timelineItems.where(
      (item) =>
          !item.supported &&
          (item.kind == CinematicTimelineStepKind.sound ||
              item.kind == CinematicTimelineStepKind.music ||
              item.kind == CinematicTimelineStepKind.fx),
    );
    if (unsupported.isNotEmpty) {
      throw StateError(
        unsupported
            .map((item) {
              final diagnostics = item.diagnostics
                  .map((d) => d.message)
                  .join(' ');
              return '${item.stepId}: $diagnostics';
            })
            .join('\n'),
      );
    }
    await cancel();
    _plan = plan;
    _checkpoint = await port.captureCheckpoint();
    clock.seekTo(0);
    _state = _stateAt(plan, 0);
    return _state;
  }

  Future<CinematicMediaPreviewState> seek(int timeMs) async {
    final plan = _requirePlan();
    final checkpoint = _checkpoint!;
    final clamped = timeMs.clamp(0, plan.totalDurationMs).toInt();
    try {
      await port.restore(checkpoint);
      _executedCueIds.clear();
      for (final cue in plan.playbackCues) {
        if (_shouldRebuildCueAt(cue, clamped)) {
          await _executeCue(cue);
        }
      }
      clock.seekTo(clamped);
      _state = _stateAt(plan, clamped);
      return _state;
    } catch (error) {
      await _rollbackAfterFailure(checkpoint);
      throw CinematicMediaPreviewException('Preview seek failed', error);
    }
  }

  Future<CinematicMediaPreviewState> advanceTo(int timeMs) async {
    final plan = _requirePlan();
    final checkpoint = _checkpoint!;
    final previous = clock.nowMs;
    final clamped = timeMs.clamp(0, plan.totalDurationMs).toInt();
    if (clamped < previous) return seek(clamped);
    try {
      for (final cue in plan.playbackCues) {
        if (!_executedCueIds.contains(cue.stepId) &&
            cue.startMs >= previous &&
            cue.startMs <= clamped) {
          await _executeCue(cue);
        }
      }
      clock.seekTo(clamped);
      _state = _stateAt(plan, clamped);
      return _state;
    } catch (error) {
      await _rollbackAfterFailure(checkpoint);
      throw CinematicMediaPreviewException('Preview playback failed', error);
    }
  }

  Future<void> cancel() async {
    final checkpoint = _checkpoint;
    _checkpoint = null;
    _plan = null;
    _executedCueIds.clear();
    clock.seekTo(0);
    _state = const CinematicMediaPreviewState(timeMs: 0, activeCues: []);
    if (checkpoint != null) await port.restore(checkpoint);
  }

  CinematicPreviewPlaybackPlan _requirePlan() {
    final plan = _plan;
    if (plan == null || _checkpoint == null) {
      throw StateError('Cinematic media preview is not prepared.');
    }
    return plan;
  }

  Future<void> _executeCue(CinematicPlaybackCue cue) async {
    final command = _commandForCue(cue);
    if (command != null) await port.execute(command);
    _executedCueIds.add(cue.stepId);
  }

  Future<void> _rollbackAfterFailure(
    CinematicMediaPlaybackCheckpoint checkpoint,
  ) async {
    try {
      await port.restore(checkpoint);
    } finally {
      _checkpoint = null;
      _plan = null;
      _executedCueIds.clear();
      clock.seekTo(0);
      _state = const CinematicMediaPreviewState(timeMs: 0, activeCues: []);
    }
  }
}

CinematicMediaPreviewState _stateAt(
  CinematicPreviewPlaybackPlan plan,
  int timeMs,
) => CinematicMediaPreviewState(
  timeMs: timeMs,
  activeCues: plan.frameAt(timeMs).activeCues,
);

bool _shouldRebuildCueAt(CinematicPlaybackCue cue, int timeMs) {
  if (cue.kind == CinematicPlaybackCueKind.music && cue.loop) {
    return cue.startMs <= timeMs;
  }
  return cue.containsTime(timeMs);
}

CinematicMediaPlaybackCommand? _commandForCue(CinematicPlaybackCue cue) {
  final assetId = cue.referenceId;
  final channel = cue.channel;
  return switch (cue.kind) {
    CinematicPlaybackCueKind.sound || CinematicPlaybackCueKind.music =>
      assetId == null || channel == null
          ? null
          : CinematicMediaPlaybackCommand.play(
              commandId: 'preview:${cue.stepId}',
              assetId: assetId,
              channel: channel,
              volume: cue.volume,
              loop: cue.loop,
              fadeMs: cue.fadeMs,
            ),
    CinematicPlaybackCueKind.fx =>
      assetId == null || channel == null
          ? null
          : CinematicMediaPlaybackCommand.spawnFx(
              commandId: 'preview:${cue.stepId}',
              assetId: assetId,
              channel: channel,
              durationMs: cue.endMs - cue.startMs,
              intensity: cue.intensity,
            ),
    CinematicPlaybackCueKind.dialogue || CinematicPlaybackCueKind.shake => null,
  };
}
