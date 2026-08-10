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
    if (!project.characters.any((character) => character.id == characterId)) {
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
    final digestSuffix = staged.hexDigest.substring(0, 12);
    final suffix = _safeSegment(uniqueSuffix());
    if (suffix.isEmpty) {
      throw const CharacterAnimationSourceImportException(
        'asset_id_suffix_invalid',
        'La source d’animation ne peut pas recevoir un identifiant unique.',
      );
    }
    final assetId =
        'sprite-${_safeSegment(characterId)}-'
        '${_safeSegment(slotKey.stableId)}-$digestSuffix-$suffix';
    final withAsset = await gateway.apply(
      projectRootPath: projectRootPath,
      expectedProject: project,
      actionId: 'characterStudio.asset.import',
      parameters: <String, Object?>{
        'artifactHandle': staged.handle,
        'assetId': assetId,
        'logicalPath':
            'assets/characters/${_safeSegment(characterId)}/animations/'
            '${_safeSegment(slotKey.stableId)}-$digestSuffix-$suffix.png',
        'mediaKind': 'spriteSheet',
      },
      operationLabel: 'animation_source_${characterId}_${slotKey.stableId}',
    );
    return gateway.apply(
      projectRootPath: projectRootPath,
      expectedProject: withAsset,
      actionId: 'characterStudio.animationClip.upsert',
      parameters: <String, Object?>{
        'characterId': characterId,
        ...slotKey.actionParameters,
        'sourceAssetId': assetId,
        'frames': const <Object?>[],
        'loop': loop,
      },
      operationLabel:
          'animation_source_assign_${characterId}_${slotKey.stableId}',
    );
  }
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
