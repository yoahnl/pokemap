import 'package:map_core/map_core_domain.dart';

import 'cinematic_workspace_controller.dart';

const cinematicInspectorTabIds = {'properties', 'actors', 'document'};

const cinematicParallelEditError =
    'Impossible de regrouper ces étapes : les déplacements et sauts doivent avoir des durées identiques. Vérifiez aussi les acteurs, la caméra et les canaux audio.';

String cinematicInspectorTab(String tab) =>
    cinematicInspectorTabIds.contains(tab) ? tab : 'properties';

bool cinematicCrossingEditable(ProjectManifest project) =>
    project.settings.dimension == ProjectDimension.threeD;

CinematicMediaAssetKind? cinematicCommandMediaKind(
  CinematicTimelineStepKind kind,
) => switch (kind) {
  CinematicTimelineStepKind.sound => CinematicMediaAssetKind.sound,
  CinematicTimelineStepKind.music => CinematicMediaAssetKind.music,
  CinematicTimelineStepKind.fx => CinematicMediaAssetKind.cinematicFx,
  _ => null,
};

List<CinematicMediaAsset> cinematicCommandMediaChoices(
  ProjectManifest project,
  CinematicTimelineStep step,
) {
  final kind = cinematicCommandMediaKind(step.kind);
  return [
    for (final media in project.cinematicMediaAssets)
      if (kind != null && media.kind == kind) media,
  ];
}

bool cinematicParallelJoinAvailable(
  CinematicAsset asset,
  CinematicTimelineStep step,
) {
  final steps = asset.timeline.steps;
  final index = steps.indexWhere((value) => value.id == step.id);
  final joined =
      index > 0 &&
      step.parallelGroupId != null &&
      steps[index - 1].parallelGroupId == step.parallelGroupId;
  return index > 0 && !joined && step.kind != CinematicTimelineStepKind.marker;
}

CinematicAsset Function(CinematicAsset) cinematicParallelEdit(
  CinematicAsset Function(CinematicAsset) change,
) => (current) {
  try {
    return change(current);
  } on ArgumentError {
    throw ArgumentError(cinematicParallelEditError);
  }
};

CinematicStagePoint? cinematicStagePointWithAxis(
  CinematicStagePoint point,
  String axis,
  String text,
) {
  final value = double.tryParse(text);
  if (value == null || !value.isFinite) return null;
  return CinematicStagePoint(
    id: point.id,
    label: point.label,
    x: axis == 'x' ? value : point.x,
    y: axis == 'y' ? value : point.y,
    description: point.description,
    relativeToActorId: point.relativeToActorId,
  );
}

List<String> cinematicWaypointsMovedUp(List<String> ids, int index) {
  final moved = List<String>.of(ids);
  moved.insert(index - 1, moved.removeAt(index));
  return moved;
}

List<String> cinematicWaypointsWithout(List<String> ids, int index) =>
    List<String>.of(ids)..removeAt(index);

extension CinematicInspectorDispatch on CinematicWorkspaceController {
  CinematicAsset stepWithActor(
    CinematicAsset asset,
    CinematicTimelineStep step,
    String actorId,
  ) {
    final project = projectWith(asset);
    if (isCinematicTimelineActorJumpStep(step)) {
      return updateCinematicTimelineActorJumpStep(
        project,
        cinematicId: asset.id,
        stepId: step.id,
        actorId: actorId,
      ).cinematic;
    }
    if (isCinematicTimelineActorMoveStep(step)) {
      return updateCinematicTimelineActorMoveStep(
        project,
        cinematicId: asset.id,
        stepId: step.id,
        actorId: actorId,
      ).cinematic;
    }
    if (isCinematicTimelineActorFacingStep(step)) {
      return updateCinematicTimelineActorFacingStep(
        project,
        cinematicId: asset.id,
        stepId: step.id,
        actorId: actorId,
      ).cinematic;
    }
    return updateCinematicTimelineActorEmoteStep(
      project,
      cinematicId: asset.id,
      stepId: step.id,
      actorId: actorId,
    ).cinematic;
  }

  CinematicAsset stepWithMotion(
    CinematicAsset asset,
    CinematicTimelineStep step, {
    String? targetId,
    CinematicTimelineActorFacingMode? facingMode,
  }) => isCinematicTimelineActorJumpStep(step)
      ? updateCinematicTimelineActorJumpStep(
          projectWith(asset),
          cinematicId: asset.id,
          stepId: step.id,
          targetId: targetId,
          facingMode: facingMode,
        ).cinematic
      : updateCinematicTimelineActorMoveStep(
          projectWith(asset),
          cinematicId: asset.id,
          stepId: step.id,
          targetId: targetId,
          facingMode: facingMode,
        ).cinematic;
}
