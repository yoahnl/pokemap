import 'dart:typed_data';
import 'dart:ui' show Color, Size;

import 'package:flame_3d/game.dart' show Vector4;
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _RecordingBackend backend;
  late GraphicsDevice device;

  setUp(() {
    backend = _RecordingBackend();
    device = GraphicsDevice(backend: backend)
      ..begin()
      ..beginPass(const Size(1, 1));
  });

  tearDown(() => device.end());

  test('10000 continuous colors reuse one four-float buffer per shader', () {
    final shader = _ColorShader()..resource;
    final expectedWrites = <(String, List<double>)>[];
    const keys = [
      'Material.albedoColor',
      'Material.lightingAmbient',
      'Material.colors[0]',
      'Material.colors[1]',
      'flatColor',
    ];

    for (var i = 0; i < 10000; i++) {
      final color = Color.from(
        alpha: i / 9999,
        red: (i + .123456789) / 10000,
        green: ((i * 7) % 10000 + .234567891) / 10000,
        blue: ((i * 13) % 10000 + .345678912) / 10000,
      );
      final key = keys[i % keys.length];
      expectedWrites.add((key, _float32Color(color)));
      shader.setColor(key, color);
    }

    shader.bind(device);
    expect(backend.uploads, hasLength(2));
    expect(shader.writes, hasLength(10000));
    for (var i = 0; i < expectedWrites.length; i++) {
      expect(shader.writes[i].$1, expectedWrites[i].$1);
      expect(shader.writes[i].$2, expectedWrites[i].$2);
    }
    expect(shader.buffers, hasLength(1));
    expect(shader.buffers.single, hasLength(4));
    expect(shader.buffers.single.lengthInBytes, 16);
  });

  test('interleaved shaders keep independent color buffers and bindings', () {
    final first = _ColorShader()..resource;
    final second = _ColorShader()..resource;
    const firstColor = Color.from(
      alpha: .123456789,
      red: .234567891,
      green: .345678912,
      blue: .456789123,
    );
    const secondColor = Color.from(
      alpha: .987654321,
      red: .876543219,
      green: .765432198,
      blue: .654321987,
    );

    first.setColor('Material.albedoColor', firstColor);
    second.setColor('Material.albedoColor', secondColor);
    first.setColor('Material.colors[1]', secondColor);
    second.setColor('Material.colors[0]', firstColor);
    first.bind(device);
    second.bind(device);

    expect(backend.uploads[0].$2.sublist(0, 4), _float32Color(firstColor));
    expect(backend.uploads[0].$2.sublist(12, 16), _float32Color(secondColor));
    expect(backend.uploads[1].$2.sublist(0, 4), _float32Color(secondColor));
    expect(backend.uploads[1].$2.sublist(8, 12), _float32Color(firstColor));
    expect(first.buffers, hasLength(1));
    expect(second.buffers, hasLength(1));
    expect(first.buffers.single, isNot(same(second.buffers.single)));
    expect(first.writes.first.$2, _float32Color(firstColor));
    expect(second.writes.first.$2, _float32Color(secondColor));
  });

  test('raw fields and array colors copy full float RGBA before reuse', () {
    final shader = _ColorShader()..resource;
    const transparent = Color.from(
      alpha: 0,
      red: .123456789,
      green: .345678912,
      blue: .567891234,
    );
    const opaque = Color.from(
      alpha: 1,
      red: .987654321,
      green: .765432198,
      blue: .543219876,
    );
    const translucent = Color.from(
      alpha: .123456789,
      red: .234567891,
      green: .456789123,
      blue: .678912345,
    );

    shader.setColor('flatColor', transparent);
    shader.setColor('Material.albedoColor', opaque);
    shader.setColor('Material.lightingAmbient', translucent);
    shader.setColor('Material.colors[0]', transparent);
    shader.setColor('Material.colors[1]', opaque);
    shader.bind(device);

    expect(backend.uploads[0].$1, 'flatColor');
    expect(backend.uploads[0].$2, _float32Color(transparent));
    expect(backend.uploads[1].$1, 'Material');
    expect(backend.uploads[1].$2, [
      ..._float32Color(opaque),
      ..._float32Color(translucent),
      ..._float32Color(transparent),
      ..._float32Color(opaque),
    ]);
    expect(
      _float32Color(translucent)[3],
      isNot((translucent.toARGB32() >> 24) / 255),
    );
  });

  test('binding color A then color B preserves the first upload', () {
    final shader = _ColorShader()..resource;
    const colorA = Color.from(
      alpha: .135791357,
      red: .246802468,
      green: .357913579,
      blue: .468024680,
    );
    const colorB = Color.from(
      alpha: .975319753,
      red: .864208642,
      green: .753197531,
      blue: .642086420,
    );

    shader.setColor('flatColor', colorA);
    shader.bind(device);
    final firstUpload = backend.uploads.single.$2;
    shader.setColor('flatColor', colorB);
    shader.bind(device);

    expect(firstUpload, _float32Color(colorA));
    expect(backend.uploads.last.$2, _float32Color(colorB));
    expect(backend.uploads.last.$2, isNot(same(firstUpload)));
  });

  test(
    'resource recreation clears bindings without aliasing the color buffer',
    () {
      final shader = _ColorShader()..resource;
      const before = Color.from(alpha: .2, red: .3, green: .4, blue: .5);
      const after = Color.from(alpha: .6, red: .7, green: .8, blue: .9);
      shader.setColor('Material.albedoColor', before);
      shader.bind(device);
      final firstUpload = backend.uploads.single.$2;

      shader.createResource();
      backend.uploads.clear();
      shader.bind(device);
      expect(backend.uploads, isEmpty);
      shader.setColor('Material.colors[1]', after);
      shader.bind(device);

      expect(firstUpload.sublist(0, 4), _float32Color(before));
      expect(backend.uploads.single.$2.sublist(0, 12), everyElement(0));
      expect(backend.uploads.single.$2.sublist(12), _float32Color(after));
      expect(shader.buffers, hasLength(1));
    },
  );

  test('invalid color keys preserve the existing reflection errors', () {
    final shader = _ColorShader()..resource;
    const color = Color.from(alpha: .2, red: .3, green: .4, blue: .5);

    expect(() => shader.setColor('Material.missing', color), throwsStateError);
    expect(
      () => shader.setColor('Material.colors[2]', color),
      throwsRangeError,
    );
    expect(
      () => shader.setColor('Material.colors[-1]', color),
      throwsStateError,
    );
    shader.setColor('Material.albedoColor', color);
    shader.bind(device);
    expect(backend.uploads.single.$2.sublist(0, 4), _float32Color(color));
  });
}

List<double> _float32Color(Color color) =>
    Float32List.fromList([color.r, color.g, color.b, color.a]).toList();

final class _ColorShader extends Shader {
  _ColorShader()
    : super.fromAsset(
        'color-storage-test',
        entryPoint: 'ColorStorage',
        slots: ['Material', 'flatColor'],
      );

  final buffers = Set<Float32List>.identity();
  final writes = <(String, List<double>)>[];

  @override
  void setVector4(String key, Vector4 vector) {
    buffers.add(vector.storage);
    writes.add((key, vector.storage.toList()));
    super.setVector4(key, vector);
  }
}

final class _RecordingBackend extends GpuBackend {
  final uploads = <(String, List<double>)>[];

  @override
  GpuShaderLibrary loadShaderLibrary(String assetName) => _ShaderLibrary();

  @override
  GpuRenderTarget createRenderTarget({
    required int width,
    required int height,
    required Color clearValue,
  }) => _RenderTarget();

  @override
  GpuFrame beginFrame() => _RecordingFrame(this);

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
    'Material' => _UniformSlot(slot, 64, {
      'albedoColor': 0,
      'lightingAmbient': 16,
      'colors': 32,
    }),
    'flatColor' => _UniformSlot(slot, 16, {}),
    _ => throw StateError('Unexpected shader slot: $slot'),
  };
}

final class _UniformSlot implements GpuUniformSlot {
  _UniformSlot(this.name, this.sizeInBytes, this.offsets);

  final String name;
  @override
  final int sizeInBytes;
  final Map<String, int> offsets;

  @override
  int? getMemberOffsetInBytes(String member) => offsets[member];
}

final class _RecordingFrame implements GpuFrame {
  _RecordingFrame(this.backend);

  final _RecordingBackend backend;

  @override
  GpuRenderPass beginRenderPass(
    GpuRenderTarget target, {
    required BlendState blend,
    required DepthStencilState depthStencil,
  }) => _RecordingPass(backend);

  @override
  void end() {}
}

final class _RecordingPass implements GpuRenderPass {
  _RecordingPass(this.backend);

  final _RecordingBackend backend;

  @override
  void bindUniform(GpuUniformSlot slot, ByteData data) {
    backend.uploads.add((
      (slot as _UniformSlot).name,
      data.buffer
          .asFloat32List(data.offsetInBytes, data.lengthInBytes ~/ 4)
          .toList(),
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _RenderTarget implements GpuRenderTarget {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
