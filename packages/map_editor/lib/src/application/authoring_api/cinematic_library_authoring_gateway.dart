import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'authoring_mutation_adapter.dart';
import 'authoring_query_adapter.dart';
import 'editor_receipt_presenter.dart';

enum CinematicLibraryWorldStartingPoint {
  blank,
  establishingShot,
  dialogueBeat,
}

final class CinematicLibraryAssetMutationResult {
  const CinematicLibraryAssetMutationResult({
    required this.manifest,
    required this.cinematicId,
  });

  final ProjectManifest manifest;
  final String cinematicId;
}

abstract interface class CinematicLibraryAuthoringGateway {
  Future<CinematicLibraryAssetMutationResult> create(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required CinematicLibraryFamily family,
    required String title,
    required String? folderId,
    CinematicLibraryWorldStartingPoint? worldStartingPoint,
    String? presentationTemplateId,
    int? presentationTemplateVersion,
  });

  Future<CinematicLibraryAssetMutationResult> duplicate(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required CinematicLibraryFamily family,
    required String cinematicId,
    required String? folderId,
  });

  Future<ProjectManifest> rename(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required CinematicLibraryFamily family,
    required String cinematicId,
    required String title,
  });

  Future<ProjectManifest> move(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required CinematicLibraryFamily family,
    required String cinematicId,
    required String? folderId,
  });

  Future<ProjectManifest> setArchived(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required CinematicLibraryFamily family,
    required String cinematicId,
    required bool archived,
  });

  Future<ProjectManifest> delete(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required CinematicLibraryFamily family,
    required String cinematicId,
  });
}

final class CanonicalCinematicLibraryAuthoringGateway
    implements CinematicLibraryAuthoringGateway {
  CanonicalCinematicLibraryAuthoringGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  }) : _mutations = mutations,
       _queries = queries;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;
  int _operationSequence = 0;

  @override
  Future<CinematicLibraryAssetMutationResult> create(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required CinematicLibraryFamily family,
    required String title,
    required String? folderId,
    CinematicLibraryWorldStartingPoint? worldStartingPoint,
    String? presentationTemplateId,
    int? presentationTemplateVersion,
  }) async {
    final cleanTitle = _title(title);
    final cinematicId = _nextAssetId(expectedProject, family, cleanTitle);
    final parameters = switch (family) {
      CinematicLibraryFamily.world => <String, Object?>{
        'family': family.name,
        'cinematicId': cinematicId,
        'title': cleanTitle,
        'targetFolderId': folderId,
        'targetIndex': _targetIndex(expectedProject, family, folderId),
        'startingPoint':
            (worldStartingPoint ?? CinematicLibraryWorldStartingPoint.blank)
                .name,
      },
      CinematicLibraryFamily.presentation => <String, Object?>{
        'family': family.name,
        'cinematicId': cinematicId,
        'title': cleanTitle,
        'targetFolderId': folderId,
        'targetIndex': _targetIndex(expectedProject, family, folderId),
        'templateId': _required(
          presentationTemplateId,
          'presentationTemplateId',
        ),
        'templateVersion': presentationTemplateVersion ?? 1,
      },
    };
    final manifest = await _apply(
      projectRootPath,
      expectedProject: expectedProject,
      actionId: 'cinematicLibraryAsset.create',
      parameters: parameters,
      operationLabel: 'create',
    );
    return CinematicLibraryAssetMutationResult(
      manifest: manifest,
      cinematicId: cinematicId,
    );
  }

  @override
  Future<CinematicLibraryAssetMutationResult> duplicate(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required CinematicLibraryFamily family,
    required String cinematicId,
    required String? folderId,
  }) async {
    final sourceTitle = _assetTitle(expectedProject, family, cinematicId);
    final duplicateId = _nextCopyId(expectedProject, family, cinematicId);
    final manifest = await _apply(
      projectRootPath,
      expectedProject: expectedProject,
      actionId: 'cinematicLibraryAsset.duplicate',
      parameters: <String, Object?>{
        'family': family.name,
        'cinematicId': cinematicId,
        'duplicateId': duplicateId,
        'title': '$sourceTitle (copie)',
        'targetFolderId': folderId,
        'targetIndex': _targetIndex(expectedProject, family, folderId),
      },
      operationLabel: 'duplicate',
    );
    return CinematicLibraryAssetMutationResult(
      manifest: manifest,
      cinematicId: duplicateId,
    );
  }

  @override
  Future<ProjectManifest> rename(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required CinematicLibraryFamily family,
    required String cinematicId,
    required String title,
  }) {
    final cleanTitle = _title(title);
    return switch (family) {
      CinematicLibraryFamily.world => _apply(
        projectRootPath,
        expectedProject: expectedProject,
        actionId: 'cinematic.upsert',
        parameters: <String, Object?>{
          'cinematic': _worldAsset(
            expectedProject,
            cinematicId,
          ).copyWith(title: cleanTitle).toJson(),
        },
        operationLabel: 'rename',
      ),
      CinematicLibraryFamily.presentation => () {
        final asset = _presentationAsset(expectedProject, cinematicId);
        return _apply(
          projectRootPath,
          expectedProject: expectedProject,
          actionId: 'presentationCinematic.update',
          parameters: <String, Object?>{
            'cinematicId': cinematicId,
            'title': cleanTitle,
            'description': asset.description,
            'durationUs': asset.durationUs,
          },
          operationLabel: 'rename',
        );
      }(),
    };
  }

  @override
  Future<ProjectManifest> move(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required CinematicLibraryFamily family,
    required String cinematicId,
    required String? folderId,
  }) => _apply(
    projectRootPath,
    expectedProject: expectedProject,
    actionId: 'cinematicLibraryEntry.place',
    parameters: <String, Object?>{
      'family': family.name,
      'cinematicId': cinematicId,
      'targetFolderId': folderId,
      'targetIndex': _targetIndex(expectedProject, family, folderId),
    },
    operationLabel: 'move',
  );

  @override
  Future<ProjectManifest> setArchived(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required CinematicLibraryFamily family,
    required String cinematicId,
    required bool archived,
  }) => _apply(
    projectRootPath,
    expectedProject: expectedProject,
    actionId: 'cinematicLibraryEntry.setArchived',
    parameters: <String, Object?>{
      'family': family.name,
      'cinematicId': cinematicId,
      'isArchived': archived,
    },
    operationLabel: archived ? 'archive' : 'restore',
  );

  @override
  Future<ProjectManifest> delete(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required CinematicLibraryFamily family,
    required String cinematicId,
  }) => _apply(
    projectRootPath,
    expectedProject: expectedProject,
    actionId: 'cinematicLibraryAsset.delete',
    parameters: <String, Object?>{
      'family': family.name,
      'cinematicId': cinematicId,
    },
    operationLabel: 'delete',
    requiresConfirmation: true,
  );

  Future<ProjectManifest> _apply(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required String actionId,
    required Map<String, Object?> parameters,
    required String operationLabel,
    bool requiresConfirmation = false,
  }) async {
    final operationId = _nextOperationId(operationLabel);
    try {
      await _queries.invalidate(projectRootPath);
      final before = await _queries.open(projectRootPath);
      if (before.manifest != expectedProject) {
        throw const EditorConflictException(
          'Le projet a changé. Rechargez la Library avant de recommencer.',
        );
      }
      final plan = await _mutations.plan(
        projectRootPath,
        actionId: actionId,
        parameters: parameters,
        idempotencyKey: operationId,
        requestId: operationId,
        expectedRevision: before.snapshotRevision,
      );
      final confirmationToken = requiresConfirmation
          ? await _mutations.confirm(plan)
          : null;
      await _mutations.apply(
        plan,
        operationId: '${operationId}_apply',
        confirmationToken: confirmationToken,
      );
      return (await _queries.open(projectRootPath)).manifest;
    } on EditorConflictException {
      rethrow;
    } on EditorAuthoringMutationFailure catch (failure) {
      if (_isConflict(failure.code)) {
        throw EditorConflictException(failure.message);
      }
      rethrow;
    }
  }

  String _nextOperationId(String label) {
    _operationSequence += 1;
    return 'editor_cinematic_library_${label}_'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}_'
        '$_operationSequence';
  }
}

int _targetIndex(
  ProjectManifest project,
  CinematicLibraryFamily family,
  String? folderId,
) => project.cinematicLibraryCatalog.entries
    .where((entry) => entry.family == family && entry.folderId == folderId)
    .length;

String _nextAssetId(
  ProjectManifest project,
  CinematicLibraryFamily family,
  String title,
) {
  final base = _slug(title);
  final ids = _familyIds(project, family);
  if (!ids.contains(base)) return base;
  for (var suffix = 2; suffix < 10000; suffix += 1) {
    final candidate = '$base-$suffix';
    if (!ids.contains(candidate)) return candidate;
  }
  throw StateError('Impossible d’allouer un identifiant de cinématique.');
}

String _nextCopyId(
  ProjectManifest project,
  CinematicLibraryFamily family,
  String sourceId,
) {
  final ids = _familyIds(project, family);
  final base = '$sourceId-copy';
  if (!ids.contains(base)) return base;
  for (var suffix = 2; suffix < 10000; suffix += 1) {
    final candidate = '$base-$suffix';
    if (!ids.contains(candidate)) return candidate;
  }
  throw StateError('Impossible d’allouer une copie de cinématique.');
}

Set<String> _familyIds(
  ProjectManifest project,
  CinematicLibraryFamily family,
) => switch (family) {
  CinematicLibraryFamily.world =>
    project.cinematics.map((asset) => asset.id).toSet(),
  CinematicLibraryFamily.presentation =>
    project.presentationCinematics.map((asset) => asset.id).toSet(),
};

String _assetTitle(
  ProjectManifest project,
  CinematicLibraryFamily family,
  String cinematicId,
) => switch (family) {
  CinematicLibraryFamily.world => _worldAsset(project, cinematicId).title,
  CinematicLibraryFamily.presentation => _presentationAsset(
    project,
    cinematicId,
  ).title,
};

CinematicAsset _worldAsset(ProjectManifest project, String cinematicId) {
  for (final asset in project.cinematics) {
    if (asset.id == cinematicId) return asset;
  }
  throw ArgumentError.value(cinematicId, 'cinematicId', 'cinématique inconnue');
}

PresentationCinematicAsset _presentationAsset(
  ProjectManifest project,
  String cinematicId,
) {
  for (final asset in project.presentationCinematics) {
    if (asset.id == cinematicId) return asset;
  }
  throw ArgumentError.value(cinematicId, 'cinematicId', 'cinématique inconnue');
}

String _title(String value) {
  final clean = value.trim();
  if (clean.isEmpty) {
    throw ArgumentError.value(value, 'title', 'le titre est obligatoire');
  }
  return clean;
}

String _required(String? value, String field) {
  final clean = value?.trim();
  if (clean == null || clean.isEmpty) {
    throw ArgumentError.value(value, field, 'la valeur est obligatoire');
  }
  return clean;
}

String _slug(String value) {
  const accents = <String, String>{
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ÿ': 'y',
  };
  final normalized = value
      .toLowerCase()
      .split('')
      .map((character) => accents[character] ?? character)
      .join();
  final slug = normalized
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return slug.isEmpty ? 'cinematic' : slug;
}

bool _isConflict(String code) =>
    code.contains('conflict') ||
    code.contains('stale') ||
    code.contains('revision');
