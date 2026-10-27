import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_gameplay/src/spatial_terrain_navigation.dart';
import 'package:test/test.dart';

void main() {
  final lift = SpatialLiftDefinition(
      id: 'lift',
      name: 'Lift',
      instanceId: 'platform',
      x: 2,
      z: 2,
      width: 3,
      depth: 3,
      lowerHeight: 2,
      upperHeight: 31,
      durationMs: 1000);
  test('lift endpoints and rider terrain stay identical at uneven frame rates',
      () {
    final a =
        SpatialLiftMotion(definition: lift, sourceOffset: 0, raised: true);
    final b =
        SpatialLiftMotion(definition: lift, sourceOffset: 0, raised: true);
    a.advance(.5);
    b.advance(.12);
    b.advance(.38);
    expect(a.offset, b.offset);
    expect(a.height, 16.5);
    a.advance(8);
    expect(a.complete, isTrue);
    expect(a.offset, 29);
    final down = SpatialLiftMotion(
        definition: lift, sourceOffset: a.offset, raised: false);
    down.advance(.5);
    expect(down.height, 16.5);
    down.advance(.5);
    expect(down.offset, 0);
  });
  test('pause preserves progress and cancellation restores its source stop',
      () {
    final a =
        SpatialLiftMotion(definition: lift, sourceOffset: 29, raised: false);
    a.advance(.3);
    final before = a.offset;
    a.advance(1, paused: true);
    expect(a.offset, before);
    a.cancel();
    expect(a.offset, 29);
    a.advance(1);
    expect(a.offset, 29);
    expect(a.complete, isFalse);
    expect(() => a.advance(double.nan), throwsArgumentError);
    expect(
        () =>
            SpatialLiftMotion(definition: lift, sourceOffset: 3, raised: true),
        throwsFormatException);
  });
  test('lift height provider opens only the matching stop edge', () {
    final scene = MapSpatialScene(width: 8, depth: 8, heightLevels: [
      for (var z = 0; z < 8; z++)
        for (var x = 0; x < 8; x++) z < 2 ? 31 : 2
    ]);
    double height(double x, double z) =>
        lift.contains(x, z) ? 31 : scene.worldHeightAt(x, z);
    expect(
        canTraverseSpatialTerrainStep(scene, 3.5, 2.1, 3.5, 1.9,
            heightAt: height),
        isTrue);
    expect(
        canTraverseSpatialTerrainStep(scene, 3.5, 4.9, 3.5, 5.1,
            heightAt: height),
        isFalse);
    expect(canTraverseSpatialTerrainStep(scene, 3.5, 2.1, 3.5, 1.9), isFalse);
  });
}
