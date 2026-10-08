part of 'studio_map_resources.dart';

extension StudioCinematicSpatialPreview on StudioMapResources {
  Future<CinematicSpatialPreview> _cinematicSpatialPreview(
    MapData map,
    CinematicActorDisplayPreviewModel actors,
  ) async {
    final owner = Object();
    final characters = <String, ProjectCharacterEntry>{
      for (final actor in actors.actors)
        for (final character in manifest.characters)
          if (character.id == actor.appearance.characterId)
            actor.actorId: character,
    };
    final ids = characters.values.expand(characterResourceIds).toSet();
    final copies = <String, ui.Image>{};
    final textures = <String, SpatialActorTexture>{};
    retain(owner, ids);
    try {
      await Future.wait(ids.map((id) => store.request(id)));
      if (_disposed) throw StateError('Le projet est fermé.');
      await initializeSpatialRenderer();
      for (final id in ids) {
        final image = images[id];
        if (image == null) {
          throw StateError('Image de personnage absente : $id');
        }
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        final bounds = ui.Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        );
        image.drawImageRect(canvas, bounds, bounds, ui.Paint());
        final picture = recorder.endRecording();
        try {
          copies[id] = await picture.toImage(image.width, image.height);
        } finally {
          picture.dispose();
        }
        textures[id] = await SpatialActorTexture.fromImage(copies[id]!);
      }
      final resolver = CharacterAnimationSourceResolver();
      return CinematicSpatialPreview(
        (asset, plan, frame, timeMs) {
          final result = <String, SpatialActorVisual>{};
          for (final actor in actors.actors) {
            final character = characters[actor.actorId];
            if (character == null || !actor.position.isResolved) continue;
            final pose = frame?.actorPoseById(actor.actorId);
            if (pose != null && !pose.hasPosition) continue;
            final x = pose?.x ?? actor.position.x!.toDouble();
            final z = pose?.y ?? actor.position.y!.toDouble();
            final facing =
                EntityFacing.values
                    .where(
                      (value) =>
                          value.name == (pose?.facing ?? actor.direction).name,
                    )
                    .firstOrNull ??
                EntityFacing.south;
            final step = asset.timeline.steps
                .where((step) => step.id == pose?.activeStepId)
                .firstOrNull;
            final timeline = plan?.timelineItems
                .where((item) => item.stepId == step?.id)
                .firstOrNull;
            final moving = pose?.isInterpolated ?? false;
            final state = !moving
                ? CharacterAnimationState.idle
                : step != null &&
                      cinematicTimelineActorMovementModeOf(step) ==
                          CinematicTimelineActorMovementMode.run
                ? CharacterAnimationState.run
                : CharacterAnimationState.walk;
            final active = frame?.activeCharacterAnimations
                .where(
                  (animation) => animation.command.actorId == actor.actorId,
                )
                .firstOrNull;
            final custom = character.customAnimations
                .where(
                  (clip) =>
                      clip.definitionId == active?.command.definitionId &&
                      (clip.direction == null ||
                          clip.direction ==
                              (active?.command.direction ?? facing)),
                )
                .firstOrNull;
            ResolvedCharacterAnimationFrameSource? source;
            if (custom != null && custom.frames.isNotEmpty) {
              source = resolver.resolveCustomFrame(
                character: character,
                clip: custom,
                frame: studioCinematicCharacterFrame(
                  custom.frames,
                  active!.elapsedMs,
                  loop: custom.loop,
                ),
                availableImageIds: textures.keys.toSet(),
              );
            } else {
              final preferredStates = [
                state,
                if (state == CharacterAnimationState.run)
                  CharacterAnimationState.walk,
                if (state != CharacterAnimationState.idle)
                  CharacterAnimationState.idle,
              ];
              final animation = preferredStates
                  .expand(
                    (preferred) => character.animations.where(
                      (clip) =>
                          clip.direction == facing &&
                          clip.state == preferred &&
                          clip.frames.isNotEmpty,
                    ),
                  )
                  .firstOrNull;
              if (animation == null || animation.frames.isEmpty) continue;
              source = resolver.resolveFrame(
                character: character,
                animation: animation,
                frame: studioCinematicCharacterFrame(
                  animation.frames,
                  moving && timeline != null ? timeMs - timeline.startMs : 0,
                  loop: animation.loop,
                ),
                tileWidth: manifest.settings.tileWidth,
                tileHeight: manifest.settings.tileHeight,
                availableImageIds: textures.keys.toSet(),
              );
            }
            if (source == null) continue;
            final image = copies[source.imageId];
            if (image == null ||
                source.sourceRect.left < 0 ||
                source.sourceRect.top < 0 ||
                source.sourceRect.right > image.width ||
                source.sourceRect.bottom > image.height) {
              continue;
            }
            result[actor.bindingKind == CinematicActorBindingKind.player
                ? 'hero'
                : 'cinematic:${actor.actorId}'] = SpatialActorVisual(
              x: x,
              y: map.spatialScene!.worldHeightAt(x, z),
              z: z,
              texture: textures[source.imageId]!,
              frame: source.sourceRect,
            );
          }
          return result;
        },
        () {
          for (final image in copies.values) {
            image.dispose();
          }
          release(owner);
        },
      );
    } catch (_) {
      for (final image in copies.values) {
        image.dispose();
      }
      release(owner);
      rethrow;
    }
  }
}

CharacterAnimationFrame studioCinematicCharacterFrame(
  List<CharacterAnimationFrame> frames,
  int elapsedMs, {
  required bool loop,
}) {
  final duration = frames.fold(0, (sum, frame) => sum + frame.durationMs);
  if (duration <= 0) return frames.first;
  var cursor = loop
      ? elapsedMs.clamp(0, 1 << 40) % duration
      : elapsedMs.clamp(0, duration - 1);
  for (final frame in frames) {
    if (cursor < frame.durationMs) return frame;
    cursor -= frame.durationMs;
  }
  return frames.last;
}
