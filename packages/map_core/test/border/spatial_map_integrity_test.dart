import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/spatial_border_ground_surface_fixture.dart';

void main() {
  test('enclosed unpainted cells are exposed and the outer void is ignored', () {
    final fixture = _ground(unpainted: {for (var z = 0; z < 6; z++) (0, z), (3, 3)});
    final report = inspectSpatialMapIntegrity(manifest: fixture.project, map: fixture.map);
    expect(report.groundGaps.map((gap) => (gap.cell.x, gap.cell.y, gap.state)), [
      (3, 3, SpatialGroundGapState.exposed),
    ]);
  });

  test('an object hides a hole without proving its ground', () {
    final fixture = _ground(unpainted: {(3, 3)}, objects: [_instance('rock', 'unit', 3.5, 3.5)]);
    final gap = inspectSpatialMapIntegrity(manifest: fixture.project, map: fixture.map)
        .groundGaps
        .single;
    expect(gap.state, SpatialGroundGapState.unproven);
    expect(gap.coveringInstanceIds, ['rock']);
    expect(gap.toJson()['coveringInstanceIds'], ['rock']);
  });

  test('a Border ground replacement proves the ground it covers', () {
    final painted = _ground(unpainted: {});
    final withBorder = _materialized(painted, replacesGround: true);
    final modules = withBorder.map.spatialScene!.instances.map((instance) => (
          instance.position.x.floor(),
          instance.position.z.floor(),
        ));
    final under = modules.first;
    final hole = _repaint(withBorder, unpainted: {under});
    final report = inspectSpatialMapIntegrity(manifest: hole.project, map: hole.map);
    expect(report.groundGaps.where((gap) => (gap.cell.x, gap.cell.y) == under), isEmpty);

    final plain = _repaint(_materialized(painted, replacesGround: false), unpainted: {under});
    final unproven = inspectSpatialMapIntegrity(manifest: plain.project, map: plain.map)
        .groundGaps
        .singleWhere((gap) => (gap.cell.x, gap.cell.y) == under);
    expect(unproven.state, SpatialGroundGapState.exposed);
  });

  test('a change reports only the gaps it introduces or worsens', () {
    final before = inspectSpatialMapIntegrity(
      manifest: _ground(unpainted: {}).project,
      map: _ground(unpainted: {(2, 2)}, objects: [_instance('rock', 'unit', 2.5, 2.5)]).map,
    );
    final hidden = _ground(unpainted: {(2, 2), (3, 3)}, objects: [_instance('rock', 'unit', 2.5, 2.5)]);
    final introduced = inspectSpatialMapIntegrity(manifest: hidden.project, map: hidden.map)
        .introducedSince(before);
    expect(introduced.groundGaps.map((gap) => (gap.cell.x, gap.cell.y)), [(3, 3)]);

    final uncovered = _ground(unpainted: {(2, 2)});
    final worsened = inspectSpatialMapIntegrity(manifest: uncovered.project, map: uncovered.map)
        .introducedSince(before);
    expect(worsened.groundGaps.single.state, SpatialGroundGapState.exposed);
    expect(before.introducedSince(worsened).groundGaps, isEmpty);
  });

  test('objects crossing Border modules are grouped per feature; Environment models are not', () {
    final fixture = _materialized(_ground(unpainted: {}), replacesGround: false);
    final module = fixture.map.spatialScene!.instances.first;
    final crate = _instance('crate', 'crate', module.position.x, module.position.z);
    final tree = _instance('tree', 'tree', module.position.x, module.position.z);
    final scene = fixture.map.spatialScene!;
    final project = fixture.project.copyWith(
      models3d: [...fixture.project.models3d, _model('crate', 1), _model('tree', 1)],
      environmentPresets: [
        EnvironmentPreset(
          id: 'forest',
          name: 'Forest',
          templateId: 'forest_dense',
          palette: [EnvironmentPaletteItem(modelId: 'tree', weight: 1)],
          defaultParams: EnvironmentGenerationParams.standard(),
          sortOrder: 0,
        ),
      ],
    );
    final map = fixture.map.copyWith(
      spatialScene: scene.copyWith(instances: [...scene.instances, crate, tree]),
    );
    final overlaps = inspectSpatialMapIntegrity(manifest: project, map: map).borderObjectOverlaps;
    expect(overlaps.map((overlap) => (overlap.featureId, overlap.instanceId, overlap.modelId)), [
      ('fence', 'crate', 'crate'),
    ]);
    expect(overlaps.single.moduleCount, greaterThanOrEqualTo(1));
    expect(overlaps.single.toJson()['layerId'], 'border');
  });

  test('a map without a 3D scene has nothing to inspect', () {
    final fixture = _ground(unpainted: {(3, 3)});
    final flat = fixture.map.copyWith(spatialScene: null);
    final report = inspectSpatialMapIntegrity(manifest: fixture.project, map: flat);
    expect(report.groundGaps, isEmpty);
    expect(report.borderObjectOverlaps, isEmpty);
  });
}

typedef _Fixture = ({ProjectManifest project, MapData map});

_Fixture _ground({required Set<(int, int)> unpainted, List<SpatialModelInstance> objects = const []}) {
  final base = spatialBorderFixture();
  final scene = base.map.spatialScene!;
  return _repaint(
    (
      project: base.project,
      map: base.map.copyWith(spatialScene: scene.copyWith(instances: objects)),
    ),
    unpainted: unpainted,
  );
}

_Fixture _repaint(_Fixture fixture, {required Set<(int, int)> unpainted}) {
  final scene = fixture.map.spatialScene!;
  final ground = SmartTileLayer(
    id: 'ground',
    name: 'Ground',
    presetId: 'grass',
    usage: SmartTileUsage.terrain,
    materialPalette: const ['', 'grass'],
    field: SmartTileField.cell(semanticCells: [
      for (var z = 0; z < scene.depth; z++)
        for (var x = 0; x < scene.width; x++) unpainted.contains((x, z)) ? 0 : 1,
    ]),
  );
  return (
    project: fixture.project,
    map: fixture.map.copyWith(layers: [
      ...fixture.map.layers.where((layer) => layer.id != 'ground'),
      ground,
    ]),
  );
}

_Fixture _materialized(_Fixture fixture, {required bool replacesGround}) {
  final record = fixture.project.borderCatalog.records.single;
  final raw = encodeBorderBlueprintRecordJson(record, formatVersion: 5);
  for (final key in ['draft', 'latestPublished']) {
    ((raw[key] as Map)['definition'] as Map)['replacesGround'] = replacesGround;
  }
  final project = fixture.project.copyWith(
    models3d: [
      for (final model in fixture.project.models3d)
        if (model.id == 'unit') _model('unit', 1) else model,
    ],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: 13,
      records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 13)],
    ),
  );
  final resolved = resolveSpatialBorderFeature(
    manifest: project,
    map: fixture.map,
    layerId: 'border',
    featureId: 'fence',
  );
  expect(resolved.result.canApply, isTrue, reason: resolved.result.diagnostics.toString());
  return (
    project: project,
    map: applySpatialBorderFeaturePreview(fixture.map, manifest: project, proposedResult: resolved),
  );
}

ProjectModel3dEntry _model(String id, double size) => ProjectModel3dEntry(
      id: id,
      name: id,
      sourceAssetId: '$id-source',
      relativePath: 'assets/models3d/$id.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: -size, y: 0, z: -size),
          max: Model3dVector3(x: size, y: 1, z: size),
        ),
        meshCount: 1,
        triangleCount: 1,
      ),
    );

SpatialModelInstance _instance(String id, String modelId, double x, double z) =>
    SpatialModelInstance.fromJson({
      'id': id,
      'modelId': modelId,
      'position': {'x': x, 'y': 1.0, 'z': z},
      'rotationDegrees': 0,
      'scale': 1,
      'blocksMovement': false,
    });
