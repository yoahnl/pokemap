import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import 'map_lifecycle_adapter.dart';
import 'semantic_map_action_support.dart';
import 'smart_tile_native_transition_guard.dart';

/// Canonical Smart Tile maintenance actions shared by direct, JSONL, editor,
/// and MCP transports. These actions operate on semantic materials only; they
/// never rewrite resolved visual variants or depend on editor controllers.
final class SmartTileLayerActions {
  const SmartTileLayerActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    _smartTileLayerDescriptor(
      'smart_tile.layer.create',
      'Create a Smart Tile layer from one published preset',
      resourceKinds: const <String>[
        'map',
        'project',
        'smartTileLayer',
        'smartTilePreset',
      ],
    ),
    _smartTileLayerDescriptor(
      'smart_tile.layer.delete',
      'Delete one revision-checked Smart Tile layer',
      resourceKinds: const <String>['map', 'smartTileLayer'],
      risk: AuthoringRiskLevel.high,
    ),
    _smartTileLayerDescriptor(
      'smart_tile.layer.merge',
      'Union compatible Smart Tile layers into one target layer',
      resourceKinds: const <String>[
        'map',
        'smartTileLayer',
        'smartTilePreset',
      ],
    ),
    _smartTileLayerDescriptor(
      'smart_tile.layer.normalize',
      'Remove unused Smart Tile palette entries without changing geometry',
      resourceKinds: const <String>[
        'map',
        'smartTileLayer',
        'smartTileMaterial',
      ],
    ),
    _smartTileLayerDescriptor(
      'smart_tile.layer.reconstruct',
      'Reconstruct hidden native Smart Tile intent from a literal tile layer',
      resourceKinds: const <String>[
        'map',
        'tileLayer',
        'smartTileLayer',
        'smartTilePreset',
      ],
      risk: AuthoringRiskLevel.high,
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    return switch (planning.request.actionId) {
      'smart_tile.layer.create' => _create(planning),
      'smart_tile.layer.delete' => _delete(planning),
      'smart_tile.layer.normalize' => _normalize(planning),
      'smart_tile.layer.merge' => _merge(planning),
      'smart_tile.layer.reconstruct' => _reconstruct(planning),
      _ => throw semanticFailure(
          'map.action_unsupported',
          'The requested Smart Tile layer action is unsupported.',
          details: {'actionId': planning.request.actionId},
        ),
    };
  }

  AuthoringMutationDraft _create(AuthoringPlanningContext planning) {
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: const <String>{'presetId', 'layerId', 'name'},
    );
    final presetId = context.parameters.string('presetId');
    final layerId = context.parameters.string('layerId');
    final preset = _smartTilePreset(context.manifest, presetId);
    if (preset.status != SmartTilePresetStatus.published) {
      throw semanticFailure(
        'smart_tile.preset_not_published',
        'A Smart Tile layer can only be created from a published preset.',
        details: <String, Object?>{
          'presetId': presetId,
          'status': preset.status.name,
        },
        remediation: const <String>[
          'Publish the preset through smart_tile.preset.publish first.',
        ],
      );
    }
    final result = planNativeSmartTileLayerCreation(
      projectMaps: planning.snapshot.maps,
      targetMapId: context.map.id,
      manifest: context.manifest,
      preset: preset,
      layerId: layerId,
      layerName: context.parameters.string('name'),
    );
    if (result case final SmartTileLayerCreationFailure failure) {
      throw semanticFailure(failure.code, failure.message);
    }
    final success = result as SmartTileLayerCreationSuccess;
    preflightNativeSmartTileMutation(
      snapshot: planning.snapshot,
      projectedManifest: success.manifest,
      projectedMaps: <String, MapData>{context.map.id: success.map},
    );
    return _creationDraft(
      context,
      manifest: success.manifest,
      map: success.map,
      preset: preset,
      layerId: success.layerId,
    );
  }

  AuthoringMutationDraft _delete(AuthoringPlanningContext planning) {
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: const <String>{'layerId'},
    );
    final layerId = context.parameters.string('layerId');
    final layer = _smartTileLayer(context.map, layerId);
    final projected = context.map.copyWith(
      layers: <MapLayer>[
        for (final candidate in context.map.layers)
          if (candidate.id != layerId) candidate,
      ],
    );
    preflightNativeSmartTileMutation(
      snapshot: planning.snapshot,
      projectedManifest: context.manifest,
      projectedMaps: <String, MapData>{context.map.id: projected},
    );
    return context.draftMap(
      after: projected,
      operation: 'smart_tile.layer.delete',
      changedItems: smartTileAuthoredValueCount(layer) + 1,
      layerId: layerId,
      preview: <String, Object?>{
        'presetId': layer.presetId,
        'usage': layer.usage.name,
        'deletedLayer': true,
      },
    );
  }

  AuthoringMutationDraft _normalize(AuthoringPlanningContext planning) {
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: const {'layerId'},
    );
    final layerId = context.parameters.string('layerId');
    _requireNativeSmartTileProject(
      context,
      operation: 'smart_tile.layer.normalize',
      layerId: layerId,
    );
    final layer = _smartTileLayer(context.map, layerId);
    final result = normalizeSmartTileLayer(layer);
    final projected = replaceSmartTileLayer(context.map, layer: result.layer);

    return context.draft(
      SemanticMapEdit(
        map: projected,
        layerId: layerId,
        operation: 'smart_tile.layer.normalize',
        changedCells: result.reindexedEntryCount,
        preview: {
          'paletteSizeBefore': layer.materialPalette.length,
          'paletteSizeAfter': result.layer.materialPalette.length,
          'removedMaterialCount': result.removedPaletteEntries.length,
          'removedMaterials': [
            for (final entry in result.removedPaletteEntries) entry.toJson(),
          ],
          'reindexedEntryCount': result.reindexedEntryCount,
          'reindexedEntryCounts': result.reindexedEntryCounts,
          'renderPreserved': true,
        },
      ),
    );
  }

  AuthoringMutationDraft _merge(AuthoringPlanningContext planning) {
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: const {
        'sourceLayerIds',
        'targetLayerId',
        'mode',
        'removeSources',
        'conflictPolicy',
        'materialMappings',
      },
    );
    final parameters = context.parameters;
    final targetLayerId = parameters.string('targetLayerId');
    _requireNativeSmartTileProject(
      context,
      operation: 'smart_tile.layer.merge',
      layerId: targetLayerId,
    );
    if (parameters.string('mode') != 'union') {
      throw invalidSemanticField('mode', '"union"');
    }
    if (parameters.string('conflictPolicy') != 'reject') {
      throw invalidSemanticField('conflictPolicy', '"reject"');
    }
    final removeSources = parameters.boolean('removeSources');
    final sourceLayerIds = _uniqueLayerIds(
      parameters.list('sourceLayerIds'),
      field: 'sourceLayerIds',
    );
    final mergeSourceIds = [
      for (final layerId in sourceLayerIds)
        if (layerId != targetLayerId) layerId,
    ];
    if (mergeSourceIds.isEmpty) {
      throw semanticFailure(
        'smart_tile.merge_sources_missing',
        'At least one source layer other than the target is required.',
        details: {'targetLayerId': targetLayerId},
      );
    }

    final target = _smartTileLayer(context.map, targetLayerId);
    _requireExpectedDimensions(context.map, target);
    final targetPreset = _smartTilePreset(context.manifest, target.presetId);
    final sources = <SmartTileLayer>[];
    for (final layerId in mergeSourceIds) {
      final source = _smartTileLayer(context.map, layerId);
      _requireExpectedDimensions(context.map, source);
      if (source.usage != target.usage) {
        throw semanticFailure(
          'smart_tile.layer_usage_incompatible',
          'Smart Tile source and target layers must have the same usage.',
          details: {
            'targetLayerId': target.id,
            'targetUsage': target.usage.name,
            'sourceLayerId': source.id,
            'sourceUsage': source.usage.name,
          },
          remediation: const [
            'Choose layers from the same Smart Tile usage category.',
          ],
        );
      }
      final sourcePreset = _smartTilePreset(
        context.manifest,
        source.presetId,
      );
      _requireCompatiblePresets(targetPreset, sourcePreset, source.id);
      sources.add(source);
    }

    final materialMappings = parameters.contains('materialMappings')
        ? _materialMappings(
            parameters.object('materialMappings'),
            sourceLayerIds: mergeSourceIds.toSet(),
          )
        : const <String, Map<String, String>>{};
    _requireTargetMaterialCompatibility(
      manifest: context.manifest,
      targetPreset: targetPreset,
      sources: sources,
      materialMappings: materialMappings,
    );

    late final SmartTileLayerUnionResult union;
    try {
      union = unionSmartTileLayers(
        target: target,
        sources: sources,
        materialMappings: materialMappings,
      );
    } on ValidationException catch (error) {
      throw semanticFailure(
        error.code ?? 'smart_tile.layer_merge_invalid',
        error.message,
        details: error.details,
        remediation: error.remediation,
      );
    }

    final removedSourceIds =
        removeSources ? mergeSourceIds.toSet() : <String>{};
    final layers = <MapLayer>[];
    for (final layer in context.map.layers) {
      if (removedSourceIds.contains(layer.id)) continue;
      layers.add(layer.id == targetLayerId ? union.layer : layer);
    }
    final projected = context.map.copyWith(layers: layers);
    return context.draftMap(
      after: projected,
      operation: 'smart_tile.layer.merge',
      changedItems: union.mergedEntryCount + removedSourceIds.length,
      layerId: targetLayerId,
      preview: {
        'mode': 'union',
        'conflictPolicy': 'reject',
        'sourceLayerIds': sourceLayerIds,
        'targetLayerId': targetLayerId,
        'removeSources': removeSources,
        'removedSourceLayerIds': removedSourceIds.toList(growable: false),
        'mergedEntryCount': union.mergedEntryCount,
        'mergedEntryCounts': union.mergedEntryCounts,
        'materialMappingsApplied': materialMappings.values
            .fold<int>(0, (sum, mapping) => sum + mapping.length),
        'paletteSizeAfter': union.layer.materialPalette.length,
        'targetMetadataPreserved': true,
        'batchAtomicity': 'all_or_nothing',
      },
    );
  }

  AuthoringMutationDraft _reconstruct(AuthoringPlanningContext planning) {
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: const <String>{
        'sourceLayerId',
        'presetId',
        'targetLayerId',
        'name',
      },
    );
    final presetId = context.parameters.string('presetId');
    final preset = _smartTilePreset(context.manifest, presetId);
    if (preset.status != SmartTilePresetStatus.published) {
      throw semanticFailure(
        'smart_tile.reconstruction_preset_not_published',
        'A literal layer can only be reconstructed with a published preset.',
        details: <String, Object?>{
          'presetId': preset.id,
          'status': preset.status.name,
        },
        remediation: const <String>[
          'Validate and publish the preset in Smart Tiles Studio first.',
        ],
      );
    }
    late final SmartTileLayerReconstructionAssessment assessment;
    try {
      assessment = assessSmartTileLayerReconstruction(
        map: context.map,
        sourceLayerId: context.parameters.string('sourceLayerId'),
        manifest: context.manifest,
        presetId: preset.id,
        targetLayerId: context.parameters.string('targetLayerId'),
        targetLayerName: context.parameters.string('name'),
      );
    } on SmartTileReconstructionException catch (error) {
      throw semanticFailure(error.code, error.message);
    }
    final proposal = assessment.proposedLayer;
    if (proposal == null) {
      throw semanticFailure(
        'smart_tile.reconstruction_no_proposal',
        'No literal cell could be reconstructed unambiguously.',
        details: assessment.toPreviewJson(),
        remediation: const <String>[
          'Choose the preset whose atlas and Wang rules produced this layer.',
          'Resolve unsupported or ambiguous visual mappings in Smart Tiles '
              'Studio, then inspect again.',
        ],
      );
    }
    final layers = <MapLayer>[];
    for (final layer in context.map.layers) {
      layers.add(layer);
      if (layer.id == assessment.sourceLayerId) layers.add(proposal);
    }
    final projected = context.map.copyWith(layers: layers);
    preflightNativeSmartTileMutation(
      snapshot: planning.snapshot,
      projectedManifest: context.manifest,
      projectedMaps: <String, MapData>{context.map.id: projected},
    );
    return context.draftMap(
      after: projected,
      operation: 'smart_tile.layer.reconstruct',
      changedItems: assessment.reconstructedCellCount + 1,
      layerId: proposal.id,
      preview: <String, Object?>{
        ...assessment.toPreviewJson(),
        'targetLayerId': proposal.id,
        'targetLayerName': proposal.name,
        'confirmationRequired': true,
        'confirmationScope': 'revision_bound_plan',
        'batchAtomicity': 'all_or_nothing',
        'projectWidePreflight': 'passed',
      },
    );
  }
}

void _requireNativeSmartTileProject(
  SemanticMapActionContext context, {
  required String operation,
  required String layerId,
}) {
  requireExistingNativeSmartTileProject(
    context.planning.snapshot,
    operation: operation,
    layerId: layerId,
  );
}

AuthoringActionDescriptor _smartTileLayerDescriptor(
  String id,
  String summary, {
  required List<String> resourceKinds,
  AuthoringRiskLevel risk = AuthoringRiskLevel.low,
}) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'pokemap.authoring.$id.input.v1',
      outputSchemaId: 'pokemap.authoring.smart_tile.mutation.v1',
      riskLevel: risk,
      resourceKinds: resourceKinds,
      capabilityIds: const <String>['authoring.smart_tiles'],
      requiredPermissions: const <AuthoringPermission>[
        AuthoringPermission.projectWrite,
      ],
      guarantees: const <AuthoringGuarantee>[
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
      extensions: const <String, Object?>{
        'semanticIds': true,
        'rawTilesetRequired': false,
        'projectWidePreflight': true,
      },
    );

AuthoringMutationDraft _creationDraft(
  SemanticMapActionContext context, {
  required ProjectManifest manifest,
  required MapData map,
  required ProjectSmartTilePreset preset,
  required String layerId,
}) {
  final mapAfter = encodeMapAuthoringDocument(map);
  final manifestBefore = context.planning.snapshot.resourceBytes('project');
  final manifestAfter = encodeProjectAuthoringDocument(
    context.planning.snapshot,
    manifest,
  );
  final manifestChanged = !_sameByteLists(manifestBefore, manifestAfter);
  final projectRevision =
      context.planning.snapshot.resourceFingerprints['project'];
  if (manifestChanged && projectRevision == null) {
    throw semanticFailure(
      'smart_tile.resource_preimage_missing',
      'The project manifest revision is unavailable.',
    );
  }
  final changes = <AuthoringResourceChange>[
    AuthoringResourceChange(
      resource: context.resource,
      storageKey: context.storageKey,
      beforeBytes: context.beforeBytes,
      afterBytes: mapAfter,
    ),
    if (manifestChanged)
      AuthoringResourceChange(
        resource: AuthoringResourceRef(
          kind: 'project',
          id: 'project',
          revision: projectRevision,
        ),
        storageKey: 'project.json',
        beforeBytes: manifestBefore,
        afterBytes: manifestAfter,
      ),
  ];
  final diffEntries = <AuthoringDiffEntry>[
    AuthoringDiffEntry(
      operation: AuthoringDiffOperation.add,
      resource: context.resource,
      path: '/layers/$layerId',
      after: <String, Object?>{
        'id': layerId,
        'presetId': preset.id,
        'usage': preset.usage.name,
      },
    ),
    if (manifestChanged)
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: AuthoringResourceRef(
          kind: 'project',
          id: 'project',
          revision: projectRevision,
        ),
        path: '/smartTileCatalog',
        before: context.manifest.smartTileCatalog.toJson(),
        after: manifest.smartTileCatalog.toJson(),
      ),
  ];
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: changes,
      diff: AuthoringDiff(diffEntries),
    ),
    preview: <String, Object?>{
      'operation': 'smart_tile.layer.create',
      'mapId': context.map.id,
      'layerId': layerId,
      'presetId': preset.id,
      'usage': preset.usage.name,
      'manifestChanged': manifestChanged,
      'batchAtomicity': 'all_or_nothing',
      'projectWidePreflight': 'passed',
    },
  );
}

bool _sameByteLists(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

SmartTileLayer _smartTileLayer(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) {
      if (layer is SmartTileLayer) return layer;
      break;
    }
  }
  throw semanticFailure(
    'smart_tile.layer_invalid',
    'The requested layer is not a Smart Tile layer.',
    details: {'layerId': layerId},
  );
}

List<String> _uniqueLayerIds(List<Object?> values, {required String field}) {
  if (values.isEmpty) {
    throw invalidSemanticField(field, 'a non-empty list of layer IDs');
  }
  final ids = <String>[];
  final seen = <String>{};
  for (var index = 0; index < values.length; index++) {
    final value = values[index];
    if (value is! String || value.trim() != value || value.isEmpty) {
      throw invalidSemanticField('$field[$index]', 'a nonblank trimmed string');
    }
    if (!seen.add(value)) {
      throw semanticFailure(
        'smart_tile.source_layer_duplicate',
        'Each Smart Tile source layer may be listed only once.',
        details: {'layerId': value},
      );
    }
    ids.add(value);
  }
  return List.unmodifiable(ids);
}

void _requireExpectedDimensions(MapData map, SmartTileLayer layer) {
  final expected = <String, int>{
    'semanticCells': map.size.width * map.size.height,
    if (layer.field is SmartTileEdgeField || layer.field is SmartTileMixedField)
      'horizontalEdges': map.size.width * (map.size.height + 1),
    if (layer.field is SmartTileEdgeField || layer.field is SmartTileMixedField)
      'verticalEdges': (map.size.width + 1) * map.size.height,
    if (layer.field is SmartTileCornerField ||
        layer.field is SmartTileMixedField)
      'corners': (map.size.width + 1) * (map.size.height + 1),
  };
  final actual = <String, int>{
    'semanticCells': smartTileSemanticCells(layer).length,
    if (layer.field is SmartTileEdgeField || layer.field is SmartTileMixedField)
      'horizontalEdges': smartTileHorizontalEdges(layer).length,
    if (layer.field is SmartTileEdgeField || layer.field is SmartTileMixedField)
      'verticalEdges': smartTileVerticalEdges(layer).length,
    if (layer.field is SmartTileCornerField ||
        layer.field is SmartTileMixedField)
      'corners': smartTileCorners(layer).length,
  };
  for (final entry in expected.entries) {
    if (actual[entry.key] == entry.value) continue;
    throw semanticFailure(
      'smart_tile.layer_dimensions_incompatible',
      'The Smart Tile layer lattices do not match the map dimensions.',
      details: {
        'layerId': layer.id,
        'field': entry.key,
        'expectedLength': entry.value,
        'actualLength': actual[entry.key],
      },
      remediation: const [
        'Resize or repair the layer before attempting a merge.',
      ],
    );
  }
}

ProjectSmartTilePreset _smartTilePreset(
  ProjectManifest manifest,
  String presetId,
) {
  for (final preset in manifest.smartTileCatalog.presets) {
    if (preset.id == presetId) return preset;
  }
  throw semanticFailure(
    'smart_tile.preset_missing',
    'The Smart Tile layer references an unknown preset.',
    details: {'presetId': presetId},
  );
}

void _requireCompatiblePresets(
  ProjectSmartTilePreset target,
  ProjectSmartTilePreset source,
  String sourceLayerId,
) {
  if (target.id == source.id) return;
  if (target.usage == source.usage &&
      target.topology == source.topology &&
      target.templateHint == source.templateHint &&
      target.boundaryPolicy == source.boundaryPolicy) {
    return;
  }
  throw semanticFailure(
    'smart_tile.layer_preset_incompatible',
    'The Smart Tile source and target presets are not topology-compatible.',
    details: {
      'targetPresetId': target.id,
      'sourcePresetId': source.id,
      'sourceLayerId': sourceLayerId,
      'targetTopology': target.topology.name,
      'sourceTopology': source.topology.name,
      'targetTemplateHint': target.templateHint.name,
      'sourceTemplateHint': source.templateHint.name,
      'targetBoundaryPolicy': target.boundaryPolicy.name,
      'sourceBoundaryPolicy': source.boundaryPolicy.name,
    },
    remediation: const [
      'Choose presets with matching usage, topology, template, and boundary '
          'policy.',
    ],
  );
}

Map<String, Map<String, String>> _materialMappings(
  Map<String, Object?> raw, {
  required Set<String> sourceLayerIds,
}) {
  final mappings = <String, Map<String, String>>{};
  for (final entry in raw.entries) {
    if (!sourceLayerIds.contains(entry.key)) {
      throw semanticFailure(
        'smart_tile.material_mapping_source_invalid',
        'Material mappings may reference only merged source layers.',
        details: {'sourceLayerId': entry.key},
      );
    }
    final value = entry.value;
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw invalidSemanticField(
        'materialMappings.${entry.key}',
        'a material ID mapping object',
      );
    }
    final mapping = <String, String>{};
    for (final materialEntry in value.entries) {
      final sourceMaterialId = materialEntry.key as String;
      final targetMaterialId = materialEntry.value;
      if (sourceMaterialId.trim() != sourceMaterialId ||
          sourceMaterialId.isEmpty ||
          targetMaterialId is! String ||
          targetMaterialId.trim() != targetMaterialId ||
          targetMaterialId.isEmpty) {
        throw invalidSemanticField(
          'materialMappings.${entry.key}',
          'nonblank trimmed material ID pairs',
        );
      }
      mapping[sourceMaterialId] = targetMaterialId;
    }
    mappings[entry.key] = Map.unmodifiable(mapping);
  }
  return Map.unmodifiable(mappings);
}

void _requireTargetMaterialCompatibility({
  required ProjectManifest manifest,
  required ProjectSmartTilePreset targetPreset,
  required Iterable<SmartTileLayer> sources,
  required Map<String, Map<String, String>> materialMappings,
}) {
  final knownMaterialIds = manifest.smartTileCatalog.materials
      .map((material) => material.id)
      .toSet();
  for (final source in sources) {
    final normalized = normalizeSmartTileLayer(source).layer;
    final usedMaterialIds = normalized.materialPalette.skip(1).toSet();
    final mapping = materialMappings[source.id] ?? const <String, String>{};
    for (final sourceMaterialId in mapping.keys) {
      if (!usedMaterialIds.contains(sourceMaterialId)) {
        throw semanticFailure(
          'smart_tile.material_mapping_unused',
          'A material mapping references a material unused by its source.',
          details: {
            'sourceLayerId': source.id,
            'materialId': sourceMaterialId,
          },
        );
      }
    }
    for (final sourceMaterialId in usedMaterialIds) {
      final targetMaterialId = mapping[sourceMaterialId] ?? sourceMaterialId;
      if (!knownMaterialIds.contains(targetMaterialId) ||
          !targetPreset.allowedMaterialIds.contains(targetMaterialId)) {
        throw semanticFailure(
          'smart_tile.material_incompatible',
          'A merged material is not allowed by the target preset.',
          details: {
            'sourceLayerId': source.id,
            'sourceMaterialId': sourceMaterialId,
            'targetMaterialId': targetMaterialId,
            'targetPresetId': targetPreset.id,
          },
          remediation: const [
            'Provide an explicit materialMappings entry to an allowed target '
                'material.',
          ],
        );
      }
    }
  }
}
