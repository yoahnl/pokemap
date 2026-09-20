part of 'cinematic_inspector.dart';

extension CinematicInspectorCamera on CinematicInspector {
  List<Widget> _cameraFields(CinematicAsset asset, CinematicTimelineStep step) {
    final focus = cinematicTimelineCameraFocusBindingOf(step);
    final target = focus?.target;
    final targetId = switch (target?.kind) {
      CinematicCameraTargetKind.actor => 'actor:${target!.actorId}',
      CinematicCameraTargetKind.stagePoint => 'point:${target!.stagePointId}',
      _ => 'center',
    };
    final zoom = focus?.zoomPreset ?? CinematicCameraZoomPreset.medium;
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
            cameraFocusBinding: value == 'focus'
                ? CinematicTimelineCameraFocusBinding(
                    target:
                        target ?? CinematicCameraTargetBinding.sceneCenter(),
                    zoomPreset: zoom,
                  )
                : null,
          ).cinematic,
        ),
      ),
      if (cinematicTimelineCameraModeOf(step) ==
          CinematicTimelineCameraMode.focus) ...[
        StudioSelect(
          label: 'Cible caméra',
          value: targetId,
          options: {
            'center': 'Centre de la scène',
            for (final actor in asset.requiredActors)
              'actor:${actor.actorId}': 'Acteur · ${actor.label}',
            for (final point
                in asset.stageContext?.stagePoints ?? <CinematicStagePoint>[])
              'point:${point.id}': 'Repère · ${point.label}',
          },
          onChanged: (value) {
            final selected = value.startsWith('actor:')
                ? CinematicCameraTargetBinding.actor(
                    actorId: value.substring(6),
                  )
                : value.startsWith('point:')
                ? CinematicCameraTargetBinding.stagePoint(
                    stagePointId: value.substring(6),
                  )
                : CinematicCameraTargetBinding.sceneCenter();
            _edit(
              asset,
              (a) => updateCinematicTimelineBasicBlockStep(
                _project(a),
                cinematicId: a.id,
                stepId: step.id,
                cameraFocusBinding: CinematicTimelineCameraFocusBinding(
                  target: selected,
                  zoomPreset: zoom,
                ),
              ).cinematic,
            );
          },
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
              cameraFocusBinding: CinematicTimelineCameraFocusBinding(
                target: target ?? CinematicCameraTargetBinding.sceneCenter(),
                zoomPreset: CinematicCameraZoomPreset.values.byName(value),
              ),
            ).cinematic,
          ),
        ),
      ],
      const Text(
        'Le pan et le zoom de travail ne changent pas cette action caméra.',
      ),
    ];
  }
}
