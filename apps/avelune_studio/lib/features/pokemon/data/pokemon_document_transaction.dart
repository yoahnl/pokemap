import 'dart:convert';
import 'dart:math';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart' show ProjectManifest;
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
import 'pokemon_document_write_request.dart';

export 'pokemon_document_write_request.dart';

part 'pokemon_document_transaction_commit.dart';
part 'pokemon_document_transaction_session.dart';
part 'pokemon_document_transaction_writes.dart';

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
    final (:writes, :changedPaths, :dependencies) = await _plannedWrites(
      documents,
      expectedDependencies: expectedDependencies,
      migrateMedia: migrateMedia,
    );
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
    final (:handles, :opened, :snapshots, :api) = await _openTransaction(
      mediaOnly,
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
      _requireSnapshotDependencies(snapshot, dependencies);
      final operation =
          'pokemon_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      final (:gifHandles, :pngHandles, :cryHandle) = await _putArtifacts(
        api,
        battleGifs: battleGifs,
        pokemonPngs: pokemonPngs,
        battleCry: battleCry,
      );
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
      final changes = _plannedChanges(planned, changedPaths);
      await _applyOrRecover(
        api: api,
        opened: opened,
        planned: planned,
        operation: operation,
        dependencies: dependencies,
        mediaOnly: mediaOnly,
      );
      return await _verifyCommitted(
        changes: changes,
        documents: documents,
        mediaOnly: mediaOnly,
        baseline: baseline,
        operation: operation,
        actionId: actionId,
      );
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }
}
