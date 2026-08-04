import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/json_contract_support.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import '../maps/map_lifecycle_adapter.dart';
import 'asset_store.dart';

final class VisualLibraryException implements Exception {
  VisualLibraryException(
    this.code,
    this.message, {
    Map<String, Object?> details = const {},
  }) : details = freezeContractJsonObject(details, field: 'details');

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'VisualLibraryException($code): $message';
}

final class TilesetRegridImpact {
  const TilesetRegridImpact({
    required this.ownerKind,
    required this.ownerId,
    required this.path,
    required this.before,
    required this.after,
  });

  final String ownerKind;
  final String ownerId;
  final String path;
  final TilesetSourceRect before;
  final TilesetSourceRect? after;

  bool get blocking => after == null;

  Map<String, Object?> toJson() => {
        'ownerKind': ownerKind,
        'ownerId': ownerId,
        'path': path,
        'before': before.toJson(),
        if (after != null) 'after': after!.toJson(),
        'blocking': blocking,
      };
}

final class TilesetRegridPreview {
  TilesetRegridPreview({
    required this.before,
    required this.after,
    required Iterable<TilesetRegridImpact> impacts,
  }) : impacts = List.unmodifiable(
          impacts.toList()
            ..sort((left, right) {
              final kind = left.ownerKind.compareTo(right.ownerKind);
              if (kind != 0) return kind;
              final id = left.ownerId.compareTo(right.ownerId);
              return id != 0 ? id : left.path.compareTo(right.path);
            }),
        );

  final ProjectRegularAtlasTilesetSource before;
  final ProjectRegularAtlasTilesetSource after;
  final List<TilesetRegridImpact> impacts;

  bool get canApply => impacts.every((impact) => !impact.blocking);

  Map<String, Object?> toJson() => {
        'before': before.toJson(),
        'after': after.toJson(),
        'canApply': canApply,
        'impacts': [for (final impact in impacts) impact.toJson()],
      };
}

/// Pure canonical tileset projector shared by standalone and composite flows.
final class TilesetImportProjector {
  const TilesetImportProjector();

  ProjectManifest project(
    ProjectManifest manifest, {
    required AssetCatalog assets,
    required ProjectTilesetEntry tileset,
  }) {
    final atlas = _requireRegularAtlas(tileset);
    _requireAssetPath(assets, atlas, tileset.relativePath);
    return const TilesetActions().upsert(manifest, tileset: tileset);
  }
}

final class TilesetActions {
  const TilesetActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    visualLibraryDescriptor(
      'tileset.upsert',
      'Create or replace a validated canonical tileset',
    ),
    visualLibraryDescriptor(
      'tileset.delete',
      'Delete one unreferenced tileset',
      risk: AuthoringRiskLevel.high,
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters);
    final manifest = context.snapshot.manifest;
    switch (context.request.actionId) {
      case 'tileset.upsert':
        parameters.allow(const {'tileset'});
        final tileset = ProjectTilesetEntry.fromJson(
          Map<String, dynamic>.from(parameters.object('tileset')),
        );
        final assets = _requireAssetCatalog(context.snapshot);
        final next = const TilesetImportProjector().project(
          manifest,
          assets: assets,
          tileset: tileset,
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'tileset.upsert',
          path: '/tilesets/${tileset.id}',
          after: tileset.toJson(),
        );
      case 'tileset.delete':
        parameters.allow(const {'tilesetId'});
        final id = parameters.string('tilesetId');
        final next =
            delete(manifest, maps: context.snapshot.maps, tilesetId: id);
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'tileset.delete',
          path: '/tilesets/$id',
          before: {'tilesetId': id},
        );
      default:
        throw VisualLibraryException(
          'visual.action_unsupported',
          'The requested tileset action is unsupported.',
        );
    }
  }

  ProjectManifest upsert(
    ProjectManifest manifest, {
    required ProjectTilesetEntry tileset,
  }) {
    final atlas = _requireRegularAtlas(tileset);
    _validateRegularAtlas(tileset.id, atlas);
    final tilesets = [
      for (final existing in manifest.tilesets)
        if (existing.id != tileset.id) existing,
      tileset,
    ]..sort((left, right) => left.id.compareTo(right.id));
    final next = manifest.copyWith(tilesets: tilesets);
    final atlases = readTilesetAtlases(next);
    _validateManifestFramesForTileset(next, atlases, tileset.id);
    return next;
  }

  ProjectManifest delete(
    ProjectManifest manifest, {
    required Iterable<MapData> maps,
    required String tilesetId,
  }) {
    if (!manifest.tilesets.any((tileset) => tileset.id == tilesetId)) {
      throw VisualLibraryException(
        'tileset.unknown',
        'The tileset identity is unknown.',
        details: {'tilesetId': tilesetId},
      );
    }
    final references = visualReferencesForTileset(manifest, maps, tilesetId);
    if (references.isNotEmpty) {
      throw VisualLibraryException(
        'tileset.references_blocking',
        'The tileset is still referenced and cannot be deleted safely.',
        details: {'tilesetId': tilesetId, 'references': references},
      );
    }
    return manifest.copyWith(
      tilesets: manifest.tilesets
          .where((tileset) => tileset.id != tilesetId)
          .toList(growable: false),
    );
  }

  void validateFrame(
    TilesetVisualFrame frame, {
    required String owningTilesetId,
    required Map<String, ProjectRegularAtlasTilesetSource> atlases,
  }) {
    final tilesetId =
        frame.tilesetId.isEmpty ? owningTilesetId : frame.tilesetId;
    final atlas = atlases[tilesetId];
    if (atlas == null) {
      throw VisualLibraryException(
        'tileset.atlas_missing',
        'A visual frame targets a tileset without atlas metadata.',
        details: {'tilesetId': tilesetId},
      );
    }
    final source = frame.source;
    if (source.x < 0 ||
        source.y < 0 ||
        source.width <= 0 ||
        source.height <= 0 ||
        source.x + source.width > atlas.columns ||
        source.y + source.height > atlas.rows) {
      throw VisualLibraryException(
        'tileset.source_out_of_bounds',
        'A visual source rectangle leaves the real atlas bounds.',
        details: {
          'tilesetId': tilesetId,
          'source': source.toJson(),
          'columns': atlas.columns,
          'rows': atlas.rows,
        },
      );
    }
    if (frame.durationMs != null && frame.durationMs! <= 0) {
      throw VisualLibraryException(
        'tileset.frame_duration_invalid',
        'Animated frame durations must be positive.',
      );
    }
  }

  TilesetRegridPreview previewRegrid(
    ProjectManifest manifest, {
    required String tilesetId,
    required int tileWidth,
    required int tileHeight,
  }) {
    final current = readTilesetAtlases(manifest)[tilesetId];
    if (current == null) {
      throw VisualLibraryException(
        'tileset.atlas_missing',
        'The tileset does not have a regular atlas source.',
        details: <String, Object?>{'tilesetId': tilesetId},
      );
    }
    final after = _regridAtlas(
      tilesetId,
      current,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
    final impacts = <TilesetRegridImpact>[];
    for (final frame in _visualFramesForTileset(manifest, tilesetId)) {
      impacts.add(
        TilesetRegridImpact(
          ownerKind: frame.ownerKind,
          ownerId: frame.ownerId,
          path: frame.path,
          before: frame.frame.source,
          after: _regridSource(frame.frame.source, current, after),
        ),
      );
    }
    return TilesetRegridPreview(
        before: current, after: after, impacts: impacts);
  }
}

AuthoringActionDescriptor visualLibraryDescriptor(
  String id,
  String summary, {
  AuthoringRiskLevel risk = AuthoringRiskLevel.medium,
  Iterable<String> resourceKinds = const ['project', 'asset'],
}) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'pokemap.authoring.$id.input.v1',
      outputSchemaId: 'pokemap.authoring.visual_library.mutation.v1',
      riskLevel: risk,
      resourceKinds: resourceKinds,
      capabilityIds: const ['authoring.visual_library'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );

AuthoringMutationDraft buildVisualManifestDraft(
  ProjectSnapshot snapshot,
  ProjectManifest manifest, {
  required String operation,
  required String path,
  Object? before,
  Object? after,
  Map<String, Object?> referenceImpact = const {},
}) {
  try {
    ProjectValidator.validate(manifest);
  } on Object catch (error) {
    throw VisualLibraryException(
      'visual.projected_state_invalid',
      'The visual library mutation would invalidate the project.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
  final project = AuthoringResourceRef(
    kind: 'project',
    id: 'project',
    revision: snapshot.resourceFingerprints['project'],
  );
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [
        AuthoringResourceChange(
          resource: project,
          storageKey: 'project.json',
          beforeBytes: snapshot.resourceBytes('project'),
          afterBytes: encodeProjectAuthoringDocument(snapshot, manifest),
        ),
      ],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation: operation.endsWith('.delete')
              ? AuthoringDiffOperation.remove
              : AuthoringDiffOperation.replace,
          resource: project,
          path: path,
          before: before,
          after: after,
        ),
      ]),
    ),
    preview: {'operation': operation, 'path': path},
    referenceImpact: referenceImpact,
  );
}

Map<String, ProjectRegularAtlasTilesetSource> readTilesetAtlases(
  ProjectManifest manifest,
) {
  final result = <String, ProjectRegularAtlasTilesetSource>{};
  for (final tileset in manifest.tilesets) {
    final source = tileset.source;
    if (source is ProjectRegularAtlasTilesetSource) {
      _validateRegularAtlas(tileset.id, source);
      result[tileset.id] = source;
    }
  }
  return result;
}

void validateManifestFrames(
  ProjectManifest manifest,
  Map<String, ProjectRegularAtlasTilesetSource> atlases,
) {
  const actions = TilesetActions();
  for (final tileset in manifest.tilesets) {
    for (final entry in tileset.paletteEntries) {
      for (final frame in entry.frames) {
        actions.validateFrame(
          frame,
          owningTilesetId: tileset.id,
          atlases: atlases,
        );
      }
    }
  }
  for (final element in manifest.elements) {
    for (final frame in element.frames) {
      actions.validateFrame(
        frame,
        owningTilesetId: element.tilesetId,
        atlases: atlases,
      );
    }
  }
}

void _validateManifestFramesForTileset(
  ProjectManifest manifest,
  Map<String, ProjectRegularAtlasTilesetSource> atlases,
  String tilesetId,
) {
  const actions = TilesetActions();
  for (final tileset in manifest.tilesets) {
    for (final entry in tileset.paletteEntries) {
      for (final frame in entry.frames) {
        if (tileset.id == tilesetId ||
            _frameTargets(frame, tileset.id, tilesetId)) {
          actions.validateFrame(
            frame,
            owningTilesetId: tileset.id,
            atlases: atlases,
          );
        }
      }
    }
  }
  for (final element in manifest.elements) {
    for (final frame in element.frames) {
      if (_frameTargets(frame, element.tilesetId, tilesetId)) {
        actions.validateFrame(
          frame,
          owningTilesetId: element.tilesetId,
          atlases: atlases,
        );
      }
    }
  }
}

List<String> visualReferencesForTileset(
  ProjectManifest manifest,
  Iterable<MapData> maps,
  String tilesetId,
) {
  final references = <String>{};
  for (final map in maps) {
    if (map.tilesetId == tilesetId) references.add('map:${map.id}:tileset');
    for (final layer in map.layers) {
      final json = layer.toJson();
      if (_containsExactString(json, tilesetId)) {
        references.add('map:${map.id}:layer:${layer.id}');
      }
    }
  }
  for (final element in manifest.elements) {
    if (element.tilesetId == tilesetId ||
        element.frames.any((frame) => frame.tilesetId == tilesetId)) {
      references.add('element:${element.id}');
    }
  }
  for (final tileset in manifest.tilesets) {
    if (tileset.id == tilesetId) continue;
    if (tileset.paletteEntries.any(
      (entry) => entry.frames.any((frame) => frame.tilesetId == tilesetId),
    )) {
      references.add('tileset:${tileset.id}:palette');
    }
  }
  return List.unmodifiable(references.toList()..sort());
}

List<_OwnedVisualFrame> _visualFramesForTileset(
  ProjectManifest manifest,
  String tilesetId,
) {
  final frames = <_OwnedVisualFrame>[];
  for (final tileset in manifest.tilesets) {
    for (final entry in tileset.paletteEntries) {
      for (var index = 0; index < entry.frames.length; index++) {
        final frame = entry.frames[index];
        if (_frameTargets(frame, tileset.id, tilesetId)) {
          frames.add(_OwnedVisualFrame(
              'paletteEntry', entry.id, 'frames/$index', frame));
        }
      }
    }
  }
  for (final element in manifest.elements) {
    for (var index = 0; index < element.frames.length; index++) {
      final frame = element.frames[index];
      if (_frameTargets(frame, element.tilesetId, tilesetId)) {
        frames.add(
            _OwnedVisualFrame('element', element.id, 'frames/$index', frame));
      }
    }
  }
  return frames;
}

final class VisualLibraryParameters {
  VisualLibraryParameters(Map<String, Object?> values) : _values = values;

  final Map<String, Object?> _values;

  void allow(Set<String> allowed) {
    final unknown = _values.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw VisualLibraryException(
        'visual.parameters_unknown',
        'The request contains unsupported visual library parameters.',
        details: {'parameters': unknown},
      );
    }
  }

  String string(String key) {
    final value = _values[key];
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw VisualLibraryException(
        'visual.parameter_invalid',
        'A required visual library parameter is invalid.',
        details: {'parameter': key},
      );
    }
    return value;
  }

  Map<String, Object?> object(String key) {
    final value = _values[key];
    if (value is! Map || value.keys.any((candidate) => candidate is! String)) {
      throw VisualLibraryException(
        'visual.parameter_invalid',
        'A required visual library object is invalid.',
        details: {'parameter': key},
      );
    }
    return Map<String, Object?>.from(value);
  }
}

void _requireAssetPath(
  AssetCatalog catalog,
  ProjectRegularAtlasTilesetSource atlas,
  String relativePath,
) {
  try {
    final asset = catalog.require(atlas.assetId);
    if (asset.logicalPath != relativePath ||
        !asset.artifact.mediaType.startsWith('image/')) {
      throw const FormatException();
    }
  } on Object {
    throw VisualLibraryException(
      'tileset.asset_invalid',
      'Tileset metadata must reference a catalogued image at the same path.',
      details: {'assetId': atlas.assetId, 'relativePath': relativePath},
    );
  }
}

AssetCatalog _requireAssetCatalog(ProjectSnapshot snapshot) {
  final bytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
  if (bytes == null) {
    throw VisualLibraryException(
      'tileset.asset_catalog_required',
      'Tileset authoring requires the canonical asset catalog.',
    );
  }
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException();
    return AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
  } on Object {
    throw VisualLibraryException(
      'tileset.asset_catalog_invalid',
      'The canonical asset catalog cannot be decoded.',
    );
  }
}

TilesetSourceRect? _regridSource(
  TilesetSourceRect source,
  ProjectRegularAtlasTilesetSource before,
  ProjectRegularAtlasTilesetSource after,
) {
  final horizontal = _regridAxis(
    sourceStart: source.x,
    sourceCount: source.width,
    beforeTileExtent: before.tileWidth,
    beforeMargin: before.marginX,
    beforeSpacing: before.spacingX,
    afterTileExtent: after.tileWidth,
    afterMargin: after.marginX,
    afterSpacing: after.spacingX,
  );
  final vertical = _regridAxis(
    sourceStart: source.y,
    sourceCount: source.height,
    beforeTileExtent: before.tileHeight,
    beforeMargin: before.marginY,
    beforeSpacing: before.spacingY,
    afterTileExtent: after.tileHeight,
    afterMargin: after.marginY,
    afterSpacing: after.spacingY,
  );
  if (horizontal == null || vertical == null) {
    return null;
  }
  return TilesetSourceRect(
    x: horizontal.start,
    y: vertical.start,
    width: horizontal.count,
    height: vertical.count,
  );
}

({int start, int count})? _regridAxis({
  required int sourceStart,
  required int sourceCount,
  required int beforeTileExtent,
  required int beforeMargin,
  required int beforeSpacing,
  required int afterTileExtent,
  required int afterMargin,
  required int afterSpacing,
}) {
  final pixelStart =
      beforeMargin + sourceStart * (beforeTileExtent + beforeSpacing);
  final pixelExtent =
      sourceCount * beforeTileExtent + (sourceCount - 1) * beforeSpacing;
  final relativeStart = pixelStart - afterMargin;
  final afterStride = afterTileExtent + afterSpacing;
  final extentNumerator = pixelExtent + afterSpacing;
  if (relativeStart < 0 ||
      relativeStart % afterStride != 0 ||
      extentNumerator % afterStride != 0) {
    return null;
  }
  final count = extentNumerator ~/ afterStride;
  if (count <= 0) return null;
  return (start: relativeStart ~/ afterStride, count: count);
}

ProjectRegularAtlasTilesetSource _requireRegularAtlas(
  ProjectTilesetEntry tileset,
) {
  final source = tileset.source;
  if (source is! ProjectRegularAtlasTilesetSource) {
    throw VisualLibraryException(
      'tileset.atlas_required',
      'Tileset authoring requires a canonical regular atlas source.',
      details: <String, Object?>{'tilesetId': tileset.id},
    );
  }
  return source;
}

void _validateRegularAtlas(
  String tilesetId,
  ProjectRegularAtlasTilesetSource atlas,
) {
  if (!_stableId(tilesetId) || !_stableId(atlas.assetId)) {
    throw VisualLibraryException(
      'tileset.atlas_identity_invalid',
      'Tileset and asset identities must be stable.',
    );
  }
  if (atlas.pixelWidth <= 0 ||
      atlas.pixelHeight <= 0 ||
      atlas.tileWidth <= 0 ||
      atlas.tileHeight <= 0 ||
      atlas.marginX < 0 ||
      atlas.marginY < 0 ||
      atlas.spacingX < 0 ||
      atlas.spacingY < 0 ||
      atlas.columns <= 0 ||
      atlas.rows <= 0 ||
      atlas.marginX * 2 +
              atlas.columns * atlas.tileWidth +
              (atlas.columns - 1) * atlas.spacingX !=
          atlas.pixelWidth ||
      atlas.marginY * 2 +
              atlas.rows * atlas.tileHeight +
              (atlas.rows - 1) * atlas.spacingY !=
          atlas.pixelHeight) {
    throw VisualLibraryException(
      'tileset.grid_invalid',
      'Atlas dimensions must exactly match its margins, spacing and tile grid.',
      details: atlas.toJson(),
    );
  }
  final ids = <int>{};
  for (final property in atlas.tileProperties) {
    if (property.tileId < 0 ||
        property.tileId >= atlas.tileCount ||
        !ids.add(property.tileId)) {
      throw VisualLibraryException(
        'tileset.tile_property_invalid',
        'Tile properties must target unique in-bounds tile identities.',
        details: <String, Object?>{
          'tilesetId': tilesetId,
          'tileId': property.tileId,
          'tileCount': atlas.tileCount,
        },
      );
    }
  }
}

ProjectRegularAtlasTilesetSource _regridAtlas(
  String tilesetId,
  ProjectRegularAtlasTilesetSource atlas, {
  required int tileWidth,
  required int tileHeight,
}) {
  final result = ProjectRegularAtlasTilesetSource(
    assetId: atlas.assetId,
    pixelWidth: atlas.pixelWidth,
    pixelHeight: atlas.pixelHeight,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    marginX: atlas.marginX,
    marginY: atlas.marginY,
    spacingX: atlas.spacingX,
    spacingY: atlas.spacingY,
    pixelOffsetX: atlas.pixelOffsetX,
    pixelOffsetY: atlas.pixelOffsetY,
    tileProperties: atlas.tileProperties,
  );
  _validateRegularAtlas(tilesetId, result);
  return result;
}

bool _frameTargets(TilesetVisualFrame frame, String owner, String target) =>
    (frame.tilesetId.isEmpty ? owner : frame.tilesetId) == target;

bool _containsExactString(Object? value, String expected) {
  if (value is String) return value == expected;
  if (value is List) {
    return value.any((item) => _containsExactString(item, expected));
  }
  if (value is Map) {
    return value.values.any((item) => _containsExactString(item, expected));
  }
  return false;
}

bool _stableId(String value) =>
    RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(value);

final class _OwnedVisualFrame {
  const _OwnedVisualFrame(this.ownerKind, this.ownerId, this.path, this.frame);

  final String ownerKind;
  final String ownerId;
  final String path;
  final TilesetVisualFrame frame;
}
