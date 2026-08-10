import '../models/cinematic_asset.dart';
import '../models/enums.dart';
import 'character_custom_animation_runtime_contract.dart';

const cinematicCharacterAnimationDefinitionIdMetadataKey =
    'pokemap.characterAnimation.definitionId';
const cinematicCharacterAnimationDirectionMetadataKey =
    'pokemap.characterAnimation.direction';
const cinematicCharacterAnimationPlaybackKindMetadataKey =
    'pokemap.characterAnimation.playbackKind';
const cinematicCharacterAnimationRepeatCountMetadataKey =
    'pokemap.characterAnimation.repeatCount';
const cinematicCharacterAnimationDurationMetadataKey =
    'pokemap.characterAnimation.durationMs';
const cinematicCharacterAnimationInterruptionMetadataKey =
    'pokemap.characterAnimation.interruptionPolicy';
const cinematicCharacterAnimationFallbackMetadataKey =
    'pokemap.characterAnimation.fallbackPolicy';

CinematicTimelineStep buildCinematicCharacterCustomAnimationStep({
  required String id,
  required CharacterCustomAnimationRuntimeCommand command,
  String? label,
}) {
  final playback = command.playback;
  return CinematicTimelineStep(
    id: id,
    kind: CinematicTimelineStepKind.actorAnimation,
    label: label,
    actorId: command.actorId,
    durationMs:
        playback.kind == CharacterCustomAnimationPlaybackKind.forDuration
        ? playback.durationMs
        : null,
    metadata: <String, String>{
      cinematicCharacterAnimationDefinitionIdMetadataKey: command.definitionId,
      if (command.direction != null)
        cinematicCharacterAnimationDirectionMetadataKey:
            command.direction!.name,
      cinematicCharacterAnimationPlaybackKindMetadataKey: playback.kind.name,
      if (playback.repeatCount != null)
        cinematicCharacterAnimationRepeatCountMetadataKey: playback.repeatCount!
            .toString(),
      if (playback.durationMs != null)
        cinematicCharacterAnimationDurationMetadataKey: playback.durationMs!
            .toString(),
      cinematicCharacterAnimationInterruptionMetadataKey:
          command.interruptionPolicy.name,
      cinematicCharacterAnimationFallbackMetadataKey:
          command.fallbackPolicy.name,
    },
  );
}

CharacterCustomAnimationRuntimeCommand?
cinematicCharacterCustomAnimationCommandOf(CinematicTimelineStep step) {
  if (step.kind != CinematicTimelineStepKind.actorAnimation) return null;
  final actorId = step.actorId?.trim();
  final definitionId = step
      .metadata[cinematicCharacterAnimationDefinitionIdMetadataKey]
      ?.trim();
  if (actorId == null ||
      actorId.isEmpty ||
      definitionId == null ||
      definitionId.isEmpty) {
    return null;
  }
  final directionName =
      step.metadata[cinematicCharacterAnimationDirectionMetadataKey];
  final playbackKindName =
      step.metadata[cinematicCharacterAnimationPlaybackKindMetadataKey];
  final interruptionName =
      step.metadata[cinematicCharacterAnimationInterruptionMetadataKey];
  final fallbackName =
      step.metadata[cinematicCharacterAnimationFallbackMetadataKey];
  try {
    final playbackKind = CharacterCustomAnimationPlaybackKind.values.byName(
      playbackKindName ?? CharacterCustomAnimationPlaybackKind.once.name,
    );
    final playback = switch (playbackKind) {
      CharacterCustomAnimationPlaybackKind.once =>
        CharacterCustomAnimationPlayback.once(),
      CharacterCustomAnimationPlaybackKind.repeatCount =>
        CharacterCustomAnimationPlayback.repeatCount(
          int.parse(
            step.metadata[cinematicCharacterAnimationRepeatCountMetadataKey]!,
          ),
        ),
      CharacterCustomAnimationPlaybackKind.forDuration =>
        CharacterCustomAnimationPlayback.forDuration(
          int.parse(
            step.metadata[cinematicCharacterAnimationDurationMetadataKey]!,
          ),
        ),
    };
    return CharacterCustomAnimationRuntimeCommand(
      actorId: actorId,
      definitionId: definitionId,
      direction: directionName == null
          ? null
          : EntityFacing.values.byName(directionName),
      playback: playback,
      interruptionPolicy: interruptionName == null
          ? CharacterCustomAnimationInterruptionPolicy.replaceActive
          : CharacterCustomAnimationInterruptionPolicy.values.byName(
              interruptionName,
            ),
      fallbackPolicy: fallbackName == null
          ? CharacterCustomAnimationFallbackPolicy.fail
          : CharacterCustomAnimationFallbackPolicy.values.byName(fallbackName),
    );
  } on Object {
    return null;
  }
}
