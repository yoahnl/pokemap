import 'package:meta/meta.dart' show immutable;

import '../models/cinematic_asset.dart';
import 'cinematic_timeline_lane_read_model.dart';

const cinematicTimelineFallbackVisualDurationMs = 300;

enum CinematicTimelineVisualDurationSource {
  explicit,
  fallback,
}

@immutable
final class CinematicTimelineTimeLayoutReadModel {
  CinematicTimelineTimeLayoutReadModel({
    required List<CinematicTimelineTimeLane> lanes,
    required List<CinematicTimelineTimeBlock> blocks,
    required List<CinematicTimelineTimeTick> ticks,
    required this.totalDurationMs,
    required this.stepCount,
  })  : lanes = List<CinematicTimelineTimeLane>.unmodifiable(lanes),
        blocks = List<CinematicTimelineTimeBlock>.unmodifiable(blocks),
        ticks = List<CinematicTimelineTimeTick>.unmodifiable(ticks);

  final List<CinematicTimelineTimeLane> lanes;
  final List<CinematicTimelineTimeBlock> blocks;
  final List<CinematicTimelineTimeTick> ticks;
  final int totalDurationMs;
  final int stepCount;

  int get laneCount => lanes.length;
  bool get isEmpty => stepCount == 0;

  CinematicTimelineTimeLane? laneById(String laneId) {
    for (final lane in lanes) {
      if (lane.laneId == laneId) {
        return lane;
      }
    }
    return null;
  }
}

@immutable
final class CinematicTimelineTimeLane {
  CinematicTimelineTimeLane({
    required this.laneId,
    required this.laneKind,
    required this.label,
    required this.sortOrder,
    this.actorId,
    this.actorLabel,
    required List<CinematicTimelineTimeBlock> blocks,
  }) : blocks = List<CinematicTimelineTimeBlock>.unmodifiable(blocks);

  final String laneId;
  final CinematicTimelineLaneKind laneKind;
  final String label;
  final int sortOrder;
  final String? actorId;
  final String? actorLabel;
  final List<CinematicTimelineTimeBlock> blocks;

  bool get isEmpty => blocks.isEmpty;
}

@immutable
final class CinematicTimelineTimeBlock {
  CinematicTimelineTimeBlock({
    required this.stepId,
    required this.stepIndex,
    required this.laneId,
    required this.kind,
    required this.label,
    required this.startMs,
    required this.endMs,
    this.durationMs,
    required this.visualDurationMs,
    required this.durationSource,
    this.actorId,
    this.actorLabel,
    this.targetId,
    this.targetLabel,
    required this.isAuthoringOwned,
    required List<String> badges,
  }) : badges = List<String>.unmodifiable(badges);

  final String stepId;
  final int stepIndex;
  final String laneId;
  final CinematicTimelineStepKind kind;
  final String label;
  final int startMs;
  final int endMs;
  final int? durationMs;
  final int visualDurationMs;
  final CinematicTimelineVisualDurationSource durationSource;
  final String? actorId;
  final String? actorLabel;
  final String? targetId;
  final String? targetLabel;
  final bool isAuthoringOwned;
  final List<String> badges;
}

@immutable
final class CinematicTimelineTimeTick {
  const CinematicTimelineTimeTick({
    required this.timeMs,
    required this.label,
    required this.isMajor,
  });

  final int timeMs;
  final String label;
  final bool isMajor;
}

CinematicTimelineTimeLayoutReadModel buildCinematicTimelineTimeLayoutReadModel(
  CinematicAsset cinematic,
) {
  final laneReadModel = buildCinematicTimelineLaneReadModel(cinematic);
  final timings = <String, _StepTiming>{};

  var currentMs = 0;
  for (final entry in cinematic.timeline.steps.asMap().entries) {
    final step = entry.value;
    final visualDurationMs = _visualDurationMs(step.durationMs);
    final durationSource = _durationSource(step.durationMs);
    final startMs = currentMs;
    final endMs = startMs + visualDurationMs;
    timings[step.id] = _StepTiming(
      startMs: startMs,
      endMs: endMs,
      visualDurationMs: visualDurationMs,
      durationSource: durationSource,
    );
    currentMs = endMs;
  }

  final timeLanes = [
    for (final lane in laneReadModel.lanes)
      CinematicTimelineTimeLane(
        laneId: lane.laneId,
        laneKind: lane.laneKind,
        label: lane.label,
        sortOrder: lane.sortOrder,
        actorId: lane.actorId,
        actorLabel: lane.actorLabel,
        blocks: [
          for (final step in lane.steps)
            if (timings[step.stepId] case final timing?)
              CinematicTimelineTimeBlock(
                stepId: step.stepId,
                stepIndex: step.stepIndex,
                laneId: lane.laneId,
                kind: step.kind,
                label: step.label,
                startMs: timing.startMs,
                endMs: timing.endMs,
                durationMs: step.durationMs,
                visualDurationMs: timing.visualDurationMs,
                durationSource: timing.durationSource,
                actorId: step.actorId,
                actorLabel: step.actorLabel,
                targetId: step.targetId,
                targetLabel: step.targetLabel,
                isAuthoringOwned: step.isAuthoringOwned,
                badges: step.badges,
              ),
        ],
      ),
  ];

  final blocks = [
    for (final lane in timeLanes) ...lane.blocks,
  ]..sort((a, b) => a.stepIndex.compareTo(b.stepIndex));

  return CinematicTimelineTimeLayoutReadModel(
    lanes: timeLanes,
    blocks: blocks,
    ticks: _ticksForTotalDuration(currentMs),
    totalDurationMs: currentMs,
    stepCount: cinematic.timeline.steps.length,
  );
}

int _visualDurationMs(int? durationMs) {
  if (durationMs != null && durationMs > 0) {
    return durationMs;
  }
  return cinematicTimelineFallbackVisualDurationMs;
}

CinematicTimelineVisualDurationSource _durationSource(int? durationMs) {
  if (durationMs != null && durationMs > 0) {
    return CinematicTimelineVisualDurationSource.explicit;
  }
  return CinematicTimelineVisualDurationSource.fallback;
}

List<CinematicTimelineTimeTick> _ticksForTotalDuration(int totalDurationMs) {
  if (totalDurationMs <= 0) {
    return const [
      CinematicTimelineTimeTick(timeMs: 0, label: '0 ms', isMajor: true),
    ];
  }

  final intervalMs = _tickIntervalMs(totalDurationMs);
  final times = <int>[];
  for (var timeMs = 0; timeMs <= totalDurationMs; timeMs += intervalMs) {
    times.add(timeMs);
  }
  if (times.last != totalDurationMs) {
    times.add(totalDurationMs);
  }

  return [
    for (final timeMs in times)
      CinematicTimelineTimeTick(
        timeMs: timeMs,
        label: _formatTickLabel(timeMs),
        isMajor: true,
      ),
  ];
}

int _tickIntervalMs(int totalDurationMs) {
  if (totalDurationMs <= 3000) {
    return 500;
  }
  if (totalDurationMs <= 10000) {
    return 1000;
  }
  if (totalDurationMs <= 30000) {
    return 5000;
  }
  return 10000;
}

String _formatTickLabel(int timeMs) {
  if (timeMs < 1000) {
    return '$timeMs ms';
  }
  if (timeMs % 1000 == 0) {
    return '${timeMs ~/ 1000} s';
  }
  final decimals = timeMs % 100 == 0 ? 1 : 2;
  var seconds = (timeMs / 1000).toStringAsFixed(decimals);
  while (seconds.endsWith('0')) {
    seconds = seconds.substring(0, seconds.length - 1);
  }
  if (seconds.endsWith('.')) {
    seconds = seconds.substring(0, seconds.length - 1);
  }
  return '$seconds s';
}

final class _StepTiming {
  const _StepTiming({
    required this.startMs,
    required this.endMs,
    required this.visualDurationMs,
    required this.durationSource,
  });

  final int startMs;
  final int endMs;
  final int visualDurationMs;
  final CinematicTimelineVisualDurationSource durationSource;
}
