import 'dart:typed_data';

import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';
import 'package:map_render_3d/src/spatial_lighting_preview.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';

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
    expect(shader.pixelWrites, 11);

    for (var frame = 0; frame < 120; frame++) {
      material.apply(context);
    }

    expect(shader.pixelWrites, 11);
    material.uvRect.x = .25;
    material.apply(context);
    expect(shader.pixelWrites, 18);
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
    expect(shader.pixelWrites, 11);
    material.apply(context);
    expect(shader.pixelWrites, 11);
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
      expect(shader.pixelWrites, 11);
      material.apply(litContext);
      expect(shader.pixelWrites, 11);
      litContext.lighting = SpatialLightingProfile.stylized(sunStrength: .5);
      material.apply(litContext);
      expect(shader.pixelWrites, 15);
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
    : super.fromAsset('pixel-test', slots: ['albedoTexture', 'Material']);

  int pixelWrites = 0;

  @override
  void setVector4(String key, Vector4 value) {
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
    'albedoTexture' => _UniformSlot(slot, null, {}),
    _ => throw StateError('Unexpected shader slot: $slot'),
  };
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
