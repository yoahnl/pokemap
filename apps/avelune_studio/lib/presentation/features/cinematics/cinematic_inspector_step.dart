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
    ..._parallelFields(asset, step),
    if (step.kind == CinematicTimelineStepKind.atmosphere)
      SpatialVisualControls(patch: step.visualSettings!,
        inherited: SpatialVisualPatch.fromScene(camera: SpatialCameraProfile(), atmosphere: SpatialAtmosphereSettings()),
        onChanged: (value) {
          if (value.isEmpty) return;
          _edit(asset, (a) => updateCinematicTimelineCommandStep(a, stepId: step.id, visualSettings: value).cinematic);
        }),
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
    Text(
      asset.timeline.steps.any((step) => step.parallelGroupId != null)
          ? 'Les étapes d’un groupe partent ensemble ; la suite attend la fin du groupe.'
          : 'Les pistes organisent une lecture séquentielle. Déplacer un bloc change son ordre de lecture.',
    ),
  ];

  List<Widget> _parallelFields(
    CinematicAsset asset,
    CinematicTimelineStep step,
  ) {
    final index = asset.timeline.steps.indexWhere(
      (value) => value.id == step.id,
    );
    final joined =
        index > 0 &&
        step.parallelGroupId != null &&
        asset.timeline.steps[index - 1].parallelGroupId == step.parallelGroupId;
    bool edit(CinematicAsset Function(CinematicAsset) change) =>
        _edit(asset, (current) {
          try {
            return change(current);
          } on ArgumentError {
            throw ArgumentError(_parallelEditError);
          }
        });
    return [
      if (step.parallelGroupId != null)
        const StudioBadge('Ensemble', tone: StudioTone.info),
      StudioButton(
        key: ValueKey('cinematic-parallel-join-${step.id}'),
        label: 'En même temps que l’étape précédente',
        secondary: true,
        icon: Icons.link,
        onPressed:
            index <= 0 ||
                joined ||
                step.kind == CinematicTimelineStepKind.marker
            ? null
            : () => edit((current) => _joinParallel(current, step.id)),
      ),
      if (index <= 0)
        const Text(
          'La première étape ne peut pas être rattachée à une étape précédente.',
        ),
      const Text(
        'Les déplacements et sauts d’un même groupe doivent avoir des durées identiques. Les durées ne sont pas ajustées automatiquement.',
      ),
      if (step.parallelGroupId != null) ...[
        Text(
          asset.timeline.steps
              .where((value) => value.parallelGroupId == step.parallelGroupId)
              .map((value) => value.label ?? cinematicActionLabel(value.kind))
              .join(' + '),
        ),
        StudioButton(
          key: ValueKey('cinematic-parallel-dissolve-${step.id}'),
          label: 'Dissocier le groupe',
          secondary: true,
          icon: Icons.link_off,
          onPressed: () =>
              edit((current) => _dissolveParallel(current, step.id)),
        ),
      ],
    ];
  }

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
      ..._relativePointFields(asset, step),
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

  List<Widget> _relativePointFields(
    CinematicAsset asset,
    CinematicTimelineStep step,
  ) {
    final binding = asset.stageContext?.movementTargetBindings
        .where(
          (entry) =>
              entry.targetId == step.targetId &&
              entry.kind == CinematicMovementTargetBindingKind.stagePoint,
        )
        .firstOrNull;
    final path = asset.stageContext?.manualPaths
        .where((entry) => entry.ownerActorMoveStepId == step.id)
        .firstOrNull;
    final ids = {
      if (binding?.sourceId != null) binding!.sourceId!,
      ...?path?.waypointStagePointIds,
    };
    return [
      for (final point
          in asset.stageContext?.stagePoints ?? const <CinematicStagePoint>[])
        if (ids.contains(point.id)) ...[
          Text(point.label),
          StudioSelect(
            key: ValueKey('cinematic-point-origin-${point.id}'),
            label: 'Origine du repère',
            value: point.relativeToActorId ?? '',
            options: {
              '': 'Carte (position absolue)',
              for (final actor in asset.stageContext!.actorBindings)
                if (actor.kind == CinematicActorBindingKind.player || actor.kind == CinematicActorBindingKind.mapEntity)
                actor.actorId:
                    'Départ de ${asset.requiredActors.where((entry) => entry.actorId == actor.actorId).firstOrNull?.label ?? actor.actorId}',
            },
            onChanged: (value) {
              if (value.isNotEmpty && model?.map.spatialScene != null) {
                view.error = 'Les repères relatifs aux acteurs sont disponibles sur les cartes 2D.';
                changed();
                return;
              }
              final origin = value.isEmpty ? null : model?.actorOrigins[value];
              final resolved = model?.resolvedStagePoints
                  .where((entry) => entry.id == point.id)
                  .firstOrNull;
              if (resolved == null || (value.isNotEmpty && origin == null)) {
                view.error =
                    'L’acteur d’origine doit être présent dans l’aperçu.';
                changed();
                return;
              }
              final accepted = controller.setStagePoint(
                CinematicStagePoint(
                  id: point.id,
                  label: point.label,
                  x: resolved.x - (origin?.x ?? 0),
                  y: resolved.y - (origin?.y ?? 0),
                  description: point.description,
                  relativeToActorId: value.isEmpty ? null : value,
                ),
              );
              if (!accepted) view.error = controller.error;
              changed();
            },
          ),
          for (final axis in ['x', 'y'])
            StudioCommitField(
              key: ValueKey('cinematic-point-$axis-${point.id}'),
              label:
                  '${point.relativeToActorId == null ? 'Position' : 'Décalage'} $axis (cases)',
              value: '${axis == 'x' ? point.x : point.y}',
              tryCommit: (text) {
                final value = double.tryParse(text);
                if (value == null || !value.isFinite) return false;
                final accepted = controller.setStagePoint(
                  CinematicStagePoint(
                    id: point.id,
                    label: point.label,
                    x: axis == 'x' ? value : point.x,
                    y: axis == 'y' ? value : point.y,
                    description: point.description,
                    relativeToActorId: point.relativeToActorId,
                  ),
                );
                changed();
                return accepted;
              },
            ),
          if (point.relativeToActorId != null)
            const Text(
              'Décalage depuis la position de l’acteur au début de chaque lecture. Disponible sur les cartes 2D.',
            ),
        ],
    ];
  }

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

CinematicAsset _joinParallel(CinematicAsset asset, String stepId) {
  final steps = asset.timeline.steps;
  final index = steps.indexWhere((step) => step.id == stepId);
  if (index <= 0) throw ArgumentError('Une étape précédente est nécessaire.');
  final previous = steps[index - 1];
  final current = steps[index];
  final groups = {
    if (previous.parallelGroupId != null) previous.parallelGroupId!,
    if (current.parallelGroupId != null) current.parallelGroupId!,
  };
  final ids = {
    previous.id,
    current.id,
    for (final step in steps)
      if (groups.contains(step.parallelGroupId)) step.id,
  };
  final used = steps.map((step) => step.parallelGroupId).toSet();
  var number = 1;
  while (used.contains('parallel_$number')) {
    number++;
  }
  final groupId =
      previous.parallelGroupId ?? current.parallelGroupId ?? 'parallel_$number';
  return setCinematicTimelineParallelGroup(
    asset,
    stepIds: ids,
    parallelGroupId: groupId,
  ).cinematic;
}

CinematicAsset _dissolveParallel(CinematicAsset asset, String stepId) {
  final group = asset.timeline.steps
      .firstWhere((step) => step.id == stepId)
      .parallelGroupId;
  if (group == null) {
    return asset;
  }
  return setCinematicTimelineParallelGroup(
    asset,
    stepIds: {
      for (final step in asset.timeline.steps)
        if (step.parallelGroupId == group) step.id,
    },
    parallelGroupId: null,
  ).cinematic;
}

const _parallelEditError =
    'Impossible de regrouper ces étapes : les déplacements et sauts doivent avoir des durées identiques. Vérifiez aussi les acteurs, la caméra et les canaux audio.';
