import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/character_studio_authoring_gateway.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/ports/project_workspace.dart';

class CreateAnimationDefinitionUseCase {
  CreateAnimationDefinitionUseCase(this._authoring);

  final CharacterStudioAuthoringGateway _authoring;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String displayName,
    required CharacterCustomAnimationMode mode,
  }) {
    final label = _requiredLabel(displayName);
    return _authoring.apply(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'characterStudio.animationDefinition.create',
      parameters: <String, Object?>{'displayName': label, 'mode': mode.name},
      operationLabel: 'animation_definition_create',
    );
  }
}

class UpdateAnimationDefinitionUseCase {
  UpdateAnimationDefinitionUseCase(this._authoring);

  final CharacterStudioAuthoringGateway _authoring;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String id,
    String? displayName,
    CharacterCustomAnimationMode? mode,
  }) {
    final label = displayName == null ? null : _requiredLabel(displayName);
    if (label == null && mode == null) {
      throw const EditorValidationException(
        'Animation definition update cannot be empty',
      );
    }
    return _authoring.apply(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'characterStudio.animationDefinition.update',
      parameters: <String, Object?>{
        'id': id,
        'displayName': ?label,
        'mode': ?mode?.name,
      },
      operationLabel: 'animation_definition_update_$id',
    );
  }
}

class ReorderAnimationDefinitionsUseCase {
  ReorderAnimationDefinitionsUseCase(this._authoring);

  final CharacterStudioAuthoringGateway _authoring;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required List<String> orderedIds,
  }) {
    return _authoring.apply(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'characterStudio.animationDefinition.reorder',
      parameters: <String, Object?>{'orderedIds': orderedIds},
      operationLabel: 'animation_definition_reorder',
    );
  }
}

enum AnimationDefinitionDeleteResolution { replace, clear }

final class AnimationDefinitionDeleteDependency {
  const AnimationDefinitionDeleteDependency({
    required this.sourceKind,
    required this.sourceId,
    required this.path,
  });

  final String sourceKind;
  final String sourceId;
  final String path;
}

final class AnimationDefinitionReplacementCandidate {
  const AnimationDefinitionReplacementCandidate({
    required this.id,
    required this.displayName,
    required this.mode,
  });

  final String id;
  final String displayName;
  final CharacterCustomAnimationMode mode;
}

final class AnimationDefinitionDeletePlan {
  const AnimationDefinitionDeletePlan({
    required this.animationDefinitionId,
    required this.requiresResolution,
    required this.dependencies,
    required this.replacementCandidates,
  });

  factory AnimationDefinitionDeletePlan.fromPreview(
    Map<String, Object?> preview,
  ) {
    final id = _previewString(preview, 'animationDefinitionId');
    if (id.isEmpty) {
      throw const EditorValidationException(
        'Animation definition deletion preview is missing its definition',
      );
    }
    return AnimationDefinitionDeletePlan(
      animationDefinitionId: id,
      requiresResolution: preview['requiresResolution'] == true,
      dependencies: <AnimationDefinitionDeleteDependency>[
        for (final raw in _previewMaps(preview['dependencies']))
          AnimationDefinitionDeleteDependency(
            sourceKind: _previewString(raw, 'sourceKind'),
            sourceId: _previewString(raw, 'sourceId'),
            path: _previewString(raw, 'path'),
          ),
      ],
      replacementCandidates: <AnimationDefinitionReplacementCandidate>[
        for (final raw in _previewMaps(preview['replacementCandidates']))
          AnimationDefinitionReplacementCandidate(
            id: _previewString(raw, 'id'),
            displayName: _previewString(raw, 'displayName'),
            mode: _mode(_previewString(raw, 'mode')),
          ),
      ],
    );
  }

  final String animationDefinitionId;
  final bool requiresResolution;
  final List<AnimationDefinitionDeleteDependency> dependencies;
  final List<AnimationDefinitionReplacementCandidate> replacementCandidates;
}

class PreviewDeleteAnimationDefinitionUseCase {
  PreviewDeleteAnimationDefinitionUseCase(this._authoring);

  final CharacterStudioAuthoringGateway _authoring;

  Future<AnimationDefinitionDeletePlan> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String id,
  }) async {
    final plan = await _authoring.preview(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'characterStudio.animationDefinition.deletePlan',
      parameters: <String, Object?>{'id': id},
      operationLabel: 'animation_definition_delete_plan_$id',
    );
    return AnimationDefinitionDeletePlan.fromPreview(plan.preview);
  }
}

class DeleteAnimationDefinitionUseCase {
  DeleteAnimationDefinitionUseCase(this._authoring);

  final CharacterStudioAuthoringGateway _authoring;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String id,
    required AnimationDefinitionDeleteResolution resolution,
    String? replacementId,
  }) {
    final replacement = replacementId?.trim();
    if (resolution == AnimationDefinitionDeleteResolution.replace &&
        (replacement == null || replacement.isEmpty)) {
      throw const EditorValidationException(
        'A replacement animation definition is required',
      );
    }
    return _authoring.apply(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'characterStudio.animationDefinition.delete',
      parameters: <String, Object?>{
        'id': id,
        'resolution': resolution.name,
        if (replacement != null && replacement.isNotEmpty)
          'replacementId': replacement,
      },
      operationLabel: 'animation_definition_delete_$id',
      requiresConfirmation: true,
    );
  }
}

String _requiredLabel(String value) {
  final label = value.trim();
  if (label.isEmpty) {
    throw const EditorValidationException(
      'Animation definition name cannot be empty',
    );
  }
  return label;
}

CharacterCustomAnimationMode _mode(String value) {
  return switch (value) {
    'single' => CharacterCustomAnimationMode.single,
    'directional' => CharacterCustomAnimationMode.directional,
    _ => throw const EditorValidationException(
      'Animation definition preview contains an invalid mode',
    ),
  };
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
