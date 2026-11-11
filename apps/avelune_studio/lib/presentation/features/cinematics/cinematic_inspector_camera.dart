part of 'cinematic_inspector.dart';

extension CinematicInspectorCamera on CinematicInspector {
  List<Widget> _cameraFields(CinematicAsset asset, CinematicTimelineStep step) {
    final targetId = cinematicCameraTargetOption(
      cinematicTimelineCameraFocusBindingOf(step)?.target,
    );
    final zoom = cinematicCameraZoomOf(step);
    return [
      StudioSelect(
        label: 'Action caméra',
        value: cinematicTimelineCameraModeOf(step)?.name,
        options: const {
          'reset': 'Revenir au cadrage initial',
          'hold': 'Conserver le cadrage',
          'focus': 'Cadrer une cible',
        },
        onChanged: (value) => _edit(
          asset,
          (a) => updateCinematicTimelineBasicBlockStep(
            _project(a),
            cinematicId: a.id,
            stepId: step.id,
            cameraMode: CinematicTimelineCameraMode.values.byName(value),
            cameraFocusBinding: cinematicCameraFocusForMode(
              step,
              CinematicTimelineCameraMode.values.byName(value),
            ),
          ).cinematic,
        ),
      ),
      if (cinematicTimelineCameraModeOf(step) ==
          CinematicTimelineCameraMode.focus) ...[
        StudioSelect(
          label: 'Cible caméra',
          value: targetId,
          options: {
            cinematicCameraCenterOption: 'Centre de la scène',
            for (final actor in asset.requiredActors)
              cinematicCameraActorOption(actor.actorId):
                  'Acteur · ${cinematicActorName(actor.label)}',
            for (final point
                in asset.stageContext?.stagePoints ?? <CinematicStagePoint>[])
              cinematicCameraPointOption(point.id): 'Repère · ${point.label}',
          },
          onChanged: (value) => _edit(
            asset,
            (a) => updateCinematicTimelineBasicBlockStep(
              _project(a),
              cinematicId: a.id,
              stepId: step.id,
              cameraFocusBinding: cinematicCameraFocusWithTarget(step, value),
            ).cinematic,
          ),
        ),
        StudioSelect(
          label: 'Cadrage',
          value: zoom.name,
          options: const {
            'wide': 'Plan large',
            'medium': 'Plan moyen',
            'close': 'Plan rapproché',
          },
          onChanged: (value) => _edit(
            asset,
            (a) => updateCinematicTimelineBasicBlockStep(
              _project(a),
              cinematicId: a.id,
              stepId: step.id,
              cameraFocusBinding: cinematicCameraFocusWithZoom(
                step,
                CinematicCameraZoomPreset.values.byName(value),
              ),
            ).cinematic,
          ),
        ),
      ],
      const Text(
        'Portée : cette action caméra ne vaut que pendant cette cinématique. '
        'Elle ne modifie ni la caméra enregistrée de la carte ni les réglages '
        'Image et caméra du projet.',
        key: ValueKey('cinematic-camera-scope'),
      ),
      const Text(
        'Le pan et le zoom de travail ne changent pas cette action caméra.',
      ),
    ];
  }
}
