import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../../api/local_map_authoring_mutation_api.dart';
import '../../../contracts/authoring_request.dart';
import '../../../workspace/workspace_handle_store.dart';
import 'avelune_gen5_battle_source.dart';
import 'gen5_battle_source_bundle_builder.dart';

enum AveluneGen5ImportStatus { imported, alreadyPresent, unavailable }

final class AveluneGen5BattleSourceImport {
  const AveluneGen5BattleSourceImport({
    required this.source,
    required this.authoring,
    required this.projectHandle,
    required this.workspaceHandle,
  });

  final AveluneGen5BattleSource source;
  final LocalMapAuthoringMutationApi authoring;
  final ProjectHandle projectHandle;
  final WorkspaceHandle workspaceHandle;

  Future<
      ({
        AveluneGen5ImportStatus status,
        String? receiptId,
        bool refreshRequired
      })> import({
    required String sourceSpecies,
    required String projectSpeciesId,
    required int nationalDex,
    required String speciesPath,
    required String operationId,
    bool Function()? isCurrent,
  }) async {
    void requireCurrent() {
      if (isCurrent?.call() == false) {
        throw StateError('The selected species changed before import.');
      }
    }

    requireCurrent();
    final fetched =
        await source.fetch(species: sourceSpecies, nationalDex: nationalDex);
    requireCurrent();
    if (fetched == null) {
      return (
        status: AveluneGen5ImportStatus.unavailable,
        receiptId: null,
        refreshRequired: false
      );
    }
    final bundle = gen5BattleSourceBundleFromSnapshot(fetched);
    final binding = Gen5BattleSourceBinding.fromBundle(
      projectSpeciesId: projectSpeciesId,
      projectNationalDex: nationalDex,
      bundle: bundle,
    );
    final staged = await authoring.artifacts.put(
      bundle.encode(),
      declaredMediaType: 'application/json',
    );
    try {
      requireCurrent();
      final parameters = <String, Object?>{
        'binding': jsonDecode(utf8.decode(binding.encode())),
        'bundleHandle': staged.reference.handle,
        'speciesPath': speciesPath,
      };
      final snapshot = await authoring.readWorkshopSnapshot(projectHandle,
          actionId: 'pokemon.gen5_battle_source.import',
          parameters: parameters);
      requireCurrent();
      final plan = await authoring.planMutation(
          projectHandle,
          AuthoringRequest(
            requestId: operationId,
            actionId: 'pokemon.gen5_battle_source.import',
            actionVersion: 1,
            workspaceHandle: workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: operationId,
            parameters: parameters,
            extensions: const {'workshopScope': true},
          ));
      requireCurrent();
      if (!plan.applicable) {
        if (plan.nonApplicableReason != 'no_changes') {
          throw StateError(
              'Gen 5 import plan is not applicable: ${plan.nonApplicableReason}');
        }
        return (
          status: AveluneGen5ImportStatus.alreadyPresent,
          receiptId: null,
          refreshRequired: false,
        );
      }
      final applied = await authoring.applyMutation(projectHandle,
          planId: plan.planId,
          operationId: operationId,
          precondition: () async => requireCurrent());
      return (
        status: AveluneGen5ImportStatus.imported,
        receiptId: applied.receipt.receiptId,
        refreshRequired: applied.diagnostic != null,
      );
    } finally {
      await authoring.artifacts.release(staged.reference.handle);
    }
  }
}
