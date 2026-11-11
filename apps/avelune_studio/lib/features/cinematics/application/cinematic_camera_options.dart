import 'package:map_core/map_core_domain.dart';

const cinematicCameraCenterOption = 'center';
const _actorOptionPrefix = 'actor:';
const _pointOptionPrefix = 'point:';

String cinematicCameraActorOption(String actorId) =>
    '$_actorOptionPrefix$actorId';

String cinematicCameraPointOption(String stagePointId) =>
    '$_pointOptionPrefix$stagePointId';

String cinematicCameraTargetOption(CinematicCameraTargetBinding? target) =>
    switch (target?.kind) {
      CinematicCameraTargetKind.actor => '$_actorOptionPrefix${target!.actorId}',
      CinematicCameraTargetKind.stagePoint =>
        '$_pointOptionPrefix${target!.stagePointId}',
      _ => cinematicCameraCenterOption,
    };

CinematicCameraTargetBinding cinematicCameraTargetFromOption(String option) =>
    option.startsWith(_actorOptionPrefix)
    ? CinematicCameraTargetBinding.actor(
        actorId: option.substring(_actorOptionPrefix.length),
      )
    : option.startsWith(_pointOptionPrefix)
    ? CinematicCameraTargetBinding.stagePoint(
        stagePointId: option.substring(_pointOptionPrefix.length),
      )
    : CinematicCameraTargetBinding.sceneCenter();

CinematicCameraZoomPreset cinematicCameraZoomOf(CinematicTimelineStep step) =>
    cinematicTimelineCameraFocusBindingOf(step)?.zoomPreset ??
    CinematicCameraZoomPreset.medium;

CinematicTimelineCameraFocusBinding? cinematicCameraFocusForMode(
  CinematicTimelineStep step,
  CinematicTimelineCameraMode mode,
) => mode == CinematicTimelineCameraMode.focus
    ? CinematicTimelineCameraFocusBinding(
        target:
            cinematicTimelineCameraFocusBindingOf(step)?.target ??
            CinematicCameraTargetBinding.sceneCenter(),
        zoomPreset: cinematicCameraZoomOf(step),
      )
    : null;

CinematicTimelineCameraFocusBinding cinematicCameraFocusWithTarget(
  CinematicTimelineStep step,
  String option,
) => CinematicTimelineCameraFocusBinding(
  target: cinematicCameraTargetFromOption(option),
  zoomPreset: cinematicCameraZoomOf(step),
);

CinematicTimelineCameraFocusBinding cinematicCameraFocusWithZoom(
  CinematicTimelineStep step,
  CinematicCameraZoomPreset zoom,
) => CinematicTimelineCameraFocusBinding(
  target:
      cinematicTimelineCameraFocusBindingOf(step)?.target ??
      CinematicCameraTargetBinding.sceneCenter(),
  zoomPreset: zoom,
);
