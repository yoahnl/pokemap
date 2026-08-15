import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'authoring_mutation_adapter.dart';
import 'authoring_query_adapter.dart';
import 'editor_receipt_presenter.dart';

final class ScenePresentationCreateAndLinkResult {
  const ScenePresentationCreateAndLinkResult({
    required this.manifest,
    required this.cinematicId,
    required this.nodeId,
    required this.receiptId,
  });

  final ProjectManifest manifest;
  final String cinematicId;
  final String nodeId;
  final String receiptId;
}

final class ScenePresentationCreateAndLinkDraft {
  const ScenePresentationCreateAndLinkDraft({
    required this.manifest,
    required this.cinematicId,
    required this.nodeId,
  });

  final ProjectManifest manifest;
  final String cinematicId;
  final String nodeId;
}

abstract interface class ScenePresentationCreateAndLinkGateway {
  ScenePresentationCreateAndLinkDraft prepareDraft({
    required ProjectManifest expectedProject,
    required String sceneId,
    required String targetNodeId,
    required String title,
    required String templateId,
    required int templateVersion,
    required String? folderId,
  });

  Future<ScenePresentationCreateAndLinkResult> createAndLink(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required String sceneId,
    required String targetNodeId,
    required String title,
    required String templateId,
    required int templateVersion,
    required String? folderId,
  });

  Future<ProjectManifest> undo(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required ScenePresentationCreateAndLinkResult transaction,
  });
}

final class CanonicalScenePresentationCreateAndLinkGateway
    implements ScenePresentationCreateAndLinkGateway {
  CanonicalScenePresentationCreateAndLinkGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  }) : _mutations = mutations,
       _queries = queries;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;
  int _operationSequence = 0;

  @override
  ScenePresentationCreateAndLinkDraft prepareDraft({
    required ProjectManifest expectedProject,
    required String sceneId,
    required String targetNodeId,
    required String title,
    required String templateId,
    required int templateVersion,
    required String? folderId,
  }) => prepareScenePresentationCreateAndLinkDraft(
    expectedProject: expectedProject,
    sceneId: sceneId,
    targetNodeId: targetNodeId,
    title: title,
    templateId: templateId,
    templateVersion: templateVersion,
    folderId: folderId,
  );

  @override
  Future<ScenePresentationCreateAndLinkResult> createAndLink(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required String sceneId,
    required String targetNodeId,
    required String title,
    required String templateId,
    required int templateVersion,
    required String? folderId,
  }) async {
    final cleanTitle = _requiredText(title, 'title');
    final cleanTemplateId = _requiredText(templateId, 'templateId');
    final cinematicId = _nextCinematicId(expectedProject, cleanTitle);
    final scene = _scene(expectedProject, sceneId);
    final nodeId = _nextNodeId(scene, cinematicId);
    final operationId = _nextOperationId();
    try {
      await _queries.invalidate(projectRootPath);
      final before = await _queries.open(projectRootPath);
      if (before.manifest != expectedProject) {
        throw const EditorConflictException(
          'La Scene a changé. Rechargez-la avant de créer la cinématique.',
        );
      }
      final plan = await _mutations.plan(
        projectRootPath,
        actionId: 'scene.preSession.presentation.createAndLink',
        parameters: <String, Object?>{
          'sceneId': sceneId,
          'nodeId': nodeId,
          'targetNodeId': targetNodeId,
          'cinematicId': cinematicId,
          'title': cleanTitle,
          'templateId': cleanTemplateId,
          'templateVersion': templateVersion,
          'targetFolderId': folderId,
          'targetIndex': _targetIndex(expectedProject, folderId),
        },
        idempotencyKey: operationId,
        requestId: operationId,
        expectedRevision: before.snapshotRevision,
      );
      final applied = await _mutations.apply(
        plan,
        operationId: '${operationId}_commit',
      );
      final manifest = (await _queries.open(projectRootPath)).manifest;
      _validateResult(
        manifest,
        sceneId: sceneId,
        nodeId: nodeId,
        cinematicId: cinematicId,
      );
      return ScenePresentationCreateAndLinkResult(
        manifest: manifest,
        cinematicId: cinematicId,
        nodeId: nodeId,
        receiptId: applied.receipt.receiptId,
      );
    } on EditorConflictException {
      rethrow;
    } on EditorAuthoringMutationFailure catch (failure) {
      if (_isConflict(failure.code)) {
        throw EditorConflictException(failure.message);
      }
      rethrow;
    }
  }

  @override
  Future<ProjectManifest> undo(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required ScenePresentationCreateAndLinkResult transaction,
  }) async {
    try {
      await _queries.invalidate(projectRootPath);
      final before = await _queries.open(projectRootPath);
      if (before.manifest != expectedProject) {
        throw const EditorConflictException(
          'Le projet a changé. Rechargez-le avant d’annuler la création.',
        );
      }
      await _mutations.undo(
        projectRootPath,
        entryId: transaction.receiptId,
        idempotencyKey: '${_nextOperationId()}_undo',
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

  String _nextOperationId() {
    _operationSequence += 1;
    return 'editor_scene_presentation_create_link_'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}_'
        '$_operationSequence';
  }
}

ScenePresentationCreateAndLinkDraft prepareScenePresentationCreateAndLinkDraft({
  required ProjectManifest expectedProject,
  required String sceneId,
  required String targetNodeId,
  required String title,
  required String templateId,
  required int templateVersion,
  required String? folderId,
}) {
  final cleanTitle = _requiredText(title, 'title');
  final cleanTemplateId = _requiredText(templateId, 'templateId');
  final cinematicId = _nextCinematicId(expectedProject, cleanTitle);
  final scene = _scene(expectedProject, sceneId);
  final nodeId = _nextNodeId(scene, cinematicId);
  final template = PresentationCinematicTemplateCatalog.canonical().require(
    cleanTemplateId,
    version: templateVersion,
  );
  final cinematic = instantiatePresentationCinematicTemplate(
    template,
    cinematicId: cinematicId,
    title: cleanTitle,
    description: null,
  );
  final manifest = const SceneActions().createAndLinkPreSessionPresentation(
    expectedProject,
    maps: const <MapData>[],
    sceneId: sceneId,
    nodeId: nodeId,
    targetNodeId: targetNodeId,
    cinematic: cinematic,
    targetFolderId: folderId,
    targetIndex: _targetIndex(expectedProject, folderId),
  );
  _validateResult(
    manifest,
    sceneId: sceneId,
    nodeId: nodeId,
    cinematicId: cinematicId,
  );
  return ScenePresentationCreateAndLinkDraft(
    manifest: manifest,
    cinematicId: cinematicId,
    nodeId: nodeId,
  );
}

SceneAsset _scene(ProjectManifest project, String sceneId) {
  for (final scene in project.scenes) {
    if (scene.id == sceneId) return scene;
  }
  throw ArgumentError.value(sceneId, 'sceneId', 'Scene inconnue');
}

int _targetIndex(ProjectManifest project, String? folderId) => project
    .cinematicLibraryCatalog
    .entries
    .where(
      (entry) =>
          entry.family == CinematicLibraryFamily.presentation &&
          entry.folderId == folderId,
    )
    .length;

String _nextCinematicId(ProjectManifest project, String title) {
  final base = _slug(title);
  final ids = <String>{
    ...project.presentationCinematics.map((asset) => asset.id),
    ...project.cinematicLibraryCatalog.entries
        .where((entry) => entry.family == CinematicLibraryFamily.presentation)
        .map((entry) => entry.cinematicId),
  };
  return _nextAvailableId(base, ids);
}

String _nextNodeId(SceneAsset scene, String cinematicId) {
  final ids = scene.graph.nodes.map((node) => node.id).toSet();
  return _nextAvailableId('presentation_$cinematicId', ids);
}

String _nextAvailableId(String base, Set<String> unavailable) {
  if (!unavailable.contains(base)) return base;
  for (var suffix = 2; suffix < 10000; suffix += 1) {
    final candidate = '$base-$suffix';
    if (!unavailable.contains(candidate)) return candidate;
  }
  throw StateError('Impossible d’allouer un identifiant disponible.');
}

void _validateResult(
  ProjectManifest project, {
  required String sceneId,
  required String nodeId,
  required String cinematicId,
}) {
  final cinematic = project.presentationCinematics.where(
    (candidate) => candidate.id == cinematicId,
  );
  final entry = project.cinematicLibraryCatalog.entryFor(
    CinematicLibraryFamily.presentation,
    cinematicId,
  );
  final scene = _scene(project, sceneId);
  final node = scene.graph.nodes.where((candidate) => candidate.id == nodeId);
  if (cinematic.length != 1 || entry == null || node.length != 1) {
    throw StateError('La transaction create-and-link est incomplète.');
  }
  final payload = node.single.payload;
  if (payload is! ScenePresentationCinematicPayload ||
      payload.presentationCinematicId != cinematicId ||
      PresentationReferenceGraph.build(
        cinematics: project.presentationCinematics,
        scenes: project.scenes,
      ).diagnostics.isNotEmpty) {
    throw StateError(
      'La transaction create-and-link contient une référence invalide.',
    );
  }
}

String _requiredText(String value, String field) {
  final clean = value.trim();
  if (clean.isEmpty) {
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
