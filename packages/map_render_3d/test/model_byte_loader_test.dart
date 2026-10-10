import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flame/cache.dart';
import 'package:flame/flame.dart';
import 'package:flame_3d/model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/map_render_3d.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
