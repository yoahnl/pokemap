import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('a translated model frees its old footprint and blocks its live footprint', () {
    final model = ProjectModel3dEntry(id: 'rock', name: 'Rock', sourceAssetId: 'rock-source',
        relativePath: 'assets/models3d/rock.glb', inspection: Model3dInspection(
          bounds: Model3dBounds(min: Model3dVector3(x: -.35, y: 0, z: -.35),
            max: Model3dVector3(x: .35, y: 1, z: .35)), meshCount: 1, triangleCount: 1));
    final map = MapData(id: 'field', name: 'Field', version: ProjectVersion.v9,
        size: const GridSize(width: 8, height: 8), spatialScene: MapSpatialScene(width: 8, depth: 8,
          instances: [SpatialModelInstance(id: 'rock', modelId: 'rock', position: Model3dVector3(x: 2.5, y: 0, z: 1.5))]));
    final controller = SpatialMovementController.fromMap(map: map, models: [model],
        spatialArrival: PlayerSpatialPosition(x: 1.5, z: 1.5),
        modelStateProvider: (_) => SpatialModelRuntimeState(modelId: 'rock', animationIndex: null,
            normalizedTime: 0, blocksMovement: true, translationX: 1));
    expect(controller.canTraverseActor(1.5, 1.5, 2.5, 1.5), isTrue);
    expect(controller.canTraverseActor(2.5, 1.5, 3.5, 1.5), isFalse);
  });
}
