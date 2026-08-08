import 'package:map_authoring/map_authoring.dart';

import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/authoring_query_adapter.dart';
import '../../../application/authoring_api/editor_receipt_presenter.dart';
import 'smart_tile_publication_service.dart';

final class SmartTilePresetDeletionCanonicalPlan {
  const SmartTilePresetDeletionCanonicalPlan({
    required this.token,
    required this.planId,
  });

  final Object token;
  final String planId;
}

abstract interface class SmartTilePresetDeletionGateway {
  Future<SmartTilePublicationCanonicalSnapshot> load({
    required String projectRootPath,
  });

  Future<SmartTilePresetDeletionCanonicalPlan> planDelete({
    required String projectRootPath,
    required String presetId,
    required String expectedRevision,
    required String idempotencyKey,
  });

  Future<String> confirmAndApply({
    required SmartTilePresetDeletionCanonicalPlan plan,
    required String operationId,
  });
}

final class CanonicalSmartTilePresetDeletionGateway
    implements SmartTilePresetDeletionGateway {
  const CanonicalSmartTilePresetDeletionGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  })  : _mutations = mutations,
        _queries = queries;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;

  @override
  Future<SmartTilePublicationCanonicalSnapshot> load({
    required String projectRootPath,
  }) async {
    final session = await _queries.open(projectRootPath);
    return SmartTilePublicationCanonicalSnapshot(
      snapshotRevision: session.snapshotRevision,
      manifest: session.manifest,
      maps: session.maps,
      mapRevisions: <String, String>{
        for (final map in session.maps)
          if (session.resourceRevision('map:${map.id}') case final revision?)
            map.id: revision,
      },
    );
  }

  @override
  Future<SmartTilePresetDeletionCanonicalPlan> planDelete({
    required String projectRootPath,
    required String presetId,
    required String expectedRevision,
    required String idempotencyKey,
  }) async {
    final plan = await _mutations.plan(
      projectRootPath,
      actionId: 'smart_tile.preset.delete',
      parameters: <String, Object?>{'presetId': presetId},
      expectedRevision: expectedRevision,
      idempotencyKey: idempotencyKey,
      requestId: idempotencyKey,
    );
    return SmartTilePresetDeletionCanonicalPlan(
      token: plan,
      planId: plan.planId,
    );
  }

  @override
  Future<String> confirmAndApply({
    required SmartTilePresetDeletionCanonicalPlan plan,
    required String operationId,
  }) async {
    final token = plan.token;
    if (token is! EditorAuthoringMutationPlan) {
      throw StateError('The canonical deletion plan token is invalid.');
    }
    final confirmationToken = await _mutations.confirm(token);
    final result = await _mutations.apply(
      token,
      operationId: operationId,
      confirmationToken: confirmationToken,
    );
    return result.snapshotRevision;
  }
}

final class SmartTilePresetDeletionException implements Exception {
  const SmartTilePresetDeletionException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'SmartTilePresetDeletionException($code): $message';
}

/// Suppression confirmée d'un preset via l'action canonique à haut risque.
final class SmartTilePresetDeletionService {
  const SmartTilePresetDeletionService({
    required SmartTilePresetDeletionGateway gateway,
  }) : _gateway = gateway;

  final SmartTilePresetDeletionGateway _gateway;

  Future<SmartTilePublicationCanonicalSnapshot> deletePreset({
    required String projectRootPath,
    required String presetId,
  }) async {
    final before = await _gateway.load(projectRootPath: projectRootPath);
    final identity = computeAuthoringJsonFingerprint(
      <String, Object?>{
        'presetId': presetId,
        'revision': before.snapshotRevision,
      },
      logicalName: 'smart-tile-preset-deletion.json',
    ).substring('sha256:'.length, 39);
    late final SmartTilePresetDeletionCanonicalPlan plan;
    try {
      plan = await _gateway.planDelete(
        projectRootPath: projectRootPath,
        presetId: presetId,
        expectedRevision: before.snapshotRevision,
        idempotencyKey: 'smart-tile-preset-delete-$identity',
      );
    } on Object catch (error) {
      final failure = EditorAuthoringMutationFailure.capture(error);
      if (failure.code == 'smart_tile.preset.references_blocking') {
        throw EditorAuthoringMutationFailure(
          code: failure.code,
          message:
              'Ce Smart Tile est encore utilisé par une ou plusieurs couches. Retirez ces couches avant de le supprimer.',
          remediation: const <String>[
            'Recherchez les couches qui utilisent ce Smart Tile.',
            'Supprimez-les ou choisissez un autre Smart Tile, puis réessayez.',
          ],
          original: error,
        );
      }
      throw failure;
    }
    final operationId = '${plan.planId}-apply';
    final appliedRevision = await _gateway.confirmAndApply(
      plan: plan,
      operationId: operationId,
    );
    final canonical = await _gateway.load(projectRootPath: projectRootPath);
    if (canonical.snapshotRevision != appliedRevision) {
      throw const SmartTilePresetDeletionException(
        'smart_tile.preset.delete.snapshot_stale',
        'Le snapshot canonique chargé après suppression est obsolète.',
      );
    }
    if (canonical.manifest.smartTileCatalog.presets
        .any((preset) => preset.id == presetId)) {
      throw const SmartTilePresetDeletionException(
        'smart_tile.preset.delete.still_present',
        'Le Smart Tile est toujours présent après la suppression canonique.',
      );
    }
    return canonical;
  }
}
