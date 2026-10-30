import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'border_actions.dart';
import 'semantic_map_action_support.dart';
import 'map_action_examples.dart';

final class BorderMaterializationBatchActions {
  const BorderMaterializationBatchActions();

  static const maximumFeatureCount = 128;
  static final descriptor = AuthoringActionDescriptor(
    id: 'border_layer.materialize_batch_apply',
    version: 1,
    summary: 'Resolve and persist a bounded atomic batch of Border features',
    inputSchemaId: 'schema.border_layer.materialize_batch_apply.input.v1',
    outputSchemaId: 'schema.map.semantic_mutation.output.v1',
    riskLevel: AuthoringRiskLevel.low,
    resourceKinds: const ['map', 'borderBlueprint', 'model3d', 'element'],
    requiredPermissions: const [AuthoringPermission.projectWrite],
    guarantees: const [
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
    ],
    extensions: {
      'inputExample': mapActionInputExample('border_layer.materialize_batch_apply'),
      'batchAtomicity': 'all_or_nothing',
      'maximumFeatureCount': maximumFeatureCount,
      'semanticIds': true,
      'rawTilesetRequired': false,
      'visualKinds': ['element', 'model3d'],
      'undoBoundary': 'batch',
      'inputSchema': {
        'type': 'object',
        'additionalProperties': false,
        'required': [
          'mapId',
          'features',
          'tileWidthPx',
          'tileHeightPx',
          'resolverVersion'
        ],
        'properties': {
          'mapId': {'type': 'string', 'minLength': 1},
          'features': {
            'type': 'array',
            'minItems': 1,
            'maxItems': maximumFeatureCount,
            'items': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['layerId', 'featureId'],
              'properties': {
                'layerId': {'type': 'string', 'minLength': 1},
                'featureId': {'type': 'string', 'minLength': 1},
              },
            },
          },
          'tileWidthPx': {'type': 'integer', 'minimum': 1},
          'tileHeightPx': {'type': 'integer', 'minimum': 1},
          'resolverVersion': {'type': 'integer', 'minimum': 1},
        },
      },
    },
  );

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final context = SemanticMapActionContext.read(planning, allowedParameters: {
      'features',
      'tileWidthPx',
      'tileHeightPx',
      'resolverVersion',
    });
    final parameters = context.parameters;
    final rawTargets = parameters.list('features');
    if (rawTargets.isEmpty || rawTargets.length > maximumFeatureCount) {
      throw semanticFailure('border.batch_bounds_exceeded',
          'A Border materialization batch requires between 1 and 128 features.');
    }
    final width = parameters.integer('tileWidthPx');
    final height = parameters.integer('tileHeightPx');
    final resolverVersion = parameters.integer('resolverVersion');
    if (width <= 0 || height <= 0 || resolverVersion <= 0) {
      throw semanticFailure('map.request_invalid',
          'Tile dimensions and resolver version must be positive integers.');
    }
    final targets = <({String layerId, String featureId})>[];
    final seen = <(String, String)>{};
    for (final raw in rawTargets) {
      if (raw is! Map || raw.keys.any((key) => key is! String)) {
        throw semanticFailure('map.request_invalid',
            'Each Border target must contain a layer ID and feature ID.');
      }
      final target = SemanticParameters(Map<String, Object?>.from(raw),
          allowed: {'layerId', 'featureId'});
      final layerId = target.string('layerId');
      final featureId = target.string('featureId');
      if (!seen.add((layerId, featureId))) {
        throw semanticFailure('border.batch_duplicate_target',
            'A Border feature may occur only once in a materialization batch.');
      }
      targets.add((layerId: layerId, featureId: featureId));
    }
    var updated = context.map;
    var changedItems = 0;
    final warnings = <Map<String, Object?>>[];
    const border = BorderActions();
    for (final target in targets) {
      final artifact = border.preview(
        manifest: context.manifest,
        map: updated,
        layerId: target.layerId,
        featureId: target.featureId,
        projectRevision: context.resource.revision!,
        tileSizePx: updated.spatialScene == null
            ? GridSize(width: width, height: height)
            : GridSize(
                width: context.manifest.settings.tileWidth,
                height: context.manifest.settings.tileHeight),
        resolverVersion: resolverVersion,
      );
      if (!artifact.result.canApply) {
        throw semanticFailure('border.materialization_failed',
            'Border diagnostics prevent the entire materialization batch.',
            details: {
              'layerId': target.layerId,
              'featureId': target.featureId,
              'errorCount': artifact.result.diagnosticReport.errorCount,
              'diagnostics': artifact.result.diagnostics
                  .take(20)
                  .map((diagnostic) => diagnostic.code)
                  .toList(),
              'diagnosticDetails': [
                for (final diagnostic in artifact.result.diagnostics.take(20))
                  {
                    'code': diagnostic.code,
                    'severity': diagnostic.severity.name,
                    if (diagnostic.slotKey != null)
                      'slotKey': diagnostic.slotKey,
                    if (diagnostic.cell case final cell?)
                      'cell': {'x': cell.x, 'y': cell.y},
                    if (diagnostic.parameters.isNotEmpty)
                      'parameters': diagnostic.parameters,
                    'suggestedAction': diagnostic.suggestedAction,
                  },
              ],
            });
      }
      warnings.addAll(artifact.warningPreview);
      if (artifact.isSpatial) {
        updated = applySpatialBorderFeaturePreview(updated,
            manifest: context.manifest,
            proposedResult: SpatialBorderResolutionResult(
                mapId: updated.id,
                layerId: target.layerId,
                featureId: target.featureId,
                result: artifact.result,
                modelInstances: artifact.modelInstances));
        changedItems += artifact.modelInstances.length;
      } else {
        final layer = updated.layers
            .whereType<BorderLayer>()
            .singleWhere((layer) => layer.id == target.layerId);
        final feature = layer.content.featureById(target.featureId)!;
        final request = BorderResolutionRequest(
            mapSize: updated.size,
            tileSizePx: GridSize(width: width, height: height),
            blueprintId: feature.blueprintId,
            blueprintRevision: border.requirePublishedBlueprint(
                context.manifest, feature.blueprintId),
            feature: feature,
            visualSnapshots: context.manifest.borderCatalog.visualSnapshots,
            resolverVersion: resolverVersion);
        updated = applyBorderFeaturePreview(updated,
            expectedMapId: updated.id,
            layerId: target.layerId,
            featureId: target.featureId,
            expectedBaseFeatureFingerprint:
                computeBorderFeatureEditFingerprint(feature),
            proposedRequest: request,
            proposedResult: artifact.result);
        changedItems += artifact.result.materialization!.placements.length +
            artifact.result.materialization!.ground.length;
      }
    }
    return context.draftMap(
        after: updated,
        operation: planning.request.actionId,
        changedItems: changedItems,
        preview: {
          'featureCount': targets.length,
          'warningCount': warnings.length,
          'warnings': warnings
              .take(BorderPreviewArtifact.maximumWarningPreviewCount)
              .toList(),
          if (warnings.length > BorderPreviewArtifact.maximumWarningPreviewCount)
            'warningsTruncated': true,
        });
  }
}
