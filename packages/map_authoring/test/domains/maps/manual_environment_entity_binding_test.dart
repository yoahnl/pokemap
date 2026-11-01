import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'environment_spatial_actions_test.dart'
    show spatialEnvironmentFixture, generate, apply;
import 'map_catalog_fixture.dart';

void main() {
  test('canonical adoption keeps the exact bound instance and entity', () {
    final fixture = spatialEnvironmentFixture();
    final instance = SpatialModelInstance(
        id: 'manual',
        modelId: 'tree',
        position: Model3dVector3(x: 1.5, y: 0, z: 1.5),
        entityId: 'object');
    final entity = MapEntity(
        id: 'object',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 1, y: 1));
    final source = fixture.map.copyWith(entities: [
      entity
    ], spatialScene: fixture.map.spatialScene!.copyWith(instances: [instance]));
    final draft = const EnvironmentActions().build(catalogContext(
        catalogSnapshot([source], project: fixture.project),
        'environment.generated_placement_adopt_batch', {
      'mapId': source.id,
      'layerId': 'env',
      'areaId': 'forest',
      'placementIds': ['manual'],
    }));
    final adopted = MapData.fromJson(Map<String, dynamic>.from(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map));
    expect(adopted.spatialScene!.instances.single, instance);
    expect(adopted.entities.single, entity);
  });

  test('native manual move reanchors a bound entity in the same mutation', () {
    final fixture = spatialEnvironmentFixture();
    final instance = SpatialModelInstance(
        id: 'manual',
        modelId: 'tree',
        position: Model3dVector3(x: 1.5, y: 0, z: 1.5),
        entityId: 'object');
    final source = fixture.map.copyWith(entities: [
      MapEntity(
          id: 'object',
          kind: MapEntityKind.custom,
          pos: const GridPos(x: 1, y: 1))
    ], spatialScene: fixture.map.spatialScene!.copyWith(instances: [instance]));
    final adopted = const EnvironmentEditing().adoptGeneratedPlacements(
        fixture.project, source,
        layerId: 'env', areaId: 'forest', placementIds: ['manual']);
    final moved = const EnvironmentEditing().moveGeneratedPlacement(adopted,
        layerId: 'env',
        areaId: 'forest',
        placementId: 'manual',
        pos: const GridPos(x: 3, y: 2));
    expect(moved.entities.single.pos, const GridPos(x: 3, y: 2));
    expect(moved.spatialScene!.instances.single.entityId, 'object');
    expect(moved.spatialScene!.instances.single.blocksMovement,
        instance.blocksMovement);
    expect(MapData.fromJson(moved.toJson()), moved);
    final regenerated =
        apply(fixture.project, moved, generate(fixture.project, moved));
    expect(
        regenerated.spatialScene!.instances
            .singleWhere((v) => v.id == 'manual'),
        same(moved.spatialScene!.instances.single));
    expect(regenerated.entities, moved.entities);
  });
}
