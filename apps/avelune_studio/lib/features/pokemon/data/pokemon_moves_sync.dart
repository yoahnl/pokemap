import 'dart:convert';
import 'dart:math';

import 'package:map_authoring/map_authoring.dart'
    show PokemonMovesCatalogMerge, ShowdownMoveCatalogConverter;
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/pokemon_moves_sync_models.dart';
import '../domain/pokemon_workspace_models.dart';
import 'pokemon_moves_snapshot_source.dart';

final class PokemonMovesSync {
  const PokemonMovesSync({
    required this.session,
    required this.mapAdapter,
    required this.reader,
    required this.source,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader reader;
  final PokemonMovesSnapshotSource source;

  Future<PokemonMovesSyncPreview> preview() async {
    final baseline = await mapAdapter.resourceBaseline(session);
    final path = baseline.manifest.pokemon.catalogFiles['moves'];
    if (!baseline.manifest.pokemon.enabled || path == null || path.isEmpty) {
      throw const PokemonWorkspaceFailure(
        'Aucun catalogue d’attaques configuré dans ce projet.',
      );
    }
    final external = const ShowdownMoveCatalogConverter().convert(
      await source.fetch(),
    );
    final before = await _readOptional(path);
    final local = before == null
        ? null
        : PokemonCatalogFile.fromJson(
            jsonDecode(utf8.decode(before)) as Map<String, dynamic>,
          );
    final result = const PokemonMovesCatalogMerge().merge(
      localCatalog: local,
      externalCatalog: external,
    );
    return PokemonMovesSyncPreview(
      relativePath: path,
      projectRevision: baseline.revision,
      beforeBytes: before,
      document: result.catalog.toJson().cast<String, dynamic>(),
      externalCount: external.entries.length,
      createdIds: List.unmodifiable(result.createdIds),
      updatedIds: List.unmodifiable(result.updatedIds),
      unchangedIds: List.unmodifiable(result.unchangedIds),
      preservedLocalOnlyIds: List.unmodifiable(result.preservedLocalOnlyIds),
    );
  }

  Future<void> apply(PokemonMovesSyncPreview preview) =>
      mapAdapter.withResourceMutation(() => _apply(preview));

  Future<void> _apply(PokemonMovesSyncPreview preview) async {
    final baseline = await mapAdapter.resourceBaseline(session);
    if (baseline.revision != preview.projectRevision ||
        baseline.manifest.pokemon.catalogFiles['moves'] !=
            preview.relativePath ||
        !_same(
          await _readOptional(preview.relativePath),
          preview.beforeBytes,
        )) {
      throw const PokemonWorkspaceFailure(
        'Le catalogue ou le projet a changé depuis l’aperçu. Reprévisualisez.',
      );
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
          'pokemon_moves_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operation,
          actionId: 'pokemon.catalog.write',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: operation,
          parameters: {
            'relativePath': preview.relativePath,
            'document': preview.document,
            if (preview.beforeBytes != null)
              'beforeBytesBase64': base64Encode(preview.beforeBytes!),
          },
        ),
      );
      if (planned.plan.changeSet.changes.any(
        (change) => change.storageKey != preview.relativePath,
      )) {
        throw const PokemonWorkspaceFailure(
          'La synchronisation cible un autre document que le catalogue.',
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
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }

  Future<List<int>?> _readOptional(String path) async {
    final probe = reader as ProjectResourceProbeReader;
    final resource = await probe.probeResource(
      projectRoot: session.directoryPath,
      relativePath: path,
    );
    if (resource.status == ProjectResourceProbeStatus.missing) return null;
    if (resource.status != ProjectResourceProbeStatus.exists) {
      throw PokemonWorkspaceFailure('Catalogue inaccessible : $path');
    }
    return reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: path,
    );
  }

  bool _same(List<int>? a, List<int>? b) {
    if (a == null || b == null) return a == null && b == null;
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
