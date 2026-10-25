import 'dart:ui';
import 'dart:math' as math;

import 'package:flame_3d/core.dart';

import 'package:flame_3d/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_render_3d/src/spatial_atmosphere.dart';

void main() {
  final target = SpatialAtmosphereTarget(
    instanceId: 'house',
    materialName: 'glass',
  );
  final zone = SpatialFireflyZone(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 4, y: 2, z: 3),
    ),
    count: 12,
    seed: 7,
  );
  test(
    'authored flags and scalar adjustments retain profile and scene identity',
    () {
      final controller = SpatialSceneController();
      final settings = SpatialAtmosphereSettings(
        waterTargets: [SpatialAtmosphereMaterialTarget.groundTileset('water')],
        fireflyZones: [
          SpatialAtmosphereFireflyZone(bounds: zone.bounds, count: 13),
        ],
      );
      var sceneChanges = 0;
      controller.sceneChanges.addListener(() => sceneChanges++);
      controller.applyAtmosphereSettings(settings);
      final profile = controller.atmosphereProfile;
      controller.applyAtmosphereSettings(
        settings.copyWith(
          waterAnimated: true,
          waterStrength: .4,
          windowStrength: 1.4,
          fireflyDensity: 1.5,
        ),
      );
      expect(controller.atmosphereProfile, same(profile));
      expect(profile.waterStrength, .4);
      expect(profile.windowStrength, 1.4);
      expect(profile.fireflyDensity, 1.5);
      expect(controller.waterAnimated, isTrue);
      expect(controller.windowsLit, isFalse);
      expect(sceneChanges, 0);
      controller.dispose();
    },
  );
  test('preview effects are off and independently toggled without replacing profile', () {
    final controller = SpatialSceneController();
    final profile = SpatialAtmosphereProfile(
      waterTargets: [target],
      windows: [
        SpatialWindowGlow(
          target: target,
          uvRects: [Rect.fromLTWH(.1, .2, .3, .4)],
        ),
      ],
      fireflyZones: [zone],
    );
    expect(controller.waterAnimated, isFalse);
    expect(controller.windowsLit, isFalse);
    expect(controller.fireflies, isFalse);
    controller.atmosphereProfile = profile;
    expect(controller.atmosphereAvailability, (
      water: true,
      windows: true,
      fireflies: true,
    ));
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.waterAnimated = true;
    controller.waterAnimated = true;
    controller.windowsLit = true;
    controller.fireflies = true;
    controller.windowsLit = false;
    expect(notifications, 4);
    expect(controller.atmosphereProfile, same(profile));
    expect(controller.waterAnimated, isTrue);
    expect(controller.windowsLit, isFalse);
    expect(controller.fireflies, isTrue);
    controller.dispose();
  });
  test('atmosphere preview never schedules camera or hover scene work', () {
    final controller = SpatialSceneController();
    var sceneChanges = 0, uiChanges = 0;
    controller.sceneChanges.addListener(() => sceneChanges++);
    controller.addListener(() => uiChanges++);
    controller.atmosphereProfile = SpatialAtmosphereProfile(
      waterTargets: [target],
    );
    controller.waterAnimated = true;
    controller.windowsLit = true;
    controller.fireflies = true;
    controller.waterAnimated = false;
    controller.windowsLit = false;
    controller.fireflies = false;
    expect(uiChanges, 7);
    expect(sceneChanges, 0);
    controller.dolly(10);
    expect(sceneChanges, 1);
    controller.dispose();
  });

  test('authored density reuses all resident firefly meshes', () {
    final controller = SpatialSceneController();
    final settings = SpatialAtmosphereSettings(
      fireflies: true,
      fireflyZones: [
        SpatialAtmosphereFireflyZone(bounds: zone.bounds, count: 13),
      ],
    );
    controller.applyAtmosphereSettings(settings);
    final effects = SpatialAtmosphereEffects(World3D());
    void sync() => effects.sync(
      profile: controller.atmosphereProfile,
      enabled: controller.fireflies,
      elapsedSeconds: 2,
      night: 1,
      cameraPitch: .8,
      cameraYaw: 0,
    );
    sync();
    final resident = effects.components.toList();
    expect(resident, hasLength(26));
    expect(effects.visibleCount, 13);
    controller.applyAtmosphereSettings(settings.copyWith(fireflyDensity: 2));
    sync();
    expect(effects.components.toList(), orderedEquals(resident));
    expect(effects.visibleCount, 26);
    controller.applyAtmosphereSettings(settings.copyWith(fireflyDensity: 0));
    sync();
    expect(effects.components.toList(), orderedEquals(resident));
    expect(effects.visibleCount, 0);
    effects.clear();
    controller.dispose();
  });

  test('targets are exact and window masks are immutable and restricted', () {
    final rects = [Rect.fromLTWH(.1, .2, .3, .4)];
    final window = SpatialWindowGlow(target: target, uvRects: rects);
    rects.clear();
    expect(window.uvRects, hasLength(1));
    expect(target.matches('house', 'glass'), isTrue);
    expect(target.matches('neighbor', 'glass'), isFalse);
    expect(target.matches('house', 'wall'), isFalse);
    expect(
      () => SpatialWindowGlow(
        target: target,
        uvRects: [Rect.fromLTWH(-.1, 0, 1, 1)],
      ),
      throwsArgumentError,
    );
    expect(
      () => SpatialFireflyZone(bounds: zone.bounds, count: 2000),
      throwsArgumentError,
    );
  });
  test('firefly positions are deterministic bounded and dark by day', () {
    final a = spatialFireflySample(zone, 3, elapsedSeconds: 2, night: 1);
    final b = spatialFireflySample(zone, 3, elapsedSeconds: 2, night: 1);
    final moved = spatialFireflySample(zone, 3, elapsedSeconds: 3, night: 1);
    expect(a, b);
    expect(a.position, isNot(moved.position));
    expect(
      spatialFireflySample(zone, 3, elapsedSeconds: 2, night: 0).opacity,
      0,
    );
    for (var index = 0; index < zone.count; index++) {
      for (final time in [0.0, 2.0, 40.0]) {
        final sample = spatialFireflySample(
          zone,
          index,
          elapsedSeconds: time,
          night: 1,
        );
        expect(sample.position.x, inInclusiveRange(0, 4));
        expect(sample.position.y, inInclusiveRange(0, 2));
        expect(sample.position.z, inInclusiveRange(0, 3));
        expect(sample.opacity, inInclusiveRange(0, 1));
      }
    }
  });
  test('firefly meshes remain resident while preview effects toggle', () {
    final world = World3D();
    final effects = SpatialAtmosphereEffects(world);
    final profile = SpatialAtmosphereProfile(fireflyZones: [zone]);
    effects.sync(
      profile: profile,
      enabled: false,
      elapsedSeconds: 1,
      night: 1,
      cameraPitch: .8,
      cameraYaw: 0,
    );
    final before = effects.components.toList();
    expect(before, hasLength(12));
    effects.sync(
      profile: profile,
      enabled: true,
      elapsedSeconds: 2,
      night: 1,
      cameraPitch: .8,
      cameraYaw: 0,
    );
    final normal = effects.components.first.rotation
        .asRotationMatrix()
        .transform(Vector3(0, 0, 1));
    expect(normal.x, closeTo(0, 1e-6));
    expect(normal.y, closeTo(math.sin(.8), 1e-6));
    expect(normal.z, closeTo(math.cos(.8), 1e-6));
    effects.sync(
      profile: profile,
      enabled: true,
      elapsedSeconds: 2,
      night: 1,
      cameraPitch: .8,
      cameraYaw: .4,
    );
    final turnedNormal = effects.components.first.rotation
        .asRotationMatrix()
        .transform(Vector3(0, 0, 1));
    expect(turnedNormal.x, closeTo(math.cos(.8) * math.sin(.4), 1e-6));
    expect(turnedNormal.y, closeTo(math.sin(.8), 1e-6));
    expect(turnedNormal.z, closeTo(math.cos(.8) * math.cos(.4), 1e-6));
    expect(effects.components.toList(), orderedEquals(before));
    effects.sync(
      profile: profile,
      enabled: false,
      elapsedSeconds: 3,
      night: 1,
      cameraPitch: .8,
      cameraYaw: 0,
    );
    expect(effects.components.toList(), orderedEquals(before));
    expect(effects.visibleCount, 0);
    effects.clear();
  });
}
