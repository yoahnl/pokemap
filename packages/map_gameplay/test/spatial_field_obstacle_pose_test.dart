import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/spatial_field_obstacle_pose.dart';
import 'package:test/test.dart';

void main() {
  test('the boulder pose is derived from its sole saved position and retains its authored anchor', () {
    const entity = MapEntity(id: 'rock', kind: MapEntityKind.custom, pos: GridPos(x: 2, y: 3),
        fieldObstacle: MapEntityFieldObstacleData(kind: FieldObstacleKind.strengthBoulder));
    final instance = SpatialModelInstance(id: 'rock-instance', modelId: 'rock', entityId: entity.id,
        position: Model3dVector3(x: 2.2, y: 1, z: 3.7));
    final world = MapInstanceWorldState(instancesByMapId: {'field': MapInstanceRuntimeState(instanceId: 'one')});
    final moved = world.moveFieldObstacle(world.instanceRef('field')!, entity.id, const GridPos(x: 4, y: 2));
    final before = moved.toJson();
    final base = SpatialModelRuntimeState(modelId: 'rock', animationIndex: null, normalizedTime: 0,
        blocksMovement: true, translationY: .2);
    final pose = spatialFieldObstacleModelPose(mapId: 'field', entity: entity,
        instance: instance, world: moved, baseState: base)!;
    expect(pose.translationX, 2);
    expect(pose.translationZ, -1);
    expect(pose.translationY, .2);
    expect(moved.toJson(), before);
    expect(base.translationX, 0);
    expect(instance.position.x, 2.2);
    expect(spatialFieldObstacleModelPose(mapId: 'other', entity: entity,
        instance: instance, world: moved, baseState: base), same(base));
  });
}
