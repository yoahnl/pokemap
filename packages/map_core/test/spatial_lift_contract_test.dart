import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> scene() => {
    ...MapSpatialScene(width: 8, depth: 8).toJson(),
    'schemaVersion': 3,
    'lifts': [
      {
        'id': 'lift',
        'name': 'Ascenseur',
        'instanceId': 'platform',
        'x': 2,
        'z': 2,
        'width': 3,
        'depth': 3,
        'lowerHeight': 2.0,
        'upperHeight': 5.0,
        'durationMs': 1000,
      },
    ],
    'instances': [
      SpatialModelInstance(
        id: 'platform',
        modelId: 'platform-model',
        position: Model3dVector3(x: 3.5, y: 0, z: 3.5),
      ).toJson(),
    ],
  };
  test(
    'native lift keeps identity, footprint and endpoints through serialization',
    () {
      final parsed = MapSpatialScene.fromJson(scene());
      expect(parsed.toJson()['schemaVersion'], 3);
      expect(parsed.toJson()['lifts'], scene()['lifts']);
      expect(
        parsed.copyWith(camera: SpatialCameraProfile()).toJson()['lifts'],
        scene()['lifts'],
      );
      expect(MapSpatialScene.fromJson(parsed.toJson()), parsed);
    },
  );
  test(
    'runtime vertical offset is finite, persistent and optional for old saves',
    () {
      final json = {
        'modelId': 'platform-model',
        'animationIndex': null,
        'normalizedTime': 0,
        'blocksMovement': false,
      };
      final parsed = SpatialModelRuntimeState.fromJson({
        ...json,
        'translationY': 3,
      });
      expect(parsed.toJson()['translationY'], 3);
      expect(SpatialModelRuntimeState.fromJson(parsed.toJson()), parsed);
      expect(
        SpatialModelRuntimeState.fromJson(
          json,
        ).toJson().containsKey('translationY'),
        isFalse,
      );
      expect(
        () => SpatialModelRuntimeState.fromJson({
          ...json,
          'translationY': double.nan,
        }),
        throwsFormatException,
      );
    },
  );
}
