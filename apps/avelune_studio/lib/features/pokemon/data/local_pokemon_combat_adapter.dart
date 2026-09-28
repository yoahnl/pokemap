import 'dart:convert';
import 'dart:math';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/pokemon_combat_port.dart';

final class LocalPokemonCombatAdapter implements PokemonCombatPort {
  const LocalPokemonCombatAdapter({
    required this.session,
    required this.mapAdapter,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;

  @override
  Future<PokemonCombatSnapshot> load() async {
    final project = await _withSnapshot((snapshot, _) async {
      return PokemonCombatSnapshot(
        project: snapshot.manifest,
        maps: List.unmodifiable(snapshot.maps),
      );
    });
    return project;
  }

  @override
  Future<void> saveTable(
    ProjectEncounterTable? before,
    ProjectEncounterTable after,
  ) => _change(
    current: (snapshot) => snapshot.manifest.encounterTables
        .where((value) => value.id == after.id)
        .firstOrNull
        ?.toJson(),
    before: before?.toJson(),
    action: 'campaign.encounter_table.upsert',
    parameters: {'value': after.toJson()},
  );

  @override
  Future<void> deleteTable(ProjectEncounterTable before) => _change(
    current: (snapshot) => snapshot.manifest.encounterTables
        .where((value) => value.id == before.id)
        .firstOrNull
        ?.toJson(),
    before: before.toJson(),
    action: 'campaign.encounter_table.delete',
    parameters: {'id': before.id},
  );

  @override
  Future<void> saveTrainer(
    ProjectTrainerEntry? before,
    ProjectTrainerEntry after,
  ) => _change(
    current: (snapshot) => snapshot.manifest.trainers
        .where((value) => value.id == after.id)
        .firstOrNull
        ?.toJson(),
    before: before?.toJson(),
    action: 'campaign.trainer.upsert',
    parameters: {'value': after.toJson()},
  );

  @override
  Future<void> deleteTrainer(ProjectTrainerEntry before) => _change(
    current: (snapshot) => snapshot.manifest.trainers
        .where((value) => value.id == before.id)
        .firstOrNull
        ?.toJson(),
    before: before.toJson(),
    action: 'campaign.trainer.delete',
    parameters: {'id': before.id},
  );

  Future<void> _change({
    required Map<String, dynamic>? Function(ProjectSnapshot) current,
    required Map<String, dynamic>? before,
    required String action,
    required Map<String, Object?> parameters,
  }) => mapAdapter.withResourceMutation(() async {
    await _withSnapshot((snapshot, run) async {
      if (jsonEncode(current(snapshot)) != jsonEncode(before)) {
        throw StateError(
          'Cette fiche a changé sur le disque. Votre brouillon est conservé.',
        );
      }
      await run(action, parameters);
      await mapAdapter.resourceBaseline(session, refreshCatalog: true);
    });
  });

  Future<T> _withSnapshot<T>(
    Future<T> Function(
      ProjectSnapshot snapshot,
      Future<void> Function(String, Map<String, Object?>) run,
    )
    operation,
  ) async {
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
    final loader = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: loader,
    );
    var attached = false;
    try {
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
      final snapshot = await loader.load(
        opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.editorReadProjection,
      );
      Future<void> run(String action, Map<String, Object?> parameters) async {
        final id =
            'studio_combat_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
        final planned = await api.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: id,
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: id,
            parameters: parameters,
          ),
        );
        if (planned.plan.changeSet.changes.any(
          (change) => change.storageKey != 'project.json',
        )) {
          throw StateError('La mutation vise une ressource inattendue.');
        }
        try {
          await api.applyMutation(
            opened.projectHandle,
            planId: planned.planId,
            operationId: id,
          );
        } on Object catch (failure) {
          try {
            await api.recoverMutation(opened.projectHandle, operationId: id);
          } on Object {
            throw StateError(
              'Écriture interrompue ; journal $id conservé : $failure',
            );
          }
          rethrow;
        }
      }

      return await operation(snapshot, run);
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }
}
