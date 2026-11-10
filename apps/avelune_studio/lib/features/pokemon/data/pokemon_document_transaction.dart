import 'dart:convert';
import 'dart:math';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart'
    show
        PokemonDocumentKind,
        PokemonJsonDocument,
        LocalTransactionFileGateway,
        readPendingTransactionJournals,
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

  Future<List<int>?> save(PokemonSpeciesDraft draft) =>
      mapAdapter.withResourceMutation(() => _save(draft));

  Future<List<int>?> _save(PokemonSpeciesDraft draft) async {
    final families = draft.changedFamilies;
    if (families.isEmpty) return null;
    final mediaOnly =
        families.length == 1 && families.single == PokemonDocumentFamily.media;
    final speciesBytes = draft.base.species.bytes;
    if (mediaOnly && speciesBytes == null) {
      throw const PokemonWorkspaceFailure(
        'La préimage de la fiche Pokémon est absente.',
      );
    }
    return _apply(
      [
        for (final family in families)
          PokemonDocumentWriteRequest(
            family: family,
            relativePath: draft.base.source(family)!.relativePath,
            beforeBytes: draft.base.source(family)!.bytes,
            document: draft.document(family)!,
          ),
      ],
      scopedMedia: mediaOnly,
      expectedDependencies: [
        if (mediaOnly)
          (
            resourceIdentity: pokemonSpeciesResourceIdentity(draft.id),
            relativePath: draft.base.species.relativePath,
            beforeBytes: speciesBytes!,
          ),
      ],
    );
  }

  Future<void> apply(
    List<PokemonDocumentWriteRequest> documents, {
    List<PokemonDocumentReadDependency> expectedDependencies = const [],
  }) => mapAdapter.withResourceMutation(() async {
    await _apply(documents, expectedDependencies: expectedDependencies);
  });

  Future<void> applyBattleGifs(
    PokemonDocumentWriteRequest media, {
    required PokemonDocumentReadDependency species,
    required Map<String, List<int>> gifs,
  }) => mapAdapter.withResourceMutation(() async {
    await _apply(
      [media],
      scopedMedia: true,
      expectedDependencies: [species],
      battleGifs: gifs,
    );
  });

  Future<void> applyPokemonPngs(
    PokemonDocumentWriteRequest media, {
    required PokemonDocumentReadDependency species,
    required Map<String, List<int>> pngs,
  }) => mapAdapter.withResourceMutation(() async {
    await _apply(
      [media],
      scopedMedia: true,
      expectedDependencies: [species],
      pokemonPngs: pngs,
    );
  });

  Future<void> migrateMedia(
    PokemonDocumentWriteRequest media, {
    required PokemonDocumentReadDependency species,
  }) => mapAdapter.withResourceMutation(() async {
    await _apply(
      [media],
      scopedMedia: true,
      expectedDependencies: [species],
      migrateMedia: true,
    );
  });

  Future<void> applyBattleCry(
    PokemonDocumentWriteRequest media, {
    required PokemonDocumentReadDependency species,
    required List<int> bytes,
    required String mediaType,
  }) => mapAdapter.withResourceMutation(() async {
    await _apply(
      [media],
      scopedMedia: true,
      expectedDependencies: [species],
      battleCry: (bytes: bytes, mediaType: mediaType),
    );
  });

  Future<List<int>?> _apply(
    List<PokemonDocumentWriteRequest> documents, {
    List<PokemonDocumentReadDependency> expectedDependencies = const [],
    bool scopedMedia = false,
    bool migrateMedia = false,
    Map<String, List<int>> battleGifs = const {},
    Map<String, List<int>> pokemonPngs = const {},
    ({List<int> bytes, String mediaType})? battleCry,
  }) async {
    if (documents.isEmpty || documents.length > 200) {
      throw const PokemonWorkspaceFailure('Lot Pokémon vide ou trop grand.');
    }
    final mediaOnly =
        scopedMedia &&
        documents.length == 1 &&
        documents.single.family == PokemonDocumentFamily.media;
    if ((battleGifs.isNotEmpty ||
            pokemonPngs.isNotEmpty ||
            battleCry != null) &&
        (!mediaOnly ||
            session.storage != ProjectSessionStorage.workingCatalog)) {
      throw const PokemonWorkspaceFailure(
        'Les GIF et les cris nécessitent un catalogue de travail.',
      );
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
          if (migrateMedia) 'migrateSchema': true,
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
      return mediaOnly ? documents.single.beforeBytes : null;
    }
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      workshopScope: mediaOnly,
      initializeSceneOwners: !mediaOnly,
      catalogMetadataFields:
          session.storage == ProjectSessionStorage.workingCatalog
          ? const {}
          : null,
    );
    final gateway = mediaOnly
        ? await LocalTransactionFileGateway.open(
            projectRoot: session.directoryPath,
          )
        : null;
    final opened = gateway == null
        ? await opener.openProject(session.directoryPath)
        : await gateway.withExclusiveWriteLock(() async {
            await readPendingTransactionJournals(
              gateway,
              requirePrepared: true,
            );
            return opener.openProject(session.directoryPath);
          });
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
      final actionId = mediaOnly
          ? 'pokemon.media.write'
          : 'pokemon.documents.write';
      final parameters = mediaOnly
          ? Map<String, Object?>.from(writes.single['parameters'] as Map)
          : <String, Object?>{'documents': writes};
      final snapshot =
          mediaOnly || session.storage == ProjectSessionStorage.workingCatalog
          ? await api.readWorkshopSnapshot(
              opened.projectHandle,
              actionId: actionId,
              parameters: parameters,
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
      final gifHandles = <String, String>{};
      for (final entry in battleGifs.entries) {
        gifHandles[entry.key] = (await api.artifacts.put(
          entry.value,
          declaredMediaType: 'image/gif',
        )).reference.handle;
      }
      final pngHandles = <String, String>{};
      for (final entry in pokemonPngs.entries) {
        pngHandles[entry.key] = (await api.artifacts.put(
          entry.value,
          declaredMediaType: 'image/png',
        )).reference.handle;
      }
      final cryHandle = battleCry == null
          ? null
          : (await api.artifacts.put(
              battleCry.bytes,
              declaredMediaType: battleCry.mediaType,
            )).reference.handle;
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operation,
          actionId: actionId,
          actionVersion: 1,
          extensions:
              mediaOnly ||
                  session.storage == ProjectSessionStorage.workingCatalog
              ? {
                  'workshopScope': true,
                  'workshopReadDependencies': {
                    for (final dependency in dependencies)
                      dependency.resourceIdentity: dependency.relativePath,
                  },
                  if (gifHandles.isNotEmpty) 'battleGifArtifacts': gifHandles,
                  if (pngHandles.isNotEmpty) 'pokemonPngArtifacts': pngHandles,
                  'battleCryArtifact': ?cryHandle,
                }
              : const {},
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: operation,
          parameters: parameters,
        ),
      );
      if (!planned.applicable) {
        if (planned.nonApplicableReason == 'no_changes') {
          return mediaOnly ? documents.single.beforeBytes : null;
        }
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
      } on Object catch (failure, stack) {
        if (mediaOnly) {
          final status = await api.recoveryStatus(
            opened.projectHandle,
            operationId: operation,
          );
          if (status['disposition'] == 'notFound') {
            Error.throwWithStackTrace(failure, stack);
          }
        }
        try {
          final recovered = await api.recoverMutation(
            opened.projectHandle,
            operationId: operation,
          );
          if (recovered.receipt.extensions['recoveryOutcome'] != 'resumed' &&
              !(mediaOnly && recovered.receipt.status.name == 'applied')) {
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
      List<int>? savedMediaBytes;
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
          if (mediaOnly && change.storageKey == documents.single.relativePath) {
            savedMediaBytes = List.unmodifiable(actual);
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
            actionId: actionId,
          ),
        );
      } on Object catch (failure) {
        throw PokemonWorkspaceFailure(
          'Écriture confirmée ; vérification ou actualisation impossible. '
          'Rouvrez le projet avant de continuer : $failure',
        );
      }
      if (mediaOnly && savedMediaBytes == null) {
        throw const PokemonWorkspaceFailure(
          'Écriture confirmée mais préimage enregistrée indisponible. '
          'Rouvrez le projet avant de continuer.',
        );
      }
      return savedMediaBytes;
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
