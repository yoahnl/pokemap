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
import 'package:map_render_3d/src/spatial_point_light.dart';
import 'package:map_render_3d/src/spatial_point_shadow.dart';
import 'package:map_core/map_core.dart';

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

  test('an offscreen opted-in masked caster produces six point depth draws and OFF ON reuses its atlas', () {
    final mask = SpatialPixelMaterial(
      material.albedoTexture,
      alphaMode: Model3dAlphaMode.mask,
      alphaCutoff: .5,
    )..uvRect.setValues(.1, .2, .3, .4);
    final spatial = SpatialRenderContext(device)
      ..pointShadowCasters = [_OffscreenPointCaster(mask)];
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
    expect(spatial.shadowStats.pointCasterDrawCount, 6);
    expect(spatial.shadowStats.pointTargetAllocations, 1);
    expect(spatial.shadowStats.pointShadowLightCount, 1);
    expect(backend.pointPasses, 1);
    expect(backend.pointFrameEnds, 0);
    expect(backend.pointMaterialSnapshots, hasLength(6));
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
    expect(spatial.shadowStats.pointCasterDrawCount, 6);
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
      ..pointShadowCasters = [caster]
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
    expect(environment.skip(28), everyElement(0));
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
    material.apply(context);
    expect(shader.pixelWrites, 14);

    for (var frame = 0; frame < 120; frame++) {
      material.apply(context);
    }

    expect(shader.pixelWrites, 14);
    material.uvRect.x = .25;
    material.apply(context);
    expect(shader.pixelWrites, 21);
    material.fragmentShader.bind(device);
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
    expect(shader.pixelWrites, 14);
    material.apply(context);
    expect(shader.pixelWrites, 14);
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
      expect(shader.pixelWrites, 14);
      material.apply(litContext);
      expect(shader.pixelWrites, 14);
      litContext.lighting = SpatialLightingProfile.stylized(sunStrength: .5);
      material.apply(litContext);
      expect(shader.pixelWrites, 18);
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
        ],
      );

  int pixelWrites = 0;
  int atmosphereWrites = 0;

  @override
  void setVector4(String key, Vector4 value) {
    if (key.startsWith('Atmosphere.')) atmosphereWrites++;
    if (!key.startsWith('Environment.') &&
        !key.startsWith('PointShadows.') &&
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
    'Shadow' => _UniformSlot(slot, 112, {
      'worldToLight': 0,
      'options': 64,
      'receiverHeight': 80,
      'samplePosition': 96,
    }),
    'Environment' => _UniformSlot(slot, 176, {
      'tint': 0,
      'options': 16,
      'samplePosition': 32,
      'pointPositionRadius': 48,
      'pointColorIntensity': 112,
    }),
    'Atmosphere' => _UniformSlot(slot, 160, {
      'options': 0,
      'windowColor': 16,
      'windowRects': 32,
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
  _OffscreenPointCaster(SpatialPixelMaterial material)
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
  @override
  void draw(covariant RenderContext3D context) {
    final spatial = context as SpatialRenderContext;
    final previous = spatial.sourceShadowId;
    try {
      spatial.sourceShadowId = 'town:wall';
      context.model.setIdentity();
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
    if ((slot as _UniformSlot).name == 'Material')
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
