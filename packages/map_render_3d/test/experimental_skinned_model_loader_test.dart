import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/animated_render_model.dart';
import 'package:map_render_3d/src/glb_renderer_layout.dart';
import 'package:map_render_3d/src/model_byte_loader.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';
import 'package:map_render_3d/src/spatial_resource_admission.dart';

import '../../map_distribution/test/support/glb_fixture.dart';

Uint8List experimentalSkinFixture({
  bool texture = false,
  bool extraJoints = false,
  bool normals = true,
  bool sharedEdge = false,
}) {
  final binary = BytesBuilder();
  final views = <Map<String, Object>>[];
  final accessors = <Map<String, Object>>[];
  int add(List<num> values, int componentType, String type, int count) {
    final alignment = (4 - binary.length % 4) % 4;
    if (alignment != 0) binary.add(Uint8List(alignment));
    final byteLength = values.length * (componentType == 5123 ? 2 : 4);
    final data = ByteData(byteLength);
    for (final (index, value) in values.indexed) {
      if (componentType == 5123) {
        data.setUint16(index * 2, value.toInt(), Endian.little);
      } else {
        data.setFloat32(index * 4, value.toDouble(), Endian.little);
      }
    }
    final view = views.length;
    views.add({
      'buffer': 0,
      'byteOffset': binary.length,
      'byteLength': byteLength,
    });
    binary.add(data.buffer.asUint8List());
    accessors.add({
      'bufferView': view,
      'componentType': componentType,
      'count': count,
      'type': type,
    });
    return accessors.length - 1;
  }

  final position = add(
    [
      for (var i = 0; i < 6; i++) ...[i, i % 3 == 2 ? 1 : 0, i < 3 ? -1 : -10],
    ],
    5126,
    'VEC3',
    6,
  );
  final normal = add(
    [
      for (var i = 0; i < 6; i++) ...[0, 0, 1],
    ],
    5126,
    'VEC3',
    6,
  );
  final uv = add(
    [
      for (var i = 0; i < 6; i++) ...[i / 8, i / 16],
    ],
    5126,
    'VEC2',
    6,
  );
  final color = add(
    [
      for (var i = 0; i < 6; i++) ...[i / 8, .25, .5, 1],
    ],
    5126,
    'VEC4',
    6,
  );
  final joints = add(
    [
      for (var i = 0; i < 6; i++) ...[i * 4, i * 4 + 1, i * 4 + 2, i * 4 + 3],
    ],
    5123,
    'VEC4',
    6,
  );
  final weights = add(
    [
      for (var i = 0; i < 6; i++) ...[.4, .3, .2, .1],
    ],
    5126,
    'VEC4',
    6,
  );
  final before = add([0, 1, 2], 5123, 'SCALAR', 3);
  final middle = add(
    sharedEdge ? [0, 1, 2, 2, 3, 4] : [0, 1, 2, 3, 4, 5],
    5123,
    'SCALAR',
    6,
  );
  final after = add([3, 4, 5], 5123, 'SCALAR', 3);
  final times = add([0, 1], 5126, 'SCALAR', 2);
  final motion = add([2.3, 0, 0, 3.3, 0, 0], 5126, 'VEC3', 2);
  int? imageView;
  if (texture) {
    final png = img.encodePng(img.Image(width: 1, height: 1));
    imageView = views.length;
    views.add({
      'buffer': 0,
      'byteOffset': binary.length,
      'byteLength': png.length,
    });
    binary.add(png);
  }
  final attributes = <String, int>{
    'POSITION': position,
    if (normals) 'NORMAL': normal,
    'TEXCOORD_0': uv,
    'COLOR_0': color,
    'JOINTS_0': joints,
    'WEIGHTS_0': weights,
    if (extraJoints) 'JOINTS_1': joints,
  };
  final json = <String, Object>{
    'asset': {'version': '2.0'},
    'scene': 0,
    'scenes': [
      {
        'nodes': [for (var i = 0; i <= 24; i++) i],
      },
    ],
    'nodes': [
      {'mesh': 0, 'skin': 0},
      for (var i = 0; i < 24; i++)
        {
          'translation': [i / 10, 0, 0],
        },
    ],
    'skins': [
      {
        'joints': [for (var i = 1; i <= 24; i++) i],
      },
    ],
    'meshes': [
      {
        'primitives': [
          {'attributes': attributes, 'indices': before, 'material': 0},
          {'attributes': attributes, 'indices': middle, 'material': 1},
          {'attributes': attributes, 'indices': after, 'material': 2},
        ],
      },
    ],
    'materials': [
      {'name': 'before', 'pbrMetallicRoughness': {}},
      {
        'name': 'middle',
        'alphaMode': 'BLEND',
        'pbrMetallicRoughness': {
          if (texture) 'baseColorTexture': {'index': 0},
        },
      },
      {'name': 'after', 'pbrMetallicRoughness': {}},
    ],
    if (texture)
      'textures': [
        {'source': 0},
      ],
    if (texture)
      'images': [
        {'bufferView': imageView!, 'mimeType': 'image/png'},
      ],
    'animations': [
      {
        'name': 'joint motion',
        'samplers': [
          {'input': times, 'output': motion},
        ],
        'channels': [
          {
            'sampler': 0,
            'target': {'node': 24, 'path': 'translation'},
          },
        ],
      },
    ],
    'extras': {
      'aveluneMaterialAnimations': {
        'schemaVersion': 1,
        'clips': [
          {
            'name': 'UV',
            'durationSeconds': 1.0,
            'tracks': [
              {
                'materialIndex': 1,
                'times': [0, 1],
                'interpolation': 'LINEAR',
                'transforms': [
                  [1, 0, 0, 1, 0, 0],
                  [1, 0, 0, 1, .5, 0],
                ],
              },
            ],
          },
        ],
      },
    },
    'buffers': [
      {'byteLength': binary.length},
    ],
    'bufferViews': views,
    'accessors': accessors,
  };
  return Uint8List.fromList(encodeGlb(json, binary.takeBytes()));
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _RecordingBackend extends GpuBackend {
  late _RecordingBuffer latest;
  @override
  GpuBuffer createBuffer({
    required GpuStorageMode storageMode,
    required int sizeInBytes,
  }) => latest = _RecordingBuffer(sizeInBytes);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _RecordingBuffer implements GpuBuffer {
  _RecordingBuffer(int size) : bytes = Uint8List(size);
  final Uint8List bytes;
  @override
  void write(ByteData data, {int destinationOffsetInBytes = 0}) {
    bytes.setRange(
      destinationOffsetInBytes,
      destinationOffsetInBytes + data.lengthInBytes,
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }
}

final class _OrderDevice extends GraphicsDevice {
  _OrderDevice() : super(backend: _UnusedBackend());
  final surfaces = <Surface>[];
  @override
  void clearBindings() {}
  @override
  void bindGeometry(Surface surface) => surfaces.add(surface);
}

final class _OrderContext extends SpatialRenderContext {
  _OrderContext(super.device);
  @override
  void applyMaterial(Material material) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the default loader preserves its existing unsplit behavior', () async {
    final model = await ModelByteLoader.load(experimentalSkinFixture());
    final surfaces = model.nodes[0]!.mesh!.surfaces.toList();
    expect(surfaces, hasLength(3));
    expect(surfaces.every((surface) => surface.jointMap!.length == 24), isTrue);
  });

  test('opt in partitions palettes, attributes, materials and animated poses in order', () async {
    final model = await ModelByteLoader.load(
      experimentalSkinFixture(),
      experimentalPartitionSkinnedMeshes: true,
    ) as AnimatedRenderModel;
    final surfaces = model.nodes[0]!.mesh!.surfaces.toList();
    expect(surfaces, hasLength(4));
    expect(
      surfaces.map(
        (s) => (s.material as SpatialPixelMaterial).sourceMaterialName,
      ),
      ['before', 'middle', 'middle', 'after'],
    );
    expect(surfaces.map((s) => s.jointMap!.length), [12, 12, 12, 12]);
    expect(surfaces[1].material, same(surfaces[2].material));
    expect(model.materialBindings[1], [same(surfaces[1].material)]);
    final expected = [
      [0, 1, 2],
      [0, 1, 2],
      [3, 4, 5],
      [3, 4, 5],
    ];
    for (final (part, surface) in surfaces.indexed) {
      final colored = surface as SpatialModelSurface;
      expect([
        for (final i in surface.indices) surface.positions[i * 3].toInt(),
      ], expected[part]);
      for (final local in surface.indices) {
        final source = surface.positions[local * 3].toInt();
        expect(colored.vertexColors[local].r, source / 8);
        expect(colored.clipVertices[local].normal!.z, 1);
        final skin = surface.vertexSkin(local);
        for (var component = 0; component < 4; component++) {
          final global = source * 4 + component;
          expect(
            skin.joints.storage[component].toInt(),
            surface.jointMap![global],
          );
          expect(
            skin.weights.storage[component],
            closeTo([.4, .3, .2, .1][component], 1e-6),
          );
        }
      }
    }
    final state = AnimationState()
      ..startAnimation(model.animations.single)
      ..clock = .5;
    final palettes = model.processNodes(state)[0]!.jointTransforms;
    expect(
      palettes[2]![surfaces[2].jointMap![23]!].getTranslation().x,
      closeTo(2.8, 1e-6),
    );
    model.applyMaterialPose(
      model.materialAnimations.clips.single,
      .5,
      loop: false,
    );
    expect(
      (surfaces[1].material as SpatialPixelMaterial).uvTransformU.z,
      closeTo(.25, 1e-6),
    );
    expect(
      (surfaces[2].material as SpatialPixelMaterial).uvTransformU.z,
      closeTo(.25, 1e-6),
    );
  });

  test('transparent partitions keep their original surface depth and triangle order', () async {
    final model = await ModelByteLoader.load(
      experimentalSkinFixture(),
      experimentalPartitionSkinnedMeshes: true,
    );
    final surfaces = model.nodes[0]!.mesh!.surfaces.toList();
    final middle = [surfaces[1], surfaces[2]];
    final other = Surface(
      vertices: [
        Vertex(position: Vector3(0, 0, -4), texCoord: Vector2.zero()),
        Vertex(position: Vector3(1, 0, -4), texCoord: Vector2.zero()),
        Vertex(position: Vector3(0, 1, -4), texCoord: Vector2.zero()),
      ],
      indices: [0, 1, 2],
      material: SpatialPixelMaterial(
        Texture(ByteData(4), width: 1, height: 1),
        alphaMode: Model3dAlphaMode.blend,
      ),
    );
    final device = _OrderDevice();
    final context = _OrderContext(device)
      ..setCamera(Matrix4.identity(), Matrix4.identity());
    for (final surface in [...middle, other]) {
      context.drawSurface(surface);
    }
    context.flush();
    expect(device.surfaces, [middle[0], middle[1], other]);
  });

  test(
    'missing normals are calculated across shared edges before splitting',
    () async {
      final bytes = experimentalSkinFixture(normals: false, sharedEdge: true);
      final original = (await ModelByteLoader.load(bytes))
          .nodes[0]!
          .mesh!
          .surfaces
          .elementAt(1);
      final split = (await ModelByteLoader.load(
        bytes,
        experimentalPartitionSkinnedMeshes: true,
      )).nodes[0]!.mesh!.surfaces.toList();
      final backend = _RecordingBackend();
      original.createResource();
      final source = backend.latest.bytes.buffer
          .asFloat32List(0, original.verticesBytes ~/ 4)
          .toList();
      for (final surface in [split[1], split[2]]) {
        surface.createResource();
        final output = backend.latest.bytes.buffer.asFloat32List(
          0,
          surface.verticesBytes ~/ 4,
        );
        for (final i in surface.indices) {
          final sourceIndex = surface.positions[i * 3].toInt();
          for (var axis = 0; axis < 3; axis++) {
            expect(
              output[i * 20 + 9 + axis],
              closeTo(source[sourceIndex * 20 + 9 + axis], 1e-6),
            );
          }
        }
      }
    },
  );

  test(
    'reserves extra memory before conversion and releases on budget refusal',
    () async {
      final bytes = experimentalSkinFixture(texture: true);
      final measuring = RuntimeResourceBudget();
      final first = await measuring.acquire();
      final baseline = await spatialModelResourceEstimate(bytes, first);
      first.release();
      final second = await measuring.acquire();
      final expanded = await spatialModelResourceEstimate(
        bytes,
        second,
        experimentalPartitionSkinnedMeshes: true,
      );
      second.release();
      expect(expanded.resident, greaterThan(baseline.resident));
      expect(expanded.transient, greaterThan(baseline.transient));
      final budget = RuntimeResourceBudget(
        profile: RuntimeResourceProfile(
          maximumResidentBytes: baseline.resident,
          maximumTransientBytes: baseline.transient,
        ),
      );
      var decoded = 0;
      await expectLater(
        ModelByteLoader.load(
          bytes,
          budget: budget,
          experimentalPartitionSkinnedMeshes: true,
          codecLoader: (data) {
            decoded++;
            return ui.instantiateImageCodec(data);
          },
        ),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      expect(decoded, 0);
      expect(budget.residentBytes, 0);
      expect(budget.transientBytes, 0);
      expect(budget.activeDecodes, 0);
    },
  );

  test('retains the experimental budget until its owner releases it', () async {
    final budget = RuntimeResourceBudget();
    RuntimeResourceReservation? held;
    final model = await ModelByteLoader.load(
      experimentalSkinFixture(),
      budget: budget,
      experimentalPartitionSkinnedMeshes: true,
      onResident: (reservation) => held = reservation,
    );
    expect(model.nodes[0]!.mesh!.surfaceCount, 4);
    expect(held, isNotNull);
    expect(budget.residentBytes, greaterThan(0));
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
    held!.release();
    expect(budget.residentBytes, 0);
  });

  test('releases its budget if texture conversion fails', () async {
    final budget = RuntimeResourceBudget();
    var calls = 0;
    await expectLater(
      ModelByteLoader.load(
        experimentalSkinFixture(texture: true),
        budget: budget,
        experimentalPartitionSkinnedMeshes: true,
        codecLoader: (_) async {
          calls++;
          throw StateError('decode failed');
        },
      ),
      throwsStateError,
    );
    expect(calls, 1);
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test(
    'unsupported additional joint attributes fail closed in experimental mode',
    () async {
      final bytes = experimentalSkinFixture(extraJoints: true);
      final budget = RuntimeResourceBudget();
      await expectLater(
        ModelByteLoader.load(
          bytes,
          budget: budget,
          experimentalPartitionSkinnedMeshes: true,
        ),
        throwsFormatException,
      );
      expect(budget.residentBytes, 0);
      expect(budget.transientBytes, 0);
      expect(budget.activeDecodes, 0);
    },
  );

  test(
    'rejects excessive skinned accessor counts before texture decoding',
    () async {
      final bytes = experimentalSkinFixture(texture: true);
      final header = ByteData.sublistView(bytes);
      final length = header.getUint32(12, Endian.little);
      final json = jsonDecode(
        utf8.decode(bytes.sublist(20, 20 + length)),
      ) as Map<String, dynamic>;
      final position =
          json['meshes'][0]['primitives'][0]['attributes']['POSITION'] as int;
      json['accessors'][position]['count'] = 65536;
      final oversized = Uint8List.fromList(
        encodeGlb(json, bytes.sublist(28 + length)),
      );
      final budget = RuntimeResourceBudget();
      var decoded = 0;
      await expectLater(
        ModelByteLoader.load(
          oversized,
          budget: budget,
          experimentalPartitionSkinnedMeshes: true,
          codecLoader: (data) {
            decoded++;
            return ui.instantiateImageCodec(data);
          },
        ),
        throwsA(
          isA<RuntimeResourceAdmissionException>().having(
            (e) => e.reason,
            'reason',
            'skin_partition_geometry',
          ),
        ),
      );
      expect(decoded, 0);
      expect(budget.residentBytes, 0);
      expect(budget.transientBytes, 0);
      expect(budget.activeDecodes, 0);
    },
  );

  test(
    'rejects normalized integer weights even when no split is needed',
    () async {
      final bytes = experimentalSkinFixture();
      final header = ByteData.sublistView(bytes);
      final length = header.getUint32(12, Endian.little);
      final json = jsonDecode(
        utf8.decode(bytes.sublist(20, 20 + length)),
      ) as Map<String, dynamic>;
      final weightIndex =
          json['meshes'][0]['primitives'][0]['attributes']['WEIGHTS_0'] as int;
      final accessor = json['accessors'][weightIndex];
      accessor['componentType'] = 5121;
      accessor['normalized'] = true;
      final offset =
          json['bufferViews'][accessor['bufferView']]['byteOffset'] as int;
      final binary = Uint8List.fromList(bytes.sublist(28 + length));
      for (var vertex = 0; vertex < 6; vertex++) {
        binary.setRange(offset + vertex * 4, offset + vertex * 4 + 4, [
          255,
          0,
          0,
          0,
        ]);
      }
      final source = Uint8List.fromList(encodeGlb(json, binary));
      final budget = RuntimeResourceBudget();
      await expectLater(
        ModelByteLoader.load(
          source,
          budget: budget,
          experimentalPartitionSkinnedMeshes: true,
        ),
        throwsFormatException,
      );
      expect(budget.residentBytes, 0);
      expect(budget.transientBytes, 0);
    },
  );
}
