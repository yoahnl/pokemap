import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

SpatialSceneView view(
  MapSpatialScene scene, {
  required SpatialSceneController controller,
  ProjectManifest? project,
  String? mapId = 'map-a',
  Offset offset = Offset.zero,
}) => SpatialSceneView(
  scene: scene,
  models: const [],
  loadModel: (_) async => Uint8List(0),
  controller: controller,
  groundProject: project,
  groundMap: mapId == null
      ? null
      : MapData(
          id: mapId,
          name: mapId,
          size: GridSize(width: scene.width, height: scene.depth),
        ),
  sceneOffset: offset,
  onCell: (_, _) {},
  background: const Color(0xff000000),
  ground: const Color(0xff224422),
  edge: const Color(0xff111111),
  errorBuilder: (_, _) => const SizedBox(),
);

void main() {
  test('a model-only preview keeps the displayed surface usable', () {
    final controller = SpatialSceneController();
    addTearDown(controller.dispose);
    final project = ProjectManifest(
      name: 'Surface project',
      maps: const [],
      tilesets: const [],
    );
    final scene = MapSpatialScene(width: 2, depth: 2);
    final before = view(scene, controller: controller, project: project);
    final after = view(
      scene.copyWith(
        instances: [
          SpatialModelInstance(
            id: 'preview',
            modelId: 'cliff',
            position: Model3dVector3.zero,
          ),
        ],
      ),
      controller: controller,
      project: project,
    );
    expect(after.scene, isNot(before.scene));
    expect(after.surfaceGeometryMatches(before), isTrue);
  });

  test('map, surface and camera changes invalidate displayed picking', () {
    final controller = SpatialSceneController();
    final otherController = SpatialSceneController();
    addTearDown(controller.dispose);
    addTearDown(otherController.dispose);
    final project = ProjectManifest(
      name: 'Surface project',
      maps: const [],
      tilesets: const [],
    );
    final scene = MapSpatialScene(width: 2, depth: 2);
    final before = view(scene, controller: controller, project: project);
    final changes = <String, SpatialSceneView>{
      'map': view(scene, controller: controller, project: project, mapId: 'b'),
      'project': view(
        scene,
        controller: controller,
        project: project.copyWith(name: 'Another project'),
      ),
      'offset': view(
        scene,
        controller: controller,
        project: project,
        offset: const Offset(1, 0),
      ),
      'controller': view(scene, controller: otherController, project: project),
      'width': view(
        MapSpatialScene(width: 3, depth: 2),
        controller: controller,
        project: project,
      ),
      'depth': view(
        MapSpatialScene(width: 2, depth: 3),
        controller: controller,
        project: project,
      ),
      'height': view(
        scene.copyWith(heightLevels: [0, 0, 1, 0]),
        controller: controller,
        project: project,
      ),
      'height unit': view(
        MapSpatialScene(width: 2, depth: 2, levelHeight: 2),
        controller: controller,
        project: project,
      ),
      'navigation': view(
        scene.copyWith(
          navigation: scene.navigation.copyWith(allowDiagonalMovement: true),
        ),
        controller: controller,
        project: project,
      ),
      'camera': view(
        scene.copyWith(camera: SpatialCameraProfile(pitchDegrees: 30)),
        controller: controller,
        project: project,
      ),
      'unknown map': view(
        scene,
        controller: controller,
        project: project,
        mapId: null,
      ),
      'unknown project': view(scene, controller: controller),
    };
    for (final entry in changes.entries) {
      expect(
        entry.value.surfaceGeometryMatches(before),
        isFalse,
        reason: entry.key,
      );
    }
    expect(
      view(
        scene,
        controller: controller,
      ).surfaceGeometryMatches(view(scene, controller: controller)),
      isFalse,
    );
  });
}
