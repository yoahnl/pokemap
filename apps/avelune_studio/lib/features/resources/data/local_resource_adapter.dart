import 'dart:convert';
import 'dart:math';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/resource_port.dart';
import 'resource_no_change.dart';

final class LocalResourceAdapter implements ResourcePort {
  LocalResourceAdapter({required this.session, required this.mapAdapter});

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  bool _disposed = false;

  static const _actions = {
    'tileset.import_image',
    'element.upsert',
    'smart_tile.preset.draft.upsert',
    'smart_tile.preset.publish',
  };

  @override
  Future<ResourceMutationReceipt> importImage(ResourceImageImport request) {
    final id = _identity('source');
    return _run(
      'tileset.import_image',
      (_) => {
        'tilesetId': id,
        'name': request.name.trim(),
        'tileWidth': request.tileWidth,
        'tileHeight': request.tileHeight,
      },
      sourcePath: request.sourcePath,
      createdTilesetId: id,
    );
  }

  @override
  Future<ResourceMutationReceipt> mutate(
    String actionId,
    Map<String, Object?> parameters,
  ) => _run(actionId, (_) => parameters);

  @override
  Future<ResourceMutationReceipt> saveElement(ProjectElementEntry element) =>
      _run('element.upsert', (manifest) {
        final known = manifest.elementCategories.any(
          (category) => category.id == element.categoryId,
        );
        if (known) return {'element': element.toJson()};
        final category = manifest.elementCategories.isEmpty
            ? const ProjectElementCategory(id: 'studio_decors', name: 'Décors')
            : manifest.elementCategories.first;
        return {
          'element': element.copyWith(categoryId: category.id).toJson(),
          if (manifest.elementCategories.isEmpty) 'category': category.toJson(),
        };
      });

  Future<ResourceMutationReceipt> _run(
    String actionId,
    Map<String, Object?> Function(ProjectManifest manifest) parameters, {
    String? sourcePath,
    String? createdTilesetId,
  }) => mapAdapter.withResourceMutation(() async {
    try {
      if (_disposed || !_actions.contains(actionId)) {
        throw const ResourceFailure(
          'Cette opération de ressource est indisponible.',
        );
      }
      final before = await mapAdapter.resourceBaseline(session);
      final fields = Map<String, Object?>.from(parameters(before.manifest));
      if (resourceMutationIsUnchanged(before.manifest, actionId, fields)) {
        await mapAdapter.resourceBaseline(session);
        return ResourceMutationReceipt(
          before: before.manifest,
          manifest: before.manifest,
          beforeRevision: before.revision,
          revision: before.revision,
          changedPaths: const [],
        );
      }
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [session.directoryPath],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ).openProject(session.directoryPath);
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final artifacts = LocalArtifactStore(
        allowedSourceRoots: [session.directoryPath],
        maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
      );
      final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
        artifactStore: artifacts,
      );
      String? artifactHandle;
      var attached = false;
      try {
        if (sourcePath != null) {
          await artifacts.authorizeSourceFile(sourcePath);
          final staged = await api.stageArtifactFile(
            sourcePath: sourcePath,
            declaredMediaType: 'image/png',
          );
          artifactHandle = staged.reference.handle;
          fields['artifactHandle'] = artifactHandle;
        }
        await api.attachProject(
          projectRootPath: session.directoryPath,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle,
        );
        attached = true;
        final snapshot = await snapshots.load(
          opened.projectHandle,
          policy: ProjectSnapshotLoadPolicy.editorReadProjection,
        );
        if (narrativeEventBytesFingerprint(snapshot.resourceBytes('project')) !=
            before.revision) {
          throw const ResourceFailure(
            'Le projet a changé sur le disque. Rien n’a été écrasé.',
          );
        }
        final operationId = _identity('resource');
        final planned = await api.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: operationId,
            actionId: actionId,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            parameters: fields,
            expectedRevision: snapshot.revision,
            idempotencyKey: operationId,
          ),
        );
        final changes = planned.plan.changeSet.changes;
        final mapPaths = before.manifest.maps
            .map((map) => map.relativePath)
            .toSet();
        if (changes.any(
          (change) =>
              change.resource.kind == 'map' ||
              mapPaths.contains(change.storageKey),
        )) {
          throw const ResourceFailure(
            'Cette publication toucherait une carte. Le travail ouvert a été préservé.',
          );
        }
        final manifestChanges = changes.where(
          (change) => change.storageKey == 'project.json',
        );
        if (manifestChanges.isEmpty && changes.isEmpty) {
          await mapAdapter.resourceBaseline(session);
          return ResourceMutationReceipt(
            before: before.manifest,
            manifest: before.manifest,
            beforeRevision: before.revision,
            revision: before.revision,
            changedPaths: const [],
          );
        }
        final bytes = manifestChanges.single.afterBytes;
        if (bytes == null) throw const FormatException('Manifest missing.');
        final manifest = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
        );
        if (jsonEncode(before.manifest.maps) != jsonEncode(manifest.maps)) {
          throw const ResourceFailure(
            'Une ressource ne peut pas remplacer le catalogue de cartes.',
          );
        }
        final receipt = ResourceMutationReceipt(
          before: before.manifest,
          manifest: manifest,
          beforeRevision: before.revision,
          revision: narrativeEventBytesFingerprint(bytes),
          changedPaths: List.unmodifiable(
            changes.map((change) => change.storageKey),
          ),
          createdTilesetId: createdTilesetId,
        );
        if (_disposed) throw const ResourceFailure('Le projet a été fermé.');
        try {
          await api.applyMutation(
            opened.projectHandle,
            planId: planned.planId,
            operationId: operationId,
          );
        } on Object catch (failure) {
          try {
            await api.recoverMutation(
              opened.projectHandle,
              operationId: operationId,
            );
          } on Object {
            throw ResourceFailure(
              'La publication a échoué. Le journal de reprise $operationId est conservé ; votre carte reste ouverte. $failure',
            );
          }
        }
        await mapAdapter.acceptResourceMutation(session, receipt);
        return receipt;
      } finally {
        if (artifactHandle != null) await artifacts.release(artifactHandle);
        if (attached) await api.detachWorkspace(opened.workspaceHandle);
        handles.closeWorkspace(opened.workspaceHandle);
      }
    } on ResourceFailure {
      rethrow;
    } on Object catch (error) {
      throw ResourceFailure('La ressource n’a pas été publiée : $error');
    }
  });

  @override
  Future<void> dispose() async {
    _disposed = true;
  }

  String _identity(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
}
