import 'package:meta/meta.dart' show immutable;

import '../models/project_manifest.dart';

enum CharacterStudioReferenceTargetKind {
  character,
  portraitState,
  customAnimationDefinition,
}

enum CharacterStudioReferenceSourceKind {
  defaultPlayer,
  newGameAvatar,
  trainer,
  cinematicAppearance,
  characterPortrait,
  characterCustomAnimation,
}

@immutable
final class CharacterStudioReference {
  const CharacterStudioReference({
    required this.targetKind,
    required this.targetId,
    required this.sourceKind,
    required this.sourceId,
    required this.path,
  });

  final CharacterStudioReferenceTargetKind targetKind;
  final String targetId;
  final CharacterStudioReferenceSourceKind sourceKind;
  final String sourceId;
  final String path;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterStudioReference &&
          other.targetKind == targetKind &&
          other.targetId == targetId &&
          other.sourceKind == sourceKind &&
          other.sourceId == sourceId &&
          other.path == path;

  @override
  int get hashCode =>
      Object.hash(targetKind, targetId, sourceKind, sourceId, path);
}

@immutable
final class CharacterStudioReferenceIndex {
  CharacterStudioReferenceIndex({
    required List<CharacterStudioReference> references,
  }) : references = List<CharacterStudioReference>.unmodifiable(references);

  final List<CharacterStudioReference> references;

  List<CharacterStudioReference> referencesTo(
    CharacterStudioReferenceTargetKind targetKind,
    String targetId,
  ) {
    return List<CharacterStudioReference>.unmodifiable(
      references.where(
        (reference) =>
            reference.targetKind == targetKind &&
            reference.targetId == targetId,
      ),
    );
  }
}

CharacterStudioReferenceIndex buildCharacterStudioReferenceIndex(
  ProjectManifest manifest,
) {
  final references = <CharacterStudioReference>[];
  final defaultPlayerId = manifest.settings.defaultPlayerCharacterId?.trim();
  if (defaultPlayerId != null && defaultPlayerId.isNotEmpty) {
    references.add(
      CharacterStudioReference(
        targetKind: CharacterStudioReferenceTargetKind.character,
        targetId: defaultPlayerId,
        sourceKind: CharacterStudioReferenceSourceKind.defaultPlayer,
        sourceId: 'project',
        path: r'$.settings.defaultPlayerCharacterId',
      ),
    );
  }

  for (
    var index = 0;
    index < manifest.newGame.playerAvatarCharacterIds.length;
    index++
  ) {
    final characterId = manifest.newGame.playerAvatarCharacterIds[index];
    references.add(
      CharacterStudioReference(
        targetKind: CharacterStudioReferenceTargetKind.character,
        targetId: characterId,
        sourceKind: CharacterStudioReferenceSourceKind.newGameAvatar,
        sourceId: 'newGame',
        path:
            r'$.newGame.playerAvatarCharacterIds['
            '$index]',
      ),
    );
  }

  for (
    var trainerIndex = 0;
    trainerIndex < manifest.trainers.length;
    trainerIndex++
  ) {
    final trainer = manifest.trainers[trainerIndex];
    final characterId = trainer.characterId?.trim();
    if (characterId == null || characterId.isEmpty) {
      continue;
    }
    references.add(
      CharacterStudioReference(
        targetKind: CharacterStudioReferenceTargetKind.character,
        targetId: characterId,
        sourceKind: CharacterStudioReferenceSourceKind.trainer,
        sourceId: trainer.id,
        path:
            r'$.trainers['
            '$trainerIndex].characterId',
      ),
    );
  }

  for (
    var cinematicIndex = 0;
    cinematicIndex < manifest.cinematics.length;
    cinematicIndex++
  ) {
    final cinematic = manifest.cinematics[cinematicIndex];
    final bindings =
        cinematic.stageContext?.actorAppearanceBindings ?? const [];
    for (var bindingIndex = 0; bindingIndex < bindings.length; bindingIndex++) {
      final binding = bindings[bindingIndex];
      references.add(
        CharacterStudioReference(
          targetKind: CharacterStudioReferenceTargetKind.character,
          targetId: binding.characterId,
          sourceKind: CharacterStudioReferenceSourceKind.cinematicAppearance,
          sourceId: cinematic.id,
          path:
              r'$.cinematics['
              '$cinematicIndex].stageContext.actorAppearanceBindings['
              '$bindingIndex].characterId',
        ),
      );
    }
  }

  for (
    var characterIndex = 0;
    characterIndex < manifest.characters.length;
    characterIndex++
  ) {
    final character = manifest.characters[characterIndex];
    for (
      var portraitIndex = 0;
      portraitIndex < character.portraits.length;
      portraitIndex++
    ) {
      final portrait = character.portraits[portraitIndex];
      references.add(
        CharacterStudioReference(
          targetKind: CharacterStudioReferenceTargetKind.portraitState,
          targetId: portrait.portraitStateId,
          sourceKind: CharacterStudioReferenceSourceKind.characterPortrait,
          sourceId: character.id,
          path:
              r'$.characters['
              '$characterIndex].portraits[$portraitIndex].portraitStateId',
        ),
      );
    }
    for (
      var animationIndex = 0;
      animationIndex < character.customAnimations.length;
      animationIndex++
    ) {
      final animation = character.customAnimations[animationIndex];
      references.add(
        CharacterStudioReference(
          targetKind:
              CharacterStudioReferenceTargetKind.customAnimationDefinition,
          targetId: animation.definitionId,
          sourceKind:
              CharacterStudioReferenceSourceKind.characterCustomAnimation,
          sourceId: character.id,
          path:
              r'$.characters['
              '$characterIndex].customAnimations['
              '$animationIndex].definitionId',
        ),
      );
    }
  }

  references.sort(_compareReferences);
  return CharacterStudioReferenceIndex(references: references);
}

int _compareReferences(
  CharacterStudioReference left,
  CharacterStudioReference right,
) {
  final targetKind = left.targetKind.index.compareTo(right.targetKind.index);
  if (targetKind != 0) return targetKind;
  final targetId = left.targetId.compareTo(right.targetId);
  if (targetId != 0) return targetId;
  final path = left.path.compareTo(right.path);
  if (path != 0) return path;
  final sourceKind = left.sourceKind.index.compareTo(right.sourceKind.index);
  if (sourceKind != 0) return sourceKind;
  return left.sourceId.compareTo(right.sourceId);
}
