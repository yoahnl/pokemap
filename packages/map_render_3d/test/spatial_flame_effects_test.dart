import 'package:flame_3d/core.dart';

import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_flame_effects.dart';

void main() {
  test('flying embers remain readable at normal perspective framing', () {
    final world = World3D();
    final effects = SpatialFlameEffects(world);
    effects.sync(
      sources: [
        SpatialFlameSource(
          key: 'small-hearth',
          light: Model3dPointLight(
            localPosition: Model3dVector3.zero,
            flame: ModelLightFlame(
              height: .36,
              style: ModelLightFlameStyle.brazier,
              embers: 1,
            ),
          ),
          transform: Matrix4.identity(),
        ),
      ],
      elapsedSeconds: 1.5,
      daylight: 0,
      cameraPitch: .6,
      cameraYaw: 0,
    );
    final flame = effects.components.single;
    final pixelsPerWorldUnit = 600 / (2 * 40 * math.tan(20 * math.pi / 360));
    final readable = world.children.where((child) {
      if (identical(child, flame)) return false;
      final ember = child as dynamic;
      return (ember.scale.x as double) * pixelsPerWorldUnit >= 1 &&
          (ember.material.albedoColor as ui.Color).a >= .25;
    });
    expect(readable.length, greaterThanOrEqualTo(3));
    effects.clear();
  });
  test('embers stay near the source and never drift toward the camera', () {
    final world = World3D();
    final effects = SpatialFlameEffects(world);
    final light = Model3dPointLight(
      localPosition: Model3dVector3(x: 0, y: 1.18, z: .2),
      flame: ModelLightFlame(
        height: .36,
        style: ModelLightFlameStyle.brazier,
        embers: 1,
      ),
    );
    void sync(double seconds, double yaw) => effects.sync(
      sources: [
        SpatialFlameSource(
          key: 'enclosed-source',
          light: light,
          transform: Matrix4.identity(),
        ),
      ],
      elapsedSeconds: seconds,
      daylight: 0,
      cameraPitch: .6,
      cameraYaw: yaw,
    );
    sync(0, 0);
    final flame = effects.components.single;
    final embers = world.children
        .where((child) => !identical(child, flame))
        .toList();
    expect(embers, hasLength(8));
    for (var frame = 0; frame < 120; frame++) {
      sync(frame / 30, 0);
      final positions = [
        for (final ember in embers)
          (ember as dynamic).position.clone() as Vector3,
      ];
      sync(frame / 30, math.pi / 2);
      for (var index = 0; index < embers.length; index++) {
        final ember = embers[index] as dynamic;
        expect(ember.position, positions[index]);
        expect(ember.position.y, inInclusiveRange(1.18, 1.18 + .36 * 2.3));
        expect(
          (ember.position.z as double) - .2,
          inInclusiveRange(-.36 * 2, .36 * 2),
        );
        expect(ember.scale.x, lessThanOrEqualTo(.36 * .12));
      }
    }
    expect(effects.allocations, 1);
    effects.clear();
  });
  test('flying embers disperse beyond the flame instead of hiding in its core', () {
    final world = World3D();
    final effects = SpatialFlameEffects(world);
    effects.sync(
      sources: [
        SpatialFlameSource(
          key: 'hearth',
          light: Model3dPointLight(
            localPosition: Model3dVector3.zero,
            flame: ModelLightFlame(
              height: .36,
              style: ModelLightFlameStyle.brazier,
              embers: 1,
            ),
          ),
          transform: Matrix4.identity(),
        ),
      ],
      elapsedSeconds: 1.5,
      daylight: 0,
      cameraPitch: .6,
      cameraYaw: 0,
    );
    final flame = effects.components.single;
    final escaping = world.children.where((child) {
      if (identical(child, flame)) return false;
      final ember = child as dynamic;
      final distance = math.sqrt(
        (ember.position.x as double) * (ember.position.x as double) +
            (ember.position.z as double) * (ember.position.z as double),
      );
      return distance > .36 * .55 &&
          (ember.material.albedoColor as ui.Color).a >= .25;
    });
    expect(escaping.length, greaterThanOrEqualTo(3));
    effects.clear();
  });
  test('crackle gain follows visible night fire and listener distance without summing voices', () {
    final effects = SpatialFlameEffects(World3D());
    final light = Model3dPointLight(
      localPosition: Model3dVector3.zero,
      radius: 4,
      flame: ModelLightFlame(
        style: ModelLightFlameStyle.brazier,
        crackleVolume: .75,
      ),
    );
    var visible = true;
    void sync(double day, double listenerX) => effects.sync(
      sources: [
        for (var i = 0; i < 2; i++)
          SpatialFlameSource(
            key: i,
            light: light,
            transform: Matrix4.translationValues(2, 0, 0),
            visible: visible,
          ),
      ],
      elapsedSeconds: 1,
      daylight: day,
      cameraPitch: .6,
      cameraYaw: 0,
      listenerPosition: Vector3(listenerX, 0, 0),
    );
    sync(0, 0);
    expect(effects.soundGain, closeTo(.75 * .75 * .75, .000001));
    sync(1, 0);
    expect(effects.soundGain, 0);
    sync(0, 100);
    expect(effects.soundGain, 0);
    visible = false;
    sync(0, 0);
    expect(effects.soundGain, 0);
    effects.clear();
    expect(effects.soundGain, 0);
  });
  test('night flames reuse geometry, follow source transforms and clear independently', () {
    final effects = SpatialFlameEffects(World3D());
    final light = Model3dPointLight(
      localPosition: Model3dVector3(x: 0, y: 1.3, z: 0),
      flame: ModelLightFlame(height: .3),
    );
    final transform = Matrix4.translationValues(5, 2, 7)
      ..scaleByDouble(2, 2, 2, 1);
    var source = SpatialFlameSource(
      key: 'lantern',
      light: light,
      transform: transform,
    );
    void sync(double seconds, double daylight) => effects.sync(
      sources: [source],
      elapsedSeconds: seconds,
      daylight: daylight,
      cameraPitch: .6,
      cameraYaw: 0,
    );
    sync(0, 1);
    expect(effects.visibleCount, 0);
    final recorder = ui.PictureRecorder();
    effects.components.single.renderTree(ui.Canvas(recorder));
    recorder.endRecording().dispose();
    sync(0, 0);
    expect(effects.visibleCount, 1);
    final mesh = effects.components.single;
    expect(mesh.position.x, 5);
    expect(mesh.position.y, closeTo(4.6, .00001));
    final height = mesh.scale.y;
    for (var i = 1; i < 120; i++) sync(i / 30, 0);
    expect(effects.allocations, 1);
    expect(effects.components.single, same(mesh));
    expect(mesh.scale.y, isNot(height));
    source = SpatialFlameSource(
      key: 'lantern',
      light: light,
      transform: transform,
      strength: 0,
    );
    sync(4, 0);
    expect(effects.visibleCount, 0);
    source = SpatialFlameSource(
      key: 'lantern',
      light: light.copyWith(
        colorCycle: ModelLightColorCycle(
          colors: [0xff0000, 0x0000ff],
          periodSeconds: 8,
        ),
      ),
      transform: transform,
    );
    sync(4, 0);
    expect((mesh as dynamic).material.albedoColor.toARGB32(), 0xff0000ff);
    source = SpatialFlameSource(
      key: 'lantern',
      light: light.copyWith(
        flame: ModelLightFlame(style: ModelLightFlameStyle.brazier, embers: 1),
      ),
      transform: transform,
    );
    sync(4, 0);
    final brazier = effects.components.single;
    expect((brazier as dynamic).material.proceduralFlame, isTrue);
    expect(brazier.mesh.aabb.max.x, greaterThan(mesh.mesh.aabb.max.x));
    expect(effects.emberCount, 8);
    for (var i = 0; i < 120; i++) sync(4 + i / 30, 0);
    expect(effects.components.single, same(brazier));
    expect(effects.allocations, 2);
    sync(8, 1);
    expect(effects.visibleCount, 0);
    final daytime = ui.PictureRecorder();
    brazier.renderTree(ui.Canvas(daytime));
    daytime.endRecording().dispose();
    source = SpatialFlameSource(
      key: 'lantern',
      light: light.copyWith(clearFlame: true),
      transform: transform,
    );
    sync(5, 0);
    expect(effects.components, isEmpty);
    effects.clear();
    expect(effects.components, isEmpty);
  });
}
