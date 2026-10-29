import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_face_ground_warning_actions_test.dart'
    show directedCliffAuthoringFixture;
import 'border_spatial_actions_test.dart' show context;

void main() {
  test('support edits rematerialize dependent Borders in the same change',
      () async {
    final source = directedCliffAuthoringFixture(levels: List.filled(24, 0));
    final scene = source.map.spatialScene!;
    final ground = _surface('ground', height: 1);
    var map = source.map.copyWith(
        spatialScene: scene.copyWith(
            terrainSurfaces: SpatialTerrainSurfaceSet(surfaces: [ground])));
    map = applySpatialBorderFeaturePreview(map,
        manifest: source.project,
        proposedResult: resolveSpatialBorderFeature(
            manifest: source.project,
            map: map,
            layerId: 'border',
            featureId: 'fence'));
    final draft = await MapMutationDispatcher.canonical().build(context(
        librarySnapshot([map], project: source.project),
        'map3d.terrain.surface.upsert_batch', {
      'mapId': 'map',
      'surfaces': [_surface('ground', height: 2).toJson()],
    }));
    expect(draft.preview['refreshedBorderFeatures'], ['border/fence']);
    expect(draft.preview['staleBorderFeatures'], isEmpty);
    final after = MapData.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));
    final feature =
        after.layers.whereType<BorderLayer>().single.content.features.single;
    final ids = feature.generatedPlacementIds.toSet();
    expect(
        after.spatialScene!.instances
            .where((instance) => ids.contains(instance.id))
            .map((instance) => instance.position.y),
        everyElement(2.0));
    expect(
        diagnoseSpatialBorderFeature(
                manifest: source.project,
                map: after,
                layerId: 'border',
                featureId: 'fence')
            .diagnostics
            .map((diagnostic) => diagnostic.code),
        isNot(contains('border.spatial.materialization_stale')));
  });
}

SpatialTerrainSurface _surface(String id, {required double height}) =>
    SpatialTerrainSurface.fromJson({
      'id': id,
      'x': 0.0,
      'z': 0.0,
      'height': height,
      'gradientX': 0.0,
      'gradientZ': 0.0,
      'footprints': [
        [
          {'x': 0.0, 'z': 0.0},
          {'x': 6.0, 'z': 0.0},
          {'x': 6.0, 'z': 4.0},
          {'x': 0.0, 'z': 4.0},
        ],
      ],
    });
