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
      final accepted = controller.updateAnimationFromInspector(
        asset.id,
        view.inputs,
        step.id,
        cinematicAnimationCommandWith(command, clip: clip, playback: playback),
      );
      if (controller.activeId == asset.id) changed();
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
        onChanged: (value) =>
            update(playback: cinematicAnimationPlaybackFor(value)),
      ),
      if (command.playback.kind != CharacterCustomAnimationPlaybackKind.once)
        CinematicCommitField(
          inputs: controller.inputsFor(asset.id),
          changed: changed,
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
            final accepted = controller.commitAnimationCount(
              asset.id,
              view.inputs,
              step.id,
              command,
              text,
            );
            changed();
            return accepted;
          },
        ),
      const Text(
        'La direction vient du clip choisi. Les règles de remplacement et de repli existantes sont conservées.',
      ),
    ];
  }
}
