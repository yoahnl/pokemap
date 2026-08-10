import 'package:map_core/map_core.dart';

import '../authoring_api/character_studio_authoring_gateway.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';

class CreateCharacterUseCase {
  CreateCharacterUseCase(this._authoring);

  final CharacterStudioAuthoringGateway _authoring;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    required String tilesetId,
    int frameWidth = 1,
    int frameHeight = 2,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Character name cannot be empty');
    }
    final trimmedTilesetId = tilesetId.trim();
    if (trimmedTilesetId.isEmpty) {
      throw const EditorValidationException(
        'Character tilesetId cannot be empty',
      );
    }
    return _authoring.apply(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'characterStudio.character.create',
      parameters: <String, Object?>{
        'name': trimmedName,
        'tilesetId': trimmedTilesetId,
        'frameWidth': frameWidth.clamp(1, 9999),
        'frameHeight': frameHeight.clamp(1, 9999),
      },
      operationLabel: 'character_create',
    );
  }
}

class UpdateCharacterUseCase {
  UpdateCharacterUseCase(this._authoring);

  final CharacterStudioAuthoringGateway _authoring;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String characterId,
    String? name,
    String? tilesetId,
    int? frameWidth,
    int? frameHeight,
    List<String>? tags,
  }) async {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isEmpty) {
      throw const EditorValidationException('Character name cannot be empty');
    }
    final trimmedTilesetId = tilesetId?.trim();
    if (trimmedTilesetId != null && trimmedTilesetId.isEmpty) {
      throw const EditorValidationException(
        'Character tilesetId cannot be empty',
      );
    }
    return _authoring.apply(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'characterStudio.character.update',
      parameters: <String, Object?>{
        'characterId': characterId,
        'name': ?trimmedName,
        'tilesetId': ?trimmedTilesetId,
        if (frameWidth != null) 'frameWidth': frameWidth.clamp(1, 9999),
        if (frameHeight != null) 'frameHeight': frameHeight.clamp(1, 9999),
        'tags': ?tags,
      },
      operationLabel: 'character_update_$characterId',
    );
  }
}

class DeleteCharacterUseCase {
  DeleteCharacterUseCase(this._authoring);

  final CharacterStudioAuthoringGateway _authoring;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String characterId,
  }) {
    return _authoring.apply(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'characterStudio.character.delete',
      parameters: <String, Object?>{
        'characterId': characterId,
        'resolution': 'clear',
      },
      operationLabel: 'character_delete_$characterId',
      requiresConfirmation: true,
    );
  }
}

class UpsertCharacterAnimationUseCase {
  UpsertCharacterAnimationUseCase(this._authoring);

  final CharacterStudioAuthoringGateway _authoring;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String characterId,
    required CharacterAnimationState animState,
    required EntityFacing direction,
    required List<CharacterAnimationFrame> frames,
  }) {
    return _authoring.apply(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'characterStudio.animationClip.upsert',
      parameters: <String, Object?>{
        'characterId': characterId,
        'kind': 'system',
        'state': animState.name,
        'direction': direction.name,
        'frames': <Object?>[for (final frame in frames) frame.toJson()],
      },
      operationLabel:
          'animation_upsert_${characterId}_${animState.name}_${direction.name}',
    );
  }
}

class SetPlayerCharacterUseCase {
  SetPlayerCharacterUseCase(this._authoring);

  final CharacterStudioAuthoringGateway _authoring;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String? characterId,
  }) {
    final trimmedId = characterId?.trim();
    return _authoring.apply(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'characterStudio.character.setDefault',
      parameters: <String, Object?>{
        'characterId': trimmedId == null || trimmedId.isEmpty
            ? null
            : trimmedId,
      },
      operationLabel: 'character_set_default',
    );
  }
}
