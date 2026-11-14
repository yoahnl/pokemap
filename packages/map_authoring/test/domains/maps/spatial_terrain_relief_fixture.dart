import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/maps/spatial_terrain_relief_actions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../support/reliability_map_fixture.dart';
import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart' show context;

final _fixture =
    ReliabilityMapContent.create(ReliabilityMapVariant.missingCliff);

ProjectManifest get reliefProject => _fixture.project;

MapData reliefBaseMap() => const SpatialMapOperations().upsertTerrainSurfaces(
      _fixture.map,
      [
        SpatialTerrainSurface(
          id: 'base',
          x: 0,
          z: 0,
          height: 1,
          footprints: [
            BorderGroundFootprint(points: [
              BorderGroundPoint(x: 0, z: 0),
              BorderGroundPoint(x: 24, z: 0),
              BorderGroundPoint(x: 24, z: 16),
              BorderGroundPoint(x: 0, z: 16),
            ]),
          ],
        ),
      ],
    );

List<GridPos> rect(int x, int y, int width, int height) => [
      for (var row = y; row < y + height; row++)
        for (var column = x; column < x + width; column++)
          GridPos(x: column, y: row),
    ];

({MapData map, Map<String, Object?> preview}) paintRelief(
  MapData map,
  List<GridPos> cells, {
  required int level,
  ProjectManifest? project,
  String blueprint = 'fence',
  String? twoLevel,
}) {
  final draft = const SpatialTerrainReliefActions().build(context(
      librarySnapshot([map], project: project ?? reliefProject),
      SpatialTerrainReliefActions.paintHeight, {
    'mapId': map.id,
    'level': level,
    'blueprintId': blueprint,
    if (twoLevel != null) 'twoLevelBlueprintId': twoLevel,
    'cells': [for (final cell in cells) cell.toJson()],
  }));
  return (
    map: MapData.fromJson(Map<String, dynamic>.from(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map)),
    preview: draft.preview,
  );
}

List<String> reliefFeatureIds(MapData map) => [
      for (final layer in map.layers.whereType<BorderLayer>())
        for (final feature in layer.content.features) feature.id,
    ];

List<BorderStroke> reliefStrokes(MapData map, Object? featureId) => ((map.layers
            .whereType<BorderLayer>()
            .expand((layer) => layer.content.features)
            .singleWhere((feature) => feature.id == featureId)).geometry
        as BorderStrokeGeometry)
    .strokes;

List<String> reliefDiagnostics(
        ProjectManifest project, MapData map, Object? featureId) =>
    [
      for (final diagnostic in diagnoseSpatialBorderFeature(
              manifest: project,
              map: map,
              layerId: 'border',
              featureId: featureId as String)
          .diagnostics)
        diagnostic.code
    ];

Matcher throwsRelief(String code) =>
    throwsA(isA<MapAuthoringException>().having((e) => e.code, 'code', code));

ProjectManifest withTwoLevelProfile(ProjectManifest project) {
  final raw = encodeBorderBlueprintRecordJson(
      project.borderCatalog.records.single,
      formatVersion: 5);
  raw['id'] = 'fence-2';
  _primitives(raw, (primitive) => primitive['sourceModelId'] = 'cliff-2');
  final cliff = project.models3d.singleWhere((model) => model.id == 'cliff');
  return project.copyWith(
    models3d: [
      ...project.models3d,
      ProjectModel3dEntry(
        id: 'cliff-2',
        name: 'Two level cliff face',
        sourceAssetId: 'cliff-2-source',
        relativePath: 'assets/models3d/cliff-2.glb',
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3(x: -.2, y: -2, z: -.2),
            max: Model3dVector3(x: .2, y: 0, z: .2),
          ),
          meshCount: cliff.inspection.meshCount,
          triangleCount: cliff.inspection.triangleCount,
        ),
      ),
    ],
    borderCatalog: ProjectBorderCatalog(formatVersion: 5, records: [
      ...project.borderCatalog.records,
      decodeBorderBlueprintRecordJson(raw, formatVersion: 5),
    ]),
  );
}

ProjectManifest leftHanded(ProjectManifest project) => project.copyWith(
      models3d: [
        for (final model in project.models3d)
          model.id == 'cliff'
              ? ProjectModel3dEntry(
                  id: model.id,
                  name: model.name,
                  sourceAssetId: model.sourceAssetId,
                  relativePath: model.relativePath,
                  inspection: Model3dInspection(
                    bounds: Model3dBounds(
                      min: Model3dVector3(x: -.5, y: -1, z: 0),
                      max: Model3dVector3(x: .5, y: 0, z: 1),
                    ),
                    meshCount: model.inspection.meshCount,
                    triangleCount: model.inspection.triangleCount,
                  ),
                )
              : model
      ],
    );

ProjectManifest innerCornerJoins(ProjectManifest project, int cells) {
  final raw = encodeBorderBlueprintRecordJson(
      project.borderCatalog.records.single,
      formatVersion: 13);
  _primitives(raw, (primitive) {
    if (primitive['id'] == 'corner-left') primitive['cornerJoinCells'] = cells;
  });
  return project.copyWith(
      borderCatalog: ProjectBorderCatalog(
          formatVersion: 13,
          records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 13)]));
}

void _primitives(Map<String, Object?> raw, void Function(Map) visit) {
  for (final key in ['draft', 'latestPublished']) {
    final definition = (raw[key] as Map)['definition'] as Map;
    (definition['primitives'] as List).cast<Map>().forEach(visit);
  }
}
