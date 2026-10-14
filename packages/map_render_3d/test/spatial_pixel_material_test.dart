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

final class _ShaderBackend extends GpuBackend {
  @override
  GpuShaderLibrary loadShaderLibrary(String assetName) => _ShaderLibrary();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _ShaderLibrary implements GpuShaderLibrary {
  @override
  GpuShader operator [](String entryPoint) => _Shader();
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

  @override
  void bindUniform(GpuUniformSlot slot, ByteBuffer buffer) {
    uniforms[(slot as _UniformSlot).name] = buffer.asFloat32List().toList();
  }
}
