import 'dart:convert';
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../domains/assets/raster_image_dimensions.dart';
import '../../domains/assets/asset_store.dart';
import '../../domains/assets/tileset_actions.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import 'map_lifecycle_adapter.dart';
import 'semantic_map_action_support.dart';
import 'smart_tile_native_transition_guard.dart';

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
        'smart_tile.preset.publish',
        'Publish a Smart Tile preset with optional atomic layer creation',
        resourceKinds: const <String>[
          'project',
          'map',
          'smartTilePreset',
          'smartTileLayer',
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

  AuthoringMutationDraft _publishPreset(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'preset', 'layer'},
    );
    final supplied = _decode(
      parameters.object('preset'),
      field: 'preset',
      decode: ProjectSmartTilePreset.fromJson,
    );
    final preset = supplied.copyWith(status: SmartTilePresetStatus.published);
    final currentCatalog = planning.snapshot.manifest.smartTileCatalog;
    final before = _findById(
      currentCatalog.presets,
      preset.id,
      (item) => item.id,
    );
    final projectedCatalog = _catalogWith(
      currentCatalog,
      presets: _upsertById(
        currentCatalog.presets,
        preset,
        (item) => item.id,
      ),
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

AuthoringActionDescriptor _descriptor(
  String id,
  String summary, {
  required List<String> resourceKinds,
  AuthoringRiskLevel risk = AuthoringRiskLevel.medium,
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
        'catalogFormatVersion': ProjectSmartTileCatalog.currentFormatVersion,
        'projectWidePreflight': true,
      },
    );

T _decode<T>(
  Map<String, Object?> json, {
  required String field,
  required T Function(Map<String, dynamic>) decode,
}) {
  try {
    return decode(Map<String, dynamic>.from(json));
  } on Object catch (error) {
    throw semanticFailure(
      'smart_tile.request_invalid',
      'Parameter "$field" is not a valid Smart Tile document.',
      details: <String, Object?>{
        'parameter': field,
        'validationType': error.runtimeType.toString(),
      },
    );
  }
}

ProjectManifest _nativeManifest(
  ProjectManifest manifest,
  ProjectSmartTileCatalog catalog,
) =>
    manifest.copyWith(
      version: ProjectVersion.v5,
      smartTileCatalog: catalog,
    );

ProjectSmartTileCatalog _catalogWith(
  ProjectSmartTileCatalog catalog, {
  List<ProjectSmartTileAtlas>? atlases,
  List<ProjectSmartTileMaterial>? materials,
  List<ProjectSmartTileAnimation>? animations,
  List<ProjectSmartTilePreset>? presets,
}) =>
    ProjectSmartTileCatalog(
      categories: catalog.categories,
      atlases: atlases ?? catalog.atlases,
      materials: materials ?? catalog.materials,
      animations: animations ?? catalog.animations,
      presets: presets ?? catalog.presets,
    );

List<T> _upsertById<T>(
  Iterable<T> values,
  T replacement,
  String Function(T) idOf,
) {
  final result = <T>[
    for (final value in values)
      if (idOf(value) != idOf(replacement)) value,
    replacement,
  ]..sort((left, right) => idOf(left).compareTo(idOf(right)));
  return List<T>.unmodifiable(result);
}

T? _findById<T>(Iterable<T> values, String id, String Function(T) idOf) {
  for (final value in values) {
    if (idOf(value) == id) return value;
  }
  return null;
}

AuthoringMutationDraft _manifestDraft(
  AuthoringPlanningContext planning, {
  required ProjectManifest manifest,
  required String operation,
  required String path,
  Object? before,
  Object? after,
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
      ]),
    ),
    preview: <String, Object?>{
      'operation': operation,
      'path': path,
      'projectWidePreflight': 'passed',
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
  final dimensions = decodeRasterImageDimensions(
    blob,
    mediaType: asset.artifact.mediaType,
  );
  if (dimensions == null) {
    throw semanticFailure(
      'smart_tile.atlas.image_decode_failed',
      'The canonical tileset image dimensions cannot be decoded.',
      details: <String, Object?>{'assetId': asset.id},
    );
  }

  final right = atlas.originX +
      atlas.marginX +
      (atlas.columns - 1) * (atlas.cellWidth + atlas.spacingX) +
      atlas.cellWidth;
  final bottom = atlas.originY +
      atlas.marginY +
      (atlas.rows - 1) * (atlas.cellHeight + atlas.spacingY) +
      atlas.cellHeight;
  if (right > dimensions.width || bottom > dimensions.height) {
    throw semanticFailure(
      'smart_tile.atlas.out_of_image',
      'The Smart Tile atlas grid extends outside the decoded image.',
      details: <String, Object?>{
        'atlasId': atlas.id,
        'imageWidth': dimensions.width,
        'imageHeight': dimensions.height,
        'requiredWidth': right,
        'requiredHeight': bottom,
      },
      remediation: const <String>[
        'Reduce the grid, origin, margins, or spacing to stay in the image.',
      ],
    );
  }
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
  return List<Map<String, Object?>>.unmodifiable(references);
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
