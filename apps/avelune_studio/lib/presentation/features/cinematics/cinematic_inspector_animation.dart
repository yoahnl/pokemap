part of 'cinematic_inspector.dart';

extension CinematicInspectorAnimation on CinematicInspector {
  List<Widget> _animationFields(
    CinematicAsset asset,
    CinematicTimelineStep step,
  ) {
    final command = cinematicCharacterCustomAnimationCommandOf(step);
    if (command == null) {
      return [const Text('Animation avancée conservée sans conversion.')];
    }
    final characterId =
        model?.actors.actorById(command.actorId)?.appearance.characterId ??
        asset.stageContext?.actorAppearanceBindings
            .where((b) => b.actorId == command.actorId)
            .firstOrNull
            ?.characterId;
    final clips =
        controller.project.characters
            .where((c) => c.id == characterId)
            .firstOrNull
            ?.customAnimations ??
        <CharacterCustomAnimationClip>[];
    final current = clips.indexWhere(
      (c) =>
          c.definitionId == command.definitionId &&
          c.direction == command.direction,
    );
    bool update({
      CharacterCustomAnimationClip? clip,
      CharacterCustomAnimationPlayback? playback,
    }) {
      if (controller.activeId != asset.id) return false;
      final accepted = controller.updateAnimation(
        step.id,
        CharacterCustomAnimationRuntimeCommand(
          actorId: command.actorId,
          definitionId: clip?.definitionId ?? command.definitionId,
          direction: clip == null ? command.direction : clip.direction,
          playback: playback ?? command.playback,
          interruptionPolicy: command.interruptionPolicy,
          fallbackPolicy: command.fallbackPolicy,
        ),
      );
      if (!accepted) {
        view.error = view.inspectorError = controller.error;
      } else if (view.error == view.inspectorError) {
        view.error = view.inspectorError = null;
      }
      changed();
      return accepted;
    }

    return [
      StudioSelect(
        label: 'Animation du personnage',
        value: current < 0 ? 'retained' : '$current',
        options: {
          if (current < 0) 'retained': '${command.definitionId} · conservée',
          for (var i = 0; i < clips.length; i++)
            '$i':
                '${controller.project.characterStudioCatalog.customAnimationDefinitions.where((d) => d.id == clips[i].definitionId).firstOrNull?.displayName ?? clips[i].definitionId}${clips[i].direction == null ? '' : ' · ${clips[i].direction!.name}'}',
        },
        onChanged: (id) {
          if (id != 'retained') update(clip: clips[int.parse(id)]);
        },
      ),
      StudioSelect(
        label: 'Lecture de l’animation',
        value: command.playback.kind.name,
        options: const {
          'once': 'Une fois',
          'repeatCount': 'Nombre de répétitions',
          'forDuration': 'Pendant une durée',
        },
        onChanged: (value) => update(
          playback: switch (value) {
            'repeatCount' => CharacterCustomAnimationPlayback.repeatCount(2),
            'forDuration' => CharacterCustomAnimationPlayback.forDuration(1000),
            _ => CharacterCustomAnimationPlayback.once(),
          },
        ),
      ),
      if (command.playback.kind != CharacterCustomAnimationPlaybackKind.once)
        StudioCommitField(
          key: ValueKey(
            'animation-count-${asset.id}-${step.id}-${command.playback.kind.name}',
          ),
          label:
              command.playback.kind ==
                  CharacterCustomAnimationPlaybackKind.repeatCount
              ? 'Répétitions'
              : 'Durée de l’animation (ms)',
          value:
              '${command.playback.repeatCount ?? command.playback.durationMs}',
          alwaysCommit: true,
          tryCommit: (text) {
            final number = int.tryParse(text);
            if (number == null || number <= 0) {
              view.error = view.inspectorError =
                  'Saisissez une valeur entière strictement positive.';
              changed();
              return false;
            }
            return update(
              playback:
                  command.playback.kind ==
                      CharacterCustomAnimationPlaybackKind.repeatCount
                  ? CharacterCustomAnimationPlayback.repeatCount(number)
                  : CharacterCustomAnimationPlayback.forDuration(number),
            );
          },
        ),
      const Text(
        'La direction vient du clip choisi. Les règles de remplacement et de repli existantes sont conservées.',
      ),
    ];
  }
}
