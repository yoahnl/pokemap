import '../models/cinematic_asset.dart';
import '../models/cinematic_media_asset.dart';

enum CinematicTimelineScheduleTiming { preview, runtime }

enum CinematicTimelineScheduleIssueKind {
  nonContiguousGroup,
  groupedMarker,
  resourceConflict,
  movementDurationMismatch,
}

final class CinematicTimelineScheduleIssue {
  CinematicTimelineScheduleIssue({
    required this.kind,
    required this.parallelGroupId,
    required Iterable<String> stepIds,
    required this.message,
    this.resourceKey,
  }) : stepIds = List.unmodifiable(stepIds);
  final CinematicTimelineScheduleIssueKind kind;
  final String parallelGroupId;
  final List<String> stepIds;
  final String message;
  final String? resourceKey;
}

final class CinematicTimelineScheduledStep {
  const CinematicTimelineScheduledStep({
    required this.step,
    required this.stepIndex,
    required this.startMs,
    required this.durationMs,
  });
  final CinematicTimelineStep step;
  final int stepIndex;
  final int startMs;
  final int durationMs;
  String get stepId => step.id;
  int get endMs => startMs + durationMs;
}

final class CinematicTimelineScheduleGroup {
  CinematicTimelineScheduleGroup({
    required this.parallelGroupId,
    required this.startMs,
    required this.durationMs,
    required Iterable<CinematicTimelineScheduledStep> members,
  }) : members = List.unmodifiable(members);
  final String? parallelGroupId;
  final int startMs;
  final int durationMs;
  final List<CinematicTimelineScheduledStep> members;
  int get endMs => startMs + durationMs;
}

final class CinematicTimelineSchedule {
  CinematicTimelineSchedule({
    required Iterable<CinematicTimelineScheduleGroup> groups,
    required this.totalDurationMs,
    required Iterable<CinematicTimelineScheduleIssue> issues,
  }) : groups = List.unmodifiable(groups),
       issues = List.unmodifiable(issues);
  final List<CinematicTimelineScheduleGroup> groups;
  final int totalDurationMs;
  final List<CinematicTimelineScheduleIssue> issues;
  List<CinematicTimelineScheduledStep> get steps =>
      List.unmodifiable([for (final group in groups) ...group.members]);
  bool get isValid => issues.isEmpty;
}

CinematicTimelineSchedule buildCinematicTimelineSchedule(
  CinematicAsset cinematic, {
  CinematicTimelineScheduleTiming timing =
      CinematicTimelineScheduleTiming.preview,
  Iterable<CinematicMediaAsset> mediaAssets = const [],
}) {
  final mediaById = {for (final asset in mediaAssets) asset.id: asset};
  final groups = <CinematicTimelineScheduleGroup>[];
  final issues = <CinematicTimelineScheduleIssue>[];
  final seen = <String>{};
  var cursor = 0;
  var index = 0;
  while (index < cinematic.timeline.steps.length) {
    final first = cinematic.timeline.steps[index];
    final id = first.parallelGroupId;
    final members = <CinematicTimelineScheduledStep>[];
    var duration = 0;
    do {
      final step = cinematic.timeline.steps[index];
      final length = _duration(step, timing);
      if (length > duration) duration = length;
      members.add(
        CinematicTimelineScheduledStep(
          step: step,
          stepIndex: index,
          startMs: cursor,
          durationMs: length,
        ),
      );
      index++;
    } while (id != null &&
        index < cinematic.timeline.steps.length &&
        cinematic.timeline.steps[index].parallelGroupId == id);
    if (id != null) {
      if (!seen.add(id)) {
        issues.add(
          CinematicTimelineScheduleIssue(
            kind: CinematicTimelineScheduleIssueKind.nonContiguousGroup,
            parallelGroupId: id,
            stepIds: members.map((member) => member.stepId),
            message: 'Parallel group "$id" must be contiguous.',
          ),
        );
      }
      final resources = <String, String>{};
      final durations = <int?>{};
      for (final member in members) {
        final step = member.step;
        if (step.kind == CinematicTimelineStepKind.marker) {
          issues.add(
            CinematicTimelineScheduleIssue(
              kind: CinematicTimelineScheduleIssueKind.groupedMarker,
              parallelGroupId: id,
              stepIds: [step.id],
              message: 'Markers must remain outside parallel groups.',
            ),
          );
        }
        if (step.kind == CinematicTimelineStepKind.actorMove ||
            step.kind == CinematicTimelineStepKind.actorJump) {
          durations.add(step.durationMs);
        }
        for (final resource in _resources(cinematic, step, mediaById)) {
          final previous = resources[resource];
          if (previous != null) {
            issues.add(
              CinematicTimelineScheduleIssue(
                kind: CinematicTimelineScheduleIssueKind.resourceConflict,
                parallelGroupId: id,
                stepIds: [previous, step.id],
                resourceKey: resource,
                message:
                    'Parallel group "$id" writes "$resource" more than once.',
              ),
            );
          } else {
            resources[resource] = step.id;
          }
        }
      }
      if (durations.length > 1) {
        issues.add(
          CinematicTimelineScheduleIssue(
            kind: CinematicTimelineScheduleIssueKind.movementDurationMismatch,
            parallelGroupId: id,
            stepIds: members
                .where(
                  (member) =>
                      member.step.kind == CinematicTimelineStepKind.actorMove ||
                      member.step.kind == CinematicTimelineStepKind.actorJump,
                )
                .map((member) => member.stepId),
            message:
                'Actor moves and jumps in one parallel group must have identical durationMs.',
          ),
        );
      }
    }
    groups.add(
      CinematicTimelineScheduleGroup(
        parallelGroupId: id,
        startMs: cursor,
        durationMs: duration,
        members: members,
      ),
    );
    cursor += duration;
  }
  return CinematicTimelineSchedule(
    groups: groups,
    totalDurationMs: cursor,
    issues: issues,
  );
}

int _duration(
  CinematicTimelineStep step,
  CinematicTimelineScheduleTiming timing,
) {
  if (step.kind == CinematicTimelineStepKind.actorFace ||
      step.kind == CinematicTimelineStepKind.marker ||
      step.kind == CinematicTimelineStepKind.camera &&
          step.durationMs == null) {
    return 0;
  }
  final duration = step.durationMs;
  if (duration != null && duration > 0) return duration;
  if (duration == 0 && timing == CinematicTimelineScheduleTiming.runtime) {
    return 0;
  }
  if (timing == CinematicTimelineScheduleTiming.preview ||
      step.kind == CinematicTimelineStepKind.sound ||
      step.kind == CinematicTimelineStepKind.music) {
    return 300;
  }
  return 0;
}

Iterable<String> _resources(
  CinematicAsset cinematic,
  CinematicTimelineStep step,
  Map<String, CinematicMediaAsset> mediaById,
) sync* {
  final actorId = step.actorId;
  if (actorId != null) {
    var identity = 'actor:$actorId';
    for (final binding
        in cinematic.stageContext?.actorBindings ??
            const <CinematicActorBinding>[]) {
      if (binding.actorId != actorId) continue;
      if (binding.kind == CinematicActorBindingKind.player) {
        identity = 'actor:player';
      }
      if (binding.kind == CinematicActorBindingKind.mapEntity &&
          binding.mapEntityId != null) {
        identity = 'actor:entity:${cinematic.mapId}:${binding.mapEntityId}';
      }
    }
    yield identity;
  }
  switch (step.kind) {
    case CinematicTimelineStepKind.camera:
    case CinematicTimelineStepKind.shake:
      yield 'camera';
    case CinematicTimelineStepKind.dialogueLine:
      yield 'dialogue';
    case CinematicTimelineStepKind.fade:
      yield 'fade';
    case CinematicTimelineStepKind.actorEmote:
      yield 'emote';
    case CinematicTimelineStepKind.sound:
    case CinematicTimelineStepKind.music:
    case CinematicTimelineStepKind.fx:
      final asset = mediaById[step.assetRef];
      yield asset == null && step.assetRef != null
          ? 'media:unresolved:${step.assetRef}'
          : 'media:${asset?.channel ?? step.kind.name}';
    default:
      break;
  }
}

int? estimateCinematicTimelineDeclaredDurationMs(CinematicTimeline timeline) {
  var total = 0;
  var hasDuration = false;
  var index = 0;
  while (index < timeline.steps.length) {
    final id = timeline.steps[index].parallelGroupId;
    var maximum = 0;
    do {
      final duration = timeline.steps[index++].durationMs;
      if (duration != null && duration > 0) {
        hasDuration = true;
        if (duration > maximum) maximum = duration;
      }
    } while (id != null &&
        index < timeline.steps.length &&
        timeline.steps[index].parallelGroupId == id);
    total += maximum;
  }
  return hasDuration ? total : null;
}
