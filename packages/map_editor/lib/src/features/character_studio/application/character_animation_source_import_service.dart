import 'package:map_core/map_core.dart';

import 'character_animation_matrix_model.dart';
import 'character_studio_portrait_import_service.dart';

final class CharacterAnimationSourceImportException implements Exception {
  const CharacterAnimationSourceImportException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() =>
      'CharacterAnimationSourceImportException($code): $message';
}

final class CharacterAnimationSourceImportService {
  const CharacterAnimationSourceImportService({
    required this.gateway,
    this.uniqueSuffix = _uniqueSuffix,
  });

  final CharacterStudioPortraitAssetGateway gateway;
  final String Function() uniqueSuffix;

  Future<ProjectManifest> import({
    required String projectRootPath,
    required ProjectManifest project,
    required String characterId,
    required CharacterAnimationSlotKey slotKey,
    required String sourcePath,
    required bool loop,
  }) async {
    final character = project.characters
        .where((character) => character.id == characterId)
        .firstOrNull;
    if (character == null) {
      throw const CharacterAnimationSourceImportException(
        'character_not_found',
        'Le personnage sélectionné n’existe plus.',
      );
    }
    final staged = await gateway.stageExactFile(
      projectRootPath: projectRootPath,
      sourcePath: sourcePath,
    );
    if (staged.mediaType != 'image/png') {
      throw const CharacterAnimationSourceImportException(
        'source_not_png',
        'La source d’animation doit être une image PNG.',
      );
    }
    final selectedAssetId = _currentAssetId(character, slotKey);
    final currentAssetId =
        selectedAssetId != null &&
            !_assetIsReferencedOutsideAnimationSlot(
              project,
              assetId: selectedAssetId,
              characterId: characterId,
              slotKey: slotKey,
            )
        ? selectedAssetId
        : null;
    final digestSuffix = staged.hexDigest.substring(0, 12);
    final suffix = currentAssetId == null ? _safeSegment(uniqueSuffix()) : null;
    if (suffix != null && suffix.isEmpty) {
      throw const CharacterAnimationSourceImportException(
        'asset_id_suffix_invalid',
        'La source d’animation ne peut pas recevoir un identifiant unique.',
      );
    }
    final assetId =
        currentAssetId ??
        'sprite-${_safeSegment(characterId)}-'
            '${_safeSegment(slotKey.stableId)}-$digestSuffix-${suffix!}';
    return gateway.apply(
      projectRootPath: projectRootPath,
      expectedProject: project,
      actionId: currentAssetId == null
          ? 'characterStudio.asset.import'
          : 'characterStudio.asset.replace',
      parameters: <String, Object?>{
        'artifactHandle': staged.handle,
        'assetId': assetId,
        if (currentAssetId == null) ...<String, Object?>{
          'logicalPath':
              'assets/characters/${_safeSegment(characterId)}/animations/'
              '${_safeSegment(slotKey.stableId)}-$digestSuffix-$suffix.png',
          'mediaKind': 'spriteSheet',
        },
        'binding': <String, Object?>{
          'kind': 'animationClip',
          'characterId': characterId,
          'slotKind': slotKey.actionParameters['kind'],
          for (final entry in slotKey.actionParameters.entries)
            if (entry.key != 'kind') entry.key: entry.value,
          'frames': const <Object?>[],
          'loop': loop,
        },
      },
      operationLabel: 'animation_source_${characterId}_${slotKey.stableId}',
    );
  }
}

bool _assetIsReferencedOutsideAnimationSlot(
  ProjectManifest project, {
  required String assetId,
  required String characterId,
  required CharacterAnimationSlotKey slotKey,
}) {
  for (final character in project.characters) {
    if (character.portraits.any((portrait) => portrait.assetId == assetId)) {
      return true;
    }
    for (final animation in character.animations) {
      if (animation.sourceAssetId != assetId) continue;
      final selected =
          character.id == characterId &&
          slotKey.kind == CharacterAnimationDefinitionKind.system &&
          animation.state == slotKey.systemState &&
          animation.direction == slotKey.direction;
      if (!selected) return true;
    }
    for (final animation in character.customAnimations) {
      if (animation.sourceAssetId != assetId) continue;
      final selected =
          character.id == characterId &&
          slotKey.kind == CharacterAnimationDefinitionKind.custom &&
          animation.definitionId == slotKey.definitionId &&
          animation.direction == slotKey.direction;
      if (!selected) return true;
    }
  }
  return false;
}

String? _currentAssetId(
  ProjectCharacterEntry character,
  CharacterAnimationSlotKey slotKey,
) {
  final value = switch (slotKey.kind) {
    CharacterAnimationDefinitionKind.system =>
      character.animations
          .where(
            (animation) =>
                animation.state == slotKey.systemState &&
                animation.direction == slotKey.direction,
          )
          .firstOrNull
          ?.sourceAssetId,
    CharacterAnimationDefinitionKind.custom =>
      character.customAnimations
          .where(
            (animation) =>
                animation.definitionId == slotKey.definitionId &&
                animation.direction == slotKey.direction,
          )
          .firstOrNull
          ?.sourceAssetId,
  };
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String _uniqueSuffix() {
  return DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(36);
}

String _safeSegment(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9_-]+'),
    '-',
  );
  final compact = normalized.replaceAll(RegExp(r'-+'), '-');
  return compact.replaceAll(RegExp(r'^-|-$'), '');
}
