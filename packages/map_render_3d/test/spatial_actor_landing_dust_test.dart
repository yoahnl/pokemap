import 'dart:ui';

import 'package:flame_3d/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_actor_landing_dust.dart';
import 'package:map_render_3d/src/spatial_actor_visual.dart';
import 'package:map_render_3d/src/spatial_actor_contact_shadow.dart';
import 'package:map_render_3d/src/spatial_lighting_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SpatialActorTexture texture;
  setUp(() async {
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 8, 8), Paint());
    final picture = recorder.endRecording();
    final image = picture.toImageSync(8, 8);
    texture = await SpatialActorTexture.fromImage(image);
    image.dispose();
    picture.dispose();
  });

  SpatialActorVisual actor({
    bool airborne = false,
    bool enabled = true,
    double x = 3,
    double y = 2,
  }) => SpatialActorVisual(
    x: x,
    y: y,
    z: 4,
    groundY: 2,
    texture: texture,
    frame: const Rect.fromLTWH(0, 0, 8, 8),
    contactShadow: true,
    airborne: airborne,
    landingDust: enabled,
  );

  test('hero and companion land independently, exactly once per jump', () {
    final effects = SpatialActorLandingDust(World3D());
    effects.sync(
      {'hero': actor(), 'companion': actor()},
      mapId: 'field',
      dt: 0,
    );
    expect(effects.components, isEmpty);
    effects.sync(
      {'hero': actor(airborne: true, y: 2.5), 'companion': actor()},
      mapId: 'field',
      dt: .05,
    );
    effects.sync(
      {'hero': actor(), 'companion': actor(airborne: true, y: 2.4)},
      mapId: 'field',
      dt: .05,
    );
    expect(effects.components.keys, ['hero']);
    final first = effects.components['hero']!;
    effects.sync(
      {'hero': actor(x: 3.25), 'companion': actor()},
      mapId: 'field',
      dt: .05,
    );
    expect(effects.components, hasLength(2));
    expect(effects.components['hero'], same(first));
    expect(first.position.x, 3);
    expect(effects.components['companion']!.position.y, closeTo(2.025, 1e-6));
    for (var i = 0; i < 8; i++) {
      effects.sync(
        {'hero': actor(), 'companion': actor()},
        mapId: 'field',
        dt: .05,
      );
    }
    expect(effects.components, isEmpty);
  });

  test('pause freezes a puff, map change and actor removal clear state', () {
    final world = World3D();
    final effects = SpatialActorLandingDust(world);
    effects.sync(
      {'hero': actor(airborne: true, y: 2.5)},
      mapId: 'field',
      dt: 0,
    );
    effects.sync({'hero': actor()}, mapId: 'field', dt: .05);
    final puff = effects.components['hero']!;
    final position = puff.position.clone();
    final scale = puff.scale.clone();
    effects.sync({'hero': actor()}, mapId: 'field', dt: 2, paused: true);
    expect(puff.position, position);
    expect(puff.scale, scale);
    expect(effects.components['hero'], same(puff));
    effects.sync({'hero': actor()}, mapId: 'other', dt: .05);
    expect(effects.components, isEmpty);
    effects.sync({'hero': actor(airborne: true)}, mapId: 'other', dt: .05);
    effects.sync({}, mapId: 'other', dt: .05);
    effects.sync({'hero': actor()}, mapId: 'other', dt: .05);
    expect(effects.components, isEmpty);
    effects.clear();
    expect(world.children, isEmpty);
  });

  test(
    'height changes, opt-outs and invalid elapsed time never invent jumps',
    () {
      final effects = SpatialActorLandingDust(World3D());
      effects.sync(
        {
          'lift': actor(y: 3),
          'disabled': actor(airborne: true, enabled: false),
        },
        mapId: 'field',
        dt: 0,
      );
      effects.sync(
        {'lift': actor(), 'disabled': actor(enabled: false)},
        mapId: 'field',
        dt: .05,
      );
      expect(effects.components, isEmpty);
      effects.sync(
        {'hero': actor(airborne: true)},
        mapId: 'field',
        dt: double.nan,
      );
      effects.sync({'hero': actor()}, mapId: 'field', dt: -.1);
      expect(effects.components, isEmpty);
    },
  );

  test(
    'a single soft cloud clears the feet and reuses its mesh during playback',
    () {
      final puff = SpatialLandingDustComponent(3, 2, 4);
      puff.sync(
        sceneOffset: Offset.zero,
        cameraPitch: .85,
        cameraYaw: 0,
        topView: false,
      );
      final mesh = puff.mesh;
      final surface = mesh.surfaces.single;
      final xs = [
        for (var i = 0; i < surface.positions.length; i += 3)
          surface.positions[i],
      ];
      xs.sort();
      expect((xs.last - xs.first) * puff.scale.x, inInclusiveRange(.75, 1.1));
      expect(surface.indexCount, 180);
      final alpha = puff.material.albedoColor.a;
      puff.elapsed = .15;
      puff.sync(
        sceneOffset: Offset.zero,
        cameraPitch: .85,
        cameraYaw: 0,
        topView: false,
      );
      expect(puff.mesh, same(mesh));
      expect(puff.material.albedoColor.a, lessThan(alpha));
    },
  );

  test('dust shares the actual foot contact even when the sprite has transparent padding', () async {
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(const Rect.fromLTWH(2, 0, 4, 4), Paint());
    final picture = recorder.endRecording();
    final image = picture.toImageSync(8, 8);
    texture = await SpatialActorTexture.fromImage(image);
    image.dispose();
    picture.dispose();
    final world = World3D();
    final dust = SpatialActorLandingDust(world);
    dust.sync({'hero': actor(airborne: true, y: 2.5)}, mapId: 'field', dt: 0);
    dust.sync({'hero': actor()}, mapId: 'field', dt: .05);
    final shadows = SpatialActorContactShadows(world);
    shadows.sync(
      {'hero': actor()},
      sceneOffset: Offset.zero,
      lighting: SpatialLightingProfile.disabled,
    );
    expect(
      dust.components['hero']!.position.z,
      closeTo(shadows.components['hero']!.position.z, 1e-6),
    );
    expect(
      dust.components['hero']!.position.x,
      closeTo(shadows.components['hero']!.position.x, 1e-6),
    );
  });
}
