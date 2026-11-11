import 'dart:collection';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test('batch source reference audit visits documents once for all assets', () {
    final artifact =
        ContentArtifactRef.fromBytes([1, 2, 3], mediaType: 'model/gltf-binary');
    final assets = [
      for (final id in ['one', 'two'])
        AssetRecord(id: id, logicalPath: 'assets/$id.glb', artifact: artifact)
    ];
    final document = _CountingMap({
      'name': 'assets/one.glb',
      'nested': [artifact.hexDigest]
    });
    final result = deriveAssetBatchDocumentUsages(
        assets: assets, documents: {'map:field': document});
    expect(result['one'], [r'map:field:$.name', r'map:field:$.nested[0]']);
    expect(result['two'], [r'map:field:$.nested[0]']);
    expect(document.reads, {'name': 1, 'nested': 1});
  });
}

final class _CountingMap extends MapBase<String, Object?> {
  _CountingMap(this.data);
  final Map<String, Object?> data;
  final Map<String, int> reads = {};

  @override
  Iterable<String> get keys => data.keys;
  @override
  Object? operator [](Object? key) {
    reads.update(key as String, (value) => value + 1, ifAbsent: () => 1);
    return data[key];
  }

  @override
  void operator []=(String key, Object? value) =>
      throw UnsupportedError('read only');
  @override
  void clear() => throw UnsupportedError('read only');
  @override
  Object? remove(Object? key) => throw UnsupportedError('read only');
}
