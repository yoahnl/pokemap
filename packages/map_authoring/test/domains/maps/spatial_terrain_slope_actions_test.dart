import 'dart:convert';

import 'package:map_authoring/src/domains/maps/map3d_edit_batch_actions.dart';
import 'package:map_authoring/src/domains/maps/spatial_terrain_slope_actions.dart';
import 'package:map_authoring/src/domains/maps/spatial_terrain_surface_actions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart' show context;
import 'spatial_terrain_relief_fixture.dart';

ProjectManifest get stairProject => reliefProject.copyWith(models3d: [
      ...reliefProject.models3d,
      ProjectModel3dEntry(
        id: 'stone-stair',
        name: 'Escalier de pierre — largeur 3 cases — montée 1 niveau',
        sourceAssetId: 'stone-stair-source',
        relativePath: 'assets/models3d/stone-stair.glb',
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3(x: -1.69, y: 0, z: -.5),
            max: Model3dVector3(x: 1.69, y: 1.19, z: .5),
          ),
          meshCount: 1,
          triangleCount: 2,
        ),
      ),
    ]);

({MapData map, Map<String, Object?> preview}) slopeAction(
    MapData map, String action, Map<String, Object?> parameters) {
  final draft = const SpatialTerrainSlopeActions().build(context(
      librarySnapshot([map], project: stairProject),
      action,
      {'mapId': map.id, ...parameters}));
  return (
    map: MapData.fromJson(Map<String, dynamic>.from(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map)),
    preview: draft.preview,
  );
}

Map<String, int> cell(int x, int y) => {'x': x, 'y': y};

void main() {
  final plateau = paintRelief(reliefBaseMap(), rect(6, 4, 10, 6),
          level: 2, project: stairProject)
      .map;

  test('a slope cuts the plateau cliff and climbs to its top', () {
    final result = slopeAction(plateau, SpatialTerrainSlopeActions.paintSlope,
        {'from': cell(9, 13), 'to': cell(10, 8)});
    expect(result.preview['direction'], 'north');
    expect(
        result.preview['region'], {'x': 9, 'y': 10, 'width': 2, 'height': 4});
    expect((result.preview['lowerHeight'], result.preview['upperHeight']),
        (1.0, 2.0));
    final trace = (result.preview['traces'] as List).single as Map;
    expect(trace['featureId'], 'relief-1');
    expect(trace['change'], 'updated');
    final stroke = reliefStrokes(result.map, 'relief-1').single;
    expect(stroke.closed, isFalse);
    expect({stroke.points.first, stroke.points.last},
        {const GridPos(x: 9, y: 10), const GridPos(x: 11, y: 10)});
    expect(reliefDiagnostics(stairProject, result.map, 'relief-1'), isEmpty);
    final scene = result.map.spatialScene!;
    final surface = scene.terrainSurfaces.surfaces
        .singleWhere((s) => s.id == result.preview['surfaceId']);
    expect(surface.closedFlanks, isTrue);
    expect(scene.worldHeightAt(9.5, 10.001), closeTo(2, 1e-3));
    expect(scene.worldHeightAt(9.5, 13.999), closeTo(1, 1e-3));
  });

  test('a stair snaps on the clicked edge with its model and cut', () {
    final result = slopeAction(plateau, SpatialTerrainSlopeActions.placeStair,
        {'cell': cell(10, 9), 'modelId': 'stone-stair'});
    expect(
        result.preview['region'], {'x': 9, 'y': 10, 'width': 3, 'height': 1});
    expect(result.preview['instanceId'], 'stair-1');
    final instance = result.map.spatialScene!.instances
        .singleWhere((i) => i.id == 'stair-1');
    expect(instance.modelId, 'stone-stair');
    expect(instance.blocksMovement, isFalse);
    expect(instance.position.x, closeTo(10.5, 1e-9));
    expect(instance.position.z, closeTo(10.5, 1e-9));
    final stroke = reliefStrokes(result.map, 'relief-1').single;
    expect({stroke.points.first, stroke.points.last},
        {const GridPos(x: 9, y: 10), const GridPos(x: 12, y: 10)});
  });

  test('refusals keep their engine codes', () {
    expect(
        () => slopeAction(plateau, SpatialTerrainSlopeActions.paintSlope,
            {'from': cell(9, 13), 'to': cell(11, 11)}),
        throwsRelief('spatial.slope.direction_ambiguous'));
    expect(
        () => slopeAction(plateau, SpatialTerrainSlopeActions.placeStair,
            {'cell': cell(6, 4), 'modelId': 'stone-stair'}),
        throwsRelief('spatial.stair.edge_ambiguous'));
    expect(
        () => slopeAction(plateau, SpatialTerrainSlopeActions.placeStair,
            {'cell': cell(10, 9), 'modelId': 'missing-model'}),
        throwsRelief('spatial.stair.model_unavailable'));
  });

  test('both actions compose inside one atomic map edit', () {
    final draft = const Map3dEditBatchActions().build(context(
        librarySnapshot([plateau], project: stairProject), 'map3d.edit_batch', {
      'mapId': 'map',
      'operations': [
        {
          'actionId': SpatialTerrainSlopeActions.paintSlope,
          'actionVersion': 1,
          'parameters': {'from': cell(7, 13), 'to': cell(7, 9)},
        },
        {
          'actionId': SpatialTerrainSlopeActions.placeStair,
          'actionVersion': 1,
          'parameters': {'cell': cell(13, 9), 'modelId': 'stone-stair'},
        },
      ],
    }));
    final map = MapData.fromJson(Map<String, dynamic>.from(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map));
    expect(reliefStrokes(map, 'relief-1'), hasLength(2));
    expect(map.spatialScene!.instances.where((i) => i.id == 'stair-1'),
        hasLength(1));
    expect(draft.preview['status'], 'changed');
  });

  test('closed flanks are part of the surface contract', () {
    final surface = SpatialTerrainSurface(
      id: 'side-slope',
      x: 18,
      z: 12,
      height: 2,
      gradientZ: -.5,
      closedFlanks: true,
      footprints: [
        BorderGroundFootprint(points: [
          BorderGroundPoint(x: 0, z: 0),
          BorderGroundPoint(x: 1, z: 0),
          BorderGroundPoint(x: 1, z: 2),
          BorderGroundPoint(x: 0, z: 2),
        ]),
      ],
    );
    final draft = const SpatialTerrainSurfaceActions().build(context(
        librarySnapshot([plateau], project: stairProject),
        SpatialTerrainSurfaceActions.upsert, {
      'mapId': plateau.id,
      'surfaces': [surface.toJson()],
    }));
    final map = MapData.fromJson(Map<String, dynamic>.from(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map));
    expect(
        map.spatialScene!.terrainSurfaces.surfaces
            .singleWhere((s) => s.id == 'side-slope')
            .closedFlanks,
        isTrue);
    final schema = (SpatialTerrainSurfaceActions.descriptors
        .singleWhere((d) => d.id == SpatialTerrainSurfaceActions.upsert)
        .extensions['inputSchema'] as Map)['properties'] as Map;
    expect(jsonEncode(schema), contains('closedFlanks'));
  });
}
