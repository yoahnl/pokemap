import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/authoring_query_adapter.dart';
import '../../../application/authoring_api/editor_receipt_presenter.dart';
import 'smart_tile_mutation_identity.dart';

final class SmartTileLayerPresetChangeCanonicalPlan {
  SmartTileLayerPresetChangeCanonicalPlan({
    required this.token,
    required this.planId,
    required this.projectRootPath,
    required this.mapId,
    required this.layerId,
    required this.targetPresetId,
    required this.remappedEntryCount,
    required this.clearedCandidateWeightCount,
    required Map<String, String> materialMappings,
  }) : materialMappings = Map<String, String>.unmodifiable(materialMappings);

  final Object token;
  final String planId;
  final String projectRootPath;
  final String mapId;
  final String layerId;
  final String targetPresetId;
  final int remappedEntryCount;
  final int clearedCandidateWeightCount;
  final Map<String, String> materialMappings;
}

final class SmartTileLayerPresetChangeCanonicalResult {
  const SmartTileLayerPresetChangeCanonicalResult({
    required this.manifest,
    required this.map,
    required this.mapRevision,
    required this.layerId,
    required this.receiptId,
    required this.targetPresetId,
    required this.materialMappings,
  });

  final ProjectManifest manifest;
  final MapData map;
  final String mapRevision;
  final String layerId;
  final String receiptId;
  final String targetPresetId;
  final Map<String, String> materialMappings;
}

abstract interface class SmartTileLayerPresetChangeGateway {
  Future<SmartTileLayerPresetChangeCanonicalPlan> planChange({
    required String projectRootPath,
    required String mapId,
    required String layerId,
    required String targetPresetId,
    required Map<String, String> materialMappings,
  });

  Future<SmartTileLayerPresetChangeCanonicalResult> applyChange({
    required SmartTileLayerPresetChangeCanonicalPlan plan,
  });
}

final class CanonicalSmartTileLayerPresetChangeGateway
    implements SmartTileLayerPresetChangeGateway {
  CanonicalSmartTileLayerPresetChangeGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  }) : _mutations = mutations,
       _queries = queries,
       _sessionToken = newSmartTileMutationSessionToken();

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;
  final String _sessionToken;

  @override
  Future<SmartTileLayerPresetChangeCanonicalPlan> planChange({
    required String projectRootPath,
    required String mapId,
    required String layerId,
    required String targetPresetId,
    required Map<String, String> materialMappings,
  }) async {
    final session = await _queries.open(projectRootPath);
    final parameters = <String, Object?>{
      'mapId': mapId,
      'layerId': layerId,
      'targetPresetId': targetPresetId,
      if (materialMappings.isNotEmpty) 'materialMappings': materialMappings,
    };
    final identity = smartTileMutationIdentity(
      purpose: 'smart-tile-layer-change-preset',
      sessionToken: _sessionToken,
      values: <String, Object?>{
        ...parameters,
        'snapshotRevision': session.snapshotRevision,
      },
    );
    final plan = await _mutations.plan(
      projectRootPath,
      actionId: 'smart_tile.layer.change_preset',
      parameters: parameters,
      expectedRevision: session.snapshotRevision,
      idempotencyKey: identity,
      requestId: identity,
    );
    return SmartTileLayerPresetChangeCanonicalPlan(
      token: plan,
      planId: plan.planId,
      projectRootPath: projectRootPath,
      mapId: mapId,
      layerId: layerId,
      targetPresetId: targetPresetId,
      remappedEntryCount: _previewCount(plan.preview, 'remappedEntryCount'),
      clearedCandidateWeightCount: _previewCount(
        plan.preview,
        'clearedCandidateWeightCount',
      ),
      materialMappings: _previewMappings(plan.preview['materialMappings']),
    );
  }

  @override
  Future<SmartTileLayerPresetChangeCanonicalResult> applyChange({
    required SmartTileLayerPresetChangeCanonicalPlan plan,
  }) async {
    final token = plan.token;
    if (token is! EditorAuthoringMutationPlan) {
      throw StateError('The canonical preset change plan token is invalid.');
    }
    final applied = await _mutations.apply(
      token,
      operationId: '${plan.planId}-apply',
    );
    final session = await _queries.open(plan.projectRootPath);
    if (session.snapshotRevision != applied.snapshotRevision) {
      throw const EditorAuthoringMutationFailure(
        code: 'smart_tile.layer_preset_snapshot_stale',
        message: 'Le snapshot canonique relu après le changement est obsolète.',
      );
    }
    final map = session.mapById(plan.mapId);
    final mapRevision = session.resourceRevision('map:${plan.mapId}');
    final layer = map?.layers
        .whereType<SmartTileLayer>()
        .where((candidate) => candidate.id == plan.layerId)
        .firstOrNull;
    if (map == null || mapRevision == null || layer == null) {
      throw const EditorAuthoringMutationFailure(
        code: 'smart_tile.layer_preset_snapshot_incomplete',
        message: 'Le calque modifié est absent du snapshot canonique relu.',
      );
    }
    if (layer.presetId != plan.targetPresetId) {
      throw const EditorAuthoringMutationFailure(
        code: 'smart_tile.layer_preset_not_applied',
        message: 'Le motif demandé n’est pas actif dans le snapshot canonique.',
      );
    }
    return SmartTileLayerPresetChangeCanonicalResult(
      manifest: session.manifest,
      map: map,
      mapRevision: mapRevision,
      layerId: layer.id,
      receiptId: applied.receipt.receiptId,
      targetPresetId: plan.targetPresetId,
      materialMappings: plan.materialMappings,
    );
  }
}

int _previewCount(Map<String, Object?> preview, String key) {
  final value = preview[key];
  return value is num ? value.toInt() : 0;
}

Map<String, String> _previewMappings(Object? value) {
  if (value is! Map) return const <String, String>{};
  return Map<String, String>.unmodifiable(<String, String>{
    for (final entry in value.entries)
      if (entry.key is String && entry.value is String)
        entry.key as String: entry.value as String,
  });
}
