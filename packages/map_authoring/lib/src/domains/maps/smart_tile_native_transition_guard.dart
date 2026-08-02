import 'package:map_core/map_core.dart';

import '../../workspace/project_snapshot.dart';
import 'map_lifecycle_adapter.dart';
import 'semantic_map_action_support.dart';

/// Validates the complete project boundary before any native Smart Tile write.
///
/// Catalog mutations are project-wide by definition: changing a material,
/// preset, atlas, or animation can invalidate a layer in a different map. This
/// guard therefore rejects incomplete snapshots, legacy providers, and any
/// projected state that fails canonical manifest/map validation.
void preflightNativeSmartTileMutation({
  required ProjectSnapshot snapshot,
  required ProjectManifest projectedManifest,
  Map<String, MapData> projectedMaps = const <String, MapData>{},
}) {
  _requireCompleteMapSnapshot(snapshot);
  _requireNoLegacyTerrainOrPath(
    manifest: snapshot.manifest,
    maps: snapshot.maps,
  );

  final unknownProjectedIds = projectedMaps.keys
      .where((mapId) => snapshot.mapById(mapId) == null)
      .toList()
    ..sort();
  if (unknownProjectedIds.isNotEmpty) {
    throw semanticFailure(
      'smart_tile_project_maps_extra',
      'Projected Smart Tile maps are absent from the project snapshot.',
      details: <String, Object?>{'mapIds': unknownProjectedIds},
    );
  }

  final maps = <MapData>[
    for (final map in snapshot.maps) projectedMaps[map.id] ?? map,
  ];
  _requireNoLegacyTerrainOrPath(
    manifest: projectedManifest,
    maps: maps,
  );

  if (projectedManifest.smartTileCatalog.isNotEmpty &&
      projectedManifest.version != ProjectVersion.v5) {
    throw semanticFailure(
      'smart_tile_native_project_version_required',
      'A non-empty native Smart Tile catalog requires ProjectVersion.v5.',
      details: <String, Object?>{
        'projectVersion': projectedManifest.version.name,
      },
    );
  }

  try {
    ProjectValidator.validate(projectedManifest);
    for (final map in maps) {
      if (map.layers.any((layer) => layer is SmartTileLayer) &&
          map.version != ProjectVersion.v5) {
        throw ValidationException(
          'Map "${map.id}" contains Smart Tile layers before v5.',
          code: 'smart_tile_native_project_version_required',
          details: <String, Object?>{
            'mapId': map.id,
            'mapVersion': map.version.name,
          },
        );
      }
      MapValidator.validate(
        map,
        projectDialogueContext: projectedManifest,
      );
    }
  } on ValidationException catch (error) {
    throw semanticFailure(
      error.code ?? 'smart_tile_projected_state_invalid',
      error.message,
      details: error.details,
      remediation: error.remediation,
    );
  } on MapAuthoringException {
    rethrow;
  } on Object catch (error) {
    throw semanticFailure(
      'smart_tile_projected_state_invalid',
      'The native Smart Tile mutation would invalidate the project.',
      details: <String, Object?>{
        'validationType': error.runtimeType.toString(),
      },
    );
  }
}

/// Checks the boundary for maintenance actions that repair an existing native
/// project. It intentionally does not run full map validation: normalize and
/// merge must remain able to repair a pre-existing palette inconsistency.
void requireExistingNativeSmartTileProject(
  ProjectSnapshot snapshot, {
  required String operation,
  String? layerId,
}) {
  _requireCompleteMapSnapshot(snapshot);
  _requireNoLegacyTerrainOrPath(
    manifest: snapshot.manifest,
    maps: snapshot.maps,
  );
  if (snapshot.manifest.version != ProjectVersion.v5) {
    throw semanticFailure(
      'smart_tile_native_project_version_required',
      'Native Smart Tile maintenance requires a ProjectVersion.v5 manifest.',
      details: <String, Object?>{
        'projectVersion': snapshot.manifest.version.name,
        'operation': operation,
        if (layerId != null) 'layerId': layerId,
      },
    );
  }
  for (final map in snapshot.maps) {
    if (map.layers.any((candidate) => candidate is SmartTileLayer) &&
        map.version != ProjectVersion.v5) {
      throw semanticFailure(
        'smart_tile_native_project_version_required',
        'Native Smart Tile maintenance requires ProjectVersion.v5 maps.',
        details: <String, Object?>{
          'mapId': map.id,
          'mapVersion': map.version.name,
          'operation': operation,
          if (layerId != null) 'layerId': layerId,
        },
      );
    }
  }
}

void _requireCompleteMapSnapshot(ProjectSnapshot snapshot) {
  final manifestIds = <String>{};
  final duplicateManifestIds = <String>{};
  for (final entry in snapshot.manifest.maps) {
    if (!manifestIds.add(entry.id)) duplicateManifestIds.add(entry.id);
  }
  if (duplicateManifestIds.isNotEmpty) {
    final ids = duplicateManifestIds.toList()..sort();
    throw semanticFailure(
      'smart_tile_manifest_maps_duplicate',
      'The manifest contains duplicate map identities.',
      details: <String, Object?>{'mapIds': ids},
    );
  }

  final snapshotIds = snapshot.maps.map((map) => map.id).toSet();
  final missing = manifestIds.difference(snapshotIds).toList()..sort();
  if (missing.isNotEmpty) {
    throw semanticFailure(
      'smart_tile_project_maps_missing',
      'The project snapshot omits manifest maps.',
      details: <String, Object?>{'mapIds': missing},
    );
  }
  final extra = snapshotIds.difference(manifestIds).toList()..sort();
  if (extra.isNotEmpty) {
    throw semanticFailure(
      'smart_tile_project_maps_extra',
      'The project snapshot contains maps absent from the manifest.',
      details: <String, Object?>{'mapIds': extra},
    );
  }
}

void _requireNoLegacyTerrainOrPath({
  required ProjectManifest manifest,
  required Iterable<MapData> maps,
}) {
  if (manifest.terrainCategories.isNotEmpty ||
      manifest.pathCategories.isNotEmpty ||
      manifest.terrainPresets.isNotEmpty ||
      manifest.pathPresets.isNotEmpty ||
      manifest.pathPatternPresets.isNotEmpty) {
    throw semanticFailure(
      'smart_tile_legacy_project_unsupported',
      'Native Smart Tile authoring is blocked while the manifest still '
          'contains legacy Terrain/Path definitions.',
      details: const <String, Object?>{'resourceKind': 'project'},
      remediation: const <String>[
        'Remove or migrate every legacy Terrain/Path definition first.',
      ],
    );
  }
  for (final map in maps) {
    final legacyLayerIds = <String>[
      for (final layer in map.layers)
        if (layer is TerrainLayer || layer is PathLayer) layer.id,
    ];
    if (legacyLayerIds.isNotEmpty) {
      throw semanticFailure(
        'smart_tile_legacy_project_unsupported',
        'Native Smart Tile authoring is blocked while a map still contains '
            'legacy Terrain/Path layers.',
        details: <String, Object?>{
          'mapId': map.id,
          'layerIds': legacyLayerIds,
        },
        remediation: const <String>[
          'Remove or migrate every legacy Terrain/Path layer first.',
        ],
      );
    }
  }
}
