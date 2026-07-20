import 'package:meta/meta.dart' show immutable;

import '../authoring/cinematic_authoring_operations.dart';
import '../models/cinematic_asset.dart';

enum CinematicStoryboardDiagnostic {
  emptyShot,
  missingMap,
  missingActor,
  missingMovementTarget,
  missingStagePoint,
}

@immutable
final class CinematicStoryboardReadModel {
  CinematicStoryboardReadModel({
    required this.locationLabel,
    required this.totalDurationMs,
    required List<CinematicStoryboardShot> shots,
  }) : shots = List<CinematicStoryboardShot>.unmodifiable(shots);

  final String locationLabel;
  final int totalDurationMs;
  final List<CinematicStoryboardShot> shots;

  bool get hasDiagnostics => shots.any((shot) => shot.diagnostics.isNotEmpty);
}

@immutable
final class CinematicStoryboardShot {
  CinematicStoryboardShot({
    required this.id,
    required this.label,
    required this.startMs,
    required this.durationMs,
    required this.cameraFraming,
    required List<String> actorLabels,
    required List<String> stepIds,
    required List<CinematicStoryboardDiagnostic> diagnostics,
  })  : actorLabels = List<String>.unmodifiable(actorLabels),
        stepIds = List<String>.unmodifiable(stepIds),
        diagnostics = List<CinematicStoryboardDiagnostic>.unmodifiable(
          diagnostics,
        );

  final String id;
  final String label;
  final int startMs;
  final int durationMs;
  final String cameraFraming;
  final List<String> actorLabels;
  final List<String> stepIds;
  final List<CinematicStoryboardDiagnostic> diagnostics;
}

/// Builds a plan-by-plan editorial view from the canonical linear timeline.
///
/// Markers, camera cuts and transitions delimit shots. Nothing in this model is
/// persisted, so the timeline remains the single source of truth.
CinematicStoryboardReadModel buildCinematicStoryboardReadModel(
  CinematicAsset cinematic,
) {
  final location = cinematic.mapId ?? 'Décor non défini';
  if (cinematic.timeline.steps.isEmpty) {
    return CinematicStoryboardReadModel(
      locationLabel: location,
      totalDurationMs: 0,
      shots: [
        CinematicStoryboardShot(
          id: 'shot-1',
          label: 'Mise en place',
          startMs: 0,
          durationMs: 0,
          cameraFraming: 'Cadrage par défaut',
          actorLabels: const [],
          stepIds: const [],
          diagnostics: [
            CinematicStoryboardDiagnostic.emptyShot,
            if (cinematic.mapId == null)
              CinematicStoryboardDiagnostic.missingMap,
          ],
        ),
      ],
    );
  }

  final actorLabels = {
    for (final actor in cinematic.requiredActors)
      actor.actorId: actor.label ?? actor.actorId,
  };
  final targetIds = {
    for (final target in cinematic.movementTargets) target.targetId,
  };
  final stagePointIds = {
    for (final point
        in cinematic.stageContext?.stagePoints ?? const <CinematicStagePoint>[])
      point.id,
  };
  final drafts = <_ShotDraft>[];
  var elapsedMs = 0;
  _ShotDraft? current;

  for (final step in cinematic.timeline.steps) {
    final isBoundary = step.kind == CinematicTimelineStepKind.marker ||
        step.kind == CinematicTimelineStepKind.camera ||
        step.kind == CinematicTimelineStepKind.fade;
    if (current == null || (isBoundary && current.stepIds.isNotEmpty)) {
      current = _ShotDraft(
        id: 'shot-${drafts.length + 1}',
        label: _shotLabel(step, drafts.length + 1),
        startMs: elapsedMs,
      );
      drafts.add(current);
    } else if (step.kind == CinematicTimelineStepKind.marker &&
        step.label != null) {
      current.label = step.label!;
    }

    current.stepIds.add(step.id);
    final durationMs = step.durationMs ?? 0;
    current.durationMs += durationMs < 0 ? 0 : durationMs;
    elapsedMs += durationMs < 0 ? 0 : durationMs;

    final actorId = step.actorId;
    if (actorId != null) {
      final actorLabel = actorLabels[actorId];
      if (actorLabel == null) {
        current.diagnostics.add(CinematicStoryboardDiagnostic.missingActor);
      } else {
        current.actorLabels.add(actorLabel);
      }
    }
    final targetId = step.targetId;
    if (targetId != null && !targetIds.contains(targetId)) {
      current.diagnostics
          .add(CinematicStoryboardDiagnostic.missingMovementTarget);
    }
    if (step.kind == CinematicTimelineStepKind.camera) {
      current.cameraFraming = _cameraFraming(step, actorLabels);
      final targetKind =
          step.metadata[cinematicTimelineCameraTargetKindMetadataKey];
      if (targetKind == 'actor') {
        final targetActor =
            step.metadata[cinematicTimelineCameraTargetActorIdMetadataKey];
        if (targetActor == null || !actorLabels.containsKey(targetActor)) {
          current.diagnostics.add(CinematicStoryboardDiagnostic.missingActor);
        } else {
          current.actorLabels.add(actorLabels[targetActor]!);
        }
      } else if (targetKind == 'stagePoint') {
        final pointId =
            step.metadata[cinematicTimelineCameraTargetStagePointIdMetadataKey];
        if (pointId == null || !stagePointIds.contains(pointId)) {
          current.diagnostics
              .add(CinematicStoryboardDiagnostic.missingStagePoint);
        }
      }
    }
  }

  return CinematicStoryboardReadModel(
    locationLabel: location,
    totalDurationMs: elapsedMs,
    shots: [
      for (final draft in drafts)
        CinematicStoryboardShot(
          id: draft.id,
          label: draft.label,
          startMs: draft.startMs,
          durationMs: draft.durationMs,
          cameraFraming: draft.cameraFraming,
          actorLabels: draft.actorLabels.toList(),
          stepIds: draft.stepIds,
          diagnostics: [
            if (cinematic.mapId == null)
              CinematicStoryboardDiagnostic.missingMap,
            ...draft.diagnostics,
          ],
        ),
    ],
  );
}

String _shotLabel(CinematicTimelineStep step, int index) {
  final label = step.label;
  if (label != null && label.trim().isNotEmpty) return label;
  return switch (step.kind) {
    CinematicTimelineStepKind.camera => 'Nouveau cadrage',
    CinematicTimelineStepKind.fade => 'Transition',
    _ => 'Plan $index',
  };
}

String _cameraFraming(
  CinematicTimelineStep step,
  Map<String, String> actorLabels,
) {
  final targetKind =
      step.metadata[cinematicTimelineCameraTargetKindMetadataKey];
  final zoom =
      switch (step.metadata[cinematicTimelineCameraZoomPresetMetadataKey]) {
    'wide' => 'Large',
    'close' => 'Rapproché',
    _ => 'Moyen',
  };
  if (targetKind == 'actor') {
    final actorId =
        step.metadata[cinematicTimelineCameraTargetActorIdMetadataKey];
    return '${actorLabels[actorId] ?? actorId ?? 'Acteur manquant'} · $zoom';
  }
  if (targetKind == 'stagePoint') {
    return 'Point de scène · $zoom';
  }
  return 'Centre scène · $zoom';
}

final class _ShotDraft {
  _ShotDraft({required this.id, required this.label, required this.startMs});

  final String id;
  String label;
  final int startMs;
  int durationMs = 0;
  String cameraFraming = 'Cadrage par défaut';
  final Set<String> actorLabels = {};
  final List<String> stepIds = [];
  final Set<CinematicStoryboardDiagnostic> diagnostics = {};
}
