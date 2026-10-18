part of 'cinematic_inspector.dart';

extension CinematicInspectorStep on CinematicInspector {
  List<Widget> _stepFields(
    CinematicAsset asset,
    CinematicTimelineStep step,
  ) => [
    StudioBadge(
      cinematicActionLabel(step.kind),
      tone: StudioTone.info,
      icon: cinematicActionIcon(step.kind),
    ),
    Text(step.label ?? cinematicActionLabel(step.kind)),
    if (cinematicDurationEditable(step))
      StudioCommitField(
        key: ValueKey('duration-${asset.id}-${step.id}'),
        label: 'Durée (ms)',
        alwaysCommit: true,
        value: '${step.durationMs}',
        tryCommit: (text) {
          if (controller.active?.asset.id != asset.id) return false;
          final duration = int.tryParse(text);
          const jumpDurationError =
              'La durée du saut doit être comprise entre 200 et 30000 ms.';
          if (isCinematicTimelineActorJumpStep(step) &&
              (duration == null ||
                  duration < cinematicTimelineActorMoveMinimumDurationMs ||
                  duration > cinematicTimelineMaximumDurationMs)) {
            view.error = jumpDurationError;
            changed();
            return false;
          }
          if (duration == null || duration <= 0) {
            view.error = 'Saisissez une durée entière strictement positive.';
            changed();
            return false;
          }
          final accepted = controller.updateDuration(step.id, duration);
          if (accepted &&
              (view.error ==
                      'Saisissez une durée entière strictement positive.' ||
                  view.error == jumpDurationError)) {
            view.error = null;
            changed();
          }
          return accepted;
        },
      ),
    if (isCinematicTimelineActorFacingStep(step) ||
        isCinematicTimelineActorMoveStep(step) ||
        isCinematicTimelineActorJumpStep(step) ||
        isCinematicTimelineActorEmoteStep(step))
      StudioSelect(
        label: 'Acteur',
        value: step.actorId,
        options: {
          for (final actor in asset.requiredActors)
            actor.actorId: '${actor.label} · ${actor.actorId}',
        },
        onChanged: (id) => _edit(
          asset,
          (a) => isCinematicTimelineActorJumpStep(step)
              ? updateCinematicTimelineActorJumpStep(
                  _project(a),
                  cinematicId: a.id,
                  stepId: step.id,
                  actorId: id,
                ).cinematic
              : isCinematicTimelineActorMoveStep(step)
              ? updateCinematicTimelineActorMoveStep(
                  _project(a),
                  cinematicId: a.id,
                  stepId: step.id,
                  actorId: id,
                ).cinematic
              : isCinematicTimelineActorFacingStep(step)
              ? updateCinematicTimelineActorFacingStep(
                  _project(a),
                  cinematicId: a.id,
                  stepId: step.id,
                  actorId: id,
                ).cinematic
              : updateCinematicTimelineActorEmoteStep(
                  _project(a),
                  cinematicId: a.id,
                  stepId: step.id,
                  actorId: id,
                ).cinematic,
        ),
      ),
    if (isCinematicTimelineActorFacingStep(step))
      StudioSelect(
        label: 'Direction',
        value: cinematicTimelineActorFacingDirectionOf(step)?.name,
        options: const {
          'up': 'Haut',
          'down': 'Bas',
          'left': 'Gauche',
          'right': 'Droite',
        },
        onChanged: (value) => _edit(
          asset,
          (a) => updateCinematicTimelineActorFacingStep(
            _project(a),
            cinematicId: a.id,
            stepId: step.id,
            direction: CinematicTimelineActorFacingDirection.values.byName(
              value,
            ),
          ).cinematic,
        ),
      ),
    if (isCinematicTimelineActorMoveStep(step) ||
        isCinematicTimelineActorJumpStep(step))
      ..._moveFields(asset, step),
    if (isCinematicTimelineActorEmoteStep(step))
      StudioSelect(
        label: 'Émotion',
        value: cinematicTimelineActorEmoteEmoteIdOf(step),
        options: {
          for (final emote in cinematicEmoteCatalog) emote.id: emote.label,
        },
        onChanged: (id) => _edit(
          asset,
          (a) => updateCinematicTimelineActorEmoteStep(
            _project(a),
            cinematicId: a.id,
            stepId: step.id,
            emoteId: id,
          ).cinematic,
        ),
      ),
    if (isCinematicTimelineBasicBlockStep(step) &&
        step.kind == CinematicTimelineStepKind.fade)
      StudioSelect(
        label: 'Fondu',
        value: step.metadata[cinematicTimelineFadeModeMetadataKey],
        options: const {
          'fadeIn': 'Révéler la scène',
          'fadeOut': 'Passer au noir',
        },
        onChanged: (value) => _edit(
          asset,
          (a) => updateCinematicTimelineBasicBlockStep(
            _project(a),
            cinematicId: a.id,
            stepId: step.id,
            fadeMode: CinematicTimelineFadeMode.values.byName(value),
          ).cinematic,
        ),
      ),
    if (isCinematicTimelineBasicBlockStep(step) &&
        step.kind == CinematicTimelineStepKind.camera)
      ..._cameraFields(asset, step),
    if (isCinematicTimelineCommandStep(step)) ..._commandFields(asset, step),
    if (step.kind == CinematicTimelineStepKind.actorAnimation)
      ..._animationFields(asset, step),
    const Text(
      'Les pistes organisent une lecture séquentielle. Déplacer un bloc change son ordre de lecture.',
    ),
  ];

  List<Widget> _moveFields(CinematicAsset asset, CinematicTimelineStep step) {
    final jump = isCinematicTimelineActorJumpStep(step);
    final path = asset.stageContext?.manualPaths
        .where((p) => p.ownerActorMoveStepId == step.id)
        .firstOrNull;
    return [
      StudioSelect(
        label: 'Destination',
        value: step.targetId,
        options: {
          for (final target in asset.movementTargets)
            target.targetId: '${target.label} · ${target.targetId}',
        },
        onChanged: (id) =>
            _edit(asset, (a) => _updateMotion(a, step, targetId: id)),
      ),
      const Text(
        'Une nouvelle destination choisie sur la carte est propre à cette étape ; les cibles partagées restent intactes.',
      ),
      StudioButton(
        label: 'Choisir la destination',
        secondary: true,
        icon: Icons.my_location,
        onPressed: model == null
            ? null
            : () => _mode(CinematicMapMode.destination),
      ),
      if (!jump)
        StudioSelect(
          label: 'Allure',
          value: cinematicTimelineActorMovementModeOf(step)?.name,
          options: const {'walk': 'Marcher', 'run': 'Courir'},
          onChanged: (value) => _edit(
            asset,
            (a) => updateCinematicTimelineActorMoveStep(
              _project(a),
              cinematicId: a.id,
              stepId: step.id,
              movementMode: CinematicTimelineActorMovementMode.values.byName(
                value,
              ),
            ).cinematic,
          ),
        ),
      StudioSelect(
        label: 'Orientation pendant le déplacement',
        value: cinematicTimelineActorFacingModeOf(step)?.name,
        options: const {
          'followMovement': 'Suivre le déplacement',
          'preserve': 'Conserver l’orientation',
        },
        onChanged: (value) => _edit(
          asset,
          (a) => _updateMotion(
            a,
            step,
            facingMode: CinematicTimelineActorFacingMode.values.byName(value),
          ),
        ),
      ),
      if (jump)
        StudioCommitField(
          key: ValueKey('jump-height-${step.id}'),
          label: 'Hauteur (cases)',
          alwaysCommit: true,
          value: '${cinematicTimelineActorJumpHeightCellsOf(step)}',
          tryCommit: (text) {
            const error =
                'La hauteur doit être supérieure à 0 et au plus égale à 4 cases.';
            final height = double.tryParse(text);
            if (height == null ||
                !height.isFinite ||
                height <= 0 ||
                height > cinematicTimelineActorJumpMaximumHeightCells) {
              view.error = error;
              changed();
              return false;
            }
            final accepted = _edit(
              asset,
              (a) => updateCinematicTimelineActorJumpStep(
                _project(a),
                cinematicId: a.id,
                stepId: step.id,
                heightCells: height,
              ).cinematic,
            );
            if (accepted && view.error == error) {
              view.error = null;
              changed();
            }
            return accepted;
          },
        ),
      if (!jump)
        StudioButton(
          label: 'Ajouter un point de trajet',
          secondary: true,
          icon: Icons.route,
          onPressed: model == null ? null : () => _mode(CinematicMapMode.path),
        ),
      if (!jump && path != null) ...[
        const Text('Points du trajet — dans l’ordre de passage'),
        for (var index = 0; index < path.waypointStagePointIds.length; index++)
          _waypoint(asset, step, path, index),
      ],
    ];
  }

  CinematicAsset _updateMotion(
    CinematicAsset asset,
    CinematicTimelineStep step, {
    String? targetId,
    CinematicTimelineActorFacingMode? facingMode,
  }) => isCinematicTimelineActorJumpStep(step)
      ? updateCinematicTimelineActorJumpStep(
          _project(asset),
          cinematicId: asset.id,
          stepId: step.id,
          targetId: targetId,
          facingMode: facingMode,
        ).cinematic
      : updateCinematicTimelineActorMoveStep(
          _project(asset),
          cinematicId: asset.id,
          stepId: step.id,
          targetId: targetId,
          facingMode: facingMode,
        ).cinematic;

  Widget _waypoint(
    CinematicAsset asset,
    CinematicTimelineStep step,
    CinematicManualPath path,
    int index,
  ) {
    final id = path.waypointStagePointIds[index];
    final point = asset.stageContext?.stagePoints
        .where((p) => p.id == id)
        .firstOrNull;
    return Row(
      children: [
        Expanded(child: Text('${index + 1}. ${point?.label ?? id}')),
        StudioTool(
          label: 'Monter le point ${index + 1}',
          icon: Icons.arrow_upward,
          onPressed: index == 0
              ? null
              : () {
                  final ids = List<String>.of(path.waypointStagePointIds);
                  ids.insert(index - 1, ids.removeAt(index));
                  controller.setManualPath(step.id, ids);
                },
        ),
        StudioTool(
          label: 'Retirer le point ${index + 1}',
          icon: Icons.close,
          onPressed: () {
            final ids = List<String>.of(path.waypointStagePointIds)
              ..removeAt(index);
            controller.setManualPath(step.id, ids);
          },
        ),
      ],
    );
  }
}
