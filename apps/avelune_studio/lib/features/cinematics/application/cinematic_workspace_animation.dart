part of 'cinematic_workspace_controller.dart';

extension CinematicWorkspaceAnimation on CinematicWorkspaceController {
  void _validateAnimation(
    CinematicAsset asset,
    CharacterCustomAnimationRuntimeCommand command,
  ) {
    if (!asset.requiredActors.any((a) => a.actorId == command.actorId)) {
      throw ArgumentError('Sélectionnez un acteur de cette cinématique.');
    }
    final definition = project.characterStudioCatalog.customAnimationDefinitions
        .where((d) => d.id == command.definitionId)
        .firstOrNull;
    if (definition == null ||
        (definition.mode == CharacterCustomAnimationMode.directional) !=
            (command.direction != null)) {
      throw ArgumentError(
        'Animation ou direction indisponible dans le catalogue.',
      );
    }
  }

  String? addAnimation(
    CharacterCustomAnimationRuntimeCommand command, {
    String? afterStepId,
  }) => _added((asset) {
    _validateAnimation(asset, command);
    final steps = asset.timeline.steps;
    final index = afterStepId == null
        ? steps.length
        : steps.indexWhere((s) => s.id == afterStepId) + 1;
    if (afterStepId != null && index == 0) {
      throw ArgumentError('Bloc de départ introuvable.');
    }
    return pasteCinematicTimelineSteps(
      asset,
      clipboard: CinematicTimelineClipboard(
        steps: [
          buildCinematicCharacterCustomAnimationStep(
            id: 'animation',
            command: command,
          ),
        ],
      ),
      insertionIndex: index,
    ).cinematic;
  });

  bool updateAnimation(
    String stepId,
    CharacterCustomAnimationRuntimeCommand command,
  ) => edit((asset) {
    _validateAnimation(asset, command);
    final old = asset.timeline.steps.firstWhere((s) => s.id == stepId);
    if (cinematicCharacterCustomAnimationCommandOf(old) == null) {
      throw ArgumentError(
        'Cette animation avancée doit être conservée sans conversion.',
      );
    }
    final next = buildCinematicCharacterCustomAnimationStep(
      id: stepId,
      command: command,
      label: old.label,
    );
    final json = {...old.toJson(), ...next.toJson()};
    json['metadata'] = {
      for (final entry in old.metadata.entries)
        if (!{
          cinematicCharacterAnimationDefinitionIdMetadataKey,
          cinematicCharacterAnimationDirectionMetadataKey,
          cinematicCharacterAnimationPlaybackKindMetadataKey,
          cinematicCharacterAnimationRepeatCountMetadataKey,
          cinematicCharacterAnimationDurationMetadataKey,
          cinematicCharacterAnimationInterruptionMetadataKey,
          cinematicCharacterAnimationFallbackMetadataKey,
        }.contains(entry.key))
          entry.key: entry.value,
      ...next.metadata,
    };
    json['durationMs'] = next.durationMs;
    return asset.copyWith(
      timeline: CinematicTimeline(
        steps: [
          for (final s in asset.timeline.steps)
            if (s.id == stepId) CinematicTimelineStep.fromJson(json) else s,
        ],
      ),
    );
  });
}
