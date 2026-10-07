import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  MapData map() => MapData(id: 'garden', name: 'Jardin', version: ProjectVersion.v9,
    size: const GridSize(width: 4, height: 3), spatialScene: MapSpatialScene(width: 4, depth: 3));
  test('spatial scene persists height levels and fixed camera independently', () {
    final original = map();
    final levels = List<int>.of(original.spatialScene!.heightLevels)..[5] = 2;
    final edited = original.copyWith(spatialScene: original.spatialScene!.copyWith(heightLevels: levels));
    final reopened = MapData.fromJson(edited.toJson());
    expect(reopened.spatialScene!.heightAt(1, 1), 2);
    expect(reopened.spatialScene!.camera.mode, SpatialCameraMode.fixed);
    expect(original.spatialScene!.heightAt(1, 1), 0);
  });
  test('3D project rejects 2D maps and 2D project rejects 3D maps', () {
    final twoD = ProjectManifest(name: '2D', maps: [], tilesets: []);
    final threeD = twoD.copyWith(version: ProjectVersion.v9, settings: ProjectSettings(
      dimension: ProjectDimension.threeD, spatialCamera: SpatialCameraProfile()));
    ProjectValidator.validate(threeD, maps: [map()]);
    expect(() => ProjectValidator.validate(twoD, maps: [map()]), throwsA(isA<ValidationException>()));
    expect(() => ProjectValidator.validate(threeD, maps: [map().copyWith(version: ProjectVersion.v8, spatialScene: null)]), throwsA(isA<ValidationException>()));
  });
  test('3D map rejects mixed 2D geometry and unsupported versions', () {
    expect(() => MapData.fromJson(map().copyWith(tilesetId: '2d').toJson()), throwsFormatException);
    expect(() => MapData.fromJson(map().copyWith(version: ProjectVersion.v8).toJson()), throwsFormatException);
  });
  test('terrain bounds, fractional levels and huge allocations are rejected', () {
    expect(() => MapSpatialScene(width: 100000, depth: 100000), throwsFormatException);
    expect(() => MapSpatialScene(width: 1, depth: 1, heightLevels: [33]), throwsFormatException);
    expect(() => SpatialCameraProfile(pitchDegrees: 90), throwsFormatException);
  });
}
