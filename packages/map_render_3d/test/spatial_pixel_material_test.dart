import 'dart:typed_data';

import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';

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
    expect(shader.pixelWrites, 7);

    for (var frame = 0; frame < 120; frame++) {
      material.apply(context);
    }

    expect(shader.pixelWrites, 7);
    material.uvRect.x = .25;
    material.apply(context);
    expect(shader.pixelWrites, 14);
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
    expect(shader.pixelWrites, 7);
    material.apply(context);
    expect(shader.pixelWrites, 7);
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
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
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
    'Material' => _UniformSlot(slot, 96, {
      'albedoColor': 0,
      'uvRect': 16,
      'uvTransformU': 32,
      'uvTransformV': 48,
      'textureDimensions': 64,
      'wrapModes': 72,
      'alphaMode': 80,
      'alphaCutoff': 84,
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

  @override
  void bindTexture(GpuUniformSlot slot, Texture texture) {
    textures[(slot as _UniformSlot).name] = texture;
  }

  @override
  void bindUniform(GpuUniformSlot slot, ByteBuffer buffer) {
    uniforms[(slot as _UniformSlot).name] = buffer.asFloat32List().toList();
  }
}
