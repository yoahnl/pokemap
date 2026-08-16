import 'package:meta/meta.dart' show immutable;

import '../models/cinematic_asset.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../read_models/narrative_dependency_index.dart';
import '../validation/validators.dart';
import 'narrative_reference_rewrite.dart';
import 'scene_authoring_operations.dart';

@immutable
sealed class NarrativeAssetMutationResult {
  const NarrativeAssetMutationResult({
    required this.before,
    required this.after,
  });

  final ProjectManifest before;
  final ProjectManifest after;

  bool get isApplicable =>
      this is NarrativeAssetCreated ||
      this is NarrativeAssetUpdated ||
      this is NarrativeAssetDeleted ||
      this is NarrativeDiagnosticSuppressionsUpdated;
}

/// Atomic project-level Narrative Studio metadata mutation.
///
/// It is intentionally distinct from an asset update: diagnostic governance
/// belongs to the project manifest and must not masquerade as a Cinematic.
@immutable
final class NarrativeDiagnosticSuppressionsUpdated
    extends NarrativeAssetMutationResult {
  factory NarrativeDiagnosticSuppressionsUpdated({
    required ProjectManifest before,
    required ProjectManifest after,
  }) {
    if (before.copyWith(
          narrativeDiagnosticSuppressions:
              after.narrativeDiagnosticSuppressions,
        ) !=
        after) {
      throw ArgumentError(
        'Only narrativeDiagnosticSuppressions may change.',
      );
    }
    return NarrativeDiagnosticSuppressionsUpdated._(
      before: before,
      after: after,
    );
  }

  const NarrativeDiagnosticSuppressionsUpdated._({
    required super.before,
    required super.after,
  });
}

@immutable
final class NarrativeAssetCreated extends NarrativeAssetMutationResult {
  const NarrativeAssetCreated({
    required super.before,
    required super.after,
    required this.asset,
  });

  final CinematicAsset asset;
}

@immutable
final class NarrativeAssetUpdated extends NarrativeAssetMutationResult {
  const NarrativeAssetUpdated({
    required super.before,
    required super.after,
    required this.previousAsset,
    required this.asset,
  });

  final CinematicAsset previousAsset;
  final CinematicAsset asset;
}

@immutable
final class NarrativeAssetDeleted extends NarrativeAssetMutationResult {
  NarrativeAssetDeleted({
    required super.before,
    required super.after,
    required this.asset,
    Iterable<String> rewrittenReferencePaths = const <String>[],
  }) : rewrittenReferencePaths = List<String>.unmodifiable(
          rewrittenReferencePaths,
        );

  final CinematicAsset asset;
  final List<String> rewrittenReferencePaths;
}

@immutable
final class NarrativeAssetRejected extends NarrativeAssetMutationResult {
  NarrativeAssetRejected({
    required ProjectManifest project,
    required this.code,
    required this.message,
    Iterable<String> referencePaths = const <String>[],
  })  : referencePaths = List<String>.unmodifiable(referencePaths),
        super(before: project, after: project);

  final String code;
  final String message;
  final List<String> referencePaths;
}

@immutable
final class NarrativeAssetNoChange extends NarrativeAssetMutationResult {
  const NarrativeAssetNoChange({
    required ProjectManifest project,
    required this.asset,
    required this.reason,
  }) : super(before: project, after: project);

  final CinematicAsset asset;
  final String reason;
}

@immutable
final class NarrativeReferenceReplacementCapability {
  NarrativeReferenceReplacementCapability._({
    required this.source,
    required this.replacement,
    required List<String> coveredReferencePaths,
  }) : coveredReferencePaths = List<String>.unmodifiable(
          coveredReferencePaths,
        );

  final NarrativeDependencyKey source;
  final NarrativeDependencyKey replacement;
  final List<String> coveredReferencePaths;
}

@immutable
sealed class NarrativeReferenceReplacementValidationResult {
  const NarrativeReferenceReplacementValidationResult();
}

@immutable
final class NarrativeReferenceReplacementValidated
    extends NarrativeReferenceReplacementValidationResult {
  const NarrativeReferenceReplacementValidated(this.capability);

  final NarrativeReferenceReplacementCapability capability;
}

@immutable
final class NarrativeReferenceReplacementRejected
    extends NarrativeReferenceReplacementValidationResult {
  const NarrativeReferenceReplacementRejected({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

/// Pure, Cinematic-only mutation boundary for Narrative Studio authoring.
///
/// Other narrative asset families deliberately remain unsupported until they
/// migrate to the same validate/persist/publish transaction contract.
abstract final class NarrativeAssetMutation {
  static NarrativeAssetMutationResult createCinematic(
    ProjectManifest project, {
    required String title,
    String? description,
    CinematicTimeline? timeline,
  }) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      return _rejected(
        project,
        code: 'blankTitle',
        message: 'A cinematic title is required.',
      );
    }
    try {
      final asset = CinematicAsset(
        id: _nextCinematicId(project, cleanTitle),
        title: cleanTitle,
        description: _trimOptional(description),
        timeline: timeline ?? CinematicTimeline(),
      );
      final after = project.copyWith(
        cinematics: [...project.cinematics, asset],
      );
      ProjectValidator.validate(after);
      return NarrativeAssetCreated(
        before: project,
        after: after,
        asset: asset,
      );
    } on Object catch (error) {
      return _invalidProjection(project, error);
    }
  }

  static NarrativeAssetMutationResult updateCinematic(
    ProjectManifest project, {
    required String cinematicId,
    required CinematicAsset cinematic,
  }) {
    final id = cinematicId.trim();
    if (id != cinematic.id) {
      return _rejected(
        project,
        code: 'idMismatch',
        message: 'A cinematic update cannot change its stable id.',
      );
    }
    final matches =
        project.cinematics.where((asset) => asset.id == id).toList();
    if (matches.isEmpty) {
      return _rejected(
        project,
        code: 'assetNotFound',
        message: 'The cinematic to update does not exist.',
      );
    }
    if (matches.length > 1) {
      return _rejected(
        project,
        code: 'assetIdAmbiguous',
        message: 'The cinematic id is ambiguous.',
      );
    }
    final previous = matches.single;
    if (previous == cinematic) {
      return NarrativeAssetNoChange(
        project: project,
        asset: previous,
        reason: 'The cinematic already has these values.',
      );
    }
    try {
      final after = project.copyWith(
        cinematics: [
          for (final asset in project.cinematics)
            if (asset.id == id) cinematic else asset,
        ],
      );
      ProjectValidator.validate(after);
      return NarrativeAssetUpdated(
        before: project,
        after: after,
        previousAsset: previous,
        asset: cinematic,
      );
    } on Object catch (error) {
      return _invalidProjection(project, error);
    }
  }

  static NarrativeAssetMutationResult cloneCinematic(
    ProjectManifest project, {
    required String cinematicId,
    String? title,
  }) {
    final matches = project.cinematics
        .where((asset) => asset.id == cinematicId.trim())
        .toList();
    if (matches.isEmpty) {
      return _rejected(
        project,
        code: 'assetNotFound',
        message: 'The cinematic to clone does not exist.',
      );
    }
    if (matches.length > 1) {
      return _rejected(
        project,
        code: 'assetIdAmbiguous',
        message: 'The cinematic id is ambiguous.',
      );
    }
    final source = matches.single;
    final cloneTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : '${source.title} (copie)';
    try {
      final clone = CinematicAsset(
        id: _nextCinematicId(project, cloneTitle),
        title: cloneTitle,
        description: source.description,
        storylineId: source.storylineId,
        chapterId: source.chapterId,
        mapId: source.mapId,
        tags: source.tags,
        requiredActors: source.requiredActors,
        movementTargets: source.movementTargets,
        stageContext: source.stageContext,
        timeline: source.timeline,
        notes: source.notes,
        metadata: source.metadata,
      );
      final after = project.copyWith(
        cinematics: [...project.cinematics, clone],
      );
      ProjectValidator.validate(after);
      return NarrativeAssetCreated(
        before: project,
        after: after,
        asset: clone,
      );
    } on Object catch (error) {
      return _invalidProjection(project, error);
    }
  }

  static NarrativeReferenceReplacementValidationResult
      validateCinematicReplacement(
    ProjectManifest project, {
    required String sourceId,
    required String replacementId,
  }) {
    final result = deleteCinematic(
      project,
      cinematicId: sourceId,
      rewrite: NarrativeReferenceRewrite.replaceWith(replacementId),
    );
    if (result case NarrativeAssetRejected(:final code, :final message)) {
      return NarrativeReferenceReplacementRejected(
        code: code,
        message: message,
      );
    }
    if (result is! NarrativeAssetDeleted) {
      return const NarrativeReferenceReplacementRejected(
        code: 'replacementValidationFailed',
        message: 'The cinematic replacement could not be validated.',
      );
    }
    final expectedPaths = _cinematicReferencePaths(project, sourceId.trim());
    if (!_sameStrings(result.rewrittenReferencePaths, expectedPaths)) {
      return const NarrativeReferenceReplacementRejected(
        code: 'unsupportedReferenceRewrite',
        message: 'At least one cinematic reference could not be rewritten.',
      );
    }
    return NarrativeReferenceReplacementValidated(
      NarrativeReferenceReplacementCapability._(
        source: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.cinematic,
          sourceId.trim(),
        ),
        replacement: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.cinematic,
          replacementId.trim(),
        ),
        coveredReferencePaths: expectedPaths,
      ),
    );
  }

  static NarrativeAssetMutationResult deleteCinematicWithValidatedReplacement(
    ProjectManifest project,
    NarrativeReferenceReplacementCapability capability,
  ) {
    final validation = validateCinematicReplacement(
      project,
      sourceId: capability.source.id,
      replacementId: capability.replacement.id,
    );
    if (validation is! NarrativeReferenceReplacementValidated ||
        validation.capability.source != capability.source ||
        validation.capability.replacement != capability.replacement ||
        !_sameStrings(
          validation.capability.coveredReferencePaths,
          capability.coveredReferencePaths,
        )) {
      return NarrativeAssetRejected(
        project: project,
        code: 'staleReplacementCapability',
        message:
            'The cinematic replacement must be validated again for the current project.',
      );
    }
    return deleteCinematic(
      project,
      cinematicId: capability.source.id,
      rewrite: NarrativeReferenceRewrite.replaceWith(
        capability.replacement.id,
      ),
    );
  }

  static NarrativeAssetMutationResult deleteCinematic(
    ProjectManifest project, {
    required String cinematicId,
    NarrativeReferenceRewrite rewrite =
        const NarrativeReferenceRewrite.rejectIfReferenced(),
  }) {
    final id = cinematicId.trim();
    final matches =
        project.cinematics.where((asset) => asset.id == id).toList();
    if (matches.isEmpty) {
      return _rejected(
        project,
        code: 'assetNotFound',
        message: 'The cinematic to delete does not exist.',
      );
    }
    if (matches.length > 1) {
      return _rejected(
        project,
        code: 'assetIdAmbiguous',
        message: 'The cinematic id is ambiguous.',
      );
    }

    final source = matches.single;
    final references = _cinematicReferencePaths(project, id);
    final replacementId = rewrite.replacementAssetId?.trim();
    if (references.isNotEmpty && rewrite.rejectsReferences) {
      return NarrativeAssetRejected(
        project: project,
        code: 'assetReferenced',
        message: 'The cinematic is still referenced by Scene nodes.',
        referencePaths: references,
      );
    }
    if (replacementId != null) {
      if (replacementId.isEmpty) {
        return _rejected(
          project,
          code: 'rewriteTargetMissing',
          message: 'A replacement cinematic id is required.',
        );
      }
      if (replacementId == id) {
        return _rejected(
          project,
          code: 'selfRewrite',
          message: 'A cinematic cannot replace itself during deletion.',
        );
      }
      final replacements = project.cinematics
          .where((asset) => asset.id == replacementId)
          .toList();
      if (replacements.isEmpty) {
        final replacementExistsInAnotherNamespace =
            buildNarrativeDependencyIndex(project: project).definitions.any(
                  (definition) =>
                      definition.key.id == replacementId &&
                      definition.key.kind !=
                          NarrativeDependencyTargetKind.cinematic,
                );
        return _rejected(
          project,
          code: replacementExistsInAnotherNamespace
              ? 'rewriteTargetTypeMismatch'
              : 'rewriteTargetMissing',
          message: replacementExistsInAnotherNamespace
              ? 'The replacement id belongs to another asset type.'
              : 'The replacement cinematic does not exist.',
        );
      }
      if (replacements.length > 1) {
        return _rejected(
          project,
          code: 'rewriteTargetAmbiguous',
          message: 'The replacement cinematic id is ambiguous.',
        );
      }
    }

    try {
      var rewrittenScenes = project.scenes;
      if (replacementId != null && references.isNotEmpty) {
        rewrittenScenes = [
          for (final scene in project.scenes)
            _rewriteSceneCinematicReferences(
              scene,
              sourceId: id,
              replacementId: replacementId,
              project: project,
            ),
        ];
      }
      final after = project.copyWith(
        cinematics: [
          for (final asset in project.cinematics)
            if (asset.id != id) asset,
        ],
        scenes: rewrittenScenes,
      );
      if (_cinematicReferencePaths(after, id).isNotEmpty) {
        return _rejected(
          project,
          code: 'unsupportedReferenceRewrite',
          message: 'At least one cinematic reference could not be rewritten.',
        );
      }
      ProjectValidator.validate(after);
      return NarrativeAssetDeleted(
        before: project,
        after: after,
        asset: source,
        rewrittenReferencePaths:
            replacementId == null ? const <String>[] : references,
      );
    } on Object catch (error) {
      return _invalidProjection(project, error);
    }
  }
}

NarrativeAssetRejected _rejected(
  ProjectManifest project, {
  required String code,
  required String message,
}) {
  return NarrativeAssetRejected(
    project: project,
    code: code,
    message: message,
  );
}

NarrativeAssetRejected _invalidProjection(
  ProjectManifest project,
  Object error,
) {
  return _rejected(
    project,
    code: 'invalidProjectedProject',
    message: 'The projected project is invalid: $error',
  );
}

List<String> _cinematicReferencePaths(
  ProjectManifest project,
  String cinematicId,
) {
  final key = NarrativeDependencyKey(
    NarrativeDependencyTargetKind.cinematic,
    cinematicId,
  );
  return buildNarrativeDependencyIndex(project: project)
      .usagesFor(key)
      .map((usage) => usage.path)
      .toList(growable: false);
}

SceneAsset _rewriteSceneCinematicReferences(
  SceneAsset source, {
  required String sourceId,
  required String replacementId,
  required ProjectManifest project,
}) {
  var scene = source;
  final nodeIds = [
    for (final node in source.graph.nodes)
      if (node.payload case SceneCinematicPayload(:final cinematicId))
        if (cinematicId == sourceId) node.id,
  ];
  for (final nodeId in nodeIds) {
    scene = updateSceneCinematicPayload(
      scene,
      nodeId: nodeId,
      cinematicId: replacementId,
      project: project,
    ).updatedScene;
  }
  return scene;
}

String _nextCinematicId(ProjectManifest project, String title) {
  final slug = title
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = slug.isEmpty ? 'cinematic' : 'cinematic_$slug';
  final existingIds = project.cinematics.map((asset) => asset.id).toSet();
  if (!existingIds.contains(base)) return base;
  var index = 2;
  while (existingIds.contains('${base}_$index')) {
    index++;
  }
  return '${base}_$index';
}

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
