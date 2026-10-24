import 'package:map_core/src/models/map_spatial_scene.dart';
import 'package:test/test.dart';

void main() {
  test('orthographic camera roundtrips its explicit vertical field', () {
    final json = {
      ...SpatialCameraProfile().toJson(),
      'projection': 'orthographic',
      'orthographicHeight': 12.5,
    };
    expect(SpatialCameraProfile.fromJson(json).toJson(), json);
  });

  test('camera rejects invalid projection and vertical field', () {
    expect(
      () => SpatialCameraProfile.fromJson(
        {...SpatialCameraProfile().toJson(), 'projection': 'orthographic'}
          ..remove('orthographicHeight'),
      ),
      throwsFormatException,
    );
    for (final projection in ['unknown', 4, null]) {
      expect(
        () => SpatialCameraProfile.fromJson({
          ...SpatialCameraProfile().toJson(),
          'projection': projection,
        }),
        throwsFormatException,
      );
    }
    for (final height in [0, -1, double.nan, double.infinity, 10001]) {
      expect(
        () => SpatialCameraProfile.fromJson({
          ...SpatialCameraProfile().toJson(),
          'projection': 'orthographic',
          'orthographicHeight': height,
        }),
        throwsFormatException,
      );
    }
  });

  test('perspective profiles retain their current optical values', () {
    final camera = SpatialCameraProfile.fromJson({
      'mode': 'fixed',
      'pitchDegrees': 55,
      'yawDegrees': 12,
      'fieldOfViewDegrees': 35,
      'distance': 42,
    });
    expect(camera.projection, SpatialCameraProjection.perspective);
    expect(camera.pitchDegrees, 55);
    expect(camera.yawDegrees, 12);
    expect(camera.fieldOfViewDegrees, 35);
    expect(camera.distance, 42);
  });

  test('copy and equality include projection and orthographic height', () {
    final before = SpatialCameraProfile();
    final after = before.copyWith(
      projection: SpatialCameraProjection.orthographic,
      orthographicHeight: 14,
    );
    expect(after, isNot(before));
    expect(after.copyWith(), after);
    expect(SpatialCameraProfile.fromJson(after.toJson()), after);
    expect(after.pitchDegrees, before.pitchDegrees);
    expect(after.distance, before.distance);
    expect(after.copyWith(orthographicHeight: 13), isNot(after));
    expect(
      after.copyWith(projection: SpatialCameraProjection.perspective),
      isNot(after),
    );
  });
}
