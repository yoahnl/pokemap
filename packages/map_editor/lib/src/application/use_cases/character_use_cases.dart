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
    CharacterDeleteResolution resolution = CharacterDeleteResolution.clear,
    String? replacementId,
  }) {
    final trimmedReplacementId = replacementId?.trim();
    if (resolution == CharacterDeleteResolution.replace &&
        (trimmedReplacementId == null || trimmedReplacementId.isEmpty)) {
      throw const EditorValidationException(
        'A replacement character is required',
      );
    }
    return _authoring.apply(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'characterStudio.character.delete',
      parameters: <String, Object?>{
        'characterId': characterId,
        'resolution': resolution.name,
        if (trimmedReplacementId != null && trimmedReplacementId.isNotEmpty)
          'replacementId': trimmedReplacementId,
      },
      operationLabel: 'character_delete_$characterId',
      requiresConfirmation: true,
    );
  }
}

enum CharacterDeleteResolution { replace, clear }

final class CharacterDeleteDependency {
  const CharacterDeleteDependency({
    required this.sourceKind,
    required this.sourceId,
    required this.path,
  });

  final String sourceKind;
  final String sourceId;
  final String path;
}

final class CharacterDeleteReplacementCandidate {
  const CharacterDeleteReplacementCandidate({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

final class CharacterDeletePlan {
  const CharacterDeletePlan({
    required this.characterId,
    required this.requiresResolution,
    required this.dependencies,
    required this.replacementCandidates,
  });

  factory CharacterDeletePlan.fromPreview(Map<String, Object?> preview) {
    final characterId = preview['characterId'];
    if (characterId is! String || characterId.trim().isEmpty) {
      throw const EditorValidationException(
        'Character deletion preview is missing its character',
      );
    }
    return CharacterDeletePlan(
      characterId: characterId,
      requiresResolution: preview['requiresResolution'] == true,
      dependencies: <CharacterDeleteDependency>[
        for (final raw in _previewMaps(preview['dependencies']))
          CharacterDeleteDependency(
            sourceKind: _previewString(raw, 'sourceKind'),
            sourceId: _previewString(raw, 'sourceId'),
            path: _previewString(raw, 'path'),
          ),
      ],
      replacementCandidates: <CharacterDeleteReplacementCandidate>[
        for (final raw in _previewMaps(preview['replacementCandidates']))
          CharacterDeleteReplacementCandidate(
            id: _previewString(raw, 'id'),
            name: _previewString(raw, 'name'),
          ),
      ],
    );
  }

  final String characterId;
  final bool requiresResolution;
  final List<CharacterDeleteDependency> dependencies;
  final List<CharacterDeleteReplacementCandidate> replacementCandidates;
}

class PreviewDeleteCharacterUseCase {
  PreviewDeleteCharacterUseCase(this._authoring);

  final CharacterStudioAuthoringGateway _authoring;

  Future<CharacterDeletePlan> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String characterId,
  }) async {
    final plan = await _authoring.preview(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'characterStudio.character.deletePlan',
      parameters: <String, Object?>{'characterId': characterId},
      operationLabel: 'character_delete_plan_$characterId',
    );
    return CharacterDeletePlan.fromPreview(plan.preview);
  }
}

Iterable<Map<String, Object?>> _previewMaps(Object? value) sync* {
  if (value is! List) return;
  for (final entry in value) {
    if (entry is Map<String, Object?>) {
      yield entry;
    } else if (entry is Map) {
      yield <String, Object?>{
        for (final item in entry.entries)
          if (item.key is String) item.key as String: item.value,
      };
    }
  }
}

String _previewString(Map<String, Object?> value, String key) {
  final result = value[key];
  return result is String ? result : '';
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
