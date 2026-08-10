import 'package:meta/meta.dart' show immutable;

import '../models/enums.dart';
import '../models/project_manifest.dart';

enum CharacterStudioReadinessSeverity { warning, error }

enum CharacterStudioReadinessCode {
  requiredCharacterUnknown,
  baseDirectionMissing,
  optionalAnimationDirectionMissing,
  portraitMissing,
  customAnimationMissing,
  customAnimationDirectionMissing,
}

@immutable
final class CharacterStudioReadinessDiagnostic {
  const CharacterStudioReadinessDiagnostic({
    required this.code,
    required this.severity,
    required this.path,
    required this.message,
    this.characterId,
    this.portraitStateId,
    this.animationDefinitionId,
    this.animationState,
    this.direction,
  });

  final CharacterStudioReadinessCode code;
  final CharacterStudioReadinessSeverity severity;
  final String path;
  final String message;
  final String? characterId;
  final String? portraitStateId;
  final String? animationDefinitionId;
  final CharacterAnimationState? animationState;
  final EntityFacing? direction;
}

@immutable
final class CharacterStudioReadinessReport {
  CharacterStudioReadinessReport({
    required List<CharacterStudioReadinessDiagnostic> diagnostics,
  }) : diagnostics = List<CharacterStudioReadinessDiagnostic>.unmodifiable(
         diagnostics,
       );

  final List<CharacterStudioReadinessDiagnostic> diagnostics;

  bool get hasErrors => diagnostics.any(
    (diagnostic) =>
        diagnostic.severity == CharacterStudioReadinessSeverity.error,
  );

  bool get isReady => !hasErrors;

  List<CharacterStudioReadinessDiagnostic> byCode(
    CharacterStudioReadinessCode code,
  ) {
    return List<CharacterStudioReadinessDiagnostic>.unmodifiable(
      diagnostics.where((diagnostic) => diagnostic.code == code),
    );
  }

  List<CharacterStudioReadinessDiagnostic> forCharacter(String characterId) {
    return List<CharacterStudioReadinessDiagnostic>.unmodifiable(
      diagnostics.where((diagnostic) => diagnostic.characterId == characterId),
    );
  }
}

CharacterStudioReadinessReport analyzeCharacterStudioReadiness({
  required ProjectManifest manifest,
  Set<String> requiredCharacterIds = const <String>{},
}) {
  final diagnostics = <CharacterStudioReadinessDiagnostic>[];
  final charactersById = <String, ProjectCharacterEntry>{
    for (final character in manifest.characters) character.id: character,
  };
  final characterIndexes = <String, int>{
    for (var index = 0; index < manifest.characters.length; index++)
      manifest.characters[index].id: index,
  };
  final requiredIds = <String>{
    ...requiredCharacterIds.map((id) => id.trim()).where((id) => id.isNotEmpty),
    if (manifest.settings.defaultPlayerCharacterId?.trim() case final defaultId?
        when defaultId.isNotEmpty)
      defaultId,
  }.toList(growable: false)..sort();

  for (final characterId in requiredIds) {
    final character = charactersById[characterId];
    if (character == null) {
      diagnostics.add(
        CharacterStudioReadinessDiagnostic(
          code: CharacterStudioReadinessCode.requiredCharacterUnknown,
          severity: CharacterStudioReadinessSeverity.error,
          path: r'$.characters',
          message: 'Required character "$characterId" does not exist.',
          characterId: characterId,
        ),
      );
      continue;
    }
    final characterPath =
        r'$.characters['
        '${characterIndexes[characterId]}]';
    for (final direction in EntityFacing.values) {
      if (_hasSystemAnimation(
        character,
        CharacterAnimationState.idle,
        direction,
      )) {
        continue;
      }
      diagnostics.add(
        CharacterStudioReadinessDiagnostic(
          code: CharacterStudioReadinessCode.baseDirectionMissing,
          severity: CharacterStudioReadinessSeverity.error,
          path: '$characterPath.animations',
          message:
              'Character "$characterId" is missing Base '
              '${direction.name}.',
          characterId: characterId,
          animationState: CharacterAnimationState.idle,
          direction: direction,
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
    final characterPath =
        r'$.characters['
        '$characterIndex]';
    _addPortraitDiagnostics(
      diagnostics: diagnostics,
      character: character,
      characterPath: characterPath,
      definitions: manifest.characterStudioCatalog.portraitStates,
    );
    _addOptionalSystemAnimationDiagnostics(
      diagnostics: diagnostics,
      character: character,
      characterPath: characterPath,
    );
    _addCustomAnimationDiagnostics(
      diagnostics: diagnostics,
      character: character,
      characterPath: characterPath,
      definitions: manifest.characterStudioCatalog.customAnimationDefinitions,
    );
  }

  diagnostics.sort(_compareDiagnostics);
  return CharacterStudioReadinessReport(diagnostics: diagnostics);
}

void _addPortraitDiagnostics({
  required List<CharacterStudioReadinessDiagnostic> diagnostics,
  required ProjectCharacterEntry character,
  required String characterPath,
  required List<CharacterPortraitStateDefinition> definitions,
}) {
  for (final definition in definitions) {
    final hasPortrait = character.portraits.any(
      (portrait) =>
          portrait.portraitStateId == definition.id &&
          portrait.assetId.trim().isNotEmpty,
    );
    if (hasPortrait) {
      continue;
    }
    diagnostics.add(
      CharacterStudioReadinessDiagnostic(
        code: CharacterStudioReadinessCode.portraitMissing,
        severity: CharacterStudioReadinessSeverity.warning,
        path: '$characterPath.portraits',
        message:
            'Character "${character.id}" has no portrait for '
            '"${definition.displayName}".',
        characterId: character.id,
        portraitStateId: definition.id,
      ),
    );
  }
}

void _addOptionalSystemAnimationDiagnostics({
  required List<CharacterStudioReadinessDiagnostic> diagnostics,
  required ProjectCharacterEntry character,
  required String characterPath,
}) {
  for (final state in const <CharacterAnimationState>[
    CharacterAnimationState.walk,
    CharacterAnimationState.run,
  ]) {
    final hasAny = character.animations.any(
      (animation) => animation.state == state && animation.frames.isNotEmpty,
    );
    if (!hasAny) {
      continue;
    }
    for (final direction in EntityFacing.values) {
      if (_hasSystemAnimation(character, state, direction)) {
        continue;
      }
      diagnostics.add(
        CharacterStudioReadinessDiagnostic(
          code: CharacterStudioReadinessCode.optionalAnimationDirectionMissing,
          severity: CharacterStudioReadinessSeverity.warning,
          path: '$characterPath.animations',
          message:
              'Character "${character.id}" has partial ${state.name} '
              'coverage and is missing ${direction.name}.',
          characterId: character.id,
          animationState: state,
          direction: direction,
        ),
      );
    }
  }
}

void _addCustomAnimationDiagnostics({
  required List<CharacterStudioReadinessDiagnostic> diagnostics,
  required ProjectCharacterEntry character,
  required String characterPath,
  required List<CharacterCustomAnimationDefinition> definitions,
}) {
  for (final definition in definitions) {
    if (definition.mode == CharacterCustomAnimationMode.single) {
      final hasClip = character.customAnimations.any(
        (clip) =>
            clip.definitionId == definition.id &&
            clip.direction == null &&
            clip.frames.isNotEmpty,
      );
      if (!hasClip) {
        diagnostics.add(
          CharacterStudioReadinessDiagnostic(
            code: CharacterStudioReadinessCode.customAnimationMissing,
            severity: CharacterStudioReadinessSeverity.warning,
            path: '$characterPath.customAnimations',
            message:
                'Character "${character.id}" has no clip for custom '
                'animation "${definition.displayName}".',
            characterId: character.id,
            animationDefinitionId: definition.id,
          ),
        );
      }
      continue;
    }
    for (final direction in EntityFacing.values) {
      final hasClip = character.customAnimations.any(
        (clip) =>
            clip.definitionId == definition.id &&
            clip.direction == direction &&
            clip.frames.isNotEmpty,
      );
      if (hasClip) {
        continue;
      }
      diagnostics.add(
        CharacterStudioReadinessDiagnostic(
          code: CharacterStudioReadinessCode.customAnimationDirectionMissing,
          severity: CharacterStudioReadinessSeverity.warning,
          path: '$characterPath.customAnimations',
          message:
              'Character "${character.id}" is missing ${direction.name} '
              'for custom animation "${definition.displayName}".',
          characterId: character.id,
          animationDefinitionId: definition.id,
          direction: direction,
        ),
      );
    }
  }
}

bool _hasSystemAnimation(
  ProjectCharacterEntry character,
  CharacterAnimationState state,
  EntityFacing direction,
) {
  return character.animations.any(
    (animation) =>
        animation.state == state &&
        animation.direction == direction &&
        animation.frames.isNotEmpty,
  );
}

int _compareDiagnostics(
  CharacterStudioReadinessDiagnostic left,
  CharacterStudioReadinessDiagnostic right,
) {
  final path = left.path.compareTo(right.path);
  if (path != 0) return path;
  final code = left.code.index.compareTo(right.code.index);
  if (code != 0) return code;
  final character = (left.characterId ?? '').compareTo(right.characterId ?? '');
  if (character != 0) return character;
  return (left.direction?.index ?? -1).compareTo(right.direction?.index ?? -1);
}
