import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_runtime_model_index.dart';

SpatialModelInstance model(String id, {double speed = 1}) =>
    SpatialModelInstance(
      id: id,
      modelId: 'water',
      position: Model3dVector3.zero,
      animationIndex: 0,
      animationSpeed: speed,
    );

void main() {
  test('frame lookups do not rescan a mounted scene for every object', () {
    final source = _CountingModels([
      for (var i = 0; i < 3000; i++) model('cell-$i'),
    ]);
    final index = SpatialRuntimeModelIndex({'route': source});
    final mountedReads = source.reads;
    for (var frame = 0; frame < 3; frame++) {
      for (var i = 0; i < source.length; i++) {
        expect(index.instance('route', 'cell-$i')!.id, 'cell-$i');
      }
    }
    expect(source.reads, mountedReads);
    expect(mountedReads, source.length);
  });

  test(
    'neighbour maps may reuse object identifiers without sharing metadata',
    () {
      final route = model('shore', speed: .5);
      final town = model('shore', speed: 2);
      final index = SpatialRuntimeModelIndex({
        'route': [route],
        'town': [town],
      });
      expect(index.instance('route', 'shore'), same(route));
      expect(index.instance('town', 'shore'), same(town));
      expect(index.instance('missing', 'shore'), isNull);
      expect(index.instance('route', 'missing'), isNull);
    },
  );

  test(
    'a replacement scene uses current metadata and drops unloaded objects',
    () {
      final before = SpatialRuntimeModelIndex({
        'route': [model('shore'), model('removed')],
      });
      final replacement = model('shore', speed: .5);
      final after = SpatialRuntimeModelIndex({
        'route': [replacement],
      });
      expect(before.instance('route', 'shore')!.animationSpeed, 1);
      expect(after.instance('route', 'shore'), same(replacement));
      expect(after.instance('route', 'removed'), isNull);
    },
  );
}

final class _CountingModels extends ListBase<SpatialModelInstance> {
  _CountingModels(this.values);

  final List<SpatialModelInstance> values;
  int reads = 0;

  @override
  int get length => values.length;

  @override
  set length(int value) => throw UnsupportedError('Read-only fixture');

  @override
  SpatialModelInstance operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, SpatialModelInstance value) =>
      throw UnsupportedError('Read-only fixture');
}
