import 'dart:convert';
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../domains/assets/asset_store.dart';
import '../../domains/assets/tileset_actions.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import 'map_lifecycle_adapter.dart';
import 'semantic_map_action_support.dart';
import 'smart_tile_native_transition_guard.dart';
import 'smart_tile_tiled_wang_projection.dart';

part 'smart_tile_catalog_support.dart';

/// Canonical native Smart Tile catalog mutations shared by every transport.
final class SmartTileCatalogActions {
  const SmartTileCatalogActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      _descriptor(
        'smart_tile.animation.delete',
        'Delete one unreferenced Smart Tile animation',
        resourceKinds: const <String>[
          'project',
          'smartTileAnimation',
          'smartTilePreset',
        ],
        risk: AuthoringRiskLevel.high,
      ),
      _descriptor(
        'smart_tile.animation.upsert',
        'Create or replace a validated Smart Tile animation',
        resourceKinds: const <String>[
          'project',
          'smartTileAnimation',
          'smartTileAtlas',
        ],
      ),
      _descriptor(
        'smart_tile.atlas.upsert',
        'Create or replace a Smart Tile atlas within decoded image bounds',
        resourceKinds: const <String>[
          'project',
          'asset',
          'smartTileAtlas',
        ],
      ),
      _descriptor(
        'smart_tile.material.upsert',
        'Create or replace a canonical Smart Tile material',
        resourceKinds: const <String>[
          'project',
          'smartTileMaterial',
        ],
      ),
      _descriptor(
        'smart_tile.pattern.delete',
        'Delete one unreferenced reusable Smart Tile pattern',
        resourceKinds: const <String>[
          'project',
          'map',
          'smartTilePattern',
          'smartTileLayer',
        ],
        risk: AuthoringRiskLevel.high,
      ),
      _descriptor(
        'smart_tile.pattern.upsert',
        'Create or replace a reusable Smart Tile visual pattern',
        resourceKinds: const <String>[
          'project',
          'smartTilePattern',
          'smartTileAtlas',
          'smartTileAnimation',
        ],
      ),
      _descriptor(
        'smart_tile.preset.delete',
        'Delete one unreferenced Smart Tile preset',
        resourceKinds: const <String>[
          'project',
          'map',
          'smartTilePreset',
          'smartTileLayer',
        ],
        risk: AuthoringRiskLevel.high,
      ),
      _descriptor(
        'smart_tile.preset.draft.delete',
        'Delete one isolated Smart Tile authoring draft',
        resourceKinds: const <String>[
          'project',
          'smartTileDraft',
        ],
        risk: AuthoringRiskLevel.high,
      ),
      _descriptor(
        'smart_tile.preset.draft.upsert',
        'Create or replace one isolated Smart Tile authoring draft',
        resourceKinds: const <String>[
          'project',
          'smartTileDraft',
          'smartTileAtlas',
          'smartTileMaterial',
          'smartTileAnimation',
        ],
      ),
      _descriptor(
        'smart_tile.preset.publish',
        'Publish a Smart Tile preset including editable candidate labels '
            '(rules[].candidates[].label), with optional atomic layer creation',
        resourceKinds: const <String>[
          'project',
          'map',
          'smartTilePreset',
          'smartTileLayer',
          'smartTileDraft',
        ],
      ),
    ]..sort((left, right) => left.id.compareTo(right.id)),
  );

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    if (planning.request.actionVersion != 1) {
      throw semanticFailure(
        'smart_tile.action_version_unsupported',
        'The requested Smart Tile catalog action version is unsupported.',
        details: <String, Object?>{
          'actionVersion': planning.request.actionVersion,
        },
      );
    }
    return switch (planning.request.actionId) {
      'smart_tile.atlas.upsert' => _upsertAtlas(planning),
      'smart_tile.material.upsert' => _upsertMaterial(planning),
      'smart_tile.animation.upsert' => _upsertAnimation(planning),
      'smart_tile.animation.delete' => _deleteAnimation(planning),
      'smart_tile.pattern.upsert' => _upsertPattern(planning),
      'smart_tile.pattern.delete' => _deletePattern(planning),
      'smart_tile.preset.draft.upsert' => _upsertDraft(planning),
      'smart_tile.preset.draft.delete' => _deleteDraft(planning),
      'smart_tile.preset.publish' => _publishPreset(planning),
      'smart_tile.preset.delete' => _deletePreset(planning),
      _ => throw semanticFailure(
          'smart_tile.action_unsupported',
          'The requested Smart Tile catalog action is unsupported.',
          details: <String, Object?>{
            'actionId': planning.request.actionId,
          },
        ),
    };
  }

  AuthoringMutationDraft _upsertAtlas(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'atlas'},
    );
    final atlas = _decode(
      parameters.object('atlas'),
      field: 'atlas',
      decode: ProjectSmartTileAtlas.fromJson,
    );
    _validateAtlasImageBounds(planning.snapshot, atlas);
    final before = _findById(
      planning.snapshot.manifest.smartTileCatalog.atlases,
      atlas.id,
      (item) => item.id,
    );
    final catalog = _catalogWith(
      planning.snapshot.manifest.smartTileCatalog,
      atlases: _upsertById(
        planning.snapshot.manifest.smartTileCatalog.atlases,
        atlas,
        (item) => item.id,
      ),
    );
    return _manifestDraft(
      planning,
      manifest: _nativeManifest(planning.snapshot.manifest, catalog),
      operation: 'smart_tile.atlas.upsert',
      path: '/smartTileCatalog/atlases/${atlas.id}',
      before: before?.toJson(),
      after: atlas.toJson(),
    );
  }

  AuthoringMutationDraft _upsertMaterial(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'material'},
    );
    final material = _decode(
      parameters.object('material'),
      field: 'material',
      decode: ProjectSmartTileMaterial.fromJson,
    );
    final before = _findById(
      planning.snapshot.manifest.smartTileCatalog.materials,
      material.id,
      (item) => item.id,
    );
    final catalog = _catalogWith(
      planning.snapshot.manifest.smartTileCatalog,
      materials: _upsertById(
        planning.snapshot.manifest.smartTileCatalog.materials,
        material,
        (item) => item.id,
      ),
    );
    return _manifestDraft(
      planning,
      manifest: _nativeManifest(planning.snapshot.manifest, catalog),
      operation: 'smart_tile.material.upsert',
      path: '/smartTileCatalog/materials/${material.id}',
      before: before?.toJson(),
      after: material.toJson(),
    );
  }

  AuthoringMutationDraft _upsertAnimation(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'animation'},
    );
    final animation = _decode(
      parameters.object('animation'),
      field: 'animation',
      decode: ProjectSmartTileAnimation.fromJson,
    );
    final before = _findById(
      planning.snapshot.manifest.smartTileCatalog.animations,
      animation.id,
      (item) => item.id,
    );
    final catalog = _catalogWith(
      planning.snapshot.manifest.smartTileCatalog,
      animations: _upsertById(
        planning.snapshot.manifest.smartTileCatalog.animations,
        animation,
        (item) => item.id,
      ),
    );
    return _manifestDraft(
      planning,
      manifest: _nativeManifest(planning.snapshot.manifest, catalog),
      operation: 'smart_tile.animation.upsert',
      path: '/smartTileCatalog/animations/${animation.id}',
      before: before?.toJson(),
      after: animation.toJson(),
    );
  }

  AuthoringMutationDraft _deleteAnimation(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'animationId'},
    );
    final animationId = parameters.string('animationId');
    final catalog = planning.snapshot.manifest.smartTileCatalog;
    final existing = _findById(
      catalog.animations,
      animationId,
      (item) => item.id,
    );
    if (existing == null) {
      throw semanticFailure(
        'smart_tile.animation.unknown',
        'The requested Smart Tile animation does not exist.',
        details: <String, Object?>{'animationId': animationId},
      );
    }
    final references = _animationReferences(catalog, animationId);
    if (references.isNotEmpty) {
      throw semanticFailure(
        'smart_tile.animation.references_blocking',
        'The Smart Tile animation is still referenced by published visuals.',
        details: <String, Object?>{
          'animationId': animationId,
          'references': references,
        },
      );
    }
    final projected = _catalogWith(
      catalog,
      animations: <ProjectSmartTileAnimation>[
        for (final animation in catalog.animations)
          if (animation.id != animationId) animation,
      ],
    );
    return _manifestDraft(
      planning,
      manifest: _nativeManifest(planning.snapshot.manifest, projected),
      operation: 'smart_tile.animation.delete',
      path: '/smartTileCatalog/animations/$animationId',
      before: existing.toJson(),
    );
  }

  AuthoringMutationDraft _upsertPattern(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'pattern'},
    );
    final pattern = _decode(
      parameters.object('pattern'),
      field: 'pattern',
      decode: ProjectSmartTilePattern.fromJson,
    );
    final catalog = planning.snapshot.manifest.smartTileCatalog;
    final before = _findById(catalog.patterns, pattern.id, (item) => item.id);
    final projected = _catalogWith(
      catalog,
      patterns: _upsertById(catalog.patterns, pattern, (item) => item.id),
    );
    return _manifestDraft(
      planning,
      manifest: _nativeManifest(planning.snapshot.manifest, projected),
      operation: 'smart_tile.pattern.upsert',
      path: '/smartTileCatalog/patterns/${pattern.id}',
      before: before?.toJson(),
      after: pattern.toJson(),
    );
  }

  AuthoringMutationDraft _deletePattern(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'patternId'},
    );
    final patternId = parameters.string('patternId');
    final catalog = planning.snapshot.manifest.smartTileCatalog;
    final existing = _findById(catalog.patterns, patternId, (item) => item.id);
    if (existing == null) {
      throw semanticFailure(
        'smart_tile.pattern.unknown',
        'The requested Smart Tile pattern does not exist.',
        details: <String, Object?>{'patternId': patternId},
      );
    }
    final references = <Map<String, Object?>>[
      for (final map in planning.snapshot.maps)
        for (final layer in map.layers.whereType<SmartTileLayer>())
          for (final stroke in layer.patternStrokes)
            if (stroke.patternId == patternId)
              <String, Object?>{
                'mapId': map.id,
                'layerId': layer.id,
                'strokeId': stroke.id,
              },
    ];
    if (references.isNotEmpty) {
      throw semanticFailure(
        'smart_tile.pattern.references_blocking',
        'The Smart Tile pattern is still painted on map layers.',
        details: <String, Object?>{
          'patternId': patternId,
          'references': references,
        },
      );
    }
    final projected = _catalogWith(
      catalog,
      patterns: <ProjectSmartTilePattern>[
        for (final pattern in catalog.patterns)
          if (pattern.id != patternId) pattern,
      ],
    );
    return _manifestDraft(
      planning,
      manifest: _nativeManifest(planning.snapshot.manifest, projected),
      operation: 'smart_tile.pattern.delete',
      path: '/smartTileCatalog/patterns/$patternId',
      before: existing.toJson(),
    );
  }

  AuthoringMutationDraft _upsertDraft(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'draft'},
    );
    final draft = _decode(
      parameters.object('draft'),
      field: 'draft',
      decode: ProjectSmartTileAuthoringDraft.fromJson,
    );
    final catalog = planning.snapshot.manifest.smartTileCatalog;
    final before = _findById(catalog.drafts, draft.id, (item) => item.id);
    _validateDraftTarget(catalog, draft, replacingDraftId: draft.id);
    final projected = _catalogWith(
      catalog,
      drafts: _upsertById(catalog.drafts, draft, (item) => item.id),
    );
    return _manifestDraft(
      planning,
      manifest: _nativeManifest(planning.snapshot.manifest, projected),
      operation: 'smart_tile.preset.draft.upsert',
      path: '/smartTileCatalog/drafts/${draft.id}',
      before: before?.toJson(),
      after: draft.toJson(),
    );
  }

  AuthoringMutationDraft _deleteDraft(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'draftId'},
    );
    final draftId = parameters.string('draftId');
    final catalog = planning.snapshot.manifest.smartTileCatalog;
    final existing = _findById(catalog.drafts, draftId, (item) => item.id);
    if (existing == null) {
      throw semanticFailure(
        'smart_tile.draft.unknown',
        'The requested Smart Tile draft does not exist.',
        details: <String, Object?>{'draftId': draftId},
      );
    }
    final projected = _catalogWith(
      catalog,
      drafts: <ProjectSmartTileAuthoringDraft>[
        for (final draft in catalog.drafts)
          if (draft.id != draftId) draft,
      ],
    );
    return _manifestDraft(
      planning,
      manifest: _nativeManifest(planning.snapshot.manifest, projected),
      operation: 'smart_tile.preset.draft.delete',
      path: '/smartTileCatalog/drafts/$draftId',
      before: existing.toJson(),
    );
  }

  AuthoringMutationDraft _publishPreset(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'preset', 'draftId', 'layer'},
    );
    final currentCatalog = planning.snapshot.manifest.smartTileCatalog;
    final hasPreset = parameters.contains('preset');
    final hasDraft = parameters.contains('draftId');
    if (hasPreset == hasDraft) {
      throw semanticFailure(
        'smart_tile.request_invalid',
        'Smart Tile publication requires exactly one of preset or draftId.',
        details: const <String, Object?>{
          'exclusiveParameters': <String>['preset', 'draftId'],
        },
      );
    }

    late final ProjectSmartTilePreset preset;
    ProjectSmartTileAuthoringDraft? publishedDraft;
    var projectedAtlases = currentCatalog.atlases;
    var projectedMaterials = currentCatalog.materials;
    var projectedAnimations = currentCatalog.animations;
    var projectedDrafts = currentCatalog.drafts;
    if (hasPreset) {
      final supplied = _decode(
        parameters.object('preset'),
        field: 'preset',
        decode: ProjectSmartTilePreset.fromJson,
      );
      preset = supplied.copyWith(status: SmartTilePresetStatus.published);
    } else {
      final draftId = parameters.string('draftId');
      publishedDraft = _findById(
        currentCatalog.drafts,
        draftId,
        (item) => item.id,
      );
      if (publishedDraft == null) {
        throw semanticFailure(
          'smart_tile.draft.unknown',
          'The requested Smart Tile draft does not exist.',
          details: <String, Object?>{'draftId': draftId},
        );
      }
      _validateDraftTarget(
        currentCatalog,
        publishedDraft,
        replacingDraftId: publishedDraft.id,
      );
      _validateSharedDraftDependencies(currentCatalog, publishedDraft);
      for (final atlas in publishedDraft.atlases) {
        _validateAtlasImageBounds(planning.snapshot, atlas);
      }
      final compilation = compileSmartTileAuthoringDraft(
        draft: publishedDraft,
        catalog: currentCatalog,
        manifest: planning.snapshot.manifest,
      );
      if (compilation case final SmartTileDraftCompilationFailure failure) {
        throw semanticFailure(
          'smart_tile.publish.incomplete',
          'The Smart Tile draft is not ready for publication.',
          details: <String, Object?>{
            'draftId': publishedDraft.id,
            'diagnostics': <Map<String, Object?>>[
              for (final diagnostic in failure.diagnostics)
                <String, Object?>{
                  'code': diagnostic.code,
                  'severity': diagnostic.severity.name,
                  'path': diagnostic.path,
                  'message': diagnostic.message,
                },
            ],
          },
        );
      }
      final success = compilation as SmartTileDraftCompilationSuccess;
      preset = success.preset;
      projectedAtlases = success.atlases;
      projectedMaterials = success.materials;
      projectedAnimations = success.animations;
      projectedDrafts = <ProjectSmartTileAuthoringDraft>[
        for (final draft in currentCatalog.drafts)
          if (draft.id != publishedDraft.id) draft,
      ];
    }
    final before = _findById(
      currentCatalog.presets,
      preset.id,
      (item) => item.id,
    );
    final projectedCatalog = _catalogWith(
      currentCatalog,
      atlases: projectedAtlases,
      materials: projectedMaterials,
      animations: projectedAnimations,
      presets: _upsertById(
        currentCatalog.presets,
        preset,
        (item) => item.id,
      ),
      drafts: projectedDrafts,
    );
    var projectedManifest = _nativeManifest(
      planning.snapshot.manifest,
      projectedCatalog,
    );

    if (!parameters.contains('layer')) {
      return _manifestDraft(
        planning,
        manifest: projectedManifest,
        operation: 'smart_tile.preset.publish',
        path: '/smartTileCatalog/presets/${preset.id}',
        before: before?.toJson(),
        after: preset.toJson(),
        removedDraft: publishedDraft,
      );
    }

    final layer = SemanticParameters(
      parameters.object('layer'),
      allowed: const <String>{'mapId', 'layerId', 'name'},
    );
    final mapId = layer.string('mapId');
    final creation = planNativeSmartTileLayerCreation(
      projectMaps: planning.snapshot.maps,
      targetMapId: mapId,
      manifest: projectedManifest,
      preset: preset,
      layerId: layer.string('layerId'),
      layerName: layer.string('name'),
    );
    if (creation case final SmartTileLayerCreationFailure failure) {
      throw semanticFailure(failure.code, failure.message);
    }
    final success = creation as SmartTileLayerCreationSuccess;
    projectedManifest = success.manifest;
    preflightNativeSmartTileMutation(
      snapshot: planning.snapshot,
      projectedManifest: projectedManifest,
      projectedMaps: <String, MapData>{mapId: success.map},
    );
    return _manifestAndMapDraft(
      planning,
      manifest: projectedManifest,
      map: success.map,
      operation: 'smart_tile.preset.publish',
      presetBefore: before,
      presetAfter: preset,
      layerId: success.layerId,
      removedDraft: publishedDraft,
    );
  }

  AuthoringMutationDraft _deletePreset(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'presetId'},
    );
    final presetId = parameters.string('presetId');
    final catalog = planning.snapshot.manifest.smartTileCatalog;
    final existing = _findById(
      catalog.presets,
      presetId,
      (item) => item.id,
    );
    if (existing == null) {
      throw semanticFailure(
        'smart_tile.preset.unknown',
        'The requested Smart Tile preset does not exist.',
        details: <String, Object?>{'presetId': presetId},
      );
    }
    final references = <Map<String, Object?>>[
      for (final map in planning.snapshot.maps)
        for (final layer in map.layers.whereType<SmartTileLayer>())
          if (layer.presetId == presetId)
            <String, Object?>{'mapId': map.id, 'layerId': layer.id},
    ];
    if (references.isNotEmpty) {
      throw semanticFailure(
        'smart_tile.preset.references_blocking',
        'The Smart Tile preset is still referenced by map layers.',
        details: <String, Object?>{
          'presetId': presetId,
          'references': references,
        },
      );
    }
    final projected = _catalogWith(
      catalog,
      presets: <ProjectSmartTilePreset>[
        for (final preset in catalog.presets)
          if (preset.id != presetId) preset,
      ],
    );
    return _manifestDraft(
      planning,
      manifest: _nativeManifest(planning.snapshot.manifest, projected),
      operation: 'smart_tile.preset.delete',
      path: '/smartTileCatalog/presets/$presetId',
      before: existing.toJson(),
    );
  }
}

AuthoringMutationDraft _manifestDraft(
  AuthoringPlanningContext planning, {
  required ProjectManifest manifest,
  required String operation,
  required String path,
  Object? before,
  Object? after,
  ProjectSmartTileAuthoringDraft? removedDraft,
  Map<String, Object?> preview = const <String, Object?>{},
}) {
  preflightNativeSmartTileMutation(
    snapshot: planning.snapshot,
    projectedManifest: manifest,
  );
  final beforeBytes = planning.snapshot.resourceBytes('project');
  final afterBytes = encodeProjectAuthoringDocument(
    planning.snapshot,
    manifest,
  );
  if (_sameBytes(beforeBytes, afterBytes)) {
    throw semanticFailure(
      'smart_tile.no_change',
      'The Smart Tile catalog mutation changes nothing.',
    );
  }
  final project = _resource(planning.snapshot, 'project', 'project');
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: <AuthoringResourceChange>[
        AuthoringResourceChange(
          resource: project,
          storageKey: 'project.json',
          beforeBytes: beforeBytes,
          afterBytes: afterBytes,
        ),
      ],
      diff: AuthoringDiff(<AuthoringDiffEntry>[
        AuthoringDiffEntry(
          operation: operation.endsWith('.delete')
              ? AuthoringDiffOperation.remove
              : before == null
                  ? AuthoringDiffOperation.add
                  : AuthoringDiffOperation.replace,
          resource: project,
          path: path,
          before: before,
          after: after,
        ),
        if (removedDraft != null)
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.remove,
            resource: project,
            path: '/smartTileCatalog/drafts/${removedDraft.id}',
            before: removedDraft.toJson(),
          ),
      ]),
    ),
    preview: <String, Object?>{
      'operation': operation,
      'path': path,
      if (removedDraft != null) 'draftId': removedDraft.id,
      'projectWidePreflight': 'passed',
      ...preview,
    },
  );
}

AuthoringMutationDraft _manifestAndMapDraft(
  AuthoringPlanningContext planning, {
  required ProjectManifest manifest,
  required MapData map,
  required String operation,
  required ProjectSmartTilePreset? presetBefore,
  required ProjectSmartTilePreset presetAfter,
  required String layerId,
  ProjectSmartTileAuthoringDraft? removedDraft,
}) {
  final mapEntry = planning.snapshot.manifest.maps
      .where((entry) => entry.id == map.id)
      .firstOrNull;
  if (mapEntry == null) {
    throw semanticFailure(
      'map.manifest_entry_missing',
      'The target map has no manifest storage entry.',
      details: <String, Object?>{'mapId': map.id},
    );
  }
  final project = _resource(planning.snapshot, 'project', 'project');
  final mapResource = _resource(planning.snapshot, 'map', map.id);
  final projectBefore = planning.snapshot.resourceBytes('project');
  final projectAfter = encodeProjectAuthoringDocument(
    planning.snapshot,
    manifest,
  );
  final projectChanged = !_sameBytes(projectBefore, projectAfter);
  final mapAfter = encodeMapAuthoringDocument(map);
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: <AuthoringResourceChange>[
        AuthoringResourceChange(
          resource: mapResource,
          storageKey: mapEntry.relativePath,
          beforeBytes: planning.snapshot.resourceBytes('map:${map.id}'),
          afterBytes: mapAfter,
        ),
        if (projectChanged)
          AuthoringResourceChange(
            resource: project,
            storageKey: 'project.json',
            beforeBytes: projectBefore,
            afterBytes: projectAfter,
          ),
      ],
      diff: AuthoringDiff(<AuthoringDiffEntry>[
        if (projectChanged)
          AuthoringDiffEntry(
            operation: presetBefore == null
                ? AuthoringDiffOperation.add
                : AuthoringDiffOperation.replace,
            resource: project,
            path: '/smartTileCatalog/presets/${presetAfter.id}',
            before: presetBefore?.toJson(),
            after: presetAfter.toJson(),
          ),
        if (projectChanged && removedDraft != null)
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.remove,
            resource: project,
            path: '/smartTileCatalog/drafts/${removedDraft.id}',
            before: removedDraft.toJson(),
          ),
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: mapResource,
          path: '/layers/$layerId',
          after: <String, Object?>{
            'id': layerId,
            'presetId': presetAfter.id,
            'usage': presetAfter.usage.name,
          },
        ),
      ]),
    ),
    preview: <String, Object?>{
      'operation': operation,
      'presetId': presetAfter.id,
      'mapId': map.id,
      'layerId': layerId,
      if (removedDraft != null) 'draftId': removedDraft.id,
      'batchAtomicity': 'all_or_nothing',
      'manifestChanged': projectChanged,
      'projectWidePreflight': 'passed',
    },
  );
}

AuthoringResourceRef _resource(
  ProjectSnapshot snapshot,
  String kind,
  String id,
) {
  final identity = kind == 'project' ? 'project' : '$kind:$id';
  final revision = snapshot.resourceFingerprints[identity];
  if (revision == null) {
    throw semanticFailure(
      'smart_tile.resource_preimage_missing',
      'A required Smart Tile resource revision is unavailable.',
      details: <String, Object?>{'kind': kind, 'id': id},
    );
  }
  return AuthoringResourceRef(kind: kind, id: id, revision: revision);
}

void _validateAtlasImageBounds(
  ProjectSnapshot snapshot,
  ProjectSmartTileAtlas atlas,
) {
  final image = _atlasImageState(snapshot, atlas);
  validateSmartTileAtlasImageBounds(
    manifest: snapshot.manifest,
    assets: image.assets,
    imageBytes: image.bytes,
    atlas: atlas,
  );
}

({AssetCatalog assets, List<int> bytes}) _atlasImageState(
  ProjectSnapshot snapshot,
  ProjectSmartTileAtlas atlas,
) {
  final tileset = snapshot.manifest.tilesets
      .where((entry) => entry.id == atlas.tilesetId)
      .firstOrNull;
  if (tileset == null) {
    throw semanticFailure(
      'smart_tile.atlas.tileset_missing',
      'The Smart Tile atlas references an unknown tileset.',
      details: <String, Object?>{'tilesetId': atlas.tilesetId},
    );
  }
  final catalogBytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
  if (catalogBytes == null) {
    throw semanticFailure(
      'smart_tile.atlas.asset_catalog_missing',
      'Decoded atlas validation requires the project asset catalog.',
      remediation: const <String>[
        'Import the tileset image into the canonical asset library first.',
      ],
    );
  }
  late final AssetCatalog assets;
  try {
    final decoded = jsonDecode(utf8.decode(catalogBytes));
    if (decoded is! Map) throw const FormatException();
    assets = AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
  } on Object catch (error) {
    throw semanticFailure(
      'smart_tile.atlas.asset_catalog_invalid',
      'The project asset catalog cannot be decoded for atlas validation.',
      details: <String, Object?>{
        'validationType': error.runtimeType.toString(),
      },
    );
  }

  final atlasSpecs = readTilesetAtlases(snapshot.manifest);
  final assetId = atlasSpecs[atlas.tilesetId]?.assetId;
  AssetRecord? asset;
  if (assetId != null) asset = assets.find(assetId);
  asset ??= assets.records
      .where((record) => record.logicalPath == tileset.relativePath)
      .firstOrNull;
  if (asset == null || !asset.artifact.mediaType.startsWith('image/')) {
    throw semanticFailure(
      'smart_tile.atlas.image_asset_missing',
      'The tileset does not resolve to a canonical image asset.',
      details: <String, Object?>{
        'tilesetId': tileset.id,
        'logicalPath': tileset.relativePath,
      },
    );
  }
  final blob = snapshot.findResourceBytes(
    assetBlobResourceIdentity(asset.artifact.digest),
  );
  if (blob == null) {
    throw semanticFailure(
      'smart_tile.atlas.image_blob_missing',
      'The canonical tileset image bytes are unavailable.',
      details: <String, Object?>{'assetId': asset.id},
    );
  }
  return (assets: assets, bytes: blob);
}

List<Map<String, Object?>> _animationReferences(
  ProjectSmartTileCatalog catalog,
  String animationId,
) {
  final references = <Map<String, Object?>>[];
  for (final preset in catalog.presets) {
    for (final rule in preset.rules) {
      for (final candidate in rule.candidates) {
        for (var index = 0; index < candidate.parts.length; index++) {
          final source = candidate.parts[index].source;
          if (source is SmartTileAnimationSource &&
              source.animationId == animationId) {
            references.add(<String, Object?>{
              'presetId': preset.id,
              'ruleId': rule.id,
              'candidateId': candidate.id,
              'partIndex': index,
            });
          }
        }
      }
    }
  }
  for (final pattern in catalog.patterns) {
    for (var cellIndex = 0; cellIndex < pattern.cells.length; cellIndex += 1) {
      final cell = pattern.cells[cellIndex];
      for (var partIndex = 0; partIndex < cell.parts.length; partIndex += 1) {
        final source = cell.parts[partIndex].source;
        if (source is SmartTileAnimationSource &&
            source.animationId == animationId) {
          references.add(<String, Object?>{
            'patternId': pattern.id,
            'cellIndex': cellIndex,
            'partIndex': partIndex,
          });
        }
      }
    }
  }
  return List<Map<String, Object?>>.unmodifiable(references);
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
