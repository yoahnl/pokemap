import 'dart:math' as math;

import 'package:map_core/map_core_domain.dart';

enum BorderWorkshopIssue {
  empty,
  missingRoles,
  missingSources,
  unsupportedConfiguration,
  mapScope,
  spriteDraft,
  noSample,
}

typedef BorderWorkshopPiece = ({
  BorderPrimitiveRole role,
  String name,
  int? placements,
});

typedef BorderWorkshopAssembly = ({
  ProjectManifest project,
  MapData? map,
  List<BorderWorkshopPiece> pieces,
  BorderWorkshopIssue? issue,
});

BorderWorkshopAssembly buildBorderWorkshopAssembly(
  ProjectManifest project,
  BorderBlueprintRecord record, {
  required bool draft,
}) {
  final definition = record.draft.definition;
  final published = record.latestPublished;
  if (!draft && published != null) {
    return published.definition.isSpatial
        ? _spatialAssembly(project, record.id, published)
        : _spriteAssembly(project, record.id, published);
  }
  final active = definition.primitives.where((piece) => piece.weight > 0);
  if (active.isEmpty) return _unavailable(project, BorderWorkshopIssue.empty);
  if (!definition.isSpatial) {
    return _unavailable(
      project,
      BorderWorkshopIssue.spriteDraft,
      pieces: _pieces(
        project,
        primitives: active.map(
          (piece) => (
            role: piece.role,
            source: piece.sourceElementId!,
            placements: null,
          ),
        ),
        spatial: false,
      ),
    );
  }
  final candidate = BorderBlueprintRevision(
    revision: (published?.revision ?? 0) + 1,
    definition: spatialBorderPublicationDefinition(definition),
  );
  final previewProject = project.copyWith(
    borderCatalog: ProjectBorderCatalog(
      formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
      records: [
        BorderBlueprintRecord(
          id: record.id,
          draft: record.draft,
          latestPublished: candidate,
          isDeprecated: record.isDeprecated,
        ),
      ],
    ),
  );
  return _spatialAssembly(previewProject, record.id, candidate);
}

const _previewMapId = 'border-workshop-preview';
const _layerId = 'preview-border';

BorderWorkshopAssembly _spatialAssembly(
  ProjectManifest project,
  String blueprintId,
  BorderBlueprintRevision revision,
) {
  final definition = revision.definition;
  final models = {
    for (final piece in definition.primitives) piece.sourceModelId!,
  };
  final library = project.resourceLibraryCatalog;
  final scopes = {
    for (final model in models) ?library.entryFor('model3d', model)?.mapId,
  };
  final mapId =
      library.entryFor('borderBlueprint', blueprintId)?.mapId ??
      (scopes.length == 1 ? scopes.single : _previewMapId);
  final joinCells = definition.primitives.fold(
    0,
    (largest, piece) => math.max(largest, piece.cornerJoinCells),
  );
  final arm = math.max(4, joinCells + 2);
  final corner = !definition.straightOnly;
  final width = corner ? arm + 6 : 12;
  final depth = corner ? arm + 6 : 7;
  final geometry = BorderStrokeGeometry(
    alignment: definition.followContourDirection
        ? BorderStrokeAlignment.gridEdges
        : BorderStrokeAlignment.cellCenters,
    strokes: [
      BorderStroke(
        id: 'preview-line',
        closed: false,
        points: [
          for (var x = 2; x <= (corner ? arm + 2 : 9); x++) GridPos(x: x, y: 2),
          if (corner)
            for (var y = 3; y <= arm + 2; y++) GridPos(x: arm + 2, y: y),
        ],
      ),
    ],
  );
  final feature = _feature(blueprintId, revision, 'preview-line', geometry);
  final map = MapData(
    id: mapId,
    name: 'Aperçu de la bordure',
    version: ProjectVersion.v9,
    size: GridSize(width: width, height: depth),
    layers: [_layer(feature)],
    spatialScene: MapSpatialScene(
      width: width,
      depth: depth,
      heightLevels: definition.followContourDirection
          ? [
              for (var y = 0; y < depth; y++)
                for (var x = 0; x < width; x++)
                  y >= 2 && (!corner || x < arm + 2) ? 1 : 0,
            ]
          : null,
    ),
  );
  final result = resolveSpatialBorderFeature(
    manifest: project,
    map: map,
    layerId: _layerId,
    featureId: feature.id,
  );
  final placements = result.result.materialization?.spatialPlacements;
  if (!result.result.canApply || placements == null || placements.isEmpty) {
    return _unavailable(project, _issue(result.result.diagnostics));
  }
  return (
    project: project,
    map: applySpatialBorderFeaturePreview(
      map,
      manifest: project,
      proposedResult: result,
    ),
    pieces: _resolvedPieces(
      project,
      definition,
      placements.map((placement) => placement.primitiveId),
    ),
    issue: null,
  );
}

BorderWorkshopAssembly _spriteAssembly(
  ProjectManifest project,
  String blueprintId,
  BorderBlueprintRevision revision,
) {
  final gallery = resolveBorderCanonicalGallery(
    blueprintId: blueprintId,
    blueprintRevision: revision,
    visualSnapshots: project.borderCatalog.visualSnapshots,
    tileSizePx: GridSize(
      width: project.settings.tileWidth,
      height: project.settings.tileHeight,
    ),
  );
  final sample = gallery.cases
      .where((entry) => entry.resolverResult.canApply)
      .firstOrNull;
  if (sample == null) {
    return _unavailable(
      project,
      _issue(gallery.resolutionDiagnostics.diagnostics),
    );
  }
  final materialization = sample.resolverResult.materialization!;
  final feature = _feature(
    blueprintId,
    revision,
    'border-gallery-v1:${borderCanonicalGalleryCaseV1WireName(sample.galleryCase)}',
    sample.geometry,
    materialization: materialization,
  );
  return (
    project: project,
    map: MapData(
      id: _previewMapId,
      name: 'Aperçu de la bordure',
      size: sample.mapSize,
      layers: [_layer(feature)],
    ),
    pieces: _resolvedPieces(
      project,
      revision.definition,
      materialization.placements.map((placement) => placement.primitiveId),
    ),
    issue: null,
  );
}

BorderFeature _feature(
  String blueprintId,
  BorderBlueprintRevision revision,
  String id,
  BorderFeatureGeometry geometry, {
  BorderMaterialization? materialization,
}) => BorderFeature(
  id: id,
  name: revision.definition.name,
  blueprintId: blueprintId,
  seed: revision.definition.previewSeed,
  geometry: geometry,
  overrides: const [],
  keepOutRegions: const [],
  materialization: materialization,
);

MapLayer _layer(BorderFeature feature) => MapLayer.border(
  id: _layerId,
  name: 'Bordure',
  content: BorderLayerContent(features: [feature]),
);

List<BorderWorkshopPiece> _resolvedPieces(
  ProjectManifest project,
  BorderBlueprintPublishedDefinition definition,
  Iterable<String> selected,
) {
  final definitions = {
    for (final primitive in definition.primitives) primitive.id: primitive,
  };
  return _pieces(
    project,
    spatial: definition.isSpatial,
    primitives: [
      for (final id in selected)
        if (definitions[id] case final piece?)
          (
            role: piece.role,
            source: (piece.sourceModelId ?? piece.sourceElementId)!,
            placements: 1,
          ),
    ],
  );
}

List<BorderWorkshopPiece> _pieces(
  ProjectManifest project, {
  required bool spatial,
  required Iterable<
    ({BorderPrimitiveRole role, String source, int? placements})
  >
  primitives,
}) {
  final totals = <(BorderPrimitiveRole, String), int?>{};
  for (final primitive in primitives) {
    final key = (primitive.role, primitive.source);
    totals[key] = primitive.placements == null
        ? null
        : (totals[key] ?? 0) + primitive.placements!;
  }
  final names = spatial
      ? {for (final model in project.models3d) model.id: model.name}
      : {for (final element in project.elements) element.id: element.name};
  return [
    for (final role in BorderPrimitiveRole.values)
      for (final entry in totals.entries)
        if (entry.key.$1 == role)
          (
            role: role,
            name: names[entry.key.$2] ?? 'Pièce introuvable',
            placements: entry.value,
          ),
  ];
}

BorderWorkshopIssue _issue(Iterable<BorderDiagnostic> diagnostics) {
  final codes = {for (final diagnostic in diagnostics) diagnostic.code};
  if (codes.contains('border.spatial.required_roles_missing')) {
    return BorderWorkshopIssue.missingRoles;
  }
  if (codes.contains('border.spatial.source_model_missing')) {
    return BorderWorkshopIssue.missingSources;
  }
  if (codes.contains('border.spatial.resource_scope_conflict')) {
    return BorderWorkshopIssue.mapScope;
  }
  if (codes.any((code) => code.startsWith('border.spatial.'))) {
    return BorderWorkshopIssue.unsupportedConfiguration;
  }
  return BorderWorkshopIssue.noSample;
}

BorderWorkshopAssembly _unavailable(
  ProjectManifest project,
  BorderWorkshopIssue issue, {
  List<BorderWorkshopPiece> pieces = const [],
}) => (project: project, map: null, pieces: pieces, issue: issue);
