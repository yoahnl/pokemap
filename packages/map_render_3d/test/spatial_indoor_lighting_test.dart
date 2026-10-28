import 'dart:typed_data';
import 'dart:ui';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_depth_of_field.dart';
import 'package:map_render_3d/src/spatial_environment_lighting.dart';
import 'package:map_render_3d/src/spatial_lighting_preview.dart';
import 'package:map_render_3d/src/spatial_point_light.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(_UnusedBackend.new);

  for (final metadata in [
    const MapMetadata(isIndoor: true),
    const MapMetadata(mapType: MapType.building),
    const MapMetadata(mapType: MapType.interior),
    const MapMetadata(mapType: MapType.facility),
    const MapMetadata(mapType: MapType.cave),
  ]) {
    final label = metadata.isIndoor ? 'indoor flag' : metadata.mapType.name;
    test('depth of field is bypassed indoors for $label', () {
      final fixture = _Fixture(metadata);
      final profile = SpatialDepthOfFieldProfile(
        enabled: true,
        strength: 1,
        focusRange: 2,
      );
      fixture.controller.depthOfFieldProfile = profile;

      fixture.game.syncDepthOfField();

      expect(fixture.game.device.postProcess, isNull);
      expect(fixture.game.device.secondaryColorClearValue, isNull);
      expect(fixture.controller.depthOfFieldProfile, same(profile));
      expect(fixture.game.depthOfFieldFrame['targetAllocations'], 0);
    });
  }

  test(
    'depth of field follows the visible map and resumes its exterior profile',
    () {
      final fixture = _Fixture(const MapMetadata());
      final profile = SpatialDepthOfFieldProfile(
        enabled: true,
        strength: .6,
        focusRange: 5,
      );
      fixture.controller.depthOfFieldProfile = profile;
      final exterior = fixture.game.configuration;
      final interior = fixture.view(const MapMetadata(isIndoor: true));
      void expectActive() {
        expect(fixture.game.device.postProcess, isNotNull);
        expect(
          fixture.game.device.secondaryColorClearValue,
          SpatialDepthOfField.depthClearValue,
        );
        expect(fixture.game.depthOfFieldFrame['enabled'], isTrue);
        expect(fixture.game.depthOfFieldFrame['strength'], profile.strength);
        expect(
          fixture.game.depthOfFieldFrame['focusRange'],
          profile.focusRange,
        );
      }

      fixture.game.syncDepthOfField();
      expectActive();

      fixture.game.renderedConfiguration = exterior;
      fixture.game.configuration = interior;
      fixture.game.syncDepthOfField();
      expectActive();

      fixture.game.renderedConfiguration = interior;
      fixture.game.syncDepthOfField();
      expect(fixture.game.device.postProcess, isNull);
      expect(fixture.game.device.secondaryColorClearValue, isNull);
      expect(fixture.game.depthOfFieldFrame['enabled'], isFalse);
      expect(fixture.controller.depthOfFieldProfile, same(profile));

      fixture.game.renderedConfiguration = exterior;
      fixture.game.syncDepthOfField();
      expectActive();
    },
  );

  test(
    'indoor lighting retains its authored appearance throughout the day',
    () {
      final fixture = _Fixture(const MapMetadata(isIndoor: true));
      final authored = SpatialLightingProfile.stylized(
        ambientStrength: .6,
        sunStrength: .2,
      );
      fixture.game.authoredLighting = authored;
      for (final minute in [0.0, 360.0, 720.0, 1140.0, 1320.0]) {
        fixture.controller.previewMinuteOfDay = minute;
        fixture.game.syncLighting();
        expect(fixture.context.lighting, same(authored));
        expect(fixture.controller.previewMinuteOfDay, minute);
      }
    },
  );

  for (final type in [
    MapType.building,
    MapType.interior,
    MapType.facility,
    MapType.cave,
  ]) {
    test(
      '$type retains its local lighting without an explicit indoor flag',
      () {
        final fixture = _Fixture(MapMetadata(mapType: type));
        final authored = SpatialLightingProfile.stylized(
          ambientStrength: .15,
          sunStrength: 0,
          sceneTint: const Color(0xff777788),
        );
        fixture.game.authoredLighting = authored;
        fixture.controller.previewMinuteOfDay = 0;
        fixture.game.syncLighting();
        expect(fixture.context.lighting, same(authored));
      },
    );
  }

  test('outdoor lighting still follows night and daylight', () {
    final fixture = _Fixture(const MapMetadata());
    for (final minute in [0.0, 720.0, 1320.0]) {
      fixture.controller.previewMinuteOfDay = minute;
      fixture.game.syncLighting();
      expect(
        fixture.context.lighting.sceneTint,
        spatialDayNightFrame(minute).tint,
      );
    }
  });

  test(
    'indoor atmosphere ignores night while the presentation clock advances',
    () {
      var elapsed = 0.0;
      final fixture = _Fixture(
        const MapMetadata(isIndoor: true),
        elapsed: () => elapsed,
      );
      fixture.game.sceneReady = true;
      fixture.game.update(0);
      expect(fixture.controller.dayNightMinuteOfDay, 0);
      expect(fixture.context.atmosphereNight, 0);
      elapsed = 600;
      fixture.game.update(0);
      expect(fixture.controller.dayNightMinuteOfDay, 720);
      expect(fixture.context.atmosphereNight, 0);
    },
  );

  test(
    'changing visible maps restores the matching lighting and atmosphere',
    () {
      final fixture = _Fixture(const MapMetadata(isIndoor: true));
      fixture.game.sceneReady = true;
      fixture.game.update(0);
      expect(fixture.context.lighting.sceneTint, const Color(0xffffffff));
      expect(fixture.context.atmosphereNight, 0);
      fixture.game.configuration = fixture.view(const MapMetadata());
      fixture.game.update(0);
      expect(fixture.context.lighting.sceneTint, spatialDayNightFrame(0).tint);
      expect(fixture.context.atmosphereNight, 1);
      fixture.game.configuration = fixture.view(
        const MapMetadata(isIndoor: true),
      );
      fixture.game.update(0);
      expect(fixture.context.lighting.sceneTint, const Color(0xffffffff));
      expect(fixture.context.atmosphereNight, 0);
    },
  );

  test('an explicit lighting preview remains authoritative indoors', () {
    final fixture = _Fixture(const MapMetadata(isIndoor: true));
    final preview = SpatialLightingProfile.stylized(
      sceneTint: const Color(0xff555566),
    );
    fixture.game.previewLighting = preview;
    fixture.controller.previewMinuteOfDay = 0;
    fixture.game.syncLighting();
    expect(fixture.context.lighting, same(preview));
  });

  test(
    'indoor lamps stay lit through the day while outdoor lamps follow night',
    () {
      final lamp = Model3dPointLight(localPosition: Model3dVector3.zero);
      for (final daylight in [0.0, .5, 1.0]) {
        expect(
          spatialPlacedPointLight(
            lamp,
            Matrix4.identity(),
            daylight: daylight,
            indoors: true,
          ).intensity,
          lamp.intensity,
        );
        expect(
          spatialPlacedPointLight(
            lamp,
            Matrix4.identity(),
            daylight: daylight,
          ).intensity,
          lamp.intensity * (1 - daylight),
        );
      }
    },
  );

  test('local lamps preserve the authored tint of a dark interior', () {
    final authored = SpatialLightingProfile.stylized(
      ambientStrength: .15,
      sunStrength: 0,
      sceneTint: const Color(0xff777788),
    );
    final lighting = spatialEnvironmentLighting(
      authored,
      lights: [SpatialPointLight(position: (x: 0, y: 1, z: 0), radius: 4)],
    );
    expect(lighting.sceneTint, authored.sceneTint);
    expect(lighting.ambientStrength, closeTo(authored.ambientStrength, 1e-12));
    expect(lighting.sunStrength, authored.sunStrength);
    expect(lighting.pointLights, hasLength(1));
  });

  test('the scene shadow switch reaches the render context', () {
    final fixture = _Fixture(const MapMetadata());
    fixture.game.syncLighting();
    expect(fixture.context.shadowsEnabled, isTrue);
    fixture.controller.shadowsEnabled = false;
    fixture.game.syncLighting();
    expect(fixture.context.shadowsEnabled, isFalse);
    fixture.controller.shadowsEnabled = true;
    fixture.game.syncLighting();
    expect(fixture.context.shadowsEnabled, isTrue);
  });
}

final class _Fixture {
  _Fixture(MapMetadata metadata, {this.elapsed}) {
    game = SpatialSceneGame(
      view(metadata),
      onPreviewStatus: (_) {},
      onSurfaceChanged: () {},
    )..onGameResize(Vector2(200, 200));
    addTearDown(controller.dispose);
    addTearDown(game.onRemove);
  }

  final controller = SpatialSceneController();
  final double Function()? elapsed;
  late final SpatialSceneGame game;
  SpatialRenderContext get context => game.context as SpatialRenderContext;

  SpatialSceneView view(MapMetadata metadata) {
    final scene = MapSpatialScene(
      width: 2,
      depth: 2,
      dayNightCycle: SpatialDayNightCycle(
        durationSeconds: 1200,
        startMinuteOfDay: 0,
      ),
    );
    return SpatialSceneView(
      scene: scene,
      groundMap: MapData(
        id: 'room',
        name: 'Room',
        size: const GridSize(width: 2, height: 2),
        mapMetadata: metadata,
        spatialScene: scene,
      ),
      models: const [],
      loadModel: (_) async => Uint8List(0),
      controller: controller,
      onCell: (_, _) {},
      background: const Color(0xff000000),
      ground: const Color(0xff000000),
      edge: const Color(0xff000000),
      errorBuilder: (_, _) => const SizedBox(),
      presentationElapsedSeconds: elapsed ?? () => 0,
    );
  }
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
