import 'package:flame_3d/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_render_3d/src/spatial_presentation_effects.dart';

void main() {
  test(
    'durable halo and fog adjustments retain presentation and firefly pools',
    () {
      final controller = SpatialSceneController();
      final settings = SpatialAtmosphereSettings(
        halos: [
          SpatialAtmosphereHalo(
            instanceId: 'lamp',
            localPosition: Model3dVector3(x: 0, y: 2, z: 0),
          ),
        ],
      );
      controller.applyAtmosphereSettings(settings);
      final profile = controller.presentationProfile,
          atmosphere = controller.atmosphereProfile;
      var invalidations = 0;
      controller.sceneChanges.addListener(() => invalidations++);
      controller.applyAtmosphereSettings(
        settings.copyWith(
          halosEnabled: true,
          depthFogEnabled: true,
          haloStrength: 1.4,
          haloSpread: 1.3,
          fogStart: 39,
          fogEnd: 49,
          fogOpacity: .32,
        ),
      );
      expect(controller.presentationProfile, same(profile));
      expect(controller.atmosphereProfile, same(atmosphere));
      expect(profile.haloStrength, 1.4);
      expect(profile.haloSpread, 1.3);
      expect(profile.fogOpacity, .32);
      expect(profile.fogStart, 39);
      expect(profile.fogEnd, 49);
      expect(controller.halosEnabled, isTrue);
      expect(controller.depthFogEnabled, isTrue);
      expect(invalidations, 0);
      controller.dispose();
    },
  );
  test('bound halos follow their owner without reallocating and hide when it disappears', () {
    final effects = SpatialPresentationEffects(World3D());
    final profile = SpatialPresentationProfile.fromSettings(
      SpatialAtmosphereSettings(
        halos: [
          SpatialAtmosphereHalo(
            instanceId: 'lamp',
            localPosition: Model3dVector3(x: 0, y: 2, z: 0),
          ),
        ],
      ),
    );
    Model3dVector3? position = Model3dVector3(x: 3, y: 2, z: 4);
    void sync() => effects.sync(
      profile: profile,
      enabled: true,
      windowsLit: true,
      night: 1,
      cameraPitch: .8,
      cameraYaw: 0,
      locate: (source) {
        expect(source.instanceId, 'lamp');
        return position;
      },
    );
    sync();
    final mesh = effects.components.single;
    expect(mesh.position.x, 3);
    expect(mesh.position.z, 4);
    position = Model3dVector3(x: 6, y: 2, z: 7);
    profile.haloSpread = 2;
    sync();
    expect(mesh.position.x, 6);
    expect(mesh.position.z, 7);
    expect(mesh.scale.x, 2);
    expect(effects.allocations, 1);
    position = null;
    sync();
    expect(effects.visibleCount, 0);
    effects.clear();
  });
  test(
    'preview switches preserve scene and atmosphere with no scene invalidation',
    () {
      final controller = SpatialSceneController();
      final atmosphere = controller.atmosphereProfile;
      final profile = SpatialPresentationProfile();
      var invalidations = 0, feedback = 0;
      controller.sceneChanges.addListener(() => invalidations++);
      controller.addListener(() => feedback++);
      expect(controller.halosEnabled, isFalse);
      expect(controller.depthFogEnabled, isFalse);
      controller.presentationProfile = profile;
      controller.halosEnabled = true;
      controller.halosEnabled = true;
      expect(controller.depthFogEnabled, isFalse);
      controller.depthFogEnabled = true;
      controller.halosEnabled = false;
      controller.depthFogEnabled = false;
      expect(feedback, 5);
      expect(invalidations, 0);
      expect(controller.presentationProfile, same(profile));
      expect(controller.atmosphereProfile, same(atmosphere));
      controller.dispose();
    },
  );

  test('depth haze leaves foreground clear and is capped in the distance', () {
    final fog = SpatialPresentationProfile(
      fogStart: 40,
      fogEnd: 60,
      fogOpacity: .2,
    );
    expect(fog.fogAtDepth(30), 0);
    expect(fog.fogAtDepth(40), 0);
    expect(fog.fogAtDepth(50), closeTo(.1, 1e-10));
    expect(fog.fogAtDepth(60), .2);
    expect(fog.fogAtDepth(1000), .2);
    expect(SpatialPresentationProfile.disabled.fogAtDepth(1000), 0);
  });

  test('unbounded or invalid preview work is rejected', () {
    expect(
      () => SpatialPresentationProfile(fogStart: 5, fogEnd: 5),
      throwsArgumentError,
    );
    expect(
      () => SpatialPresentationProfile(fogOpacity: double.nan),
      throwsArgumentError,
    );
    expect(
      () => SpatialHaloSource(position: Model3dVector3.zero, radiusX: 0),
      throwsArgumentError,
    );
    expect(
      () => SpatialPresentationProfile(
        halos: List.generate(
          33,
          (_) => SpatialHaloSource(position: Model3dVector3.zero),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('halo pool is retained across first and repeated switches and vanishes in daylight', () {
    final effects = SpatialPresentationEffects(World3D());
    final profile = SpatialPresentationProfile(
      halos: [
        SpatialHaloSource(position: Model3dVector3.zero),
        SpatialHaloSource(position: Model3dVector3.zero, window: true),
      ],
    );
    void sync(bool enabled, {double night = 1, bool windows = true}) =>
        effects.sync(
          profile: profile,
          enabled: enabled,
          windowsLit: windows,
          night: night,
          cameraPitch: .6,
          cameraYaw: 0,
        );
    sync(false);
    final components = effects.components.toList();
    expect(effects.allocations, 2);
    for (var i = 0; i < 10; i++) {
      sync(true);
      expect(effects.visibleCount, 2);
      sync(false);
      expect(effects.visibleCount, 0);
      expect(effects.components.toList(), orderedEquals(components));
    }
    sync(true, windows: false);
    expect(effects.visibleCount, 1);
    sync(true, night: 0);
    expect(effects.visibleCount, 0);
    expect(effects.allocations, 2);
    effects.clear();
    expect(effects.components, isEmpty);
  });
}
