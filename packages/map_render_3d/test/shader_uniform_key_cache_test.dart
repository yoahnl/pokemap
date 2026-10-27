import 'dart:typed_data';
import 'dart:ui' show Color, Size;

import 'package:flame_3d/game.dart'
    show Matrix2, Matrix3, Matrix4, Vector2, Vector3, Vector4;
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flame_3d/src/resources/shader/uniform_key_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a stable uniform key is fully parsed once across 300 frames', () {
    final cache = _CountingUniformKeyCache();

    for (var frame = 0; frame < 300; frame++) {
      expect(cache.parse('Lights.positions[12]'), ('Lights', 'positions', 12));
    }

    expect(cache.parses, 1);
  });

  test('stable variations are fully parsed once per key across 300 frames', () {
    final cache = _CountingUniformKeyCache();
    const keys = {
      'VertexInfo.model': ('VertexInfo', 'model', null),
      'Material.albedoColor': ('Material', 'albedoColor', null),
      'Lights.positions[0]': ('Lights', 'positions', 0),
      'Lights.positions[1]': ('Lights', 'positions', 1),
      'Lights.positions[01]': ('Lights', 'positions', 1),
      'Lights.intensities[1]': ('Lights', 'intensities', 1),
      'flatColor': ('flatColor', null, null),
      'flatColor[3]': ('flatColor', null, 3),
    };

    for (var frame = 0; frame < 300; frame++) {
      for (final entry in keys.entries) {
        expect(cache.parse(entry.key), entry.value);
      }
    }

    expect(cache.parses, keys.length);
  });

  test('more than 10000 keys retain only the configured newest entries', () {
    final cache = _CountingUniformKeyCache();
    const count = 10001;

    for (var i = 0; i < count; i++) {
      expect(cache.parse('Lights.positions[$i]'), ('Lights', 'positions', i));
    }
    expect(cache.parses, count);

    for (var i = count - cache.capacity; i < count; i++) {
      expect(cache.parse('Lights.positions[$i]'), ('Lights', 'positions', i));
    }
    expect(cache.parses, count);

    for (var i = 0; i < count - cache.capacity; i++) {
      cache.parse('Lights.positions[$i]');
    }
    expect(cache.parses, count * 2 - cache.capacity);
  });

  test('evicted keys resume correctly with bounded FIFO retention', () {
    final cache = _CountingUniformKeyCache(capacity: 2);

    cache.parse('Lights.positions[0]');
    cache.parse('Lights.positions[1]');
    for (var i = 0; i < 300; i++) {
      cache.parse('Lights.positions[0]');
    }
    expect(cache.parses, 2);

    cache.parse('Lights.positions[2]');
    expect(cache.parse('Lights.positions[1]'), ('Lights', 'positions', 1));
    expect(cache.parses, 3);
    expect(cache.parse('Lights.positions[0]'), ('Lights', 'positions', 0));
    expect(cache.parses, 4);
    expect(cache.parse('Lights.positions[2]'), ('Lights', 'positions', 2));
    expect(cache.parses, 4);
  });

  test('invalid keys are never retained and never evict valid keys', () {
    final cache = _CountingUniformKeyCache(capacity: 2);
    cache.parse('Material.albedoColor');
    cache.parse('Lights.positions[0]');

    for (var i = 0; i < 10001; i++) {
      expect(
        () => cache.parse('Lights.positions[-$i]'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Invalid uniform key: "Lights.positions[-$i]"',
          ),
        ),
      );
    }
    for (var i = 0; i < 2; i++) {
      expect(() => cache.parse('Lights.positions[-1]'), throwsStateError);
    }
    expect(cache.parses, 10005);
    cache.parse('Material.albedoColor');
    cache.parse('Lights.positions[0]');
    expect(cache.parses, 10005);
  });

  test('overflowing indices keep FormatException and are never retained', () {
    final cache = _CountingUniformKeyCache(capacity: 1);
    final key = 'Lights.positions[${'9' * 100}]';
    cache.parse('Material.albedoColor');

    expect(() => cache.parse(key), throwsFormatException);
    expect(() => cache.parse(key), throwsFormatException);
    cache.parse('Material.albedoColor');
    expect(cache.parses, 3);
  });

  test('public parseKey preserves the exact existing key grammar', () {
    const valid = {
      'VertexInfo.model': ('VertexInfo', 'model', null),
      '_Slot._member_2[00012]': ('_Slot', '_member_2', 12),
      '1.2[3]': ('1', '2', 3),
      'raw': ('raw', null, null),
      'raw[3]': ('raw', null, 3),
    };
    const invalid = [
      '',
      ' Slot.member',
      'Slot.member ',
      'Slot.member\n',
      'Slot.member.other',
      'Slot.member[-1]',
      'Slot.member[+1]',
      'Slot.member[]',
      'Slot.member[1][2]',
      'Slot[1].member',
      'Slot.member[1.0]',
      'Slot.mémbre',
    ];

    for (final entry in valid.entries) {
      expect(Shader.parseKey(entry.key), entry.value);
    }
    for (final key in invalid) {
      expect(
        () => Shader.parseKey(key),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Invalid uniform key: "$key"',
          ),
        ),
      );
    }
  });

  group('uniform uploads through setters and bindings', () {
    late _RecordingBackend backend;
    late GraphicsDevice device;

    setUp(() {
      backend = _RecordingBackend();
      device = GraphicsDevice(backend: backend)
        ..begin()
        ..beginPass(const Size(1, 1));
    });

    tearDown(() => device.end());

    test('300 frames preserve scalar vector matrix uint and raw uploads', () {
      final shader = _shader()..resource;
      final vector2 = Vector2(2.25, 3.5);
      final vector3 = Vector3(4.25, 5.5, 6.75);
      final vector4 = Vector4(7.25, 8.5, 9.75, 10.125);
      final matrix2 = Matrix2.identity()..storage[1] = 11.25;
      final matrix3 = Matrix3.identity()..storage[2] = 12.5;
      final matrix4 = Matrix4.identity()..storage[3] = 13.75;

      for (var frame = 0; frame < 300; frame++) {
        final value = frame + .125;
        final uint = 0xf1230000 + frame;
        shader
          ..setFloat('Uniforms.floatValue', value)
          ..setUint('Uniforms.uintValue', uint)
          ..setVector2('Uniforms.vector2', vector2)
          ..setVector3('Uniforms.vector3', vector3)
          ..setVector4('Uniforms.vector4', vector4)
          ..setMatrix2('Uniforms.matrix2', matrix2)
          ..setMatrix3('Uniforms.matrix3', matrix3)
          ..setMatrix4('Uniforms.matrix4', matrix4)
          ..setVector4('raw', vector4)
          ..bind(device);

        final bytes = backend.uploads[frame * 2].$3;
        final data = ByteData.sublistView(bytes);
        expect(data.getFloat32(0, Endian.little), value);
        expect(data.getUint32(4, Endian.little), uint);
        expect(_floats(bytes, 16, 2), vector2.storage);
        expect(_floats(bytes, 32, 3), vector3.storage);
        expect(_floats(bytes, 48, 4), vector4.storage);
        expect(_floats(bytes, 64, 4), matrix2.storage);
        expect(_floats(bytes, 80, 9), matrix3.storage);
        expect(_floats(bytes, 128, 16), matrix4.storage);
        expect(
          _floats(backend.uploads[frame * 2 + 1].$3, 0, 4),
          vector4.storage,
        );
      }

      vector4.setValues(100, 200, 300, 400);
      expect(_floats(backend.uploads.first.$3, 48, 4), [
        7.25,
        8.5,
        9.75,
        10.125,
      ]);
      expect(backend.uploads, hasLength(600));
    });

    test(
      'array variations preserve std140 strides for every element width',
      () {
        final shader = _shader()..resource;
        final matrix = Matrix4.identity()..storage[7] = 17.25;

        for (var frame = 0; frame < 300; frame++) {
          for (var index = 0; index < 2; index++) {
            final value = frame + index + .25;
            shader
              ..setFloat('Uniforms.floatArray[$index]', value)
              ..setVector2('Uniforms.vector2Array[$index]', Vector2(value, 2))
              ..setVector3(
                'Uniforms.vector3Array[$index]',
                Vector3(value, 3, 4),
              )
              ..setVector4(
                'Uniforms.vector4Array[$index]',
                Vector4(value, 5, 6, 7),
              )
              ..setMatrix4('Uniforms.matrixArray[$index]', matrix);
          }
          shader.bind(device);
          final bytes = backend.uploads.last.$3;
          for (var index = 0; index < 2; index++) {
            final value = frame + index + .25;
            expect(_floats(bytes, 192 + index * 16, 4), [value, 0, 0, 0]);
            expect(_floats(bytes, 224 + index * 16, 4), [value, 2, 0, 0]);
            expect(_floats(bytes, 256 + index * 16, 4), [value, 3, 4, 0]);
            expect(_floats(bytes, 288 + index * 16, 4), [value, 5, 6, 7]);
            expect(_floats(bytes, 320 + index * 64, 16), matrix.storage);
          }
        }
        expect(backend.uploads, hasLength(300));
      },
    );

    test('eviction after 10001 public keys preserves resumed uploads', () {
      final shader = _shader()..resource;
      shader
        ..setFloat('Uniforms.floatValue', 1.25)
        ..bind(device);

      for (var i = 0; i < 10001; i++) {
        expect(Shader.parseKey('Other.field[$i]'), ('Other', 'field', i));
      }

      shader
        ..setFloat('Uniforms.floatValue', 2.5)
        ..setFloat('raw[5]', 3.75)
        ..bind(device);
      expect(_floats(backend.uploads.first.$3, 0, 1), [1.25]);
      expect(_floats(backend.uploads[1].$3, 0, 1), [2.5]);
      expect(_floats(backend.uploads[2].$3, 0, 4), [3.75, 0, 0, 0]);
    });

    test(
      'resource recreation uses new reflection and discards old bindings',
      () {
        final shader = _shader()..resource;
        shader
          ..setFloat('Uniforms.floatValue', 4.25)
          ..bind(device);
        final before = backend.uploads.single;

        backend.generation++;
        shader.recreateResource = true;
        shader.resource;
        shader.bind(device);
        expect(backend.uploads, hasLength(1));

        shader
          ..setFloat('Uniforms.floatValue', 8.5)
          ..bind(device);
        final after = backend.uploads.last;
        expect(before.$2, 0);
        expect(after.$2, 1);
        expect(_floats(before.$3, 0, 3), [4.25, 0, 0]);
        expect(_floats(after.$3, 0, 3), [0, 0, 8.5]);
      },
    );

    test(
      'interleaved shaders keep independent uploads for shared parsed keys',
      () {
        final first = _shader()..resource;
        final second = _shader()..resource;
        final vector = Vector4(1.25, 2.5, 3.75, 4.125);

        for (var frame = 0; frame < 300; frame++) {
          first
            ..setFloat('Uniforms.floatValue', frame + .25)
            ..setVector4('raw', vector);
          second
            ..setFloat('Uniforms.floatValue', frame + .5)
            ..setVector4('Uniforms.vector4', vector);
          first.bind(device);
          second.bind(device);
        }

        expect(backend.uploads, hasLength(900));
        for (var frame = 0; frame < 300; frame++) {
          expect(_floats(backend.uploads[frame * 3].$3, 0, 1), [frame + .25]);
          expect(
            _floats(backend.uploads[frame * 3 + 1].$3, 0, 4),
            vector.storage,
          );
          expect(_floats(backend.uploads[frame * 3 + 2].$3, 0, 1), [
            frame + .5,
          ]);
          expect(
            _floats(backend.uploads[frame * 3 + 2].$3, 48, 4),
            vector.storage,
          );
        }
      },
    );

    test('cached keys keep existing grammar reflection and bounds errors', () {
      final shader = _shader()..resource;

      for (var i = 0; i < 2; i++) {
        expect(
          () => shader.setFloat('Uniforms.missing', 1),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Field "missing" not found in uniform struct',
            ),
          ),
        );
        expect(
          () => shader.setFloat('Uniforms.floatArray[99]', 1),
          throwsRangeError,
        );
        expect(
          () => shader.setFloat('Uniforms.floatArray[-1]', 1),
          throwsStateError,
        );
        expect(
          () => shader.setFloat('Missing.value', 1),
          throwsA(isA<TypeError>()),
        );
        expect(() => shader.setFloat('sampler', 1), throwsA(isA<TypeError>()));
      }

      shader
        ..setFloat('Uniforms.floatValue', 9.25)
        ..bind(device);
      expect(_floats(backend.uploads.single.$3, 0, 1), [9.25]);

      final texture = Texture(ByteData(4), width: 1, height: 1);
      final samplerShader = _shader()..resource;
      samplerShader.setTexture('sampler', texture);
      for (var i = 0; i < 2; i++) {
        expect(
          () => samplerShader.setFloat('sampler.value', 1),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Slot "sampler.value" is a sampler block, not a uniform',
            ),
          ),
        );
        expect(
          () => shader.setTexture('Uniforms', texture),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Slot "Uniforms" is a uniform block, not a sampler',
            ),
          ),
        );
      }
    });
  });
}

class _CountingUniformKeyCache extends UniformKeyCache {
  _CountingUniformKeyCache({super.capacity});

  int parses = 0;

  @override
  (String, String?, int?) parseUncached(String key) {
    parses++;
    return super.parseUncached(key);
  }
}

Shader _shader() => Shader.fromAsset(
  'uniform-key-test',
  entryPoint: 'UniformKeys',
  slots: ['Uniforms', 'raw', 'sampler'],
);

List<double> _floats(Uint8List bytes, int offset, int count) {
  final data = ByteData.sublistView(bytes);
  return List.generate(
    count,
    (i) => data.getFloat32(offset + i * 4, Endian.little),
  );
}

final class _RecordingBackend extends GpuBackend {
  final uploads = <(String, int, Uint8List)>[];
  int generation = 0;

  @override
  GpuShaderLibrary loadShaderLibrary(String assetName) =>
      _ShaderLibrary(generation);

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
  _ShaderLibrary(this.generation);

  final int generation;

  @override
  GpuShader operator [](String entryPoint) => _Shader(generation);
}

final class _Shader implements GpuShader {
  _Shader(this.generation);

  final int generation;

  @override
  GpuUniformSlot getUniformSlot(String slot) => switch (slot) {
    'Uniforms' => _UniformSlot(slot, generation, 448, {
      'floatValue': generation == 0 ? 0 : 8,
      'uintValue': 4,
      'vector2': 16,
      'vector3': 32,
      'vector4': 48,
      'matrix2': 64,
      'matrix3': 80,
      'matrix4': 128,
      'floatArray': 192,
      'vector2Array': 224,
      'vector3Array': 256,
      'vector4Array': 288,
      'matrixArray': 320,
    }),
    'raw' => _UniformSlot(slot, generation, 16, {}),
    'sampler' => _UniformSlot(slot, generation, null, {}),
    _ => throw StateError('Unexpected shader slot: $slot'),
  };
}

final class _UniformSlot implements GpuUniformSlot {
  _UniformSlot(this.name, this.generation, this.sizeInBytes, this.offsets);

  final String name;
  final int generation;
  @override
  final int? sizeInBytes;
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
    final uniform = slot as _UniformSlot;
    backend.uploads.add((
      uniform.name,
      uniform.generation,
      Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      ),
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
