import 'dart:typed_data';
import 'dart:ui' show Color, Size, Rect;

import 'package:flame_3d/game.dart';
import 'package:flame_3d/components.dart' show Object3D;
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';
import 'package:map_render_3d/src/spatial_atmosphere.dart';
import 'package:map_render_3d/src/spatial_actor_contact_shadow.dart';
import 'package:map_render_3d/src/spatial_lighting_preview.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';
import 'package:map_render_3d/src/spatial_shadow_profile.dart';
import 'package:map_render_3d/src/spatial_shadow_coverage.dart';
import 'package:map_render_3d/src/spatial_point_light.dart';
import 'package:map_render_3d/src/spatial_point_shadow.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_presentation_effects.dart';
import 'package:map_render_3d/src/spatial_weather_material.dart';
import 'package:map_render_3d/src/spatial_weather_profile.dart';

void main() {
  late _ShaderBackend backend;
  late _RecordingDevice device;
  late RenderContext3D context;
  late SpatialPixelMaterial material;

  setUp(() {
    backend = _ShaderBackend();
    device = _RecordingDevice(backend: backend);
    context = RenderContext3D(device);
    material = SpatialPixelMaterial(Texture(ByteData(4), width: 1, height: 1));
    material.vertexShader.resource;
    material.fragmentShader.resource;
  });

  test('particle coverage follows the camera without growing geometry', () {
    final batch = SpatialWeatherBatch();
    final surface = batch.mesh.surfaces.single;
    final shader = batch.material.vertexShader;
    shader.resource;
    batch.material.configure(
      frame: const SpatialWeatherFrame(opacity: 1, size: .1),
      anchor: Vector3.zero(),
      bounds: const Rect.fromLTWH(0, 0, 100, 100),
      seconds: 10,
      weight: 1,
      count: spatialWeatherMaximumParticles,
      cameraDistance: 30,
    );
    context.projection.setIdentity();
    context.projection[0] = 7;
    context.projection[5] = 5;
    batch.material.apply(context);
    shader.bind(device);
    expect(device.uniforms['Weather']![52], 20);
    context.projection[0] = 2;
    context.projection[5] = 3;
    batch.material.apply(context);
    shader.bind(device);
    expect(device.uniforms['Weather']![52], 38);
    expect(device.uniforms['Weather']![40], spatialWeatherMaximumParticles);
    expect(batch.mesh.surfaces.single, same(surface));
    expect(batch.mesh.vertexCount, spatialWeatherMaximumParticles * 4);
  });

  test('solar coverage uploads all 64 cells without changing the filter', () {
    final ground = SpatialPixelMaterial(
      material.albedoTexture,
      lightingRole: SpatialPixelLightingRole.ground,
    );
    ground.vertexShader.resource;
    ground.fragmentShader.resource;
    final profile = SpatialShadowProfile(
      casterInstanceIds: {'block'},
      filterRadius: 2.5,
    );
    final spatial = SpatialRenderContext(device)
      ..lighting = SpatialLightingProfile.stylized(shadow: profile)
      ..shadowFrame = SpatialShadowFrame(
        material.albedoTexture,
        Matrix4.identity(),
        profile,
        coverage: (a: 1, b: 2, c: 32768, d: 65535),
      );
    ground.apply(spatial);
    ground.fragmentShader.bind(device);
    expect(device.uniforms['Shadow']!.sublist(32), [1, 2, 32768, 65535]);
    expect(device.uniforms['Shadow']![22], 2.5);
  });

  test('an offscreen solar caster keeps casting into visible ground', () {
    final wall = _OffscreenPointCaster(material);
    final spatial = SpatialRenderContext(device)
      ..shadowCasters = [wall]
      ..lighting = SpatialLightingProfile.stylized(
        shadow: SpatialShadowProfile(casterInstanceIds: {'town:wall'}),
      );
    spatial.flush();
    expect(spatial.shadowStats.casterDrawCount, 1);
    expect(spatial.shadowStats.targetAllocations, 1);
    expect(spatial.shadowFrame!.coverage, isNot(spatialFullShadowCoverage));
    spatial.flush();
    expect(spatial.shadowStats.casterDrawCount, 1);
    expect(spatial.shadowStats.targetAllocations, 1);
  });

  test('distant solar casters upload local coordinates', () {
    final spatial = SpatialRenderContext(device)
      ..shadowCasters = [_OffscreenPointCaster(material, offset: 10000)]
      ..lighting = SpatialLightingProfile.stylized(
        shadow: SpatialShadowProfile(
          casterInstanceIds: {'town:wall'},
          center: (x: 10000, y: 0, z: 0),
        ),
      );
    spatial.flush();
    expect(spatial.shadowStats.casterDrawCount, 1);
    expect(backend.shadowVertexSnapshots.single[12], closeTo(0, 1e-6));
  });

  test('solar receivers bind a relative projection and clear its origin', () {
    final ground = SpatialPixelMaterial(
      material.albedoTexture,
      lightingRole: SpatialPixelLightingRole.ground,
    );
    ground.vertexShader.resource;
    ground.fragmentShader.resource;
    final profile = SpatialShadowProfile(casterInstanceIds: {'block'});
    final relative = Matrix4.diagonal3Values(2, 3, 4);
    final spatial = SpatialRenderContext(device)
      ..lighting = SpatialLightingProfile.stylized(shadow: profile)
      ..shadowFrame = SpatialShadowFrame(
        material.albedoTexture,
        Matrix4.identity(),
        profile,
        origin: (x: 10000, y: 2, z: 10000),
        relativeWorldToLight: relative,
      );
    ground.apply(spatial);
    ground.fragmentShader.bind(device);
    expect(device.uniforms['Shadow']!.take(16), relative.storage);
    expect(device.uniforms['Shadow']!.sublist(28, 32), [10000, 2, 10000, 0]);
    spatial.shadowFrame = SpatialShadowFrame(
      material.albedoTexture,
      Matrix4.identity(),
      profile,
    );
    ground.apply(spatial);
    ground.fragmentShader.bind(device);
    expect(device.uniforms['Shadow']!.take(16), Matrix4.identity().storage);
    expect(device.uniforms['Shadow']!.sublist(28, 32), [0, 0, 0, 0]);
    spatial.shadowFrame = null;
    ground.apply(spatial);
    ground.fragmentShader.bind(device);
    expect(device.uniforms['Shadow']!.sublist(28, 32), [0, 0, 0, 0]);
  });

  test('solar casters outside the light volume do not submit GPU draws', () {
    final spatial = SpatialRenderContext(device)
      ..shadowCasters = [_OffscreenPointCaster(material, offset: 10000)]
      ..lighting = SpatialLightingProfile.stylized(
        shadow: SpatialShadowProfile(casterInstanceIds: {'town:wall'}),
      );
    spatial.flush();
    expect(spatial.shadowStats.casterDrawCount, 0);
  });

  test('sampled depth modes bind independently and return to packed depth', () {
    final ground = SpatialPixelMaterial(
      material.albedoTexture,
      lightingRole: SpatialPixelLightingRole.ground,
    );
    ground.vertexShader.resource;
    ground.fragmentShader.resource;
    final profile = SpatialShadowProfile(casterInstanceIds: {'block'});
    final spatial = SpatialRenderContext(device)
      ..lighting = SpatialLightingProfile.stylized(shadow: profile)
      ..shadowFrame = SpatialShadowFrame(
        material.albedoTexture,
        Matrix4.identity(),
        profile,
        samples: 4,
      )
      ..pointShadowFrame = SpatialPointShadowFrame(
        material.albedoTexture,
        1,
        samples: 4,
      );
    ground.apply(spatial);
    ground.fragmentShader.bind(device);
    expect(device.uniforms['Shadow']![16], 2);
    expect(device.uniforms['PointShadows']![0], 2);
    spatial.shadowFrame = SpatialShadowFrame(
      material.albedoTexture,
      Matrix4.identity(),
      profile,
      samples: 4,
      supersampled: true,
    );
    spatial.pointShadowFrame = SpatialPointShadowFrame(
      material.albedoTexture,
      1,
      samples: 4,
      supersampled: true,
    );
    ground.apply(spatial);
    ground.fragmentShader.bind(device);
    expect(device.uniforms['Shadow']![16], 3);
    expect(device.uniforms['PointShadows']![0], 3);
    spatial.shadowFrame = SpatialShadowFrame(
      material.albedoTexture,
      Matrix4.identity(),
      profile,
    );
    ground.apply(spatial);
    ground.fragmentShader.bind(device);
    expect(device.uniforms['Shadow']![16], 1);
    expect(device.uniforms['PointShadows']![0], 3);
    spatial.pointShadowFrame = SpatialPointShadowFrame(
      material.albedoTexture,
      1,
    );
    ground.apply(spatial);
    ground.fragmentShader.bind(device);
    expect(device.uniforms['PointShadows']![0], 1);
  });

  test(
    'depth fog binds only presentation uniforms and clears when disabled',
    () {
      final spatial = SpatialRenderContext(device);
      material.apply(spatial);
      material.fragmentShader.bind(device);
      final base = device.uniforms['Material']!.toList();
      final vertex = material.vertexShader, fragment = material.fragmentShader;
      expect(device.uniforms['Presentation']![3], 0);
      spatial
        ..presentationProfile = SpatialPresentationProfile(
          fogStart: 40,
          fogEnd: 55,
          fogOpacity: .2,
        )
        ..depthFogEnabled = true;
      material.apply(spatial);
      material.fragmentShader.bind(device);
      expect(device.uniforms['Presentation']![3], closeTo(.2, 1e-6));
      expect(device.uniforms['Presentation']!.sublist(4, 6), [40, 55]);
      expect(device.uniforms['Material'], base);
      expect(material.vertexShader, same(vertex));
      expect(material.fragmentShader, same(fragment));
      spatial.depthFogEnabled = false;
      material.apply(spatial);
      material.fragmentShader.bind(device);
      expect(device.uniforms['Presentation']![3], 0);
    },
  );
  test('unchanged presentation never rewrites uniforms for repeated draws', () {
    final shader = _CountingFragmentShader();
    shader.resource;
    material.fragmentShader = shader;
    final spatial = SpatialRenderContext(device)
      ..depthFogEnabled = true
      ..presentationProfile = SpatialPresentationProfile();
    material.apply(spatial);
    final writes = shader.presentationWrites;
    for (var i = 0; i < 120; i++) {
      material.apply(spatial);
    }
    expect(writes, 5);
    expect(shader.presentationWrites, writes);
    spatial.depthFogEnabled = false;
    material.apply(spatial);
    expect(shader.presentationWrites, writes + 5);
  });

  test(
    'weather uniforms animate existing materials and clear on return indoors',
    () {
      final profile = SpatialPresentationProfile()
        ..weatherFogStrength = .4
        ..weatherSeconds = 12
        ..weatherWindX = 2
        ..weatherWindZ = -3
        ..weatherGroundHeight = 5
        ..weatherImpactStrength = .7
        ..weatherImpactSpeed = 2;
      final spatial = SpatialRenderContext(device)
        ..presentationProfile = profile;
      material.apply(spatial);
      material.fragmentShader.bind(device);
      expect(device.uniforms['Presentation']!.sublist(8, 12), [
        2,
        -3,
        5,
        closeTo(.4, 1e-6),
      ]);
      expect(device.uniforms['Presentation']!.sublist(12, 16), [
        closeTo(.7, 1e-6),
        2,
        12,
        0,
      ]);
      profile.weatherSeconds = 13;
      material.apply(spatial);
      material.fragmentShader.bind(device);
      expect(device.uniforms['Presentation']![14], 13);
      final actor = SpatialPixelMaterial(
        material.albedoTexture,
        lightingRole: SpatialPixelLightingRole.actor,
      );
      actor.vertexShader.resource;
      actor.fragmentShader.resource;
      actor.apply(spatial);
      actor.fragmentShader.bind(device);
      expect(device.uniforms['Presentation']![12], 0);
      spatial.presentationProfile = SpatialPresentationProfile.disabled;
      material.apply(spatial);
      material.fragmentShader.bind(device);
      expect(device.uniforms['Presentation']!.sublist(8, 16), everyElement(0));
    },
  );

  test('atmosphere uniforms target one instance and keep all off pixels and resources intact', () {
    final spatial = SpatialRenderContext(device)..sourceInstanceId = 'house';
    final glass = SpatialPixelMaterial(
      material.albedoTexture,
      sourceMaterialName: 'glass',
    );
    final target = SpatialAtmosphereTarget(
      instanceId: 'house',
      materialName: 'glass',
    );
    spatial.atmosphereProfile = SpatialAtmosphereProfile(
      waterTargets: [target],
      windows: [
        SpatialWindowGlow(
          target: target,
          uvRects: [const Rect.fromLTWH(.1, .2, .3, .4)],
        ),
      ],
    );
    glass.vertexShader.resource;
    glass.fragmentShader.resource;
    glass.apply(spatial);
    glass.fragmentShader.bind(device);
    final vertex = glass.vertexShader, fragment = glass.fragmentShader;
    final original = device.uniforms['Material']!.toList();
    expect(device.uniforms['Atmosphere']!.sublist(0, 4), [0, 0, 0, 0]);
    spatial
      ..waterAnimated = true
      ..windowsLit = true
      ..atmosphereElapsedSeconds = 2
      ..atmosphereNight = .75;
    glass.apply(spatial);
    glass.fragmentShader.bind(device);
    expect(device.uniforms['Atmosphere']!.sublist(0, 4), [1, 2, 0, 1]);
    expect(device.uniforms['Atmosphere']![7], closeTo(.6, 1e-6));
    expect(
      device.uniforms['Atmosphere']!.sublist(8, 12),
      [.1, .2, .4, .6].map((v) => closeTo(v, 1e-6)),
    );
    expect(device.uniforms['Material'], original);
    expect(glass.vertexShader, same(vertex));
    expect(glass.fragmentShader, same(fragment));
    spatial.sourceInstanceId = 'neighbor';
    glass.apply(spatial);
    glass.fragmentShader.bind(device);
    expect(device.uniforms['Atmosphere']!.sublist(0, 4), [0, 0, 0, 0]);
    spatial
      ..sourceInstanceId = 'house'
      ..waterAnimated = false
      ..windowsLit = false;
    glass.apply(spatial);
    glass.fragmentShader.bind(device);
    expect(device.uniforms['Atmosphere']!.every((value) => value == 0), isTrue);
    expect(device.textures['albedoTexture'], same(material.albedoTexture));
  });
  test(
    'unchanged atmosphere does not rewrite uniforms for unrelated draws',
    () {
      final shader = _CountingFragmentShader();
      shader.resource;
      material.fragmentShader = shader;
      final spatial = SpatialRenderContext(device);
      material.apply(spatial);
      final writes = shader.atmosphereWrites;
      expect(writes, greaterThan(0));
      for (var i = 0; i < 120; i++) {
        spatial.atmosphereElapsedSeconds = i.toDouble();
        material.apply(spatial);
      }
      expect(shader.atmosphereWrites, writes);
    },
  );

  test('a point caster only draws into the cube faces it intersects', () {
    final spatial = SpatialRenderContext(device)
      ..shadowCasters = [_OffscreenPointCaster(material)]
      ..lighting = SpatialLightingProfile.stylized(
        pointLights: [
          SpatialPointLight(position: (x: -10, y: 1, z: -1), radius: 20),
        ],
        pointShadowCasterInstanceIds: {'town:wall'},
      );
    spatial.flush();
    expect(spatial.shadowStats.pointCasterDrawCount, 1);
    expect(backend.pointPasses, 1);
    expect(spatial.pointShadowFrame!.lightCount, 1);
    expect(backend.pointMaterialSnapshots, hasLength(1));
  });

  test('joint deformation keeps conservative point shadow coverage', () {
    final spatial = SpatialRenderContext(device)
      ..shadowCasters = [_OffscreenPointCaster(material)]
      ..lighting = SpatialLightingProfile.stylized(
        pointLights: [
          SpatialPointLight(position: (x: -10, y: 1, z: -1), radius: 20),
        ],
        pointShadowCasterInstanceIds: {'town:wall'},
      );
    spatial.jointsInfo.jointTransforms = [Matrix4.translationValues(-12, 0, 0)];
    spatial.flush();
    expect(spatial.shadowStats.pointCasterDrawCount, 6);
  });

  test('an offscreen opted-in masked caster produces point depth draws and OFF ON reuses its atlas', () {
    final mask = SpatialPixelMaterial(
      material.albedoTexture,
      alphaMode: Model3dAlphaMode.mask,
      alphaCutoff: .5,
    )..uvRect.setValues(.1, .2, .3, .4);
    final spatial = SpatialRenderContext(device)
      ..shadowCasters = [_OffscreenPointCaster(mask)];
    final light = SpatialPointLight(position: (x: 0, y: 2, z: 0), radius: 5);
    spatial.lighting = SpatialLightingProfile.stylized(
      surfaceStrength: 0,
      pointLights: [light],
    );
    spatial.flush();
    expect(backend.pointPasses, 0);
    spatial.lighting = SpatialLightingProfile.stylized(
      surfaceStrength: 0,
      pointLights: [light],
      pointShadowCasterInstanceIds: {'town:wall'},
    );
    spatial.flush();
    expect(spatial.shadowStats.pointCasterDrawCount, 5);
    expect(spatial.shadowStats.pointTargetAllocations, 1);
    expect(spatial.shadowStats.pointShadowLightCount, 1);
    expect(backend.pointPasses, 1);
    expect(backend.pointFrameEnds, 0);
    expect(backend.pointMaterialSnapshots, hasLength(5));
    for (final snapshot in backend.pointMaterialSnapshots) {
      expect(snapshot[20], 2);
      expect(snapshot[21], .5);
      expect(snapshot[4], closeTo(.1, 1e-6));
      expect(snapshot[7], closeTo(.4, 1e-6));
    }
    spatial.pointLightShadowsEnabled = false;
    spatial.flush();
    expect(spatial.shadowStats.pointCasterDrawCount, 0);
    expect(spatial.pointShadowFrame, isNull);
    expect(backend.pointPasses, 1);
    spatial.pointLightShadowsEnabled = true;
    spatial.flush();
    expect(spatial.shadowStats.pointCasterDrawCount, 5);
    expect(spatial.shadowStats.pointTargetAllocations, 1);
    expect(backend.pointPasses, 2);
    expect(spatial.sourceShadowId, isNull);
    expect(
      mask.uvRect.storage,
      [.1, .2, .3, .4].map((value) => closeTo(value, 1e-6)),
    );
  });

  test('point shadow bindings apply to model receivers without relighting normals and clear on OFF', () {
    final spatial = SpatialRenderContext(device)
      ..lighting = SpatialLightingProfile.stylized(surfaceStrength: 0)
      ..pointShadowFrame = SpatialPointShadowFrame(material.albedoTexture, 2);
    final shader = material.vertexShader;
    material.apply(spatial);
    material.fragmentShader.bind(device);
    expect(material.vertexShader, same(shader));
    expect(device.uniforms['PointShadows']!.sublist(0, 3), [1, 256, 2]);
    expect(device.textures['pointShadowTexture'], same(material.albedoTexture));
    spatial.pointShadowFrame = null;
    material.apply(spatial);
    material.fragmentShader.bind(device);
    expect(device.uniforms['PointShadows']!.first, 0);
    expect(device.textures['pointShadowTexture'], same(Texture.standard));
  });

  test('contact ellipse never enters solar or point caster passes even with a matching id', () {
    final contact = SpatialActorContactShadow();
    final caster = _OffscreenPointCaster(contact.material);
    final spatial = SpatialRenderContext(device)
      ..shadowCasters = [caster]
      ..lighting = SpatialLightingProfile.stylized(
        shadow: SpatialShadowProfile(casterInstanceIds: {'town:wall'}),
        pointLights: [
          SpatialPointLight(position: (x: 0, y: 2, z: 0), radius: 5),
        ],
        pointShadowCasterInstanceIds: {'town:wall'},
      );
    device.begin();
    device.beginPass(const Size(16, 16));
    spatial.submitDraw(caster, Matrix4.identity());
    spatial.flush();
    device.end();
    expect(spatial.shadowStats.casterDrawCount, 0);
    expect(spatial.shadowStats.pointCasterDrawCount, 0);
    expect(spatial.shadowStats.pointTargetAllocations, 0);
    expect(spatial.shadowStats.receiverDrawCount, 0);
  });

  test('environment uniforms tint prelit artwork and restore all point slots after disabling', () {
    final spatial = SpatialRenderContext(device);
    final unlitShader = material.vertexShader;
    spatial.lighting = SpatialLightingProfile.stylized(
      surfaceStrength: 0,
      sceneTint: const Color(0xff4d5e94),
      pointLights: [
        SpatialPointLight(
          position: (x: 3, y: 4, z: 5),
          radius: 6,
          intensity: .75,
        ),
      ],
    );
    material.apply(spatial);
    material.fragmentShader.bind(device);
    expect(material.vertexShader, same(unlitShader));
    var environment = device.uniforms['Environment']!;
    expect(environment.sublist(4, 8), [1, 1, 0, 0]);
    expect(environment.sublist(12, 16), [3, 4, 5, 6]);
    expect(environment[31], .75);
    spatial.lighting = SpatialLightingProfile.disabled;
    material.apply(spatial);
    material.fragmentShader.bind(device);
    environment = device.uniforms['Environment']!;
    expect(environment.sublist(0, 8), [1, 1, 1, 1, 0, 0, 0, 0]);
    expect(environment.sublist(28, 44), everyElement(0));
    expect(environment[55], 0);
    expect(environment[59], 0);
  });

  test('actor point illumination follows a uniform foot anchor without a shadow map', () {
    final actor = SpatialPixelMaterial(
      material.albedoTexture,
      lightingRole: SpatialPixelLightingRole.actor,
    )..shadowSamplePosition = Vector3(4, 1, 7);
    final spatial = SpatialRenderContext(device)
      ..lighting = SpatialLightingProfile.stylized(
        surfaceStrength: 0,
        pointLights: [
          SpatialPointLight(position: (x: 4, y: 3, z: 7), radius: 5),
        ],
      );
    actor.vertexShader.resource;
    actor.fragmentShader.resource;
    actor.apply(spatial);
    actor.fragmentShader.bind(device);
    expect(device.uniforms['Environment']!.sublist(8, 12), [4, 1, 7, 1]);
    actor.shadowSamplePosition!.x = 8;
    actor.apply(spatial);
    actor.fragmentShader.bind(device);
    expect(device.uniforms['Environment']!.sublist(8, 12), [8, 1, 7, 1]);
    expect(device.uniforms['Shadow']![16], 0);
  });

  test('moving an actor only rewrites its environment sample position', () {
    final shader = _CountingFragmentShader();
    shader.resource;
    final actor =
        SpatialPixelMaterial(
            material.albedoTexture,
            lightingRole: SpatialPixelLightingRole.actor,
          )
          ..fragmentShader = shader
          ..shadowSamplePosition = Vector3(4, 1, 7);
    actor.vertexShader.resource;
    final spatial = SpatialRenderContext(device)
      ..lighting = SpatialLightingProfile.stylized();

    actor.apply(spatial);
    expect(
      shader.environmentWrites,
      unorderedEquals([
        'Environment.tint',
        'Environment.options',
        'Environment.samplePosition',
        for (var i = 0; i < 4; i++) ...[
          'Environment.pointPositionRadius[$i]',
          'Environment.pointColorIntensity[$i]',
        ],
        for (var i = 0; i < 2; i++) ...[
          'Environment.fireflyPositionRadius[$i]',
          'Environment.fireflyColorIntensity[$i]',
        ],
      ]),
    );
    for (var i = 0; i < 120; i++) {
      actor.apply(spatial);
    }
    actor.shadowSamplePosition = Vector3(4, 1, 7);
    actor.apply(spatial);
    expect(shader.environmentWrites, hasLength(15));

    final positions = <Vector3?>[
      actor.shadowSamplePosition!..x = 8,
      Vector3(9, 2, 10),
      null,
      Vector3.zero(),
      Vector3(4, 1, 7),
    ];
    for (final position in positions) {
      actor.shadowSamplePosition = position;
      final before = shader.environmentWrites.length;
      actor.apply(spatial);
      expect(shader.environmentWrites.skip(before), [
        'Environment.samplePosition',
      ]);
      shader.bind(device);
      expect(device.uniforms['Environment']!.sublist(8, 12), [
        position?.x ?? 0,
        position?.y ?? 0,
        position?.z ?? 0,
        position == null ? 0 : 1,
      ]);
      actor.apply(spatial);
      expect(shader.environmentWrites, hasLength(before + 1));
    }
  });

  test(
    'new environment profiles restore light slots without rewriting the anchor',
    () {
      final shader = _CountingFragmentShader();
      shader.resource;
      final actor =
          SpatialPixelMaterial(
              material.albedoTexture,
              lightingRole: SpatialPixelLightingRole.actor,
            )
            ..fragmentShader = shader
            ..shadowSamplePosition = Vector3(4, 1, 7);
      actor.vertexShader.resource;
      final spatial = SpatialRenderContext(device)
        ..lighting = SpatialLightingProfile.stylized(
          pointLights: [
            for (var i = 0; i < 4; i++)
              SpatialPointLight(position: (x: i + 1, y: 2, z: 3), radius: 4),
          ],
          fireflyLights: [
            for (var i = 0; i < 2; i++)
              SpatialPointLight(position: (x: i + 5, y: 6, z: 7), radius: 8),
          ],
        );
      actor.apply(spatial);
      expect(shader.environmentWrites, hasLength(15));

      final reduced = SpatialLightingProfile.stylized(
        sceneTint: const Color(0xff00ff00),
        pointLights: [
          SpatialPointLight(
            position: (x: 10, y: 11, z: 12),
            radius: 13,
            color: const Color(0xffff0000),
            intensity: .5,
          ),
        ],
      );
      for (final profile in [
        reduced,
        SpatialLightingProfile.disabled,
        reduced,
      ]) {
        spatial.lighting = profile;
        final before = shader.environmentWrites.length;
        actor.apply(spatial);
        final writes = shader.environmentWrites.skip(before);
        expect(writes, hasLength(14));
        expect(writes, isNot(contains('Environment.samplePosition')));
        shader.bind(device);
        final environment = device.uniforms['Environment']!;
        expect(environment.sublist(8, 12), [4, 1, 7, 1]);
        expect(environment.sublist(16, 28), [
          for (var i = 0; i < 3; i++) ...[0, 0, 0, 1],
        ]);
        expect(environment.sublist(32, 44), everyElement(0));
        expect(environment.sublist(44, 52), [0, 0, 0, 1, 0, 0, 0, 1]);
        expect(environment.sublist(52, 60), everyElement(0));
        if (profile.enabled) {
          expect(environment.sublist(0, 8), [0, 1, 0, 1, 1, 1, 0, 0]);
          expect(environment.sublist(12, 16), [10, 11, 12, 13]);
          expect(environment.sublist(28, 32), [1, 0, 0, .5]);
        } else {
          expect(environment.sublist(0, 8), [1, 1, 1, 1, 0, 0, 0, 0]);
          expect(environment.sublist(12, 16), [0, 0, 0, 1]);
          expect(environment.sublist(28, 32), everyElement(0));
          actor.shadowSamplePosition!.x = 5;
          actor.apply(spatial);
          expect(shader.environmentWrites, hasLength(before + 15));
          shader.bind(device);
          expect(device.uniforms['Environment']!.sublist(8, 12), [5, 1, 7, 1]);
          actor.shadowSamplePosition!.x = 4;
          actor.apply(spatial);
        }
      }
    },
  );

  test('replaced shaders and resources restore both environment groups', () {
    final first = _CountingFragmentShader();
    first.resource;
    final actor =
        SpatialPixelMaterial(
            material.albedoTexture,
            lightingRole: SpatialPixelLightingRole.actor,
          )
          ..fragmentShader = first
          ..shadowSamplePosition = Vector3(4, 1, 7);
    actor.vertexShader.resource;
    final spatial = SpatialRenderContext(device)
      ..lighting = SpatialLightingProfile.stylized(
        sceneTint: const Color(0xff00ff00),
        pointLights: [
          SpatialPointLight(position: (x: 2, y: 3, z: 4), radius: 5),
        ],
        fireflyLights: [
          SpatialPointLight(position: (x: 6, y: 7, z: 8), radius: 9),
        ],
      );
    actor.apply(spatial);
    first.bind(device);
    final expected = device.uniforms['Environment']!.toList();
    final second = _CountingFragmentShader();
    second.resource;
    actor.fragmentShader = second;
    actor.apply(spatial);
    second.bind(device);
    expect(first.environmentWrites, hasLength(15));
    expect(second.environmentWrites, hasLength(15));
    expect(device.uniforms['Environment'], expected);

    final resource = second.resource;
    backend._shaders['TextureFragment'] = _Shader();
    second.recreateResource = true;
    expect(second.resource, isNot(same(resource)));
    actor.apply(spatial);
    second.bind(device);
    expect(second.environmentWrites, hasLength(30));
    expect(device.uniforms['Environment'], expected);
    actor.apply(spatial);
    expect(second.environmentWrites, hasLength(30));
  });

  test('recreated pixel shader resources restore environment with identical GPU handles', () {
    final actor = SpatialPixelMaterial(
      material.albedoTexture,
      lightingRole: SpatialPixelLightingRole.actor,
    )..shadowSamplePosition = Vector3(4, 1, 7);
    actor.vertexShader.resource;
    actor.fragmentShader.resource;
    final spatial = SpatialRenderContext(device)
      ..lighting = SpatialLightingProfile.stylized(
        sceneTint: const Color(0xff00ff00),
        pointLights: [
          SpatialPointLight(position: (x: 2, y: 3, z: 4), radius: 5),
        ],
        fireflyLights: [
          SpatialPointLight(position: (x: 6, y: 7, z: 8), radius: 9),
        ],
      );
    actor.apply(spatial);
    actor.fragmentShader.bind(device);
    final expected = device.uniforms['Environment']!.toList();
    final resource = actor.fragmentShader.resource;
    actor.fragmentShader.recreateResource = true;
    expect(actor.fragmentShader.resource, same(resource));
    device.uniforms.clear();
    actor.apply(spatial);
    actor.fragmentShader.bind(device);
    expect(device.uniforms['Environment'], expected);
  });

  test(
    'environment anchors follow the actor role even for excluded materials',
    () {
      final spatial = SpatialRenderContext(device)
        ..lighting = SpatialLightingProfile.stylized(
          unlitMaterialNames: {'prelit'},
        );
      for (final role in SpatialPixelLightingRole.values) {
        final shader = _CountingFragmentShader();
        shader.resource;
        final surface =
            SpatialPixelMaterial(
                material.albedoTexture,
                lightingRole: role,
                sourceMaterialName: 'prelit',
              )
              ..fragmentShader = shader
              ..shadowSamplePosition = Vector3(4, 1, 7);
        surface.vertexShader.resource;
        surface.apply(spatial);
        shader.bind(device);
        expect(device.uniforms['Material']![36], 0);
        expect(
          device.uniforms['Environment']!.sublist(8, 12),
          role == SpatialPixelLightingRole.actor ? [4, 1, 7, 1] : [0, 0, 0, 0],
        );
        surface.shadowSamplePosition!.x = 5;
        surface.apply(spatial);
        expect(
          shader.environmentWrites,
          hasLength(role == SpatialPixelLightingRole.actor ? 16 : 15),
        );
      }
    },
  );

  test(
    'environment profile and anchor buffers stay isolated across materials',
    () {
      final spatial = SpatialRenderContext(device)
        ..lighting = SpatialLightingProfile.stylized(
          sceneTint: const Color(0xff00ff00),
        );
      final actors = [
        for (var i = 0; i < 2; i++)
          SpatialPixelMaterial(
            material.albedoTexture,
            lightingRole: SpatialPixelLightingRole.actor,
          )..shadowSamplePosition = Vector3(i + 1, 2, 3),
      ];
      final snapshots = <List<double>>[];
      for (final actor in actors) {
        actor.vertexShader.resource;
        actor.fragmentShader.resource;
        actor.apply(spatial);
        actor.fragmentShader.bind(device);
        snapshots.add(device.uniforms['Environment']!.toList());
      }
      spatial.lighting = SpatialLightingProfile.stylized(
        sceneTint: const Color(0xffff0000),
      );
      actors[0].shadowSamplePosition!.x = 10;
      actors[0].apply(spatial);
      actors[1].fragmentShader.bind(device);
      expect(device.uniforms['Environment'], snapshots[1]);
      actors[0].fragmentShader.bind(device);
      expect(device.uniforms['Environment']!.sublist(0, 4), [1, 0, 0, 1]);
      expect(device.uniforms['Environment']!.sublist(8, 12), [10, 2, 3, 1]);
    },
  );

  test('unlit context binds identity joints on its first static draw', () {
    final spatial = SpatialRenderContext(device);
    final unlit = UnlitMaterial(albedoTexture: material.albedoTexture);
    final originalJoints = spatial.jointsInfo.jointTransforms;

    spatial.applyMaterial(unlit);

    expect(device.uniforms, contains('JointMatrices'));
    final joints = device.uniforms['JointMatrices']!;
    expect(joints, hasLength(16 * 16));
    expect(joints.take(16), Matrix4.identity().storage);
    expect(joints.skip(16), everyElement(0));
    expect(spatial.jointsInfo.jointTransforms, same(originalJoints));
    expect(originalJoints, isEmpty);
  });

  test('unlit context preserves actual skeletal joint transforms', () {
    final spatial = SpatialRenderContext(device);
    final unlit = UnlitMaterial(albedoTexture: material.albedoTexture);
    final joints = [
      Matrix4.translationValues(2, 3, 4),
      Matrix4.diagonal3Values(2, 3, 4),
    ];
    final expected = [for (final joint in joints) joint.storage.toList()];
    spatial.jointsInfo.jointTransforms = joints;

    spatial.applyMaterial(unlit);

    final buffer = device.uniforms['JointMatrices']!;
    expect(buffer.take(16), expected.first);
    expect(buffer.skip(16).take(16), expected.last);
    expect(spatial.jointsInfo.jointTransforms, same(joints));
    expect(joints.first.storage, expected.first);
    expect(joints.last.storage, expected.last);
  });

  test('unlit context restores identity after an animated draw', () {
    final spatial = SpatialRenderContext(device);
    final unlit = UnlitMaterial(albedoTexture: material.albedoTexture);
    final joint = Matrix4.translationValues(2, 3, 4);
    spatial.jointsInfo.jointTransforms = [joint];
    spatial.applyMaterial(unlit);
    expect(device.uniforms['JointMatrices']!.take(16), joint.storage);
    final staticJoints = <Matrix4>[];
    spatial.jointsInfo.jointTransforms = staticJoints;
    device.uniforms.clear();

    spatial.applyMaterial(unlit);

    expect(
      device.uniforms['JointMatrices']!.take(16),
      Matrix4.identity().storage,
    );
    expect(spatial.jointsInfo.jointTransforms, same(staticJoints));
    expect(staticJoints, isEmpty);
  });

  test('unlit context restores joint binding after replacing its shader', () {
    final spatial = SpatialRenderContext(device);
    final unlit = UnlitMaterial(albedoTexture: material.albedoTexture);
    spatial.applyMaterial(unlit);
    final replacement = _CountingVertexShader();
    unlit.vertexShader = replacement;
    device.uniforms.clear();

    spatial.applyMaterial(unlit);

    expect(replacement.jointWrites, greaterThan(0));
    expect(device.uniforms, contains('JointMatrices'));
    expect(
      device.uniforms['JointMatrices']!.take(16),
      Matrix4.identity().storage,
    );
    expect(spatial.jointsInfo.jointTransforms, isEmpty);
  });

  test('static surfaces bind the required joint matrix buffer', () {
    material.apply(context);
    material.vertexShader.bind(device);

    expect(device.uniforms, contains('JointMatrices'));
    final joints = device.uniforms['JointMatrices']!;
    expect(joints, hasLength(16 * 16));
    expect(joints.take(16), Matrix4.identity().storage);
    expect(joints.skip(16), everyElement(0));
  });

  test('static joint matrix is written once across repeated draws', () {
    final shader = _CountingVertexShader();
    shader.resource;
    material.vertexShader = shader;
    for (var frame = 0; frame < 120; frame++) {
      material.apply(context);
    }
    expect(shader.jointWrites, 1);
    material.vertexShader.bind(device);
    expect(
      device.uniforms['JointMatrices']!.take(16),
      Matrix4.identity().storage,
    );
  });

  test('static joint cache restores identity after skeletal draws', () {
    final shader = _CountingVertexShader();
    shader.resource;
    material.vertexShader = shader;
    material.apply(context);
    context.jointsInfo.jointTransforms = [Matrix4.translationValues(2, 3, 4)];
    material.apply(context);
    material.vertexShader.bind(device);
    expect(
      device.uniforms['JointMatrices']!.take(16),
      context.jointsInfo.jointTransforms.single.storage,
    );
    context.jointsInfo.jointTransforms = [];
    material.apply(context);
    material.apply(context);
    expect(shader.jointWrites, 3);
    material.vertexShader.bind(device);
    expect(
      device.uniforms['JointMatrices']!.take(16),
      Matrix4.identity().storage,
    );
  });

  test('replacing the vertex shader binds the static joint matrix', () {
    final first = _CountingVertexShader();
    first.resource;
    material.vertexShader = first;
    material.apply(context);
    final second = _CountingVertexShader();
    second.resource;
    material.vertexShader = second;
    material.apply(context);
    material.apply(context);
    expect(first.jointWrites, 1);
    expect(second.jointWrites, 1);
  });

  test('unchanged pixel uniforms are written once across repeated draws', () {
    final shader = _CountingFragmentShader();
    shader.resource;
    material.fragmentShader = shader;
    material.albedoColor = const Color.from(
      alpha: .375,
      red: .125,
      green: .625,
      blue: .875,
    );
    material.apply(context);
    expect(shader.pixelWrites, 16);
    expect(shader.albedoWrites, 1);

    for (var frame = 0; frame < 120; frame++) {
      material.apply(context);
    }

    expect(shader.pixelWrites, 16);
    expect(shader.albedoWrites, 121);
    expect(shader.albedoSnapshots, everyElement([.125, .625, .875, .375]));
    material.uvRect.x = .25;
    material.apply(context);
    expect(shader.pixelWrites, 23);
    expect(shader.albedoWrites, 122);
    material.fragmentShader.bind(device);
    expect(device.uniforms['Material']!.sublist(0, 4), [
      .125,
      .625,
      .875,
      .375,
    ]);
    expect(device.uniforms['Material']!.sublist(4, 8), [.25, 0, 1, 1]);
  });

  test('material resource recreation retains every pixel uniform', () {
    material
      ..uvRect.setValues(.1, .2, .3, .4)
      ..applyAnimation(
        [1, 0, 0, 1, .25, .5],
        texture: Texture(ByteData(32), width: 2, height: 4),
        wrapModes: (wrapS: 33071, wrapT: 33648),
      );
    material.apply(context);
    material.fragmentShader.bind(device);
    final before = device.uniforms['Material']!.toList();
    final shaderResource = material.fragmentShader.resource;

    material.fragmentShader.recreateResource = true;
    material.fragmentShader.resource;
    expect(material.fragmentShader.resource, same(shaderResource));
    device.uniforms.clear();
    material.apply(context);
    material.fragmentShader.bind(device);

    expect(device.uniforms['Material'], before);
    expect(before.sublist(16, 20), [2, 4, 33071, 33648]);
  });

  test(
    'shared animated materials restore texture and UVs before static draws',
    () {
      final texture = material.albedoTexture;
      material.apply(context);
      material.fragmentShader.bind(device);
      final original = device.uniforms['Material']!.toList();
      material.applyAnimation(
        [2, 0, 0, 3, .25, .5],
        texture: Texture(ByteData(32), width: 2, height: 4),
        wrapModes: (wrapS: 33071, wrapT: 33648),
      );
      material.apply(context);
      material.fragmentShader.bind(device);
      expect(device.uniforms['Material']!.sublist(8, 16), [
        2,
        0,
        .25,
        0,
        0,
        3,
        .5,
        0,
      ]);
      expect(device.uniforms['Material']!.sublist(16, 20), [
        2,
        4,
        33071,
        33648,
      ]);

      material.resetAnimation();
      material.apply(context);
      material.fragmentShader.bind(device);
      expect(device.uniforms['Material'], original);
      expect(device.textures['albedoTexture'], same(texture));
    },
  );

  test('replacing a fragment shader writes the current pixel state', () {
    material.apply(context);
    final shader = _CountingFragmentShader();
    shader.resource;
    material.fragmentShader = shader;
    material.apply(context);
    expect(shader.pixelWrites, 16);
    material.apply(context);
    expect(shader.pixelWrites, 16);
  });

  test('skeletal surfaces retain their actual joint transforms', () {
    final joints = [
      Matrix4.translationValues(2, 3, 4),
      Matrix4.diagonal3Values(2, 3, 4),
    ];
    context.jointsInfo.jointTransforms = joints;

    material.apply(context);
    material.vertexShader.bind(device);

    final buffer = device.uniforms['JointMatrices']!;
    expect(buffer.take(16), joints.first.storage);
    expect(buffer.skip(16).take(16), joints.last.storage);
  });

  test('static surfaces rebind joints after shader resource recreation', () {
    material.apply(context);
    material.vertexShader.bind(device);
    material.vertexShader.recreateResource = true;
    material.vertexShader.resource;
    device.uniforms.clear();

    material.apply(context);
    material.vertexShader.bind(device);

    expect(device.uniforms, contains('JointMatrices'));
    expect(
      device.uniforms['JointMatrices']!.take(16),
      Matrix4.identity().storage,
    );
  });

  test('the default material keeps the original shader and alpha state', () {
    final originalVertex = material.vertexShader;
    material.apply(context);
    material.fragmentShader.bind(device);
    expect(material.vertexShader, same(originalVertex));
    expect(device.uniforms['Material']!.sublist(36, 40), [0, 0, 1, 0]);
    expect(device.uniforms['Material']!.sublist(20, 22), [
      0,
      closeTo(.1, 1e-6),
    ]);
  });

  test(
    'lighting toggles the normal shader and leaves UV alpha and joints intact',
    () {
      final litContext = SpatialRenderContext(device);
      final originalVertex = material.vertexShader;
      material.apply(litContext);
      material.fragmentShader.bind(device);
      final before = device.uniforms['Material']!.take(24).toList();
      litContext.lighting = SpatialLightingProfile.stylized();
      material.apply(litContext);
      material.fragmentShader.bind(device);
      expect(material.vertexShader, isNot(same(originalVertex)));
      expect(device.uniforms['Material']!.sublist(36, 40), [1, 1, 1, 0]);
      expect(device.uniforms['Material']!.take(24).toList(), before);
      material.vertexShader.bind(device);
      expect(
        device.uniforms['JointMatrices']!.take(16),
        Matrix4.identity().storage,
      );
      litContext.lighting = SpatialLightingProfile.disabled;
      material.apply(litContext);
      material.fragmentShader.bind(device);
      expect(material.vertexShader, same(originalVertex));
      expect(device.uniforms['Material']!.sublist(36, 40), [0, 0, 1, 0]);
      expect(device.uniforms['Material']!.take(24).toList(), before);
    },
  );

  test('nominated source materials remain unlit inside the preview', () {
    final litContext = SpatialRenderContext(device)
      ..lighting = SpatialLightingProfile.stylized(
        unlitMaterialNames: {'shadow'},
      );
    final excluded = SpatialPixelMaterial(
      material.albedoTexture,
      sourceMaterialName: 'shadow',
    );
    excluded.vertexShader.resource;
    excluded.fragmentShader.resource;
    final originalVertex = excluded.vertexShader;
    excluded.apply(litContext);
    excluded.fragmentShader.bind(device);
    expect(excluded.vertexShader, same(originalVertex));
    expect(device.uniforms['Material']!.sublist(36, 40), [0, 0, 1, 0]);
  });

  test(
    'actors and ground retain their original vertex paths and uniform tint',
    () {
      final litContext = SpatialRenderContext(device)
        ..lighting = SpatialLightingProfile.stylized(
          actorStrength: .2,
          groundStrength: .6,
        );
      for (final role in [
        SpatialPixelLightingRole.actor,
        SpatialPixelLightingRole.ground,
      ]) {
        final uniform = SpatialPixelMaterial(
          material.albedoTexture,
          lightingRole: role,
          groundDepthOnly: role == SpatialPixelLightingRole.ground,
        );
        uniform.vertexShader.resource;
        uniform.fragmentShader.resource;
        final originalVertex = uniform.vertexShader;
        uniform.apply(litContext);
        uniform.fragmentShader.bind(device);
        expect(uniform.vertexShader, same(originalVertex));
        final options = device.uniforms['Material']!.sublist(36, 40);
        expect(options[0], 1);
        expect(options[1], 0);
        expect(
          options[2],
          closeTo(role == SpatialPixelLightingRole.actor ? .2 : .6, 1e-6),
        );
      }
    },
  );

  test(
    'a new profile updates GPU lighting without rebinding pixel uniforms',
    () {
      final shader = _CountingFragmentShader();
      shader.resource;
      material.fragmentShader = shader;
      final litContext = SpatialRenderContext(device)
        ..lighting = SpatialLightingProfile.stylized(sunStrength: .2);
      material.apply(litContext);
      expect(shader.pixelWrites, 16);
      material.apply(litContext);
      expect(shader.pixelWrites, 16);
      litContext.lighting = SpatialLightingProfile.stylized(sunStrength: .5);
      material.apply(litContext);
      expect(shader.pixelWrites, 20);
      material.fragmentShader.bind(device);
      expect(device.uniforms['Material']![28], closeTo(.5, 1e-6));
    },
  );
  test(
    'the context selects the lit pipeline before binding shader uniforms',
    () {
      final litContext = SpatialRenderContext(device)
        ..lighting = SpatialLightingProfile.stylized();
      litContext.applyMaterial(material);
      expect(
        device.pipeline!.vertexShader,
        same(backend._shaders['LitTextureVertex']),
      );
      expect(device.uniforms['Material']!.sublist(36, 40), [1, 1, 1, 0]);
      litContext.lighting = SpatialLightingProfile.disabled;
      litContext.applyMaterial(material);
      expect(
        device.pipeline!.vertexShader,
        same(backend._shaders['TextureVertex']),
      );
      expect(device.uniforms['Material']!.sublist(36, 40), [0, 0, 1, 0]);
    },
  );
  test('only enabled ground materials bind the shadow visibility and receiver heights', () {
    final shadow = SpatialShadowProfile(
      casterInstanceIds: {'house'},
      receiverMinY: .9,
      receiverMaxY: 1.2,
    );
    final litContext = SpatialRenderContext(device)
      ..lighting = SpatialLightingProfile.stylized(shadow: shadow)
      ..shadowFrame = SpatialShadowFrame(
        material.albedoTexture,
        Matrix4.identity(),
        shadow,
      );
    for (final role in SpatialPixelLightingRole.values) {
      final surface = SpatialPixelMaterial(
        material.albedoTexture,
        lightingRole: role,
      );
      surface.vertexShader.resource;
      surface.fragmentShader.resource;
      surface.apply(litContext);
      surface.fragmentShader.bind(device);
      final options = device.uniforms['Shadow']!.sublist(16, 20);
      expect(options[0], role == SpatialPixelLightingRole.ground ? 1 : 0);
      if (role == SpatialPixelLightingRole.ground) {
        expect(options[1], closeTo(shadow.bias, 1e-6));
        expect(options[2], shadow.resolution);
        expect(device.uniforms['Shadow']![20], closeTo(.9, 1e-6));
        expect(device.uniforms['Shadow']![21], closeTo(1.2, 1e-6));
        litContext.lighting = SpatialLightingProfile.disabled;
        surface.apply(litContext);
        surface.fragmentShader.bind(device);
        expect(device.uniforms['Shadow']![16], 0);
      }
    }
  });
  test(
    'prelit model surfaces bypass normal shading independently of ground',
    () {
      final originalVertex = material.vertexShader;
      final litContext = SpatialRenderContext(device)
        ..lighting = SpatialLightingProfile.stylized(
          surfaceStrength: 0,
          groundStrength: .8,
        );
      material.apply(litContext);
      material.fragmentShader.bind(device);
      expect(material.vertexShader, same(originalVertex));
      expect(device.uniforms['Material']!.sublist(36, 40), [1, 0, 0, 0]);
    },
  );

  test('actors opt into uniform foot-point shadow sampling and update moving anchors', () {
    final shadow = SpatialShadowProfile(
      casterInstanceIds: {'house'},
      actorReceivers: true,
      filterRadius: 2.5,
      receiverMinY: .9,
      receiverMaxY: 1.2,
    );
    final litContext = SpatialRenderContext(device)
      ..lighting = SpatialLightingProfile.stylized(
        shadow: shadow,
        actorStrength: 1,
      )
      ..shadowFrame = SpatialShadowFrame(
        material.albedoTexture,
        Matrix4.identity(),
        shadow,
      );
    final actor = SpatialPixelMaterial(
      material.albedoTexture,
      lightingRole: SpatialPixelLightingRole.actor,
    )..shadowSamplePosition = Vector3(28, 1, 15);
    actor.vertexShader.resource;
    actor.fragmentShader.resource;
    final originalVertex = actor.vertexShader;
    actor.apply(litContext);
    actor.fragmentShader.bind(device);
    expect(device.uniforms['Shadow']![16], 1);
    expect(device.uniforms['Shadow']![22], 2.5);
    expect(device.uniforms['Shadow']!.sublist(24, 28), [28, 1, 15, 1]);
    expect(device.uniforms['Material']!.sublist(36, 40), [1, 0, 1, 0]);
    expect(actor.vertexShader, same(originalVertex));
    actor.shadowSamplePosition!.x = 29;
    actor.apply(litContext);
    actor.fragmentShader.bind(device);
    expect(device.uniforms['Shadow']!.sublist(24, 28), [29, 1, 15, 1]);
    actor.shadowSamplePosition = null;
    actor.apply(litContext);
    actor.fragmentShader.bind(device);
    expect(device.uniforms['Shadow']![16], 0);
    expect(device.uniforms['Shadow']![27], 0);
  });
}

final class _CountingVertexShader extends VertexShader {
  _CountingVertexShader()
    : super.fromAsset('pixel-test', slots: ['VertexInfo', 'JointMatrices']);

  int jointWrites = 0;

  @override
  void setMatrix4(String key, Matrix4 value) {
    if (key.startsWith('JointMatrices.')) jointWrites++;
    super.setMatrix4(key, value);
  }
}

final class _CountingFragmentShader extends FragmentShader {
  _CountingFragmentShader()
    : super.fromAsset(
        'pixel-test',
        slots: [
          'albedoTexture',
          'Material',
          'shadowTexture',
          'Shadow',
          'Environment',
          'PointShadows',
          'pointShadowTexture',
          'Atmosphere',
          'Presentation',
        ],
      );

  int pixelWrites = 0;
  int albedoWrites = 0;
  final albedoSnapshots = <List<double>>[];
  int atmosphereWrites = 0;
  int presentationWrites = 0;
  final environmentWrites = <String>[];

  @override
  void setVector4(String key, Vector4 value) {
    if (key == 'Material.albedoColor') {
      albedoWrites++;
      albedoSnapshots.add(value.storage.toList());
    }
    if (key.startsWith('Atmosphere.')) atmosphereWrites++;
    if (key.startsWith('Presentation.')) presentationWrites++;
    if (key.startsWith('Environment.')) environmentWrites.add(key);
    if (key != 'Material.albedoColor' &&
        !key.startsWith('Environment.') &&
        !key.startsWith('PointShadows.') &&
        !key.startsWith('Presentation.') &&
        !key.startsWith('Atmosphere.'))
      pixelWrites++;
    super.setVector4(key, value);
  }

  @override
  void setVector2(String key, Vector2 value) {
    pixelWrites++;
    super.setVector2(key, value);
  }

  @override
  void setFloat(String key, double value) {
    pixelWrites++;
    super.setFloat(key, value);
  }
}

final class _ShaderBackend extends GpuBackend {
  final _shaders = <String, GpuShader>{};
  int pointPasses = 0, pointFrameEnds = 0;
  final pointMaterialSnapshots = <List<double>>[];
  final shadowVertexSnapshots = <List<double>>[];

  @override
  GpuRenderTarget createRenderTarget({
    required int width,
    required int height,
    required Color clearValue,
  }) => _PointTarget();
  @override
  GpuFrame beginFrame() => _PointFrame(this);
  @override
  GpuBuffer createBuffer({
    required GpuStorageMode storageMode,
    required int sizeInBytes,
  }) => _PointBuffer();
  @override
  GpuTexture createTexture({
    required GpuStorageMode storageMode,
    required int width,
    required int height,
    required GpuPixelFormat format,
  }) => _PointTexture();

  @override
  GpuShaderLibrary loadShaderLibrary(String assetName) =>
      _ShaderLibrary(_shaders);

  @override
  GpuPipeline createPipeline({
    required GpuShader vertexShader,
    required GpuShader fragmentShader,
  }) => _Pipeline(vertexShader);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _Pipeline implements GpuPipeline {
  _Pipeline(this.vertexShader);
  final GpuShader vertexShader;
}

final class _ShaderLibrary implements GpuShaderLibrary {
  _ShaderLibrary(this.shaders);

  final Map<String, GpuShader> shaders;

  @override
  GpuShader operator [](String entryPoint) =>
      shaders.putIfAbsent(entryPoint, _Shader.new);
}

final class _Shader implements GpuShader {
  @override
  GpuUniformSlot getUniformSlot(String slot) => switch (slot) {
    'VertexInfo' => _UniformSlot(slot, 192, {
      'model': 0,
      'view': 64,
      'projection': 128,
    }),
    'JointMatrices' => _UniformSlot(slot, 1024, {'joints': 0}),
    'Material' => _UniformSlot(slot, 160, {
      'albedoColor': 0,
      'uvRect': 16,
      'uvTransformU': 32,
      'uvTransformV': 48,
      'textureDimensions': 64,
      'wrapModes': 72,
      'alphaMode': 80,
      'alphaCutoff': 84,
      'lightingAmbient': 96,
      'lightingSun': 112,
      'lightingDirection': 128,
      'lightingOptions': 144,
    }),
    'Shadow' => _UniformSlot(slot, 144, {
      'worldToLight': 0,
      'options': 64,
      'receiverHeight': 80,
      'samplePosition': 96,
      'origin': 112,
      'coverage': 128,
    }),
    'Environment' => _UniformSlot(slot, 240, {
      'tint': 0,
      'options': 16,
      'samplePosition': 32,
      'pointPositionRadius': 48,
      'pointColorIntensity': 112,
      'fireflyPositionRadius': 176,
      'fireflyColorIntensity': 208,
    }),
    'Atmosphere' => _UniformSlot(slot, 160, {
      'options': 0,
      'windowColor': 16,
      'windowRects': 32,
    }),
    'Presentation' => _UniformSlot(slot, 80, {
      'fogColor': 0,
      'depthRange': 16,
      'weatherFog': 32,
      'weatherImpacts': 48,
      'manualFog': 64,
    }),
    'Weather' => _UniformSlot(slot, 224, {
      'view': 0,
      'projection': 64,
      'anchorTime': 128,
      'motion': 144,
      'particle': 160,
      'tint': 176,
      'bounds': 192,
      'volume': 208,
    }),
    'PointShadows' => _UniformSlot(slot, 16, {'options': 0}),
    'PointDepth' => _UniformSlot(slot, 32, {'positionRadius': 0, 'tile': 16}),
    'albedoTexture' ||
    'shadowTexture' ||
    'pointShadowTexture' => _UniformSlot(slot, null, {}),
    _ => throw StateError('Unexpected shader slot: $slot'),
  };
}

final class _OffscreenPointCaster extends Object3D {
  _OffscreenPointCaster(SpatialPixelMaterial material, {this.offset = 0})
    : surface = Surface(
        vertices: [
          Vertex(position: Vector3(-1, 0, -1), texCoord: Vector2(0, 0)),
          Vertex(position: Vector3(1, 0, -1), texCoord: Vector2(1, 0)),
          Vertex(position: Vector3(0, 3, -1), texCoord: Vector2(0, 1)),
        ],
        indices: [0, 1, 2],
        material: material,
      );
  final Surface surface;
  final double offset;
  @override
  void draw(covariant RenderContext3D context) {
    final spatial = context as SpatialRenderContext;
    final previous = spatial.sourceShadowId;
    try {
      spatial.sourceShadowId = 'town:wall';
      context.model.setIdentity();
      context.model.setTranslationRaw(offset, 0, 0);
      context.drawSurface(surface);
    } finally {
      spatial.sourceShadowId = previous;
    }
  }
}

final class _PointTarget implements GpuRenderTarget {
  @override
  final colorTexture = _PointTexture();
}

final class _PointTexture implements GpuTexture {
  @override
  void write(ByteData data) {}
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Point maps stay on the GPU.');
}

final class _PointBuffer implements GpuBuffer {
  @override
  void write(ByteData data, {int destinationOffsetInBytes = 0}) {}
}

final class _PointFrame implements GpuFrame {
  _PointFrame(this.backend);
  final _ShaderBackend backend;
  @override
  GpuRenderPass beginRenderPass(
    GpuRenderTarget target, {
    required BlendState blend,
    required DepthStencilState depthStencil,
  }) {
    backend.pointPasses++;
    return _PointPass(backend);
  }

  @override
  void end() {
    backend.pointFrameEnds++;
  }
}

final class _PointPass implements GpuRenderPass {
  _PointPass(this.backend);
  final _ShaderBackend backend;
  @override
  void bindUniform(GpuUniformSlot slot, ByteData data) {
    final name = (slot as _UniformSlot).name;
    if (name == 'VertexInfo') {
      backend.shadowVertexSnapshots.add(
        data.buffer
            .asFloat32List(data.offsetInBytes, data.lengthInBytes ~/ 4)
            .toList(),
      );
    }
    if (name == 'Material')
      backend.pointMaterialSnapshots.add(
        data.buffer
            .asFloat32List(data.offsetInBytes, data.lengthInBytes ~/ 4)
            .toList(),
      );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _UniformSlot implements GpuUniformSlot {
  _UniformSlot(this.name, this.sizeInBytes, this.offsets);

  final String name;
  @override
  final int? sizeInBytes;
  final Map<String, int> offsets;

  @override
  int? getMemberOffsetInBytes(String member) => offsets[member];
}

final class _RecordingDevice extends GraphicsDevice {
  _RecordingDevice({required super.backend});

  final uniforms = <String, List<double>>{};
  final textures = <String, Texture>{};
  _Pipeline? pipeline;

  @override
  void bindPipeline(GpuPipeline pipeline, CullMode cullMode) {
    this.pipeline = pipeline as _Pipeline;
  }

  @override
  void bindTexture(GpuUniformSlot slot, Texture texture) {
    textures[(slot as _UniformSlot).name] = texture;
  }

  @override
  void bindUniform(GpuUniformSlot slot, ByteBuffer buffer) {
    uniforms[(slot as _UniformSlot).name] = buffer.asFloat32List().toList();
  }
}
