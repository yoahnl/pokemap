import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/project_file_reader.dart';
import '../../references/project_reference_index.dart';
import '../../references/reference_impact.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';

/// Stable domain failure returned by map action adapters.
final class MapAuthoringException implements Exception {
  MapAuthoringException({
    required this.code,
    required this.message,
    Map<String, Object?> details = const {},
    Iterable<String> remediation = const [],
  })  : details = Map.unmodifiable(details),
        remediation = List.unmodifiable(remediation);

  final String code;
  final String message;
  final Map<String, Object?> details;
  final List<String> remediation;

  @override
  String toString() => 'MapAuthoringException($code): $message';
}

/// Pure map lifecycle adapter. It never receives a filesystem write port.
final class MapLifecycleAdapter {
  const MapLifecycleAdapter();

  AuthoringMutationDraft create(AuthoringPlanningContext context) {
    final parameters = _Parameters(
      context.request.parameters,
      allowed: const {
        'mapId',
        'name',
        'width',
        'height',
        'groupId',
        'role',
        'tilesetId',
      },
    );
    final snapshot = context.snapshot;
    _requireManifestOwnership(snapshot.manifest);
    final mapId = _requireAvailableMapId(
      parameters.string('mapId'),
      snapshot.manifest,
    );
    final name = _mapName(parameters.optionalString('name') ?? mapId);
    final width = parameters.positiveInt('width');
    final height = parameters.positiveInt('height');
    final groupId = parameters.optionalString('groupId');
    if (groupId != null &&
        !snapshot.manifest.groups.any((group) => group.id == groupId)) {
      throw _failure(
        'map.group_missing',
        'The requested map group does not exist.',
        details: {'groupId': groupId},
      );
    }
    final role = _mapRole(parameters.optionalString('role') ?? 'exterior');
    final explicitTilesetId = parameters.optionalString('tilesetId');
    final tilesetId = explicitTilesetId == null
        ? _pickDefaultTilesetId(snapshot.manifest, groupId)
        : _requireTileset(snapshot.manifest, explicitTilesetId);
    final map = MapData(
      id: mapId,
      name: name,
      size: GridSize(width: width, height: height),
      version: ProjectVersion.v3,
      visualStack: MapVisualStackConfig.canonicalV1,
      tilesetId: tilesetId ?? '',
      layers: [
        MapLayer.tile(
          id: 'l_base',
          name: 'Base',
          tilesetId: tilesetId,
          tiles: List<int>.filled(width * height, 0, growable: false),
        ),
        MapLayer.terrain(
          id: 'l_terrain',
          name: 'Terrain',
          terrains: List<TerrainType>.filled(
            width * height,
            TerrainType.none,
            growable: false,
          ),
        ),
        MapLayer.collision(
          id: 'l_collisions',
          name: 'Collisions',
          collisions: List<bool>.filled(
            width * height,
            false,
            growable: false,
          ),
        ),
      ],
    );
    final path = _canonicalMapPath(mapId);
    _requireAvailablePath(snapshot.manifest, path);
    final manifest = snapshot.manifest.copyWith(
      maps: [
        ...snapshot.manifest.maps,
        ProjectMapEntry(
          id: mapId,
          name: name,
          relativePath: path,
          groupId: groupId,
          role: role,
        ),
      ],
    );
    _validateProjected(manifest, [map]);
    final mapRef = AuthoringResourceRef(kind: 'map', id: mapId);
    final projectRef = _existingResource(snapshot, 'project', 'project');
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: mapRef,
            storageKey: path,
            beforeBytes: null,
            afterBytes: encodeMapAuthoringDocument(map),
          ),
          _manifestChange(snapshot, manifest, projectRef),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: mapRef,
            path: '/',
            after: _mapSummary(map),
          ),
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: projectRef,
            path: '/maps/$mapId',
            after: _entrySummary(manifest.maps.last),
          ),
        ]),
      ),
      preview: {
        'operation': 'create',
        'mapId': mapId,
        'name': name,
        'size': {'width': width, 'height': height},
        'layerCount': map.layers.length,
        'storageGuarantee': 'recoverable',
      },
    );
  }

  AuthoringMutationDraft save(AuthoringPlanningContext context) {
    final parameters = _Parameters(
      context.request.parameters,
      allowed: const {'map'},
    );
    final rawMap = parameters.object('map');
    late final MapData updated;
    try {
      updated = MapData.fromJson(Map<String, dynamic>.from(rawMap));
    } on Object {
      throw _failure(
        'map.document_invalid',
        'The supplied map document is not valid PokeMap data.',
      );
    }
    _requireCanonicalMapId(updated.id);
    final snapshot = context.snapshot;
    _requireManifestOwnership(snapshot.manifest);
    final entry = _requireMapEntry(snapshot.manifest, updated.id);
    final before = _requireMap(snapshot, updated.id);
    _validateProjected(snapshot.manifest, [updated]);
    final beforeBytes = snapshot.resourceBytes('map:${updated.id}');
    final afterBytes = encodeMapAuthoringDocument(updated);
    _requireChanged(beforeBytes, afterBytes);
    final resource = _existingResource(snapshot, 'map', updated.id);
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: resource,
            storageKey: entry.relativePath,
            beforeBytes: beforeBytes,
            afterBytes: afterBytes,
          ),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: resource,
            path: '/',
            before: _mapSummary(before),
            after: _mapSummary(updated),
          ),
        ]),
      ),
      preview: {
        'operation': 'save',
        'mapId': updated.id,
        'before': _mapSummary(before),
        'after': _mapSummary(updated),
      },
    );
  }

  AuthoringMutationDraft rename(AuthoringPlanningContext context) {
    final parameters = _Parameters(
      context.request.parameters,
      allowed: const {'mapId', 'newMapId', 'name'},
    );
    final snapshot = context.snapshot;
    final oldId = parameters.string('mapId');
    _requireManifestOwnership(snapshot.manifest, allowedLegacyId: oldId);
    final entry = _requireMapEntry(snapshot.manifest, oldId);
    final source = _requireMap(snapshot, oldId);
    final newId = _requireAvailableMapId(
      parameters.string('newMapId'),
      snapshot.manifest,
      excludingId: oldId,
    );
    final name = _mapName(parameters.optionalString('name') ?? newId);
    final newPath = _canonicalMapPath(newId);
    _requireAvailablePath(
      snapshot.manifest,
      newPath,
      excludingId: oldId,
    );
    if (_pathKey(entry.relativePath) == _pathKey(newPath)) {
      throw _failure(
        'map.case_equivalent_rename',
        'Case-equivalent map paths require an explicit migration.',
      );
    }
    final impact = _referenceImpact(snapshot, oldId, newId: newId);
    _requireNoDependents(impact);
    final renamed = source.copyWith(id: newId, name: name);
    final manifest = snapshot.manifest.copyWith(
      maps: [
        for (final candidate in snapshot.manifest.maps)
          if (candidate.id == oldId)
            candidate.copyWith(id: newId, name: name, relativePath: newPath)
          else
            candidate,
      ],
    );
    _validateProjected(
      manifest,
      [
        for (final map in snapshot.maps)
          if (map.id == oldId) renamed else map,
      ],
    );
    final oldRef = _existingResource(snapshot, 'map', oldId);
    final newRef = AuthoringResourceRef(kind: 'map', id: newId);
    final projectRef = _existingResource(snapshot, 'project', 'project');
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: oldRef,
            storageKey: entry.relativePath,
            beforeBytes: snapshot.resourceBytes('map:$oldId'),
            afterBytes: null,
          ),
          AuthoringResourceChange(
            resource: newRef,
            storageKey: newPath,
            beforeBytes: null,
            afterBytes: encodeMapAuthoringDocument(renamed),
          ),
          _manifestChange(snapshot, manifest, projectRef),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.remove,
            resource: oldRef,
            path: '/',
            before: _mapSummary(source),
          ),
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: newRef,
            path: '/',
            after: _mapSummary(renamed),
          ),
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.move,
            resource: projectRef,
            path: '/maps/$oldId',
            before: _entrySummary(entry),
            after: _entrySummary(
              manifest.maps.singleWhere((candidate) => candidate.id == newId),
            ),
          ),
        ]),
      ),
      preview: {
        'operation': 'rename',
        'mapId': oldId,
        'newMapId': newId,
        'storageGuarantee': 'recoverable',
      },
      referenceImpact: _boundedImpact(impact),
    );
  }

  AuthoringMutationDraft duplicate(AuthoringPlanningContext context) {
    final parameters = _Parameters(
      context.request.parameters,
      allowed: const {'sourceMapId', 'targetMapId', 'name'},
    );
    final snapshot = context.snapshot;
    _requireManifestOwnership(snapshot.manifest);
    final sourceId = parameters.string('sourceMapId');
    final entry = _requireMapEntry(snapshot.manifest, sourceId);
    final source = _requireMap(snapshot, sourceId);
    final requestedId = parameters.optionalString('targetMapId');
    final targetId = requestedId == null
        ? _nextCopyId(sourceId, snapshot.manifest.maps.map((map) => map.id))
        : _requireAvailableMapId(requestedId, snapshot.manifest);
    final name = _mapName(parameters.optionalString('name') ?? targetId);
    final path = _canonicalMapPath(targetId);
    _requireAvailablePath(snapshot.manifest, path);
    final duplicated = source.copyWith(id: targetId, name: name);
    final manifest = snapshot.manifest.copyWith(
      maps: [
        ...snapshot.manifest.maps,
        ProjectMapEntry(
          id: targetId,
          name: name,
          relativePath: path,
          groupId: entry.groupId,
          role: entry.role,
        ),
      ],
    );
    _validateProjected(manifest, [...snapshot.maps, duplicated]);
    final mapRef = AuthoringResourceRef(kind: 'map', id: targetId);
    final projectRef = _existingResource(snapshot, 'project', 'project');
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: mapRef,
            storageKey: path,
            beforeBytes: null,
            afterBytes: encodeMapAuthoringDocument(duplicated),
          ),
          _manifestChange(snapshot, manifest, projectRef),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: mapRef,
            path: '/',
            after: _mapSummary(duplicated),
          ),
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: projectRef,
            path: '/maps/$targetId',
            after: _entrySummary(manifest.maps.last),
          ),
        ]),
      ),
      preview: {
        'operation': 'duplicate',
        'sourceMapId': sourceId,
        'mapId': targetId,
        'storageGuarantee': 'recoverable',
      },
    );
  }

  AuthoringMutationDraft delete(AuthoringPlanningContext context) {
    final parameters = _Parameters(
      context.request.parameters,
      allowed: const {'mapId'},
    );
    final snapshot = context.snapshot;
    _requireManifestOwnership(snapshot.manifest);
    final mapId = parameters.string('mapId');
    final entry = _requireMapEntry(snapshot.manifest, mapId);
    final map = _requireMap(snapshot, mapId);
    final impact = _referenceImpact(snapshot, mapId);
    _requireNoDependents(impact);
    final manifest = snapshot.manifest.copyWith(
      maps: snapshot.manifest.maps
          .where((candidate) => candidate.id != mapId)
          .toList(growable: false),
    );
    _validateProjected(
      manifest,
      snapshot.maps
          .where((candidate) => candidate.id != mapId)
          .toList(growable: false),
    );
    final mapRef = _existingResource(snapshot, 'map', mapId);
    final projectRef = _existingResource(snapshot, 'project', 'project');
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: mapRef,
            storageKey: entry.relativePath,
            beforeBytes: snapshot.resourceBytes('map:$mapId'),
            afterBytes: null,
          ),
          _manifestChange(snapshot, manifest, projectRef),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.remove,
            resource: mapRef,
            path: '/',
            before: _mapSummary(map),
          ),
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.remove,
            resource: projectRef,
            path: '/maps/$mapId',
            before: _entrySummary(entry),
          ),
        ]),
      ),
      preview: {
        'operation': 'delete',
        'mapId': mapId,
        'storageGuarantee': 'recoverable',
      },
      referenceImpact: _boundedImpact(impact),
    );
  }

  AuthoringMutationDraft resize(AuthoringPlanningContext context) {
    final parameters = _Parameters(
      context.request.parameters,
      allowed: const {'mapId', 'width', 'height'},
    );
    final snapshot = context.snapshot;
    _requireManifestOwnership(snapshot.manifest);
    final mapId = parameters.string('mapId');
    final entry = _requireMapEntry(snapshot.manifest, mapId);
    final map = _requireMap(snapshot, mapId);
    final width = parameters.positiveInt('width');
    final height = parameters.positiveInt('height');
    final plan = planMapResize(
      map,
      width: width,
      height: height,
      project: snapshot.manifest,
      tileSizePx: GridSize(
        width: snapshot.manifest.settings.tileWidth,
        height: snapshot.manifest.settings.tileHeight,
      ),
    );
    if (plan.isNoOp) {
      throw _failure('map.no_change', 'The requested resize changes nothing.');
    }
    if (!plan.canApply) {
      throw _failure(
        'map.resize_impacts',
        'The resize would discard or invalidate authored map data.',
        details: {
          'mapId': mapId,
          'impactCount': plan.impacts.length,
          'impacts':
              plan.impacts.map(_resizeImpactJson).toList(growable: false),
          'borderDiagnostics': plan.borderDiagnostics.diagnostics
              .map(_borderDiagnosticJson)
              .toList(growable: false),
        },
        remediation: const [
          'Move or clear the impacted authored data before resizing.',
        ],
      );
    }
    final result = resizeMapDataWithBorderDiagnostics(
      map,
      width: width,
      height: height,
      tileSizePx: GridSize(
        width: snapshot.manifest.settings.tileWidth,
        height: snapshot.manifest.settings.tileHeight,
      ),
    );
    if (!result.canApply || result.map == null) {
      throw _failure(
        'map.resize_border_invalid',
        'Border diagnostics prevent this map resize.',
        details: {
          'diagnostics': result.diagnosticReport.diagnostics
              .map(_borderDiagnosticJson)
              .toList(growable: false),
        },
      );
    }
    final resized = result.map!;
    _validateProjected(snapshot.manifest, [resized]);
    final mapRef = _existingResource(snapshot, 'map', mapId);
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: mapRef,
            storageKey: entry.relativePath,
            beforeBytes: snapshot.resourceBytes('map:$mapId'),
            afterBytes: encodeMapAuthoringDocument(resized),
          ),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: mapRef,
            path: '/size',
            before: _sizeJson(map.size),
            after: _sizeJson(resized.size),
          ),
        ]),
      ),
      preview: {
        'operation': 'resize',
        'mapId': mapId,
        'before': _sizeJson(map.size),
        'after': _sizeJson(resized.size),
        'impactCount': 0,
        'borderDiagnostics': result.diagnosticReport.diagnostics
            .map(_borderDiagnosticJson)
            .toList(growable: false),
      },
    );
  }
}

/// Editor-compatible canonical bytes for one complete map document.
List<int> encodeMapAuthoringDocument(MapData map) => utf8.encode(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );

List<int> _encodeManifest(
  ProjectSnapshot snapshot,
  ProjectManifest manifest,
) {
  late final Map<String, Object?> original;
  try {
    final decoded = jsonDecode(utf8.decode(snapshot.resourceBytes('project')));
    if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
      throw const FormatException();
    }
    original = Map<String, Object?>.from(decoded);
  } on Object {
    throw _failure(
      'project.manifest_invalid',
      'The original project manifest cannot be preserved safely.',
    );
  }
  final next = Map<String, Object?>.from(original)
    ..addAll(Map<String, Object?>.from(manifest.toJson()));
  return utf8.encode(const JsonEncoder.withIndent('  ').convert(next));
}

AuthoringResourceChange _manifestChange(
  ProjectSnapshot snapshot,
  ProjectManifest manifest,
  AuthoringResourceRef resource,
) {
  return AuthoringResourceChange(
    resource: resource,
    storageKey: 'project.json',
    beforeBytes: snapshot.resourceBytes('project'),
    afterBytes: _encodeManifest(snapshot, manifest),
  );
}

AuthoringResourceRef _existingResource(
  ProjectSnapshot snapshot,
  String kind,
  String id,
) {
  final identity = kind == 'project' ? 'project' : '$kind:$id';
  final revision = snapshot.resourceFingerprints[identity];
  if (revision == null) {
    throw _failure(
      'map.resource_preimage_missing',
      'A required resource revision is unavailable.',
      details: {'kind': kind, 'id': id},
    );
  }
  return AuthoringResourceRef(kind: kind, id: id, revision: revision);
}

void _validateProjected(ProjectManifest manifest, Iterable<MapData> maps) {
  try {
    ProjectValidator.validate(manifest);
    for (final map in maps) {
      MapValidator.validate(map, projectDialogueContext: manifest);
    }
  } on Object catch (error) {
    throw _failure(
      'map.projected_state_invalid',
      'The lifecycle operation would produce invalid PokeMap data.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}

ProjectMapEntry _requireMapEntry(ProjectManifest manifest, String mapId) {
  for (final entry in manifest.maps) {
    if (entry.id == mapId) return entry;
  }
  throw _failure(
    'map.not_found',
    'The requested map does not exist.',
    details: {'mapId': mapId},
  );
}

MapData _requireMap(ProjectSnapshot snapshot, String mapId) {
  final map = snapshot.mapById(mapId);
  if (map == null) {
    throw _failure(
      'map.document_missing',
      'The requested map document is unavailable.',
      details: {'mapId': mapId},
    );
  }
  return map;
}

String _requireAvailableMapId(
  String value,
  ProjectManifest manifest, {
  String? excludingId,
}) {
  final id = _requireCanonicalMapId(value);
  for (final entry in manifest.maps) {
    if (entry.id == excludingId) continue;
    if (entry.id.toLowerCase() == id.toLowerCase()) {
      throw _failure(
        'map.id_conflict',
        'A map already owns the requested identity.',
        details: {'mapId': id},
      );
    }
  }
  return id;
}

String _requireCanonicalMapId(String value) {
  if (value.length > 64 ||
      !RegExp(r'^[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?$').hasMatch(value) ||
      _windowsReservedMapIds.contains(value.toLowerCase())) {
    throw _failure(
      'map.id_invalid',
      'Map IDs must be portable lowercase filename-safe identifiers.',
      details: {'mapId': value},
    );
  }
  return value;
}

void _requireManifestOwnership(
  ProjectManifest manifest, {
  String? allowedLegacyId,
}) {
  final ids = <String>{};
  final paths = <String>{};
  for (final entry in manifest.maps) {
    if (!ids.add(entry.id.toLowerCase())) {
      throw _failure(
        'map.manifest_id_conflict',
        'Map manifest identities are ambiguous.',
      );
    }
    if (entry.id != allowedLegacyId) _requireCanonicalMapId(entry.id);
    late final String path;
    try {
      path = validateProjectRelativePath(entry.relativePath).join('/');
    } on Object {
      throw _failure(
        'map.manifest_path_invalid',
        'A map manifest path is unsafe.',
        details: {'mapId': entry.id},
      );
    }
    if (!paths.add(_pathKey(path))) {
      throw _failure(
        'map.manifest_path_conflict',
        'Multiple map entries own the same portable path.',
      );
    }
  }
}

void _requireAvailablePath(
  ProjectManifest manifest,
  String path, {
  String? excludingId,
}) {
  final key = _pathKey(path);
  for (final entry in manifest.maps) {
    if (entry.id == excludingId) continue;
    if (_pathKey(entry.relativePath) == key) {
      throw _failure(
        'map.path_conflict',
        'A map manifest entry already owns the target document path.',
      );
    }
  }
}

ProjectReferenceImpact _referenceImpact(
  ProjectSnapshot snapshot,
  String mapId, {
  String? newId,
}) {
  final target = ProjectReferenceKey(
    kind: NarrativeDependencyTargetKind.sourceMap.name,
    id: mapId,
    scope: 'map',
    parentId: mapId,
    sourceKind: 'map',
  );
  final analyzer = ProjectReferenceImpactAnalyzer(
    ProjectReferenceIndex.fromSnapshot(snapshot),
  );
  return newId == null
      ? analyzer.deletionImpact(target)
      : analyzer.renameImpact(target, newId: newId);
}

void _requireNoDependents(ProjectReferenceImpact impact) {
  if (impact.affectedEdges.isEmpty) return;
  throw _failure(
    'map.references_blocking',
    'The map is still referenced and cannot be renamed or deleted safely.',
    details: _boundedImpact(impact),
    remediation: const [
      'Remove or explicitly rewrite every incoming reference first.',
    ],
  );
}

Map<String, Object?> _boundedImpact(ProjectReferenceImpact impact) => {
      'kind': impact.kind.name,
      'target': impact.target.toJson(),
      if (impact.replacement != null)
        'replacement': impact.replacement!.toJson(),
      'dependentCount': impact.directDependents.length,
      'edgeCount': impact.affectedEdges.length,
      'runtimeBlocking': impact.runtimeBlocking,
      'dependents': impact.directDependents
          .take(32)
          .map((dependent) => dependent.toJson())
          .toList(growable: false),
      'edges': impact.affectedEdges
          .take(64)
          .map((edge) => edge.toJson())
          .toList(growable: false),
      'truncated': impact.directDependents.length > 32 ||
          impact.affectedEdges.length > 64,
    };

String? _pickDefaultTilesetId(ProjectManifest manifest, String? groupId) {
  if (manifest.tilesets.isEmpty) return null;
  final sorted = manifest.tilesets.toList()
    ..sort((left, right) {
      final order = left.sortOrder.compareTo(right.sortOrder);
      return order != 0 ? order : left.id.compareTo(right.id);
    });
  if (groupId != null) {
    final ancestors = <String>{};
    String? cursor = groupId;
    while (cursor != null && ancestors.add(cursor)) {
      cursor = manifest.groups
          .where((group) => group.id == cursor)
          .firstOrNull
          ?.parentGroupId;
    }
    final grouped = sorted.where(
      (tileset) =>
          tileset.scope == TilesetScope.group &&
          tileset.groupId != null &&
          ancestors.contains(tileset.groupId),
    );
    if (grouped.isNotEmpty) return grouped.first.id;
  }
  final world = sorted.where((tileset) => tileset.isWorldTileset);
  if (world.isNotEmpty) return world.first.id;
  final global =
      sorted.where((tileset) => tileset.scope == TilesetScope.global);
  return global.isNotEmpty ? global.first.id : sorted.first.id;
}

String _requireTileset(ProjectManifest manifest, String id) {
  if (!manifest.tilesets.any((tileset) => tileset.id == id)) {
    throw _failure(
      'map.tileset_missing',
      'The requested tileset does not exist.',
      details: {'tilesetId': id},
    );
  }
  return id;
}

String _nextCopyId(String sourceId, Iterable<String> existingIds) {
  _requireCanonicalMapId(sourceId);
  final occupied = existingIds.map((id) => id.toLowerCase()).toSet();
  for (var copy = 0; copy < 100000; copy++) {
    final suffix = copy == 0 ? '_copy' : '_copy_$copy';
    final bounded = sourceId.substring(
      0,
      sourceId.length.clamp(1, 64 - suffix.length),
    );
    final candidate = '$bounded$suffix';
    if (!occupied.contains(candidate.toLowerCase())) return candidate;
  }
  throw _failure(
    'map.copy_id_unavailable',
    'No portable copy identity could be allocated.',
  );
}

MapRole _mapRole(String value) {
  for (final role in MapRole.values) {
    if (role.name == value) return role;
  }
  throw _failure(
    'map.role_invalid',
    'The requested map role is unsupported.',
    details: {'role': value},
  );
}

String _mapName(String value) {
  if (value.trim() != value || value.isEmpty || value.length > 160) {
    throw _failure(
      'map.name_invalid',
      'Map names must be nonblank, trimmed, and at most 160 characters.',
    );
  }
  return value;
}

Map<String, Object?> _mapSummary(MapData map) => {
      'id': map.id,
      'name': map.name,
      'size': _sizeJson(map.size),
      'layerCount': map.layers.length,
      'entityCount': map.entities.length,
      'warpCount': map.warps.length,
    };

Map<String, Object?> _entrySummary(ProjectMapEntry entry) => {
      'id': entry.id,
      'name': entry.name,
      if (entry.groupId != null) 'groupId': entry.groupId,
      'role': entry.role.name,
      'sortOrder': entry.sortOrder,
    };

Map<String, Object?> _sizeJson(GridSize size) => {
      'width': size.width,
      'height': size.height,
    };

Map<String, Object?> _resizeImpactJson(MapResizeImpact impact) => {
      'kind': impact.kind.name,
      'reason': impact.reason.name,
      'subjectId': impact.subjectId,
      'subjectLabel': impact.subjectLabel,
      if (impact.layerId != null) 'layerId': impact.layerId,
      'affectedCount': impact.affectedCount,
      'positions': impact.positions
          .map((position) => {'x': position.x, 'y': position.y})
          .toList(growable: false),
      'relatedIds': impact.relatedIds,
      if (impact.diagnosticCode != null)
        'diagnosticCode': impact.diagnosticCode,
    };

Map<String, Object?> _borderDiagnosticJson(BorderDiagnostic diagnostic) => {
      'code': diagnostic.code,
      'severity': diagnostic.severity.name,
      'phase': diagnostic.phase.name,
      'scope': diagnostic.scope.name,
      if (diagnostic.blueprintId != null) 'blueprintId': diagnostic.blueprintId,
      if (diagnostic.featureId != null) 'featureId': diagnostic.featureId,
      if (diagnostic.cell != null)
        'cell': {'x': diagnostic.cell!.x, 'y': diagnostic.cell!.y},
      'parameters': diagnostic.parameters,
      'suggestedAction': diagnostic.suggestedAction,
    };

void _requireChanged(List<int> before, List<int> after) {
  if (before.length != after.length) return;
  for (var index = 0; index < before.length; index++) {
    if (before[index] != after[index]) return;
  }
  throw _failure('map.no_change', 'The supplied map changes nothing.');
}

String _canonicalMapPath(String mapId) => 'maps/$mapId.json';

String _pathKey(String path) {
  try {
    return validateProjectRelativePath(path).join('/').toLowerCase();
  } on Object {
    throw _failure('map.path_invalid', 'A map path is unsafe.');
  }
}

MapAuthoringException _failure(
  String code,
  String message, {
  Map<String, Object?> details = const {},
  Iterable<String> remediation = const [],
}) {
  return MapAuthoringException(
    code: code,
    message: message,
    details: details,
    remediation: remediation,
  );
}

final class _Parameters {
  _Parameters(Map<String, Object?> values, {required Set<String> allowed})
      : _values = values {
    final unknown = values.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw _failure(
        'map.request_invalid',
        'The map action contains unsupported parameters.',
        details: {'unknownParameters': unknown},
      );
    }
  }

  final Map<String, Object?> _values;

  String string(String key) {
    final value = _values[key];
    if (value is! String || value.trim() != value || value.isEmpty) {
      throw _invalid(key, 'a nonblank trimmed string');
    }
    return value;
  }

  String? optionalString(String key) {
    final value = _values[key];
    return value == null ? null : string(key);
  }

  int positiveInt(String key) {
    final value = _values[key];
    if (value is! int || value <= 0) throw _invalid(key, 'a positive integer');
    return value;
  }

  Map<String, Object?> object(String key) {
    final value = _values[key];
    if (value is! Map || value.keys.any((candidate) => candidate is! String)) {
      throw _invalid(key, 'a JSON object');
    }
    return Map<String, Object?>.from(value);
  }

  MapAuthoringException _invalid(String key, String expected) => _failure(
        'map.request_invalid',
        'Parameter "$key" must be $expected.',
        details: {'parameter': key, 'expected': expected},
      );
}

const Set<String> _windowsReservedMapIds = {
  'con',
  'prn',
  'aux',
  'nul',
  'com1',
  'com2',
  'com3',
  'com4',
  'com5',
  'com6',
  'com7',
  'com8',
  'com9',
  'lpt1',
  'lpt2',
  'lpt3',
  'lpt4',
  'lpt5',
  'lpt6',
  'lpt7',
  'lpt8',
  'lpt9',
};
