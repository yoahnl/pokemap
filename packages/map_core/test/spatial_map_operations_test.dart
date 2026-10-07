import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const ops = SpatialMapOperations();
  MapData map() => MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v9,
    size: const GridSize(width: 3, height: 4),
    spatialScene: MapSpatialScene(width: 3, depth: 4),
  );
  test('terrain changes are immutable and bound checked before publishing', () {
    final before = map();
    final after = ops.setLevels(before, [
      const SpatialCellLevel(x: 2, z: 3, level: 32),
    ]);
    expect(after.spatialScene!.heightAt(2, 3), 32);
    expect(before.spatialScene!.heightAt(2, 3), 0);
    for (final cell in [
      const SpatialCellLevel(x: 3, z: 0, level: 1),
      const SpatialCellLevel(x: -1, z: 1, level: 1),
      const SpatialCellLevel(x: 0, z: 4, level: 1),
      const SpatialCellLevel(x: 0, z: 0, level: -1),
      const SpatialCellLevel(x: 0, z: 0, level: 33),
    ]) {
      expect(
        () => ops.setLevels(before, [
          const SpatialCellLevel(x: 0, z: 0, level: 1),
          cell,
        ]),
        throwsFormatException,
      );
      expect(before.spatialScene!.heightAt(0, 0), 0);
    }
    expect(
      () => ops.setLevels(
        before.copyWith(version: ProjectVersion.v8, spatialScene: null),
        [],
      ),
      throwsFormatException,
    );
  });

  test(
    'terrain changes preserve model offset above the supporting surface',
    () {
      final before = ops.upsertInstance(
        map(),
        SpatialModelInstance(
          id: 'tree',
          modelId: 'oak',
          position: Model3dVector3(x: 1.5, y: .75, z: 1.5),
        ),
      );
      final after = ops.setLevels(before, [
        const SpatialCellLevel(x: 1, z: 1, level: 3),
      ]);
      expect(after.spatialScene!.instances.single.position.y, 3.75);
      expect(before.spatialScene!.instances.single.position.y, .75);
      final lowered = ops.setLevels(after, [
        const SpatialCellLevel(x: 1, z: 1, level: 1),
      ]);
      expect(lowered.spatialScene!.instances.single.position.y, 1.75);
    },
  );

  test('navigation changes preserve model offset on a ramp', () {
    final base = ops.setLevels(map(), [
      const SpatialCellLevel(x: 1, z: 0, level: 2),
    ]);
    final before = ops.upsertInstance(
      base,
      SpatialModelInstance(
        id: 'tree',
        modelId: 'oak',
        position: Model3dVector3(x: 1.5, y: .5, z: 1.5),
      ),
    );
    final after = ops.configureNavigation(
      before,
      SpatialNavigationProfile(
        ramps: [
          SpatialRamp(
            id: 'ramp',
            x: 1,
            z: 1,
            width: 1,
            depth: 2,
            lowLevel: 0,
            highLevel: 2,
            direction: SpatialRampDirection.north,
          ),
        ],
      ),
    );
    expect(after.spatialScene!.instances.single.position.y, 2);
    expect(
      ops
          .configureNavigation(after, SpatialNavigationProfile())
          .spatialScene!
          .instances
          .single
          .position
          .y,
      .5,
    );
  });
  test(
    'instances upsert by stable id, preserve order and delete explicitly',
    () {
      final tree = SpatialModelInstance(
        id: 'tree',
        modelId: 'oak',
        position: Model3dVector3(x: 1, y: 0, z: 1),
      );
      final before = ops.upsertInstance(map(), tree);
      final after = ops.upsertInstance(before, tree.copyWith(scale: 2));
      expect(after.spatialScene!.instances.single.scale, 2);
      expect(before.spatialScene!.instances.single.scale, 1);
      expect(
        ops.deleteInstance(after, 'tree').spatialScene!.instances,
        isEmpty,
      );
      expect(() => ops.deleteInstance(after, 'missing'), throwsFormatException);
      expect(
        () => ops.upsertInstance(
          before,
          tree.copyWith(position: Model3dVector3(x: 3, y: 0, z: 1)),
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'reopened spatial data has consistent value equality and hash codes',
    () {
      final edited = ops.configureCamera(
        map(),
        SpatialCameraProfile(distance: 60),
      );
      final reopened = MapData.fromJson(edited.toJson());
      expect(edited, reopened);
      expect(edited.hashCode, reopened.hashCode);
      expect(edited.spatialScene!.camera, SpatialCameraProfile(distance: 60));
    },
  );
}
