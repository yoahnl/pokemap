import 'dart:convert';
import 'dart:math';

import 'package:map_authoring/map_authoring_local.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/pokemon_workspace_models.dart';

final class PokemonDocumentWriteRequest {
  const PokemonDocumentWriteRequest({
    required this.family,
    required this.relativePath,
    required this.beforeBytes,
    required this.document,
  });

  final PokemonDocumentFamily family;
  final String relativePath;
  final List<int>? beforeBytes;
  final Map<String, dynamic> document;
}

final class PokemonDocumentTransaction {
  const PokemonDocumentTransaction({
    required this.session,
    required this.mapAdapter,
    required this.reader,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader reader;

  Future<void> save(PokemonSpeciesDraft draft) =>
      mapAdapter.withResourceMutation(() => _save(draft));

  Future<void> _save(PokemonSpeciesDraft draft) async {
    final families = draft.changedFamilies;
    if (families.isEmpty) return;
    await _apply([
      for (final family in families)
        PokemonDocumentWriteRequest(
          family: family,
          relativePath: draft.base.source(family)!.relativePath,
          beforeBytes: draft.base.source(family)!.bytes,
          document: draft.document(family)!,
        ),
    ]);
  }

  Future<void> apply(List<PokemonDocumentWriteRequest> documents) =>
      mapAdapter.withResourceMutation(() => _apply(documents));

  Future<void> _apply(List<PokemonDocumentWriteRequest> documents) async {
    if (documents.isEmpty || documents.length > 200) {
      throw const PokemonWorkspaceFailure('Lot Pokémon vide ou trop grand.');
    }
    final writes = <Map<String, Object?>>[];
    for (final item in documents) {
      final currentBytes = await _readOptional(item.relativePath);
      if (!_sameBytes(currentBytes, item.beforeBytes)) {
        throw PokemonWorkspaceFailure(
          'Le document ${item.relativePath} a changé sur le disque. '
          'Votre brouillon reste ouvert.',
        );
      }
      writes.add({
        'actionId': 'pokemon.${item.family.name}.write',
        'parameters': {
          'relativePath': item.relativePath,
          'document': item.document,
          if (item.beforeBytes != null)
            'beforeBytesBase64': base64Encode(item.beforeBytes!),
        },
      });
    }
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
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    var attached = false;
    try {
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
      final operation =
          'pokemon_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operation,
          actionId: 'pokemon.documents.write',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: operation,
          parameters: {'documents': writes},
        ),
      );
      final changes = planned.plan.changeSet.changes;
      final expectedPaths = {for (final item in documents) item.relativePath};
      if (changes.length != expectedPaths.length ||
          changes.any((change) => !expectedPaths.contains(change.storageKey))) {
        throw const PokemonWorkspaceFailure(
          'La transaction Pokémon touche un autre document que prévu.',
        );
      }
      try {
        await api.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: operation,
        );
      } on Object catch (failure) {
        try {
          await api.recoverMutation(
            opened.projectHandle,
            operationId: operation,
          );
        } on Object {
          throw PokemonWorkspaceFailure(
            'Écriture interrompue ; journal $operation conservé : $failure',
          );
        }
        rethrow;
      }
      for (final change in changes) {
        final actual = await reader.readBytes(
          projectRoot: session.directoryPath,
          relativePath: change.storageKey,
        );
        if (!_sameBytes(actual, change.afterBytes)) {
          throw PokemonWorkspaceFailure(
            'Le document ${change.storageKey} ne correspond pas au reçu.',
          );
        }
      }
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }

  Future<List<int>?> _readOptional(String path) async {
    final probe = reader;
    if (probe is ProjectResourceProbeReader) {
      final result = await (probe as ProjectResourceProbeReader).probeResource(
        projectRoot: session.directoryPath,
        relativePath: path,
      );
      if (result.status == ProjectResourceProbeStatus.missing) return null;
      if (result.status != ProjectResourceProbeStatus.exists) {
        throw PokemonWorkspaceFailure('Document inaccessible : $path');
      }
    }
    return reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: path,
    );
  }

  bool _sameBytes(List<int>? a, List<int>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
