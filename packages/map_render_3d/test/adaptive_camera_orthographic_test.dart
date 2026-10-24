import 'package:flame_3d/core.dart';
import 'package:flame_3d/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/adaptive_camera.dart';
import 'package:map_render_3d/src/spatial_camera_magnification.dart';
import 'package:map_core/src/models/map_spatial_scene.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'orthographic depth occupies the Flutter GPU zero to one clip range',
    () {
      final camera = AdaptiveCamera3D(fovY: 12)
        ..projection = CameraProjection.orthographic;
      camera.frame(Vector3.zero(), pitch: .7, yaw: 0, distance: 97.72);
      final projection = camera.projectionMatrix;
      for (final depth in [97.72 * .02, 20.0, 97.72, 500.0, 1000.0]) {
        final clip = projection.transform(Vector4(0, 0, -depth, 1));
        expect(clip.z / clip.w, inInclusiveRange(-1e-7, 1 + 1e-7));
      }
      final near = projection.transform(Vector4(0, 0, -97.72 * .02, 1));
      final far = projection.transform(Vector4(0, 0, -1000, 1));
      expect(near.z / near.w, closeTo(0, 1e-7));
      expect(far.z / far.w, closeTo(1, 1e-7));
    },
  );

  test('orthographic camera retains parallel projection at every depth', () {
    final camera = AdaptiveCamera3D(fovY: 12)
      ..projection = CameraProjection.orthographic;
    camera.frame(Vector3.zero(), pitch: .7, yaw: 0, distance: 42);
    final projection = camera.projectionMatrix.clone();
    expect(projection.entry(3, 3), 1);
    expect(projection.entry(3, 2), 0);
    expect(projection.entry(1, 1), closeTo(2 / 12, 1e-7));
    camera.frame(Vector3.zero(), pitch: .7, yaw: 0, distance: 84);
    expect(camera.projectionMatrix.entry(1, 1), projection.entry(1, 1));
  });

  test(
    'orthographic zoom and door magnification change the vertical field',
    () {
      final camera = AdaptiveCamera3D();
      final profile = SpatialCameraProfile(
        projection: SpatialCameraProjection.orthographic,
        orthographicHeight: 12,
      );
      camera.frame(Vector3(2, 1, 3), pitch: .6, yaw: .2, distance: 42);
      final position = camera.position.clone();
      final target = camera.target.clone();
      applySpatialCameraProfile(
        camera,
        profile: profile,
        zoom: .75,
        magnification: 1.25,
      );
      expect(camera.projection, CameraProjection.orthographic);
      expect(camera.fovY, closeTo(7.2, 1e-9));
      expect(camera.position, position);
      expect(camera.target, target);
      applySpatialCameraProfile(camera, profile: profile, magnification: 1);
      expect(camera.fovY, 12);
      expect(camera.projectionMatrix.entry(1, 1), closeTo(1 / 6, 1e-7));
    },
  );

  test(
    'orthographic portrait framing and projection switches stay independent',
    () {
      final camera = AdaptiveCamera3D();
      applySpatialCameraProfile(
        camera,
        profile: SpatialCameraProfile(
          projection: SpatialCameraProjection.orthographic,
          orthographicHeight: 12,
        ),
        magnification: 1,
        viewportAspectRatio: .5,
      );
      expect(camera.fovY, 24);
      camera.frame(
        Vector3.zero(),
        pitch: .6,
        yaw: 0,
        distance: 42,
        viewportAspectRatio: .5,
      );
      expect((camera.position - camera.target).length, closeTo(42, 1e-6));
      applySpatialCameraProfile(
        camera,
        profile: SpatialCameraProfile(fieldOfViewDegrees: 35),
        magnification: 1,
        viewportAspectRatio: .5,
      );
      expect(camera.projection, CameraProjection.perspective);
      expect(camera.fovY, closeTo(35, 1e-9));
      expect(camera.projectionMatrix.entry(3, 3), 0);
    },
  );

  test('invalid orthographic zoom cannot mutate the active camera', () {
    final camera = AdaptiveCamera3D(fovY: 35);
    final profile = SpatialCameraProfile(
      projection: SpatialCameraProjection.orthographic,
    );
    for (final invalid in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        () => applySpatialCameraProfile(
          camera,
          profile: profile,
          magnification: invalid,
        ),
        throwsArgumentError,
      );
      expect(
        () => applySpatialCameraProfile(
          camera,
          profile: profile,
          magnification: 1,
          zoom: invalid,
        ),
        throwsArgumentError,
      );
      expect(
        () => applySpatialCameraProfile(
          camera,
          profile: profile,
          magnification: 1,
          viewportAspectRatio: invalid,
        ),
        throwsArgumentError,
      );
      expect(camera.projection, CameraProjection.perspective);
      expect(camera.fovY, 35);
    }
    expect(
      () => applySpatialCameraProfile(
        camera,
        profile: profile,
        magnification: 1e-300,
        zoom: 1e300,
      ),
      throwsArgumentError,
    );
    expect(camera.projection, CameraProjection.perspective);
    expect(camera.fovY, 35);
  });
}
