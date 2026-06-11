import 'package:meta/meta.dart' show immutable;

import '../authoring/cinematic_authoring_operations.dart';
import '../models/cinematic_asset.dart';

enum CinematicTimelineLaneKind {
  camera,
  actor,
  dialogue,
  fx,
  audio,
  transitions,
  timeGlobal,
  other,
}

@immutable
final class CinematicTimelineLaneReadModel {
  CinematicTimelineLaneReadModel({
    required List<CinematicTimelineLane> lanes,
    required this.stepCount,
    required this.estimatedDurationMs,
  }) : lanes = List<CinematicTimelineLane>.unmodifiable(lanes);

  final List<CinematicTimelineLane> lanes;
  final int stepCount;
  final int? estimatedDurationMs;

  int get laneCount => lanes.length;
  bool get isEmpty => stepCount == 0;

  CinematicTimelineLane? laneById(String laneId) {
    for (final lane in lanes) {
      if (lane.laneId == laneId) {
        return lane;
      }
    }
    return null;
  }
}

@immutable
final class CinematicTimelineLane {
  CinematicTimelineLane({
    required this.laneId,
    required this.laneKind,
    required this.label,
    required this.sortOrder,
    this.actorId,
    this.actorLabel,
    required List<CinematicTimelineLaneStep> steps,
  }) : steps = List<CinematicTimelineLaneStep>.unmodifiable(steps);

  final String laneId;
  final CinematicTimelineLaneKind laneKind;
  final String label;
  final int sortOrder;
  final String? actorId;
  final String? actorLabel;
  final List<CinematicTimelineLaneStep> steps;

  bool get isEmpty => steps.isEmpty;
}

@immutable
final class CinematicTimelineLaneStep {
  CinematicTimelineLaneStep({
    required this.stepId,
    required this.stepIndex,
    required this.kind,
    required this.label,
    this.durationMs,
    this.actorId,
    this.actorLabel,
    this.targetId,
    this.targetLabel,
    required this.isAuthoringOwned,
    required List<String> badges,
  }) : badges = List<String>.unmodifiable(badges);

  final String stepId;
  final int stepIndex;
  final CinematicTimelineStepKind kind;
  final String label;
  final int? durationMs;
  final String? actorId;
  final String? actorLabel;
  final String? targetId;
  final String? targetLabel;
  final bool isAuthoringOwned;
  final List<String> badges;
}

CinematicTimelineLaneReadModel buildCinematicTimelineLaneReadModel(
  CinematicAsset cinematic,
) {
  final actorLabels = <String, String>{
    for (final actor in cinematic.requiredActors)
      actor.actorId: actor.label ?? actor.actorId,
  };
  final targetLabels = <String, String>{};
  for (final target in cinematic.movementTargets) {
    var label = target.label;
    final stageContext = cinematic.stageContext;
    if (stageContext != null) {
      CinematicMovementTargetBinding? binding;
      for (final b in stageContext.movementTargetBindings) {
        if (b.targetId == target.targetId) {
          binding = b;
          break;
        }
      }
      if (binding != null) {
        if (binding.kind == CinematicMovementTargetBindingKind.stagePoint) {
          final sourceId = binding.sourceId;
          CinematicStagePoint? point;
          if (sourceId != null) {
            for (final p in stageContext.stagePoints) {
              if (p.id == sourceId) {
                point = p;
                break;
              }
            }
          }
          if (point != null) {
            label = point.label;
          } else {
            label = '[Point de scène manquant]';
          }
        }
      }
    }
    targetLabels[target.targetId] = label;
  }
  final lanes = <String, _LaneDraft>{};

  _addLane(
    lanes,
    laneId: 'camera',
    laneKind: CinematicTimelineLaneKind.camera,
    label: 'Caméra',
    sortOrder: 0,
  );
  for (final actor in cinematic.requiredActors.asMap().entries) {
    final actorId = actor.value.actorId;
    final actorLabel = actor.value.label ?? actorId;
    _addLane(
      lanes,
      laneId: _actorLaneId(actorId),
      laneKind: CinematicTimelineLaneKind.actor,
      label: 'Acteur: $actorLabel',
      sortOrder: 100 + actor.key,
      actorId: actorId,
      actorLabel: actorLabel,
    );
  }
  _addLane(
    lanes,
    laneId: 'dialogue',
    laneKind: CinematicTimelineLaneKind.dialogue,
    label: 'Dialogue',
    sortOrder: 200,
  );
  _addLane(
    lanes,
    laneId: 'fx',
    laneKind: CinematicTimelineLaneKind.fx,
    label: 'FX',
    sortOrder: 300,
  );
  _addLane(
    lanes,
    laneId: 'audio',
    laneKind: CinematicTimelineLaneKind.audio,
    label: 'Audio',
    sortOrder: 400,
  );
  _addLane(
    lanes,
    laneId: 'transitions',
    laneKind: CinematicTimelineLaneKind.transitions,
    label: 'Transitions',
    sortOrder: 500,
  );
  _addLane(
    lanes,
    laneId: 'time-global',
    laneKind: CinematicTimelineLaneKind.timeGlobal,
    label: 'Temps / Global',
    sortOrder: 600,
  );
  _addLane(
    lanes,
    laneId: 'other',
    laneKind: CinematicTimelineLaneKind.other,
    label: 'Autres',
    sortOrder: 700,
  );

  var duration = 0;
  var hasDuration = false;
  var unknownActorOffset = 0;
  for (final entry in cinematic.timeline.steps.asMap().entries) {
    final step = entry.value;
    final durationMs = step.durationMs;
    if (durationMs != null && durationMs > 0) {
      duration += durationMs;
      hasDuration = true;
    }

    final lane = _laneForStep(
      step,
      lanes,
      actorLabels,
      unknownActorOffset,
    );
    if (lane.wasUnknownActorCreated) {
      unknownActorOffset += 1;
    }
    lane.draft.steps.add(
      _laneStepFor(
        step,
        stepIndex: entry.key,
        actorLabel: step.actorId == null ? null : actorLabels[step.actorId],
        targetLabel: step.targetId == null ? null : targetLabels[step.targetId],
      ),
    );
  }

  final sortedLanes = lanes.values.toList()
    ..sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) {
        return order;
      }
      return a.label.compareTo(b.label);
    });

  return CinematicTimelineLaneReadModel(
    lanes: [
      for (final lane in sortedLanes)
        CinematicTimelineLane(
          laneId: lane.laneId,
          laneKind: lane.laneKind,
          label: lane.label,
          sortOrder: lane.sortOrder,
          actorId: lane.actorId,
          actorLabel: lane.actorLabel,
          steps: lane.steps,
        ),
    ],
    stepCount: cinematic.timeline.steps.length,
    estimatedDurationMs: hasDuration ? duration : null,
  );
}

_LaneLookup _laneForStep(
  CinematicTimelineStep step,
  Map<String, _LaneDraft> lanes,
  Map<String, String> actorLabels,
  int unknownActorOffset,
) {
  final actorId = step.actorId;
  if (_isActorLaneStep(step.kind) && actorId != null) {
    final laneId = _actorLaneId(actorId);
    final existing = lanes[laneId];
    if (existing != null) {
      return _LaneLookup(existing, wasUnknownActorCreated: false);
    }
    final lane = _addLane(
      lanes,
      laneId: laneId,
      laneKind: CinematicTimelineLaneKind.actor,
      label: 'Acteur inconnu: $actorId',
      sortOrder: 100 + actorLabels.length + unknownActorOffset,
      actorId: actorId,
      actorLabel: actorId,
    );
    actorLabels[actorId] = actorId;
    return _LaneLookup(lane, wasUnknownActorCreated: true);
  }

  final laneId = switch (step.kind) {
    CinematicTimelineStepKind.camera => 'camera',
    CinematicTimelineStepKind.dialogueLine => 'dialogue',
    CinematicTimelineStepKind.fx || CinematicTimelineStepKind.shake => 'fx',
    CinematicTimelineStepKind.sound ||
    CinematicTimelineStepKind.music =>
      'audio',
    CinematicTimelineStepKind.fade => 'transitions',
    CinematicTimelineStepKind.wait ||
    CinematicTimelineStepKind.marker =>
      'time-global',
    CinematicTimelineStepKind.actorMove ||
    CinematicTimelineStepKind.actorFace ||
    CinematicTimelineStepKind.actorEmote =>
      'other',
  };
  return _LaneLookup(lanes[laneId]!, wasUnknownActorCreated: false);
}

CinematicTimelineLaneStep _laneStepFor(
  CinematicTimelineStep step, {
  required int stepIndex,
  required String? actorLabel,
  required String? targetLabel,
}) {
  final badges = <String>[step.kind.name];
  if (isCinematicTimelineAuthoringStep(step)) {
    badges.add('Builder V0');
  }
  if (isCinematicTimelineDraftStep(step)) {
    badges.add('Brouillon');
  }
  if (step.kind == CinematicTimelineStepKind.actorMove) {
    final target = targetLabel ?? step.targetId;
    if (target != null) {
      badges.add('Cible: $target');
    }
    final movementMode = cinematicTimelineActorMovementModeOf(step);
    if (movementMode != null) {
      badges.add(_movementModeLabel(movementMode));
    }
    final pathMode = cinematicTimelineActorPathModeOf(step);
    if (pathMode != null) {
      badges.add(_pathModeLabel(pathMode));
    }
  }
  return CinematicTimelineLaneStep(
    stepId: step.id,
    stepIndex: stepIndex,
    kind: step.kind,
    label: _laneStepLabel(
      step,
      stepIndex: stepIndex,
      actorLabel: actorLabel,
      targetLabel: targetLabel,
    ),
    durationMs: step.durationMs,
    actorId: step.actorId,
    actorLabel: actorLabel,
    targetId: step.targetId,
    targetLabel: targetLabel,
    isAuthoringOwned: isCinematicTimelineAuthoringStep(step),
    badges: badges,
  );
}

String _laneStepLabel(
  CinematicTimelineStep step, {
  required int stepIndex,
  required String? actorLabel,
  required String? targetLabel,
}) {
  if (step.kind == CinematicTimelineStepKind.actorMove) {
    final actor = actorLabel ?? step.actorId;
    final target = targetLabel ?? step.targetId;
    if (actor != null && target != null) {
      return '$actor → $target';
    }
  }
  return step.label ?? 'Step ${stepIndex + 1}';
}

String _movementModeLabel(CinematicTimelineActorMovementMode mode) {
  return switch (mode) {
    CinematicTimelineActorMovementMode.walk => 'Marche',
    CinematicTimelineActorMovementMode.run => 'Course',
  };
}

String _pathModeLabel(CinematicTimelineActorPathMode mode) {
  return switch (mode) {
    CinematicTimelineActorPathMode.direct => 'Direct',
    CinematicTimelineActorPathMode.manual => 'Manuel',
  };
}

bool _isActorLaneStep(CinematicTimelineStepKind kind) {
  return switch (kind) {
    CinematicTimelineStepKind.actorMove ||
    CinematicTimelineStepKind.actorFace ||
    CinematicTimelineStepKind.actorEmote =>
      true,
    _ => false,
  };
}

String _actorLaneId(String actorId) => 'actor:$actorId';

_LaneDraft _addLane(
  Map<String, _LaneDraft> lanes, {
  required String laneId,
  required CinematicTimelineLaneKind laneKind,
  required String label,
  required int sortOrder,
  String? actorId,
  String? actorLabel,
}) {
  final existing = lanes[laneId];
  if (existing != null) {
    return existing;
  }
  final lane = _LaneDraft(
    laneId: laneId,
    laneKind: laneKind,
    label: label,
    sortOrder: sortOrder,
    actorId: actorId,
    actorLabel: actorLabel,
  );
  lanes[laneId] = lane;
  return lane;
}

final class _LaneDraft {
  _LaneDraft({
    required this.laneId,
    required this.laneKind,
    required this.label,
    required this.sortOrder,
    this.actorId,
    this.actorLabel,
  });

  final String laneId;
  final CinematicTimelineLaneKind laneKind;
  final String label;
  final int sortOrder;
  final String? actorId;
  final String? actorLabel;
  final List<CinematicTimelineLaneStep> steps = [];
}

final class _LaneLookup {
  const _LaneLookup(this.draft, {required this.wasUnknownActorCreated});

  final _LaneDraft draft;
  final bool wasUnknownActorCreated;
}
