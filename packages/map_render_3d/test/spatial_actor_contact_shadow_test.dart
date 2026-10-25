import 'dart:ui';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flame_3d/camera.dart';
import 'package:map_render_3d/src/spatial_actor_visual.dart';
import 'package:map_core/map_core.dart';

import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_actor_contact_shadow.dart';
import 'package:map_render_3d/src/spatial_lighting_preview.dart';
import 'package:map_render_3d/src/spatial_point_light.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('actor contact defaults off, stays at ground during jumps, and removes opt-outs', () async {
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 1, 1),
      Paint()..color = const Color(0xffffffff),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(1, 1);
    final texture = await SpatialActorTexture.fromImage(image);
    image.dispose();
    picture.dispose();
    SpatialActorVisual actor({bool? enabled, double y = 1}) =>
        SpatialActorVisual(
          x: 2,
          y: y,
          z: 3,
          groundY: 1,
          texture: texture,
          frame: const Rect.fromLTWH(0, 0, 1, 1),
          billboardVerticalOffset: 5,
          contactShadow: enabled ?? false,
        );
    final defaults = SpatialActorVisual(
      x: 2,
      y: 1,
      z: 3,
      groundY: 1,
      texture: texture,
      frame: const Rect.fromLTWH(0, 0, 1, 1),
    );
    expect(defaults.contactShadow, isFalse);
    final world = World3D();
    final contacts = SpatialActorContactShadows(world);
    void sync(Map<String, SpatialActorVisual> frames) => contacts.sync(
      frames,
      sceneOffset: const Offset(10, -4),
      lighting: SpatialLightingProfile.disabled,
    );
    sync({'hero': defaults});
    expect(contacts.components, isEmpty);
    sync({'hero': actor(enabled: true), 'npc': actor(enabled: true)});
    expect(contacts.components, hasLength(2));
    expect(world.children.whereType<SpatialActorContactShadow>(), hasLength(2));
    final shadow = contacts.components['hero']!;
    expect(shadow.position, Vector3(12, 1.012, -1.008));
    sync({'hero': actor(enabled: true, y: 3), 'npc': actor()});
    expect(contacts.components, hasLength(1));
    expect(world.children.whereType<SpatialActorContactShadow>(), hasLength(1));
    expect(contacts.components['hero'], same(shadow));
    expect(shadow.position, Vector3(12, 1.012, -1.008));
    contacts.sync(
      {'hero': actor(enabled: true)},
      sceneOffset: const Offset(10, -4),
      lighting: SpatialLightingProfile.disabled,
      previewActorId: 'hero',
      previewPosition: Model3dVector3(x: 6, y: 2, z: 7),
    );
    expect(shadow.position, Vector3(16, 2.012, 2.992));
    sync({});
    expect(contacts.components, isEmpty);
    sync({'hero': actor(enabled: true)});
    contacts.clear();
    expect(contacts.components, isEmpty);
    expect(world.children.whereType<SpatialActorContactShadow>(), isEmpty);
  });

  test('foot anchors use visible bottom pixels and account for subframes', () {
    final alpha = Uint8List(16 * 16);
    for (var y = 10; y < 14; y++) {
      for (var x = 10; x < 13; x++) alpha[y * 16 + x] = 255;
    }
    final anchor = spatialActorFrameFootAnchor(
      alpha,
      width: 16,
      height: 16,
      frame: const Rect.fromLTWH(8, 8, 8, 8),
    );
    expect(anchor, (x: -.0625, y: .25));
    expect(
      spatialActorFrameFootAnchor(
        Uint8List(64),
        width: 8,
        height: 8,
        frame: const Rect.fromLTWH(0, 0, 8, 8),
      ),
      isNull,
    );
    expect(
      spatialActorFrameFootAnchor(
        Uint8List.fromList(List.filled(64, 255)),
        width: 8,
        height: 8,
        frame: const Rect.fromLTWH(0, 0, 8, 8),
      ),
      (x: 0.0, y: 0.0),
    );
    expect(
      () => spatialActorFrameFootAnchor(
        alpha,
        width: 16,
        height: 16,
        frame: const Rect.fromLTWH(double.nan, 0, 8, 8),
      ),
      throwsArgumentError,
    );
  });

  test(
    'ground anchor projects beneath visible feet for camera yaw and pitch',
    () {
      const anchor = (x: -.0625, y: .25);
      for (final pitchDegrees in [30.0, 48.680419921875, 70.0]) {
        for (final yawDegrees in [0.0, 90.0, 180.0, 270.0]) {
          final pitch = pitchDegrees * math.pi / 180;
          final yaw = yawDegrees * math.pi / 180;
          final offset = spatialActorContactShadowOffset(
            anchor,
            width: 1.92,
            height: 1.92,
            pitch: pitch,
            yaw: yaw,
          );
          final visibleFoot = Vector3(
            anchor.x * 1.92 * math.cos(yaw),
            .02 + anchor.y * 1.92 / math.cos(pitch),
            -anchor.x * 1.92 * math.sin(yaw),
          );
          final groundContact = Vector3(offset.x, .012, offset.z);
          final screenRight = Vector3(math.cos(yaw), 0, -math.sin(yaw));
          final screenUp = Vector3(
            -math.sin(pitch) * math.sin(yaw),
            math.cos(pitch),
            -math.sin(pitch) * math.cos(yaw),
          );
          expect(
            groundContact.dot(screenRight),
            closeTo(visibleFoot.dot(screenRight), 1e-6),
          );
          expect(
            groundContact.dot(screenUp),
            closeTo(visibleFoot.dot(screenUp), 1e-6),
          );
        }
      }
      expect(
        spatialActorContactShadowOffset(
          anchor,
          width: 2,
          height: 2,
          pitch: math.pi / 2,
          yaw: 0,
          topView: true,
        ),
        (x: -.125, z: -.5),
      );
      expect(
        () => spatialActorContactShadowOffset(
          anchor,
          width: 2,
          height: 2,
          pitch: double.nan,
          yaw: 0,
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'fully transparent actor frames never leave a contact component',
    () async {
      final recorder = PictureRecorder();
      Canvas(recorder);
      final picture = recorder.endRecording();
      final image = picture.toImageSync(8, 8);
      final texture = await SpatialActorTexture.fromImage(image);
      image.dispose();
      picture.dispose();
      final visual = SpatialActorVisual(
        x: 0,
        y: 0,
        z: 0,
        texture: texture,
        frame: const Rect.fromLTWH(0, 0, 8, 8),
        contactShadow: true,
      );
      expect(visual.contactShadowFootAnchor, isNull);
      final world = World3D();
      final contacts = SpatialActorContactShadows(world);
      contacts.sync(
        {'hero': visual},
        sceneOffset: Offset.zero,
        lighting: SpatialLightingProfile.disabled,
      );
      expect(contacts.components, isEmpty);
      expect(world.children.whereType<SpatialActorContactShadow>(), isEmpty);
    },
  );

  test('CPU alpha anchors preserve GPU pixels and use processed color-key transparency', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 8, 8),
      Paint()..color = const Color(0xffff00ff),
    );
    canvas.drawRect(
      const Rect.fromLTWH(2, 2, 3, 4),
      Paint()..color = const Color(0xffffffff),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(8, 8);
    final expected = await image.toByteData();
    final original = await SpatialActorTexture.fromImage(image);
    expect(
      original.texture.sourceData.buffer.asUint8List(),
      expected!.buffer.asUint8List(),
    );
    expect(original.footAnchor(const Rect.fromLTWH(0, 0, 8, 8)), (
      x: 0.0,
      y: 0.0,
    ));
    final keyed = await SpatialActorTexture.fromImage(
      image,
      transparentColor: TilesetTransparentColor(red: 255, green: 0, blue: 255),
    );
    expect(keyed.footAnchor(const Rect.fromLTWH(0, 0, 8, 8)), (
      x: -.0625,
      y: .25,
    ));
    expect(keyed.footAnchor(const Rect.fromLTWH(0, 0, 8, 8)), (
      x: -.0625,
      y: .25,
    ));
    image.dispose();
    picture.dispose();
  });

  test('contact footprint stays small and rejects non-finite dimensions', () {
    expect(spatialActorContactShadowRadii(1.92).x, closeTo(.3, 1e-12));
    expect(spatialActorContactShadowRadii(1.92).z, closeTo(.2, 1e-12));
    expect(spatialActorContactShadowRadii(100).x, .4);
    expect(spatialActorContactShadowRadii(.1).x, .12);
    for (final width in [double.nan, double.infinity, -1.0, 0.0]) {
      expect(() => spatialActorContactShadowRadii(width), throwsArgumentError);
    }
  });

  test('contact opacity fades in darkness and responds to nearby light', () {
    const feet = (x: 0.0, y: 0.0, z: 0.0);
    final day = SpatialLightingProfile.stylized();
    final night = SpatialLightingProfile.stylized(
      sceneTint: const Color(0xff4d5e94),
      sunStrength: 0,
    );
    final lamp = SpatialLightingProfile.stylized(
      sceneTint: const Color(0xff4d5e94),
      sunStrength: 0,
      pointLights: [SpatialPointLight(position: (x: 0, y: 2, z: 0), radius: 5)],
    );
    final daylight = spatialActorContactShadowOpacity(day, feet);
    final darkness = spatialActorContactShadowOpacity(night, feet);
    final lamplight = spatialActorContactShadowOpacity(lamp, feet);
    expect(daylight, inInclusiveRange(.15, .22));
    expect(darkness, lessThan(.06));
    expect(lamplight, greaterThan(darkness));
    expect(lamplight, lessThan(daylight));
    expect(
      spatialActorContactShadowOpacity(lamp, (x: 20, y: 0, z: 0)),
      darkness,
    );
    expect(
      spatialActorContactShadowOpacity(day, (x: double.nan, y: 0, z: 0)),
      0,
    );
    expect(
      spatialActorContactShadowOpacity(SpatialLightingProfile.disabled, feet),
      .18,
    );
  });

  test('contact mesh reuses geometry and material while tracking feet', () {
    final shadow = SpatialActorContactShadow();
    final mesh = shadow.mesh;
    final material = shadow.material;
    shadow.sync(
      x: 2,
      groundY: 1.5,
      z: 3,
      width: 1.92,
      lighting: SpatialLightingProfile.stylized(),
    );
    expect(shadow.position, Vector3(2, 1.512, 3));
    expect(shadow.scale, Vector3(.3, 1, .2));
    expect(shadow.rotation, Quaternion.identity());
    final dayAlpha = material.albedoColor.a;
    shadow.sync(
      x: 4,
      groundY: 2,
      z: 5,
      width: 1.92,
      lighting: SpatialLightingProfile.stylized(
        sceneTint: const Color(0xff4d5e94),
      ),
    );
    expect(shadow.mesh, same(mesh));
    expect(shadow.material, same(material));
    expect(shadow.position, Vector3(4, 2.012, 5));
    expect(material.albedoColor.a, lessThan(dayAlpha));
    expect(material.lightingRole.name, 'actor');
    expect(material.alphaMode?.name, 'blend');
    final surface = mesh.surfaces.single;
    expect(surface.positions.length, greaterThan(0));
  });
}
