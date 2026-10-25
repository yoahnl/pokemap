import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/flame.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('model textures upload straight RGB for every glTF alpha mode', () async {
    final pixels = [
      [255, 255, 255, 115],
      [0, 0, 0, 115],
      [128, 64, 32, 115],
      [255, 128, 64, 255],
      [0, 0, 0, 0],
    ];
    for (final mode in ['BLEND', 'MASK', 'OPAQUE']) {
      final backend = _AlphaUploadBackend();
      final model = await ModelByteLoader.load(
        _texturedTriangle(pixels, alphaMode: mode),
      );
      final material =
          model.nodes.values.single.mesh!.surfaces.single.material
              as SpatialPixelMaterial;

      material.albedoTexture.resource;

      expect(backend.uploads, hasLength(1), reason: mode);
      expect(backend.size, const ui.Size(5, 1));
      expect(backend.format, GpuPixelFormat.rgba8888);
      final uploaded = backend.uploads.single;
      expect(uploaded.take(4), pixels.first, reason: '$mode semi-white');
      expect(uploaded.skip(4).take(4), pixels[1], reason: '$mode semi-black');
      for (var channel = 0; channel < 4; channel++) {
        expect(
          uploaded[8 + channel],
          closeTo(pixels[2][channel], 1),
          reason: '$mode colored channel $channel',
        );
      }
      expect(uploaded.skip(12).take(4), pixels[3], reason: '$mode opaque');
      expect(uploaded.skip(16), pixels[4], reason: '$mode transparent');
      expect(material.alphaMode, switch (mode) {
        'BLEND' => Model3dAlphaMode.blend,
        'MASK' => Model3dAlphaMode.mask,
        _ => Model3dAlphaMode.opaque,
      });
    }
  });

  test('straight model texture upload keeps material color and opacity factors', () async {
    final backend = _AlphaUploadBackend();
    final model = await ModelByteLoader.load(
      _texturedTriangle(
        [[255, 255, 255, 115]],
        alphaMode: 'BLEND',
        colorFactor: [.5, .25, .75, .5],
      ),
    );
    final material =
        model.nodes.values.single.mesh!.surfaces.single.material
            as SpatialPixelMaterial;

    material.albedoTexture.resource;

    expect(backend.uploads.single, [255, 255, 255, 115]);
    expect(material.albedoColor.r, .5);
    expect(material.albedoColor.g, .25);
    expect(material.albedoColor.b, .75);
    expect(material.albedoColor.a, .5);
    expect(material.alphaMode, Model3dAlphaMode.blend);
  });

  test(
    'scene model preload overlaps four reads and reuses cached models',
    () async {
      final cache = <String, Future<Model>>{};
      final gates = [
        for (var index = 0; index < 6; index++) Completer<Uint8List>(),
      ];
      final started = <int>[];
      var active = 0, maximum = 0;
      final sources = {
        for (var index = 0; index < gates.length; index++)
          'model-$index': () async {
            started.add(index);
            active++;
            if (active > maximum) maximum = active;
            try {
              return await gates[index].future;
            } finally {
              active--;
            }
          },
      };
      final loading = ModelByteLoader.preloadCached(cache, sources);
      try {
        await Future<void>.delayed(Duration.zero);
        expect(started, [0, 1, 2, 3]);
        for (var index = 0; index < 4; index++) {
          gates[index].complete(_triangle('Model $index'));
        }
        await Future.wait([
          for (var index = 0; index < 4; index++) cache['model-$index']!,
        ]);
        await Future<void>.delayed(Duration.zero);
        expect(started, [0, 1, 2, 3, 4, 5]);
        for (var index = 4; index < gates.length; index++) {
          gates[index].complete(_triangle('Model $index'));
        }
        expect(await loading, isTrue);
        expect(maximum, 4);
        final models = await Future.wait(cache.values);
        expect(models.map((model) => model.nodes.values.single.name), [
          for (var index = 0; index < 6; index++) 'Model $index',
        ]);
        expect(await ModelByteLoader.preloadCached(cache, sources), isTrue);
        expect(started, [0, 1, 2, 3, 4, 5]);
      } finally {
        for (var index = 0; index < gates.length; index++) {
          if (!gates[index].isCompleted)
            gates[index].complete(_triangle('Model $index'));
        }
        await loading;
      }
    },
  );

  test('cancelled scene preload starts no further model reads', () async {
    final cache = <String, Future<Model>>{};
    final gates = [
      for (var index = 0; index < 6; index++) Completer<Uint8List>(),
    ];
    final started = <int>[];
    var current = true;
    final loading = ModelByteLoader.preloadCached(cache, {
      for (var index = 0; index < gates.length; index++)
        'model-$index': () {
          started.add(index);
          return gates[index].future;
        },
    }, isCurrent: () => current);
    try {
      await Future<void>.delayed(Duration.zero);
      expect(started, [0, 1, 2, 3]);
      current = false;
      for (var index = 0; index < 4; index++) {
        gates[index].complete(_triangle('Model $index'));
      }
      expect(await loading, isFalse);
      expect(started, [0, 1, 2, 3]);
      expect(cache.keys, ['model-0', 'model-1', 'model-2', 'model-3']);
    } finally {
      current = false;
      for (var index = 0; index < gates.length; index++) {
        if (!gates[index].isCompleted)
          gates[index].complete(_triangle('Model $index'));
      }
      await loading;
    }
  });

  test(
    'failed scene preload drains active reads and remains retryable',
    () async {
      final cache = <String, Future<Model>>{};
      final gates = [
        for (var index = 0; index < 6; index++) Completer<Uint8List>(),
      ];
      final started = <int>[];
      final loading = ModelByteLoader.preloadCached(cache, {
        for (var index = 0; index < gates.length; index++)
          'model-$index': () {
            started.add(index);
            return gates[index].future;
          },
      });
      final failure = expectLater(loading, throwsStateError);
      try {
        await Future<void>.delayed(Duration.zero);
        expect(started, [0, 1, 2, 3]);
        gates[0].completeError(StateError('Unavailable model'));
        await Future<void>.delayed(Duration.zero);
        expect(cache.containsKey('model-0'), isFalse);
        for (var index = 1; index < 4; index++) {
          gates[index].complete(_triangle('Model $index'));
        }
        await failure;
        expect(started, [0, 1, 2, 3]);
        expect(
          await ModelByteLoader.preloadCached(cache, {
            'model-0': () async => _triangle('Recovered'),
          }),
          isTrue,
        );
        expect((await cache['model-0']!).nodes.values.single.name, 'Recovered');
      } finally {
        for (var index = 0; index < gates.length; index++) {
          if (!gates[index].isCompleted)
            gates[index].complete(_triangle('Model $index'));
        }
        await failure;
      }
    },
  );

  test(
    'shared model cache retries a rejected asset once it becomes available',
    () async {
      final cache = <String, Future<Model>>{};
      var attempts = 0;
      Future<Uint8List> read() async {
        attempts++;
        if (attempts == 1) throw StateError('asset not available');
        return _triangle('Recovered');
      }

      await expectLater(
        ModelByteLoader.loadCached(cache, 'asset', read),
        throwsStateError,
      );
      expect(cache, isEmpty);
      final recovered = await ModelByteLoader.loadCached(cache, 'asset', read);
      expect(recovered.nodes.values.single.name, 'Recovered');
      expect(attempts, 2);
      expect(
        await ModelByteLoader.loadCached(cache, 'asset', read),
        same(recovered),
      );
      expect(attempts, 2);
    },
  );

  test(
    'stale failed model request preserves its replacement cache entry',
    () async {
      final cache = <String, Future<Model>>{};
      final missing = Completer<Uint8List>();
      final stale = ModelByteLoader.loadCached(
        cache,
        'asset',
        () => missing.future,
      );
      final rejected = expectLater(stale, throwsStateError);
      cache.clear();
      final latest = ModelByteLoader.loadCached(
        cache,
        'asset',
        () async => _triangle('Latest'),
      );
      final replacement = cache['asset'];
      missing.completeError(StateError('stale read failed'));
      await rejected;
      expect(cache['asset'], same(replacement));
      expect((await latest).nodes.values.single.name, 'Latest');
    },
  );

  test(
    'concurrent project models preserve ordinary Flame asset reads',
    () async {
      final original = Flame.assets;
      final bundle = _Bundle();
      Flame.assets = AssetsCache(bundle: bundle);
      addTearDown(() => Flame.assets = original);
      final models = await Future.wait([
        ModelByteLoader.load(_triangle('Maison')),
        ModelByteLoader.load(_triangle('Arbre')),
      ]);
      expect(models[0].nodes.values.single.name, 'Maison');
      expect(models[1].nodes.values.single.name, 'Arbre');
      expect(await Flame.assets.readFile('assets/ordinary.txt'), 'ordinary');
      expect(bundle.keys, ['assets/ordinary.txt']);
      expect(Flame.assets.cacheCount, 1);
    },
  );

  test(
    'failed model load does not replace or clear existing asset data',
    () async {
      final original = Flame.assets;
      Flame.assets = AssetsCache(bundle: _Bundle());
      addTearDown(() => Flame.assets = original);
      await Flame.assets.readFile('assets/ordinary.txt');
      await expectLater(
        ModelByteLoader.load(Uint8List.fromList([0, 1])),
        throwsA(anything),
      );
      expect(Flame.assets.fromCache<String>('assets/ordinary.txt'), 'ordinary');
      expect(Flame.assets.cacheCount, 1);
    },
  );
}

class _Bundle extends CachingAssetBundle {
  final keys = <String>[];
  @override
  Future<ByteData> load(String key) async {
    keys.add(key);
    if (key != 'assets/ordinary.txt') throw StateError('Unexpected asset $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode('ordinary')));
  }
}

final class _AlphaUploadBackend extends GpuBackend {
  final uploads = <List<int>>[];
  ui.Size? size;
  GpuPixelFormat? format;

  @override
  GpuTexture createTexture({
    required GpuStorageMode storageMode,
    required int width,
    required int height,
    required GpuPixelFormat format,
  }) {
    size = ui.Size(width.toDouble(), height.toDouble());
    this.format = format;
    return _AlphaUploadTexture(uploads);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _AlphaUploadTexture implements GpuTexture {
  _AlphaUploadTexture(this.uploads);
  final List<List<int>> uploads;

  @override
  void write(ByteData data) {
    uploads.add(
      data.buffer
          .asUint8List(data.offsetInBytes, data.lengthInBytes)
          .toList(),
    );
  }

  @override
  ui.Image asImage() => throw UnsupportedError('GPU upload capture only');
}

Uint8List _texturedTriangle(
  List<List<int>> pixels, {
  required String alphaMode,
  List<double> colorFactor = const [1, 1, 1, 1],
}) {
  final source = _triangle('Alpha fixture');
  final sourceData = ByteData.sublistView(source);
  final jsonLength = sourceData.getUint32(12, Endian.little);
  final json = jsonDecode(utf8.decode(source.sublist(20, 20 + jsonLength)))
      as Map<String, dynamic>;
  final image = img.Image(width: pixels.length, height: 1, numChannels: 4);
  for (var index = 0; index < pixels.length; index++) {
    final rgba = pixels[index];
    image.setPixelRgba(index, 0, rgba[0], rgba[1], rgba[2], rgba[3]);
  }
  final png = img.encodePng(image);
  final binary = Uint8List(60 + png.length);
  binary.setRange(0, 36, source.sublist(28 + jsonLength, 64 + jsonLength));
  binary.setRange(60, binary.length, png);
  json['buffers'][0]['byteLength'] = binary.length;
  json['bufferViews'].addAll([
    {'buffer': 0, 'byteOffset': 36, 'byteLength': 24},
    {'buffer': 0, 'byteOffset': 60, 'byteLength': png.length},
  ]);
  json['accessors'].add({
    'bufferView': 1,
    'componentType': 5126,
    'count': 3,
    'type': 'VEC2',
  });
  json['meshes'][0]['primitives'][0]['attributes']['TEXCOORD_0'] = 1;
  json['meshes'][0]['primitives'][0]['material'] = 0;
  json['images'] = [
    {'bufferView': 2, 'mimeType': 'image/png'},
  ];
  json['textures'] = [
    {'source': 0},
  ];
  json['materials'] = [
    {
      'alphaMode': alphaMode,
      if (alphaMode == 'MASK') 'alphaCutoff': .5,
      'pbrMetallicRoughness': {
        'baseColorTexture': {'index': 0},
        'baseColorFactor': colorFactor,
      },
    },
  ];
  final encodedJson = utf8.encode(jsonEncode(json));
  final paddedJsonLength = (encodedJson.length + 3) ~/ 4 * 4;
  final paddedBinaryLength = (binary.length + 3) ~/ 4 * 4;
  final output = Uint8List(28 + paddedJsonLength + paddedBinaryLength);
  final outputData = ByteData.sublistView(output);
  outputData.setUint32(0, 0x46546c67, Endian.little);
  outputData.setUint32(4, 2, Endian.little);
  outputData.setUint32(8, output.length, Endian.little);
  outputData.setUint32(12, paddedJsonLength, Endian.little);
  outputData.setUint32(16, 0x4e4f534a, Endian.little);
  output.fillRange(20, 20 + paddedJsonLength, 32);
  output.setRange(20, 20 + encodedJson.length, encodedJson);
  outputData.setUint32(20 + paddedJsonLength, paddedBinaryLength, Endian.little);
  outputData.setUint32(24 + paddedJsonLength, 0x004e4942, Endian.little);
  output.setRange(28 + paddedJsonLength, 28 + paddedJsonLength + binary.length, binary);
  return output;
}

Uint8List _triangle(String name) {
  final binary = ByteData(36);
  final coordinates = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0];
  for (var i = 0; i < coordinates.length; i++) {
    binary.setFloat32(i * 4, coordinates[i], Endian.little);
  }
  final json = utf8.encode(
    jsonEncode({
      'asset': {'version': '2.0'},
      'scene': 0,
      'scenes': [
        {
          'nodes': [0],
        },
      ],
      'nodes': [
        {'name': name, 'mesh': 0},
      ],
      'buffers': [
        {'byteLength': 36},
      ],
      'bufferViews': [
        {'buffer': 0, 'byteLength': 36},
      ],
      'accessors': [
        {'bufferView': 0, 'componentType': 5126, 'count': 3, 'type': 'VEC3'},
      ],
      'meshes': [
        {
          'primitives': [
            {
              'attributes': {'POSITION': 0},
            },
          ],
        },
      ],
    }),
  );
  final jsonSize = (json.length + 3) ~/ 4 * 4;
  final bytes = Uint8List(12 + 8 + jsonSize + 8 + 36);
  final data = ByteData.sublistView(bytes);
  data.setUint32(0, 0x46546c67, Endian.little);
  data.setUint32(4, 2, Endian.little);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint32(12, jsonSize, Endian.little);
  data.setUint32(16, 0x4e4f534a, Endian.little);
  bytes.fillRange(20, 20 + jsonSize, 32);
  bytes.setRange(20, 20 + json.length, json);
  data.setUint32(20 + jsonSize, 36, Endian.little);
  data.setUint32(24 + jsonSize, 0x004e4942, Endian.little);
  bytes.setRange(28 + jsonSize, bytes.length, binary.buffer.asUint8List());
  return bytes;
}
