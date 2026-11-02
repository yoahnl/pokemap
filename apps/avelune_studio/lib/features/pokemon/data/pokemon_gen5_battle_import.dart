import 'dart:math';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../../resources/domain/resource_port.dart';
import 'pokemon_external_import_helpers.dart';

final class PokemonGen5BattleImport {
  const PokemonGen5BattleImport({
    required this.session,
    required this.mapAdapter,
    required this.reader,
    required this.source,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader reader;
  final AveluneGen5BattleSource source;

  Future<({AveluneGen5ImportStatus status, bool refreshRequired})> apply({
    required Gen5BattleSourceBundle bundle,
    required String projectSpeciesId,
    required String speciesPath,
    required bool Function() isCurrent,
  }) => mapAdapter.withResourceMutation(() async {
    if (!isCurrent()) throw StateError('La sélection a changé.');
    final baseline = await mapAdapter.resourceBaseline(session);
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: const {},
      initializeSceneOwners: false,
    ).openProject(session.directoryPath);
    final artifacts = LocalArtifactStore(
      allowedSourceRoots: [session.directoryPath],
      maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
    );
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
      artifactStore: artifacts,
      catalogFileReader: reader,
    );
    var attached = false;
    try {
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
      final operation =
          'studio_gen5_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      final result =
          await AveluneGen5BattleSourceImport(
            source: source,
            authoring: api,
            projectHandle: opened.projectHandle,
            workspaceHandle: opened.workspaceHandle,
          ).importBundle(
            bundle: bundle,
            projectSpeciesId: projectSpeciesId,
            nationalDex: bundle.nationalDex,
            speciesPath: speciesPath,
            operationId: operation,
            isCurrent: isCurrent,
          );
      var refreshRequired = result.refreshRequired;
      final head = result.headAfterBytes;
      if (head != null) {
        try {
          final revision = await mapAdapter.resourceRevision(session);
          final actual = await reader.readBytes(
            projectRoot: session.directoryPath,
            relativePath: CatalogStorageStore.headStorageKey,
          );
          if (!samePokemonBytes(actual, head)) {
            throw StateError('Le catalogue a changé après la transaction.');
          }
          await mapAdapter.acceptResourceMutation(
            session,
            ResourceMutationReceipt(
              before: baseline.manifest,
              manifest: baseline.manifest,
              beforeRevision: baseline.revision,
              revision: revision,
              changedPaths: [CatalogStorageStore.headStorageKey],
              operationId: operation,
              actionId: 'pokemon.gen5_battle_source.import',
            ),
          );
        } on Object {
          refreshRequired = true;
        }
      }
      return (status: result.status, refreshRequired: refreshRequired);
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  });
}
