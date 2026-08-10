import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/character_studio_authoring_gateway.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/ports/project_workspace.dart';
import 'character_animation_matrix_model.dart';

class SaveCharacterAnimationClipUseCase {
  SaveCharacterAnimationClipUseCase(this._authoring);

  final CharacterStudioAuthoringGateway _authoring;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String characterId,
    required CharacterAnimationSlotKey slotKey,
    required String? sourceAssetId,
    required List<CharacterAnimationFrame> frames,
    required bool loop,
  }) {
    _validateFrames(frames);
    final source = sourceAssetId?.trim();
    if (slotKey.kind == CharacterAnimationDefinitionKind.custom &&
        (source == null || source.isEmpty)) {
      throw const EditorValidationException(
        'Custom animation clips require a portable source asset',
      );
    }
    return _authoring.apply(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'characterStudio.animationClip.upsert',
      parameters: <String, Object?>{
        'characterId': characterId,
        ...slotKey.actionParameters,
        'sourceAssetId': source,
        'frames': <Object?>[for (final frame in frames) frame.toJson()],
        'loop': loop,
      },
      operationLabel: 'animation_clip_${characterId}_${slotKey.stableId}',
    );
  }
}

class DeleteCharacterAnimationClipUseCase {
  DeleteCharacterAnimationClipUseCase(this._authoring);

  final CharacterStudioAuthoringGateway _authoring;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String characterId,
    required CharacterAnimationSlotKey slotKey,
  }) {
    return _authoring.apply(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'characterStudio.animationClip.delete',
      parameters: <String, Object?>{
        'characterId': characterId,
        ...slotKey.actionParameters,
      },
      operationLabel:
          'animation_clip_delete_${characterId}_${slotKey.stableId}',
      requiresConfirmation: true,
    );
  }
}

void _validateFrames(List<CharacterAnimationFrame> frames) {
  for (final frame in frames) {
    final source = frame.source;
    if (source.x < 0 ||
        source.y < 0 ||
        source.width <= 0 ||
        source.height <= 0 ||
        frame.durationMs <= 0) {
      throw const EditorValidationException(
        'Animation frames require valid rectangles and positive durations',
      );
    }
  }
}
