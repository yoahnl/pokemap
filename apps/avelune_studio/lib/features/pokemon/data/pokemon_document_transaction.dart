import 'dart:convert';
import 'dart:math';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart'
    show
        PokemonDocumentKind,
        PokemonJsonDocument,
        pokemonMediaResourceIdentity,
        pokemonSpeciesResourceIdentity;

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../../resources/domain/resource_port.dart';
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

typedef PokemonDocumentReadDependency = ({
  String resourceIdentity,
  String relativePath,
  List<int> beforeBytes,
});

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

  Future<void> apply(
    List<PokemonDocumentWriteRequest> documents, {
    List<PokemonDocumentReadDependency> expectedDependencies = const [],
  }) => mapAdapter.withResourceMutation(
    () => _apply(documents, expectedDependencies: expectedDependencies),
  );

  Future<void> _apply(
    List<PokemonDocumentWriteRequest> documents, {
    List<PokemonDocumentReadDependency> expectedDependencies = const [],
  }) async {
    if (documents.isEmpty || documents.length > 200) {
      throw const PokemonWorkspaceFailure('Lot Pokémon vide ou trop grand.');
    }
    final baseline = await mapAdapter.resourceBaseline(session);
    final writes = <Map<String, Object?>>[];
    final changedPaths = <String>{};
    final dependencies = [...expectedDependencies];
    for (final item in documents) {
      final currentBytes = await _readOptional(item.relativePath);
      if (!_sameBytes(currentBytes, item.beforeBytes)) {
        throw PokemonWorkspaceFailure(
          'Le document ${item.relativePath} a changé sur le disque. '
          'Votre brouillon reste ouvert.',
        );
      }
      final kind = switch (item.family) {
        PokemonDocumentFamily.species => PokemonDocumentKind.species,
        PokemonDocumentFamily.learnset => PokemonDocumentKind.learnset,
        PokemonDocumentFamily.evolution => PokemonDocumentKind.evolution,
        PokemonDocumentFamily.media => PokemonDocumentKind.media,
      };
      final json = PokemonJsonDocument.fromJson(kind, item.document).toJson();
      final after = utf8.encode(
        '${const JsonEncoder.withIndent('  ').convert(json)}\n',
      );
      if (currentBytes != null && _sameBytes(currentBytes, after)) {
        final identity = switch (item.family) {
          PokemonDocumentFamily.species => pokemonSpeciesResourceIdentity(
            json['id'] as String,
          ),
          PokemonDocumentFamily.media => pokemonMediaResourceIdentity(
            json['speciesId'] as String,
          ),
          PokemonDocumentFamily.learnset =>
            'pokemonLearnset:${item.relativePath}',
          PokemonDocumentFamily.evolution =>
            'pokemonEvolution:${item.relativePath}',
        };
        dependencies.add((
          resourceIdentity: identity,
          relativePath: item.relativePath,
          beforeBytes: currentBytes,
        ));
        continue;
      }
      changedPaths.add(item.relativePath);
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
    if (writes.isEmpty) {
      for (final dependency in dependencies) {
        if (!_sameBytes(
          await _readOptional(dependency.relativePath),
          dependency.beforeBytes,
        )) {
          throw PokemonWorkspaceFailure(
            '${dependency.relativePath} a changé depuis l’aperçu. Reprévisualisez.',
          );
        }
      }
      return;
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
      catalogMetadataFields:
          session.storage == ProjectSessionStorage.workingCatalog
          ? const {}
          : null,
    ).openProject(session.directoryPath);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
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
      final snapshot = session.storage == ProjectSessionStorage.workingCatalog
          ? await api.readWorkshopSnapshot(
              opened.projectHandle,
              actionId: 'pokemon.documents.write',
              parameters: {'documents': writes},
              readDependencies: {
                for (final dependency in dependencies)
                  dependency.resourceIdentity: dependency.relativePath,
              },
            )
          : await snapshots.load(
              opened.projectHandle,
              policy: ProjectSnapshotLoadPolicy.editorReadProjection,
            );
      for (final dependency in dependencies) {
        if (snapshot.resourceStorageKeys[dependency.resourceIdentity] !=
                dependency.relativePath ||
            !_sameBytes(
              snapshot.findResourceBytes(dependency.resourceIdentity),
              dependency.beforeBytes,
            )) {
          throw PokemonWorkspaceFailure(
            '${dependency.relativePath} a changé depuis l’aperçu. '
            'Reprévisualisez.',
          );
        }
      }
      final operation =
          'pokemon_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operation,
          actionId: 'pokemon.documents.write',
          actionVersion: 1,
          extensions: session.storage == ProjectSessionStorage.workingCatalog
              ? {
                  'workshopScope': true,
                  'workshopReadDependencies': {
                    for (final dependency in dependencies)
                      dependency.resourceIdentity: dependency.relativePath,
                  },
                }
              : const {},
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: operation,
          parameters: {'documents': writes},
        ),
      );
      if (!planned.applicable) {
        if (planned.nonApplicableReason == 'no_changes') return;
        throw PokemonWorkspaceFailure(
          'La transaction Pokémon ne peut pas être préparée : '
          '${planned.nonApplicableReason ?? "raison inconnue"}.',
        );
      }
      final changes = planned.plan.changeSet.changes;
      final expectedPaths = {...changedPaths};
      if (session.storage == ProjectSessionStorage.workingCatalog) {
        if (planned.plan.catalogDelta == null) {
          throw const PokemonWorkspaceFailure(
            'La transaction Pokémon ne contient pas de mise à jour du catalogue.',
          );
        }
        planned.plan.requireCatalogDelta();
        expectedPaths.add(CatalogStorageStore.headStorageKey);
      }
      final plannedPaths = {for (final change in changes) change.storageKey};
      if (plannedPaths.length != changes.length ||
          plannedPaths.length != expectedPaths.length ||
          plannedPaths.any((path) => !expectedPaths.contains(path))) {
        throw const PokemonWorkspaceFailure(
          'La transaction Pokémon touche un autre document que prévu.',
        );
      }
      try {
        await api.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: operation,
          precondition: () async {
            for (final dependency in dependencies) {
              if (!_sameBytes(
                await _readOptional(dependency.relativePath),
                dependency.beforeBytes,
              )) {
                throw PokemonWorkspaceFailure(
                  '${dependency.relativePath} a changé depuis l’aperçu. '
                  'Reprévisualisez.',
                );
              }
            }
          },
        );
      } on Object catch (failure) {
        try {
          final recovered = await api.recoverMutation(
            opened.projectHandle,
            operationId: operation,
          );
          if (recovered.receipt.extensions['recoveryOutcome'] != 'resumed') {
            throw PokemonWorkspaceFailure(
              'Transaction interrompue ; vérifiez le projet avant de réessayer : $failure',
            );
          }
        } on Object {
          throw PokemonWorkspaceFailure(
            'État de la transaction incertain ; rouvrez le projet et vérifiez '
            'les documents avant de réessayer. Référence $operation : $failure',
          );
        }
      }
      try {
        for (final change in changes) {
          final actual = await reader.readBytes(
            projectRoot: session.directoryPath,
            relativePath: change.storageKey,
          );
          if (!_sameBytes(actual, change.afterBytes)) {
            throw StateError(
              'Le document ${change.storageKey} ne correspond pas au reçu.',
            );
          }
        }
        final revision = await mapAdapter.resourceRevision(session);
        final head = changes.where(
          (change) => change.storageKey == CatalogStorageStore.headStorageKey,
        );
        if (head.isNotEmpty &&
            !_sameBytes(
              await _readOptional(CatalogStorageStore.headStorageKey),
              head.single.afterBytes,
            )) {
          throw StateError('Le catalogue a changé après la transaction.');
        }
        await mapAdapter.acceptResourceMutation(
          session,
          ResourceMutationReceipt(
            before: baseline.manifest,
            manifest: baseline.manifest,
            beforeRevision: baseline.revision,
            revision: revision,
            changedPaths: [for (final change in changes) change.storageKey],
            operationId: operation,
            actionId: 'pokemon.documents.write',
          ),
        );
      } on Object catch (failure) {
        throw PokemonWorkspaceFailure(
          'Écriture confirmée ; vérification ou actualisation impossible. '
          'Rouvrez le projet avant de continuer : $failure',
        );
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
