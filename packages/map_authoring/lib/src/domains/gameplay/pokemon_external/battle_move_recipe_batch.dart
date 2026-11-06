import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../../api/local_map_authoring_mutation_api.dart';
import '../../../catalog_storage/catalog_storage_store.dart';
import '../../../contracts/authoring_request.dart';
import '../../../documents/document_errors.dart';
import '../../../ports/transaction_file_gateway.dart';
import '../../../transactions/recovery_service.dart';
import '../../../workspace/project_open_service.dart';
import '../../../workspace/workspace_handle_store.dart';
import 'avelune_move_recipe_source.dart';
import 'avelune_catalog_release.dart';
import 'avelune_pokemon_media_source.dart';
import 'battle_move_recipe_inventory.dart';
import 'battle_move_recipe_selection.dart';
import 'pokemon_external_http_transport.dart';

typedef BattleRecipeMutationGuard = Future<T> Function<T>(
    Future<T> Function() action);

final class BattleMoveRecipeBatchService {
  const BattleMoveRecipeBatchService({
    required this.openService,
    required this.authoring,
    required this.client,
  });

  final ProjectOpenService openService;
  final LocalMapAuthoringMutationApi authoring;
  final PokemonBoundedExternalHttpTransport client;

  Future<BattleMoveRecipeBatchResult> run({
    required ProjectHandle projectHandle,
    required WorkspaceHandle workspaceHandle,
    required String operationId,
    int startIndex = 0,
    int limit = BattleMoveRecipeBatchImporter.maximumBatchSize,
    String? expectedInventoryRevision,
    bool Function()? isCancelled,
  }) async {
    final reader = await openService
        .catalogProject(projectHandle, metadataFields: const {'pokemon'});
    if (reader == null) {
      throw const FormatException('A working project catalog is required.');
    }
    final manifest = await reader.readMetadata(const {'pokemon'});
    final media = AvelunePokemonMediaSource(
      client: client,
      release: manifest.pokemon.catalogRelease ?? aveluneCatalogRelease,
    );
    return BattleMoveRecipeBatchImporter(
            openService: openService, authoring: authoring, media: media)
        .run(
      projectHandle: projectHandle,
      workspaceHandle: workspaceHandle,
      operationId: operationId,
      startIndex: startIndex,
      limit: limit,
      expectedInventoryRevision: expectedInventoryRevision,
      isCancelled: isCancelled,
    );
  }
}

enum BattleMoveRecipeBatchStatus {
  imported,
  alreadyPresent,
  preserved,
  missing,
  ambiguous,
  custom,
  uncertain,
  failed,
}

final class BattleMoveRecipeBatchEntry {
  const BattleMoveRecipeBatchEntry({
    required this.index,
    required this.projectMoveId,
    required this.status,
    this.reason,
    this.receiptId,
    this.operationId,
    this.changeNotification,
    this.isPilotFallback = false,
  });

  final int index;
  final String? projectMoveId;
  final BattleMoveRecipeBatchStatus status;
  final String? reason;
  final String? receiptId;
  final String? operationId;
  final Map<String, Object?>? changeNotification;
  final bool isPilotFallback;

  Map<String, Object?> toJson() => {
        'index': index,
        'projectMoveId': projectMoveId,
        'status': status.name,
        if (reason != null) 'reason': reason,
        if (receiptId != null) 'receiptId': receiptId,
        if (operationId != null) 'operationId': operationId,
        if (changeNotification != null)
          'changeNotification': changeNotification,
        if (isPilotFallback) 'pilotFallback': true,
      };
}

final class BattleMoveRecipeBatchResult {
  const BattleMoveRecipeBatchResult({
    required this.total,
    required this.nextIndex,
    required this.results,
    required this.inventoryRevision,
    this.stopped,
  });

  final int total;
  final int nextIndex;
  final List<BattleMoveRecipeBatchEntry> results;
  final String inventoryRevision;
  final String? stopped;
  int get remaining => total - nextIndex;

  Map<String, Object?> toJson() => {
        'total': total,
        'nextIndex': nextIndex,
        'remaining': remaining,
        'results': [for (final result in results) result.toJson()],
        'inventoryRevision': inventoryRevision,
        if (stopped != null) 'stopped': stopped,
      };
}

final class BattleMoveRecipeBatchImporter {
  const BattleMoveRecipeBatchImporter({
    required this.openService,
    required this.authoring,
    required this.media,
    this.withMutation,
  });

  static const maximumBatchSize = 10;
  static const _limits = BattleRecipeBundleLimits(
    maxTextures: 256,
    maxTextureBytes: 8 * 1024 * 1024,
    maxBundleBytes: 64 * 1024 * 1024,
    maxDimension: 2048,
    maxTexturePixels: 4000000,
    maxTotalPixels: 16000000,
  );

  final ProjectOpenService openService;
  final LocalMapAuthoringMutationApi authoring;
  final AvelunePokemonMediaSource media;
  final BattleRecipeMutationGuard? withMutation;

  Future<BattleMoveRecipeBatchResult> run({
    required ProjectHandle projectHandle,
    required WorkspaceHandle workspaceHandle,
    required String operationId,
    int startIndex = 0,
    int limit = maximumBatchSize,
    String? expectedInventoryRevision,
    bool Function()? isCancelled,
    void Function(BattleMoveRecipeBatchEntry entry)? onProgress,
  }) async {
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.:@-]{0,127}$')
            .hasMatch(operationId) ||
        startIndex < 0 ||
        limit < 1 ||
        limit > maximumBatchSize ||
        (startIndex > 0 && expectedInventoryRevision == null)) {
      throw const FormatException('Invalid move recipe batch request.');
    }
    void check() {
      if (isCancelled?.call() == true) throw const _BatchCancelled();
    }

    authoring.authorizePokemonRecipeBatch(projectHandle, workspaceHandle);
    final inventory = await BattleMoveRecipeInventoryReader(openService)
        .read(projectHandle, startIndex: startIndex, limit: limit);
    final inventoryRevision = 'sha256:${sha256.convert(utf8.encode(jsonEncode({
          'movesRevision': inventory.movesRevision,
          'movesPath': inventory.movesPath,
          'catalogRelease': inventory.catalogRelease,
        })))}';
    if (inventory.movesRevision == null ||
        (expectedInventoryRevision != null &&
            expectedInventoryRevision != inventoryRevision)) {
      throw const CatalogStorageException('catalog.revision_conflict',
          'The move catalog changed; restart the inventory.');
    }
    if (isCancelled?.call() == true) {
      return BattleMoveRecipeBatchResult(
        total: inventory.total,
        nextIndex: startIndex,
        results: const [],
        inventoryRevision: inventoryRevision,
        stopped: 'cancelled',
      );
    }
    if (media.release != inventory.catalogRelease ||
        startIndex > inventory.total) {
      throw const FormatException(
          'Move recipe batch does not match the project.');
    }
    String? notReady;
    try {
      await authoring.requirePokemonRecipeBatchReady(projectHandle);
    } on TransactionFileGatewayException catch (error) {
      if (error.code != 'transaction.pending_index_preparation_required') {
        rethrow;
      }
      notReady = 'preparationRequired';
    } on AuthoringRecoveryException catch (error) {
      if (error.code != 'resource_pack.recovery_required') rethrow;
      notReady = 'recoveryRequired';
    }
    if (notReady != null || isCancelled?.call() == true) {
      return BattleMoveRecipeBatchResult(
        total: inventory.total,
        nextIndex: startIndex,
        results: const [],
        inventoryRevision: inventoryRevision,
        stopped: notReady ?? 'cancelled',
      );
    }
    final source = BattleMoveRecipeCatalogSource(media);
    final results = <BattleMoveRecipeBatchEntry>[];
    var next = startIndex;
    String? stopped;
    void notify(BattleMoveRecipeBatchEntry entry) {
      try {
        onProgress?.call(entry);
      } on Object {
        stopped = 'progressError';
      }
    }

    final end = startIndex + inventory.moves.length;
    while (next < end) {
      final entry = inventory.moves[next - startIndex];
      final id =
          'bw2_${sha256.convert(utf8.encode('$operationId:${entry.index}:${entry.projectMoveId}'))}';
      var localPhase = false;
      var applyStarted = false;
      try {
        check();
        final selected = await inventory.select(entry, source, check: check);
        check();
        BattleMoveRecipeBatchEntry result;
        if (selected.status != BattleMoveRecipeSelectionStatus.available) {
          result = BattleMoveRecipeBatchEntry(
            index: entry.index,
            projectMoveId: entry.projectMoveId,
            status:
                BattleMoveRecipeBatchStatus.values.byName(selected.status.name),
            reason: selected.status == BattleMoveRecipeSelectionStatus.uncertain
                ? entry.reason.name
                : null,
            isPilotFallback: selected.isPilotFallback,
          );
        } else {
          final candidate = selected.candidate!;
          final fetched = await AveluneMoveRecipeSource(media).fetch(
            catalogMoveId: candidate.catalogMoveId,
            sourceMoveId: candidate.binding.sourceMoveId,
            projectMoveId: entry.projectMoveId!,
            mediaId: candidate.mediaId,
            limits: _limits,
            availableCapabilities:
                BattleMoveAnimationRecipe.recognizedCapabilities,
            check: check,
          );
          check();
          final expected = candidate.binding.toJson();
          final actual = fetched.binding.toJson();
          if (expected.entries
              .any((value) => actual[value.key] != value.value)) {
            throw const FormatException('Move recipe changed during download.');
          }
          Future<BattleMoveRecipeBatchEntry> apply() async {
            check();
            final staged = <String>[];
            try {
              final recipe =
                  await authoring.artifacts.put(fetched.bundle.recipeBytes);
              staged.add(recipe.reference.handle);
              final resources = <Map<String, Object?>>[];
              for (final resource in fetched.bundle.recipe.resources) {
                check();
                final item = await authoring.artifacts
                    .put(fetched.bundle.media[resource.id]!);
                staged.add(item.reference.handle);
                resources.add({
                  'id': resource.id,
                  'sha256': resource.sha256Hex,
                  'mediaType': resource.mediaType,
                  'artifactHandle': item.reference.handle,
                });
              }
              check();
              final parameters = <String, Object?>{
                'projectBinding': BattleRecipeProjectBinding(
                  binding: fetched.binding,
                  catalogMoveId: fetched.catalogMoveId,
                  recipeMediaId: fetched.recipeMediaId,
                ).toJson(),
                'recipeHandle': recipe.reference.handle,
                'resources': resources,
              };
              final snapshot = await authoring.readWorkshopSnapshot(
                  projectHandle,
                  actionId: 'pokemon.move_recipe.import',
                  parameters: parameters);
              final scope = snapshot.scopedStorageRevisions;
              final bindingPath = battleRecipeBindingPath(entry.projectMoveId!);
              if (scope == null ||
                  inventory.movesPath == null ||
                  (snapshot.manifest.pokemon.catalogRelease ??
                          aveluneCatalogRelease) !=
                      inventory.catalogRelease ||
                  scope[inventory.movesPath] != inventory.movesRevision ||
                  !scope.containsKey(bindingPath) ||
                  scope[bindingPath] != entry.bindingRevision) {
                throw const _BatchConflict();
              }
              check();
              final plan = await authoring.planMutation(
                  projectHandle,
                  AuthoringRequest(
                    requestId: id,
                    actionId: 'pokemon.move_recipe.import',
                    actionVersion: 1,
                    workspaceHandle: workspaceHandle.value,
                    expectedRevision: snapshot.revision,
                    idempotencyKey: id,
                    parameters: parameters,
                    extensions: const {'workshopScope': true},
                  ));
              check();
              if (!plan.applicable) {
                if (plan.nonApplicableReason != 'no_changes') {
                  throw StateError('Move recipe import is not applicable.');
                }
                return BattleMoveRecipeBatchEntry(
                    index: entry.index,
                    projectMoveId: entry.projectMoveId,
                    status: BattleMoveRecipeBatchStatus.alreadyPresent);
              }
              applyStarted = true;
              final applied = await authoring.applyMutation(projectHandle,
                  planId: plan.planId,
                  operationId: id,
                  precondition: () async => check());
              if (applied.diagnostic != null) stopped = 'refreshRequired';
              final notification = applied.toJson()['changeNotification'];
              return BattleMoveRecipeBatchEntry(
                  index: entry.index,
                  projectMoveId: entry.projectMoveId,
                  status: BattleMoveRecipeBatchStatus.imported,
                  receiptId: applied.receipt.receiptId,
                  operationId: id,
                  changeNotification: notification is Map
                      ? Map<String, Object?>.from(notification)
                      : null,
                  isPilotFallback: selected.isPilotFallback);
            } finally {
              for (final handle in staged) {
                await authoring.artifacts.release(handle);
              }
            }
          }

          localPhase = true;
          result =
              withMutation == null ? await apply() : await withMutation!(apply);
        }
        results.add(result);
        next++;
        notify(result);
        if (stopped != null) break;
      } on _BatchCancelled {
        stopped = 'cancelled';
        break;
      } on Object catch (error) {
        if (!applyStarted && isCancelled?.call() == true) {
          stopped = 'cancelled';
          break;
        }
        final network = error is SocketException ||
            error is HttpException ||
            error is TimeoutException ||
            error is EditorPersistenceException;
        final conflict = error is _BatchConflict;
        final preparationRequired = error is TransactionFileGatewayException &&
            error.code == 'transaction.pending_index_preparation_required';
        final result = BattleMoveRecipeBatchEntry(
          index: entry.index,
          projectMoveId: entry.projectMoveId,
          status: BattleMoveRecipeBatchStatus.failed,
          reason: applyStarted
              ? 'recoveryRequired'
              : network
                  ? 'network'
                  : conflict
                      ? 'projectChanged'
                      : preparationRequired
                          ? 'preparationRequired'
                          : localPhase
                              ? 'authoringError'
                              : 'invalidOrUnavailable',
          operationId: applyStarted ? id : null,
        );
        results.add(result);
        next++;
        notify(result);
        if (network || conflict || localPhase || applyStarted) {
          stopped = result.reason;
          break;
        }
      }
    }
    return BattleMoveRecipeBatchResult(
      total: inventory.total,
      nextIndex: next,
      results: List.unmodifiable(results),
      inventoryRevision: inventoryRevision,
      stopped: stopped,
    );
  }
}

final class _BatchCancelled implements Exception {
  const _BatchCancelled();
}

final class _BatchConflict implements Exception {
  const _BatchConflict();
}
